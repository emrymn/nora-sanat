import Foundation
import NoraCekirdek
import UIKit
import UserNotifications
import WebKit

/// Tekrar hatırlatmaları ve simge rozeti.
///
/// - Sayılar Sanat Atlası'nın kendi ilerlemesinden gelir (`WebKabugu` → `TekrarKoprusu.betik`): uygulama her kapanışta ve
///   açılışta önümüzdeki 14 günün "tekrar bekliyor" sayılarını bildirir; burada her gün için seçilen saatte bir bildirim kurulur.
/// - Açma/kapama ve saat iOS Ayarlar'ında: Ayarlar → Uygulamalar → Nora Sanat (Settings.bundle).
/// - Rozet: sitedeki Ayarlar → "Simge rozeti" açıksa (sitenin `navigator.setAppBadge` çağrıları) ve bildirimlerde.
@MainActor
final class Hatirlatici: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Hatirlatici()

    enum Anahtar {
        static let acik = "hatirlatma"
        static let saat = "hatirlatmaSaati"
        static let sonTakvim = "sonTekrarTakvimi"
    }

    private let merkez = UNUserNotificationCenter.current()
    private let ayarlar = UserDefaults.standard
    private var degisimGozlemi: NSObjectProtocol?

    override init() {
        super.init()
        ayarlar.register(defaults: [Anahtar.acik: true, Anahtar.saat: 20])
        // iOS Ayarlar'da saat değişince (uygulamaya dönüldüğünde) yeniden kur
        degisimGozlemi = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in Hatirlatici.shared.ayarDegistiMi() }
        }
        sonAyar = ayarImzasi
    }

    func baslat() {
        merkez.delegate = self
    }

    // MARK: Takvim

    private var sonAyar = ""
    private var ayarImzasi: String { "\(ayarlar.bool(forKey: Anahtar.acik))-\(ayarlar.integer(forKey: Anahtar.saat))" }

    private func ayarDegistiMi() {
        guard ayarImzasi != sonAyar else { return }
        sonAyar = ayarImzasi
        Task { await planla() }
    }

    var sonTakvim: TekrarTakvimi? {
        get { ayarlar.data(forKey: Anahtar.sonTakvim).flatMap { try? JSONDecoder().decode(TekrarTakvimi.self, from: $0) } }
        set { ayarlar.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: Anahtar.sonTakvim) }
    }

    /// Her açılış ve kapanışta gelir; izin ya da ayar sonradan değişmiş olabileceği için her seferinde yeniden kurulur.
    func takvimGeldi(_ t: TekrarTakvimi) {
        sonTakvim = t
        Task { await planla() }
    }

    /// Bekleyen hatırlatmaları son takvime göre baştan kurar.
    func planla() async {
        let eskiler = await merkez.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(TekrarPlani.onek) }
        merkez.removePendingNotificationRequests(withIdentifiers: eskiler)

        guard ayarlar.bool(forKey: Anahtar.acik), let t = sonTakvim else { return }
        // İzni, gerçekten bekleyen bir tekrar olduğunda bir kez sor
        guard t.gunler.contains(where: { $0 > 0 }), await izinVar(sor: true) else { return }

        let saat = min(23, max(0, ayarlar.integer(forKey: Anahtar.saat)))
        let simdi = Date()
        let c = Calendar.current.dateComponents([.hour, .minute], from: simdi)
        let plan = TekrarPlani.plan(t, saat: saat, dakika: 0, simdiGun: GunTarihi.gun(simdi),
                                    simdiDakika: (c.hour ?? 0) * 60 + (c.minute ?? 0))
        for h in plan {
            guard let (y, a, g) = GunTarihi.ayir(h.gun) else { continue }
            let icerik = UNMutableNotificationContent()
            icerik.title = h.baslik
            icerik.body = h.govde
            icerik.sound = .default
            icerik.userInfo = ["adres": "#/pekistir"]
            if t.rozet { icerik.badge = NSNumber(value: h.sayi) }
            let zaman = DateComponents(year: y, month: a, day: g, hour: h.saat, minute: h.dakika)
            let istek = UNNotificationRequest(identifier: h.kimlik, content: icerik,
                                              trigger: UNCalendarNotificationTrigger(dateMatching: zaman, repeats: false))
            try? await merkez.add(istek)
        }
    }

    // MARK: İzin ve rozet

    /// Bildirim izni var mı; `sor` ise ve henüz sorulmadıysa sorar.
    func izinVar(sor: Bool) async -> Bool {
        let durum = await merkez.notificationSettings().authorizationStatus
        switch durum {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined:
            #if DEBUG
            // CI karşılaştırma görüntüleri (G5): izin penceresi ekranın üstüne binmesin
            if CommandLine.arguments.contains("-izinSorma") { return false }
            #endif
            guard sor else { return false }
            return (try? await merkez.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default: return false
        }
    }

    /// Sitenin `Notification.requestPermission()`'ı ("Simge rozeti"ni açarken)
    func izinIste() async -> String {
        await izinVar(sor: true) ? "granted" : "denied"
    }

    /// Sitenin `navigator.setAppBadge(n)` / `clearAppBadge()`'i
    func rozet(_ n: Int) {
        Task {
            if n > 0 {
                let izin = await izinVar(sor: true)
                guard izin else { return }
            }
            try? await merkez.setBadgeCount(max(0, n))
        }
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Bildirime dokununca Çalış sekmesi açılır.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let adres = response.notification.request.content.userInfo["adres"] as? String
        Task { @MainActor in
            if let adres { Gezgin.shared.git(adres) }
            completionHandler()
        }
    }

    /// Uygulama açıkken gelen hatırlatma gösterilmez (zaten içindesin).
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }
}

/// Sitenin içinde bir sayfaya gitmek (widget'a ya da bildirime dokununca).
@MainActor
final class Gezgin {
    static let shared = Gezgin()

    weak var webView: WKWebView?
    /// Site henüz yüklenmediyse yüklenince gidilecek adres
    private(set) var bekleyen: String?
    var yuklendi = false

    /// adres: "#/", "#/pekistir" … Hedef sekme Swift'e taşındıysa orada açılır (Kabuk, T3).
    func git(_ adres: String) {
        guard adres.hasPrefix("#/") else { return }
        if KabukDurumu.shared.yerliyeGit(adres) { return }
        if yuklendi, let w = webView {
            let js = "location.hash = \(Self.jsDizge(adres));"
            w.evaluateJavaScript(js, completionHandler: nil)
        } else {
            bekleyen = adres
        }
    }

    /// Sitenin kendi sekme düğmesine basar (kullanıcı dokunmuş gibi); çubuk gizliyse sekmenin ana sayfasına gider.
    /// `onceki`: yerli çubukta seçili sekmenin sırası; sitenin hapı oradan kayar. `bas` false: site zaten o sekmede,
    /// yalnız hap kayar (`Gecis.sekmeyeGecBetigi`).
    func sekmeyeGec(_ s: Sekme, onceki: Int? = nil, bas: Bool = true) {
        guard let kimlik = s.siteKimligi, yuklendi, let w = webView else {
            if bas { git(s.kokAdres) }
            return
        }
        let arguman: [String: Any] = ["kimlik": kimlik, "adres": s.kokAdres, "bas": bas,
                                      "onceki": onceki.map { $0 as Any } ?? NSNull()]
        w.callAsyncJavaScript(Gecis.sekmeyeGecBetigi, arguments: arguman, in: nil, in: .page, completionHandler: nil)
    }

    func yuklemeBitti() {
        yuklendi = true
        Task { await ElleOdaklar.sitedenAl() }   // Z2c-3: site kalkmadan önce cihazdaki elle odaklar
        KabukDurumu.shared.rozetiYenile()
        if let b = bekleyen {
            bekleyen = nil
            git(b)
        }
    }

    /// norasanat://bugun → Bugün (Tuval), norasanat://calis → Çalış
    func ac(_ url: URL) {
        guard url.scheme == "norasanat" else { return }
        switch url.host {
        case "calis": git("#/pekistir")
        default: git("#/")
        }
    }

    static func jsDizge(_ s: String) -> String {
        let veri = (try? JSONSerialization.data(withJSONObject: [s])) ?? Data("[\"\"]".utf8)
        return String(decoding: veri, as: UTF8.self) + "[0]"
    }
}

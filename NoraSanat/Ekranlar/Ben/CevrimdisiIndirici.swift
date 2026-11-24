// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (devasaIndir, devasaSurdur, devasaSil, durdurma), js/devasaOnbellek.js
// @ a866b86 (site 1.90.3). Kurallar (liste, parçalar, yazılar, dosya deposu): NoraCekirdek/Cevrimdisi.
import NoraCekirdek
import SwiftUI
import UIKit

/// "En büyük kopyaları telefona indir" (C5): görseller Swift'te, arka plan `URLSession`'ıyla iner.
///
/// Sitedeki gibi parça parça (~0,7 GB ya da 1000 dosya): bir parçanın bütün dosyaları birden arka plan oturumuna verilir,
/// parça bitince sıradaki başlar. Arka plan oturumu uygulama arka plandayken ve iOS onu kapatınca da indirmeyi sürdürür;
/// iş bitince uygulamayı uyandırır (`handleEventsForBackgroundURLSession`), sıradaki parça orada verilir. Kullanıcı
/// uygulamayı kaydırıp kapatırsa iOS görevleri iptal eder: bir dahaki açılışta kaldığı yerden sürer (sitenin
/// `devasaSurdur`'u).
///
/// İnen dosyalar `CevrimdisiDepo`'da (Application Support). `GorselDeposu` bir adresi önce orada arar.
@MainActor @Observable
final class CevrimdisiIndirici {
    static let shared = CevrimdisiIndirici()
    static let oturumKimligi = "com.emrymn.norasanat.cevrimdisi"

    let depo = CevrimdisiDepo.varsayilan
    /// İndirme listesi (katalogdan; son hesaplanan diske de yazılır, arka planda uyanınca oradan okunur)
    private(set) var liste: CevrimdisiListe?
    /// Listedekilerden telefonda olanlar
    private(set) var telefonda = 0
    /// Bu açılıştaki (ya da sürmekte olan) parça
    private(set) var durum: CevrimdisiDurumu?
    /// "Telefondan sil"den sonra
    private(set) var silindi = false

    @ObservationIgnored private var oturum: URLSession!
    /// Arka plan aktarım servisi çalışmazsa (simülatörde `NSURLErrorUnknown`) uygulama içi oturum; o açılış boyunca
    /// bununla iner, uygulama arka plana geçince iOS'tan biraz süre istenir
    @ObservationIgnored private var onPlan: URLSession!
    @ObservationIgnored private var arkaPlanYok = false
    @ObservationIgnored private var sureIstegi: UIBackgroundTaskIdentifier = .invalid
    @ObservationIgnored private let temsilci = Temsilci()
    @ObservationIgnored private var bekleyen = Set<String>()
    /// Görev listesi gelmeden sonucu gelenler (arka planda yeniden açılışta)
    @ObservationIgnored private var erkenBiten = Set<String>()
    @ObservationIgnored private var durdurIstendi = false
    /// Z3s: parça arka planda hazırlanıyor (telefondakilerin sayımı ana iş parçacığında değil)
    @ObservationIgnored private var hazirlaniyor = false
    @ObservationIgnored private var kuruldu = false
    @ObservationIgnored var arkaPlanBitti: (() -> Void)?

    #if DEBUG
    /// CI: `-cevrimdisiParca 2` küçük parça (sitenin `__atlasParca`'sı); yalnız bir parça iner, sürdürülmez
    static let denemeParcasi = NoraSanatApp.arguman("-cevrimdisiParca").flatMap(Int.init)
    #else
    static let denemeParcasi: Int? = nil
    #endif

    private static let surdurAnahtari = "cevrimdisi.surdur"
    private static let durumAnahtari = "cevrimdisi.durum"
    private var listeDosyasi: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CevrimdisiListe.json")
    }
    /// Başlatılan indirme bitmedi: uygulama kapanıp açılınca sürer (sitenin `sanat-atlasi:devasa-surdur`'u)
    private var surdur: Bool {
        get { UserDefaults.standard.bool(forKey: Self.surdurAnahtari) }
        set { UserDefaults.standard.set(newValue, forKey: Self.surdurAnahtari) }
    }

    /// Uygulama açılışında (ve arka planda uyanınca) çağrılır: oturumu yeniden kurar, yarım kalan indirmeyi sürdürür.
    func baslat() {
        guard !kuruldu else { return }
        kuruldu = true
        let ayar = URLSessionConfiguration.background(withIdentifier: Self.oturumKimligi)
        ayar.isDiscretionary = false
        ayar.sessionSendsLaunchEvents = true
        ayar.httpMaximumConnectionsPerHost = 3          // sitede üç görsel birden (İş 125)
        ayar.timeoutIntervalForRequest = 90             // İş 135: en büyük kopyalar 3–5 MB
        ayar.urlCache = nil
        temsilci.sahip = self
        oturum = URLSession(configuration: ayar, delegate: temsilci, delegateQueue: nil)
        let onAyar = URLSessionConfiguration.default
        onAyar.httpMaximumConnectionsPerHost = 3
        onAyar.timeoutIntervalForRequest = 90
        onAyar.urlCache = nil
        onPlan = URLSession(configuration: onAyar, delegate: temsilci, delegateQueue: nil)
        temsilci.arkaPlanOturumu = oturum
        // Sitede durum yalnız o açılışta durur: biten ya da durdurulan eski parçanın iletisi yeni açılışta görünmez
        if let d = UserDefaults.standard.data(forKey: Self.durumAnahtari),
           let x = try? JSONDecoder().decode(CevrimdisiDurumu.self, from: d), x.suruyor || surdur {
            durum = x
        }
        if liste == nil, let d = try? Data(contentsOf: listeDosyasi) {
            liste = try? JSONDecoder().decode(CevrimdisiListe.self, from: d)
        }
        oturum.getAllTasks { gorevler in
            let suren = Set(gorevler.filter { $0.state == .running || $0.state == .suspended }.compactMap(\.taskDescription))
            Task { @MainActor in
                self.bekleyen = suren.subtracting(self.erkenBiten)
                self.erkenBiten = []
                if suren.isEmpty, self.surdur { self.parcaBaslat() }   // kapanmadan önce başlamıştı
                else if suren.isEmpty, self.durum?.bitti == false { self.parcaBitti() }
            }
        }
        siteIndirmesiniDurdur()
    }

    /// Ayarlar açılınca: listeyi güncel katalogdan kurar ve telefondakileri sayar
    func hazirla(_ katalog: SiteKatalogu) async {
        let yeni = await Task.detached(priority: .userInitiated) { CevrimdisiListe(katalog: katalog) }.value
        if yeni != liste {
            liste = yeni
            let dosya = listeDosyasi
            Task.detached(priority: .utility) { try? JSONEncoder().encode(yeni).write(to: dosya, options: .atomic) }
        }
        await say()
    }

    /// Listedekilerden telefonda olanları sayar; listede olmayan eski dosyaları siler (`telefondakiler`)
    func say() async {
        guard let l = liste else { return }
        let depo = depo
        let suren = durum?.suruyor ?? false
        telefonda = await Task.detached(priority: .utility) {
            depo.telefondakiler(l.telefonAdresleri, sil: l.suzuldu && !suren).adresler.count
        }.value
    }

    var gorunum: CevrimdisiGorunum? {
        liste.map { CevrimdisiGorunum(liste: $0, telefonda: telefonda, durum: durum) }
    }

    // MARK: Düğmeler

    func indir() {
        guard liste != nil, durum?.suruyor != true, !hazirlaniyor else { return }
        silindi = false
        surdur = true
        parcaBaslat()
    }

    func durdur() {
        if hazirlaniyor { durdurIstendi = true; surdur = false; return }   // parça daha başlamadı: başlamasın
        guard durum?.suruyor == true else { return }
        durdurIstendi = true
        surdur = false
        hepsiniIptalEt()
        if bekleyen.isEmpty { parcaBitti() }
    }

    func sil() async {
        surdur = false
        durdurIstendi = true
        hepsiniIptalEt()
        bekleyen = []
        sureyiBitir()
        durum = nil
        kaydet()
        let depo = depo
        await Task.detached(priority: .userInitiated) { depo.temizle() }.value
        siteDeposunuSil()
        telefonda = 0
        silindi = true
        durdurIstendi = false
    }

    // MARK: Parçalar

    private func parcaBaslat() {
        guard let l = liste, !hazirlaniyor else { if liste == nil { surdur = false }; return }
        durdurIstendi = false
        hazirlaniyor = true
        // Z3s: telefondaki binlerce dosyanın sayımı ve parçanın hesabı arka planda (önceden ana iş parçacığındaydı:
        // her parça başında ve durdurunca ekran donuyordu)
        let depo = depo
        let boy = Self.denemeParcasi ?? CevrimdisiListe.parcaGorsel
        // Arka planda uyandırılmışken (önceki parça bitti) iOS hazırlık bitmeden uygulamayı uyutmasın
        let sure = UIApplication.shared.beginBackgroundTask(withName: "cevrimdisi-hazirla", expirationHandler: nil)
        Task {
            defer { if sure != .invalid { UIApplication.shared.endBackgroundTask(sure) } }
            let (var_, p) = await Task.detached(priority: .utility) { () -> (Set<String>, CevrimdisiListe.Parca) in
                let v = depo.telefondakiler(l.telefonAdresleri, sil: false).adresler
                return (v, l.parca(telefonda: v, parcaGorsel: boy))
            }.value
            hazirlaniyor = false
            if durdurIstendi { durdurIstendi = false; return }
            parcayiVer(p, telefondaki: var_.count)
        }
    }

    private func parcayiVer(_ p: CevrimdisiListe.Parca, telefondaki: Int) {
        var i = CevrimdisiDurumu(p)
        telefonda = telefondaki
        guard !p.urller.isEmpty else {
            i.bitir(durduruldu: false)
            durum = i
            surdur = false
            kaydet()
            return
        }
        durum = i
        kaydet()
        try? depo.hazirla()
        bekleyen = Set(p.urller)
        for u in p.urller {
            guard let url = URL(string: u) else { bekleyen.remove(u); continue }
            var istek = URLRequest(url: url)
            istek.cachePolicy = .reloadIgnoringLocalCacheData   // `cache: 'no-store'`
            gorevVer(u, istek)
        }
    }

    private func gorevVer(_ u: String, _ istek: URLRequest) {
        let g = (arkaPlanYok ? onPlan : oturum).downloadTask(with: istek)
        g.taskDescription = u
        g.resume()
        if arkaPlanYok && sureIstegi == .invalid {
            sureIstegi = UIApplication.shared.beginBackgroundTask(withName: "cevrimdisi") { [weak self] in
                MainActor.assumeIsolated { self?.sureyiBitir() }
            }
        }
    }

    private func sureyiBitir() {
        guard sureIstegi != .invalid else { return }
        UIApplication.shared.endBackgroundTask(sureIstegi)
        sureIstegi = .invalid
    }

    private func hepsiniIptalEt() {
        oturum.getAllTasks { $0.forEach { $0.cancel() } }
        onPlan.getAllTasks { $0.forEach { $0.cancel() } }
    }

    enum Sonuc: Sendable {
        case indi, hata(String), yerYok(String), yazilamadi(String), kesildi
        /// Arka plan aktarım servisi hatası: uygulama içi oturumla yeniden denenir
        case yeniden
        var inmis: Bool {
            switch self { case .kesildi, .yeniden: return false; default: return true }
        }
    }

    /// Bir dosyanın sonucu (temsilciden)
    fileprivate func sonuc(_ adres: String, _ s: Sonuc) {
        if case .yeniden = s {
            guard bekleyen.contains(adres), durum?.suruyor == true, !durdurIstendi, let url = URL(string: adres) else { return }
            arkaPlanYok = true
            var istek = URLRequest(url: url)
            istek.cachePolicy = .reloadIgnoringLocalCacheData
            gorevVer(adres, istek)
            return
        }
        guard bekleyen.remove(adres) != nil else {
            if s.inmis { erkenBiten.insert(adres) }
            return
        }
        guard var i = durum, i.suruyor else { return }
        switch s {
        case .kesildi, .yeniden:
            break   // durdurulunca kesilen istek hata da inen de sayılmaz
        case .indi:
            i.biten += 1
            i.bitenBayt += liste?.tahminiBayt(adres) ?? 0
            telefonda += 1
        case let .hata(m):
            i.biten += 1
            i.hata += 1
            if i.yazilamadi == 0 { i.sonHata = m }   // ileti yalnız kaydedilemeyince gösterir; tanı için saklanır
            i.bitenBayt += liste?.tahminiBayt(adres) ?? 0
        case let .yerYok(m):
            i.biten += 1
            i.bitenBayt += liste?.tahminiBayt(adres) ?? 0
            i.yerYok = true
            i.yazilamadi += 1
            i.sonHata = m
            hepsiniIptalEt()
        case let .yazilamadi(m):
            i.biten += 1
            i.bitenBayt += liste?.tahminiBayt(adres) ?? 0
            i.hata += 1
            i.yazilamadi += 1
            i.sonHata = m
        }
        durum = i
        if bekleyen.isEmpty { parcaBitti() } else if i.biten % 10 == 0 { kaydet() }
    }

    private func parcaBitti() {
        guard var i = durum, i.suruyor else { return }
        defer { if bekleyen.isEmpty { sureyiBitir() } }
        i.bitir(durduruldu: durdurIstendi)
        durum = i
        // parça bitti, sıradaki parçalar var: sürer. Hiç görsel inemediyse (internet yok) durur
        if !i.parcaBitti || Self.denemeParcasi != nil { surdur = false }
        kaydet()
        if i.parcaBitti && Self.denemeParcasi == nil { parcaBaslat() } else { Task { await say() } }
    }

    private func kaydet() {
        let veri = durum.flatMap { try? JSONEncoder().encode($0) }
        UserDefaults.standard.set(veri, forKey: Self.durumAnahtari)
        #if DEBUG
        // CI: indirme denemesinin durumu (sayılar ve son hata)
        try? veri?.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("cevrimdisi-durum.json"))
        #endif
    }

    fileprivate func olaylarBitti() {
        arkaPlanBitti?()
        arkaPlanBitti = nil
    }

    // MARK: Site

    /// Eski yol: site görselleri kendisi (IndexedDB'ye) indiriyordu ve kapanınca kaldığı yerden sürdürüyordu. Artık
    /// indirme burada: sitenin sürdürme işareti kaldırılır, sürmekte olan site indirmesi durdurulur.
    static let siteIndirmesiniDurdurBetigi = """
    try { localStorage.removeItem('sanat-atlasi:devasa-surdur'); } catch {}
    const o = await import('/js/ekranlar/ortak.js');
    const i = o.d.devasaIndirme;
    if (i && !i.bitti) { i.durdur = true; for (const a of i.iptaller || []) a.abort(); }
    return !!i;
    """

    /// "Telefondan sil": sitenin eski indirdikleri de silinir (yer açılsın)
    static let siteDeposunuSilBetigi = """
    const D = await import('/js/devasaOnbellek.js');
    await D.kaliciSil();
    D.defterSil();
    for (const a of ['sanat-atlasi:devasa-surdur', 'sanat-atlasi:devasa-sayi']) try { localStorage.removeItem(a); } catch {}
    const o = await import('/js/ekranlar/ortak.js');
    o.d.devasaIndirme = null;
    return true;
    """

    private func siteBetigi(_ kaynak: String) {
        Task {
            for _ in 0..<120 {
                if Gezgin.shared.yuklendi, let w = Gezgin.shared.webView {
                    _ = try? await w.callAsyncJavaScript(kaynak, arguments: [:], in: nil, contentWorld: .page)
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func siteIndirmesiniDurdur() { siteBetigi(Self.siteIndirmesiniDurdurBetigi) }
    private func siteDeposunuSil() { siteBetigi(Self.siteDeposunuSilBetigi) }

    // MARK: Oturum temsilcisi

    /// `URLSession` olaylarını alır (kendi kuyruğunda); inen dosyayı hemen yerine taşır, sonucu ana iş parçacığına verir.
    private final class Temsilci: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
        weak var sahip: CevrimdisiIndirici?
        weak var arkaPlanOturumu: URLSession?
        private let kilit = NSLock()
        private var sonuclar: [Int: Sonuc] = [:]
        private let depo = CevrimdisiDepo.varsayilan

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            guard let adres = downloadTask.taskDescription else { return }
            let s: Sonuc
            let h = downloadTask.response as? HTTPURLResponse
            if let h, (200..<300).contains(h.statusCode),
               (h.value(forHTTPHeaderField: "Content-Type") ?? "").hasPrefix("image/") {
                do {
                    try depo.tasi(location, adres: adres)
                    s = .indi
                } catch {
                    let ns = error as NSError
                    let m = "\(ns.domain) \(ns.code): \(ns.localizedDescription)"
                    s = ns.domain == NSCocoaErrorDomain && ns.code == NSFileWriteOutOfSpaceError ? .yerYok(m) : .yazilamadi(m)
                }
            } else {
                s = .hata("yanıt \(h?.statusCode ?? -1) \(h?.value(forHTTPHeaderField: "Content-Type") ?? "-")")
            }
            kilit.lock(); sonuclar[downloadTask.taskIdentifier] = s; kilit.unlock()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let adres = task.taskDescription else { return }
            kilit.lock(); let kayitli = sonuclar.removeValue(forKey: task.taskIdentifier); kilit.unlock()
            let s: Sonuc
            if let kayitli { s = kayitli }
            else if let e = error as? URLError, e.code == .cancelled { s = .kesildi }
            else if session === arkaPlanOturumu, let e = error as? URLError,
                    [.unknown, .backgroundSessionWasDisconnected, .backgroundSessionInUseByAnotherProcess,
                     .backgroundSessionRequiresSharedContainer].contains(e.code) { s = .yeniden }
            else {
                let ns = error.map { $0 as NSError }
                s = .hata(ns.map { "\($0.domain) \($0.code): \($0.localizedDescription)" } ?? "dosya gelmedi")
            }
            Task { @MainActor in self.sahip?.sonuc(adres, s) }
        }

        func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            Task { @MainActor in self.sahip?.olaylarBitti() }
        }
    }
}

/// Arka plan oturumunun olayları için (uygulama arka planda uyandırılınca)
final class NoraSanatUygulamaTemsilcisi: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        CevrimdisiIndirici.shared.baslat()
        return true
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        guard identifier == CevrimdisiIndirici.oturumKimligi else { completionHandler(); return }
        CevrimdisiIndirici.shared.arkaPlanBitti = completionHandler
        CevrimdisiIndirici.shared.baslat()
    }
}

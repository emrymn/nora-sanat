// Y1 · Sesli rehberli bakış: akışı adım adım yürütür; kilit ekranı ve kulaklık denetimleri, Now Playing (sitede karşılığı yok).
// Z4a: kaydı olan parça doğal sesle (Gemini "Fola", `DinleSesKaynagi`) çalınır, kelime kelime altyazı kaydın zamanlamasıyla
// (`AVAudioPlayer.currentTime`) akar; kaydı yoksa ya da inmediyse telefonun sesi okur (`willSpeakRange` ile).
import AVFoundation
import MediaPlayer
import NoraCekirdek
import UIKit

/// `DinlemePlani`'nı oynatır: her adımda kameranın hedefini verir, metni okur (ya da sessiz seçenekte altyazıyı tahmini
/// süre kadar tutar), sessizliği bekler. Süre yalnız oynarken işler.
@Observable @MainActor
final class DinleOynatici {
    enum Durum: Equatable { case oynuyor, duraklatildi, bitti }
    /// Adımda kim konuşuyor
    enum Konusan: Equatable { case yok, kayit, sentez }

    private(set) var plan: DinlemePlani
    private(set) var sesli: Bool
    private let baslik: String
    private let sanatci: String
    /// Künye ("Ad. Sanatçı, tarih."): notun kaydı var ama inmediyse telefon künye + notu okur (eski davranış)
    private let kunye: String
    /// Görsellerin R2 adresi (kayıtlar da orada)
    private let sesKoku: String
    var kapak: UIImage? { didSet { simdiCalan() } }

    private(set) var durum: Durum = .oynuyor
    private(set) var sira = 0
    private(set) var altyaziBaslik = ""
    private(set) var altyazi = ""
    /// Altyazının kelimeleri ve zamanlaması
    private(set) var akis: AltyaziAkisi?
    private(set) var konusan: Konusan = .yok
    /// Kameranın hedefi (nil: tablonun tamamı) ve her yeni hedefte artan sayaç
    private(set) var kamera: DinlemeKutusu?
    private(set) var kameraSayac = 0
    /// Z4c: dinleme hızı (1, 1,5, 2): kayıt ve telefonun sesi bu hızda okur, aralar ve kamera saati de bu hızda işler
    private(set) var hiz = 1.0

    @ObservationIgnored private let ses = DinleSesi()
    @ObservationIgnored private var akisIsi: Task<Void, Never>?
    @ObservationIgnored private var saatIsi: Task<Void, Never>?
    @ObservationIgnored private var indirmeIsi: Task<Void, Never>?
    /// Adımın başından beri oynayarak geçen süre (duraklatılan süre sayılmaz)
    @ObservationIgnored private var adimGecen = 0.0
    /// Sessiz seçenekte sözün (altyazının) başladığı an
    @ObservationIgnored private var konusmaBasi = 0.0
    @ObservationIgnored private var sozBitti = false
    @ObservationIgnored private var komutlar: [(MPRemoteCommand, Any)] = []
    @ObservationIgnored private var kesinti: NSObjectProtocol?

    init(plan: DinlemePlani, sesli: Bool, baslik: String, sanatci: String, kunye: String, sesKoku: String,
         kapak: UIImage?) {
        self.plan = plan
        self.sesli = sesli
        self.baslik = baslik
        self.sanatci = sanatci
        self.kunye = kunye
        self.sesKoku = sesKoku
        self.kapak = kapak
    }

    var adimSayisi: Int { plan.adimlar.count }
    var simdikiAdim: DinlemeAdimi? { plan.adimlar.indices.contains(sira) ? plan.adimlar[sira] : nil }

    func baslat(adim: Int = 0) {
        // Z4b: hikâye çalıyorsa iki ses üst üste binmesin; hikâyenin yeri kaydedilir, kilit ekranı komutları bırakılır
        if sesli { HikayeCalari.shared.kapat(); sesiAc() }
        saatIsi?.cancel()
        saatIsi = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                if self.durum == .oynuyor { self.adimGecen += 0.1 * self.hiz }
            }
        }
        kayitlariIndir()
        git(adim)
    }

    func kapat() {
        akisIsi?.cancel()
        saatIsi?.cancel()
        indirmeIsi?.cancel()
        akisIsi = nil
        saatIsi = nil
        sesiKapat()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func duraklat() {
        guard durum == .oynuyor else { return }
        durum = .duraklatildi
        ses.duraklat()
        simdiCalan()
    }

    func surdur() {
        switch durum {
        case .duraklatildi:
            durum = .oynuyor
            if sesli { try? AVAudioSession.sharedInstance().setActive(true) }
            ses.surdur()
            simdiCalan()
        case .bitti:
            git(0)
        case .oynuyor:
            break
        }
    }

    func degistir() { durum == .oynuyor ? duraklat() : surdur() }

    func sonraki() {
        guard durum != .bitti else { return }
        git(sira + 1)
    }

    /// Adımın başındaysa bir öncekine, değilse bu adımın başına
    func onceki() {
        git(adimGecen > 3 || sira == 0 ? sira : sira - 1)
    }

    /// Adım şeridinden: o adıma git
    func adimaGit(_ i: Int) {
        git(min(max(0, i), plan.adimlar.count - 1))
    }

    /// Süre değişti: yeni plan, aynı sıradaki adımdan sürer
    func planiDegistir(_ yeni: DinlemePlani) {
        guard yeni != plan, !yeni.adimlar.isEmpty else { return }
        plan = yeni
        kayitlariIndir()
        if durum != .bitti { git(min(sira, yeni.adimlar.count - 1)) }
    }

    /// Z4c: hız değişti; çalan kayıt hemen yeni hızda sürer, telefonun sesi sonraki sözden itibaren
    func hiziDegistir(_ yeni: Double) {
        let h = min(2, max(0.5, yeni))
        guard abs(h - hiz) > 0.001 else { return }
        hiz = h
        ses.hiz = h
        simdiCalan()
    }

    /// Ses ↔ yalnız altyazı: adım baştan, yeni seçenekle
    func sesiDegistir(_ yeni: Bool) {
        guard yeni != sesli else { return }
        sesli = yeni
        if yeni { sesiAc() } else { sesiKapat() }
        if durum != .bitti { git(sira) }
    }

    /// Adımın ilerlemesi (0–1), ray için
    func ilerleme() -> Double {
        guard let a = simdikiAdim, durum != .bitti else { return durum == .bitti ? 1 : 0 }
        return min(1, adimGecen / max(1, a.sure))
    }

    /// Kalan süre (sn)
    func kalan() -> Double {
        guard durum != .bitti else { return 0 }
        return max(0, plan.toplam - plan.baslangic(sira) - adimGecen)
    }

    /// Şu an söylenen kelimenin sırası (altyazının kelime kelime aydınlanması). Söz bittiyse hepsi söylenmiş sayılır.
    func kelimeSirasi() -> Int {
        guard let a = akis else { return -1 }
        if sozBitti { return a.kelimeler.count }
        switch konusan {
        case .kayit:
            if let t = ses.kayitAni { return a.kelime(sn: t) }
        case .sentez:
            if let k = ses.sozKonumu { return a.kelime(utf16: k) }
        case .yok:
            break
        }
        return a.kelime(sn: adimGecen - konusmaBasi)
    }

    private func git(_ i: Int) {
        akisIsi?.cancel()
        ses.durdur()
        if durum != .oynuyor {
            durum = .oynuyor
            ses.surdur()
        }
        akisIsi = Task { [weak self] in await self?.yurut(i) }
    }

    private func yurut(_ ilk: Int) async {
        var i = ilk
        while i < plan.adimlar.count {
            guard !Task.isCancelled else { return }
            await adim(i)
            guard !Task.isCancelled else { return }
            i += 1
        }
        bitir()
    }

    private func adim(_ i: Int) async {
        let a = plan.adimlar[i]
        sira = i
        adimGecen = 0
        kamera = a.kutu
        kameraSayac += 1
        altyaziBaslik = ""
        altyazi = ""
        akis = nil
        konusan = .yok
        sozBitti = false
        simdiCalan()

        await bekle(a.gecikme)
        guard !Task.isCancelled else { return }
        altyaziBaslik = a.baslik
        if sesli, a.tur != .sessiz, !a.metin.isEmpty {
            var calindi = false
            if let k = a.kayit, let kayit = await DinleSesKaynagi.shared.kayit(k, kok: sesKoku) {
                guard !Task.isCancelled else { return }
                await oynayanaKadar()
                guard !Task.isCancelled else { return }
                let akis = kayit.akis ?? AltyaziAkisi(metin: a.metin, sure: a.konusma)
                self.akis = akis
                altyazi = akis.metin
                konusan = .kayit
                isaretle(i, "Fola")
                calindi = await ses.cal(kayit.mp3)
            }
            guard !Task.isCancelled else { return }
            if !calindi {
                // Kayıt yok ya da inmedi: telefonun sesi. Açılışta notun kaydı varsa adımın metni yalnız nottur;
                // telefon eskisi gibi künye + notu okur (iki ses karışmaz: bu adımda yalnız telefon konuşur).
                let metin = a.tur == .acilis && a.kayit != nil && !kunye.isEmpty ? kunye + " " + a.metin : a.metin
                await oynayanaKadar()
                guard !Task.isCancelled else { return }
                akis = AltyaziAkisi(metin: metin, sure: DinlemeKurallari.okumaSuresi(metin))
                altyazi = metin
                konusan = .sentez
                isaretle(i, "AVSpeech")
                await ses.oku(metin)
            }
            // Duraklatılan söz sürdürülene kadar bekler; okuma bitince süre zaten işlemiş olur
        } else {
            akis = AltyaziAkisi(metin: a.metin, sure: a.konusma)
            altyazi = a.metin
            konusmaBasi = adimGecen
            konusan = .yok
            if sesli == false { isaretle(i, "yok") }
            await bekle(a.konusma)
        }
        guard !Task.isCancelled else { return }
        sozBitti = true
        // Kamera yerine varsın, sonra kısa sessizlik
        await bekle(max(0, a.yaklasma - adimGecen))
        guard !Task.isCancelled else { return }
        if sesli, a.tur != .sessiz {
            altyazi = ""
            altyaziBaslik = ""
            akis = nil
        }
        await bekle(a.sessizlik)
    }

    /// Yalnız oynarken işleyen bekleme
    private func bekle(_ sure: Double) async {
        guard sure > 0 else { return }
        let hedef = adimGecen + sure
        while adimGecen < hedef - 0.001 {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Duraklatılmışsa sürdürülene kadar (kayıt inerken duraklatılırsa ses kendiliğinden başlamasın)
    private func oynayanaKadar() async {
        while durum != .oynuyor, !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    func bitir() {
        akisIsi?.cancel()
        durum = .bitti
        sira = plan.adimlar.count - 1
        altyaziBaslik = ""
        altyazi = ""
        akis = nil
        kamera = nil
        kameraSayac += 1
        ses.durdur()
        simdiCalan()
    }

    // MARK: - Ses oturumu ve kayıtlar

    private func sesiAc() {
        ses.oturumuAc()
        komutlariKur()
        if kesinti == nil {
            kesinti = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
            ) { [weak self] n in
                let tur = (n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                    .flatMap(AVAudioSession.InterruptionType.init(rawValue:))
                Task { @MainActor in if tur == .began { self?.duraklat() } }
            }
        }
    }

    private func sesiKapat() {
        ses.oturumuKapat()
        for (komut, hedef) in komutlar { komut.removeTarget(hedef) }
        komutlar = []
        if let kesinti { NotificationCenter.default.removeObserver(kesinti) }
        kesinti = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Planın bütün kayıtları arka planda iner (diskte olanlar inmez)
    private func kayitlariIndir() {
        let anahtarlar = plan.adimlar.compactMap(\.kayit)
        guard !anahtarlar.isEmpty else { return }
        let kok = sesKoku
        indirmeIsi?.cancel()
        indirmeIsi = Task.detached(priority: .utility) {
            await DinleSesKaynagi.shared.hazirla(anahtarlar, kok: kok)
        }
    }

    /// DEBUG/CI: hangi sesin konuştuğu `tmp/dinle-ses`'e yazılır (R2'ye ulaşılamayınca AVSpeech'e dönüş sınanır)
    private func isaretle(_ i: Int, _ kim: String) {
        #if DEBUG
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("dinle-ses")
        let satir = "adim \(i) \(plan.adimlar[i].tur.rawValue): \(kim)\(plan.adimlar[i].kayit.map { " (kayit \($0))" } ?? "")\n"
        let eski = (try? String(contentsOf: u, encoding: .utf8)) ?? ""
        try? (eski + satir).write(to: u, atomically: true, encoding: .utf8)
        #endif
    }

    // MARK: - Kilit ekranı, kulaklık, Now Playing

    private func komutlariKur() {
        guard komutlar.isEmpty else { return }
        let m = MPRemoteCommandCenter.shared()
        func ekle(_ komut: MPRemoteCommand, _ yap: @escaping @MainActor (DinleOynatici) -> Void) {
            komut.isEnabled = true
            let hedef = komut.addTarget { [weak self] _ in
                Task { @MainActor in if let self { yap(self) } }
                return .success
            }
            komutlar.append((komut, hedef))
        }
        ekle(m.playCommand) { $0.surdur() }
        ekle(m.pauseCommand) { $0.duraklat() }
        ekle(m.togglePlayPauseCommand) { $0.degistir() }
        ekle(m.nextTrackCommand) { $0.sonraki() }
        ekle(m.previousTrackCommand) { $0.onceki() }
    }

    private func simdiCalan() {
        guard sesli, saatIsi != nil else { return }
        var bilgi: [String: Any] = [
            MPMediaItemPropertyTitle: baslik,
            MPMediaItemPropertyArtist: sanatci,
            MPMediaItemPropertyAlbumTitle: "Dinleyerek bak",
            MPMediaItemPropertyPlaybackDuration: plan.toplam,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: min(plan.toplam, plan.baslangic(sira) + adimGecen),
            MPNowPlayingInfoPropertyPlaybackRate: durum == .oynuyor ? hiz : 0.0,
            MPNowPlayingInfoPropertyChapterNumber: sira,
            MPNowPlayingInfoPropertyChapterCount: plan.adimlar.count,
        ]
        if let kapak { bilgi[MPMediaItemPropertyArtwork] = Self.sanat(kapak) }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = bilgi
    }

    /// Kilit ekranındaki resim: istek arka planda gelebilir, kapanış ana aktöre bağlı olmasın
    nonisolated private static func sanat(_ r: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: r.size) { _ in r }
    }
}

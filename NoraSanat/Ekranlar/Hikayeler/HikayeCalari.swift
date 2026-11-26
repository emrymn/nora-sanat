// Z4b · Hikâyeleri dinleme (yeni; sitede yok). Parçalar ve anahtarlar Z4a'nın sözleşmesiyle (`HikayeSesi.parcalar`,
// sanat-atlasi scripts/ses_uret.py `hikaye_parcalari`): kaydı olan parça doğal sesle (Gemini "Fola", `DinleSesKaynagi`),
// kaydı yoksa ya da inmediyse telefonun sesiyle (`DinleSesi.oku`, Z4a'daki gibi). Çalar uygulamanın tamamında tektir:
// okuma ekranında altta ince çalar, başka sekmede küçük çalar (`HikayeMiniCalar`), kilit ekranında Now Playing.
import AVFoundation
import MediaPlayer
import NoraCekirdek
import UIKit

@MainActor
@Observable
final class HikayeCalari {
    static let shared = HikayeCalari()

    /// Çalınan (ya da duraklatılmış) yazı; nil: çalar kapalı
    private(set) var hikaye: SanatciHikayesi?
    private(set) var parcalar: [HikayeParcasi] = []
    private(set) var sureler: [Double] = []
    /// Şu anki parça ve parçanın içindeki an (sn; ekranda saniyede dört kez güncellenir)
    private(set) var sira = 0
    private(set) var an = 0.0
    private(set) var caliyor = false
    private(set) var bitti = false
    private(set) var hiz = 1.0
    /// Küçük çalardaki ve kilit ekranındaki kapak
    var kapak: UIImage? { didSet { simdiCalan() } }

    /// Okunan paragraf (vurgu ve ekranın izlediği yer); başlık okunurken nil
    var paragraf: Int? { HikayeSesi.paragraf(parca: sira, parcalar) }
    var toplam: Double { sureler.reduce(0, +) }
    var gecen: Double { HikayeSesi.gecen(sureler, sira: sira, an: an) }
    var acik: Bool { hikaye != nil }

    /// Şu an okunan parçanın bölümünün başlığı (çaların üstündeki yazı)
    var bolumBasligi: String {
        guard let h = hikaye else { return "" }
        if let p = paragraf { return h.bolum(paragraf: p).map { h.bolumler[$0].baslik } ?? (p < h.giris.count ? "Giriş" : "Kapanış") }
        if parcalar.indices.contains(sira), case .bolumBasligi(let b) = parcalar[sira].yer { return h.bolumler[b].baslik }
        return h.baslik
    }

    /// Okunan paragrafın metni (küçük çaların ikinci satırı)
    var paragrafMetni: String {
        guard parcalar.indices.contains(sira) else { return "" }
        return parcalar[sira].ham
    }

    @ObservationIgnored private let ses = DinleSesi()
    @ObservationIgnored private var akisIsi: Task<Void, Never>?
    @ObservationIgnored private var saatIsi: Task<Void, Never>?
    @ObservationIgnored private var indirmeIsi: Task<Void, Never>?
    @ObservationIgnored private var komutlar: [(MPRemoteCommand, Any)] = []
    @ObservationIgnored private var kesinti: NSObjectProtocol?
    /// Telefonun sesiyle okunan metnin başladığı an (parçanın ortasından başlanınca) ve tahmini akışı
    @ObservationIgnored private var sentezBasi = 0.0
    @ObservationIgnored private var sentezAkisi: AltyaziAkisi?
    @ObservationIgnored private var sonKayit = Date.distantPast
    @ObservationIgnored private var dizin: SesDizini?
    @ObservationIgnored private var kok = ""

    private init() {}

    // MARK: Başlat / bitir

    /// Yazıyı dinlemeye başlar: kalınan yerden ya da `paragraf`tan (o paragrafa dokunulunca). Aynı yazı çalıyorsa
    /// yalnız yer değişir.
    func baslat(_ h: SanatciHikayesi, paragraf: Int? = nil, oynat: Bool = true) {
        let depo = HikayeDeposu.shared
        if hikaye?.id != h.id {
            kapat()
            hikaye = h
            dizin = depo.dizin
            kok = depo.katalog?.gorsel.adres ?? ""
            parcalar = HikayeSesi.parcalar(h)
            sureler = HikayeSesi.sureler(parcalar, dizin: dizin)
            bitti = false
            kapak = nil
            kayitlariIndir()
            komutlariKur()
            let y = depo.yer(h.id)
            sira = min(max(0, y?.parca ?? 0), max(0, parcalar.count - 1))
            an = y?.parca == nil ? 0 : max(0, y?.an ?? 0)
            Task { await kapagiYukle(h) }
        }
        if let p = paragraf, let i = HikayeSesi.parca(paragraf: p, parcalar) {
            sira = i
            an = 0
        }
        if oynat { calmaya(sira, an) } else { simdiCalan() }
    }

    /// Çaları kapatır (yer kaydedilir)
    func kapat() {
        guard hikaye != nil else { return }
        yeriKaydet()
        akisIsi?.cancel()
        saatIsi?.cancel()
        indirmeIsi?.cancel()
        akisIsi = nil
        saatIsi = nil
        ses.oturumuKapat()
        for (komut, hedef) in komutlar { komut.removeTarget(hedef) }
        komutlar = []
        if let kesinti { NotificationCenter.default.removeObserver(kesinti) }
        kesinti = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        caliyor = false
        bitti = false
        hikaye = nil
        parcalar = []
        sureler = []
        sira = 0
        an = 0
        kapak = nil
    }

    // MARK: Denetimler

    func degistir() { caliyor ? duraklat() : surdur() }

    func duraklat() {
        guard caliyor else { return }
        caliyor = false
        ses.duraklat()
        anlikAn()
        yeriKaydet()
        simdiCalan()
    }

    func surdur() {
        guard hikaye != nil, !caliyor else { return }
        if bitti || akisIsi == nil {
            if bitti { sira = 0; an = 0; bitti = false }
            calmaya(sira, an)
            return
        }
        caliyor = true
        try? AVAudioSession.sharedInstance().setActive(true)
        ses.surdur()
        simdiCalan()
    }

    /// ±15 sn (parça sınırlarını aşar)
    func atla(_ fark: Double) {
        guard hikaye != nil else { return }
        anlikAn()
        let y = HikayeSesi.atla(sureler, sira: sira, an: an, fark: fark)
        let oynuyordu = caliyor
        sira = y.sira
        an = y.an
        bitti = false
        if oynuyordu { calmaya(sira, an) } else { akisIsi?.cancel(); akisIsi = nil; ses.durdur(); simdiCalan() }
    }

    /// Paragrafa dokununca: o paragraftan
    func paragrafaGit(_ p: Int) {
        guard let i = HikayeSesi.parca(paragraf: p, parcalar) else { return }
        sira = i
        an = 0
        bitti = false
        calmaya(sira, an)
    }

    func hiziDegistir() {
        hiz = HikayeSesi.sonrakiHiz(hiz)
        ses.hiz = hiz
        simdiCalan()
    }

    // MARK: Akış

    private func calmaya(_ bas: Int, _ basAn: Double) {
        guard hikaye != nil, !parcalar.isEmpty else { return }
        akisIsi?.cancel()
        ses.hiz = hiz
        sesiAc()
        caliyor = true
        bitti = false
        saatiKur()
        akisIsi = Task { [weak self] in
            // Eski akışın iptali sesi ana aktörde durdurur (`DinleSesi.cal` onCancel); yeni ses ondan sonra başlasın
            await Task.yield()
            if Task.isCancelled { return }
            var i = bas
            var a = basAn
            while let self, i < self.parcalar.count, !Task.isCancelled {
                self.sira = i
                self.an = a
                self.yeriKaydet()
                self.simdiCalan()
                await self.parcayiOku(i, bas: a)
                if Task.isCancelled { return }
                i += 1
                a = 0
            }
            guard let self, !Task.isCancelled else { return }
            self.caliyor = false
            self.bitti = true
            self.sira = max(0, self.parcalar.count - 1)
            self.an = self.sureler.last ?? 0
            self.akisIsi = nil
            if let h = self.hikaye {
                let d = HikayeDeposu.shared
                d.yerYaz(h.id, HikayeAkisi.dinlendi(d.yer(h.id), parca: self.sira, an: 0, paragraf: h.paragraflar.count - 1,
                                                    toplam: h.paragraflar.count, bitti: true))
            }
            Titresim.dogru()
            self.simdiCalan()
        }
    }

    /// Bir parçayı okur: kaydı varsa doğal sesle (inmemişse en çok 3 sn beklenir), yoksa telefonun sesiyle.
    private func parcayiOku(_ i: Int, bas: Double) async {
        let p = parcalar[i]
        sentezAkisi = nil
        if HikayeSesi.kayitli(p, dizin: dizin), let k = await DinleSesKaynagi.shared.kayit(p.anahtar, kok: kok) {
            // Kayıt inerken duraklatıldıysa sürdürülene kadar bekle
            await duraklatildiysaBekle()
            if Task.isCancelled { return }
            if await ses.cal(k.mp3, bas: bas) {
                isaretle(i, "Fola")
                return
            }
        }
        await duraklatildiysaBekle()
        if Task.isCancelled { return }
        isaretle(i, "AVSpeech")
        // Parçanın ortasından: o andaki kelimeden başlar (tahmini akış)
        let tahmin = AltyaziAkisi(metin: p.metin, sure: sureler[i])
        var metin = p.metin
        sentezBasi = 0
        if bas > 0.5, case let k = tahmin.kelime(sn: bas), k > 0, k < tahmin.kelimeler.count {
            let u = tahmin.kelimeler[k].utf16.lowerBound
            metin = String(decoding: Array(p.metin.utf16)[u...], as: UTF16.self)
            sentezBasi = tahmin.kelimeler[k].bas
        }
        sentezAkisi = AltyaziAkisi(metin: metin, sure: max(0.1, sureler[i] - sentezBasi))
        await ses.oku(metin)
    }

    /// Ses başlamadan duraklatıldıysa (ör. kayıt inerken) sürdürülene ya da akış iptal edilene kadar bekler
    private func duraklatildiysaBekle() async {
        while !caliyor, !Task.isCancelled { try? await Task.sleep(for: .milliseconds(200)) }
    }

    /// Ekrandaki an: kayıtta oynatıcının anı, telefonun sesinde söylenen kelimenin tahmini anı
    private func anlikAn() {
        guard parcalar.indices.contains(sira) else { return }
        if let k = ses.kayitAni {
            an = min(k, sureler[sira])
        } else if let s = ses.sozKonumu, let akis = sentezAkisi {
            let w = akis.kelime(utf16: s)
            if w >= 0 { an = min(sureler[sira], sentezBasi + akis.kelimeler[w].bas) }
        }
    }

    private func saatiKur() {
        guard saatIsi == nil else { return }
        saatIsi = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                guard self.caliyor else { continue }
                self.anlikAn()
                if Date().timeIntervalSince(self.sonKayit) > 5 { self.yeriKaydet() }
            }
        }
    }

    /// Okuma yerine dinlemenin yerini yazar (paragraf da ilerler)
    private func yeriKaydet() {
        guard let h = hikaye, !bitti else { return }
        sonKayit = Date()
        let d = HikayeDeposu.shared
        d.yerYaz(h.id, HikayeAkisi.dinlendi(d.yer(h.id), parca: sira, an: an, paragraf: paragraf,
                                            toplam: h.paragraflar.count))
    }

    // MARK: Ses oturumu, indirme, kilit ekranı

    private func sesiAc() {
        ses.oturumuAc()
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

    private func kayitlariIndir() {
        let anahtarlar = parcalar.filter { HikayeSesi.kayitli($0, dizin: dizin) }.map(\.anahtar)
        guard !anahtarlar.isEmpty, !kok.isEmpty else { return }
        let k = kok
        indirmeIsi?.cancel()
        indirmeIsi = Task.detached(priority: .utility) {
            await DinleSesKaynagi.shared.hazirla(anahtarlar, kok: k)
        }
    }

    private func kapagiYukle(_ h: SanatciHikayesi) async {
        guard let u = HikayeDeposu.shared.kucukAdres(h.kapakQid, sanatci: h.id, genislik: 640) else { return }
        let r = await GorselCozucu.shared.resim(u, piksel: 640)
        if hikaye?.id == h.id { kapak = r }
    }

    private func komutlariKur() {
        guard komutlar.isEmpty else { return }
        let m = MPRemoteCommandCenter.shared()
        func ekle(_ komut: MPRemoteCommand, _ yap: @escaping @MainActor (HikayeCalari) -> Void) {
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
        m.skipForwardCommand.preferredIntervals = [15]
        m.skipBackwardCommand.preferredIntervals = [15]
        ekle(m.skipForwardCommand) { $0.atla(15) }
        ekle(m.skipBackwardCommand) { $0.atla(-15) }
    }

    private func simdiCalan() {
        guard let h = hikaye else { return }
        var bilgi: [String: Any] = [
            MPMediaItemPropertyTitle: h.baslik,
            MPMediaItemPropertyArtist: HikayeDeposu.shared.sanatciAdi(h.id),
            MPMediaItemPropertyAlbumTitle: "Hikâyeler",
            MPMediaItemPropertyPlaybackDuration: toplam,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: gecen,
            MPNowPlayingInfoPropertyPlaybackRate: caliyor ? hiz : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
        ]
        if let kapak { bilgi[MPMediaItemPropertyArtwork] = Self.sanat(kapak) }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = bilgi
    }

    nonisolated private static func sanat(_ r: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: r.size) { _ in r }
    }

    /// DEBUG/CI: hangi sesin okuduğu `tmp/hikaye-ses`'e yazılır (Z4a'nın `dinle-ses`'i gibi)
    private func isaretle(_ i: Int, _ kim: String) {
        #if DEBUG
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("hikaye-ses")
        let satir = "parca \(i) \(parcalar[i].anahtar): \(kim)\n"
        let eski = (try? String(contentsOf: u, encoding: .utf8)) ?? ""
        try? (eski + satir).write(to: u, atomically: true, encoding: .utf8)
        #endif
    }
}

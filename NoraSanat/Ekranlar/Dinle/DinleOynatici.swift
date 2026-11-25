// Y1 · Sesli rehberli bakış: akışı adım adım yürütür; kilit ekranı ve kulaklık denetimleri, Now Playing (sitede karşılığı yok).
import AVFoundation
import MediaPlayer
import NoraCekirdek
import UIKit

/// `DinlemePlani`'nı oynatır: her adımda kameranın hedefini verir, metni okur (ya da sessiz seçenekte altyazıyı tahmini
/// süre kadar tutar), sessizliği bekler. Süre yalnız oynarken işler: duraklatınca kamera dışında her şey durur.
@Observable @MainActor
final class DinleOynatici {
    enum Durum: Equatable { case oynuyor, duraklatildi, bitti }

    let plan: DinlemePlani
    let sesli: Bool
    private let baslik: String
    private let sanatci: String
    var kapak: UIImage? { didSet { simdiCalan() } }

    private(set) var durum: Durum = .oynuyor
    private(set) var sira = 0
    private(set) var altyaziBaslik = ""
    private(set) var altyazi = ""
    /// Kameranın hedefi (nil: tablonun tamamı), varış süresi ve her yeni hedefte artan sayaç
    private(set) var kamera: DinlemeKutusu?
    private(set) var kameraSuresi = 0.0
    private(set) var kameraSayac = 0

    @ObservationIgnored private let ses = DinleSesi()
    @ObservationIgnored private var akisIsi: Task<Void, Never>?
    @ObservationIgnored private var saatIsi: Task<Void, Never>?
    /// Adımın başından beri oynayarak geçen süre (duraklatılan süre sayılmaz)
    @ObservationIgnored private var adimGecen = 0.0
    @ObservationIgnored private var komutlar: [(MPRemoteCommand, Any)] = []
    @ObservationIgnored private var kesinti: NSObjectProtocol?

    init(plan: DinlemePlani, sesli: Bool, baslik: String, sanatci: String, kapak: UIImage?) {
        self.plan = plan
        self.sesli = sesli
        self.baslik = baslik
        self.sanatci = sanatci
        self.kapak = kapak
    }

    var adimSayisi: Int { plan.adimlar.count }
    var simdikiAdim: DinlemeAdimi? { plan.adimlar.indices.contains(sira) ? plan.adimlar[sira] : nil }

    func baslat(adim: Int = 0) {
        if sesli {
            ses.oturumuAc()
            komutlariKur()
            kesinti = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
            ) { [weak self] n in
                let tur = (n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                    .flatMap(AVAudioSession.InterruptionType.init(rawValue:))
                Task { @MainActor in if tur == .began { self?.duraklat() } }
            }
        }
        saatIsi?.cancel()
        saatIsi = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                if self.durum == .oynuyor { self.adimGecen += 0.1 }
            }
        }
        git(adim)
    }

    func kapat() {
        akisIsi?.cancel()
        saatIsi?.cancel()
        akisIsi = nil
        saatIsi = nil
        if sesli { ses.oturumuKapat() }
        for (komut, hedef) in komutlar { komut.removeTarget(hedef) }
        komutlar = []
        if let kesinti { NotificationCenter.default.removeObserver(kesinti) }
        kesinti = nil
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

    /// Bitişte seçilen ayrıntıya yeniden bakmak için (söz yok)
    func bak(_ kutu: DinlemeKutusu?) {
        kamera = kutu
        kameraSuresi = 2.5
        kameraSayac += 1
    }

    private func git(_ i: Int) {
        akisIsi?.cancel()
        ses.durdur()
        if durum != .oynuyor {
            durum = .oynuyor
            ses.surdur()
        }
        akisIsi = Task { [weak self] in await self?.akis(i) }
    }

    private func akis(_ ilk: Int) async {
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
        kameraSuresi = a.yaklasma
        kameraSayac += 1
        altyaziBaslik = ""
        altyazi = ""
        simdiCalan()

        await bekle(a.gecikme)
        guard !Task.isCancelled else { return }
        altyaziBaslik = a.baslik
        altyazi = a.metin
        if sesli, a.tur != .sessiz, !a.metin.isEmpty {
            await ses.oku(a.metin)
            // Duraklatılan söz sürdürülene kadar bekler; okuma bitince süre zaten işlemiş olur
        } else {
            await bekle(a.konusma)
        }
        guard !Task.isCancelled else { return }
        // Kamera yerine varsın, sonra kısa sessizlik
        await bekle(max(0, a.yaklasma - adimGecen))
        guard !Task.isCancelled else { return }
        if sesli, a.tur != .sessiz { altyazi = "" ; altyaziBaslik = "" }
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

    private func bitir() {
        durum = .bitti
        sira = plan.adimlar.count - 1
        altyaziBaslik = ""
        altyazi = ""
        kamera = nil
        ses.durdur()
        simdiCalan()
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
            MPNowPlayingInfoPropertyPlaybackRate: durum == .oynuyor ? 1.0 : 0.0,
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

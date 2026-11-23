// Kaynak: sanat-atlasi js/kunye.js (oynatmaOturumu, sesDosyasi, sesSec, oku) @ a866b86
import AVFoundation
import NoraCekirdek

/// "Dinle" düğmeleri (Bugün'ün sonu, sanatçı künyesi) için tek ses: adın kaydı varsa o, yoksa telefonun o dildeki sesi.
/// Site gibi ses oturumu "oynatma" türündedir: sessiz moddayken de duyulur (önceden yerli düğmeler sessiz moddayken
/// hiç ses çıkarmıyordu). Aynı sanatçıya ikinci dokunuş durdurur.
@MainActor
final class AdOkuyucu {
    static let shared = AdOkuyucu()
    private let sentez = AVSpeechSynthesizer()
    private var oynatici: AVPlayer?
    private var calan: String?

    func oku(id: String, ad: String, kunye k: JSONDeger?) {
        // Aynı ad hâlâ çalıyorsa ikinci dokunuş durdurur; bitmişse yeniden okur
        let caliyor = calan == id && (sentez.isSpeaking || (oynatici?.rate ?? 0) > 0)
        durdur()
        if caliyor { return }
        oturumuAc()
        calan = id
        if let uzanti = GaleriKatalogu.sesUzantisi(k) {
            let url = SiteVerisi.site.appendingPathComponent("gorseller/ses/\(id).\(uzanti)")
            let p = AVPlayer(url: url)
            oynatici = p
            p.play()
        } else {
            let dil = k?["dil"]?.metin
            let soz = AVSpeechUtterance(string: GaleriKatalogu.okunacakAd(ad))
            soz.voice = Self.sesSec(dil)
            // sitenin u.rate = 0.85'i (Web'de 1 olağan hız; AVSpeech'te olağan hız 0.5)
            soz.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            sentez.speak(soz)
        }
    }

    func durdur() {
        oynatici?.pause()
        oynatici = nil
        if sentez.isSpeaking { sentez.stopSpeaking(at: .immediate) }
        calan = nil
    }

    /// iOS 17+ `navigator.audioSession.type = 'playback'`
    private func oturumuAc() {
        let o = AVAudioSession.sharedInstance()
        try? o.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? o.setActive(true)
    }

    /// `sesSec`: dil koduna ("nl") uyan ses ("nl-NL", "nl-BE"); önce telefonun dilindeki bölge, sonra daha kaliteli olan
    private static func sesSec(_ dil: String?) -> AVSpeechSynthesisVoice? {
        guard let dil = dil?.lowercased(), !dil.isEmpty else { return nil }
        let uyan = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().replacingOccurrences(of: "_", with: "-").split(separator: "-").first.map(String.init) == dil
        }
        let varsayilan = AVSpeechSynthesisVoice(language: dil)
        if let v = varsayilan, uyan.contains(where: { $0.identifier == v.identifier }) {
            return uyan.filter { $0.language == v.language }.max { $0.quality.rawValue < $1.quality.rawValue } ?? v
        }
        return uyan.max { $0.quality.rawValue < $1.quality.rawValue } ?? varsayilan
    }
}

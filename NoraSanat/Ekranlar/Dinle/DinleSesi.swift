// Y1 · Sesli rehberli bakış: Türkçe ses ve arka planda kesintisiz ses oturumu (sitede karşılığı yok).
import AVFoundation

/// Rehberin sesi. `AVSpeechSynthesizer` ile Türkçe okur; telefonda "gelişmiş" (ya da daha iyi) Türkçe ses varsa onu seçer.
/// Söz aralarındaki sessizlikte de ses oturumu açık kalsın diye arkada sessiz bir ses çalar: yoksa iOS uygulamayı arka
/// planda askıya alır ve akış kilit ekranında durur.
@MainActor
final class DinleSesi: NSObject, AVSpeechSynthesizerDelegate {
    private let sentez = AVSpeechSynthesizer()
    private var bekleyen: CheckedContinuation<Void, Never>?
    /// Beklenen sözün kimliği: durdurulan eski sözün geç gelen "bitti" haberi yenisini bitirmesin
    private var bekleyenSoz: ObjectIdentifier?
    private var motor: AVAudioEngine?
    private var sessizCalar: AVAudioPlayerNode?

    override init() {
        super.init()
        sentez.delegate = self
    }

    /// Telefondaki en iyi Türkçe ses (premium > gelişmiş > varsayılan).
    static var turkceSes: AVSpeechSynthesisVoice? {
        let tr = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.lowercased().hasPrefix("tr") }
        return tr.max { $0.quality.rawValue < $1.quality.rawValue } ?? AVSpeechSynthesisVoice(language: "tr-TR")
    }

    /// Ses oturumu: oynatma (sessiz moddayken de duyulur), sözlü içerik; öbür sesleri durdurur.
    func oturumuAc() {
        let o = AVAudioSession.sharedInstance()
        try? o.setCategory(.playback, mode: .spokenAudio, options: [])
        try? o.setActive(true)
        sessiziBaslat()
    }

    func oturumuKapat() {
        durdur()
        sessizCalar?.stop()
        motor?.stop()
        sessizCalar = nil
        motor = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Metni okur; bitince (ya da durdurulunca) döner. Görev iptal edilirse ses hemen kesilir.
    func oku(_ metin: String) async {
        guard !metin.isEmpty else { return }
        durdur()
        let soz = AVSpeechUtterance(string: metin)
        soz.voice = Self.turkceSes
        // Yavaş bakışa uygun, olağandan biraz yavaş (AVSpeech'te olağan hız 0,5)
        soz.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        soz.prefersAssistiveTechnologySettings = false
        await withTaskCancellationHandler {
            await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                guard !Task.isCancelled else { c.resume(); return }
                bekleyen = c
                bekleyenSoz = ObjectIdentifier(soz)
                sentez.speak(soz)
            }
        } onCancel: {
            Task { @MainActor in self.durdur() }
        }
    }

    func duraklat() {
        if sentez.isSpeaking { sentez.pauseSpeaking(at: .word) }
    }

    func surdur() {
        if sentez.isPaused { sentez.continueSpeaking() }
    }

    func durdur() {
        if sentez.isSpeaking || sentez.isPaused { sentez.stopSpeaking(at: .immediate) }
        bitti(nil)
    }

    /// `soz` nil: hangi söz beklenirse beklensin bitir (durdurma)
    private func bitti(_ soz: ObjectIdentifier?) {
        guard soz == nil || soz == bekleyenSoz else { return }
        let c = bekleyen
        bekleyen = nil
        bekleyenSoz = nil
        c?.resume()
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        let kimlik = ObjectIdentifier(u)
        Task { @MainActor in self.bitti(kimlik) }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        let kimlik = ObjectIdentifier(u)
        Task { @MainActor in self.bitti(kimlik) }
    }

    /// Sessiz bir tamponu döngüde çalar (oturum söz aralarında da "çalıyor" sayılır).
    private func sessiziBaslat() {
        guard motor == nil else { return }
        let m = AVAudioEngine()
        let calar = AVAudioPlayerNode()
        guard let bicim = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1),
              let tampon = AVAudioPCMBuffer(pcmFormat: bicim, frameCapacity: 44_100) else { return }
        tampon.frameLength = tampon.frameCapacity  // sıfırlarla dolu: bir saniye sessizlik
        m.attach(calar)
        m.connect(calar, to: m.mainMixerNode, format: bicim)
        do {
            try m.start()
        } catch {
            return
        }
        calar.scheduleBuffer(tampon, at: nil, options: .loops)
        calar.play()
        motor = m
        sessizCalar = calar
    }
}

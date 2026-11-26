// Y1 · Sesli rehberli bakış: rehberin sesi ve arka planda kesintisiz ses oturumu (sitede karşılığı yok).
// Z4a: önce doğal ses (Gemini "Fola" kaydı, `DinleSesKaynagi`) çalınır; kaydı olmayan metni telefonun en iyi Türkçe sesi okur.
import AVFoundation

/// Rehberin sesi. Bir adımda tek ses konuşur: ya kayıt (`cal`) ya `AVSpeechSynthesizer` (`oku`).
/// Söz aralarındaki sessizlikte de ses oturumu açık kalsın diye arkada sessiz bir ses çalar: yoksa iOS uygulamayı arka
/// planda askıya alır ve akış kilit ekranında durur.
@MainActor
final class DinleSesi: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private let sentez = AVSpeechSynthesizer()
    private var bekleyen: CheckedContinuation<Void, Never>?
    /// Beklenen sözün kimliği: durdurulan eski sözün geç gelen "bitti" haberi yenisini bitirmesin
    private var bekleyenSoz: ObjectIdentifier?
    private var motor: AVAudioEngine?
    private var sessizCalar: AVAudioPlayerNode?
    private var calar: AVAudioPlayer?

    /// Sentezin şu an söylediği yerin UTF-16 konumu (kelime kelime altyazı için); söz yoksa nil
    private(set) var sozKonumu: Int?

    override init() {
        super.init()
        sentez.delegate = self
    }

    /// Kayıt çalıyorsa (ya da duraklatılmışsa) içindeki an (sn)
    var kayitAni: Double? { calar?.currentTime }

    /// Z4b (Hikâyeler): okuma hızı. Kayıtta `AVAudioPlayer.rate` (hemen), telefonun sesinde sonraki sözden. Dinle (Z4a)
    /// hep 1 kullanır: davranışı değişmez.
    var hiz: Float = 1 {
        didSet { calar?.rate = hiz }
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

    /// Kaydı çalar; bitince (ya da durdurulunca) true döner. Dosya açılamazsa hemen false (o adımı telefon okur).
    /// Z4b: `bas` kaydın içinden başlama anı (sn; ±15 sn ve kalınan yer), hız `hiz`.
    func cal(_ url: URL, bas: Double = 0) async -> Bool {
        durdur()
        guard let c = try? AVAudioPlayer(contentsOf: url) else { return false }
        c.delegate = self
        c.enableRate = true
        c.prepareToPlay()
        c.rate = hiz
        if bas > 0 { c.currentTime = min(bas, max(0, c.duration - 0.05)) }
        calar = c
        await withTaskCancellationHandler {
            await withCheckedContinuation { (k: CheckedContinuation<Void, Never>) in
                guard !Task.isCancelled, c.play() else { k.resume(); return }
                bekleyen = k
                bekleyenSoz = ObjectIdentifier(c)
            }
        } onCancel: {
            Task { @MainActor in self.durdur() }
        }
        return true
    }

    /// Metni telefonun sesiyle okur; bitince (ya da durdurulunca) döner. Görev iptal edilirse ses hemen kesilir.
    func oku(_ metin: String) async {
        guard !metin.isEmpty else { return }
        durdur()
        let soz = AVSpeechUtterance(string: metin)
        soz.voice = Self.turkceSes
        // Yavaş bakışa uygun, olağandan biraz yavaş (AVSpeech'te olağan hız 0,5)
        soz.rate = min(AVSpeechUtteranceMaximumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * 0.9 * hiz)
        soz.prefersAssistiveTechnologySettings = false
        sozKonumu = 0
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
        if let c = calar, c.isPlaying { c.pause() }
    }

    func surdur() {
        if sentez.isPaused { sentez.continueSpeaking() }
        if let c = calar, !c.isPlaying, bekleyenSoz == ObjectIdentifier(c) { c.play() }
    }

    func durdur() {
        if sentez.isSpeaking || sentez.isPaused { sentez.stopSpeaking(at: .immediate) }
        calar?.stop()
        calar = nil
        sozKonumu = nil
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

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange,
                                       utterance u: AVSpeechUtterance) {
        let kimlik = ObjectIdentifier(u)
        Task { @MainActor in if kimlik == self.bekleyenSoz { self.sozKonumu = r.location } }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        let kimlik = ObjectIdentifier(u)
        Task { @MainActor in self.bitti(kimlik) }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        let kimlik = ObjectIdentifier(u)
        Task { @MainActor in self.bitti(kimlik) }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ p: AVAudioPlayer, successfully _: Bool) {
        let kimlik = ObjectIdentifier(p)
        Task { @MainActor in
            if let c = self.calar, ObjectIdentifier(c) == kimlik { self.calar = nil }
            self.bitti(kimlik)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ p: AVAudioPlayer, error _: Error?) {
        let kimlik = ObjectIdentifier(p)
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

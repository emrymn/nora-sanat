// Kaynak: sanat-atlasi js/kunye.js, js/imza.js @ a866b86
import AVFoundation
import NoraCekirdek
import SwiftUI

struct SanatciKunyesi: View {
    let s: Sanatci
    let g: GaleriKatalogu
    @State private var oynatici: AVPlayer?
    @State private var okuyucu = AVSpeechSynthesizer()

    var body: some View {
        let kayit = g.kunye?[s.id]
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(s.yillar)
                    Text(s.kaynak == "ek" ? "Kurs dışı" : "Kursta konu \(s.konu ?? 0)").font(.caption)
                    if g.imzalar?[s.id]?.doluMetin != nil {
                        UzakGorsel(url: SiteVerisi.site.appendingPathComponent("gorseller/imza/\(s.id).png"), icerik: .fit)
                            .frame(width: 128, height: 44).accessibilityLabel("Sanatçının imzası")
                    }
                }
                Spacer()
                if kayit?["portre"]?.doluMetin != nil {
                    UzakGorsel(url: SiteVerisi.site.appendingPathComponent("gorseller/portre/\(s.id).jpg"), icerik: .fill)
                        .frame(width: 90, height: 105).clipped().accessibilityLabel("\(s.ad) portresi")
                }
            }
            if let dil = kayit?["dil"]?.metin {
                HStack {
                    Button { dinle(kayit, dil: dil) } label: { Label("Dinle", systemImage: "speaker.wave.2") }
                    if let ipa = kayit?["ipa"]?["yazi"]?.metin { Text(ipa).font(.caption) }
                }
            }
        }.onDisappear { oynatici?.pause(); okuyucu.stopSpeaking(at: .immediate) }
    }

    private func dinle(_ k: JSONDeger?, dil: String) {
        if let uzanti = GaleriKatalogu.sesUzantisi(k) {
            oynatici = AVPlayer(url: SiteVerisi.site.appendingPathComponent("gorseller/ses/\(s.id).\(uzanti)"))
            oynatici?.play()
        } else {
            okuyucu.stopSpeaking(at: .immediate)
            let soz = AVSpeechUtterance(string: GaleriKatalogu.okunacakAd(s.ad))
            soz.voice = AVSpeechSynthesisVoice(language: dil)
            okuyucu.speak(soz)
        }
    }
}

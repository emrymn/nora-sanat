// Kaynak: sanat-atlasi js/kunye.js (kunyeGoster, ipaHtml, dinle), js/imza.js (imzaGoster), js/ekranlar/ortak.js isimHtml,
// css/app.css (.isim-blok, .ad-son, .ad-ilk, .ad-tam, .portre-arka, .imza, .isim-ek, .dinle, .ipa) @ a866b86
import AVFoundation
import NoraCekirdek
import SwiftUI

/// `.isim-blok`: büyük ad (64 px Bodoni), altında tam ad (italik 19 px), altın imza, "Dinle" ve IPA, yıllar · kurs,
/// seviye satırı. Portre adın arkasında sağ üstte büyük ve silik.
struct SanatciKunyesi: View {
    let s: Sanatci
    let g: GaleriKatalogu
    let il: Ilerleme
    @Environment(TemaDeposu.self) private var tema
    @State private var oynatici: AVPlayer?
    @State private var okuyucu = AVSpeechSynthesizer()

    var body: some View {
        let r = tema.renkler
        let kayit = g.kunye?[s.id]
        let p = g.katalog.adParcalari(s)
        let acik = s.konu.map(il.islenenKume.contains) == true || il.acikSanatcilar(g.katalog.sanatcilar).contains { $0.id == s.id }
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                if !p.ilk.isEmpty {
                    Text(p.ilk).font(Yazi.serif(19, italik: true)).foregroundStyle(Color(r.murekkep2))
                }
                Text(p.son).font(Yazi.serif(64, stil: .largeTitle)).tracking(-0.64).cssSatir(.serif, 64, 62.72)
                    .foregroundStyle(Color(r.murekkep))
                    .lineLimit(2).minimumScaleFactor(0.5)
                if let tam = p.tam {
                    Text(tam).font(Yazi.serif(19, italik: true)).cssSatir(.serif, 19, 21.85)
                        .foregroundStyle(Color(r.murekkep2)).padding(.top, 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(s.ad)
            .accessibilityAddTraits(.isHeader)
            if g.imzalar?[s.id]?.doluMetin != nil { Imza(id: s.id).padding(.top, 4).padding(.bottom, 8) }
            if let dil = kayit?["dil"]?.metin {
                HStack(spacing: 12) {
                    Button { dinle(kayit, dil: dil) } label: {
                        HStack(spacing: 7) {
                            GaleriIkon(simge: .ses, boyut: 18, kalinlik: 1.7)
                            Text("Dinle").font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                        }
                        .foregroundStyle(Color(GaleriRenk.karis(r.vurgu, r.murekkep, 0.5)))
                        .padding(.leading, 11).padding(.trailing, 14)
                        .frame(height: 44)
                        .overlay(Capsule().strokeBorder(Color(RGBA(css: "#c9a24a")!, 0.55), lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(s.ad): adı nasıl okunur, dinle")
                    if let ipa = kayit?["ipa"]?["yazi"]?.metin ?? kayit?["ipa"]?.metin {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("IPA").font(Yazi.sans(10, agirlik: 600, stil: .caption2)).tracking(1.4)
                                .foregroundStyle(Color(r.murekkep2)).opacity(0.85)
                            Text(ipa).font(.system(size: 17, design: .serif)).foregroundStyle(Color(r.murekkep))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
                .padding(.top, 8).padding(.bottom, 2)
            }
            Text("\(s.yillar) · " + (s.kaynak == "ek" ? "Kurs dışı" : "Kursta Konu \(s.konu ?? 0)"))
                .font(Yazi.sans(14, stil: .subheadline)).cssSatir(.sans, 14, 19.6)
                .foregroundStyle(Color(r.murekkep2))
            Group {
                if acik {
                    Text("\(s.akim) dönemi: \(Seviye.durum(Seviye.kayit(il.seviyeler, s.akim)))")
                } else {
                    Text("Bu sanatçı Konu \(s.konu ?? 0) işlenince pekiştirmeye girer.")
                }
            }
            .font(Yazi.sans(14, stil: .subheadline)).cssSatir(.sans, 14, 21)
            .foregroundStyle(Color(r.murekkep2))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            if kayit?["portre"]?.doluMetin != nil {
                // `.portre-arka`: 250 × 330, 96 px yukarıda, sağ kenara taşar; solda ve altta silinir; Gece %70, Gündüz %40
                UzakGorsel(url: SiteVerisi.site.appendingPathComponent("gorseller/portre/\(s.id).jpg"), icerik: .fill)
                    .frame(width: 250, height: 330)
                    .clipped()
                    .saturation(0.85)
                    .mask {
                        LinearGradient(stops: [.init(color: .black, location: 0.3), .init(color: .clear, location: 0.92)],
                                       startPoint: .trailing, endPoint: .leading)
                            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.22),
                                                         .init(color: .black, location: 0.55), .init(color: .clear, location: 1)],
                                                 startPoint: .top, endPoint: .bottom))
                    }
                    .opacity(r.koyu ? 0.7 : 0.4)
                    .offset(x: BenOlcu.yan, y: -96)
                    .accessibilityHidden(true)
            }
        }
        .onDisappear { oynatici?.pause(); okuyucu.stopSpeaking(at: .immediate) }
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

/// `.imza`: ressamın imzası (uygulamayla gelen maske `gorseller/imza/<id>.png`; mürekkep saydamlıkta) altın geçişle,
/// 52 px yükseklik
private struct Imza: View {
    let id: String
    private static let altin: [Color] = ["#a8782a", "#f6dc8e", "#c9973a", "#fff1c4", "#c9973a", "#e8c46e", "#9a6b1f"]
        .map { Color(RGBA(css: $0)!) }

    var body: some View {
        AsyncImage(url: SiteVerisi.site.appendingPathComponent("gorseller/imza/\(id).png")) { faz in
            if let resim = faz.image {
                resim.resizable().scaledToFit().opacity(0)
                    .overlay(LinearGradient(colors: Self.altin, startPoint: .leading, endPoint: .trailing)
                        .mask(resim.resizable().scaledToFit()))
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: 250, maxHeight: 52, alignment: .leading)
        .frame(height: 52)
        .accessibilityLabel("Sanatçının imzası")
    }
}

import AVFoundation
// Kaynak: sanat-atlasi js/ekranlar/bugun.js yuruyusSonu, css/app.css .yur-hayat @ a866b86
import NoraCekirdek
import SwiftUI

struct BugunHayati: View {
  let s: BugunTablosu
  let kucukler: [URL?]
  let kunye: JSONDeger?
  @State private var oynatici: AVPlayer?
  @State private var okuma = AVSpeechSynthesizer()
  let adet: Int
  let git: (String, Sekme) -> Void
  let basa: () -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if !s.hayat.isEmpty {
        Text("Hayatı").font(Yazi.serif(34)).accessibilityAddTraits(.isHeader)
        ForEach(Array(s.hayat.split(whereSeparator: \.isNewline).enumerated()), id: \.offset) {
          _, p in
          Text(String(p)).font(Yazi.okuma(19)).cssSatir(.okuma, 19, 29.45)
        }
        if !s.kaynak.isEmpty {
          Text("Kaynak: " + s.kaynak).font(Yazi.sans(13)).foregroundStyle(.secondary)
        }
      }
      Etiket(s.kunye).padding(.top, 26)
      Text("Resmi gezdin.").font(Yazi.serif(40))
      Button {
        git(adet == 0 ? "#/pekistir" : "#/pekistir/karisik", .calis)
      } label: {
        HStack(spacing: 18) {
          ZStack {
            ForEach([-12, 12, 0], id: \.self) { don in
              RoundedRectangle(cornerRadius: 5).fill(.black.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.5)))
                .rotationEffect(.degrees(Double(don)))
            }
            Text(adet == 0 ? "✓" : String(adet)).font(Yazi.serif(30))
          }.frame(width: 46, height: 58)
          VStack(alignment: .leading, spacing: 3) {
            if adet > 0 { Etiket("Günün işi") }
            Text(adet == 0 ? "Bugünkü kartlar bitti" : "Bugünkü tur").font(Yazi.serif(26))
            Text(
              adet == 0
                ? "Başka turlar Çalış'ta"
                : "\(adet) kart · yaklaşık \(max(1,Int((Double(adet)/3).rounded()))) dk"
            )
            .font(Yazi.sans(13))
          }
          Spacer()
          BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.8)
        }.padding(16).frame(minHeight: 104)
          .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 22))
          .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.28)))
      }
      HStack(spacing: 12) {
        karo(s.ad.son, "Sanatçı sayfası", "#/sanatci/" + s.tablo.sanatciId)
        karo("Bütün eserleri", "Izgara, tam ekran", "#/sanatci/" + s.tablo.sanatciId + "/eserler")
      }
      if let kunye {
        HStack {
          Button("Dinle", systemImage: "speaker.wave.2") { dinle(kunye) }
          if let ipa = kunye["ipa"]?["yazi"]?.metin { Text(ipa) }
        }.font(Yazi.sans(14))
      }
      Button(action: basa) {
        Label("Başa dön", systemImage: "arrow.up").font(Yazi.sans(15)).padding(.vertical, 18)
      }
      .frame(maxWidth: .infinity)
    }.buttonStyle(.plain).padding(.horizontal, 24).foregroundStyle(.white)
      .onDisappear {
        oynatici?.pause()
        okuma.stopSpeaking(at: .immediate)
      }
  }
  private func dinle(_ k: JSONDeger) {
    if let uzanti = GaleriKatalogu.sesUzantisi(k) {
      let url = SiteVerisi.site.appendingPathComponent(
        "gorseller/ses/" + s.tablo.sanatciId + "." + uzanti)
      oynatici = AVPlayer(url: url)
      oynatici?.play()
    } else {
      let soz = AVSpeechUtterance(string: GaleriKatalogu.okunacakAd(s.tablo.sanatci))
      soz.voice = AVSpeechSynthesisVoice(language: k["dil"]?.metin)
      okuma.speak(soz)
    }
  }

  private func karo(_ baslik: String, _ alt: String, _ adres: String) -> some View {
    Button {
      git(adres, .galeri)
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        if adres.hasSuffix("/eserler") {
          HStack(spacing: 3) {
            ForEach(kucukler.indices, id: \.self) { i in
              UzakGorsel(url: kucukler[i]).frame(width: 22, height: 30).clipped()
            }
          }
        } else {
          Text(String(baslik.prefix(1))).font(Yazi.serif(34))
        }
        Text(baslik).font(Yazi.serif(22))
        Text(alt).font(Yazi.sans(12))
      }.padding(14).frame(maxWidth: .infinity, minHeight: 104, alignment: .bottomLeading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
  }
}

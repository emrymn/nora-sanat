// Kaynak: sanat-atlasi js/ekranlar/bugun.js (yuruyusKur biyografi, yuruyusSonu), js/kunye.js (dinleEkle, ipaHtml),
// css/app.css (.yur-hayat, .yur-son, .yur-tur, .yur-deste, .yur-baglar, .yur-karo, .yur-harf, .yur-kare, .isim-ek,
// .yur-basa) @ a866b86. Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece).
import NoraCekirdek
import SwiftUI

/// Yürüyüş her temada koyu (resmin üstünde): `.bugun-yuruyus` yerel renkleri
enum YurRenk {
  /// `--yur-yazi: #ebe5da`
  static let yazi = Color(.sRGB, red: 235 / 255, green: 229 / 255, blue: 218 / 255)
  /// `--yur-ikincil: #cfc7bc`
  static let ikincil = Color(.sRGB, red: 207 / 255, green: 199 / 255, blue: 188 / 255)
  /// `rgba(235, 229, 218, a)`
  static func acik(_ a: Double) -> Color { yazi.opacity(a) }
  /// `rgba(18, 17, 16, a)`: perde, buğu, üst şerit
  static func zemin(_ a: Double) -> Color { Color(.sRGB, red: 18 / 255, green: 17 / 255, blue: 16 / 255, opacity: a) }
  /// `rgba(24, 22, 20, a)`: cam kartlar
  static func cam(_ a: Double) -> Color { Color(.sRGB, red: 24 / 255, green: 22 / 255, blue: 20 / 255, opacity: a) }
  /// `rgba(201, 163, 92, a)`: pirinç çizgiler
  static func pirinc(_ a: Double) -> Color { Color(.sRGB, red: 201 / 255, green: 163 / 255, blue: 92 / 255, opacity: a) }
  static func hex(_ s: String) -> Color { Color(RGBA(css: s) ?? RGBA(0, 0, 0), 1) }
}

struct BugunHayati: View {
  let s: BugunTablosu
  let kucukler: [URL?]
  let kunye: JSONDeger?
  @Environment(TemaDeposu.self) private var tema
  let adet: Int
  let git: (String, Sekme) -> Void
  let basa: () -> Void
  private var tur: BugunTuru { BugunTuru(adet: adet) }
  private let turkce = Locale(identifier: "tr_TR")
  private var pirinc: Color { Color(tema.renkler.pirinc) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if !s.hayat.isEmpty {
        // [data-yur-bio]: h2 34/1.1 (alt 14), p 19/1.55 (alt 14), small 13/1.4 (alt 40)
        Text("Hayatı").font(Yazi.serif(34)).cssSatir(.serif, 34, 37.4).accessibilityAddTraits(.isHeader)
          .padding(.bottom, 14)
        ForEach(Array(s.hayat.split(whereSeparator: \.isNewline).enumerated()), id: \.offset) { _, p in
          Text(String(p)).font(Yazi.okuma(19)).cssSatir(.okuma, 19, 29.45)
            .fixedSize(horizontal: false, vertical: true).padding(.bottom, 14)
        }
        Text("Kaynak: " + s.kaynak).font(Yazi.sans(13)).cssSatir(.sans, 13, 18.2)
          .foregroundStyle(YurRenk.ikincil).padding(.bottom, 40)
      }
      son
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .buttonStyle(.plain).padding(.horizontal, 24).foregroundStyle(YurRenk.yazi)
    .onDisappear { AdOkuyucu.shared.durdur() }
    // Z4i: hikâye kartı için (Hikâyeler sekmesi hiç açılmamış olabilir)
    .task { await HikayeDeposu.shared.yukle() }
  }

  /// `.yur-son`: sütun, aralık 14
  private var son: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(s.sonKunye.uppercased(with: turkce)).font(Yazi.sans(11, agirlik: 600)).tracking(2.2)
        .cssSatir(.sans, 11, 14.3).foregroundStyle(pirinc)
      Text("Resmi gezdin.").font(Yazi.serif(40)).cssSatir(.serif, 40, 42).padding(.bottom, 6)
        .accessibilityAddTraits(.isHeader)
      turKarti.id("tur")
      HStack(spacing: 12) {
        karo(adres: "#/sanatci/" + s.tablo.sanatciId, baslik: s.ad.son, alt: "Sanatçı sayfası") {
          Text(String(s.ad.son.prefix(1))).font(Yazi.serif(26)).foregroundStyle(pirinc)
            .frame(width: 52, height: 52).overlay(Circle().strokeBorder(pirinc, lineWidth: 1.5))
        }
        karo(adres: "#/sanatci/" + s.tablo.sanatciId + "/eserler", baslik: "Bütün eserleri", alt: "Izgara, tam ekran") {
          kareler
        }
      }.fixedSize(horizontal: false, vertical: true).id("eserler")
      // Z4i: günün sanatçısının hikâyesi (varsa). Karoların altında: sitedekiyle yan yana karşılaştırılan tur ve
      // eserler konumları değişmesin (CI `bugun` grubu)
      SanatciHikayeKarti(sanatci: s.tablo.sanatciId, renk: .bugun)
      dinle
      basaDon.frame(maxWidth: .infinity).padding(.top, 26)
    }
  }

  /// `.yur-tur`: koyu cam kart, solda üç kartlık deste, sağda halkalı ok
  private var turKarti: some View {
    Button {
      git(tur.adres, .calis)
    } label: {
      HStack(spacing: 18) {
        deste
        VStack(alignment: .leading, spacing: 3) {
          if adet > 0 {
            Text("GÜNÜN İŞİ").font(Yazi.sans(11, agirlik: 600)).tracking(1.98).cssSatir(.sans, 11, 13.2)
              .foregroundStyle(pirinc)
          }
          Text(tur.baslik).font(Yazi.serif(26)).cssSatir(.serif, 26, 28.6)
          Text(tur.alt).font(Yazi.sans(14, agirlik: 500)).cssSatir(.sans, 14, 18.2).foregroundStyle(YurRenk.ikincil)
        }.frame(maxWidth: .infinity, alignment: .leading)
        BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.8).foregroundStyle(pirinc)
          .frame(width: 40, height: 40)
          .overlay(Circle().strokeBorder(YurRenk.pirinc(0.6), lineWidth: 1.5))
      }
      .padding(.leading, 14).padding(.trailing, 18).padding(.vertical, 16)
      .frame(minHeight: 104)
      .background(YurRenk.cam(0.55), in: RoundedRectangle(cornerRadius: 22))
      .overlay(
        RoundedRectangle(cornerRadius: 22).strokeBorder(
          adet > 0 ? YurRenk.pirinc(0.55) : YurRenk.acik(0.24), lineWidth: 1)
      )
      .shadow(color: .black.opacity(0.35), radius: 15, y: 10)
      .contentShape(RoundedRectangle(cornerRadius: 22))
    }
    .accessibilityLabel(adet > 0 ? "\(tur.baslik), \(tur.alt)" : tur.baslik)
  }

  /// `.yur-deste`: 70 × 66; 42 × 58 kartlar soldan 14, üstten 3; yanlardakiler ±8° alt ortadan döner
  private var deste: some View {
    ZStack(alignment: .topLeading) {
      ForEach([("#4e3d2c", -8.0), ("#6d5236", 8.0)], id: \.1) { k in
        RoundedRectangle(cornerRadius: 6).fill(YurRenk.hex(k.0))
          .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(YurRenk.pirinc(0.35), lineWidth: 1))
          .frame(width: 42, height: 58)
          .rotationEffect(.degrees(k.1), anchor: .bottom)
          .offset(x: 14, y: 3)
      }
      Group {
        if adet > 0 {
          Text(String(adet)).font(Yazi.serif(24, agirlik: 500))
        } else {
          BenIkon(simge: .dogru, boyut: 20, kalinlik: 1.8)
        }
      }
      .foregroundStyle(pirinc)
      .frame(width: 42, height: 58)
      .background(YurRenk.hex("#26221e"), in: RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(pirinc, lineWidth: 1.5))
      .offset(x: 14, y: 1)
    }
    .frame(width: 70, height: 66, alignment: .topLeading)
    .accessibilityHidden(true)
  }

  /// `.yur-kareler`: 64 genişlikte 2 × 2, aralık 4, kare 26 yüksek
  private var kareler: some View {
    let renkler = ["#4e3d2c", "#6d5236", "#5d4630", "#8c6d45"]
    return Grid(horizontalSpacing: 4, verticalSpacing: 4) {
      ForEach(0..<2, id: \.self) { satir in
        GridRow {
          ForEach(0..<2, id: \.self) { sutun in
            let i = satir * 2 + sutun
            YurRenk.hex(renkler[i])
              .overlay {
                if kucukler.indices.contains(i) { UzakGorsel(url: kucukler[i], icerik: .fill) }
              }
              .frame(width: 30, height: 26)
              .clipShape(RoundedRectangle(cornerRadius: 4))
          }
        }
      }
    }
    .frame(width: 64, alignment: .leading)
    .accessibilityHidden(true)
  }

  /// `.yur-karo`: en az 150 yüksek, iç boşluk 16, köşe 20; üstte simge, altta başlık (Bodoni 21) ve küçük yazı
  private func karo<Ust: View>(adres: String, baslik: String, alt: String, @ViewBuilder ust: () -> Ust) -> some View {
    Button {
      git(adres, .galeri)
    } label: {
      // justify-content: space-between; gap 14
      VStack(alignment: .leading, spacing: 0) {
        ust()
        Spacer(minLength: 14)
        VStack(alignment: .leading, spacing: 4) {
          Text(baslik).font(Yazi.serif(21)).cssSatir(.serif, 21, 23.1)
            .fixedSize(horizontal: false, vertical: true)
          HStack(spacing: 4) {
            Text(alt).font(Yazi.sans(13, agirlik: 500)).cssSatir(.sans, 13, 16.9).foregroundStyle(YurRenk.ikincil)
            BenIkon(simge: .ileri, boyut: 13, kalinlik: 1.8).foregroundStyle(pirinc)
          }
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, minHeight: 150, maxHeight: .infinity, alignment: .topLeading)
      .background(YurRenk.cam(0.5), in: RoundedRectangle(cornerRadius: 20))
      .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(YurRenk.acik(0.2), lineWidth: 1))
      .contentShape(RoundedRectangle(cornerRadius: 20))
    }
  }

  /// `.isim-ek`: "Dinle" hapı (44 yüksek) ve yanında IPA okunuşu; ses yoksa ve dil bilinmiyorsa yalnız IPA
  @ViewBuilder private var dinle: some View {
    if let k = kunye {
      let dil = k["dil"]?.metin
      let okunur = GaleriKatalogu.sesUzantisi(k) != nil || dil != nil
      let ipa = k["ipa"]?["yazi"]?.metin ?? k["ipa"]?.metin
      if okunur || ipa != nil {
        HStack(spacing: 12) {
          if okunur {
            Button { oku(k) } label: {
              HStack(spacing: 7) {
                GaleriIkon(simge: .ses, boyut: 18, kalinlik: 1.7)
                Text("Dinle").font(Yazi.sans(13, agirlik: 600))
              }
              .foregroundStyle(Color(GaleriRenk.karis(tema.renkler.vurgu, RGBA(235 / 255, 229 / 255, 218 / 255), 0.5)))
              .padding(.leading, 11).padding(.trailing, 14).frame(height: 44)
              .overlay(Capsule().strokeBorder(Color(RGBA(css: "#c9a24a")!, 0.55), lineWidth: 1))
              .contentShape(Capsule())
            }
            .accessibilityLabel("\(s.tablo.sanatci): adı nasıl okunur, dinle")
          }
          if let ipa {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text("IPA").font(Yazi.sans(10, agirlik: 600)).tracking(1.4)
                .foregroundStyle(Color(.sRGB, red: 172 / 255, green: 164 / 255, blue: 152 / 255)).opacity(0.85)
              Text(ipa).font(.system(size: 17, design: .serif)).lineLimit(1).minimumScaleFactor(0.7)
            }
          }
        }
      }
    }
  }

  /// `.yur-basa`: ince pirinç halka içinde yukarı ok, altında BAŞA DÖN (11, aralık 0.2em)
  private var basaDon: some View {
    Button(action: basa) {
      VStack(spacing: 12) {
        GaleriIkon(simge: .cik, boyut: 20, kalinlik: 1.5).foregroundStyle(pirinc)
          .frame(width: 56, height: 56)
          .overlay(Circle().strokeBorder(Color(.sRGB, red: 201 / 255, green: 164 / 255, blue: 92 / 255, opacity: 0.6), lineWidth: 1))
        Text("BAŞA DÖN").font(Yazi.sans(11, agirlik: 600)).tracking(2.2).foregroundStyle(YurRenk.ikincil)
      }
      .padding(.horizontal, 20).frame(minHeight: 96).contentShape(Rectangle())
    }
    .accessibilityLabel("Başa dön")
  }

  private func oku(_ k: JSONDeger) {
    AdOkuyucu.shared.oku(id: s.tablo.sanatciId, ad: s.tablo.sanatci, kunye: k)
  }
}

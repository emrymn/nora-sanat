// Kaynak: sanat-atlasi js/ekranlar/ders.js (adimUst, adimCizgileri, adimSonu, altCubuk), css/app.css (.ders-etiket,
// .ders-dugme, .ders-ust, .ders-geri, .ders-cizgiler, .ders-alt-cubuk, .ders-son, `--ders-*` değişkenleri) @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt genişlik, Gece; Testler/kahin/ders_adimlari.mjs ile aynı oturum).
import NoraCekirdek
import SwiftUI
import UIKit

// MARK: Renkler

/// `--ders-altin-yazi`, `--ders-iz`, `--ders-kenar` (css/app.css; Gece ve Gündüz). Dolu düğme `--pg-asil` = `--vurgu-acik`.
struct DersRenkleri {
    let altinYazi: Color
    let iz: Color
    let kenar: Color
    let dolu: Color
    let doluYazi: Color

    init(_ r: TemaRenkleri) {
        if r.koyu {
            altinYazi = Color(RGBA(css: "#d9b56a")!)
            iz = Color(RGBA(css: "#3d3935")!)
            kenar = Color(RGBA(css: "#4a4540")!)
        } else {
            altinYazi = Color(RGBA(css: "#6b4c10")!)
            iz = Color(r.murekkep).opacity(0.16)
            kenar = Color(r.murekkep).opacity(0.34)
        }
        dolu = Color(r.vurguAcik)
        doluYazi = Color(r.vurguAcikYazi)
    }

    /// Gör sahnesi her temada koyu (`.ders-gor` değişkenleri)
    static let sahne = (
        zemin: Color(RGBA(css: "#0d0c0b")!),
        yazi: Color(RGBA(css: "#ebe5da")!),
        yazi2: Color(RGBA(css: "#aca498")!),
        metin: Color(RGBA(css: "#d8d1c6")!),
        altin: Color(RGBA(css: "#d9b56a")!),
        iz: Color(RGBA(css: "#4a4540")!),
        kenar: Color(RGBA(css: "#5a544d")!),
        dogru: Color(RGBA(css: "#6fb487")!),
        dugme: Color(RGBA(css: "#121110")!.saydam(0.6))
    )
}

extension RGBA {
    func saydam(_ a: Double) -> RGBA { RGBA(r, g, b, a) }
}

// MARK: Satır yüksekliği

extension View {
    /// Çok satırlı serif başlıklar için CSS `line-height`: `cssSatir` satır arasını sıfırın altına indirmez; Bodoni'nin
    /// kendi satırı (1.525 em) sitenin 1.1–1.15'inden yüksek olduğundan burada satır arası eksiye de iner.
    func dersSatir(_ aile: Yazi.Aile, _ boyut: CGFloat, _ satir: CGFloat) -> some View {
        let fark = satir - boyut * aile.satirOrani
        return lineSpacing(fark).padding(.vertical, fark / 2)
    }
}

// MARK: Düğme

/// `.ders-dugme`: hap, 52 pt; `dolu`: `--pg-asil` zemin. `koyu`: Gör sahnesinin kenarlı düğmesi.
struct DersDugme: ButtonStyle {
    enum Tur { case dolu, bos, sahneDolu, sahneBos }
    var tur: Tur = .dolu
    var yatay: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration, tur: tur, yatay: yatay) }

    private struct Govde: View {
        let configuration: Configuration
        let tur: Tur
        let yatay: CGFloat
        @Environment(TemaDeposu.self) private var tema
        var body: some View {
            let d = DersRenkleri(tema.renkler)
            let (zemin, yazi, kenar): (Color, Color, Color) = {
                switch tur {
                case .dolu: return (d.dolu, d.doluYazi, .clear)
                case .bos: return (.clear, Color(tema.renkler.murekkep), d.kenar)
                case .sahneDolu: return (d.dolu, d.doluYazi, .clear)
                case .sahneBos: return (.clear, DersRenkleri.sahne.yazi, DersRenkleri.sahne.kenar)
                }
            }()
            configuration.label
                .font(Yazi.sans(16, agirlik: 600))
                .lineLimit(1)
                .foregroundStyle(yazi)
                .padding(.horizontal, yatay)
                .frame(minHeight: 52)
                .background(Capsule().fill(zemin))
                .overlay(Capsule().strokeBorder(kenar, lineWidth: 1))
                .contentShape(Capsule())
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
        }
    }
}

// MARK: Üst

/// `.ders-cizgiler`: adım başına ince çizgi (biten yeşil, süren altın; şimdiki adım en az %30)
struct DersCizgileri: View {
    let durum: DersDurumu
    var simdiki: DersAdimi?
    var genislik: CGFloat = 18
    var sahne = false
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let d = DersRenkleri(tema.renkler)
        let altin = sahne ? DersRenkleri.sahne.altin : d.altinYazi
        let iz = sahne ? DersRenkleri.sahne.iz : d.iz
        let dogru = sahne ? DersRenkleri.sahne.dogru : Color(tema.renkler.dogru)
        HStack(spacing: 4) {
            ForEach(durum.adimlar, id: \.adim) { x in
                let simdi = x.adim == simdiki && !x.bitti
                let oran = simdi ? max(x.i, 0.3) : x.i
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(x.bitti ? dogru : (simdi ? altin.karis(iz, 0.55) : iz))
                        if !x.bitti {
                            Rectangle().fill(altin).frame(width: g.size.width * oran)
                        }
                    }
                }
                .frame(width: genislik, height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .accessibilityElement()
        .accessibilityLabel(durum.adimlar.map { "\($0.ad) \($0.bitti ? "tamam" : $0.i > 0 ? "sürüyor" : "bekliyor")" }.joined(separator: ", "))
    }
}

extension Color {
    /// `color-mix(in srgb, self p, öbürü)`: kaba karışım (yalnız opaklıkla)
    func karis(_ diger: Color, _ digerPay: Double) -> Color {
        Color(UIColor { tr in
            var a = (r: CGFloat(0), g: CGFloat(0), b: CGFloat(0), a: CGFloat(0))
            var b = a
            UIColor(self).resolvedColor(with: tr).getRed(&a.r, green: &a.g, blue: &a.b, alpha: &a.a)
            UIColor(diger).resolvedColor(with: tr).getRed(&b.r, green: &b.g, blue: &b.b, alpha: &b.a)
            let p = CGFloat(digerPay)
            return UIColor(red: a.r * (1 - p) + b.r * p, green: a.g * (1 - p) + b.g * p, blue: a.b * (1 - p) + b.b * p,
                           alpha: a.a * (1 - p) + b.a * p)
        })
    }
}

/// `.ders-ust`: geri düğmesi, "<akım> dersi · n. adım" etiketi, başlık ve adım çizgileri
struct DersAdimUst: View {
    let etiket: String
    let baslik: String
    let durum: DersDurumu
    let adim: DersAdimi
    var sahne = false
    let geri: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let d = DersRenkleri(r)
        HStack(spacing: 10) {
            Button(action: geri) {
                BenIkon(simge: .geri, boyut: 20, kalinlik: 1.8)
                    .foregroundStyle(sahne ? DersRenkleri.sahne.yazi : Color(r.murekkep))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(sahne ? DersRenkleri.sahne.dugme : Color(r.yuzey)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Derse dön")

            VStack(alignment: .leading, spacing: 2) {
                Text(etiket)
                    .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                    .cssSatir(.sans, 13, 16.9)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(sahne ? DersRenkleri.sahne.altin : d.altinYazi)
                Text(baslik)
                    .font(Yazi.serif(22))
                    .cssSatir(.serif, 22, 25.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(sahne ? DersRenkleri.sahne.yazi : Color(r.murekkep))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("ders-adim-baslik")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            DersCizgileri(durum: durum, simdiki: adim, sahne: sahne)
        }
        .frame(minHeight: 52)
    }
}

// MARK: Alt çubuk

/// `.ders-alt-cubuk`: ekranın altında, zemine solan şerit; içinde Geri ve dolu düğme
struct DersAltCubuk<Icerik: View>: View {
    @ViewBuilder let icerik: Icerik
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let z = Color(tema.renkler.zemin)
        HStack(spacing: 10) { icerik }
            .padding(.top, 22)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(stops: [
                    .init(color: z.opacity(0), location: 0),
                    .init(color: z.opacity(0.96), location: 22 / 88),
                    .init(color: z, location: 40 / 88),
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
            }
    }
}

// MARK: Adım sonu

/// `adimSonu(adim)`: yeşil onay, "<adım> tamam", kısa kapanış; sıradaki adım, haritaya geç ve derse dön düğmeleri
struct DersAdimSonu: View {
    struct Dugme: Identifiable {
        let id: String
        let yazi: String
        var dolu = true
        var simge: BenSimge? = nil
        var harita = false
        let eylem: () -> Void
    }

    let baslik: String
    let yazilar: [String]
    let dugmeler: [Dugme]
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(r.dogru))
                BenIkon(simge: .dogru, boyut: 26, kalinlik: 2).foregroundStyle(Color(r.zemin))
            }
            .frame(width: 64, height: 64)
            Text(baslik)
                .font(Yazi.serif(34, stil: .largeTitle))
                .dersSatir(.serif, 34, 37.4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(r.murekkep))
                .accessibilityAddTraits(.isHeader)
            ForEach(yazilar, id: \.self) { p in
                Text(p)
                    .font(Yazi.okuma(17))
                    .cssSatir(.okuma, 17, 24.65)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(r.murekkep2))
            }
            VStack(spacing: 10) {
                ForEach(dugmeler) { b in
                    Button(action: b.eylem) {
                        HStack {
                            Text(b.yazi)
                            if b.simge != nil || b.harita {
                                Spacer(minLength: 8)
                                if b.harita { DersHaritaSimgesi(boyut: 18, kalinlik: 1.7) }
                                if let s = b.simge { BenIkon(simge: s, boyut: 18, kalinlik: 1.8) }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DersDugme(tur: b.dolu ? .dolu : .bos))
                    .accessibilityIdentifier(b.id)
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("ders-adim-son")
    }
}

/// js/tasarim.js `YOLLAR.harita`
struct DersHaritaSimgesi: View {
    var boyut: CGFloat = 16
    var kalinlik: CGFloat = 1.7
    private static let yol = #"<path d="M9 4 3 6.5v13.5l6-2.5 6 2.5 6-2.5V4l-6 2.5z"/><path d="M9 4v13.5"/><path d="M15 6.5V20"/>"#
    var body: some View {
        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: Self.yol))
            .stroke(style: StrokeStyle(lineWidth: kalinlik, lineCap: .round, lineJoin: .round))
            .frame(width: boyut, height: boyut)
            .accessibilityHidden(true)
    }
}

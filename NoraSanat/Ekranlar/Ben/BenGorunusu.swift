// Kaynak: sanat-atlasi css/app.css (.ust, .ust-dugme, .etiket, .bolum-baslik, .ayar, .parcali, .adimlayici, .dugme,
// .dugme.ince, .konu, .anahtar, .secim-hap, .cubuk, .kutu-pip, .sv-iz, .pg-disk), js/tasarim.js YOLLAR @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt genişlik, Gece) alındı; renkler TemaDeposu'ndan.
import NoraCekirdek
import SwiftUI

// MARK: Simgeler

/// Ben ve Ayarlar'ın simgeleri: js/tasarim.js `YOLLAR[ad]`, olduğu gibi (24'lük viewBox, çizgi)
enum BenSimge {
    case geri, ileri, ayarlar, isaret, kilit, dogru, karsilastir, kapat, hareket, muhur, kumSaati

    var isaretleme: String {
        switch self {
        case .geri: return #"<path d="m15 18-6-6 6-6"/>"#
        case .ileri: return #"<path d="m9 18 6-6-6-6"/>"#
        case .ayarlar: return SekmeCubugu.Simge.ayarlar.isaretleme
        case .isaret: return #"<path d="M6.5 4h11a1 1 0 0 1 1 1v15l-6.5-4-6.5 4V5a1 1 0 0 1 1-1z"/>"#
        case .kilit: return #"<rect x="5.5" y="10.5" width="13" height="9" rx="1.5"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>"#
        case .dogru: return #"<path d="M20 6 9 17l-5-5"/>"#
        case .karsilastir: return #"<rect x="3" y="4" width="7.5" height="16" rx="1.5"/><rect x="13.5" y="4" width="7.5" height="16" rx="1.5"/>"#
        case .kapat: return #"<path d="M18 6 6 18"/><path d="m6 6 12 12"/>"#
        case .hareket: return #"<rect x="8" y="3" width="8" height="18" rx="2"/><path d="M11 18h2"/><path d="M4.5 8.5a7.5 7.5 0 0 0 0 7"/><path d="M19.5 8.5a7.5 7.5 0 0 1 0 7"/>"#
        case .muhur: return #"<circle cx="12" cy="9.500" r="5.500"/><path d="M9 14.200 7.500 21l4.500-2.500 4.500 2.500-1.500-6.800"/>"#
        case .kumSaati: return #"<path d="M7 3.500h10M7 20.500h10M8 3.500c0 4 4 5.500 4 8.500s-4 4.500-4 8.500M16 3.500c0 4-4 5.500-4 8.500s4 4.500 4 8.500"/>"#
        }
    }
}

/// `ikon(ad, boyut, kalinlik)`
struct BenIkon: View {
    let simge: BenSimge
    var boyut: CGFloat = 20
    var kalinlik: CGFloat = 1.4

    var body: some View {
        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: simge.isaretleme))
            .stroke(style: StrokeStyle(lineWidth: kalinlik, lineCap: .round, lineJoin: .round))
            .frame(width: boyut, height: boyut)
            .accessibilityHidden(true)
    }
}

// MARK: Ölçüler

enum BenOlcu {
    /// `--yan`
    static let yan: CGFloat = 24
}

private let turkce = Locale(identifier: "tr_TR")

extension Yazi.Aile {
    /// Yazı tipinin kendi satır yüksekliği (hhea: (ascent − descent + lineGap) / unitsPerEm). SwiftUI satırı bununla
    /// çizer; sitede ise CSS `line-height` geçerli. Bodoni Moda 2250/−800/2000, Archivo 878/−210/1000, Newsreader 1470/−530/2000.
    /// Newsreader'ın tablodan çıkan 1.0'ı iOS'ta tutmuyor: CI'da Bugün Hayatı'nın 19/29.45 metninde yerli satır adımı 29.92
    /// ölçüldü (G4b, satır başına +0.47 pt) → gerçek doğal satır ≈ 1.0247 × boyut (Z3b; uzun okuma metinleri artık kaymıyor).
    var satirOrani: CGFloat {
        switch self {
        case .serif: return 1.525
        case .sans: return 1.088
        case .okuma: return 1.0247
        }
    }
}

extension View {
    /// CSS `line-height`'ı uygular: satır arası ve ilk/son satırın yarım boşluğu sitedeki gibi olur
    /// (ör. `.ayar > b`: 22 px Bodoni, 26.4 px satır → yazının üstü ve altı 3.6 pt daralır).
    func cssSatir(_ aile: Yazi.Aile, _ boyut: CGFloat, _ satir: CGFloat) -> some View {
        let fark = satir - boyut * aile.satirOrani
        return lineSpacing(max(0, fark)).padding(.vertical, fark / 2)
    }
}

// MARK: Yazılar

/// `.etiket`: 600 11px Archivo, 0.2em aralık, büyük harf, `--ink-2`
struct Etiket: View {
    let metin: String
    var boyut: CGFloat = 11
    var aralik: CGFloat = 0.2
    @Environment(TemaDeposu.self) private var tema

    init(_ metin: String, boyut: CGFloat = 11, aralik: CGFloat = 0.2) {
        self.metin = metin
        self.boyut = boyut
        self.aralik = aralik
    }

    var body: some View {
        Text(metin.uppercased(with: turkce))
            .font(Yazi.sans(boyut, agirlik: 600, stil: .caption2))
            .tracking(boyut * aralik)
            .foregroundStyle(Color(tema.renkler.murekkep2))
    }
}

/// `h2.etiket.bolum-baslik`: üstte 28, altta 10 boşluk
struct BolumBasligi: View {
    let metin: String
    init(_ metin: String) { self.metin = metin }
    var body: some View {
        Etiket(metin)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 28).padding(.bottom, 10)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: Üst

/// `.ust`: solda yuvarlak geri düğmesi, büyük serif başlık (Ben ve Ayarlar'da 48 px), sağda isteğe bağlı düğme.
/// `html .ust-dugme`: 44×44, `--surface` zemin, 1 px `--border`, `--ink`.
struct BenUst<Sag: View>: View {
    let baslik: String
    let geri: () -> Void
    /// Ben'de 48 (`.pk-ust .ust h1`), Ayarlar'da 40 (`.ust h1`); ikisinde de `line-height: 1`
    var boyut: CGFloat = 48
    @ViewBuilder var sag: Sag
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: geri) { BenIkon(simge: .geri, boyut: 22, kalinlik: 1.4) }
                .buttonStyle(YuvarlakDugme())
                .accessibilityLabel("Geri")
            Text(baslik)
                .font(Yazi.serif(boyut, stil: .largeTitle))
                .cssSatir(.serif, boyut, boyut)
                .foregroundStyle(Color(tema.renkler.murekkep))
                .shadow(color: Color(tema.renkler.zemin).opacity(0.6), radius: 12, y: 2)
                .lineLimit(1).minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            sag
        }
        .padding(.leading, -12)
        .padding(.trailing, -10)
        .frame(minHeight: 52)
    }
}

extension BenUst where Sag == EmptyView {
    init(baslik: String, boyut: CGFloat = 48, geri: @escaping () -> Void) {
        self.init(baslik: baslik, geri: geri, boyut: boyut) { EmptyView() }
    }
}

/// `html .ust-dugme`, `.ust .geri`
struct YuvarlakDugme: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }

    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        var body: some View {
            configuration.label
                .foregroundStyle(Color(tema.renkler.murekkep))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(tema.renkler.yuzey)))
                .overlay(Circle().strokeBorder(Color(tema.renkler.kenar), lineWidth: 1))
                .contentShape(Circle())
                .scaleEffect(configuration.isPressed ? 0.94 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

// MARK: Çizgiler

/// 1 px `--border` çizgisi
struct Ayrac: View {
    var renk: KeyPath<TemaRenkleri, RGBA> = \.kenar
    @Environment(TemaDeposu.self) private var tema
    var body: some View { Rectangle().fill(Color(tema.renkler[keyPath: renk])).frame(height: 1) }
}

// MARK: Düğmeler

/// `.dugme` (Ayarlar'da `width: auto`, hap): `--surface`, iç kenar `--notr-kenar`, 600 15px; yükseklik 48.
/// `ince`: `.dugme.ince` — saydam, iç kenar beyaz %16, yazı `--ink-2`.
struct HapDugme: ButtonStyle {
    var ince = false
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration, ince: ince) }

    private struct Govde: View {
        let configuration: Configuration
        let ince: Bool
        @Environment(TemaDeposu.self) private var tema
        @Environment(\.isEnabled) private var etkin
        var body: some View {
            let r = tema.renkler
            configuration.label
                .font(Yazi.sans(15, agirlik: 600))
                .foregroundStyle(Color(ince ? r.murekkep2 : r.murekkep))
                .padding(.horizontal, 18)
                .frame(minHeight: 48)
                .background {
                    if !ince {
                        Capsule().fill(Color(r.yuzey))
                            .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.06), .white.opacity(0)],
                                                                   startPoint: .top, endPoint: .bottom)))
                    }
                }
                .overlay(Capsule().strokeBorder(ince ? Color.white.opacity(r.koyu ? 0.16 : 0) : Color(r.notrKenar), lineWidth: 1))
                .overlay { if ince && !r.koyu { Capsule().strokeBorder(Color(r.vurgu).opacity(0.4), lineWidth: 1) } }
                .contentShape(Capsule())
                .opacity(etkin ? 1 : 0.55)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
        }
    }
}

/// `pgDisk(ad, renk)`: 34 px yuvarlak pigment, içinde simge (Yedekle: mühür/okra, Geri yükle: kum saati/umbra)
struct PigmentDisk: View {
    enum Renk { case okra, umbra }
    let simge: BenSimge
    let renk: Renk
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let gece = tema.renkler.koyu
        let zemin: RGBA = switch renk {
        case .okra: gece ? RGBA(css: "#c09a55")! : RGBA(css: "#8a6420")!
        case .umbra: gece ? RGBA(css: "#8d7763")! : RGBA(css: "#5e4a3a")!
        }
        BenIkon(simge: simge, boyut: 18, kalinlik: 1.6)
            .foregroundStyle(Color(RGBA(css: gece ? "#14110e" : "#f7f5f1")!))
            .frame(width: 34, height: 34)
            .background(Circle().fill(Color(zemin)))
            .padding(.leading, -8)
    }
}

/// `.parcali`: üç sütunlu seçim ızgarası; seçili hapta `--vurgu-acik` kenar ve koyu vurgu zemin
struct ParcaliSecim<Deger: Hashable>: View {
    let ad: String
    let secenekler: [(deger: Deger, ad: String)]
    let secili: Deger
    var ornek: ((Deger) -> AnyView)? = nil
    let sec: (Deger) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(0..<secenekler.count, id: \.self) { i in
                let s = secenekler[i]
                let acik = s.deger == secili
                Button { sec(s.deger) } label: {
                    // `.gunduz-renkleri span`: 72 yükseklik, 8/4 dolgu, 6 aralık, 13 px
                    VStack(spacing: 6) {
                        if let ornek { ornek(s.deger) }
                        Text(s.ad).font(Yazi.sans(ornek == nil ? 14 : 13, agirlik: acik ? 700 : 500, stil: .subheadline))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, ornek == nil ? 0 : 8).padding(.horizontal, 4)
                    .foregroundStyle(Color(r.murekkep))
                    .frame(maxWidth: .infinity, minHeight: ornek == nil ? 48 : 72)
                    // seçili: `--surface` üstünde `--vurgu` (%55 Gece; sitede color-mix)
                    .background(RoundedRectangle(cornerRadius: ornek == nil ? 24 : 14, style: .continuous)
                        .fill(Color(r.yuzey))
                        .overlay(RoundedRectangle(cornerRadius: ornek == nil ? 24 : 14, style: .continuous)
                            .fill(Color(r.vurgu).opacity(acik ? (r.koyu ? 0.55 : 0.22) : 0))))
                    .overlay(RoundedRectangle(cornerRadius: ornek == nil ? 24 : 14, style: .continuous)
                        .strokeBorder(Color(acik ? r.vurguAcik : r.kenar), lineWidth: acik ? 2 : 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(acik ? [.isSelected] : [])
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ad)
    }
}

/// `.anahtar`: 46×28; açıkken `--vurgu-acik` zemin ve `--vurgu-acik-yazi` düğme, kapalıyken `--surface` ve `--ink-3`
/// `murekkep`: konu kartındaki anahtar (`.konu-karti-anahtar`): açıkken `--ink` zemin, `--bg` düğme.
struct AnahtarBicimi: ToggleStyle {
    var murekkep = false
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration, murekkep: murekkep) }

    private struct Govde: View {
        let configuration: Configuration
        let murekkep: Bool
        @Environment(TemaDeposu.self) private var tema
        @Environment(\.isEnabled) private var etkin
        var body: some View {
            let r = tema.renkler
            let acik = configuration.isOn
            Button { configuration.isOn.toggle() } label: {
                HStack(spacing: 12) {
                    configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                    ZStack(alignment: acik ? .trailing : .leading) {
                        let zemin = murekkep ? r.murekkep : r.vurguAcik
                        Capsule().fill(Color(acik ? zemin : r.yuzey))
                            .overlay(Capsule().strokeBorder(Color(acik ? zemin : r.kenar), lineWidth: 1))
                        Circle().fill(Color(acik ? (murekkep ? r.zemin : r.vurguAcikYazi) : r.murekkep3))
                            .frame(width: 20, height: 20).padding(.horizontal, 4)
                    }
                    .frame(width: 46, height: 28)
                    .animation(.easeOut(duration: 0.18), value: acik)
                }
                .frame(minHeight: murekkep ? 44 : 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(etkin ? 1 : 0.55)
            .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
        }
    }
}

/// `.konu .metin`: 600 15 px başlık, altında 12.5 px açıklama
struct AnahtarYazisi: View {
    let baslik: String
    let aciklama: String
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(baslik).font(Yazi.sans(15, agirlik: 600)).foregroundStyle(Color(tema.renkler.murekkep))
                .cssSatir(.sans, 15, 20.25)
            Text(aciklama).font(Yazi.sans(12.5, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep2))
                .cssSatir(.sans, 12.5, 16.875)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// `.secim-hap.kucuk-hap`: hap içinde iki küçük seçenek; seçili `--ink` zemin, `--bg` yazı
struct KucukHap<Deger: Hashable>: View {
    let secenekler: [(deger: Deger, ad: String)]
    @Binding var secili: Deger
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<secenekler.count, id: \.self) { i in dugme(i) }
        }
        .padding(3)
        .overlay(Capsule().strokeBorder(Color(tema.renkler.kenar), lineWidth: 1))
    }

    private func dugme(_ i: Int) -> some View {
        let r = tema.renkler
        let deger: Deger = secenekler[i].deger
        let acik: Bool = deger == secili
        let yazi: Color = acik ? Color(r.zemin) : Color(r.murekkep2)
        let zemin: Color = acik ? Color(r.murekkep) : Color.clear
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { secili = deger }
        } label: {
            Text(secenekler[i].ad).font(Yazi.sans(12, agirlik: 500, stil: .caption1))
                .foregroundStyle(yazi)
                .padding(.horizontal, 10).frame(minHeight: 28)
                .background(Capsule().fill(zemin))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(acik ? .isSelected : [])
    }
}

// MARK: Göstergeler

/// `.cubuk`: 4 px (zayıflarda 3 px) yuvarlak çubuk; dolu kısım `--vurgu-acik` (zayıflarda `--wrong`)
struct OranCubugu: View {
    let oran: Double
    var yukseklik: CGFloat = 4
    var renk: KeyPath<TemaRenkleri, RGBA> = \.vurguAcik
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(tema.renkler.kenar))
                Capsule().fill(Color(tema.renkler[keyPath: renk])).frame(width: g.size.width * min(1, max(0, oran)))
            }
        }
        .frame(height: yukseklik)
        .accessibilityHidden(true)
    }
}

/// `kutuPipHtml(kutu)`: altı nokta; kutuya kadar dolu
struct KutuPip: View {
    let kutu: Int
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<6, id: \.self) { i in
                Circle().fill(i <= kutu ? Color(tema.renkler.vurguAcik) : .clear)
                    .overlay(Circle().strokeBorder(Color(i <= kutu ? tema.renkler.vurguAcik : tema.renkler.murekkep3), lineWidth: 1))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }
}

/// `seviyeIziHtml(kayit)`: Kolay · Orta · Zor üç parçalı iz
struct SeviyeIzi: View {
    let kayit: SeviyeKaydi
    var genislik: CGFloat = 60
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        let n = Double(kayit.son.count)
        let p = Seviye.usta(kayit) ? 1 : min(1, n / Double(Seviye.enAz)) * min(1, Seviye.oran(kayit.son) / Seviye.gecisOrani)
        HStack(spacing: 3) {
            ForEach(Seviye.seviyeler, id: \.no) { x in
                OranCubugu(oran: x.no < kayit.s ? 1 : x.no == kayit.s ? p : 0, yukseklik: 3)
            }
        }
        .frame(width: genislik)
        .accessibilityHidden(true)
    }
}

/// `.akim-nokta`: akımın rengi, 7 px
struct AkimNoktasi: View {
    let renk: String
    var body: some View {
        Circle().fill(Color(RGBA(css: renk) ?? RGBA(css: "#8A827A")!)).frame(width: 7, height: 7).accessibilityHidden(true)
    }
}

/// `.ayar`: 18 px dikey boşluk, altında `--border`; başlık 400 22px Bodoni, açıklama 13 px `--ink-2`
struct AyarBolumu<Icerik: View>: View {
    var baslik: String? = nil
    var aciklama: String? = nil
    var ilk = false
    @ViewBuilder var icerik: Icerik
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if ilk { Ayrac() }
            VStack(alignment: .leading, spacing: 0) {
                if let baslik {
                    Text(baslik).font(Yazi.serif(22)).foregroundStyle(Color(tema.renkler.murekkep))
                        .cssSatir(.serif, 22, 26.4)
                        .padding(.bottom, 4)
                        .accessibilityAddTraits(.isHeader)
                }
                if let aciklama { AyarAciklamasi(aciklama) }
                icerik
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            Ayrac()
        }
    }
}

/// `.ayar p`: 13 px, `--ink-2`
struct AyarAciklamasi: View {
    let metin: String
    init(_ metin: String) { self.metin = metin }
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Text(metin).font(Yazi.sans(13, stil: .footnote))
            .cssSatir(.sans, 13, 19.5)
            .foregroundStyle(Color(tema.renkler.murekkep2))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 7.2)
    }
}

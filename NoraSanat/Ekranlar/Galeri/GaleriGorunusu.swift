// Kaynak: sanat-atlasi css/app.css (.gz-ust, .arama-hapi, .arama-kalp, .bolumler, .hale, .bsy-hale, .bsy-desen, .ust,
// .ust-yazi, .sanatci-ust, .satir, .kucuk-kare, .eser, .izgara, .donem, .akim-nokta, .by-haplar), js/tasarim.js YOLLAR,
// js/ekranlar/gozat.js gozAtUst, js/ekranlar/ortak.js (sayfaZemini, ust, akimRenk), js/harita.js BOLGELER @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (iPhone 15 Pro, 393 pt, Gece) alındı; renkler TemaDeposu'ndan.
// Ben'in ortak parçaları (Etiket, BolumBasligi, BenUst, YuvarlakDugme, HapDugme, Ayrac, AkimNoktasi) burada da kullanılır.
import NoraCekirdek
import SwiftUI

// MARK: Simgeler

/// Galeri'nin simgeleri: js/tasarim.js `YOLLAR[ad]` (24'lük viewBox, çizgi); `ses` js/kunye.js'teki hoparlör
enum GaleriSimge {
    case ara, kalp, izgara, ileri, geri, asagi, kilit, buyut, ses, karsilastir, kapat, kitap, cik

    var isaretleme: String {
        switch self {
        case .ara: return #"<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>"#
        case .kalp: return #"<path d="M12 20s-7-4.3-7-9.5A4 4 0 0 1 12 8a4 4 0 0 1 7 2.5c0 5.2-7 9.500-7 9.500z"/>"#
        case .izgara:
            return #"<rect x="4" y="4" width="6.5" height="6.5" rx="1.2"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.2"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.2"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.2"/>"#
        case .ileri: return #"<path d="m9 18 6-6-6-6"/>"#
        case .geri: return #"<path d="m15 18-6-6 6-6"/>"#
        case .asagi: return #"<path d="m6 9 6 6 6-6"/>"#
        case .kilit: return #"<rect x="5.5" y="10.5" width="13" height="9" rx="1.5"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>"#
        case .buyut: return #"<path d="M14 5h5v5M10 19H5v-5M19 5l-6 6M5 19l6-6"/>"#
        case .ses: return #"<path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/>"#
        case .karsilastir: return #"<rect x="3" y="4" width="7.5" height="16" rx="1.5"/><rect x="13.5" y="4" width="7.5" height="16" rx="1.5"/>"#
        case .kapat: return #"<path d="M18 6 6 18"/><path d="m6 6 12 12"/>"#
        case .kitap:
            return #"<path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H11v16H5.5A1.5 1.5 0 0 1 4 18.5z"/><path d="M20 5.5A1.5 1.5 0 0 0 18.5 4H13v16h5.5a1.5 1.5 0 0 0 1.5-1.5z"/>"#
        case .cik: return #"<path d="M12 20V5"/><path d="m6 11 6-6 6 6"/>"#
        }
    }
}

/// `ikon(ad, boyut, kalinlik)`
struct GaleriIkon: View {
    let simge: GaleriSimge
    var boyut: CGFloat = 20
    var kalinlik: CGFloat = 1.6
    var dolu = false

    var body: some View {
        let sekil = SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: simge.isaretleme))
        ZStack {
            if dolu { sekil.fill() }
            sekil.stroke(style: StrokeStyle(lineWidth: kalinlik, lineCap: .round, lineJoin: .round))
        }
        .frame(width: boyut, height: boyut)
        .accessibilityHidden(true)
    }
}

// MARK: Renkler

enum GaleriRenk {
    /// `color-mix(in srgb, a p%, b)`
    static func karis(_ a: RGBA, _ b: RGBA, _ p: Double) -> RGBA {
        RGBA(a.r * p + b.r * (1 - p), a.g * p + b.g * (1 - p), a.b * p + b.b * (1 - p), a.a * p + b.a * (1 - p))
    }

    /// `akimRenk(ad)`: akimlar.json `renk`, yoksa #8A827A
    static func akim(_ k: SiteKatalogu, _ ad: String) -> RGBA {
        k.akimlar.first { $0.ad == ad }.flatMap { RGBA(css: $0.renk) } ?? RGBA(css: "#8A827A")!
    }

    /// `rgba(r, g, b, a)` ile aynı rengin saydamı
    static func saydam(_ c: RGBA, _ a: Double) -> RGBA { RGBA(c.r, c.g, c.b, a) }
}

extension Color {
    init(_ c: RGBA, _ opaklik: Double) { self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a * opaklik) }
}

// MARK: Dönemler

/// js/harita.js `BOLGELER` ve `bolgeBul(sira)`: sayfa zemininin deseni (`.bsy-desen[data-donem]`) akımın dönemiyle değişir
enum GaleriDonem {
    static let bolgeler: [(id: String, ilk: Double, son: Double)] = [
        ("ortacag", 0, 3), ("ronesans", 4, 8), ("barok", 9, 12), ("barok2", 13, 14), ("aydinlanma", 15, 16),
        ("romantik", 17, 20), ("empresyonizm", 21, 22), ("postempresyonizm", 23, 25), ("modern", 26, 99),
    ]

    static func bul(_ sira: Double) -> String {
        bolgeler.first { sira >= $0.ilk && sira <= $0.son }?.id ?? "modern"
    }

    /// `akiminDonemi(akim)`
    static func akimin(_ k: SiteKatalogu, _ ad: String) -> String? {
        k.akimlar.first { $0.ad == ad }.map { bul($0.sira) }
    }
}

// MARK: Zemin

/// `sayfaZemini(donem)`: sabit hale (`.hale.bsy-hale`, vurgu rengi sol üstte, sağ altta daha soluk) ve dönemin silik
/// sembolleri (`.bsy-desen`: 96 px karo, `--ink` %4; Gündüz'de %4,5). Karolar sitenin SVG'lerinden (Desenler/).
struct SayfaZemini: View {
    var donem: String?
    /// `.hale` (sanatçı, konu sayfaları): yalnız üstteki 520 px, sol üstten
    var ustHale = false
    /// Z3c (kullanıcının tasarım tuvali, `TabloRenkleri`): sayfanın ana tablosu. Zemin onun iki renginden süzülür: sol
    /// üstte birinci %50 → %16 → 0, sağ altta ikinci %36 → %10 → 0 (tasarımda %24 / %16; telefonda seçilmedi, Z3d'de
    /// kullanıcı üç güç arasından B'yi seçti). Verilmezse bu bölümde (Galeri / Çalış) son bakılan tablonunki; hiç yoksa
    /// sitenin tek renkli soluk halesi.
    var tablo: URL? = nil
    var alan: ZeminTablosu.Alan = .galeri
    /// Z3w (yeni tasarım, sitede yok; yon-2.html `.zemin-hale` üçüncü katman): kemerin arkasında tablonun birinci renginden
    /// ortada bir hale (66% × 36%, merkez 50% 38%; Gece %24, Gündüz %16 → %74'te sıfır). Yalnız Galeri › Akımlar'da.
    var ortaHale = false
    @Environment(TemaDeposu.self) private var tema
    @State private var cift: TabloRenkleri.Cift?
    private var kaynak: URL? { tablo ?? ZeminTablosu.shared.son[alan] }

    var body: some View {
        let r = tema.renkler
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                Color(r.zemin)
                if let c = cift {
                    // Z3j: Gündüz'de süzme kâğıdın üstüne çarpılarak (multiply) boyanır. Önceden aynı süzme %60 güçte ve
                    // normal karışımla açık zeminde neredeyse görünmüyordu (kullanıcı: "açık temada süzme yok").
                    let karisim: BlendMode = r.koyu ? .normal : .multiply
                    let k = r.koyu ? 1.0 : 0.85
                    elips(c.birinci, [(0.5 * k, 0), (0.16 * k, 0.5), (0, 0.85)], rx: 1.2 * w, ry: 0.6 * h, merkez: .topLeading, w: w, h: h)
                        .blendMode(karisim)
                    elips(c.ikinci, [(0.36 * k, 0), (0.1 * k, 0.45), (0, 0.8)], rx: 0.9 * w, ry: 0.5 * h, merkez: .bottomTrailing, w: w, h: h)
                        .blendMode(karisim)
                    if ortaHale {
                        let duraklar: [Gradient.Stop] = [.init(color: Color(c.birinci, r.koyu ? 0.24 : 0.16), location: 0),
                                                         .init(color: Color(c.birinci, 0), location: 0.74)]
                        EllipticalGradient(stops: duraklar, center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                            .frame(width: 1.32 * w, height: 0.72 * h)
                            .position(x: w / 2, y: 0.38 * h)
                            .blendMode(karisim)
                    }
                } else if ustHale {
                    elips(r.vurgu, [(0.11, 0), (0.03, 0.45), (0, 0.7)], rx: 1.2 * w, ry: 0.8 * 520, merkez: .topLeading, w: w, h: 520)
                } else {
                    elips(r.vurgu, [(0.1, 0), (0.025, 0.45), (0, 0.7)], rx: 1.2 * w, ry: 0.6 * h, merkez: .topLeading, w: w, h: h)
                    elips(r.vurgu, [(0.05, 0), (0, 0.7)], rx: 0.9 * w, ry: 0.5 * h, merkez: .bottomTrailing, w: w, h: h)
                }
                if let donem, let karo = UIImage(named: "desen-\(donem)") {
                    Image(uiImage: karo).renderingMode(.template).resizable(resizingMode: .tile)
                        .foregroundStyle(Color(r.murekkep, r.koyu ? 0.04 : 0.045))
                        .id(donem)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.6), value: donem)
            .animation(.easeInOut(duration: 0.8), value: cift)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .task(id: kaynak) {
            if let tablo { ZeminTablosu.shared.son[alan] = tablo }
            if let c = await TabloRengi.cift(kaynak) { cift = c }
        }
    }

    /// CSS `radial-gradient(rx ry at köşe, …)`: dairesel geçiş, dikeyde ölçeklenir
    private func elips(_ c: RGBA, _ duraklar: [(Double, Double)], rx: CGFloat, ry: CGFloat, merkez: UnitPoint,
                       w: CGFloat, h: CGFloat) -> some View {
        let oran = ry / rx
        return RadialGradient(stops: duraklar.map { .init(color: Color(c, $0.0), location: $0.1) },
                              center: merkez, startRadius: 0, endRadius: rx)
            .frame(width: w, height: h / oran)
            .scaleEffect(x: 1, y: oran, anchor: merkez)
            .frame(width: w, height: h, alignment: merkez == .topLeading ? .topLeading : .bottomTrailing)
    }
}

// MARK: Galeri üstü

/// `gozAtUst(etkin)`: "Galeri" başlığı, cam arama hapı ve kalp (Koleksiyon); altında yazılı dört bölüm sekmesi
struct GaleriUst: View {
    enum Bolum: Int, CaseIterable { case akimlar, basyapitlar, konular, zaman
        var ad: String { ["Akımlar", "Başyapıtlar", "Konular", "Zaman"][rawValue] }
        /// `.bolumler a:nth-child(2) { flex-grow: 1.3 }`
        var pay: CGFloat { self == .basyapitlar ? 1.3 : 1 }
    }
    let etkin: Bolum
    let koleksiyonDolu: Bool
    let ara: () -> Void
    let koleksiyon: () -> Void
    /// Z3j: arama sayfası bu haptan büyüyerek açılır (iOS 18)
    var aramaKaynagi: String? = nil
    var aramaAlani: Namespace.ID? = nil
    let sec: (Bolum) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 14) {
            // `.ust`: 52 yükseklik, 10 aralık; h1 400 32px/1 Bodoni
            HStack(spacing: 10) {
                Text("Galeri").font(Yazi.serif(32, stil: .largeTitle)).cssSatir(.serif, 32, 32)
                    .foregroundStyle(Color(r.murekkep)).fixedSize()
                    .accessibilityAddTraits(.isHeader)
                Button(action: ara) {
                    HStack(spacing: 8) {
                        GaleriIkon(simge: .ara, boyut: 18, kalinlik: 1.6)
                        Text("Sanatçı, eser ara").font(Yazi.sans(15, stil: .subheadline)).lineLimit(1)
                    }
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().fill(Color(r.ustDugme))))
                    .overlay(Capsule().strokeBorder(Color(r.kenar), lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .modifier(BuyuyerekAcilanKaynak(id: aramaKaynagi ?? "ara", alan: aramaKaynagi == nil ? nil : aramaAlani))
                .accessibilityLabel("Sanatçı, eser, konu ara")
                Button(action: koleksiyon) {
                    GaleriIkon(simge: .kalp, boyut: 20, kalinlik: 1.6, dolu: koleksiyonDolu)
                        .foregroundStyle(Color(koleksiyonDolu ? r.pirinc : r.murekkep2))
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(.ultraThinMaterial).overlay(Circle().fill(Color(r.ustDugme))))
                        .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(koleksiyonDolu ? "Beğendiklerin" : "Beğendiklerin (boş)")
            }
            .frame(height: 52)
            BolumHaplari(etkin: etkin, sec: sec)
        }
        .padding(.bottom, 8)
    }
}

/// `.bolumler`: 54 yükseklik, 4 iç boşluk, 2 aralık; seçili sekme `--ink` zemin, `--bg` yazı, 600 14px
struct BolumHaplari: View {
    let etkin: GaleriUst.Bolum
    let sec: (GaleriUst.Bolum) -> Void
    @Environment(TemaDeposu.self) private var tema
    @Namespace private var hap

    var body: some View {
        let r = tema.renkler
        GeometryReader { g in
            let ic = g.size.width - 10 - 2 * 3
            let birim = ic / GaleriUst.Bolum.allCases.reduce(0) { $0 + $1.pay }
            HStack(spacing: 2) {
                ForEach(GaleriUst.Bolum.allCases, id: \.self) { b in
                    let acik = b == etkin
                    Button { sec(b) } label: {
                        Text(b.ad)
                            .font(Yazi.sans(14, agirlik: acik ? 600 : 500, stil: .subheadline))
                            .lineLimit(1).minimumScaleFactor(0.8)
                            .foregroundStyle(Color(acik ? r.zemin : r.murekkep2))
                            .frame(width: birim * b.pay, height: 44)
                            .background { if acik { Capsule().fill(Color(r.murekkep)).matchedGeometryEffect(id: "hap", in: hap) } }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(acik ? .isSelected : [])
                }
            }
            .padding(4)
            .frame(width: g.size.width, height: 54)
            .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().fill(Color(r.ustDugme))))
            .overlay(Capsule().strokeBorder(Color(r.kenar), lineWidth: 1))
        }
        .frame(height: 54)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Galeri bölümleri")
    }
}

// MARK: Sayfa üstleri

/// `ust(baslik, geri, { ustEtiket })`: yuvarlak geri, üstte küçük etiket (11 px, 0.2em), altında 40 px Bodoni başlık
struct GaleriSayfaUst: View {
    let etiket: String
    let baslik: String
    let geri: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Button(action: geri) { GaleriIkon(simge: .geri, boyut: 22, kalinlik: 1.4) }
                .buttonStyle(YuvarlakDugme())
                .accessibilityLabel("Geri")
                .padding(.leading, -12)
            VStack(alignment: .leading, spacing: 4) {
                Etiket(etiket)
                Text(baslik).font(Yazi.serif(40, stil: .largeTitle)).cssSatir(.serif, 40, 40)
                    .foregroundStyle(Color(tema.renkler.murekkep))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 60, alignment: .bottom)
        .padding(.bottom, 10)
    }
}

/// `.sanatci-ust`: çerçevesiz geri oku ve vurgulu etiket (akım ya da konu grubu; dokununca oraya gider)
struct SanatciUst: View {
    let etiket: String
    let geri: () -> Void
    var etiketeDokun: (() -> Void)? = nil
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        HStack(spacing: 6) {
            Button(action: geri) {
                GaleriIkon(simge: .geri, boyut: 22, kalinlik: 1.4)
                    .foregroundStyle(Color(tema.renkler.murekkep2))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Geri")
            Button { (etiketeDokun ?? geri)() } label: { Etiket(etiket).frame(minHeight: 44) }
                .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.leading, -12)
        .frame(minHeight: 48)
        .padding(.bottom, 10)
    }
}

/// `.etiket.vurgu`: 600 11 px, 0.2em, büyük harf; renk `--pirinc` (Galeri'nin tek sabit vurgusu)
struct VurguEtiket: View {
    let metin: String
    var boyut: CGFloat = 11
    var aralik: CGFloat = 0.2
    var renk: RGBA?
    @Environment(TemaDeposu.self) private var tema
    init(_ metin: String, boyut: CGFloat = 11, aralik: CGFloat = 0.2, renk: RGBA? = nil) {
        self.metin = metin; self.boyut = boyut; self.aralik = aralik; self.renk = renk
    }
    var body: some View {
        Text(metin.uppercased(with: Locale(identifier: "tr_TR")))
            .font(Yazi.sans(boyut, agirlik: 600, stil: .caption2))
            .tracking(boyut * aralik)
            .foregroundStyle(Color(renk ?? tema.renkler.pirinc))
    }
}

// MARK: Satırlar ve kartlar

/// `sanatciSatiri(s, acik)` (`.satir`): 52 px küçük kare, 22 px Bodoni ad, 13 px yıllar, sağda ileri; kilitliyse soluk,
/// karesiz ve "Konu n'de açılır"
struct GaleriSatir: View {
    let ad: String
    let alt: String
    var rozet: String? = nil
    var kare: URL? = nil
    var kilitli = false
    var kareVar = true
    let ac: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: ac) {
            HStack(spacing: 14) {
                if kareVar && !kilitli {
                    UzakGorsel(url: kare, icerik: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(ad).font(Yazi.serif(22)).cssSatir(.serif, 22, 24.2)
                            .foregroundStyle(Color(kilitli ? r.murekkep2 : r.murekkep))
                            .fixedSize(horizontal: false, vertical: true)
                        if let rozet { Rozet(metin: rozet) }
                    }
                    Text(alt).font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 19.5)
                        .foregroundStyle(Color(r.murekkep2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !kilitli {
                    GaleriIkon(simge: .ileri, boyut: 20, kalinlik: 1.4).foregroundStyle(Color(r.murekkep3))
                }
            }
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!kilitli)
    }
}

/// `.rozet`: küçük hap ("kurs dışı", "Henüz kursta yok")
struct Rozet: View {
    let metin: String
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Text(metin).font(Yazi.sans(11, agirlik: 600, stil: .caption2))
            .foregroundStyle(Color(tema.renkler.murekkep2))
            .padding(.horizontal, 7).padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(Color(tema.renkler.kenar), lineWidth: 1))
    }
}

/// `.liste`: üstte ve satır aralarında 1 px `--border`
struct GaleriListe<Oge: Identifiable, Satir: View>: View {
    let ogeler: [Oge]
    @ViewBuilder let satir: (Oge) -> Satir
    var body: some View {
        VStack(spacing: 0) {
            Ayrac()
            ForEach(ogeler) { o in
                satir(o)
                Ayrac()
            }
        }
    }
}

/// `eserSeridi` düğmesi (`.eser`): kırpılmadan sabit yükseklikte resim (4 px köşe, `--surface`), altında 17 px Newsreader ad
/// ve 13 px tarih. Şeritte genişlik oranından, ızgarada sütun genişliği.
struct EserKarti: View {
    let eser: Eser
    let url: URL?
    var yedek: URL? = nil
    var oran: Double?
    var yukseklik: CGFloat
    var genislik: CGFloat?
    var alt: String? = nil
    var kirp = false
    let ac: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let w = genislik ?? yukseklik * CGFloat(oran ?? 1)
        Button(action: ac) {
            VStack(alignment: .leading, spacing: 0) {
                UzakGorsel(url: url, icerik: kirp ? .fill : .fit, yedek: yedek)
                    .frame(width: w, height: genislik == nil || kirp ? yukseklik : min(yukseklik, w / CGFloat(oran ?? 1)))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .frame(width: w, alignment: .leading)
                Text(eser.gorunenAd).font(Yazi.okuma(17)).cssSatir(.okuma, 17, 20.74)
                    .foregroundStyle(Color(r.murekkep))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                if let a = alt ?? (eser.tarih.isEmpty ? nil : eser.tarih) {
                    Text(a).font(Yazi.sans(13, agirlik: 500, stil: .footnote)).cssSatir(.sans, 13, 17.55)
                        .foregroundStyle(Color(r.murekkep2))
                        .padding(.top, 4)
                }
            }
            .frame(width: w, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(eser.gorunenAd) — büyüt")
    }
}

/// `donemCizelgesi(akim)` (`.donem`): üç sütun; ortada akım (600, üstte 4 px akım rengi), yanlarda önceki ve sonraki
struct DonemCizelgesi: View {
    let akimlar: [Akim]
    let ad: String
    let git: (String) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let i = akimlar.firstIndex { $0.ad == ad }
        let onceki = i.flatMap { $0 > 0 ? akimlar[$0 - 1] : nil }
        let sonraki = i.flatMap { $0 + 1 < akimlar.count ? akimlar[$0 + 1] : nil }
        HStack(alignment: .top, spacing: 8) {
            sutun(onceki.map { "← " + $0.ad }, cizgi: r.kenar, renk: r.murekkep3, agirlik: 400, hiza: .leading) {
                if let onceki { git(onceki.ad) }
            }
            sutun(ad, cizgi: RGBA(css: akimlar.first { $0.ad == ad }?.renk ?? "") ?? r.vurgu, renk: r.murekkep, agirlik: 600,
                  hiza: .center) {}
            sutun(sonraki.map { $0.ad + " →" }, cizgi: r.kenar, renk: r.murekkep3, agirlik: 400, hiza: .trailing) {
                if let sonraki { git(sonraki.ad) }
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Akım zaman çizelgesi")
    }

    private func sutun(_ metin: String?, cizgi: RGBA, renk: RGBA, agirlik: CGFloat, hiza: Alignment,
                       eylem: @escaping () -> Void) -> some View {
        Button(action: eylem) {
            VStack(spacing: 0) {
                Rectangle().fill(Color(metin == nil ? tema.renkler.kenar : cizgi)).frame(height: 4)
                Text(metin ?? " ").font(Yazi.sans(12.5, agirlik: agirlik, stil: .footnote)).cssSatir(.sans, 12.5, 16.25)
                    .foregroundStyle(Color(renk))
                    .lineLimit(2).minimumScaleFactor(0.85)
                    .multilineTextAlignment(hiza == .leading ? .leading : hiza == .trailing ? .trailing : .center)
                    .frame(maxWidth: .infinity, alignment: hiza)
                    .padding(.top, 8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(metin == nil)
        .frame(maxWidth: .infinity)
    }
}

/// `.bolum` (sanatçı ve konu sayfaları): üstte 1 px çizgi, 26 boşluk, etiket, 8 aralık
struct GaleriBolum<Icerik: View>: View {
    let etiket: String
    var vurgu = false
    @ViewBuilder var icerik: Icerik

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if vurgu { VurguEtiket(etiket) } else { Etiket(etiket) }
            icerik
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 26)
        .overlay(alignment: .top) { Ayrac() }
        .padding(.top, 16)
    }
}

/// `p.okuma`: 19 px Newsreader, satır 27.55
struct OkumaMetni: View {
    let metin: String
    var italik = false
    var boyut: CGFloat = 19
    var satir: CGFloat = 27.55
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Text(metin).font(Yazi.okuma(boyut, italik: italik)).cssSatir(.okuma, boyut, satir)
            .foregroundStyle(Color(tema.renkler.murekkep))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Yerli sayfalarda gizli gezinme çubuğu: kenardan kaydırarak geri dönme yine çalışsın
/// (`.toolbar(.hidden)` UIKit'in geri hareketini kapatıyor; sitede de yandan kaydırma geri götürür).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

/// Z3c: bölümde (Galeri, Çalış) son bakılan ana tablo; ana tablosu olmayan sayfalar (arama, koleksiyon, listeler) zemini
/// bundan alır, geçişte renk kopmaz
@MainActor @Observable
final class ZeminTablosu {
    enum Alan: Hashable { case galeri, calis }
    static let shared = ZeminTablosu()
    var son: [Alan: URL] = [:]
}

/// Z3c: tablonun küçük kopyasından iki süzme rengi (`TabloRenkleri.cift`); adres başına bir kez hesaplanır
@MainActor
enum TabloRengi {
    private static var onbellek: [URL: TabloRenkleri.Cift] = [:]

    static func cift(_ url: URL?) async -> TabloRenkleri.Cift? {
        guard let url else { return nil }
        if let c = onbellek[url] { return c }
        guard let resim = await GorselCozucu.shared.resim(url, piksel: 200), let cg = resim.cgImage else { return nil }
        let c = await Task.detached(priority: .utility) { () -> TabloRenkleri.Cift? in
            let n = 24
            var veri = [UInt8](repeating: 0, count: n * n * 4)
            let tamam = veri.withUnsafeMutableBytes { tampon -> Bool in
                guard let baglam = CGContext(data: tampon.baseAddress, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                baglam.interpolationQuality = .medium
                baglam.draw(cg, in: CGRect(x: 0, y: 0, width: n, height: n))
                return true
            }
            guard tamam else { return nil }
            let px = stride(from: 0, to: veri.count, by: 4).map { i in
                (Double(veri[i]) / 255, Double(veri[i + 1]) / 255, Double(veri[i + 2]) / 255)
            }
            return TabloRenkleri.cift(pikseller: px)
        }.value
        if let c { onbellek[url] = c }
        return c
    }
}

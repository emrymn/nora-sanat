import CoreText
import NoraCekirdek
import SwiftUI
import UIKit

/// Uygulamanın teması (ISLER.md K5): sitenin renkleri ve yazı tipleri.
///
/// - Renkler: Z2c-2'den beri siteden okunmaz; `TemaHesabi` ayarlardan ve günün tablosundan sitenin kurallarıyla
///   hesaplar (renkli Gündüz ve tablonun vurgusu dahil). İlk hesaba kadar css/app.css'teki sabit tablo (`TemaRenkleri.gece`).
/// - Ekranlar `@Environment(TemaDeposu.self) var tema` ile okur: `Color(tema.renkler.murekkep)`, `Yazi.serif(28)`.
@MainActor
@Observable
final class TemaDeposu {
    static let shared = TemaDeposu()

    /// Sitenin renk değişkenleri
    private(set) var renkler: TemaRenkleri = .gece
    /// Sitenin görünüş ayarları (tema, hareket, yazı)
    private(set) var ayar = TemaAyari()
    /// Sitenin `theme-color`'ı (`temaZemini()`): pencerenin zemini ve durum çubuğu
    private(set) var siteRengi = UIColor(TemaRenkleri.gece.zemin)
    /// Z3m: renkli Gündüz paleti (ekranın kendi vurgusu `EkranRengi` bununla aynı temayı yeniden hesaplar)
    private(set) var gunduz: GunduzPaleti?

    init() {}

    /// Z3m: bir ekranın kendi rengi (`EkranRengi`): temanın aynısı, vurgu o ekranın eserinden
    init(renkler: TemaRenkleri, ayar: TemaAyari, siteRengi: UIColor, gunduz: GunduzPaleti?) {
        self.renkler = renkler; self.ayar = ayar; self.siteRengi = siteRengi; self.gunduz = gunduz
    }

    /// Durum çubuğu ve sistem öğeleri koyu zemine göre mi
    var koyu: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        siteRengi.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b < 0.5
    }

    /// `TemaHesabi`'nın sonucu
    func uygula(_ r: TemaRenkleri, ayar a: TemaAyari, zemin: RGBA, gunduz g: GunduzPaleti? = nil) {
        if a != ayar { ayar = a }
        if g != gunduz { gunduz = g }
        if r != renkler { renkler = r }
        let yeni = UIColor(zemin)
        if !yeni.isEqual(siteRengi) { siteRengi = yeni }
    }
}

extension Color {
    init(_ c: RGBA) { self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a) }
}

extension UIColor {
    convenience init(_ c: RGBA) { self.init(red: c.r, green: c.g, blue: c.b, alpha: c.a) }
}

// MARK: - Yazı tipleri

/// Sitenin yazı tipleri (css/app.css `--serif`, `--sans`, `--okuma`), uygulamayla gelir (NoraSanat/YaziTipleri, OFL):
/// - `serif`: Bodoni Moda (başlıklar, adlar)
/// - `sans`: Archivo (arayüz)
/// - `okuma`: Newsreader (okuma metni)
/// Üçü de değişken yazı tipi: ağırlık (`wght`) ve optik boyut (`opsz`, sitedeki `font-optical-sizing: auto` gibi yazı
/// boyuna eşit) eksenlerle verilir. Boyut Dinamik Yazı'yla ölçeklenir (`stil`). Yazı tipi yüklenemezse sistemin
/// benzeri (serif / varsayılan) kullanılır.
enum Yazi {
    enum Aile {
        case serif, sans, okuma

        func ad(italik: Bool) -> String {
            switch self {
            case .serif: return italik ? "BodoniModa-Italic" : "BodoniModa-Regular"
            case .okuma: return italik ? "Newsreader16pt-Italic" : "Newsreader16pt-Regular"
            case .sans: return "Archivo-SemiBold"
            }
        }

        /// Eksenlerin sınırları (fvar)
        var agirlikAraligi: ClosedRange<CGFloat> {
            switch self {
            case .serif: return 400...900
            case .okuma: return 200...800
            case .sans: return 100...900
            }
        }

        var optikAraligi: ClosedRange<CGFloat>? {
            switch self {
            case .serif: return 6...96
            case .okuma: return 6...72
            case .sans: return nil
            }
        }
    }

    private static let wght = 0x7767_6874 as NSNumber   // 'wght'
    private static let opsz = 0x6F70_737A as NSNumber   // 'opsz'
    private static var kayitli = false

    /// Uygulamayla gelen yazı tiplerini bu süreç için kaydeder (açılışta bir kez)
    static func kaydet() {
        guard !kayitli else { return }
        kayitli = true
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Yazı tipi yüklendi mi (DEBUG tema ekranı gösterir)
    static func yuklu(_ aile: Aile) -> Bool { UIFont(name: aile.ad(italik: false), size: 12) != nil }

    static func uiFont(_ aile: Aile, _ boyut: CGFloat, agirlik: CGFloat = 400, italik: Bool = false) -> UIFont {
        kaydet()
        let ad = aile.ad(italik: italik)
        guard UIFont(name: ad, size: boyut) != nil else {
            let sistem = UIFont.systemFont(ofSize: boyut, weight: sistemAgirligi(agirlik))
            var tanim = sistem.fontDescriptor
            if aile != .sans, let s = tanim.withDesign(.serif) { tanim = s }
            if italik, let i = tanim.withSymbolicTraits(.traitItalic) { tanim = i }
            return UIFont(descriptor: tanim, size: boyut)
        }
        var eksen: [NSNumber: CGFloat] = [wght: min(max(agirlik, aile.agirlikAraligi.lowerBound), aile.agirlikAraligi.upperBound)]
        if let o = aile.optikAraligi { eksen[opsz] = min(max(boyut, o.lowerBound), o.upperBound) }
        let tanim = UIFontDescriptor(fontAttributes: [
            .name: ad,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): eksen,
        ])
        // Z3l: Archivo'nun eğik hali yok; tarayıcı `<i>`'yi eğerek üretir (WebKit: 14°). Uygulamada `.italic()` özel yazı
        // tipinde hiçbir şey yapmıyordu (Galeri "Arkadaki eser"de eser adı düz kalıyordu).
        if italik, aile == .sans {
            let egik = tanim.withMatrix(CGAffineTransform(a: 1, b: 0, c: tan(14 * .pi / 180), d: 1, tx: 0, ty: 0))
            return UIFont(descriptor: egik, size: boyut)
        }
        return UIFont(descriptor: tanim, size: boyut)
    }

    private static func sistemAgirligi(_ w: CGFloat) -> UIFont.Weight {
        switch w {
        case ..<250: return .light
        case ..<450: return .regular
        case ..<550: return .medium
        case ..<650: return .semibold
        default: return .bold
        }
    }

    /// `boyut` CSS pikseli (= nokta); `stil` Dinamik Yazı ölçeği için
    static func font(_ aile: Aile, _ boyut: CGFloat, agirlik: CGFloat = 400, italik: Bool = false,
                     stil: UIFont.TextStyle = .body) -> Font {
        Font(UIFontMetrics(forTextStyle: stil).scaledFont(for: uiFont(aile, boyut, agirlik: agirlik, italik: italik)))
    }

    /// Bodoni Moda (sitede başlıklar 400–500)
    static func serif(_ boyut: CGFloat, agirlik: CGFloat = 400, italik: Bool = false, stil: UIFont.TextStyle = .title2) -> Font {
        font(.serif, boyut, agirlik: agirlik, italik: italik, stil: stil)
    }

    /// Archivo (arayüz; sitede 400–700)
    static func sans(_ boyut: CGFloat, agirlik: CGFloat = 400, italik: Bool = false, stil: UIFont.TextStyle = .body) -> Font {
        font(.sans, boyut, agirlik: agirlik, italik: italik, stil: stil)
    }

    /// Newsreader (okuma metni; sitede 400–500)
    static func okuma(_ boyut: CGFloat, agirlik: CGFloat = 400, italik: Bool = false, stil: UIFont.TextStyle = .body) -> Font {
        font(.okuma, boyut, agirlik: agirlik, italik: italik, stil: stil)
    }
}

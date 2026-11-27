// Kaynak: sanat-atlasi css/app.css `:root` değişkenleri (gece ve gündüz), js/ekranlar/ortak.js `TEMA_RENK` @ a866b86
// (site 1.90.3). Tasarım dili: TASARIM_DILI.md.
// Renkli Gündüz'de (js/gunduzRenk.js) site bu değişkenleri günün tablosunun paletiyle değiştirir; uygulama o anki
// değerleri siteden alır (`TemaRenkleri(degiskenler:)`). Sabit tablolar site açılmadan önce ve sınamada kullanılır.
// Kâhin: Testler/kahin/tema.mjs (sitenin hesapladığı değişkenler gece ve gündüzde).
import Foundation

/// sRGB renk, 0…1
public struct RGBA: Hashable, Sendable, CustomStringConvertible {
    public var r: Double, g: Double, b: Double, a: Double

    public init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    /// "#121110", "#fff", "#12111080", "rgb(18, 17, 16)", "rgba(18,17,16,0.8)", "rgb(18 17 16 / 80%)", "transparent"
    public init?(css: String) {
        let s = css.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s == "transparent" { self.init(0, 0, 0, 0); return }
        if s.hasPrefix("#") {
            var h = String(s.dropFirst())
            guard h.allSatisfy(\.isHexDigit) else { return nil }
            if h.count == 3 || h.count == 4 { h = h.map { "\($0)\($0)" }.joined() }
            guard h.count == 6 || h.count == 8, let n = UInt64(h, radix: 16) else { return nil }
            let a = h.count == 8 ? Double(n & 0xFF) / 255 : 1
            let v = h.count == 8 ? n >> 8 : n
            self.init(Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255, a)
            return
        }
        guard let ac = s.firstIndex(of: "("), s.hasSuffix(")") else { return nil }
        let ad = s[..<ac].trimmingCharacters(in: .whitespaces)
        guard ad == "rgb" || ad == "rgba" else { return nil }
        let ic = s[s.index(after: ac)..<s.index(before: s.endIndex)]
            .replacingOccurrences(of: "/", with: " ").replacingOccurrences(of: ",", with: " ")
        let p = ic.split(separator: " ").map(String.init)
        guard p.count == 3 || p.count == 4 else { return nil }
        func kanal(_ x: String) -> Double? {
            if x.hasSuffix("%") { return Double(x.dropLast()).map { $0 / 100 } }
            return Double(x).map { $0 / 255 }
        }
        func alfa(_ x: String) -> Double? {
            if x.hasSuffix("%") { return Double(x.dropLast()).map { $0 / 100 } }
            return Double(x)
        }
        guard let r = kanal(p[0]), let g = kanal(p[1]), let b = kanal(p[2]) else { return nil }
        let a = p.count == 4 ? alfa(p[3]) : 1
        guard let a else { return nil }
        self.init(min(1, max(0, r)), min(1, max(0, g)), min(1, max(0, b)), min(1, max(0, a)))
    }

    /// "#121110" (saydamlık varsa "#12111080")
    public var hex: String {
        func iki(_ x: Double) -> String {
            let n = Int((min(1, max(0, x)) * 255).rounded())
            return String(n, radix: 16).count == 1 ? "0" + String(n, radix: 16) : String(n, radix: 16)
        }
        return "#" + iki(r) + iki(g) + iki(b) + (a < 1 ? iki(a) : "")
    }

    public var description: String { hex }

    /// Göreli parlaklık (yazının açık mı koyu mu olacağı için)
    public var parlaklik: Double { 0.299 * r + 0.587 * g + 0.114 * b }
    public var koyu: Bool { parlaklik < 0.5 }
}

/// Sitenin iki teması
public enum TemaAdi: String, CaseIterable, Sendable {
    case gece, gunduz

    /// Ayarlar'daki ad
    public var ad: String { self == .gece ? "Gece" : "Gündüz" }
}

/// Sitenin renk değişkenleri (css/app.css `:root`). Adlar sitedeki değişkenin Türkçe karşılığı; yorumda CSS adı.
public struct TemaRenkleri: Hashable, Sendable {
    /// `--bg`: zemin
    public var zemin: RGBA
    /// `--surface`: kart yüzeyi
    public var yuzey: RGBA
    /// `--border`
    public var kenar: RGBA
    /// `--ink`: ana yazı
    public var murekkep: RGBA
    /// `--ink-2`: ikincil yazı
    public var murekkep2: RGBA
    /// `--ink-3`: üçüncül yazı
    public var murekkep3: RGBA
    /// `--ink-soluk`
    public var soluk: RGBA
    /// `--right`, `--right-ikon`, `--right-bg`
    public var dogru: RGBA
    public var dogruIkon: RGBA
    public var dogruZemin: RGBA
    /// `--wrong`, `--wrong-ikon`, `--wrong-bg`
    public var yanlis: RGBA
    public var yanlisIkon: RGBA
    public var yanlisZemin: RGBA
    /// `--tab-bg`: sekme çubuğu zemini
    public var sekmeZemin: RGBA
    /// `--overlay-btn`: görselin üstündeki düğme
    public var ustDugme: RGBA
    /// `--vurgu`, `--vurgu-yazi`, `--vurgu-acik`, `--vurgu-acik-yazi`, `--vurgu-koyu`
    public var vurgu: RGBA
    public var vurguYazi: RGBA
    public var vurguAcik: RGBA
    public var vurguAcikYazi: RGBA
    public var vurguKoyu: RGBA
    /// `--notr-kenar`, `--notr-yuzey`
    public var notrKenar: RGBA
    public var notrYuzey: RGBA
    /// `--pirinc`, `--pirinc-yazi`: tek sabit vurgu
    public var pirinc: RGBA
    public var pirincYazi: RGBA

    /// CSS değişken adı → alan
    public static let degiskenler: [(String, WritableKeyPath<TemaRenkleri, RGBA>)] = [
        ("--bg", \.zemin), ("--surface", \.yuzey), ("--border", \.kenar),
        ("--ink", \.murekkep), ("--ink-2", \.murekkep2), ("--ink-3", \.murekkep3), ("--ink-soluk", \.soluk),
        ("--right", \.dogru), ("--right-ikon", \.dogruIkon), ("--right-bg", \.dogruZemin),
        ("--wrong", \.yanlis), ("--wrong-ikon", \.yanlisIkon), ("--wrong-bg", \.yanlisZemin),
        ("--tab-bg", \.sekmeZemin), ("--overlay-btn", \.ustDugme),
        ("--vurgu", \.vurgu), ("--vurgu-yazi", \.vurguYazi), ("--vurgu-acik", \.vurguAcik),
        ("--vurgu-acik-yazi", \.vurguAcikYazi), ("--vurgu-koyu", \.vurguKoyu),
        ("--notr-kenar", \.notrKenar), ("--notr-yuzey", \.notrYuzey),
        ("--pirinc", \.pirinc), ("--pirinc-yazi", \.pirincYazi),
    ]

    /// Z4f · Emre'nin kendi seçtiği renkler (renk seçme sayfası, 27 Kasım; "pirinç rengi olmasın, çok Claude duruyor …
    /// ben seçeyim"). Sitenin sabit tablolarının üstüne yazılır; günün tablosundan gelen vurgu ve renkli Gündüz
    /// (Emre: "günün resmiyle uyumluluğu ve arkaplandaki renk halesini kaldırma") bunların üstüne eskisi gibi gelir.
    /// "Vurgu" eski pirincin yerindedir (`--pirinc`); sitenin nötr `--vurgu` ailesi değişmedi.
    public static let gece = TemaRenkleri(degiskenler: [
        "--bg": "#111111", "--surface": "#1b1b1b", "--border": "#2c2c2c",
        "--ink": "#ffffff", "--ink-2": "#b29999", "--ink-3": "#d1bdbd", "--ink-soluk": "#8a7f7f",
        "--right": "#74b48c", "--right-bg": "rgba(116, 180, 140, 0.14)",
        "--wrong": "#d66d5b", "--wrong-bg": "rgba(214, 109, 91, 0.14)",
        "--tab-bg": "rgba(27, 27, 27, 0.8)", "--overlay-btn": "rgba(17, 17, 17, 0.6)",
        "--vurgu-yazi": "#111111", "--vurgu-acik-yazi": "#111111",
        "--notr-kenar": "rgba(255, 255, 255, 0.14)", "--notr-yuzey": "rgba(255, 255, 255, 0.05)",
        "--pirinc": "#b8a8a8", "--pirinc-yazi": "#111111",
    ], yedek: siteGece)!

    public static let gunduz = TemaRenkleri(degiskenler: [
        "--bg": "#dfe2e1", "--surface": "#ffffff", "--border": "#cfcfcf",
        "--ink": "#000000", "--ink-2": "#4d525b", "--ink-3": "#5b6474", "--ink-soluk": "#8a909a",
        "--right": "#2a6a48", "--right-ikon": "#2a6a48", "--right-bg": "rgba(42, 106, 72, 0.12)",
        "--wrong": "#a03a2a", "--wrong-ikon": "#a03a2a", "--wrong-bg": "rgba(160, 58, 42, 0.1)",
        "--tab-bg": "rgba(255, 255, 255, 0.84)", "--overlay-btn": "rgba(255, 255, 255, 0.85)",
        "--vurgu-yazi": "#ffffff", "--vurgu-acik-yazi": "#ffffff", "--vurgu-koyu": "#cfcfcf",
        "--notr-kenar": "rgba(0, 0, 0, 0.14)", "--notr-yuzey": "rgba(0, 0, 0, 0.035)",
        "--pirinc": "#a5785f", "--pirinc-yazi": "#ffffff",
    ], yedek: siteGunduz)!

    /// css/app.css `:root[data-tema='gece']` (sitenin kendi sabiti; kâhin testi bununla)
    public static let siteGece = TemaRenkleri(sabit: [
        "--bg": "#121110", "--surface": "#1c1a18", "--border": "#2e2b28",
        "--ink": "#ebe5da", "--ink-2": "#aca498", "--ink-3": "#8a8379", "--ink-soluk": "#645e57",
        "--right": "#6fb487", "--right-ikon": "#8fd0a2", "--right-bg": "rgba(111, 180, 135, 0.14)",
        "--wrong": "#d66854", "--wrong-ikon": "#f09a86", "--wrong-bg": "rgba(214, 104, 84, 0.14)",
        "--tab-bg": "rgba(24, 22, 20, 0.8)", "--overlay-btn": "rgba(18, 17, 16, 0.6)",
        "--vurgu": "#8a827a", "--vurgu-yazi": "#121110", "--vurgu-acik": "#cfc7bc", "--vurgu-acik-yazi": "#121110",
        "--vurgu-koyu": "#2a2725",
        "--notr-kenar": "rgba(244, 239, 230, 0.14)", "--notr-yuzey": "rgba(244, 239, 230, 0.05)",
        "--pirinc": "#c9a45c", "--pirinc-yazi": "#121110",
    ])

    /// css/app.css `:root[data-tema='gunduz']` (nötr; renkli Gündüz'de site bunları paletle değiştirir)
    public static let siteGunduz = TemaRenkleri(sabit: [
        "--bg": "#ece8e1", "--surface": "#f7f5f1", "--border": "#d6d0c6",
        "--ink": "#1f1b17", "--ink-2": "#4c463f", "--ink-3": "#5f5850", "--ink-soluk": "#8e867c",
        "--right": "#2a6644", "--right-ikon": "#2a6644", "--right-bg": "rgba(42, 102, 68, 0.12)",
        "--wrong": "#9a3726", "--wrong-ikon": "#9a3726", "--wrong-bg": "rgba(154, 55, 38, 0.1)",
        "--tab-bg": "rgba(247, 245, 241, 0.84)", "--overlay-btn": "rgba(247, 245, 241, 0.85)",
        "--vurgu": "#4c463f", "--vurgu-yazi": "#f7f5f1", "--vurgu-acik": "#4c463f", "--vurgu-acik-yazi": "#f7f5f1",
        "--vurgu-koyu": "#d6d0c6",
        "--notr-kenar": "rgba(31, 27, 23, 0.14)", "--notr-yuzey": "rgba(31, 27, 23, 0.035)",
        // Gündüz'de koyu pirinç (css/app.css sonlarında); Bugün yürüyüşünde ve görüntüleyicide (.gor) gecenin pirinci kalır
        "--pirinc": "#8a651c", "--pirinc-yazi": "#f7f5f1",
    ])

    /// `site`: sitenin kendi sabitleri (kâhin testleri); yoksa Emre'nin renkleri (Z4f)
    public static func sabit(_ t: TemaAdi, site: Bool = false) -> TemaRenkleri {
        site ? (t == .gece ? siteGece : siteGunduz) : (t == .gece ? gece : gunduz)
    }

    private init(sabit d: [String: String]) {
        self.init(degiskenler: d, yedek: nil)!
    }

    /// Sitenin hesapladığı değişkenlerden (`getComputedStyle(document.documentElement)`); okunamayan ya da eksik
    /// değişken `yedek`'ten alınır. Yedek yoksa ve bir değişken eksikse nil.
    public init?(degiskenler d: [String: String], yedek: TemaRenkleri?) {
        let siyah = RGBA(0, 0, 0)
        var t = yedek ?? TemaRenkleri(hepsi: siyah)
        for (ad, yol) in Self.degiskenler {
            if let deger = d[ad].flatMap(RGBA.init(css:)) {
                t[keyPath: yol] = deger
            } else if yedek == nil {
                return nil
            }
        }
        self = t
    }

    private init(hepsi c: RGBA) {
        zemin = c; yuzey = c; kenar = c; murekkep = c; murekkep2 = c; murekkep3 = c; soluk = c
        dogru = c; dogruIkon = c; dogruZemin = c; yanlis = c; yanlisIkon = c; yanlisZemin = c
        sekmeZemin = c; ustDugme = c; vurgu = c; vurguYazi = c; vurguAcik = c; vurguAcikYazi = c; vurguKoyu = c
        notrKenar = c; notrYuzey = c; pirinc = c; pirincYazi = c
    }

    /// Koyu zemin mi (durum çubuğu ve sistem öğeleri buna göre)
    public var koyu: Bool { zemin.koyu }

    /// Z2c-2: sitenin `temaUygula` + `gunduzYaz` + `renkleriYaz`'ı (js/ekranlar/ortak.js). Renkli Gündüz'de paletin
    /// değişkenleri, sonra ekranın vurgusu sabit temanın önüne geçer.
    public static func hesapla(_ tema: TemaAdi, gunduz: GunduzPaleti?, vurgu: ResimRengi.VurguTemasi?,
                               site: Bool = false) -> TemaRenkleri {
        var d: [String: String] = [:]
        if tema == .gunduz, let gunduz { d.merge(gunduz.degiskenler) { $1 } }
        if let vurgu { d.merge(vurgu.degiskenler) { $1 } }
        return TemaRenkleri(degiskenler: d, yedek: sabit(tema, site: site)) ?? sabit(tema, site: site)
    }

    /// Z3m: sitenin `renkleriYaz(palet)`'ı (js/ekranlar/ortak.js @ cca62eb): bir ekranın renkleri, vurgu o ekranın
    /// eserinin paletinden (`renkTemasi(palet, temaZemini())`); palet nil ise temanın nötr vurgusu (değişkenler silinir).
    public static func ekran(_ tema: TemaAdi, gunduz: GunduzPaleti?, palet: [ResimRengi.PaletRengi]?) -> TemaRenkleri {
        let g = tema == .gunduz ? gunduz : nil
        let vurgu = palet.flatMap { ResimRengi.renkTemasi($0, zemin: zeminHex(tema, gunduz: g)) }
        return hesapla(tema, gunduz: g, vurgu: vurgu)
    }

    /// Sitenin `temaZemini()`'i: vurgunun kontrast hesabı ve pencerenin rengi (`theme-color`)
    public static func zeminHex(_ tema: TemaAdi, gunduz: GunduzPaleti?, site: Bool = false) -> String {
        if tema == .gunduz, let gunduz { return gunduz.bg }
        // Z4f: Emre'nin zeminleri (sitede #121110 / #ECE8E1); vurgu bu zemine göre seçilir
        return sabit(tema, site: site).zemin.hex.uppercased()
    }
}

/// Sitenin ölçüleri (css/app.css `:root`)
public enum TemaOlcu {
    /// `--yan`: kenar boşluğu
    public static let yan: Double = 24
    /// `--sekme-h`: sekme çubuğu yüksekliği
    public static let sekmeYuksekligi: Double = 62
    /// `--kart-kose`
    public static let kartKose: Double = 4
}

/// Sitenin görünüş ayarları (`ilerleme.ayarlar`: tema, hareket, yazi, gunduzRenk); `<html>` öznitelikleri
public struct TemaAyari: Hashable, Sendable {
    public var tema: TemaAdi
    /// "tam", "sade", "kapali" (İş 148)
    public var hareket: String
    /// "standart" ya da büyük yazı
    public var yazi: String

    public init(tema: TemaAdi = .gece, hareket: String = "tam", yazi: String = "standart") {
        self.tema = tema; self.hareket = hareket; self.yazi = yazi
    }

    /// Hareket kapalıysa ya da sadeyse süs hareketleri yapılmaz
    public var hareketAzaltilmis: Bool { hareket != "tam" }
}

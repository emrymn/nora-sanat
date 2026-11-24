// Kaynak: sanat-atlasi js/renk.js (hexten, hexe, hsl, hsldenHex, karistir, paletHesapla, vurguSec, acikHal, doluButon,
// yumusat, renkTemasi, tonlariHesapla), js/gunduzRenk.js (HAZIR_PALETLER, resimdenPalet, paletDegiskenleri,
// gunduzPaleti), js/tasarim.js (kontrast) @ a866b86 (site 1.90.3).
// Z2c-2: renkler artık siteden okunmaz, burada hesaplanır. Kâhin: Testler/kahin/renk.mjs (sitenin kendi modülleri).
// JS'teki sıralamalar kararlı (stable): eşit değerlerde sıra korunur; burada da öyle.
import Foundation

public enum ResimRengi {
    public static let koyuYazi = "#0B0A0B"
    public static let beyazYazi = "#FFFFFF"
    static let hedef = 4.5

    // MARK: - Renk biçimleri

    /// `Math.round`: yarım yukarı
    static func jsYuvarla(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

    /// "#rrggbb" → [r, g, b] (0…255)
    public static func hexten(_ hex: String) -> [Double] {
        let h = Array(hex.replacingOccurrences(of: "#", with: ""))
        return [0, 2, 4].map { i -> Double in
            guard i + 2 <= h.count, let n = Int(String(h[i..<i + 2]), radix: 16) else { return .nan }
            return Double(n)
        }
    }

    public static func hexe(_ c: [Double]) -> String {
        "#" + c.prefix(3).map { x -> String in
            let n = Int(jsYuvarla(min(255, max(0, x))))
            let s = String(n, radix: 16)
            return s.count == 1 ? "0" + s : s
        }.joined()
    }

    /// [ton 0…360, doygunluk, açıklık]
    public static func hsl(_ hex: String) -> (Double, Double, Double) {
        let c = hexten(hex).map { $0 / 255 }
        let (r, g, b) = (c[0], c[1], c[2])
        let en = max(r, g, b), az = min(r, g, b)
        let l = (en + az) / 2
        if en == az { return (0, 0, l) }
        let d = en - az
        let s = l > 0.5 ? d / (2 - en - az) : d / (en + az)
        var h: Double
        if en == r { h = (g - b) / d + (g < b ? 6 : 0) } else if en == g { h = (b - r) / d + 2 } else { h = (r - g) / d + 4 }
        h *= 60
        return (h, s, l)
    }

    public static func hsldenHex(_ h: Double, _ s: Double, _ l: Double) -> String {
        func k(_ n: Double) -> Double { (n + h / 30).truncatingRemainder(dividingBy: 12) }
        let a = s * min(l, 1 - l)
        func f(_ n: Double) -> Double { l - a * max(-1, min(k(n) - 3, min(9 - k(n), 1))) }
        return hexe([f(0) * 255, f(8) * 255, f(4) * 255])
    }

    /// İki rengi karıştır: oran = a'nın payı
    public static func karistir(_ a: String, _ b: String, _ oran: Double) -> String {
        let x = hexten(a), y = hexten(b)
        return hexe(x.indices.map { x[$0] * oran + y[$0] * (1 - oran) })
    }

    /// WCAG kontrast oranı (js/tasarim.js)
    public static func kontrast(_ a: String, _ b: String) -> Double {
        func kanal(_ v: Double) -> Double {
            let x: Double = v / 255
            if x <= 0.03928 { return x / 12.92 }
            return pow((x + 0.055) / 1.055, 2.4)
        }
        func parlaklik(_ hex: String) -> Double {
            let c: [Double] = hexten(hex).map(kanal)
            let r: Double = 0.2126 * c[0]
            let g: Double = 0.7152 * c[1]
            let b: Double = 0.0722 * c[2]
            return r + g + b
        }
        let p = [parlaklik(a), parlaklik(b)]
        return (max(p[0], p[1]) + 0.05) / (min(p[0], p[1]) + 0.05)
    }

    /// Kararlı sıralama (JS Array.prototype.sort gibi)
    static func kararli<T>(_ a: [T], _ once: (T, T) -> Bool) -> [T] {
        a.enumerated().sorted { x, y in
            if once(x.element, y.element) { return true }
            if once(y.element, x.element) { return false }
            return x.offset < y.offset
        }.map(\.element)
    }

    // MARK: - Palet ve vurgu

    public struct PaletRengi: Equatable, Sendable, Codable {
        public var renk: String
        public var pay: Double
        public init(renk: String, pay: Double) { self.renk = renk; self.pay = pay }
    }

    /// js/akim.js `paletBirlestir(paletler, { adet, esik })` (Z3l; Galeri akım sayfasının renk şeridi, `.akim-palet`):
    /// eserlerin paletleri tek palette toplanır. Her eserin payı eşit (pay / eser sayısı); birbirine `esik`'ten yakın
    /// renkler ağırlıklarıyla karışır; en ağır `adet` renk, payları yeniden toplamı 1 olacak biçimde.
    public static func paletBirlestir(_ paletler: [[PaletRengi]?], adet: Int = 6, esik: Double = 38) -> [PaletRengi] {
        let l = paletler.compactMap { $0 }.filter { !$0.isEmpty }
        guard !l.isEmpty else { return [] }
        var kume: [(c: [Double], w: Double)] = []
        for p in l {
            for r in p {
                let c = hexten(r.renk)
                let w = r.pay / Double(l.count)
                if let i = kume.firstIndex(where: { k in
                    let dx = k.c[0] - c[0], dy = k.c[1] - c[1], dz = k.c[2] - c[2]
                    return (dx * dx + dy * dy + dz * dz).squareRoot() < esik
                }) {
                    let y = kume[i]
                    let t = y.w + w
                    let bolen = t == 0 ? 1 : t
                    kume[i] = (c: (0..<3).map { (y.c[$0] * y.w + c[$0] * w) / bolen }, w: t)
                } else {
                    kume.append((c: c, w: w))
                }
            }
        }
        let secilen = Array(kararli(kume) { $0.w > $1.w }.prefix(adet))
        let toplam = secilen.reduce(0.0) { $0 + $1.w }
        let t = toplam == 0 ? 1 : toplam
        return secilen.map { PaletRengi(renk: hexe($0.c.map(jsYuvarla)), pay: $0.w / t) }
    }

    /// Z3m: sitenin `eserPaleti(e, yedekRenk)`'i (js/ekranlar/ortak.js @ cca62eb): görselden hesaplanan palet; görsel
    /// açılmadıysa (ya da palet boşsa) yedek renk tek renkli palet olur, yedek yoksa nil (temanın nötr vurgusu).
    public static func eserPaleti(_ hesaplanan: [PaletRengi]?, yedek: String?) -> [PaletRengi]? {
        if let p = hesaplanan, !p.isEmpty { return p }
        guard let yedek, !yedek.isEmpty else { return nil }
        return [PaletRengi(renk: yedek, pay: 1)]
    }

    /// RGBA piksellerinden (0…255, satır satır) median-cut ile en fazla `adet` renk; büyükten küçüğe
    public static func paletHesapla(_ veri: [UInt8], adet: Int = 6) -> [PaletRengi] {
        var px: [[Int]] = []
        var i = 0
        while i + 3 < veri.count {
            if veri[i + 3] >= 128 { px.append([Int(veri[i]), Int(veri[i + 1]), Int(veri[i + 2])]) }
            i += 4
        }
        guard !px.isEmpty else { return [] }
        var kutular = [px]
        while kutular.count < adet {
            var secilen = -1, enIyi = 0, kanal = 0
            for (i, k) in kutular.enumerated() where k.count >= 2 {
                for c in 0..<3 {
                    var az = 255, en = 0
                    for p in k { if p[c] < az { az = p[c] }; if p[c] > en { en = p[c] } }
                    let puan = (en - az) * k.count
                    if puan > enIyi { enIyi = puan; secilen = i; kanal = c }
                }
            }
            if secilen < 0 { break }
            let k = kararli(kutular[secilen]) { $0[kanal] < $1[kanal] }
            let orta = k.count >> 1
            kutular.replaceSubrange(secilen...secilen, with: [Array(k[..<orta]), Array(k[orta...])])
        }
        let sonuc = kutular.map { k -> PaletRengi in
            var t = [0.0, 0.0, 0.0]
            for p in k { for c in 0..<3 { t[c] += Double(p[c]) } }
            return PaletRengi(renk: hexe(t.map { $0 / Double(k.count) }), pay: Double(k.count) / Double(px.count))
        }
        return kararli(sonuc) { $0.pay > $1.pay }
    }

    /// Paletin en doygun orta tonu (çok küçük lekeler sayılmaz)
    public static func vurguSec(_ palet: [PaletRengi]) -> String? {
        guard !palet.isEmpty else { return nil }
        let aday = palet.filter { $0.pay >= 0.04 }
        let havuz = aday.isEmpty ? palet : aday
        let orta = havuz.filter { let l = hsl($0.renk).2; return l >= 0.25 && l <= 0.72 }
        let liste = orta.isEmpty ? havuz : orta
        return liste.reduce(liste[0]) { en, p in hsl(p.renk).1 > hsl(en.renk).1 ? p : en }.renk
    }

    static func koyuMu(_ zemin: String) -> Bool { hsl(zemin).2 < 0.5 }

    /// Zeminde metin olarak okunan hali: koyu zeminde açılır, açık zeminde koyulaşır (≥ 4.5:1)
    public static func acikHal(_ renk: String, _ zemin: String) -> String {
        let (h, s, l0) = hsl(renk)
        let koyu = koyuMu(zemin)
        var l = koyu ? max(l0, 0.62) : min(l0, 0.45)
        for _ in 0..<60 {
            let c = hsldenHex(h, s, l)
            if kontrast(c, zemin) >= hedef { return c }
            l = min(1, max(0, l + (koyu ? 0.02 : -0.02)))
        }
        return koyu ? beyazYazi : koyuYazi
    }

    /// Dolu düğme: yazı (koyu ya da beyaz) zeminle en az 4.5:1
    public static func doluButon(_ renk: String) -> (zemin: String, yazi: String) {
        let (h, s, l0) = hsl(renk)
        var l = l0
        for _ in 0..<60 {
            let c = hsldenHex(h, s, l)
            let kk = kontrast(c, koyuYazi), kb = kontrast(c, beyazYazi)
            if max(kk, kb) >= hedef { return (c, kk >= kb ? koyuYazi : beyazYazi) }
            l = min(1, max(0, l + (l >= 0.5 ? 0.02 : -0.02)))
        }
        return (koyuYazi, beyazYazi)
    }

    /// Yağlı boya tonu: sarılar okra kayar, doygunluk ve açıklık toprak boyalarının aralığına iner
    public static func yumusat(_ renk: String) -> String {
        var (h, s, l) = hsl(renk)
        if h >= 45 && h < 75 { h = 36 + (h - 45) * 0.15 }
        s = min(s, h >= 75 && h < 170 ? 0.28 : 0.4)
        l = min(max(l, 0.3), 0.46)
        return hsldenHex(h, s, l)
    }

    static func sonuk(_ renk: String) -> String {
        let (h, s, l) = hsl(renk)
        return hsldenHex(h, min(s, 0.26), l)
    }

    /// `--vurgu…` değişkenleri
    public struct VurguTemasi: Equatable, Sendable {
        public var vurgu, vurguYazi, vurguAcik, vurguAcikYazi, vurguKoyu, vurguRgb: String

        public var degiskenler: [String: String] {
            ["--vurgu": vurgu, "--vurgu-yazi": vurguYazi, "--vurgu-acik": vurguAcik, "--vurgu-acik-yazi": vurguAcikYazi,
             "--vurgu-koyu": vurguKoyu, "--vurgu-rgb": vurguRgb]
        }
    }

    /// Paletten vurgu değişkenleri; `zemin`: temanın `--bg`'si
    public static func renkTemasi(_ palet: [PaletRengi], zemin: String) -> VurguTemasi? {
        guard let secilen = vurguSec(palet) else { return nil }
        let koyu = koyuMu(zemin)
        let ana = koyu ? sonuk(yumusat(secilen)) : yumusat(secilen)
        let dolu = doluButon(ana)
        let acik = acikHal(ana, zemin)
        let acikYazi = kontrast(acik, koyuYazi) >= kontrast(acik, beyazYazi) ? koyuYazi : beyazYazi
        return VurguTemasi(
            vurgu: dolu.zemin, vurguYazi: dolu.yazi, vurguAcik: acik, vurguAcikYazi: acikYazi,
            vurguKoyu: karistir(ana, zemin, koyu ? 0.3 : 0.14),
            vurguRgb: hexten(ana).map { String(Int($0)) }.joined(separator: ", "))
    }

    // MARK: - Renkli Gündüz için tablonun renk aileleri

    public static let renkAileleri: [(String, Double, Double)] = [
        ("kirmizi", 345, 15), ("turuncu", 15, 45), ("okr", 45, 70), ("yesil", 70, 170), ("mavi", 170, 260), ("mor", 260, 345),
    ]

    static func aileBul(_ h: Double) -> String {
        for (ad, a, b) in renkAileleri where a < b ? (h >= a && h < b) : (h >= a || h < b) { return ad }
        return "kirmizi"
    }

    public struct Aile: Equatable, Sendable {
        public var ad: String
        public var pay: Double
        public var renk: String?
    }

    public struct Tonlar: Equatable, Sendable {
        public var aileler: [Aile]
        public var acik: String?
        public var renkOrani: Double
    }

    public static func tonlariHesapla(_ veri: [UInt8]) -> Tonlar {
        var ort = [0.0, 0.0, 0.0]
        var say = 0
        var i = 0
        while i + 3 < veri.count {
            if veri[i + 3] >= 128 {
                ort[0] += Double(veri[i]); ort[1] += Double(veri[i + 1]); ort[2] += Double(veri[i + 2]); say += 1
            }
            i += 4
        }
        let gri = (ort[0] + ort[1] + ort[2]) / 3
        let kazanc = ort.map { m in m > 0 ? pow(gri / m, 0.5) : 1 }
        var aile: [String: (w: Double, x: Double, y: Double, s: Double, l: Double)] = [:]
        for (ad, _, _) in renkAileleri { aile[ad] = (0, 0, 0, 0, 0) }
        var acik = [0.0, 0.0, 0.0]
        var acikSay = 0, renkli = 0
        i = 0
        while i + 3 < veri.count {
            defer { i += 4 }
            guard veri[i + 3] >= 128 else { continue }
            let r = min(1, Double(veri[i]) / 255 * kazanc[0])
            let g = min(1, Double(veri[i + 1]) / 255 * kazanc[1])
            let b = min(1, Double(veri[i + 2]) / 255 * kazanc[2])
            let en = max(r, g, b), az = min(r, g, b)
            let l = (en + az) / 2
            if (Double(veri[i]) + Double(veri[i + 1]) + Double(veri[i + 2])) / 765 >= 0.62 {
                acik[0] += Double(veri[i]); acik[1] += Double(veri[i + 1]); acik[2] += Double(veri[i + 2]); acikSay += 1
            }
            let f = en - az
            if f < 0.04 || l < 0.1 || l > 0.92 { continue }
            renkli += 1
            let s = f / (1 - abs(2 * l - 1))
            var h = en == r ? ((g - b) / f).truncatingRemainder(dividingBy: 6) : en == g ? (b - r) / f + 2 : (r - g) / f + 4
            h = (h * 60 + 360).truncatingRemainder(dividingBy: 360)
            let w = f * f * (1 - abs(l - 0.5))
            let ad = aileBul(h)
            let a = h * Double.pi / 180
            var k = aile[ad]!
            k.w += w; k.x += cos(a) * w; k.y += sin(a) * w; k.s += s * w; k.l += l * w
            aile[ad] = k
        }
        // JS: Object.values sırasıyla (aile sırası) toplanır
        let toplamW = renkAileleri.reduce(0.0) { $0 + aile[$1.0]!.w }
        let aileler = renkAileleri.map { (ad, _, _) -> Aile in
            let k = aile[ad]!
            if k.w == 0 { return Aile(ad: ad, pay: 0, renk: nil) }
            let h = (atan2(k.y, k.x) * 180 / Double.pi + 360).truncatingRemainder(dividingBy: 360)
            return Aile(ad: ad, pay: k.w / toplamW, renk: hsldenHex(h, min(1, max(0.3, k.s / k.w)), k.l / k.w))
        }
        return Tonlar(aileler: aileler, acik: acikSay > 0 ? hexe(acik.map { $0 / Double(acikSay) }) : nil,
                      renkOrani: say > 0 ? Double(renkli) / Double(say) : 0)
    }
}

// MARK: - Renkli Gündüz paleti (js/gunduzRenk.js)

public struct GunduzPaleti: Equatable, Sendable, Codable {
    public var bg, surface, border, ink, ink2, ink3, soluk, band, bandInk, bandInk2, sekme, altin, pirinc, etiket: String

    public static let renkler = ["otomatik", "lapis", "pompei", "bakir", "safran", "notr"]
    public static let varsayilan = "otomatik"
    public static let adlar = ["otomatik": "Günün resmi", "lapis": "Lapis", "pompei": "Pompei", "bakir": "Bakır yeşili",
                               "safran": "Safran", "notr": "Nötr kâğıt"]
    /// Otomatik palet üretilemezse
    public static let yedek = "lapis"

    public static let hazir: [String: GunduzPaleti] = [
        "lapis": GunduzPaleti(bg: "#e6dcc4", surface: "#faf5e8", border: "#d3c6a6", ink: "#1a2138", ink2: "#424862",
                              ink3: "#555a72", soluk: "#8a8778", band: "#1f3768", bandInk: "#f4ecd8", bandInk2: "#c9cfe3",
                              sekme: "#1f3768", altin: "#c49a3a", pirinc: "#7a510e", etiket: "#1f3768"),
        "pompei": GunduzPaleti(bg: "#efdcc6", surface: "#fff7ec", border: "#dfc2a5", ink: "#2b1712", ink2: "#5e4134",
                               ink3: "#6e5144", soluk: "#9a7d6c", band: "#8c2a22", bandInk: "#fbebd8", bandInk2: "#f0cdb9",
                               sekme: "#3a1e17", altin: "#d29a3c", pirinc: "#8a5410", etiket: "#8c2a22"),
        "bakir": GunduzPaleti(bg: "#d6e3da", surface: "#f4f9f5", border: "#b6cbc2", ink: "#12302b", ink2: "#3e5852",
                              ink3: "#4c665f", soluk: "#7f958f", band: "#22544d", bandInk: "#eef7f2", bandInk2: "#cfe7df",
                              sekme: "#12302b", altin: "#d97c8e", pirinc: "#a2405a", etiket: "#22544d"),
        "safran": GunduzPaleti(bg: "#f3e1b0", surface: "#fff8e4", border: "#e2c987", ink: "#1d1e3a", ink2: "#48466a",
                               ink3: "#57557a", soluk: "#8c8466", band: "#25306a", bandInk: "#fbf1d6", bandInk2: "#c5cae6",
                               sekme: "#25306a", altin: "#e0a02f", pirinc: "#a33a24", etiket: "#25306a"),
    ]

    static func arala(_ x: Double, _ a: Double, _ b: Double) -> Double { min(b, max(a, x)) }
    static func tonFarki(_ a: Double, _ b: Double) -> Double {
        let x = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(x, 360 - x)
    }

    static func okunur(_ h: Double, _ s: Double, _ l0: Double, _ zeminler: [String], _ hedef: Double = 4.5) -> String {
        var l = l0
        for _ in 0..<60 {
            let c = ResimRengi.hsldenHex(h, s, l)
            if zeminler.allSatisfy({ ResimRengi.kontrast(c, $0) >= hedef }) { return c }
            l = max(0, l - 0.015)
        }
        return ResimRengi.hsldenHex(h, s, 0.08)
    }

    static func acikOkunur(_ h: Double, _ s: Double, _ l0: Double, _ zemin: String, _ hedef: Double = 4.5) -> String {
        var l = l0
        for _ in 0..<60 {
            let c = ResimRengi.hsldenHex(h, s, l)
            if ResimRengi.kontrast(c, zemin) >= hedef { return c }
            l = min(1, l + 0.015)
        }
        return "#ffffff"
    }

    static let bantAileleri: Set<String> = ["kirmizi", "yesil", "mavi", "mor"]

    /// Günün tablosunun renk ailelerinden Gündüz paleti; renksiz tabloda nil
    public static func resimden(_ t: ResimRengi.Tonlar?) -> GunduzPaleti? {
        guard let t, t.renkOrani >= 0.04 else { return nil }
        struct A { var ad: String; var h, s, l, pay: Double }
        let hexMi: (String) -> Bool = { r in
            r.count == 7 && r.hasPrefix("#") && r.dropFirst().allSatisfy(\.isHexDigit)
        }
        let aileler = ResimRengi.kararli(t.aileler.compactMap { a -> A? in
            guard a.pay > 0, let r = a.renk, hexMi(r) else { return nil }
            let (h, s, l) = ResimRengi.hsl(r)
            return A(ad: a.ad, h: h, s: s, l: l, pay: a.pay)
        }) { $0.pay > $1.pay }
        guard !aileler.isEmpty else { return nil }
        let kimlikSira = aileler.firstIndex { bantAileleri.contains($0.ad) && $0.pay >= 0.05 }
        let ana = kimlikSira.map { aileler[$0] } ?? A(ad: "toprak", h: 20, s: 0.45, l: 0.3, pay: 0)
        let ikinci: A? = kimlikSira != nil
            ? aileler.enumerated().first { $0.offset != kimlikSira! && tonFarki($0.element.h, ana.h) >= 45 && $0.element.pay >= 0.04 }?.element
            : aileler.first { ($0.ad == "okr" || $0.ad == "turuncu") && $0.pay >= 0.04 }
        let vh = ikinci?.h ?? 40, vs = ikinci?.s ?? 0.55
        let hb = ana.h
        let sb = arala(ana.s, 0.35, 0.6)
        let ha = ikinci != nil && (ikinci!.ad == "turuncu" || ikinci!.ad == "okr") ? arala(vh, 34, 46) : vh
        let sa = arala(vs, 0.45, 0.65)
        let (ah, asat, _) = t.acik.map(ResimRengi.hsl) ?? (hb, 0, 0)
        let hz = asat >= 0.08 ? ah : hb
        let sz = arala(asat >= 0.08 ? asat : 0.25, 0.18, 0.38)

        let bg = ResimRengi.hsldenHex(hz, sz, 0.86)
        let surface = ResimRengi.hsldenHex(hz, sz * 0.8, 0.955)
        let border = ResimRengi.hsldenHex(hz, sz * 0.8, 0.76)
        let bandInk0 = ResimRengi.hsldenHex(hz, 0.45, 0.93)
        let band = okunur(hb, sb, 0.27, [bandInk0], 7)
        let zeminler = [bg, surface]
        return GunduzPaleti(
            bg: bg, surface: surface, border: border,
            ink: okunur(hb, 0.35, 0.15, zeminler, 7),
            ink2: okunur(hb, 0.2, 0.33, zeminler),
            ink3: okunur(hb, 0.16, 0.38, zeminler),
            soluk: ResimRengi.hsldenHex(hb, 0.12, 0.55),
            band: band,
            bandInk: acikOkunur(hz, 0.45, 0.93, band, 7),
            bandInk2: acikOkunur(hb, 0.3, 0.8, band),
            sekme: band,
            altin: ResimRengi.hsldenHex(ha, sa, 0.6),
            pirinc: okunur(ha, sa, 0.42, zeminler),
            etiket: okunur(hb, sb, 0.3, zeminler))
    }

    /// Seçime göre palet: otomatikte günün tablosunun tonları (yoksa ya da renksizse hazır yedek); notr → nil
    public static func sec(_ secim: String, tonlar: ResimRengi.Tonlar?) -> GunduzPaleti? {
        if secim == "notr" { return nil }
        if let p = hazir[secim] { return p }
        return resimden(tonlar) ?? hazir[yedek]
    }

    /// CSS değişkenleri (kökün satır içi stili; sabit Gündüz değerlerinin önüne geçer)
    public var degiskenler: [String: String] {
        let rgb: (String) -> String = { ResimRengi.hexten($0).map { String(Int($0)) }.joined(separator: ", ") }
        let altinYazi = ResimRengi.kontrast(altin, ink) >= 4.5 ? ink : "#ffffff"
        return [
            "--bg": bg, "--bg-rgb": rgb(bg), "--surface": surface, "--border": border,
            "--ink": ink, "--ink-2": ink2, "--ink-3": ink3, "--ink-soluk": soluk,
            "--notr-kenar": "rgba(\(rgb(band)), 0.2)", "--notr-yuzey": "rgba(\(rgb(band)), 0.06)",
            "--doku": "radial-gradient(rgba(\(rgb(band)), 0.06) 1px, transparent 1px)",
            "--tab-bg": "rgba(\(rgb(surface)), 0.84)", "--overlay-btn": "rgba(\(rgb(surface)), 0.85)",
            "--durum-cubugu": "rgba(31, 27, 23, 0.42)",
            "--pirinc": pirinc, "--pirinc-rgb": rgb(pirinc), "--pirinc-yazi": surface,
            "--band": band, "--band-rgb": rgb(band), "--band-ink": bandInk, "--band-ink-2": bandInk2,
            "--sekme-zemin": rgb(sekme), "--altin": altin, "--altin-rgb": rgb(altin), "--altin-yazi": altinYazi,
            "--etiket": etiket,
        ]
    }
}

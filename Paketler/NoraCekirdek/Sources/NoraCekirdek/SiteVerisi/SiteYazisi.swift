// Kaynak: sanat-atlasi js/yardimci.js, js/md5.js, js/adlar.js @ a866b86 (site 1.90.3)
import Foundation

/// Sitenin küçük, saf yazı yardımcıları (js/yardimci.js). Davranış JS'tekiyle aynı tutulur.
public enum SiteYazisi {

    /// `yilYaz`: -450 → "MÖ 450"
    public static func yilYaz(_ y: Int?) -> String {
        guard let y else { return "?" }
        return y < 0 ? "MÖ \(-y)" : String(y)
    }

    /// `bulunmaEki`: 3 → "3'te", 10 → "10'da", 100 → "100'de" (ör. "Konu 3'te açılır")
    public static func bulunmaEki(_ n: Int) -> String {
        let sayi = abs(n)
        let birler = ["", "de", "de", "te", "te", "te", "da", "de", "de", "da"]
        let onlar = ["", "da", "de", "da", "ta", "de", "ta", "de", "de", "da"]
        if sayi == 0 { return "\(n)'da" }
        if sayi % 10 != 0 { return "\(n)'\(birler[sayi % 10])" }
        if sayi % 100 != 0 { return "\(n)'\(onlar[(sayi / 10) % 10])" }
        return "\(n)'de"
    }

    /// `yillarYaz`
    public static func yillarYaz(dogum: Int?, olum: Int?) -> String {
        switch (dogum, olum) {
        case (nil, nil): return "tarih bilinmiyor"
        case (nil, let o?): return "ö. \(yilYaz(o))"
        case (let d?, nil): return "d. \(yilYaz(d))"
        case (let d?, let o?):
            if d < 0 && o < 0 { return "MÖ \(-d)–\(-o)" }
            return "\(yilYaz(d))–\(yilYaz(o))"
        }
    }

    /// `eserler.js tarihYaz`: yıl yoksa boş
    static func tarihYaz(_ y: Int?) -> String { y.map { yilYaz($0) } ?? "" }

    /// `baslikNormal`: başlık karşılaştırması için
    public static func baslikNormal(_ s: String) -> String {
        let kucuk = trKucuk(s).decomposedStringWithCanonicalMapping
        var sonuc = ""
        var bosluk = false
        for u in kucuk.unicodeScalars {
            if (0x300...0x36F).contains(u.value) { continue }
            let c: Unicode.Scalar = u == "ı" ? "i" : u
            if ("a"..."z").contains(c) || ("0"..."9").contains(c) {
                if bosluk && !sonuc.isEmpty { sonuc.append(" ") }
                bosluk = false
                sonuc.unicodeScalars.append(c)
            } else { bosluk = true }
        }
        return sonuc
    }

    /// `toLocaleLowerCase('tr')`
    public static func trKucuk(_ s: String) -> String {
        s.replacingOccurrences(of: "I", with: "ı").replacingOccurrences(of: "İ", with: "i").lowercased()
    }

    /// `dosyaNormal`: Commons dosya adı tek biçimde (%xx çözülür, "File:" atılır, boşluk → _, ilk harf büyük)
    public static func dosyaNormal(_ ad: String?) -> String {
        var s = (ad ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if s.range(of: "%[0-9A-Fa-f]{2}", options: .regularExpression) != nil, let c = s.removingPercentEncoding {
            s = c
        }
        if s.lowercased().hasPrefix("file:") { s = String(s.dropFirst(5)) }
        s = s.replacingOccurrences(of: " ", with: "_")
        guard let ilk = s.first else { return s }
        return ilk.uppercased() + s.dropFirst()
    }

    /// `encodeURIComponent`
    public static func uriBileseni(_ s: String) -> String {
        var sonuc = ""
        sonuc.reserveCapacity(s.utf8.count)
        let hex = Array("0123456789ABCDEF")
        for b in s.utf8 {
            switch b {
            case 0x41...0x5A, 0x61...0x7A, 0x30...0x39,
                 UInt8(ascii: "-"), UInt8(ascii: "_"), UInt8(ascii: "."), UInt8(ascii: "!"), UInt8(ascii: "~"),
                 UInt8(ascii: "*"), UInt8(ascii: "'"), UInt8(ascii: "("), UInt8(ascii: ")"):
                sonuc.unicodeScalars.append(Unicode.Scalar(b))
            default:
                sonuc.append("%")
                sonuc.append(hex[Int(b >> 4)])
                sonuc.append(hex[Int(b & 0xF)])
            }
        }
        return sonuc
    }

    /// `resimUrl`: Commons Special:FilePath adresi
    public static func resimUrl(_ dosya: String?, genislik: Int = 800) -> String {
        "https://commons.wikimedia.org/wiki/Special:FilePath/\(uriBileseni(dosyaNormal(dosya)))?width=\(genislik)"
    }

    /// `dosyaSayfasi`
    public static func dosyaSayfasi(_ dosya: String?) -> String {
        "https://commons.wikimedia.org/wiki/File:\(uriBileseni(dosyaNormal(dosya)))"
    }

    // MARK: notTemizle

    private static let notKelime = try! NSRegularExpression(
        pattern: "(?<![\\p{L}])(slayt\\p{L}*|metin\\p{L}*|metne|künye\\p{L}*|altyaz\\p{L}*)", options: [.caseInsensitive])
    private static let notOnek = try! NSRegularExpression(
        pattern: "^(slayt\\p{L}*\\s+(künye\\p{L}*|yazı\\p{L}*|altyazı\\p{L}*|etiket\\p{L}*)(\\s+göre)?|slayt\\p{L}*(\\s+göre)?|metin\\p{L}*(\\s+göre)?|metne\\s+göre)\\s*:?\\s*",
        options: [.caseInsensitive])
    private static let parantez = try! NSRegularExpression(pattern: "\\s*\\(([^()]*)\\)")

    static func var_(_ r: NSRegularExpression, _ s: String) -> Bool {
        r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    /// `notTemizle`: kurs notlarından kalan "slayt/metin" açıklamalarını gösterimden atar
    public static func notTemizle(_ metin: String?) -> String {
        var s = metin ?? ""
        guard var_(notKelime, s) else { return s }
        // parantez içi notlar
        let ns = s as NSString
        var yeni = ""
        var son = 0
        for m in parantez.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            yeni += ns.substring(with: NSRange(location: son, length: m.range.location - son))
            let ic = ns.substring(with: m.range(at: 1))
            if !var_(notKelime, ic) { yeni += ns.substring(with: m.range) }
            son = m.range.location + m.range.length
        }
        yeni += ns.substring(from: son)
        s = yeni

        struct Parca { var metin: String; var slayt: Bool; var metinden: Bool }
        let parcalar: [Parca] = s.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { p in
                let onekli = var_(notOnek, p)
                let kalan = notOnek.stringByReplacingMatches(in: p, range: NSRange(p.startIndex..., in: p), withTemplate: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let kucuk = p.lowercased()
                return Parca(metin: kalan, slayt: onekli && kucuk.hasPrefix("slayt"), metinden: onekli && kucuk.hasPrefix("met"))
            }
            .filter { !$0.metin.isEmpty && !var_(notKelime, $0.metin) }
        let kalan = parcalar.contains { $0.metinden } ? parcalar.filter { !$0.slayt } : parcalar
        return kalan.map(\.metin).joined(separator: "; ")
    }

    // MARK: md5 (yalnız Commons küçük resim yolu için)

    /// `md5(metin)`: UTF-8 metnin onaltılık özeti
    public static func md5(_ metin: String) -> String {
        let s: [UInt32] = [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                           5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
                           4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                           6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]
        let k: [UInt32] = (0..<64).map { UInt32(truncatingIfNeeded: Int64(abs(sin(Double($0 + 1))) * 4294967296.0)) }
        var veri = Array(metin.utf8)
        let bit = UInt64(veri.count) &* 8
        veri.append(0x80)
        while veri.count % 64 != 56 { veri.append(0) }
        for j in 0..<8 { veri.append(UInt8(truncatingIfNeeded: bit >> (8 * UInt64(j)))) }
        var a0: UInt32 = 0x67452301, b0: UInt32 = 0xefcdab89, c0: UInt32 = 0x98badcfe, d0: UInt32 = 0x10325476
        for blok in stride(from: 0, to: veri.count, by: 64) {
            var m = [UInt32](repeating: 0, count: 16)
            for w in 0..<16 {
                let o = blok + w * 4
                m[w] = UInt32(veri[o]) | UInt32(veri[o + 1]) << 8 | UInt32(veri[o + 2]) << 16 | UInt32(veri[o + 3]) << 24
            }
            var a = a0, b = b0, c = c0, d = d0
            for i in 0..<64 {
                var f: UInt32
                let g: Int
                switch i {
                case 0..<16: f = (b & c) | (~b & d); g = i
                case 16..<32: f = (d & b) | (~d & c); g = (5 * i + 1) % 16
                case 32..<48: f = b ^ c ^ d; g = (3 * i + 5) % 16
                default: f = c ^ (b | ~d); g = (7 * i) % 16
                }
                f = f &+ a &+ k[i] &+ m[g]
                a = d; d = c; c = b
                b = b &+ ((f << s[i]) | (f >> (32 - s[i])))
            }
            a0 = a0 &+ a; b0 = b0 &+ b; c0 = c0 &+ c; d0 = d0 &+ d
        }
        return [a0, b0, c0, d0].map { v in
            (0..<4).map { String(format: "%02x", (v >> (8 * UInt32($0))) & 0xFF) }.joined()
        }.joined()
    }
}

// MARK: - Adlar (js/adlar.js)

/// `data/kisa_adlar.json` kaydı
public struct KisaAd: Equatable, Hashable, Sendable, Codable {
    public var buyuk: String?
    public var kucuk: String?
    public init(buyuk: String?, kucuk: String?) { self.buyuk = buyuk; self.kucuk = kucuk }
}

/// `adParcala` sonucu: küçük satır (italik), büyük satır (bilinen ad), varsa büyük satırın altındaki tam ad
public struct AdParcalari: Equatable, Hashable, Sendable, Codable {
    public var ilk: String
    public var son: String
    public var tam: String?
}

public enum Adlar {
    static let ekler: Set<String> = ["van", "von", "de", "der", "den", "da", "di", "del", "della", "du", "la", "le", "ter", "el"]
    private static let parantezli = try! NSRegularExpression(pattern: "^(.*?)(\\s*\\([^)]*\\))?$")

    /// `adParcala(ad, kisa)`
    public static func parcala(_ ad: String, kisa: KisaAd? = nil) -> AdParcalari {
        if let kisa, let buyuk = kisa.buyuk, !buyuk.isEmpty {
            let kucuk = kisa.kucuk ?? ""
            let tam = [buyuk, kucuk].filter { !$0.isEmpty }.joined(separator: " ")
            if ad.hasPrefix(buyuk) {
                return kucuk.isEmpty ? AdParcalari(ilk: "", son: buyuk) : AdParcalari(ilk: "", son: buyuk, tam: tam)
            }
            return AdParcalari(ilk: kucuk, son: buyuk)
        }
        let s = ad.trimmingCharacters(in: .whitespacesAndNewlines)
        let ns = s as NSString
        var ana = s, parantez = ""
        if let m = parantezli.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) {
            ana = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            if m.range(at: 2).location != NSNotFound {
                parantez = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        let k = ana.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        let kelimeler = k.isEmpty ? [""] : k
        var i = kelimeler.count - 1
        if kelimeler.count == 2 && kelimeler[1] == SiteYazisi.trKucuk(kelimeler[1]) { i = 0 }
        while i > 0 && ekler.contains(SiteYazisi.trKucuk(kelimeler[i - 1])) { i -= 1 }
        let son = [kelimeler[i...].joined(separator: " "), parantez].filter { !$0.isEmpty }.joined(separator: " ")
        return AdParcalari(ilk: kelimeler[..<i].joined(separator: " "), son: son)
    }

    /// `bilinenAd`
    public static func bilinen(_ ad: String, kisa: KisaAd? = nil) -> String { parcala(ad, kisa: kisa).son }
}

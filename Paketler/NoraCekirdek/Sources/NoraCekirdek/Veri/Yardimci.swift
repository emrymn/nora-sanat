// Kaynak: sanat-atlasi js/yardimci.js, js/md5.js @ a866b86 (site 1.90.3)
// Sitenin küçük, saf yardımcılarının birebir karşılıkları. Sonuçlar JavaScript'inkiyle aynı olmalı:
// Testler/kahin/site_verisi.mjs `yapay` bölümü bunları canlı siteyle karşılaştırır.
import Foundation

/// JavaScript'in yerleşik davranışları (encodeURIComponent, String(sayı), trim)
public enum JS {
    /// `encodeURIComponent`: UTF-8 baytları; A–Z a–z 0–9 - _ . ! ~ * ' ( ) dışındakiler %XX
    public static func encodeURIComponent(_ s: String) -> String {
        var sonuc = ""
        sonuc.reserveCapacity(s.utf8.count)
        let onaltilik = Array("0123456789ABCDEF")
        for b in s.utf8 {
            switch b {
            case 0x41...0x5A, 0x61...0x7A, 0x30...0x39, 0x2D, 0x5F, 0x2E, 0x21, 0x7E, 0x2A, 0x27, 0x28, 0x29:
                sonuc.unicodeScalars.append(Unicode.Scalar(b))
            default:
                sonuc.append("%")
                sonuc.append(onaltilik[Int(b >> 4)])
                sonuc.append(onaltilik[Int(b & 0xF)])
            }
        }
        return sonuc
    }

    /// `String(sayı)`: tam sayılar ondalıksız ("1", "0.61")
    public static func sayi(_ x: Double) -> String {
        if x.rounded() == x, abs(x) < 1e15 { return String(Int64(x)) }
        return "\(x)"
    }

    /// `String.prototype.trim`
    public static func kirp(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}")))
    }

    /// Boş dizgeyi yok sayar (JS'teki `a || b` zinciri için)
    @inline(__always) static func dolu(_ s: String?) -> String? {
        guard let s, !s.isEmpty else { return nil }
        return s
    }
}

public enum Yardimci {
    /// `yilYaz`: -450 → "MÖ 450", nil → "?"
    public static func yilYaz(_ y: Int?) -> String {
        guard let y else { return "?" }
        return y < 0 ? "MÖ \(-y)" : String(y)
    }

    /// `yillarYaz`: sanatçının yaşam yılları
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

    /// js/eserler.js `tarihYaz`: yıl yoksa boş
    static func tarihYaz(_ y: Int?) -> String { y.map(yilYaz) ?? "" }

    /// `baslikNormal`: başlık karşılaştırması için
    public static func baslikNormal(_ s: String) -> String {
        let kucuk = s.lowercased(with: Locale(identifier: "tr")).decomposedStringWithCanonicalMapping
        var sonuc = ""
        var bosluk = false
        for u in kucuk.unicodeScalars {
            if (0x300...0x36F).contains(u.value) { continue }
            let c: Unicode.Scalar = u == "ı" ? "i" : u
            if ("a"..."z").contains(c) || ("0"..."9").contains(c) {
                if bosluk && !sonuc.isEmpty { sonuc.append(" ") }
                bosluk = false
                sonuc.unicodeScalars.append(c)
            } else {
                bosluk = true
            }
        }
        return sonuc
    }

    /// `dosyaNormal`: Commons dosya adı tek biçime (%xx çözülür, "File:" atılır, boşluk → _, ilk harf büyük)
    public static func dosyaNormal(_ ad: String?) -> String {
        var s = JS.kirp(ad ?? "")
        if s.range(of: "%[0-9A-Fa-f]{2}", options: .regularExpression) != nil, let c = s.removingPercentEncoding {
            s = c
        }
        if s.count >= 5, s.prefix(5).lowercased() == "file:" { s = String(s.dropFirst(5)) }
        s = s.replacingOccurrences(of: " ", with: "_")
        guard let ilk = s.unicodeScalars.first else { return s }
        return String(ilk).uppercased() + String(s.unicodeScalars.dropFirst())
    }

    /// `resimUrl`: Commons Special:FilePath adresi
    public static func resimUrl(_ dosya: String?, genislik: Int = 800) -> String {
        "https://commons.wikimedia.org/wiki/Special:FilePath/\(JS.encodeURIComponent(dosyaNormal(dosya)))?width=\(genislik)"
    }

    /// `dosyaSayfasi`: Commons dosya sayfası
    public static func dosyaSayfasi(_ dosya: String?) -> String {
        "https://commons.wikimedia.org/wiki/File:\(JS.encodeURIComponent(dosyaNormal(dosya)))"
    }

    // MARK: notTemizle

    private static let notKelime = try! NSRegularExpression(
        pattern: #"(?<![\p{L}])(slayt\p{L}*|metin\p{L}*|metne|künye\p{L}*|altyaz\p{L}*)"#, options: [.caseInsensitive])
    private static let notOnek = try! NSRegularExpression(
        pattern: #"^(slayt\p{L}*\s+(künye\p{L}*|yazı\p{L}*|altyazı\p{L}*|etiket\p{L}*)(\s+göre)?|slayt\p{L}*(\s+göre)?|metin\p{L}*(\s+göre)?|metne\s+göre)\s*:?\s*"#,
        options: [.caseInsensitive])
    private static let parantez = try! NSRegularExpression(pattern: #"\s*\(([^()]*)\)"#)

    private static func var_(_ r: NSRegularExpression, _ s: String) -> Bool {
        r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    /// `notTemizle`: kurs notlarından kalan "slayt/metin" açıklamalarını gösterimden atar (D8)
    public static func notTemizle(_ metin: String?) -> String {
        var s = metin ?? ""
        guard var_(notKelime, s) else { return s }
        // parantez içi notlar
        let ns = s as NSString
        var parcalar: [String] = []
        var son = 0
        for m in parantez.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            let ic = ns.substring(with: m.range(at: 1))
            if var_(notKelime, ic) {
                parcalar.append(ns.substring(with: NSRange(location: son, length: m.range.location - son)))
                son = m.range.location + m.range.length
            }
        }
        parcalar.append(ns.substring(from: son))
        s = parcalar.joined()

        struct Parca { let metin: String; let slayt: Bool; let metinden: Bool }
        let liste: [Parca] = s.components(separatedBy: ";").map(JS.kirp).filter { !$0.isEmpty }.map { p in
            let onekli = var_(notOnek, p)
            let pn = p as NSString
            let kalan = JS.kirp(notOnek.stringByReplacingMatches(in: p, range: NSRange(location: 0, length: pn.length),
                                                                 withTemplate: ""))
            let k = p.lowercased()
            return Parca(metin: kalan, slayt: onekli && k.hasPrefix("slayt"), metinden: onekli && k.hasPrefix("met"))
        }.filter { !$0.metin.isEmpty && !var_(notKelime, $0.metin) }
        let kalan = liste.contains(where: \.metinden) ? liste.filter { !$0.slayt } : liste
        return kalan.map(\.metin).joined(separator: "; ")
    }
}

/// MD5 (RFC 1321), UTF-8 metin için. Yalnız Commons küçük resim yolunu (…/thumb/a/ab/…) bulmakta kullanılır.
public enum MD5 {
    private static let s: [UInt32] = [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                                      5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
                                      4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                                      6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]
    private static let k: [UInt32] = (0..<64).map { UInt32(truncatingIfNeeded: Int64(abs(sin(Double($0 + 1))) * 4294967296)) }

    public static func onaltilik(_ metin: String) -> String {
        var veri = Array(metin.utf8)
        let bitUzunluk = UInt64(veri.count) &* 8
        veri.append(0x80)
        while veri.count % 64 != 56 { veri.append(0) }
        for i in 0..<8 { veri.append(UInt8(truncatingIfNeeded: bitUzunluk >> (8 * UInt64(i)))) }

        var a0: UInt32 = 0x67452301, b0: UInt32 = 0xefcdab89, c0: UInt32 = 0x98badcfe, d0: UInt32 = 0x10325476
        var m = [UInt32](repeating: 0, count: 16)
        for blok in stride(from: 0, to: veri.count, by: 64) {
            for i in 0..<16 {
                let j = blok + i * 4
                m[i] = UInt32(veri[j]) | UInt32(veri[j + 1]) << 8 | UInt32(veri[j + 2]) << 16 | UInt32(veri[j + 3]) << 24
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
                b = b &+ (f << s[i] | f >> (32 - s[i]))
            }
            a0 = a0 &+ a; b0 = b0 &+ b; c0 = c0 &+ c; d0 = d0 &+ d
        }
        let hex = Array("0123456789abcdef")
        var sonuc = ""
        for v in [a0, b0, c0, d0] {
            for i in 0..<4 {
                let bayt = UInt8(truncatingIfNeeded: v >> (8 * UInt32(i)))
                sonuc.append(hex[Int(bayt >> 4)]); sonuc.append(hex[Int(bayt & 0xF)])
            }
        }
        return sonuc
    }
}

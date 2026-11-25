// Kaynak: sanat-atlasi js/yenilikler.js (YENILIKLER, yeniMi, gosterilecekler, yenilikYazisi) @ 7cf00b8 (site 1.90.3)
// Z3x: Ayarlar → Hakkında → "Yenilikler". Liste uygulamaya kopyalanmaz: tek kaynak sitenin `js/yenilikler.js`'i; uygulama
// dosyayı siteden indirir (`SiteVerisi.kokDosyasi`, çevrimdışıyken son inen) ve buradaki küçük okuyucuyla çözer.
// Kâhin: Testler/kahin/yenilikler.mjs (sitenin kendi modülüyle) → Tests/.../Ornekler/yenilikler/.
import Foundation

/// Bir sürüm notu (`{ surum, metin }`)
public struct Yenilik: Equatable, Hashable, Sendable {
    public let surum: String
    public let metin: String

    public init(surum: String, metin: String) {
        self.surum = surum
        self.metin = metin
    }

    /// `yenilikYazisi(x)`: "1.90 · metin" (sondaki ".0" düşer)
    public var yazi: String { "\(Yenilikler.surumAdi(surum)) · \(metin)" }
}

public enum Yenilikler {
    /// `js/yenilikler.js`'in `YENILIKLER` dizisini okur. Dizi yalnız `{ surum: '…', metin: '…' }` nesnelerinden oluşur;
    /// dizgeler tek, çift ya da ters tırnaklı olabilir (kaçışlar: `\\`, `\'`, `\"`, `\n`, `\uXXXX`). Okunamayan nesne atlanır;
    /// dizi bulunamazsa boş liste.
    public static func coz(_ js: String) -> [Yenilik] {
        let k = Array(js.unicodeScalars)
        guard let bas = bul(Array("YENILIKLER".unicodeScalars), k) else { return [] }
        var i = bas
        while i < k.count, k[i] != "[" { i += 1 }
        guard i < k.count else { return [] }
        i += 1
        var sonuc: [Yenilik] = []
        var alanlar: [String: String] = [:]
        var anahtar: String?
        var deger = false   // ":" görüldü, sıradaki değer
        var icinde = false
        while i < k.count {
            let c = k[i]
            if c == "'" || c == "\"" || c == "`" {
                let (s, son) = dizge(k, i)
                i = son
                if icinde {
                    if deger, let a = anahtar { alanlar[a] = s; anahtar = nil } else if !deger { anahtar = s }
                    deger = false
                }
                continue
            }
            if c == "/", i + 1 < k.count, k[i + 1] == "/" {   // satır yorumu
                while i < k.count, k[i] != "\n" { i += 1 }
                continue
            }
            if icinde, harf(c) {
                var a = ""
                while i < k.count, harf(k[i]) { a.unicodeScalars.append(k[i]); i += 1 }
                if deger { anahtar = nil; deger = false } else { anahtar = a }   // dizge olmayan değer atlanır
                continue
            }
            switch c {
            case "{":
                icinde = true; alanlar = [:]; anahtar = nil; deger = false
            case "}":
                if icinde, let s = alanlar["surum"], let m = alanlar["metin"] { sonuc.append(Yenilik(surum: s, metin: m)) }
                icinde = false
            case "]":
                if !icinde { return sonuc }
            case ":":
                deger = true
            case ",":
                anahtar = nil; deger = false
            default:
                break
            }
            i += 1
        }
        return sonuc
    }

    /// `x.surum.replace(/\.0$/, '')`
    public static func surumAdi(_ s: String) -> String {
        s.hasSuffix(".0") ? String(s.dropLast(2)) : s
    }

    /// `yeniMi(a, b)`: a, b'den yeni mi (ilk üç parça sayı olarak; eksik ya da sayı olmayan parça 0)
    public static func yeniMi(_ a: String, _ b: String) -> Bool {
        let x = a.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        let y = b.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        for i in 0..<3 {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }

    /// `gosterilecekler(sonGorulen, surum, calismis, liste)`: son görülen sürümden sonraki ve şimdiki sürüme kadar
    /// olanlar (en yeni başta); hiç sürüm görmemişse yalnız şimdikinin notu; hiç çalışmamış yeni kullanıcıya hiçbiri.
    public static func gosterilecekler(sonGorulen: String?, surum: String, calismis: Bool, liste: [Yenilik]) -> [Yenilik] {
        let son = sonGorulen.flatMap { $0.isEmpty ? nil : $0 }
        if son == nil && !calismis { return [] }
        let uygun = liste.filter { x in !yeniMi(x.surum, surum) && (son.map { s in yeniMi(x.surum, s) } ?? true) }
        return son != nil ? uygun : Array(uygun.prefix(1))
    }

    // MARK: Okuyucu

    private static func harf(_ c: Unicode.Scalar) -> Bool {
        CharacterSet.alphanumerics.contains(c) || c == "_" || c == "$"
    }

    /// `aranan` adının ardından (boşluktan sonra) "=" gelen ilk yer: `YENILIKLER = [` (yorumdaki ad sayılmaz)
    private static func bul(_ aranan: [Unicode.Scalar], _ k: [Unicode.Scalar]) -> Int? {
        guard aranan.count <= k.count else { return nil }
        var i = 0
        while i + aranan.count <= k.count {
            if Array(k[i..<(i + aranan.count)]) == aranan {
                var j = i + aranan.count
                while j < k.count, k[j] == " " || k[j] == "\t" { j += 1 }
                if j < k.count, k[j] == "=" { return j + 1 }
            }
            i += 1
        }
        return nil
    }

    /// `k[i]` tırnakla başlayan dizge → (değer, kapanış tırnağından sonraki konum)
    private static func dizge(_ k: [Unicode.Scalar], _ bas: Int) -> (String, Int) {
        let tirnak = k[bas]
        var s = String.UnicodeScalarView()
        var i = bas + 1
        while i < k.count {
            let c = k[i]
            if c == tirnak { return (String(s), i + 1) }
            if c == "\\", i + 1 < k.count {
                let n = k[i + 1]
                i += 2
                switch n {
                case "n": s.append("\n")
                case "t": s.append("\t")
                case "r": s.append("\r")
                case "u":
                    if i + 4 <= k.count, let v = UInt32(String(String.UnicodeScalarView(k[i..<(i + 4)])), radix: 16),
                       let u = Unicode.Scalar(v) {
                        s.append(u); i += 4
                    }
                case "\n": break   // satır devamı
                default: s.append(n)
                }
                continue
            }
            s.append(c)
            i += 1
        }
        return (String(s), i)
    }
}

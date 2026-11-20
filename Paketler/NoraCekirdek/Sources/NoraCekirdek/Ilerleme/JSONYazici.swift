import Foundation

// JSONDeger'i yazmak (`JSON.stringify` biçiminde) ve sırası korunarak değiştirmek.
// İlerleme siteye geri yazılırken bilinmeyen alanlar ve anahtar sırası olduğu gibi kalır (K2).

public extension JSONDeger {
    /// `JSON.stringify(x)` (boşluksuz)
    var jsonMetni: String {
        var s = ""
        yaz(&s)
        return s
    }

    var jsonVerisi: Data { Data(jsonMetni.utf8) }

    func yaz(_ s: inout String) {
        switch self {
        case .bos: s += "null"
        case .mantik(let b): s += b ? "true" : "false"
        case .sayi(let d): s += Self.sayiMetni(d)
        case .metin(let m): Self.metinYaz(m, &s)
        case .dizi(let l):
            s += "["
            for (i, x) in l.enumerated() { if i > 0 { s += "," }; x.yaz(&s) }
            s += "]"
        case .nesne(let n):
            s += "{"
            for (i, c) in n.ciftler.enumerated() {
                if i > 0 { s += "," }
                Self.metinYaz(c.anahtar, &s)
                s += ":"
                c.deger.yaz(&s)
            }
            s += "}"
        }
    }

    /// JS sayı yazımı: tam sayılar ".0"sız, üs "e-7" biçiminde; NaN/sonsuz → null
    static func sayiMetni(_ d: Double) -> String {
        guard d.isFinite else { return "null" }
        if d.rounded() == d && abs(d) < 1e21 { return d == 0 ? "0" : String(Int64(d)) }
        var t = "\(d)"
        if let e = t.firstIndex(of: "e") {
            var us = String(t[t.index(after: e)...])
            var isaret = "+"
            if us.hasPrefix("-") || us.hasPrefix("+") { isaret = String(us.removeFirst()) }
            while us.count > 1 && us.hasPrefix("0") { us.removeFirst() }
            t = String(t[..<e]) + "e" + isaret + us
        }
        return t
    }

    static func metinYaz(_ m: String, _ s: inout String) {
        s += "\""
        for u in m.unicodeScalars {
            switch u {
            case "\"": s += "\\\""
            case "\\": s += "\\\\"
            case "\n": s += "\\n"
            case "\r": s += "\\r"
            case "\t": s += "\\t"
            case "\u{08}": s += "\\b"
            case "\u{0C}": s += "\\f"
            default:
                if u.value < 0x20 {
                    s += "\\u00" + (u.value < 0x10 ? "0" : "") + String(u.value, radix: 16)
                } else { s.unicodeScalars.append(u) }
            }
        }
        s += "\""
    }

    // Kısa kurucular
    static func sayi(_ n: Int) -> JSONDeger { .sayi(Double(n)) }
    static func metinYaDaBos(_ s: String?) -> JSONDeger { s.map { .metin($0) } ?? .bos }
    static func nesne(_ ciftler: [(String, JSONDeger)]) -> JSONDeger { .nesne(SiraliNesne(ciftler)) }
}

public extension SiraliNesne {
    static let bos = SiraliNesne([])

    init(ciftler: [(String, JSONDeger)]) { self.init(ciftler) }

    /// Anahtarı ayarlar: varsa yerinde, yoksa sona; nil verilirse siler
    func ayarlandi(_ anahtar: String, _ deger: JSONDeger?) -> SiraliNesne {
        var l = ciftler.map { ($0.anahtar, $0.deger) }
        if let i = l.firstIndex(where: { $0.0 == anahtar }) {
            if let deger { l[i].1 = deger } else { l.remove(at: i) }
        } else if let deger {
            l.append((anahtar, deger))
        }
        return SiraliNesne(l)
    }

    /// Bir sözlüğün tamamını yazar: var olan anahtarlar yerinde, silinenler çıkar, yeniler sıralı olarak sona eklenir
    func yerine(_ yeni: [String: JSONDeger]) -> SiraliNesne {
        var l: [(String, JSONDeger)] = ciftler.compactMap { c in yeni[c.anahtar].map { (c.anahtar, $0) } }
        let eski = Set(ciftler.map(\.anahtar))
        for a in yeni.keys.filter({ !eski.contains($0) }).sorted(by: { $0.utf16.lexicographicallyPrecedes($1.utf16) }) {
            l.append((a, yeni[a]!))
        }
        return SiraliNesne(l)
    }
}

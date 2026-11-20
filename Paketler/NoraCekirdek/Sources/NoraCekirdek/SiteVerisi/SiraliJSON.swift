import Foundation

/// Anahtar sırasını koruyan JSON değeri. Site birçok kuralında `Object.entries`/`Object.keys` sırasına dayanır
/// (örneğin `eserler_onbellek.json`'daki sanatçı sırası ortak atıfların sırasını belirler); `JSONSerialization`
/// bu sırayı kaybeder. Ayrıca aynı anahtar iki kez geçerse `JSON.parse` gibi sonuncusu kalır, çökme olmaz.
public enum JSONDeger: Equatable, Sendable {
    case bos
    case mantik(Bool)
    case sayi(Double)
    case metin(String)
    case dizi([JSONDeger])
    case nesne(SiraliNesne)

    public static func coz(_ veri: Data) throws -> JSONDeger {
        var c = Cozucu(bayt: [UInt8](veri))
        c.bosluk()
        let d = try c.deger()
        c.bosluk()
        guard c.i == c.bayt.count else { throw JSONHatasi.fazlalik(c.i) }
        return d
    }

    public subscript(_ anahtar: String) -> JSONDeger? {
        if case .nesne(let n) = self { return n[anahtar] }
        return nil
    }

    public var metin: String? { if case .metin(let s) = self { return s }; return nil }
    public var sayi: Double? { if case .sayi(let s) = self { return s }; return nil }
    public var mantik: Bool? { if case .mantik(let b) = self { return b }; return nil }
    public var dizi: [JSONDeger]? { if case .dizi(let d) = self { return d }; return nil }
    public var nesne: SiraliNesne? { if case .nesne(let n) = self { return n }; return nil }
    public var bosMu: Bool { self == .bos }

    /// `Number.isInteger(x)` doğruysa tam sayı
    public var tamSayi: Int? {
        guard let s = sayi, s.isFinite, s.rounded() == s, abs(s) < 9e15 else { return nil }
        return Int(s)
    }

    /// Boş olmayan metin (JS'teki `x || ...` kalıbı için)
    public var doluMetin: String? { metin.flatMap { $0.isEmpty ? nil : $0 } }

    /// JS doğruluk değeri (`if (x)`)
    public var dogru: Bool {
        switch self {
        case .bos: return false
        case .mantik(let b): return b
        case .sayi(let s): return s != 0 && !s.isNaN
        case .metin(let s): return !s.isEmpty
        case .dizi, .nesne: return true
        }
    }

    /// JS `String(x)` (sayılarda "1234", "1.5")
    public var jsMetni: String {
        switch self {
        case .bos: return "null"
        case .mantik(let b): return b ? "true" : "false"
        case .sayi(let s): return s.rounded() == s && abs(s) < 1e21 ? String(Int64(s)) : String(s)
        case .metin(let m): return m
        case .dizi(let d): return d.map { $0 == .bos ? "" : $0.jsMetni }.joined(separator: ",")
        case .nesne: return "[object Object]"
        }
    }
}

/// Sırası korunan JSON nesnesi
public struct SiraliNesne: Equatable, Sendable {
    public let ciftler: [(anahtar: String, deger: JSONDeger)]
    public let sozluk: [String: JSONDeger]

    init(_ ciftler: [(String, JSONDeger)]) {
        var s: [String: JSONDeger] = [:]
        s.reserveCapacity(ciftler.count)
        var sirali: [(anahtar: String, deger: JSONDeger)] = []
        sirali.reserveCapacity(ciftler.count)
        var yer: [String: Int] = [:]
        for (a, d) in ciftler {
            // JSON.parse: yinelenen anahtarın son değeri, ilk yerinde
            if let i = yer[a] { sirali[i].deger = d } else { yer[a] = sirali.count; sirali.append((a, d)) }
            s[a] = d
        }
        self.ciftler = sirali
        self.sozluk = s
    }

    public subscript(_ anahtar: String) -> JSONDeger? { sozluk[anahtar] }
    public var anahtarlar: [String] { ciftler.map(\.anahtar) }
    public var count: Int { ciftler.count }

    public static func == (a: SiraliNesne, b: SiraliNesne) -> Bool {
        a.ciftler.count == b.ciftler.count && zip(a.ciftler, b.ciftler).allSatisfy { $0.anahtar == $1.anahtar && $0.deger == $1.deger }
    }
}

public enum JSONHatasi: Error, Equatable {
    case beklenmedik(Int)
    case fazlalik(Int)
    case bitti
}

private struct Cozucu {
    let bayt: [UInt8]
    var i = 0

    init(bayt: [UInt8]) {
        self.bayt = bayt
        // UTF-8 BOM
        if bayt.count >= 3, bayt[0] == 0xEF, bayt[1] == 0xBB, bayt[2] == 0xBF { i = 3 }
    }

    mutating func bosluk() {
        while i < bayt.count, bayt[i] == 0x20 || bayt[i] == 0x0A || bayt[i] == 0x0D || bayt[i] == 0x09 { i += 1 }
    }

    mutating func deger() throws -> JSONDeger {
        guard i < bayt.count else { throw JSONHatasi.bitti }
        switch bayt[i] {
        case UInt8(ascii: "{"): return try nesne()
        case UInt8(ascii: "["): return try dizi()
        case UInt8(ascii: "\""): return .metin(try metin())
        case UInt8(ascii: "t"): try kelime("true"); return .mantik(true)
        case UInt8(ascii: "f"): try kelime("false"); return .mantik(false)
        case UInt8(ascii: "n"): try kelime("null"); return .bos
        default: return .sayi(try sayi())
        }
    }

    mutating func kelime(_ k: String) throws {
        let b = Array(k.utf8)
        guard i + b.count <= bayt.count else { throw JSONHatasi.bitti }
        for j in 0..<b.count where bayt[i + j] != b[j] { throw JSONHatasi.beklenmedik(i + j) }
        i += b.count
    }

    mutating func nesne() throws -> JSONDeger {
        i += 1
        var ciftler: [(String, JSONDeger)] = []
        bosluk()
        if i < bayt.count, bayt[i] == UInt8(ascii: "}") { i += 1; return .nesne(SiraliNesne(ciftler)) }
        while true {
            bosluk()
            guard i < bayt.count, bayt[i] == UInt8(ascii: "\"") else { throw JSONHatasi.beklenmedik(i) }
            let a = try metin()
            bosluk()
            guard i < bayt.count, bayt[i] == UInt8(ascii: ":") else { throw JSONHatasi.beklenmedik(i) }
            i += 1
            bosluk()
            ciftler.append((a, try deger()))
            bosluk()
            guard i < bayt.count else { throw JSONHatasi.bitti }
            if bayt[i] == UInt8(ascii: ",") { i += 1; continue }
            if bayt[i] == UInt8(ascii: "}") { i += 1; return .nesne(SiraliNesne(ciftler)) }
            throw JSONHatasi.beklenmedik(i)
        }
    }

    mutating func dizi() throws -> JSONDeger {
        i += 1
        var l: [JSONDeger] = []
        bosluk()
        if i < bayt.count, bayt[i] == UInt8(ascii: "]") { i += 1; return .dizi(l) }
        while true {
            bosluk()
            l.append(try deger())
            bosluk()
            guard i < bayt.count else { throw JSONHatasi.bitti }
            if bayt[i] == UInt8(ascii: ",") { i += 1; continue }
            if bayt[i] == UInt8(ascii: "]") { i += 1; return .dizi(l) }
            throw JSONHatasi.beklenmedik(i)
        }
    }

    mutating func sayi() throws -> Double {
        let bas = i
        while i < bayt.count {
            let c = bayt[i]
            if (c >= 0x30 && c <= 0x39) || c == UInt8(ascii: "-") || c == UInt8(ascii: "+") || c == UInt8(ascii: ".")
                || c == UInt8(ascii: "e") || c == UInt8(ascii: "E") { i += 1 } else { break }
        }
        guard i > bas, let s = String(bytes: bayt[bas..<i], encoding: .ascii), let d = Double(s) else {
            throw JSONHatasi.beklenmedik(bas)
        }
        return d
    }

    mutating func hex4() throws -> UInt32 {
        guard i + 4 <= bayt.count else { throw JSONHatasi.bitti }
        var v: UInt32 = 0
        for _ in 0..<4 {
            let c = bayt[i]
            let h: UInt32
            switch c {
            case 0x30...0x39: h = UInt32(c - 0x30)
            case 0x41...0x46: h = UInt32(c - 0x41 + 10)
            case 0x61...0x66: h = UInt32(c - 0x61 + 10)
            default: throw JSONHatasi.beklenmedik(i)
            }
            v = v << 4 | h
            i += 1
        }
        return v
    }

    mutating func metin() throws -> String {
        i += 1
        var tampon: [UInt8] = []
        var bas = i
        while true {
            guard i < bayt.count else { throw JSONHatasi.bitti }
            let c = bayt[i]
            if c == UInt8(ascii: "\"") {
                tampon.append(contentsOf: bayt[bas..<i])
                i += 1
                return String(decoding: tampon, as: UTF8.self)
            }
            if c != UInt8(ascii: "\\") { i += 1; continue }
            tampon.append(contentsOf: bayt[bas..<i])
            i += 1
            guard i < bayt.count else { throw JSONHatasi.bitti }
            let e = bayt[i]
            i += 1
            switch e {
            case UInt8(ascii: "\""): tampon.append(0x22)
            case UInt8(ascii: "\\"): tampon.append(0x5C)
            case UInt8(ascii: "/"): tampon.append(0x2F)
            case UInt8(ascii: "b"): tampon.append(0x08)
            case UInt8(ascii: "f"): tampon.append(0x0C)
            case UInt8(ascii: "n"): tampon.append(0x0A)
            case UInt8(ascii: "r"): tampon.append(0x0D)
            case UInt8(ascii: "t"): tampon.append(0x09)
            case UInt8(ascii: "u"):
                var kod = try hex4()
                if (0xD800...0xDBFF).contains(kod), i + 6 <= bayt.count,
                   bayt[i] == UInt8(ascii: "\\"), bayt[i + 1] == UInt8(ascii: "u") {
                    let geri = i
                    i += 2
                    let alt = try hex4()
                    if (0xDC00...0xDFFF).contains(alt) {
                        kod = 0x10000 + ((kod - 0xD800) << 10) + (alt - 0xDC00)
                    } else { i = geri }
                }
                let skaler = Unicode.Scalar(kod) ?? "\u{FFFD}"
                tampon.append(contentsOf: Array(String(Character(skaler)).utf8))
            default: throw JSONHatasi.beklenmedik(i - 1)
            }
            bas = i
        }
    }
}

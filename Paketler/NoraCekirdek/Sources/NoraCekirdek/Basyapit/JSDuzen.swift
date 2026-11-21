// JS düzenli ifadelerinin Swift karşılığı (yalnız Başyapıt ve eser dersi kuralları için).
// JS'te (u bayrağı yokken) \b ve \w yalnız ASCII sayar: Türkçe harfler "sözcük dışı"dır. ICU ise Unicode sayar.
// Bu yüzden desenler `\b` yerine `⟨b⟩`, `\w` yerine `⟨w⟩` ile yazılır ve ASCII karşılıklarına çevrilir.
import Foundation

struct JSDuzen: @unchecked Sendable {
    let r: NSRegularExpression

    init(_ desen: String, i: Bool = false) {
        let w = "[A-Za-z0-9_]"
        let d = desen
            .replacingOccurrences(of: "⟨b⟩", with: "(?:(?<=\(w))(?!\(w))|(?<!\(w))(?=\(w)))")
            .replacingOccurrences(of: "⟨w⟩", with: w)
        r = try! NSRegularExpression(pattern: d, options: i ? [.caseInsensitive] : [])
    }

    private static func tum(_ s: String) -> NSRange { NSRange(location: 0, length: (s as NSString).length) }

    /// `re.test(s)`
    func var_(_ s: String) -> Bool { r.firstMatch(in: s, range: Self.tum(s)) != nil }

    /// `re.exec(s)`: ilk eşleşmenin grupları (yoksa nil; eşleşmeyen grup "")
    func ilk(_ s: String) -> [String]? {
        guard let m = r.firstMatch(in: s, range: Self.tum(s)) else { return nil }
        let ns = s as NSString
        return (0..<m.numberOfRanges).map { m.range(at: $0).location == NSNotFound ? "" : ns.substring(with: m.range(at: $0)) }
    }

    /// `s.replace(re /g, şablon)`: şablonda yalnız `$1`… (JS ile aynı); `$` ve `\` başka anlamda kullanılmaz
    func degistir(_ s: String, _ sablon: String) -> String {
        r.stringByReplacingMatches(in: s, range: Self.tum(s), withTemplate: sablon)
    }

    /// `s.replace(re, fn)`: her eşleşme (gruplarıyla) yerine fn'in döndürdüğü
    func degistir(_ s: String, ilkTek: Bool = false, _ fn: ([String]) -> String) -> String {
        let ns = s as NSString
        var cikti = ""
        var son = 0
        var eslesmeler = r.matches(in: s, range: Self.tum(s))
        if ilkTek { eslesmeler = Array(eslesmeler.prefix(1)) }
        for m in eslesmeler {
            cikti += ns.substring(with: NSRange(location: son, length: m.range.location - son))
            let gruplar = (0..<m.numberOfRanges).map { m.range(at: $0).location == NSNotFound ? "" : ns.substring(with: m.range(at: $0)) }
            cikti += fn(gruplar)
            son = m.range.location + m.range.length
        }
        return cikti + ns.substring(from: son)
    }

    /// `s.split(re)` (yakalama grubu yok)
    func bol(_ s: String) -> [String] {
        let ns = s as NSString
        var parcalar: [String] = []
        var son = 0
        for m in r.matches(in: s, range: Self.tum(s)) where m.range.length > 0 {
            parcalar.append(ns.substring(with: NSRange(location: son, length: m.range.location - son)))
            son = m.range.location + m.range.length
        }
        parcalar.append(ns.substring(from: son))
        return parcalar
    }
}

enum JSMetin {
    /// JS `trim()`
    static func kirp(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}"))) }
    /// JS `.length` (UTF-16)
    static func boy(_ s: String) -> Int { s.utf16.count }
    /// `toLocaleLowerCase('tr')`
    static func kucuk(_ s: String) -> String { SiteYazisi.trKucuk(s) }
    /// `toLocaleUpperCase('tr')`
    static func buyuk(_ s: String) -> String {
        s.replacingOccurrences(of: "i", with: "İ").replacingOccurrences(of: "ı", with: "I").uppercased()
    }
    /// `s.replace(/^./, h => h.toLocaleUpperCase('tr'))`
    static func ilkBuyuk(_ s: String) -> String {
        guard let ilk = s.first, ilk != "\n", ilk != "\r", ilk != "\u{2028}", ilk != "\u{2029}" else { return s }
        return buyuk(String(ilk)) + s.dropFirst()
    }
    /// `kacis`: HTML'e kaçırma
    static func kacis(_ s: String) -> String {
        var c = ""
        c.reserveCapacity(s.count)
        for h in s {
            switch h {
            case "&": c += "&amp;"
            case "<": c += "&lt;"
            case ">": c += "&gt;"
            case "\"": c += "&quot;"
            case "'": c += "&#39;"
            default: c.append(h)
            }
        }
        return c
    }
}

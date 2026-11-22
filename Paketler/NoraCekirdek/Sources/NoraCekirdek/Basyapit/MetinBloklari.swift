// Başyapıt sayfasının metinleri sitede HTML olarak kurulur (kaçırılmış metin, `mdHtml`, `terimIsaretle`). Swift aynı HTML'i
// üretir (kâhinle sınanır) ve ekran için bu küçük okuyucuyla bloklara çevirir. Yalnız bu üreticilerin çıkardığı etiketler
// tanınır: p, h1–h6, ul/ol/li, blockquote, hr, table/thead/tbody/tr/th/td, b, i, code, sup, button.bsy-terim.
import Foundation

public struct MetinParcasi: Equatable, Hashable, Sendable {
    public var metin: String
    public var kalin = false
    public var italik = false
    public var kod = false
    /// `<sup>` (kanıt etiketi: ekranda gösterilmez)
    public var ust = false
    /// Sözlük teriminin sırası (`data-bsy-terim`)
    public var terim: Int?

    public init(metin: String, kalin: Bool = false, italik: Bool = false, kod: Bool = false, ust: Bool = false, terim: Int? = nil) {
        self.metin = metin; self.kalin = kalin; self.italik = italik; self.kod = kod; self.ust = ust; self.terim = terim
    }
}

public enum MetinBlogu: Equatable, Hashable, Sendable {
    case paragraf([MetinParcasi])
    case baslik(Int, [MetinParcasi])
    case liste(sirali: Bool, [[MetinParcasi]])
    case alinti([MetinParcasi])
    case cizgi
    case tablo(bas: [[MetinParcasi]], satirlar: [[[MetinParcasi]]])
}

public enum MetinBloklari {
    private static let etiketDeseni = try! NSRegularExpression(pattern: #"<(/?)([a-zA-Z0-9]+)([^>]*)>"#)
    private static let terimDeseni = try! NSRegularExpression(pattern: #"data-bsy-terim="(\d+)""#)

    /// `&amp;` `&lt;` `&gt;` `&quot;` `&#39;` (kacis'in tersi)
    public static func coz(_ s: String) -> String {
        guard s.contains("&") else { return s }
        return s.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    public static func oku(_ html: String) -> [MetinBlogu] {
        var bloklar: [MetinBlogu] = []
        // açık blok
        enum Acik { case yok, p, h(Int), li, alinti, hucre(bas: Bool) }
        var acik = Acik.yok
        var parcalar: [MetinParcasi] = []
        var liste: (sirali: Bool, ogeler: [[MetinParcasi]])?
        var tablo: (bas: [[MetinParcasi]], satirlar: [[[MetinParcasi]]], satir: [[MetinParcasi]], basta: Bool)?
        var kalin = 0, italik = 0, kod = 0, ust = 0
        var terim: Int?

        func ekle(_ m: String) {
            let t = coz(m)
            guard !t.isEmpty else { return }
            if case .yok = acik {
                if liste != nil || tablo != nil { return } // liste ve tablo aralarındaki boşluklar
                if t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
                acik = .p
            }
            let p = MetinParcasi(metin: t, kalin: kalin > 0, italik: italik > 0, kod: kod > 0, ust: ust > 0, terim: terim)
            if let son = parcalar.last, son.kalin == p.kalin, son.italik == p.italik, son.kod == p.kod, son.ust == p.ust,
               son.terim == p.terim {
                parcalar[parcalar.count - 1].metin += p.metin
            } else {
                parcalar.append(p)
            }
        }
        func kapat() {
            switch acik {
            case .yok: break
            case .p: if !parcalar.isEmpty { bloklar.append(.paragraf(parcalar)) }
            case .h(let n): bloklar.append(.baslik(n, parcalar))
            case .alinti: bloklar.append(.alinti(parcalar))
            case .li: liste?.ogeler.append(parcalar)
            case .hucre: tablo?.satir.append(parcalar)
            }
            parcalar = []
            acik = .yok
        }

        let ns = html as NSString
        var son = 0
        for m in etiketDeseni.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            ekle(ns.substring(with: NSRange(location: son, length: m.range.location - son)))
            son = m.range.location + m.range.length
            let kapan = ns.substring(with: m.range(at: 1)) == "/"
            let ad = ns.substring(with: m.range(at: 2)).lowercased()
            let nitelik = ns.substring(with: m.range(at: 3))
            switch (ad, kapan) {
            case ("p", false): kapat(); acik = .p
            case ("p", true), ("li", true), ("blockquote", true), ("th", true), ("td", true): kapat()
            case let (h, k) where h.count == 2 && h.hasPrefix("h") && h != "hr" && Int(h.dropFirst()) != nil:
                kapat()
                if !k { acik = .h(Int(h.dropFirst())!) }
            case ("ul", false), ("ol", false): kapat(); liste = (ad == "ol", [])
            case ("ul", true), ("ol", true):
                kapat()
                if let l = liste { bloklar.append(.liste(sirali: l.sirali, l.ogeler)) }
                liste = nil
            case ("li", false): kapat(); acik = .li
            case ("blockquote", false): kapat(); acik = .alinti
            case ("hr", _): kapat(); bloklar.append(.cizgi)
            case ("table", false): kapat(); tablo = ([], [], [], false)
            case ("table", true):
                kapat()
                if let t = tablo { bloklar.append(.tablo(bas: t.bas, satirlar: t.satirlar)) }
                tablo = nil
            case ("thead", let k): tablo?.basta = !k
            case ("tr", false): tablo?.satir = []
            case ("tr", true):
                if let t = tablo {
                    if t.basta { tablo?.bas = t.satir } else { tablo?.satirlar.append(t.satir) }
                    tablo?.satir = []
                }
            case ("th", false), ("td", false): kapat(); acik = .hucre(bas: ad == "th")
            case ("b", let k), ("strong", let k): kalin += k ? -1 : 1
            case ("i", let k), ("em", let k): italik += k ? -1 : 1
            case ("code", let k): kod += k ? -1 : 1
            case ("sup", let k): ust += k ? -1 : 1
            case ("button", false):
                let nn = nitelik as NSString
                terim = terimDeseni.firstMatch(in: nitelik, range: NSRange(location: 0, length: nn.length))
                    .flatMap { Int(nn.substring(with: $0.range(at: 1))) }
            case ("button", true): terim = nil
            default: break
            }
        }
        ekle(ns.substring(from: son))
        kapat()
        return bloklar
    }

    /// Bloklardaki düz yazı (sınama ve erişilebilirlik için)
    public static func duzYazi(_ bloklar: [MetinBlogu]) -> String {
        func y(_ p: [MetinParcasi]) -> String { p.filter { !$0.ust }.map(\.metin).joined() }
        return bloklar.map { b -> String in
            switch b {
            case .paragraf(let p), .baslik(_, let p), .alinti(let p): return y(p)
            case .liste(_, let l): return l.map(y).joined(separator: "\n")
            case .cizgi: return "—"
            case .tablo(let bas, let satirlar): return ([bas] + satirlar).map { $0.map(y).joined(separator: " | ") }.joined(separator: "\n")
            }
        }.joined(separator: "\n")
    }
}

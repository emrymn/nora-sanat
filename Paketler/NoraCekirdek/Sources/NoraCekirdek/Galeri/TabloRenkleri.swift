// Kaynak: kullanıcının tasarım tuvali "Başyapıt Sayfası — Bütüncül Tasarım" (2026-11-16; Galeri · Başyapıtlar ve
// 1 · Açılış artboard'ları, `.zemin`): zeminde tablonun İKİ renginden süzme, sol üstte biri (%24 → %6 → 0), sağ altta
// öbürü (%16 → 0). Örnekler: Elçiler rgb(150,60,50) + rgb(60,110,90); Arnolfini rgb(96,128,78) + rgb(150,58,44).
// Sitede bu zemin tek renge (vurgu) indi ve İş 192'de üçte birine düştü; uygulama tasarımdakini kullanır (bilinçli fark,
// kullanıcının isteği 2026-11-22: "renk süzmeleri", yalnız uygulama).
import Foundation

public enum TabloRenkleri {
    /// Sol üstteki (birinci) ve sağ alttaki (ikinci) süzmenin rengi
    public struct Cift: Equatable, Sendable {
        public var birinci: RGBA
        public var ikinci: RGBA
        public init(_ birinci: RGBA, _ ikinci: RGBA) { self.birinci = birinci; self.ikinci = ikinci }
    }

    /// Tablonun küçültülmüş piksellerinden (0…1 RGB) iki baskın renk: 12 ton diliminde (ağırlık renk yoğunluğu) ikisi de
    /// ağır ve birbirinden en az 60° ayrık ikili; ağır olan sol üste. Ayrık ikinci ton yoksa aynı tonun koyusu. Renkler tasarımdaki
    /// açıklık ve doygunluğa getirilir (HSL açıklık 0,40–0,50; doygunluk 0,45–0,65). Neredeyse renksiz tabloda nil.
    public static func cift(pikseller: [(Double, Double, Double)]) -> Cift? {
        let dilim = 12
        var agirlik = [Double](repeating: 0, count: dilim)
        var toplam = [(Double, Double, Double)](repeating: (0, 0, 0), count: dilim)
        for (r, g, b) in pikseller {
            let (h, s, l) = hsl(r, g, b)
            let renk = s * (1 - abs(2 * l - 1))   // renk yoğunluğu (chroma)
            guard renk > 0.06, l > 0.08, l < 0.94 else { continue }
            let i = Int((h / 360 * Double(dilim)).rounded(.down)) % dilim
            agirlik[i] += renk
            toplam[i].0 += r * renk; toplam[i].1 += g * renk; toplam[i].2 += b * renk
        }
        let dolu = agirlik.indices.filter { agirlik[$0] > 0 }
        guard !dolu.isEmpty else { return nil }
        func uzaklik(_ a: Int, _ b: Int) -> Int { let d = abs(a - b) % dilim; return min(d, dilim - d) }
        func ortalama(_ i: Int) -> RGBA {
            RGBA(toplam[i].0 / agirlik[i], toplam[i].1 / agirlik[i], toplam[i].2 / agirlik[i])
        }
        // En iyi ikili: ikisi de ağır ve tonları ayrık (120°'ye kadar uzaklık ödüllenir)
        var enIyi: (Int, Int, Double)?
        for i in dolu { for j in dolu where j > i {
            let p = agirlik[i] * agirlik[j] * Double(min(uzaklik(i, j), 4)) / 4
            if p > (enIyi?.2 ?? 0) { enIyi = (i, j, p) }
        } }
        let a: RGBA, b: RGBA
        if let (i, j, _) = enIyi, uzaklik(i, j) >= 2 {
            let (ilk, ikinci) = agirlik[i] >= agirlik[j] ? (i, j) : (j, i)
            a = yumusat(ortalama(ilk)); b = yumusat(ortalama(ikinci))
        } else {
            let ilk = dolu.max { agirlik[$0] < agirlik[$1] }!
            a = yumusat(ortalama(ilk)); b = koyulas(a)
        }
        return Cift(a, b)
    }

    /// Tasarımdaki tonlara (rgb(150,60,50), (60,95,150), (190,140,60): doygunluk 0,43–0,52, açıklık 0,39–0,49):
    /// HSL doygunluk 0,45–0,65, açıklık 0,40–0,50. Tablonun ortalaması çoğu zaman soluk ve kahveye çeker; koyu zeminde
    /// görünsün diye renk canlandırılır (kullanıcı 2026-11-23: "renk süzmeleri hiç yok").
    static func yumusat(_ c: RGBA) -> RGBA {
        let (h, s, l) = hsl(c.r, c.g, c.b)
        return rgb(h, min(0.65, max(0.45, s)), min(0.5, max(0.4, l)))
    }

    /// Tek renkli tabloda ikinci süzme: aynı ton, biraz koyu ve 30° kaymış
    static func koyulas(_ c: RGBA) -> RGBA {
        let (h, s, l) = hsl(c.r, c.g, c.b)
        return rgb((h + 30).truncatingRemainder(dividingBy: 360), s, max(0.34, l - 0.08))
    }

    static func hsl(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        let l = (mx + mn) / 2
        guard d > 1e-9 else { return (0, 0, l) }
        let s = d / (1 - abs(2 * l - 1))
        var h: Double
        if mx == r { h = ((g - b) / d).truncatingRemainder(dividingBy: 6) } else if mx == g { h = (b - r) / d + 2 } else { h = (r - g) / d + 4 }
        h *= 60
        if h < 0 { h += 360 }
        return (h, min(1, s), l)
    }

    static func rgb(_ h: Double, _ s: Double, _ l: Double) -> RGBA {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        let (r, g, b): (Double, Double, Double)
        switch h {
        case ..<60: (r, g, b) = (c, x, 0)
        case ..<120: (r, g, b) = (x, c, 0)
        case ..<180: (r, g, b) = (0, c, x)
        case ..<240: (r, g, b) = (0, x, c)
        case ..<300: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        return RGBA(r + m, g + m, b + m)
    }
}

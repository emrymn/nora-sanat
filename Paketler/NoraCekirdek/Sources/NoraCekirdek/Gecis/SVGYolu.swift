// Sitenin simgelerini (js/tasarim.js `YOLLAR`) Swift'te çizmek için küçük bir SVG okuyucu (T4).
// Simgeler 24×24'lük `viewBox`'ta çizgi (stroke) olarak çizilir; burada yalnız geometri çıkarılır: `<path d>`, `<rect>`,
// `<circle>`. Yay (A) komutları kübik eğrilere çevrilir; böylece SwiftUI tarafı yalnız git/çizgi/eğri/kapat bilir.
// Kâhin: Testler/kahin/sekme_cubugu.mjs (tarayıcının `getBBox()`'ı ile sınır kutuları).
import Foundation

public struct Nokta: Equatable, Sendable {
    public var x: Double, y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
}

/// Mutlak koordinatlı çizim komutu
public enum YolKomutu: Equatable, Sendable {
    case git(Nokta)
    case cizgi(Nokta)
    case egri(Nokta, Nokta, Nokta)   // kontrol 1, kontrol 2, bitiş
    case kapat
}

public struct SinirKutusu: Equatable, Sendable {
    public var x: Double, y: Double, genislik: Double, yukseklik: Double
    public init(x: Double, y: Double, genislik: Double, yukseklik: Double) {
        self.x = x; self.y = y; self.genislik = genislik; self.yukseklik = yukseklik
    }
}

public enum SVGYolu {
    /// Bir SVG parçasındaki (`<path/>`, `<rect/>`, `<circle/>` dizisi) bütün şekillerin komutları
    public static func komutlar(isaretleme: String) -> [YolKomutu] {
        var sonuc: [YolKomutu] = []
        let desen = try! NSRegularExpression(pattern: #"<(path|rect|circle)\b([^>]*)/?>"#)
        let ns = isaretleme as NSString
        for m in desen.matches(in: isaretleme, range: NSRange(location: 0, length: ns.length)) {
            let ad = ns.substring(with: m.range(at: 1))
            let oz = ozellikler(ns.substring(with: m.range(at: 2)))
            let s = { (k: String) in Double(oz[k] ?? "") ?? 0 }
            switch ad {
            case "path": sonuc += komutlar(d: oz["d"] ?? "")
            case "rect": sonuc += dikdortgen(x: s("x"), y: s("y"), g: s("width"), y2: s("height"), r: s("rx"))
            default: sonuc += daire(cx: s("cx"), cy: s("cy"), r: s("r"))
            }
        }
        return sonuc
    }

    static func ozellikler(_ metin: String) -> [String: String] {
        let desen = try! NSRegularExpression(pattern: #"([a-zA-Z-]+)="([^"]*)""#)
        let ns = metin as NSString
        var o: [String: String] = [:]
        for m in desen.matches(in: metin, range: NSRange(location: 0, length: ns.length)) {
            o[ns.substring(with: m.range(at: 1))] = ns.substring(with: m.range(at: 2))
        }
        return o
    }

    // MARK: Path verisi (d)

    private enum Simge: Equatable { case komut(Character), sayi(Double) }

    private static func simgeler(_ d: String) -> [Simge] {
        var l: [Simge] = []
        let k = Array(d.unicodeScalars)
        var i = 0
        while i < k.count {
            let c = k[i]
            if CharacterSet.letters.contains(c) && c != "e" && c != "E" {
                l.append(.komut(Character(c))); i += 1
            } else if c == "-" || c == "+" || c == "." || CharacterSet.decimalDigits.contains(c) {
                // Sayı: işaret, rakamlar, en çok bir nokta, üs. "1.500-2.800" ve ".5.5" gibi bitişik sayılar ayrılır.
                var j = i
                if k[j] == "-" || k[j] == "+" { j += 1 }
                var nokta = false
                while j < k.count {
                    let x = k[j]
                    if CharacterSet.decimalDigits.contains(x) { j += 1 }
                    else if x == "." && !nokta { nokta = true; j += 1 }
                    else if (x == "e" || x == "E") && j + 1 < k.count {
                        j += 1
                        if k[j] == "-" || k[j] == "+" { j += 1 }
                    } else { break }
                }
                let metin = String(String.UnicodeScalarView(k[i..<j]))
                l.append(.sayi(Double(metin) ?? 0))
                i = j
            } else { i += 1 }   // boşluk, virgül
        }
        return l
    }

    /// `d` özniteliğinin komutları (M L H V C S Q T A Z, büyük/küçük harf)
    public static func komutlar(d: String) -> [YolKomutu] {
        let s = simgeler(d)
        var i = 0
        var sonuc: [YolKomutu] = []
        var p = Nokta(0, 0), bas = Nokta(0, 0)
        var sonKontrol: Nokta?          // S için son kübik kontrol noktası
        var sonQ: Nokta?                // T için son ikinci derece kontrol noktası
        var komut: Character = "M"
        func sayi() -> Double? {
            guard i < s.count, case let .sayi(v) = s[i] else { return nil }
            i += 1
            return v
        }
        func bayrak() -> Bool? {
            // Yay bayrakları tek rakamdır ("0 01" gibi bitişik de yazılabilir; buradaki yollarda boşluklu)
            sayi().map { $0 != 0 }
        }
        while i < s.count {
            if case let .komut(c) = s[i] { komut = c; i += 1 }
            let goreli = komut.isLowercase
            let ox = goreli ? p.x : 0, oy = goreli ? p.y : 0
            switch komut.uppercased() {
            case "Z":
                sonuc.append(.kapat); p = bas; sonKontrol = nil; sonQ = nil
                // Z'den sonra sayı gelmez; bir sonraki simge komut olmalı
                if i < s.count, case .sayi = s[i] { i += 1 }
                continue
            case "M":
                guard let x = sayi(), let y = sayi() else { return sonuc }
                p = Nokta(ox + x, oy + y); bas = p
                sonuc.append(.git(p))
                komut = goreli ? "l" : "L"   // ardından gelen çiftler çizgidir
                sonKontrol = nil; sonQ = nil
            case "L":
                guard let x = sayi(), let y = sayi() else { return sonuc }
                p = Nokta(ox + x, oy + y); sonuc.append(.cizgi(p)); sonKontrol = nil; sonQ = nil
            case "H":
                guard let x = sayi() else { return sonuc }
                p = Nokta(ox + x, p.y); sonuc.append(.cizgi(p)); sonKontrol = nil; sonQ = nil
            case "V":
                guard let y = sayi() else { return sonuc }
                p = Nokta(p.x, (goreli ? p.y : 0) + y); sonuc.append(.cizgi(p)); sonKontrol = nil; sonQ = nil
            case "C":
                guard let a = sayi(), let b = sayi(), let c = sayi(), let d = sayi(), let e = sayi(), let f = sayi()
                else { return sonuc }
                let k1 = Nokta(ox + a, oy + b), k2 = Nokta(ox + c, oy + d), son = Nokta(ox + e, oy + f)
                sonuc.append(.egri(k1, k2, son)); p = son; sonKontrol = k2; sonQ = nil
            case "S":
                guard let c = sayi(), let d = sayi(), let e = sayi(), let f = sayi() else { return sonuc }
                let k1 = sonKontrol.map { Nokta(2 * p.x - $0.x, 2 * p.y - $0.y) } ?? p
                let k2 = Nokta(ox + c, oy + d), son = Nokta(ox + e, oy + f)
                sonuc.append(.egri(k1, k2, son)); p = son; sonKontrol = k2; sonQ = nil
            case "Q", "T":
                var q: Nokta
                if komut.uppercased() == "Q" {
                    guard let a = sayi(), let b = sayi() else { return sonuc }
                    q = Nokta(ox + a, oy + b)
                } else {
                    q = sonQ.map { Nokta(2 * p.x - $0.x, 2 * p.y - $0.y) } ?? p
                }
                guard let e = sayi(), let f = sayi() else { return sonuc }
                let son = Nokta(ox + e, oy + f)
                let k1 = Nokta(p.x + 2 / 3 * (q.x - p.x), p.y + 2 / 3 * (q.y - p.y))
                let k2 = Nokta(son.x + 2 / 3 * (q.x - son.x), son.y + 2 / 3 * (q.y - son.y))
                sonuc.append(.egri(k1, k2, son)); p = son; sonQ = q; sonKontrol = nil
            case "A":
                guard let rx = sayi(), let ry = sayi(), let aci = sayi(), let buyuk = bayrak(), let yon = bayrak(),
                      let x = sayi(), let y = sayi() else { return sonuc }
                let son = Nokta(ox + x, oy + y)
                sonuc += yay(p, son, rx: rx, ry: ry, aci: aci, buyuk: buyuk, yon: yon)
                p = son; sonKontrol = nil; sonQ = nil
            default:
                i += 1   // bilinmeyen komut: atla
            }
        }
        return sonuc
    }

    // MARK: Şekiller

    /// `<rect>`; rx varsa köşeler yuvarlak (ry = rx)
    static func dikdortgen(x: Double, y: Double, g: Double, y2 h: Double, r: Double) -> [YolKomutu] {
        let r = min(r, g / 2, h / 2)
        guard r > 0 else {
            return [.git(Nokta(x, y)), .cizgi(Nokta(x + g, y)), .cizgi(Nokta(x + g, y + h)), .cizgi(Nokta(x, y + h)), .kapat]
        }
        var l: [YolKomutu] = [.git(Nokta(x + r, y)), .cizgi(Nokta(x + g - r, y))]
        l += yay(Nokta(x + g - r, y), Nokta(x + g, y + r), rx: r, ry: r, aci: 0, buyuk: false, yon: true)
        l.append(.cizgi(Nokta(x + g, y + h - r)))
        l += yay(Nokta(x + g, y + h - r), Nokta(x + g - r, y + h), rx: r, ry: r, aci: 0, buyuk: false, yon: true)
        l.append(.cizgi(Nokta(x + r, y + h)))
        l += yay(Nokta(x + r, y + h), Nokta(x, y + h - r), rx: r, ry: r, aci: 0, buyuk: false, yon: true)
        l.append(.cizgi(Nokta(x, y + r)))
        l += yay(Nokta(x, y + r), Nokta(x + r, y), rx: r, ry: r, aci: 0, buyuk: false, yon: true)
        l.append(.kapat)
        return l
    }

    static func daire(cx: Double, cy: Double, r: Double) -> [YolKomutu] {
        var l: [YolKomutu] = [.git(Nokta(cx + r, cy))]
        l += yay(Nokta(cx + r, cy), Nokta(cx - r, cy), rx: r, ry: r, aci: 0, buyuk: false, yon: true)
        l += yay(Nokta(cx - r, cy), Nokta(cx + r, cy), rx: r, ry: r, aci: 0, buyuk: false, yon: true)
        l.append(.kapat)
        return l
    }

    /// SVG yayı → kübik eğriler (SVG 1.1 F.6.5: uç noktadan merkeze çevirme; her ≤ 90° parça bir eğri)
    static func yay(_ p0: Nokta, _ p1: Nokta, rx rx0: Double, ry ry0: Double, aci: Double, buyuk: Bool, yon: Bool)
        -> [YolKomutu] {
        if p0 == p1 { return [] }
        var rx = abs(rx0), ry = abs(ry0)
        if rx == 0 || ry == 0 { return [.cizgi(p1)] }
        let fi = aci * .pi / 180, c = cos(fi), s = sin(fi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = c * dx + s * dy, y1 = -s * dx + c * dy
        let l = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if l > 1 { rx *= l.squareRoot(); ry *= l.squareRoot() }
        let pay = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let payda = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var k = (max(0, pay) / payda).squareRoot()
        if buyuk == yon { k = -k }
        let cxp = k * rx * y1 / ry, cyp = -k * ry * x1 / rx
        let cx = c * cxp - s * cyp + (p0.x + p1.x) / 2
        let cy = s * cxp + c * cyp + (p0.y + p1.y) / 2
        func aciAl(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        }
        let t1 = aciAl(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry)
        var dt = aciAl((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry)
        if !yon && dt > 0 { dt -= 2 * .pi } else if yon && dt < 0 { dt += 2 * .pi }
        let parca = max(1, Int((abs(dt) / (.pi / 2) - 1e-9).rounded(.up)))
        let adim = dt / Double(parca)
        let alfa = 4.0 / 3.0 * tan(adim / 4)
        func nokta(_ t: Double) -> (Nokta, Nokta) {   // nokta ve türev (birim çember → elips)
            let ex = rx * cos(t), ey = ry * sin(t)
            let tx = -rx * sin(t), ty = ry * cos(t)
            return (Nokta(cx + c * ex - s * ey, cy + s * ex + c * ey), Nokta(c * tx - s * ty, s * tx + c * ty))
        }
        var sonuc: [YolKomutu] = []
        var t = t1
        for n in 0..<parca {
            let (a, da) = nokta(t)
            let (b, db) = nokta(t + adim)
            let son = n == parca - 1 ? p1 : b
            sonuc.append(.egri(Nokta(a.x + alfa * da.x, a.y + alfa * da.y), Nokta(b.x - alfa * db.x, b.y - alfa * db.y), son))
            t += adim
        }
        return sonuc
    }

    // MARK: Sınır kutusu

    /// Geometrinin sıkı sınır kutusu (tarayıcının `getBBox()`'ı gibi; çizgi kalınlığı hariç)
    public static func sinirKutusu(_ komutlar: [YolKomutu]) -> SinirKutusu? {
        var minX = Double.infinity, minY = Double.infinity, maxX = -Double.infinity, maxY = -Double.infinity
        func ekle(_ p: Nokta) {
            minX = min(minX, p.x); minY = min(minY, p.y); maxX = max(maxX, p.x); maxY = max(maxY, p.y)
        }
        var p = Nokta(0, 0), bas = Nokta(0, 0)
        for k in komutlar {
            switch k {
            case let .git(n): p = n; bas = n; ekle(n)
            case let .cizgi(n): p = n; ekle(n)
            case .kapat: p = bas
            case let .egri(a, b, n):
                ekle(n)
                // Kübik eğrinin türevinin kökleri (her eksen için ayrı)
                for (p0, p1, p2, p3) in [(p.x, a.x, b.x, n.x), (p.y, a.y, b.y, n.y)] {
                    let qa = -p0 + 3 * p1 - 3 * p2 + p3, qb = 2 * (p0 - 2 * p1 + p2), qc = p1 - p0
                    var kokler: [Double] = []
                    if abs(qa) < 1e-12 {
                        if abs(qb) > 1e-12 { kokler = [-qc / qb] }
                    } else {
                        let del = qb * qb - 4 * qa * qc
                        if del >= 0 { kokler = [(-qb + del.squareRoot()) / (2 * qa), (-qb - del.squareRoot()) / (2 * qa)] }
                    }
                    for t in kokler where t > 0 && t < 1 {
                        let u = 1 - t
                        let x = u * u * u * p.x + 3 * u * u * t * a.x + 3 * u * t * t * b.x + t * t * t * n.x
                        let y = u * u * u * p.y + 3 * u * u * t * a.y + 3 * u * t * t * b.y + t * t * t * n.y
                        ekle(Nokta(x, y))
                    }
                }
                p = n
            }
        }
        guard minX.isFinite else { return nil }
        return SinirKutusu(x: minX, y: minY, genislik: maxX - minX, yukseklik: maxY - minY)
    }
}

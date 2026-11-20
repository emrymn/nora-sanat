// Kaynak: sanat-atlasi js/seviye.js, js/birlesme.js seviyeleriBirlestir @ a866b86 (site 1.90.3)
import Foundation

/// Bir dönemin (akımın) seviye kaydı: `{ s: 0–2, son: [1, 0, 2, …] }` (son cevaplar, en yeni sonda; 2 = "Bilmiyorum")
public struct SeviyeKaydi: Equatable, Sendable, Codable {
    public var s: Int
    public var son: [Int]
    public init(s: Int = 0, son: [Int] = []) { self.s = s; self.son = son }

    public var json: JSONDeger { .nesne([("s", .sayi(s)), ("son", .dizi(son.map { .sayi($0) }))]) }
}

/// Seviyeler dönem başına: Kolay → Orta → Zor; son cevaplarda %80 başarı olmadan geçilmez (js/seviye.js)
public enum Seviye {
    public struct Tanim: Equatable, Sendable { public let no: Int; public let anahtar, ad, aciklama: String }
    public static let seviyeler = [
        Tanim(no: 0, anahtar: "kolay", ad: "Kolay", aciklama: "Tanınmış, tipik eserler; şıklar uzak dönemlerden"),
        Tanim(no: 1, anahtar: "orta", ad: "Orta", aciklama: "Her türden eser; şıklar komşu akımlardan"),
        Tanim(no: 2, anahtar: "zor", ad: "Zor", aciklama: "Az bilinen eserler; şıklar aynı akımdan"),
    ]
    public static let gecisOrani = 0.8
    public static let pencere = 10
    public static let enAz = 5
    public static let bilmiyorum = 2

    public enum Cevap: Sendable { case dogru, yanlis, bilmiyorum }

    public static func bul(_ no: Int) -> Tanim { seviyeler.first { $0.no == no } ?? seviyeler[0] }

    /// `seviyeKaydi(ilerleme, akim)`
    public static func kayit(_ seviyeler: [String: SeviyeKaydi], _ akim: String) -> SeviyeKaydi { seviyeler[akim] ?? SeviyeKaydi() }

    /// `oran(son)`: "Bilmiyorum" yarım ağırlıkla yanlış
    public static func oran(_ son: [Int]) -> Double {
        let payda = son.reduce(0.0) { $0 + ($1 == bilmiyorum ? 0.5 : 1) }
        return payda > 0 ? Double(son.filter { $0 == 1 }.count) / payda : 0
    }

    /// `ustaMi`
    public static func usta(_ k: SeviyeKaydi) -> Bool { k.s == 2 && k.son.count >= enAz && oran(k.son) >= gecisOrani }

    /// `seviyeCevapla(kayit, dogru)`: yeni kayıt ve seviye atlandı mı
    public static func cevapla(_ k: SeviyeKaydi, _ c: Cevap) -> (kayit: SeviyeKaydi, gecti: Bool) {
        let son = Array((k.son + [c == .bilmiyorum ? bilmiyorum : c == .dogru ? 1 : 0]).suffix(pencere))
        if k.s < 2 && son.count >= enAz && oran(son) >= gecisOrani { return (SeviyeKaydi(s: k.s + 1, son: []), true) }
        return (SeviyeKaydi(s: k.s, son: son), false)
    }

    /// `seviyeIsle`: cevabı dönemin kaydına işler
    @discardableResult
    public static func isle(_ seviyeler: inout [String: SeviyeKaydi], akim: String, _ c: Cevap) -> (once: Int, sonra: Int, gecti: Bool) {
        let once = kayit(seviyeler, akim)
        let (y, gecti) = cevapla(once, c)
        seviyeler[akim] = y
        return (once.s, y.s, gecti)
    }

    static func yuzde(_ x: Double) -> Int { Int((x * 100).rounded()) }

    /// `seviyeDurumu`: "Kolay · son 6 cevapta 5 doğru · Orta için %80 (en az 5 cevap)"
    public static func durum(_ k: SeviyeKaydi) -> String {
        let sv = bul(k.s)
        let n = k.son.count, d = k.son.filter { $0 == 1 }.count
        let sayi = n > 0 ? "son \(n) cevapta \(d) doğru" : "henüz cevap yok"
        guard let sonraki = seviyeler.first(where: { $0.no == k.s + 1 }) else {
            return "\(sv.ad) · \(sayi)\(usta(k) ? " · ustalaştın" : "")"
        }
        let kalan = max(0, enAz - n)
        return "\(sv.ad) · \(sayi) · \(sonraki.ad) için %\(yuzde(gecisOrani))\(kalan > 0 ? " (en az \(kalan) cevap daha)" : "")"
    }

    /// `seviyeKisa`: "Kolay · 3/5", "Orta · 4/7 doğru", "Zor · usta"
    public static func kisa(_ k: SeviyeKaydi) -> String {
        let sv = bul(k.s)
        if usta(k) { return "\(sv.ad) · usta" }
        let n = k.son.count, d = k.son.filter { $0 == 1 }.count
        return n < enAz ? "\(sv.ad) · \(n)/\(enAz)" : "\(sv.ad) · \(d)/\(n) doğru"
    }

    /// `eserSeviyesi`: zorluk diliminin beklediği değer
    public static func eserSeviyesi(_ s: Int) -> Int { s == 0 ? 0 : s == 1 ? 2 : 5 }

    /// `kartSeviyesi(kayit, secili)`
    public static func kartSeviyesi(_ k: SeviyeKaydi, secili: Int?) -> Int { secili.map { max(0, min($0, k.s)) } ?? k.s }

    /// `pencereyeYazilirMi`
    public static func pencereyeYazilir(_ k: SeviyeKaydi, kartSeviyesi: Int?) -> Bool { (kartSeviyesi ?? k.s) >= k.s }

    /// `seviyelerDogrula`
    public static func dogrula(_ v: JSONDeger?) -> [String: SeviyeKaydi] {
        guard let n = v?.nesne else { return [:] }
        var sonuc: [String: SeviyeKaydi] = [:]
        for (id, k) in n.ciftler {
            guard let s = k["s"]?.sayi, [0.0, 1, 2].contains(s), let son = k["son"]?.dizi else { continue }
            let l = son.compactMap { x -> Int? in
                guard let d = x.sayi, [0.0, 1, 2].contains(d) else { return nil }
                return Int(d)
            }
            sonuc[id] = SeviyeKaydi(s: Int(s), son: Array(l.suffix(pencere)))
        }
        return sonuc
    }

    /// `seviyeleriBirlestir`: birleşen akımın kaydı hedefinkine katılır
    public static func birlestir(_ sv: [String: SeviyeKaydi]) -> [String: SeviyeKaydi] {
        var sv = sv
        for (kaynak, hedef) in Birlesme.akimlar {
            guard let k = sv[kaynak] else { continue }
            if let h = sv[hedef] {
                if k.s > h.s { sv[hedef] = k } else if k.s == h.s { sv[hedef] = SeviyeKaydi(s: h.s, son: Array((k.son + h.son).suffix(pencere))) }
            } else { sv[hedef] = k }
            sv[kaynak] = nil
        }
        return sv
    }
}

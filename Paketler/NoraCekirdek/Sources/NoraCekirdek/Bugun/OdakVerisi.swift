// Kaynak: sanat-atlasi js/gorsel.js (odaklariAyarla, elleOdaklariAyarla, cihazdakiElleOdaklar, elleOdakKoy,
// yuruyusOdaklariAyarla, yuruyusEki, adlaOdak / odakAdla, gorselOdakNoktasi), js/ekranlar/ortak.js (odaklariYukle)
// @ a866b86
import Foundation

/// Z2c-3: tabloların odak noktaları (yüzde [x, y]) ve Bugün yürüyüşünün açılış ayarları, sitenin üç veri dosyasından ve
/// bu cihazda elle işaretlenenlerden. Öncelik (sitedeki gibi): cihazdaki elle → depodaki elle
/// (`data/gorsel_odak_elle.json`) → yürüyüş odağı (`data/yuruyus_odak.json`; yalnız `adlaOdak`) → otomatik yüz odağı
/// (`data/gorsel_odak.json`).
public struct OdakVerisi: Sendable {
    public var otomatik: [String: [Double]] = [:]
    public var elleDosya: [String: [Double]] = [:]
    public var yuruyusOdak: [String: [Double]] = [:]
    public var yuruyusYakin: [String: JSONDeger] = [:]
    public var yuruyusKirp: [String: JSONDeger] = [:]
    /// Bu cihazda elle işaretlenenler (sitede localStorage `sanat-atlasi:odak-elle`)
    public var cihaz: [String: [Double]] = [:]

    public static let dosyalar = ["gorsel_odak.json", "gorsel_odak_elle.json", "yuruyus_odak.json"]

    public init() {}

    /// `veriler`: dosya adı → içerik (eksik ya da bozuk dosya boş sayılır)
    public init(veriler: [String: Data], cihaz: [String: [Double]] = [:]) {
        func coz(_ ad: String) -> JSONDeger? { veriler[ad].flatMap { try? JSONDeger.coz($0) } }
        func noktalar(_ j: JSONDeger?) -> [String: [Double]] {
            var s: [String: [Double]] = [:]
            for c in j?.nesne?.ciftler ?? [] { if let d = c.deger.dizi { s[c.anahtar] = d.compactMap(\.sayi) } }
            return s
        }
        func nesne(_ j: JSONDeger?) -> [String: JSONDeger] {
            var s: [String: JSONDeger] = [:]
            for c in j?.nesne?.ciftler ?? [] { s[c.anahtar] = c.deger }
            return s
        }
        otomatik = noktalar(coz("gorsel_odak.json")?["odak"])
        elleDosya = noktalar(coz("gorsel_odak_elle.json")?["odak"])
        let y = coz("yuruyus_odak.json")
        yuruyusOdak = noktalar(y?["odak"])
        yuruyusYakin = nesne(y?["yakin"])
        yuruyusKirp = nesne(y?["kirp"])
        self.cihaz = cihaz
    }

    /// `gecerliOdak`: iki sayı, 0–100
    public static func gecerli(_ o: [Double]?) -> Bool {
        guard let o, o.count == 2 else { return false }
        return o.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 100 }
    }

    /// `adlaOdak(ad)`: Bugün yürüyüşünün açılış odağı
    public func adlaOdak(_ ad: String) -> [Double]? {
        guard !ad.isEmpty else { return nil }
        if let e = cihaz[ad] ?? elleDosya[ad], Self.gecerli(e) { return e }
        if Self.gecerli(yuruyusOdak[ad]) { return yuruyusOdak[ad] }
        return Self.gecerli(otomatik[ad]) ? otomatik[ad] : nil
    }

    /// `gorselOdakNoktasi(g)`: kırpılan görselin odağı (yürüyüş odağı sayılmaz)
    public func odak(_ ad: String) -> [Double]? {
        guard !ad.isEmpty else { return nil }
        if let e = cihaz[ad] ?? elleDosya[ad], Self.gecerli(e) { return e }
        return Self.gecerli(otomatik[ad]) ? otomatik[ad] : nil
    }

    /// `yuruyusEki(ad)`: yakınlık (1–2,2) ve kırpım ([x, y, w, h], 0–1; w ve h > 0,3) ya da nil
    public func yuruyusEki(_ ad: String) -> (yakin: Double, kirp: [Double]?) {
        // JS Number(x): sayı ya da sayı metni
        let y: Double? = {
            switch yuruyusYakin[ad] {
            case .sayi(let d)?: return d
            case .metin(let m)?: return Double(m.trimmingCharacters(in: .whitespaces))
            case .mantik(let b)?: return b ? 1 : 0
            default: return nil
            }
        }()
        let k = yuruyusKirp[ad]?.dizi?.compactMap(\.sayi)
        let gecerliKirp = k.map { $0.count == 4 && yuruyusKirp[ad]?.dizi?.count == 4 && $0.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 1 } && $0[2] > 0.3 && $0[3] > 0.3 } ?? false
        let yakin = y.map { $0.isFinite ? min(2.2, max(1, $0)) : 1 } ?? 1
        return (yakin, gecerliKirp ? k : nil)
    }

    /// `elleOdakKoy`'un kuralı: yüzdeler 0–100'e sıkışır ve yuvarlanır (`Math.round`)
    public static func elleOdak(_ o: [Double]) -> [Double] {
        o.map { (min(100, max(0, $0.isFinite ? $0 : 0)) + 0.5).rounded(.down) }
    }
}

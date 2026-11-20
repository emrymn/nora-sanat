import Foundation

/// Sitenin ilerlemesinden (localStorage) çıkarılan tekrar takvimi:
/// `gunler[i]` = `bugun`'den i gün sonrasına kadar (o gün dahil) vadesi gelmiş sanatçı sayısı
/// (sitenin `vadeSayisi`'yle aynı sayım; arada çalışılmazsa o gün "tekrar bekliyor" yazacak sayı).
public struct TekrarTakvimi: Codable, Equatable, Sendable {
    public var bugun: String
    public var gunler: [Int]
    /// Sitede Ayarlar → "Simge rozeti" açık mı
    public var rozet: Bool

    public init(bugun: String, gunler: [Int], rozet: Bool) {
        self.bugun = bugun; self.gunler = gunler; self.rozet = rozet
    }

    /// Betikten gelen ileti: { bugun: "YYYY-MM-DD", gunler: [Int], rozet: Bool }
    public init?(ileti: Any) {
        guard let s = ileti as? [String: Any], let b = s["bugun"] as? String, GunTarihi.ayir(b) != nil,
              let g = s["gunler"] as? [Any] else { return nil }
        let sayilar = g.compactMap { ($0 as? NSNumber)?.intValue ?? ($0 as? Int) }
        guard sayilar.count == g.count, sayilar.allSatisfy({ $0 >= 0 }) else { return nil }
        self.init(bugun: b, gunler: sayilar, rozet: (s["rozet"] as? Bool) ?? ((s["rozet"] as? NSNumber)?.boolValue ?? false))
    }
}

public struct Hatirlatma: Equatable, Sendable {
    public var kimlik: String
    public var gun: String
    public var saat: Int
    public var dakika: Int
    public var sayi: Int
    public var baslik: String
    public var govde: String
}

public enum TekrarPlani {
    public static let onek = "tekrar-"
    public static let enCokGun = 14

    /// Önümüzdeki günlerin hatırlatmaları. `simdiGun`/`simdiDakika`: cihazın şimdiki yerel günü ve gece yarısından beri dakika.
    /// Saati geçmiş ya da tekrar beklemeyen günler atlanır.
    public static func plan(_ t: TekrarTakvimi, saat: Int, dakika: Int,
                            simdiGun: String, simdiDakika: Int) -> [Hatirlatma] {
        guard let bugunNo = GunTarihi.gunNo(simdiGun) else { return [] }
        let hedef = saat * 60 + dakika
        var sonuc: [Hatirlatma] = []
        for (i, n) in t.gunler.prefix(enCokGun).enumerated() where n > 0 {
            let gun = GunTarihi.ekle(t.bugun, i)
            guard let no = GunTarihi.gunNo(gun) else { continue }
            if no < bugunNo || (no == bugunNo && hedef <= simdiDakika) { continue }
            sonuc.append(Hatirlatma(kimlik: onek + gun, gun: gun, saat: saat, dakika: dakika, sayi: n,
                                    baslik: "Tekrar zamanı",
                                    govde: "Bugün \(n) sanatçı tekrarını bekliyor."))
        }
        return sonuc
    }
}

import Foundation

/// Sanat Atlası'nın "günün sanatçısı" seçiminin birebir kopyası (sanat-atlasi: js/gunun.js `gununSanatcisi`).
/// Aynı havuz ve aynı günle sitenin Bugün ekranındaki ressamı verir. Site bu kuralı değiştirirse burası da değişmeli;
/// testler (GununSanatcisiTests) siteden alınmış örnek günlerle bunu denetler.
public enum GununSanatcisi {
    public static let tekrarYokGun = 30
    public static let baslangic = "2026-01-01"

    static func karistir32(_ n: Int) -> UInt32 {
        var x = UInt32(truncatingIfNeeded: Int64(n) + 0x9e37_79b9)
        x = (x ^ (x >> 16)) &* 0x85eb_ca6b
        x = (x ^ (x >> 13)) &* 0xc2b2_ae35
        return x ^ (x >> 16)
    }

    /// havuz: sanatçı kimlikleri (sırası önemsiz). tarih: "YYYY-MM-DD"
    public static func sec(havuz: [String], tarih: String) -> String? {
        // JS'teki sort(): UTF-16 kod birimi sırası
        let liste = Array(Set(havuz)).sorted { $0.utf16.lexicographicallyPrecedes($1.utf16) }
        guard !liste.isEmpty else { return nil }
        let n = max(0, (GunTarihi.gunNo(tarih) ?? 0) - (GunTarihi.gunNo(baslangic) ?? 0))
        let pencere = min(tekrarYokGun, liste.count - 1)
        var gecmis: [String] = []
        gecmis.reserveCapacity(n + 1)
        var secilen: String?
        for gun in 0...n {
            let yasak = pencere > 0 ? Set(gecmis.suffix(pencere)) : []
            let adaylar = liste.filter { !yasak.contains($0) }
            let s = adaylar[Int(karistir32(gun) % UInt32(adaylar.count))]
            secilen = s
            gecmis.append(s)
        }
        return secilen
    }
}

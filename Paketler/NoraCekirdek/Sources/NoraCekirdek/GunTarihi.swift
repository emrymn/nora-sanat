import Foundation

/// Sanat Atlası'nın gün dizgeleri ("YYYY-MM-DD", yerel gün) üzerinde saat diliminden bağımsız hesap.
public enum GunTarihi {

    /// "2026-11-20" → (2026, 11, 20); geçersizse nil
    public static func ayir(_ t: String) -> (yil: Int, ay: Int, gun: Int)? {
        let p = t.split(separator: "-")
        guard p.count == 3, let y = Int(p[0]), let a = Int(p[1]), let g = Int(p[2]),
              (1...12).contains(a), (1...31).contains(g) else { return nil }
        return (y, a, g)
    }

    public static func yaz(_ y: Int, _ a: Int, _ g: Int) -> String {
        func iki(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
        return "\(y)-\(iki(a))-\(iki(g))"
    }

    /// Bir tarihin yerel günü (sitenin `bugunStr()`'u ile aynı: cihazın saat dilimi)
    public static func gun(_ tarih: Date, takvim: Calendar = .current) -> String {
        let c = takvim.dateComponents([.year, .month, .day], from: tarih)
        return yaz(c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    /// 1970-01-01'den bu yana gün sayısı (proleptik Gregoryen)
    public static func gunNo(_ t: String) -> Int? {
        guard let (y0, a, g) = ayir(t) else { return nil }
        let y = a <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (a + (a > 2 ? -3 : 9)) + 2) / 5 + g - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }

    public static func gunNodan(_ z0: Int) -> String {
        let z = z0 + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let g = doy - (153 * mp + 2) / 5 + 1
        let a = mp < 10 ? mp + 3 : mp - 9
        return yaz(yoe + era * 400 + (a <= 2 ? 1 : 0), a, g)
    }

    /// Sitenin `gunEkle(tarih, n)`'i
    public static func ekle(_ t: String, _ n: Int) -> String {
        guard let z = gunNo(t) else { return t }
        return gunNodan(z + n)
    }
}

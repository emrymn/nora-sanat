// Kaynak: sanat-atlasi js/leitner.js @ a866b86 (site 1.90.3)
import Foundation

/// Bir sorunun (sanatçı, akım, bölüm, konu) Leitner skoru. Bilinmeyen alanlar `ham`'da korunur.
public struct Skor: Equatable, Sendable {
    /// 0–5
    public var kutu: Int
    /// Sonraki tekrar günü "YYYY-MM-DD"
    public var sonraki: String?
    public var dogru: Int
    public var yanlis: Int
    /// Son görüldüğü gün
    public var son: String?
    var ham: SiraliNesne = .bos

    public init(kutu: Int = 0, sonraki: String? = nil, dogru: Int = 0, yanlis: Int = 0, son: String? = nil) {
        self.kutu = kutu; self.sonraki = sonraki; self.dogru = dogru; self.yanlis = yanlis; self.son = son
    }

    public init?(json j: JSONDeger?) {
        guard let n = j?.nesne else { return nil }
        func sayi(_ a: String) -> Int { n[a]?.sayi.map { $0.isFinite ? Int($0.rounded(.down)) : 0 } ?? 0 }
        kutu = sayi("kutu"); dogru = sayi("dogru"); yanlis = sayi("yanlis")
        sonraki = n["sonraki"]?.metin
        son = n["son"]?.metin
        ham = n
    }

    public var json: JSONDeger {
        // `{ ...yeniSkor(), ...skor }` sırası
        var n = ham.count == 0 ? SiraliNesne([("kutu", .bos), ("sonraki", .bos), ("dogru", .bos), ("yanlis", .bos), ("son", .bos)]) : ham
        n = n.ayarlandi("kutu", .sayi(kutu)).ayarlandi("sonraki", .metinYaDaBos(sonraki))
            .ayarlandi("dogru", .sayi(dogru)).ayarlandi("yanlis", .sayi(yanlis)).ayarlandi("son", .metinYaDaBos(son))
        return .nesne(n)
    }

    public static func == (a: Skor, b: Skor) -> Bool {
        a.kutu == b.kutu && a.sonraki == b.sonraki && a.dogru == b.dogru && a.yanlis == b.yanlis && a.son == b.son
    }
}

/// Leitner kutuları 0–5; aralıklar gün cinsinden, kutu 0 = aynı oturum (js/leitner.js)
public enum Leitner {
    public static let araliklar = [0, 1, 3, 7, 14, 30]
    public static let gunlukYeniSiniri = 8

    /// `gorulduMu`
    public static func goruldu(_ s: Skor?) -> Bool { !(s?.son ?? "").isEmpty }

    /// `vadesiGeldiMi`
    public static func vadesiGeldi(_ s: Skor?, _ bugun: String) -> Bool {
        guard goruldu(s), let t = s?.sonraki, !t.isEmpty else { return false }
        return t <= bugun
    }

    /// `zayifMi`
    public static func zayif(_ s: Skor?) -> Bool {
        guard let s, goruldu(s) else { return false }
        let toplam = s.dogru + s.yanlis
        return s.kutu <= 1 || (toplam >= 2 && Double(s.dogru) / Double(toplam) < 0.6)
    }

    /// `cevapla(skor, dogruMu, bugun)`: yanlış → kutu 0, bugün tekrar; doğru → vadesi gelmiş ya da yeni kartta kutu+1
    /// ve aralık kadar sonraya. Vadesi gelmemiş kartta doğru cevap kutuyu ilerletmez.
    public static func cevapla(_ skor: Skor?, dogru: Bool, bugun: String) -> Skor {
        var s = skor ?? Skor()
        let zamaninda = !goruldu(s) || (s.sonraki ?? "").isEmpty || s.sonraki! <= bugun
        if !dogru {
            s.kutu = 0
            s.sonraki = bugun
            s.yanlis += 1
        } else {
            s.dogru += 1
            if zamaninda {
                s.kutu = min(araliklar.count - 1, s.kutu + 1)
                s.sonraki = GunTarihi.ekle(bugun, araliklar[max(0, s.kutu)])
            }
        }
        s.son = bugun
        return s
    }

    /// `tekrarAraligi(rng)`: yanlış cevaptan sonra kaç kart sonra tekrar gelsin (3–5); `r` 0..<1
    public static func tekrarAraligi(_ r: Double) -> Int { 3 + Int((r * 3).rounded(.down)) }

    /// Gün dizgesinin haftanın günü (pazartesi = 0)
    static func haftaGunu(_ t: String) -> Int {
        let n = GunTarihi.gunNo(t) ?? 0
        let pazar0 = ((n + 4) % 7 + 7) % 7   // 1970-01-01 perşembe
        return (pazar0 + 6) % 7
    }
}

// Kaynak: sanat-atlasi js/gecmis.js @ a866b86 (site 1.90.3)
import Foundation

/// Bir günün çalışma kaydı: `ilerleme.gecmis["2026-10-22"] = { kart, dogru, akimlar: { Barok: 3 } }`
public struct GunKaydi: Equatable, Sendable {
    public var kart: Int
    public var dogru: Int
    public var akimlar: [String: Int]
    var ham: SiraliNesne = .bos

    public init(kart: Int = 0, dogru: Int = 0, akimlar: [String: Int] = [:]) {
        self.kart = kart; self.dogru = dogru; self.akimlar = akimlar
    }

    init?(json j: JSONDeger?) {
        guard let n = j?.nesne else { return nil }
        kart = n["kart"]?.tamSayi ?? 0
        dogru = n["dogru"]?.tamSayi ?? 0
        var a: [String: Int] = [:]
        for (ad, v) in n["akimlar"]?.nesne?.ciftler ?? [] { if let x = v.tamSayi { a[ad] = x } }
        akimlar = a
        ham = n
    }

    public var json: JSONDeger {
        let eskiA = ham["akimlar"]?.nesne ?? .bos
        let a = eskiA.yerine(akimlar.mapValues { .sayi($0) })
        let temel = ham.count == 0 ? SiraliNesne([("kart", .bos), ("dogru", .bos), ("akimlar", .bos)]) : ham
        return .nesne(temel.ayarlandi("kart", .sayi(kart)).ayarlandi("dogru", .sayi(dogru)).ayarlandi("akimlar", .nesne(a)))
    }

    public static func == (a: GunKaydi, b: GunKaydi) -> Bool { a.kart == b.kart && a.dogru == b.dogru && a.akimlar == b.akimlar }
}

/// Takvimdeki bir gün (`takvim`)
public struct TakvimGunu: Equatable, Sendable, Codable {
    public var tarih: String
    public var kart: Int
    public var dogru: Int
    public var akim: String?
    public var gelecek: Bool
}

/// Haftalık doğru oranı (`haftalikOran`)
public struct HaftaOrani: Equatable, Sendable, Codable {
    public var bas: String
    public var kart: Int
    public var dogru: Int
    public var oran: Double?
}

/// Çalışma geçmişi: günlük kart kaydı, takvim, seri, haftalık doğru oranı ve gelecek yük (js/gecmis.js)
public enum Gecmis {
    static func tarihMi(_ t: String) -> Bool { t.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil }

    /// `gecmisDogrula`: geçersiz günler atılır, birleşen akımlar toplanır
    public static func dogrula(_ g: JSONDeger?) -> [String: GunKaydi] {
        guard let n = g?.nesne else { return [:] }
        var sonuc: [String: GunKaydi] = [:]
        for (tarih, k) in n.ciftler {
            guard tarihMi(tarih), k.nesne != nil, let kart = k["kart"]?.tamSayi, kart >= 0,
                  let dogru = k["dogru"]?.tamSayi, dogru >= 0 else { continue }
            var akimlar: [String: Int] = [:]
            for (ad, v) in k["akimlar"]?.nesne?.ciftler ?? [] {
                if let x = v.tamSayi, x > 0 { akimlar[Birlesme.akimAdi(ad), default: 0] += x }
            }
            sonuc[tarih] = GunKaydi(kart: kart, dogru: min(dogru, kart), akimlar: akimlar)
        }
        return sonuc
    }

    /// `gecmisEkle`: biten bir kartı o günün kaydına yazar
    @discardableResult
    public static func ekle(_ gecmis: inout [String: GunKaydi], tarih: String, dogru: Bool, akim: String?) -> GunKaydi {
        var k = gecmis[tarih] ?? GunKaydi()
        k.kart += 1
        if dogru { k.dogru += 1 }
        if let akim, !akim.isEmpty { k.akimlar[akim, default: 0] += 1 }
        gecmis[tarih] = k
        return k
    }

    /// `baskinAkim`: günün en çok çalışılan akımı (eşitlikte Türkçe alfabe sırası)
    public static func baskinAkim(_ k: GunKaydi?) -> String? {
        guard let k, !k.akimlar.isEmpty else { return nil }
        let tr = Locale(identifier: "tr")
        return k.akimlar.sorted { a, b in
            a.value != b.value ? a.value > b.value : a.key.compare(b.key, locale: tr) == .orderedAscending
        }.first?.key
    }

    /// `takvim`: son `hafta` haftanın günleri (pazartesi başlar)
    public static func takvim(_ gecmis: [String: GunKaydi], bugun: String, hafta: Int = 12) -> [TakvimGunu] {
        let bas = GunTarihi.ekle(bugun, -(hafta - 1) * 7 - Leitner.haftaGunu(bugun))
        return (0..<(hafta * 7)).map { i in
            let t = GunTarihi.ekle(bas, i)
            let k = gecmis[t]
            return TakvimGunu(tarih: t, kart: k?.kart ?? 0, dogru: k?.dogru ?? 0, akim: baskinAkim(k), gelecek: t > bugun)
        }
    }

    /// `seri`: art arda çalışılan gün sayısı; bugün henüz çalışılmadıysa dünden sayılır
    public static func seri(_ gecmis: [String: GunKaydi], bugun: String) -> Int {
        func var_(_ t: String) -> Bool { (gecmis[t]?.kart ?? 0) > 0 }
        var t = var_(bugun) ? bugun : GunTarihi.ekle(bugun, -1)
        var n = 0
        while var_(t) { n += 1; t = GunTarihi.ekle(t, -1) }
        return n
    }

    /// `haftalikOran`
    public static func haftalikOran(_ gecmis: [String: GunKaydi], bugun: String, hafta: Int = 12) -> [HaftaOrani] {
        let gunler = takvim(gecmis, bugun: bugun, hafta: hafta)
        return (0..<hafta).map { h in
            let dilim = gunler[(h * 7)..<(h * 7 + 7)]
            let kart = dilim.reduce(0) { $0 + $1.kart }, dogru = dilim.reduce(0) { $0 + $1.dogru }
            return HaftaOrani(bas: dilim.first!.tarih, kart: kart, dogru: dogru, oran: kart > 0 ? Double(dogru) / Double(kart) : nil)
        }
    }

    /// `gelecekYuk`: önümüzdeki `gun` günün vadeli sanatçı sayısı (0 = bugün; vadesi geçmişler bugüne).
    /// Bir sanatçı, sanatçı ve akım sorularından en yakın vadesiyle bir kez sayılır.
    public static func gelecekYuk(_ skorlar: [String: SkorKaydi], idler: [String], bugun: String, gun: Int = 14) -> [Int] {
        var sayilar = [Int](repeating: 0, count: gun)
        let sinir = (0..<gun).map { GunTarihi.ekle(bugun, $0) }
        for id in idler {
            let sk = skorlar[id]
            let tarihler = [sk?.sanatci, sk?.akim].compactMap { $0 }
                .filter { !($0.son ?? "").isEmpty && !($0.sonraki ?? "").isEmpty }.map { $0.sonraki! }
            guard let yakin = tarihler.min(by: { $0.utf16.lexicographicallyPrecedes($1.utf16) }) else { continue }
            if let i = sinir.firstIndex(where: { yakin <= $0 }) { sayilar[i] += 1 }
        }
        return sayilar
    }

    /// `vadeSayisi`: verilen güne kadar (o gün dahil) vadesi gelen sanatçı sayısı (Bugün'deki "tekrar bekliyor")
    public static func vadeSayisi(_ skorlar: [String: SkorKaydi], idler: [String], tarih: String) -> Int {
        idler.filter { id in
            let sk = skorlar[id]
            return Leitner.vadesiGeldi(sk?.sanatci, tarih) || Leitner.vadesiGeldi(sk?.akim, tarih)
        }.count
    }

    /// `yarinVade`: rozet için yarına kadar vadesi gelenler
    public static func yarinVade(_ skorlar: [String: SkorKaydi], idler: [String], bugun: String) -> Int {
        vadeSayisi(skorlar, idler: idler, tarih: GunTarihi.ekle(bugun, 1))
    }
}

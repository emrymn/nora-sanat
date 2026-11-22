// Kaynak: sanat-atlasi js/{harita,bolum,birlesme,ders,dersIcerik}.js @ a866b86
import Foundation

public struct YolculukDuragi: Identifiable {
    public let id: String
    public let akim: String
    public let no: Int
    public let adet: Int
    public let sanatcilar: [String]
    public var ad: String { adet == 1 ? akim : "\(akim) · \(no). bölüm" }
    public var kilit: String?
    public var dersGerekli = false
    public var acik: Bool { kilit == nil }
    public var kayit: JSONDeger?
    public func gecti(_ seviye: String) -> Bool { acik && (kayit?[seviye]?.sayi ?? 0) >= 0.75 }
    public var yildiz: Int { ["kolay","orta","zor"].filter(gecti).count }
    public var gruplar: [[String]] {
        let n = sanatcilar.count
        guard n >= 6 else { return [sanatcilar] }
        let adet = (n + 3) / 4
        var i = 0
        return (0..<adet).map { g in
            let son = i + n / adet + (g < n % adet ? 1 : 0)
            defer { i = son }
            return Array(sanatcilar[i..<son])
        }
    }
    public let sembol: Int
    public let bolge: String
    public let x, y, en, boy, ax, ay: Double
}

public enum YolculukHaritasi {
    public static let bolgeler = ["ortacag","ronesans","barok","barok2","aydinlanma","romantik","empresyonizm","postempresyonizm","modern"]
    public static let adlar = ["Orta Çağ","Rönesans","Barok","Klasisizm ve Geç Barok","Rokoko ve Neoklasisizm","Romantizmden Realizme","Empresyonizm","Post-Empresyonizm ve Sembolizm","Modern sanat"]
    public static func vakit(saat: Int) -> String { (7..<19).contains(saat) ? "gunduz" : "gece" }

    public static func kur(_ k: SiteKatalogu, ilerleme: Ilerleme, harita: JSONDeger,
                           dersler: JSONDeger?, yuruyus: JSONDeger?) -> [YolculukDuragi] {
        let bolumler = CalisDersKurallari.bolumleriKur(akimlar: k.akimlar, sanatcilar: k.sanatcilar)
        let durum = CalisDersKurallari.bolumDurumlari(bolumler: bolumler, ilerleme: ilerleme, harita: k.harita) { akim in
            guard let dersler else { return nil }
            guard let ders = CalisDersKurallari.dersBul(kaynak: dersler, akim: akim) else { return true }
            let adimlar = CalisDersKurallari.dersAdimlari(ders: ders, yuruyus: yuruyus)
            return CalisDersKurallari.dersDurumu(CalisDersKurallari.dersKaydi(ilerleme, akim: akim), adimlar: adimlar).bitti
        }
        var sayilar = [String: Int]()
        return durum.durumlar.map { d in
            let b = d.bolum
            let sonlar = [3,8,12,14,16,20,22,25,99]
            let bolge = bolgeler[sonlar.firstIndex { b.sira >= 0 && b.sira <= Double($0) } ?? 8]
            let veri = harita["bolgeler"]?[bolge]
            let noktalar = veri?["duraklar"]?.dizi ?? []
            let j = sayilar[bolge, default: 0]
            sayilar[bolge] = j+1
            let s = max(0,min(j,noktalar.count-1))
            let p = noktalar.indices.contains(s) ? noktalar[s].dizi ?? [] : []
            let semboller = veri?["semboller"]?.dizi ?? []
            let n = semboller.indices.contains(s) ? semboller[s] : nil
            let dersGerekli: Bool
            if case .ders = d.neden { dersGerekli = true } else { dersGerekli = false }
            return YolculukDuragi(id:b.id, akim:b.akim, no:b.no, adet:b.adet, sanatcilar:b.sanatcilar,
                kilit:d.acik ? nil : CalisDersKurallari.kilitMetni(d,bolumler:bolumler), dersGerekli:dersGerekli,
                kayit:ilerleme[alan:"bolumler"]?[b.id], sembol:s+1, bolge:bolge,
                x:p.first?.sayi ?? 0.5, y:max(0.02,(p.last?.sayi ?? 0.5)-Double(j-s)*0.05),
                en:n?["w"]?.sayi ?? 34, boy:n?["h"]?.sayi ?? 56, ax:n?["ax"]?.sayi ?? 0.5, ay:n?["ay"]?.sayi ?? 0.85)
        }
    }
}

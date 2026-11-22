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
        let kumeler = k.akimlar.sorted { $0.sira < $1.sira }.map { a in
            let uyeler = k.sanatcilar.filter { $0.akim == a.ad && $0.birlesen == nil }
            let konular = Dictionary(grouping: uyeler) { $0.konu ?? 0 }
            var gruplar = [[Sanatci]](), grup = [Sanatci]()
            for no in konular.keys.sorted() {
                grup += konular[no, default: []].sorted { ($0.dogum ?? 0) < ($1.dogum ?? 0) }
                if grup.count >= 3 { gruplar.append(grup); grup = [] }
            }
            if !grup.isEmpty {
                if gruplar.isEmpty { gruplar.append(grup) } else { gruplar[gruplar.count - 1] += grup }
            }
            return (a, uyeler, gruplar)
        }
        let boylar = kumeler.flatMap { $0.2.map(\.count) }
        let ortalama = boylar.isEmpty ? 3 : Int((Double(boylar.reduce(0,+)) / Double(boylar.count)).rounded())
        let kayitlar = ilerleme[alan: "bolumler"]
        var duraklar = [YolculukDuragi](), sayilar = [String:Int]()
        for (a, uyeler, gruplar) in kumeler {
            var tum = gruplar.enumerated().map { ("\(Int(a.sira))-\($0.offset + 1)", $0.element) }
            let ek = k.sanatcilar.filter { $0.akim == a.ad && $0.birlesen == "Uluslararası Gotik" }
            if !ek.isEmpty {
                let tamamlayan = uyeler.sorted { ($0.dogum ?? 0) > ($1.dogum ?? 0) }.prefix(max(0, ortalama - ek.count))
                tum.append(("3-1", (ek + tamamlayan).sorted { ($0.dogum ?? 0) < ($1.dogum ?? 0) }))
            }
            let ders = dersler?["dersler"]?.dizi?.first { $0["akim"]?.metin == a.ad }
            let oynandi = tum.contains { !(kayitlar?[$0.0]?.nesne?.ciftler.isEmpty ?? true) }
            let gor = ders?["gor"]?.dizi?.contains { g in
                guard let id = g["sanatci"]?.metin, let eser = yuruyus?[id], eser["eser"] == g["eser"] else { return false }
                return !(eser["noktalar"]?.dizi?.isEmpty ?? true)
            } ?? false
            let gerekli = gor ? ["gor","ogren","ayirt"] : ["ogren","ayirt"]
            let dersKilit = ders != nil && !oynandi && gerekli.contains { (ilerleme[alan:"dersler"]?[a.ad]?[$0]?["i"]?.sayi ?? 0) < 1 - 1e-9 }
            let sonlar = [3,8,12,14,16,20,22,25,99]
            let bolge = bolgeler[a.sira >= 0 ? sonlar.firstIndex(where: { Double($0) >= a.sira }) ?? 8 : 8]
            let veri = harita["bolgeler"]?[bolge]
            let noktalar = veri?["duraklar"]?.dizi ?? []
            for (i, kayit) in tum.enumerated() {
                let j = sayilar[bolge, default: 0]
                sayilar[bolge] = j + 1
                let s = max(0,min(j,noktalar.count - 1))
                let p = noktalar.indices.contains(s) ? noktalar[s].dizi ?? [] : []
                let semboller = veri?["semboller"]?.dizi ?? []
                let n = semboller.indices.contains(s) ? semboller[s] : nil
                var x = YolculukDuragi(id: kayit.0, akim: a.ad, no: i+1, adet: tum.count,
                    sanatcilar: kayit.1.map(\.id), kayit: kayitlar?[kayit.0], sembol: s+1, bolge: bolge,
                    x: p.first?.sayi ?? 0.5, y: max(0.02,(p.last?.sayi ?? 0.5) - Double(j-s)*0.05),
                    en: n?["w"]?.sayi ?? 34, boy: n?["h"]?.sayi ?? 56, ax: n?["ax"]?.sayi ?? 0.5, ay: n?["ay"]?.sayi ?? 0.85)
                if let once = duraklar.last {
                    if i > 0 && !once.gecti("orta") { x.kilit = "\(once.ad): Orta seviyeyi geçince açılır." }
                    if i == 0 {
                        let gereken = Int(ceil(Double(once.adet)*0.6 - 1e-9))
                        let gecen = duraklar.filter { $0.akim == once.akim && $0.gecti("orta") }.count
                        if gecen < gereken { x.kilit = "\(once.akim) akımında \(gereken) bölümün Orta'sını geçince açılır (şu an \(gecen))." }
                    }
                }
                if x.kilit == nil && dersKilit { x.kilit = "Çalış’taki \(a.ad) dersini bitirince açılır."; x.dersGerekli = true }
                if let eksik = kayit.1.compactMap(\.konu).filter({ !ilerleme.islenenKume.contains($0) }).min() {
                    x.kilit = "Konu \(eksik) işlenince açılır."; x.dersGerekli = false
                }
                duraklar.append(x)
            }
        }
        return duraklar
    }
}

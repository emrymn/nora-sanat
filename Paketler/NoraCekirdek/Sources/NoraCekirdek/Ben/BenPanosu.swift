// Kaynak: sanat-atlasi js/ekranlar/ilerleme.js, js/ekranlar/pano.js, js/ekranlar/ayarlar.js @ a866b86
import Foundation

public struct AkimBasarisi: Identifiable {
    public let id: String
    public var sanatci = 0, dogru = 0, toplam = 0, kalici = 0, vade = 0
    public var oran: Double? { toplam > 0 ? Double(dogru) / Double(toplam) : nil }
}

public struct SanatciBasarisi: Identifiable {
    public let id: String
    public let dogru, toplam, kutu: Int
    public var oran: Double { Double(dogru) / Double(toplam) }
}

public struct BenPanosu {
    public let akimlar: [AkimBasarisi]
    public let zayiflar: [SanatciBasarisi]
    public let acik, kalici, vade: Int

    public init(_ il: Ilerleme, sanatcilar: [Sanatci], akimlar: [Akim], bugun: String) {
        let skorlar = il.skorlar
        let aciklar = il.acikSanatcilar(sanatcilar)
        let kurstakiler = Set(Kilit.acikSanatcilar(sanatcilar, islenen: il.islenenKume).map(\.id))
        var satirlar: [String: AkimBasarisi] = [:]
        var zayif: [SanatciBasarisi] = []
        var kalici = 0, vade = 0
        for s in aciklar {
            let kayit = skorlar[s.id]
            let skor: [Skor] = [kayit?.sanatci, kayit?.akim].compactMap { $0 }
            let gorulen = skor.filter { Leitner.goruldu($0) }
            let kutu = gorulen.map(\.kutu).min() ?? -1
            let vadeli = gorulen.contains { Leitner.vadesiGeldi($0, bugun) }
            var a = satirlar[s.akim] ?? AkimBasarisi(id: s.akim)
            a.sanatci += 1
            for x in skor {
                a.dogru += x.dogru
                a.toplam += x.dogru + x.yanlis
            }
            if kutu >= 4 { a.kalici += 1; kalici += 1 }
            if vadeli { a.vade += 1 }
            satirlar[s.akim] = a
            guard kurstakiler.contains(s.id) else { continue }
            if vadeli { vade += 1 }
            let dg = gorulen.reduce(0) { $0 + $1.dogru }
            let tp = gorulen.reduce(0) { $0 + $1.dogru + $1.yanlis }
            if tp > 0 && (dg < tp || kutu <= 1) {
                zayif.append(SanatciBasarisi(id: s.id, dogru: dg, toplam: tp, kutu: kutu))
            }
        }
        self.akimlar = Kilit.akimDurumlari(akimlar, sanatcilar, islenen: il.islenenKume)
            .filter(\.acik).compactMap { satirlar[$0.ad] }
        self.zayiflar = Array(zayif.sorted { ($0.oran, $0.kutu, -$0.toplam) < ($1.oran, $1.kutu, -$1.toplam) }.prefix(10))
        self.acik = aciklar.count
        self.kalici = kalici
        self.vade = vade
    }

    public static func isaretle(_ nolar: [Int], islendi: Bool, il: inout Ilerleme) {
        var s = il.islenenKume
        if islendi { s.formUnion(nolar) } else { s.subtract(nolar) }
        il.islenen = s.sorted()
    }

    public static func kart(_ fark: Int, il: inout Ilerleme) {
        let n = il.ayar("gunlukKart")?.tamSayi ?? 20
        il.ayarla("gunlukKart", .sayi(max(5, min(100, n + fark))))
    }

    public static func sec(_ alan: String, _ deger: String, il: inout Ilerleme) {
        il.ayarla(alan, .metin(deger))
        if alan == "gunduzRenk" { il.ayarla("tema", .metin("gunduz")) }
    }
}

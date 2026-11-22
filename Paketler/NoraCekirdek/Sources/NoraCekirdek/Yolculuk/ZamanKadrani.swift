// Kaynak: sanat-atlasi js/zaman.js, js/ekranlar/zaman.js @ a866b86
import Foundation

public enum ZamanKadrani {
    public static func sinirla(_ yil: Double) -> Int { Int(max(1250,min(2000,yil.rounded()))) }
    public static func baslangic(_ sanatcilar: [Sanatci], islenen: Set<Int>) -> Int {
        let yillar = sanatcilar.filter { islenen.contains($0.konu ?? -1) }.compactMap(\.dogum)
        return yillar.isEmpty ? 1500 : sinirla(Double(yillar.reduce(0,+))/Double(yillar.count) + 35)
    }
    public static func evre(_ yil: Int) -> String {
        let yuzyil = (yil-1)/100+1
        let sira = (yil-1)%100
        let roma = ["","I","II","III","IV","V","VI","VII","VIII","IX"]
        return String(repeating: "X", count: yuzyil/10) + roma[yuzyil%10] + ". yüzyıl " + (sira < 33 ? "başı" : sira < 66 ? "ortası" : "sonu")
    }
    public struct Yasam: Identifiable {
        public var id: String { sanatci.id }
        public let sanatci: Sanatci
        public let bas, son: Int
        public func pay(_ yil: Int) -> Double { son == bas ? 1 : max(0,min(1,Double(yil-bas)/Double(son-bas))) }
        public func yas(_ yil: Int) -> String {
            guard let dogum = sanatci.dogum else { return "yaşı bilinmiyor" }
            if yil == dogum { return "doğduğu yıl" }
            return "\(yil-dogum) yaşında" + (sanatci.olum == yil ? " öldü" : "")
        }
    }
    public static func yasayanlar(_ sanatcilar: [Sanatci], yil: Int) -> [Yasam] {
        sanatcilar.compactMap { s -> Yasam? in
            guard let bas = s.dogum ?? s.olum.map({ $0-60 }), let son = s.olum ?? s.dogum.map({ $0+60 }),
                  bas <= yil, yil <= son else { return nil }
            return Yasam(sanatci: s, bas: bas, son: son)
        }.sorted { ($0.bas,$0.son) < ($1.bas,$1.son) }
    }
    public struct Cubuk: Identifiable {
        public let id, sayi: Int
        public let akim: String?
        public let acik: Bool
    }
    public static func yogunluk(_ sanatcilar: [Sanatci], islenen: Set<Int>) -> [Cubuk] {
        stride(from: 1250, to: 2000, by: 10).map { yil in
            let liste = yasayanlar(sanatcilar, yil: yil+5)
            let sayilar = Dictionary(grouping: liste, by: { $0.sanatci.akim }).mapValues(\.count)
            let en = sayilar.values.max()
            return Cubuk(id: yil, sayi: liste.count, akim: liste.first { sayilar[$0.sanatci.akim] == en }?.sanatci.akim,
                         acik: liste.contains { islenen.contains($0.sanatci.konu ?? -1) })
        }
    }
}

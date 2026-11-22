// Kaynak: sanat-atlasi js/harita.js ve js/ekranlar/harita.js @ a866b86
import Foundation

public struct YolcuPatikasi {
    public struct Nokta: Equatable {
        public let x, y: Double
        public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    }
    public let noktalar: [Nokta]
    public let geri: Bool
    public let uzunluk: Double
    public var yurunur: Bool { noktalar.count > 1 && uzunluk > 0 && uzunluk <= 1000 }
    public var sure: Double { min(1.6, max(0.9, uzunluk / 220)) }

    public static func yer(_ d: YolculukDuragi) -> Nokta {
        Nokta(min(372, max(18, d.x * 390 + (d.x > 0.5 ? -34 : 34))), d.y * 1170 + 4)
    }

    public init?(duraklar: [YolculukDuragi], eski: String, yeni: String, veri: JSONDeger?) {
        guard let bas = duraklar.firstIndex(where: { $0.id == eski }),
              let son = duraklar.firstIndex(where: { $0.id == yeni }), bas != son else { return nil }
        geri = son < bas
        let ilk = duraklar[bas], hedef = duraklar[son]
        var yol = [Self.yer(ilk)]
        if ilk.bolge == hedef.bolge && abs(son-bas) <= 4 {
            let bolgeBasi = duraklar.firstIndex { $0.bolge == ilk.bolge } ?? bas
            let yollar = veri?["bolgeler"]?[ilk.bolge]?["yollar"]?.dizi ?? []
            let yon = geri ? -1 : 1
            for i in stride(from: bas, to: son, by: yon) {
                let k = min(i, i + yon) - bolgeBasi
                if yollar.indices.contains(k), let ara = yollar[k].dizi, ara.count >= 2 {
                    let orta = ara.dropFirst().dropLast().compactMap { c -> Nokta? in
                        guard let n = c.dizi, n.count == 2, let x = n[0].sayi, let y = n[1].sayi else { return nil }
                        return Nokta(x * 390, y * 1170)
                    }
                    yol += geri ? Array(orta.reversed()) : orta
                }
                yol.append(Self.yer(duraklar[i + yon]))
            }
        } else { yol = [Self.yer(hedef)] }
        noktalar = yol
        uzunluk = zip(yol, yol.dropFirst()).reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
    }

    public func konum(_ pay: Double) -> (yer: Nokta, on: Bool) {
        let u = min(1,max(0,pay))
        var kalan = uzunluk * (u < 0.5 ? 2*u*u : 1-pow(-2*u+2,2)/2)
        for (a,b) in zip(noktalar,noktalar.dropFirst()) {
            let dx = b.x-a.x, dy = b.y-a.y, boy = hypot(dx,dy)
            if boy > 0 && kalan <= boy {
                let t = kalan/boy
                return (Nokta(a.x+t*dx,a.y+t*dy), dy > abs(dx)*0.6 || (geri && -dy <= abs(dx)*1.6))
            }
            kalan -= boy
        }
        return (noktalar[noktalar.count-1],geri)
    }
}

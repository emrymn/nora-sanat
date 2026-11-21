// Kaynak: sanat-atlasi js/yuruyus.js (noktaAdimi, durus, boya), js/egim.js @ a866b86
import Foundation

public struct YuruyusKamerasi {
    public let ekran, resim: CGSize
    public let kirp: CGRect
    public var kapla: Double { max(ekran.width / kirp.width, ekran.height / kirp.height) }

    public init(ekran: CGSize, oran: Double, kirp: [Double]?) {
        self.ekran = ekran
        resim = CGSize(width: 4000 * min(1, oran), height: 4000 / max(1, oran))
        let r = kirp ?? []
        if r.count == 4, r.allSatisfy({ (0...1).contains($0) }), r[2] > 0, r[3] > 0 {
            self.kirp = CGRect(x: r[0]*resim.width, y: r[1]*resim.height,
                               width: r[2]*resim.width, height: r[3]*resim.height)
        } else { self.kirp = CGRect(origin: .zero, size: resim) }
    }

    public struct Durus {
        public let merkez: CGPoint
        public let olcek, hedefY: Double
        public var kartUstte = false
        public var gorunen = 1.0

        public init(_ merkez: CGPoint, _ olcek: Double, _ hedefY: Double) {
            self.merkez = merkez
            self.olcek = olcek
            self.hedefY = hedefY
        }

        public func ara(_ hedef: Self, pay: Double) -> Self {
            let t = min(1, max(0, pay))
            let f = t < 0.5 ? 4*t*t*t : 1 - pow(-2*t+2, 3)/2
            func karistir(_ a: Double, _ b: Double) -> Double { a + (b-a)*f }
            return Self(CGPoint(x: karistir(merkez.x, hedef.merkez.x), y: karistir(merkez.y, hedef.merkez.y)),
                        exp(karistir(log(olcek), log(hedef.olcek))), karistir(hedefY, hedef.hedefY))
        }
    }

    /// Ayrıntının iki olası kart konumunda görünen payını karşılaştırır.
    public func nokta(_ kutu: CGRect, kart: Double, ust: Double, alt: Double) -> Durus {
        let w = ekran.width, h = ekran.height
        let r = CGRect(x: kutu.minX*resim.width, y: kutu.minY*resim.height,
                       width: kutu.width*resim.width, height: kutu.height*resim.height)
        func dene(_ ustte: Bool) -> Durus {
            let bas = ust + (ustte ? kart + 14 : 0)
            let son = h - alt - (ustte ? 0 : kart + 14)
            let vy = (bas + son)/2
            var s = max(kapla, min(w*0.94/r.width, max(80,son-bas)*0.92/r.height, 1.1))
            func gorunen(_ s: Double) -> Double {
                let ty = min(-kirp.minY*s, max(h-kirp.maxY*s, vy-r.midY*s))
                return max(0, min(ty+r.maxY*s,son)-max(ty+r.minY*s,bas))/max(1,r.height*s)
            }
            var iyi = Durus(CGPoint(x:r.midX, y:r.midY), s, vy)
            iyi.kartUstte = ustte
            iyi.gorunen = gorunen(s)
            for _ in 0..<25 {
                if iyi.gorunen >= 0.97 { break }
                s *= 1.08
                let g = gorunen(s)
                if g > iyi.gorunen + 0.02 {
                    iyi = Durus(iyi.merkez, s, vy)
                    iyi.kartUstte = ustte
                    iyi.gorunen = g
                }
            }
            return iyi
        }
        let a = dene(false), b = dene(true)
        if abs(a.gorunen - b.gorunen) < 0.05 { return a.olcek <= b.olcek ? a : b }
        return a.gorunen > b.gorunen ? a : b
    }

    public func cerceve(_ d: Durus, buyut: Double, egim: CGPoint?) -> CGRect {
        let pay = egim == nil ? 0.0 : 26.0
        let s = max(d.olcek*buyut, (ekran.width+2*pay)/kirp.width, (ekran.height+2*pay)/kirp.height)
        let x = min(-kirp.minX*s-pay, max(ekran.width-kirp.maxX*s+pay, ekran.width/2-d.merkez.x*s))
        let y = min(-kirp.minY*s-pay, max(ekran.height-kirp.maxY*s+pay, d.hedefY-d.merkez.y*s))
        return CGRect(x:x-(egim?.x ?? 0)*14, y:y-(egim?.y ?? 0)*10.5, width:resim.width*s, height:resim.height*s)
    }
}

public struct YuruyusEgimi {
    private var aci = CGPoint.zero
    public init() {}
    public mutating func izle(hiz: CGPoint, sure: Double) -> CGPoint {
        let k = exp(-sure/1.6)
        func biriktir(_ eski: Double, _ hiz: Double) -> Double { min(33,max(-33,eski*k+hiz*sure)) }
        aci = CGPoint(x:biriktir(aci.x,hiz.x), y:biriktir(aci.y,hiz.y))
        return CGPoint(x:min(1,max(-1,aci.x/22)), y:min(1,max(-1,aci.y/22)))
    }
}

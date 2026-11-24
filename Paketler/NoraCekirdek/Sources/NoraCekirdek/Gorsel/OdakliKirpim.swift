// Kaynak: sanat-atlasi js/ekranlar/ortak.js (odakliGorsel, odagaKaydir, kucukGorsel { odak: true }), js/gorsel.js
// (gorselOdakNoktasi, gorselOdagi, gorselAdi) @ cca62eb
import Foundation

/// Z3m: kırpılan kartlarda görsel ortadan değil, odak noktasının (yüz ya da elle işaretlenen) çevresinden kırpılır.
/// Sitede `odakliGorsel(el, e, genislik)`: `<img>`'ye `object-position: x% y%` (odak yüzdesi) verilir; kutuyu kaplayan
/// (`object-fit: cover`) görsel CSS'in kuralıyla yerleşir: taşan pay × yüzde kadar kaydırılır. Odak yoksa CSS'in
/// varsayılanı `50% 50%` (ortadan).
public enum OdakliKirpim {
    /// Kutudaki yerleşim (kutunun sol üstüne göre, nokta): görselin konumu ve kaplama boyu
    public struct Yerlesim: Equatable, Sendable {
        public var x, y, w, h: Double
        public init(x: Double, y: Double, w: Double, h: Double) { self.x = x; self.y = y; self.w = w; self.h = h }
    }

    /// `object-fit: cover; object-position: odak[0]% odak[1]%`. `dogal`: görselin boyu (oran yeter), `kutu`: kutunun
    /// boyu. Boyu bilinmeyen görselde nil.
    public static func yerlesim(dogal: (w: Double, h: Double), kutu: (w: Double, h: Double), odak: [Double]?) -> Yerlesim? {
        guard dogal.w > 0, dogal.h > 0, kutu.w > 0, kutu.h > 0 else { return nil }
        let k = max(kutu.w / dogal.w, kutu.h / dogal.h)
        let w = dogal.w * k, h = dogal.h * k
        let o = OdakVerisi.gecerli(odak) ? odak! : [50, 50]
        return Yerlesim(x: (kutu.w - w) * o[0] / 100, y: (kutu.h - h) * o[1] / 100, w: w, h: h)
    }
}

extension OdakVerisi {
    /// `gorselOdakNoktasi(g)`: görselin yerel adıyla (`gorselAdi(g)`; yerel kopyası olmayanın odağı yok) odağı
    public func odak(_ g: Gorsel?, adresler: GorselAdresleri) -> [Double]? {
        g.flatMap { adresler.yerelAd($0) }.flatMap { odak($0) }
    }

    /// `odakliGorsel(el, e)`: eserin gösterilen görseli (`secilenGorsel(e, kotuler()) || e.gorseller[0]`) ve odağı
    public func odak(_ e: Eser, adresler: GorselAdresleri, kotuler: [String: [String]] = [:]) -> [Double]? {
        odak(GorselAdresleri.secilen(e, kotuler: kotuler) ?? e.gorseller.first, adresler: adresler)
    }
}

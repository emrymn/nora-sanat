// Kaynak: sanat-atlasi js/deste.js, js/sallanma.js, js/egim.js @ a866b86
import Foundation

/// Yaylı sarkacın durumu (`{ aci, hiz }`)
public struct SarkacDurumu: Equatable, Sendable, Codable {
    public var aci: Double
    public var hiz: Double

    public init(aci: Double = 0, hiz: Double = 0) {
        self.aci = aci
        self.hiz = hiz
    }
}

/// Deste yelpaze hedefi (`{ acilim: 0…1, yatma: derece }`)
public struct YelpazeHedefi: Equatable, Sendable, Codable {
    public var acilim: Double
    public var yatma: Double

    public init(acilim: Double = 0, yatma: Double = 0) {
        self.acilim = acilim
        self.yatma = yatma
    }
}

/// Jiroskop / eğim durumu (`{ x, y }`)
public struct EgimNoktasi: Equatable, Sendable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
}

/// Hesaplanmış eğim (`{ x, y, eksen }`)
public struct EgimDegeri: Equatable, Sendable, Codable {
    public var x: Double
    public var y: Double
    public var eksen: String

    public init(x: Double, y: Double, eksen: String) {
        self.x = x
        self.y = y
        self.eksen = eksen
    }
}

/// Atölye / Turlar sahnesindeki kart destesinin eğim ve yay fiziği (`js/deste.js`, `js/sallanma.js`, `js/egim.js`)
public enum DesteFizigi {
    // MARK: - js/deste.js
    public static let yatma: Double = 6.0
    public static let desteSertligi: Double = 90.0
    public static let desteSonumu: Double = 6.0

    /// `yelpazeHedefi(x)` (`js/deste.js`)
    public static func yelpazeHedefi(_ x: Double) -> YelpazeHedefi {
        YelpazeHedefi(acilim: min(1.0, abs(x)), yatma: -x * yatma)
    }

    // MARK: - js/sallanma.js
    public static let enCokSalinim: Double = 9.0
    public static let sallanmaSonumu: Double = 2.4

    /// `ipSertligi(ip)` (`js/sallanma.js`)
    public static func ipSertligi(_ ip: Double) -> Double {
        1800.0 / (max(0.0, ip) + 26.0)
    }

    /// `sarkacAdim(durum, hedef, dt, sertlik, sonum)` (`js/sallanma.js`)
    public static func sarkacAdim(
        _ durum: SarkacDurumu,
        hedef: Double,
        dt: Double,
        sertlik: Double = desteSertligi,
        sonum: Double = desteSonumu
    ) -> SarkacDurumu {
        let ivme = -sertlik * (durum.aci - hedef) - sonum * durum.hiz
        let hiz = durum.hiz + ivme * dt
        return SarkacDurumu(aci: durum.aci + hiz * dt, hiz: hiz)
    }

    /// `durgunMu(durum, hedef)` (`js/sallanma.js`)
    public static func durgunMu(_ durum: SarkacDurumu, hedef: Double) -> Bool {
        abs(durum.aci - hedef) < 0.02 && abs(durum.hiz) < 0.05
    }

    // MARK: - js/egim.js
    public static let sinir: Double = 22.0
    public static let enCokAci: Double = 5.0
    public static let egimSonumu: Double = 1.6
    public static let takip: Double = 0.003
    public static let suzgec: Double = 0.3

    private static func sinirla(_ v: Double) -> Double {
        max(-1.0, min(1.0, v))
    }

    private static func fark(_ a: Double, _ b: Double) -> Double {
        let m = (a - b).truncatingRemainder(dividingBy: 360.0)
        return (m + 540.0).truncatingRemainder(dividingBy: 360.0) - 180.0
    }

    /// `eksenYaz(x, y)` (`js/egim.js`)
    public static func eksenYaz(x: Double, y: Double) -> String {
        let buyukluk = min(1.0, hypot(x, y))
        if buyukluk < 0.001 { return "0 1 0 0deg" }
        return String(format: "%.3f %.3f 0 %.2fdeg", -y, x, buyukluk * enCokAci)
    }

    /// `donusIzle(durum, hiz, dt, sonum)` (`js/egim.js`)
    public static func donusIzle(
        _ durum: EgimNoktasi,
        hizBeta: Double,
        hizGamma: Double,
        dt: Double,
        sonum: Double = egimSonumu
    ) -> EgimNoktasi {
        let k = exp(-dt / sonum)
        let tavan = sinir * 1.5
        func sin(_ v: Double) -> Double { max(-tavan, min(tavan, v)) }
        return EgimNoktasi(
            x: sin(durum.x * k + hizGamma * dt),
            y: sin(durum.y * k + hizBeta * dt)
        )
    }

    /// `donustenEgim(durum)` (`js/egim.js`)
    public static func donustenEgim(_ durum: EgimNoktasi) -> EgimDegeri {
        let x = sinirla(durum.x / sinir)
        let y = sinirla(durum.y / sinir)
        return EgimDegeri(x: x, y: y, eksen: eksenYaz(x: x, y: y))
    }

    /// `egimAcilari(beta, gamma)` (`js/egim.js`)
    public static func egimAcilari(beta: Double, gamma: Double) -> (on: Double, yan: Double) {
        let derece = Double.pi / 180.0
        let b = beta * derece
        let g = gamma * derece
        let yan = asin(max(-1.0, min(1.0, cos(b) * sin(g)))) / derece
        let on = atan2(sin(b), cos(b) * cos(g)) / derece
        return (on, yan)
    }

    /// `egimHesapla(beta, gamma, taban)` (`js/egim.js`)
    public static func egimHesapla(beta: Double, gamma: Double, tabanBeta: Double, tabanGamma: Double) -> EgimDegeri {
        let x = sinirla(fark(gamma, tabanGamma) / sinir)
        let y = sinirla(fark(beta, tabanBeta) / sinir)
        return EgimDegeri(x: x, y: y, eksen: eksenYaz(x: x, y: y))
    }

    /// `tabanIzle(taban, beta, gamma, takip)` (`js/egim.js`)
    public static func tabanIzle(
        taban: (beta: Double, gamma: Double)?,
        beta: Double,
        gamma: Double,
        takip: Double = takip
    ) -> (beta: Double, gamma: Double) {
        guard let taban else { return (beta, gamma) }
        return (
            beta: taban.beta + fark(beta, taban.beta) * takip,
            gamma: taban.gamma + fark(gamma, taban.gamma) * takip
        )
    }
}

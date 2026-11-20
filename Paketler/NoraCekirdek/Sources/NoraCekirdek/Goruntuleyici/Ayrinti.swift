// Kaynak: sanat-atlasi js/ayrinti.js @ 28f751ed
import Foundation

/// Rehberli eser incelemesi noktası (`data/eser_ayrintilari.json` veya `data/eser_hikayeleri.json` karakterleri).
/// Koordinatlar görselin en/boyuna oranla 0–1 arasında (`x`, `y` sol üst köşe, `w`, `h` boyut).
public struct AyrintiNoktasi: Equatable, Hashable, Sendable, Codable {
    public var ad: String
    public var x: Double
    public var y: Double
    public var w: Double
    public var h: Double
    public var metin: String

    public init(ad: String, x: Double, y: Double, w: Double, h: Double, metin: String) {
        self.ad = ad
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.metin = metin
    }

    init?(json j: JSONDeger) {
        guard let ad = j["ad"]?.metin,
              let metin = j["metin"]?.metin,
              let x = j["x"]?.sayi,
              let y = j["y"]?.sayi,
              let w = j["w"]?.sayi,
              let h = j["h"]?.sayi else { return nil }
        let n = AyrintiNoktasi(ad: ad, x: x, y: y, w: w, h: h, metin: metin)
        guard AyrintiKurallari.noktaGecerliMi(n) else { return nil }
        self = n
    }

    /// `noktaYeri(n)`: noktanın işaretinin yeri (görselin kutusuna göre yüzde: kutunun ortası)
    public var yerYuzdesi: (x: Double, y: Double) {
        AyrintiKurallari.noktaYeri(self)
    }
}

/// Bir eserin rehberli inceleme kaydı (`data/eser_ayrintilari.json` ya da hikâyenin karakterleri).
public struct AyrintiKaydi: Equatable, Hashable, Sendable, Codable {
    public var anahtar: String
    public var sanatci: String
    public var baslik: String
    public var gorsel: String
    public var birim: String
    public var noktalar: [AyrintiNoktasi]

    public init(anahtar: String = "", sanatci: String = "", baslik: String = "", gorsel: String = "",
                birim: String = "ayrıntı", noktalar: [AyrintiNoktasi]) {
        self.anahtar = anahtar
        self.sanatci = sanatci
        self.baslik = baslik
        self.gorsel = gorsel
        self.birim = birim
        self.noktalar = noktalar
    }

    init?(json e: JSONDeger) {
        guard let anahtar = e["anahtar"]?.metin,
              !anahtar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let hamNoktalar = e["noktalar"]?.dizi else { return nil }
        let noktalar = hamNoktalar.compactMap(AyrintiNoktasi.init(json:))
        guard !noktalar.isEmpty else { return nil }
        self.init(
            anahtar: anahtar,
            sanatci: e["sanatci"]?.metin ?? "",
            baslik: e["baslik"]?.metin ?? "",
            gorsel: e["gorsel"]?.metin ?? "",
            birim: e["birim"]?.metin ?? "ayrıntı",
            noktalar: noktalar
        )
    }
}

/// `noktaOdagi` çıktısı: hedef ölçek ve merkeze göre kayma (px).
public struct NoktaOdagi: Equatable, Hashable, Sendable {
    public var olcek: Double
    public var tx: Double
    public var ty: Double

    public init(olcek: Double, tx: Double, ty: Double) {
        self.olcek = olcek
        self.tx = tx
        self.ty = ty
    }
}

/// Rehberli eser incelemesi kuralları (`js/ayrinti.js`).
public enum AyrintiKurallari {
    public static let enAzNokta = 4
    public static let enCokNokta = 6
    public static let metinEnAz = 60
    public static let metinEnCok = 420

    private static func yaziMi(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func oranMi(_ n: Double) -> Bool {
        n.isFinite && n >= 0 && n <= 1
    }

    /// `noktaGecerliMi(n)`: koordinatlar 0–1 arasında, kutu görselin içinde, boyu makul, açıklama var.
    public static func noktaGecerliMi(_ n: AyrintiNoktasi) -> Bool {
        guard yaziMi(n.ad), yaziMi(n.metin) else { return false }
        guard oranMi(n.x), oranMi(n.y), oranMi(n.w), oranMi(n.h) else { return false }
        guard n.w >= 0.02, n.h >= 0.02 else { return false }
        guard n.x + n.w <= 1.0001, n.y + n.h <= 1.0001 else { return false }
        return true
    }

    /// `ayrintilariAl(json)`: veri dosyasından geçerli kayıtlar (bozuk kayıt sessizce atılır).
    public static func ayrintilariAl(_ json: JSONDeger?) -> [AyrintiKaydi] {
        guard let liste = json?["eserler"]?.dizi else { return [] }
        return liste.compactMap(AyrintiKaydi.init(json:))
    }

    public static func ayrintilariAl(veri: Data) -> [AyrintiKaydi] {
        ayrintilariAl(try? JSONDeger.coz(veri))
    }

    /// `ayrintiAnahtari(e)`: QID, yoksa "sanatçıId|başlık".
    public static func ayrintiAnahtari(_ e: Eser?) -> String {
        guard let e else { return "" }
        if let qid = e.qid, !qid.isEmpty { return qid }
        return !e.sid.isEmpty && !e.baslik.isEmpty ? "\(e.sid)|\(e.baslik)" : ""
    }

    /// `ayrintiBul(liste, anahtar)`
    public static func ayrintiBul(_ liste: [AyrintiKaydi], anahtar: String) -> AyrintiKaydi? {
        guard !anahtar.isEmpty else { return nil }
        return liste.first { $0.anahtar == anahtar }
    }

    /// `eserinAyrintisi(liste, e)`
    public static func eserinAyrintisi(_ liste: [AyrintiKaydi], eser: Eser?) -> AyrintiKaydi? {
        let a = ayrintiAnahtari(eser)
        return a.isEmpty ? nil : ayrintiBul(liste, anahtar: a)
    }

    /// JS `Math.round(x)`: yarımları (`-0.5`, `+0.5`) `+∞` yönüne yuvarlar (`floor(x + 0.5)`).
    static func jsRound(_ x: Double) -> Double {
        let r = floor(x + 0.5)
        return r == 0 ? 0 : r
    }

    /// `noktaOdagi(nokta, taban, sahne, { pay = 0.78, enAz = 1.15, enCok = 6 })`
    public static func noktaOdagi(
        _ nokta: AyrintiNoktasi?,
        taban: (w: Double, h: Double),
        sahne: (w: Double, h: Double),
        pay: Double = 0.78,
        enAz: Double = 1.15,
        enCok: Double = 6.0
    ) -> NoktaOdagi? {
        guard let nokta,
              taban.w > 0, taban.h > 0,
              sahne.w > 0, sahne.h > 0 else { return nil }
        let kw = max(0.02, nokta.w) * taban.w
        let kh = max(0.02, nokta.h) * taban.h
        var olcek = min((sahne.w * pay) / kw, (sahne.h * pay) / kh)
        olcek = min(enCok, max(enAz, olcek))
        let mx = (nokta.x + nokta.w / 2.0 - 0.5) * taban.w
        let my = (nokta.y + nokta.h / 2.0 - 0.5) * taban.h
        var tx = -mx * olcek
        var ty = -my * olcek
        let sx = max(0.0, (taban.w * olcek - sahne.w) / 2.0)
        let sy = max(0.0, (taban.h * olcek - sahne.h) / 2.0)
        tx = min(sx, max(-sx, tx))
        ty = min(sy, max(-sy, ty))
        let yuvarlaOlcek = jsRound(olcek * 1000.0) / 1000.0
        let yuvarlaTx = jsRound(tx)
        let yuvarlaTy = jsRound(ty)
        return NoktaOdagi(
            olcek: yuvarlaOlcek,
            tx: yuvarlaTx,
            ty: yuvarlaTy
        )
    }

    /// `noktaYeri(n)`: noktanın işaretinin yeri (görselin kutusuna göre yüzde: kutunun ortası)
    public static func noktaYeri(_ n: AyrintiNoktasi) -> (x: Double, y: Double) {
        let x = jsRound((n.x + n.w / 2.0) * 10000.0) / 100.0
        let y = jsRound((n.y + n.h / 2.0) * 10000.0) / 100.0
        return (x, y)
    }

    /// `yakinlasmaSiniri(kaynak, taban, dpr = 1, { pay = 1.5, enAz = 1.15, enCok = 6 })`
    public static func yakinlasmaSiniri(
        kaynak: Double,
        taban: Double,
        dpr: Double = 1.0,
        pay: Double = 1.5,
        enAz: Double = 1.15,
        enCok: Double = 6.0
    ) -> Double {
        guard kaynak > 0, taban > 0 else { return enCok }
        let gecerliDpr = dpr.isFinite && dpr > 0 ? max(1.0, dpr) : 1.0
        let olcek = (kaynak * pay) / (taban * gecerliDpr)
        return jsRound(min(enCok, max(enAz, olcek)) * 100.0) / 100.0
    }
}

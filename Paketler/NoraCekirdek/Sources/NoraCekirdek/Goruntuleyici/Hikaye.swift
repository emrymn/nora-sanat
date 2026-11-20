// Kaynak: sanat-atlasi js/hikaye.js @ 28f751ed
import Foundation

/// Resmin hikâyesindeki bir karakter veya önemli nesne (`data/eser_hikayeleri.json` `kim` dizisi).
public struct HikayeKarakteri: Equatable, Hashable, Sendable, Codable {
    public var ad: String
    public var metin: String
    /// Görselin en/boyuna oranla 0–1 arasında `[x, y, w, h]` (varsa)
    public var kutu: [Double]?

    public init(ad: String, metin: String, kutu: [Double]? = nil) {
        self.ad = ad
        self.metin = metin
        self.kutu = kutu
    }

    init?(json k: JSONDeger) {
        guard let ad = k["ad"]?.metin,
              let metin = k["metin"]?.metin,
              !ad.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !metin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        var gecerliKutu: [Double]? = nil
        if let d = k["kutu"]?.dizi, d.count == 4 {
            let sayilar = d.compactMap(\.sayi)
            if sayilar.count == 4 {
                let n = AyrintiNoktasi(ad: ad, x: sayilar[0], y: sayilar[1], w: sayilar[2], h: sayilar[3], metin: metin)
                if AyrintiKurallari.noktaGecerliMi(n) {
                    gecerliKutu = sayilar
                }
            }
        }
        self.init(ad: ad, metin: metin, kutu: gecerliKutu)
    }
}

/// Bir eserin hikâyesi (`data/eser_hikayeleri.json`).
public struct HikayeKaydi: Equatable, Hashable, Sendable, Codable {
    public var anahtar: String
    public var sanatci: String
    public var baslik: String
    /// "Ne oluyor?" paragrafları
    public var olay: [String]
    /// "Kim kimdir?" listesi
    public var kim: [HikayeKarakteri]
    /// "Ressamla bağı" paragrafları
    public var ressam: [String]
    /// "Gözden kaçanlar" maddeleri
    public var gozden: [String]

    public init(anahtar: String, sanatci: String = "", baslik: String, olay: [String],
                kim: [HikayeKarakteri] = [], ressam: [String] = [], gozden: [String] = []) {
        self.anahtar = anahtar
        self.sanatci = sanatci
        self.baslik = baslik
        self.olay = olay
        self.kim = kim
        self.ressam = ressam
        self.gozden = gozden
    }

    init?(json e: JSONDeger) {
        guard let anahtar = e["anahtar"]?.metin,
              let baslik = e["baslik"]?.metin,
              !anahtar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !baslik.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let olay = HikayeKurallari.yazilarAl(e["olay"]) else { return nil }
        let kim = (e["kim"]?.dizi ?? []).compactMap(HikayeKarakteri.init(json:))
        let ressam = HikayeKurallari.yazilarAl(e["ressam"]) ?? []
        let gozden = HikayeKurallari.yazilarAl(e["gozden"]) ?? []
        self.init(anahtar: anahtar, sanatci: e["sanatci"]?.metin ?? "", baslik: baslik,
                  olay: olay, kim: kim, ressam: ressam, gozden: gozden)
    }

    /// `karakterKaydi(k)`: kutusu olan karakterler rehberli inceleme kaydı biçiminde
    public var karakterKaydi: AyrintiKaydi? {
        HikayeKurallari.karakterKaydi(self)
    }
}

/// Resimlerin hikâyesi kuralları (`js/hikaye.js`).
public enum HikayeKurallari {
    static func yazilarAl(_ j: JSONDeger?) -> [String]? {
        guard let dizi = j?.dizi, !dizi.isEmpty else { return nil }
        var sonuc: [String] = []
        sonuc.reserveCapacity(dizi.count)
        for oge in dizi {
            guard let m = oge.metin, !m.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            sonuc.append(m)
        }
        return sonuc
    }

    /// `hikayeleriAl(json)`: geçerli kayıtlar (bozuk kayıt sessizce atlanır)
    public static func hikayeleriAl(_ json: JSONDeger?) -> [HikayeKaydi] {
        guard let liste = json?["eserler"]?.dizi else { return [] }
        return liste.compactMap(HikayeKaydi.init(json:))
    }

    public static func hikayeleriAl(veri: Data) -> [HikayeKaydi] {
        hikayeleriAl(try? JSONDeger.coz(veri))
    }

    /// `eserinHikayesi(liste, e)`
    public static func eserinHikayesi(_ liste: [HikayeKaydi], eser: Eser?) -> HikayeKaydi? {
        let a = AyrintiKurallari.ayrintiAnahtari(eser)
        guard !a.isEmpty else { return nil }
        return liste.first { $0.anahtar == a }
    }

    /// `karakterKaydi(k)`: kutusu olan karakterler rehberli inceleme kaydı biçiminde
    public static func karakterKaydi(_ k: HikayeKaydi?) -> AyrintiKaydi? {
        guard let k else { return nil }
        let noktalar: [AyrintiNoktasi] = k.kim.compactMap { c in
            guard let kutu = c.kutu, kutu.count == 4 else { return nil }
            return AyrintiNoktasi(ad: c.ad, x: kutu[0], y: kutu[1], w: kutu[2], h: kutu[3], metin: c.metin)
        }
        guard !noktalar.isEmpty else { return nil }
        return AyrintiKaydi(anahtar: k.anahtar, sanatci: k.sanatci, baslik: k.baslik, birim: "karakter", noktalar: noktalar)
    }
}

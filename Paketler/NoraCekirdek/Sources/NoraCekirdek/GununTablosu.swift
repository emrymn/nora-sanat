import Foundation

/// Bugün ekranındaki (Tuval) günün tablosu: widget'ta gösterilen kart.
public struct GununTablosu: Codable, Equatable, Sendable {
    public var tarih: String
    public var sanatciId: String
    public var sanatci: String
    public var eser: String
    public var yil: Int?
    public var gorsel: URL?
    /// Yürüyüşün ilk durağı (büyük widget'ta kısa not olarak)
    public var notBaslik: String?
    public var notMetin: String?

    public init(tarih: String, sanatciId: String, sanatci: String, eser: String, yil: Int?, gorsel: URL?,
                notBaslik: String? = nil, notMetin: String? = nil) {
        self.tarih = tarih; self.sanatciId = sanatciId; self.sanatci = sanatci; self.eser = eser
        self.yil = yil; self.gorsel = gorsel; self.notBaslik = notBaslik; self.notMetin = notMetin
    }

    /// "Venüs'ün Zaferi · 1740"
    public var eserSatiri: String {
        [eser, yil.map(String.init)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// Sitenin veri dosyalarından günün tablosunu çözer. Sitenin kuralları:
/// - Havuz: `data/yuruyus.json`'da yürüyüşü (noktaları) olan sanatçılar (js/ekranlar/ortak.js `gununHavuzu`).
/// - Ad: `data/eser_adlari_tr.json` (QID ya da "sanatçı|başlık"), yoksa özgün ad (`yuruyusEserAdi`).
/// - Yıl: sanatçının hayatıyla çelişmiyorsa (`yilSupheliMi`).
/// - Görsel: `data/gorsel_kaynagi.json`'daki R2 adresinden 1280'lik kopya (`yuruyusAdresleri`).
public enum GununTablosuCozucu {
    public static let site = SiteVerisi.site

    /// Widget'ın indirdiği dosyalar (`data/` altında; SiteVerisi ile)
    public static let dosyalar = ["yuruyus.json", "sanatcilar.json", "eser_adlari_tr.json", "gorsel_kaynagi.json"]

    public enum Hata: Error { case bozukVeri, bosHavuz }

    /// Z2c-3: günün sanatçısı havuzu (`data/yuruyus.json`'da noktaları olanlar; sitenin `yuruyusHavuzu`)
    public static func havuz(yuruyus: Data) -> [String] {
        guard let y = (try? JSONSerialization.jsonObject(with: yuruyus)) as? [String: Any],
              let eserler = y["eserler"] as? [String: Any] else { return [] }
        return havuz(eserler)
    }

    /// Kayıtta `"bugun": false` olan ana sayfaya gelmez (sitenin js/gunun.js `yuruyusHavuzu`, 2026-11-24: Berlinghieri)
    static func havuz(_ eserler: [String: Any]) -> [String] {
        eserler.compactMap { (id, v) -> String? in
            guard let k = v as? [String: Any], let n = k["noktalar"] as? [Any], !n.isEmpty,
                  (k["bugun"] as? Bool) != false else { return nil }
            return id
        }
    }

    public static func coz(tarih: String, yuruyus: Data, sanatcilar: Data,
                           adlar: Data?, kaynak: Data?) throws -> GununTablosu {
        guard let y = try JSONSerialization.jsonObject(with: yuruyus) as? [String: Any],
              let eserler = y["eserler"] as? [String: Any] else { throw Hata.bozukVeri }

        let havuz = Self.havuz(eserler)
        guard let id = GununSanatcisi.sec(havuz: havuz, tarih: tarih),
              let kayit = eserler[id] as? [String: Any] else { throw Hata.bosHavuz }

        // Sanatçı
        let s = sanatciBul(id, sanatcilar)
        let ad = (s?["ad"] as? String) ?? id

        // Eser adı
        let ozgun = ((kayit["eser"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var eser = ozgun
        if let adlar, let a = (try? JSONSerialization.jsonObject(with: adlar)) as? [String: Any],
           let liste = a["adlar"] as? [String: Any] {
            let qid = kayit["qid"] as? String
            let tr = (qid.flatMap { liste[$0] as? String }) ?? (liste["\(id)|\(ozgun)"] as? String)
            if let tr, !tr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                eser = tr.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Yıl
        var yil = tamSayi(kayit["yil"])
        if let y0 = yil {
            if let olum = tamSayi(s?["olum"]), y0 > olum + 2 { yil = nil }
            if let dogum = tamSayi(s?["dogum"]), y0 < dogum + 12 { yil = nil }
        }

        // Görsel
        let gorsel = gorselAdresi(ad: kayit["gorsel"] as? String, buyuk: kayit["buyuk"] as? String, kaynak: kaynak)

        // İlk durak
        let ilk = (kayit["noktalar"] as? [[String: Any]])?.first
        return GununTablosu(tarih: tarih, sanatciId: id, sanatci: ad, eser: eser, yil: yil, gorsel: gorsel,
                            notBaslik: ilk?["ad"] as? String, notMetin: ilk?["metin"] as? String)
    }

    static func sanatciBul(_ id: String, _ veri: Data) -> [String: Any]? {
        let kok = try? JSONSerialization.jsonObject(with: veri)
        let liste = (kok as? [[String: Any]]) ?? ((kok as? [String: Any])?["sanatcilar"] as? [[String: Any]]) ?? []
        return liste.first { ($0["id"] as? String) == id }
    }

    static func tamSayi(_ x: Any?) -> Int? {
        if let n = x as? Int { return n }
        if let d = x as? Double, d.rounded() == d, abs(d) < 1e9 { return Int(d) }
        if let n = x as? NSNumber { let d = n.doubleValue; return d.rounded() == d ? Int(d) : nil }
        return nil
    }

    /// js/gorsel.js `yuruyusAdresleri(ad, buyuk).kucuk` (kural `GorselAdresleri`'nde, T1)
    public static func gorselAdresi(ad: String?, buyuk: String?, kaynak: Data?) -> URL? {
        let adresler = GorselAdresleri(kaynak: kaynak.flatMap { try? JSONDeger.coz($0) }, kok: site)
        let ayriKopya = !adresler.adres.isEmpty && !(buyuk ?? "").isEmpty
        guard ayriKopya || !(ad ?? "").isEmpty else { return nil }
        return GorselAdresleri.url(adresler.yuruyusAdresleri(ad: ad ?? "", buyuk: buyuk).kucuk)
    }
}

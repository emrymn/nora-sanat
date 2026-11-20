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
    public static let site = URL(string: "https://sanat-atlasi.pages.dev/")!

    /// Widget'ın indirdiği dosyalar (siteye göre)
    public static let dosyalar = ["data/yuruyus.json", "data/sanatcilar.json",
                                  "data/eser_adlari_tr.json", "data/gorsel_kaynagi.json"]

    public enum Hata: Error { case bozukVeri, bosHavuz }

    public static func coz(tarih: String, yuruyus: Data, sanatcilar: Data,
                           adlar: Data?, kaynak: Data?) throws -> GununTablosu {
        guard let y = try JSONSerialization.jsonObject(with: yuruyus) as? [String: Any],
              let eserler = y["eserler"] as? [String: Any] else { throw Hata.bozukVeri }

        let havuz = eserler.compactMap { (id, v) -> String? in
            guard let k = v as? [String: Any], let n = k["noktalar"] as? [Any], !n.isEmpty else { return nil }
            return id
        }
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

    /// js/gorsel.js `yuruyusAdresleri(ad, buyuk).kucuk`
    public static func gorselAdresi(ad: String?, buyuk: String?, kaynak: Data?) -> URL? {
        var adres = ""
        var hepsiBuyuk = false
        var surumler: [String: String] = [:]
        if let kaynak, let k = (try? JSONSerialization.jsonObject(with: kaynak)) as? [String: Any],
           let a = k["adres"] as? String, a.hasPrefix("https://") {
            adres = a
            while adres.hasSuffix("/") { adres.removeLast() }
            hepsiBuyuk = (k["buyuk"] as? Bool) == true
            for (ad, v) in (k["b_surumler"] as? [String: Any]) ?? [:] {
                let s = "\(v)"
                if s.range(of: "^[0-9a-f]{4,16}$", options: .regularExpression) != nil { surumler[ad] = s }
            }
        }
        if !adres.isEmpty, let buyuk, !buyuk.isEmpty {
            let kucuk = buyuk.hasSuffix(".jpg") ? String(buyuk.dropLast(4)) + "-1280.jpg" : buyuk
            return URL(string: "\(adres)/\(kucuk)")
        }
        guard let ad, !ad.isEmpty else { return nil }
        if !adres.isEmpty && hepsiBuyuk {
            let ek = surumler[ad].map { "-\($0)" } ?? ""
            return URL(string: "\(adres)/b/\(ad)\(ek).jpg")
        }
        return URL(string: "gorseller/k/\(ad).jpg", relativeTo: site)?.absoluteURL
    }
}

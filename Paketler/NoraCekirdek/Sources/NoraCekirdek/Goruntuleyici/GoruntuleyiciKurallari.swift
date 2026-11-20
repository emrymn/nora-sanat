// Kaynak: sanat-atlasi js/karsilastir.js, js/goruntuleyici.js, js/keskin.js, js/ikonografi.js @ 28f751ed
import Foundation

/// Görüntüleyicideki "Konu:" bağlantısı için ikonografi konusu özeti (`js/ikonografi.js`).
public struct IkonografiKonuOzeti: Equatable, Hashable, Sendable, Codable {
    public var id: String
    public var ad: String

    public init(id: String, ad: String) {
        self.id = id
        self.ad = ad
    }
}

/// Görüntüleyici künyesi, eser notları, keskin üst kopya, karşılaştırma ve odak yardımcıları
/// (`js/goruntuleyici.js`, `js/karsilastir.js`, `js/keskin.js`, `js/ikonografi.js`, `js/gorsel.js`).
public enum GoruntuleyiciKurallari {
    /// `EN_BUYUK` (`js/goruntuleyici.js`)
    public static let enBuyukOlcek = 6.0

    /// `kaynakYazisi(eser, gorsel)` (`js/goruntuleyici.js`):
    /// Görsel kaynağı ve (varsa) eserin müzesi; iki sanatçıya atfedilen eserde öteki sanatçı.
    public static func kaynakYazisi(_ eser: Eser, gorsel: Gorsel? = nil) -> String {
        let g = gorsel ?? eser.gorseller.first
        let ortak = eser.ortakAdlar.isEmpty ? "" : "Ayrıca atfedilir: \(eser.ortakAdlar.joined(separator: ", "))"
        let gorselYazisi = g.map(GorselAdresleri.kaynakYazisi) ?? ""
        return [ortak, eser.muze, gorselYazisi].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// `notlariAl(json)` (`js/karsilastir.js`): veri dosyasının `"notlar"` alanını güvenle okur (dosya yok / bozuk → `[:]`).
    public static func notlariAl(_ json: JSONDeger?) -> [String: String] {
        guard let nesne = json?["notlar"]?.nesne else { return [:] }
        var sonuc: [String: String] = [:]
        for (k, v) in nesne.ciftler {
            if let m = v.metin {
                let temiz = m.trimmingCharacters(in: .whitespacesAndNewlines)
                if !temiz.isEmpty {
                    sonuc[k] = temiz
                }
            }
        }
        return sonuc
    }

    public static func notlariAl(veri: Data) -> [String: String] {
        notlariAl(try? JSONDeger.coz(veri))
    }

    /// `eserNotu(sanatciId, eser, eserNotlari)` (`js/karsilastir.js`): önce QID, yoksa `"<sanatciId>|<eser başlığı>"`.
    public static func eserNotu(sanatciId: String? = nil, eser: Eser?, eserNotlari: [String: String]) -> String {
        guard let eser else { return "" }
        if let qid = eser.qid, !qid.isEmpty, let not = eserNotlari[qid] {
            return not
        }
        let sid = sanatciId ?? eser.sid
        if !sid.isEmpty, let not = eserNotlari["\(sid)|\(eser.baslik)"] {
            return not
        }
        return ""
    }

    /// `taninmaMetni(s, tanimaNotlari)` (`js/karsilastir.js`): sanatçının kendi notu, yoksa `data/tanima_notlari.json`'daki not.
    public static func taninmaMetni(_ s: Sanatci?, tanimaNotlari: [String: String] = [:]) -> String {
        guard let s else { return "" }
        if let t = s.taninma, !t.isEmpty { return t }
        return tanimaNotlari[s.id] ?? ""
    }

    /// `karsilastirmaAdresi(a, b)` (`js/karsilastir.js`)
    public static func karsilastirmaAdresi(_ a: String, _ b: String) -> String {
        "#/karsilastir/\(SiteYazisi.uriBileseni(a))/\(SiteYazisi.uriBileseni(b))"
    }

    /// `karsilastirmaRotasi(hash)` (`js/karsilastir.js`): `"#/karsilastir/a/b"` → `(a, b)`; geçersizse nil.
    public static func karsilastirmaRotasi(_ hash: String?) -> (String, String)? {
        guard let hash, hash.hasPrefix("#/karsilastir/") else { return nil }
        let kalan = String(hash.dropFirst("#/karsilastir/".count))
        let parcalar = kalan.split(separator: "/", omittingEmptySubsequences: false)
        guard parcalar.count == 2,
              !parcalar[0].isEmpty, !parcalar[1].isEmpty,
              let a = String(parcalar[0]).removingPercentEncoding,
              let b = String(parcalar[1]).removingPercentEncoding,
              !a.isEmpty, !b.isEmpty, a != b else { return nil }
        return (a, b)
    }

    /// `benzerSanatcilar(s, sanatcilar, akimlar, adet = 8)` (`js/karsilastir.js`):
    /// Aynı ya da komşu akım, doğum yılı farkı ≤ 50. Önce aynı akım, sonra yaşça en yakınlar; en çok `adet` kişi.
    public static func benzerSanatcilar(
        _ s: Sanatci?,
        sanatcilar: [Sanatci],
        akimlar: [Akim],
        adet: Int = 8
    ) -> [Sanatci] {
        guard let s, adet > 0 else { return [] }
        let komsular = akimlar.first { $0.ad == s.akim }?.komsular ?? []
        let komsuKume = Set(komsular + [s.akim])
        let y = s.dogum ?? s.olum
        let trLocale = Locale(identifier: "tr")
        let adaylar: [(x: Sanatci, ayni: Int, fark: Int)] = sanatcilar.compactMap { x in
            guard x.id != s.id, komsuKume.contains(x.akim) else { return nil }
            let xy = x.dogum ?? x.olum
            if let y, let xy, abs(xy - y) > 50 { return nil }
            let ayni = x.akim == s.akim ? 0 : 1
            let fark: Int
            if let y, let xy { fark = abs(xy - y) } else { fark = 999 }
            return (x, ayni, fark)
        }
        return adaylar.sorted { a, b in
            if a.ayni != b.ayni { return a.ayni < b.ayni }
            if a.fark != b.fark { return a.fark < b.fark }
            return a.x.ad.compare(b.x.ad, options: [], range: nil, locale: trLocale) == .orderedAscending
        }
        .prefix(adet)
        .map(\.x)
    }

    // MARK: - İkonografi konu bağlantısı (js/ikonografi.js)

    /// `konuHaritasiniAyarla` (`js/ikonografi.js`): `data/ikonografi.json` içinden eser anahtarı → konu özeti haritası kurar.
    public static func ikonografiKonuHaritasi(_ json: JSONDeger?, sanatciVarMi: (String) -> Bool = { _ in true }) -> [String: IkonografiKonuOzeti] {
        guard let konular = json?["konular"]?.dizi else { return [:] }
        var harita: [String: IkonografiKonuOzeti] = [:]
        for k in konular {
            guard let id = k["id"]?.metin?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty,
                  let ad = k["ad"]?.metin?.trimmingCharacters(in: .whitespacesAndNewlines), !ad.isEmpty,
                  let hikaye = k["hikaye"]?.dizi,
                  hikaye.contains(where: { !($0.metin?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }),
                  let eserler = k["eserler"]?.dizi else { continue }
            var gecerliEserler: [String] = []
            for x in eserler {
                guard let cift = x.dizi, cift.count >= 2,
                      let eAnahtar = cift[0].metin, !eAnahtar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let sid = cift[1].metin, !sid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      sanatciVarMi(sid) else { continue }
                gecerliEserler.append(eAnahtar)
            }
            guard !gecerliEserler.isEmpty else { continue }
            let ozet = IkonografiKonuOzeti(id: id, ad: k["ad"]?.metin ?? ad)
            for a in gecerliEserler where harita[a] == nil {
                harita[a] = ozet
            }
        }
        return harita
    }

    /// `eserKonusu(e, h)` (`js/ikonografi.js`)
    public static func eserKonusu(_ e: Eser?, harita: [String: IkonografiKonuOzeti]) -> IkonografiKonuOzeti? {
        guard let e else { return nil }
        if let qid = e.qid, !qid.isEmpty, let konu = harita[qid] {
            return konu
        }
        if !e.sid.isEmpty, let konu = harita["\(e.sid)|\(e.baslik)"] {
            return konu
        }
        return nil
    }

    // MARK: - Keskin görseller (js/keskin.js)

    public static let keskinlikEsigi = 0.8
    public static let buyukAlanOrani = 0.3

    /// `keskinlik(img)` (`js/keskin.js`): görselin pikseli / ekran pikseli; `< 0.8` ise bulanık sayılır.
    public static func keskinlik(
        dogalBoyut: (w: Double, h: Double),
        kutuBoyutu: (w: Double, h: Double),
        contain: Bool = true,
        dpr: Double = 1.0
    ) -> Double {
        guard dogalBoyut.w > 0, dogalBoyut.h > 0, kutuBoyutu.w >= 1, kutuBoyutu.h >= 1 else {
            return .infinity
        }
        let olcek = contain
            ? min(kutuBoyutu.w / dogalBoyut.w, kutuBoyutu.h / dogalBoyut.h)
            : max(kutuBoyutu.w / dogalBoyut.w, kutuBoyutu.h / dogalBoyut.h)
        let gecerliDpr = dpr > 0 ? dpr : 1.0
        return 1.0 / (olcek * gecerliDpr)
    }

    private static let commonsKalip = try! NSRegularExpression(
        pattern: "^(https://upload\\.wikimedia\\.org/wikipedia/commons/thumb/.+/)(\\d+)px-([^/]+)$"
    )

    /// `commonsUstu(src, k, nw)` (`js/keskin.js`)
    public static func commonsUstu(_ src: String, keskinlik k: Double, dogalGenislik nw: Double) -> String {
        let ns = src as NSString
        guard let m = commonsKalip.firstMatch(in: src, range: NSRange(location: 0, length: ns.length)),
              k > 0 else { return "" }
        let on = ns.substring(with: m.range(at: 1))
        let simdiki = Int(ns.substring(with: m.range(at: 2))) ?? 0
        let son = ns.substring(with: m.range(at: 3))
        let gerek = nw / k
        let adim = GorselAdresleri.adimlar.first { Double($0) >= gerek } ?? GorselAdresleri.adimlar.last!
        return adim > simdiki ? "\(on)\(adim)px-\(son)" : ""
    }

    /// `keskinlestir` hedef adresi (`js/keskin.js`):
    /// Ekranda kapladığı yere göre gerçek pikseli yetmiyorsa bir üst kopyanın adresini döndürür (yoksa `""`).
    public static func keskinUstAdres(
        src: String,
        dogalBoyut: (w: Double, h: Double),
        kutuBoyutu: (w: Double, h: Double),
        ekranBoyutu: (w: Double, h: Double),
        dpr: Double = 3.0,
        gorselAdresleri: GorselAdresleri,
        telefondaInmisMi: Bool = false
    ) -> String {
        guard kutuBoyutu.w >= 48 else { return "" }
        let k = keskinlik(dogalBoyut: dogalBoyut, kutuBoyutu: kutuBoyutu, contain: true, dpr: dpr)
        guard k < keskinlikEsigi else { return "" }
        let commons = commonsUstu(src, keskinlik: k, dogalGenislik: dogalBoyut.w)
        if !commons.isEmpty { return commons }
        let ekranAlani = ekranBoyutu.w * ekranBoyutu.h
        let buyuk = ekranAlani > 0 && (kutuBoyutu.w * kutuBoyutu.h) / ekranAlani >= buyukAlanOrani
        let ust = gorselAdresleri.ustKopya(src, buyuk: true)
        guard !ust.isEmpty else { return "" }
        let devasaMi = ust.range(of: "/d/[0-9a-f]+(?:-[0-9a-f]+)?\\.jpg$", options: .regularExpression) != nil
        if devasaMi && !buyuk && !telefondaInmisMi {
            return ""
        }
        return ust
    }
}

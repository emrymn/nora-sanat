// Kaynak: sanat-atlasi js/{ikonografi,basyapit,birlesme,akim,temsil}.js ve
// js/ekranlar/{gozat,akim,arama,koleksiyon}.js @ a866b86
import Foundation

public struct GaleriKonusu: Identifiable, Sendable {
    public let id, ad, ozgun, tur, ozet, kaynak: String
    public let hikaye, tanima: [String]
    public let baglar: [(anahtar: String, sanatci: String)]
}

public struct GaleriKatalogu: Sendable {
    public static let turler = ["eski_ahit", "yeni_ahit", "aziz", "mitoloji", "tarih_edebiyat", "diger"]
    public static let turAdlari = ["Eski Ahit", "Yeni Ahit", "Azizler", "Mitoloji", "Tarih ve edebiyat", "Diğer"]
    public static let dosyalar = ["ikonografi.json", "basyapitlar.json", "akim_bilgi.json", "akim_ozellikleri.json", "imzalar.json", "kunye.json", "tanima_notlari.json", "tanima_kirpimlari.json"]
    public let katalog: SiteKatalogu
    public let eserler: [String: [Eser]]
    public let konular: [GaleriKonusu]
    /// `basyapitVeri()`: geçerli ve temsil edebilen yakın okumalar (G3: `BasyapitKurallari.al`)
    public let basyapitlar: [Basyapit]
    public let konuKirpimlari, sanatciKirpimlari: [String: [TanimaKirpimi]]
    public let kunye: JSONDeger?
    public let imzalar: JSONDeger?
    public let tanimaNotlari: [String: String]
    public let bilgi: [String: [String: String]]
    public let ozellikler: [String: [String]]

    public init(katalog k: SiteKatalogu, dosyalar: [String: Data]) throws {
        self.katalog = k
        self.eserler = Dictionary(uniqueKeysWithValues: k.harita.keys.map { ($0, k.eserler($0)) })
        let ham = try dosyalar.mapValues { try JSONDeger.coz($0) }
        self.konuKirpimlari = TanimaKirpimi.oku(ham["tanima_kirpimlari.json"], konu: true)
        self.sanatciKirpimlari = TanimaKirpimi.oku(ham["tanima_kirpimlari.json"], konu: false)
        self.kunye = ham["kunye.json"]?["kunye"]
        self.imzalar = ham["imzalar.json"]?["imzalar"]
        self.tanimaNotlari = GoruntuleyiciKurallari.notlariAl(ham["tanima_notlari.json"])
        func dolu(_ j: JSONDeger?) -> String? {
            guard let s = j?.metin, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return s
        }
        func satirlar(_ j: JSONDeger?) -> [String] { (j?.dizi ?? []).compactMap(dolu) }
        self.konular = (ham["ikonografi.json"]?["konular"]?.dizi ?? []).compactMap { j in
            let hikaye = satirlar(j["hikaye"])
            guard let id = dolu(j["id"]), let ad = dolu(j["ad"]), !hikaye.isEmpty else { return nil }
            let baglar: [(String, String)] = (j["eserler"]?.dizi ?? []).compactMap { x in
                guard let a = x.dizi, a.count >= 2, let key = dolu(a[0]), let sid = dolu(a[1]), k.harita[sid] != nil else { return nil }
                return (key, sid)
            }
            guard !baglar.isEmpty else { return nil }
            let tur = j["tur"]?.metin ?? ""
            return GaleriKonusu(id: id, ad: ad, ozgun: j["ozgun"]?.metin ?? "", tur: Self.turler.contains(tur) ? tur : "diger",
                                ozet: dolu(j["ozet"]) ?? "", kaynak: dolu(j["kaynak"]) ?? "", hikaye: hikaye,
                                tanima: satirlar(j["tanima"]), baglar: baglar)
        }
        self.basyapitlar = BasyapitKurallari.al(ham["basyapitlar.json"]) { k.harita[$0] != nil }
        let bilgiler = ham["akim_bilgi.json"]?["akimlar"]?.nesne
        var bilgi: [String: [String: String]] = [:]
        for ad in bilgiler?.anahtarlar ?? [] {
            bilgi[ad] = Dictionary(uniqueKeysWithValues: (bilgiler?[ad]?.nesne?.anahtarlar ?? []).compactMap { alan in
                bilgiler?[ad]?[alan]?.metin.map { (alan, $0) }
            })
        }
        let kaynak = "Uluslararası Gotik"
        if let eski = bilgi.removeValue(forKey: kaynak) {
            if var hedef = bilgi["Gotik"] {
                hedef["donem"] = "12. yüzyıl – y. 1425"
                for (alan, ayrac) in [("metin", " "), ("yer", "; ")] {
                    hedef[alan] = [hedef[alan], eski[alan]].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ayrac)
                }
                bilgi["Gotik"] = hedef
            } else { bilgi["Gotik"] = eski }
        }
        self.bilgi = bilgi
        let maddeler = ham["akim_ozellikleri.json"]?["akimlar"]?.nesne
        var oz = Dictionary(uniqueKeysWithValues: (maddeler?.anahtarlar ?? []).map { ($0, satirlar(maddeler?[$0])) })
        if let eski = oz.removeValue(forKey: kaynak) {
            for i in [0, 2, 3] where eski.indices.contains(i) { oz["Gotik", default: []].append(eski[i] + " (" + kaynak + ")") }
        }
        self.ozellikler = oz
    }

    public func eslestir(_ anahtar: String, _ sid: String) -> Eser? {
        eserler[sid]?.first { $0.qid == anahtar || sid + "|" + $0.baslik == anahtar }
    }

    public func konuEserleri(_ konu: GaleriKonusu) -> [Eser] {
        konu.baglar.compactMap { eslestir($0.anahtar, $0.sanatci) }.filter { !$0.gorseller.isEmpty }
    }

    public func koleksiyon(_ il: Ilerleme) -> [Eser] {
        (il[alan: "koleksiyon"]?.dizi ?? []).compactMap { x in
            guard let sid = x["s"]?.metin, let a = x["a"]?.metin else { return nil }
            return eserler[sid]?.first { $0.anahtar == a }
        }
    }

    public func dizin(_ il: Ilerleme) -> [GaleriKaydi] {
        var d = katalog.sanatcilar.map { s in
            let kisa = katalog.kisaAdlar[s.id]
            return GaleriKaydi(.sanatci, s.id, s.ad, alanlar: [s.ad, kisa?.buyuk, kisa?.kucuk, s.adArama])
        }
        for s in il.acikSanatcilar(katalog.sanatcilar) {
            for e in eserler[s.id] ?? [] {
                d.append(GaleriKaydi(.eser, e.anahtar, e.gorunenAd, alanlar: [e.ad, e.baslik], agirlik: e.sl, sanatci: s.id))
            }
        }
        for k in konular { d.append(GaleriKaydi(.konu, k.id, k.ad, alanlar: [k.ad, k.ozgun], agirlik: k.baglar.count)) }
        for b in basyapitlar {
            d.append(GaleriKaydi(.basyapit, b.anahtar, b.baslik, alanlar: [b.baslik, b.ozgun], sanatci: b.sanatci))
        }
        return d
    }

    /// Konu kapağı (`kapakSec`, Temsil)
    public func konuKapagi(_ eserler: [Eser]) -> Eser? { Temsil.kapakSec(eserler) }

    public func tipikKonular(_ ad: String, _ il: Ilerleme) -> [GaleriKonusu] {
        let uyeler = Set(katalog.sanatcilar.filter { $0.akim == ad && $0.konu.map(il.islenenKume.contains) == true }.map(\.id))
        let sayilar = konular.map { k in (k, k.baglar.filter { uyeler.contains($0.sanatci) }.count) }
        return sayilar.filter { $0.1 > 0 }.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            return a.0.ad.compare(b.0.ad, locale: Locale(identifier: "tr")) == .orderedAscending
        }.prefix(4).map { $0.0 }
    }

    /// Çarktaki kemerin eseri (`onizlemeleriDoldur`): `Temsil.akimKapak`'ta elle seçilmişse o; yoksa açık sanatçılar önce
    /// (sonra doğum yılı), ilk 8 sanatçıdan en bilineni olan ilki (`enBilinen`)
    public func carkKapagi(_ ad: String, _ il: Ilerleme) -> Eser? {
        let uyeler = katalog.sanatcilar.filter { $0.akim == ad }
        if let q = Temsil.akimKapak[ad],
           let kapak = uyeler.lazy.flatMap({ self.eserler[$0.id] ?? [] }).first(where: { $0.qid == q }) { return kapak }
        let islenen = il.islenenKume
        let sirali = uyeler.enumerated().sorted { a, b in
            let x = a.element.konu.map(islenen.contains) ?? false, y = b.element.konu.map(islenen.contains) ?? false
            if x != y { return x }
            let da = a.element.dogum ?? 0, db = b.element.dogum ?? 0
            return da != db ? da < db : a.offset < b.offset
        }.map(\.element)
        for s in sirali.prefix(8) {
            if let e = Temsil.enBilinen(eserler[s.id] ?? [], kotuler: il.kotuGorseller) { return e }
        }
        return nil
    }

    /// Akımın en bilinen eserleri (`akimVerisi` → `enBilinenEserler(listeler, 4)`): açık sanatçılardan
    public func enBilinenler(_ ad: String, _ il: Ilerleme, adet: Int = 4) -> [(sanatci: Sanatci, eser: Eser)] {
        let acik = katalog.sanatcilar.filter { $0.akim == ad && $0.konu.map(il.islenenKume.contains) == true }
        return Temsil.enBilinenEserler(acik.map { ($0, eserler[$0.id] ?? []) }, adet: adet)
    }

    public func dortlu(_ ad: String, _ il: Ilerleme) -> [Eser] { enBilinenler(ad, il).map(\.eser) }
}

// Kaynak: sanat-atlasi js/kunye.js @ a866b86
extension GaleriKatalogu {
    public static func sesUzantisi(_ k: JSONDeger?) -> String? {
        if k?["ses"]?.dogru == true { return "mp3" }
        return k?["okunus"]?.dogru == true ? "m4a" : nil
    }

    public static func okunacakAd(_ ad: String) -> String {
        ad.replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+kardeşler\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+ve\s+"#, with: ", ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

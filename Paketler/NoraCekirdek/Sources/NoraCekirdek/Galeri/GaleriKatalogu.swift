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
    public static let dosyalar = ["ikonografi.json", "basyapitlar.json", "akim_bilgi.json", "akim_ozellikleri.json", "imzalar.json", "kunye.json", "tanima_notlari.json"]
    public let katalog: SiteKatalogu
    public let eserler: [String: [Eser]]
    public let konular: [GaleriKonusu]
    public let basyapitlar: [JSONDeger]
    public let kunye: JSONDeger?
    public let imzalar: JSONDeger?
    public let tanimaNotlari: [String: String]
    public let bilgi: [String: [String: String]]
    public let ozellikler: [String: [String]]

    public init(katalog k: SiteKatalogu, dosyalar: [String: Data]) throws {
        self.katalog = k
        self.eserler = Dictionary(uniqueKeysWithValues: k.harita.keys.map { ($0, k.eserler($0)) })
        let ham = try dosyalar.mapValues { try JSONDeger.coz($0) }
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
        self.basyapitlar = (ham["basyapitlar.json"]?["eserler"]?.dizi ?? []).filter { b in
            guard let sid = dolu(b["sanatci"]), k.harita[sid] != nil, dolu(b["anahtar"]) != nil, b["anahtar"]?.metin != "Q3947103", dolu(b["baslik"]) != nil,
                  let bolumler = b["bolumler"]?.dizi, !bolumler.isEmpty else { return false }
            return bolumler.allSatisfy { dolu($0["baslik"]) != nil && dolu($0["metin"]) != nil }
        }
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
            let ad = b["baslik"]?.metin ?? ""
            d.append(GaleriKaydi(.basyapit, b["anahtar"]?.metin ?? "", ad,
                                 alanlar: [ad, SiteYazisi.notTemizle(b["ozgun"]?.metin ?? "")], sanatci: b["sanatci"]?.metin))
        }
        return d
    }

    private func temsil(_ e: Eser) -> Bool {
        e.qid != "Q3947103" && !["q:Q3947103", "Q3947103"].contains(e.anahtar)
    }

    public func konuKapagi(_ eserler: [Eser]) -> Eser? {
        eserler.filter(temsil).max { $0.sl < $1.sl }
    }

    public func tipikKonular(_ ad: String, _ il: Ilerleme) -> [GaleriKonusu] {
        let uyeler = Set(katalog.sanatcilar.filter { $0.akim == ad && $0.konu.map(il.islenenKume.contains) == true }.map(\.id))
        let sayilar = konular.map { k in (k, k.baglar.filter { uyeler.contains($0.sanatci) }.count) }
        return sayilar.filter { $0.1 > 0 }.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            return a.0.ad.compare(b.0.ad, locale: Locale(identifier: "tr")) == .orderedAscending
        }.prefix(4).map { $0.0 }
    }

    public func carkKapagi(_ ad: String, _ il: Ilerleme) -> Eser? {
        let uyeler = katalog.sanatcilar.filter { $0.akim == ad }
        if ad == "Gotik", let kapak = uyeler.lazy.compactMap({ eslestir("Q948745", $0.id) }).first { return kapak }
        let islenen = il.islenenKume
        let sirali = uyeler.sorted { a, b in
            let x = a.konu.map(islenen.contains) ?? false, y = b.konu.map(islenen.contains) ?? false
            return x != y ? x : (a.dogum ?? 0) < (b.dogum ?? 0)
        }
        for s in sirali.prefix(8) {
            let uygun = (eserler[s.id] ?? []).filter { temsil($0) && $0.pekistirme && GorselAdresleri.secilen($0, kotuler: il.kotuGorseller) != nil }
            if let ilk = uygun.max(by: { $0.sl < $1.sl }) { return ilk }
        }
        return nil
    }

    public func dortlu(_ ad: String, _ il: Ilerleme) -> [Eser] {
        var secimler: [(Eser, Int)] = []
        for s in katalog.sanatcilar where s.akim == ad && s.konu.map(il.islenenKume.contains) == true {
            let uygun = (eserler[s.id] ?? []).filter { !$0.gorseller.isEmpty && temsil($0) }
            guard let ilk = uygun.max(by: { $0.sl < $1.sl }) else { continue }
            let ozel = s.id == "pierre-puvis-de-chavannes" ? uygun.first { $0.qid == "Q19820268" } : nil
            secimler.append((ozel ?? ilk, ilk.sl))
        }
        return secimler.sorted { $0.1 > $1.1 }.prefix(4).map { $0.0 }
    }
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

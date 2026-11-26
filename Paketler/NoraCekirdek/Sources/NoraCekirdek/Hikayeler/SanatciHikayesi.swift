// Z4b · Hikâyeler sekmesi (yeni; sitede bu sekme yok). Veri: sanat-atlasi data/sanatci_hikayeleri.json
// (scripts/hikaye_uret.py; @ 1f54a6c). Biçim:
//   {"sanatcilar": {kimlik: {baslik, alt_baslik, giris[], bolumler[{baslik, yillar, paragraflar[], eserler[{qid, bag}]}],
//                            kapanis[], baglantilar[{sanatci, iliski, id?}], kaynaklar[{baslik, adres}], kelime, olusturma}}}
// Kimlik sanatçının kimliğidir (sanatcilar.json `id`). Eserler yalnız katalogdaki (eserler_onbellek) qid'lerle anılır.
import Foundation

/// Bir bölümdeki eser: katalogdaki eserin qid'si ve "Bu dönemle bağı" notu.
public struct HikayeEseri: Equatable, Hashable, Sendable {
    public var qid: String
    public var bag: String

    public init(qid: String, bag: String) {
        self.qid = qid
        self.bag = bag
    }
}

public struct HikayeBolumu: Equatable, Sendable {
    public var baslik: String
    public var yillar: String
    public var paragraflar: [String]
    public var eserler: [HikayeEseri]

    public init(baslik: String, yillar: String, paragraflar: [String], eserler: [HikayeEseri]) {
        self.baslik = baslik
        self.yillar = yillar
        self.paragraflar = paragraflar
        self.eserler = eserler
    }
}

/// Hikâyede anılan başka bir sanatçı. `id` yalnız katalogda olan sanatçıda vardır.
public struct HikayeBaglantisi: Equatable, Sendable {
    public var sanatci: String
    public var iliski: String
    public var id: String?

    public init(sanatci: String, iliski: String, id: String? = nil) {
        self.sanatci = sanatci
        self.iliski = iliski
        self.id = id
    }
}

public struct HikayeKaynagi: Equatable, Sendable {
    /// Alan adı (ör. "britannica.com"); ekranda bu görünür
    public var baslik: String
    public var adres: String

    public init(baslik: String, adres: String) {
        self.baslik = baslik
        self.adres = adres
    }
}

/// Bir sanatçının uzun biçimli hikâyesi.
public struct SanatciHikayesi: Equatable, Sendable, Identifiable {
    /// Sanatçının kimliği
    public var id: String
    public var baslik: String
    public var altBaslik: String
    public var giris: [String]
    public var bolumler: [HikayeBolumu]
    public var kapanis: [String]
    public var baglantilar: [HikayeBaglantisi]
    /// Verideki sırayla (güvenilirliğe göre sıralı)
    public var kaynaklar: [HikayeKaynagi]
    /// Kelime sayısı (okuma süresi)
    public var kelime: Int
    /// "YYYY-AA-GG"
    public var olusturma: String

    public init(id: String, baslik: String, altBaslik: String, giris: [String], bolumler: [HikayeBolumu],
                kapanis: [String], baglantilar: [HikayeBaglantisi] = [], kaynaklar: [HikayeKaynagi] = [],
                kelime: Int = 0, olusturma: String = "") {
        self.id = id
        self.baslik = baslik
        self.altBaslik = altBaslik
        self.giris = giris
        self.bolumler = bolumler
        self.kapanis = kapanis
        self.baglantilar = baglantilar
        self.kaynaklar = kaynaklar
        self.kelime = kelime
        self.olusturma = olusturma
    }

    /// JSON kaydından; başlığı ya da hiç paragrafı olmayan kayıt nil.
    public init?(id: String, json j: JSONDeger) {
        func metinler(_ d: JSONDeger?) -> [String] {
            (d?.dizi ?? []).compactMap { $0.metin?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        guard let baslik = j["baslik"]?.metin?.trimmingCharacters(in: .whitespacesAndNewlines), !baslik.isEmpty else {
            return nil
        }
        let bolumler = (j["bolumler"]?.dizi ?? []).map { b in
            HikayeBolumu(
                baslik: b["baslik"]?.metin ?? "",
                yillar: b["yillar"]?.metin ?? "",
                paragraflar: metinler(b["paragraflar"]),
                eserler: (b["eserler"]?.dizi ?? []).compactMap { e in
                    guard let q = e["qid"]?.doluMetin else { return nil }
                    return HikayeEseri(qid: q, bag: e["bag"]?.metin ?? "")
                })
        }
        let baglantilar = (j["baglantilar"]?.dizi ?? []).compactMap { b -> HikayeBaglantisi? in
            guard let ad = b["sanatci"]?.doluMetin else { return nil }
            return HikayeBaglantisi(sanatci: ad, iliski: b["iliski"]?.metin ?? "", id: b["id"]?.doluMetin)
        }
        let kaynaklar = (j["kaynaklar"]?.dizi ?? []).compactMap { k -> HikayeKaynagi? in
            guard let a = k["adres"]?.doluMetin else { return nil }
            return HikayeKaynagi(baslik: k["baslik"]?.doluMetin ?? HikayeAkisi.alanAdi(a), adres: a)
        }
        self.init(id: id, baslik: baslik, altBaslik: j["alt_baslik"]?.metin ?? "", giris: metinler(j["giris"]),
                  bolumler: bolumler, kapanis: metinler(j["kapanis"]), baglantilar: baglantilar, kaynaklar: kaynaklar,
                  kelime: j["kelime"]?.tamSayi ?? 0, olusturma: j["olusturma"]?.metin ?? "")
        guard !paragraflar.isEmpty else { return nil }
    }

    /// Okunan bütün paragraflar, ekrandaki sırayla: giriş, bölümlerin paragrafları, kapanış. Paragrafın numarası bu
    /// dizideki yeridir (okuma yeri ve dinlemede vurgulanan paragraf bununla anılır).
    public var paragraflar: [String] { giris + bolumler.flatMap(\.paragraflar) + kapanis }

    /// Kapak: ilk bölümün ilk eseri (o bölümde eser yoksa eseri olan ilk bölümün ilki)
    public var kapakQid: String? {
        bolumler.first?.eserler.first?.qid ?? bolumler.lazy.compactMap(\.eserler.first).first?.qid
    }

    /// Okuma ekranının blokları, sırayla. Bölümün `i`. eseri bölümün `i`. paragrafının hemen ardından gelir; paragraftan
    /// fazla eser varsa artanlar bölümün sonunda.
    public var bloklar: [HikayeBlogu] {
        var l: [HikayeBlogu] = []
        var no = 0
        for p in giris {
            l.append(.paragraf(no: no, metin: p))
            no += 1
        }
        // Paragrafı ve eseri olmayan bölüm ekranda yok (Rembrandt'ın verisinde boş bir "Kapanış" bölümü var; başlığı
        // yine de okunur: ses_uret.py öyle kaydetti)
        for (bi, b) in bolumler.enumerated() where !b.paragraflar.isEmpty || !b.eserler.isEmpty {
            l.append(.araBaslik(bolum: bi, baslik: b.baslik, yillar: b.yillar))
            for (pi, p) in b.paragraflar.enumerated() {
                l.append(.paragraf(no: no, metin: p))
                no += 1
                if pi < b.eserler.count { l.append(.eser(bolum: bi, sira: pi, b.eserler[pi])) }
            }
            if b.eserler.count > b.paragraflar.count {
                for (ei, e) in b.eserler.enumerated().dropFirst(b.paragraflar.count) {
                    l.append(.eser(bolum: bi, sira: ei, e))
                }
            }
        }
        if !kapanis.isEmpty {
            l.append(.kapanis)
            for p in kapanis {
                l.append(.paragraf(no: no, metin: p))
                no += 1
            }
        }
        return l
    }

    /// Paragrafın bulunduğu bölümün başlığı (giriş ve kapanışta nil)
    public func bolum(paragraf no: Int) -> Int? {
        var n = giris.count
        guard no >= n else { return nil }
        for (bi, b) in bolumler.enumerated() {
            if no < n + b.paragraflar.count { return bi }
            n += b.paragraflar.count
        }
        return nil
    }
}

/// Okuma ekranında bir blok
public enum HikayeBlogu: Equatable, Sendable {
    /// `no`: `SanatciHikayesi.paragraflar` içindeki yeri
    case paragraf(no: Int, metin: String)
    case araBaslik(bolum: Int, baslik: String, yillar: String)
    case eser(bolum: Int, sira: Int, HikayeEseri)
    /// Kapanış paragraflarının ara başlığı
    case kapanis
}

public enum HikayeVerisi {
    /// Sitenin veri dosyası (K3: siteden iner, önbelleğe alınır)
    public static let dosya = "sanatci_hikayeleri.json"

    /// Bütün hikâyeler, dosyadaki sırayla. Bozuk ya da boş kayıt atlanır; dosya okunamazsa boş.
    public static func coz(_ veri: Data?) -> [SanatciHikayesi] {
        guard let v = veri, let j = try? JSONDeger.coz(v) else { return [] }
        return (j["sanatcilar"]?.nesne?.ciftler ?? []).compactMap { SanatciHikayesi(id: $0.anahtar, json: $0.deger) }
    }
}

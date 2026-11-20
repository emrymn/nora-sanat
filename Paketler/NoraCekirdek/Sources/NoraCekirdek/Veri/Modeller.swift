// Kaynak: sanat-atlasi data/sanatcilar.json, data/akimlar.json, data/konular.json, data/eserler_onbellek.json,
// js/eserler.js (`onbellekEseri`, eser nesnesi), js/gorsel.js (görsel biçimi) @ a866b86 (site 1.90.3)
//
// Çözücüler hoşgörülüdür: beklenmeyen tipteki alan yok sayılır (site de `x || ''` ile okur); tek bozuk alan bütün
// dosyayı düşürmesin.
import Foundation

// MARK: - Görsel

/// Bir eserin görseli: `{ k: 'commons'|'met'|'aic'|'cma'|'nga'|'wikiart', d?, u?, i?, l?, s?, p? }`
public struct Gorsel: Codable, Hashable, Sendable {
    /// Kaynak: commons, met, aic, cma, nga, wikiart
    public var k: String
    /// Commons dosya adı
    public var d: String?
    /// Doğrudan adres
    public var u: String?
    /// IIIF kimliği ya da adresi
    public var i: String?
    /// Lisans
    public var l: String?
    /// Kaynak sayfası
    public var s: String?
    /// Kalite puanı (≤ 5: pekiştirmede kullanılmaz)
    public var p: Double?

    public init(k: String, d: String? = nil, u: String? = nil, i: String? = nil, l: String? = nil, s: String? = nil, p: Double? = nil) {
        self.k = k; self.d = d; self.u = u; self.i = i; self.l = l; self.s = s; self.p = p
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        k = (try? c.decodeIfPresent(String.self, forKey: .k)) ?? ""
        d = try? c.decodeIfPresent(String.self, forKey: .d)
        u = try? c.decodeIfPresent(String.self, forKey: .u)
        i = try? c.decodeIfPresent(String.self, forKey: .i)
        l = try? c.decodeIfPresent(String.self, forKey: .l)
        s = try? c.decodeIfPresent(String.self, forKey: .s)
        p = try? c.decodeIfPresent(Double.self, forKey: .p)
    }
}

// MARK: - Sanatçı

/// data/sanatcilar.json'daki bir sanatçı. `akim` birleşmiş akımın adıdır; birleşmeden önceki ad `birlesen`'de (js/birlesme.js).
public struct Sanatci: Codable, Hashable, Sendable, Identifiable {
    public struct KursEseri: Codable, Hashable, Sendable {
        public var baslik: String
        public var tarih: String?
        public var yer: String?
        public var konu: Int?
        public var commonsDosya: String?
        public var lisans: String?

        enum CodingKeys: String, CodingKey {
            case baslik, tarih, yer, konu, lisans
            case commonsDosya = "commons_dosya"
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            baslik = (try? c.decodeIfPresent(String.self, forKey: .baslik)) ?? ""
            tarih = try? c.decodeIfPresent(String.self, forKey: .tarih)
            yer = try? c.decodeIfPresent(String.self, forKey: .yer)
            konu = try? c.decodeIfPresent(Int.self, forKey: .konu)
            commonsDosya = try? c.decodeIfPresent(String.self, forKey: .commonsDosya)
            lisans = try? c.decodeIfPresent(String.self, forKey: .lisans)
        }
    }

    /// "Önemli eserler" listesindeki kayıt (ek sanatçılar)
    public struct OnemliEser: Codable, Hashable, Sendable {
        public var baslik: String?
        public var tr: String?
        public var yil: String?

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            baslik = try? c.decodeIfPresent(String.self, forKey: .baslik)
            tr = try? c.decodeIfPresent(String.self, forKey: .tr)
            yil = (try? c.decodeIfPresent(String.self, forKey: .yil)) ?? (try? c.decodeIfPresent(Int.self, forKey: .yil)).map(String.init)
        }
    }

    public var id: String
    public var ad: String
    public var akim: String
    /// Akımı uygulamada birleştirildiyse eski akımın adı (Uluslararası Gotik)
    public var birlesen: String?
    public var konu: Int?
    public var konuBaslik: String?
    /// "kurs" ya da "ek"
    public var kaynak: String?
    public var dogum: Int?
    public var olum: Int?
    public var kursNotu: String?
    public var kursNotuKonu: Int?
    public var adArama: String?
    public var kursEserleri: [KursEseri]?
    public var anlatim: String?
    public var taninma: String?
    public var onemliEserler: [OnemliEser]?
    public var eminDegil: [String]?

    enum CodingKeys: String, CodingKey {
        case id, ad, akim, birlesen, konu, kaynak, dogum, olum, anlatim, taninma
        case konuBaslik = "konu_baslik", kursNotu = "kurs_notu", kursNotuKonu = "kurs_notu_konu", adArama = "ad_arama"
        case kursEserleri = "kurs_eserleri", onemliEserler = "onemli_eserler", eminDegil = "emin_degil"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        ad = (try? c.decodeIfPresent(String.self, forKey: .ad)) ?? id
        akim = (try? c.decodeIfPresent(String.self, forKey: .akim)) ?? ""
        birlesen = try? c.decodeIfPresent(String.self, forKey: .birlesen)
        konu = try? c.decodeIfPresent(Int.self, forKey: .konu)
        konuBaslik = try? c.decodeIfPresent(String.self, forKey: .konuBaslik)
        kaynak = try? c.decodeIfPresent(String.self, forKey: .kaynak)
        dogum = try? c.decodeIfPresent(Int.self, forKey: .dogum)
        olum = try? c.decodeIfPresent(Int.self, forKey: .olum)
        kursNotu = try? c.decodeIfPresent(String.self, forKey: .kursNotu)
        kursNotuKonu = try? c.decodeIfPresent(Int.self, forKey: .kursNotuKonu)
        adArama = try? c.decodeIfPresent(String.self, forKey: .adArama)
        kursEserleri = try? c.decodeIfPresent([KursEseri].self, forKey: .kursEserleri)
        anlatim = try? c.decodeIfPresent(String.self, forKey: .anlatim)
        taninma = try? c.decodeIfPresent(String.self, forKey: .taninma)
        onemliEserler = try? c.decodeIfPresent([OnemliEser].self, forKey: .onemliEserler)
        eminDegil = try? c.decodeIfPresent([String].self, forKey: .eminDegil)
    }

    /// "1445–1510", "MÖ 480–430" (js/yardimci.js `yillarYaz`)
    public var yillar: String { Yardimci.yillarYaz(dogum: dogum, olum: olum) }
}

// MARK: - Akım ve konu

/// data/akimlar.json'daki bir akım (birleşmeden sonra: komşu adları hedef akıma döner)
public struct Akim: Codable, Hashable, Sendable, Identifiable {
    public var ad: String
    public var sira: Double
    public var komsular: [String]
    /// "#B0643C"
    public var renk: String?
    public var id: String { ad }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ad = try c.decode(String.self, forKey: .ad)
        sira = (try? c.decodeIfPresent(Double.self, forKey: .sira)) ?? .nan
        komsular = (try? c.decodeIfPresent([String].self, forKey: .komsular)) ?? []
        renk = try? c.decodeIfPresent(String.self, forKey: .renk)
    }
}

/// data/konular.json: kursun bir dersi
public struct Konu: Codable, Hashable, Sendable, Identifiable {
    public var no: Int
    public var baslik: String
    public var bolum: String?
    public var bolumAd: String?
    public var id: Int { no }

    enum CodingKeys: String, CodingKey {
        case no, baslik, bolum
        case bolumAd = "bolum_ad"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        no = try c.decode(Int.self, forKey: .no)
        baslik = (try? c.decodeIfPresent(String.self, forKey: .baslik)) ?? ""
        bolum = try? c.decodeIfPresent(String.self, forKey: .bolum)
        bolumAd = try? c.decodeIfPresent(String.self, forKey: .bolumAd)
    }
}

// MARK: - Eser

/// Uygulamanın eser nesnesi (js/eserler.js `onbellekEseri` + `sanatciEserleri`'nin eklediği alanlar).
public struct Eser: Codable, Hashable, Sendable, Identifiable {
    /// "q:QID", "c:<küçük harfli Commons dosyası>" ya da "<kaynak>:<kimlik>"; ilerleme (kotuler, koleksiyon) bunu anar
    public var anahtar: String
    /// Sanatçı kimliği
    public var sid: String
    /// "kurs", "wikidata", "met", …
    public var kaynak: String
    public var kaynaklar: [String]
    /// Özgün başlık (notlar ve eşleştirme bunu kullanır)
    public var baslik: String
    /// Türkçe ad (data/eser_adlari_tr.json; özgün başlıktan farklıysa)
    public var ad: String?
    public var tarih: String
    public var yil: Int?
    public var muze: String
    public var kursKonu: Int?
    public var qid: String?
    /// En iyisi önce
    public var gorseller: [Gorsel]
    public var pekistirme: Bool
    /// Bilinirlik sırası
    public var sl: Int
    /// Aynı eserin atfedildiği öteki sanatçılar (İş 174)
    public var ortak: [String]
    public var ortakAdlar: [String]

    public var id: String { anahtar }

    /// Ekranda gösterilen ad: Türkçe ad varsa o, yoksa özgün başlık (js/eserler.js `eserBaslik`)
    public var gosterilenBaslik: String { Yardimci.notTemizle(JS.dolu(ad) ?? baslik) }

    public init(anahtar: String, sid: String = "", kaynak: String, kaynaklar: [String], baslik: String, ad: String? = nil,
                tarih: String, yil: Int?, muze: String, kursKonu: Int?, qid: String?, gorseller: [Gorsel],
                pekistirme: Bool = true, sl: Int = 0, ortak: [String] = [], ortakAdlar: [String] = []) {
        self.anahtar = anahtar; self.sid = sid; self.kaynak = kaynak; self.kaynaklar = kaynaklar; self.baslik = baslik
        self.ad = ad; self.tarih = tarih; self.yil = yil; self.muze = muze; self.kursKonu = kursKonu; self.qid = qid
        self.gorseller = gorseller; self.pekistirme = pekistirme; self.sl = sl; self.ortak = ortak; self.ortakAdlar = ortakAdlar
    }
}

// MARK: - Önbellek dosyası (data/eserler_onbellek.json, surum ≥ 3)

struct OnbellekDosyasi: Decodable {
    struct Kayit: Decodable {
        var qid: String?
        var eserler: [HamEser]?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            qid = try? c.decodeIfPresent(String.self, forKey: .qid)
            eserler = try? c.decodeIfPresent([HamEser].self, forKey: .eserler)
        }
        enum CodingKeys: String, CodingKey { case qid, eserler }
    }

    struct HamEser: Decodable {
        var baslik: String
        var yil: Int?
        var muze: String?
        var qid: String?
        var kaynaklar: [String]
        var sl: Int?
        var kurs: Bool?
        var konu: Int?
        var tarih: String?
        var pekistirme: Bool?
        var gorseller: [Gorsel]

        enum CodingKeys: String, CodingKey { case baslik, yil, muze, qid, kaynaklar, sl, kurs, konu, tarih, pekistirme, gorseller }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            baslik = (try? c.decodeIfPresent(String.self, forKey: .baslik)) ?? ""
            yil = try? c.decodeIfPresent(Int.self, forKey: .yil)
            muze = try? c.decodeIfPresent(String.self, forKey: .muze)
            qid = try? c.decodeIfPresent(String.self, forKey: .qid)
            kaynaklar = (try? c.decodeIfPresent([String].self, forKey: .kaynaklar)) ?? []
            sl = try? c.decodeIfPresent(Int.self, forKey: .sl)
            kurs = try? c.decodeIfPresent(Bool.self, forKey: .kurs)
            konu = try? c.decodeIfPresent(Int.self, forKey: .konu)
            tarih = try? c.decodeIfPresent(String.self, forKey: .tarih)
            pekistirme = try? c.decodeIfPresent(Bool.self, forKey: .pekistirme)
            gorseller = (try? c.decodeIfPresent([Gorsel].self, forKey: .gorseller)) ?? []
        }
    }

    var surum: Int
    var olusturma: String?
    var sanatcilar: [String: Kayit]

    enum CodingKeys: String, CodingKey { case surum, olusturma, sanatcilar }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        surum = (try? c.decodeIfPresent(Int.self, forKey: .surum)) ?? 0
        olusturma = try? c.decodeIfPresent(String.self, forKey: .olusturma)
        sanatcilar = (try? c.decodeIfPresent([String: Kayit].self, forKey: .sanatcilar)) ?? [:]
    }
}

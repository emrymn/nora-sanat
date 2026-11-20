// Kaynak: sanat-atlasi data/*.json biçimleri, js/eserler.js onbellekEseri @ a866b86 (site 1.90.3)
import Foundation

/// Bir eser görseli. Biçim (js/gorsel.js başı):
/// `{ k: 'commons'|'met'|'aic'|'cma'|'nga'|'wikiart', d?: Commons dosyası, u?: doğrudan URL, i?: IIIF kimliği/adresi,
///    l?: lisans, s?: kaynak sayfası, p?: kalite puanı }`
public struct Gorsel: Equatable, Hashable, Sendable, Codable {
    public var k: String
    public var d: String?
    public var u: String?
    public var i: String?
    public var l: String?
    public var s: String?
    public var p: Double?

    public init(k: String, d: String? = nil, u: String? = nil, i: String? = nil, l: String? = nil, s: String? = nil, p: Double? = nil) {
        self.k = k; self.d = d; self.u = u; self.i = i; self.l = l; self.s = s; self.p = p
    }

    init(json j: JSONDeger) {
        self.init(k: j["k"]?.metin ?? "", d: j["d"]?.metin, u: j["u"]?.metin, i: j["i"]?.metin,
                  l: j["l"]?.metin, s: j["s"]?.metin, p: j["p"]?.sayi)
    }

    /// `gorselAnahtari`: kullanıcının "kötü" işaretleri bu anahtarla tutulur
    public var anahtar: String {
        if k == "commons" { return "c:" + SiteYazisi.dosyaNormal(d).lowercased() }
        return "\(k):\(dolu(i) ?? u ?? "undefined")"
    }

    /// `yerelAnahtar`: data/yerel_gorseller.json'daki anahtar
    public var yerelAnahtar: String { "\(k):\(dolu(d) ?? dolu(i) ?? dolu(u) ?? "")" }

    /// `eserler.js cikarAnahtari`
    var cikarAnahtari: String {
        (k == "commons" ? SiteYazisi.dosyaNormal(d).lowercased() : "\(k):\(dolu(d) ?? dolu(i) ?? dolu(u) ?? "")")
            .precomposedStringWithCanonicalMapping
    }
}

@inline(__always) func dolu(_ s: String?) -> String? { s.flatMap { $0.isEmpty ? nil : $0 } }

/// Uygulamanın eser nesnesi (js/eserler.js `onbellekEseri` + `sanatciEserleri`'nin eklediği alanlar)
public struct Eser: Equatable, Hashable, Sendable, Codable, Identifiable {
    /// "q:QID" ya da "c:<küçük harfli Commons dosyası>" ya da "<kaynak>:<kimlik>"
    public var anahtar: String
    public var kaynak: String
    public var kaynaklar: [String]
    /// Özgün başlık (notlar ve eşleştirme bunu kullanır)
    public var baslik: String
    public var tarih: String
    public var yil: Int?
    public var muze: String
    public var kursKonu: Int?
    public var qid: String?
    public var gorseller: [Gorsel]
    public var pekistirme: Bool
    /// Bilinirlik sırası
    public var sl: Int
    /// Sanatçı kimliği
    public var sid: String = ""
    /// Aynı eserin atfedildiği öteki sanatçılar (İş 174)
    public var ortak: [String] = []
    public var ortakAdlar: [String] = []
    /// Türkçe ad (data/eser_adlari_tr.json); özgün başlıktan farklıysa
    public var ad: String?

    public var id: String { anahtar }

    /// `eserBaslik`: ekranda gösterilecek ad
    public var gorunenAd: String { SiteYazisi.notTemizle(dolu(ad) ?? baslik) }

    public init(anahtar: String, kaynak: String, kaynaklar: [String], baslik: String, tarih: String, yil: Int?,
                muze: String, kursKonu: Int?, qid: String?, gorseller: [Gorsel], pekistirme: Bool, sl: Int) {
        self.anahtar = anahtar; self.kaynak = kaynak; self.kaynaklar = kaynaklar; self.baslik = baslik
        self.tarih = tarih; self.yil = yil; self.muze = muze; self.kursKonu = kursKonu; self.qid = qid
        self.gorseller = gorseller; self.pekistirme = pekistirme; self.sl = sl
    }

    /// `onbellekEseri(e)`: data/eserler_onbellek.json kaydından
    init?(onbellek e: JSONDeger) {
        let gorseller = (e["gorseller"]?.dizi ?? []).map(Gorsel.init(json:))
        guard let ilk = gorseller.first else { return nil }
        let kurs = e["kurs"]?.dogru ?? false
        let qid = e["qid"]?.doluMetin
        anahtar = kurs ? ilk.anahtar : qid.map { "q:" + $0 } ?? ilk.anahtar
        kaynaklar = (e["kaynaklar"]?.dizi ?? []).map(\.jsMetni)
        kaynak = kurs ? "kurs" : (kaynaklar.first ?? "undefined")
        baslik = e["baslik"]?.metin ?? ""
        yil = e["yil"]?.tamSayi
        let t = SiteYazisi.notTemizle(e["tarih"]?.metin)
        tarih = t.isEmpty ? SiteYazisi.tarihYaz(yil) : t
        muze = SiteYazisi.notTemizle(e["muze"]?.metin ?? "")
        kursKonu = e["konu"]?.tamSayi
        self.qid = qid
        self.gorseller = gorseller
        pekistirme = e["pekistirme"] != .mantik(false)
        sl = e["sl"]?.tamSayi ?? 0
    }
}

/// `data/sanatcilar.json`'daki kurs eseri
public struct KursEseri: Equatable, Hashable, Sendable, Codable {
    public var baslik: String
    public var tarih: String
    public var yer: String
    public var konu: Int?
    public var commonsDosya: String
    public var lisans: String
    /// Sanatçının listesindeki yeri (sitede nesne kimliği karşılaştırması bunun yerine geçer)
    public var sira: Int

    init(json j: JSONDeger, sira: Int) {
        baslik = j["baslik"]?.metin ?? ""
        tarih = j["tarih"]?.metin ?? ""
        yer = j["yer"]?.metin ?? ""
        konu = j["konu"]?.tamSayi
        commonsDosya = j["commons_dosya"]?.metin ?? ""
        lisans = j["lisans"]?.metin ?? ""
        self.sira = sira
    }
}

/// `data/sanatcilar.json` kaydı (birleşmeden sonra: `akim` hedef akım, `birlesen` eski akım)
public struct Sanatci: Equatable, Hashable, Sendable, Identifiable {
    public var id: String
    public var ad: String
    public var akim: String
    /// Uygulamada birleştirilen akımın eski adı (js/birlesme.js)
    public var birlesen: String?
    public var konu: Int?
    public var konuBaslik: String?
    public var kaynak: String?
    public var dogum: Int?
    public var olum: Int?
    public var adArama: String?
    public var kursNotu: String?
    public var kursNotuKonu: Int?
    public var anlatim: String?
    public var taninma: String?
    public var kursEserleri: [KursEseri]
    /// Bütün kayıt (modelde olmayan alanlar için)
    public var ham: JSONDeger

    init(json j: JSONDeger) {
        id = j["id"]?.metin ?? ""
        ad = j["ad"]?.metin ?? ""
        akim = j["akim"]?.metin ?? ""
        konu = j["konu"]?.tamSayi
        konuBaslik = j["konu_baslik"]?.metin
        kaynak = j["kaynak"]?.metin
        dogum = j["dogum"]?.tamSayi
        olum = j["olum"]?.tamSayi
        adArama = j["ad_arama"]?.metin
        kursNotu = j["kurs_notu"]?.metin
        kursNotuKonu = j["kurs_notu_konu"]?.tamSayi
        anlatim = j["anlatim"]?.metin
        taninma = j["taninma"]?.metin
        kursEserleri = (j["kurs_eserleri"]?.dizi ?? []).enumerated().map { KursEseri(json: $1, sira: $0) }
        ham = j
    }

    /// `yillarYaz(s)`
    public var yillar: String { SiteYazisi.yillarYaz(dogum: dogum, olum: olum) }

    public static func == (a: Sanatci, b: Sanatci) -> Bool { a.id == b.id && a.akim == b.akim && a.ham == b.ham }
    public func hash(into h: inout Hasher) { h.combine(id) }
}

/// `data/akimlar.json` kaydı (birleşmeden sonra)
public struct Akim: Equatable, Hashable, Sendable, Codable, Identifiable {
    public var ad: String
    public var sira: Double
    public var komsular: [String]
    public var renk: String
    public var id: String { ad }

    init(json j: JSONDeger) {
        ad = j["ad"]?.metin ?? ""
        sira = j["sira"]?.sayi ?? 0
        komsular = (j["komsular"]?.dizi ?? []).compactMap(\.metin)
        renk = j["renk"]?.metin ?? ""
    }
}

/// `js/kurs.js konuKapagi` sonucu
public struct KonuKapagi: Equatable, Hashable, Sendable, Codable {
    public var sanatci: String
    public var dosya: String?
    public var baslik: String?
    public var resimDegil: Bool?
}

/// `data/konular.json` kaydı; kurs konularında kapak da dolu
public struct Konu: Equatable, Hashable, Sendable, Codable, Identifiable {
    public var no: Int
    public var baslik: String
    public var bolum: String
    public var bolumAd: String
    public var kapak: KonuKapagi?
    public var id: Int { no }

    init(json j: JSONDeger) {
        no = j["no"]?.tamSayi ?? 0
        baslik = j["baslik"]?.metin ?? ""
        bolum = j["bolum"]?.metin ?? ""
        bolumAd = j["bolum_ad"]?.metin ?? ""
    }
}

// Z4h · Hikâyeler'e "Diziler" rafı. Veri: sanat-atlasi data/diziler.json (biçim: diziler/PLAN.md @ 57257c3).
// Biçim:
//   { "surum": 1,
//     "diziler": [ { "id": "dueller", "ad": "Düellolar", "aciklama": "…", "bolumler": ["dueller-...", …] } ],
//     "bolumler": { "<bolum-id>": { "dizi": "dueller", "baslik": "", "alt_baslik": "",
//                                   "sanatcilar": ["leonardo-da-vinci", "michelangelo"],
//                                   "giris": [], "bolumler": [{ "baslik": "", "yillar": "", "paragraflar": [],
//                                                               "eserler": [{ "sanatci": "", "qid"|"commons": "", "bag": "" }] }],
//                                   "kapanis": [], "kaynaklar": [{ "baslik": "", "adres": "" }],
//                                   "kelime": 0, "olusturma": "YYYY-MM-DD" } } }
import Foundation

/// Bir dizi (ör. "Düellolar"): ad, açıklama ve sıralı bölüm kimlikleri.
public struct Dizi: Equatable, Hashable, Sendable, Identifiable {
    public var id: String
    public var ad: String
    public var aciklama: String
    /// Dizideki geçerli bölümlerin kimlikleri, sırayla
    public var bolumIds: [String]

    public init(id: String, ad: String, aciklama: String, bolumIds: [String]) {
        self.id = id
        self.ad = ad
        self.aciklama = aciklama
        self.bolumIds = bolumIds
    }
}

/// Bir dizinin bölümü: `SanatciHikayesi` ile aynı metin/blok/ses yapısını taşır (`hikaye`),
/// böylece mevcut `HikayeOkuma` ve `HikayeCalari` ile doğrudan açılır.
public struct DiziBolumu: Equatable, Sendable, Identifiable {
    public var id: String
    public var dizi: String
    /// Dizi içindeki 1 tabanlı bölüm numarası (1, 2, 3…)
    public var sira: Int
    public var hikaye: SanatciHikayesi

    public init(id: String, dizi: String, sira: Int, hikaye: SanatciHikayesi) {
        self.id = id
        self.dizi = dizi
        self.sira = sira
        var h = hikaye
        h.dizi = dizi
        h.bolumSirasi = sira
        self.hikaye = h
    }

    public var baslik: String { hikaye.baslik }
    public var altBaslik: String { hikaye.altBaslik }
    public var sanatcilar: [String] { hikaye.sanatcilar }
    public var kelime: Int { hikaye.kelime }
    public var olusturma: String { hikaye.olusturma }
    public var paragraflar: [String] { hikaye.paragraflar }
    public var kapakEseri: HikayeEseri? { hikaye.kapakEseri }
}

/// `data/diziler.json` dosyasının ayrıştırılmış hâli.
public struct DiziKatalogu: Equatable, Sendable {
    public var surum: Int
    /// Dosyadaki sırayla geçerli diziler (en az bir geçerli bölümü olanlar)
    public var diziler: [Dizi]
    /// Bölüm kimliği → bölüm kaydı
    public var bolumler: [String: DiziBolumu]

    public init(surum: Int = 1, diziler: [Dizi] = [], bolumler: [String: DiziBolumu] = [:]) {
        self.surum = surum
        self.diziler = diziler
        self.bolumler = bolumler
    }

    public static let bos = DiziKatalogu()
    public var bosMu: Bool { diziler.isEmpty }

    public func dizi(_ id: String) -> Dizi? { diziler.first { $0.id == id } }
    public func bolum(_ id: String) -> DiziBolumu? { bolumler[id] }

    /// Dizinin bölümleri, tanımlanan sırayla
    public func bolumleri(_ diziId: String) -> [DiziBolumu] {
        guard let d = dizi(diziId) else { return [] }
        return d.bolumIds.compactMap { bolumler[$0] }
    }

    /// Tüm dizilerdeki bütün bölümler, dizi ve bölüm sırasıyla
    public var tumBolumler: [DiziBolumu] {
        diziler.flatMap { d in d.bolumIds.compactMap { bolumler[$0] } }
    }
}

public enum DiziVerisi {
    /// Sitenin veri dosyası (K3: `SiteVerisi` ile iner ve önbelleğe alınır)
    public static let dosya = "diziler.json"

    /// `data/diziler.json` ayrıştırıcısı. Bozuk bölüm ya da boş dizi atlanır; dosya okunamazsa `.bos`.
    public static func coz(_ veri: Data?) -> DiziKatalogu {
        guard let v = veri, let j = try? JSONDeger.coz(v) else { return .bos }
        let surum = j["surum"]?.tamSayi ?? 1

        var hamBolumler: [String: (dizi: String, hikaye: SanatciHikayesi)] = [:]
        for (bid, bj) in j["bolumler"]?.nesne?.ciftler ?? [] {
            guard !bid.isEmpty, let h = bolumCoz(id: bid, json: bj) else { continue }
            hamBolumler[bid] = (bj["dizi"]?.doluMetin ?? "", h)
        }

        var diziler: [Dizi] = []
        var bolumler: [String: DiziBolumu] = [:]
        var gorulenDiziler = Set<String>()

        for dj in j["diziler"]?.dizi ?? [] {
            guard let did = dj["id"]?.doluMetin,
                  let ad = dj["ad"]?.metin?.trimmingCharacters(in: .whitespacesAndNewlines), !ad.isEmpty,
                  gorulenDiziler.insert(did).inserted
            else { continue }
            let aciklama = dj["aciklama"]?.metin?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            var gecerliIds: [String] = []
            var gorulenBolum = Set<String>()
            for rawId in (dj["bolumler"]?.dizi ?? []).compactMap(\.doluMetin) {
                guard gorulenBolum.insert(rawId).inserted, let kayit = hamBolumler[rawId] else { continue }
                let sira = gecerliIds.count + 1
                var h = kayit.hikaye
                h.dizi = did
                h.bolumSirasi = sira
                bolumler[rawId] = DiziBolumu(id: rawId, dizi: did, sira: sira, hikaye: h)
                gecerliIds.append(rawId)
            }
            guard !gecerliIds.isEmpty else { continue }
            diziler.append(Dizi(id: did, ad: ad, aciklama: aciklama, bolumIds: gecerliIds))
        }

        return DiziKatalogu(surum: surum, diziler: diziler, bolumler: bolumler)
    }

    private static func bolumCoz(id: String, json j: JSONDeger) -> SanatciHikayesi? {
        func metinler(_ d: JSONDeger?) -> [String] {
            (d?.dizi ?? []).compactMap { $0.metin?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        guard let baslik = j["baslik"]?.metin?.trimmingCharacters(in: .whitespacesAndNewlines), !baslik.isEmpty else {
            return nil
        }
        let sanatcilar = (j["sanatcilar"]?.dizi ?? []).compactMap(\.doluMetin)
        let bolumler = (j["bolumler"]?.dizi ?? []).map { b in
            HikayeBolumu(
                baslik: b["baslik"]?.metin ?? "",
                yillar: b["yillar"]?.metin ?? "",
                paragraflar: metinler(b["paragraflar"]),
                eserler: (b["eserler"]?.dizi ?? []).compactMap { e -> HikayeEseri? in
                    let q = e["qid"]?.doluMetin ?? ""
                    let c = e["commons"]?.doluMetin
                    guard !q.isEmpty || c != nil else { return nil }
                    return HikayeEseri(qid: q, bag: e["bag"]?.metin ?? "", sanatci: e["sanatci"]?.doluMetin, commons: c)
                })
        }
        let kaynaklar = (j["kaynaklar"]?.dizi ?? []).compactMap { k -> HikayeKaynagi? in
            guard let a = k["adres"]?.doluMetin else { return nil }
            return HikayeKaynagi(baslik: k["baslik"]?.doluMetin ?? HikayeAkisi.alanAdi(a), adres: a)
        }
        let giris = metinler(j["giris"])
        let kapanis = metinler(j["kapanis"])
        let paragrafToplami = giris + bolumler.flatMap(\.paragraflar) + kapanis
        guard !paragrafToplami.isEmpty else { return nil }
        let verilenKelime = j["kelime"]?.tamSayi ?? 0
        let kelime = verilenKelime > 0
            ? verilenKelime
            : paragrafToplami.reduce(0) { $0 + $1.split(whereSeparator: \.isWhitespace).count }
        return SanatciHikayesi(
            id: id,
            baslik: baslik,
            altBaslik: j["alt_baslik"]?.metin ?? "",
            giris: giris,
            bolumler: bolumler,
            kapanis: kapanis,
            baglantilar: [],
            kaynaklar: kaynaklar,
            kelime: kelime,
            olusturma: j["olusturma"]?.metin ?? "",
            dizi: j["dizi"]?.doluMetin,
            sanatcilar: sanatcilar
        )
    }
}

/// Bir dizinin genel okunma/dinlenme durumu
public struct DiziIlerleme: Equatable, Sendable {
    public var okunan: Int
    public var yarim: Int
    public var toplam: Int
    /// 0…1 (tüm bölümlerin ortalama ilerlemesi)
    public var oran: Double

    public init(okunan: Int, yarim: Int, toplam: Int, oran: Double) {
        self.okunan = okunan
        self.yarim = yarim
        self.toplam = toplam
        self.oran = oran
    }

    public var bitti: Bool { toplam > 0 && okunan == toplam }
    public var baslandi: Bool { okunan > 0 || yarim > 0 }
}

public enum DiziKurallari {
    /// Bir bölümün okundu/dinlendi durumu
    public enum BolumDurumu: Equatable, Sendable {
        case okunmadi
        case yarim(kalanDk: Int, dinleme: Bool)
        case okundu
    }

    /// Dizinin ilerleme özeti (kaç bölüm okundu, kaçı yarım, toplam oran)
    public static func ilerleme(_ dizi: Dizi, katalog: DiziKatalogu, yerler: [String: OkumaYeri]) -> DiziIlerleme {
        let l = katalog.bolumleri(dizi.id)
        guard !l.isEmpty else { return DiziIlerleme(okunan: 0, yarim: 0, toplam: 0, oran: 0) }
        var okunan = 0
        var yarim = 0
        var toplamOran = 0.0
        for b in l {
            if let y = yerler[b.id] {
                if y.bitti {
                    okunan += 1
                    toplamOran += 1
                } else if y.yarim {
                    yarim += 1
                    toplamOran += y.oran
                }
            }
        }
        return DiziIlerleme(okunan: okunan, yarim: yarim, toplam: l.count, oran: toplamOran / Double(l.count))
    }

    /// Tek bir bölümün durumu
    public static func bolumDurumu(_ b: DiziBolumu, yer: OkumaYeri?) -> BolumDurumu {
        guard let y = yer else { return .okunmadi }
        if y.bitti { return .okundu }
        if y.yarim {
            let dk = HikayeAkisi.kalanDakika(okuma: HikayeAkisi.okumaDakikasi(kelime: b.kelime), yer: y)
            return .yarim(kalanDk: dk, dinleme: (y.parca ?? 0) > 0)
        }
        return .okunmadi
    }

    /// Raf sıralaması: yarım kalmış (başlanıp bitmemiş) diziler en başta (en son dokunulan önce),
    /// ardından hiç başlanmamışlar dosya sırasıyla, en sonda tüm bölümleri bitenler dosya sırasıyla.
    public static func sirala(_ katalog: DiziKatalogu, yerler: [String: OkumaYeri]) -> [Dizi] {
        var yarimlar: [(dizi: Dizi, tarih: Date, sira: Int)] = []
        var yeniler: [Dizi] = []
        var bitenler: [Dizi] = []

        for (i, d) in katalog.diziler.enumerated() {
            let il = ilerleme(d, katalog: katalog, yerler: yerler)
            if il.bitti {
                bitenler.append(d)
            } else if il.baslandi {
                let sonTarih = d.bolumIds.compactMap { yerler[$0]?.tarih }.max() ?? .distantPast
                yarimlar.append((d, sonTarih, i))
            } else {
                yeniler.append(d)
            }
        }
        yarimlar.sort { $0.tarih != $1.tarih ? $0.tarih > $1.tarih : $0.sira < $1.sira }
        return yarimlar.map(\.dizi) + yeniler + bitenler
    }

    /// Kapak kolajı için dizinin bölümlerinden en çok `enCok` tekil eser seçer:
    /// önce her bölümün ilk eserini (sırayla, aynı görsel tekrar etmeden), yetmezse bölümlerin sonraki eserlerini alır.
    public static func kapakEserleri(_ dizi: Dizi, katalog: DiziKatalogu, enCok: Int = 3) -> [HikayeEseri] {
        guard enCok > 0 else { return [] }
        let bolumListesi = katalog.bolumleri(dizi.id)
        let havuzlar: [[HikayeEseri]] = bolumListesi.map { b in
            b.hikaye.bolumler.flatMap(\.eserler)
        }
        let maxUzunluk = havuzlar.map(\.count).max() ?? 0
        var sonuc: [HikayeEseri] = []
        var gorulen = Set<String>()

        for tur in 0..<maxUzunluk {
            for eserler in havuzlar where tur < eserler.count {
                let e = eserler[tur]
                let k = e.kimlik
                guard !k.isEmpty, gorulen.insert(k).inserted else { continue }
                sonuc.append(e)
                if sonuc.count == enCok { return sonuc }
            }
        }
        return sonuc
    }

    /// Dizide açılacak sıradaki bölüm: yarım kalan varsa en son dokunulan, yoksa henüz okunmamış ilk bölüm,
    /// hepsi bittiyse ilk bölüm.
    public static func siradakiBolum(_ dizi: Dizi, katalog: DiziKatalogu, yerler: [String: OkumaYeri]) -> DiziBolumu? {
        let l = katalog.bolumleri(dizi.id)
        if let yarim = l.filter({ yerler[$0.id]?.yarim == true })
            .max(by: { (yerler[$0.id]?.tarih ?? .distantPast) < (yerler[$1.id]?.tarih ?? .distantPast) }) {
            return yarim
        }
        if let okunmamis = l.first(where: { yerler[$0.id]?.bitti != true }) {
            return okunmamis
        }
        return l.first
    }

    /// Çalar ve okuma sonu için: aynı dizide şimdikinden sonra gelen bitirilmemiş bölümler.
    public static func siradaki(_ katalog: DiziKatalogu, diziId: String, simdikiBolumId: String,
                                yerler: [String: OkumaYeri], enCok: Int = 2) -> [DiziBolumu] {
        let l = katalog.bolumleri(diziId)
        guard let i = l.firstIndex(where: { $0.id == simdikiBolumId }) else {
            return Array(l.filter { yerler[$0.id]?.bitti != true }.prefix(enCok))
        }
        let sonrakiler = l[(i + 1)...].filter { yerler[$0.id]?.bitti != true }
        return Array(sonrakiler.prefix(enCok))
    }

    /// Dizinin toplam tahmini okuma süresi (dakika)
    public static func toplamOkumaDakikasi(_ dizi: Dizi, katalog: DiziKatalogu) -> Int {
        katalog.bolumleri(dizi.id).reduce(0) { $0 + HikayeAkisi.okumaDakikasi(kelime: $1.kelime) }
    }

    /// Dizinin zemin dönemi için ilk sanatçı kimliği
    public static func donemSanatcisi(_ dizi: Dizi, katalog: DiziKatalogu) -> String? {
        katalog.bolumleri(dizi.id).lazy.flatMap(\.sanatcilar).first
    }

    /// Dizi bölümlerinde arama: bölüm başlığı, alt başlık, dizi adı ya da sanatçı adlarında
    public static func ara(_ katalog: DiziKatalogu, sorgu: String, sanatciAdi: (String) -> String) -> [DiziBolumu] {
        let q = HikayeAkisi.sade(sorgu)
        guard !q.isEmpty else { return [] }
        return katalog.tumBolumler.filter { b in
            if HikayeAkisi.sade(b.baslik).contains(q) || HikayeAkisi.sade(b.altBaslik).contains(q) { return true }
            if let d = katalog.dizi(b.dizi), HikayeAkisi.sade(d.ad).contains(q) { return true }
            return b.sanatcilar.contains { HikayeAkisi.sade(sanatciAdi($0)).contains(q) || HikayeAkisi.sade($0).contains(q) }
        }
    }

    /// Wikimedia Commons dosya adından `Eser` üretir (katalog/kurs eserinde yoksa yedek künye için).
    public static func commonsEseri(dosya: String, sanatci sid: String, kurs: KursEseri? = nil) -> Eser {
        let norm = SiteYazisi.dosyaNormal(dosya)
        let g = Gorsel(k: "commons", d: norm, l: kurs?.lisans)
        let baslik: String
        let tarih: String
        let muze: String
        if let kurs {
            baslik = SiteYazisi.notTemizle(kurs.baslik)
            tarih = SiteYazisi.notTemizle(kurs.tarih)
            muze = SiteYazisi.notTemizle(kurs.yer)
        } else {
            let uzantisiz = norm.replacingOccurrences(of: "\\.[a-zA-Z0-9]+$", with: "", options: .regularExpression)
            baslik = uzantisiz.replacingOccurrences(of: "_", with: " ")
            tarih = ""
            muze = ""
        }
        var e = Eser(
            anahtar: "c:" + norm.lowercased(),
            kaynak: "kurs",
            kaynaklar: ["kurs"],
            baslik: baslik,
            tarih: tarih,
            yil: nil,
            muze: muze,
            kursKonu: kurs?.konu,
            qid: nil,
            gorseller: [g],
            pekistirme: false,
            sl: 0
        )
        e.sid = sid
        return e
    }
}

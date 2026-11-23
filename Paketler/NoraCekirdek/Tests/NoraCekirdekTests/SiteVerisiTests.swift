import Foundation
import XCTest
@testable import NoraCekirdek

/// T1 kâhini: beklenen değerler canlı siteden (sanat-atlasi.pages.dev) sitenin kendi modülleriyle alındı
/// (Testler/kahin/site_verisi.mjs). Veri dosyaları da aynı anda alınıp Ornekler/site_verisi/'ne kondu.
final class SiteVerisiTests: XCTestCase {
    struct Cevaplar: Decodable {
        struct AkimC: Decodable { let ad: String; let sira: Double; let komsular: [String]; let renk: String }
        struct KonuC: Decodable { let no: Int; let kapak: KonuKapagi }
        struct EserC: Decodable {
            let anahtar, baslik, ad, tarih, muze, kaynak: String
            let yil: Int?
            let kaynaklar: [String]
            let kursKonu: Int?
            let qid: String?
            let sl: Int
            let pekistirme: Bool
            let ortak: [String]
            let gorselSayisi: Int
            let g400, g1280, devasa, ust, ustBuyuk: String
            let oran: Double?
            let uygun: Bool
        }
        struct UzakC: Decodable {
            let g: Gorsel
            let u330, u400, u800, u1280, u2000, yedek: String
        }
        let surum: String
        let tumSanatcilar: [[String?]]
        let sanatcilar: [String]
        let akimlar: [AkimC]
        let kursKonulari: [KonuC]
        let bilinenAdlar: [String: AdParcalari]
        let eserler: [String: [EserC]]
        let uzaklar: [UzakC]
    }

    static func dosya(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/site_verisi/\(ad)", withExtension: nil))
        return try Data(contentsOf: url)
    }

    static let hazir: (Cevaplar, SiteKatalogu)? = {
        guard let c = try? JSONDecoder().decode(Cevaplar.self, from: dosya("cevaplar.json")) else { return nil }
        var d: [String: Data] = [:]
        for f in SiteVerisi.katalogDosyalari { d[f] = try? dosya(f) }
        guard let k = try? SiteKatalogu(dosyalar: d) else { return nil }
        return (c, k)
    }()

    func hazirla() throws -> (Cevaplar, SiteKatalogu) { try XCTUnwrap(Self.hazir, "örnekler okunamadı") }

    func testSanatciVeAkimListeleri() throws {
        let (c, k) = try hazirla()
        XCTAssertEqual(k.tumSanatcilar.map(\.id), c.tumSanatcilar.map { $0[0] ?? "" })
        XCTAssertEqual(k.tumSanatcilar.map(\.akim), c.tumSanatcilar.map { $0[1] ?? "" })
        XCTAssertEqual(k.tumSanatcilar.map(\.birlesen), c.tumSanatcilar.map { $0[2] })
        XCTAssertEqual(k.sanatcilar.map(\.id), c.sanatcilar)
        XCTAssertEqual(k.akimlar.map(\.ad), c.akimlar.map(\.ad))
        XCTAssertEqual(k.akimlar.map(\.komsular), c.akimlar.map(\.komsular))
        XCTAssertEqual(k.akimlar.map(\.sira), c.akimlar.map(\.sira))
        XCTAssertEqual(k.akimlar.map(\.renk), c.akimlar.map(\.renk))
        XCTAssertGreaterThan(c.sanatcilar.count, 100)
    }

    func testKursKonulari() throws {
        let (c, k) = try hazirla()
        XCTAssertEqual(k.kursKonulari.map(\.no), c.kursKonulari.map(\.no))
        for (a, b) in zip(k.kursKonulari, c.kursKonulari) { XCTAssertEqual(a.kapak, b.kapak, "konu \(a.no)") }
    }

    func testBilinenAdlar() throws {
        let (c, k) = try hazirla()
        for s in k.sanatcilar { XCTAssertEqual(k.adParcalari(s), c.bilinenAdlar[s.id], s.id) }
    }

    /// Denetim: görünür bütün sanatçıların bütün eserleri (7000+), sanatçı başına eser sayısı ve özet.
    /// Satır biçimi kâhindekiyle aynı: anahtar, görünen ad, yıl, 400 ve 1280 adresleri, pekiştirmeye uygun (1/0).
    func testTamKatalog() throws {
        let (_, k) = try hazirla()
        let kok = try XCTUnwrap(JSONSerialization.jsonObject(with: Self.dosya("cevaplar.json")) as? [String: Any])
        let katalog = try XCTUnwrap(kok["katalog"] as? [String: [Any]], "kâhin çıktısında katalog yok")
        XCTAssertEqual(Set(katalog.keys), Set(k.sanatcilar.map(\.id)))
        var toplam = 0
        for s in k.sanatcilar {
            let beklenen = try XCTUnwrap(katalog[s.id], s.id)
            let l = k.eserler(s.id)
            let satirlar = l.map { e -> String in
                let g = GorselAdresleri.secilen(e)
                return [e.anahtar, e.gorunenAd, e.yil.map(String.init) ?? "",
                        g.map { k.gorsel.url($0, genislik: 400) } ?? "",
                        g.map { k.gorsel.url($0, genislik: 1280) } ?? "",
                        GorselAdresleri.pekistirmeyeUygun(e) ? "1" : "0"].joined(separator: "\t")
            }
            XCTAssertEqual(l.count, (beklenen[0] as? NSNumber)?.intValue, "\(s.id): eser sayısı")
            XCTAssertEqual(SiteYazisi.md5(satirlar.joined(separator: "\n")), beklenen[1] as? String, "\(s.id): eserler")
            toplam += l.count
        }
        XCTAssertGreaterThan(toplam, 7000)
    }

    func testSanatciEserleri() throws {
        let (c, k) = try hazirla()
        XCTAssertEqual(c.eserler.count, 20)
        var toplam = 0
        for (id, beklenen) in c.eserler {
            let l = k.eserler(id)
            XCTAssertEqual(l.map(\.anahtar), beklenen.map(\.anahtar), id)
            guard l.count == beklenen.count else { continue }
            for (e, b) in zip(l, beklenen) {
                let yer = "\(id) \(b.anahtar)"
                XCTAssertEqual(e.baslik, b.baslik, yer)
                XCTAssertEqual(e.gorunenAd, b.ad, yer)
                XCTAssertEqual(e.tarih, b.tarih, yer)
                XCTAssertEqual(e.yil, b.yil, yer)
                XCTAssertEqual(e.muze, b.muze, yer)
                XCTAssertEqual(e.kaynak, b.kaynak, yer)
                XCTAssertEqual(e.kaynaklar, b.kaynaklar, yer)
                XCTAssertEqual(e.kursKonu, b.kursKonu, yer)
                XCTAssertEqual(e.qid, b.qid, yer)
                XCTAssertEqual(e.sl, b.sl, yer)
                XCTAssertEqual(e.pekistirme, b.pekistirme, yer)
                XCTAssertEqual(e.ortak, b.ortak, yer)
                XCTAssertEqual(e.sid, id, yer)
                XCTAssertEqual(e.gorseller.count, b.gorselSayisi, yer)
                XCTAssertEqual(GorselAdresleri.pekistirmeyeUygun(e), b.uygun, yer)
                let g = try XCTUnwrap(GorselAdresleri.secilen(e), yer)
                XCTAssertEqual(k.gorsel.url(g, genislik: 400), b.g400, yer)
                XCTAssertEqual(k.gorsel.url(g, genislik: 1280), b.g1280, yer)
                XCTAssertEqual(k.gorsel.devasaUrl(g), b.devasa, yer)
                XCTAssertEqual(k.gorsel.ustKopya(b.g400), b.ust, yer)
                XCTAssertEqual(k.gorsel.ustKopya(b.g1280, buyuk: true), b.ustBuyuk, yer)
                XCTAssertEqual(k.gorsel.oran(g), b.oran, yer)
                toplam += 1
            }
        }
        XCTAssertGreaterThan(toplam, 500)
    }

    /// Yerel kopyası olmayan görseller: Commons küçük resmi (md5 yolu), müze IIIF, WikiArt
    func testUzakAdresler() throws {
        let (c, k) = try hazirla()
        XCTAssertGreaterThan(c.uzaklar.count, 30)
        for u in c.uzaklar {
            XCTAssertEqual(k.gorsel.url(u.g, genislik: 330), u.u330, u.g.anahtar)
            XCTAssertEqual(k.gorsel.url(u.g, genislik: 400), u.u400, u.g.anahtar)
            XCTAssertEqual(k.gorsel.url(u.g, genislik: 800), u.u800, u.g.anahtar)
            XCTAssertEqual(k.gorsel.url(u.g, genislik: 1280), u.u1280, u.g.anahtar)
            XCTAssertEqual(k.gorsel.url(u.g, genislik: 2000), u.u2000, u.g.anahtar)
            XCTAssertEqual(k.gorsel.yedek(u.g), u.yedek, u.g.anahtar)
            XCTAssertNotNil(GorselAdresleri.url(u.u1280), u.u1280)
        }
    }

    /// Widget yeni katmanla aynı tabloyu buluyor: widget'ın çözücüsü (GununTablosuCozucu) ile katalogun kuralları
    /// (görünür sanatçı, Türkçe eser adı, şüpheli yıl, yürüyüş görseli) aynı günlerde aynı kartı veriyor.
    func testWidgetAyniTablo() throws {
        let (_, k) = try hazirla()
        let y = try Self.dosya("yuruyus.json"), s = try Self.dosya("sanatcilar.json")
        let a = try Self.dosya("eser_adlari_tr.json"), kaynak = try Self.dosya("gorsel_kaynagi.json")
        let eserler = try XCTUnwrap(JSONDeger.coz(y)["eserler"]?.nesne)
        var gorulen = Set<String>()
        for gun in stride(from: 0, to: 400, by: 4) {
            let tarih = GunTarihi.ekle("2026-01-01", gun)
            let t = try GununTablosuCozucu.coz(tarih: tarih, yuruyus: y, sanatcilar: s, adlar: a, kaynak: kaynak)
            let kayit = try XCTUnwrap(eserler[t.sanatciId])
            let sanatci = try XCTUnwrap(k.harita[t.sanatciId], "\(t.sanatciId) görünür değil")
            XCTAssertEqual(t.sanatci, sanatci.ad)
            let ozgun = (kayit["eser"]?.metin ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let ad = kayit["qid"]?.metin.flatMap { k.kurallar.adlar[$0] } ?? k.kurallar.adlar["\(sanatci.id)|\(ozgun)"] ?? ozgun
            XCTAssertEqual(t.eser, ad, tarih)
            let yil = kayit["yil"]?.tamSayi
            XCTAssertEqual(t.yil, EserKurallari.yilSupheli(yil, sanatci) ? nil : yil, tarih)
            let gorsel = k.gorsel.yuruyusAdresleri(ad: kayit["gorsel"]?.metin ?? "", buyuk: kayit["buyuk"]?.metin).kucuk
            XCTAssertEqual(t.gorsel?.absoluteString, gorsel, tarih)
            gorulen.insert(t.sanatciId)
        }
        XCTAssertGreaterThan(gorulen.count, 60)
    }

    /// "Yeni sürüm var mı?": diskteki kopyalar eskir ama silinmez (çevrimdışıyken yine okunur)
    func testHepsiniEskit() async throws {
        let klasor = FileManager.default.temporaryDirectory.appendingPathComponent("SiteVerisiTest-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: klasor) }
        let site = SiteVerisi(klasor: klasor, kok: URL(string: "https://yok.invalid/")!)
        let icerik = Data(#"{"eserler":{}}"#.utf8)
        try icerik.write(to: klasor.appendingPathComponent("yuruyus.json"))
        XCTAssertLessThan(site.yas("yuruyus.json"), 60)
        await site.hepsiniEskit()
        let omur = await site.omur
        XCTAssertGreaterThan(site.yas("yuruyus.json"), omur)
        // indirilemeyince eski kopya döner
        let d = await site.veri("yuruyus.json")
        XCTAssertEqual(d, icerik)
    }

    /// İndirme katmanı canlı siteye karşı (yalnız CANLI=1 ile; CI'da ağa bağlı test yok)
    func testCanliIndirme() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["CANLI"] == "1", "CANLI=1 değil")
        let klasor = FileManager.default.temporaryDirectory.appendingPathComponent("SiteVerisiTest-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: klasor) }
        let site = SiteVerisi(klasor: klasor)
        let k = try await site.katalog()
        XCTAssertGreaterThan(k.sanatcilar.count, 100)
        XCTAssertFalse(k.eserler(k.sanatcilar[0].id).isEmpty)
        XCTAssertLessThan(site.yas("sanatcilar.json"), 60)
        // ikinci kez: diskten
        let k2 = try await SiteVerisi(klasor: klasor, kok: URL(string: "https://yok.invalid/")!).katalog()
        XCTAssertEqual(k2.sanatcilar.map(\.id), k.sanatcilar.map(\.id))
    }
}

final class SiteYazisiTests: XCTestCase {
    func testMd5() {
        XCTAssertEqual(SiteYazisi.md5(""), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(SiteYazisi.md5("The quick brown fox jumps over the lazy dog"), "9e107d9d372bb6826bd81d3542a419d6")
        XCTAssertEqual(SiteYazisi.md5(String(repeating: "ğ", count: 40)).count, 32)
    }

    func testDosyaNormal() {
        XCTAssertEqual(SiteYazisi.dosyaNormal("File:mona lisa.jpg"), "Mona_lisa.jpg")
        XCTAssertEqual(SiteYazisi.dosyaNormal("Le_Jupiter_Olympien_ou_l%27art.jpg"), "Le_Jupiter_Olympien_ou_l'art.jpg")
        XCTAssertEqual(SiteYazisi.dosyaNormal("100%_bozuk"), "100%_bozuk")
        XCTAssertEqual(SiteYazisi.dosyaNormal(nil), "")
    }

    func testUriBileseni() {
        XCTAssertEqual(SiteYazisi.uriBileseni("a b/ç'(x)!*~"), "a%20b%2F%C3%A7'(x)!*~")
    }

    func testNotTemizle() {
        XCTAssertEqual(SiteYazisi.notTemizle("1401 (slayt yazısı)"), "1401")
        XCTAssertEqual(SiteYazisi.notTemizle("slaytta c1308–11"), "c1308–11")
        XCTAssertEqual(SiteYazisi.notTemizle("Slayta göre Uffizi"), "Uffizi")
        XCTAssertEqual(SiteYazisi.notTemizle("metinde 1520'ler; slaytta c1500"), "1520'ler")
        XCTAssertEqual(SiteYazisi.notTemizle("Uffizi, Floransa"), "Uffizi, Floransa")
    }

    func testYilYaz() {
        XCTAssertEqual(SiteYazisi.yilYaz(-450), "MÖ 450")
        XCTAssertEqual(SiteYazisi.yillarYaz(dogum: -480, olum: -430), "MÖ 480–430")
        XCTAssertEqual(SiteYazisi.yillarYaz(dogum: nil, olum: 1500), "ö. 1500")
    }

    func testBaslikNormal() {
        XCTAssertEqual(SiteYazisi.baslikNormal("  Gülün Adı — İkinci  "), "gulun adi ikinci")
    }

    func testSiraliJSON() throws {
        let j = try JSONDeger.coz(Data(#"{"b":1,"a":[true,null,"ç😀"],"b":2.5}"#.utf8))
        XCTAssertEqual(j.nesne?.anahtarlar, ["b", "a"])
        XCTAssertEqual(j["b"]?.sayi, 2.5)
        XCTAssertEqual(j["a"]?.dizi?[2].metin, "ç😀")
        XCTAssertThrowsError(try JSONDeger.coz(Data("{\"a\":1".utf8)))
    }
}

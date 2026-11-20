import Foundation
import XCTest
@testable import NoraCekirdek
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// T1 kâhini: beklenen değerler canlı siteden sitenin kendi modülleriyle alındı (Testler/kahin/site_verisi.mjs).
/// Ornekler/siteVerisi/data_*.json sitenin aynı anda yüklediği dosyalardır; cevaplar.json sitenin cevapları.
private enum Ornek {
    static func veri(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/siteVerisi/\(ad)", withExtension: "json"), ad)
        return try Data(contentsOf: url)
    }

    static let dosyalar: [String: Data] = {
        var d: [String: Data] = [:]
        for yol in SiteAtlasi.dosyalar + ["data/yuruyus.json"] {
            let ad = "data_" + yol.dropFirst(5).dropLast(5)
            d[yol] = try? veri(String(ad))
        }
        return d
    }()

    static let atlas: SiteAtlasi = try! SiteAtlasi(veri: dosyalar)

    struct Cevaplar: Decodable {
        struct Yapay: Decodable {
            let gorseller: [String]
            let notTemizle: [[String]]
            let dosyaNormal: [[String]]
            let yilYaz: [[Sayi]]
            let ustKopya: [[String]]
        }
        struct Kaynaksiz: Decodable {
            let eserler: [String: [String]]
            let yuruyus: [[String]]
            let ustKopya: [[String]]
        }
        let surum: String
        let tumSanatcilar: [[String]]
        let sanatcilar: [String]
        let akimlar: [[Sayi]]
        let kursKonulari: [[Sayi]]
        let adlar: [[String]]
        let yuruyus: [[String]]
        let ozet: [String: [Sayi]]
        let ayrinti: [String: [String]]
        let yapay: Yapay
        let kaynaksiz: Kaynaksiz
    }

    /// Sayı ya da dizge ya da null (karışık diziler için)
    enum Sayi: Decodable, Equatable {
        case sayi(Double), metin(String), yok
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() { self = .yok } else if let d = try? c.decode(Double.self) { self = .sayi(d) } else { self = .metin(try c.decode(String.self)) }
        }
        var metin: String { if case let .metin(s) = self { return s }; if case let .sayi(d) = self { return JS.sayi(d) }; return "" }
        var tam: Int? { if case let .sayi(d) = self { return Int(d) }; return nil }
    }

    static let cevap: Cevaplar = try! JSONDecoder().decode(Cevaplar.self, from: veri("cevaplar"))
}

/// Kâhinle aynı eser satırı (Testler/kahin/site_verisi.mjs `satir`)
func eserSatiri(_ e: Eser, _ g: GorselKaynagi) -> String {
    let s = GorselKaynagi.secilen(e)
    let u400 = g.adres(s, genislik: 400), u1280 = g.adres(s, genislik: 1280)
    let yil: String = e.yil.map { String($0) } ?? ""
    let konu: String = e.kursKonu.map { String($0) } ?? ""
    let oran: String = g.oran(s).map { JS.sayi($0) } ?? ""
    let sayfa: String = s.map { GorselKaynagi.sayfa($0) } ?? ""
    let yazi: String = s.map { GorselKaynagi.kaynakYazisi($0) } ?? ""
    var alanlar: [String] = [e.anahtar, e.kaynak, e.kaynaklar.joined(separator: ","), e.baslik, e.ad ?? "", e.gosterilenBaslik]
    alanlar += [e.tarih, yil, e.muze, konu, e.qid ?? "", e.pekistirme ? "1" : "0", String(e.sl)]
    alanlar += [e.ortak.joined(separator: ","), e.ortakAdlar.joined(separator: ",")]
    alanlar += [e.gorseller.map { GorselKaynagi.anahtar($0) }.joined(separator: ","), u400, u1280]
    alanlar += [g.devasaUrl(s), g.devasaKaynagi(s), oran, GorselKaynagi.pekistirmeyeUygun(e) ? "1" : "0", sayfa, yazi]
    alanlar += [g.ustKopya(u400), g.ustKopya(u1280, buyuk: true), g.yedek(s)]
    return alanlar.joined(separator: "\u{1F}")
}

/// İlk farklı satırı ve alanı okunur biçimde yazar
private func karsilastir(_ bulunan: [String], _ beklenen: [String], _ ad: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(bulunan.count, beklenen.count, "\(ad): eser sayısı", file: file, line: line)
    for (i, (a, b)) in zip(bulunan, beklenen).enumerated() where a != b {
        let pa = a.components(separatedBy: "\u{1F}"), pb = b.components(separatedBy: "\u{1F}")
        let alan = zip(pa, pb).enumerated().first { $0.element.0 != $0.element.1 }
        XCTFail("\(ad) #\(i) alan \(alan?.offset ?? -1): \(alan?.element.0 ?? a) ≠ site: \(alan?.element.1 ?? b)", file: file, line: line)
        return
    }
}

final class SiteAtlasiTests: XCTestCase {
    func testSanatcilarVeAkimlar() {
        let a = Ornek.atlas, c = Ornek.cevap
        XCTAssertEqual(a.sanatcilar.map(\.id), c.sanatcilar)
        XCTAssertEqual(a.tumSanatcilar.map { [$0.id, $0.akim, $0.birlesen ?? ""] }, c.tumSanatcilar)
        XCTAssertEqual(a.akimlar.map(\.ad), c.akimlar.map { $0[0].metin })
        XCTAssertEqual(a.akimlar.map { JS.sayi($0.sira) }, c.akimlar.map { $0[1].metin })
        XCTAssertEqual(a.akimlar.map { $0.renk ?? "" }, c.akimlar.map { $0[2].metin })
        XCTAssertEqual(a.akimlar.map { $0.komsular.joined(separator: ",") }, c.akimlar.map { $0[3].metin })
        XCTAssertEqual(a.harita.count, a.sanatcilar.count)
        // Uluslararası Gotik Gotik'e katıldı
        XCTAssertFalse(a.akimlar.contains { $0.ad == "Uluslararası Gotik" })
        XCTAssertTrue(a.tumSanatcilar.contains { $0.birlesen == "Uluslararası Gotik" && $0.akim == "Gotik" })
    }

    func testKursKonulari() throws {
        let a = Ornek.atlas
        XCTAssertEqual(a.kursKonulari.map(\.konu.no), Ornek.cevap.kursKonulari.map { $0[0].tam })
        for (k, b) in zip(a.kursKonulari, Ornek.cevap.kursKonulari) {
            let j = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(b[1].metin.utf8)) as? [String: Any])
            XCTAssertEqual(k.kapak.sanatci, j["sanatci"] as? String, "konu \(k.konu.no)")
            XCTAssertEqual(k.kapak.dosya, j["dosya"] as? String, "konu \(k.konu.no)")
            XCTAssertEqual(k.kapak.baslik, j["baslik"] as? String, "konu \(k.konu.no)")
            XCTAssertEqual(k.kapak.resimDegil, (j["resimDegil"] as? Bool) ?? false, "konu \(k.konu.no)")
        }
    }

    func testAdlar() {
        let a = Ornek.atlas
        for b in Ornek.cevap.adlar {
            guard let s = a.harita[b[0]] else { XCTFail(b[0]); continue }
            let p = a.adParcalari(s)
            XCTAssertEqual([p.ilk, p.son, p.tam ?? ""], Array(b[1...]), b[0])
        }
        XCTAssertEqual(Adlar.parcala("Jan van Eyck"), AdParcalari(ilk: "Jan", son: "van Eyck"))
        XCTAssertEqual(Adlar.parcala("Pieter Bruegel (Yaşlı)"), AdParcalari(ilk: "Pieter", son: "Bruegel (Yaşlı)"))
        XCTAssertEqual(Adlar.parcala("Limbourg kardeşler"), AdParcalari(ilk: "", son: "Limbourg kardeşler"))
    }

    /// Her görünür sanatçının bütün eserleri: satırların MD5'i sitenin özetiyle aynı
    func testButunEserListeleriSiteyleAyni() {
        let a = Ornek.atlas
        var toplam = 0
        XCTAssertEqual(Set(Ornek.cevap.ozet.keys), Set(a.sanatcilar.map(\.id)))
        for s in a.sanatcilar {
            let satirlar = a.eserler(s).map { eserSatiri($0, a.gorsel) }
            toplam += satirlar.count
            guard let oz = Ornek.cevap.ozet[s.id] else { continue }
            XCTAssertEqual(satirlar.count, oz[0].tam, "\(s.id): eser sayısı")
            XCTAssertEqual(MD5.onaltilik(satirlar.joined(separator: "\n")), oz[1].metin, s.id)
        }
        XCTAssertGreaterThan(toplam, 7000)
    }

    /// 20 sanatçının eserleri alan alan (kopya, düzeltme, çıkarılan, ortak atıf, kurs eserleri)
    func testAyrintiliEserler() {
        let a = Ornek.atlas
        XCTAssertEqual(Ornek.cevap.ayrinti.count, 20)
        for (id, beklenen) in Ornek.cevap.ayrinti.sorted(by: { $0.key < $1.key }) {
            karsilastir(a.eserler(id).map { eserSatiri($0, a.gorsel) }, beklenen, id)
        }
    }

    func testKurallarinDegdigiEserler() throws {
        let a = Ornek.atlas
        // İş 101: Limbourg'un kopya kaydı çıktı, kalan duruyor
        let limbourg = a.eserler("limbourg-kardesler").map(\.anahtar)
        XCTAssertFalse(limbourg.contains("q:Q29385502"))
        XCTAssertTrue(limbourg.contains("q:Q1959777"))
        // İş 174: Cimabue'ye atfedilen sahte eser çıktı
        XCTAssertFalse(a.eserler("cimabue").contains { $0.qid == "Q119086004" })
        // Ortak atıf: Giorgione ↔ Titian
        let ortak = try XCTUnwrap(a.eserler("giorgione").first { !$0.ortak.isEmpty })
        XCTAssertEqual(ortak.ortak, ["titian"])
        XCTAssertFalse(ortak.ortakAdlar.isEmpty)
    }

    func testYuruyusAdresleriVeWidget() throws {
        let a = Ornek.atlas
        let y = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(Ornek.dosyalar["data/yuruyus.json"])) as? [String: Any])
        let eserler = try XCTUnwrap(y["eserler"] as? [String: [String: Any]])
        XCTAssertGreaterThan(Ornek.cevap.yuruyus.count, 100)
        for b in Ornek.cevap.yuruyus {
            let k = try XCTUnwrap(eserler[b[0]])
            let r = a.gorsel.yuruyusAdresleri(ad: k["gorsel"] as? String, buyuk: k["buyuk"] as? String)
            XCTAssertEqual([r.kucuk, r.buyuk], [b[1], b[2]], b[0])
            // Widget aynı adresi buluyor
            XCTAssertEqual(GununTablosuCozucu.gorselAdresi(ad: k["gorsel"] as? String, buyuk: k["buyuk"] as? String,
                                                           kaynak: Ornek.dosyalar["data/gorsel_kaynagi.json"])?.absoluteString, b[1], b[0])
        }
    }

    /// Widget'ın günün tablosu yeni dosyalarla da sitenin seçtiği tabloyu ve atlasın adresini buluyor
    func testWidgetYeniKatmanlaAyniTablo() throws {
        let d = Ornek.dosyalar
        let tablo = try GununTablosuCozucu.coz(tarih: "2026-11-20", yuruyus: XCTUnwrap(d["data/yuruyus.json"]),
                                               sanatcilar: XCTUnwrap(d["data/sanatcilar.json"]),
                                               adlar: d["data/eser_adlari_tr.json"], kaynak: d["data/gorsel_kaynagi.json"])
        let b = try XCTUnwrap(Ornek.cevap.yuruyus.first { $0[0] == tablo.sanatciId })
        XCTAssertEqual(tablo.gorsel?.absoluteString, b[1])
        XCTAssertEqual(tablo.sanatci, Ornek.atlas.harita[tablo.sanatciId]?.ad)
    }
}

final class GorselKaynagiTests: XCTestCase {
    func testYapayGorseller() {
        let g = Ornek.atlas.gorsel
        let ornekler: [Gorsel] = [
            Gorsel(k: "commons", d: "Some_painting_(détail),_1500.tif", l: "CC BY-SA 4.0"),
            Gorsel(k: "commons", d: "File:a%C3%A7ık hava %25 rapor.svg", l: ""),
            Gorsel(k: "commons", d: "Book_of_hours.pdf"),
            Gorsel(k: "commons", d: "çizim_Ç.djvu"),
            Gorsel(k: "commons", d: "L'Été_*_(1).JPEG"),
            Gorsel(k: "commons", d: "%E0%A4%A"),
            Gorsel(k: "aic", i: "0a1b2c3d-1111-2222-3333-444455556666", l: "CC0", s: "https://www.artic.edu/artworks/1"),
            Gorsel(k: "nga", i: "https://api.nga.gov/iiif/abc-def", s: "javascript:alert(1)"),
            Gorsel(k: "wikiart", u: "https://uploads.wikiart.org/images/x/y.jpg!HalfHD.jpg", s: "https://www.wikiart.org/en/x/y"),
            Gorsel(k: "wikiart", u: "https://uploads.wikiart.org/images/x/z.jpg"),
            Gorsel(k: "met", u: "https://images.metmuseum.org/CRDImages/ep/original/DT1.jpg", l: "CC0"),
            Gorsel(k: "cma", u: "https://openaccess-cdn.clevelandart.org/1.jpg", s: "http://clevelandart.org/1"),
            Gorsel(k: "met"),
            Gorsel(k: "bilinmez", u: "https://ornek.org/a.jpg", l: "X"),
        ]
        XCTAssertEqual(ornekler.count, Ornek.cevap.yapay.gorseller.count)
        let satirlar = ornekler.map { x in
            [GorselKaynagi.anahtar(x), GorselKaynagi.yerelAnahtar(x), g.adres(x, genislik: 400), g.adres(x, genislik: 960),
             g.adres(x, genislik: 2000), GorselKaynagi.sayfa(x), GorselKaynagi.kaynakYazisi(x), g.yedek(x)].joined(separator: "\u{1F}")
        }
        karsilastir(satirlar, Ornek.cevap.yapay.gorseller, "yapay")
    }

    func testYardimcilar() {
        let y = Ornek.cevap.yapay
        for n in y.notTemizle { XCTAssertEqual(Yardimci.notTemizle(n[0]), n[1], n[0]) }
        for n in y.dosyaNormal { XCTAssertEqual(Yardimci.dosyaNormal(n[0]), n[1], n[0]) }
        for n in y.yilYaz { XCTAssertEqual(Yardimci.yilYaz(n[0].tam), n[1].metin) }
        for n in y.ustKopya {
            XCTAssertEqual(Ornek.atlas.gorsel.ustKopya(n[0]), n[1], n[0])
            XCTAssertEqual(Ornek.atlas.gorsel.ustKopya(n[0], buyuk: true), n[2], n[0])
        }
        XCTAssertEqual(Yardimci.yillarYaz(dogum: -480, olum: -430), "MÖ 480–430")
        XCTAssertEqual(Yardimci.yillarYaz(dogum: 1445, olum: 1510), "1445–1510")
        XCTAssertEqual(Yardimci.yillarYaz(dogum: nil, olum: 1510), "ö. 1510")
        XCTAssertEqual(Yardimci.baslikNormal("  Büyük İskender'in  Savaşı! "), "buyuk iskender in savasi")
        XCTAssertEqual(JS.encodeURIComponent("a b/ç'(*)~"), "a%20b%2F%C3%A7'(*)~")
    }

    func testMD5() {
        XCTAssertEqual(MD5.onaltilik(""), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(MD5.onaltilik("The quick brown fox jumps over the lazy dog"), "9e107d9d372bb6826bd81d3542a419d6")
        XCTAssertEqual(MD5.onaltilik(String(repeating: "a", count: 200)), "887f30b43b2867f4a9accceee7d16e6c")
        XCTAssertEqual(MD5.onaltilik("çanak"), "72c99486438e9050ec6837d378fa2531")
    }

    /// R2 kaynağı yokken (dosya inmediyse) adresler sitenin kendi kopyalarına döner
    func testKaynakYokken() throws {
        let d = Ornek.dosyalar
        let atlas = try SiteAtlasi(veri: d.filter { $0.key != "data/gorsel_kaynagi.json" })
        XCTAssertFalse(atlas.gorsel.r2Var)
        for (id, beklenen) in Ornek.cevap.kaynaksiz.eserler {
            karsilastir(Array(atlas.eserler(id).prefix(15)).map { eserSatiri($0, atlas.gorsel) }, beklenen, "kaynaksız \(id)")
        }
        let y = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(d["data/yuruyus.json"])) as? [String: Any])
        let eserler = try XCTUnwrap(y["eserler"] as? [String: [String: Any]])
        for b in Ornek.cevap.kaynaksiz.yuruyus {
            let k = try XCTUnwrap(eserler[b[0]])
            let r = atlas.gorsel.yuruyusAdresleri(ad: k["gorsel"] as? String, buyuk: k["buyuk"] as? String)
            XCTAssertEqual([r.kucuk, r.buyuk], [b[1], b[2]], b[0])
        }
        for n in Ornek.cevap.kaynaksiz.ustKopya {
            XCTAssertEqual(atlas.gorsel.ustKopya(n[0]), n[1], n[0])
            XCTAssertEqual(atlas.gorsel.ustKopya(n[0], buyuk: true), n[2], n[0])
        }
    }

    func testSecilenGorselVeKotuler() throws {
        let e = try XCTUnwrap(Ornek.atlas.eserler("giorgione").first { $0.gorseller.count > 1 } ?? Ornek.atlas.sanatcilar.lazy
            .flatMap { Ornek.atlas.eserler($0) }.first { $0.gorseller.count > 1 })
        let ilk = GorselKaynagi.anahtar(e.gorseller[0])
        XCTAssertEqual(GorselKaynagi.secilen(e), e.gorseller[0])
        XCTAssertEqual(GorselKaynagi.secilen(e, kotuler: [e.anahtar: [ilk]]), e.gorseller[1])
        let hepsi = e.gorseller.map(GorselKaynagi.anahtar)
        XCTAssertNil(GorselKaynagi.secilen(e, kotuler: [e.anahtar: hepsi]))
        XCTAssertFalse(GorselKaynagi.pekistirmeyeUygun(e, kotuler: [e.anahtar: hepsi]))
    }
}

final class SiteVerisiTests: XCTestCase {
    final class SahteSite: @unchecked Sendable {
        let kilit = NSLock()
        var dosyalar: [String: Data]
        var etag = "\"v1\""
        var cevrimdisi = false
        var istekler: [(String, String?)] = []
        init(_ d: [String: Data]) { dosyalar = d }

        func indir(_ r: URLRequest) throws -> (Data, URLResponse) {
            kilit.lock(); defer { kilit.unlock() }
            let yol = String(r.url!.path.dropFirst())
            istekler.append((yol, r.value(forHTTPHeaderField: "If-None-Match")))
            if cevrimdisi { throw URLError(.notConnectedToInternet) }
            guard let d = dosyalar[yol] else {
                return (Data(), HTTPURLResponse(url: r.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
            }
            if r.value(forHTTPHeaderField: "If-None-Match") == etag {
                return (Data(), HTTPURLResponse(url: r.url!, statusCode: 304, httpVersion: nil, headerFields: nil)!)
            }
            return (d, HTTPURLResponse(url: r.url!, statusCode: 200, httpVersion: nil, headerFields: ["ETag": etag])!)
        }
    }

    func geciciKlasor() -> URL {
        let k = FileManager.default.temporaryDirectory.appendingPathComponent("SiteVerisiTests-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: k) }
        return k
    }

    func testIndirOnbellekVeETag() async throws {
        let sahte = SahteSite(["data/akimlar.json": Data(#"[{"ad":"A","sira":0,"komsular":[]}]"#.utf8)])
        let k = geciciKlasor()
        let site = SiteVerisi(klasor: k, omur: 0) { try sahte.indir($0) }
        let ilk = await site.dosya("data/akimlar.json")
        XCTAssertNotNil(ilk)
        XCTAssertTrue(FileManager.default.fileExists(atPath: k.appendingPathComponent("data_akimlar.json").path))
        // Eski: ETag'le sorulur, 304 → önbellekteki
        let ikinci = await site.dosya("data/akimlar.json")
        XCTAssertEqual(ikinci, ilk)
        XCTAssertEqual(sahte.istekler.last?.1, "\"v1\"")
        // Değişti: yenisi iner
        sahte.etag = "\"v2\""
        sahte.dosyalar["data/akimlar.json"] = Data(#"[{"ad":"B","sira":0,"komsular":[]}]"#.utf8)
        let ucuncu = await site.dosya("data/akimlar.json")
        XCTAssertEqual(ucuncu.map { String(decoding: $0, as: UTF8.self) }, #"[{"ad":"B","sira":0,"komsular":[]}]"#)
        // Çevrimdışı: son indirilen
        sahte.cevrimdisi = true
        let dorduncu = await site.dosya("data/akimlar.json")
        XCTAssertEqual(dorduncu, ucuncu)
        // Bozuk yanıt önbelleği bozmaz
        sahte.cevrimdisi = false
        sahte.etag = "\"v3\""
        sahte.dosyalar["data/akimlar.json"] = Data("<html>".utf8)
        let besinci = await site.dosya("data/akimlar.json")
        XCTAssertEqual(besinci, ucuncu)
        // Hiç inmemiş dosya
        let yok = await site.dosya("data/yok.json")
        XCTAssertNil(yok)
    }

    func testTazeDosyaIcinAgaCikilmaz() async {
        let sahte = SahteSite(["data/konular.json": Data("[]".utf8)])
        let site = SiteVerisi(klasor: geciciKlasor(), omur: 3600) { try sahte.indir($0) }
        _ = await site.dosya("data/konular.json")
        _ = await site.dosya("data/konular.json")
        XCTAssertEqual(sahte.istekler.count, 1)
        _ = await site.dosya("data/konular.json", zorla: true)
        XCTAssertEqual(sahte.istekler.count, 2)
    }

    func testAtlasSitedenKurulur() async throws {
        let sahte = SahteSite(Ornek.dosyalar)
        let site = SiteVerisi(klasor: geciciKlasor()) { try sahte.indir($0) }
        let atlas = try await site.atlas()
        XCTAssertEqual(atlas.sanatcilar.map(\.id), Ornek.cevap.sanatcilar)
        // Zorunlu dosya yoksa hata
        sahte.dosyalar["data/konular.json"] = nil
        let bos = SiteVerisi(klasor: geciciKlasor()) { try sahte.indir($0) }
        do { _ = try await bos.atlas(); XCTFail("hata bekleniyordu") } catch let h as SiteAtlasi.Hata {
            XCTAssertEqual(h, .eksikDosya("data/konular.json"))
        }
    }

    func testSiraliJSON() {
        let j = Data(#"{"surum":3,"x":{"a":[1,{"b":"}"}]},"sanatcilar":{"zeta":{"e":[]},"alfa":{"q":"a\"b"},"mü":1}}"#.utf8)
        XCTAssertEqual(SiraliJSON.anahtarlar(j, alan: "sanatcilar"), ["zeta", "alfa", "mü"])
        XCTAssertEqual(SiraliJSON.anahtarlar(j, alan: "yok"), [])
        let onbellek = try! Ornek.veri("data_eserler_onbellek")
        XCTAssertEqual(SiraliJSON.anahtarlar(onbellek, alan: "sanatcilar").count, 187)
    }
}

import Foundation
import XCTest
@testable import NoraCekirdek
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// T3 kâhini: Testler/kahin/kabuk.mjs → Ornekler/kabuk/cevaplar.json (canlı sitenin sekme çubuğu ve renk değişkenleri)
private enum KabukOrnek {
    struct Cevap: Decodable {
        struct Tema: Decodable {
            let dataTema: String
            let themeColor: String
            let degiskenler: [String: String]
        }
        let surum: String
        let sekmeler: [[String?]]
        let tema: [String: Tema]
    }

    static let cevap: Cevap = {
        let url = Bundle.module.url(forResource: "Ornekler/kabuk/cevaplar", withExtension: "json")!
        return try! JSONDecoder().decode(Cevap.self, from: Data(contentsOf: url))
    }()
}

final class SekmeTests: XCTestCase {
    /// Sitenin sekme çubuğunda seçili sekme, her örnek adreste
    func testSiteSekmesiSiteyleAyni() {
        XCTAssertGreaterThan(KabukOrnek.cevap.sekmeler.count, 30)
        for s in KabukOrnek.cevap.sekmeler {
            let adres = s[0] ?? ""
            XCTAssertEqual(SiteRotalari.siteSekmesi(adres), s[1] ?? nil, adres)
        }
    }

    func testUygulamaSekmesi() {
        XCTAssertEqual(SiteRotalari.sekme(""), .bugun)
        XCTAssertEqual(SiteRotalari.sekme("#/harita"), .yolculuk)
        XCTAssertEqual(SiteRotalari.sekme("#/sanatci/rembrandt"), .galeri)
        XCTAssertEqual(SiteRotalari.sekme("#/koleksiyon"), .galeri)
        XCTAssertEqual(SiteRotalari.sekme("#/pekistir/ders/3"), .calis)
        XCTAssertNil(SiteRotalari.sekme("#/pekistir/karisik"))
        XCTAssertEqual(SiteRotalari.sekme("#/ilerleme"), .ben)
        XCTAssertEqual(SiteRotalari.sekme("#/ayarlar"), .ben)
        XCTAssertEqual(SiteRotalari.sekme("#/gunun"), .bugun)
        for s in Sekme.allCases {
            XCTAssertEqual(SiteRotalari.sekme(s.kokAdres), s, s.rawValue)
            if let k = s.siteKimligi { XCTAssertEqual(Sekme(siteKimligi: k), s) }
        }
    }

    /// Denetimde bulundu: site açılışta "#/" bildirince `-adres`/widget ile açılan yerli Galeri kapanıyordu
    func testSitedenGelenAdresleSekmeSecimi() {
        let galeri: (Sekme) -> Bool = { $0 == .galeri }
        XCTAssertNil(SiteRotalari.secim(onceki: "#/", yeni: "#/", secili: .galeri, yerli: galeri))
        XCTAssertNil(SiteRotalari.secim(onceki: "#/", yeni: "", secili: .galeri, yerli: galeri))
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/", yeni: "#/sanatci/rembrandt", secili: .bugun, yerli: galeri), .galeri)
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/", yeni: "#/harita", secili: .galeri, yerli: galeri), .yolculuk)
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/gozat", yeni: "#/", secili: .galeri, yerli: galeri), .bugun)
        XCTAssertNil(SiteRotalari.secim(onceki: "#/pekistir", yeni: "#/pekistir/karisik", secili: .calis, yerli: galeri))
        XCTAssertNil(SiteRotalari.secim(onceki: "#/", yeni: "#/gozat", secili: .galeri, yerli: galeri))
        // Hiç sekme taşınmamışken seçim sitenin sekmesini izler
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/", yeni: "#/ilerleme", secili: .bugun, yerli: { _ in false }), .ben)
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/ilerleme", yeni: "#/", secili: .ben, yerli: { _ in false }), .bugun)
    }

    /// T7: Bugün ve Yolculuk da yerli; sekmesiz adresler yerli Çalış'a / Galeri'ye
    func testHepsiYerliyken() {
        let hepsi: (Sekme) -> Bool = { _ in true }
        // Site açılışta "#/" bildirir: widget'la açılmış Çalış kapanmamalı
        XCTAssertNil(SiteRotalari.secim(onceki: "#/", yeni: "#/", secili: .calis, yerli: hepsi))
        XCTAssertNil(SiteRotalari.secim(onceki: "#/pekistir", yeni: "#/pekistir", secili: .bugun, yerli: hepsi))
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/", yeni: "#/pekistir/karisik", secili: .galeri, yerli: hepsi), .calis)
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/", yeni: "#/pekistir/ders/Gotik/gor", secili: .bugun, yerli: hepsi), .calis)
        XCTAssertNil(SiteRotalari.secim(onceki: "#/pekistir", yeni: "#/pekistir/karisik", secili: .calis, yerli: hepsi))
        XCTAssertEqual(SiteRotalari.secim(onceki: "#/", yeni: "#/karsilastir/a/b", secili: .calis, yerli: hepsi), .galeri)
        XCTAssertEqual(SiteRotalari.yerliSekme("#/pekistir/ders/Gotik/ayirt"), .calis)
        XCTAssertEqual(SiteRotalari.yerliSekme("#/pekistir/donem/Barok"), .calis)
        XCTAssertEqual(SiteRotalari.yerliSekme("#/akim-karsilastir/a/b"), .galeri)
        XCTAssertNil(SiteRotalari.yerliSekme("#/pekistir/bolum/2-1/kolay"))
        XCTAssertEqual(SiteRotalari.yerliSekme("#/harita"), .yolculuk)
        XCTAssertEqual(SiteRotalari.yerliSekme(""), .bugun)
    }
}

final class TemaTests: XCTestCase {
    func testCSSRengi() {
        XCTAssertEqual(RGBA(css: "#121110")?.hex, "#121110")
        XCTAssertEqual(RGBA(css: "#ECE8E1")?.hex, "#ece8e1")
        XCTAssertEqual(RGBA(css: "#fff")?.hex, "#ffffff")
        XCTAssertEqual(RGBA(css: "#12111080")?.hex, "#12111080")
        XCTAssertEqual(RGBA(css: "rgba(111, 180, 135, 0.14)")?.a ?? 0, 0.14, accuracy: 1e-9)
        XCTAssertEqual(RGBA(css: "rgba(111, 180, 135, 0.14)")?.r ?? 0, 111.0 / 255, accuracy: 1e-9)
        XCTAssertEqual(RGBA(css: "rgb(18 17 16 / 80%)")?.a ?? 0, 0.8, accuracy: 1e-9)
        XCTAssertEqual(RGBA(css: " rgb(255,0,0) ")?.hex, "#ff0000")
        XCTAssertEqual(RGBA(css: "transparent")?.a, 0)
        XCTAssertNil(RGBA(css: "linear-gradient(red, blue)"))
        XCTAssertNil(RGBA(css: "#12"))
        XCTAssertNil(RGBA(css: ""))
        XCTAssertTrue(TemaRenkleri.gece.koyu)
        XCTAssertFalse(TemaRenkleri.gunduz.koyu)
    }

    /// Sabit tablolar sitenin hesapladığı değişkenlerle aynı (vurgu ailesi hariç: site onu tablonun renginden üretir)
    func testSabitTablolarSiteyleAyni() throws {
        let vurgu: Set<String> = ["--vurgu", "--vurgu-yazi", "--vurgu-acik", "--vurgu-acik-yazi", "--vurgu-koyu"]
        for (ad, sabit) in [("gece", TemaRenkleri.gece), ("gunduz", TemaRenkleri.gunduz)] {
            let t = try XCTUnwrap(KabukOrnek.cevap.tema[ad])
            XCTAssertEqual(t.dataTema, ad)
            XCTAssertEqual(RGBA(css: t.themeColor), sabit.zemin, "\(ad) theme-color")
            for (degisken, yol) in TemaRenkleri.degiskenler where !vurgu.contains(degisken) {
                let site = try XCTUnwrap(t.degiskenler[degisken].flatMap(RGBA.init(css:)), "\(ad) \(degisken)")
                XCTAssertEqual(sabit[keyPath: yol].hex, site.hex, "\(ad) \(degisken)")
            }
        }
    }

    /// Sitenin canlı değişkenleri (renkli Gündüz dahil) eksiksiz okunuyor
    func testCanliDegiskenler() throws {
        for (ad, t) in KabukOrnek.cevap.tema {
            let r = try XCTUnwrap(TemaRenkleri(degiskenler: t.degiskenler, yedek: nil), ad)
            XCTAssertEqual(r.zemin, RGBA(css: t.themeColor), ad)
        }
        let lapis = try XCTUnwrap(KabukOrnek.cevap.tema["gunduzLapis"])
        let r = try XCTUnwrap(TemaRenkleri(degiskenler: lapis.degiskenler, yedek: .gunduz))
        XCTAssertNotEqual(r.zemin, TemaRenkleri.gunduz.zemin, "renkli Gündüz'ün zemini paletten")
        // Eksik değişken yedekten
        var eksik = lapis.degiskenler
        eksik["--ink"] = nil
        eksik["--bg"] = "bozuk"
        XCTAssertNil(TemaRenkleri(degiskenler: eksik, yedek: nil))
        let y = try XCTUnwrap(TemaRenkleri(degiskenler: eksik, yedek: .gunduz))
        XCTAssertEqual(y.murekkep, TemaRenkleri.gunduz.murekkep)
        XCTAssertEqual(y.zemin, TemaRenkleri.gunduz.zemin)
    }
}

final class GorselDeposuTests: XCTestCase {
    final class Sayac: @unchecked Sendable {
        let kilit = NSLock()
        var n = 0
        var durum = 200
        func say() -> Int { kilit.lock(); defer { kilit.unlock() }; n += 1; return durum }
        func indir(_ u: URL) async throws -> (Data, URLResponse) {
            let d = say()
            try await Task.sleep(nanoseconds: 20_000_000)
            let veri = d == 200 ? Data(repeating: 7, count: 1000) : Data("yok".utf8)
            return (veri, HTTPURLResponse(url: u, statusCode: d, httpVersion: nil, headerFields: nil)!)
        }
    }

    func klasor() -> URL {
        let k = FileManager.default.temporaryDirectory.appendingPathComponent("GorselDeposu-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: k) }
        return k
    }

    func testBirKezIner() async throws {
        let s = Sayac()
        let depo = GorselDeposu(klasor: klasor()) { try await s.indir($0) }
        let u = URL(string: "https://gorsel.noracloud.ai/b/0123456789abcdef.jpg")!
        // Aynı anda istenen aynı görsel tek indirme
        async let a = depo.veri(u)
        async let b = depo.veri(u)
        let (x, y) = try await (a, b)
        XCTAssertEqual(x, y)
        XCTAssertEqual(s.n, 1)
        // Sonra diskten
        _ = try await depo.veri(u)
        XCTAssertEqual(s.n, 1)
        XCTAssertNotNil(depo.diskte(u))
        XCTAssertEqual(depo.dosya(u).lastPathComponent, SiteYazisi.md5(u.absoluteString))
        // Yeni depo örneği aynı klasörü kullanınca yine diskten
        let depo2 = GorselDeposu(klasor: await depo.klasor) { try await s.indir($0) }
        _ = try await depo2.veri(u)
        XCTAssertEqual(s.n, 1)
    }

    func testHataliYanitYazilmaz() async {
        let s = Sayac()
        s.durum = 404
        let depo = GorselDeposu(klasor: klasor()) { try await s.indir($0) }
        let u = URL(string: "https://ornek.org/yok.jpg")!
        do { _ = try await depo.veri(u); XCTFail() } catch {
            XCTAssertEqual(error as? GorselDeposu.Hata, .yanit(404))
        }
        XCTAssertNil(depo.diskte(u))
    }

    func testBudamaEskileriSiler() async throws {
        let s = Sayac()
        let depo = GorselDeposu(klasor: klasor(), sinir: 5000) { try await s.indir($0) }
        var adresler: [URL] = []
        for i in 0..<8 {
            let u = URL(string: "https://ornek.org/\(i).jpg")!
            adresler.append(u)
            _ = try await depo.veri(u)
            // kullanım zamanları ayrışsın
            try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: Double(i - 100))],
                                                  ofItemAtPath: depo.dosya(u).path)
        }
        await depo.budama()
        let kalan = await depo.boyut()
        XCTAssertLessThanOrEqual(kalan, 4000)
        XCTAssertNil(depo.diskte(adresler[0]), "en eski silinir")
        XCTAssertNotNil(depo.diskte(adresler[7]), "en yeni kalır")
        await depo.temizle()
        let bos = await depo.boyut()
        XCTAssertEqual(bos, 0)
    }
}

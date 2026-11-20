import Foundation
import XCTest
@testable import NoraCekirdek

private func ornek(_ ad: String) throws -> Data {
    let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/\(ad)", withExtension: nil))
    return try Data(contentsOf: url)
}

final class GunTarihiTests: XCTestCase {
    func testEkle() {
        XCTAssertEqual(GunTarihi.ekle("2026-11-20", 1), "2026-11-21")
        XCTAssertEqual(GunTarihi.ekle("2026-12-31", 1), "2027-01-01")
        XCTAssertEqual(GunTarihi.ekle("2028-02-28", 1), "2028-02-29")
        XCTAssertEqual(GunTarihi.ekle("2027-02-28", 1), "2027-03-01")
        XCTAssertEqual(GunTarihi.ekle("2026-03-01", -1), "2026-02-28")
        XCTAssertEqual(GunTarihi.gunNo("1970-01-01"), 0)
        XCTAssertEqual(GunTarihi.gunNo("2026-01-01"), 20454)
    }

    func testGecersiz() {
        XCTAssertNil(GunTarihi.gunNo("2026-13-01"))
        XCTAssertNil(GunTarihi.gunNo("dün"))
    }
}

/// Beklenen değerler canlı siteden (sanat-atlasi.pages.dev) sitenin kendi modülleriyle alındı:
/// `gununSanatcisi(gununHavuzu(), gün)` ve her tablonun `yuruyusEserAdi`, yılı, `yuruyusAdresleri(...).kucuk`.
final class GununTablosuTests: XCTestCase {
    struct Cevaplar: Decodable {
        struct Tablo: Decodable { let ad: String; let eser: String; let yil: Int?; let gorsel: String }
        let tablo: [String: Tablo]
        let secim: [[String]]
    }

    func testSecimSiteyleAyni() throws {
        let c = try JSONDecoder().decode(Cevaplar.self, from: ornek("site_cevaplari.json"))
        let havuz = Array(c.tablo.keys)
        XCTAssertEqual(havuz.count, 145)
        XCTAssertGreaterThan(c.secim.count, 200)
        for s in c.secim {
            XCTAssertEqual(GununSanatcisi.sec(havuz: havuz, tarih: s[0]), s[1], s[0])
        }
    }

    func testTablolarSiteyleAyni() throws {
        let c = try JSONDecoder().decode(Cevaplar.self, from: ornek("site_cevaplari.json"))
        let y = try ornek("yuruyus.json"), s = try ornek("sanatcilar.json")
        let a = try ornek("eser_adlari_tr.json"), k = try ornek("gorsel_kaynagi.json")
        var gorulen = Set<String>()
        for g in c.secim {
            let t = try GununTablosuCozucu.coz(tarih: g[0], yuruyus: y, sanatcilar: s, adlar: a, kaynak: k)
            let beklenen = try XCTUnwrap(c.tablo[t.sanatciId])
            XCTAssertEqual(t.sanatciId, g[1])
            XCTAssertEqual(t.sanatci, beklenen.ad)
            XCTAssertEqual(t.eser, beklenen.eser, t.sanatciId)
            XCTAssertEqual(t.yil, beklenen.yil, t.sanatciId)
            XCTAssertEqual(t.gorsel?.absoluteString, beklenen.gorsel, t.sanatciId)
            XCTAssertNotNil(t.notBaslik)
            gorulen.insert(t.sanatciId)
        }
        XCTAssertGreaterThan(gorulen.count, 100)
    }

    func testBugun() throws {
        let t = try GununTablosuCozucu.coz(tarih: "2026-11-20", yuruyus: ornek("yuruyus.json"),
                                           sanatcilar: ornek("sanatcilar.json"),
                                           adlar: ornek("eser_adlari_tr.json"), kaynak: ornek("gorsel_kaynagi.json"))
        XCTAssertEqual(t.sanatci, "François Boucher")
        XCTAssertEqual(t.eserSatiri, "Venüs'ün Zaferi · 1740")
    }

    func testKaynakYoksaSitedenKucukKopya() throws {
        let t = try GununTablosuCozucu.coz(tarih: "2026-11-20", yuruyus: ornek("yuruyus.json"),
                                           sanatcilar: ornek("sanatcilar.json"), adlar: nil, kaynak: nil)
        XCTAssertEqual(t.gorsel?.absoluteString.hasPrefix("https://sanat-atlasi.pages.dev/gorseller/k/"), true)
        XCTAssertFalse(t.eser.isEmpty)
    }

    func testBozukVeri() {
        XCTAssertThrowsError(try GununTablosuCozucu.coz(tarih: "2026-11-20", yuruyus: Data("[]".utf8),
                                                        sanatcilar: Data("[]".utf8), adlar: nil, kaynak: nil))
        XCTAssertThrowsError(try GununTablosuCozucu.coz(tarih: "2026-11-20", yuruyus: Data(#"{"eserler":{}}"#.utf8),
                                                        sanatcilar: Data("[]".utf8), adlar: nil, kaynak: nil))
    }
}

final class TekrarPlaniTests: XCTestCase {
    let t = TekrarTakvimi(bugun: "2026-11-20", gunler: [3, 3, 5, 0, 0, 8], rozet: true)

    func testSaatGecmediyseBugunDahil() {
        let p = TekrarPlani.plan(t, saat: 20, dakika: 0, simdiGun: "2026-11-20", simdiDakika: 10 * 60)
        XCTAssertEqual(p.map(\.gun), ["2026-11-20", "2026-11-21", "2026-11-22", "2026-11-25"])
        XCTAssertEqual(p.map(\.sayi), [3, 3, 5, 8])
        XCTAssertEqual(p.first?.kimlik, "tekrar-2026-11-20")
        XCTAssertEqual(p.first?.govde, "Bugün 3 sanatçı tekrarını bekliyor.")
    }

    func testSaatGectiyseYarindanBaslar() {
        let p = TekrarPlani.plan(t, saat: 20, dakika: 0, simdiGun: "2026-11-20", simdiDakika: 20 * 60)
        XCTAssertEqual(p.first?.gun, "2026-11-21")
    }

    func testEskiTakvimGecmisGunleriAtlar() {
        // Takvim iki gün önce hesaplandı: geçmiş günler atlanır, sonrakiler geçerli kalır
        let p = TekrarPlani.plan(t, saat: 9, dakika: 30, simdiGun: "2026-11-22", simdiDakika: 8 * 60)
        XCTAssertEqual(p.map(\.gun), ["2026-11-22", "2026-11-25"])
        XCTAssertEqual(p.first?.dakika, 30)
    }

    func testEnCok14Gun() {
        let uzun = TekrarTakvimi(bugun: "2026-11-20", gunler: Array(repeating: 1, count: 30), rozet: false)
        XCTAssertEqual(TekrarPlani.plan(uzun, saat: 20, dakika: 0, simdiGun: "2026-11-20", simdiDakika: 0).count, 14)
    }

    func testIleti() {
        let i: [String: Any] = ["bugun": "2026-11-20", "gunler": [NSNumber(value: 2), NSNumber(value: 4)], "rozet": true]
        XCTAssertEqual(TekrarTakvimi(ileti: i), TekrarTakvimi(bugun: "2026-11-20", gunler: [2, 4], rozet: true))
        XCTAssertNil(TekrarTakvimi(ileti: ["bugun": "x", "gunler": [1]]))
        XCTAssertNil(TekrarTakvimi(ileti: ["bugun": "2026-11-20", "gunler": [-1]]))
        XCTAssertNil(TekrarTakvimi(ileti: "bozuk"))
    }
}

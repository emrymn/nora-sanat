// Kaynak: sanat-atlasi js/ekranlar/{ilerleme,ayarlar,pano}.js, js/depo.js @ a866b86
import XCTest
@testable import NoraCekirdek

final class BenTests: XCTestCase {
    func ornek(_ ad: String) throws -> JSONDeger {
        let url = try XCTUnwrap(Bundle.module.url(forResource: ad, withExtension: "json", subdirectory: "Ornekler/ben"))
        return try JSONDeger.coz(Data(contentsOf: url))
    }
    func testPanoCanliSiteyleAyni() throws {
        let g = try ornek("girdi"), c = try ornek("cevaplar")
        let il = try Ilerleme(json: XCTUnwrap(g["il"]))
        let p = BenPanosu(il, sanatcilar: (g["sanatcilar"]?.dizi ?? []).map(Sanatci.init(json:)),
                          akimlar: (g["akimlar"]?.dizi ?? []).map(Akim.init(json:)), bugun: "2026-11-21")
        XCTAssertEqual(p.acik, c["acik"]?.tamSayi)
        XCTAssertEqual(p.kalici, c["kalici"]?.tamSayi)
        XCTAssertEqual(p.vade, c["vade"]?.tamSayi)
        let a = try XCTUnwrap(p.akimlar.first)
        XCTAssertEqual([a.dogru,a.toplam,a.kalici,a.vade,a.sanatci], c["akim"]?.dizi?.compactMap(\.tamSayi))
        XCTAssertEqual(p.zayiflar.map(\.id), c["zayif"]?.dizi?.compactMap(\.metin))
    }
    func testKonuVeAyarDegisiklikleri() throws {
        let g = try ornek("girdi"), c = try ornek("cevaplar")
        var il = try Ilerleme(json: XCTUnwrap(g["il"]))
        il[alan: "gelecekAlan"] = .metin("koru")
        BenPanosu.isaretle([992,993,993], islendi: true, il: &il)
        BenPanosu.isaretle([992], islendi: false, il: &il)
        XCTAssertEqual(il.islenen, c["islenen"]?.dizi?.compactMap(\.tamSayi))
        il.ayarla("gunlukKart", .sayi(7))
        BenPanosu.kart(-5, il: &il)
        let alt = il.ayar("gunlukKart")?.tamSayi
        il.ayarla("gunlukKart", .sayi(98))
        BenPanosu.kart(5, il: &il)
        XCTAssertEqual([alt, il.ayar("gunlukKart")?.tamSayi].compactMap { $0 }, c["kart"]?.dizi?.compactMap(\.tamSayi))
        BenPanosu.sec("gunduzRenk", "lapis", il: &il)
        XCTAssertEqual([il.ayar("tema")?.metin, il.ayar("gunduzRenk")?.metin].compactMap { $0 }, c["renk"]?.dizi?.compactMap(\.metin))
        XCTAssertEqual(il[alan: "gelecekAlan"]?.metin, "koru")
    }
}

// Kaynak: sanat-atlasi js/{bolum,harita,zaman}.js @ a866b86; Testler/kahin/yolculuk.mjs
import XCTest
@testable import NoraCekirdek

final class YolculukTests: XCTestCase {
    private func cevaplar() throws -> JSONDeger {
        let url = try XCTUnwrap(Bundle.module.url(forResource:"Ornekler/yolculuk/cevaplar",withExtension:"json"))
        return try JSONDeger.coz(Data(contentsOf:url))
    }

    func testButunDuraklar() throws {
        let k = try XCTUnwrap(SiteVerisiTests.hazir?.1)
        let c = try cevaplar()
        var il = try Ilerleme(json:.nesne(.bos))
        il.islenen = Array(0...57)
        il[alan:"bolumler"] = c["kayitlar"]
        let duraklar = YolculukHaritasi.kur(k,ilerleme:il,harita:try XCTUnwrap(c["konumlar"]),dersler:nil,yuruyus:nil)
        let beklenen = try XCTUnwrap(c["duraklar"]?.dizi)
        XCTAssertEqual(duraklar.map(\.id),beklenen.compactMap{$0["id"]?.metin})
        for (d,x) in zip(duraklar,beklenen) {
            XCTAssertEqual(d.ad,x["ad"]?.metin)
            XCTAssertEqual(d.sanatcilar,x["sanatcilar"]?.dizi?.compactMap(\.metin))
            XCTAssertEqual(d.gruplar,x["gruplar"]?.dizi?.map { $0.dizi?.compactMap(\.metin) ?? [] })
            XCTAssertEqual(d.bolge,x["bolge"]?.metin)
            XCTAssertEqual(d.sembol,x["sembol"]?.tamSayi)
            XCTAssertEqual(d.x,x["x"]?.sayi)
            XCTAssertEqual(d.y,x["y"]?.sayi)
            XCTAssertEqual(d.kilit,x["kilit"]?.metin)
            XCTAssertEqual(d.yildiz,x["yildiz"]?.tamSayi)
        }
    }

    func testKadranVeYogunluk() throws {
        let k = try XCTUnwrap(SiteVerisiTests.hazir?.1)
        let c = try cevaplar()
        for x in try XCTUnwrap(c["yillar"]?.dizi) {
            let y = try XCTUnwrap(x["yil"]?.tamSayi)
            XCTAssertEqual(ZamanKadrani.evre(y),x["evre"]?.metin)
            XCTAssertEqual(ZamanKadrani.yasayanlar(k.sanatcilar,yil:y).map(\.id),x["idler"]?.dizi?.compactMap(\.metin))
        }
        let cubuklar = ZamanKadrani.yogunluk(k.sanatcilar,islenen:Set(0..<12))
        let beklenen = try XCTUnwrap(c["cubuklar"]?.dizi)
        XCTAssertEqual(cubuklar.count,beklenen.count)
        for (d,x) in zip(cubuklar,beklenen) {
            let satir = try XCTUnwrap(x.dizi)
            XCTAssertEqual(d.sayi,satir[0].tamSayi)
            XCTAssertEqual(d.akim,satir[1].metin)
            XCTAssertEqual(d.acik,satir[2].mantik)
        }
    }
}

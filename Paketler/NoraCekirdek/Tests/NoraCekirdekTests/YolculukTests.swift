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

    /// `tanismaGrubuGoruldu`, `tanitimGoruldu`, `bolumSonucuIsle`: kâhindeki sırayla aynı kayıt ve aynı dönüşler
    func testBolumKaydi() throws {
        let c = try cevaplar()
        var il = try Ilerleme(json: .nesne(.bos))
        BolumKurallari.grubuGoruldu(&il, id: "2-1", orta: false, grup: 1, adet: 2)
        XCTAssertEqual(BolumKurallari.gorulenGruplar(BolumKurallari.kayit(il, "2-1"), orta: false, adet: 2), [1])
        BolumKurallari.grubuGoruldu(&il, id: "2-1", orta: false, grup: 0, adet: 2)
        BolumKurallari.tanitimGoruldu(&il, id: "2-1", orta: true)
        let adimlar: [(String, Int, Int)] = [("kolay", 6, 8), ("kolay", 4, 8), ("orta", 7, 10), ("orta", 8, 10), ("zor", 0, 0)]
        let beklenen = try XCTUnwrap(c["sonuclar"]?.dizi)
        XCTAssertEqual(beklenen.count, adimlar.count)
        for (a, x) in zip(adimlar, beklenen) {
            let r = BolumKurallari.sonucuIsle(&il, id: "2-1", seviye: a.0, dogru: a.1, toplam: a.2)
            XCTAssertEqual(r.oran, x["oran"]?.sayi)
            XCTAssertEqual(r.gecti, x["gecti"]?.mantik)
            XCTAssertEqual(r.yeniGecti, x["yeniGecti"]?.mantik)
            XCTAssertEqual(r.yildizOnce, x["yildizOnce"]?.tamSayi)
            XCTAssertEqual(r.yildizSonra, x["yildizSonra"]?.tamSayi)
        }
        let kayit = try XCTUnwrap(c["sonuc"]?["bolumler"]?["2-1"]?.nesne)
        let bizim = BolumKurallari.kayit(il, "2-1")
        XCTAssertEqual(Set(bizim.anahtarlar), Set(kayit.anahtarlar))
        for k in kayit.anahtarlar { XCTAssertEqual(bizim[k], kayit[k], k) }
        XCTAssertEqual(BolumKurallari.yildiz(bizim), 2)
        XCTAssertEqual(BolumKurallari.gorulenGruplar(bizim, orta: true, adet: 3), [0, 1, 2])
    }
}

// Kaynak: sanat-atlasi js/{devam,soruTurlari,oturum,leitner}.js @ a866b86
// C1b: ek turların (kurs bölümü, ikonografi) şıkları ve yarım turun kaydedilip sürdürülmesi.
// Ek tur cevapları: Testler/kahin/pekistir_ek.mjs (sitenin a866b86 modülleri).
import XCTest
@testable import NoraCekirdek

final class PekistirmeEkranAkisiTests: XCTestCase {
    func testSoruTurlariVeGeriDonusKahini() throws {
        let gun = "2026-11-21"
        let ids = ["a", "b", "c", "d", "e"]
        let rng: PekistirmeRastgele = { 0.42 }
        let konular = ids.enumerated().map { (id: $0.element, tur: $0.offset < 3 ? "din" : "tarih") }
        let bolum = SoruTuru.bolumSecenekleri(dogru: "c", siraliBolumler: ids, rastgele: rng)
        let konu = SoruTuru.konuSecenekleri(dogru: "a", konular: konular, rastgele: rng)
        XCTAssertEqual(bolum, ["d", "c", "a", "b"])
        XCTAssertEqual(konu, ["b", "a", "e", "c"])
        for kip in [SoruTuru.kursBolumu, .ikonografi] {
            var il = try Ilerleme(veri: Data("{}".utf8))
            XCTAssertEqual(kip.kartlar(adaylar: ids, ilerleme: il, bugun: gun, rastgele: rng), ["e", "a", "d", "b", "c"])
            var oturum = PekistirmeOturumu(ids)
            kip.cevapla(oturum: &oturum, konum: 0, dogru: false, akim: nil, bugun: gun, ilerleme: &il, rastgele: rng)
            let skor = try XCTUnwrap(kip == .ikonografi ? il.skorlarKonu["a"] : il.skorlar["a"]?.bolumKart)
            XCTAssertEqual(skor.kutu, 0)
            XCTAssertEqual(skor.sonraki, gun)
            XCTAssertEqual(skor.yanlis, 1)
            if kip == .ikonografi { XCTAssertNil(il.skorlar["a"]) } else { XCTAssertNil(il.skorlarKonu["a"]) }
            let geri = try JSONDecoder().decode(PekistirmeOturumu.self, from: JSONEncoder().encode(oturum))
            XCTAssertEqual(geri.kuyruk.map { $0.id + ($0.tekrar ? "*" : "") }, ["a", "b", "c", "d", "e", "a*"])
            XCTAssertEqual(geri.konum, 1)
            XCTAssertEqual(geri.yanlis, 1)
        }
    }

    func testIkiSorununArasindaVeCevapYapragindaSurdur() throws {
        let (_, katalog) = try XCTUnwrap(SiteVerisiTests.hazir)
        let veri = PekistirmeVerileri(ikonografi: nil, zorluk: nil)
        var il = try Ilerleme(veri: Data("{}".utf8))
        il.islenen = katalog.konular.map(\.no)
        let gun = "2026-11-21"
        var tur = TurKaydi(kip: .sanatci(.karisik), seviye: nil, katalog: katalog, veri: veri, ilerleme: il, gun: gun)
        tur.hazirla(katalog: katalog, veri: veri, ilerleme: &il)
        let ilk = try XCTUnwrap(tur.kart)
        tur.cevapla(nil, katalog: katalog, gun: gun, ilerleme: &il)
        func geri(_ tur: TurKaydi) throws -> TurKaydi {
            try JSONDecoder().decode(TurKaydi.self, from: JSONEncoder().encode(tur))
        }
        tur = try geri(tur)
        XCTAssertEqual(tur.kart?.resim.eser.anahtar, ilk.resim.eser.anahtar)
        XCTAssertEqual(tur.kart?.secenekler, ilk.secenekler)
        XCTAssertTrue(tur.kart?.bilmiyorum == true)
        XCTAssertEqual(tur.oturum.konum, 0)
        tur.sonraki(katalog: katalog, veri: veri, ilerleme: &il)
        tur = try geri(tur)
        XCTAssertTrue(tur.kart?.ikinci == true)
        let akim = try XCTUnwrap(katalog.harita[ilk.dogru]?.akim)
        tur.cevapla(akim, katalog: katalog, gun: gun, ilerleme: &il)
        tur = try geri(tur)
        XCTAssertEqual(tur.kart?.sonuc, true)
        XCTAssertEqual(tur.oturum.yanlis, 1)
        XCTAssertEqual(tur.oturum.konum, 1)
        let sonuc = il
        tur.cevapla(akim, katalog: katalog, gun: gun, ilerleme: &il)
        XCTAssertEqual(il, sonuc)
        XCTAssertEqual(il.gunluk.kart, 1)
    }
}

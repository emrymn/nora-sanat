import Foundation
import XCTest
@testable import NoraCekirdek

/// Z4e · Hikâyeler 4. tur: öne çıkanlar, devam et, arşiv (dönem), beğeni/sonra oku, sıradaki ve çaların bölüm işaretleri.
/// Örnek: `Ornekler/hikayeler/` (Vermeer, Van Gogh, Rembrandt; üçü de 2026-11-26).
final class HikayeVitriniTests: XCTestCase {
    private func ornek(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: ad, withExtension: "json", subdirectory: "Ornekler/hikayeler"))
        return try Data(contentsOf: url)
    }

    private func hikayeler() throws -> [SanatciHikayesi] { HikayeVerisi.coz(try ornek("sanatci_hikayeleri")) }
    private func dizin() throws -> SesDizini { try XCTUnwrap(SesDizini(veri: try ornek("ses_dizini"))) }

    private func gun(_ s: String) -> Date {
        var c = DateComponents()
        c.year = Int(s.prefix(4)); c.month = Int(s.dropFirst(5).prefix(2)); c.day = Int(s.suffix(2)); c.hour = 12
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    /// Üç örneğe farklı günler: Van Gogh en yeni, Rembrandt ile Vermeer aynı gün (dosyada sonra gelen Rembrandt önce)
    private func tarihli() throws -> [SanatciHikayesi] {
        var l = try hikayeler()
        XCTAssertEqual(l.map(\.id), ["johannes-vermeer", "vincent-van-gogh", "rembrandt-van-rijn"])
        l[0].olusturma = "2026-11-24"
        l[1].olusturma = "2026-11-27"
        l[2].olusturma = "2026-11-24"
        return l
    }

    func testEnYeniVeOneCikanlar() throws {
        let l = try tarihli()
        XCTAssertEqual(HikayeVitrini.enYeni(l).map(\.id), ["vincent-van-gogh", "rembrandt-van-rijn", "johannes-vermeer"])
        // Aynı günde hepsi: dosyanın sonundaki önce
        XCTAssertEqual(HikayeVitrini.enYeni(try hikayeler()).map(\.id),
                       ["rembrandt-van-rijn", "vincent-van-gogh", "johannes-vermeer"])
        let bitti = ["vincent-van-gogh": OkumaYeri(paragraf: 30, toplam: 30, bitti: true)]
        XCTAssertEqual(HikayeVitrini.oneCikanlar(l, yerler: bitti).map(\.id), ["rembrandt-van-rijn", "johannes-vermeer"])
        XCTAssertEqual(HikayeVitrini.oneCikanlar(l, yerler: [:], enCok: 1).map(\.id), ["vincent-van-gogh"])
    }

    func testYeniEtiketiYalnizEnYenilerde() throws {
        let l = try tarihli()
        XCTAssertEqual(HikayeVitrini.yeniler(l, bugun: gun("2026-11-27"), enCok: 2), ["vincent-van-gogh", "rembrandt-van-rijn"])
        // 7 günü geçen etiket almaz
        XCTAssertEqual(HikayeVitrini.yeniler(l, bugun: gun("2026-11-28"), enCok: 4).count, 3)
        XCTAssertEqual(HikayeVitrini.yeniler(l, bugun: gun("2026-12-01"), enCok: 4), ["vincent-van-gogh"])
    }

    func testDevamEt() throws {
        let l = try hikayeler()
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        let yerler: [String: OkumaYeri] = [
            "johannes-vermeer": OkumaYeri(paragraf: 5, toplam: 30, tarih: t0),
            "vincent-van-gogh": OkumaYeri(paragraf: 2, toplam: 30, parca: 7, an: 3, tarih: t0.addingTimeInterval(60)),
            "rembrandt-van-rijn": OkumaYeri(paragraf: 30, toplam: 30, bitti: true, tarih: t0.addingTimeInterval(90)),
        ]
        let d = HikayeVitrini.devamEt(l, yerler: yerler)
        XCTAssertEqual(d.map(\.hikaye.id), ["vincent-van-gogh", "johannes-vermeer"])
        XCTAssertEqual(d.map(\.dinleme), [true, false])
        XCTAssertTrue(HikayeVitrini.devamEt(l, yerler: [:]).isEmpty)
    }

    func testDonemlerDogumYuzyilinaGore() throws {
        let l = try hikayeler()
        let dogum = ["johannes-vermeer": 1632, "vincent-van-gogh": 1853, "rembrandt-van-rijn": 1606]
        let g = HikayeVitrini.donemler(l) { dogum[$0] }
        XCTAssertEqual(g.map(\.baslik), ["XVII. yüzyıl", "XIX. yüzyıl"])
        XCTAssertEqual(g[0].hikayeler.map(\.id), ["rembrandt-van-rijn", "johannes-vermeer"])
        XCTAssertEqual(HikayeVitrini.donemler(l) { $0 == "vincent-van-gogh" ? nil : dogum[$0] }.last?.baslik, "Diğer")
        XCTAssertEqual(HikayeVitrini.yuzyil(1267), 13)
        XCTAssertEqual(HikayeVitrini.yuzyil(1300), 13)
        XCTAssertEqual(HikayeVitrini.yuzyil(1301), 14)
        XCTAssertEqual(HikayeVitrini.roma(14), "XIV")
        XCTAssertEqual(HikayeVitrini.roma(19), "XIX")
    }

    func testBegeniVeSonraOku() throws {
        let l = try hikayeler()
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        var k = HikayeKitapligi()
        XCTAssertTrue(k.begen("johannes-vermeer", tarih: t0))
        XCTAssertTrue(k.begen("rembrandt-van-rijn", tarih: t0.addingTimeInterval(5)))
        XCTAssertEqual(k.begenilenler(l).map(\.id), ["rembrandt-van-rijn", "johannes-vermeer"])
        XCTAssertFalse(k.begen("johannes-vermeer"))
        XCTAssertFalse(k.begenildi("johannes-vermeer"))
        XCTAssertTrue(k.sonraOkuDegistir("vincent-van-gogh", tarih: t0))
        XCTAssertTrue(k.sonraOkuDegistir("johannes-vermeer", tarih: t0.addingTimeInterval(1)))
        XCTAssertEqual(k.sonraOkunacaklar(l, yerler: [:]).map(\.id), ["johannes-vermeer", "vincent-van-gogh"])
        // Bitirilen yazı listede görünmez
        let bitti = ["johannes-vermeer": OkumaYeri(paragraf: 30, toplam: 30, bitti: true)]
        XCTAssertEqual(k.sonraOkunacaklar(l, yerler: bitti).map(\.id), ["vincent-van-gogh"])
        // Kayıt-geri okuma
        let v = try JSONEncoder().encode(k)
        XCTAssertEqual(try JSONDecoder().decode(HikayeKitapligi.self, from: v), k)
    }

    func testSiradaki() throws {
        let l = try tarihli()   // en yeni: van gogh, rembrandt, vermeer
        XCTAssertEqual(HikayeVitrini.siradaki(l, simdiki: "vincent-van-gogh", yerler: [:]).map(\.id),
                       ["rembrandt-van-rijn", "johannes-vermeer"])
        // Sona gelince başa döner; bitirilen atlanır
        let bitti = ["rembrandt-van-rijn": OkumaYeri(paragraf: 30, toplam: 30, bitti: true)]
        XCTAssertEqual(HikayeVitrini.siradaki(l, simdiki: "johannes-vermeer", yerler: bitti).map(\.id),
                       ["vincent-van-gogh"])
    }

    func testBolumIsaretleri() throws {
        let d = try dizin()
        for h in try hikayeler() {
            let p = HikayeSesi.parcalar(h)
            let s = HikayeSesi.sureler(p, dizin: d)
            let l = HikayeSesi.bolumIsaretleri(h, parcalar: p, sureler: s)
            // Giriş, dolu bölümler, kapanış (Rembrandt'ın boş "Kapanış" bölümü kapanışla birleşir: tek "Kapanış")
            let dolu = h.bolumler.filter { !$0.paragraflar.isEmpty }.map(\.baslik)
            XCTAssertEqual(l.map(\.ad), ["Giriş"] + dolu + ["Kapanış"], h.id)
            XCTAssertEqual(l.first?.bas, 0)
            XCTAssertEqual(l.map(\.sure).reduce(0, +), s.reduce(0, +), accuracy: 0.001, h.id)
            XCTAssertTrue(zip(l, l.dropFirst()).allSatisfy { $0.bas < $1.bas }, h.id)
            // Bölüm işaretinin parçası bölüm başlığı
            for i in l where i.bolum != nil { XCTAssertEqual(p[i.parca].yer, .bolumBasligi(i.bolum!)) }
            // Anın işareti
            XCTAssertEqual(HikayeSesi.isaret(l, gecen: 0), 0)
            XCTAssertEqual(HikayeSesi.isaret(l, gecen: l[2].bas + 1), 2)
            XCTAssertEqual(HikayeSesi.isaret(l, gecen: s.reduce(0, +)), l.count - 1)
        }
    }
}

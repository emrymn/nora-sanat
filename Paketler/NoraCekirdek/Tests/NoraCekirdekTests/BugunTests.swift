// Kaynak: sanat-atlasi js/yuruyus.js, js/egim.js @ a866b86
import XCTest

@testable import NoraCekirdek

final class BugunTests: XCTestCase {
  struct Cevaplar: Decodable {
    struct Kutu: Decodable { let x, y, w, h: Double }
    struct Durus: Decodable {
      let cx, cy, s, vy, gor: Double
      let kartUstte: Bool
    }
    struct Nokta: Decodable {
      let IW, IH, kartH: Double
      let n: Kutu
      let sonuc: Durus
    }
    struct Egim: Decodable { let hiz, x, y: Double }
    let noktalar: [Nokta]
    let egim: [Egim]
  }
  func testSiteninKamerasiVeJiroskopu() throws {
    let url = try XCTUnwrap(
      Bundle.module.url(
        forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/bugun"))
    let c = try JSONDecoder().decode(Cevaplar.self, from: Data(contentsOf: url))
    for ornek in c.noktalar {
      let k = YuruyusKamerasi(
        ekran: CGSize(width: 393, height: 852), oran: ornek.IW / ornek.IH,
        kirp: [0.03, 0.04, 0.94, 0.92])
      let n = ornek.n
      let a = k.nokta(
        CGRect(x: n.x, y: n.y, width: n.w, height: n.h), kart: ornek.kartH, ust: 68, alt: 112)
      XCTAssertEqual(a.merkez.x, ornek.sonuc.cx, accuracy: 1e-8)
      XCTAssertEqual(a.merkez.y, ornek.sonuc.cy, accuracy: 1e-8)
      XCTAssertEqual(a.hedefY, ornek.sonuc.vy, accuracy: 1e-8)
      XCTAssertEqual(a.olcek, ornek.sonuc.s, accuracy: 1e-8)
      XCTAssertEqual(a.gorunen, ornek.sonuc.gor, accuracy: 1e-8)
      XCTAssertEqual(a.kartUstte, ornek.sonuc.kartUstte)
    }
    var egim = YuruyusEgimi()
    for e in c.egim {
      let n = egim.izle(hiz: CGPoint(x: e.hiz, y: -e.hiz), sure: 0.2)
      XCTAssertEqual(n.x, e.x, accuracy: 1e-8)
      XCTAssertEqual(n.y, e.y, accuracy: 1e-8)
    }
  }

  /// Aynı tarihte Ayarlar'dan değiştirilen sanatçı, eski değişim ve geçersiz kimlik.
  /// Beklenen ad, eser, yıl ve görsel sitenin gunun_tablosu.mjs kâhininden.
  func testGununDegisimiVeGoruntuleyiciEseri() throws {
    let (_, katalog) = try XCTUnwrap(SiteVerisiTests.hazir)
    let veriler = try Dictionary(
      uniqueKeysWithValues: GununTablosuCozucu.dosyalar.map { ad in
        (ad, try SiteVerisiTests.dosya(ad))
      })
    struct Site: Decodable {
      struct Tablo: Decodable {
        let eser: String
        let yil: Int?
        let gorsel: URL?
      }
      let tablo: [String: Tablo]
      let secim: [[String]]
    }
    let url = try XCTUnwrap(
      Bundle.module.url(forResource: "Ornekler/site_cevaplari", withExtension: "json"))
    let cevap = try JSONDecoder().decode(Site.self, from: Data(contentsOf: url))
    let gun = cevap.secim[0][0]
    let normal = cevap.secim[0][1]
    let baska = cevap.secim[1][1]
    for (tarih, id, beklenen) in [
      (gun, baska, baska), ("2000-01-01", baska, normal), (gun, "yok", normal),
    ] {
      let degisim = JSONDeger.nesne([("tarih", .metin(tarih)), ("id", .metin(id))])
      let s = try BugunTablosu(tarih: gun, degisim: degisim, veriler: veriler, katalog: katalog)
      XCTAssertEqual(s.tablo.sanatciId, beklenen)
      let e = try XCTUnwrap(cevap.tablo[beklenen])
      XCTAssertEqual(s.tablo.eser, e.eser)
      XCTAssertEqual(s.tablo.yil, e.yil)
      XCTAssertEqual(s.tablo.gorsel, e.gorsel)
      let eser = try XCTUnwrap(s.eser)
      XCTAssertTrue(eser.gorseller.contains { katalog.gorsel.yerelAd($0) == s.kayit.gorsel })
    }
  }
}

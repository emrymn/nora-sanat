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
    struct Kare: Decodable { let adim, x, y, s: Double }
    let kareler: [Kare]
    let izleme: [Double]
    struct Tur: Decodable { let adet: Int; let adres, baslik, alt: String }
    let turlar: [Tur]
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
    let kamera = YuruyusKamerasi(ekran: CGSize(width: 393, height: 852), oran: 2, kirp: [0.03,0.04,0.94,0.92])
    let duruslar = kamera.duruslar(odak: CGPoint(x: 0.31, y: 0.38), yakin: 1.25,
      noktalar: [CGRect(x: 0.28, y: 0.48, width: 0.32, height: 0.16)], kartBoylari: [2:104],
      ust: 68, alt: 112, taninma: true)
    for kare in c.kareler {
      let i = Int(kare.adim)
      let d = duruslar[i].ara(duruslar[min(i+1,3)], pay: kare.adim - Double(i))
      let r = kamera.cerceve(d, buyut: 1, egim: nil)
      XCTAssertEqual(r.minX, kare.x, accuracy: 0.051)
      XCTAssertEqual(r.minY, kare.y, accuracy: 0.051)
      XCTAssertEqual(r.width / 4000, kare.s, accuracy: 0.0000051)
    }
    var iz = 0.0
    for beklenen in c.izleme {
      iz = YuruyusKamerasi.sonrakiKare(iz, hedef: 1)
      XCTAssertEqual(iz, beklenen, accuracy: 1e-8)
    }
    for e in c.turlar {
      let tur = BugunTuru(adet: e.adet)
      XCTAssertEqual(tur.baslik, e.baslik)
      XCTAssertEqual(tur.alt, e.alt)
      XCTAssertEqual(tur.adres, e.adres)
    }
    var egim = YuruyusEgimi()
    for e in c.egim {
      let n = egim.izle(hiz: CGPoint(x: e.hiz, y: -e.hiz), sure: 0.2)
      XCTAssertEqual(n.x, e.x, accuracy: 1e-8)
      XCTAssertEqual(n.y, e.y, accuracy: 1e-8)
    }
  }

  /// js/egim.js ciz(): anlik = anlik + (hedef - anlik) * 0.2 (TABLO_IZ)
  func testEgimYumusatici() {
    var y = EgimYumusatici()
    XCTAssertEqual(y.izle(CGPoint(x: 1, y: -0.5)).x, 0.2, accuracy: 1e-12)
    let ikinci = y.izle(CGPoint(x: 1, y: -0.5))
    XCTAssertEqual(ikinci.x, 0.36, accuracy: 1e-12)
    XCTAssertEqual(ikinci.y, -0.18, accuracy: 1e-12)
    for _ in 0..<60 { _ = y.izle(.zero) }
    XCTAssertEqual(y.anlik.x, 0, accuracy: 1e-4)
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
  /// Yürüyüş sonundaki künye sitenin `kunye(gs, { bag: false, konuYok: true })` çıktısıyla aynı
  /// (canlı sitede `.yur-son-kunye`: "1431–1506 · Erken Rönesans").
  func testYuruyusSonuKunyesi() throws {
    let (_, katalog) = try XCTUnwrap(SiteVerisiTests.hazir)
    let veriler = try Dictionary(
      uniqueKeysWithValues: GununTablosuCozucu.dosyalar.map { ad in
        (ad, try SiteVerisiTests.dosya(ad))
      })
    let degisim = JSONDeger.nesne([("tarih", .metin("2026-11-22")), ("id", .metin("andrea-mantegna"))])
    let s = try BugunTablosu(tarih: "2026-11-22", degisim: degisim, veriler: veriler, katalog: katalog)
    XCTAssertEqual(s.tablo.sanatciId, "andrea-mantegna")
    XCTAssertEqual(s.sonKunye, "1431–1506 · Erken Rönesans")
  }
}

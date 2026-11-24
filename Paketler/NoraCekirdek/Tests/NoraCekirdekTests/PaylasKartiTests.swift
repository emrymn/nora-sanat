// Z3v: Bugün paylaş kartının geometrisi (yeni özellik, sitede karşılığı yok: davranış testi)
import XCTest

@testable import NoraCekirdek

final class PaylasKartiTests: XCTestCase {
  private func esit(_ a: CGRect?, _ b: CGRect, _ d: Double = 1e-6, file: StaticString = #filePath, line: UInt = #line) {
    guard let a else { return XCTFail("nil", file: file, line: line) }
    XCTAssertEqual(a.minX, b.minX, accuracy: d, file: file, line: line)
    XCTAssertEqual(a.minY, b.minY, accuracy: d, file: file, line: line)
    XCTAssertEqual(a.width, b.width, accuracy: d, file: file, line: line)
    XCTAssertEqual(a.height, b.height, accuracy: d, file: file, line: line)
  }

  func testKirpimGecersizseButunTablo() {
    XCTAssertEqual(PaylasKarti.kirpim(nil), CGRect(x: 0, y: 0, width: 1, height: 1))
    XCTAssertEqual(PaylasKarti.kirpim([0.1, 0.2]), CGRect(x: 0, y: 0, width: 1, height: 1))
    XCTAssertEqual(PaylasKarti.kirpim([0.1, 0.2, 0, 0.5]), CGRect(x: 0, y: 0, width: 1, height: 1))
    XCTAssertEqual(PaylasKarti.kirpim([0.1, 1.2, 0.5, 0.5]), CGRect(x: 0, y: 0, width: 1, height: 1))
    esit(PaylasKarti.kirpim([0.1, 0.2, 0.5, 0.6]), CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.6))
    // Tablonun dışına taşan kırpım tablonun kenarında kesilir
    esit(PaylasKarti.kirpim([0.6, 0, 0.6, 1]), CGRect(x: 0.6, y: 0, width: 0.4, height: 1))
  }

  /// Yatay tablo, kırpım yok: tablo kutunun yüksekliğini kaplar; odak ortadaysa yatayda ortalanır
  func testCoverYerlesimOdakOrtada() {
    let y = PaylasKarti.yerlesim(
      resim: CGSize(width: 2000, height: 1000), kirp: PaylasKarti.kirpim(nil),
      kutu: CGSize(width: 1080, height: 1030), odak: CGPoint(x: 0.5, y: 0.5), hedef: CGPoint(x: 0.5, y: 0.5))
    esit(y, CGRect(x: (1080 - 2060) / 2, y: 0, width: 2060, height: 1030))
  }

  /// Odak kenara yakınsa tablo kırpımın dışını göstermez: kenara dayanır
  func testOdakKenardaSinirlanir() {
    let sol = PaylasKarti.yerlesim(
      resim: CGSize(width: 2000, height: 1000), kirp: PaylasKarti.kirpim(nil),
      kutu: CGSize(width: 1080, height: 1030), odak: CGPoint(x: 0.02, y: 0.5), hedef: CGPoint(x: 0.5, y: 0.5))
    XCTAssertEqual(sol.minX, 0, accuracy: 1e-9)
    let sag = PaylasKarti.yerlesim(
      resim: CGSize(width: 2000, height: 1000), kirp: PaylasKarti.kirpim(nil),
      kutu: CGSize(width: 1080, height: 1030), odak: CGPoint(x: 0.98, y: 0.5), hedef: CGPoint(x: 0.5, y: 0.5))
    XCTAssertEqual(sag.maxX, 1080, accuracy: 1e-9)
    // Odak hedefe birebir gelir (sınır yokken): x = 0.3 · 2060 kutuda 540'a
    let ara = PaylasKarti.yerlesim(
      resim: CGSize(width: 2000, height: 1000), kirp: PaylasKarti.kirpim(nil),
      kutu: CGSize(width: 1080, height: 1030), odak: CGPoint(x: 0.4, y: 0.5), hedef: CGPoint(x: 0.5, y: 0.5))
    XCTAssertEqual(ara.minX + 0.4 * ara.width, 540, accuracy: 1e-9)
  }

  /// Kırpım varsa kutuyu kırpım kaplar ve tablo kırpımın dışına kaymaz
  func testKirpimKaplanir() {
    let k = CGRect(x: 0.1, y: 0.2, width: 0.6, height: 0.5)
    let resim = CGSize(width: 1000, height: 1000)
    let kutu = CGSize(width: 1080, height: 756)
    let y = PaylasKarti.yerlesim(resim: resim, kirp: k, kutu: kutu, odak: CGPoint(x: 0, y: 0), hedef: CGPoint(x: 0.5, y: 0.42))
    // ölçek: max(1080/600, 756/500) = 1.8
    XCTAssertEqual(y.width, 1800, accuracy: 1e-9)
    // Odak sol üstte: kırpımın sol üst köşesi kutunun sol üstüne dayanır
    XCTAssertEqual(y.minX, -0.1 * 1800, accuracy: 1e-9)
    XCTAssertEqual(y.minY, -0.2 * 1800, accuracy: 1e-9)
    let kirpimKutuda = PaylasKarti.alan(k, yerlesim: y)
    XCTAssertLessThanOrEqual(kirpimKutuda.minX, 0)
    XCTAssertLessThanOrEqual(kirpimKutuda.minY, 0)
    XCTAssertGreaterThanOrEqual(kirpimKutuda.maxX, kutu.width - 1e-9)
    XCTAssertGreaterThanOrEqual(kirpimKutuda.maxY, kutu.height - 1e-9)
  }

  /// Noktanın kutudaki yeri, tablonun çizildiği dikdörtgene göre: kırpım ve odak değişince çerçeve tabloyla birlikte kayar
  func testNoktaKutuya() {
    let y = CGRect(x: -100, y: -50, width: 2000, height: 1600)
    esit(
      PaylasKarti.alan(CGRect(x: 0.13, y: 0.55, width: 0.28, height: 0.35), yerlesim: y),
      CGRect(x: -100 + 260, y: -50 + 880, width: 560, height: 560))
  }

  /// Tasarımdaki örnek (Yıldızlı Gece 1280×1014, servi 13/55/28/35): Bugün odağı gökte; çerçeve görünür payda
  func testKapakCercevesi() throws {
    let resim = CGSize(width: 1280, height: 1014)
    let servi = CGRect(x: 0.13, y: 0.55, width: 0.28, height: 0.35)
    for boy in PaylasKarti.Boy.allCases {
      let k = PaylasKarti.kapak(resim: resim, kirp: nil, odak: CGPoint(x: 0.5, y: 0.4), nokta: servi, boy: boy)
      let c = try XCTUnwrap(k.cerceve, "\(boy)")
      esit(c, PaylasKarti.alan(servi, yerlesim: k.resim))
      XCTAssertGreaterThanOrEqual(c.minY, -0.5)
      XCTAssertLessThanOrEqual(c.maxY, boy.kapak.height * boy.gorunurAlt + 0.5)
      // Tablo kapağı kaplar
      XCTAssertLessThanOrEqual(k.resim.minX, 0)
      XCTAssertLessThanOrEqual(k.resim.minY, 0)
      XCTAssertGreaterThanOrEqual(k.resim.maxX, boy.kapak.width - 1e-9)
      XCTAssertGreaterThanOrEqual(k.resim.maxY, boy.kapak.height - 1e-9)
    }
  }

  /// Ayrıntı Bugün'ün odağıyla kapağın dışına düşerse odak ayrıntıya alınır
  func testAyrintiDisardaysaOdakAyrintiya() throws {
    // Dikey tablo; odak üstte, ayrıntı en altta
    let resim = CGSize(width: 800, height: 2000)
    let nokta = CGRect(x: 0.4, y: 0.6, width: 0.2, height: 0.1)
    let odakla = PaylasKarti.yerlesim(
      resim: resim, kirp: PaylasKarti.kirpim(nil), kutu: PaylasKarti.Boy.hikaye.kapak,
      odak: CGPoint(x: 0.5, y: 0.2), hedef: PaylasKarti.Boy.hikaye.hedef)
    XCTAssertGreaterThan(PaylasKarti.alan(nokta, yerlesim: odakla).minY, PaylasKarti.Boy.hikaye.kapak.height)
    let k = PaylasKarti.kapak(resim: resim, kirp: nil, odak: CGPoint(x: 0.5, y: 0.2), nokta: nokta, boy: .hikaye)
    let c = try XCTUnwrap(k.cerceve)
    XCTAssertEqual(c.midY, PaylasKarti.Boy.hikaye.kapak.height * PaylasKarti.Boy.hikaye.hedef.y, accuracy: 1e-6)
    XCTAssertNotEqual(k.resim, odakla)
  }

  /// Ayrıntı kapağa hiç sığmıyorsa (kapaktan büyük) çerçeve yok; ayrıntı yoksa yalnız odak
  func testSigmayanAyrintiCercevesiz() {
    let resim = CGSize(width: 1000, height: 1000)
    let buyuk = CGRect(x: 0, y: 0, width: 1, height: 1)
    XCTAssertNil(PaylasKarti.kapak(resim: resim, kirp: nil, odak: CGPoint(x: 0.5, y: 0.5), nokta: buyuk, boy: .gonderi).cerceve)
    let yok = PaylasKarti.kapak(resim: resim, kirp: nil, odak: CGPoint(x: 0.5, y: 0.5), nokta: nil, boy: .gonderi)
    XCTAssertNil(yok.cerceve)
    XCTAssertEqual(
      yok.resim,
      PaylasKarti.yerlesim(
        resim: resim, kirp: PaylasKarti.kirpim(nil), kutu: PaylasKarti.Boy.gonderi.kapak,
        odak: CGPoint(x: 0.5, y: 0.5), hedef: PaylasKarti.Boy.gonderi.hedef))
  }

  func testKareKirpim() {
    let resim = CGSize(width: 1280, height: 1014)
    // Servi: 358.4 × 354.9 px → kare kenar 358.4 · 1.12
    let k = PaylasKarti.kareKirpim(CGRect(x: 0.13, y: 0.55, width: 0.28, height: 0.35), resim: resim)
    XCTAssertEqual(k.width, k.height)
    XCTAssertEqual(k.width, 358.4 * 1.12, accuracy: 1e-6)
    // Alt kenara taşmaz (ortası 0.725 · 1014 = 735; yarım kenar ~200 → 935 < 1014)
    XCTAssertLessThanOrEqual(k.maxY, 1014 + 1e-9)
    XCTAssertEqual(k.midX, 0.27 * 1280, accuracy: 1e-6)
    // Kenardaki ayrıntı: kare tablonun içinde kalır
    let kose = PaylasKarti.kareKirpim(CGRect(x: 0.95, y: 0.95, width: 0.05, height: 0.05), resim: resim)
    XCTAssertEqual(kose.maxX, 1280, accuracy: 1e-9)
    XCTAssertEqual(kose.maxY, 1014, accuracy: 1e-9)
    // Tablodan büyük ayrıntı: kısa kenar kadar, ortada
    let dev = PaylasKarti.kareKirpim(CGRect(x: 0, y: 0, width: 1, height: 1), resim: resim)
    XCTAssertEqual(dev, CGRect(x: 133, y: 0, width: 1014, height: 1014))
  }

  func testNoktaSirasiVeMetinler() {
    XCTAssertNil(PaylasKarti.noktaSirasi(adim: 3, noktaSayisi: 0))
    XCTAssertEqual(PaylasKarti.noktaSirasi(adim: 0, noktaSayisi: 3), 0)  // kapak → ilk
    XCTAssertEqual(PaylasKarti.noktaSirasi(adim: 1, noktaSayisi: 3), 0)  // künye → ilk
    XCTAssertEqual(PaylasKarti.noktaSirasi(adim: 3, noktaSayisi: 3), 1)
    XCTAssertEqual(PaylasKarti.noktaSirasi(adim: 4, noktaSayisi: 3), 2)
    XCTAssertEqual(PaylasKarti.noktaSirasi(adim: 5, noktaSayisi: 3), 0)  // tanıma → ilk
    XCTAssertEqual(PaylasKarti.dosyaAdi(tarih: "2026-11-24"), "nora-sanat-2026-11-24.png")
    let t = GununTablosu(tarih: "2026-11-24", sanatciId: "x", sanatci: "Vincent van Gogh", eser: "Yıldızlı Gece", yil: 1889, gorsel: nil)
    XCTAssertEqual(PaylasKarti.sanatciYil(t), "Vincent van Gogh · 1889")
    var y = t
    y.yil = nil
    XCTAssertEqual(PaylasKarti.sanatciYil(y), "Vincent van Gogh")
  }
}

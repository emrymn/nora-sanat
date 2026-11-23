import Foundation
import XCTest
@testable import NoraCekirdek

/// Z3c: Başyapıt zemininin iki rengi (kullanıcının tasarım tuvali)
final class TabloRenkleriTests: XCTestCase {
    func ton(_ c: RGBA) -> Double { TabloRenkleri.hsl(c.r, c.g, c.b).0 }
    func tonFarki(_ a: Double, _ b: Double) -> Double { let d = abs(a - b).truncatingRemainder(dividingBy: 360); return min(d, 360 - d) }

    /// Elçiler'in küçük kopyası (24 × 24): tasarımdaki gibi biri kırmızı-kahve, öbürü yeşil
    func testElciler() throws {
        let url = Bundle.module.url(forResource: "elciler", withExtension: "json", subdirectory: "Ornekler/tablo_renkleri")!
        let j = try JSONDeger.coz(Data(contentsOf: url))
        let px = j["pikseller"]!.dizi!.map { p in (p.dizi![0].sayi!, p.dizi![1].sayi!, p.dizi![2].sayi!) }
        let c = try XCTUnwrap(TabloRenkleri.cift(pikseller: px))
        let tonlar = [ton(c.birinci), ton(c.ikinci)]
        print("Elçiler:", c.birinci, c.ikinci, tonlar)
        // Tasarımdaki gibi sol üstte kırmızı-kahve (tasarım: 6°); ikinci ton ondan ayrık (tasarımda yeşil; tablonun
        // perdesi küçük kopyada zeytin yeşili)
        XCTAssertLessThan(tonFarki(tonlar[0], 6), 30, "\(tonlar)")
        XCTAssertGreaterThanOrEqual(tonFarki(tonlar[0], tonlar[1]), 45)
        for x in [c.birinci, c.ikinci] {
            let (_, s, l) = TabloRenkleri.hsl(x.r, x.g, x.b)
            XCTAssert((0.39...0.51).contains(l) && (0.44...0.66).contains(s), "\(x)")
        }
    }

    func testRenksizTablo() {
        let gri = (0..<100).map { i in (Double(i) / 100, Double(i) / 100, Double(i) / 100) }
        XCTAssertNil(TabloRenkleri.cift(pikseller: gri))
    }

    func testTekTon() throws {
        let mavi = (0..<100).map { i in (0.1, 0.2 + Double(i) / 400, 0.6) }
        let c = try XCTUnwrap(TabloRenkleri.cift(pikseller: mavi))
        XCTAssertNotEqual(c.birinci, c.ikinci)
    }
}

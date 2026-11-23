import Foundation
import XCTest
@testable import NoraCekirdek

/// Z2c: tekrar takvimi artık Swift'te (eski köprü betiğiyle aynı sayım). Örnekler: Testler/kahin/tekrar_takvimi.mjs.
final class TekrarTakvimiTests: XCTestCase {
    func testKahin() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/tekrar_takvimi"))
        let vakalar = try XCTUnwrap(JSONDeger.coz(Data(contentsOf: url))["vakalar"]?.dizi)
        XCTAssertEqual(vakalar.count, 300)
        for (i, v) in vakalar.enumerated() {
            let bugun = try XCTUnwrap(v["bugun"]?.metin)
            let t = TekrarTakvimi.hesapla(v["girdi"] ?? .bos, bugun: bugun)
            guard let c = v["cikti"], c.nesne != nil else { XCTAssertNil(t, "vaka \(i)"); continue }
            XCTAssertEqual(t?.bugun, c["bugun"]?.metin, "vaka \(i)")
            XCTAssertEqual(t?.gunler, c["gunler"]?.dizi?.compactMap(\.tamSayi), "vaka \(i)")
            XCTAssertEqual(t?.rozet, c["rozet"] == .mantik(true), "vaka \(i)")
        }
    }
}

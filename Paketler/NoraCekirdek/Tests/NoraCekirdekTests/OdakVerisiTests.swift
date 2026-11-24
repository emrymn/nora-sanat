import Foundation
import XCTest
@testable import NoraCekirdek

/// Z2c-3: odak önceliği ve yürüyüş ekleri (js/gorsel.js odakAdla, gorselOdakNoktasi, yuruyusEki)
final class OdakVerisiTests: XCTestCase {
    func veri(_ j: String) -> Data { Data(j.utf8) }

    func testOncelik() {
        let o = OdakVerisi(veriler: [
            "gorsel_odak.json": veri(#"{"odak":{"a":[10,20],"b":[30,40],"c":[50,60],"d":[1,2],"bozuk":[120,5]}}"#),
            "gorsel_odak_elle.json": veri(#"{"odak":{"b":[31,41],"c":[0,0]}}"#),
            "yuruyus_odak.json": veri(#"{"odak":{"a":[11,21],"d":[70,80]},"yakin":{"a":1.6,"b":"3","c":null},"kirp":{"a":[0.1,0.1,0.8,0.8],"b":[0,0,0.2,0.9],"c":[0,0,0.5,"x"]}}"#),
        ], cihaz: ["c": [99, 99]])
        XCTAssertEqual(o.adlaOdak("a"), [11, 21], "yürüyüş odağı otomatiğin önünde")
        XCTAssertEqual(o.odak("a"), [10, 20], "kırpımda yürüyüş odağı sayılmaz")
        XCTAssertEqual(o.adlaOdak("b"), [31, 41], "depodaki elle")
        XCTAssertEqual(o.adlaOdak("c"), [99, 99], "cihazdaki elle en önde")
        XCTAssertEqual(o.adlaOdak("d"), [70, 80])
        XCTAssertNil(o.adlaOdak("bozuk"), "0–100 dışı geçersiz")
        XCTAssertNil(o.adlaOdak("yok")); XCTAssertNil(o.adlaOdak(""))
        XCTAssertEqual(o.yuruyusEki("a").yakin, 1.6); XCTAssertEqual(o.yuruyusEki("a").kirp, [0.1, 0.1, 0.8, 0.8])
        XCTAssertEqual(o.yuruyusEki("b").yakin, 2.2, "metin sayı, en çok 2,2"); XCTAssertNil(o.yuruyusEki("b").kirp, "w ≤ 0,3")
        XCTAssertEqual(o.yuruyusEki("c").yakin, 1); XCTAssertNil(o.yuruyusEki("c").kirp, "sayı olmayan öğe")
        XCTAssertEqual(o.yuruyusEki("yok").yakin, 1)
        XCTAssertEqual(OdakVerisi.elleOdak([12.4, 120]), [12, 100])
        XCTAssertEqual(OdakVerisi.elleOdak([-3, 49.5]), [0, 50])
    }

    func testBaskaSanatci() {
        XCTAssertEqual(GununSanatcisi.baska(havuz: ["a"], haric: "a"), "a")
        XCTAssertEqual(GununSanatcisi.baska(havuz: ["a", "b", "c"], haric: "a", rastgele: { 0 }), "b")
        XCTAssertEqual(GununSanatcisi.baska(havuz: ["a", "b", "c"], haric: "a", rastgele: { 0.99 }), "c")
        XCTAssertEqual(GununTablosuCozucu.havuz(yuruyus: veri(#"{"eserler":{"x":{"noktalar":[1]},"y":{"noktalar":[]},"z":{}}}"#)), ["x"])
        XCTAssertEqual(GununTablosuCozucu.havuz(yuruyus: veri(#"{"eserler":{"x":{"noktalar":[1]},"b":{"bugun":false,"noktalar":[1]}}}"#)), ["x"])
    }
}

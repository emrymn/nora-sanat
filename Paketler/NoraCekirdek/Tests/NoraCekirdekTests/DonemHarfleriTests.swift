import Foundation
import XCTest
@testable import NoraCekirdek

/// Z3f: sitenin harf tablosu ve css2 adresi (js/harfler.js; örnekler sitenin modülüyle Node'da üretildi)
final class DonemHarfleriTests: XCTestCase {
    func testSiteninTablosuVeAdresler() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/harfler"))
        let j = try JSONDeger.coz(Data(contentsOf: url))
        func harf(_ x: JSONDeger) -> DonemHarfi {
            DonemHarfi(x["aile"]!.metin!, italik: x["italik"]?.dogruMu ?? false, kalinlik: x["kalinlik"]?.tamSayi,
                       olcek: x["olcek"]?.sayi ?? 1)
        }
        let ak = try XCTUnwrap(j["akimlar"]?.nesne)
        XCTAssertEqual(ak.ciftler.count, DonemHarfleri.akimlar.count)
        for c in ak.ciftler { XCTAssertEqual(DonemHarfleri.akimlar[c.anahtar], harf(c.deger), c.anahtar) }
        for c in try XCTUnwrap(j["bolgeler"]?.nesne).ciftler { XCTAssertEqual(DonemHarfleri.bolgeler[c.anahtar], harf(c.deger), c.anahtar) }
        for a in try XCTUnwrap(j["adresler"]?.dizi) {
            XCTAssertEqual(harf(a["harf"]!).adres(metin: a["metin"]!.metin!), a["adres"]!.metin!)
        }
    }
}

import Foundation
import XCTest
@testable import NoraCekirdek

/// Z3m: ekranın rengi (js/ekranlar/ortak.js ekranRengi, eserPaleti, renkleriYaz @ cca62eb) ve odaklı kırpma
/// (odakliGorsel: `object-fit: cover; object-position: x% y%`)
final class EkranRengiTests: XCTestCase {
    typealias P = ResimRengi.PaletRengi
    let palet = [P(renk: "#8a5a2b", pay: 0.4), P(renk: "#2b3a55", pay: 0.3), P(renk: "#d9c8a0", pay: 0.2), P(renk: "#101010", pay: 0.1)]

    func testEserPaleti() {
        XCTAssertEqual(ResimRengi.eserPaleti(palet, yedek: "#8A827A"), palet, "görsel açıldıysa kendi paleti")
        XCTAssertEqual(ResimRengi.eserPaleti(nil, yedek: "#8A827A"), [P(renk: "#8A827A", pay: 1)], "açılmadıysa yedek (akım rengi)")
        XCTAssertEqual(ResimRengi.eserPaleti([], yedek: "#C0392B"), [P(renk: "#C0392B", pay: 1)])
        XCTAssertNil(ResimRengi.eserPaleti(nil, yedek: nil), "pekiştirme kartı: yedek yok → nötr")
        XCTAssertNil(ResimRengi.eserPaleti(nil, yedek: ""))
    }

    func testEkraninRenkleri() throws {
        // palet yoksa (renkleriYaz(null)) temanın nötr değişkenleri
        XCTAssertEqual(TemaRenkleri.ekran(.gece, gunduz: nil, palet: nil), TemaRenkleri.gece)
        XCTAssertEqual(TemaRenkleri.ekran(.gunduz, gunduz: nil, palet: nil), TemaRenkleri.gunduz)
        // Gece'de Gündüz paleti yok sayılır
        let lapis = try XCTUnwrap(GunduzPaleti.hazir["lapis"])
        XCTAssertEqual(TemaRenkleri.ekran(.gece, gunduz: lapis, palet: palet), TemaRenkleri.ekran(.gece, gunduz: nil, palet: palet))
        // vurgu temanın zeminine göre (`renkTemasi(palet, temaZemini())`), geri kalan değişkenler temanınki
        for (tema, g) in [(TemaAdi.gece, nil), (.gunduz, nil), (.gunduz, lapis)] as [(TemaAdi, GunduzPaleti?)] {
            let r = TemaRenkleri.ekran(tema, gunduz: g, palet: palet)
            let v = try XCTUnwrap(ResimRengi.renkTemasi(palet, zemin: TemaRenkleri.zeminHex(tema, gunduz: g)))
            XCTAssertEqual(r, TemaRenkleri.hesapla(tema, gunduz: g, vurgu: v))
            XCTAssertEqual(r.vurgu, RGBA(css: v.vurgu))
            XCTAssertEqual(r.vurguAcik, RGBA(css: v.vurguAcik))
            let notr = TemaRenkleri.hesapla(tema, gunduz: g, vurgu: nil)
            for (css, yol) in TemaRenkleri.degiskenler where !css.hasPrefix("--vurgu") {
                XCTAssertEqual(r[keyPath: yol], notr[keyPath: yol], "\(tema) \(css)")
            }
        }
        // iki ayrı eserin rengi ayrı
        let mavi = [P(renk: "#1d3f8a", pay: 0.7), P(renk: "#e8e0c8", pay: 0.3)]
        XCTAssertNotEqual(TemaRenkleri.ekran(.gece, gunduz: nil, palet: mavi).vurgu, TemaRenkleri.ekran(.gece, gunduz: nil, palet: palet).vurgu)
    }

    func testOdakliYerlesim() throws {
        // dik tablo (3:4) geniş kutuda (300 × 150): genişliğe göre kaplar (300 × 400), 250 nokta taşar
        let ortadan = try XCTUnwrap(OdakliKirpim.yerlesim(dogal: (3, 4), kutu: (300, 150), odak: nil))
        XCTAssertEqual(ortadan, .init(x: 0, y: -125, w: 300, h: 400), "odak yoksa 50% 50%")
        let yuz = try XCTUnwrap(OdakliKirpim.yerlesim(dogal: (3, 4), kutu: (300, 150), odak: [40, 20]))
        XCTAssertEqual(yuz.x, 0); XCTAssertEqual(yuz.y, -50, accuracy: 1e-9, "taşan 250 × %20")
        XCTAssertEqual(try XCTUnwrap(OdakliKirpim.yerlesim(dogal: (3, 4), kutu: (300, 150), odak: [0, 0])).y, 0)
        XCTAssertEqual(try XCTUnwrap(OdakliKirpim.yerlesim(dogal: (3, 4), kutu: (300, 150), odak: [100, 100])).y, -250)
        // yatay tablo dar kutuda: yüksekliğe göre kaplar, yatayda kayar
        let yatay = try XCTUnwrap(OdakliKirpim.yerlesim(dogal: (2000, 1000), kutu: (100, 100), odak: [75, 10]))
        XCTAssertEqual(yatay, .init(x: -75, y: 0, w: 200, h: 100))
        // geçersiz odak (0–100 dışı) ortadan; boyu bilinmeyen görsel nil
        XCTAssertEqual(OdakliKirpim.yerlesim(dogal: (3, 4), kutu: (300, 150), odak: [120, 5]), ortadan)
        XCTAssertNil(OdakliKirpim.yerlesim(dogal: (0, 4), kutu: (300, 150), odak: nil))
    }

    func testEserinOdagi() throws {
        let adresler = GorselAdresleri(yerel: try JSONDeger.coz(Data(#"{"gorseller":{"commons:A.jpg":"a1","commons:B.jpg":"b1"}}"#.utf8)))
        let o = OdakVerisi(veriler: ["gorsel_odak.json": Data(#"{"odak":{"a1":[30,20],"b1":[60,70]}}"#.utf8)], cihaz: ["b1": [10, 90]])
        func eser(_ g: [Gorsel]) -> Eser {
            Eser(anahtar: "x", kaynak: "", kaynaklar: [], baslik: "x", tarih: "", yil: nil, muze: "", kursKonu: nil, qid: nil,
                 gorseller: g, pekistirme: true, sl: 0)
        }
        XCTAssertEqual(o.odak(eser([Gorsel(k: "commons", d: "A.jpg")]), adresler: adresler), [30, 20])
        XCTAssertEqual(o.odak(eser([Gorsel(k: "commons", d: "B.jpg")]), adresler: adresler), [10, 90], "cihazdaki elle önde")
        XCTAssertNil(o.odak(eser([Gorsel(k: "commons", d: "C.jpg")]), adresler: adresler), "yerel adı yoksa odak yok")
        XCTAssertNil(o.odak(eser([]), adresler: adresler))
    }
}

import Foundation
import XCTest
@testable import NoraCekirdek

/// Z2c-2: sitenin resim rengi ve renkli Gündüz kuralları. Örnekler: Testler/kahin/renk.mjs (sitenin kendi modülleri).
final class ResimRengiTests: XCTestCase {
    static let ornek: JSONDeger = {
        let url = Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/renk")!
        return try! JSONDeger.coz(Data(contentsOf: url))
    }()

    func palet(_ j: JSONDeger?) -> [ResimRengi.PaletRengi] {
        (j?.dizi ?? []).map { ResimRengi.PaletRengi(renk: $0["renk"]!.metin!, pay: $0["pay"]!.sayi!) }
    }

    /// Kanallar en çok 1 farklı (V8 ile glibc'nin pow/cos/atan2'si son basamakta ayrışabilir)
    func yakin(_ a: String?, _ b: String?, _ m: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let a, let b else { XCTAssertEqual(a, b, m, file: file, line: line); return }
        let x = ResimRengi.hexten(a), y = ResimRengi.hexten(b)
        XCTAssert(zip(x, y).allSatisfy { abs($0 - $1) <= 1 }, "\(m): \(a) ≠ \(b)", file: file, line: line)
    }

    func testRenkler() {
        let r = Self.ornek["renkler"]!.dizi!
        XCTAssertEqual(r.count, 200)
        for (i, v) in r.enumerated() {
            let c = v["renk"]!.metin!, z = v["zemin"]!.metin!
            let (h, s, l) = ResimRengi.hsl(c)
            let beklenen = v["hsl"]!.dizi!.map { $0.sayi! }
            XCTAssertEqual(h, beklenen[0], accuracy: 1e-9, "\(i)"); XCTAssertEqual(s, beklenen[1], accuracy: 1e-12, "\(i)")
            XCTAssertEqual(l, beklenen[2], accuracy: 1e-12, "\(i)")
            XCTAssertEqual(ResimRengi.hsldenHex(h, s, l), v["geri"]!.metin!, "\(i) geri")
            XCTAssertEqual(ResimRengi.kontrast(c, z), v["kontrast"]!.sayi!, accuracy: 1e-9, "\(i) kontrast")
            XCTAssertEqual(ResimRengi.acikHal(c, z), v["acik"]!.metin!, "\(i) acikHal")
            let d = ResimRengi.doluButon(c)
            XCTAssertEqual(d.zemin, v["dolu"]!["zemin"]!.metin!, "\(i) dolu"); XCTAssertEqual(d.yazi, v["dolu"]!["yazi"]!.metin!)
            XCTAssertEqual(ResimRengi.yumusat(c), v["yumusak"]!.metin!, "\(i) yumusat")
            XCTAssertEqual(ResimRengi.karistir(c, z, 0.3), v["karisim"]!.metin!, "\(i) karistir")
        }
    }

    func testResimler() throws {
        let r = Self.ornek["resimler"]!.dizi!
        XCTAssertEqual(r.count, 70)
        var gunduz = 0
        for (i, v) in r.enumerated() {
            let veri = [UInt8](try XCTUnwrap(Data(base64Encoded: v["piksel"]!.metin!)))
            let p = ResimRengi.paletHesapla(veri, adet: v["adet"]!.tamSayi!)
            let bp = palet(v["palet"])
            XCTAssertEqual(p.map(\.renk), bp.map(\.renk), "\(i) palet")
            for (a, b) in zip(p, bp) { XCTAssertEqual(a.pay, b.pay, accuracy: 1e-12) }
            XCTAssertEqual(ResimRengi.vurguSec(p), v["vurgu"]?.metin, "\(i) vurgu")
            for t in v["temalar"]!.dizi! {
                let z = t["zemin"]!.metin!
                let s = ResimRengi.renkTemasi(p, zemin: z)
                let b = t["tema"]!
                XCTAssertEqual(s?.vurgu, b["vurgu"]?.metin, "\(i) \(z) vurgu")
                XCTAssertEqual(s?.vurguYazi, b["vurguYazi"]?.metin); XCTAssertEqual(s?.vurguAcik, b["vurguAcik"]?.metin)
                XCTAssertEqual(s?.vurguAcikYazi, b["vurguAcikYazi"]?.metin); XCTAssertEqual(s?.vurguKoyu, b["vurguKoyu"]?.metin)
                XCTAssertEqual(s?.vurguRgb, b["vurguRgb"]?.metin)
            }
            let ton = ResimRengi.tonlariHesapla(veri)
            let bt = v["tonlar"]!
            XCTAssertEqual(ton.renkOrani, bt["renkOrani"]!.sayi!, accuracy: 1e-12, "\(i) renkOrani")
            yakin(ton.acik, bt["acik"]?.metin, "\(i) acik")
            for (a, b) in zip(ton.aileler, bt["aileler"]!.dizi!) {
                XCTAssertEqual(a.ad, b["ad"]!.metin!)
                XCTAssertEqual(a.pay, b["pay"]!.sayi!, accuracy: 1e-9, "\(i) \(a.ad) pay")
                yakin(a.renk, b["renk"]?.metin, "\(i) \(a.ad) renk")
            }
            // Gündüz paleti sitenin tonlarından (ton hesabının son basamak farkları paleti etkilemesin)
            let siteTonlari = ResimRengi.Tonlar(
                aileler: bt["aileler"]!.dizi!.map { ResimRengi.Aile(ad: $0["ad"]!.metin!, pay: $0["pay"]!.sayi!, renk: $0["renk"]?.metin) },
                acik: bt["acik"]?.metin, renkOrani: bt["renkOrani"]!.sayi!)
            let g = GunduzPaleti.resimden(siteTonlari)
            if let bg = v["gunduz"], bg.nesne != nil {
                gunduz += 1
                let g = try XCTUnwrap(g, "\(i) gündüz")
                let m = Mirror(reflecting: g)
                for c in m.children { XCTAssertEqual(c.value as? String, bg[c.label!]?.metin, "\(i) gündüz \(c.label!)") }
                let dg = v["degiskenler"]!.nesne!
                XCTAssertEqual(g.degiskenler.count, dg.count)
                for c in dg.ciftler { XCTAssertEqual(g.degiskenler[c.anahtar], c.deger.metin, "\(i) \(c.anahtar)") }
            } else {
                XCTAssertNil(g, "\(i) gündüz yok")
            }
        }
        XCTAssertGreaterThan(gunduz, 40)
    }

    func testHazirPaletler() {
        let h = Self.ornek["hazir"]!.nesne!
        XCTAssertEqual(h.ciftler.map(\.anahtar), GunduzPaleti.renkler)
        for c in h.ciftler {
            let p = GunduzPaleti.sec(c.anahtar, tonlar: nil)
            guard c.deger.nesne != nil else { XCTAssertNil(p, c.anahtar); continue }
            let dg = c.deger["degiskenler"]!.nesne!
            for d in dg.ciftler { XCTAssertEqual(p?.degiskenler[d.anahtar], d.deger.metin, "\(c.anahtar) \(d.anahtar)") }
        }
    }
}

/// Z3l: js/akim.js `paletBirlestir`; beklenenler sitenin kendi modülüyle (node, sanat-atlasi 05f9039) alındı
final class PaletBirlestirTests: XCTestCase {
    typealias P = ResimRengi.PaletRengi
    let p1 = [P(renk: "#8a5a2b", pay: 0.4), P(renk: "#2b3a55", pay: 0.3), P(renk: "#d9c8a0", pay: 0.2), P(renk: "#101010", pay: 0.1)]
    let p2 = [P(renk: "#8f5d2e", pay: 0.5), P(renk: "#c0392b", pay: 0.25), P(renk: "#2a3b57", pay: 0.25)]
    let p3 = [P(renk: "#556b2f", pay: 0.6), P(renk: "#d8c9a1", pay: 0.4)]

    private func esit(_ a: [P], _ b: [(String, Double)], _ s: StaticString = #filePath, _ l: UInt = #line) {
        XCTAssertEqual(a.map(\.renk), b.map(\.0), file: s, line: l)
        for (x, y) in zip(a, b) { XCTAssertEqual(x.pay, y.1, accuracy: 1e-12, file: s, line: l) }
    }

    func testUcEser() {
        esit(ResimRengi.paletBirlestir([p1, p2, p3]), [("#8d5c2d", 0.3), ("#d8c9a1", 0.2), ("#556b2f", 0.2),
                                                      ("#2b3a56", 0.18333333333333332), ("#c0392b", 0.08333333333333333),
                                                      ("#101010", 0.03333333333333333)])
    }

    func testBosVeEksikPaletler() {
        esit(ResimRengi.paletBirlestir([p1, nil, []]), [("#8a5a2b", 0.4), ("#2b3a55", 0.3), ("#d9c8a0", 0.2), ("#101010", 0.1)])
        XCTAssertEqual(ResimRengi.paletBirlestir([nil, []]), [])
    }

    func testAdet() {
        esit(ResimRengi.paletBirlestir([p1, p2, p3], adet: 3), [("#8d5c2d", 0.4285714285714286), ("#d8c9a1", 0.28571428571428575),
                                                               ("#556b2f", 0.2857142857142857)])
    }
}

/// Z2c-2: temanın değişkenleri sitedeki gibi birleşir (kâhin kabuk.mjs: gece, nötr gündüz, renkli gündüz "lapis")
final class TemaHesabiTests: XCTestCase {
    func testSiteninDegiskenleri() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/kabuk"))
        let t = try XCTUnwrap(JSONDeger.coz(Data(contentsOf: url))["tema"])
        for (ad, tema, palet) in [("gece", TemaAdi.gece, nil), ("gunduz", .gunduz, nil), ("gunduzLapis", .gunduz, GunduzPaleti.hazir["lapis"])] {
            let b = try XCTUnwrap(t[ad])
            XCTAssertEqual(TemaRenkleri.zeminHex(tema, gunduz: palet).lowercased(), b["themeColor"]!.metin!.lowercased(), ad)
            let r = TemaRenkleri.hesapla(tema, gunduz: palet, vurgu: nil)
            for (css, yol) in TemaRenkleri.degiskenler where !css.hasPrefix("--vurgu") {
                XCTAssertEqual(r[keyPath: yol], RGBA(css: b["degiskenler"]![css]!.metin!), "\(ad) \(css)")
            }
        }
    }
}

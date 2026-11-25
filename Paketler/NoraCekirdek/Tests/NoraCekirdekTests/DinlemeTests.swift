import Foundation
import XCTest
@testable import NoraCekirdek

/// Y1 · Sesli rehberli bakış: akış planı ve süre dağılımı (sitede karşılığı yok; davranış testi).
final class DinlemeTests: XCTestCase {
    private func nokta(_ i: Int, harf: Int = 150) -> DinlemeNoktasi {
        DinlemeNoktasi(ad: "Ayrıntı \(i)", metin: String(repeating: "a", count: harf - 1) + ".",
                       kutu: DinlemeKutusu(x: Double(i % 5) * 0.18, y: Double(i / 5) * 0.4, w: 0.15, h: 0.15))
    }

    private func kaynak(noktalar: Int, olay: [String] = [], ek: [String] = []) -> DinlemeKaynagi {
        DinlemeKaynagi(baslik: "Arnolfini Portresi", sanatci: "Jan van Eyck", tarih: "1434",
                       notMetni: String(repeating: "n", count: 180),
                       olay: olay, ek: ek, noktalar: (0..<noktalar).map { nokta($0) })
    }

    func testKunyeVeNoktalama() {
        XCTAssertEqual(kaynak(noktalar: 0).kunye, "Arnolfini Portresi. Jan van Eyck, 1434.")
        XCTAssertEqual(DinlemeKaynagi(baslik: "Yıldızlı Gece", sanatci: "", tarih: "").kunye, "Yıldızlı Gece.")
        XCTAssertEqual(DinlemeKurallari.noktala("Soru mu?"), "Soru mu?")
        XCTAssertEqual(DinlemeKurallari.noktala("  "), "")
    }

    func testOkumaSuresi() {
        XCTAssertEqual(DinlemeKurallari.okumaSuresi(""), 0)
        // 120 harf, bir cümle: 10 + 0,35
        XCTAssertEqual(DinlemeKurallari.okumaSuresi(String(repeating: "a", count: 119) + "."), 10.4, accuracy: 0.05)
        // uzun metin daha uzun sürer
        XCTAssertGreaterThan(DinlemeKurallari.okumaSuresi(String(repeating: "a. ", count: 60)),
                             DinlemeKurallari.okumaSuresi(String(repeating: "a", count: 60)))
    }

    func testAkisSirasi() {
        let p = DinlemePlani.kur(kaynak(noktalar: 4, olay: ["Ne oluyor"], ek: ["Ressam"]), sure: .on)
        XCTAssertEqual(p.adimlar.first?.tur, .acilis)
        XCTAssertNil(p.adimlar.first?.kutu, "açılışta tablonun tamamı")
        XCTAssertTrue(p.adimlar.first?.metin.hasPrefix("Arnolfini Portresi. Jan van Eyck, 1434.") ?? false)
        XCTAssertEqual(p.adimlar.last?.tur, .kapanis)
        XCTAssertNil(p.adimlar.last?.kutu, "sonda tablonun tamamına dönülür")
        XCTAssertEqual(p.adimlar.map(\.tur), [.acilis, .anlati, .nokta, .nokta, .nokta, .nokta, .anlati, .sessiz, .kapanis])
        XCTAssertEqual(p.adimlar.filter { $0.tur == .nokta }.map(\.baslik), (0..<4).map { "Ayrıntı \($0)" })
    }

    func testNoktaAdimi20ile40saniyeArasi() {
        for sure in DinlemeSuresi.allCases {
            let p = DinlemePlani.kur(kaynak(noktalar: 6), sure: sure)
            for a in p.adimlar where a.tur == .nokta {
                XCTAssertGreaterThanOrEqual(a.sure, 20 - 0.001, "\(sure)")
                XCTAssertLessThanOrEqual(a.sure, 40 + 0.001, "\(sure)")
                XCTAssertGreaterThan(a.sessizlik, 0, "metinden sonra kısa sessizlik")
                XCTAssertLessThan(a.gecikme + a.konusma, a.sure)
            }
        }
    }

    func testSureyeSigar() {
        for sure in DinlemeSuresi.allCases {
            let p = DinlemePlani.kur(kaynak(noktalar: 30, olay: ["o1", "o2"], ek: ["e1", "e2", "e3"]), sure: sure)
            XCTAssertLessThanOrEqual(p.toplam, sure.saniye + 0.001, "\(sure)")
            XCTAssertGreaterThan(p.toplam, sure.saniye - 25, "\(sure): süre boşa kalmasın")
        }
        let uc = DinlemePlani.kur(kaynak(noktalar: 30), sure: .uc).adimlar.filter { $0.tur == .nokta }.count
        let bes = DinlemePlani.kur(kaynak(noktalar: 30), sure: .bes).adimlar.filter { $0.tur == .nokta }.count
        let on = DinlemePlani.kur(kaynak(noktalar: 30), sure: .on).adimlar.filter { $0.tur == .nokta }.count
        XCTAssertLessThan(uc, bes)
        XCTAssertLessThan(bes, on)
        XCTAssertGreaterThanOrEqual(uc, 4)
    }

    func testAzIcerikteNoktalarUzarVeSessizBakis() {
        let p = DinlemePlani.kur(kaynak(noktalar: 3), sure: .on)
        let noktalar = p.adimlar.filter { $0.tur == .nokta }
        XCTAssertEqual(noktalar.count, 3)
        for a in noktalar { XCTAssertEqual(a.sure, 40, accuracy: 0.01) }
        let sessiz = p.adimlar.filter { $0.tur == .sessiz }
        XCTAssertEqual(sessiz.count, 1)
        XCTAssertEqual(sessiz[0].sure, DinlemeKurallari.sessizEnCok, accuracy: 0.01)
        XCTAssertLessThanOrEqual(p.toplam, 600)
    }

    func testUzunMetinliNoktaKesilmez() {
        let uzun = DinlemeNoktasi(ad: "Uzun", metin: String(repeating: "a", count: 600),
                                  kutu: DinlemeKutusu(x: 0.1, y: 0.1, w: 0.2, h: 0.2))
        let p = DinlemePlani.kur(DinlemeKaynagi(baslik: "B", sanatci: "S", noktalar: [uzun]), sure: .uc)
        let a = try! XCTUnwrap(p.adimlar.first { $0.tur == .nokta })
        XCTAssertGreaterThanOrEqual(a.sure, a.gecikme + a.konusma + a.sessizlik - 0.001)
    }

    func testEnAzBirNokta() {
        let uzun = (0..<3).map {
            DinlemeNoktasi(ad: "N\($0)", metin: String(repeating: "a", count: 3000),
                           kutu: DinlemeKutusu(x: 0.1 * Double($0), y: 0.1, w: 0.1, h: 0.1))
        }
        let p = DinlemePlani.kur(DinlemeKaynagi(baslik: "B", sanatci: "S", noktalar: uzun), sure: .uc)
        XCTAssertEqual(p.adimlar.filter { $0.tur == .nokta }.count, 1)
    }

    func testNoktasizGezinti() {
        let p = DinlemePlani.kur(kaynak(noktalar: 0, olay: ["Birinci paragraf", "İkinci paragraf"],
                                        ek: ["Ressamla bağı"]), sure: .bes)
        let anlati = p.adimlar.filter { $0.tur == .anlati }
        XCTAssertEqual(anlati.count, 3)
        // kamera tablonun bölgeleri arasında dolaşır: her anlatının ayrı bir hedefi
        XCTAssertEqual(Set(anlati.compactMap(\.kutu)).count, 3)
        for k in anlati.compactMap(\.kutu) {
            XCTAssertLessThanOrEqual(k.x + k.w, 1.0001)
            XCTAssertLessThanOrEqual(k.y + k.h, 1.0001)
        }
        // not yoksa ve hikâye de yoksa yalnız açılış, sessiz bakış ve kapanış
        let bos = DinlemePlani.kur(DinlemeKaynagi(baslik: "B", sanatci: "S"), sure: .uc)
        XCTAssertEqual(bos.adimlar.map(\.tur), [.acilis, .sessiz, .kapanis])
    }

    func testBaslangicAnlari() {
        let p = DinlemePlani.kur(kaynak(noktalar: 5), sure: .bes)
        XCTAssertEqual(p.baslangic(0), 0)
        XCTAssertEqual(p.baslangic(1), p.adimlar[0].sure, accuracy: 0.0001)
        XCTAssertEqual(p.baslangic(p.adimlar.count), p.toplam, accuracy: 0.0001)
    }

    func testNoktalariBirlestir() {
        let a = DinlemeNoktasi(ad: "Ayna", metin: "m", kutu: DinlemeKutusu(x: 0.4, y: 0.2, w: 0.2, h: 0.2))
        let ayniAd = DinlemeNoktasi(ad: "ayna", metin: "m2", kutu: DinlemeKutusu(x: 0, y: 0, w: 0.1, h: 0.1))
        let ortusen = DinlemeNoktasi(ad: "Dışbükey ayna", metin: "m3", kutu: DinlemeKutusu(x: 0.41, y: 0.21, w: 0.2, h: 0.2))
        let baska = DinlemeNoktasi(ad: "Köpek", metin: "m4", kutu: DinlemeKutusu(x: 0.4, y: 0.75, w: 0.2, h: 0.2))
        let sonuc = DinlemeKurallari.noktalariBirlestir([[a], [ayniAd, ortusen, baska]])
        XCTAssertEqual(sonuc.map(\.ad), ["Ayna", "Köpek"])
    }

    // MARK: - Sitenin verisiyle

    func testGercekVeri() throws {
        let hazir = try XCTUnwrap(GoruntuleyiciTests.hazir)
        let b = hazir.baglam
        let k = hazir.katalog
        let yuruyusUrl = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/site_verisi/yuruyus.json", withExtension: nil))
        let yuruyus = try JSONDeger.coz(Data(contentsOf: yuruyusUrl))
        var denenen = 0
        var yuruyusBulunan = 0
        for s in k.sanatcilar {
            for e in k.eserler(s.id) {
                let ayr = b.ayrinti(e)
                let yerel = e.gorseller.compactMap { k.gorsel.yerelAd($0) }
                let yur = DinlemeKurallari.yuruyusNoktalari(yuruyus, eser: e, yerelAdlar: yerel)
                guard ayr != nil || !yur.isEmpty else { continue }
                if !yur.isEmpty { yuruyusBulunan += 1 }
                let kay = DinlemeKurallari.kaynak(eser: e, sanatci: s.ad, notMetni: b.eserNotu(e), ayrinti: ayr,
                                                  hikaye: b.hikaye(e), yuruyus: yur)
                XCTAssertFalse(kay.noktalar.isEmpty)
                XCTAssertGreaterThanOrEqual(kay.noktalar.count, max(ayr?.noktalar.count ?? 0, yur.count))
                for sure in DinlemeSuresi.allCases {
                    let p = DinlemePlani.kur(kay, sure: sure)
                    XCTAssertEqual(p.adimlar.first?.tur, .acilis)
                    XCTAssertEqual(p.adimlar.last?.tur, .kapanis)
                    XCTAssertTrue(p.adimlar.contains { $0.tur == .nokta })
                    // gerçek metinler 20–40 sn'ye sığar; plan seçilen süreyi aşmaz
                    XCTAssertLessThanOrEqual(p.toplam, sure.saniye + 0.001, "\(e.gorunenAd) \(sure)")
                    for a in p.adimlar where a.tur == .nokta {
                        XCTAssertLessThanOrEqual(a.sure, 40.001, "\(e.gorunenAd): \(a.baslik)")
                    }
                }
                denenen += 1
            }
        }
        XCTAssertGreaterThan(denenen, 20)
        XCTAssertGreaterThan(yuruyusBulunan, 10)
    }
}

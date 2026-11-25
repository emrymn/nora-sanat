// Z3w (yeni tasarım, sitede yok): Galeri › Akımlar "Kemerlerin yayı" geometrisi. Kâhin yok: davranış testi.
// Beklenen değerler Neon'un yon-2.html `cizKonum` / `centikCiz` formüllerinden elle hesaplandı.
import XCTest

@testable import NoraCekirdek

final class KemerYayiTests: XCTestCase {
    func testOrtadakiKartTamBoyDuzVeNet() {
        let k = KemerYayi.kart(fark: 0)
        XCTAssertEqual(k.olcek, 1, accuracy: 1e-9)
        XCTAssertEqual(k.kayma, 0, accuracy: 1e-9)
        XCTAssertEqual(k.aci, 0, accuracy: 1e-9)
        XCTAssertEqual(k.opaklik, 1, accuracy: 1e-9)
        XCTAssertEqual(k.cerceve, 0.72, accuracy: 1e-9)
        XCTAssertEqual(k.bulaniklik, 0, accuracy: 1e-9)
        XCTAssertEqual(k.parlaklik, 1, accuracy: 1e-9)
        XCTAssertEqual(k.yaziOpakligi, 1, accuracy: 1e-9)
        XCTAssertTrue(k.odak)
    }

    func testKomsuKartKucukEgikAlcakVeBulanik() {
        let sag = KemerYayi.kart(fark: 1)
        XCTAssertEqual(sag.olcek, 0.89, accuracy: 1e-9)
        XCTAssertEqual(sag.kayma, 15, accuracy: 1e-9)
        XCTAssertEqual(sag.aci, 2.6, accuracy: 1e-9)
        XCTAssertEqual(sag.opaklik, 0.64, accuracy: 1e-9)
        XCTAssertEqual(sag.cerceve, 0.10, accuracy: 1e-9)
        XCTAssertEqual(sag.bulaniklik, KemerYayi.komsuBulanikligi, accuracy: 1e-9)
        XCTAssertEqual(sag.parlaklik, 0.86, accuracy: 1e-9)
        XCTAssertEqual(sag.yaziOpakligi, 0, accuracy: 1e-9)
        XCTAssertFalse(sag.odak)
        // Soldaki ters yöne eğilir; geri kalan simetrik
        let sol = KemerYayi.kart(fark: -1)
        XCTAssertEqual(sol.aci, -2.6, accuracy: 1e-9)
        XCTAssertEqual(sol.olcek, sag.olcek, accuracy: 1e-9)
        XCTAssertEqual(sol.kayma, sag.kayma, accuracy: 1e-9)
    }

    func testEgimSinirliUzakKartlarDahaFazlaKuculmez() {
        XCTAssertEqual(KemerYayi.kart(fark: 2).aci, 3.2, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.kart(fark: -5).aci, -3.2, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.kart(fark: 3).olcek, 0.89, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.kart(fark: 3).bulaniklik, KemerYayi.komsuBulanikligi, accuracy: 1e-9)
    }

    func testYaridaYumusakGecis() {
        let k = KemerYayi.kart(fark: 0.5)
        let y = cos(0.25 * Double.pi)
        XCTAssertEqual(k.olcek, 0.89 + 0.11 * y, accuracy: 1e-9)
        XCTAssertEqual(k.kayma, (1 - y) * 15, accuracy: 1e-9)
        XCTAssertEqual(k.aci, 1.3, accuracy: 1e-9)
        XCTAssertEqual(k.bulaniklik, 0.5 * KemerYayi.komsuBulanikligi, accuracy: 1e-9)
        // Yazı 0,58 akımda tamamen söner: yarıda çok soluk
        XCTAssertEqual(k.yaziOpakligi, pow(1 - 0.5 / 0.58, 1.15), accuracy: 1e-9)
        XCTAssertFalse(k.odak)
        XCTAssertTrue(KemerYayi.kart(fark: 0.3).odak)
    }

    func testHareketAzaltilmissaEgimKaymaBulaniklikYok() {
        for d in [-1.4, -0.5, 0.3, 1, 2] {
            let k = KemerYayi.kart(fark: d, hareketAz: true)
            XCTAssertEqual(k.aci, 0)
            XCTAssertEqual(k.kayma, 0)
            XCTAssertEqual(k.bulaniklik, 0)
            XCTAssertEqual(k.yaziKaymasi, 0)
            // ölçek ve opaklık kalır
            XCTAssertEqual(k.olcek, KemerYayi.kart(fark: d).olcek, accuracy: 1e-9)
            XCTAssertEqual(k.opaklik, KemerYayi.kart(fark: d).opaklik, accuracy: 1e-9)
        }
    }

    func testKilitliKapagaParlaklikUygulanmaz() {
        XCTAssertEqual(KemerYayi.kart(fark: 1, acik: false).parlaklik, 1)
    }

    func testKonumVeOturma() {
        XCTAssertEqual(KemerYayi.adim, 252)
        XCTAssertEqual(KemerYayi.konum(yol: 0, sayi: 28), 0)
        XCTAssertEqual(KemerYayi.konum(yol: 252 * 3.5, sayi: 28), 3.5, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.konum(yol: -40, sayi: 28), 0)
        XCTAssertEqual(KemerYayi.konum(yol: 252 * 40, sayi: 28), 27)
        XCTAssertEqual(KemerYayi.konum(yol: 100, sayi: 0), 0)
        XCTAssertEqual(KemerYayi.oturma(konum: 3.4, sayi: 28), 3)
        XCTAssertEqual(KemerYayi.oturma(konum: 3.4, hiz: 0.3, sayi: 28), 4)
        XCTAssertEqual(KemerYayi.oturma(konum: 26.8, hiz: 2, sayi: 28), 27)
    }

    func testKilavuzKomsulari() {
        XCTAssertNil(KemerYayi.komsu(0, yon: -1, sayi: 28))
        XCTAssertEqual(KemerYayi.komsu(0, yon: 1, sayi: 28), 1)
        XCTAssertEqual(KemerYayi.komsu(9, yon: -1, sayi: 28), 8)
        XCTAssertNil(KemerYayi.komsu(27, yon: 1, sayi: 28))
    }

    func testEylemYuvasiAcikKilitliSinirindaSoner() {
        let a = [true, true, false, false]
        XCTAssertEqual(KemerYayi.eylemOpakligi(konum: 0.5, aciklar: a), 1)
        XCTAssertEqual(KemerYayi.eylemOpakligi(konum: 1, aciklar: a), 1)
        XCTAssertEqual(KemerYayi.eylemOpakligi(konum: 1.5, aciklar: a), 0.38, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.eylemOpakligi(konum: 1.25, aciklar: a), 0.38 + 0.62 * 0.5, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.eylemOpakligi(konum: 3, aciklar: a), 1)
        XCTAssertEqual(KemerYayi.eylemOpakligi(konum: 0, aciklar: []), 1)
    }

    func testCentiklerYaylaAkar() {
        let c0 = KemerYayi.centikler(konum: 0)
        // 28, 42, …, 350: 24 çentik (hepsi |u| ≤ 0,96 içinde)
        XCTAssertEqual(c0.count, 24)
        XCTAssertEqual(c0.first?.x ?? 0, 28, accuracy: 1e-9)
        // Ortadaki (x = 196, u ≈ 0) en parlak ve en yüksek
        let orta = c0.min { abs($0.x - 195) < abs($1.x - 195) }!
        XCTAssertEqual(orta.y, 14, accuracy: 0.01)
        XCTAssertEqual(orta.opaklik, 0.65, accuracy: 0.01)
        XCTAssertTrue(c0.allSatisfy { $0.opaklik <= 0.65 && $0.y >= 14 })
        // Yarım akımda 7 kayar (21 ucu |u| > 0,96 olduğu için atlanır); tam akımda başa döner
        XCTAssertEqual(KemerYayi.centikler(konum: 0.5).first!.x, 35, accuracy: 1e-9)
        XCTAssertEqual(KemerYayi.centikler(konum: 0.5).count, 24)
        XCTAssertEqual(KemerYayi.centikler(konum: 1).map(\.x), c0.map(\.x))
        // Genişlik ölçeklenir
        XCTAssertEqual(KemerYayi.centikler(konum: 0, genislik: 780).first!.x, 56, accuracy: 1e-9)
    }

    func testYillarVeDurum() {
        func s(_ d: Int?, _ o: Int?) -> Sanatci {
            var x = Sanatci(json: .nesne([]))
            x.dogum = d
            x.olum = o
            return x
        }
        XCTAssertEqual(KemerYayi.yillar([s(1582, 1666), s(1632, 1675), s(1628, 1682)]), "1582–1682")
        XCTAssertEqual(KemerYayi.yillar([s(nil, 1348), s(1210, nil)]), "1210–1348")
        XCTAssertEqual(KemerYayi.yillar([s(nil, nil)]), "")
        XCTAssertEqual(KemerYayi.yillar([]), "")
        let acik = AkimDurumu(ad: "Barok", sira: 9, toplam: 5, acikSayisi: 2, acik: true, acilacagiKonu: nil)
        XCTAssertEqual(KemerYayi.durum(acik), "2 / 5 sanatçı açık")
        let kilitli = AkimDurumu(ad: "Klasisizm", sira: 13, toplam: 4, acikSayisi: 0, acik: false, acilacagiKonu: 37)
        XCTAssertEqual(KemerYayi.durum(kilitli), "Konu 37'de açılır")
    }
}

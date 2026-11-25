// Z3y (yeni tasarım, sitede yok): Yolculuk soru ekranı "Şık 5 · El Yelpazesi". Kâhin yok: davranış testi.
// Beklenen değerler Neon'un tasarim/soru/sik-5.html'inden (`.muze-kart[data-i]`, `.muze-kart.basili`,
// `.yelpaze.biri-basili`, `.deste-bolge`, `.yelpaze.cevapli .muze-kart`).
import XCTest

@testable import NoraCekirdek

final class SoruYelpazesiTests: XCTestCase {
    let sanatcilar = ["Jan van Eyck", "Robert Campin", "Rogier van der Weyden", "Petrus Christus"]

    func testDortKartinAcisiVeDususuTasarimdaki() {
        XCTAssertEqual((0..<4).map { SoruYelpazesi.aci($0, adet: 4) }, [-8.5, -2.8, 2.8, 8.5])
        XCTAssertEqual((0..<4).map { SoruYelpazesi.dusus($0, adet: 4) }, [8, 1, 1, 8])
    }

    func testBaskaAdetteYaySimetrikVeSinirli() {
        let uc = (0..<3).map { SoruYelpazesi.aci($0, adet: 3) }
        XCTAssertEqual(uc, [-8.5, 0, 8.5])
        XCTAssertEqual(SoruYelpazesi.aci(0, adet: 1), 0)
        XCTAssertEqual(SoruYelpazesi.dusus(1, adet: 3), 1, accuracy: 1e-9)
        XCTAssertEqual(SoruYelpazesi.dusus(0, adet: 3), 8, accuracy: 1e-9)
    }

    func testBasiliKartSiyrilirDuzlesirBuyurOtekilerSoner() {
        let b = SoruYelpazesi.kart(2, adet: 4, basili: 2, hareketAz: false)
        XCTAssertEqual(b.aci, 0)
        XCTAssertEqual(b.y, -24)
        XCTAssertEqual(b.olcek, 1.08)
        XCTAssertEqual(b.opaklik, 1)
        XCTAssertTrue(b.basili)
        let o = SoruYelpazesi.kart(0, adet: 4, basili: 2, hareketAz: false)
        XCTAssertEqual(o.opaklik, 0.48)
        XCTAssertEqual(o.aci, -8.5)
        XCTAssertGreaterThan(b.z, o.z)
    }

    func testBasilmadanHepsiTamOpakSagdakiUstte() {
        let k = (0..<4).map { SoruYelpazesi.kart($0, adet: 4, basili: nil, hareketAz: false) }
        XCTAssertEqual(k.map(\.opaklik), [1, 1, 1, 1])
        XCTAssertEqual(k.map(\.z), [1, 2, 3, 4])
        XCTAssertFalse(k.contains { $0.basili })
    }

    func testHareketAzaltilmissaSiyrilmaYokYalnizSonme() {
        let b = SoruYelpazesi.kart(1, adet: 4, basili: 1, hareketAz: true)
        XCTAssertEqual(b.aci, -2.8)
        XCTAssertEqual(b.y, 1)
        XCTAssertEqual(b.olcek, 1)
        XCTAssertTrue(b.basili)
        XCTAssertEqual(SoruYelpazesi.kart(3, adet: 4, basili: 1, hareketAz: true).opaklik, 0.48)
    }

    func testSabitAltYukseklikIkiBoyda() {
        let buyuk = SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: sanatcilar)
        XCTAssertFalse(buyuk.kucuk)
        XCTAssertEqual(buyuk.altYukseklik, 260)
        XCTAssertEqual(buyuk.kartYuksekligi, 146)
        let kucuk = SoruYelpazesi.olcu(genislik: 375, yukseklik: 647, adlar: sanatcilar)
        XCTAssertTrue(kucuk.kucuk)
        XCTAssertEqual(kucuk.altYukseklik, 228)
        XCTAssertEqual(kucuk.kartYuksekligi, 126)
    }

    func testAltYukseklikAdlardanBagimsiz() {
        // Cevaptan önce ve sonra aynı ölçü: eser yüksekliği değişmez
        let a = SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: sanatcilar)
        let b = SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: ["Jan van Eyck", "Petrus Christus"])
        XCTAssertEqual(a.altYukseklik, b.altYukseklik)
        // Cevaptan sonraki düzleşmiş iki kart ve geçiş satırı sabit alana sığar (başlık 34 + iç boşluklar 24)
        XCTAssertLessThanOrEqual(34 + a.cevapYuksekligi + 14 + 57 + 24, a.altYukseklik)
        let k = SoruYelpazesi.olcu(genislik: 375, yukseklik: 647, adlar: sanatcilar)
        XCTAssertLessThanOrEqual(30 + k.cevapYuksekligi + 10 + 57 + 16, k.altYukseklik)
    }

    func testKartlarTasarimdanGenisVeYatayTasmaYok() {
        for (g, h) in [(390.0, 763.0), (375.0, 647.0), (393.0, 759.0), (430.0, 839.0), (320.0, 548.0)] {
            let o = SoruYelpazesi.olcu(genislik: g, yukseklik: h, adlar: sanatcilar)
            XCTAssertGreaterThanOrEqual(o.kartGenisligi, 44, "\(g)")
            XCTAssertLessThanOrEqual(o.kartGenisligi, SoruYelpazesi.enGenis)
            if g >= 375 {
                XCTAssertLessThanOrEqual(SoruYelpazesi.yelpazeEni(o), g - 2 * SoruYelpazesi.kenarPayi, "\(g)")
            }
            XCTAssertLessThanOrEqual(2 * o.cevapGenisligi + o.cevapAraligi, g - 28, "\(g)")
        }
        XCTAssertGreaterThan(SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: sanatcilar).kartGenisligi,
                             SoruYelpazesi.tasarimGenisligi)
    }

    func testUzunAdIkiSatiraIner() {
        let o = SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: sanatcilar)
        XCTAssertLessThanOrEqual(o.satir, 2)
        XCTAssertLessThanOrEqual(o.punto, 13.5)
        XCTAssertGreaterThanOrEqual(o.punto, 11)
        let k = SoruYelpazesi.olcu(genislik: 375, yukseklik: 647, adlar: sanatcilar)
        XCTAssertLessThanOrEqual(k.satir, 2)
        // Tasarımın 90 pt kartında aynı ad 3 satıra kırılıyordu
        XCTAssertEqual(SoruYelpazesi.satirSayisi("Rogier van der Weyden", genislik: 90 - 20, punto: 13.5), 3)
    }

    func testKisaAdlarBuyukPuntoda() {
        let o = SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: ["Barok", "Rokoko", "Gotik", "Rönesans"])
        XCTAssertEqual(o.punto, 13.5)
        XCTAssertEqual(o.satir, 1)
    }

    func testUzunSozcukOrtasindanKirilmazPuntoKuculur() {
        let o = SoruYelpazesi.olcu(genislik: 390, yukseklik: 763, adlar: ["Barok", "Rokoko", "Gotik", "Maniyerizm"])
        XCTAssertLessThan(o.punto, 13.5)
        XCTAssertTrue(SoruYelpazesi.sozcuklerSigar(["Maniyerizm"], genislik: o.kartGenisligi - o.icPay, punto: o.punto))
    }

    func testSatirSayisiSozcukKirar() {
        XCTAssertEqual(SoruYelpazesi.satirSayisi("Barok", genislik: 70, punto: 13.5), 1)
        XCTAssertEqual(SoruYelpazesi.satirSayisi("Kuzey Rönesansı", genislik: 70, punto: 13.5), 2)
        XCTAssertEqual(SoruYelpazesi.satirSayisi("", genislik: 70, punto: 13.5), 1)
        // Sığmayan tek sözcük harf harf kırılır
        XCTAssertGreaterThanOrEqual(SoruYelpazesi.satirSayisi("Postempresyonizmciler", genislik: 60, punto: 13.5), 3)
    }

    func testNoktalar() {
        XCTAssertEqual(SoruYelpazesi.noktalar(toplam: 4, konum: 2, sonuc: nil), [.gecildi, .gecildi, .simdi, .bekliyor])
        XCTAssertEqual(SoruYelpazesi.noktalar(toplam: 3, konum: 0, sonuc: false), [.yanlis, .bekliyor, .bekliyor])
        XCTAssertEqual(SoruYelpazesi.noktalar(toplam: 2, konum: 1, sonuc: true), [.gecildi, .dogru])
        XCTAssertNil(SoruYelpazesi.noktalar(toplam: 13, konum: 0, sonuc: nil))
        XCTAssertNil(SoruYelpazesi.noktalar(toplam: 0, konum: 0, sonuc: nil))
    }

    func testCevaptanSonraYalnizDogruVeSecilenKalir() {
        XCTAssertEqual(SoruYelpazesi.kalanlar(sanatcilar, dogru: "Jan van Eyck", secilen: "Petrus Christus"),
                       ["Jan van Eyck", "Petrus Christus"])
        XCTAssertEqual(SoruYelpazesi.kalanlar(sanatcilar, dogru: "Jan van Eyck", secilen: "Jan van Eyck"), ["Jan van Eyck"])
        XCTAssertEqual(SoruYelpazesi.kalanlar(sanatcilar, dogru: "Robert Campin", secilen: nil), ["Robert Campin"])
    }
}

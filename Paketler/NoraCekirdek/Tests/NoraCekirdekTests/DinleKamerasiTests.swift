import Foundation
import XCTest
@testable import NoraCekirdek

/// Z4a · "Dinleyerek bak" kamerası: kamera.js (neon/dinle-tasarim, PR #70) ve BENIOKU.md'deki değerler.
final class DinleKamerasiTests: XCTestCase {
    typealias K = DinleKamerasi
    // Nedimeler (3840×4420) 390×844 sahnede, 4096 px görsel, 3× ekran
    let en = 3840.0, boy = 4420.0, w = 390.0, h = 844.0

    func testEgriler() {
        XCTAssertEqual(K.egriKonum(0), 0)
        XCTAssertEqual(K.egriKonum(1), 1)
        XCTAssertEqual(K.egriOlcek(1), 1)
        var onceki = 0.0
        for i in 1...100 {
            let y = K.egriKonum(Double(i) / 100)
            XCTAssertGreaterThanOrEqual(y, onceki - 1e-9, "tekdüze artar")
            onceki = y
        }
        // cubic-bezier(0.42, 0, 0.18, 1): kalkış yavaş, varış uzun
        XCTAssertLessThan(K.egriKonum(0.2), 0.2)
        XCTAssertGreaterThan(K.egriKonum(0.8), 0.9)
    }

    func testNefesZarfi() {
        XCTAssertEqual(K.nefes(0), 0, accuracy: 1e-12)
        XCTAssertEqual(K.nefes(1), 0, accuracy: 1e-9)
        // tepe hafif erken (t ≈ 0,44) ve 1
        let tepe = stride(from: 0.0, through: 1.0, by: 0.005).max { K.nefes($0) < K.nefes($1) }!
        XCTAssertEqual(tepe, 0.455, accuracy: 0.03)
        XCTAssertEqual(K.nefes(tepe), 1, accuracy: 0.001)
        // uçlarda yavaş başlar, yavaş biter
        XCTAssertLessThan(K.nefes(0.01), 0.02)
        XCTAssertLessThan(K.nefes(0.99), 0.01)
    }

    func testDerinlikVeSure() {
        XCTAssertEqual(K.nefesDerinligi(0), 0.16, accuracy: 1e-9)
        XCTAssertEqual(K.nefesDerinligi(0.2), 0.16 + 0.124, accuracy: 1e-9)
        XCTAssertEqual(K.nefesDerinligi(5), 0.48)
        XCTAssertEqual(K.gecisSuresi(0), 2.9)
        XCTAssertEqual(K.gecisSuresi(0.3), 3.58, accuracy: 1e-9)
        XCTAssertEqual(K.gecisSuresi(2), 4.4)
        XCTAssertEqual(K.gecisSuresi(.kapanis, mesafe: 0), 3.6)
        XCTAssertEqual(K.gecisSuresi(.acilis, mesafe: 0), 1.4)
    }

    func testAyrintiHedefi() {
        let ayna = DinlemeKutusu(x: 0.37, y: 0.51, w: 0.10, h: 0.11)
        let d = K.hedef(kutu: ayna, tur: .nokta, en: en, boy: boy, kaynakEn: 4096, dpr: 3, sahneW: w, sahneH: h)
        XCTAssertGreaterThanOrEqual(d.olcek, 1.48 - 1e-9)
        XCTAssertLessThanOrEqual(d.olcek, 2.68 + 1e-9)
        XCTAssertEqual(d.capaY, 0.42 * h, accuracy: 1e-9, "ayrıntı ekranın %42'sinde: dokununca tablo sıçramaz")
        // bakılan nokta çapaya gelir; ayrıntı yatayda ortada (tablonun tepesi ekranın altına inmesin diye dikeyde
        // kenara sınırlanabilir)
        let y = K.yerlesim(d, en: en, boy: boy, sahneW: w, sahneH: h)
        let bakilan = K.ekranda(DinlemeKutusu(x: d.u, y: d.v, w: 0, h: 0), y, sahneW: w, sahneH: h)
        XCTAssertEqual(bakilan.ortaX, w / 2, accuracy: 0.5)
        XCTAssertEqual(bakilan.ortaY, 0.42 * h, accuracy: 0.5)
        XCTAssertEqual(K.ekranda(ayna, y, sahneW: w, sahneH: h).ortaX, w / 2, accuracy: 1)
        let ust = h / 2 + y.ty - y.tabanH * y.olcek / 2
        XCTAssertLessThanOrEqual(ust, 0.5, "tablonun tepesi ekranın üstünde")
    }

    func testPikselSiniriAsilmaz() {
        // 1280 px'lik görselde ayrıntıya yaklaşma çözünürlüğü aşmaz (1,48'in altında kalsa bile)
        let kucuk = DinlemeKutusu(x: 0.5, y: 0.5, w: 0.04, h: 0.04)
        let t = K.taban(en: en, boy: boy, sahneW: w, sahneH: h)
        let sinir = K.pikselSiniri(kaynakEn: 1280, tabanW: t.w, dpr: 3)
        XCTAssertLessThan(sinir, 1.48)
        let d = K.hedef(kutu: kucuk, tur: .nokta, en: en, boy: boy, kaynakEn: 1280, dpr: 3, sahneW: w, sahneH: h)
        XCTAssertLessThanOrEqual(d.olcek, max(1, sinir) + 1e-9)
        // büyük görselde de üst sınır 2,68
        let d2 = K.hedef(kutu: kucuk, tur: .nokta, en: en, boy: boy, kaynakEn: 20000, dpr: 3, sahneW: w, sahneH: h)
        XCTAssertEqual(d2.olcek, 2.68, accuracy: 1e-9)
        // anlatıda yavaş geniş gezinti
        let a = K.hedef(kutu: DinlemeKurallari.gezintiKutusu(0), tur: .anlati, en: en, boy: boy, kaynakEn: 4096,
                        dpr: 3, sahneW: w, sahneH: h)
        XCTAssertEqual(a.olcek, 1.24, accuracy: 1e-9)
    }

    func testKenardaBoslukKalmaz() {
        // Arnolfini'nin köpeği (en altta): yakınlaşınca tablonun alt kenarı ekranın altından yukarı çıkmaz
        let kopek = DinlemeKutusu(x: 0.36, y: 0.83, w: 0.24, h: 0.15)
        let d = K.hedef(kutu: kopek, tur: .nokta, en: 3840, boy: 5253, kaynakEn: 4096, dpr: 3, sahneW: w, sahneH: h)
        let y = K.yerlesim(d, en: 3840, boy: 5253, sahneW: w, sahneH: h)
        let alt = h / 2 + y.ty + y.tabanH * y.olcek / 2
        let sol = w / 2 + y.tx - y.tabanW * y.olcek / 2
        let sag = w / 2 + y.tx + y.tabanW * y.olcek / 2
        XCTAssertGreaterThanOrEqual(alt, h - 0.5)
        XCTAssertLessThanOrEqual(sol, 0.5)
        XCTAssertGreaterThanOrEqual(sag, w - 0.5)
    }

    func testTamGorunum() {
        let d = K.tamHedef(en: en, boy: boy, sahneW: w, sahneH: h)
        XCTAssertEqual(d.u, 0.5)
        XCTAssertEqual(d.capaY, 0.37 * h, accuracy: 1e-9)
        XCTAssertEqual(d.olcek, 1, accuracy: 1e-9)
        // Dikey tablo (Arnolfini) ekranın %54'ünden uzun olmaz
        let a = K.tamHedef(en: 3840, boy: 5253, sahneW: w, sahneH: h)
        let t = K.taban(en: 3840, boy: 5253, sahneW: w, sahneH: h)
        XCTAssertLessThanOrEqual(t.h * a.olcek, 0.54 * h + 1e-6)
    }

    func testYayliGecis() {
        let a = K.hedef(kutu: DinlemeKutusu(x: 0.37, y: 0.51, w: 0.10, h: 0.11), tur: .nokta, en: en, boy: boy,
                        kaynakEn: 4096, dpr: 3, sahneW: w, sahneH: h)
        let b = K.hedef(kutu: DinlemeKutusu(x: 0.51, y: 0.52, w: 0.11, h: 0.15), tur: .nokta, en: en, boy: boy,
                        kaynakEn: 4096, dpr: 3, sahneW: w, sahneH: h)
        let g = KameraGecisi.yeni(canli: a, hedef: b, tur: .nokta, sira: 2)
        let mesafe = hypot(b.u - a.u, b.v - a.v)
        XCTAssertEqual(g.derinlik, K.nefesDerinligi(mesafe), accuracy: 1e-9)
        XCTAssertEqual(g.sure, K.gecisSuresi(mesafe), accuracy: 1e-9)
        XCTAssertGreaterThanOrEqual(g.sure, 2.9)
        XCTAssertLessThanOrEqual(g.sure, 4.4)
        // başta ve sonda kesintisiz; ortada uzaklaşır
        XCTAssertEqual(g.durum(gecen: 0), a)
        XCTAssertEqual(g.durum(gecen: g.sure - 1e-6).z, b.z, accuracy: 1e-3)
        let orta = g.durum(gecen: g.sure * 0.45)
        XCTAssertLessThan(orta.z, min(a.z, b.z), "iki ayrıntı arasında önce hafif uzaklaşır")
        // tablonun tamamından ilk ayrıntıya yay yok
        let tam = K.tamHedef(en: en, boy: boy, sahneW: w, sahneH: h)
        XCTAssertEqual(KameraGecisi.yeni(canli: tam, hedef: a, tur: .nokta, sira: 1).derinlik, 0)
    }

    func testCanliSuzulme() {
        let a = KameraDurumu(u: 0.4, v: 0.5, z: log(2), capaY: 354)
        let g = KameraGecisi(bas: a, hedef: a, sure: 3, faz: 1.37)
        // varışta sıçrama yok (rampa 0'dan başlar)
        XCTAssertEqual(g.durum(gecen: 3).u, a.u, accuracy: 1e-9)
        XCTAssertEqual(g.durum(gecen: 3).z, a.z, accuracy: 1e-9)
        // belli belirsiz yaklaşır: en çok +0,072
        XCTAssertGreaterThan(g.durum(gecen: 13).z, a.z)
        XCTAssertLessThanOrEqual(g.durum(gecen: 300).z - a.z, 0.072 + 1e-9)
        for t in stride(from: 3.0, through: 60, by: 0.5) {
            let d = g.durum(gecen: t)
            XCTAssertLessThanOrEqual(abs(d.u - a.u), 0.0052 + 1e-9)
            XCTAssertLessThanOrEqual(abs(d.v - a.v), 0.0038 + 1e-9)
        }
        // başlangıç ve bitişte süzülme yok
        XCTAssertEqual(KameraGecisi.sabit(a).durum(gecen: 40), a)
    }

    func testFren() {
        var s = KameraSaati(an: 10)
        XCTAssertEqual(s.gecen(12), 2, accuracy: 1e-9)
        s.duraklat(12)
        XCTAssertEqual(s.gecen(12), 2, accuracy: 1e-9, "duraklatma anında sıçrama yok")
        // ~0,45 sn'de durur: toplam ek yol 1/6,5 sn
        XCTAssertEqual(s.gecen(12.45), 2 + (1 - exp(-6.5 * 0.45)) / 6.5, accuracy: 1e-9)
        XCTAssertEqual(s.gecen(20), 2 + 1 / 6.5, accuracy: 1e-6)
        let durdu = s.gecen(20)
        s.surdur(20)
        XCTAssertEqual(s.gecen(20), durdu, accuracy: 1e-9)
        XCTAssertLessThan(s.gecen(20.1) - durdu, 0.1, "yumuşak kalkış")
        XCTAssertEqual(s.gecen(30) - s.gecen(29), 1, accuracy: 1e-6)
        // yeni yol sıfırdan başlar, hız korunur
        s.sifirla(30)
        XCTAssertEqual(s.gecen(30), 0)
        XCTAssertEqual(s.gecen(31), 1, accuracy: 1e-6)
    }

    func testIsik() {
        XCTAssertEqual(K.isikOpakligi(gecen: 0, sure: 3), 0)
        XCTAssertEqual(K.isikOpakligi(gecen: 0.68 * 3, sure: 3), 0)
        XCTAssertEqual(K.isikOpakligi(gecen: 10, sure: 3), 1)
    }
}

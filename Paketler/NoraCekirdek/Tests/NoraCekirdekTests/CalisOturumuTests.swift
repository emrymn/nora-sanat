// Z3u (yeni, sitede yok): Çalış "Bugünün oturumu" kuralları (`CalisOturumu`): dersin kalan süresi, hafıza ritmi, dönem yolu.
import XCTest
@testable import NoraCekirdek

final class CalisOturumuTests: XCTestCase {
    /// Gör: 3 eser, 12 ayrıntı · Öğren: 5 özellik · Ayırt et: 2 ikili
    private func ders(gor: Double = 0, ogren: Double = 0, ayirt: Double = 0, gorVar: Bool = true) -> DersBilgisi {
        let kayit = DersKaydi(gor: .init(i: gor), ogren: .init(i: ogren), ayirt: .init(i: ayirt))
        let adimlar: [DersAdimi] = gorVar ? DersAdimi.allCases : [.ogren, .ayirt]
        let gorPlani = gorVar
            ? GorPlani(eserler: [.init(sanatci: "a", eser: "x", noktaSayisi: 4),
                                 .init(sanatci: "b", eser: "y", noktaSayisi: 4),
                                 .init(sanatci: "c", eser: "z", noktaSayisi: 4)], toplam: 12)
            : GorPlani(eserler: [], toplam: 0)
        let ogren = (1...5).map { OgrenMaddesi(no: $0, madde: "Madde \($0)", kanitlar: [], aciklamalar: []) }
        let ayirt = ["Empresyonizm", "Sembolizm"].map {
            AyirtIkilisi(komsu: $0, acik: true, cumleler: [], kendi: [], karsi: [], kendiMaddeler: [], komsuMaddeler: [])
        }
        return DersBilgisi(
            akim: "Post-Empresyonizm",
            adimlar: adimlar,
            gor: gorPlani,
            ogren: ogren,
            ayirt: ayirt,
            acikSanatcilar: [],
            kayit: kayit,
            durum: CalisDersKurallari.dersDurumu(kayit, adimlar: adimlar),
            kapakAdaylari: []
        )
    }

    func testBaslamamisDers() {
        let b = ders()
        // 12 × 20 sn + 5 × 60 sn + 2 × 60 sn = 660 sn = 11 dk
        XCTAssertEqual(CalisOturumu.adimKalani(b, .gor), DersAdimKalani(adim: .gor, kalan: 12, birim: "ayrıntı", saniye: 240))
        XCTAssertEqual(CalisOturumu.dersKalanDakika(b), 11)
        XCTAssertEqual(CalisOturumu.devamAltYazisi(b), "~4 dk · 12 ayrıntı kaldı")
    }

    func testSurenAdimdaKalanOran() {
        // Gör bitti, Öğren 3/5: kalan 2 özellik (2 dk) + Ayırt 2 ikili (2 dk)
        let b = ders(gor: 1, ogren: 0.6)
        XCTAssertEqual(CalisOturumu.adimKalani(b, .gor).saniye, 0)
        XCTAssertEqual(CalisOturumu.adimKalani(b, .ogren).kalan, 2)
        XCTAssertEqual(CalisOturumu.adimKalani(b, .ogren).saniye, 120, accuracy: 1e-9)
        XCTAssertEqual(CalisOturumu.dersKalanDakika(b), 4)
        XCTAssertEqual(CalisOturumu.devamAltYazisi(b), "~2 dk · 2 özellik kaldı")
    }

    func testNeredeyseBitenAdimdaEnAzBirKalir() {
        let b = ders(gor: 1, ogren: 0.95)
        XCTAssertEqual(CalisOturumu.adimKalani(b, .ogren).kalan, 1)
        XCTAssertEqual(CalisOturumu.devamAltYazisi(b), "~1 dk · 1 özellik kaldı")
    }

    func testBitenDers() {
        let b = ders(gor: 1, ogren: 1, ayirt: 1)
        XCTAssertEqual(CalisOturumu.dersKalanDakika(b), 0)
        XCTAssertEqual(CalisOturumu.devamAltYazisi(b), "")
    }

    func testGorsuzDers() {
        let b = ders(gorVar: false)
        XCTAssertEqual(CalisOturumu.adimKalani(b, .gor).saniye, 0)
        XCTAssertEqual(CalisOturumu.dersKalanDakika(b), 7)
        XCTAssertEqual(CalisOturumu.devamAltYazisi(b), "~5 dk · 5 özellik kaldı")
    }

    func testOturumDakikasi() {
        XCTAssertEqual(CalisOturumu.oturumDakikasi(dersDakika: 4, tekrar: TurOzeti(toplam: 14)), 9)
        XCTAssertEqual(CalisOturumu.oturumDakikasi(dersDakika: 4, tekrar: TurOzeti()), 4)
        XCTAssertEqual(CalisOturumu.dakika(0), 0)
        XCTAssertEqual(CalisOturumu.dakika(10), 1)
        XCTAssertEqual(CalisOturumu.dakika(150), 3)
    }

    func testRitim() {
        // 2026-11-24 salı (tasarımdaki örnek)
        let gunluk = [14, 6, 4, 8, 3, 0, 5, 2, 0, 4, 1, 3, 0, 2]
        let g = CalisOturumu.ritim(gunluk: gunluk, bugun: "2026-11-24")
        XCTAssertEqual(g.count, 14)
        XCTAssertEqual(g.prefix(7).map(\.harf), ["S", "Ç", "P", "C", "C", "P", "P"])
        XCTAssertEqual(g[0].ad, "Bugün, 24 Kas")
        XCTAssertEqual(g[1].ad, "Yarın, 25 Kas")
        XCTAssertEqual(g[2].ad, "Perşembe, 26 Kas")
        XCTAssertEqual(g[7].ad, "Salı, 1 Ara")
        XCTAssertEqual(g[7].gun, 1)
        XCTAssertTrue(g[0].yogun)
        XCTAssertEqual(g.filter(\.yogun).count, 1)
        XCTAssertTrue(g[5].dinlenme)
        XCTAssertEqual(g[0].dakika, 5)
        XCTAssertEqual(CalisOturumu.haftaAraligi(Array(g.prefix(7))), "24–30 Kas")
        XCTAssertEqual(CalisOturumu.haftaAraligi(Array(g.suffix(7))), "1–7 Ara")
        XCTAssertEqual(CalisOturumu.haftaAraligi(Array(g[3..<10])), "27 Kas – 3 Ara")
        XCTAssertEqual(CalisOturumu.ritimSatiri(g[0]).vurgu, "Bugün, 24 Kas:")
        XCTAssertEqual(CalisOturumu.ritimSatiri(g[0]).metin, " 14 kart (~5 dk) · en yoğun gün.")
        XCTAssertEqual(CalisOturumu.ritimSatiri(g[1]).metin, " 6 kart (~2 dk).")
        XCTAssertEqual(CalisOturumu.ritimSatiri(g[5]).metin, " dinlenme günü, tekrar yok.")
        XCTAssertEqual(CalisOturumu.yarinYazisi(gunluk: gunluk), "6 kart · ~2 dk")
        XCTAssertEqual(CalisOturumu.yarinYazisi(gunluk: [3, 0]), "Dinlenme günü")
        XCTAssertEqual(CalisOturumu.ritimNotu(gunluk: gunluk), ["52 sanatçı", "3 dinlenme günü"])
        XCTAssertEqual(CalisOturumu.ritimNotu(gunluk: [1, 2]), ["3 sanatçı"])
    }

    func testBoncukCapi() {
        XCTAssertEqual(CalisOturumu.boncukCapi(0, en: 14), 10)
        XCTAssertEqual(CalisOturumu.boncukCapi(14, en: 14), 32)
        XCTAssertEqual(CalisOturumu.boncukCapi(6, en: 14), 26)
        XCTAssertEqual(CalisOturumu.boncukCapi(1, en: 14), 20)
        XCTAssertEqual(CalisOturumu.boncukCapi(5, en: 0), 32)
    }

    func testDonemYolu() {
        XCTAssertEqual(CalisOturumu.yolAltYazisi(ders(gor: 1, ogren: 1, ayirt: 1)), "0 sanatçı · 3 adım tamam")
        XCTAssertEqual(CalisOturumu.yolAltYazisi(ders(gorVar: false)), "0 sanatçı · 2 adım")
        let kilitli = AkimDurumu(ad: "Sembolizm", sira: 1, toplam: 4, acikSayisi: 0, acik: false, acilacagiKonu: 14)
        XCTAssertEqual(CalisOturumu.kilitliAltYazisi(kilitli, islenen: [11, 12, 13]), "Konu 14'te açılır · 1 konu kaldı")
        XCTAssertEqual(CalisOturumu.kilitliAltYazisi(kilitli, islenen: [20]), "Konu 14'te açılır")
        var hic = kilitli
        hic.acilacagiKonu = nil
        XCTAssertEqual(CalisOturumu.kilitliAltYazisi(hic, islenen: []), "Henüz açılmadı")
        XCTAssertEqual(
            CalisOturumu.yolOzeti([ders(gor: 1, ogren: 1, ayirt: 1), ders(gor: 1, ogren: 1, ayirt: 1), ders(gor: 1), ders()]),
            "2 bitti · 1 sürüyor"
        )
        XCTAssertEqual(CalisOturumu.yolOzeti([ders(), ders()]), "2 sırada")
    }

    func testAkimYayi() {
        let acik = ["Gerçekçilik", "Empresyonizm", "Post-Empresyonizm", "Romantizm"]
        XCTAssertEqual(
            CalisOturumu.akimYayi(aciklar: acik, kilitliler: ["Sembolizm"], bugunku: "Post-Empresyonizm"),
            AkimYayi(onceki: "Empresyonizm", bugunku: "Post-Empresyonizm", sonraki: "Romantizm", sonrakiKilitli: false)
        )
        XCTAssertEqual(
            CalisOturumu.akimYayi(aciklar: acik, kilitliler: ["Sembolizm"], bugunku: "Romantizm"),
            AkimYayi(onceki: "Post-Empresyonizm", bugunku: "Romantizm", sonraki: "Sembolizm", sonrakiKilitli: true)
        )
        XCTAssertEqual(
            CalisOturumu.akimYayi(aciklar: ["Gotik"], kilitliler: [], bugunku: nil),
            AkimYayi(onceki: nil, bugunku: "Gotik", sonraki: nil, sonrakiKilitli: false)
        )
        XCTAssertNil(CalisOturumu.akimYayi(aciklar: [], kilitliler: ["Gotik"], bugunku: nil))
    }
}

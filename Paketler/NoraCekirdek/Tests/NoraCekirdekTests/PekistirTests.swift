// Kaynak: sanat-atlasi js/oturum.js, js/celdirici.js, js/turlar.js, js/bolum.js, js/soruTurlari.js @ a866b86
import XCTest
@testable import NoraCekirdek

final class PekistirTests: XCTestCase {
    let bugun = "2026-11-21"
    let rng = { 0.42 }

    func sanatcilar() -> [Sanatci] {
        (0..<8).map { i in
            var s = Sanatci(json: .nesne([]))
            s.id = String(i)
            s.ad = "Ressam \(i)"
            s.akim = i < 4 ? "A" : "B"
            s.dogum = 1600 + i
            s.konu = i < 3 ? 1 : 2
            return s
        }
    }

    func kayit() throws -> Ilerleme {
        var il = try Ilerleme(veri: Data(#"{"gelecekAlan":42}"#.utf8))
        il.islenen = [1, 2]
        il.gunluk = Gunluk(tarih: bugun, yeni: 6)
        il.ayarla("gunlukKart", .sayi(7))
        let skor = Skor(kutu: 0, sonraki: bugun, yanlis: 1, son: bugun)
        il.skorlar = ["1": SkorKaydi(sanatci: skor), "6": SkorKaydi(akim: skor)]
        il.karisanlar = ["0|3": Karisan(n: 3, son: bugun), "0|4": Karisan(n: 2, son: bugun)]
        return il
    }

    func plan(_ tur: PekistirmeTuru, _ il: Ilerleme) -> TurPlani {
        TurPlani.kur(tur, sanatcilar: sanatcilar(), ilerleme: il, bugun: bugun,
                     akimSira: ["B": 0, "A": 1], eseriVar: { _ in true }, rastgele: rng)
    }

    func testSiteModullerininCevaplari() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/pekistir"))
        let cevaplar = try JSONDecoder().decode([String: [String]].self, from: Data(contentsOf: url))
        let il = try kayit()
        let s = sanatcilar()
        XCTAssertEqual(TurPlani.kartlariSec(s, skorlar: il.skorlar, bugun: bugun, adet: 7, kota: 2,
                                            karisik: false, rastgele: rng).map(\.id), cevaplar["donem"])
        XCTAssertEqual(plan(.karisik, il).kartlar, cevaplar["karisik"])
        XCTAssertEqual(plan(.konu(1), il).kartlar, cevaplar["konu"])
        let hatalar = plan(.hatalar, il)
        XCTAssertEqual(hatalar.kartlar, cevaplar["hatalar"])
        XCTAssertEqual(hatalar.esler, ["0": "3", "3": "0"])
        let akimlar = ["A", "B"].enumerated().map { i, ad in
            Akim(json: .nesne([("ad", .metin(ad)), ("sira", .sayi(i + 1)),
                               ("komsular", .dizi([.metin(i == 0 ? "B" : "A")]))]))
        }
        XCTAssertEqual(Celdirici.sanatciSecenekleri(s[0], sanatcilar: s, akimlar: akimlar, acik: ["2"],
                                                     zorluk: .zor, ortak: ["1"], rastgele: rng), cevaplar["secenekler"])
        var o = PekistirmeOturumu(s.map(\.id))
        var idler: [String] = []
        while let k = o.simdiki {
            idler.append(k.id)
            o.ilerle(dogruMu: k.id != "0", rastgele: rng)
        }
        XCTAssertEqual(idler, cevaplar["kuyruk"])
        XCTAssertEqual(o.yanlis, 4)
        XCTAssertEqual(o.ilkToplam, 8)
        XCTAssertEqual(o.ilkDogru, 7)
    }

    func testBolumGruplariVeGunlukSinir() throws {
        var il = try kayit()
        il.gunluk = Gunluk(tarih: bugun, yeni: 8)
        XCTAssertEqual(plan(.donem("A"), il).kartlar, ["1"])
        let ids = sanatcilar().map(\.id)
        let grup = plan(.bolum(id: "b", sanatcilar: ids, seviye: .tanitim(orta: false, grup: 1)), il)
        XCTAssertEqual(grup.tanisma, ["4", "5", "6", "7"])
        XCTAssertEqual(grup.kartlar.count, 8)
        XCTAssertEqual(Set(grup.kartlar), Set(grup.tanisma))
        XCTAssertTrue(zip(grup.kartlar, grup.kartlar.dropFirst()).allSatisfy { $0 != $1 })
        il[alan: "bolumler"] = .nesne([("b", .nesne([("tanitimGrup", .dizi([.sayi(1)]))]))])
        XCTAssertEqual(plan(.bolum(id: "b", sanatcilar: ids, seviye: .kolay), il).tanisma, Array(ids.prefix(4)))
        XCTAssertEqual(plan(.bolum(id: "b", sanatcilar: [], seviye: .orta), il).kartlar, [])
        XCTAssertEqual(plan(.konu(1), il).kartlar.count, 6)
    }

    func testHatalarinTarihSiniri() throws {
        var il = try kayit()
        il.karisanlar = ["0|3": Karisan(n: 9, son: "2026-11-14"), "4|5": Karisan(n: 9, son: "2026-11-22"),
                         "2|3": Karisan(n: 1, son: "2026-11-15")]
        XCTAssertEqual(plan(.hatalar, il).kartlar, ["2", "3", "1"])
    }

    func testKartCevabiTekKezYazilir() throws {
        var il = try kayit()
        var o = PekistirmeOturumu(["0"])
        let s = sanatcilar()[0]
        let cevap = PekistirmeOturumu.KartCevabi.karisik(sanatci: "3", akim: "A")
        XCTAssertTrue(o.cevapla(konum: 0, sanatci: s, tur: .karisik, cevap: cevap, bugun: bugun, ilerleme: &il))
        XCTAssertFalse(o.cevapla(konum: 0, sanatci: s, tur: .karisik, cevap: cevap, bugun: bugun, ilerleme: &il))
        XCTAssertEqual(il.karisanlar["0|3"]?.n, 4)
        XCTAssertEqual(il.skorlar["0"]?.akim?.dogru, 1)
        XCTAssertEqual(il.skorlar["0"]?.sanatci?.yanlis, 1)
        XCTAssertEqual(il.seviyeler["A"]?.son, [0])
        XCTAssertEqual(il.gunluk.yeni, 7)
        XCTAssertEqual(il.gunluk.kart, 1)
        XCTAssertEqual(il.gecmis[bugun]?.dogru, 0)
        XCTAssertEqual(il[alan: "gelecekAlan"]?.tamSayi, 42)
        XCTAssertEqual(o.simdiki?.tekrar, true)
    }

    func testAkrabaVeOrtakAtifHataEsiOlamaz() {
        var s = sanatcilar()
        s[0].ad = "Jan Ressam the Elder"
        s[1].ad = "Jan Ressam the Younger"
        for es in ["1", "2"] {
            let sonuc = Celdirici.sanatciSecenekleri(s[0], sanatcilar: s, akimlar: [], acik: [], zorluk: .zor,
                                                     ortak: ["2"], es: es, rastgele: rng)
            XCTAssertEqual(Set(sonuc).count, 4)
            XCTAssertFalse(sonuc.contains("1"))
            XCTAssertFalse(sonuc.contains("2"))
        }
    }

    func testSoruTuruSkorlariVeSecenekleri() throws {
        var il = try kayit()
        for tur in [SoruTuru.kursBolumu, .ikonografi] {
            var oturum = PekistirmeOturumu(["1"])
            tur.cevapla(oturum: &oturum, konum: 0, dogru: true, akim: "A", bugun: bugun, ilerleme: &il)
        }
        XCTAssertEqual(il.skorlar["1"]?.bolumKart?.dogru, 1)
        XCTAssertEqual(il.skorlarKonu["1"]?.dogru, 1)
        XCTAssertEqual(il.skorlar["1"]?.sanatci?.dogru, 0)
        XCTAssertEqual(Set(SoruTuru.bolumSecenekleri(dogru: "0", siraliBolumler: ["0","1","2","3","4"], rastgele: rng)), ["0","1","2","3"])
    }
    func testEserSecimiVeTersKart() {
        func eser(_ ad: String) -> Eser {
            Eser(anahtar: ad, kaynak: "", kaynaklar: [], baslik: ad, tarih: "", yil: nil,
                 muze: "", kursKonu: nil, qid: nil, gorseller: [Gorsel(k: "c", d: ad)], pekistirme: true, sl: 0)
        }
        var ortak = eser("ortak")
        ortak.ortak = ["a"]
        let eserler = ["1", "2", "3", "4"].map(eser)
        let kolaylik = ["1": 10.0, "2": 8, "3": 5, "4": 2]
        XCTAssertEqual(KartEseri.sec(eserler, tur: .karisik, seviye: 2, son: ["4"], kolaylik: kolaylik, rastgele: { 0.99 })?.anahtar, "3")
        XCTAssertTrue(KartEseri.tersSorulur(.karisik, seviye: 1, rastgele: { 0.24 }))
        XCTAssertFalse(KartEseri.tersSorulur(.karisik, seviye: 1, rastgele: { 0.25 }))
        let ters = KartEseri.tersSecenekleri(dogru: ("a", eser("1")),
            adaylar: [("b", [ortak, eser("2")]), ("c", [eser("3")]), ("d", [eser("4")])],
            kotuler: [:], konu: { _, _ in nil }, rastgele: rng)
        XCTAssertEqual(Set(ters?.map { $0.eser.anahtar } ?? []), ["1", "2", "3", "4"])
    }
}

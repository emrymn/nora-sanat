import Foundation
import XCTest
@testable import NoraCekirdek

/// Z4h · Hikâyeler'e "Diziler" rafı: ayrıştırma, sıralama, kapak kolajı seçimi, okundu/ilerleme durumu,
/// ses durumu ve adres çözme testleri. Örnek: `Ornekler/hikayeler/diziler.json` (sanat-atlasi @ 57257c3).
final class DizilerTests: XCTestCase {
    private func ornek(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: ad, withExtension: "json", subdirectory: "Ornekler/hikayeler"))
        return try Data(contentsOf: url)
    }

    private func katalog() throws -> DiziKatalogu { DiziVerisi.coz(try ornek("diziler")) }

    // MARK: Ayrıştırma

    func testAyristirmaVeSira() throws {
        let k = try katalog()
        XCTAssertEqual(k.surum, 1)
        XCTAssertEqual(k.diziler.map(\.id), ["dueller"])
        let d = try XCTUnwrap(k.dizi("dueller"))
        XCTAssertEqual(d.ad, "Düellolar")
        XCTAssertFalse(d.aciklama.isEmpty)
        XCTAssertEqual(d.bolumIds, [
            "dueller-leonardo-michelangelo",
            "dueller-ghiberti-brunelleschi",
            "dueller-caravaggio-baglione",
        ])

        let bolumler = k.bolumleri("dueller")
        XCTAssertEqual(bolumler.map(\.sira), [1, 2, 3])
        let b1 = bolumler[0]
        XCTAssertEqual(b1.baslik, "Palazzo Vecchio'nun İki Duvarı")
        XCTAssertEqual(b1.sanatcilar, ["leonardo-da-vinci", "michelangelo"])
        XCTAssertEqual(b1.hikaye.dizi, "dueller")
        XCTAssertEqual(b1.hikaye.bolumSirasi, 1)
        XCTAssertEqual(b1.kelime, 1090)

        // Hem commons hem qid eserleri çözülmüş
        let e1 = b1.hikaye.bolumler[0].eserler
        XCTAssertEqual(e1.count, 2)
        XCTAssertEqual(e1[0].sanatci, "michelangelo")
        XCTAssertEqual(e1[0].qid, "")
        XCTAssertEqual(e1[0].commons, "Michelangelo%27s_David_2015.jpg")
        XCTAssertEqual(e1[0].kimlik, "c:michelangelo's_david_2015.jpg")
        XCTAssertEqual(e1[1].sanatci, "leonardo-da-vinci")
        XCTAssertEqual(e1[1].qid, "Q12418")
        XCTAssertNil(e1[1].commons)
        XCTAssertEqual(e1[1].kimlik, "q:Q12418")

        // Kapak eseri commons olsa bile kapakEseri dolar, kapakQid ise ilk qid'yi verir
        XCTAssertEqual(b1.kapakEseri, e1[0])
        XCTAssertEqual(b1.hikaye.kapakQid, "Q12418")
    }

    /// Z4i: sanatçının geçtiği bölümler
    func testSanatcininBolumleri() throws {
        let k = try katalog()
        XCTAssertEqual(k.sanatcininBolumleri("michelangelo").map(\.id), ["dueller-leonardo-michelangelo"])
        XCTAssertEqual(k.sanatcininBolumleri("caravaggio").map(\.id), ["dueller-caravaggio-baglione"])
        XCTAssertEqual(k.sanatcininBolumleri("yok-boyle-biri"), [])
        XCTAssertEqual(DiziKatalogu.bos.sanatcininBolumleri("michelangelo"), [])
    }

    func testBozukVeEksikVeri() {
        XCTAssertTrue(DiziVerisi.coz(nil).bosMu)
        XCTAssertTrue(DiziVerisi.coz(Data("{".utf8)).bosMu)

        let j = Data("""
        {
          "surum": 1,
          "diziler": [
            { "id": "", "ad": "Adsız", "aciklama": "", "bolumler": ["b1"] },
            { "id": "bos", "ad": "Boş Dizi", "aciklama": "", "bolumler": ["yok"] },
            { "id": "iyi", "ad": "İyi Dizi", "aciklama": "Açıklama", "bolumler": ["b1", "yok", "b1", "b2"] }
          ],
          "bolumler": {
            "b1": {
              "dizi": "iyi", "baslik": "Birinci", "alt_baslik": "Alt",
              "sanatcilar": ["caravaggio"],
              "giris": ["İlk paragraf bir iki üç"],
              "bolumler": [{
                "baslik": "Ara", "yillar": "1600", "paragraflar": ["İkinci"],
                "eserler": [{"sanatci": "caravaggio"}, {"sanatci": "caravaggio", "qid": "Q1", "bag": "not"}]
              }],
              "kapanis": ["Son"],
              "kaynaklar": [{"adres": "https://www.uffizi.it/a"}]
            },
            "b2": { "dizi": "iyi", "baslik": "Paragrafsız", "giris": [], "bolumler": [], "kapanis": [] }
          }
        }
        """.utf8)

        let k = DiziVerisi.coz(j)
        XCTAssertEqual(k.diziler.map(\.id), ["iyi"])
        XCTAssertEqual(k.bolumleri("iyi").map(\.id), ["b1"])
        let b1 = k.bolum("b1")!
        XCTAssertEqual(b1.sira, 1)
        // Kelime verilmemişse paragraflardan hesaplanır
        XCTAssertEqual(b1.kelime, 7)
        // Boş qid+commons eseri atlanır
        XCTAssertEqual(b1.hikaye.bolumler[0].eserler.map(\.qid), ["Q1"])
        // Kaynak başlığı yoksa alan adı
        XCTAssertEqual(b1.hikaye.kaynaklar.map(\.baslik), ["uffizi.it"])
    }

    // MARK: Kapak seçimi

    func testKapakEserleriBolumlerdenSecilir() throws {
        let k = try katalog()
        let d = try XCTUnwrap(k.dizi("dueller"))
        let kapaklar = DiziKurallari.kapakEserleri(d, katalog: k, enCok: 3)
        // Üç bölümün ilk eserleri sırayla: David (commons), Ghiberti/Brunelleschi levha (commons), Q969377 (qid)
        XCTAssertEqual(kapaklar.count, 3)
        XCTAssertEqual(kapaklar[0].commons, "Michelangelo%27s_David_2015.jpg")
        XCTAssertEqual(kapaklar[1].commons, "Ghiberti_and_Brunelleschi,_Sacrifice_of_Isaac,_competition_reliefs,_1401-2,_Bargello,_Florence.jpg")
        XCTAssertEqual(kapaklar[2].qid, "Q969377")

        // Tekrar eden görseller elenir ve tek bölümlü dizide sonraki eserlerden tamamlanır
        let tek = DiziKatalogu(
            diziler: [Dizi(id: "t", ad: "T", aciklama: "", bolumIds: ["e1"])],
            bolumler: [
                "e1": DiziBolumu(id: "e1", dizi: "t", sira: 1, hikaye: SanatciHikayesi(
                    id: "e1", baslik: "B1", altBaslik: "", giris: ["g"],
                    bolumler: [HikayeBolumu(baslik: "A", yillar: "", paragraflar: ["p"], eserler: [
                        HikayeEseri(qid: "Q1", bag: "", sanatci: "s1"),
                        HikayeEseri(qid: "Q1", bag: "", sanatci: "s1"),
                        HikayeEseri(qid: "Q2", bag: "", sanatci: "s2"),
                    ])], kapanis: []))
            ]
        )
        XCTAssertEqual(DiziKurallari.kapakEserleri(tek.diziler[0], katalog: tek, enCok: 3).map(\.qid), ["Q1", "Q2"])
    }

    // MARK: Sıralama ve okundu durumu

    func testSiralamaVeIlerlemeDurumu() {
        func bolum(_ id: String, _ dizi: String, _ sira: Int) -> DiziBolumu {
            DiziBolumu(id: id, dizi: dizi, sira: sira, hikaye: SanatciHikayesi(
                id: id, baslik: id, altBaslik: "", giris: ["g"], bolumler: [], kapanis: [], kelime: 1600))
        }
        let d1 = Dizi(id: "d1", ad: "Bir", aciklama: "", bolumIds: ["b1", "b2"])
        let d2 = Dizi(id: "d2", ad: "İki", aciklama: "", bolumIds: ["b3"])
        let d3 = Dizi(id: "d3", ad: "Üç", aciklama: "", bolumIds: ["b4", "b5"])
        let k = DiziKatalogu(
            diziler: [d1, d2, d3],
            bolumler: [
                "b1": bolum("b1", "d1", 1), "b2": bolum("b2", "d1", 2),
                "b3": bolum("b3", "d2", 1),
                "b4": bolum("b4", "d3", 1), "b5": bolum("b5", "d3", 2),
            ]
        )
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)

        // Başta dosya sırası
        XCTAssertEqual(DiziKurallari.sirala(k, yerler: [:]).map(\.id), ["d1", "d2", "d3"])

        // d1 bitti, d3 yarım, d2 başlanmamış → d3 (yarım), d2 (yeni), d1 (bitti)
        let yerler: [String: OkumaYeri] = [
            "b1": OkumaYeri(paragraf: 10, toplam: 10, bitti: true, tarih: t0),
            "b2": OkumaYeri(paragraf: 10, toplam: 10, bitti: true, tarih: t0.addingTimeInterval(10)),
            "b4": OkumaYeri(paragraf: 5, toplam: 10, tarih: t0.addingTimeInterval(20)),
        ]
        XCTAssertEqual(DiziKurallari.sirala(k, yerler: yerler).map(\.id), ["d3", "d2", "d1"])

        let il1 = DiziKurallari.ilerleme(d1, katalog: k, yerler: yerler)
        XCTAssertTrue(il1.bitti)
        XCTAssertEqual(il1.okunan, 2)
        XCTAssertEqual(il1.oran, 1.0, accuracy: 0.001)

        let il3 = DiziKurallari.ilerleme(d3, katalog: k, yerler: yerler)
        XCTAssertFalse(il3.bitti)
        XCTAssertTrue(il3.baslandi)
        XCTAssertEqual(il3.okunan, 0)
        XCTAssertEqual(il3.yarim, 1)
        XCTAssertEqual(il3.oran, 0.25, accuracy: 0.001)

        // Bölüm durumları
        XCTAssertEqual(DiziKurallari.bolumDurumu(k.bolum("b1")!, yer: yerler["b1"]), .okundu)
        XCTAssertEqual(DiziKurallari.bolumDurumu(k.bolum("b4")!, yer: yerler["b4"]), .yarim(kalanDk: 5, dinleme: false))
        XCTAssertEqual(DiziKurallari.bolumDurumu(k.bolum("b3")!, yer: nil), .okunmadi)

        // Sıradaki bölüm: yarım kalan varsa o; yoksa ilk okunmamış
        XCTAssertEqual(DiziKurallari.siradakiBolum(d3, katalog: k, yerler: yerler)?.id, "b4")
        XCTAssertEqual(DiziKurallari.siradakiBolum(d2, katalog: k, yerler: yerler)?.id, "b3")
        XCTAssertEqual(DiziKurallari.siradakiBolum(d1, katalog: k, yerler: yerler)?.id, "b1")

        // Çalar için sonraki bölümler
        XCTAssertEqual(DiziKurallari.siradaki(k, diziId: "d3", simdikiBolumId: "b4", yerler: yerler).map(\.id), ["b5"])
    }

    // MARK: Ses, arama ve adresler

    func testSesDurumuVeAdresler() throws {
        let k = try katalog()
        let b1 = try XCTUnwrap(k.bolum("dueller-leonardo-michelangelo"))
        let sesDizini = try XCTUnwrap(SesDizini(veri: try ornek("ses_dizini")))

        // Dizi bölümünün henüz R2 kaydı yok → sesVarMi ve dinlenebilir false
        XCTAssertFalse(HikayeSesi.sesVarMi(b1.hikaye, dizin: nil))
        XCTAssertFalse(HikayeSesi.sesVarMi(b1.hikaye, dizin: sesDizini))
        XCTAssertFalse(HikayeSesi.dinlenebilir(b1.hikaye, dizin: sesDizini))

        // Parçalar üretilip dizine bir kayıt eklenince otomatik true olur
        let parcalar = HikayeSesi.parcalar(b1.hikaye)
        XCTAssertFalse(parcalar.isEmpty)
        let yeniDizin = SesDizini(ses: "Fola", klasor: "ses/Fola", parcalar: [parcalar[0].anahtar: 4.2])
        XCTAssertTrue(HikayeSesi.sesVarMi(b1.hikaye, dizin: yeniDizin))
        XCTAssertTrue(HikayeSesi.dinlenebilir(b1.hikaye, dizin: yeniDizin))

        // Sanatçı hikâyesinde (dizi == nil) ses dizini olmasa da dinlenebilir true kalır (AVSpeech)
        var normal = b1.hikaye
        normal.dizi = nil
        XCTAssertTrue(HikayeSesi.dinlenebilir(normal, dizin: nil))

        // Arama ve toplam süre
        XCTAssertEqual(DiziKurallari.toplamOkumaDakikasi(k.diziler[0], katalog: k), 20)
        XCTAssertEqual(DiziKurallari.ara(k, sorgu: "vaftizhane", sanatciAdi: { $0 }).map(\.id), ["dueller-ghiberti-brunelleschi"])
        XCTAssertEqual(DiziKurallari.ara(k, sorgu: "duello", sanatciAdi: { $0 }).count, 3)

        // Commons eseri yedek üretimi
        let e = DiziKurallari.commonsEseri(dosya: "Michelangelo%27s_David_2015.jpg", sanatci: "michelangelo")
        XCTAssertEqual(e.anahtar, "c:michelangelo's_david_2015.jpg")
        XCTAssertEqual(e.gorseller.first?.k, "commons")
        XCTAssertEqual(e.gorseller.first?.d, "Michelangelo's_David_2015.jpg")
        XCTAssertEqual(e.gorunenAd, "Michelangelo's David 2015")

        // Adresler
        XCTAssertEqual(HikayeAdresi.dizi("dueller"), "#/dizi/dueller")
        XCTAssertEqual(HikayeAdresi.diziBolumu("dueller", "dueller-leonardo-michelangelo"), "#/dizi/dueller/dueller-leonardo-michelangelo")
        XCTAssertEqual(HikayeAdresi.diziYolu("#/dizi/dueller")?.dizi, "dueller")
        XCTAssertNil(HikayeAdresi.diziYolu("#/dizi/dueller")?.bolum)
        XCTAssertEqual(HikayeAdresi.diziYolu("#/dizi/dueller/dueller-leonardo-michelangelo")?.bolum, "dueller-leonardo-michelangelo")
        XCTAssertEqual(SiteRotalari.sekme("#/dizi/dueller"), .hikayeler)
        XCTAssertEqual(SiteRotalari.sekme("#/dizi/dueller/dueller-leonardo-michelangelo"), .hikayeler)
    }
}

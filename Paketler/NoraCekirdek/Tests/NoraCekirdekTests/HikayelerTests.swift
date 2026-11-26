import Foundation
import XCTest
@testable import NoraCekirdek

/// Z4b · Hikâyeler. Sitede bu sekme yok: kâhin yerine davranış testi. Ses sözleşmesinin beklenen değerleri
/// sanat-atlasi scripts/ses_uret.py'nin kendi `hikaye_parcalari`, `duzgun` ve `anahtar` fonksiyonlarıyla alındı
/// (@ 1f54a6c; `Ornekler/hikayeler/cevaplar.json`). Veri örneği gerçek `data/sanatci_hikayeleri.json`'dan üç hikâye,
/// ses dizini gerçek `data/ses_dizini.json`'un bu üç hikâyeye düşen parçaları.
final class HikayelerTests: XCTestCase {
    struct Cevaplar: Decodable {
        struct Hikaye: Decodable {
            let metinler: [String]
            let anahtarlar: [String]
            let kayitli: Int
            let sure: Double
        }
        let hikayeler: [String: Hikaye]
        let toplamParca: Int
    }

    private func ornek(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: ad, withExtension: "json", subdirectory: "Ornekler/hikayeler"))
        return try Data(contentsOf: url)
    }

    private func hikayeler() throws -> [SanatciHikayesi] { HikayeVerisi.coz(try ornek("sanatci_hikayeleri")) }
    private func cevaplar() throws -> Cevaplar { try JSONDecoder().decode(Cevaplar.self, from: try ornek("cevaplar")) }
    private func dizin() throws -> SesDizini { try XCTUnwrap(SesDizini(veri: try ornek("ses_dizini"))) }

    // MARK: Veri

    func testVeriSirasiVeAlanlar() throws {
        let l = try hikayeler()
        // Dosyadaki sıra korunur
        XCTAssertEqual(l.map(\.id), ["johannes-vermeer", "vincent-van-gogh", "rembrandt-van-rijn"])
        let v = l[0]
        XCTAssertEqual(v.baslik, "Gürültülü Bir Evde Kurulan Sessizlik")
        XCTAssertFalse(v.altBaslik.isEmpty)
        XCTAssertGreaterThan(v.bolumler.count, 3)
        XCTAssertGreaterThan(v.kelime, 2000)
        XCTAssertEqual(v.olusturma.count, 10)
        // Kaynaklar verideki sırayla, alan adıyla
        XCTAssertFalse(v.kaynaklar.isEmpty)
        for k in v.kaynaklar { XCTAssertTrue(k.adres.hasPrefix("http")) }
        // Kapak: ilk bölümün ilk eseri
        XCTAssertEqual(v.kapakQid, v.bolumler[0].eserler[0].qid)
    }

    func testBozukVeri() {
        XCTAssertEqual(HikayeVerisi.coz(nil), [])
        XCTAssertEqual(HikayeVerisi.coz(Data("{".utf8)), [])
        let j = Data("""
        {"sanatcilar":{"a":{"baslik":"","giris":["x"]},"b":{"baslik":"B","giris":[]},
         "c":{"baslik":"C","alt_baslik":"c","giris":["  ","g"],"bolumler":[{"baslik":"Bir","yillar":"1500","paragraflar":["p"],
         "eserler":[{"qid":"Q1","bag":"b1"},{"qid":""},{"qid":"Q2","bag":"b2"}]}],"kapanis":["k"],
         "baglantilar":[{"sanatci":"X","iliski":"i"},{"sanatci":"Y","iliski":"j","id":"y"}],
         "kaynaklar":[{"adres":"https://www.nga.gov/a"},{"baslik":"b.com","adres":"https://b.com"}],"kelime":321}}}
        """.utf8)
        let l = HikayeVerisi.coz(j)
        XCTAssertEqual(l.map(\.id), ["c"])
        let c = l[0]
        XCTAssertEqual(c.giris, ["g"])
        XCTAssertEqual(c.bolumler[0].eserler.map(\.qid), ["Q1", "Q2"])
        XCTAssertEqual(c.baglantilar.map(\.id), [nil, "y"])
        XCTAssertEqual(c.kaynaklar.map(\.baslik), ["nga.gov", "b.com"])
        XCTAssertEqual(c.paragraflar, ["g", "p", "k"])
        // Paragraftan fazla eser bölümün sonunda
        XCTAssertEqual(c.bloklar, [
            .paragraf(no: 0, metin: "g"),
            .araBaslik(bolum: 0, baslik: "Bir", yillar: "1500"),
            .paragraf(no: 1, metin: "p"),
            .eser(bolum: 0, sira: 0, HikayeEseri(qid: "Q1", bag: "b1")),
            .eser(bolum: 0, sira: 1, HikayeEseri(qid: "Q2", bag: "b2")),
            .kapanis,
            .paragraf(no: 2, metin: "k"),
        ])
        XCTAssertNil(c.bolum(paragraf: 0))
        XCTAssertEqual(c.bolum(paragraf: 1), 0)
        XCTAssertNil(c.bolum(paragraf: 2))
    }

    func testBloklarEserlerParagraflarinArdinda() throws {
        for h in try hikayeler() {
            let b = h.bloklar
            // Bütün paragraflar ve bütün eserler, sırayla, birer kez
            let paragraflar = b.compactMap { if case .paragraf(_, let m) = $0 { return m }; return nil }
            XCTAssertEqual(paragraflar, h.paragraflar)
            let eserler = b.compactMap { if case .eser(_, _, let e) = $0 { return e }; return nil }
            XCTAssertEqual(eserler, h.bolumler.flatMap(\.eserler))
            // Her eserin hemen öncesinde bir paragraf ya da eser var (başlık değil)
            for (i, x) in b.enumerated() {
                guard case .eser = x else { continue }
                switch b[i - 1] {
                case .paragraf, .eser: break
                default: XCTFail("\(h.id): eser bir başlığın ardında")
                }
            }
            // Boş bölüm (Rembrandt'ın paragrafsız "Kapanış"ı) ara başlık olmaz
            XCTAssertEqual(b.filter { if case .araBaslik = $0 { return true }; return false }.count,
                           h.bolumler.filter { !$0.paragraflar.isEmpty || !$0.eserler.isEmpty }.count)
            if h.id == "rembrandt-van-rijn" { XCTAssertEqual(h.bolumler.count - 1, h.bolumler.filter { !$0.paragraflar.isEmpty }.count) }
        }
    }

    // MARK: Ses (ses_uret.py sözleşmesi)

    func testParcalarBetiginSirasiVeAnahtarlari() throws {
        let c = try cevaplar()
        for h in try hikayeler() {
            let beklenen = try XCTUnwrap(c.hikayeler[h.id])
            let p = HikayeSesi.parcalar(h)
            XCTAssertEqual(p.map(\.metin), beklenen.metinler, h.id)
            XCTAssertEqual(p.map(\.anahtar), beklenen.anahtarlar, h.id)
            // İlk iki parça başlık ve alt başlık; bölüm başlıkları yılsız
            XCTAssertEqual(p[0].yer, .baslik)
            XCTAssertEqual(p[1].yer, .altBaslik)
            for (bi, b) in h.bolumler.enumerated() {
                let bp = try XCTUnwrap(p.first { $0.yer == .bolumBasligi(bi) })
                XCTAssertEqual(bp.metin, SesAnahtari.metin(b.baslik))
                XCTAssertFalse(bp.metin.contains(b.yillar), "bölüm başlığı yılsız okunur")
            }
            // "bag" notları okunmaz
            let metinler = Set(p.map(\.ham))
            for e in h.bolumler.flatMap(\.eserler) where !e.bag.isEmpty { XCTAssertFalse(metinler.contains(e.bag)) }
            // Bütün paragraflar okunur (bu örneklerde tekrar yok) ve numaraları sırayla
            XCTAssertEqual(p.compactMap(\.paragraf), Array(h.paragraflar.indices))
        }
    }

    func testTekrarlananVeBosParcaAtlanir() {
        let h = SanatciHikayesi(id: "x", baslik: "Başlık", altBaslik: "  ", giris: ["Aynı söz.", "Aynı  söz"],
                                bolumler: [HikayeBolumu(baslik: "Başlık.", yillar: "1600", paragraflar: ["Yeni"], eserler: [])],
                                kapanis: ["Son"])
        let p = HikayeSesi.parcalar(h)
        // "Başlık" ve "Başlık." düzgünleşince aynı; "Aynı söz." ile "Aynı  söz" de
        XCTAssertEqual(p.map(\.metin), ["Başlık.", "Aynı söz.", "Yeni.", "Son."])
        XCTAssertEqual(p.map(\.yer), [.baslik, .paragraf(0), .paragraf(2), .paragraf(3)])
        // Okunmayan paragrafın parçası: sonraki ilk paragraf
        XCTAssertEqual(HikayeSesi.parca(paragraf: 1, p), 2)
        XCTAssertEqual(HikayeSesi.parca(paragraf: 3, p), 3)
        XCTAssertNil(HikayeSesi.parca(paragraf: 9, p))
        XCTAssertNil(HikayeSesi.paragraf(parca: 0, p))
        XCTAssertEqual(HikayeSesi.paragraf(parca: 1, p), 0)
    }

    func testDinlemeSuresiKayittanYoksaTahmin() throws {
        let c = try cevaplar()
        let d = try dizin()
        XCTAssertEqual(d.klasor, "ses/Fola")
        for h in try hikayeler() {
            let beklenen = try XCTUnwrap(c.hikayeler[h.id])
            let p = HikayeSesi.parcalar(h)
            XCTAssertEqual(p.filter { HikayeSesi.kayitli($0, dizin: d) }.count, beklenen.kayitli)
            XCTAssertEqual(HikayeSesi.sureler(p, dizin: d).reduce(0, +), beklenen.sure, accuracy: 0.05)
            // Dizin yoksa her parça telefonun sesine düşer: tahmini süre (Z4a'nın kuralı)
            let tahmin = HikayeSesi.sureler(p, dizin: nil)
            XCTAssertEqual(tahmin, p.map { DinlemeKurallari.okumaSuresi($0.metin) })
            XCTAssertFalse(p.contains { HikayeSesi.kayitli($0, dizin: nil) })
        }
        // Vermeer: 38 parça, 1581 sn → 26 dk dinleme; 3132 kelime → 20 dk okuma
        let v = try hikayeler()[0]
        XCTAssertEqual(HikayeAkisi.dakika(HikayeSesi.sureler(HikayeSesi.parcalar(v), dizin: d).reduce(0, +)), 26)
        XCTAssertEqual(HikayeAkisi.okumaDakikasi(kelime: v.kelime), 20)
        XCTAssertEqual(HikayeAkisi.okumaDakikasi(kelime: 0), 1)
    }

    func testAtlamaParcaSinirlariniAsar() {
        let s = [10.0, 20, 5]
        XCTAssertEqual(HikayeSesi.gecen(s, sira: 1, an: 4), 14)
        XCTAssertEqual(HikayeSesi.gecen(s, sira: 1, an: 99), 30)
        XCTAssertEqual(HikayeSesi.gecen([], sira: 0, an: 3), 0)
        XCTAssertTrue(HikayeSesi.yer(s, gecen: 0) == (0, 0))
        XCTAssertTrue(HikayeSesi.yer(s, gecen: 10) == (1, 0))
        XCTAssertTrue(HikayeSesi.yer(s, gecen: 33) == (2, 3))
        XCTAssertTrue(HikayeSesi.yer(s, gecen: 99) == (2, 5))
        // +15: 1. parçanın 4. sn'si (14) → 29 → 1. parçanın 19. sn'si
        XCTAssertTrue(HikayeSesi.atla(s, sira: 1, an: 4, fark: 15) == (1, 19))
        // +15 sondan taşar: son parçanın sonu
        XCTAssertTrue(HikayeSesi.atla(s, sira: 2, an: 1, fark: 15) == (2, 5))
        // −15 baştan taşar: en baş
        XCTAssertTrue(HikayeSesi.atla(s, sira: 0, an: 6, fark: -15) == (0, 0))
        // −15 önceki parçaya geçer
        // −15 önceki parçaya geçer: 32 → 17 → 1. parçanın 7. sn'si
        XCTAssertTrue(HikayeSesi.atla(s, sira: 2, an: 2, fark: -15) == (1, 7))
    }

    func testHizVeSaat() {
        XCTAssertEqual(HikayeSesi.sonrakiHiz(1), 1.25)
        XCTAssertEqual(HikayeSesi.sonrakiHiz(1.5), 0.85)
        XCTAssertEqual(HikayeSesi.sonrakiHiz(0.85), 1)
        XCTAssertEqual(HikayeSesi.sonrakiHiz(3), 1)
        XCTAssertEqual(HikayeSesi.hizYazisi(1), "1×")
        XCTAssertEqual(HikayeSesi.hizYazisi(1.25), "1,25×")
        XCTAssertEqual(HikayeSesi.hizYazisi(1.5), "1,5×")
        XCTAssertEqual(HikayeSesi.hizYazisi(0.85), "0,85×")
        XCTAssertEqual(HikayeSesi.saat(0), "0:00")
        XCTAssertEqual(HikayeSesi.saat(247.9), "4:07")
        XCTAssertEqual(HikayeSesi.saat(3725), "1:02:05")
    }

    // MARK: Ana ekran

    func testBaglantiliYazilar() throws {
        let l = try hikayeler()
        let ids = Set(l.map(\.id))
        // Rembrandt'ın bağlantılarından yalnız hikâyesi olan Van Gogh (örnekte Goya'nın hikâyesi yok)
        let r = try XCTUnwrap(l.first { $0.id == "rembrandt-van-rijn" })
        XCTAssertTrue(r.baglantilar.contains { $0.id == "francisco-de-goya" })
        XCTAssertEqual(HikayeAkisi.baglantilar(r, hikayeler: ids).map(\.id), ["vincent-van-gogh"])
        // id'siz bağlantı, kendisi ve tekrar kart olmaz; en çok 4
        let h = SanatciHikayesi(id: "a", baslik: "A", altBaslik: "", giris: ["x"], bolumler: [], kapanis: [],
                                baglantilar: [
                                    HikayeBaglantisi(sanatci: "Kendi", iliski: "", id: "a"),
                                    HikayeBaglantisi(sanatci: "Adsız", iliski: ""),
                                    HikayeBaglantisi(sanatci: "B", iliski: "", id: "b"),
                                    HikayeBaglantisi(sanatci: "Yok", iliski: "", id: "yok"),
                                    HikayeBaglantisi(sanatci: "B yine", iliski: "", id: "b"),
                                    HikayeBaglantisi(sanatci: "C", iliski: "", id: "c"),
                                    HikayeBaglantisi(sanatci: "D", iliski: "", id: "d"),
                                    HikayeBaglantisi(sanatci: "E", iliski: "", id: "e"),
                                    HikayeBaglantisi(sanatci: "F", iliski: "", id: "f"),
                                ])
        XCTAssertEqual(HikayeAkisi.baglantilar(h, hikayeler: ["a", "b", "c", "d", "e", "f"]).map(\.id), ["b", "c", "d", "e"])
        XCTAssertEqual(HikayeAkisi.baglantilar(h, hikayeler: []).count, 0)
    }

    func testSiralamaYarimKalanUstte() throws {
        let l = try hikayeler()
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(HikayeAkisi.sirala(l, yerler: [:]).map(\.id), l.map(\.id))
        let yerler: [String: OkumaYeri] = [
            "vincent-van-gogh": OkumaYeri(paragraf: 0, toplam: 30, tarih: t0),                   // başlanmamış
            "rembrandt-van-rijn": OkumaYeri(paragraf: 5, toplam: 30, tarih: t0),
            "johannes-vermeer": OkumaYeri(paragraf: 30, toplam: 30, bitti: true, tarih: t0.addingTimeInterval(60)),
        ]
        XCTAssertEqual(HikayeAkisi.sirala(l, yerler: yerler).map(\.id),
                       ["rembrandt-van-rijn", "johannes-vermeer", "vincent-van-gogh"])
        var y2 = yerler
        y2["vincent-van-gogh"] = OkumaYeri(paragraf: 0, toplam: 30, parca: 3, an: 2, tarih: t0.addingTimeInterval(9))
        XCTAssertEqual(HikayeAkisi.sirala(l, yerler: y2).map(\.id),
                       ["vincent-van-gogh", "rembrandt-van-rijn", "johannes-vermeer"])
    }

    func testDurumVeKalan() throws {
        let v = try hikayeler()[0]
        let gun = { (s: String) -> Date in
            var c = DateComponents(); c.year = Int(s.prefix(4)); c.month = Int(s.dropFirst(5).prefix(2)); c.day = Int(s.suffix(2)); c.hour = 12
            c.timeZone = TimeZone(identifier: "Europe/Istanbul")
            return Calendar(identifier: .gregorian).date(from: c)!
        }
        XCTAssertEqual(v.olusturma, "2026-11-26")
        XCTAssertEqual(HikayeAkisi.durum(v, yer: nil, bugun: gun("2026-11-26")), .yeni)
        XCTAssertEqual(HikayeAkisi.durum(v, yer: nil, bugun: gun("2026-12-02")), .yeni)
        XCTAssertEqual(HikayeAkisi.durum(v, yer: nil, bugun: gun("2026-12-04")), .yok)
        let ok = HikayeAkisi.okumaDakikasi(kelime: v.kelime)   // 20
        let yarim = OkumaYeri(paragraf: 10, toplam: 40)
        XCTAssertEqual(HikayeAkisi.durum(v, yer: yarim, bugun: gun("2026-11-26")), .yarim(kalanDk: 15))
        XCTAssertEqual(HikayeAkisi.kalanDakika(okuma: ok, yer: OkumaYeri(paragraf: 40, toplam: 40)), 1)
        XCTAssertEqual(HikayeAkisi.durum(v, yer: OkumaYeri(paragraf: 40, toplam: 40, bitti: true), bugun: gun("2026-11-26")), .okundu)
        XCTAssertEqual(yarim.oran, 0.25)
        XCTAssertFalse(HikayeAkisi.yeniMi("bozuk", bugun: Date()))
    }

    func testArama() throws {
        let l = try hikayeler()
        let ad: (String) -> String = {
            ["johannes-vermeer": "Johannes Vermeer", "vincent-van-gogh": "Vincent van Gogh",
             "rembrandt-van-rijn": "Rembrandt van Rijn"][$0] ?? $0
        }
        XCTAssertEqual(HikayeAkisi.ara(l, sorgu: "", sanatciAdi: ad).count, 3)
        XCTAssertEqual(HikayeAkisi.ara(l, sorgu: "  GOGH ", sanatciAdi: ad).map(\.id), ["vincent-van-gogh"])
        XCTAssertEqual(HikayeAkisi.ara(l, sorgu: "van ", sanatciAdi: ad).map(\.id), ["vincent-van-gogh", "rembrandt-van-rijn"])
        // Başlıkta, Türkçe harfler aksan duyarsız: "Gürültülü" ← "gurultu", "Sessizlik" ← "SESSİZ"
        XCTAssertEqual(HikayeAkisi.ara(l, sorgu: "gurultu", sanatciAdi: ad).map(\.id), ["johannes-vermeer"])
        XCTAssertEqual(HikayeAkisi.ara(l, sorgu: "SESSİZ", sanatciAdi: ad).map(\.id), ["johannes-vermeer"])
        XCTAssertEqual(HikayeAkisi.ara(l, sorgu: "zzz", sanatciAdi: ad).count, 0)
        XCTAssertEqual(HikayeAkisi.alanAdi("https://www.nga.gov/x/y.pdf"), "nga.gov")
        // Kaynaklar: aynı alan adı bir kez, ilk geçtiği yerde ve ilk adresiyle; sıra korunur
        let v = l[0]
        let k = HikayeAkisi.kaynaklar(v)
        XCTAssertLessThan(k.count, v.kaynaklar.count)
        XCTAssertEqual(Set(k.map(\.baslik)).count, k.count)
        var sira: [String] = []
        for x in v.kaynaklar where !sira.contains(x.baslik) { sira.append(x.baslik) }
        XCTAssertEqual(k.map(\.baslik), sira)
        let ev = try XCTUnwrap(k.first { $0.baslik == "essentialvermeer.com" })
        XCTAssertEqual(ev.adres, v.kaynaklar.first { $0.baslik == "essentialvermeer.com" }?.adres)
        XCTAssertEqual(HikayeAkisi.alanAdi("https://tour.milan.it/a"), "tour.milan.it")
    }

    func testOkumaYeri() {
        let t = Date(timeIntervalSince1970: 1_800_000_000)
        var y = HikayeAkisi.ilerle(nil, paragraf: 3, toplam: 40, sonda: false, tarih: t)
        XCTAssertEqual(y, OkumaYeri(paragraf: 3, toplam: 40, tarih: t))
        XCTAssertTrue(y.yarim)
        // Geri kaydırma yeri geri almaz
        y = HikayeAkisi.ilerle(y, paragraf: 1, toplam: 40, sonda: false, tarih: t.addingTimeInterval(5))
        XCTAssertEqual(y.paragraf, 3)
        XCTAssertEqual(y.tarih, t)
        y = HikayeAkisi.ilerle(y, paragraf: 12, toplam: 40, sonda: false, tarih: t.addingTimeInterval(6))
        XCTAssertEqual(y.paragraf, 12)
        // Yazı değişti (paragraf sayısı): yer yeni yazıya göre
        let z = HikayeAkisi.ilerle(y, paragraf: 2, toplam: 30, sonda: false, tarih: t)
        XCTAssertEqual(z.paragraf, 2)
        XCTAssertEqual(z.toplam, 30)
        // Sona gelindi
        y = HikayeAkisi.ilerle(y, paragraf: 39, toplam: 40, sonda: true, tarih: t)
        XCTAssertTrue(y.bitti)
        XCTAssertFalse(y.yarim)
        XCTAssertEqual(y.oran, 1)
        // Dinleme yeri
        var d = HikayeAkisi.dinlendi(nil, parca: 7, an: 3.5, paragraf: 5, toplam: 40, tarih: t)
        XCTAssertEqual(d.parca, 7)
        XCTAssertEqual(d.an, 3.5)
        XCTAssertEqual(d.paragraf, 5)
        // Başlık okunurken (paragraf yok) paragraf yerinde kalır
        d = HikayeAkisi.dinlendi(d, parca: 8, an: 0, paragraf: nil, toplam: 40, tarih: t)
        XCTAssertEqual(d.paragraf, 5)
        XCTAssertEqual(d.parca, 8)
        d = HikayeAkisi.dinlendi(d, parca: 40, an: 9, paragraf: 39, toplam: 40, bitti: true, tarih: t)
        XCTAssertTrue(d.bitti)
        XCTAssertNil(d.parca)
        // Saklanır (Codable)
        let geri = try? JSONDecoder().decode(OkumaYeri.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(geri, d)
    }
}

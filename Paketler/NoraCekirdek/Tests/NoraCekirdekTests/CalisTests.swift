// C2 kâhin testleri: Çalış ana ekranı, Turlar / Döneme göre ekranı, ders planı, harita bölümleri,
// soru turları, 14 günlük yük grafiği ve deste/eğim fiziği kuralları (`Testler/kahin/calis.mjs`).
// Kaynak: sanat-atlasi js/ders.js, js/dersIcerik.js, js/bolum.js, js/oturum.js, js/soruTurlari.js,
// js/ikonografi.js, js/gecmis.js, js/deste.js, js/sallanma.js, js/egim.js,
// js/ekranlar/{ders,pekistir,soruTurlari,gozat,calisma,bugun}.js @ a866b86
import XCTest
@testable import NoraCekirdek

final class CalisTests: XCTestCase {
    struct Cevaplar: Decodable {
        struct Bulunma: Decodable {
            let n: Int
            let ek: String
            let konum: String
        }
        struct DersPlan: Decodable {
            struct GorEser: Decodable {
                let sanatci: String
                let eser: String
                let noktaSayisi: Int
            }
            struct OgrenMadde: Decodable {
                let no: Int
                let madde: String
                let kanitlar: [String]
                let aciklamalar: [String]
            }
            let akim: String
            let adimlar: [String]
            let gorEserler: [GorEser]
            let gorToplam: Int
            let ogrenSayisi: Int
            let ogrenMaddeler: [OgrenMadde]
            let ayirtKomsu: [String]
            let kapakAnahtar: String?
        }
        struct Senaryo: Decodable {
            struct KilitliDers: Decodable {
                let ad: String
                let acilacagiKonu: Int?
            }
            struct AcikDers: Decodable {
                let akim: String
                let hal: String
                let kunye: String
                let siradaki: String?
                let bitti: Bool
                let davetMetni: String
                let devamBaslik: String
                let devamAlt: String
                let haritaDurak: Int
                let haritaKilit: String
            }
            struct HatalarC: Decodable {
                let idler: [String]
                let hatalilar: [String]
                let alt: String
                let ikiliYazi: String
            }
            struct SalonC: Decodable {
                let ad: String
                let acikSayisi: Int
                let temsilciId: String?
                let seviyeRozeti: String
                let turYazisi: String
                let dogru: Int
                let toplam: Int
                let vade: Int
                let oranYuzde: Int?
            }
            let ad: String
            let yolculukAkimi: String?
            let bugunku: String?
            let kilitliDersAkimlari: [KilitliDers]
            let acikDersler: [AcikDers]
            let karisikTur: TurOzeti
            let karisikAlt: String
            let sahneDestesi: [String]
            let hatalar: HatalarC
            let bolumTuruSayisi: Int
            let karsSecim: KarsilastirSecimi?
            let hepsiMozaik: [String]
            let salonSiralamalari: [String: [SalonC]]
            let gunlukYuk: [Int]
            let yukYazi: String
        }
        struct KursBolumuC: Decodable {
            let id: String
            let no: Int
            let ad: String
            let kisaAd: String
            let konular: [Int]
            let yuzyilAraligi: String
        }
        struct IkonoC: Decodable {
            let id: String
            let ad: String
            let tur: String
            let turAdi: String
            let ozet: String
            let kaynak: String
            let hikayeSayisi: Int
            let eserSayisi: Int
        }
        struct YelpazeC: Decodable {
            let x: Double
            let hedef: YelpazeHedefi
        }
        struct SarkacC: Decodable {
            let acilim: SarkacDurumu
            let yatma: SarkacDurumu
            let durgun: Bool
        }
        struct EgimIzC: Decodable {
            let donus: EgimNoktasi
            let egim: EgimDegeri
        }
        struct AciOrnekC: Decodable {
            struct Acilar: Decodable { let on: Double; let yan: Double }
            let b: Double
            let g: Double
            let acilar: Acilar
            let hesap: EgimDegeri
        }

        let bugun: String
        let bulunmaSonuclari: [Bulunma]
        let dersPlanlari: [DersPlan]
        let tumBolumler: [HaritaBolumu]
        let senaryolar: [Senaryo]
        let kursBolumleriSonuc: [KursBolumuC]
        let ikonoToplam: Int
        let ikonoSonuc: [IkonoC]
        let yelpazeSonuclari: [YelpazeC]
        let sarkacIzleri: [SarkacC]
        let egimIzleri: [EgimIzC]
        let aciOrnekleri: [AciOrnekC]
    }

    static func dosya(_ yol: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/\(yol)", withExtension: nil))
        return try Data(contentsOf: url)
    }

    func yukle() throws -> (Cevaplar, JSONDeger, SiteKatalogu, JSONDeger, JSONDeger) {
        let (_, k) = try XCTUnwrap(SiteVerisiTests.hazir, "katalog örnekleri okunamadı")
        let cevapData = try Self.dosya("calis/cevaplar.json")
        let cevaplar = try JSONDecoder().decode(Cevaplar.self, from: cevapData)
        let hamCevap = try JSONDeger.coz(cevapData)
        let dersKaynagi = try JSONDeger.coz(Self.dosya("calis/ders_kaynaklari.json"))
        let yuruyus = try JSONDeger.coz(Self.dosya("site_verisi/yuruyus.json"))
        return (cevaplar, hamCevap, k, dersKaynagi, yuruyus)
    }

    func testBulunmaEkiVeKonumYazisi() throws {
        let (c, _, _, _, _) = try yukle()
        for b in c.bulunmaSonuclari {
            XCTAssertEqual(CalisKurallari.bulunmaEki(b.n), b.ek, "n=\(b.n)")
            XCTAssertEqual(CalisKurallari.konumYazisi(islenen: [b.n]), b.konum, "n=\(b.n)")
        }
        XCTAssertEqual(CalisKurallari.konumYazisi(islenen: []), "")
    }

    func testDersPlanlariVeHaritaBolumleri() throws {
        let (c, _, k, dersKaynagi, yuruyus) = try yukle()
        let bolumler = CalisDersKurallari.bolumleriKur(akimlar: k.akimlar, sanatcilar: k.sanatcilar)
        XCTAssertEqual(bolumler, c.tumBolumler)

        var il = try Ilerleme(veri: Data("{}".utf8))
        il.islenen = k.konular.map(\.no)
        let gorunur = Set(k.akimlar.map(\.ad))
        func maddeler(_ ad: String) -> [String] {
            (CalisDersKurallari.dersBul(kaynak: dersKaynagi, akim: ad)?["ogren"]?.dizi ?? []).compactMap { $0["madde"]?.metin }
        }

        XCTAssertEqual(c.dersPlanlari.count, 28)
        for dp in c.dersPlanlari {
            let ders = try XCTUnwrap(CalisDersKurallari.dersBul(kaynak: dersKaynagi, akim: dp.akim), dp.akim)
            let adimlar = CalisDersKurallari.dersAdimlari(ders: ders, yuruyus: yuruyus)
            XCTAssertEqual(adimlar.map(\.rawValue), dp.adimlar, dp.akim)

            let gor = CalisDersKurallari.gorPlani(ders: ders, yuruyus: yuruyus)
            XCTAssertEqual(gor.toplam, dp.gorToplam, dp.akim)
            XCTAssertEqual(gor.eserler.map(\.sanatci), dp.gorEserler.map(\.sanatci), dp.akim)
            XCTAssertEqual(gor.eserler.map(\.eser), dp.gorEserler.map(\.eser), dp.akim)
            XCTAssertEqual(gor.eserler.map(\.noktaSayisi), dp.gorEserler.map(\.noktaSayisi), dp.akim)

            let ogren = CalisDersKurallari.ogrenPlani(ders: ders)
            XCTAssertEqual(ogren.count, dp.ogrenSayisi, dp.akim)
            for (m, bm) in zip(ogren, dp.ogrenMaddeler) {
                XCTAssertEqual(m.no, bm.no, dp.akim)
                XCTAssertEqual(m.madde, bm.madde, dp.akim)
                XCTAssertEqual(m.kanitlar.map(\.id), bm.kanitlar, dp.akim)
                XCTAssertEqual(m.aciklamalar.map(\.id), bm.aciklamalar, dp.akim)
            }

            let ayirt = CalisDersKurallari.ayirtPlani(ders: ders, gorunur: gorunur, acik: gorunur, maddeler: maddeler)
            XCTAssertEqual(ayirt.map(\.komsu), dp.ayirtKomsu, dp.akim)

            let b = try XCTUnwrap(CalisDersKurallari.dersBilgisi(
                kaynak: dersKaynagi, yuruyus: yuruyus, katalog: k, ilerleme: il, akim: dp.akim
            ), dp.akim)
            if let beklenenKapak = dp.kapakAnahtar {
                XCTAssertEqual(CalisDersKurallari.dersKapakEseri(b, katalog: k)?.anahtar, beklenenKapak, dp.akim)
            }
        }
    }

    func testSenaryolarCanliSiteyleAyni() throws {
        let (c, ham, k, dersKaynagi, yuruyus) = try yukle()
        let hamSenaryolar = try XCTUnwrap(ham["senaryolar"]?.dizi)
        XCTAssertEqual(c.senaryolar.count, 3)

        for (i, s) in c.senaryolar.enumerated() {
            let yer = s.ad
            let ilJson = try XCTUnwrap(hamSenaryolar[i]["il"])
            let il = try Ilerleme(json: ilJson)

            // 1) yolculukAkimi ve bugununDersi
            let yolculuk = CalisDersKurallari.yolculukAkimi(katalog: k, ilerleme: il, kaynak: dersKaynagi, yuruyus: yuruyus)
            XCTAssertEqual(yolculuk, s.yolculukAkimi, "\(yer): yolculukAkimi")

            let akimlar = Kilit.akimDurumlari(k.akimlar, k.sanatcilar, islenen: il.islenenKume)
            let sirali = akimlar.filter { CalisDersKurallari.dersBul(kaynak: dersKaynagi, akim: $0.ad) != nil }
            let aciklar = sirali.filter(\.acik).compactMap {
                CalisDersKurallari.dersBilgisi(kaynak: dersKaynagi, yuruyus: yuruyus, katalog: k, ilerleme: il, akim: $0.ad)
            }
            let kilitliler = sirali.filter { !$0.acik }

            XCTAssertEqual(kilitliler.map(\.ad), s.kilitliDersAkimlari.map(\.ad), "\(yer): kilitli dersler")
            XCTAssertEqual(kilitliler.map(\.acilacagiKonu), s.kilitliDersAkimlari.map(\.acilacagiKonu), "\(yer): kilitli konu")

            let bugunku = CalisDersKurallari.bugununDersi(
                acikAkimlar: aciklar.map(\.akim),
                ilerleme: il,
                yolculukAkimi: yolculuk,
                adimlar: { ad in aciklar.first { $0.akim == ad }?.adimlar ?? DersAdimi.allCases }
            )
            XCTAssertEqual(bugunku, s.bugunku, "\(yer): bugununDersi")

            // 2) Açık derslerin tüm metinleri
            XCTAssertEqual(aciklar.count, s.acikDersler.count, "\(yer): açık ders sayısı")
            for (b, bd) in zip(aciklar, s.acikDersler) {
                let dYer = "\(yer) · \(b.akim)"
                XCTAssertEqual(b.akim, bd.akim, dYer)
                XCTAssertEqual(b.hal.rawValue, bd.hal, dYer)
                XCTAssertEqual(CalisDersKurallari.dersKunyesi(b), bd.kunye, dYer)
                XCTAssertEqual(b.durum.siradaki?.rawValue, bd.siradaki, dYer)
                XCTAssertEqual(b.durum.bitti, bd.bitti, dYer)
                let hb = CalisDersKurallari.haritaBilgisi(b, katalog: k, ilerleme: il, kaynak: dersKaynagi, yuruyus: yuruyus)
                XCTAssertEqual(hb.durak, bd.haritaDurak, dYer)
                XCTAssertEqual(hb.kilit, bd.haritaKilit, dYer)
                XCTAssertEqual(CalisDersKurallari.davet(b, harita: hb).duz, bd.davetMetni, dYer)
                let dv = CalisDersKurallari.devamDugmesi(b, sahne: true)
                XCTAssertEqual(dv.baslik, bd.devamBaslik, dYer)
                XCTAssertEqual(dv.alt, bd.devamAlt, dYer)
            }

            // 3) Karışık tur, sahne destesi, Hatalarım, Bölüm turu, Karşılaştır
            let karisik = CalisKurallari.turBilgisi(sanatcilar: k.sanatcilar, ilerleme: il, bugun: c.bugun, karisik: true)
            XCTAssertEqual(karisik, s.karisikTur, "\(yer): karisikTur")
            XCTAssertEqual(CalisKurallari.turAltYazisi(karisik), s.karisikAlt, "\(yer): karisikAlt")

            let deste = CalisKurallari.sahneDestesi(sanatcilar: k.sanatcilar, ilerleme: il, bugun: c.bugun).map(\.id)
            XCTAssertEqual(deste, s.sahneDestesi, "\(yer): sahneDestesi")

            let hatalar = CalisKurallari.hatalarBilgisi(sanatcilar: k.sanatcilar, ilerleme: il, bugun: c.bugun)
            XCTAssertEqual(hatalar.idler, s.hatalar.idler, "\(yer): hatalar.idler")
            XCTAssertEqual(hatalar.hatalilar, s.hatalar.hatalilar, "\(yer): hatalar.hatalilar")
            XCTAssertEqual(hatalar.altYazi, s.hatalar.alt, "\(yer): hatalar.alt")
            XCTAssertEqual(hatalar.ikiliYazisi(k), s.hatalar.ikiliYazi, "\(yer): hatalar.ikiliYazi")

            XCTAssertEqual(CalisKurallari.bolumTuruKartSayisi(katalog: k, ilerleme: il), s.bolumTuruSayisi, "\(yer): bolumTuruSayisi")
            XCTAssertEqual(CalisKurallari.karsilastirSecimi(katalog: k, ilerleme: il), s.karsSecim, "\(yer): karsSecim")

            // 4) Dönem salonları ve Hepsi mozaiği
            let acikSan = il.acikSanatcilar(k.sanatcilar)
            XCTAssertEqual(CalisKurallari.hepsiMozaikSanatcilari(acik: acikSan).map(\.id), s.hepsiMozaik, "\(yer): hepsiMozaik")

            for sira in DonemSiralamasi.allCases {
                let salonlar = CalisKurallari.donemSalonlari(katalog: k, ilerleme: il, bugun: c.bugun, siralama: sira)
                let beklenen = try XCTUnwrap(s.salonSiralamalari[sira.rawValue], "\(yer): \(sira.rawValue)")
                XCTAssertEqual(salonlar.map(\.ad), beklenen.map(\.ad), "\(yer) \(sira.rawValue): sıra")
                for (sl, bsl) in zip(salonlar, beklenen) {
                    let sYer = "\(yer) \(sira.rawValue) \(sl.ad)"
                    XCTAssertEqual(sl.acikSayisi, bsl.acikSayisi, sYer)
                    XCTAssertEqual(sl.temsilciId, bsl.temsilciId, sYer)
                    XCTAssertEqual(sl.seviyeRozeti, bsl.seviyeRozeti, sYer)
                    XCTAssertEqual(sl.turYazisi, bsl.turYazisi, sYer)
                    XCTAssertEqual(sl.dogru, bsl.dogru, sYer)
                    XCTAssertEqual(sl.toplam, bsl.toplam, sYer)
                    XCTAssertEqual(sl.vade, bsl.vade, sYer)
                    XCTAssertEqual(sl.oranYuzde, bsl.oranYuzde, sYer)
                }
            }

            // 5) 14 günlük gelecek yük
            let yuk = CalisKurallari.gelecekYukOzeti(skorlar: il.skorlar, idler: acikSan.map(\.id), bugun: c.bugun)
            XCTAssertEqual(yuk.gunluk, s.gunlukYuk, "\(yer): gunlukYuk")
            XCTAssertEqual(yuk.yazi, s.yukYazi, "\(yer): yukYazi")
        }
    }

    func testKursBolumleriVeIkonografi() throws {
        let (c, _, k, _, _) = try yukle()
        let bolumler = CalisKurallari.kursBolumleri(konular: k.konular)
        XCTAssertEqual(bolumler.count, c.kursBolumleriSonuc.count)
        for (b, cb) in zip(bolumler, c.kursBolumleriSonuc) {
            XCTAssertEqual(b.id, cb.id)
            XCTAssertEqual(b.no, cb.no)
            XCTAssertEqual(b.ad, cb.ad)
            XCTAssertEqual(b.kisaAd, cb.kisaAd)
            XCTAssertEqual(b.konular, cb.konular)
            let aralik = CalisKurallari.yuzyilAraligi(konular: b.konular, sanatcilar: k.sanatcilar)
            XCTAssertEqual(aralik, cb.yuzyilAraligi, b.id)
        }

        let ikonoData = try Self.dosya("goruntuleyici/ikonografi.json")
        let ikono = CalisKurallari.ikonografiKonulari(ikonoData, varMi: { k.harita[$0] != nil })
        XCTAssertEqual(ikono.count, c.ikonoToplam)
        for (ik, cik) in zip(ikono.prefix(15), c.ikonoSonuc) {
            XCTAssertEqual(ik.id, cik.id)
            XCTAssertEqual(ik.ad, cik.ad)
            XCTAssertEqual(ik.tur, cik.tur)
            XCTAssertEqual(ik.turAdi, cik.turAdi)
            XCTAssertEqual(ik.ozet, cik.ozet)
            XCTAssertEqual(ik.kaynak, cik.kaynak)
            XCTAssertEqual(ik.hikaye.count, cik.hikayeSayisi)
            XCTAssertEqual(ik.eserler.count, cik.eserSayisi)
        }
    }

    func testDesteVeEgimFizigi() throws {
        let (c, _, _, _, _) = try yukle()
        for y in c.yelpazeSonuclari {
            let h = DesteFizigi.yelpazeHedefi(y.x)
            XCTAssertEqual(h.acilim, y.hedef.acilim, accuracy: 1e-9)
            XCTAssertEqual(h.yatma, y.hedef.yatma, accuracy: 1e-9)
        }

        var acilim = SarkacDurumu()
        var yatma = SarkacDurumu()
        let h = DesteFizigi.yelpazeHedefi(0.75)
        for (i, iz) in c.sarkacIzleri.enumerated() {
            acilim = DesteFizigi.sarkacAdim(acilim, hedef: h.acilim, dt: 0.016)
            yatma = DesteFizigi.sarkacAdim(yatma, hedef: h.yatma, dt: 0.016)
            XCTAssertEqual(acilim.aci, iz.acilim.aci, accuracy: 1e-9, "adım \(i)")
            XCTAssertEqual(acilim.hiz, iz.acilim.hiz, accuracy: 1e-9, "adım \(i)")
            XCTAssertEqual(yatma.aci, iz.yatma.aci, accuracy: 1e-9, "adım \(i)")
            XCTAssertEqual(yatma.hiz, iz.yatma.hiz, accuracy: 1e-9, "adım \(i)")
            let durgun = DesteFizigi.durgunMu(acilim, hedef: h.acilim) && DesteFizigi.durgunMu(yatma, hedef: h.yatma)
            XCTAssertEqual(durgun, iz.durgun, "adım \(i)")
        }

        var donus = EgimNoktasi()
        let adimlar: [(Double, Double, Double)] = [
            (15, -30, 0.02),
            (10, -25, 0.02),
            (-5, 40, 0.03),
            (0, 0, 0.5),
        ]
        for (girdi, beklenen) in zip(adimlar, c.egimIzleri) {
            donus = DesteFizigi.donusIzle(donus, hizBeta: girdi.0, hizGamma: girdi.1, dt: girdi.2)
            let egim = DesteFizigi.donustenEgim(donus)
            XCTAssertEqual(donus.x, beklenen.donus.x, accuracy: 1e-9)
            XCTAssertEqual(donus.y, beklenen.donus.y, accuracy: 1e-9)
            XCTAssertEqual(egim.x, beklenen.egim.x, accuracy: 1e-9)
            XCTAssertEqual(egim.y, beklenen.egim.y, accuracy: 1e-9)
            XCTAssertEqual(egim.eksen, beklenen.egim.eksen)
        }

        for o in c.aciOrnekleri {
            let acilar = DesteFizigi.egimAcilari(beta: o.b, gamma: o.g)
            XCTAssertEqual(acilar.on, o.acilar.on, accuracy: 1e-9)
            XCTAssertEqual(acilar.yan, o.acilar.yan, accuracy: 1e-9)
            let hesap = DesteFizigi.egimHesapla(beta: o.b, gamma: o.g, tabanBeta: 40, tabanGamma: 0)
            XCTAssertEqual(hesap.x, o.hesap.x, accuracy: 1e-9)
            XCTAssertEqual(hesap.y, o.hesap.y, accuracy: 1e-9)
            XCTAssertEqual(hesap.eksen, o.hesap.eksen)
        }
    }

    func testDersAdimIslemeVeDogrulama() throws {
        var il = try Ilerleme(veri: Data("{}".utf8))
        let r1 = CalisDersKurallari.adimIsle(ilerleme: &il, akim: "Gotik", adim: .gor, oran: 0.4, bugun: "2026-11-21")
        XCTAssertFalse(r1.bitti)
        XCTAssertFalse(r1.yeniBitti)
        XCTAssertEqual(r1.sonra.gor.i, 0.4)
        XCTAssertNil(r1.sonra.gor.t)

        // Oran hiç düşmez
        let r2 = CalisDersKurallari.adimIsle(ilerleme: &il, akim: "Gotik", adim: .gor, oran: 0.2, bugun: "2026-11-21")
        XCTAssertEqual(r2.sonra.gor.i, 0.4)

        // Tamamlanma
        let r3 = CalisDersKurallari.adimIsle(ilerleme: &il, akim: "Gotik", adim: .gor, oran: 1.0, bugun: "2026-11-21")
        XCTAssertTrue(r3.bitti)
        XCTAssertTrue(r3.yeniBitti)
        XCTAssertEqual(r3.sonra.gor.t, "2026-11-21")

        // Birleşen akım doğrulaması (Uluslararası Gotik → Gotik)
        let bozuk = try JSONDeger.coz(Data(#"{"Uluslararası Gotik":{"gor":{"i":0.8},"ogren":{"i":1,"t":"2026-11-10"}},"Gotik":{"gor":{"i":0.5},"ogren":{"i":1,"t":"2026-11-15"}}}"#.utf8))
        let dogrulanan = CalisDersKurallari.derslerDogrula(bozuk)
        XCTAssertEqual(dogrulanan["Gotik"]?.gor.i, 0.8)
        XCTAssertEqual(dogrulanan["Gotik"]?.ogren.t, "2026-11-10")
    }
}

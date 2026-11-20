import Foundation
import XCTest
@testable import NoraCekirdek

/// G1 kâhini: görüntüleyici kuralları (`js/goruntuleyici.js`, `js/ayrinti.js`, `js/hikaye.js`, `js/koleksiyon.js`,
/// `js/bildirim.js`, `js/karsilastir.js`, `js/keskin.js`, `js/ikonografi.js`) canlı siteden alınan beklenen değerlerle sınanır.
final class GoruntuleyiciTests: XCTestCase {
    static func goruntuleyiciDosya(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/goruntuleyici/\(ad)", withExtension: nil))
        return try Data(contentsOf: url)
    }

    static func siteVerisiDosya(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/site_verisi/\(ad)", withExtension: nil))
        return try Data(contentsOf: url)
    }

    static let hazir: (cevaplar: JSONDeger, katalog: SiteKatalogu, baglam: GoruntuleyiciBaglami)? = {
        guard let cVeri = try? goruntuleyiciDosya("cevaplar.json"),
              let c = try? JSONDeger.coz(cVeri) else { return nil }
        var d: [String: Data] = [:]
        for f in SiteVerisi.katalogDosyalari { d[f] = try? siteVerisiDosya(f) }
        guard let k = try? SiteKatalogu(dosyalar: d) else { return nil }

        let notlar = (try? goruntuleyiciDosya("eser_notlari.json")).map(GoruntuleyiciKurallari.notlariAl(veri:)) ?? [:]
        let ayr = (try? goruntuleyiciDosya("eser_ayrintilari.json")).map(AyrintiKurallari.ayrintilariAl(veri:)) ?? []
        let hik = (try? goruntuleyiciDosya("eser_hikayeleri.json")).map(HikayeKurallari.hikayeleriAl(veri:)) ?? []
        let sanatciSet = Set(k.sanatcilar.map(\.id))
        let ikono: [String: IkonografiKonuOzeti]
        if let ikonoVeri = try? goruntuleyiciDosya("ikonografi.json"),
           let ikonoJson = try? JSONDeger.coz(ikonoVeri) {
            ikono = GoruntuleyiciKurallari.ikonografiKonuHaritasi(ikonoJson) { sanatciSet.contains($0) }
        } else {
            ikono = [:]
        }
        let baglam = GoruntuleyiciBaglami(
            katalog: k,
            gorselAdresleri: k.gorsel,
            eserNotlari: notlar,
            ayrintilar: ayr,
            hikayeler: hik,
            ikonografiKonulari: ikono
        )
        return (c, k, baglam)
    }()

    func hazirla() throws -> (cevaplar: JSONDeger, katalog: SiteKatalogu, baglam: GoruntuleyiciBaglami) {
        try XCTUnwrap(Self.hazir, "goruntuleyici örnekleri okunamadı")
    }

    // MARK: - Ayrıntılar (js/ayrinti.js)

    func testAyrintilarVeNoktaOdagi() throws {
        let (c, _, baglam) = try hazirla()
        let vakalar = try XCTUnwrap(c["ayrintiVakalar"]?.dizi)
        let sahneler = try XCTUnwrap(c["sahneler"]?.dizi)
        XCTAssertEqual(baglam.ayrintilar.count, vakalar.count)
        XCTAssertGreaterThan(vakalar.count, 20)

        for (kayit, beklenen) in zip(baglam.ayrintilar, vakalar) {
            XCTAssertEqual(kayit.anahtar, beklenen["anahtar"]?.metin)
            XCTAssertEqual(kayit.sanatci, beklenen["sanatci"]?.metin)
            XCTAssertEqual(kayit.baslik, beklenen["baslik"]?.metin)
            XCTAssertEqual(kayit.gorsel, beklenen["gorsel"]?.metin)

            let bNoktalar = try XCTUnwrap(beklenen["noktalar"]?.dizi)
            XCTAssertEqual(kayit.noktalar.count, bNoktalar.count, kayit.anahtar)

            for (n, bn) in zip(kayit.noktalar, bNoktalar) {
                let yer = n.yerYuzdesi
                XCTAssertEqual(yer.x, bn["yeri"]?["x"]?.sayi ?? -1, accuracy: 1e-6, "\(kayit.anahtar) \(n.ad)")
                XCTAssertEqual(yer.y, bn["yeri"]?["y"]?.sayi ?? -1, accuracy: 1e-6, "\(kayit.anahtar) \(n.ad)")

                let bOdaklar = try XCTUnwrap(bn["odaklar"]?.dizi)
                for (s, bo) in zip(sahneler, bOdaklar) {
                    let tw = s["taban"]!["w"]!.sayi!
                    let th = s["taban"]!["h"]!.sayi!
                    let sw = s["sahne"]!["w"]!.sayi!
                    let sh = s["sahne"]!["h"]!.sayi!
                    let enCok = s["enCok"]!.sayi!
                    let odak = try XCTUnwrap(
                        AyrintiKurallari.noktaOdagi(n, taban: (tw, th), sahne: (sw, sh), enCok: enCok)
                    )
                    XCTAssertEqual(odak.olcek, bo["olcek"]?.sayi ?? -1, accuracy: 1e-6, "\(kayit.anahtar) \(n.ad)")
                    XCTAssertEqual(odak.tx, bo["tx"]?.sayi ?? -9999, accuracy: 1e-6, "\(kayit.anahtar) \(n.ad)")
                    XCTAssertEqual(odak.ty, bo["ty"]?.sayi ?? -9999, accuracy: 1e-6, "\(kayit.anahtar) \(n.ad)")
                }
            }
        }
    }

    func testYakinlasmaSiniriVeGecerlilik() throws {
        let (c, _, _) = try hazirla()
        let sinirlar = try XCTUnwrap(c["yakinlasmaSinirlari"]?.dizi)
        for v in sinirlar {
            let kaynak = v["kaynak"]!.sayi!
            let taban = v["taban"]!.sayi!
            let dpr = v["dpr"]!.sayi!
            let beklenen = v["sinir"]!.sayi!
            XCTAssertEqual(
                AyrintiKurallari.yakinlasmaSiniri(kaynak: kaynak, taban: taban, dpr: dpr),
                beklenen,
                accuracy: 1e-6
            )
        }

        // Geçersiz noktalar reddedilmeli
        XCTAssertTrue(AyrintiKurallari.noktaGecerliMi(AyrintiNoktasi(ad: "Ayna", x: 0.4, y: 0.2, w: 0.2, h: 0.2, metin: "Açıklama.")))
        XCTAssertFalse(AyrintiKurallari.noktaGecerliMi(AyrintiNoktasi(ad: "Ayna", x: 0.9, y: 0.2, w: 0.2, h: 0.2, metin: "Taşar.")))
        XCTAssertFalse(AyrintiKurallari.noktaGecerliMi(AyrintiNoktasi(ad: "Ayna", x: 0.1, y: 0.2, w: 0.01, h: 0.2, metin: "Çok küçük.")))
        XCTAssertFalse(AyrintiKurallari.noktaGecerliMi(AyrintiNoktasi(ad: "", x: 0.1, y: 0.2, w: 0.2, h: 0.2, metin: "Adsız.")))
    }

    // MARK: - Hikâyeler (js/hikaye.js)

    func testHikayelerVeKarakterKaydi() throws {
        let (c, _, baglam) = try hazirla()
        let vakalar = try XCTUnwrap(c["hikayeVakalar"]?.dizi)
        XCTAssertEqual(baglam.hikayeler.count, vakalar.count)
        XCTAssertGreaterThanOrEqual(vakalar.count, 5)

        for (h, bh) in zip(baglam.hikayeler, vakalar) {
            let k = try XCTUnwrap(bh["kayit"])
            XCTAssertEqual(h.anahtar, k["anahtar"]?.metin)
            XCTAssertEqual(h.sanatci, k["sanatci"]?.metin)
            XCTAssertEqual(h.baslik, k["baslik"]?.metin)
            XCTAssertEqual(h.olay, (k["olay"]?.dizi ?? []).compactMap(\.metin))
            XCTAssertEqual(h.ressam, (k["ressam"]?.dizi ?? []).compactMap(\.metin))
            XCTAssertEqual(h.gozden, (k["gozden"]?.dizi ?? []).compactMap(\.metin))

            let bKar = bh["karakterKaydi"]
            if let bKar, !bKar.bosMu {
                let kar = try XCTUnwrap(h.karakterKaydi, h.anahtar)
                XCTAssertEqual(kar.birim, bKar["birim"]?.metin)
                let bNoktalar = try XCTUnwrap(bKar["noktalar"]?.dizi)
                XCTAssertEqual(kar.noktalar.count, bNoktalar.count, h.anahtar)
                for (n, bn) in zip(kar.noktalar, bNoktalar) {
                    XCTAssertEqual(n.ad, bn["ad"]?.metin)
                    XCTAssertEqual(n.metin, bn["metin"]?.metin)
                    XCTAssertEqual(n.x, bn["x"]?.sayi ?? -1, accuracy: 1e-6)
                    XCTAssertEqual(n.y, bn["y"]?.sayi ?? -1, accuracy: 1e-6)
                    XCTAssertEqual(n.w, bn["w"]?.sayi ?? -1, accuracy: 1e-6)
                    XCTAssertEqual(n.h, bn["h"]?.sayi ?? -1, accuracy: 1e-6)
                }
            } else {
                XCTAssertNil(h.karakterKaydi, h.anahtar)
            }
        }
    }

    // MARK: - Künye, Notlar, Konu ve Kaynak Yazısı (js/goruntuleyici.js, js/karsilastir.js, js/ikonografi.js)

    func testEserKunyesiNotlarVeKonular() throws {
        let (c, katalog, baglam) = try hazirla()
        let vakalar = try XCTUnwrap(c["eserKunyeVakalar"]?.dizi)
        XCTAssertGreaterThan(vakalar.count, 100)

        var eserHaritasi: [String: [String: Eser]] = [:]
        for v in vakalar {
            let sid = v["sid"]!.metin!
            if eserHaritasi[sid] == nil {
                eserHaritasi[sid] = Dictionary(katalog.eserler(sid).map { ($0.anahtar, $0) }, uniquingKeysWith: { a, _ in a })
            }
            let anahtar = v["anahtar"]!.metin!
            let eser = try XCTUnwrap(eserHaritasi[sid]?[anahtar], "\(sid) \(anahtar)")
            let gorsel = try XCTUnwrap(baglam.secilenGorsel(eser), "\(sid) \(anahtar)")

            let yer = "\(sid) \(anahtar)"
            XCTAssertEqual(AyrintiKurallari.ayrintiAnahtari(eser), v["ayrintiAnahtari"]?.metin, yer)
            XCTAssertEqual(GoruntuleyiciKurallari.kaynakYazisi(eser, gorsel: gorsel), v["kaynakYazisi"]?.metin, yer)
            XCTAssertEqual(katalog.gorsel.devasaKaynagi(gorsel), v["devasaKaynagi"]?.metin, yer)
            XCTAssertEqual(katalog.gorsel.sayfa(gorsel), v["sayfa"]?.metin, yer)
            XCTAssertEqual(baglam.eserNotu(eser), v["not"]?.metin, yer)
            XCTAssertEqual(baglam.ayrinti(eser)?.anahtar, v["ayrinti"]?.metin, yer)
            XCTAssertEqual(baglam.hikaye(eser)?.anahtar, v["hikaye"]?.metin, yer)
            XCTAssertEqual(baglam.konu(eser)?.id, v["konu"]?["id"]?.metin, yer)
            XCTAssertEqual(baglam.konu(eser)?.ad, v["konu"]?["ad"]?.metin, yer)
        }
    }

    func testTaninmaBenzerSanatcilarVeKarsilastirmaRotasi() throws {
        let (c, katalog, _) = try hazirla()
        let tanimaNotlari = GoruntuleyiciKurallari.notlariAl(veri: try Self.goruntuleyiciDosya("tanima_notlari.json"))

        for cift in c["taninmaListesi"]?.dizi ?? [] {
            let id = cift.dizi![0].metin!
            let beklenen = cift.dizi![1].metin!
            let sanatci = try XCTUnwrap(katalog.harita[id])
            XCTAssertEqual(GoruntuleyiciKurallari.taninmaMetni(sanatci, tanimaNotlari: tanimaNotlari), beklenen, id)
        }

        for v in c["benzerVakalar"]?.dizi ?? [] {
            let id = v["id"]!.metin!
            let beklenen = (v["benzerler"]?.dizi ?? []).compactMap(\.metin)
            let sanatci = try XCTUnwrap(katalog.harita[id])
            let sonuc = GoruntuleyiciKurallari.benzerSanatcilar(
                sanatci,
                sanatcilar: katalog.sanatcilar,
                akimlar: katalog.akimlar
            ).map(\.id)
            XCTAssertEqual(sonuc, beklenen, "benzerSanatcilar: \(id)")
        }

        for r in c["rotaTestleri"]?.dizi ?? [] {
            let a = r["a"]!.metin!
            let b = r["b"]!.metin!
            let adr = GoruntuleyiciKurallari.karsilastirmaAdresi(a, b)
            XCTAssertEqual(adr, r["adres"]?.metin)
            let cozulen = GoruntuleyiciKurallari.karsilastirmaRotasi(adr)
            XCTAssertEqual(cozulen?.0, a)
            XCTAssertEqual(cozulen?.1, b)
        }
        XCTAssertNil(GoruntuleyiciKurallari.karsilastirmaRotasi("#/karsilastir/a/a"))
        XCTAssertNil(GoruntuleyiciKurallari.karsilastirmaRotasi("#/karsilastir/a"))
    }

    // MARK: - Koleksiyon ve Bildirim (js/koleksiyon.js, js/bildirim.js)

    func testKoleksiyonVeBildirimAdimlari() throws {
        let (c, katalog, _) = try hazirla()
        XCTAssertEqual(
            c["nedenler"]?.dizi?.compactMap(\.metin),
            BildirimKurallari.nedenler
        )
        XCTAssertEqual(c["koleksiyonSiniri"]?.tamSayi, KoleksiyonKurallari.sinir)

        var eserHaritasi: [String: [String: Eser]] = [:]
        func eserBul(_ sid: String, _ anahtar: String) throws -> Eser {
            if eserHaritasi[sid] == nil {
                eserHaritasi[sid] = Dictionary(katalog.eserler(sid).map { ($0.anahtar, $0) }, uniquingKeysWith: { a, _ in a })
            }
            return try XCTUnwrap(eserHaritasi[sid]?[anahtar], "\(sid) \(anahtar)")
        }

        var il = try Ilerleme(json: .nesne([
            ("koleksiyon", c["baslangicKoleksiyon"] ?? .dizi([])),
            ("kotuGorseller", .nesne(.bos)),
            ("bildirimler", .dizi([])),
        ]))

        for (i, adim) in (c["koleksiyonAdimlari"]?.dizi ?? []).enumerated() {
            let e = try eserBul(adim["sid"]!.metin!, adim["anahtar"]!.metin!)
            let t = adim["tarih"]!.metin!
            let sonuc = KoleksiyonKurallari.degistir(&il, eser: e, tarih: t)
            XCTAssertEqual(sonuc, adim["sonuc"]?.mantik, "koleksiyon adım \(i)")
            XCTAssertEqual(KoleksiyonKurallari.koleksiyondaMi(il, eser: e), adim["varMi"]?.mantik, "koleksiyon adım \(i)")
            XCTAssertEqual(il[alan: "koleksiyon"], adim["liste"], "koleksiyon adım \(i)")
        }

        for (i, adim) in (c["bildirimAdimlari"]?.dizi ?? []).enumerated() {
            let e = try eserBul(adim["sid"]!.metin!, adim["anahtar"]!.metin!)
            let neden = adim["neden"]!.metin!
            let t = adim["tarih"]!.metin!
            let g = GorselAdresleri.secilen(e, kotuler: il.kotuGorseller)
            let sonraki = BildirimKurallari.eseriBildir(&il, eser: e, gorsel: g, neden: neden, tarih: t)
            XCTAssertEqual(sonraki?.anahtar, adim["sonrakiAnahtar"]?.metin, "bildirim adım \(i)")
            XCTAssertEqual(
                GorselAdresleri.pekistirmeyeUygun(e, kotuler: il.kotuGorseller),
                adim["uygunMu"]?.mantik,
                "bildirim adım \(i)"
            )
            XCTAssertEqual(il[alan: "kotuGorseller"], adim["kotuGorseller"], "bildirim adım \(i)")
            XCTAssertEqual(il[alan: "bildirimler"], adim["bildirimler"], "bildirim adım \(i)")
        }
    }

    // MARK: - Keskin üst kopya (js/keskin.js)

    func testKeskinlikVeUstKopya() throws {
        let (_, katalog, _) = try hazirla()
        // 400 px genişliğinde görsel 300x300 kutuda dpr=3 ile gösterilirse keskinlik = 400 / (300 * 3) = 0.444 < 0.8
        let k = GoruntuleyiciKurallari.keskinlik(
            dogalBoyut: (400, 400),
            kutuBoyutu: (300, 300),
            contain: true,
            dpr: 3.0
        )
        XCTAssertEqual(k, 400.0 / 900.0, accuracy: 1e-6)

        // Commons küçük resmi bir üst basamağa yükseltilmeli
        let commonsSrc = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Mona_Lisa.jpg/500px-Mona_Lisa.jpg"
        let ustCommons = GoruntuleyiciKurallari.commonsUstu(commonsSrc, keskinlik: 0.45, dogalGenislik: 500)
        XCTAssertEqual(ustCommons, "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Mona_Lisa.jpg/1280px-Mona_Lisa.jpg")

        // Yerel 400 px görsel → 1280 px b/ kopyasına yükseltilmeli
        let eser = try XCTUnwrap(katalog.eserler("jan-van-eyck").first)
        let g = try XCTUnwrap(GorselAdresleri.secilen(eser))
        let kucuk = katalog.gorsel.url(g, genislik: 400)
        let buyuk = katalog.gorsel.url(g, genislik: 1280)
        let yukseltilen = GoruntuleyiciKurallari.keskinUstAdres(
            src: kucuk,
            dogalBoyut: (400, 500),
            kutuBoyutu: (320, 400),
            ekranBoyutu: (390, 844),
            dpr: 3.0,
            gorselAdresleri: katalog.gorsel
        )
        XCTAssertEqual(yukseltilen, buyuk)
    }
}

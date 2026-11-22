// Kâhin: Testler/kahin/ders_adimlari.mjs → Ornekler/ders_adimlari/cevaplar.json (canlı sitenin ders ekranları @ a866b86)
import XCTest
@testable import NoraCekirdek

final class DersAdimlariTests: XCTestCase {
    private struct Durus: Decodable { let tx: Double; let ty: Double; let s: Double }
    private struct Ornek: Decodable { let t: Double; let p: Durus }
    private struct Yol: Decodable {
        let a: Durus; let b: Durus; let W: Double; let orta: Double
        let sure: Int; let uzunluk: Double; let ornekler: [Ornek]
    }
    private struct Egri: Decodable { let x: Double; let kamera: Double; let ease: Double }
    private struct Roma: Decodable { let n: Int; let r: String }
    private struct Kamera: Decodable { let yollar: [Yol]; let egriler: [Egri]; let roma: [Roma] }
    private struct GorKaresiC: Decodable {
        let kare: Int; let nokta: Int; let eser: String; let baslik: String; let metin: String; let noktalar: String
        let noktaSiniflari: [String]; let ileri: String; let geriGizli: Bool; let alt: String
        let W: Double; let ust: Double; let altSinir: Double; let IW: Double; let IH: Double; let durus: Durus; let olcek: String
    }
    private struct GorC: Decodable { let kareler: [GorKaresiC] }
    private struct Aciklama: Decodable { let id: String; let yazi: String }
    private struct OgrenC: Decodable {
        let madde: Int; let baslik: String; let etiket: String; let h2: String; let kanit: String?; let kanitYok: String?
        let kanitSayisi: Int; let aciklamalar: [Aciklama]; let altyazi: String?; let serit: [String]; let ileri: String; let geri: Bool
    }
    private struct Yan: Decodable { let akim: String; let sinif: String; let ad: String }
    private struct Sutun: Decodable { let ad: String; let maddeler: [String] }
    private struct Cumle: Decodable { let cumle: String; let kaynak: String }
    private struct AyirtC: Decodable {
        let komsu: String; let baslik: String; let soru: String; let soruAlt: String; let bos: [String]
        let sonuc: String; let dogru: Bool; let yanlar: [Yan]; let sutunlar: [Sutun]; let cumleler: [Cumle]
        let bag: String; let ileri: String; let geri: Bool
    }
    private struct Dugme: Decodable { let test: String?; let yazi: String; let adres: String }
    private struct AdimKaydiC: Decodable { let i: Double; let t: String? }
    private struct SonC: Decodable {
        let adim: String?; let test: String; let h2: String; let p: [String]; let dugmeler: [Dugme]
        let etiket: String; let baslik: String
        let kayit: [String: AdimKaydiC]?
    }
    private struct DersC: Decodable {
        let akim: String; let gor: GorC?; let ogren: [OgrenC]; let ayirt: [AyirtC]; let sonlar: [String: SonC]
    }
    private struct Baslangic: Decodable { let akim: String; let i: Double; let kare: Int }
    private struct Cevaplar: Decodable { let kamera: Kamera; let dersler: [DersC]; let baslangiclar: [Baslangic] }

    private func yukle() throws -> (Cevaplar, SiteKatalogu, JSONDeger, JSONDeger) {
        let (_, k) = try XCTUnwrap(SiteVerisiTests.hazir, "katalog örnekleri okunamadı")
        let c = try JSONDecoder().decode(Cevaplar.self, from: CalisTests.dosya("ders_adimlari/cevaplar.json"))
        let dersKaynagi = try JSONDeger.coz(CalisTests.dosya("calis/ders_kaynaklari.json"))
        let yuruyus = try JSONDeger.coz(CalisTests.dosya("site_verisi/yuruyus.json"))
        return (c, k, dersKaynagi, yuruyus)
    }

    private func esit(_ a: KameraDurusu, _ b: Durus, _ tol: Double, _ m: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.tx, b.tx, accuracy: tol * max(1, abs(b.tx)), "\(m) tx", file: file, line: line)
        XCTAssertEqual(a.ty, b.ty, accuracy: tol * max(1, abs(b.ty)), "\(m) ty", file: file, line: line)
        XCTAssertEqual(a.s, b.s, accuracy: tol * max(1, abs(b.s)), "\(m) s", file: file, line: line)
    }

    private func durus(_ d: Durus) -> KameraDurusu { KameraDurusu(tx: d.tx, ty: d.ty, s: d.s) }

    func testKameraYoluVeEgrisi() throws {
        let (c, _, _, _) = try yukle()
        XCTAssertEqual(c.kamera.yollar.count, 26)
        for (i, y) in c.kamera.yollar.enumerated() {
            let yol = DersKamerasi.kameraYolu(durus(y.a), durus(y.b), W: y.W, orta: y.orta)
            XCTAssertEqual(yol.sure, y.sure, "yol \(i)")
            XCTAssertEqual(yol.uzunluk, y.uzunluk, accuracy: 1e-9 * max(1, y.uzunluk), "yol \(i)")
            for o in y.ornekler { esit(yol.ornek(o.t), o.p, 1e-9, "yol \(i) t=\(o.t)") }
        }
        let ease = DersKamerasi.egri(0.25, 0.1, 0.25, 1)
        for e in c.kamera.egriler {
            XCTAssertEqual(DersKamerasi.kameraEgrisi(e.x), e.kamera, accuracy: 1e-12, "x=\(e.x)")
            XCTAssertEqual(ease(e.x), e.ease, accuracy: 1e-12, "x=\(e.x)")
        }
        for r in c.kamera.roma { XCTAssertEqual(DersAdimKurallari.roma(r.n), r.r) }
    }

    func testGorKareleriYazilarVeKamera() throws {
        let (c, k, dersKaynagi, yuruyus) = try yukle()
        var gorlu = 0
        for d in c.dersler {
            let ders = CalisDersKurallari.dersBul(kaynak: dersKaynagi, akim: d.akim)
            let eserler = DersAdimKurallari.gorEserleri(ders: ders, yuruyus: yuruyus)
            guard let g = d.gor else {
                XCTAssertTrue(eserler.isEmpty, d.akim)
                let s = try XCTUnwrap(d.sonlar["gorYok"], d.akim)
                XCTAssertEqual(s.etiket, DersAdimKurallari.ustEtiketi(akim: d.akim, adim: .gor, adimlar: DersAdimi.allCases))
                continue
            }
            gorlu += 1
            let kareler = DersAdimKurallari.gorKareleri(eserler.map(\.noktalar.count))
            XCTAssertEqual(kareler.count, g.kareler.count, d.akim)
            let toplam = eserler.reduce(0) { $0 + $1.noktalar.count }
            for (konum, b) in g.kareler.enumerated() {
                let m = "\(d.akim) kare \(konum)"
                XCTAssertEqual(b.kare, konum, m)
                XCTAssertEqual(kareler[konum].ni, b.nokta, m)
                let es = eserler[kareler[konum].ei]
                let kisa = DersAdimKurallari.kisaAd(es.sanatci, katalog: k)
                let ad = DersAdimKurallari.yuruyusEserAdi(es, katalog: k)
                let y = DersAdimKurallari.gorYazilari(eserler: eserler, kareler: kareler, konum: konum, kisaAd: kisa, eserAdi: ad)
                XCTAssertEqual(y.eser, b.eser, m)
                XCTAssertEqual(y.baslik, b.baslik, m)
                XCTAssertEqual(y.metin, b.metin, m)
                XCTAssertEqual(y.noktalar, b.noktalar, m)
                XCTAssertEqual(y.ileri, b.ileri, m)
                XCTAssertEqual(y.geriGizli, b.geriGizli, m)
                XCTAssertEqual(DersAdimKurallari.gorEserAdi(es, kisaAd: kisa, eserAdi: ad), b.alt, m)
                let ni = kareler[konum].ni
                XCTAssertEqual(b.noktaSiniflari, (0..<es.noktalar.count).map { $0 < ni ? "gecti" : $0 == ni ? "simdi" : "" }, m)
                // kamera: site duruşu matrisle 2 ve 5 hane yuvarlar
                let n = ni >= 0 ? es.noktalar[ni] : nil
                let h = DersKamerasi.hedef(W: b.W, ust: b.ust, alt: b.altSinir, resim: (b.IW, b.IH),
                                           nokta: n.map { ($0.x, $0.y, $0.w, $0.h) })
                XCTAssertEqual(h.p.tx, b.durus.tx, accuracy: 0.006, m)
                XCTAssertEqual(h.p.ty, b.durus.ty, accuracy: 0.006, m)
                XCTAssertEqual(h.p.s, b.durus.s, accuracy: 0.000006, m)
                XCTAssertEqual(String(format: "%.2f", h.olcek), b.olcek, m)
            }
            // Gör'ün sonu
            let s = try XCTUnwrap(d.sonlar["gor"], d.akim)
            XCTAssertEqual(s.h2, "Gör tamam")
            XCTAssertEqual(s.p.first, DersAdimKurallari.sonYazisi(.gor, gorEser: eserler.count, gorToplam: toplam, ogren: 0, ayirt: 0))
            XCTAssertEqual(s.kayit?["gor"]?.i, 1, d.akim)
        }
        XCTAssertEqual(gorlu, 25)

        // Kaldığı yerden açılış
        let gotik = try XCTUnwrap(DersAdimKurallari.gorEserleri(
            ders: CalisDersKurallari.dersBul(kaynak: dersKaynagi, akim: "Gotik"), yuruyus: yuruyus))
        let kareler = DersAdimKurallari.gorKareleri(gotik.map(\.noktalar.count))
        let toplam = gotik.reduce(0) { $0 + $1.noktalar.count }
        XCTAssertFalse(c.baslangiclar.isEmpty)
        for b in c.baslangiclar {
            XCTAssertEqual(DersAdimKurallari.gorBaslangici(kareler, i: b.i, toplam: toplam), b.kare, "i=\(b.i)")
        }
    }

    func testOgrenVeAyirtYazilari() throws {
        let (c, k, dersKaynagi, yuruyus) = try yukle()
        var il = try Ilerleme(veri: Data("{}".utf8))
        il.islenen = k.konular.map(\.no)
        var altyaziFarki = 0
        for d in c.dersler {
            let b = try XCTUnwrap(CalisDersKurallari.dersBilgisi(kaynak: dersKaynagi, yuruyus: yuruyus, katalog: k, ilerleme: il, akim: d.akim))
            // Öğren
            XCTAssertEqual(b.ogren.count, d.ogren.count, d.akim)
            for (konum, (m, x)) in zip(b.ogren, d.ogren).enumerated() {
                let yer = "\(d.akim) öğren \(konum)"
                XCTAssertEqual(x.madde, m.no, yer)
                XCTAssertEqual(x.baslik, DersAdimKurallari.ogrenBasligi(konum: konum, toplam: b.ogren.count), yer)
                XCTAssertEqual(x.etiket, DersAdimKurallari.ustEtiketi(akim: d.akim, adim: .ogren, adimlar: b.adimlar), yer)
                XCTAssertEqual(x.h2, m.madde, yer)
                XCTAssertEqual(x.kanit, m.kanitlar.first?.id, yer)
                XCTAssertEqual(x.kanitYok != nil, m.kanitlar.isEmpty, yer)
                XCTAssertEqual(x.kanitSayisi, m.kanitlar.count, yer)
                XCTAssertEqual(x.aciklamalar.map(\.id), m.aciklamalar.map(\.id), yer)
                for (a, ma) in zip(x.aciklamalar, m.aciklamalar) {
                    let kisa = ma.sanatci.map { DersAdimKurallari.kisaAd($0, katalog: k) } ?? ""
                    XCTAssertEqual(a.yazi, (kisa.isEmpty ? "" : "\(kisa): ") + ma.cumle, yer)
                }
                XCTAssertEqual(x.ileri, DersAdimKurallari.ogrenIleri(konum: konum, toplam: b.ogren.count), yer)
                XCTAssertEqual(x.geri, konum > 0, yer)
                XCTAssertEqual(x.serit, m.kanitlar.count > 1 ? m.kanitlar.map { DersAdimKurallari.kisaAd($0.sanatci, katalog: k) } : [], yer)
                if let kn = m.kanitlar.first {
                    let ref = DersEserRef(sanatci: kn.sanatci, eser: kn.eser, qid: kn.qid, anahtar: kn.anahtar)
                    let e = CalisDersKurallari.eserEslestir(k.eserler(kn.sanatci), sid: kn.sanatci, ref: ref)
                    let alt = DersAdimKurallari.kanitAltyazisi(kisaAd: DersAdimKurallari.kisaAd(kn.sanatci, katalog: k), kanitEseri: kn.eser, eser: e)
                    // eser listesi sitede Wikidata'dan da gelebilir; örnek katalog onunla aynı olmayabilir
                    if alt != x.altyazi { altyaziFarki += 1 }
                }
            }
            let so = try XCTUnwrap(d.sonlar["ogren"], d.akim)
            XCTAssertEqual(so.h2, "Öğren tamam")
            XCTAssertEqual(so.p.first, DersAdimKurallari.sonYazisi(.ogren, gorEser: 0, gorToplam: 0, ogren: b.ogren.count, ayirt: 0))

            // Ayırt et
            XCTAssertEqual(b.ayirt.count, d.ayirt.count, d.akim)
            for (konum, (ik, x)) in zip(b.ayirt, d.ayirt).enumerated() {
                let yer = "\(d.akim) ayırt \(konum)"
                XCTAssertEqual(x.komsu, ik.komsu, yer)
                XCTAssertEqual(x.baslik, DersAdimKurallari.ayirtBasligi(konum: konum, toplam: b.ayirt.count), yer)
                XCTAssertEqual(x.soru, DersAdimKurallari.ayirtSorusu(d.akim), yer)
                XCTAssertEqual(x.soruAlt, DersAdimKurallari.ayirtAltYazisi(ik), yer)
                XCTAssertEqual(x.bos, ["Soldaki", "Sağdaki"], yer)
                XCTAssertEqual(x.sonuc, DersAdimKurallari.ayirtSonucu(dogru: x.dogru), yer)
                XCTAssertEqual(x.yanlar.map(\.akim).sorted(), [d.akim, ik.komsu].sorted(), yer)
                XCTAssertEqual(x.yanlar[0].sinif, x.dogru ? "dogru" : "yanlis", yer)
                XCTAssertEqual(x.sutunlar.map(\.ad), [d.akim, ik.komsu], yer)
                XCTAssertEqual(x.sutunlar.map(\.maddeler), [ik.kendiMaddeler, ik.komsuMaddeler], yer)
                XCTAssertEqual(x.cumleler.map(\.cumle), ik.cumleler.map(\.cumle), yer)
                XCTAssertEqual(x.cumleler.map(\.kaynak), ik.cumleler.map { DersAdimKurallari.cumleKaynagi($0.kaynak) }, yer)
                XCTAssertEqual(x.bag, CalisKurallari.akimKarsilastirmaAdresi(d.akim, ik.komsu), yer)
                XCTAssertEqual(x.ileri, DersAdimKurallari.ayirtIleri(konum: konum, toplam: b.ayirt.count), yer)
                XCTAssertEqual(x.geri, konum > 0, yer)
            }

            // Ayırt et'in sonu: üç adım da bitti (Gör'süz derste iki adım)
            let sa = try XCTUnwrap(d.sonlar["ayirt"], d.akim)
            XCTAssertEqual(sa.h2, "Ayırt et tamam")
            XCTAssertEqual(sa.etiket, DersAdimKurallari.ustEtiketi(akim: d.akim, adim: .ayirt, adimlar: b.adimlar))
            XCTAssertEqual(sa.p.first, DersAdimKurallari.sonYazisi(.ayirt, gorEser: 0, gorToplam: 0, ogren: 0, ayirt: b.ayirt.count))
            var kayit = DersKaydi()
            for a in DersAdimi.allCases { if let x = sa.kayit?[a.rawValue] { kayit[a] = DersAdimKaydi(i: x.i, t: x.t) } }
            let durum = CalisDersKurallari.dersDurumu(kayit, adimlar: b.adimlar)
            XCTAssertTrue(durum.bitti, d.akim)
            XCTAssertNil(DersAdimKurallari.sonrakiAdim(.ayirt, adimlar: b.adimlar, durum: durum))
            XCTAssertEqual(sa.dugmeler.map(\.test), ["ders-haritaya-gec", "ders-derse-don"], d.akim)
            XCTAssertEqual(sa.p.count, 2, d.akim)
            // Öğren'in sonunda sıradaki adım: Ayırt et (Gör bittiyse) — sitede Gör önce bitti
            let sonrakiOgren = DersAdimKurallari.sonrakiAdim(.ogren, adimlar: b.adimlar,
                durum: CalisDersKurallari.dersDurumu(DersKaydi(gor: .init(i: 1), ogren: .init(i: 1)), adimlar: b.adimlar))
            XCTAssertEqual(so.dugmeler.first?.test, "ders-sonraki-adim", d.akim)
            XCTAssertEqual(so.dugmeler.first?.yazi, "Sıradaki adım: \(sonrakiOgren?.ad ?? "")", d.akim)
        }
        XCTAssertLessThanOrEqual(altyaziFarki, 6, "kanıt altyazılarında örnek katalogla fark")
    }

    func testSonrakiAdim() {
        let adimlar = DersAdimi.allCases
        func durum(_ g: Double, _ o: Double, _ a: Double) -> DersDurumu {
            CalisDersKurallari.dersDurumu(DersKaydi(gor: .init(i: g), ogren: .init(i: o), ayirt: .init(i: a)), adimlar: adimlar)
        }
        // Ayırt et önce bitti: sıradaki baştaki Gör
        XCTAssertEqual(DersAdimKurallari.sonrakiAdim(.ayirt, adimlar: adimlar, durum: durum(0, 0, 1)), .gor)
        // Gör bitti, Öğren yarım: Öğren
        XCTAssertEqual(DersAdimKurallari.sonrakiAdim(.gor, adimlar: adimlar, durum: durum(1, 0.5, 0)), .ogren)
        // Gör bitti, Öğren bitmiş: Ayırt et
        XCTAssertEqual(DersAdimKurallari.sonrakiAdim(.gor, adimlar: adimlar, durum: durum(1, 1, 0)), .ayirt)
        XCTAssertNil(DersAdimKurallari.sonrakiAdim(.ogren, adimlar: adimlar, durum: durum(1, 1, 1)))
        XCTAssertEqual(DersAdimKurallari.gorIlerle(GorKaresi(ei: 0, ni: 2, sira: 3), gorulen: 2), 3)
        XCTAssertNil(DersAdimKurallari.gorIlerle(GorKaresi(ei: 0, ni: -1, sira: 3), gorulen: 2))
        XCTAssertNil(DersAdimKurallari.gorIlerle(GorKaresi(ei: 0, ni: 0, sira: 1), gorulen: 4))
        XCTAssertEqual(DersAdimKurallari.ilerle(konum: 2, gorulen: 2), 3)
        XCTAssertNil(DersAdimKurallari.ilerle(konum: 1, gorulen: 4))
    }
}

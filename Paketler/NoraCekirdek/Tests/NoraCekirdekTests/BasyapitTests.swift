// Kaynak: sanat-atlasi js/basyapit.js, js/basyapitSayfa.js, js/eserDersi.js, js/ekranlar/{gozat,basyapit}.js @ a866b86
// Örnekler: node Testler/kahin/basyapit.mjs (canlı sitenin kendi modülleriyle)
import Foundation
import XCTest
@testable import NoraCekirdek

final class BasyapitTests: XCTestCase {
    private struct Grup: Decodable {
        let bolge, ad, yuzyil: String
        let akimlar: [[JSONSecim]]
    }
    /// `[ad, [anahtar]]`
    private enum JSONSecim: Decodable {
        case ad(String), liste([String])
        init(from d: Decoder) throws {
            let c = try d.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .ad(s) } else { self = .liste(try c.decode([String].self)) }
        }
        var ad: String? { if case .ad(let s) = self { return s }; return nil }
        var liste: [String]? { if case .liste(let l) = self { return l }; return nil }
    }
    private struct One: Decodable {
        let durum: String
        let gun: Int
        let donem: String
        let sonuc: [String]
    }
    private struct Kirp: Decodable, Equatable { let w, h, l, t: Double }
    private struct Satir: Decodable { let ad, deger: String }
    private struct TerimC: Decodable { let ad, tanim: String }
    private struct Kiyas: Decodable { let eser, sanatci, gerekce: String; let anahtar: String? }
    private struct DersB: Decodable { let baslik, govde: String; let karsilastirma: Bool }
    private struct Sayfa: Decodable {
        let anahtar, gorunen: String
        let eser, ayrinti, klasor: String?
        let yerler: [[Int]]?
        let kirpimlar: [[[Kirp]]]
        let durum: [String]
        let kunye, kunyeDerssiz: [Satir]
        let terimler: [TerimC]
        let kiyaslar: [Kiyas]
        let temiz: String
        let bolumler: [DersB]
        let dakika: Int
        let metinler: [String]
        let aciklamalar: [String: String]
        let derin: [String?]
    }
    private struct Ornekler: Decodable {
        let gorunen: [[String]]
        let sade: [[String]]
        let md: [[String]]
        let temizle: [[String]]
    }
    private struct Cevaplar: Decodable {
        let liste, hikayeli: [String]
        let gruplar: [Grup]
        let oneCikanlar: [One]
        let sayfalar: [Sayfa]
        let ornekler: Ornekler
    }

    private static func dosya(_ ad: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/basyapit/\(ad)", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private static let hazir: (Cevaplar, [Basyapit], JSONDeger, SiteKatalogu)? = {
        guard let c = try? JSONDecoder().decode(Cevaplar.self, from: dosya("cevaplar")),
              let ham = try? dosya("basyapitlar"), let dersler = try? JSONDeger.coz(dosya("dersler")),
              let (_, k) = SiteVerisiTests.hazir else { return nil }
        return (c, BasyapitKurallari.al(veri: ham) { k.harita[$0] != nil }, dersler, k)
    }()

    private func hazirla() throws -> (Cevaplar, [Basyapit], JSONDeger, SiteKatalogu) {
        try XCTUnwrap(Self.hazir, "örnekler okunamadı")
    }

    func testListeVeGruplar() throws {
        let (c, liste, _, k) = try hazirla()
        XCTAssertEqual(liste.map(\.anahtar), c.liste)
        let gruplar = BasyapitKurallari.gruplar(liste, katalog: k)
        XCTAssertEqual(gruplar.map(\.bolge.id), c.gruplar.map(\.bolge))
        for (g, s) in zip(gruplar, c.gruplar) {
            XCTAssertEqual(g.bolge.ad, s.ad)
            XCTAssertEqual(g.bolge.yuzyil, s.yuzyil)
            XCTAssertEqual(g.akimlar.map(\.ad), s.akimlar.map { $0[0].ad ?? "" }, s.bolge)
            XCTAssertEqual(g.akimlar.map { $0.eserler.map(\.anahtar) }, s.akimlar.map { $0[1].liste ?? [] }, s.bolge)
        }
    }

    func testOneCikanlar() throws {
        let (c, liste, _, k) = try hazirla()
        let hikayeli = Set(c.hikayeli)
        let konular = Array(Set(k.sanatcilar.compactMap(\.konu))).sorted()
        let durumlar: [String: Set<Int>] = ["hepsi": Set(konular), "yarisi": Set(konular.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)), "hicbiri": []]
        let gruplar = BasyapitKurallari.gruplar(liste, katalog: k)
        XCTAssertGreaterThan(c.oneCikanlar.count, 50)
        for o in c.oneCikanlar {
            let islenen = try XCTUnwrap(durumlar[o.durum])
            let l = o.donem.isEmpty ? liste : gruplar.first { $0.bolge.id == o.donem }?.eserler ?? []
            let sonuc = BasyapitKurallari.oneCikanlar(l, hikayeli: hikayeli, acikMi: { b in
                k.harita[b.sanatci]?.konu.map(islenen.contains) ?? false
            }, gun: o.gun)
            XCTAssertEqual(sonuc.map(\.anahtar), o.sonuc, "\(o.durum) \(o.gun) \(o.donem)")
        }
    }

    func testSayfaYardimcilari() throws {
        let (c, liste, dersler, k) = try hazirla()
        let ayrintilar = AyrintiKurallari.ayrintilariAl(veri: try Data(contentsOf: XCTUnwrap(
            Bundle.module.url(forResource: "Ornekler/goruntuleyici/eser_ayrintilari", withExtension: "json"))))
        let yayin = DersYayini(dersler["yayin"])
        var dersSayisi = 0
        for s in c.sayfalar {
            let b = try XCTUnwrap(BasyapitKurallari.bul(liste, s.anahtar))
            XCTAssertEqual(b.gorunenBaslik, s.gorunen)
            let e = BasyapitKurallari.eser(k.eserler(b.sanatci), b)
            XCTAssertEqual(e?.anahtar, s.eser, b.anahtar)
            let kayit = AyrintiKurallari.ayrintiBul(ayrintilar, anahtar: b.anahtar) ?? AyrintiKurallari.eserinAyrintisi(ayrintilar, eser: e)
            XCTAssertEqual(kayit?.anahtar, s.ayrinti, b.anahtar)
            let noktalar = kayit?.noktalar ?? []
            let yerler = kayit.map { BasyapitSayfasi.noktalariYerlestir(b.bolumler, $0.noktalar) }
            XCTAssertEqual(yerler, s.yerler, b.anahtar)
            for (n, oranlar) in zip(noktalar, s.kirpimlar) {
                for (oran, beklenen) in zip([0.62, 1, 1.45], oranlar) {
                    let a = BasyapitSayfasi.kirpim(n, oran: oran, kutu: BasyapitSayfasi.buyukKutu, pay: 1.8, enCok: 3.2)
                    let b2 = BasyapitSayfasi.kirpim(n, oran: oran, kutu: BasyapitSayfasi.kucukKutu, pay: 1.4)
                    XCTAssertEqual(Kirp(w: a.w, h: a.h, l: a.l, t: a.t), beklenen[0], "\(b.anahtar) \(n.ad)")
                    XCTAssertEqual(Kirp(w: b2.w, h: b2.h, l: b2.l, t: b2.t), beklenen[1], "\(b.anahtar) \(n.ad)")
                }
            }
            XCTAssertEqual(yayin.klasor(b.anahtar), s.klasor)
            XCTAssertEqual([yayin.durum(b.anahtar).rawValue, yayin.durum(b.anahtar, gelistirici: true).rawValue], s.durum)
            let girdi = s.klasor.flatMap { dersler["dersler"]?[$0] }
            let ders = girdi?["ders"].flatMap { $0 == .bos ? nil : $0 }
            let orta = girdi?["orta"]?.metin ?? ""
            if girdi != nil { dersSayisi += 1 }
            XCTAssertEqual(BasyapitSayfasi.kunyeSatirlari(b, ders).map { [$0.ad, $0.deger] }, s.kunye.map { [$0.ad, $0.deger] }, b.anahtar)
            XCTAssertEqual(BasyapitSayfasi.kunyeSatirlari(b, nil).map { [$0.ad, $0.deger] }, s.kunyeDerssiz.map { [$0.ad, $0.deger] })
            let terimler = BasyapitSayfasi.sozlukAl(ders)
            XCTAssertEqual(terimler.map { [$0.ad, $0.tanim] }, s.terimler.map { [$0.ad, $0.tanim] }, b.anahtar)
            let kiyaslar = BasyapitSayfasi.karsilastirmalariAl(ders, liste, bu: b.anahtar) { k.harita[$0]?.ad ?? "" }
            XCTAssertEqual(kiyaslar.map { [$0.eser, $0.sanatci, $0.gerekce, $0.anahtar ?? "-"] },
                           s.kiyaslar.map { [$0.eser, $0.sanatci, $0.gerekce, $0.anahtar ?? "-"] }, b.anahtar)
            let temiz = DersMetni.temizle(orta)
            XCTAssertEqual(temiz, s.temiz, b.anahtar)
            let bolumler = BasyapitSayfasi.dersBolumleri(temiz)
            XCTAssertEqual(bolumler.map { [$0.baslik, $0.govde, "\($0.karsilastirma)"] },
                           s.bolumler.map { [$0.baslik, $0.govde, "\($0.karsilastirma)"] }, b.anahtar)
            XCTAssertEqual(BasyapitSayfasi.okumaDakikasi(temiz), s.dakika, b.anahtar)
            let m = BasyapitSayfasi.metinler(b, yerler: yerler, noktalar: noktalar, derin: bolumler,
                                             kiyasVar: !kiyaslar.isEmpty, terimler: terimler)
            XCTAssertEqual(m.bolumler, s.metinler, b.anahtar)
            XCTAssertEqual(Dictionary(uniqueKeysWithValues: m.aciklamalar.map { ("\($0.key)", $0.value) }), s.aciklamalar, b.anahtar)
            XCTAssertEqual(m.derin, s.derin, b.anahtar)
            // ekran okuyucusu: düz yazı HTML'in metniyle aynı (etiketler ve kanıt etiketleri hariç)
            for h in m.derin.compactMap({ $0 }) + m.bolumler {
                XCTAssertFalse(MetinBloklari.duzYazi(MetinBloklari.oku(h)).contains("<"), b.anahtar)
            }
        }
        XCTAssertGreaterThan(dersSayisi, 100)
    }

    func testKenarDurumlari() throws {
        let (c, _, _, _) = try hazirla()
        for g in c.ornekler.gorunen {
            let b = Basyapit(anahtar: "x", sanatci: "y", baslik: g[0], ozgun: g[1], bolumler: [])
            XCTAssertEqual(b.gorunenBaslik, g[2], g[0])
        }
        for s in c.ornekler.sade { XCTAssertEqual(BasyapitSayfasi.sade(s[0]), s[1], s[0]) }
        for m in c.ornekler.md { XCTAssertEqual(DersMetni.mdHtml(m[0]), m[1]) }
        for m in c.ornekler.temizle { XCTAssertEqual(DersMetni.temizle(m[0]), m[1]) }
    }

    func testTerimIsaretleOrnekleri() throws {
        let veri = try Self.dosya("cevaplar")
        let terim = try XCTUnwrap(JSONDeger.coz(veri)["ornekler"]?["terim"]?.dizi)
        for o in terim {
            let a = try XCTUnwrap(o.dizi)
            let terimler = (a[1].dizi ?? []).map { BasyapitSayfasi.Terim(ad: $0["ad"]?.metin ?? "", tanim: $0["tanim"]?.metin ?? "") }
            var kullanilan = Set<Int>()
            XCTAssertEqual(BasyapitSayfasi.terimIsaretle(a[0].metin ?? "", terimler, &kullanilan), a[2].metin)
        }
    }

    func testMetinBloklari() {
        let html = DersMetni.mdHtml("Paragraf **kalın** ve *italik* `kod` [C12].\n\n- bir\n- iki\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n> alıntı\n\n---\n### Alt & başlık")
        var k = Set<Int>()
        let isaretli = BasyapitSayfasi.terimIsaretle(html, [.init(ad: "Paragraf", tanim: "x")], &k)
        let b = MetinBloklari.oku(isaretli)
        XCTAssertEqual(b.count, 6)
        guard case .paragraf(let p) = b[0] else { return XCTFail() }
        XCTAssertEqual(p.first?.terim, 0)
        XCTAssertEqual(p.first?.metin, "Paragraf")
        XCTAssertTrue(p.contains { $0.kalin && $0.metin == "kalın" })
        XCTAssertTrue(p.contains { $0.italik && $0.metin == "italik" })
        XCTAssertTrue(p.contains { $0.kod && $0.metin == "kod" })
        XCTAssertTrue(p.contains { $0.ust && $0.metin == "C12" })
        XCTAssertEqual(b[1], .liste(sirali: false, [[.init(metin: "bir")], [.init(metin: "iki")]]))
        guard case .tablo(let bas, let satirlar) = b[2] else { return XCTFail() }
        XCTAssertEqual(bas.map { $0.first?.metin }, ["A", "B"])
        XCTAssertEqual(satirlar.map { $0.map { $0.first?.metin } }, [["1", "2"]])
        XCTAssertEqual(b[3], .alinti([.init(metin: "alıntı")]))
        XCTAssertEqual(b[4], .cizgi)
        XCTAssertEqual(b[5], .baslik(4, [.init(metin: "Alt & başlık")]))
        // düz metin (bölüm metni): tek paragraf, kaçışlar çözülür
        XCTAssertEqual(MetinBloklari.oku("Selve&#39;dir &amp; &quot;x&quot;"), [.paragraf([.init(metin: "Selve'dir & \"x\"")])])
    }
}

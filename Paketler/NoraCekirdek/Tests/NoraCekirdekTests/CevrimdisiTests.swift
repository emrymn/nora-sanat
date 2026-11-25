import Foundation
import XCTest
@testable import NoraCekirdek

/// C5 kâhini (Testler/kahin/cevrimdisi.mjs): sitenin indirme listesi, parça planı ve Ayarlar'daki yazılar. Liste
/// Ornekler/site_verisi/'ndeki veri dosyalarından kurulur (kâhin canlı sitenin aynı dosyaları kullandığını denetledi).
final class CevrimdisiTests: XCTestCase {
    struct ParcaC: Decodable {
        let adet: Int; let ilk, son: String?; let parca, parcaSayisi, onceden: Int; let oncedenBayt: Double; let sonParca: Bool
    }
    struct Sayilar: Decodable { let telefon, devasa: Int; let toplamBayt: Double }
    struct ListeC: Decodable {
        let suzuldu: Bool
        let sayilar: Sayilar
        let md5: String
        let ornekler: [[Deger]]
        let tahmini: [[Deger]]
        let parcalar: [String: ParcaC]
        let ilkBes: [String]
    }
    enum Deger: Decodable {
        case sayi(Double), metin(String)
        init(from d: Decoder) throws {
            let c = try d.singleValueContainer()
            if let s = try? c.decode(Double.self) { self = .sayi(s) } else { self = .metin(try c.decode(String.self)) }
        }
        var sayi: Double { if case let .sayi(s) = self { return s }; return .nan }
        var metin: String { if case let .metin(s) = self { return s }; return "" }
    }
    struct DurumC: Decodable {
        let toplam, hepsi, onceden, biten, hata, yazilamadi, parca, parcaSayisi: Int
        let oncedenBayt, bitenBayt: Double
        let bitti: Bool
        let yerYok, durduruldu, inemedi, parcaBitti: Bool?
        let sonHata: String?
        var durum: CevrimdisiDurumu {
            var i = CevrimdisiDurumu(CevrimdisiListe.Parca(urller: Array(repeating: "", count: toplam), parca: parca,
                                                            parcaSayisi: parcaSayisi, onceden: onceden, oncedenBayt: oncedenBayt,
                                                            hepsi: hepsi, sonParca: false))
            i.biten = biten; i.bitenBayt = bitenBayt; i.hata = hata; i.yazilamadi = yazilamadi; i.bitti = bitti
            i.yerYok = yerYok ?? false; i.durduruldu = durduruldu ?? false; i.inemedi = inemedi ?? false
            i.parcaBitti = parcaBitti ?? false; i.sonHata = sonHata
            return i
        }
    }
    struct AyarC: Decodable {
        let bilgi, mesaj, mesajSinif: String
        let indir, indirKapali, durdur, sil: Bool
        let cubuk: [Double]?
        let durum: DurumC?
    }
    struct Cevaplar: Decodable {
        let liste: ListeC
        let ayarlar: [String: AyarC]
        let mesajlar: [String: AyarC]
    }

    static let hazir: (Cevaplar, CevrimdisiListe)? = {
        guard let url = Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/cevrimdisi"),
              let c = try? JSONDecoder().decode(Cevaplar.self, from: Data(contentsOf: url)) else { return nil }
        var d: [String: Data] = [:]
        for f in SiteVerisi.katalogDosyalari { d[f] = try? SiteVerisiTests.dosya(f) }
        guard let k = try? SiteKatalogu(dosyalar: d) else { return nil }
        return (c, CevrimdisiListe(katalog: k))
    }()

    func hazirla() throws -> (Cevaplar, CevrimdisiListe) { try XCTUnwrap(Self.hazir, "örnekler okunamadı") }

    func testIndirmeListesiSitedekiyle() throws {
        let (c, l) = try hazirla()
        XCTAssertTrue(l.suzuldu)
        XCTAssertEqual(l.telefonAdresleri.count, c.liste.sayilar.telefon)
        XCTAssertEqual(l.devasaAdresleri.count, c.liste.sayilar.devasa)
        for o in c.liste.ornekler {
            let i = Int(o[0].sayi)
            XCTAssertEqual(l.telefonAdresleri[i], o[1].metin, "sıra \(i)")
        }
        XCTAssertEqual(SiteYazisi.md5(l.telefonAdresleri.joined(separator: "\n")), c.liste.md5, "sıralı listenin tamamı")
        XCTAssertEqual(l.toplamBayt, c.liste.sayilar.toplamBayt)
        for t in c.liste.tahmini { XCTAssertEqual(l.tahminiBayt(t[0].metin), t[1].sayi, accuracy: 1e-6, t[0].metin) }
    }

    func testParcaPlaniSitedekiyle() throws {
        let (c, l) = try hazirla()
        let tel = l.telefonAdresleri, dev = l.devasaAdresleri
        let kumeler: [String: Set<String>] = [
            "bos": [], "ilk150": Set(tel.prefix(150)), "ilk200": Set(tel.prefix(200)), "ilk1234": Set(tel.prefix(1234)),
            "ucteBir": Set(tel.enumerated().filter { $0.offset % 3 == 0 }.map(\.element)), "devasalar": Set(dev),
            "sonBesHaric": Set(tel.dropLast(5)), "hepsi": Set(tel),
        ]
        XCTAssertEqual(Set(kumeler.keys), Set(c.liste.parcalar.keys))
        for (ad, k) in kumeler {
            let p = l.parca(telefonda: k), b = try XCTUnwrap(c.liste.parcalar[ad])
            XCTAssertEqual(p.urller.count, b.adet, ad)
            XCTAssertEqual(p.urller.first, b.ilk, ad)
            XCTAssertEqual(p.urller.last, b.son, ad)
            XCTAssertEqual(p.parca, b.parca, ad)
            XCTAssertEqual(p.parcaSayisi, b.parcaSayisi, ad)
            XCTAssertEqual(p.onceden, b.onceden, ad)
            XCTAssertEqual(p.oncedenBayt, b.oncedenBayt, accuracy: 1, ad)
            XCTAssertEqual(p.sonParca, b.sonParca, ad)
        }
    }

    /// Sitede indirme notu (parçalar, sayfanın kendini yenilemesi) uygulamada farklı: o cümleye kadar aynı
    func bilgiAyni(_ swift: String, _ site: String, _ ad: String) {
        let kes = "Wi-Fi’de indir."
        if let r = site.range(of: kes) {
            XCTAssertEqual(String(swift[..<(swift.range(of: kes)?.upperBound ?? swift.endIndex)]), String(site[..<r.upperBound]), ad)
        } else {
            XCTAssertEqual(swift, site, ad)
        }
    }

    func dugmelerAyni(_ g: CevrimdisiGorunum, _ s: AyarC, _ ad: String) {
        XCTAssertEqual(g.indir, s.indir, "\(ad) indir")
        XCTAssertEqual(g.indirKapali, s.indirKapali, "\(ad) indir kapalı")
        XCTAssertEqual(g.durdur, s.durdur, "\(ad) durdur")
        XCTAssertEqual(g.sil, s.sil, "\(ad) sil")
        XCTAssertEqual(g.cubuk.map { [$0.deger, $0.enCok] }, s.cubuk, "\(ad) çubuk")
        let sinif: CevrimdisiGorunum.Tur = s.mesajSinif.contains("hata") ? .hata : s.mesajSinif.contains("tamam") ? .tamam : .olagan
        XCTAssertEqual(g.mesajTuru, sinif, "\(ad) ileti türü")
    }

    func testAyarlarBilgisiSitedekiyle() throws {
        let (c, l) = try hazirla()
        let bos = try XCTUnwrap(c.ayarlar["bos"]), bes = try XCTUnwrap(c.ayarlar["bes"])
        let g0 = CevrimdisiGorunum(liste: l, telefonda: 0, durum: nil)
        bilgiAyni(g0.bilgi, bos.bilgi, "telefonda 0")
        dugmelerAyni(g0, bos, "telefonda 0")
        let g5 = CevrimdisiGorunum(liste: l, telefonda: 5, durum: nil)
        bilgiAyni(g5.bilgi, bes.bilgi, "telefonda 5")
        dugmelerAyni(g5, bes, "telefonda 5")
        XCTAssertTrue(g0.bilgi.hasSuffix(CevrimdisiGorunum.indirmeNotu(l)))
        // Hepsi telefondayken: İndir kalkar
        let gh = CevrimdisiGorunum(liste: l, telefonda: l.telefonAdresleri.count, durum: nil)
        XCTAssertEqual(gh.bilgi, "Hepsi telefonda: 19402 görsel (5624 eserin 4096 piksele kadar en yüksek kalitedeki hali ve sayfalarda görünen 1280 ile 400 piksellik halleri (19402 dosya)) · 21,0 GB. Sayfalar ve görüntüleyici internet olmadan, telefondan açılır.")
        XCTAssertFalse(gh.indir)
        XCTAssertTrue(gh.sil)
    }

    func testIletilerSitedekiyle() throws {
        let (c, l) = try hazirla()
        XCTAssertEqual(c.mesajlar.count, 10)
        for (ad, s) in c.mesajlar {
            let i = try XCTUnwrap(s.durum?.durum)
            let g = CevrimdisiGorunum(liste: l, telefonda: 5, durum: i)
            bilgiAyni(g.bilgi, s.bilgi, ad)
            dugmelerAyni(g, s, ad)
            if ad == "parcaBitti" {
                // Sitede sayfa yenilenir; burada sıradaki parça hemen başlar
                XCTAssertEqual(g.mesaj.components(separatedBy: ". ").first, s.mesaj.components(separatedBy: ". ").first, ad)
                XCTAssertTrue(g.mesaj.hasSuffix("Sıradaki parça başlıyor…"))
            } else {
                XCTAssertEqual(g.mesaj, s.mesaj, ad)
            }
        }
    }

    func testParcaBitisi() {
        let p = CevrimdisiListe.Parca(urller: ["a", "b"], parca: 1, parcaSayisi: 3, onceden: 0, oncedenBayt: 0, hepsi: 6, sonParca: false)
        var i = CevrimdisiDurumu(p)
        i.biten = 2
        i.bitir(durduruldu: false)
        XCTAssertTrue(i.parcaBitti)
        var j = CevrimdisiDurumu(p)
        j.biten = 2; j.hata = 2
        j.bitir(durduruldu: false)
        XCTAssertTrue(j.inemedi)
        XCTAssertFalse(j.parcaBitti)
        var k = CevrimdisiDurumu(p)
        k.bitir(durduruldu: true)
        XCTAssertFalse(k.parcaBitti)
        XCTAssertTrue(k.durduruldu)
    }

    func testGb() {
        XCTAssertEqual(CevrimdisiGorunum.gb(21_026_536_790), "21,0")
        XCTAssertEqual(CevrimdisiGorunum.gb(660_000_000), "0,7")
        XCTAssertEqual(CevrimdisiGorunum.gb(0), "0,0")
        XCTAssertEqual(CevrimdisiGorunum.gb(1_234_560_000_000), "1.234,6")
    }

    func testDepo() async throws {
        let k = FileManager.default.temporaryDirectory.appendingPathComponent("cevrimdisi-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: k) }
        let depo = CevrimdisiDepo(klasor: k)
        let d = "https://gorsel.noracloud.ai/d/e0694234ff2368ba-49ea0ad0.jpg"
        let kk = "https://sanat-atlasi.pages.dev/gorseller/k/0123456789abcdef.jpg"
        XCTAssertEqual(CevrimdisiDepo.dosyaAdi(d), "d-e0694234ff2368ba-49ea0ad0.jpg")
        XCTAssertEqual(CevrimdisiDepo.dosyaAdi(kk), "k-0123456789abcdef.jpg")
        XCTAssertNil(CevrimdisiDepo.dosyaAdi("https://upload.wikimedia.org/x.jpg"))
        XCTAssertNil(depo.veri(d))
        try depo.yaz(Data([1, 2, 3]), adres: d)
        try depo.yaz(Data([4]), adres: kk)
        XCTAssertEqual(depo.veri(d), Data([1, 2, 3]))
        XCTAssertTrue(depo.varMi(kk))
        // GorselDeposu önce buraya bakar (indirmeden)
        let gd = GorselDeposu(klasor: k.appendingPathComponent("onbellek"), indirici: { _ in throw URLError(.notConnectedToInternet) },
                              cevrimdisi: depo)
        let v = try await gd.veri(URL(string: d)!)
        XCTAssertEqual(v, Data([1, 2, 3]))
        XCTAssertEqual(gd.diskte(URL(string: kk)!), Data([4]))
        // Listede olmayan az sayıda dosya silinir
        let sayim = depo.telefondakiler([d])
        XCTAssertEqual(sayim.adresler, [d])
        XCTAssertEqual(sayim.silinen, 1)
        XCTAssertFalse(depo.varMi(kk))
        depo.temizle()
        XCTAssertFalse(depo.varMi(d))
    }

    func testListeDisindakilerCoksaKorunur() throws {
        let k = FileManager.default.temporaryDirectory.appendingPathComponent("cevrimdisi-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: k) }
        let depo = CevrimdisiDepo(klasor: k)
        let adres = { (i: Int) in "https://x/d/\(String(format: "%016x", i)).jpg" }
        for i in 0..<30 { try depo.yaz(Data([1]), adres: adres(i)) }
        // 30 dosyadan 25'i listede değil: liste yanlış hesaplanmış olabilir, silinmez
        let s = depo.telefondakiler((0..<5).map(adres))
        XCTAssertEqual(s.adresler.count, 5)
        XCTAssertEqual(s.korundu, 25)
        XCTAssertEqual(depo.adlar().count, 30)
    }
}

/// Z3s: `tahminiBayt`'ın düzenli ifadesiz denetimi (`/d/[0-9a-f]`, `/k/[0-9a-f]`) eskisiyle aynı
final class KlasordeTests: XCTestCase {
    func testEskiDuzenliIfadeyleAyni() {
        let ornekler = ["https://gorsel.noracloud.ai/d/0a1b2c3d4e5f.jpg", "https://x/d/A12.jpg", "https://x/d/z1.jpg",
                        "https://x/k/9f.jpg", "https://x/b/0a.jpg", "/d/0", "/d/", "d/0", "https://x/ad/0", "https://x/dd/0",
                        "gorseller/k/abc.jpg", "", "/k/f", "/k/g", "https://x/y/d/e"]
        for u in ornekler {
            for h in ["d", "k"] {
                let eski = u.range(of: "/\(h)/[0-9a-f]", options: .regularExpression) != nil
                XCTAssertEqual(CevrimdisiListe.klasorde(u, Character(h)), eski, "\(h) \(u)")
            }
        }
    }
}


// Kaynak: sanat-atlasi js/{arama,akim,ikonografi,basyapit,birlesme}.js @ a866b86
import Foundation
import XCTest
@testable import NoraCekirdek

final class GaleriTests: XCTestCase {
    private struct Salon: Decodable {
        let ad, yy, cerceve: String
        let konular: [String]
        let kapak: String?
        let dortlu: [String]
    }
    private struct Arama: Decodable {
        let sorgu, normal: String
        let sayilar: [String: Int]
        let gruplar: [String: [String]]
    }
    private struct Cevaplar: Decodable {
        let salonlar: [Salon]
        let aramalar: [Arama]
        let islenen: [Int]
        let ek, koleksiyon: [String]
        let bilgi: [String: [String: String]]
        let kirpSonuc: [String: [String: [String]]]
        let kapaklar, adlar: [String: String]
        let oz, baglar: [String: [String]]
    }

    func testSiteninGaleriCevaplari() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/galeri/cevaplar", withExtension: "json"))
        let veri = try Data(contentsOf: url)
        let c = try JSONDecoder().decode(Cevaplar.self, from: veri)
        let ham = try JSONDeger.coz(veri)
        var dosyalar: [String: Data] = [:]
        for (dosya, alan) in [("akim_bilgi.json", "bilgiGirdi"), ("akim_ozellikleri.json", "ozGirdi"), ("basyapitlar.json", "basGirdi"), ("tanima_kirpimlari.json", "kirpGirdi")] {
            dosyalar[dosya] = Data(try XCTUnwrap(ham[alan]).jsonMetni.utf8)
        }
        let konuURL = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/goruntuleyici/ikonografi", withExtension: "json"))
        dosyalar["ikonografi.json"] = try Data(contentsOf: konuURL)
        let (_, katalog) = try XCTUnwrap(SiteVerisiTests.hazir)
        let g = try GaleriKatalogu(katalog: katalog, dosyalar: dosyalar)
        var il = try Ilerleme(veri: Data("{}".utf8))
        il.islenen = c.islenen
        il.ekSanatcilar = c.ek
        il[alan: "koleksiyon"] = ham["kayitlar"]
        XCTAssertEqual(g.koleksiyon(il).map(\.anahtar), c.koleksiyon)
        XCTAssertEqual(g.bilgi, c.bilgi)
        XCTAssertEqual(g.ozellikler, c.oz)
        XCTAssertEqual(Set(g.konular.map(\.id)), Set(c.baglar.keys))
        for k in g.konular {
            let eserler = g.konuEserleri(k)
            XCTAssertEqual(eserler.map(\.anahtar), c.baglar[k.id], k.ad)
            XCTAssertEqual(g.konuKapagi(eserler)?.anahtar ?? "", c.kapaklar[k.id], k.ad)
        }
        for (tur, bolum) in [("konular", g.konuKirpimlari), ("sanatcilar", g.sanatciKirpimlari)] {
            let eslesen = bolum.mapValues { kirpimlar in
                kirpimlar.map { k in k.eser(g.eserler[k.sanatci] ?? [], katalog: katalog, il: il)?.anahtar ?? "" }
            }
            XCTAssertEqual(eslesen, c.kirpSonuc[tur])
        }
        let kirpim = try XCTUnwrap(TanimaKirpimi(try XCTUnwrap(ham["ornek"])))
        for x in try XCTUnwrap(ham["incelemeler"]?.dizi) {
            let kayit = x["kayit"].flatMap(AyrintiKaydi.init(json:))
            let cikti = kirpim.inceleme(kayit, aciklama: "Açıklama")
            XCTAssertEqual(cikti.noktalar.first?.ad, x["ilk"]?["ad"]?.metin)
            XCTAssertEqual(cikti.noktalar.first?.metin, x["ilk"]?["metin"]?.metin)
            XCTAssertEqual(cikti.noktalar.count, x["adet"]?.tamSayi)
        }
        for (i, x) in (ham["salinim"]?.dizi ?? []).enumerated() {
            var tablo = AsiliTablo(sira: i)
            XCTAssertEqual(tablo.egim, x["egim"]?.sayi)
            XCTAssertEqual(tablo.ip, x["ip"]?.sayi)
            var donus = 0.0
            for adim in try XCTUnwrap(x["adimlar"]?.dizi) {
                donus = AsiliTablo.donus(donus, dereceHizi: try XCTUnwrap(adim["hiz"]?.sayi), dt: 1/30)
                tablo.adim(donus: donus, dt: 1/30)
                XCTAssertEqual(donus, try XCTUnwrap(adim["x"]?.sayi), accuracy: 1e-9)
                XCTAssertEqual(tablo.aci, try XCTUnwrap(adim["aci"]?.sayi), accuracy: 1e-9)
                XCTAssertEqual(tablo.hiz, try XCTUnwrap(adim["v"]?.sayi), accuracy: 1e-9)
            }
        }
        for (ad, soz) in c.adlar { XCTAssertEqual(GaleriKatalogu.okunacakAd(ad), soz) }
        for x in ham["sesler"]?.dizi ?? [] {
            XCTAssertEqual(GaleriKatalogu.sesUzantisi(x["k"]), x["url"]?.metin.map { ($0 as NSString).pathExtension })
        }
        for salon in c.salonlar {
            XCTAssertEqual(GaleriSergisi.yuzyillar(katalog.sanatcilar.filter { $0.akim == salon.ad }), salon.yy)
            XCTAssertEqual(GaleriSergisi.cerceve(salon.ad), salon.cerceve)
            XCTAssertEqual(g.tipikKonular(salon.ad, il).map(\.id), salon.konular)
            XCTAssertEqual(g.carkKapagi(salon.ad, il)?.anahtar, salon.kapak, salon.ad)
            XCTAssertEqual(g.dortlu(salon.ad, il).map(\.anahtar), salon.dortlu, salon.ad)
        }
        let dizin = g.dizin(il)
        for a in c.aramalar {
            XCTAssertEqual(GaleriAramasi.normallestir(a.sorgu), a.normal)
            let sonuc = GaleriAramasi.ara(dizin, sorgu: a.sorgu)
            for tur in GaleriKaydi.Tur.allCases {
                let grup = sonuc.filter { $0.tur == tur }
                XCTAssertEqual(grup.count, a.sayilar[tur.rawValue], a.sorgu)
                let idler = grup.prefix(8).map { x in x.sanatci != nil && tur == .eser ? (x.sanatci ?? "") + "|" + x.anahtar : x.anahtar }
                XCTAssertEqual(idler, a.gruplar[tur.rawValue], a.sorgu)
            }
        }
    }
}

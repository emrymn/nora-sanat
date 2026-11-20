import Foundation
import XCTest
@testable import NoraCekirdek

/// T2 kâhini: beklenen değerler canlı siteden (sanat-atlasi.pages.dev) sitenin kendi modülleriyle, tohumlu rastgele
/// 200 ilerleme nesnesinde alındı (Testler/kahin/ilerleme.mjs).
final class IlerlemeKahinTests: XCTestCase {
    static let cevaplar: JSONDeger? = {
        guard let url = Bundle.module.url(forResource: "Ornekler/ilerleme/cevaplar.json", withExtension: nil),
              let d = try? Data(contentsOf: url) else { return nil }
        return try? JSONDeger.coz(d)
    }()

    func hazirla() throws -> (c: JSONDeger, vakalar: [JSONDeger], sanatcilar: [Sanatci], akimlar: [Akim]) {
        let c = try XCTUnwrap(Self.cevaplar, "örnek okunamadı")
        let sanatcilar = (c["sanatcilar"]?.dizi ?? []).map { s in
            Sanatci(json: .nesne([("id", s.dizi![0]), ("konu", s.dizi![1]), ("akim", s.dizi![2])]))
        }
        let akimlar = (c["akimlar"]?.dizi ?? []).map { a in Akim(json: .nesne([("ad", a.dizi![0]), ("sira", a.dizi![1])])) }
        let vakalar = try XCTUnwrap(c["vakalar"]?.dizi)
        XCTAssertEqual(vakalar.count, 200)
        XCTAssertGreaterThan(sanatcilar.count, 100)
        return (c, vakalar, sanatcilar, akimlar)
    }

    static func ilerleme(_ g: JSONDeger) throws -> Ilerleme {
        try Ilerleme(json: .nesne([
            ("islenen", g["islenen"]!), ("ekSanatcilar", g["ek"]!), ("skorlar", g["skorlar"]!),
            ("gecmis", g["gecmis"]!), ("karisanlar", g["karisanlar"]!), ("seviyeler", g["seviyeler"]!),
        ]))
    }

    static func skor(_ j: JSONDeger?) -> Skor? { Skor(json: j) }

    func testAraliklar() throws {
        let (c, _, _, _) = try hazirla()
        XCTAssertEqual(c["aralikler"]?.dizi?.compactMap(\.tamSayi), Leitner.araliklar)
        for x in c["tekrarAraligi"]?.dizi ?? [] {
            XCTAssertEqual(Leitner.tekrarAraligi(x.dizi![0].sayi!), x.dizi![1].tamSayi, "\(x)")
        }
    }

    func testVadeVeGelecekYuk() throws {
        let (_, vakalar, sanatcilar, _) = try hazirla()
        for (i, v) in vakalar.enumerated() {
            let g = v["girdi"]!
            let il = try Self.ilerleme(g)
            let bugun = g["bugun"]!.metin!
            let ids = g["skorlar"]!.nesne!.anahtarlar
            let acik = il.acikSanatcilar(sanatcilar).map(\.id)
            XCTAssertEqual(acik, v["acik"]!.dizi!.compactMap(\.metin), "vaka \(i) açık")
            XCTAssertEqual(Gecmis.vadeSayisi(il.skorlar, idler: ids, tarih: bugun), v["vadeSayisi"]!.tamSayi, "vaka \(i)")
            XCTAssertEqual(il.vadeSayisi(sanatcilar, tarih: bugun), v["vadeSayisiAcik"]!.tamSayi, "vaka \(i)")
            XCTAssertEqual(Gecmis.yarinVade(il.skorlar, idler: ids, bugun: bugun), v["yarinVade"]!.tamSayi, "vaka \(i)")
            XCTAssertEqual(Gecmis.gelecekYuk(il.skorlar, idler: ids, bugun: bugun), v["gelecekYuk"]!.dizi!.compactMap(\.tamSayi), "vaka \(i)")
            XCTAssertEqual(Gecmis.gelecekYuk(il.skorlar, idler: acik, bugun: bugun), v["gelecekYukAcik"]!.dizi!.compactMap(\.tamSayi), "vaka \(i)")
            XCTAssertEqual(ids.prefix(6).map { Ogrenme.tanismaGerekir(il.skorlar[$0]) }, v["tanisma"]!.dizi!.compactMap(\.mantik), "vaka \(i)")
        }
    }

    func testCevapla() throws {
        let (_, vakalar, _, _) = try hazirla()
        var n = 0
        for (i, v) in vakalar.enumerated() {
            let bugun = v["girdi"]!["bugun"]!.metin!
            for k in v["skorlar"]!.dizi! {
                let s = Self.skor(k["skor"])
                let yer = "vaka \(i) \(k.jsonMetni)"
                XCTAssertEqual(Leitner.cevapla(s, dogru: k["dogruMu"]!.mantik!, bugun: bugun), Self.skor(k["sonuc"]), yer)
                XCTAssertEqual(Leitner.zayif(s), k["zayif"]!.mantik, yer)
                XCTAssertEqual(Leitner.vadesiGeldi(s, bugun), k["vadeli"]!.mantik, yer)
                XCTAssertEqual(Leitner.goruldu(s), k["goruldu"]!.mantik, yer)
                n += 1
            }
        }
        XCTAssertGreaterThan(n, 1000)
    }

    func testGecmis() throws {
        let (_, vakalar, _, _) = try hazirla()
        for (i, v) in vakalar.enumerated() {
            let g = v["girdi"]!
            let bugun = g["bugun"]!.metin!
            let gd = Gecmis.dogrula(g["gecmis"])
            let beklenen = Gecmis.dogrula(v["gecmisDogru"])   // zaten doğrulanmış: kendisini verir
            XCTAssertEqual(gd, beklenen, "vaka \(i)")
            XCTAssertEqual(gd.count, v["gecmisDogru"]!.nesne!.count, "vaka \(i)")
            XCTAssertEqual(Gecmis.seri(gd, bugun: bugun), v["seri"]!.tamSayi, "vaka \(i)")
            let t = Gecmis.takvim(gd, bugun: bugun, hafta: 4)
            let bt = v["takvim"]!.dizi!
            XCTAssertEqual(t.count, bt.count)
            for (a, b) in zip(t, bt) {
                XCTAssertEqual(a.tarih, b["tarih"]?.metin, "vaka \(i)")
                XCTAssertEqual(a.kart, b["kart"]?.tamSayi, "vaka \(i) \(a.tarih)")
                XCTAssertEqual(a.dogru, b["dogru"]?.tamSayi, "vaka \(i) \(a.tarih)")
                XCTAssertEqual(a.akim, b["akim"]?.metin, "vaka \(i) \(a.tarih)")
                XCTAssertEqual(a.gelecek, b["gelecek"]?.mantik, "vaka \(i) \(a.tarih)")
            }
            for (a, b) in zip(Gecmis.haftalikOran(gd, bugun: bugun, hafta: 4), v["haftalik"]!.dizi!) {
                XCTAssertEqual(a.bas, b["bas"]?.metin)
                XCTAssertEqual(a.kart, b["kart"]?.tamSayi)
                XCTAssertEqual(a.dogru, b["dogru"]?.tamSayi)
                XCTAssertEqual(a.oran, b["oran"]?.sayi, "vaka \(i)")
            }
        }
    }

    func testKilit() throws {
        let (_, vakalar, sanatcilar, akimlar) = try hazirla()
        for (i, v) in vakalar.enumerated() {
            let g = v["girdi"]!
            let once = Set(g["islenen"]!.dizi!.compactMap(\.tamSayi))
            let sonra = Set(g["islenen2"]!.dizi!.compactMap(\.tamSayi))
            XCTAssertEqual(Kilit.yeniAcilanlar(sanatcilar, once: once, sonra: sonra).map(\.id),
                           v["yeniAcilan"]!.dizi!.compactMap(\.metin), "vaka \(i)")
            let d = Kilit.akimDurumlari(akimlar, sanatcilar, islenen: once)
            let b = v["akimDurumlari"]!.dizi!
            XCTAssertEqual(d.count, b.count)
            for (x, y) in zip(d, b) {
                XCTAssertEqual(x.ad, y["ad"]?.metin)
                XCTAssertEqual(x.toplam, y["toplam"]?.tamSayi, "vaka \(i) \(x.ad)")
                XCTAssertEqual(x.acikSayisi, y["acikSayisi"]?.tamSayi, "vaka \(i) \(x.ad)")
                XCTAssertEqual(x.acik, y["acik"]?.mantik, "vaka \(i) \(x.ad)")
                XCTAssertEqual(x.acilacagiKonu, y["acilacagiKonu"]?.tamSayi, "vaka \(i) \(x.ad)")
            }
        }
    }

    func testKarisanlar() throws {
        let (_, vakalar, _, _) = try hazirla()
        for (i, v) in vakalar.enumerated() {
            let sirali = Ogrenme.dogrulaSirali(v["girdi"]!["karisanlar"])
            let b = v["karisanDogru"]!.nesne!
            XCTAssertEqual(sirali.map(\.anahtar), b.anahtarlar, "vaka \(i)")
            XCTAssertEqual(sirali.map(\.deger.n), b.ciftler.map { $0.deger["n"]!.tamSayi! }, "vaka \(i)")
            XCTAssertEqual(sirali.map(\.deger.son), b.ciftler.map { $0.deger["son"]!.metin! }, "vaka \(i)")
            let enCok = Ogrenme.enCok(sirali, adet: 3)
            let be = v["enCokKarisan"]!.dizi!
            XCTAssertEqual(enCok.map { "\($0.a)|\($0.b)|\($0.n)|\($0.son)" },
                           be.map { "\($0["a"]!.metin!)|\($0["b"]!.metin!)|\($0["n"]!.tamSayi!)|\($0["son"]!.metin!)" }, "vaka \(i)")
        }
    }

    func testSeviyeler() throws {
        let (_, vakalar, _, _) = try hazirla()
        var gecen = 0
        for (i, v) in vakalar.enumerated() {
            let dogru = Seviye.dogrula(v["girdi"]!["seviyeler"])
            XCTAssertEqual(dogru, Seviye.dogrula(v["seviyeDogru"]), "vaka \(i)")
            XCTAssertEqual(dogru.count, v["seviyeDogru"]!.nesne!.count, "vaka \(i)")
            XCTAssertEqual(Seviye.birlestir(dogru), Seviye.dogrula(v["seviyeBirlesik"]), "vaka \(i)")
            for x in v["seviye"]!.dizi! {
                let k = Seviye.dogrula(.nesne([("a", x["kayit"]!)]))["a"]!
                let c: Seviye.Cevap = x["cevap"] == .mantik(true) ? .dogru : x["cevap"] == .mantik(false) ? .yanlis : .bilmiyorum
                let (y, gecti) = Seviye.cevapla(k, c)
                let yer = "vaka \(i) \(x.jsonMetni)"
                XCTAssertEqual(y, Seviye.dogrula(.nesne([("a", x["sonuc"]!["kayit"]!)]))["a"], yer)
                XCTAssertEqual(gecti, x["sonuc"]!["gecti"]!.mantik, yer)
                XCTAssertEqual(Seviye.durum(k), x["durum"]!.metin, yer)
                XCTAssertEqual(Seviye.kisa(k), x["kisa"]!.metin, yer)
                XCTAssertEqual(Seviye.usta(k), x["usta"]!.mantik, yer)
                XCTAssertEqual(Seviye.oran(k.son), x["oran"]!.sayi!, accuracy: 1e-12, yer)
                if gecti { gecen += 1 }
            }
        }
        XCTAssertGreaterThan(gecen, 10)
    }

    /// Siteye yazılacak JSON, sitenin aynı işlemlerden sonra yazacağıyla birebir aynı (bilinmeyen alanlar, sıra, biçim)
    func testYazmaSitedekiyleAyni() throws {
        let (c, _, _, _) = try hazirla()
        let once = try XCTUnwrap(c["yazma"]?["once"]?.metin)
        let sonra = try XCTUnwrap(c["yazma"]?["sonra"]?.metin)
        var il = try Ilerleme(veri: Data(once.utf8))
        XCTAssertEqual(il.jsonMetni, once, "değiştirmeden okuyup yazmak aynı metni vermeli")
        let bugun = "2026-11-20"
        il.gunlukGuncelle(bugun: bugun)
        var sk = il.skorlar
        sk["giotto-di-bondone", default: SkorKaydi()].sanatci = Leitner.cevapla(sk["giotto-di-bondone"]?.sanatci, dogru: true, bugun: bugun)
        sk["masaccio"]!.sanatci = Leitner.cevapla(sk["masaccio"]!.sanatci, dogru: true, bugun: bugun)
        sk["masaccio"]!.akim = Leitner.cevapla(sk["masaccio"]!.akim, dogru: false, bugun: bugun)
        il.skorlar = sk
        il.gecmisEkle(tarih: bugun, dogru: true, akim: "Gotik")
        il.gecmisEkle(tarih: "2026-11-19", dogru: false, akim: "Barok")
        il.sonCalisilanEkle("giotto-di-bondone")
        var sv = il.seviyeler
        Seviye.isle(&sv, akim: "Gotik", .dogru)
        il.seviyeler = sv
        var kr = il.karisanlar
        Ogrenme.ekle(&kr, dogruId: "giotto-di-bondone", secilenId: "cimabue", tarih: bugun)
        il.karisanlar = kr
        il.islenen = il.islenen + [9, 2]
        XCTAssertEqual(il.jsonMetni, sonra)
    }
}

final class IlerlemeModelTests: XCTestCase {
    func testBilinmeyenAlanlarKorunur() throws {
        let metin = #"{"surum":2,"yeniAlan":{"a":[1,2.5,"x"]},"skorlar":{"s1":{"sanatci":{"kutu":2,"sonraki":"2026-11-22","dogru":3,"yanlis":0,"son":"2026-11-19","ek":true},"akimGibi":1}},"kayitNo":41}"#
        var il = try Ilerleme(veri: Data(metin.utf8))
        XCTAssertEqual(il.jsonMetni, metin)
        XCTAssertEqual(il.kayitNo, 41)
        var sk = il.skorlar
        sk["s1"]!.sanatci = Leitner.cevapla(sk["s1"]!.sanatci, dogru: true, bugun: "2026-11-22")
        il.skorlar = sk
        XCTAssertEqual(il.jsonMetni,
                       #"{"surum":2,"yeniAlan":{"a":[1,2.5,"x"]},"skorlar":{"s1":{"sanatci":{"kutu":3,"sonraki":"2026-11-29","dogru":4,"yanlis":0,"son":"2026-11-22","ek":true},"akimGibi":1}},"kayitNo":41}"#)
    }

    func testYedekBicimi() throws {
        let il = try Ilerleme(veri: Data(#"{"uygulama":"sanat-atlasi","ilerleme":{"islenen":[3,1]}}"#.utf8))
        XCTAssertEqual(il.islenen, [3, 1])
        XCTAssertThrowsError(try Ilerleme(veri: Data("[1]".utf8)))
    }

    func testSayiYazimi() {
        XCTAssertEqual(JSONDeger.sayiMetni(0.1), "0.1")
        XCTAssertEqual(JSONDeger.sayiMetni(-3), "-3")
        XCTAssertEqual(JSONDeger.sayiMetni(1e-7), "1e-7")
        XCTAssertEqual(JSONDeger.sayiMetni(-0.0), "0")
        XCTAssertEqual(JSONDeger.metin("a\u{1}\n\"").jsonMetni, #""a\u0001\n\"""#)
    }

    func testHaftaGunu() {
        XCTAssertEqual(Leitner.haftaGunu("2026-11-23"), 0)   // pazartesi
        XCTAssertEqual(Leitner.haftaGunu("2026-11-22"), 6)   // pazar
        XCTAssertEqual(Leitner.haftaGunu("1969-12-31"), 2)   // çarşamba
    }
}

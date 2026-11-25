import Foundation
import XCTest
@testable import NoraCekirdek

/// Z3x: Ayarlar'ın yeni kuralları. Yenilikler sitenin kendi modülüyle (Testler/kahin/yenilikler.mjs) sınanır; hatırlatma,
/// hata günlüğü ve çevrimdışı özeti yeni (sitede yok), davranış testi.
final class AyarlarTests: XCTestCase {
    // MARK: Yenilikler

    private func yenilikOrnekleri() throws -> (js: String, cevap: JSONDeger) {
        let js = try XCTUnwrap(Bundle.module.url(forResource: "yenilikler", withExtension: "js", subdirectory: "Ornekler/yenilikler"))
        let c = try XCTUnwrap(Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/yenilikler"))
        return (try String(contentsOf: js, encoding: .utf8), try JSONDeger.coz(Data(contentsOf: c)))
    }

    func testYeniliklerSitedekiyle() throws {
        let (js, c) = try yenilikOrnekleri()
        let liste = Yenilikler.coz(js)
        let beklenen = try XCTUnwrap(c["liste"]?.dizi).map { Yenilik(surum: $0["surum"]!.metin!, metin: $0["metin"]!.metin!) }
        XCTAssertEqual(liste.count, beklenen.count)
        XCTAssertGreaterThan(liste.count, 50)
        for (a, b) in zip(liste, beklenen) { XCTAssertEqual(a, b, b.surum) }
        let yazilar = try XCTUnwrap(c["yazilar"]?.dizi).compactMap(\.metin)
        XCTAssertEqual(liste.map(\.yazi), yazilar)
        for (ad, l) in [("gosterilecekler", liste), ("kucuk", [Yenilik(surum: "2.0.0", metin: "c"),
                                                              Yenilik(surum: "1.10.0", metin: "b"),
                                                              Yenilik(surum: "1.9.1", metin: "a")])] {
            for o in try XCTUnwrap(c[ad]?.dizi) {
                let son = o["son"]?.metin
                let sonuc = Yenilikler.gosterilecekler(sonGorulen: son, surum: o["surum"]!.metin!,
                                                       calismis: o["calismis"]?.dogruMu ?? false, liste: l)
                XCTAssertEqual(sonuc.map(\.surum), try XCTUnwrap(o["sonuc"]?.dizi).compactMap(\.metin),
                               "\(ad) \(son ?? "null") → \(o["surum"]!.metin!)")
            }
        }
    }

    func testYeniliklerOkuyucusu() {
        let js = """
        // "Yenilikler": YENILIKLER = yorumdaki ad aranmaz
        export const YENILIKLER = [
          { surum: '2.0.0', metin: 'Tek \\'tırnak\\' ve satır\\nsonu', yeni: true },
          { "surum": "1.9.0", "metin": "Çift tırnak: [köşeli] {süslü} // yorum değil" },
          { surum: `1.8.1`, metin: `Ters tırnak \\u00e7` },
          { surum: '1.8.0' },
        ];
        export function yeniMi() {}
        """
        XCTAssertEqual(Yenilikler.coz(js), [
            Yenilik(surum: "2.0.0", metin: "Tek 'tırnak' ve satır\nsonu"),
            Yenilik(surum: "1.9.0", metin: "Çift tırnak: [köşeli] {süslü} // yorum değil"),
            Yenilik(surum: "1.8.1", metin: "Ters tırnak ç"),
        ])
        XCTAssertEqual(Yenilikler.coz("export const BASKA = [];"), [])
        XCTAssertEqual(Yenilik(surum: "1.90.0", metin: "x").yazi, "1.90 · x")
        XCTAssertEqual(Yenilik(surum: "1.90.3", metin: "x").yazi, "1.90.3 · x")
        XCTAssertTrue(Yenilikler.yeniMi("1.10.0", "1.9.9"))
        XCTAssertFalse(Yenilikler.yeniMi("1.9.0", "1.9"))
        XCTAssertFalse(Yenilikler.yeniMi("1.9.0", "1.9.0"))
    }

    // MARK: Hatırlatma

    func testHatirlatmaAyariSettingsBundleIleAyni() throws {
        XCTAssertEqual(HatirlatmaAyari.acikAnahtari, "hatirlatma")
        XCTAssertEqual(HatirlatmaAyari.saatAnahtari, "hatirlatmaSaati")
        XCTAssertEqual(HatirlatmaAyari.saatler.count, 17)
        XCTAssertEqual(HatirlatmaAyari.saat(nil), 20)
        XCTAssertEqual(HatirlatmaAyari.saat(0), 7)
        XCTAssertEqual(HatirlatmaAyari.saat(6), 7)
        XCTAssertEqual(HatirlatmaAyari.saat(13), 13)
        XCTAssertEqual(HatirlatmaAyari.saat(24), 23)
        XCTAssertEqual(HatirlatmaAyari.yazi(7), "07:00")
        XCTAssertEqual(HatirlatmaAyari.yazi(20), "20:00")
        XCTAssertEqual(HatirlatmaAyari.saatAltYazisi, "07:00 – 23:00 arası")
        XCTAssertEqual(HatirlatmaAyari.dipnot(acik: true, rozet: false, izin: .yok).prefix(19), "Bildirim izni kapal")
        XCTAssertTrue(HatirlatmaAyari.dipnot(acik: false, rozet: false, izin: .yok).hasPrefix("O gün"))
        XCTAssertTrue(HatirlatmaAyari.dipnot(acik: true, rozet: true, izin: .var_).hasPrefix("O gün"))

        // Settings.bundle'daki değerlerle aynı mı (depo kökünden; paket başka yerden derlenirse atlanır)
        let kok = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let plist = kok.appendingPathComponent("NoraSanat/Settings.bundle/Root.plist")
        guard let veri = try? Data(contentsOf: plist) else { throw XCTSkip("Settings.bundle yok: \(plist.path)") }
        let kokNesne = try PropertyListSerialization.propertyList(from: veri, format: nil) as? [String: Any]
        let ogeler = try XCTUnwrap(kokNesne?["PreferenceSpecifiers"] as? [[String: Any]])
        let ac = try XCTUnwrap(ogeler.first { $0["Key"] as? String == HatirlatmaAyari.acikAnahtari })
        XCTAssertEqual(ac["DefaultValue"] as? Bool, HatirlatmaAyari.varsayilanAcik)
        let saat = try XCTUnwrap(ogeler.first { $0["Key"] as? String == HatirlatmaAyari.saatAnahtari })
        XCTAssertEqual(saat["DefaultValue"] as? Int, HatirlatmaAyari.varsayilanSaat)
        XCTAssertEqual(saat["Values"] as? [Int], HatirlatmaAyari.saatler)
        XCTAssertEqual(saat["Titles"] as? [String], HatirlatmaAyari.saatler.map(HatirlatmaAyari.yazi))
    }

    // MARK: Yazılar

    func testAyarYazilari() {
        XCTAssertEqual(AyarYazilari.tarih("2026-11-22", bugun: "2026-11-25"), "22 Kasım")
        XCTAssertEqual(AyarYazilari.tarih("2026-11-25", bugun: "2026-11-25"), "bugün")
        XCTAssertEqual(AyarYazilari.tarih("2025-01-03", bugun: "2026-11-25"), "3 Ocak 2025")
        XCTAssertEqual(AyarYazilari.tarih("dün", bugun: "2026-11-25"), "dün")
        XCTAssertEqual(AyarYazilari.sonYedek(nil, bugun: "2026-11-25"), "Henüz yedek alınmadı")
        XCTAssertEqual(AyarYazilari.sonYedek("2026-11-22", bugun: "2026-11-25"), "Son yedek: 22 Kasım")
        XCTAssertEqual(AyarYazilari.onizlemeDurumu(tema: "gece", gunduzRenk: "lapis", yazi: nil), "Gece · Standart")
        XCTAssertEqual(AyarYazilari.onizlemeDurumu(tema: "gunduz", gunduzRenk: nil, yazi: "buyuk"), "Günün resmi · Büyük")
        XCTAssertEqual(AyarYazilari.onizlemeDurumu(tema: "gunduz", gunduzRenk: "bakir", yazi: "standart"), "Bakır yeşili · Standart")
        XCTAssertEqual(AyarYazilari.hareketAdi("sade"), "Sade")
        XCTAssertEqual(AyarYazilari.hareketAdi(nil), "Tam")
        // Gündüz renkleri sitenin sırası ve adlarıyla (Günün resmi = otomatik)
        XCTAssertEqual(AyarYazilari.gunduzRenkleri.map { $0.deger }, ["otomatik", "lapis", "pompei", "bakir", "safran", "notr"])
        XCTAssertEqual(AyarYazilari.gunduzRenkleri.map { $0.ad }, ["Günün resmi", "Lapis", "Pompei", "Bakır yeşili", "Safran", "Nötr kâğıt"])
    }

    // MARK: Hata günlüğü

    func testHataGunlugu() throws {
        var g = HataGunlugu()
        XCTAssertEqual(g.ozet, "Kayıt yok")
        g.ekle(HataKaydi(t: "1", yer: "ayarlar", metin: "  "))
        XCTAssertTrue(g.kayitlar.isEmpty)
        g.ekle(HataKaydi(t: "1", yer: "ayarlar", metin: "Bağlantı yok\n"))
        g.ekle(HataKaydi(t: "2", yer: "ayarlar", metin: "Bağlantı yok"))
        XCTAssertEqual(g.kayitlar, [HataKaydi(t: "2", yer: "ayarlar", metin: "Bağlantı yok")])
        g.ekle(HataKaydi(t: "3", yer: "cevrimdisi", metin: "Yer yok"))
        XCTAssertEqual(g.kayitlar.map(\.t), ["3", "2"])
        XCTAssertEqual(g.ozet, "2 kayıt · son: Yer yok")
        for i in 0..<80 { g.ekle(HataKaydi(t: "\(i)", yer: "x", metin: "h\(i)")) }
        XCTAssertEqual(g.kayitlar.count, HataGunlugu.enCok)
        XCTAssertEqual(g.kayitlar.first?.metin, "h79")
        let j = try JSONDeger.coz(Data(g.metin.utf8))
        XCTAssertEqual(j["tur"]?.metin, "hata-gunlugu")
        XCTAssertEqual(j["kayitlar"]?.dizi?.count, HataGunlugu.enCok)
        let geri = try JSONDecoder().decode(HataGunlugu.self, from: JSONEncoder().encode(g))
        XCTAssertEqual(geri, g)
        g.temizle()
        XCTAssertTrue(g.kayitlar.isEmpty)
    }

    // MARK: Çevrimdışı özeti

    func testCevrimdisiOzeti() throws {
        let (_, l) = try XCTUnwrap(CevrimdisiTests.hazir, "örnekler okunamadı")
        let hepsi = l.telefonAdresleri.count
        XCTAssertGreaterThan(hepsi, 1000)
        let bos = CevrimdisiOzeti(liste: l, telefonda: 0, durum: nil)
        XCTAssertEqual(bos.yuzde, 0)
        XCTAssertFalse(bos.tamam)
        XCTAssertTrue(bos.altYazi.hasPrefix("0 / \(CevrimdisiOzeti.binlik(hepsi)) görsel"), bos.altYazi)
        if l.toplamBayt > 0 { XCTAssertTrue(bos.altYazi.hasSuffix(" GB"), bos.altYazi) }

        let neredeyse = CevrimdisiOzeti(liste: l, telefonda: hepsi - 1, durum: nil)
        XCTAssertEqual(neredeyse.yuzde, 99)
        let tam = CevrimdisiOzeti(liste: l, telefonda: hepsi + 5, durum: nil)
        XCTAssertEqual(tam.telefonda, hepsi)
        XCTAssertEqual(tam.yuzde, 100)
        XCTAssertTrue(tam.tamam)
        XCTAssertEqual(tam.bayt, l.toplamBayt, accuracy: 1)

        // Sürerken: önceden 100 + parçada inen 40 (5'i hatalı)
        var i = CevrimdisiDurumu(CevrimdisiListe.Parca(urller: Array(repeating: "", count: 200), parca: 2, parcaSayisi: 9,
                                                        onceden: 100, oncedenBayt: 3e8, hepsi: hepsi, sonParca: false))
        i.biten = 40; i.hata = 5; i.bitenBayt = 1e8
        let suren = CevrimdisiOzeti(liste: l, telefonda: 100, durum: i)
        XCTAssertEqual(suren.telefonda, 135)
        if l.toplamBayt > 4e8 { XCTAssertEqual(suren.bayt, 4e8, accuracy: 1) }
        XCTAssertEqual(suren.yuzde, Int((Double(135) / Double(hepsi) * 100).rounded(.down)))

        XCTAssertEqual(CevrimdisiOzeti.binlik(812), "812")
        XCTAssertEqual(CevrimdisiOzeti.binlik(1420), "1.420")
        XCTAssertEqual(CevrimdisiOzeti.binlik(1234567), "1.234.567")
    }
}

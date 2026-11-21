// C1c: pekiştirme turunda tanışma, başka eser, atlanan kart, cevap yaprağı bilgileri; TurKaydi uçtan uca.
// Örnekler `Testler/kahin/pekistir_tanisma.mjs` ile canlı sitenin kendi modüllerinden alındı (sanat-atlasi @ a866b86):
// 60 rastgele ilerleme × tur (karışık, dönem, hepsi, konu, hatalar), her turda en çok 10 kart.
import XCTest
@testable import NoraCekirdek

final class PekistirTanismaTests: XCTestCase {
    struct Ornekler: Decodable {
        let bugun: String
        let durumlar: [Durum]
    }
    struct Durum: Decodable {
        struct Tur: Decodable { let kip: String; let akim: String?; let seciliSeviye: Int? }
        struct Kart: Decodable {
            let id: String
            let eser: String?
            let seviye: Int?
            let secenekler: [String]?
            let akim: [String]?
            let ters: [[String]]?
            let tanisma: [String]?
        }
        struct Cevap: Decodable { let s: String?; let a: String? }
        struct SeviyeSonuc: Decodable { let isinma: Bool; let once: Int; let sonra: Int; let gecti: Bool }
        struct Adim: Decodable {
            let konum: Int
            let toplam: Int
            let kart: Kart
            let baska: String?
            let cevap: Cevap?
            let karisan: Int?
            let seviye: SeviyeSonuc?
            let kuyruk: [String]?
        }
        struct Tanisma: Decodable { let id: String; let eserler: [String] }
        struct Gecen: Decodable { let akim: String; let seviye: Int }
        let tur: Tur
        let ilerleme: String
        let tohum: Int
        let sayilar: Int
        let kolaylik: [String: Double]
        let konular: [String: String]
        let tanismalar: [Tanisma]
        let adimlar: [Adim]
        let gecenler: [Gecen]
        let sonra: [String: String]
    }

    func turu(_ t: Durum.Tur) throws -> PekistirmeTuru {
        switch t.kip {
        case "karisik": return .karisik
        case "donem": return .donem(t.akim == "hepsi" ? nil : t.akim)
        case "konu": return .konu(try XCTUnwrap(Int(t.akim ?? "")))
        default: return .hatalar
        }
    }

    func testSitedekiAkislaAyni() throws {
        let (_, k) = try XCTUnwrap(SiteVerisiTests.hazir, "katalog örnekleri okunamadı")
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/pekistir/tanisma", withExtension: "json"))
        let o = try JSONDecoder().decode(Ornekler.self, from: Data(contentsOf: url))
        XCTAssertEqual(o.durumlar.count, 60)
        var sayac = (kart: 0, tanisma: 0, konuTanisma: 0, baska: 0, atlanan: 0, gecen: 0)
        for (i, d) in o.durumlar.enumerated() {
            let yer = "durum \(i) (\(d.tur.kip) \(d.tur.akim ?? ""))"
            var il = try Ilerleme(veri: Data(d.ilerleme.utf8))
            let tur = try turu(d.tur)
            let r = SiteRastgelesi(d.tohum)
            let rastgele: PekistirmeRastgele = { r.sonraki() }
            let veri = PekistirmeVerileri(kolaylik: d.kolaylik, konuHaritasi: d.konular)
            var kayit = TurKaydi(kip: .sanatci(tur), seviye: d.tur.seciliSeviye, katalog: k, veri: veri, ilerleme: il,
                                 gun: o.bugun, rastgele: rastgele)
            kayit.hazirla(katalog: k, veri: veri, ilerleme: &il, rastgele: rastgele)

            // Konu turu: turdan önce tanışmalar
            var tanismalar: [Durum.Tanisma] = []
            while kayit.tanismaBekliyor, let t = kayit.tanisma, let id = t.simdiki {
                tanismalar.append(.init(id: id, eserler: t.gosterilen))
                XCTAssertNil(kayit.kart, "\(yer): tanışma sürerken kart yok")
                kayit.tanismaGec(katalog: k, veri: veri, ilerleme: &il, rastgele: rastgele)
            }
            XCTAssertEqual(tanismalar.map(\.id), d.tanismalar.map(\.id), "\(yer): tanışma sırası")
            XCTAssertEqual(tanismalar.map(\.eserler), d.tanismalar.map(\.eserler), "\(yer): tanışma eserleri")
            sayac.konuTanisma += tanismalar.count

            let gercek = d.adimlar.filter { $0.kart.eser != nil }
            for (n, adim) in d.adimlar.enumerated() {
                let yer = "\(yer) adım \(n)"
                guard let beklenenEser = adim.kart.eser else {
                    // Eseri bulunamayan kart: Swift hazirla'da geçti; sayaçta kalmalı
                    sayac.atlanan += 1
                    XCTAssertEqual(kayit.oturum.kuyruk.count, adim.toplam, "\(yer): atlanan kart sayaçta kalır")
                    continue
                }
                let kart = try XCTUnwrap(kayit.kart, "\(yer): kart yok")
                sayac.kart += 1
                XCTAssertEqual(kayit.oturum.konum, adim.konum, "\(yer): sıra")
                XCTAssertEqual(kayit.oturum.kuyruk.count, adim.toplam, "\(yer): toplam")
                XCTAssertEqual(kart.resim.id, adim.kart.id, "\(yer): sanatçı")
                XCTAssertEqual(kart.resim.eser.anahtar, beklenenEser, "\(yer): eser")
                XCTAssertEqual(kart.seviye, adim.kart.seviye, "\(yer): seviye")
                XCTAssertEqual(kart.ters == nil ? kart.secenekler : kart.ters?.map(\.id), adim.kart.secenekler, "\(yer): şıklar")
                XCTAssertEqual(kart.akimlar, adim.kart.akim, "\(yer): akım şıkları")
                XCTAssertEqual(kart.ters?.map { [$0.id, $0.eser.anahtar] }, adim.kart.ters, "\(yer): ters")
                XCTAssertEqual(kart.tanisma, adim.kart.tanisma, "\(yer): kart tanışması")
                if let tanisma = kart.tanisma {
                    sayac.tanisma += 1
                    XCTAssertFalse(tanisma.contains(beklenenEser), "\(yer): sorulan eser tanışmada görünmez")
                    kayit.tanismaGec(katalog: k, veri: veri, ilerleme: &il, rastgele: rastgele)
                    XCTAssertNil(kayit.kart?.tanisma, yer)
                }
                if let baska = adim.baska {
                    sayac.baska += 1
                    XCTAssertTrue(kayit.baskaEser(katalog: k, ilerleme: il, rastgele: rastgele), "\(yer): başka eser")
                    XCTAssertEqual(kayit.kart?.resim.eser.anahtar, baska, "\(yer): başka eser")
                }
                let c = try XCTUnwrap(adim.cevap, yer)
                kayit.cevapla(c.s, katalog: k, gun: o.bugun, ilerleme: &il, rastgele: rastgele)
                let yaprak = try XCTUnwrap(kayit.kart, yer)
                XCTAssertEqual(yaprak.karisan, adim.karisan, "\(yer): karıştırma sayısı")
                if let sv = adim.seviye {
                    XCTAssertEqual(yaprak.seviyeSonucu, SeviyeSonucu(isinma: sv.isinma, once: sv.once, sonra: sv.sonra, gecti: sv.gecti),
                                   "\(yer): seviye sonucu")
                }
                if yaprak.akimBekliyor {
                    kayit.sonraki(katalog: k, veri: veri, ilerleme: &il, rastgele: rastgele)
                    XCTAssertTrue(kayit.kart?.ikinci == true, yer)
                    kayit.cevapla(c.a, katalog: k, gun: o.bugun, ilerleme: &il, rastgele: rastgele)
                }
                XCTAssertEqual(kayit.oturum.kuyruk.map { $0.id + ($0.tekrar ? "*" : "") }, adim.kuyruk, "\(yer): kuyruk")
                XCTAssertEqual(kayit.gorunenKonum, adim.konum, "\(yer): cevaptan sonra sayaç aynı kartta")
                // Site 10. karttan sonra durur; Swift de sonrakini hazırlamamalı (rastgele sayılar)
                if adim.kart.eser != nil, sayac.kart > 0, gercek.last.map({ $0.konum == adim.konum }) == true { break }
                kayit.sonraki(katalog: k, veri: veri, ilerleme: &il, rastgele: rastgele)
            }
            XCTAssertEqual(kayit.gecenler?.map { "\($0.akim)>\($0.seviye)" } ?? [], d.gecenler.map { "\($0.akim)>\($0.seviye)" },
                           "\(yer): seviye atlayan dönemler")
            sayac.gecen += d.gecenler.count
            XCTAssertEqual(r.sayac, d.sayilar, "\(yer): çekilen rastgele sayı")
            for (alan, beklenen) in d.sonra.sorted(by: { $0.key < $1.key }) {
                XCTAssertEqual(il[alan: alan]?.jsonMetni ?? "null", beklenen, "\(yer): \(alan)")
            }
        }
        XCTAssertGreaterThan(sayac.kart, 300)
        XCTAssertGreaterThan(sayac.tanisma, 30)
        XCTAssertGreaterThan(sayac.konuTanisma, 5)
        XCTAssertGreaterThan(sayac.baska, 30)
        XCTAssertGreaterThan(sayac.atlanan, 0)
        XCTAssertGreaterThan(sayac.gecen, 5)
    }

    /// Ayarlardan kapatılınca (`ayarlar.tanisma === false`) ne kart ne konu tanışması.
    func testTanismaKapali() throws {
        let (_, k) = try XCTUnwrap(SiteVerisiTests.hazir)
        let veri = PekistirmeVerileri(ikonografi: nil, zorluk: nil)
        var il = try Ilerleme(veri: Data(#"{"ayarlar":{"tanisma":false}}"#.utf8))
        il.islenen = k.konular.map(\.no)
        for tur in [PekistirmeTuru.karisik, .konu(1)] {
            var kayit = TurKaydi(kip: .sanatci(tur), seviye: nil, katalog: k, veri: veri, ilerleme: il, gun: "2026-11-21")
            kayit.hazirla(katalog: k, veri: veri, ilerleme: &il)
            XCTAssertFalse(kayit.tanismaBekliyor)
            XCTAssertNotNil(kayit.kart)
            XCTAssertNil(kayit.kart?.tanisma)
        }
    }

    /// Dönem turunun seviye hapları: alt seviye seçilince cevaplanmamış kart yeniden hazırlanır, cevap ısınma sayılır.
    func testSeviyeHaplari() throws {
        let (_, k) = try XCTUnwrap(SiteVerisiTests.hazir)
        let veri = PekistirmeVerileri(ikonografi: nil, zorluk: nil)
        var il = try Ilerleme(veri: Data(#"{"ayarlar":{"tanisma":false}}"#.utf8))
        il.islenen = k.konular.map(\.no)
        let akim = try XCTUnwrap(il.acikSanatcilar(k.sanatcilar).first?.akim)
        var kayit = TurKaydi(kip: .sanatci(.donem(akim)), seviye: nil, katalog: k, veri: veri, ilerleme: il, gun: "2026-11-21")
        kayit.hazirla(katalog: k, veri: veri, ilerleme: &il)
        XCTAssertNil(kayit.seviyeHaplari(il), "Kolay'daki dönemde hap yok")
        var sv = il.seviyeler
        sv[akim] = SeviyeKaydi(s: 2, son: [])
        il.seviyeler = sv
        let haplar = try XCTUnwrap(kayit.seviyeHaplari(il))
        XCTAssertEqual(haplar.map(\.acik), [true, true, true])
        XCTAssertEqual(haplar.map(\.secili), [false, false, true])
        kayit.seviyeSec(0, katalog: k, veri: veri, ilerleme: &il)
        XCTAssertEqual(kayit.seviye, 0)
        XCTAssertEqual(kayit.kart?.seviye, 0)
        XCTAssertEqual(kayit.seviyeHaplari(il)?.map(\.isinma), [true, false, false])
        kayit.cevapla(kayit.kart?.dogru, katalog: k, gun: "2026-11-21", ilerleme: &il)
        XCTAssertEqual(kayit.kart?.seviyeSonucu?.isinma, true)
        XCTAssertEqual(il.seviyeler[akim], SeviyeKaydi(s: 2, son: []), "ısınma penceresine yazılmaz")
        kayit.seviyeSec(2, katalog: k, veri: veri, ilerleme: &il)
        XCTAssertNil(kayit.seviye, "dönemin kendi seviyesi seçilince nil")
    }

    /// Cevap yaprağının yazıları (js/ekranlar/pekistir.js'teki metinlerle aynı)
    func testCevapYazilari() {
        // akimiAciklarMi: akım adının 4+ harfli sözcüklerinin ilk beş harfi metinde geçiyor mu
        XCTAssertTrue(CevapYazilari.akimiAciklarMi("Erken Rönesans ustalarından", "Erken Rönesans"))
        XCTAssertTrue(CevapYazilari.akimiAciklarMi("İTALYAN RÖNESANSI", "Yüksek Rönesans"))
        XCTAssertFalse(CevapYazilari.akimiAciklarMi("Altın zemin, düz figürler", "Gotik"))
        XCTAssertTrue(CevapYazilari.akimiAciklarMi("gotik katedral", "Gotik"))
        XCTAssertFalse(CevapYazilari.akimiAciklarMi("ışık", "Barok (Flaman)"))
        XCTAssertTrue(CevapYazilari.akimiAciklarMi("flamanların", "Barok (Flaman)"))
        // kutuSatiri
        let gun = "2026-11-21"
        XCTAssertEqual(CevapYazilari.kutu(Skor(kutu: 0, sonraki: gun), bugun: gun)?.yazi, "Baştan · bu turda yine gelecek")
        let bir = CevapYazilari.kutu(Skor(kutu: 1, sonraki: "2026-11-22"), bugun: gun)
        XCTAssertEqual(bir?.yazi, "1. kutu · 1 gün sonra tekrar")
        XCTAssertEqual(bir?.ilerledi, true)
        let uc = CevapYazilari.kutu(Skor(kutu: 3, sonraki: "2026-11-21"), bugun: gun)
        XCTAssertEqual(uc?.yazi, "3. kutu · bugün tekrar")
        XCTAssertEqual(uc?.ilerledi, false)
        XCTAssertNil(CevapYazilari.kutu(nil, bugun: gun))
        // seviyeSatiri
        let kayit = SeviyeKaydi(s: 0, son: [1, 1, 0])
        XCTAssertEqual(CevapYazilari.seviyeSatiri(SeviyeSonucu(once: 0, sonra: 0, gecti: false), akim: "Gotik", kartSeviyesi: 0, kayit: kayit),
                       "Gotik · Kolay · son 3 cevapta 2 doğru · Orta için %80 (en az 2 cevap daha)")
        XCTAssertEqual(CevapYazilari.seviyeSatiri(SeviyeSonucu(once: 0, sonra: 1, gecti: true), akim: "Gotik", kartSeviyesi: 0, kayit: kayit),
                       "Gotik Orta seviyeye geçti")
        XCTAssertEqual(CevapYazilari.seviyeSatiri(SeviyeSonucu(isinma: true, once: 2, sonra: 2, gecti: false), akim: "Gotik", kartSeviyesi: 0, kayit: kayit),
                       "Isınma · Kolay · Gotik Zor penceresine yazılmadı")
        // sonuç satırları
        XCTAssertEqual(CevapYazilari.akimSonucu(akimDogru: true, sanatciDogru: false, bilmiyorum: false).1,
                       "sanatçı yanlıştı, bu kart 3–5 kart sonra yine gelecek")
        XCTAssertEqual(CevapYazilari.sonuc(dogru: false, bilmiyorum: true).0, "Bilmiyorum")
    }
}

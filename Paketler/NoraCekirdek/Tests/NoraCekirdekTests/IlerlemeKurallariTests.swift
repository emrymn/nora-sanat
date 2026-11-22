import Foundation
import XCTest
@testable import NoraCekirdek

/// Z2a: sitenin kayıt kuralları (js/depo.js) Swift'te. Örnekler: Testler/kahin/depo.mjs (sitenin kendi modülleri,
/// sabit saat 2026-11-22T10:00:00Z, UTC).
final class IlerlemeKurallariTests: XCTestCase {
    static let ornek: JSONDeger = {
        let url = Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/depo")!
        return try! JSONDeger.coz(Data(contentsOf: url))
    }()
    var simdi: String { Self.ornek["simdi"]!.metin! }
    var bugun: String { Self.ornek["bugun"]!.metin! }

    /// JS nesnelerinde anahtar sırası (tam sayı anahtarlar önce) farklı olabilir: yapıca eşitlik
    static func ayni(_ a: JSONDeger?, _ b: JSONDeger?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (.nesne(let x)?, .nesne(let y)?):
            return x.count == y.count && x.ciftler.allSatisfy { c in ayni(c.deger, y[c.anahtar]) }
        case (.dizi(let x)?, .dizi(let y)?):
            return x.count == y.count && zip(x, y).allSatisfy { ayni($0, $1) }
        case (.sayi(let x)?, .sayi(let y)?): return x == y
        default: return a == b
        }
    }

    func esit(_ a: JSONDeger?, _ b: JSONDeger?, _ m: @autoclosure () -> String, file: StaticString = #filePath, line: UInt = #line) {
        if !Self.ayni(a, b) {
            XCTFail("\(m())\nSwift: \(a?.jsonMetni ?? "nil")\nSite:  \(b?.jsonMetni ?? "nil")", file: file, line: line)
        }
    }

    func testVarsayilan() {
        let v = Self.ornek["varsayilan"]!.dizi!
        esit(.nesne(IlerlemeKurallari.varsayilan(bugun: bugun, simdi: simdi)), v[0], "varsayılan")
        esit(.nesne(IlerlemeKurallari.varsayilan(islenen: [.sayi(5), .sayi(1), .sayi(2)], bugun: bugun, simdi: simdi)), v[1], "varsayılan islenen")
    }

    func testDogrulama() {
        let vakalar = Self.ornek["vakalar"]!.dizi!
        XCTAssertGreaterThan(vakalar.count, 400)
        var hata = 0
        for (i, v) in vakalar.enumerated() {
            let girdi = v["girdi"] ?? .bos
            do {
                let c = try IlerlemeKurallari.dogrula(girdi, bugun: bugun, simdi: simdi)
                if let beklenen = v["hata"] { XCTFail("vaka \(i): site hata verdi (\(beklenen.metin!)), Swift vermedi"); continue }
                esit(.nesne(c), v["cikti"], "vaka \(i)")
            } catch let e as IlerlemeKurallari.Hata {
                hata += 1
                XCTAssertEqual(.metin(e.description), v["hata"], "vaka \(i) hata metni")
            } catch { XCTFail("vaka \(i): \(error)") }
        }
        XCTAssertGreaterThan(hata, 20)
    }

    /// Açılışta her okumada doğrulanır: ikinci geçişten sonra değişmez. (İlk geçiş tam sabit değil: sitede de
    /// derslerDogrula günü olan ama ilerlemesi 0 adımı `{ i: 0 }` bırakır, bir sonraki doğrulamada o adım silinir.)
    func testDogrulamaSabit() throws {
        for v in Self.ornek["vakalar"]!.dizi! {
            guard let c = v["cikti"] else { continue }
            let a = try IlerlemeKurallari.dogrula(c, bugun: bugun, simdi: simdi)
            esit(.nesne(try IlerlemeKurallari.dogrula(.nesne(a), bugun: bugun, simdi: simdi)), .nesne(a), "üçüncü doğrulama")
        }
    }

    func testYedekMetni() throws {
        for y in Self.ornek["yedekler"]!.dizi! {
            let yarim = y["yarim"].flatMap { $0.bosMu ? nil : $0 }
            let m = IlerlemeKurallari.yedekMetni(y["ilerleme"]!, yarim: yarim, tarih: simdi)
            // Anahtar sırası JS'te aynıysa metin birebir; değilse içerik aynı
            if m != y["metin"]!.metin! {
                esit(try JSONDeger.coz(Data(m.utf8)), try JSONDeger.coz(Data(y["metin"]!.metin!.utf8)), "yedek içeriği")
            }
            XCTAssertTrue(m.hasPrefix("{\n \"uygulama\": \"sanat-atlasi\",\n \"surum\": 2,"))
        }
    }

    func testYedekCoz() {
        for c in Self.ornek["cozumler"]!.dizi! {
            let metin = c["metin"]!.metin!
            do {
                let n = try IlerlemeKurallari.yedekCoz(metin, bugun: bugun, simdi: simdi)
                esit(.nesne(n), c["cikti"], "çöz: \(metin.prefix(40))")
            } catch let e as IlerlemeKurallari.Hata {
                XCTAssertEqual(.metin(e.description), c["hata"], "çöz hata: \(metin.prefix(40))")
            } catch { XCTFail("\(error)") }
            esit(IlerlemeKurallari.yedekYarimOturum(metin) ?? .bos, c["yarim"], "yarım oturum")
        }
    }

    func testKucukKurallar() {
        for k in Self.ornek["kucukler"]!.dizi! {
            let il = k["ilerleme"]!.nesne!
            let g = IlerlemeKurallari.gunlukGuncelle(il, bugun: k["bugun"]!.metin!)
            esit(g["gunluk"], k["gunluk"], "günlük")
            let s = IlerlemeKurallari.sonCalisilanEkle(il, k["id"]!.metin!)
            esit(s["sonCalisilanlar"], k["sonCalisilanlar"], "son çalışılanlar")
            let h = IlerlemeKurallari.yedekHatirlatmasi(il, bugun: k["hatirlatmaGunu"]!.metin!)
            let hj: JSONDeger = h.map { .nesne(SiraliNesne([("gun", .sayi(Double($0.gun))), ("metin", .metin($0.metin))])) } ?? .bos
            esit(hj, k["hatirlatma"], "yedek hatırlatması")
        }
    }

    func testEnYeniKayit() {
        for e in Self.ornek["enYeni"]!.dizi! {
            let s = IlerlemeKurallari.enYeniKayit(e["ls"]?.nesne, e["idb"]?.nesne)
            esit(s.map { .nesne($0) } ?? .bos, e["secilen"], "en yeni kayıt")
        }
    }

    func testGelistirici() throws {
        let g = Self.ornek["gelistirici"]!.dizi!
        XCTAssertGreaterThan(g.count, 5)
        for x in g {
            let il = x["ilerleme"]!.nesne!
            let yarim = x["yarim"].flatMap { $0.bosMu ? nil : $0 }
            let acik = IlerlemeKurallari.gelistiriciAc(il, konular: x["konular"]!.dizi!.map { Int($0.sayi!) },
                                                        bolumIdleri: x["bolumIdleri"]!.dizi!.map { $0.metin! }, yarim: yarim, simdi: simdi)
            esit(.nesne(acik), x["acik"], "geliştirici aç")
            var ayarlar = acik["ayarlar"]!.nesne!
            ayarlar = ayarlar.ayarlandi("tema", .metin("gunduz"))
            let k = try IlerlemeKurallari.gelistiriciKapat(acik.ayarlandi("ayarlar", .nesne(ayarlar)), bugun: bugun, simdi: simdi)
            esit(.nesne(k.ilerleme), x["kapali"]?["ilerleme"], "geliştirici kapat")
            esit(k.yarim, x["kapali"]?["yarim"], "geliştirici yarım")
        }
    }
}

final class IlerlemeDosyasiTests: XCTestCase {
    let bugun = "2026-11-22", simdi = "2026-11-22T10:00:00.000Z"
    var klasor: URL!

    override func setUp() {
        klasor = FileManager.default.temporaryDirectory.appendingPathComponent("ilerleme-\(UUID().uuidString)")
    }
    override func tearDown() { try? FileManager.default.removeItem(at: klasor) }

    func ornek(_ islenen: [Int]) throws -> SiraliNesne {
        try IlerlemeKurallari.dogrula(.nesne(SiraliNesne([("islenen", .dizi(islenen.map { .sayi(Double($0)) }))])), bugun: bugun, simdi: simdi)
    }

    func testYazOku() throws {
        let d = IlerlemeDosyasi(klasor: klasor)
        XCTAssertNil(try d.oku(bugun: bugun, simdi: simdi))
        XCTAssertFalse(d.varMi)
        let a = try d.yaz(try ornek([1, 2]), beklenen: nil)
        XCTAssertEqual(a["kayitNo"], .sayi(1))
        let o = try XCTUnwrap(try IlerlemeDosyasi(klasor: klasor).oku(bugun: bugun, simdi: simdi))
        XCTAssertEqual(o["islenen"], .dizi([.sayi(1), .sayi(2)]))
        let b = try d.yaz(o.ayarlandi("islenen", .dizi([.sayi(3)])), beklenen: 1)
        XCTAssertEqual(b["kayitNo"], .sayi(2))
        // Önceki kayıt saklanır
        let onceki = try JSONDeger.coz(Data(contentsOf: d.onceki))
        XCTAssertEqual(onceki["kayitNo"], .sayi(1))
    }

    func testCakisma() throws {
        let d = IlerlemeDosyasi(klasor: klasor)
        try d.yaz(try ornek([1]), beklenen: nil)
        let il = try XCTUnwrap(try d.oku(bugun: bugun, simdi: simdi))
        try d.yaz(il, beklenen: 1)
        XCTAssertThrowsError(try d.yaz(il, beklenen: 1)) { XCTAssertEqual($0 as? IlerlemeDosyasi.Hata, .cakisma) }
    }

    /// Ana kayıt bozulduysa önceki okunur, bozuk dosya silinmez saklanır
    func testBozukAnaKayit() throws {
        let d = IlerlemeDosyasi(klasor: klasor)
        try d.yaz(try ornek([1]), beklenen: nil)
        try d.yaz(try ornek([1, 2]), beklenen: 1)
        try Data("{bozuk".utf8).write(to: d.ana)
        let d2 = IlerlemeDosyasi(klasor: klasor)
        let o = try XCTUnwrap(try d2.oku(bugun: bugun, simdi: simdi))
        XCTAssertEqual(o["islenen"], .dizi([.sayi(1)]))
        let bozuk = try FileManager.default.contentsOfDirectory(atPath: klasor.path).filter { $0.hasPrefix("bozuk-") }
        XCTAssertEqual(bozuk.count, 1)
        // Yeni kayıt numarası eskilerden büyük
        XCTAssertEqual(try d2.yaz(o, beklenen: 1)["kayitNo"], .sayi(2))
    }

    /// Hiçbir kopya okunamazsa kilitlenir: boş ilerleme gerçek kaydın üstüne yazılmaz
    func testOkunamazsaKilit() throws {
        let d = IlerlemeDosyasi(klasor: klasor)
        try FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        try Data("[]".utf8).write(to: d.ana)
        XCTAssertThrowsError(try d.oku(bugun: bugun, simdi: simdi))
        XCTAssertTrue(d.kilitli)
        XCTAssertThrowsError(try d.yaz(try ornek([]), beklenen: nil))
        d.kilidiAc()
        XCTAssertNoThrow(try d.yaz(try ornek([]), beklenen: nil))
    }
}

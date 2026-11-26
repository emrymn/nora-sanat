import Foundation
import XCTest
@testable import NoraCekirdek

/// Z4a · doğal ses (Fola): anahtar sözleşmesi, ses dizini, kelime zamanlaması ve planda gerçek süre.
/// Beklenen değerler sanat-atlasi scripts/ses_uret.py'nin (PR #238) kendi fonksiyonlarıyla alındı:
/// `duzgun`, `anahtar`, `kelime_zamanlari`.
final class DinleSesTests: XCTestCase {
    func testSHA1BilinenDegerler() {
        func hex(_ s: String) -> String { SHA1.ozet(Array(s.utf8)).map { String(format: "%02x", $0) }.joined() }
        XCTAssertEqual(hex(""), "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        XCTAssertEqual(hex("abc"), "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(hex(String(repeating: "a", count: 1000)), "291e9a6c66994949b57ba5e650361e98fc36b1ba")
    }

    func testAnahtarSozlesmesi() {
        // Görevdeki örnek: kapanış sözü
        XCTAssertEqual(SesAnahtari.parcaAnahtari("Şimdi tablonun tamamına bir kez daha bak."), "06595c992253ae11")
        XCTAssertEqual(SesAnahtari.parcaAnahtari(DinlemeKurallari.kapanisMetni), "06595c992253ae11")
        // NBSP, U+2028, sekme ve baştaki/sondaki boşluk tek boşluk olur; tırnakla biten metne nokta eklenmez
        let ham = "  Van\u{00A0}Eyck\u{2028}aynada,\t\"Johannes de Eyck fuit hic\"  "
        XCTAssertEqual(SesAnahtari.metin(ham), "Van Eyck aynada, \"Johannes de Eyck fuit hic\"")
        XCTAssertEqual(SesAnahtari.parcaAnahtari(ham), "656d825221d1580d")
        // NFC: ayrık yazılmış é birleşir; sonuna nokta eklenir
        XCTAssertEqual(SesAnahtari.metin("Ce\u{0301}zanne elmaları"), "Cézanne elmaları.")
        XCTAssertEqual(SesAnahtari.metin("Ce\u{0301}zanne elmaları").unicodeScalars.count, 17)
        XCTAssertEqual(SesAnahtari.parcaAnahtari("Ce\u{0301}zanne elmaları"), "e1b8a1bc9b41f081")
        XCTAssertEqual(SesAnahtari.parcaAnahtari("Kral 👑 ve kraliçe"), "7bcdbe6635555779")
        XCTAssertNil(SesAnahtari.parcaAnahtari(" \u{2028} "))
    }

    private var dizinVerisi: Data {
        Data("""
        {"surum":1,"model":"gemini-3.8-flash-tts","ses":"Fola","klasor":"ses/Fola/",
         "parcalar":{"06595c992253ae11":3.25,"656d825221d1580d":4.5,"bozuk":"x","sifir":0}}
        """.utf8)
    }

    func testSesDizini() throws {
        let d = try XCTUnwrap(SesDizini(veri: dizinVerisi))
        XCTAssertEqual(d.ses, "Fola")
        XCTAssertEqual(d.klasor, "ses/Fola")
        XCTAssertEqual(d.parcalar.count, 2, "sayı olmayan ve sıfır süreler atlanır")
        XCTAssertEqual(d.sure("Şimdi  tablonun tamamına bir kez daha bak"), 3.25)
        XCTAssertNil(d.sure("Kaydı olmayan bir cümle."))
        let a = try XCTUnwrap(d.adresler("06595c992253ae11", kok: "https://gorsel.noracloud.ai/"))
        XCTAssertEqual(a.mp3.absoluteString, "https://gorsel.noracloud.ai/ses/Fola/06595c992253ae11.mp3?v=3.250")
        XCTAssertEqual(a.json.absoluteString, "https://gorsel.noracloud.ai/ses/Fola/06595c992253ae11.json?v=3.250")
        let b = try XCTUnwrap(d.adresler("dizindeyok0000000", kok: "https://gorsel.noracloud.ai"))
        XCTAssertEqual(b.mp3.absoluteString, "https://gorsel.noracloud.ai/ses/Fola/dizindeyok0000000.mp3")
        XCTAssertEqual(d.surum("06595c992253ae11"), "3.250")
        XCTAssertEqual(d.surum("dizindeyok0000000"), "0")
        XCTAssertNil(d.adresler("06595c992253ae11", kok: ""), "R2 adresi yoksa ses yok (AVSpeech'e dönülür)")
        XCTAssertNil(SesDizini(veri: Data("{}".utf8)))
        XCTAssertNil(SesDizini(veri: nil))
        XCTAssertNil(SesDizini(veri: Data("<html>404</html>".utf8)))
    }

    func testZamanlamaDosyasi() throws {
        // `<anahtar>.json`: konumlar kod noktası; 👑 tek kod noktası ama iki UTF-16 birimi
        let json = Data("""
        {"metin":"Kral 👑 ve kraliçe.","sure":2.0,"tahmini":true,
         "kelimeler":[[0.12,0,4],[0.452,5,6],[0.603,7,9],[0.814,10,18]]}
        """.utf8)
        let a = try XCTUnwrap(AltyaziAkisi(veri: json))
        XCTAssertEqual(a.kelimeler.map(\.yazi), ["Kral", "👑", "ve", "kraliçe."])
        XCTAssertEqual(a.kelimeler[1].harf, 5..<6)
        XCTAssertEqual(a.kelimeler[1].utf16, 5..<7)
        XCTAssertEqual(a.kelimeler[2].utf16, 8..<10)
        XCTAssertEqual(a.kelime(sn: 0), -1)
        XCTAssertEqual(a.kelime(sn: 0.5), 1)
        XCTAssertEqual(a.kelime(sn: 1.9), 3)
        XCTAssertEqual(a.kelime(utf16: 9), 2)
        XCTAssertEqual(a.sure, 2.0)
        // konum metnin dışındaysa akış kurulmaz
        XCTAssertNil(AltyaziAkisi(veri: Data(#"{"metin":"Kısa.","kelimeler":[[0,0,40]]}"#.utf8)))
    }

    func testTahminiZamanlamaBetikleAyni() {
        // ses_uret.py kelime_zamanlari("Şimdi tablonun tamamına bir kez daha bak.", 3.0)
        let beklenen: [(Double, Int, Int)] = [(0.12, 0, 5), (0.452, 6, 14), (0.937, 15, 23), (1.422, 24, 27),
                                              (1.652, 28, 31), (1.882, 32, 36), (2.163, 37, 41)]
        let a = AltyaziAkisi(metin: "Şimdi tablonun tamamına bir kez daha bak.", sure: 3.0)
        XCTAssertEqual(a.kelimeler.count, beklenen.count)
        for (k, b) in zip(a.kelimeler, beklenen) {
            XCTAssertEqual(k.bas, b.0, accuracy: 0.001)
            XCTAssertEqual(k.harf, b.1..<b.2)
        }
    }

    func testCumleCumle() {
        let a = AltyaziAkisi(metin: "Bir iki üç. Dört beş! “Altı yedi.” Sekiz", sure: 10)
        XCTAssertEqual(a.cumle(kelime: 1), 0..<3)
        XCTAssertEqual(a.cumle(kelime: 3), 3..<5)
        XCTAssertEqual(a.cumle(kelime: 6), 5..<7, "kapanış tırnağıyla biten cümle")
        XCTAssertEqual(a.cumle(kelime: 7), 7..<8)
        XCTAssertEqual(a.cumle(kelime: -1), 0..<3, "henüz söz başlamadıysa ilk cümle")
        // uzun cümle eşit parçalara bölünür
        let uzun = AltyaziAkisi(metin: (1...30).map { "k\($0)" }.joined(separator: " ") + ".", sure: 10)
        XCTAssertEqual(uzun.cumle(kelime: 0, enCok: 22), 0..<15)
        XCTAssertEqual(uzun.cumle(kelime: 20, enCok: 22), 15..<30)
    }

    // MARK: - Plan

    private func kaynak() -> DinlemeKaynagi {
        DinlemeKaynagi(baslik: "Arnolfini Portresi", sanatci: "Jan van Eyck", tarih: "1434",
                       notMetni: "Bir çiftin tam boy portresi", olay: ["Kuzey ışığı pencereden süzülüyor."],
                       noktalar: [
                           DinlemeNoktasi(ad: "Ayna", metin: "Dışbükey aynada  iki konuk görünür",
                                          kutu: DinlemeKutusu(x: 0.4, y: 0.2, w: 0.2, h: 0.18)),
                           DinlemeNoktasi(ad: "Köpek", metin: "Küçük köpek sadakatin simgesidir.",
                                          kutu: DinlemeKutusu(x: 0.36, y: 0.83, w: 0.24, h: 0.15)),
                       ])
    }

    func testPlanGercekSureyiKullanir() throws {
        let k = kaynak()
        var parcalar: [String: Double] = [:]
        for (m, s) in [(k.notMetni, 7.5), (k.noktalar[0].metin, 9.25), (DinlemeKurallari.kapanisMetni, 3.25)] {
            parcalar[try XCTUnwrap(SesAnahtari.parcaAnahtari(m))] = s
        }
        let dizin = SesDizini(ses: "Fola", klasor: "ses/Fola", parcalar: parcalar)
        let p = DinlemePlani.kur(k, sure: .bes, dizin: dizin)
        let eski = DinlemePlani.kur(k, sure: .bes)
        XCTAssertEqual(p.adimlar.map(\.tur), eski.adimlar.map(\.tur), "sıra aynı")
        XCTAssertLessThanOrEqual(p.toplam, DinlemeSuresi.bes.saniye + 0.001, "bütçe aynı")

        // Açılış: notun kaydı var → ses yalnız notu okur, künye ekranda
        let acilis = try XCTUnwrap(p.adimlar.first)
        XCTAssertEqual(acilis.metin, "Bir çiftin tam boy portresi.")
        XCTAssertEqual(acilis.konusma, 7.5)
        XCTAssertEqual(acilis.kayit, SesAnahtari.parcaAnahtari(k.notMetni))
        XCTAssertFalse(acilis.metin.contains("Jan van Eyck"))
        // Eski davranış: kayıt yoksa künye + not, telefonun sesi
        XCTAssertTrue(eski.adimlar[0].metin.hasPrefix("Arnolfini Portresi. Jan van Eyck, 1434."))
        XCTAssertNil(eski.adimlar[0].kayit)

        // Nokta: gerçek süre ve kaydın (düzgünleştirilmiş) metni
        let ayna = try XCTUnwrap(p.adimlar.first { $0.baslik == "Ayna" })
        XCTAssertEqual(ayna.konusma, 9.25)
        XCTAssertEqual(ayna.metin, "Dışbükey aynada iki konuk görünür.")
        XCTAssertNotNil(ayna.kayit)
        let kopek = try XCTUnwrap(p.adimlar.first { $0.baslik == "Köpek" })
        XCTAssertNil(kopek.kayit, "kaydı olmayan parça telefonun sesiyle")
        XCTAssertEqual(kopek.konusma, DinlemeKurallari.okumaSuresi(k.noktalar[1].metin))
        XCTAssertEqual(p.adimlar.last?.konusma, 3.25)
        XCTAssertEqual(p.adimlar.last?.kayit, "06595c992253ae11")
        // Sessiz bakış okunmaz, kaydı da olmaz
        XCTAssertTrue(p.adimlar.filter { $0.tur == .sessiz }.allSatisfy { $0.kayit == nil })
    }

    func testDizinsizPlanEskisiyleAyni() {
        let k = kaynak()
        for s in DinlemeSuresi.allCases {
            XCTAssertEqual(DinlemePlani.kur(k, sure: s), DinlemePlani.kur(k, sure: s, dizin: nil))
            let bos = SesDizini(ses: "Fola", klasor: "ses/Fola", parcalar: [:])
            XCTAssertEqual(DinlemePlani.kur(k, sure: s), DinlemePlani.kur(k, sure: s, dizin: bos),
                           "R2'ye ulaşılamayınca (boş dizin) plan eskisi gibi")
        }
    }
}

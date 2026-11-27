import Foundation
import XCTest
@testable import NoraCekirdek

/// T4 kâhini: Testler/kahin/sekme_cubugu.mjs → Ornekler/sekme_cubugu/cevaplar.json (canlı sitenin sekme çubuğu)
private enum CubukOrnek {
    struct Cevap: Decodable {
        struct Simge: Decodable { let isaretleme: String; let kutu: [Double] }
        struct Yer: Decodable {
            let ekran: [Double]
            let cubuk: [Double]
            let sekmeler: [[Double]]
            let isaret: [Double]
            let secili: Int
            let simge: [Double]
            let dil: [Double]
            let rozet: [Double]?
        }
        struct Hizli: Decodable {
            let temalar: [[String]]
            let hareketler: [[String]]
            let kart: [[Int]]
            let dilAyarlarda: Bool
        }
        let surum: String
        let simgeler: [String: Simge]
        let yerlesim: [Yer]
        let hizli: Hizli
    }

    static let cevap: Cevap = {
        let url = Bundle.module.url(forResource: "Ornekler/sekme_cubugu/cevaplar", withExtension: "json")!
        return try! JSONDecoder().decode(Cevap.self, from: Data(contentsOf: url))
    }()
}

final class SekmeCubuguTests: XCTestCase {
    private func ayni(_ k: SekmeCubugu.Kutu, _ d: [Double], _ ad: String, dosya: StaticString = #filePath, satir: UInt = #line) {
        XCTAssertEqual(k.x, d[0], accuracy: 0.01, "\(ad) x", file: dosya, line: satir)
        XCTAssertEqual(k.y, d[1], accuracy: 0.01, "\(ad) y", file: dosya, line: satir)
        XCTAssertEqual(k.genislik, d[2], accuracy: 0.01, "\(ad) genişlik", file: dosya, line: satir)
        XCTAssertEqual(k.yukseklik, d[3], accuracy: 0.01, "\(ad) yükseklik", file: dosya, line: satir)
    }

    /// Simgeler sitenin `YOLLAR`'ıyla birebir aynı ve okuyucu onları tarayıcının çizdiği kutuya çiziyor
    func testSimgelerSiteyleAyni() {
        // Z4b: Hikâyeler'in simgesi sitede yok (Neon'un tasarımından)
        XCTAssertEqual(Set(CubukOrnek.cevap.simgeler.keys),
                       Set(SekmeCubugu.Simge.allCases.filter { $0 != .hikayeler }.map(\.rawValue)))
        XCTAssertNotNil(SVGYolu.sinirKutusu(SekmeCubugu.Simge.hikayeler.komutlar))
        for s in SekmeCubugu.Simge.allCases {
            guard let o = CubukOrnek.cevap.simgeler[s.rawValue] else { continue }
            XCTAssertEqual(s.isaretleme, o.isaretleme, "\(s.rawValue) sitede değişmiş: örnekleri yeniden al, yolu kopyala")
            guard let k = SVGYolu.sinirKutusu(s.komutlar) else { return XCTFail(s.rawValue) }
            // Yaylar kübik eğriyle yaklaşık çizilir: 0,01 birimden (24'lükte) az fark
            XCTAssertEqual(k.x, o.kutu[0], accuracy: 0.01, "\(s.rawValue) x")
            XCTAssertEqual(k.y, o.kutu[1], accuracy: 0.01, "\(s.rawValue) y")
            XCTAssertEqual(k.genislik, o.kutu[2], accuracy: 0.01, "\(s.rawValue) genişlik")
            XCTAssertEqual(k.yukseklik, o.kutu[3], accuracy: 0.01, "\(s.rawValue) yükseklik")
        }
    }

    /// Çubuk, sekmeler, simge, dil ve rozet sitenin ölçülen yerlerinde (dört ekran boyu, iPad'de en çok 520). Sitenin
    /// çubuğu dört sekme (Çalış sonda); uygulamanınki Z4b'den beri beş, aynı hesapla.
    func testYerlesimSiteyleAyni() {
        XCTAssertEqual(CubukOrnek.cevap.yerlesim.count, 4)
        for o in CubukOrnek.cevap.yerlesim {
            let y = SekmeCubugu.Yerlesim(ekranGenisligi: o.ekran[0], ekranYuksekligi: o.ekran[1],
                                         sayi: SekmeCubugu.siteSekmeleri.count,
                                         rozetSira: SekmeCubugu.siteSekmeleri.firstIndex(of: .calis)!)
            let ad = "\(Int(o.ekran[0]))×\(Int(o.ekran[1]))"
            ayni(y.cubuk, o.cubuk, "\(ad) çubuk")
            XCTAssertEqual(y.sekmeler.count, o.sekmeler.count)
            for (i, s) in o.sekmeler.enumerated() { ayni(y.sekmeler[i], s, "\(ad) sekme \(i)") }
            ayni(y.sekmeler[o.secili], o.isaret, "\(ad) hap")
            let simge = y.simge(0)
            XCTAssertEqual(simge.x, o.simge[0], accuracy: 0.01, "\(ad) simge x")
            XCTAssertEqual(simge.y, o.simge[1], accuracy: 0.01, "\(ad) simge y")
            ayni(y.dil, o.dil, "\(ad) dil")
            if let r = o.rozet {
                XCTAssertEqual(y.rozet.x, r[0], accuracy: 0.01, "\(ad) rozet x")
                XCTAssertEqual(y.rozet.y, r[1], accuracy: 0.01, "\(ad) rozet y")
                XCTAssertEqual(SekmeCubugu.Olcu.rozet, r[3], accuracy: 0.01)
            }
        }
    }

    func testGuvenliAlan() {
        // Ana ekran çizgisi olan iPhone: alt 34 > 12; yatayda yanlar çentik kadar içeride
        let y = SekmeCubugu.Yerlesim(ekranGenisligi: 393, ekranYuksekligi: 852, altGuvenli: 34)
        XCTAssertEqual(y.alt, 34)
        XCTAssertEqual(y.cubuk.y, 852 - 34 - 62)
        XCTAssertEqual(y.dil.y, 852 - (34 + 54) - 28)
        let yatay = SekmeCubugu.Yerlesim(ekranGenisligi: 852, ekranYuksekligi: 393, solGuvenli: 59, sagGuvenli: 59, altGuvenli: 21)
        XCTAssertEqual(yatay.cubuk.genislik, 520)
        XCTAssertEqual(yatay.cubuk.ortaX, 426, accuracy: 0.001)
    }

    func testSurukleVeDokunus() {
        let y = SekmeCubugu.Yerlesim(ekranGenisligi: 393, ekranYuksekligi: 852, sayi: 4)
        XCTAssertEqual(y.enYakin(0), 0)
        XCTAssertEqual(y.enYakin(150), 1)
        XCTAssertEqual(y.enYakin(241), 2)
        XCTAssertEqual(y.enYakin(500), 3)
        XCTAssertEqual(y.surukle(14), 0)
        XCTAssertEqual(y.surukle(14 + 365), 3)
        XCTAssertEqual(y.surukle(196.5), 1.5, accuracy: 0.001)
        XCTAssertTrue(y.yakin(10, 770))
        XCTAssertFalse(y.yakin(200, 700))
    }

    /// Z4b: uygulamanın beş sekmeli çubuğu (sekme 70,2 geniş, ortaları 56,1 · 126,3 · 196,5 · 266,7 · 336,9)
    func testBesSekme() {
        let y = SekmeCubugu.Yerlesim(ekranGenisligi: 393, ekranYuksekligi: 852)
        XCTAssertEqual(y.sekmeler.count, 5)
        XCTAssertEqual(y.sekmeler[0].genislik, 70.2, accuracy: 0.001)
        XCTAssertEqual(y.sekmeler[2].ortaX, 196.5, accuracy: 0.001)
        XCTAssertEqual(y.enYakin(150), 1)
        XCTAssertEqual(y.enYakin(241), 3)
        XCTAssertEqual(y.enYakin(500), 4)
        XCTAssertEqual(y.surukle(14 + 365), 4)
        XCTAssertEqual(y.surukle(196.5), 2, accuracy: 0.001)
        // Rozet Çalış'ta (Z4f: dördüncü sekme)
        XCTAssertEqual(y.rozet.x, 266.7 + 6, accuracy: 0.001)
        // Hızlı ayar dili ekranın ortasında: Çalış'ın üstünde
        XCTAssertEqual(y.dil.ortaX, y.sekmeler[2].ortaX, accuracy: 0.001)
    }

    func testCubuktakiSira() {
        XCTAssertEqual(SekmeCubugu.siteSekmeleri.map(\.siteKimligi), ["bugun", "harita", "gozat", "pekistir"])
        // Z4f (Emre): Bugün · Hikâyeler · Yolculuk · Çalış · Galeri; Ben çubukta değil
        XCTAssertEqual(SekmeCubugu.sekmeler, [.bugun, .hikayeler, .yolculuk, .calis, .galeri])
        XCTAssertFalse(SekmeCubugu.sekmeler.contains(.ben))
        XCTAssertEqual(SekmeCubugu.sira(.galeri), 4)
        XCTAssertEqual(SekmeCubugu.sira(.yolculuk), 2)
        XCTAssertEqual(SekmeCubugu.Simge(.hikayeler), .hikayeler)
        // Sitede İlerleme ve Ayarlar'da Bugün seçili
        XCTAssertEqual(SekmeCubugu.sira(.ben), SekmeCubugu.sira(.bugun))
        XCTAssertEqual(SekmeCubugu.Simge(.ben), .bugun)
        XCTAssertEqual(SekmeCubugu.rozet(0), nil)
        XCTAssertEqual(SekmeCubugu.rozet(8), "8")
    }

    func testHizliAyarSiteyleAyni() {
        let h = CubukOrnek.cevap.hizli
        XCTAssertEqual(h.temalar, HizliAyar.temalar.map { [$0.0, $0.1] })
        XCTAssertEqual(h.hareketler, HizliAyar.hareketler.map { [$0.0, $0.1] })
        XCTAssertEqual(h.kart.count, 5)
        for k in h.kart { XCTAssertEqual(HizliAyar.gunlukKart(k[0], k[1]), k[2], "\(k)") }
        XCTAssertEqual(HizliAyar.dilGorunur(adres: "#/ayarlar"), h.dilAyarlarda)
        XCTAssertTrue(HizliAyar.dilGorunur(adres: "#/gozat"))
    }

    func testSVGOkuyucu() {
        // Bitişik sayılar ve göreli komutlar
        let k = SVGYolu.komutlar(d: "M1.5-2.5l.5.5h1v-1z")
        XCTAssertEqual(k, [.git(Nokta(1.5, -2.5)), .cizgi(Nokta(2, -2)), .cizgi(Nokta(3, -2)), .cizgi(Nokta(3, -3)), .kapat])
        // M'den sonraki çiftler çizgidir
        XCTAssertEqual(SVGYolu.komutlar(d: "M4 20 21 3"), [.git(Nokta(4, 20)), .cizgi(Nokta(21, 3))])
        // Yarım çember yayı uca varır ve kutusu çemberin yarısı
        let yay = SVGYolu.komutlar(d: "M0 0a5 5 0 0 0 10 0")
        guard case let .egri(_, _, son)? = yay.last else { return XCTFail() }
        XCTAssertEqual(son, Nokta(10, 0))
        let kutu = SVGYolu.sinirKutusu(yay)!
        XCTAssertEqual(kutu.yukseklik, 5, accuracy: 0.01)
        XCTAssertEqual(kutu.y, 0, accuracy: 0.01)
    }
}

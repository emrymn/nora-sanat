import Foundation
import XCTest
@testable import NoraCekirdek

/// C4b kâhini: sitenin `enBilinen` / `temsilOlabilir` cevapları (Testler/kahin/temsil.mjs), her sanatçının sitedeki eser
/// listesiyle. Swift aynı listeden aynı eseri seçmeli.
final class TemsilTests: XCTestCase {
    struct GorselC: Decodable { let k: String; let d, u, i: String? }
    struct EserC: Decodable {
        let anahtar: String
        let qid: String?
        let sl: Int
        let pekistirme: Bool
        let gorseller: [GorselC]
        var eser: Eser {
            Eser(anahtar: anahtar, kaynak: "", kaynaklar: [], baslik: "", tarih: "", yil: nil, muze: "", kursKonu: nil,
                 qid: qid, gorseller: gorseller.map { Gorsel(k: $0.k, d: $0.d, u: $0.u, i: $0.i) }, pekistirme: pekistirme, sl: sl)
        }
    }
    struct SanatciC: Decodable { let id: String; let eserler: [EserC]; let cevap: String?; let sirali: [String] }
    struct KotuC: Decodable { let id: String; let kotuler: [String: [String]]; let cevap: String? }
    struct Cevaplar: Decodable { let temsilDisi: [String]; let sanatcilar: [SanatciC]; let kotuler: [KotuC] }

    func cevaplar() throws -> Cevaplar {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "cevaplar", withExtension: "json", subdirectory: "Ornekler/temsil"))
        return try JSONDecoder().decode(Cevaplar.self, from: Data(contentsOf: url))
    }

    func testTemsilDisiListesiSitedekiyle() throws {
        XCTAssertEqual(Temsil.disi, Set(try cevaplar().temsilDisi))
    }

    func testEnBilinenSitedekiyleAyni() throws {
        let c = try cevaplar()
        XCTAssertGreaterThan(c.sanatcilar.count, 100)
        var ilktenFarkli = 0
        for s in c.sanatcilar {
            let l = s.eserler.map(\.eser)
            XCTAssertEqual(Temsil.enBilinen(l)?.anahtar, s.cevap, s.id)
            if let ilk = l.first, ilk.anahtar != s.cevap { ilktenFarkli += 1 }
        }
        // Eski kural ("ilk eser") bu sanatçılarda yanlıştı
        XCTAssertGreaterThan(ilktenFarkli, 0)
    }

    func testTemsilDisiEserSecilmez() throws {
        let c = try cevaplar()
        let s = try XCTUnwrap(c.sanatcilar.first { $0.eserler.contains { e in e.qid.map(Temsil.disi.contains) ?? false } })
        let l = s.eserler.map(\.eser)
        XCTAssertFalse(l.filter { !Temsil.olabilir($0) }.isEmpty)
        XCTAssertNotEqual(Temsil.enBilinen(l)?.qid, "Q3947103")
    }

    func testKotuGorsellerleSitedekiyleAyni() throws {
        let c = try cevaplar()
        XCTAssertFalse(c.kotuler.isEmpty)
        let liste = Dictionary(uniqueKeysWithValues: c.sanatcilar.map { ($0.id, $0.eserler.map(\.eser)) })
        for k in c.kotuler {
            let l = try XCTUnwrap(liste[k.id])
            XCTAssertEqual(Temsil.enBilinen(l, kotuler: k.kotuler)?.anahtar, k.cevap, k.id)
        }
    }

    func testBilinirlikSirasiSitedekiyle() throws {
        for s in try cevaplar().sanatcilar {
            let l = s.eserler.map(\.eser)
            XCTAssertEqual(Array(Temsil.bilinirlikSirasi(l).filter { !$0.gorseller.isEmpty }.prefix(10).map(\.anahtar)), s.sirali, s.id)
            for (i, a) in s.sirali.enumerated() {
                XCTAssertEqual(Temsil.siradaki(l, sira: i)?.anahtar, a, s.id)
            }
        }
    }
}

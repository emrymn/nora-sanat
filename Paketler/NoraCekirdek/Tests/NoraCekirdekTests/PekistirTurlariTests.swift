// C1a denetimi: pekiştirme turları uçtan uca, gerçek katalogla.
// Örnekler `Testler/kahin/pekistir_turlari.mjs` ile canlı sitenin kendi modüllerinden alındı (sanat-atlasi @ a866b86):
// 60 rastgele ilerleme × tur (karışık, dönem, hepsi, konu, hatalar, harita bölümü), her turda en çok 10 kart.
import XCTest
@testable import NoraCekirdek

/// Sitenin `rastgeleYap`'ı (js/yardimci.js, mulberry32). Kaç sayı çekildiğini sayar.
final class SiteRastgelesi {
    private var a: UInt32
    private(set) var sayac = 0
    init(_ tohum: Int) { a = UInt32(truncatingIfNeeded: tohum) }
    func sonraki() -> Double {
        sayac += 1
        a = a &+ 0x6d2b_79f5
        var t = a
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }
}

final class PekistirTurlariTests: XCTestCase {
    struct Ornekler: Decodable {
        let bugun: String
        let durumlar: [Durum]
    }
    struct Durum: Decodable {
        struct Tur: Decodable { let kip: String; let akim: String?; let seciliSeviye: Int?; let bolum: [String]? }
        struct Plan: Decodable { let kartlar: [String]; let tanisma: [String]; let esler: [String: String] }
        struct Kart: Decodable {
            let id: String
            let eser: String?
            let seviye: Int?
            let secenekler: [String]?
            let akim: [String]?
            let ters: [[String]]?
        }
        struct Cevap: Decodable { let s: String?; let a: String? }
        struct Adim: Decodable { let kart: Kart; let cevap: Cevap?; let kuyruk: [String]? }
        let tur: Tur
        let ilerleme: String
        let tohum: Int
        let sayilar: Int
        let kolaylik: [String: Double]
        let konular: [String: String]
        let plan: Plan
        let adimlar: [Adim]
        let sonra: [String: String]
    }

    func turu(_ t: Durum.Tur) throws -> PekistirmeTuru {
        switch t.kip {
        case "karisik": return .karisik
        case "donem": return .donem(t.akim == "hepsi" ? nil : t.akim)
        case "konu": return .konu(try XCTUnwrap(Int(t.akim ?? "")))
        case "hatalar": return .hatalar
        default:
            let p = (t.akim ?? "").split(separator: "/", maxSplits: 1).map(String.init)
            let ham = p.count > 1 ? p[1] : ""
            let seviye: BolumSeviyesi
            if ham.hasPrefix("tanitim") {
                let orta = ham.hasPrefix("tanitim-orta")
                let son = ham.split(separator: "-").last.flatMap { Int($0) }
                seviye = .tanitim(orta: orta, grup: son.map { $0 - 1 })
            } else {
                seviye = ham == "kolay" ? .kolay : ham == "orta" ? .orta : .zor
            }
            return .bolum(id: p[0], sanatcilar: t.bolum ?? [], seviye: seviye)
        }
    }

    func testSitedekiTurlarlaAyni() throws {
        let (_, k) = try XCTUnwrap(SiteVerisiTests.hazir, "katalog örnekleri okunamadı")
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Ornekler/pekistir/turlar", withExtension: "json"))
        let o = try JSONDecoder().decode(Ornekler.self, from: Data(contentsOf: url))
        XCTAssertEqual(o.durumlar.count, 60)
        var kartSayisi = 0, tersSayisi = 0
        for (i, d) in o.durumlar.enumerated() {
            let yer = "durum \(i) (\(d.tur.kip) \(d.tur.akim ?? ""))"
            var il = try Ilerleme(veri: Data(d.ilerleme.utf8))
            let tur = try turu(d.tur)
            let r = SiteRastgelesi(d.tohum)
            let rastgele: PekistirmeRastgele = { r.sonraki() }
            let plan = TurPlani.kur(tur, katalog: k, ilerleme: il, bugun: o.bugun, rastgele: rastgele)
            XCTAssertEqual(plan.kartlar, d.plan.kartlar, "\(yer): kartlar")
            XCTAssertEqual(plan.tanisma, d.plan.tanisma, "\(yer): tanışma")
            XCTAssertEqual(plan.esler, d.plan.esler, "\(yer): eşler")
            guard plan.kartlar == d.plan.kartlar else { continue }
            var oturum = PekistirmeOturumu(plan.kartlar)
            for (n, adim) in d.adimlar.enumerated() {
                let yer = "\(yer) kart \(n)"
                let simdiki = try XCTUnwrap(oturum.simdiki, yer)
                XCTAssertEqual(simdiki.id, adim.kart.id, yer)
                let kart = PekistirmeKarti.hazirla(simdiki, tur: tur, plan: plan, katalog: k, ilerleme: &il,
                                                   seciliSeviye: d.tur.seciliSeviye, kolaylik: d.kolaylik,
                                                   konu: { e, sid in d.konular["\(sid)|\(e.qid ?? "")|\(e.baslik)"] },
                                                   rastgele: rastgele)
                guard let beklenenEser = adim.kart.eser else {
                    XCTAssertNil(kart, "\(yer): site eser bulamadı")
                    break
                }
                guard let kart else { XCTFail("\(yer): kart kurulamadı"); break }
                kartSayisi += 1
                XCTAssertEqual(kart.eser.anahtar, beklenenEser, "\(yer): eser")
                XCTAssertEqual(kart.seviye, adim.kart.seviye, "\(yer): seviye")
                XCTAssertEqual(kart.secenekler, adim.kart.secenekler, "\(yer): şıklar")
                XCTAssertEqual(kart.akimSecenekleri, adim.kart.akim, "\(yer): akım şıkları")
                XCTAssertEqual(kart.ters?.map { [$0.id, $0.eser.anahtar] }, adim.kart.ters, "\(yer): ters")
                if kart.ters != nil { tersSayisi += 1 }
                let c = try XCTUnwrap(adim.cevap, yer)
                let cevap: PekistirmeOturumu.KartCevabi = tur == .karisik && kart.ters == nil
                    ? .karisik(sanatci: c.s, akim: c.a) : .sanatci(c.s)
                XCTAssertTrue(oturum.cevapla(konum: oturum.konum, sanatci: kart.sanatci, tur: tur, cevap: cevap,
                                             seciliSeviye: d.tur.seciliSeviye, bugun: o.bugun, ilerleme: &il,
                                             rastgele: rastgele), yer)
                XCTAssertEqual(oturum.kuyruk.map { $0.id + ($0.tekrar ? "*" : "") }, adim.kuyruk, "\(yer): kuyruk")
            }
            XCTAssertEqual(r.sayac, d.sayilar, "\(yer): çekilen rastgele sayı")
            for (alan, beklenen) in d.sonra.sorted(by: { $0.key < $1.key }) {
                XCTAssertEqual(il[alan: alan]?.jsonMetni ?? "null", beklenen, "\(yer): \(alan)")
            }
        }
        XCTAssertGreaterThan(kartSayisi, 300)
        XCTAssertGreaterThan(tersSayisi, 0)
    }
}

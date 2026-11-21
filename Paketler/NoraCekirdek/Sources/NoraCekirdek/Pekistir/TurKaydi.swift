// Kaynak: sanat-atlasi js/devam.js, js/ekranlar/{pekistir,soruTurlari}.js @ a866b86
import Foundation

public enum PekistirmeKipi: Codable, Equatable {
    case sanatci(PekistirmeTuru), kursBolumu, ikonografi
    var soru: SoruTuru? {
        switch self {
        case .sanatci: return nil
        case .kursBolumu: return .kursBolumu
        case .ikonografi: return .ikonografi
        }
    }
}

public struct PekistirmeVerileri {
    struct Konu: Decodable {
        let id, ad, tur: String
        let eserler: [[String]]
    }
    let konular: [Konu]
    let kolaylik: [String: Double]
    let konuHaritasi: [String: String]

    public init(ikonografi: Data?, zorluk: Data?) {
        struct Liste: Decodable { let konular: [Konu] }
        struct Puanlar: Decodable { let kolaylik: [String: Double] }
        konular = ikonografi.flatMap { try? JSONDecoder().decode(Liste.self, from: $0) }?.konular ?? []
        kolaylik = zorluk.flatMap { try? JSONDecoder().decode(Puanlar.self, from: $0) }?.kolaylik ?? [:]
        var harita = [String: String]()
        for konu in konular {
            for cift in konu.eserler where cift.count == 2 && harita[cift[0]] == nil { harita[cift[0]] = konu.id }
        }
        konuHaritasi = harita
    }
    public func ad(_ id: String) -> String { konular.first { $0.id == id }?.ad ?? id }
}

public struct TurKarti: Codable {
    public struct Resim: Codable {
        public let id: String
        public let eser: Eser
    }
    public let resim: Resim
    public let dogru: String
    public let secenekler: [String]
    public var akimlar: [String]?
    public var ters: [Resim]?
    public var sanatciCevabi: String?
    public var ikinci = false
    public var sonuc: Bool?
    public var bilmiyorum = false
    public var akimBekliyor: Bool { akimlar != nil && !ikinci }
}

public struct TurKaydi: Codable {
    public let kip: PekistirmeKipi
    public let seviye: Int?
    public let plan: TurPlani
    public private(set) var kart: TurKarti?
    public private(set) var oturum: PekistirmeOturumu
    public var zaman = Date()

    public init(kip: PekistirmeKipi, seviye: Int?, katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: Ilerleme, gun: String) {
        self.kip = kip
        self.seviye = seviye
        var plan = TurPlani()
        switch kip {
        case .sanatci(let tur): plan = .kur(tur, katalog: k, ilerleme: il, bugun: gun)
        case .kursBolumu, .ikonografi:
            let acik = il.acikSanatcilar(k.sanatcilar)
            let idler = Set(acik.map(\.id))
            let numaralar = Set(k.konular.map(\.no))
            let adaylar = kip == .kursBolumu
                ? acik.filter { $0.konu.map(numaralar.contains) == true }.map(\.id)
                : veri.konular.filter { $0.eserler.contains { $0.count == 2 && idler.contains($0[1]) } }.map(\.id)
            plan.kartlar = kip.soru?.kartlar(adaylar: adaylar, ilerleme: il, bugun: gun) ?? []
        }
        self.plan = plan
        oturum = PekistirmeOturumu(plan.kartlar)
    }

    public mutating func hazirla(katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: inout Ilerleme) {
        kart = nil
        while let s = oturum.simdiki {
            switch kip {
            case .sanatci(let tur):
                if let c = PekistirmeKarti.hazirla(s, tur: tur, plan: plan, katalog: k, ilerleme: &il,
                    seciliSeviye: seviye, kolaylik: veri.kolaylik, konu: { e, id in
                        e.qid.flatMap { veri.konuHaritasi[$0] } ?? veri.konuHaritasi["\(id)|\(e.baslik)"]
                    }) {
                    kart = TurKarti(resim: .init(id: s.id, eser: c.eser), dogru: s.id, secenekler: c.secenekler,
                        akimlar: c.akimSecenekleri, ters: c.ters?.map { .init(id: $0.id, eser: $0.eser) })
                }
            case .kursBolumu:
                if let sanatci = k.harita[s.id], let b = k.konular.first(where: { $0.no == sanatci.konu })?.bolum {
                    var bolumler = [String]()
                    for konu in k.konular where !bolumler.contains(konu.bolum) { bolumler.append(konu.bolum) }
                    let once = il[alan: "sonEserler"]?.nesne ?? .bos
                    let son = once[s.id]?.dizi?.compactMap(\.metin) ?? []
                    if let e = KartEseri.sec(k.eserler(s.id), tur: .donem(nil), seviye: 0, son: son, kotuler: il.kotuGorseller) {
                        let sonlar = (son.filter { $0 != e.anahtar } + [e.anahtar]).suffix(8)
                        il[alan: "sonEserler"] = .nesne(once.ayarlandi(s.id, .dizi(sonlar.map(JSONDeger.metin))))
                        kart = TurKarti(resim: .init(id: s.id, eser: e), dogru: b,
                            secenekler: SoruTuru.bolumSecenekleri(dogru: b, siraliBolumler: bolumler))
                    }
                }
            case .ikonografi:
                if let konu = veri.konular.first(where: { $0.id == s.id }) {
                    let acik = Set(il.acikSanatcilar(k.sanatcilar).map(\.id))
                    let adaylar = konu.eserler.filter { $0.count == 2 && acik.contains($0[1]) }
                    for cift in adaylar.shuffled().prefix(4) {
                        guard let e = k.eserler(cift[1]).first(where: { $0.qid == cift[0] || "\(cift[1])|\($0.baslik)" == cift[0] }),
                              GorselAdresleri.pekistirmeyeUygun(e, kotuler: il.kotuGorseller) else { continue }
                        kart = TurKarti(resim: .init(id: cift[1], eser: e), dogru: s.id,
                            secenekler: SoruTuru.konuSecenekleri(dogru: s.id, konular: veri.konular.map { ($0.id, $0.tur) }))
                        break
                    }
                }
            }
            if kart != nil { return }
            oturum.simdikiniAtla()
        }
    }

    public mutating func cevapla(_ secim: String?, katalog: SiteKatalogu, gun: String, ilerleme: inout Ilerleme,
                                 rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard var k = kart, k.sonuc == nil, let s = katalog.harita[k.resim.id] else { return }
        let dogru = secim == (k.ikinci ? s.akim : k.dogru)
        k.sonuc = dogru
        k.bilmiyorum = secim == nil
        if !k.ikinci { k.sanatciCevabi = secim }
        if case let .sanatci(tur) = kip {
            if !k.akimBekliyor {
                let cevap: PekistirmeOturumu.KartCevabi = k.ikinci ? .karisik(sanatci: k.sanatciCevabi, akim: secim) : .sanatci(secim)
                guard oturum.cevapla(konum: oturum.konum, sanatci: s, tur: tur, cevap: cevap, seciliSeviye: seviye,
                                     bugun: gun, ilerleme: &ilerleme, rastgele: rastgele) else { return }
            }
        } else {
            kip.soru?.cevapla(oturum: &oturum, konum: oturum.konum, dogru: dogru, akim: s.akim,
                              bugun: gun, ilerleme: &ilerleme, rastgele: rastgele)
        }
        kart = k
    }

    public mutating func sonraki(katalog: SiteKatalogu, veri: PekistirmeVerileri, ilerleme: inout Ilerleme) {
        guard let k = kart, k.sonuc != nil else { return }
        if k.akimBekliyor {
            kart?.ikinci = true
            kart?.sonuc = nil
            kart?.bilmiyorum = false
        } else {
            hazirla(katalog: katalog, veri: veri, ilerleme: &ilerleme)
        }
    }
}

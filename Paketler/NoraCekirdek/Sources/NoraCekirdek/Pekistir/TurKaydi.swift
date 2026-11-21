// Kaynak: sanat-atlasi js/devam.js, js/ogrenme.js, js/bolum.js, js/ekranlar/{pekistir,soruTurlari}.js @ a866b86
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
    /// `data/tanima_notlari.json` (`d.tanimaNotlari`): kurs sanatçılarının "Nasıl tanırım?" notları
    public let tanimaNotlari: [String: String]

    public init(ikonografi: Data?, zorluk: Data?, tanima: Data? = nil) {
        struct Liste: Decodable { let konular: [Konu] }
        struct Puanlar: Decodable { let kolaylik: [String: Double] }
        konular = ikonografi.flatMap { try? JSONDecoder().decode(Liste.self, from: $0) }?.konular ?? []
        kolaylik = zorluk.flatMap { try? JSONDecoder().decode(Puanlar.self, from: $0) }?.kolaylik ?? [:]
        var harita = [String: String]()
        for konu in konular {
            for cift in konu.eserler where cift.count == 2 && harita[cift[0]] == nil { harita[cift[0]] = konu.id }
        }
        konuHaritasi = harita
        tanimaNotlari = tanima.map { GoruntuleyiciKurallari.notlariAl(veri: $0) } ?? [:]
    }

    /// Testler için: veri dosyaları yerine hazır sözlükler.
    init(kolaylik: [String: Double], konuHaritasi: [String: String], tanimaNotlari: [String: String] = [:]) {
        konular = []
        self.kolaylik = kolaylik
        self.konuHaritasi = konuHaritasi
        self.tanimaNotlari = tanimaNotlari
    }

    public func ad(_ id: String) -> String { konular.first { $0.id == id }?.ad ?? id }

    /// `eserKonusu(e)`: önce QID, yoksa `sanatçıId|başlık`
    func konu(_ e: Eser, _ sid: String) -> String? {
        e.qid.flatMap { konuHaritasi[$0] } ?? konuHaritasi["\(sid)|\(e.baslik)"]
    }

    /// `kolaylikFn(sanatciId)`: puan dosyası boşsa nil (site de `null` verir)
    func kolaylikFn(_ sid: String) -> ((Eser) -> Double?)? {
        guard !kolaylik.isEmpty else { return nil }
        return { e in e.qid.flatMap { kolaylik[$0] } ?? kolaylik["\(sid)|\(e.baslik)"] }
    }

    /// `ipucuMetni(s)`: `taninma(s) || s.kurs_notu || s.anlatim || ''`
    public func ipucu(_ s: Sanatci) -> String {
        let t = GoruntuleyiciKurallari.taninmaMetni(s, tanimaNotlari: tanimaNotlari)
        if !t.isEmpty { return t }
        if let n = s.kursNotu, !n.isEmpty { return n }
        return s.anlatim ?? ""
    }
}

/// Cevap yaprağındaki seviye satırı (`seviyeSatiri`, `k.seviyeSonuc`)
public struct SeviyeSonucu: Codable, Equatable {
    /// Harita bölümü: dönem seviyesi yerine bölümün geçme sınırı gösterilir.
    public var bolum = false
    /// Alt seviye seçilmiş (ısınma): cevap dönemin penceresine yazılmadı.
    public var isinma = false
    public var once: Int
    public var sonra: Int
    public var gecti: Bool
}

public struct TurKarti: Codable {
    public struct Resim: Codable {
        public let id: String
        public let eser: Eser
    }
    public var resim: Resim
    public let dogru: String
    public let secenekler: [String]
    public var akimlar: [String]?
    public var ters: [Resim]?
    public var sanatciCevabi: String?
    public var ikinci = false
    public var sonuc: Bool?
    public var bilmiyorum = false
    // C1c alanları isteğe bağlıdır: C1b'nin sakladığı yarım tur da çözülür.
    /// Kartın sorulduğu dönem seviyesi (0 Kolay, 1 Orta, 2 Zor)
    public var seviye: Int?
    /// Yeni sanatçı: sorudan önce gösterilecek tanışma eserleri (`tanismaGoster`). nil: tanışma yok ya da geçildi.
    public var tanisma: [String]?
    /// Görseli açılmadığı için bırakılan eserler (`baskaEser`)
    public var atlananlar: [String]?
    /// Yanlış cevaptan sonra ikilinin karıştırılma sayısı (`k.karisanSayi`)
    public var karisan: Int?
    public var seviyeSonucu: SeviyeSonucu?
    public var akimBekliyor: Bool { akimlar != nil && !ikinci }
}

public struct TurKaydi: Codable {
    /// Konu turunun (ve harita bölümünün) turdan önceki tanışmaları (`o.tanisma`)
    public struct Tanisma: Codable, Equatable {
        public var sira: [String]
        public var konum = 0
        public var gecmis: [Int] = []
        /// Şu an gösterilen sanatçının tanışma eserleri
        public var gosterilen: [String] = []
        public var simdiki: String? { sira.indices.contains(konum) ? sira[konum] : nil }
    }
    /// Bu turda seviye atlayan dönem (`o.gecenler`)
    public struct Gecen: Codable, Equatable {
        public let akim: String
        public let seviye: Int
    }

    public let kip: PekistirmeKipi
    /// Dönem turunda seçilen alt seviye (`o.seviye`); nil dönemin kendi seviyesi
    public private(set) var seviye: Int?
    public let plan: TurPlani
    public private(set) var kart: TurKarti?
    public private(set) var oturum: PekistirmeOturumu
    public var zaman = Date()
    public private(set) var tanisma: Tanisma?
    /// Tanışmada gösterilen eserler: o turda sorulmaz (`o.tanismaGorulen`)
    public private(set) var tanismaGorulen: [String: [String]]?
    public private(set) var gecenler: [Gecen]?
    /// Son gösterilen kartın eseri (özetteki "Bir tur daha" kartının resmi)
    public private(set) var sonResim: TurKarti.Resim?

    public init(kip: PekistirmeKipi, seviye: Int?, katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: Ilerleme, gun: String,
                rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        self.kip = kip
        self.seviye = seviye
        var plan = TurPlani()
        switch kip {
        case .sanatci(let tur): plan = .kur(tur, katalog: k, ilerleme: il, bugun: gun, rastgele: rastgele)
        case .kursBolumu, .ikonografi:
            let acik = il.acikSanatcilar(k.sanatcilar)
            let idler = Set(acik.map(\.id))
            let numaralar = Set(k.konular.map(\.no))
            let adaylar = kip == .kursBolumu
                ? acik.filter { $0.konu.map(numaralar.contains) == true }.map(\.id)
                : veri.konular.filter { $0.eserler.contains { $0.count == 2 && idler.contains($0[1]) } }.map(\.id)
            plan.kartlar = kip.soru?.kartlar(adaylar: adaylar, ilerleme: il, bugun: gun, rastgele: rastgele) ?? []
        }
        self.plan = plan
        oturum = PekistirmeOturumu(plan.kartlar)
        if !plan.tanisma.isEmpty { tanisma = Tanisma(sira: plan.tanisma) }
    }

    /// Turdan önceki tanışma sürüyor (`o.tanisma.konum < o.tanisma.sira.length`)
    public var tanismaBekliyor: Bool { tanisma.map { $0.konum < $0.sira.count } ?? false }
    /// Ne tanışma ne kart kaldı: tur özeti
    public var bitti: Bool { kart == nil && !tanismaBekliyor }

    /// Sayaçtaki sıra: cevaptan sonra da kartın kendi sırası kalır (site `ilerle`'yi "Sonraki"de yapar).
    public var gorunenKonum: Int {
        let tamam = kart.map { $0.sonuc != nil && !$0.akimBekliyor } ?? false
        return oturum.konum - (tamam ? 1 : 0)
    }

    /// Tanışmayı ayarlardan kapatan (`ayarlar.tanisma === false`)
    static func tanismaAcik(_ il: Ilerleme) -> Bool { il.ayar("tanisma")?.mantik != false }

    public mutating func hazirla(katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: inout Ilerleme,
                                 rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        if let onceki = kart { sonResim = onceki.resim }
        kart = nil
        if tanismaBekliyor {
            tanismayiHazirla(katalog: k, veri: veri, ilerleme: il)
            if tanismaBekliyor { return }
        }
        while let s = oturum.simdiki {
            switch kip {
            case .sanatci(let tur):
                if let c = PekistirmeKarti.hazirla(s, tur: tur, plan: plan, katalog: k, ilerleme: &il,
                    seciliSeviye: seviye, kolaylik: veri.kolaylik, tanismadaGorulen: tanismaGorulen?[s.id] ?? [],
                    konu: veri.konu, rastgele: rastgele) {
                    var t = TurKarti(resim: .init(id: s.id, eser: c.eser), dogru: s.id, secenekler: c.secenekler,
                        akimlar: c.akimSecenekleri, ters: c.ters?.map { .init(id: $0.id, eser: $0.eser) })
                    t.seviye = c.seviye
                    // kartCiz: konu turunda ve bölümde tanışmalar turdan önce yapıldı
                    switch tur {
                    case .konu, .bolum: break
                    default:
                        if Self.tanismaAcik(il), Ogrenme.tanismaGerekir(il.skorlar[s.id]) {
                            t.tanisma = Ogrenme.tanismaEserleri(KartEseri.havuz(k.eserler(s.id), il.kotuGorseller),
                                haric: c.eser.anahtar, adet: 3, kolaylik: veri.kolaylikFn(s.id)).map(\.anahtar)
                        }
                    }
                    kart = t
                }
            case .kursBolumu:
                if let sanatci = k.harita[s.id], let b = k.konular.first(where: { $0.no == sanatci.konu })?.bolum {
                    var bolumler = [String]()
                    for konu in k.konular where !bolumler.contains(konu.bolum) { bolumler.append(konu.bolum) }
                    let once = il[alan: "sonEserler"]?.nesne ?? .bos
                    let son = once[s.id]?.dizi?.compactMap(\.metin) ?? []
                    if let e = KartEseri.sec(k.eserler(s.id), tur: .donem(nil), seviye: 0, son: son, kotuler: il.kotuGorseller, rastgele: rastgele) {
                        let sonlar = (son.filter { $0 != e.anahtar } + [e.anahtar]).suffix(8)
                        il[alan: "sonEserler"] = .nesne(once.ayarlandi(s.id, .dizi(sonlar.map(JSONDeger.metin))))
                        kart = TurKarti(resim: .init(id: s.id, eser: e), dogru: b,
                            secenekler: SoruTuru.bolumSecenekleri(dogru: b, siraliBolumler: bolumler, rastgele: rastgele))
                    }
                }
            case .ikonografi:
                if let konu = veri.konular.first(where: { $0.id == s.id }) {
                    let acik = Set(il.acikSanatcilar(k.sanatcilar).map(\.id))
                    let adaylar = konu.eserler.filter { $0.count == 2 && acik.contains($0[1]) }
                    for cift in karistir(adaylar, rastgele).prefix(4) {
                        guard let e = k.eserler(cift[1]).first(where: { $0.qid == cift[0] || "\(cift[1])|\($0.baslik)" == cift[0] }),
                              GorselAdresleri.pekistirmeyeUygun(e, kotuler: il.kotuGorseller) else { continue }
                        kart = TurKarti(resim: .init(id: cift[1], eser: e), dogru: s.id,
                            secenekler: SoruTuru.konuSecenekleri(dogru: s.id, konular: veri.konular.map { ($0.id, $0.tur) }, rastgele: rastgele))
                        break
                    }
                }
            }
            if kart != nil { return }
            // Eseri bulunamayan kart atlanır ama sayaçta kalır (site: o.oturum.ilerle()).
            oturum.simdikiniAtla()
        }
    }

    // MARK: Tanışma

    /// `konuTanismaGoster`: sıradaki sanatçının tanışma eserleri; eseri olmayan sanatçı atlanır.
    mutating func tanismayiHazirla(katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: Ilerleme) {
        guard var t = tanisma, case let .sanatci(tur) = kip else { return }
        while let id = t.simdiki {
            let havuz = KartEseri.havuz(k.eserler(id), il.kotuGorseller)
            let kolay = veri.kolaylikFn(id)
            let sec: [Eser]
            // İş 30: bölümde o seviyenin eserleri (sorular yalnız bunlardan); konu turunda en bilinen 3
            if case let .bolum(_, _, sv) = tur, let orta = sv.tanitimOrta {
                sec = KartEseri.bolumEserleri(havuz, orta: orta, kolaylik: kolay)
            } else {
                sec = Ogrenme.tanismaEserleri(havuz, haric: nil, adet: 3, kolaylik: kolay)
            }
            if k.harita[id] != nil && !sec.isEmpty {
                t.gosterilen = sec.map(\.anahtar)
                break
            }
            t.konum += 1
        }
        tanisma = t
    }

    /// "Tanıdım / Sıradaki sanatçı / Tura başla": konu tanışmasında gösterilenler o turda sorulmaz.
    /// Kart tanışmasında (yeni sanatçı) soru açılır.
    public mutating func tanismaGec(katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: inout Ilerleme,
                                    rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        if var t = tanisma, let id = t.simdiki {
            var g = tanismaGorulen ?? [:]
            g[id] = t.gosterilen
            tanismaGorulen = g
            t.gecmis.append(t.konum)
            t.konum += 1
            tanisma = t
            hazirla(katalog: k, veri: veri, ilerleme: &il, rastgele: rastgele)
        } else if kart?.tanisma != nil {
            kart?.tanisma = nil
        }
    }

    /// Konu tanışmasında önceki sanatçıya dön (`data-konu-tanisma-geri`)
    public mutating func tanismaGeri(katalog k: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: Ilerleme) {
        guard var t = tanisma, let onceki = t.gecmis.popLast() else { return }
        t.konum = onceki
        tanisma = t
        tanismayiHazirla(katalog: k, veri: veri, ilerleme: il)
    }

    // MARK: Cevap

    /// Sanatçı cevabının dönem seviyesine etkisi (`sanatciCevapla`). Karışık kartta site bunu birinci soruda yazar;
    /// burada kart bitince tek yazmada gider, yaprak için önceden hesaplanır.
    func seviyeSonucu(_ tur: PekistirmeTuru, _ s: Sanatci, _ secim: String?, _ il: Ilerleme) -> SeviyeSonucu {
        let kayit = Seviye.kayit(il.seviyeler, s.akim)
        if case .bolum = tur { return SeviyeSonucu(bolum: true, once: kayit.s, sonra: kayit.s, gecti: false) }
        guard Seviye.pencereyeYazilir(kayit, kartSeviyesi: seviye) else {
            return SeviyeSonucu(isinma: true, once: kayit.s, sonra: kayit.s, gecti: false)
        }
        var sv = il.seviyeler
        let r = Seviye.isle(&sv, akim: s.akim, secim == nil ? .bilmiyorum : secim == s.id ? .dogru : .yanlis)
        return SeviyeSonucu(once: r.once, sonra: r.sonra, gecti: r.gecti)
    }

    public mutating func cevapla(_ secim: String?, katalog: SiteKatalogu, gun: String, ilerleme: inout Ilerleme,
                                 rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard var k = kart, k.sonuc == nil, k.tanisma == nil, let s = katalog.harita[k.resim.id] else { return }
        let dogru = secim == (k.ikinci ? s.akim : k.dogru)
        k.sonuc = dogru
        k.bilmiyorum = secim == nil
        if !k.ikinci { k.sanatciCevabi = secim }
        if case let .sanatci(tur) = kip {
            if !k.ikinci {
                if let secim, secim != s.id {
                    k.karisan = (ilerleme.karisanlar[Ogrenme.anahtar(s.id, secim)]?.n ?? 0) + 1
                } else {
                    k.karisan = 0
                }
                k.seviyeSonucu = seviyeSonucu(tur, s, secim, ilerleme)
            }
            if !k.akimBekliyor {
                let cevap: PekistirmeOturumu.KartCevabi = k.ikinci ? .karisik(sanatci: k.sanatciCevabi, akim: secim) : .sanatci(secim)
                guard oturum.cevapla(konum: oturum.konum, sanatci: s, tur: tur, cevap: cevap, seciliSeviye: seviye,
                                     bugun: gun, ilerleme: &ilerleme, rastgele: rastgele) else { return }
                if let r = k.seviyeSonucu, r.gecti { gecenler = (gecenler ?? []) + [Gecen(akim: s.akim, seviye: r.sonra)] }
            }
        } else {
            kip.soru?.cevapla(oturum: &oturum, konum: oturum.konum, dogru: dogru, akim: s.akim,
                              bugun: gun, ilerleme: &ilerleme, rastgele: rastgele)
        }
        kart = k
    }

    public mutating func sonraki(katalog: SiteKatalogu, veri: PekistirmeVerileri, ilerleme: inout Ilerleme,
                                 rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard let k = kart, k.sonuc != nil else { return }
        if k.akimBekliyor {
            kart?.ikinci = true
            kart?.sonuc = nil
            kart?.bilmiyorum = false
        } else {
            hazirla(katalog: katalog, veri: veri, ilerleme: &ilerleme, rastgele: rastgele)
        }
    }

    // MARK: Görsel açılmazsa, seviye seçimi

    /// `baskaEser`: soru görseli açılmazsa (cevaptan önce) aynı sanatçının başka bir eseri; en çok dört kez.
    @discardableResult
    public mutating func baskaEser(katalog k: SiteKatalogu, ilerleme il: Ilerleme,
                                   rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Bool {
        guard var t = kart, t.sonuc == nil, !t.ikinci, t.ters == nil, case .sanatci = kip else { return false }
        var atla = t.atlananlar ?? []
        guard atla.count <= 3 else { return false }
        atla.append(t.resim.eser.anahtar)
        let kalan = k.eserler(t.resim.id).filter { !atla.contains($0.anahtar) }
        // eserSec(kalan, [], rng, kotuler): zorluk dilimi ve koleksiyon ağırlığı yok
        guard let e = KartEseri.sec(kalan, tur: .karisik, seviye: 1, son: [], kotuler: il.kotuGorseller, rastgele: rastgele) else { return false }
        t.resim = .init(id: t.resim.id, eser: e)
        t.atlananlar = atla
        kart = t
        return true
    }

    /// Dönem turunun seviye hapları (`seviyeHaplari`): yalnız tek dönemlik turda ve dönem Kolay'ı geçtiyse.
    public func seviyeHaplari(_ il: Ilerleme) -> [(tanim: Seviye.Tanim, acik: Bool, secili: Bool, isinma: Bool)]? {
        guard case let .sanatci(.donem(akim?)) = kip else { return nil }
        let kayit = Seviye.kayit(il.seviyeler, akim)
        guard kayit.s >= 1 else { return nil }
        let simdiki = Seviye.kartSeviyesi(kayit, secili: seviye)
        return Seviye.seviyeler.map { x in
            (x, x.no <= kayit.s, x.no == simdiki, x.no < kayit.s && x.no == simdiki)
        }
    }

    /// Hap seçilince (`seviyeSec`): cevaplanmamış kart yeni seviyeyle yeniden hazırlanır.
    public mutating func seviyeSec(_ no: Int, katalog: SiteKatalogu, veri: PekistirmeVerileri, ilerleme il: inout Ilerleme,
                                   rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard case let .sanatci(.donem(akim?)) = kip else { return }
        let kayit = Seviye.kayit(il.seviyeler, akim)
        let yeni: Int? = no >= kayit.s ? nil : no
        guard yeni != seviye else { return }
        seviye = yeni
        if let k = kart, k.sonuc == nil, !k.ikinci {
            sonResim = nil
            kart = nil
            hazirla(katalog: katalog, veri: veri, ilerleme: &il, rastgele: rastgele)
        }
    }
}

extension BolumSeviyesi {
    /// `TANITIM_SEVIYE[sv]`: tanışma eserleri Kolay'ınkiler mi Orta'nınkiler mi (Zor'da tanışma yok)
    var tanitimOrta: Bool? {
        switch self {
        case .kolay, .tanitim(false, _): return false
        case .orta, .tanitim(true, _): return true
        case .zor: return nil
        }
    }
}

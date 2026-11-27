// Z4b · Hikâyeler: verinin uygulamadaki yeri. Hikâyeler sitenin data/sanatci_hikayeleri.json'undan (K3: siteden iner,
// önbelleğe alınır; internet yoksa son inen), eserler ve sanatçılar katalogdan (eserler_onbellek, eser_adlari_tr),
// sesin dizini Z4a'nın `DinleSesKaynagi`'ndan. Okuma yerleri telefonda (UserDefaults; ilerleme kaydına girmez).
import Foundation
import NoraCekirdek

/// Ana ekranda bir yazının satırı
struct HikayeSatiri: Identifiable {
    let hikaye: SanatciHikayesi
    let sanatci: String
    let yillar: String
    let okumaDk: Int
    let dinlemeDk: Int
    let kapak: URL?
    let kapakYedek: URL?
    var id: String { hikaye.id }
}

/// Okuma ekranında bir eser
struct HikayeEserBilgisi {
    let eser: Eser
    let url: URL?
    let yedek: URL?
    /// Görselin en/boy oranı (biliniyorsa; yüklenmeden yer ayırmak için)
    let oran: Double?
}

@MainActor
@Observable
final class HikayeDeposu {
    static let shared = HikayeDeposu()

    enum Durum: Equatable { case yukleniyor, hazir, yok }

    private(set) var durum: Durum = .yukleniyor
    private(set) var hikayeler: [SanatciHikayesi] = []
    private(set) var katalog: SiteKatalogu?
    private(set) var dizin: SesDizini?
    private(set) var yerler: [String: OkumaYeri] = [:]
    /// Z4e: beğenilenler ve sonra okunacaklar (telefonda; ilerleme kaydına ve yedeğe girmez)
    private(set) var kitaplik = HikayeKitapligi()
    /// Z4e: "Yeni" etiketi alan yazılar (son 7 günün en yeni dördü)
    private(set) var yeniler: Set<String> = []
    private var kotuler: [String: [String]] = [:]
    @ObservationIgnored private var eserBellegi: [String: [String: Eser]] = [:]
    @ObservationIgnored private var satirBellegi: [String: HikayeSatiri] = [:]
    @ObservationIgnored private var sureBellegi: [String: [Double]] = [:]
    @ObservationIgnored private var yukleme: Task<Void, Never>?

    private let site = SiteVerisi()
    private static let yerAnahtari = "hikayeYerleri"
    private static let kitaplikAnahtari = "hikayeKitapligi"

    private init() {
        if let v = UserDefaults.standard.data(forKey: Self.yerAnahtari),
           let y = try? JSONDecoder().decode([String: OkumaYeri].self, from: v) {
            yerler = y
        }
        if let v = UserDefaults.standard.data(forKey: Self.kitaplikAnahtari),
           let k = try? JSONDecoder().decode(HikayeKitapligi.self, from: v) {
            kitaplik = k
        }
    }

    /// İlk açılışta ve "yeniden dene"de. `zorla`: diskteki kopya genç de olsa siteden yeniden indir.
    func yukle(zorla: Bool = false) async {
        if let yukleme { return await yukleme.value }
        if durum == .hazir && !zorla { return }
        let g = Task { await self.indir(zorla: zorla) }
        yukleme = g
        await g.value
        yukleme = nil
    }

    private func indir(zorla: Bool) async {
        let site = self.site
        async let veri = site.veri(HikayeVerisi.dosya, zorla: zorla)
        async let kat = SayacDeposu.katalogu()
        async let sesDizini = DinleSesKaynagi.shared.dizin()
        let l = HikayeVerisi.coz(await veri)
        let k = await kat
        let d = await sesDizini
        let il = try? await IlerlemeKoprusu.shared.oku()
        eserBellegi = [:]
        satirBellegi = [:]
        sureBellegi = [:]
        katalog = k
        dizin = d
        kotuler = il?.kotuGorseller ?? [:]
        hikayeler = l
        yeniler = HikayeVitrini.yeniler(l)
        durum = l.isEmpty ? .yok : .hazir
    }

    // MARK: Okuma yerleri

    func yer(_ id: String) -> OkumaYeri? { yerler[id] }

    func yerYaz(_ id: String, _ y: OkumaYeri) {
        guard yerler[id] != y else { return }
        yerler[id] = y
        if let v = try? JSONEncoder().encode(yerler) { UserDefaults.standard.set(v, forKey: Self.yerAnahtari) }
    }

    // MARK: Beğeni, sonra oku (Z4e)

    func begenildi(_ id: String) -> Bool { kitaplik.begenildi(id) }
    func sonradaMi(_ id: String) -> Bool { kitaplik.sonradaMi(id) }

    func begen(_ id: String) {
        kitaplik.begen(id)
        kitapligiYaz()
    }

    func sonraOku(_ id: String) {
        kitaplik.sonraOkuDegistir(id)
        kitapligiYaz()
    }

    private func kitapligiYaz() {
        if let v = try? JSONEncoder().encode(kitaplik) { UserDefaults.standard.set(v, forKey: Self.kitaplikAnahtari) }
    }

    var begenilenler: [SanatciHikayesi] { kitaplik.begenilenler(hikayeler) }
    var sonraOkunacaklar: [SanatciHikayesi] { kitaplik.sonraOkunacaklar(hikayeler, yerler: yerler) }
    var oneCikanlar: [SanatciHikayesi] { HikayeVitrini.oneCikanlar(hikayeler, yerler: yerler) }
    var devamEt: [HikayeVitrini.Devam] { HikayeVitrini.devamEt(hikayeler, yerler: yerler) }
    var enYeni: [SanatciHikayesi] { HikayeVitrini.enYeni(hikayeler) }
    var donemler: [HikayeVitrini.DonemGrubu] { HikayeVitrini.donemler(hikayeler) { self.sanatci($0)?.dogum } }

    /// Satırın durumu: "Yeni" yalnız en yeni dört yazıda (Z4e; önce son 7 günün hepsindeydi)
    func durum(_ h: SanatciHikayesi) -> HikayeAkisi.Durum {
        let d = HikayeAkisi.durum(h, yer: yer(h.id))
        if d == .yeni && !yeniler.contains(h.id) { return .yok }
        return d
    }

    /// Parçaların süreleri (bir kez hesaplanır)
    func sureler(_ h: SanatciHikayesi) -> [Double] {
        if let s = sureBellegi[h.id] { return s }
        let s = HikayeSesi.sureler(HikayeSesi.parcalar(h), dizin: dizin)
        sureBellegi[h.id] = s
        return s
    }

    /// Devam et'te kalan dakika: dinlemede kalındıysa kalan dinleme, değilse kalan okuma
    func kalanDakika(_ d: HikayeVitrini.Devam) -> Int {
        if d.dinleme {
            let s = sureler(d.hikaye)
            let gecen = HikayeSesi.gecen(s, sira: d.yer.parca ?? 0, an: d.yer.an ?? 0)
            return HikayeAkisi.dakika(max(0, s.reduce(0, +) - gecen))
        }
        return HikayeAkisi.kalanDakika(okuma: HikayeAkisi.okumaDakikasi(kelime: d.hikaye.kelime), yer: d.yer)
    }

    /// Çalarda gösterilecek eserler: bölümün eserleri (giriş: ilk bölümünkiler; kapanış: son bölümünkiler)
    func bolumEserleri(_ h: SanatciHikayesi, _ i: HikayeBolumIsareti?) -> [HikayeEserBilgisi] {
        let b: HikayeBolumu?
        if let n = i?.bolum, h.bolumler.indices.contains(n) {
            b = h.bolumler[n]
        } else if i?.kapanis == true {
            b = h.bolumler.last { !$0.eserler.isEmpty }
        } else {
            b = h.bolumler.first { !$0.eserler.isEmpty }
        }
        return (b?.eserler ?? []).compactMap { eser($0.qid, sanatci: h.id) }
    }

    /// Hikâyede anılmayan öbür eserleri (katalogdan; görseli olan, en çok `enCok`): yazının sonundaki "Daha fazla eser"
    func digerEserler(_ h: SanatciHikayesi, enCok: Int = 12) -> [Eser] {
        guard let k = katalog else { return [] }
        let anilan = Set(h.bolumler.flatMap(\.eserler).map(\.qid))
        return Array(k.eserler(h.id).filter { !$0.gorseller.isEmpty && !anilan.contains($0.qid ?? "") }.prefix(enCok))
    }

    /// Hikâyedeki bütün eserler, sırayla (görüntüleyicide kaydırarak gezilsin)
    func hikayeEserleri(_ h: SanatciHikayesi) -> [Eser] {
        var gorulen = Set<String>()
        return h.bolumler.flatMap(\.eserler).compactMap { e in
            guard gorulen.insert(e.qid).inserted else { return nil }
            return eser(e.qid, sanatci: h.id)?.eser
        }
    }

    func gorselAdresi(_ e: Eser, genislik: Int) -> URL? { katalog?.gorselAdresi(e, genislik: genislik, kotuler: kotuler) }

    #if DEBUG
    /// CI (`-hikayeDevam`): Devam et ve Sonra oku dolu görünsün
    func provaDoldur() {
        let t = Date()
        if let v = hikaye("johannes-vermeer") {
            yerYaz(v.id, OkumaYeri(paragraf: 9, toplam: v.paragraflar.count, parca: 14, an: 6, tarih: t))
            if !kitaplik.begenildi(v.id) { kitaplik.begen(v.id) }
        }
        if let r = hikaye("rembrandt-van-rijn") {
            yerYaz(r.id, OkumaYeri(paragraf: 24, toplam: r.paragraflar.count, tarih: t.addingTimeInterval(-60)))
        }
        if !kitaplik.sonradaMi("francisco-de-goya") { kitaplik.sonraOkuDegistir("francisco-de-goya") }
        kitapligiYaz()
    }
    #endif

    // MARK: Katalogdan

    func hikaye(_ id: String) -> SanatciHikayesi? { hikayeler.first { $0.id == id } }

    func sanatci(_ id: String) -> Sanatci? { katalog?.tumSanatcilar.first { $0.id == id } }

    /// Sanatçının adı (katalogda yoksa bağlantıdaki ya da kimlikten)
    func sanatciAdi(_ id: String) -> String { sanatci(id)?.ad ?? id.replacingOccurrences(of: "-", with: " ").capitalized }

    func yillar(_ id: String) -> String {
        guard let s = sanatci(id) else { return "" }
        return SiteYazisi.yillarYaz(dogum: s.dogum, olum: s.olum)
    }

    /// Hikâyedeki eser (qid → katalogdaki eser). Hikâyeler eserleri yalnız katalogdan anar; bulunamayan eser gösterilmez.
    func eser(_ qid: String, sanatci sid: String) -> HikayeEserBilgisi? {
        if eserBellegi[sid] == nil, let k = katalog {
            var m: [String: Eser] = [:]
            for e in k.eserler(sid) { if let q = e.qid, m[q] == nil { m[q] = e } }
            eserBellegi[sid] = m
        }
        guard let k = katalog, let e = eserBellegi[sid]?[qid] else { return nil }
        let g = GorselAdresleri.secilen(e, kotuler: kotuler) ?? e.gorseller.first
        return HikayeEserBilgisi(
            eser: e,
            url: k.gorselAdresi(e, genislik: 1280, kotuler: kotuler),
            yedek: g.flatMap { GorselAdresleri.url(k.gorsel.yedek($0)) },
            oran: g.flatMap { k.gorsel.oran($0) })
    }

    func kucukAdres(_ qid: String?, sanatci sid: String, genislik: Int = 400) -> URL? {
        guard let q = qid, let k = katalog, let e = eser(q, sanatci: sid)?.eser else { return nil }
        return k.gorselAdresi(e, genislik: genislik, kotuler: kotuler)
    }

    /// Ana ekranın satırı (süreler bir kez hesaplanır)
    func satir(_ h: SanatciHikayesi) -> HikayeSatiri {
        if let s = satirBellegi[h.id] { return s }
        let parcalar = HikayeSesi.parcalar(h)
        let sn = HikayeSesi.sureler(parcalar, dizin: dizin).reduce(0, +)
        let kapak = h.kapakQid.flatMap { eser($0, sanatci: h.id) }
        let s = HikayeSatiri(hikaye: h, sanatci: sanatciAdi(h.id), yillar: yillar(h.id),
                             okumaDk: HikayeAkisi.okumaDakikasi(kelime: h.kelime), dinlemeDk: HikayeAkisi.dakika(sn),
                             kapak: kapak?.url, kapakYedek: kapak?.yedek)
        satirBellegi[h.id] = s
        return s
    }

    /// Ana ekranın sırası: yarım kalan en üstte
    var sirali: [SanatciHikayesi] { HikayeAkisi.sirala(hikayeler, yerler: yerler) }

    /// Bağlantılı yazılar (id'si olan ve hikâyesi bulunan, 2–4)
    func baglantilar(_ h: SanatciHikayesi) -> [HikayeBaglantisi] {
        HikayeAkisi.baglantilar(h, hikayeler: Set(hikayeler.map(\.id)))
    }
}

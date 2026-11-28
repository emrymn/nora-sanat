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
    /// Z4h: data/diziler.json (K3: SiteVerisi ile iner ve önbelleğe alınır)
    private(set) var diziKatalogu = DiziKatalogu.bos
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
        async let diziVeri = site.veri(DiziVerisi.dosya, zorla: zorla)
        async let kat = SayacDeposu.katalogu()
        async let sesDizini = DinleSesKaynagi.shared.dizin()
        let l = HikayeVerisi.coz(await veri)
        let dz = DiziVerisi.coz(await diziVeri)
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
        diziKatalogu = dz
        yeniler = HikayeVitrini.yeniler(l)
        durum = l.isEmpty && dz.bosMu ? .yok : .hazir
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

    /// Tüm hikâyeler ve dizi bölümleri (Devam et, Beğendiklerim, Sonra oku için)
    private var tumYazilar: [SanatciHikayesi] { hikayeler + diziKatalogu.tumBolumler.map(\.hikaye) }

    var begenilenler: [SanatciHikayesi] { kitaplik.begenilenler(tumYazilar) }
    var sonraOkunacaklar: [SanatciHikayesi] { kitaplik.sonraOkunacaklar(tumYazilar, yerler: yerler) }
    var oneCikanlar: [SanatciHikayesi] { HikayeVitrini.oneCikanlar(hikayeler, yerler: yerler) }
    var devamEt: [HikayeVitrini.Devam] { HikayeVitrini.devamEt(tumYazilar, yerler: yerler) }
    var enYeni: [SanatciHikayesi] { HikayeVitrini.enYeni(hikayeler) }
    var donemler: [HikayeVitrini.DonemGrubu] { HikayeVitrini.donemler(hikayeler) { self.sanatci($0)?.dogum } }

    // MARK: Diziler (Z4h)

    var diziler: [Dizi] { DiziKurallari.sirala(diziKatalogu, yerler: yerler) }
    func dizi(_ id: String) -> Dizi? { diziKatalogu.dizi(id) }
    func diziBolumu(_ id: String) -> DiziBolumu? { diziKatalogu.bolum(id) }
    func diziBolumleri(_ diziId: String) -> [DiziBolumu] { diziKatalogu.bolumleri(diziId) }
    /// Z4i: sanatçının geçtiği dizi bölümleri (sanatçı sayfası, Bugün)
    func sanatcininBolumleri(_ sanatci: String) -> [DiziBolumu] { diziKatalogu.sanatcininBolumleri(sanatci) }
    func diziAdi(_ h: SanatciHikayesi) -> String? { h.dizi.flatMap { dizi($0)?.ad } }
    func diziIlerleme(_ d: Dizi) -> DiziIlerleme { DiziKurallari.ilerleme(d, katalog: diziKatalogu, yerler: yerler) }
    func bolumDurumu(_ b: DiziBolumu) -> DiziKurallari.BolumDurumu { DiziKurallari.bolumDurumu(b, yer: yer(b.id)) }
    func siradakiBolum(_ d: Dizi) -> DiziBolumu? { DiziKurallari.siradakiBolum(d, katalog: diziKatalogu, yerler: yerler) }
    func diziOkumaDakikasi(_ d: Dizi) -> Int { DiziKurallari.toplamOkumaDakikasi(d, katalog: diziKatalogu) }

    func sonrakiBolumler(_ h: SanatciHikayesi, enCok: Int = 2) -> [DiziBolumu] {
        guard let did = h.dizi else { return [] }
        return DiziKurallari.siradaki(diziKatalogu, diziId: did, simdikiBolumId: h.id, yerler: yerler, enCok: enCok)
    }

    func ilgiliSanatciHikayeleri(_ h: SanatciHikayesi) -> [SanatciHikayesi] {
        var gorulen = Set<String>()
        return h.sanatcilar.compactMap { sid in
            guard gorulen.insert(sid).inserted else { return nil }
            return hikaye(sid)
        }
    }

    func diziKapaklari(_ d: Dizi, enCok: Int = 3, genislik: Int = 800) -> [HikayeEserBilgisi] {
        DiziKurallari.kapakEserleri(d, katalog: diziKatalogu, enCok: enCok)
            .compactMap { eser($0, varsayilanSanatci: $0.sanatci ?? "", genislik: genislik) }
    }

    func diziZeminTablosu(_ d: Dizi) -> URL? {
        guard let ilk = DiziKurallari.kapakEserleri(d, katalog: diziKatalogu, enCok: 1).first else { return nil }
        return eser(ilk, varsayilanSanatci: ilk.sanatci ?? "", genislik: 400)?.url
    }

    func diziDonem(_ d: Dizi) -> String? {
        DiziKurallari.donemSanatcisi(d, katalog: diziKatalogu).flatMap(donem)
    }

    func dinlenebilir(_ h: SanatciHikayesi) -> Bool { HikayeSesi.dinlenebilir(h, dizin: dizin) }

    func yaziVeyaBolum(_ id: String) -> SanatciHikayesi? { hikaye(id) ?? diziBolumu(id)?.hikaye }

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
        return (b?.eserler ?? []).compactMap { eser($0, varsayilanSanatci: h.id) }
    }

    /// Hikâyede anılmayan öbür eserleri (katalogdan; görseli olan, en çok `enCok`): yazının sonundaki "Daha fazla eser"
    func digerEserler(_ h: SanatciHikayesi, enCok: Int = 12) -> [Eser] {
        guard h.dizi == nil, let k = katalog else { return [] }
        let anilan = Set(h.bolumler.flatMap(\.eserler).map(\.qid))
        return Array(k.eserler(h.id).filter { !$0.gorseller.isEmpty && !anilan.contains($0.qid ?? "") }.prefix(enCok))
    }

    /// Hikâyedeki bütün eserler, sırayla (görüntüleyicide kaydırarak gezilsin)
    func hikayeEserleri(_ h: SanatciHikayesi) -> [Eser] {
        var gorulen = Set<String>()
        return h.bolumler.flatMap(\.eserler).compactMap { e in
            let k = e.kimlik
            guard !k.isEmpty, gorulen.insert(k).inserted else { return nil }
            return eser(e, varsayilanSanatci: h.id)?.eser
        }
    }

    /// Z4f: sanatçının döneminin deseni (`SayfaZemini`, Galeri'deki gibi; Emre: arkadaki hale ve semboller)
    func donem(_ id: String) -> String? {
        guard let k = katalog, let s = sanatci(id) else { return nil }
        return GaleriDonem.akimin(k, s.akim)
    }

    func donem(_ h: SanatciHikayesi) -> String? {
        h.ilgiliSanatcilar.lazy.compactMap(donem).first
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

    /// Yazı ya da dizi bölümünün sanatçı satırı ("Leonardo da Vinci · Michelangelo")
    func sanatciAdlari(_ h: SanatciHikayesi) -> String {
        if !h.sanatcilar.isEmpty {
            return h.sanatcilar.map(sanatciAdi).joined(separator: " · ")
        }
        return sanatciAdi(h.id)
    }

    func yillar(_ id: String) -> String {
        guard let s = sanatci(id) else { return "" }
        return SiteYazisi.yillarYaz(dogum: s.dogum, olum: s.olum)
    }

    /// Hikâyedeki eser (qid → katalogdaki eser). Hikâyeler eserleri yalnız katalogdan anar; bulunamayan eser gösterilmez.
    func eser(_ qid: String, sanatci sid: String, genislik: Int = 1280) -> HikayeEserBilgisi? {
        if eserBellegi[sid] == nil, let k = katalog {
            var m: [String: Eser] = [:]
            for e in k.eserler(sid) { if let q = e.qid, m[q] == nil { m[q] = e } }
            eserBellegi[sid] = m
        }
        guard let k = katalog, let e = eserBellegi[sid]?[qid] else { return nil }
        let g = GorselAdresleri.secilen(e, kotuler: kotuler) ?? e.gorseller.first
        return HikayeEserBilgisi(
            eser: e,
            url: k.gorselAdresi(e, genislik: genislik, kotuler: kotuler),
            yedek: g.flatMap { GorselAdresleri.url(k.gorsel.yedek($0)) },
            oran: g.flatMap { k.gorsel.oran($0) })
    }

    /// Z4h: hem `qid` hem `commons` (Wikimedia Commons dosya adı) destekli eser çözücü.
    func eser(_ e: HikayeEseri, varsayilanSanatci sid: String, genislik: Int = 1280) -> HikayeEserBilgisi? {
        let s = e.sanatciKimligi(varsayilan: sid)
        if !e.qid.isEmpty { return eser(e.qid, sanatci: s, genislik: genislik) }
        guard let dosya = e.commons, !dosya.isEmpty else { return nil }
        let norm = SiteYazisi.dosyaNormal(dosya)
        let normKucuk = norm.lowercased()
        if let k = katalog {
            if let katalogEseri = k.eserler(s).first(where: { es in
                es.gorseller.contains { $0.k == "commons" && SiteYazisi.dosyaNormal($0.d).lowercased() == normKucuk }
            }) {
                let g = GorselAdresleri.secilen(katalogEseri, kotuler: kotuler) ?? katalogEseri.gorseller.first
                return HikayeEserBilgisi(
                    eser: katalogEseri,
                    url: k.gorselAdresi(katalogEseri, genislik: genislik, kotuler: kotuler),
                    yedek: g.flatMap { GorselAdresleri.url(k.gorsel.yedek($0)) },
                    oran: g.flatMap { k.gorsel.oran($0) })
            }
            let kurs = sanatci(s)?.kursEserleri.first { SiteYazisi.dosyaNormal($0.commonsDosya).lowercased() == normKucuk }
            let es = DiziKurallari.commonsEseri(dosya: norm, sanatci: s, kurs: kurs)
            let g = es.gorseller.first
            return HikayeEserBilgisi(
                eser: es,
                url: g.flatMap { GorselAdresleri.url(k.gorsel.url($0, genislik: genislik)) },
                yedek: g.flatMap { GorselAdresleri.url(k.gorsel.yedek($0)) },
                oran: g.flatMap { k.gorsel.oran($0) })
        }
        let es = DiziKurallari.commonsEseri(dosya: norm, sanatci: s)
        return HikayeEserBilgisi(
            eser: es,
            url: GorselAdresleri.url(GorselAdresleri.commonsKucuk(norm, genislik: genislik)),
            yedek: GorselAdresleri.url(SiteYazisi.resimUrl(norm, genislik: 800)),
            oran: nil)
    }

    func kapakEseri(_ h: SanatciHikayesi, genislik: Int = 1280) -> HikayeEserBilgisi? {
        h.kapakEseri.flatMap { eser($0, varsayilanSanatci: h.id, genislik: genislik) }
    }

    func kapakAdresi(_ h: SanatciHikayesi, genislik: Int = 400) -> URL? {
        kapakEseri(h, genislik: genislik)?.url
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
        let kapak = kapakEseri(h, genislik: 1280)
        let s = HikayeSatiri(hikaye: h, sanatci: sanatciAdlari(h), yillar: h.dizi == nil ? yillar(h.id) : "",
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

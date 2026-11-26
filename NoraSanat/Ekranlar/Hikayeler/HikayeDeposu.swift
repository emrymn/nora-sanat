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
    private var kotuler: [String: [String]] = [:]
    @ObservationIgnored private var eserBellegi: [String: [String: Eser]] = [:]
    @ObservationIgnored private var satirBellegi: [String: HikayeSatiri] = [:]
    @ObservationIgnored private var yukleme: Task<Void, Never>?

    private let site = SiteVerisi()
    private static let yerAnahtari = "hikayeYerleri"

    private init() {
        if let v = UserDefaults.standard.data(forKey: Self.yerAnahtari),
           let y = try? JSONDecoder().decode([String: OkumaYeri].self, from: v) {
            yerler = y
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
        katalog = k
        dizin = d
        kotuler = il?.kotuGorseller ?? [:]
        hikayeler = l
        durum = l.isEmpty ? .yok : .hazir
    }

    // MARK: Okuma yerleri

    func yer(_ id: String) -> OkumaYeri? { yerler[id] }

    func yerYaz(_ id: String, _ y: OkumaYeri) {
        guard yerler[id] != y else { return }
        yerler[id] = y
        if let v = try? JSONEncoder().encode(yerler) { UserDefaults.standard.set(v, forKey: Self.yerAnahtari) }
    }

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

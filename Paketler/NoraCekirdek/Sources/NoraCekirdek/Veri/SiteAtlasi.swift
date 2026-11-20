// Kaynak: sanat-atlasi js/app.js `basla()` @ a866b86 (site 1.90.3)
// Sitenin açılışta kurduğu veri (`d`): görünür sanatçılar ve akımlar, kurs konuları, kısa adlar, eser listeleri ve
// görsel adresleri. Ekranlar bunu kullanır; veri dosyalarını `SiteVerisi` indirir.
import Foundation

public final class SiteAtlasi: @unchecked Sendable {
    /// Atlasın okuduğu dosyalar. İlk üçü zorunlu (sitede de öyle: biri inmezse site açılmaz).
    public static let dosyalar = [
        "data/sanatcilar.json", "data/akimlar.json", "data/konular.json",
        "data/eser_turleri.json", "data/eser_adlari_tr.json", "data/yerel_gorseller.json", "data/gorsel_oranlari.json",
        "data/gorsel_kaynagi.json", "data/kopya_eserler.json", "data/cikarilan_gorseller.json",
        "data/eser_duzeltmeleri.json", "data/eserler_onbellek.json", "data/kisa_adlar.json",
    ]
    public static let zorunlu = Array(dosyalar.prefix(3))

    public enum Hata: Error, Equatable { case eksikDosya(String), bozukDosya(String) }

    /// Bütün sanatçılar (heykeltıraş ve mimarlar dahil), akımları birleşmiş
    public let tumSanatcilar: [Sanatci]
    /// Gösterilen (resim yapan) sanatçılar, dosyadaki sırayla (`d.sanatcilar`)
    public let sanatcilar: [Sanatci]
    /// Kimlikten görünür sanatçıya (`d.harita`)
    public let harita: [String: Sanatci]
    /// En az bir görünür sanatçısı olan akımlar, `sira`'ya göre (`d.akimlar`)
    public let akimlar: [Akim]
    /// Birleşmiş bütün akımlar (renkler için)
    public let tumAkimlar: [Akim]
    public let konular: [Konu]
    /// Eseri olan kurs konuları ve kapakları (`d.kursKonulari`)
    public let kursKonulari: [KursKonusu]
    /// data/kisa_adlar.json
    public let kisaAdlar: [String: KisaAd]
    /// Görselleri çoğunlukla dikey sanatçılar (data/gorsel_oranlari.json `dikeyler`); dosya yoksa nil
    public let dikeyler: Set<String>?
    public let gorsel: GorselKaynagi
    public let kurallar: EserKurallari

    private var bellek: [String: [Eser]] = [:]
    private let kilit = NSLock()

    /// `veri`: dosya yolu ("data/sanatcilar.json") → içerik. Eksik isteğe bağlı dosyalar boş sayılır.
    public init(veri: [String: Data], site: URL = SiteVerisi.site) throws {
        func zorunluCoz<T: Decodable>(_ yol: String, _ tip: T.Type) throws -> T {
            guard let d = veri[yol] else { throw Hata.eksikDosya(yol) }
            do { return try JSONDecoder().decode(T.self, from: d) } catch { throw Hata.bozukDosya(yol) }
        }
        let ham = try zorunluCoz("data/sanatcilar.json", [Sanatci].self)
        let hamAkimlar = try zorunluCoz("data/akimlar.json", [Akim].self)
        konular = try zorunluCoz("data/konular.json", [Konu].self)

        tumSanatcilar = AkimBirlesmesi.sanatcilar(ham)
        kurallar = EserKurallari(turler: veri["data/eser_turleri.json"], onbellek: veri["data/eserler_onbellek.json"],
                                 kopyalar: veri["data/kopya_eserler.json"], cikarilan: veri["data/cikarilan_gorseller.json"],
                                 duzeltmeler: veri["data/eser_duzeltmeleri.json"], adlar: veri["data/eser_adlari_tr.json"],
                                 sanatciAdlari: Dictionary(tumSanatcilar.map { ($0.id, $0.ad) }, uniquingKeysWith: { a, _ in a }))
        let k = kurallar
        sanatcilar = tumSanatcilar.filter { k.resimSanatcisiMi($0) }
        harita = Dictionary(sanatcilar.map { ($0.id, $0) }, uniquingKeysWith: { _, b in b })

        tumAkimlar = AkimBirlesmesi.akimlar(hamAkimlar)
        let gorunurAkimAdlari = Set(sanatcilar.map(\.akim))
        akimlar = tumAkimlar.enumerated()
            .sorted { $0.element.sira < $1.element.sira || ($0.element.sira == $1.element.sira && $0.offset < $1.offset) }
            .map(\.element)
            .filter { gorunurAkimAdlari.contains($0.ad) }

        let (gorunur, kurallar, tum) = (sanatcilar, kurallar, tumSanatcilar)
        kursKonulari = konular.compactMap { k in
            KursKapagi.kapak(k, gorunur, kurallar, tum).map { KursKonusu(konu: k, kapak: $0) }
        }

        var kisa: [String: KisaAd] = [:]
        for (id, v) in JSONNesne.sozluk(JSONNesne.sozluk(veri["data/kisa_adlar.json"])?["adlar"]) ?? [:] {
            guard let v = JSONNesne.sozluk(v) else { continue }
            kisa[id] = KisaAd(buyuk: v["buyuk"] as? String, kucuk: v["kucuk"] as? String)
        }
        kisaAdlar = kisa

        let oranlar = veri["data/gorsel_oranlari.json"]
        dikeyler = (JSONNesne.sozluk(oranlar)?["dikeyler"] as? [Any]).map { Set($0.compactMap { $0 as? String }) }
        gorsel = GorselKaynagi(yerelGorseller: veri["data/yerel_gorseller.json"], oranlar: oranlar,
                               kaynak: veri["data/gorsel_kaynagi.json"], site: site)
    }

    /// Sanatçının eser listesi (en bilinenler önce; kurs eserleri en başta). Bellekte tutulur.
    public func eserler(_ s: Sanatci) -> [Eser] {
        kilit.lock()
        if let l = bellek[s.id] { kilit.unlock(); return l }
        kilit.unlock()
        let l = kurallar.eserler(s)
        kilit.lock()
        bellek[s.id] = l
        kilit.unlock()
        return l
    }

    /// Kimlikle; görünür olmayan sanatçıda boş
    public func eserler(_ sanatciId: String) -> [Eser] {
        harita[sanatciId].map(eserler) ?? []
    }

    /// Sanatçının bilinen (kısa) adı: "Rembrandt", "Leonardo" (js/adlar.js `bilinenAd`)
    public func bilinenAd(_ s: Sanatci) -> String { Adlar.bilinen(s.ad, kisa: kisaAdlar[s.id]) }

    /// Sanatçı adının iki satırı (js/adlar.js `adParcala`)
    public func adParcalari(_ s: Sanatci) -> AdParcalari { Adlar.parcala(s.ad, kisa: kisaAdlar[s.id]) }

    /// Akımın rengi ("#B0643C"); `d.akimRenk`
    public func akimRengi(_ ad: String) -> String? { tumAkimlar.first { $0.ad == AkimBirlesmesi.akimAdi(ad) }?.renk }
}

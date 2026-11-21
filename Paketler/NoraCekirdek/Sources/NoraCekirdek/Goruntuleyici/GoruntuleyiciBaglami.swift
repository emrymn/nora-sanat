// Kaynak: sanat-atlasi js/goruntuleyici.js @ a866b86
import Foundation

/// Bir görselin görüntüleyicide kullanılan adresleri (400 px ışık, 1280/800 px birincil, yedek, 4096 px devasa).
public struct GoruntuleyiciGorselAdresleri: Equatable, Sendable {
    public var isik: URL?
    public var birincil: URL?
    public var yedek: URL?
    public var devasa: URL?

    public init(isik: URL? = nil, birincil: URL? = nil, yedek: URL? = nil, devasa: URL? = nil) {
        self.isik = isik
        self.birincil = birincil
        self.yedek = yedek
        self.devasa = devasa
    }
}

/// Görüntüleyicinin veri katmanı: `SiteVerisi` üzerinden katalog, eser notları, rehberli ayrıntılar,
/// hikâyeler ve ikonografi konularını yükler; künye, görsel adresleri ve yakınlaşma hesaplarını sunar.
public struct GoruntuleyiciBaglami: Sendable {
    public var katalog: SiteKatalogu?
    public var gorselAdresleri: GorselAdresleri
    public var eserNotlari: [String: String]
    public var ayrintilar: [AyrintiKaydi]
    public var hikayeler: [HikayeKaydi]
    public var ikonografiKonulari: [String: IkonografiKonuOzeti]

    public init(
        katalog: SiteKatalogu? = nil,
        gorselAdresleri: GorselAdresleri? = nil,
        eserNotlari: [String: String] = [:],
        ayrintilar: [AyrintiKaydi] = [],
        hikayeler: [HikayeKaydi] = [],
        ikonografiKonulari: [String: IkonografiKonuOzeti] = [:]
    ) {
        self.katalog = katalog
        self.gorselAdresleri = gorselAdresleri ?? katalog?.gorsel ?? GorselAdresleri()
        self.eserNotlari = eserNotlari
        self.ayrintilar = ayrintilar
        self.hikayeler = hikayeler
        self.ikonografiKonulari = ikonografiKonulari
    }

    /// `SiteVerisi` üzerinden görüntüleyiciye gereken bütün veri dosyalarını yükler.
    public static func yukle(siteVerisi: SiteVerisi = SiteVerisi()) async -> GoruntuleyiciBaglami {
        async let kat = try? siteVerisi.katalog()
        async let ekDosyalar = siteVerisi.veriler([
            "eser_notlari.json",
            "eser_ayrintilari.json",
            "eser_hikayeleri.json",
            "ikonografi.json",
        ])
        let k = await kat
        let d = await ekDosyalar
        let notlar = d["eser_notlari.json"].map(GoruntuleyiciKurallari.notlariAl(veri:)) ?? [:]
        let ayr = d["eser_ayrintilari.json"].map(AyrintiKurallari.ayrintilariAl(veri:)) ?? []
        let hik = d["eser_hikayeleri.json"].map(HikayeKurallari.hikayeleriAl(veri:)) ?? []
        let sanatciSet = Set((k?.sanatcilar ?? []).map(\.id))
        let ikono: [String: IkonografiKonuOzeti]
        if let ikonoVeri = d["ikonografi.json"], let ikonoJson = try? JSONDeger.coz(ikonoVeri) {
            ikono = GoruntuleyiciKurallari.ikonografiKonuHaritasi(ikonoJson) { sid in
                sanatciSet.isEmpty || sanatciSet.contains(sid)
            }
        } else {
            ikono = [:]
        }
        return GoruntuleyiciBaglami(
            katalog: k,
            gorselAdresleri: k?.gorsel,
            eserNotlari: notlar,
            ayrintilar: ayr,
            hikayeler: hik,
            ikonografiKonulari: ikono
        )
    }

    /// Eserin seçilen görseli (`secilenGorsel(e, kotuler) || e.gorseller[0]`)
    public func secilenGorsel(_ eser: Eser, kotuler: [String: [String]] = [:]) -> Gorsel? {
        GorselAdresleri.secilen(eser, kotuler: kotuler) ?? eser.gorseller.first
    }

    /// Görselin ışık (400 px), birincil (1280/800 px), yedek ve en büyük (devasa 4096 px) adresleri.
    public func adresler(_ gorsel: Gorsel) -> GoruntuleyiciGorselAdresleri {
        let isik = GorselAdresleri.url(gorselAdresleri.url(gorsel, genislik: 400))
        let birincil = GorselAdresleri.url(gorselAdresleri.url(gorsel, genislik: 800))
        let yedek = GorselAdresleri.url(gorselAdresleri.yedek(gorsel))
        let devasaStr = gorselAdresleri.devasaUrl(gorsel)
        let devasa = devasaStr.isEmpty ? nil : GorselAdresleri.url(devasaStr)
        return GoruntuleyiciGorselAdresleri(isik: isik, birincil: birincil, yedek: yedek, devasa: devasa)
    }

    public func eserNotu(_ eser: Eser) -> String {
        GoruntuleyiciKurallari.eserNotu(sanatciId: eser.sid, eser: eser, eserNotlari: eserNotlari)
    }

    public func ayrinti(_ eser: Eser) -> AyrintiKaydi? {
        AyrintiKurallari.eserinAyrintisi(ayrintilar, eser: eser)
    }

    public func hikaye(_ eser: Eser) -> HikayeKaydi? {
        HikayeKurallari.eserinHikayesi(hikayeler, eser: eser)
    }

    public func konu(_ eser: Eser) -> IkonografiKonuOzeti? {
        GoruntuleyiciKurallari.eserKonusu(eser, harita: ikonografiKonulari)
    }
}

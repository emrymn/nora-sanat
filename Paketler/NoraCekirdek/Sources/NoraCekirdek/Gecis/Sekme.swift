// Kaynak: sanat-atlasi js/ekranlar/yonlendirme.js `rotalar`, js/ekranlar/ortak.js `SEKMELER` @ a866b86 (site 1.90.3)
// Uygulamanın sekmeleri (ISLER.md K1) ve sitenin adreslerinin hangi sekmeye ait olduğu.
// Kâhin: Testler/kahin/kabuk.mjs (sitenin sekme çubuğunda hangi sekmenin seçili olduğu).
import Foundation

/// Uygulamanın sekmeleri. İlk dördü sitenin sekme çubuğundakiler; Ben (İlerleme, Ayarlar) sitede Bugün'ün sağ üstündeki
/// düğmedir, yerli uygulamada ayrı sekme olur.
public enum Sekme: String, CaseIterable, Hashable, Sendable, Identifiable {
    case bugun, yolculuk, galeri, calis, ben

    public var id: String { rawValue }

    /// Sekmenin sitedeki ana sayfası
    public var kokAdres: String {
        switch self {
        case .bugun: return "#/"
        case .yolculuk: return "#/harita"
        case .galeri: return "#/gozat"
        case .calis: return "#/pekistir"
        case .ben: return "#/ilerleme"
        }
    }

    /// Sekme çubuğundaki ad (sitedeki gibi)
    public var baslik: String {
        switch self {
        case .bugun: return "Bugün"
        case .yolculuk: return "Yolculuk"
        case .galeri: return "Galeri"
        case .calis: return "Çalış"
        case .ben: return "Ben"
        }
    }

    /// Sitenin sekme kimliği (`SEKMELER`); Ben sitede sekme değil
    public var siteKimligi: String? {
        switch self {
        case .bugun: return "bugun"
        case .yolculuk: return "harita"
        case .galeri: return "gozat"
        case .calis: return "pekistir"
        case .ben: return nil
        }
    }

    public init?(siteKimligi: String) {
        guard let s = Sekme.allCases.first(where: { $0.siteKimligi == siteKimligi }) else { return nil }
        self = s
    }
}

public enum SiteRotalari {
    /// `rotalar`: [desen, sitenin seçili sekmesi (nil: sekme çubuğu yok)]. Sıra önemli: ilk eşleşen kazanır.
    static let rotalar: [(NSRegularExpression, String?)] = [
        (#"^#?\/?$"#, "bugun"),
        (#"^#\/gozat$"#, "gozat"),
        (#"^#\/ara$"#, "gozat"),
        (#"^#\/zaman$"#, "gozat"),
        (#"^#\/akim-karsilastir\/([^/]+)\/([^/]+)$"#, nil),
        (#"^#\/akim\/(.+)$"#, "gozat"),
        (#"^#\/sanatci\/(.+)\/eserler$"#, "gozat"),
        (#"^#\/sanatci\/(.+)$"#, "gozat"),
        (#"^#\/karsilastir\/([^/]+)\/([^/]+)$"#, nil),
        (#"^#\/basyapitlar$"#, "gozat"),
        (#"^#\/konular$"#, "gozat"),
        (#"^#\/konular\/([^/]+)$"#, "gozat"),
        (#"^#\/konu\/(.+)$"#, "gozat"),
        (#"^#\/basyapit\/(.+)\/ders$"#, "gozat"),
        (#"^#\/basyapit\/(.+)$"#, "gozat"),
        (#"^#\/pekistir$"#, "pekistir"),
        (#"^#\/pekistir\/donem$"#, "pekistir"),
        (#"^#\/pekistir\/ders\/([^/]+)$"#, "pekistir"),
        (#"^#\/pekistir\/ders\/([^/]+)\/gor$"#, nil),
        (#"^#\/pekistir\/ders\/([^/]+)\/ogren$"#, nil),
        (#"^#\/pekistir\/ders\/([^/]+)\/ayirt$"#, nil),
        (#"^#\/pekistir\/ders\/([^/]+)\/sina$"#, "pekistir"),
        (#"^#\/pekistir\/donem\/(.+)$"#, nil),
        (#"^#\/pekistir\/karisik$"#, nil),
        (#"^#\/pekistir\/konu\/(\d+)$"#, nil),
        (#"^#\/pekistir\/hatalar$"#, nil),
        (#"^#\/pekistir\/devam$"#, nil),
        (#"^#\/pekistir\/bolum$"#, nil),
        (#"^#\/pekistir\/ikonografi$"#, nil),
        (#"^#\/pekistir\/bolum\/(\d+-\d+)\/(kolay|orta|zor|tanitim(?:-orta)?(?:-\d+)?)$"#, nil),
        (#"^#\/ilerleme$"#, "bugun"),
        (#"^#\/ayarlar$"#, "bugun"),
        (#"^#\/koleksiyon$"#, "gozat"),
        (#"^#\/harita$"#, "harita"),
        (#"^#\/gunun$"#, "bugun"),
        (#"^#\/gunun\/(.+)$"#, "bugun"),
    ].map { (try! NSRegularExpression(pattern: $0.0), $0.1) }

    /// `location.hash`'i sitenin yaptığı gibi tamamlar ("" → "#/")
    public static func hash(_ adres: String) -> String { adres.isEmpty ? "#/" : adres }

    /// Sitenin bu adreste sekme çubuğunda seçtiği sekme ("bugun", "harita", "gozat", "pekistir");
    /// nil: o sayfada sekme çubuğu yok (pekiştirme kartı, karşılaştırma). Bilinmeyen adres Bugün'e düşer.
    public static func siteSekmesi(_ adres: String) -> String? {
        let h = hash(adres)
        let r = NSRange(h.startIndex..., in: h)
        for (desen, sekme) in rotalar where desen.firstMatch(in: h, range: r) != nil { return sekme }
        return "bugun"
    }

    /// Adresin uygulamadaki sekmesi. İlerleme ve Ayarlar Ben sekmesidir (sitede Bugün seçili görünür).
    /// nil: sekmesiz sayfa (açıldığı sekmede kalır).
    public static func sekme(_ adres: String) -> Sekme? {
        let h = hash(adres)
        if h == "#/ilerleme" || h == "#/ayarlar" { return .ben }
        return siteSekmesi(h).flatMap(Sekme.init(siteKimligi:))
    }

    /// Site yeni bir adres bildirince uygulamanın geçeceği sekme (nil: seçim değişmez). `KabukDurumu.siteAdresiGeldi`.
    /// - Taşınmış (yerli) bir sekmenin adresi her zaman o sekmeyi açar: sitenin bağlantısı yerli ekrana götürür.
    /// - Taşınmamış sekmeye yalnız sitenin sekmesi gerçekten değiştiyse geçilir. Sitenin açılışta ya da yeniden
    ///   yüklenince bildirdiği aynı sekmenin adresi (ör. "#/") widget'la, bildirimle açılmış yerli sekmeyi kapatmaz.
    /// - Sekmesiz sayfa (pekiştirme kartı, karşılaştırma) açıldığı sekmede kalır.
    public static func secim(onceki: String, yeni: String, secili: Sekme, yerli: (Sekme) -> Bool) -> Sekme? {
        guard let s = sekme(yeni), s != secili else { return nil }
        return yerli(s) || s != sekme(onceki) ? s : nil
    }
}

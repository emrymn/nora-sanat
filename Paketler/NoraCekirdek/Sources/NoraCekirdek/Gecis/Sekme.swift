// Kaynak: sanat-atlasi js/ekranlar/yonlendirme.js `rotalar`, js/ekranlar/ortak.js `SEKMELER` @ a866b86 (site 1.90.3)
// Uygulamanın sekmeleri (ISLER.md K1) ve sitenin adreslerinin hangi sekmeye ait olduğu.
// Kâhin: Testler/kahin/kabuk.mjs (sitenin sekme çubuğunda hangi sekmenin seçili olduğu).
import Foundation

/// Uygulamanın sekmeleri. Bugün, Yolculuk, Galeri, Çalış sitenin sekme çubuğundakiler; Ben (İlerleme, Ayarlar) sitede
/// Bugün'ün sağ üstündeki düğmedir, uygulamada da çubukta değil, ana ekranların sağ üstündeki düğmeyle açılır.
/// Z4b: Hikâyeler yeni (sitede yok).
public enum Sekme: String, CaseIterable, Hashable, Sendable, Identifiable {
    case bugun, hikayeler, yolculuk, galeri, calis, ben

    public var id: String { rawValue }

    /// Sekmenin sitedeki ana sayfası
    public var kokAdres: String {
        switch self {
        case .bugun: return "#/"
        case .hikayeler: return "#/hikayeler"
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
        case .hikayeler: return "Hikâyeler"
        case .yolculuk: return "Yolculuk"
        case .galeri: return "Galeri"
        case .calis: return "Çalış"
        case .ben: return "Ben"
        }
    }

    /// Sitenin sekme kimliği (`SEKMELER`); Ben sitede sekme değil, Hikâyeler sitede yok
    public var siteKimligi: String? {
        switch self {
        case .bugun: return "bugun"
        case .yolculuk: return "harita"
        case .galeri: return "gozat"
        case .calis: return "pekistir"
        case .ben, .hikayeler: return nil
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
        // Z4b: sitede olmayan Hikâyeler'in adresleri (uygulamanın kendi bağlantıları: widget, Spotlight)
        if HikayeAdresi.sekmeninMi(h) { return .hikayeler }
        return siteSekmesi(h).flatMap(Sekme.init(siteKimligi:))
    }

    /// Site yeni bir adres bildirince uygulamanın geçeceği sekme (nil: seçim değişmez). `KabukDurumu.siteAdresiGeldi`.
    /// - Taşınmış (yerli) bir sekmenin adresi her zaman o sekmeyi açar: sitenin bağlantısı yerli ekrana götürür.
    /// - Taşınmamış sekmeye yalnız sitenin sekmesi gerçekten değiştiyse geçilir. Sitenin açılışta ya da yeniden
    ///   yüklenince bildirdiği aynı sekmenin adresi (ör. "#/") widget'la, bildirimle açılmış yerli sekmeyi kapatmaz.
    /// - Sekmesiz sayfa (pekiştirme kartı, karşılaştırma) açıldığı sekmede kalır.
    /// - Aynı adres (sitenin açılışta ya da yeniden yüklenince bildirdiği) seçimi hiç değiştirmez (T7: Bugün yerli
    ///   olunca açılıştaki "#/" widget'la açılmış sekmeyi Bugün'e çeviriyordu).
    public static func secim(onceki: String, yeni: String, secili: Sekme, yerli: (Sekme) -> Bool) -> Sekme? {
        guard hash(yeni) != hash(onceki) else { return nil }
        if let y = yerliSekme(yeni), yerli(y) { return y == secili ? nil : y }
        guard let s = sekme(yeni), s != secili else { return nil }
        return s != sekme(onceki) ? s : nil
    }

    /// Yerli ekranların açacağı sekme (T7). `sekme`'nin sekmesiz bıraktığı sayfaları da bir yerli sekmeye verir:
    /// `#/pekistir/…` (tur, ders adımları, kurs bölümü) Çalış'ta, karşılaştırmalar Galeri'de açılır; yerli Çalış ve
    /// Galeri bu adresleri kendi içinde gösterir (`CalisSekmesi.rotayiIsle`, `GaleriYolu`).
    /// Yolculuk'un bölüm turu (`#/pekistir/bolum/<id>/<seviye>`) nil: yerli Yolculuk turu adresle açmaz.
    public static func yerliSekme(_ adres: String) -> Sekme? {
        if let s = sekme(adres) { return s }
        let h = hash(adres)
        if h.hasPrefix("#/pekistir/bolum/") { return nil }
        if h.hasPrefix("#/pekistir/") { return .calis }
        if h.hasPrefix("#/karsilastir/") || h.hasPrefix("#/akim-karsilastir/") { return .galeri }
        return nil
    }
}

/// Z4b · Hikâyeler'in adresleri (sitede yok; uygulama içi): "#/hikayeler" ana ekran, "#/hikaye/<sanatçı>" yazı,
/// Z4h: "#/dizi/<dizi>" dizi sayfası, "#/dizi/<dizi>/<bölüm>" dizi bölümü.
public enum HikayeAdresi {
    public static let kok = "#/hikayeler"

    public static func yazi(_ sanatci: String) -> String { "#/hikaye/\(sanatci)" }
    public static func dizi(_ id: String) -> String { "#/dizi/\(id)" }
    public static func diziBolumu(_ dizi: String, _ bolum: String) -> String { "#/dizi/\(dizi)/\(bolum)" }

    /// Adres bir yazınınsa sanatçının kimliği
    public static func sanatci(_ adres: String) -> String? {
        let h = SiteRotalari.hash(adres)
        guard h.hasPrefix("#/hikaye/") else { return nil }
        let id = String(h.dropFirst("#/hikaye/".count))
        return id.isEmpty || id.contains("/") ? nil : id.removingPercentEncoding ?? id
    }

    /// "#/dizi/<dizi>" ya da "#/dizi/<dizi>/<bölüm>" → (dizi, bolum?)
    public static func diziYolu(_ adres: String) -> (dizi: String, bolum: String?)? {
        let h = SiteRotalari.hash(adres)
        guard h.hasPrefix("#/dizi/") else { return nil }
        let parcalar = String(h.dropFirst("#/dizi/".count))
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { String($0).removingPercentEncoding ?? String($0) }
        guard !parcalar.isEmpty, !parcalar[0].isEmpty, parcalar.count <= 2 else { return nil }
        if parcalar.count == 2 {
            guard !parcalar[1].isEmpty else { return nil }
            return (parcalar[0], parcalar[1])
        }
        return (parcalar[0], nil)
    }

    static func sekmeninMi(_ h: String) -> Bool { h == kok || sanatci(h) != nil || diziYolu(h) != nil }
}

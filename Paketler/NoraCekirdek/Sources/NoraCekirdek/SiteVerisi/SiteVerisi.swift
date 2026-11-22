// Kaynak: sanat-atlasi js/app.js basla() (hangi dosyalar yüklenir) @ a866b86 (site 1.90.3)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Sitenin `data/*.json` dosyalarını indirir ve diskte saklar (K3: veri uygulamaya gömülmez).
/// Dosya `omur`'dan eskiyse yeniden indirilir; indirilemezse (internet yok) son inen kullanılır.
/// Widget da aynı katmanı kendi klasörüyle kullanır (App Group yok, veri paylaşılmaz).
public actor SiteVerisi {
    public static let site = URL(string: "https://sanat-atlasi.pages.dev/")!

    /// `SiteKatalogu`'nun kurulduğu dosyalar (js/app.js basla() sırasıyla; ilk üçü zorunlu)
    public static let katalogDosyalari = [
        "sanatcilar.json", "akimlar.json", "konular.json", "eser_turleri.json", "eser_adlari_tr.json",
        "yerel_gorseller.json", "gorsel_oranlari.json", "gorsel_kaynagi.json", "kopya_eserler.json",
        "cikarilan_gorseller.json", "eser_duzeltmeleri.json", "kisa_adlar.json", "eserler_onbellek.json",
    ]
    static let zorunlu: Set<String> = ["sanatcilar.json", "akimlar.json", "konular.json"]

    public enum Hata: Error, Equatable { case yok(String) }

    public let klasor: URL
    public let omur: TimeInterval
    let kok: URL
    let oturum: URLSession
    private var katalogBellegi: (zaman: Date, katalog: SiteKatalogu)?

    /// - Parameters:
    ///   - klasor: önbellek klasörü (varsayılan: Caches/SiteVerisi)
    ///   - omur: dosya bu kadar eskiyince yeniden indirilir
    ///   - kok: sitenin kökü (testlerde yerel sunucu)
    public init(klasor: URL? = nil, omur: TimeInterval = 6 * 3600, kok: URL = SiteVerisi.site) {
        let k = klasor ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SiteVerisi", isDirectory: true)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        self.klasor = k
        self.omur = omur
        self.kok = kok
        let ayar = URLSessionConfiguration.default
        ayar.timeoutIntervalForRequest = 20
        ayar.requestCachePolicy = .reloadIgnoringLocalCacheData
        oturum = URLSession(configuration: ayar)
    }

    func yerel(_ dosya: String) -> URL {
        klasor.appendingPathComponent(dosya.replacingOccurrences(of: "/", with: "_"))
    }

    /// Diskteki kopyanın yaşı (yoksa sonsuz)
    public nonisolated func yas(_ dosya: String) -> TimeInterval {
        let u = klasor.appendingPathComponent(dosya.replacingOccurrences(of: "/", with: "_"))
        let t = (try? u.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        return t.map { Date().timeIntervalSince($0) } ?? .infinity
    }

    /// `data/<dosya>`: taze kopya ya da yeni indirilen; indirilemezse eski kopya; hiç yoksa nil.
    /// `zorla`: yaşına bakmadan indirmeyi dene.
    public func veri(_ dosya: String, zorla: Bool = false) async -> Data? {
        let u = yerel(dosya)
        if !zorla, yas(dosya) < omur, let d = try? Data(contentsOf: u) { return d }
        if let d = await indir(dosya) {
            try? d.write(to: u, options: .atomic)
            return d
        }
        return try? Data(contentsOf: u)
    }

    /// Birden çok dosya aynı anda; dönen sözlükte yalnız elde edilenler var
    public func veriler(_ dosyalar: [String], zorla: Bool = false) async -> [String: Data] {
        await withTaskGroup(of: (String, Data?).self) { g in
            for f in dosyalar { g.addTask { (f, await self.veri(f, zorla: zorla)) } }
            var s: [String: Data] = [:]
            for await (f, d) in g { if let d { s[f] = d } }
            return s
        }
    }

    /// Sitenin verisi (`d`). Dosyalar tazeyse bellekteki katalog yeniden kurulmaz.
    public func katalog(zorla: Bool = false) async throws -> SiteKatalogu {
        if !zorla, let b = katalogBellegi, Date().timeIntervalSince(b.zaman) < omur { return b.katalog }
        let d = await veriler(Self.katalogDosyalari, zorla: zorla)
        for z in Self.zorunlu where d[z] == nil { throw Hata.yok(z) }
        let k = try SiteKatalogu(dosyalar: d)
        katalogBellegi = (Date(), k)
        return k
    }

    /// Sitenin kökünden bir dosya (`data/` dışında; G3: `basyapit-dersleri/eserler/<klasör>/DERS_ORTA.md`).
    /// `veri` gibi önbelleğe alınır; .json değilse JSON denetimi yapılmaz.
    public func kokDosyasi(_ yol: String, zorla: Bool = false) async -> Data? {
        let ad = "kok/" + yol
        let u = yerel(ad)
        if !zorla, yas(ad) < omur, let d = try? Data(contentsOf: u) { return d }
        if let d = await indir(yol, onek: "", json: yol.hasSuffix(".json")) {
            try? d.write(to: u, options: .atomic)
            return d
        }
        return try? Data(contentsOf: u)
    }

    /// İndirme: 200 ve geçerli JSON ise veri, değilse nil
    func indir(_ dosya: String, onek: String = "data/", json: Bool = true) async -> Data? {
        guard let url = URL(string: onek + dosya, relativeTo: kok) else { return nil }
        let istek = URLRequest(url: url)
        let sonuc: (Data, URLResponse)? = await withCheckedContinuation { devam in
            oturum.dataTask(with: istek) { d, y, h in
                devam.resume(returning: h == nil && d != nil && y != nil ? (d!, y!) : nil)
            }.resume()
        }
        guard let (d, y) = sonuc, (y as? HTTPURLResponse)?.statusCode == 200,
              !json || (try? JSONDeger.coz(d)) != nil else { return nil }
        return d
    }
}

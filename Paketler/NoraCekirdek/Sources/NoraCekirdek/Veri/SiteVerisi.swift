// Sitenin veri dosyalarını (data/*.json) indirir ve diskte saklar (ISLER.md K3: veri siteden gelir, uygulamaya gömülmez).
// - Dosya `omur`'den gençse indirilmez.
// - Eskiyse ETag'le sorulur (değişmediyse 304, yeniden indirilmez).
// - İnternet yoksa ya da yanıt bozuksa son indirilen kullanılır.
// Widget (TabloYukleyici) ve uygulama aynı türü kendi klasörleriyle kullanır (ücretsiz Apple ID'de ortak klasör yok).
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct SiteVerisi: Sendable {
    public static let site = URL(string: "https://sanat-atlasi.pages.dev/")!

    /// İstek → (veri, yanıt). Testlerde sahte indirici verilir.
    public typealias Indirici = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    public let klasor: URL
    public let site: URL
    /// Bu kadar yeni dosya için ağa çıkılmaz
    public let omur: TimeInterval
    let indirici: Indirici

    public init(klasor: URL? = nil, site: URL = SiteVerisi.site, omur: TimeInterval = 6 * 3600, indirici: Indirici? = nil) {
        let k = klasor ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SiteVerisi", isDirectory: true)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        self.klasor = k
        self.site = site
        self.omur = omur
        if let indirici {
            self.indirici = indirici
        } else {
            let ayar = URLSessionConfiguration.default
            ayar.timeoutIntervalForRequest = 20
            ayar.requestCachePolicy = .reloadIgnoringLocalCacheData
            let oturum = URLSession(configuration: ayar)
            self.indirici = { try await oturum.data(for: $0) }
        }
    }

    /// Önbellekteki dosyanın yeri: "data/x.json" → "<klasör>/data_x.json"
    public func yerel(_ yol: String) -> URL {
        klasor.appendingPathComponent(yol.replacingOccurrences(of: "/", with: "_"))
    }

    /// Dosyanın son indirilme zamanı (önbellekte yoksa nil)
    public func indirilme(_ yol: String) -> Date? {
        try? yerel(yol).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    /// Bir dosya: tazeyse önbellekten, değilse siteden (olmazsa önbellekten). `zorla`: yaşına bakmadan siteye sor.
    public func dosya(_ yol: String, zorla: Bool = false) async -> Data? {
        let yerel = yerel(yol)
        let eski = try? Data(contentsOf: yerel)
        if !zorla, eski != nil, let t = indirilme(yol), Date().timeIntervalSince(t) < omur { return eski }
        guard let url = URL(string: yol, relativeTo: site) else { return eski }
        var istek = URLRequest(url: url)
        istek.cachePolicy = .reloadIgnoringLocalCacheData
        let etagYeri = yerel.appendingPathExtension("etag")
        if eski != nil, let etag = try? String(contentsOf: etagYeri, encoding: .utf8), !etag.isEmpty {
            istek.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        guard let (veri, yanit) = try? await indirici(istek), let h = yanit as? HTTPURLResponse else { return eski }
        if h.statusCode == 304, eski != nil {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: yerel.path)
            return eski
        }
        guard h.statusCode == 200, (try? JSONSerialization.jsonObject(with: veri)) != nil else { return eski }
        try? veri.write(to: yerel, options: .atomic)
        if let etag = h.value(forHTTPHeaderField: "ETag"), !etag.isEmpty {
            try? etag.write(to: etagYeri, atomically: true, encoding: .utf8)
        } else {
            try? FileManager.default.removeItem(at: etagYeri)
        }
        return veri
    }

    /// Birden çok dosya aynı anda; inmeyen (ve önbellekte de olmayan) dosya sözlükte yer almaz
    public func dosyalar(_ yollar: [String], zorla: Bool = false) async -> [String: Data] {
        await withTaskGroup(of: (String, Data?).self) { grup in
            for yol in yollar { grup.addTask { (yol, await self.dosya(yol, zorla: zorla)) } }
            var sonuc: [String: Data] = [:]
            for await (yol, veri) in grup { if let veri { sonuc[yol] = veri } }
            return sonuc
        }
    }

    /// Sitenin açılıştaki verisi (`SiteAtlasi.dosyalar`). Zorunlu dosyalardan biri hiç inmemişse hata.
    public func atlas(zorla: Bool = false) async throws -> SiteAtlasi {
        let veri = await dosyalar(SiteAtlasi.dosyalar, zorla: zorla)
        return try SiteAtlasi(veri: veri, site: site)
    }
}

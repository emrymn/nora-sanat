// Eser görsellerinin disk önbelleği (ISLER.md T3 `Gorsel`). Görsel adresleri değişmez (R2'de yeni sürüm yeni adla
// gelir: js/gorsel.js İş 84, İş 118), bu yüzden bir kez inen görsel bir daha sorulmaz.
// - Dosya: Caches/Gorseller/<adresin MD5'i>. iOS yer daralınca Caches'i boşaltabilir; öyle olursa yeniden iner.
// - Aynı adres için aynı anda tek indirme yapılır; bekleyenler aynı sonucu alır.
// - Toplam boyut `sinir`'ı aşınca en uzun süredir kullanılmayanlar silinir.
// - C5: telefona indirilmiş görseller (`CevrimdisiDepo`, Ayarlar'daki "En büyük kopyaları telefona indir") önce oradan
//   okunur; internet yokken de görünür.
// Çözme ve küçültme (ImageIO) uygulamada: NoraSanat/Kabuk/Gorsel.swift.
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor GorselDeposu {
    public typealias Indirici = @Sendable (URL) async throws -> (Data, URLResponse)

    public enum Hata: Error, Equatable {
        /// Sunucu görseli vermedi (HTTP durum kodu)
        case yanit(Int)
        case bos
    }

    public static let shared = GorselDeposu()

    public let klasor: URL
    /// Bayt; aşılınca en eski kullanılanlar silinir
    public let sinir: Int
    private let indirici: Indirici
    /// Telefona indirilmiş görseller (C5); önce burada aranır
    public nonisolated let cevrimdisi: CevrimdisiDepo?
    private var surenler: [URL: Task<Data, Error>] = [:]
    private var yazilanBayt = 0

    public init(klasor: URL? = nil, sinir: Int = 400 * 1024 * 1024, indirici: Indirici? = nil,
                cevrimdisi: CevrimdisiDepo? = .varsayilan) {
        self.cevrimdisi = cevrimdisi
        let k = klasor ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Gorseller", isDirectory: true)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        self.klasor = k
        self.sinir = sinir
        if let indirici {
            self.indirici = indirici
        } else {
            let ayar = URLSessionConfiguration.default
            ayar.timeoutIntervalForRequest = 30
            ayar.urlCache = nil   // önbellek burası; URLCache ikinci kopya tutmasın
            ayar.httpMaximumConnectionsPerHost = 6
            let oturum = URLSession(configuration: ayar)
            self.indirici = { try await oturum.data(from: $0) }
        }
    }

    /// Adresin diskteki yeri
    public nonisolated func dosya(_ url: URL) -> URL {
        klasor.appendingPathComponent(SiteYazisi.md5(url.absoluteString))
    }

    /// Diskte varsa (indirmeden)
    public nonisolated func diskte(_ url: URL) -> Data? {
        cevrimdisi?.veri(url.absoluteString) ?? (try? Data(contentsOf: dosya(url)))
    }

    /// Görselin baytları: diskte varsa oradan (kullanım zamanı tazelenir), yoksa indirip diske yazar.
    public func veri(_ url: URL) async throws -> Data {
        if let d = cevrimdisi?.veri(url.absoluteString) { return d }
        let yer = dosya(url)
        if let d = try? Data(contentsOf: yer), !d.isEmpty {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: yer.path)
            return d
        }
        if let suren = surenler[url] { return try await suren.value }
        let indirici = self.indirici
        let is_ = Task<Data, Error> {
            let (d, yanit) = try await indirici(url)
            if let h = yanit as? HTTPURLResponse, !(200..<300).contains(h.statusCode) { throw Hata.yanit(h.statusCode) }
            guard !d.isEmpty else { throw Hata.bos }
            return d
        }
        surenler[url] = is_
        defer { surenler[url] = nil }
        let d = try await is_.value
        try? d.write(to: yer, options: .atomic)
        yazilanBayt += d.count
        if yazilanBayt > sinir / 20 {   // her ~20 MB'ta bir sınırı denetle
            yazilanBayt = 0
            budama()
        }
        return d
    }

    /// Toplam boyut (bayt)
    public func boyut() -> Int {
        dosyalar().reduce(0) { $0 + $1.boyut }
    }

    /// Sınır aşıldıysa en uzun süredir kullanılmayanları siler (sınırın %80'ine iner)
    public func budama() {
        var l = dosyalar()
        var toplam = l.reduce(0) { $0 + $1.boyut }
        guard toplam > sinir else { return }
        l.sort { $0.zaman < $1.zaman }
        let hedef = sinir * 8 / 10
        for d in l where toplam > hedef {
            try? FileManager.default.removeItem(at: d.url)
            toplam -= d.boyut
        }
    }

    /// Hepsini siler
    public func temizle() {
        for d in dosyalar() { try? FileManager.default.removeItem(at: d.url) }
    }

    private func dosyalar() -> [(url: URL, boyut: Int, zaman: Date)] {
        let anahtarlar: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let l = (try? FileManager.default.contentsOfDirectory(at: klasor, includingPropertiesForKeys: anahtarlar)) ?? []
        return l.compactMap { u in
            guard let v = try? u.resourceValues(forKeys: Set(anahtarlar)) else { return nil }
            return (u, v.fileSize ?? 0, v.contentModificationDate ?? .distantPast)
        }
    }
}

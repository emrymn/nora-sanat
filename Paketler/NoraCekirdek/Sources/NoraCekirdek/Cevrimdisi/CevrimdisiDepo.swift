// Kaynak: sanat-atlasi js/devasaOnbellek.js (kaliciYaz, kaliciOku, kaliciAdresler, kaliciSil, defterAdi) @ a866b86
import Foundation

/// Telefona indirilmiş görseller (C5). Sitede IndexedDB (`atlas-devasa`); burada Application Support/CevrimdisiGorseller
/// altında dosyalar. Caches değil: iOS yer daralınca Caches'i boşaltabilir, kullanıcının bilerek indirdiği 21 GB
/// gitmesin. iCloud yedeğine girmez.
///
/// Dosya adı adresin türü ve adı: `…/d/<ad>[-sürüm].jpg` → `d-<ad>[-sürüm].jpg` (sitenin `defterAdi`'yle aynı kalıp).
/// Böylece klasörün listesi hangi adreslerin telefonda olduğunu söyler; ayrı bir defter gerekmez.
/// `GorselDeposu` (uygulamanın görsel önbelleği) bir adresi önce burada arar: internet yokken de görünür.
public struct CevrimdisiDepo: Sendable {
    public static let varsayilan = CevrimdisiDepo()

    public let klasor: URL

    public init(klasor: URL? = nil) {
        self.klasor = klasor ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CevrimdisiGorseller", isDirectory: true)
    }

    private static let kalip = try! NSRegularExpression(pattern: "/([dbk])/([0-9a-f]{12,}(?:-[0-9a-f]{4,16})?)\\.jpg")

    /// Adresin dosya adı; listede olabilecek bir adres değilse nil (`defterAdi` kalıbı)
    public static func dosyaAdi(_ url: String) -> String? {
        let ns = url as NSString
        guard let m = kalip.firstMatch(in: url, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return "\(ns.substring(with: m.range(at: 1)))-\(ns.substring(with: m.range(at: 2))).jpg"
    }

    public func dosya(_ url: String) -> URL? { Self.dosyaAdi(url).map { klasor.appendingPathComponent($0) } }

    /// İndirilmişse baytları
    public func veri(_ url: String) -> Data? {
        guard let f = dosya(url), let d = try? Data(contentsOf: f), !d.isEmpty else { return nil }
        return d
    }

    public func varMi(_ url: String) -> Bool {
        dosya(url).map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    /// Klasörü kurar (yedeğe girmez)
    public func hazirla() throws {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: klasor.path) else { return }
        try fm.createDirectory(at: klasor, withIntermediateDirectories: true)
        #if os(iOS)
        var k = klasor
        var v = URLResourceValues()
        v.isExcludedFromBackup = true
        try? k.setResourceValues(v)
        #endif
    }

    /// İnen dosyayı yerine taşır (indirme görevinin geçici dosyası). Yer yoksa hata `CocoaError.fileWriteOutOfSpace`.
    public func tasi(_ gecici: URL, adres: String) throws {
        guard let hedef = dosya(adres) else { throw CocoaError(.fileWriteInvalidFileName) }
        try hazirla()
        let fm = FileManager.default
        if fm.fileExists(atPath: hedef.path) { try fm.removeItem(at: hedef) }
        try fm.moveItem(at: gecici, to: hedef)
    }

    public func yaz(_ veri: Data, adres: String) throws {
        guard let hedef = dosya(adres) else { throw CocoaError(.fileWriteInvalidFileName) }
        try hazirla()
        try veri.write(to: hedef, options: .atomic)
    }

    /// Klasördeki dosya adları
    public func adlar() -> Set<String> {
        Set(((try? FileManager.default.contentsOfDirectory(atPath: klasor.path)) ?? []).filter { $0.hasSuffix(".jpg") })
    }

    /// Toplam boyut (bayt)
    public func boyut() -> Int {
        let l = (try? FileManager.default.contentsOfDirectory(at: klasor, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return l.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) }
    }

    public struct Sayim: Sendable, Equatable {
        /// Listedekilerden telefonda olanlar
        public let adresler: Set<String>
        /// Listede olmadığı için silinenler
        public let silinen: Int
        /// Listede olmayan ama silinmeyenler (çok fazlaydı)
        public let korundu: Int
    }

    /// Listedekilerden telefonda olanlar. `sil` ise listede olmayan dosyalar (eski sürüm, çıkarılan görsel) silinir;
    /// ama telefondakilerin %20'sinden (en az 20) fazlaysa liste yanlış hesaplanmış olabilir, hiçbiri silinmez
    /// (`kaliciAdresler`, İş 127).
    public func telefondakiler(_ liste: [String], sil: Bool = true) -> Sayim {
        let var_ = adlar()
        var adresler = Set<String>(), listedeki = Set<String>()
        for u in liste {
            guard let a = Self.dosyaAdi(u) else { continue }
            listedeki.insert(a)
            if var_.contains(a) { adresler.insert(u) }
        }
        let disarida = var_.subtracting(listedeki)
        let toplam = var_.intersection(listedeki).count + disarida.count
        let korundu = Double(disarida.count) > max(20, Double(toplam) * 0.2)
        if sil && !korundu {
            for a in disarida { try? FileManager.default.removeItem(at: klasor.appendingPathComponent(a)) }
        }
        return Sayim(adresler: adresler, silinen: korundu || !sil ? 0 : disarida.count, korundu: korundu ? disarida.count : 0)
    }

    /// Hepsini siler (`kaliciSil`)
    public func temizle() {
        try? FileManager.default.removeItem(at: klasor)
    }
}

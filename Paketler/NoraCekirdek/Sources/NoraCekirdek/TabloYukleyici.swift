#if canImport(ImageIO)
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Widget için günün tablosunu ve görselini siteden indirir; kendi önbelleğinde saklar.
/// İnternet yoksa son indirilen veriyle çalışır (tablo yine günün kuralıyla seçilir; görseli önceden inmemişse görselsiz).
public actor TabloYukleyici {
    public struct Sonuc: Sendable {
        public let tablo: GununTablosu
        public let gorsel: CGImage?
    }

    /// Veri dosyaları bu kadar eskiyince yeniden indirilir
    let veriOmru: TimeInterval = 2 * 24 * 3600
    /// Widget'ın bellek sınırı küçük (~30 MB): görsel en uzun kenarı bu kadar piksele küçültülür
    let enBuyukPiksel = 1000

    let klasor: URL
    let oturum: URLSession

    public init(klasor: URL? = nil) {
        let k = klasor ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GununTablosu", isDirectory: true)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        self.klasor = k
        let ayar = URLSessionConfiguration.default
        ayar.timeoutIntervalForRequest = 20
        ayar.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.oturum = URLSession(configuration: ayar)
    }

    public func yukle(tarih: String) async throws -> Sonuc {
        let veriler = try await veriDosyalari()
        let tablo = try GununTablosuCozucu.coz(tarih: tarih, yuruyus: veriler[0], sanatcilar: veriler[1],
                                               adlar: veriler[2], kaynak: veriler[3])
        return Sonuc(tablo: tablo, gorsel: await gorsel(tablo))
    }

    /// Sıra: GununTablosuCozucu.dosyalar. İlk ikisi zorunlu.
    func veriDosyalari() async throws -> [Data?] {
        var sonuc: [Data?] = []
        for yol in GununTablosuCozucu.dosyalar {
            let yerel = klasor.appendingPathComponent(yol.replacingOccurrences(of: "/", with: "_"))
            let yas = (try? yerel.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                .map { Date().timeIntervalSince($0) } ?? .infinity
            var veri: Data? = nil
            if yas > veriOmru, let url = URL(string: yol, relativeTo: GununTablosuCozucu.site),
               let (d, yanit) = await indir(url),
               (yanit as? HTTPURLResponse)?.statusCode == 200, (try? JSONSerialization.jsonObject(with: d)) != nil {
                try? d.write(to: yerel, options: .atomic)
                veri = d
            }
            sonuc.append(veri ?? (try? Data(contentsOf: yerel)))
        }
        guard sonuc[0] != nil, sonuc[1] != nil else { throw URLError(.notConnectedToInternet) }
        return sonuc
    }

    func gorsel(_ t: GununTablosu) async -> CGImage? {
        guard let url = t.gorsel else { return nil }
        let ad = url.lastPathComponent.replacingOccurrences(of: "/", with: "_")
        let yerel = klasor.appendingPathComponent("gorsel-\(ad)")
        if let d = try? Data(contentsOf: yerel), let g = kucult(d) { return g }
        guard let (d, yanit) = await indir(url),
              (yanit as? HTTPURLResponse)?.statusCode == 200, let g = kucult(d) else { return nil }
        // Eski günlerin görsellerini sil, yalnız bugününkü kalsın
        if let eski = try? FileManager.default.contentsOfDirectory(at: klasor, includingPropertiesForKeys: nil) {
            for u in eski where u.lastPathComponent.hasPrefix("gorsel-") { try? FileManager.default.removeItem(at: u) }
        }
        if let jpeg = jpegVerisi(g) { try? jpeg.write(to: yerel, options: .atomic) }
        return g
    }

    /// Hata yerine nil (koşullarda kullanılabilsin)
    func indir(_ url: URL) async -> (Data, URLResponse)? {
        try? await oturum.data(from: url)
    }

    func kucult(_ veri: Data) -> CGImage? {
        guard let kaynak = CGImageSourceCreateWithData(veri as CFData, nil) else { return nil }
        let secenek: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: enBuyukPiksel,
        ]
        return CGImageSourceCreateThumbnailAtIndex(kaynak, 0, secenek as CFDictionary)
    }

    func jpegVerisi(_ g: CGImage) -> Data? {
        let veri = NSMutableData()
        guard let hedef = CGImageDestinationCreateWithData(veri, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(hedef, g, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(hedef) ? veri as Data : nil
    }
}
#endif

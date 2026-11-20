import ImageIO
import NoraCekirdek
import SwiftUI
import UIKit

/// Disk önbellekli uzak görsel (eser görselleri). Baytlar `GorselDeposu`'nda (Caches/Gorseller) durur; görsel, kutunun
/// piksel boyuna küçültülerek çözülür ve bellekte tutulur. Yüklenene kadar temanın yüzey rengi görünür, sonra yumuşakça
/// belirir. Hata olursa yer tutucu kalır.
///
///     UzakGorsel(url: katalog.gorselAdresi(eser, genislik: 400, kotuler: il.kotuGorseller))
///         .frame(width: 120, height: 160).clipped()
///
/// Not: Adı `UzakGorsel`; `Gorsel` NoraCekirdek'teki görsel modelidir (`{ k, d, u, i, … }`).
struct UzakGorsel: View {
    let url: URL?
    var icerik: ContentMode = .fill
    /// Yüklenemezse (ör. 404) denenecek ikinci adres (`katalog.gorsel.yedek`)
    var yedek: URL? = nil

    @Environment(\.displayScale) private var olcek
    @Environment(TemaDeposu.self) private var tema
    @State private var resim: UIImage?

    var body: some View {
        GeometryReader { g in
            let piksel = Int((max(g.size.width, g.size.height) * olcek).rounded(.up))
            ZStack {
                Color(tema.renkler.yuzey)
                if let resim {
                    Image(uiImage: resim)
                        .resizable()
                        .aspectRatio(contentMode: icerik)
                        .frame(width: g.size.width, height: g.size.height)
                        .transition(.opacity)
                }
            }
            .task(id: "\(url?.absoluteString ?? "")|\(piksel)") {
                guard piksel > 0 else { return }
                if let hazir = GorselCozucu.shared.bellekte(url, piksel) { resim = hazir; return }
                var r = await GorselCozucu.shared.resim(url, piksel: piksel)
                if r == nil, let yedek { r = await GorselCozucu.shared.resim(yedek, piksel: piksel) }
                guard !Task.isCancelled else { return }
                withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.25)) { resim = r }
            }
        }
    }
}

/// Görsel baytlarını küçülterek çözer (ImageIO, ana iş parçacığı dışında) ve bellekte tutar
final class GorselCozucu: @unchecked Sendable {
    static let shared = GorselCozucu()

    private let bellek: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.totalCostLimit = 120 * 1024 * 1024
        return c
    }()

    /// Piksel boyları basamaklanır: kutu biraz değişince yeniden çözülmesin
    private func basamak(_ p: Int) -> Int {
        for b in [128, 256, 400, 640, 960, 1280, 1920, 2560, 4096] where p <= b { return b }
        return 4096
    }

    private func anahtar(_ url: URL, _ piksel: Int) -> NSString { "\(basamak(piksel))|\(url.absoluteString)" as NSString }

    func bellekte(_ url: URL?, _ piksel: Int) -> UIImage? {
        url.flatMap { bellek.object(forKey: anahtar($0, piksel)) }
    }

    func resim(_ url: URL?, piksel: Int) async -> UIImage? {
        guard let url else { return nil }
        if let r = bellekte(url, piksel) { return r }
        guard let veri = try? await GorselDeposu.shared.veri(url) else { return nil }
        let p = basamak(piksel)
        let r = await Task.detached(priority: .userInitiated) { Self.cozumle(veri, enBuyuk: p) }.value
        if let r { bellek.setObject(r, forKey: anahtar(url, piksel), cost: Int(r.size.width * r.size.height * r.scale * r.scale * 4)) }
        return r
    }

    /// En uzun kenarı `enBuyuk` pikseli geçmeyecek biçimde çözer (yönü düzeltilmiş)
    static func cozumle(_ veri: Data, enBuyuk: Int) -> UIImage? {
        guard let kaynak = CGImageSourceCreateWithData(veri as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        let secenek: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: enBuyuk,
        ]
        guard let g = CGImageSourceCreateThumbnailAtIndex(kaynak, 0, secenek as CFDictionary) else { return nil }
        return UIImage(cgImage: g)
    }
}

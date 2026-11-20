import SwiftUI
import UIKit

@main
struct NoraSanatApp: App {
    @State private var tema = SiteTemasi()

    var body: some Scene {
        WindowGroup {
            WebKabugu(tema: tema)
                .ignoresSafeArea()
                .background(Color(uiColor: tema.renk).ignoresSafeArea())
                // Saat/pil çubuğu sitenin rengine uysun (koyu zeminde açık yazı).
                .preferredColorScheme(tema.koyu ? .dark : .light)
        }
    }
}

/// Sitenin `theme-color` rengi; zemin ve durum çubuğu buna göre ayarlanır.
@Observable
final class SiteTemasi {
    /// Sanat Atlası'nın varsayılan gece zemini (#121110): site yüklenene kadar beyaz parlama olmasın.
    var renk = UIColor(red: 0x12 / 255.0, green: 0x11 / 255.0, blue: 0x10 / 255.0, alpha: 1)

    var koyu: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        renk.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b < 0.5
    }
}

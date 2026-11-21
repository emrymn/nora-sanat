// Kaynak: sanat-atlasi js/goruntuleyici.js, js/keskin.js @ a866b86
import SwiftUI
import NoraCekirdek

/// İlk kopya ekranda kalırken keskin kopya T3'ün disk ve bellek önbelleğinden hazırlanır.
struct GoruntuleyiciGorseli: View {
    let birincil: URL?
    let yedek: URL?
    let devasa: URL?
    var yuklendiMi: ((CGSize) -> Void)? = nil

    @State private var resim: UIImage?
    @State private var hata = false

    var body: some View {
        Group {
            if let resim {
                Image(uiImage: resim).resizable().scaledToFit()
            } else {
                Text(hata ? "Görsel yüklenemedi." : "Yükleniyor…")
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
            }
        }
        .task(id: [birincil, yedek, devasa]) {
            resim = nil
            hata = false
            var kullanilan: URL?
            for case let url? in [birincil, yedek] {
                guard !Task.isCancelled else { return }
                if let ilk = await GorselCozucu.shared.resim(url, piksel: 1280) {
                    guard !Task.isCancelled else { return }
                    resim = ilk
                    yuklendiMi?(ilk.size)
                    kullanilan = url
                    break
                }
            }
            guard !Task.isCancelled else { return }
            if let devasa, devasa != kullanilan,
               let keskin = await GorselCozucu.shared.resim(devasa, piksel: 4096) {
                guard !Task.isCancelled else { return }
                resim = keskin
                yuklendiMi?(keskin.size)
            }
            if !Task.isCancelled { hata = resim == nil }
        }
    }
}

struct TabloIsigiGorunumu: View {
    let url: URL?
    let opaklikCarpani: Double
    @State private var resim: UIImage?

    var body: some View {
        Group {
            if let resim {
                Image(uiImage: resim).resizable().scaledToFit()
                    .scaleEffect(1.7).blur(radius: 34).saturation(1.4)
                    .brightness(-0.15).opacity(0.55 * opaklikCarpani)
            } else { Color.clear }
        }
        .task(id: url) {
            resim = nil
            let yeni = await GorselCozucu.shared.resim(url, piksel: 400)
            if !Task.isCancelled { resim = yeni }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Görüntüleyicinin gece renkleri (`css/app.css` `.gor` değişkenleri: her temada gece renkleri kullanılır).
enum GoruntuleyiciTema {
    static let zemin = Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0)          // #121110
    static let yuzey = Color(red: 28 / 255.0, green: 26 / 255.0, blue: 24 / 255.0)          // #1c1a18
    static let kenar = Color(red: 46 / 255.0, green: 43 / 255.0, blue: 40 / 255.0)          // #2e2b28
    static let murekkep = Color(red: 235 / 255.0, green: 229 / 255.0, blue: 218 / 255.0)    // #ebe5da
    static let ikincilMurekkep = Color(red: 172 / 255.0, green: 164 / 255.0, blue: 152 / 255.0) // #aca498
    static let ucunculMurekkep = Color(red: 138 / 255.0, green: 131 / 255.0, blue: 121 / 255.0) // #8a8379
    static let vurgu = Color(red: 201 / 255.0, green: 164 / 255.0, blue: 92 / 255.0)        // #c9a45c (pirinç)
    static let vurguYazi = Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0)      // #121110
    static let yanlisIkon = Color(red: 240 / 255.0, green: 154 / 255.0, blue: 134 / 255.0)  // #f09a86
    static let yuvarlakDugmeZemini = Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0).opacity(0.6)
}

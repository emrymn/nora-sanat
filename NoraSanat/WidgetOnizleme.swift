#if DEBUG
import NoraCekirdek
import SwiftUI
import WidgetKit

/// Yalnız geliştirme: `-widgetOnizleme` ile açılınca widget'ın üç boyutunu gerçek veriyle gösterir
/// (GitHub'daki simülatör ekran görüntüsü için; ana ekrana widget eklemek otomatikleştirilemiyor).
struct WidgetOnizleme: View {
    @State private var sonuc: TabloYukleyici.Sonuc?
    @State private var hata: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Widget önizlemesi").font(.headline).foregroundStyle(.white)
                let t = sonuc?.tablo ?? .ornek
                HStack(spacing: 18) {
                    kart(t, .systemSmall, 158, 158)
                    Spacer(minLength: 0)
                }
                kart(t, .systemMedium, 338, 158)
                kart(t, .systemLarge, 338, 354)
                if let hata { Text(hata).foregroundStyle(.red).font(.footnote) }
            }
            .padding(24)
        }
        .background(Color(white: 0.2).ignoresSafeArea())
        .task {
            do {
                sonuc = try await TabloYukleyici().yukle(tarih: GunTarihi.gun(Date()))
            } catch {
                hata = "\(error)"
            }
        }
    }

    private func kart(_ t: GununTablosu, _ b: WidgetFamily, _ g: CGFloat, _ y: CGFloat) -> some View {
        TabloKarti(tablo: t, gorsel: sonuc?.gorsel, boyut: b)
            .frame(width: g, height: y)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
#endif

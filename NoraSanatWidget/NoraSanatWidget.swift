import NoraCekirdek
import SwiftUI
import WidgetKit

/// Ana ekran widget'ı: Sanat Atlası'nın Bugün ekranındaki günün tablosu.
/// Veriyi siteden kendisi indirir (uygulamayla veri paylaşmaz: ücretsiz Apple ID'de App Group yok).
@main
struct NoraSanatWidgetleri: WidgetBundle {
    var body: some Widget {
        GununTablosuWidget()
    }
}

struct GununTablosuWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GununTablosu", provider: TabloSaglayici()) { giris in
            TabloGorunumu(giris: giris)
        }
        .configurationDisplayName("Günün tablosu")
        .description("Sanat Atlası'nda bugün gezdiğin tablo. Dokununca Nora Sanat'ta açılır.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct TabloGirisi: TimelineEntry {
    let date: Date
    let tablo: GununTablosu
    let gorsel: CGImage?
}

struct TabloSaglayici: TimelineProvider {
    func placeholder(in context: Context) -> TabloGirisi {
        TabloGirisi(date: Date(), tablo: .ornek, gorsel: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TabloGirisi) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { completion(await giris().0) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TabloGirisi>) -> Void) {
        Task {
            let (g, tamam) = await giris()
            // Gece yarısından hemen sonra yeni tablo; indirilemediyse bir saat sonra yeniden dene
            let takvim = Calendar.current
            let yarin = takvim.date(byAdding: .minute, value: 5,
                                    to: takvim.startOfDay(for: takvim.date(byAdding: .day, value: 1, to: Date())!))!
            let sonraki = tamam ? yarin : min(yarin, Date().addingTimeInterval(3600))
            completion(Timeline(entries: [g], policy: .after(sonraki)))
        }
    }

    /// (giriş, görseliyle eksiksiz mi)
    private func giris() async -> (TabloGirisi, Bool) {
        do {
            let s = try await TabloYukleyici().yukle(tarih: GunTarihi.gun(Date()))
            return (TabloGirisi(date: Date(), tablo: s.tablo, gorsel: s.gorsel), s.gorsel != nil)
        } catch {
            return (TabloGirisi(date: Date(), tablo: .ornek, gorsel: nil), false)
        }
    }
}

struct TabloGorunumu: View {
    @Environment(\.widgetFamily) private var boyut
    let giris: TabloGirisi

    var body: some View {
        TabloKarti(tablo: giris.tablo, gorsel: giris.gorsel, boyut: boyut)
            .containerBackground(for: .widget) { TabloKarti.zemin }
            .widgetURL(URL(string: "norasanat://bugun"))
    }
}

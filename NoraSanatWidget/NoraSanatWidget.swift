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
        // Z3o: kilit ekranı (dikdörtgen, yuvarlak, saatin üstündeki satır); küçük boy StandBy'da da görünür
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
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
        Group {
            switch boyut {
            case .accessoryRectangular, .accessoryCircular, .accessoryInline:
                KilitEkrani(giris: giris, boyut: boyut)
                    .containerBackground(for: .widget) { Color.clear }
            default:
                TabloKarti(tablo: giris.tablo, gorsel: giris.gorsel, boyut: boyut)
                    .containerBackground(for: .widget) { TabloKarti.zemin }
            }
        }
        .widgetURL(URL(string: "norasanat://bugun"))
    }
}

/// Z3o: kilit ekranı. Sistem bunları tek renkte (yarı saydam, duvar kâğıdına göre) çizer:
/// - dikdörtgen: küçük tablo, eserin adı, sanatçı ve yıl;
/// - yuvarlak: tablonun kendisi (dairede);
/// - satır (saatin üstü): "Sanatçı · Eser".
/// "Bugün N tekrar" yok: widget uygulamanın kaydını okuyamaz (ücretsiz Apple ID'de App Group yok).
struct KilitEkrani: View {
    let giris: TabloGirisi
    let boyut: WidgetFamily

    var body: some View {
        let t = giris.tablo
        switch boyut {
        case .accessoryInline:
            Text("\(t.sanatci) · \(t.eser)")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                if let g = giris.gorsel {
                    Image(decorative: g, scale: 1).resizable().scaledToFill()
                        .clipShape(Circle())
                        .widgetAccentable()
                } else {
                    Image(systemName: "photo.artframe").font(.title3)
                }
            }
            .accessibilityLabel("Günün tablosu: \(t.eser), \(t.sanatci)")
        default:
            HStack(spacing: 8) {
                if let g = giris.gorsel {
                    Image(decorative: g, scale: 1).resizable().scaledToFill()
                        .frame(width: 44, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .widgetAccentable()
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("GÜNÜN TABLOSU").font(.system(size: 10, weight: .semibold)).tracking(0.8).opacity(0.7)
                    Text(t.eser).font(.system(size: 14, weight: .semibold, design: .serif)).lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text([t.sanatci, t.yil.map(String.init)].compactMap { $0 }.joined(separator: " · "))
                        .font(.system(size: 11)).lineLimit(1).opacity(0.85)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

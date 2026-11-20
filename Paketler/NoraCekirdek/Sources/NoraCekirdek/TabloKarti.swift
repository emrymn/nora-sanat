#if canImport(SwiftUI) && canImport(WidgetKit) && os(iOS)
import SwiftUI
import WidgetKit

/// Widget'taki "Günün tablosu" kartı. Uygulamadaki DEBUG önizlemesi de bunu kullanır.
public struct TabloKarti: View {
    public static let zemin = Color(red: 0x12 / 255, green: 0x11 / 255, blue: 0x10 / 255)
    static let yazi = Color(red: 0xF3 / 255, green: 0xEE / 255, blue: 0xE6 / 255)

    let tablo: GununTablosu
    let gorsel: CGImage?
    let boyut: WidgetFamily

    public init(tablo: GununTablosu, gorsel: CGImage?, boyut: WidgetFamily) {
        self.tablo = tablo; self.gorsel = gorsel; self.boyut = boyut
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            Self.zemin
            if let gorsel {
                GeometryReader { g in
                    Image(decorative: gorsel, scale: 1)
                        .resizable()
                        .scaledToFill()
                        .frame(width: g.size.width, height: g.size.height)
                        .clipped()
                }
            }
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.35), .black.opacity(0.82)],
                           startPoint: UnitPoint(x: 0.5, y: boyut == .systemLarge ? 0.35 : 0.2), endPoint: .bottom)
            yazilar
                .padding(boyut == .systemSmall ? 12 : 16)
        }
        .foregroundStyle(Self.yazi)
    }

    @ViewBuilder var yazilar: some View {
        VStack(alignment: .leading, spacing: boyut == .systemSmall ? 2 : 4) {
            if boyut != .systemSmall {
                Text("GÜNÜN TABLOSU")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .opacity(0.75)
            }
            Text(tablo.eser)
                .font(.system(size: boyut == .systemSmall ? 15 : (boyut == .systemLarge ? 22 : 18),
                              weight: .semibold, design: .serif))
                .lineLimit(boyut == .systemSmall ? 3 : 2)
                .minimumScaleFactor(0.85)
            Text([tablo.sanatci, tablo.yil.map(String.init)].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: boyut == .systemSmall ? 11 : 13, weight: .medium))
                .lineLimit(1)
                .opacity(0.85)
            if boyut == .systemLarge, let b = tablo.notBaslik, let m = tablo.notMetin {
                Text("\(Text(b + ".").fontWeight(.semibold)) \(m)")
                    .font(.system(size: 13))
                    .lineLimit(3)
                    .opacity(0.85)
                    .padding(.top, 6)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
    }
}

public extension GununTablosu {
    /// Galeri ve yer tutucu için
    static let ornek = GununTablosu(tarih: "2026-11-20", sanatciId: "francois-boucher", sanatci: "François Boucher",
                                    eser: "Venüs'ün Zaferi", yil: 1740, gorsel: nil,
                                    notBaslik: "Venüs", notMetin: "Deniz kabuğundan arabasında, nimfalar ve tritonlar arasında.")
}
#endif

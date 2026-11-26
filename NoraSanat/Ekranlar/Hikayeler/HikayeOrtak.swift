// Z4b · Hikâyeler: ortak görünüş parçaları. Tasarım: Neon "Yön 2 · Substack Minimal" (dal neon/hikayeler-tasarim-3,
// PR #75; birleştirilmedi, yalnız referans): tasarim/hikayeler-3/ortak.css, yon-2.html, hikaye-verisi.js `IKONLAR`.
// Renkler temadan (TASARIM_DILI): --bg zemin, --surface yuzey, --ink murekkep, --ink-2/3 murekkep2/3, --notr-kenar
// notrKenar, --pirinc pirinc, --tab-bg sekmeZemin, --overlay-btn ustDugme.
import NoraCekirdek
import SwiftUI

/// Tasarımın çizgi simgeleri (24'lük viewBox)
enum HikayeSimge: String {
    case ara, geri, kulaklik, ben, geri15, ileri15, kapat, ileri

    var isaretleme: String {
        switch self {
        case .ara: return #"<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4 4"/>"#
        case .geri: return #"<path d="M15 6l-6 6 6 6"/>"#
        case .ileri: return #"<path d="M9 6l6 6-6 6"/>"#
        case .kulaklik:
            return #"<path d="M4.5 14.5v-2a7.5 7.5 0 0 1 15 0v2"/><rect x="4" y="13.5" width="3.5" height="6" rx="1.6"/><rect x="16.5" y="13.5" width="3.5" height="6" rx="1.6"/>"#
        case .ben: return #"<circle cx="12" cy="8.2" r="3.6"/><path d="M5.5 19.5c.8-3.6 3.3-5.3 6.5-5.3s5.7 1.7 6.5 5.3"/>"#
        case .geri15: return #"<path d="M9 5.5L5.5 8.5 9 11.5"/><path d="M6 8.5h7a5.5 5.5 0 1 1-4.8 8.2"/>"#
        case .ileri15: return #"<path d="M15 5.5l3.5 3-3.5 3"/><path d="M18 8.5h-7a5.5 5.5 0 1 0 4.8 8.2"/>"#
        case .kapat: return #"<path d="M6 6l12 12M18 6L6 18"/>"#
        }
    }
}

struct HikayeIkon: View {
    let simge: HikayeSimge
    var boyut: CGFloat = 20
    var kalinlik: CGFloat = 1.6

    var body: some View {
        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: simge.isaretleme))
            .stroke(style: StrokeStyle(lineWidth: kalinlik, lineCap: .round, lineJoin: .round))
            .frame(width: boyut, height: boyut)
            .accessibilityHidden(true)
    }
}

/// `.btn-cam.kare`: 44'lük cam daire (`--overlay-btn`, blur 22, 1 px `--notr-kenar`)
struct HikayeCamDugme: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }

    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        var body: some View {
            configuration.label
                .foregroundStyle(Color(tema.renkler.murekkep))
                .frame(width: 44, height: 44)
                .background {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(Color(tema.renkler.ustDugme))
                        Circle().strokeBorder(Color(tema.renkler.notrKenar), lineWidth: 1)
                    }
                }
                .contentShape(Circle())
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

/// Z4b (Emre): Ben sekme değil; ana ekranların sağ üstündeki kişi düğmesi onu bulunduğun sekmenin üstünde sayfa olarak
/// açar (`KabukDurumu.benOncesi`: geri oraya döner).
struct BenDugmesi: View {
    @Environment(KabukDurumu.self) private var kabuk

    var body: some View {
        Button {
            Titresim.dokunus()
            kabuk.sec(.ben)
        } label: {
            HikayeIkon(simge: .ben, boyut: 20, kalinlik: 1.5)
        }
        .buttonStyle(HikayeCamDugme())
        .accessibilityLabel("Ben: ilerleme ve ayarlar")
        .accessibilityIdentifier("ben-dugmesi")
    }
}

/// Kırpılmamış, tam genişlikte eser görseli (`.eser-fig img { width: 100%; height: auto }`). Oran biliniyorsa yer
/// baştan ayrılır; yoksa görsel inince kendi oranına oturur.
struct TamGorsel: View {
    let url: URL?
    var yedek: URL? = nil
    var oran: Double? = nil
    var kose: CGFloat = 12

    @Environment(\.displayScale) private var olcek
    @Environment(TemaDeposu.self) private var tema
    @State private var resim: UIImage?

    private var gercekOran: CGFloat {
        if let r = resim, r.size.height > 0 { return r.size.width / r.size.height }
        return CGFloat(oran ?? 4.0 / 3.0)
    }

    var body: some View {
        GeometryReader { g in
            ZStack {
                Color(tema.renkler.yuzey)
                if let resim {
                    Image(uiImage: resim).resizable().aspectRatio(contentMode: .fit).transition(.opacity)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .task(id: "\(url?.absoluteString ?? "")|\(Int(g.size.width))") {
                let piksel = Int((g.size.width * olcek).rounded(.up))
                guard piksel > 0 else { return }
                if let hazir = GorselCozucu.shared.bellekte(url, piksel) { resim = hazir; return }
                var r = await GorselCozucu.shared.resim(url, piksel: piksel)
                if r == nil, let yedek { r = await GorselCozucu.shared.resim(yedek, piksel: piksel) }
                guard !Task.isCancelled else { return }
                withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.25)) { resim = r }
            }
        }
        .aspectRatio(gercekOran, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: kose, style: .continuous))
    }
}

/// Hikâyeler'in renkleri (tasarımın değişkenleri)
struct HikayeRenk {
    let r: TemaRenkleri
    var zemin: Color { Color(r.zemin) }
    var yuzey: Color { Color(r.yuzey) }
    var yazi: Color { Color(r.murekkep) }
    var yazi2: Color { Color(r.murekkep2) }
    var yazi3: Color { Color(r.murekkep3) }
    var kenar: Color { Color(r.notrKenar) }
    var pirinc: Color { Color(r.pirinc) }
    var dogru: Color { Color(r.dogru) }
    /// `--tab-bg`
    var cam: Color { Color(r.sekmeZemin) }
    /// `--aktif-p-bg`: pirinç %9 (Gündüz %8,5)
    var okunan: Color { Color(r.pirinc).opacity(r.koyu ? 0.09 : 0.085) }
    var golge: Color { r.koyu ? .black.opacity(0.44) : Color(r.murekkep).opacity(0.12) }
}

/// `.cizgi-iz` + `.cizgi-dol`: 2,5 pt ince ilerleme çizgisi
struct HikayeCizgi: View {
    let oran: Double
    var bitti = false
    var yukseklik: CGFloat = 2.5
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(c.kenar)
                Capsule().fill(bitti ? c.dogru : c.pirinc).frame(width: g.size.width * min(1, max(0, oran)))
            }
        }
        .frame(height: yukseklik)
        .accessibilityHidden(true)
    }
}

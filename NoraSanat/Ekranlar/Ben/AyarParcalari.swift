// Z3x: Ayarlar'ın yeni görünüşünün parçaları. Kaynak: Neon'un tasarımı "Yön 2 · Kompakt fihrist ve yapışkan bölüm şeridi"
// (dal neon/ayarlar-tasarim, PR #63: tasarim/ayarlar/yon-2.html; .kart, .satir, .simge-kap, .mini-parcali, .anahtar,
// .adim-btn, .cam-hap, .birincil-hap, .cekmece, .bolum-baslik, .bolum-dipnot). Renkler yalnız `tema.renkler`'den;
// tasarımın türetilmiş değişkenleri (--surface-2, --border-ince, --simge-zemin) temanın renklerinden karıştırılır.
import NoraCekirdek
import SwiftUI

// MARK: Renkler

extension RGBA {
    /// `color-mix(in srgb, self, o t)`
    func karis(_ o: RGBA, _ t: Double) -> RGBA {
        RGBA(r + (o.r - r) * t, g + (o.g - g) * t, b + (o.b - b) * t, a + (o.a - a) * t)
    }
}

extension TemaRenkleri {
    /// `--surface-2`: yüzeyin bir ton mürekkebe yakını (Gece #24211e, Gündüz #efebe3)
    var yuzey2: RGBA { yuzey.karis(murekkep, 0.04) }
    /// `--border-ince`: mürekkep %8,5
    var kenarInce: RGBA { RGBA(murekkep.r, murekkep.g, murekkep.b, 0.085) }
    /// `--simge-zemin`: mürekkep %6
    var simgeZemin: RGBA { RGBA(murekkep.r, murekkep.g, murekkep.b, 0.06) }
    /// `--anahtar-top`: Gece'de mürekkep, Gündüz'de yüzey
    var anahtarTop: RGBA { koyu ? murekkep : yuzey }
}

// MARK: Simgeler

/// Satır simgeleri (yon-2.html'in 24'lük çizgi simgeleri, 1.6 kontur)
enum AyarSimge: String {
    case tema, renk, yazi, hareket, egim, kart, tanis, titresim, gunun, zil, saat, rozet, indir, muhur, kumSaati,
         yildiz, bilgi, kitap, kod

    var isaretleme: String {
        switch self {
        case .tema: return #"<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z"/>"#
        case .renk: return #"<circle cx="12" cy="12" r="9"/><circle cx="9" cy="10" r="1"/><circle cx="15" cy="10" r="1"/><circle cx="12" cy="15" r="1"/>"#
        case .yazi: return #"<path d="M4 19 9 5l5 14"/><path d="M6 14h6"/><path d="M16 19v-7"/><path d="M14 14h4"/>"#
        case .hareket: return #"<path d="M3 12c3-5 6-5 9 0s6 5 9 0"/>"#
        case .egim: return #"<rect x="8" y="3" width="8" height="18" rx="2"/><path d="M4.5 8.5a7.5 7.5 0 0 0 0 7"/><path d="M19.5 8.5a7.5 7.5 0 0 1 0 7"/>"#
        case .kart: return #"<rect x="4" y="5" width="12" height="15" rx="2"/><path d="M8 3h10a2 2 0 0 1 2 2v12"/>"#
        case .tanis: return #"<circle cx="12" cy="8" r="4"/><path d="M5 20a7 7 0 0 1 14 0"/>"#
        case .titresim: return #"<path d="M6 8v8"/><path d="M18 8v8"/><rect x="9" y="5" width="6" height="14" rx="1.5"/>"#
        case .gunun: return #"<rect x="4" y="4" width="16" height="16" rx="2"/><path d="m4 16 5-5 4 4 3-3 4 4"/>"#
        case .zil: return #"<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/>"#
        case .saat: return #"<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>"#
        case .rozet: return #"<rect x="4" y="4" width="16" height="16" rx="4"/>"#
        case .indir: return #"<path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M4 20h16"/>"#
        case .muhur: return BenSimge.muhur.isaretleme
        case .kumSaati: return BenSimge.kumSaati.isaretleme
        case .yildiz: return #"<path d="M12 3 14.4 9.6 21 12l-6.6 2.4L12 21l-2.4-6.6L3 12l6.6-2.4Z"/>"#
        case .bilgi: return #"<circle cx="12" cy="12" r="9"/><path d="M12 16v-4"/><path d="M12 8h.01"/>"#
        case .kitap: return #"<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>"#
        case .kod: return #"<path d="m18 16 4-4-4-4"/><path d="m6 8-4 4 4 4"/><path d="m14.5 4-5 16"/>"#
        }
    }
}

/// `.simge-kap`: 32×32, 10 köşe, `--simge-zemin`, simge 17 pt `--ink-2`
struct AyarSimgeKabi: View {
    let simge: AyarSimge
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: simge.isaretleme))
            .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .frame(width: 17, height: 17)
            .foregroundStyle(Color(r.murekkep2))
            .overlay(alignment: .topTrailing) {
                // Simge rozeti: köşede pirinç nokta (`circle cx=18 cy=6 r=3 fill=--pirinc`)
                if simge == .rozet {
                    Circle().fill(Color(r.pirinc)).frame(width: 4.25, height: 4.25).offset(x: -2.125, y: 2.125)
                }
            }
            .frame(width: 32, height: 32)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(r.simgeZemin)))
            .accessibilityHidden(true)
    }
}

// MARK: Kart ve satır

/// `.bolum-baslik`: 600 13 px pirinç, cümle düzeni
struct AyarGrupBasligi: View {
    let metin: String
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Text(metin)
            .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
            .foregroundStyle(Color(tema.renkler.pirinc))
            .padding(.leading, 6).padding(.bottom, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

/// `.bolum-dipnot`: kartın altında 12/17 px `--ink-3`
struct AyarDipnotu: View {
    let metin: String
    init(_ metin: String) { self.metin = metin }
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Text(metin)
            .font(Yazi.sans(12, stil: .caption1))
            .cssSatir(.sans, 12, 17)
            .foregroundStyle(Color(tema.renkler.murekkep3))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8).padding(.top, 8)
    }
}

/// `.kart`: 24 köşe, `--surface`, 1 px `--border`; satırlar arasında `--border-ince` çizgi
struct AyarKarti<Icerik: View>: View {
    @ViewBuilder var icerik: Icerik
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let sekil = RoundedRectangle(cornerRadius: 24, style: .continuous)
        VStack(alignment: .leading, spacing: 0) { icerik }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sekil.fill(Color(r.yuzey)))
            .clipShape(sekil)
            .overlay(sekil.strokeBorder(Color(r.kenar), lineWidth: 1))
    }
}

/// `.ayrac-ust`
struct AyarCizgisi: View {
    @Environment(TemaDeposu.self) private var tema
    var body: some View { Rectangle().fill(Color(tema.renkler.kenarInce)).frame(height: 1) }
}

/// `.satir-govde`: ad 500 15 px, alt yazı 12.5/17.5 px `--ink-2` (Büyük yazıda Dinamik Yazı'yla büyür)
struct AyarSatirYazisi: View {
    let ad: String
    var alt: String?
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ad).font(Yazi.sans(15, agirlik: 500))
                .foregroundStyle(Color(tema.renkler.murekkep))
                .fixedSize(horizontal: false, vertical: true)
            if let alt, !alt.isEmpty {
                Text(alt).font(Yazi.sans(12.5, stil: .footnote))
                    .cssSatir(.sans, 12.5, 17.5)
                    .foregroundStyle(Color(tema.renkler.murekkep2))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `.satir`: simge, ad + alt yazı, sağda denetim; 12/16 dolgu, en az 56
struct AyarSatiri<Sag: View>: View {
    let simge: AyarSimge
    let ad: String
    var alt: String?
    @ViewBuilder var sag: Sag

    var body: some View {
        HStack(spacing: 12) {
            AyarSimgeKabi(simge: simge)
            AyarSatirYazisi(ad: ad, alt: alt)
            sag
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

extension AyarSatiri where Sag == EmptyView {
    init(simge: AyarSimge, ad: String, alt: String?) {
        self.init(simge: simge, ad: ad, alt: alt) { EmptyView() }
    }
}

/// `.satir-btn` + `.cekmece`: dokununca altında açılan satır; sağda değer ve dönen ok
struct AcilirSatir<Deger: View, Icerik: View>: View {
    let simge: AyarSimge
    let ad: String
    var alt: String?
    @Binding var acik: Bool
    var tam = false
    @ViewBuilder var deger: Deger
    @ViewBuilder var icerik: Icerik
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(tema.ayar.hareketAzaltilmis ? nil : .spring(duration: 0.3, bounce: 0)) { acik.toggle() }
            } label: {
                HStack(spacing: 12) {
                    AyarSimgeKabi(simge: simge)
                    AyarSatirYazisi(ad: ad, alt: alt)
                    deger
                    BenIkon(simge: .ileri, boyut: 16, kalinlik: 1.8)
                        .rotationEffect(.degrees(acik ? -90 : 90))
                        .foregroundStyle(Color(tema.renkler.murekkep3))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(SatirBasinci())
            .accessibilityValue(acik ? "Açık" : "Kapalı")
            .accessibilityHint(acik ? "Kapatmak için dokun" : "Açmak için dokun")
            if acik {
                icerik
                    .padding(.leading, tam ? 16 : 60).padding(.trailing, 16).padding(.top, 4).padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

extension AcilirSatir where Deger == EmptyView {
    init(simge: AyarSimge, ad: String, alt: String?, acik: Binding<Bool>, tam: Bool = false,
         @ViewBuilder icerik: () -> Icerik) {
        self.init(simge: simge, ad: ad, alt: alt, acik: acik, tam: tam, deger: { EmptyView() }, icerik: icerik)
    }
}

/// `.satir-btn:active`: basılıyken `--surface-2`
struct SatirBasinci: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }
    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        @Environment(\.isEnabled) private var etkin
        var body: some View {
            configuration.label
                .background(Color(tema.renkler.yuzey2).opacity(configuration.isPressed ? 1 : 0))
                .opacity(etkin ? 1 : 0.44)
        }
    }
}

/// `.sag-deger`: 500 13.5 px `--ink-2` (pirinç ya da yeşil)
struct SagDeger: View {
    let metin: String
    var renk: KeyPath<TemaRenkleri, RGBA> = \.murekkep2
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Text(metin).font(Yazi.sans(13.5, agirlik: 500, stil: .subheadline))
            .monospacedDigit()
            .foregroundStyle(Color(tema.renkler[keyPath: renk]))
            .lineLimit(1)
            .fixedSize()
    }
}

// MARK: Denetimler

/// `.anahtar`: 50×30, açıkken pirinç; düğme `--anahtar-top`. Bütün satır dokunulabilir.
struct AyarAnahtari: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }

    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        @Environment(\.isEnabled) private var etkin
        var body: some View {
            let r = tema.renkler
            let acik = configuration.isOn
            Button { configuration.isOn.toggle() } label: {
                HStack(spacing: 12) {
                    configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                    ZStack(alignment: acik ? .trailing : .leading) {
                        Capsule().fill(Color(acik ? r.pirinc : r.kenar))
                            .overlay(Capsule().strokeBorder(Color(acik ? RGBA(0, 0, 0, 0) : r.kenar), lineWidth: 1))
                        Circle().fill(Color(r.anahtarTop))
                            .shadow(color: .black.opacity(0.28), radius: 2.5, y: 2)
                            .frame(width: 24, height: 24).padding(.horizontal, 3)
                    }
                    .frame(width: 50, height: 30)
                    .animation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.26), value: acik)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(etkin ? 1 : 0.44)
            .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
        }
    }
}

/// Simgeli anahtar satırı
struct AnahtarSatiri: View {
    let simge: AyarSimge
    let ad: String
    var alt: String?
    @Binding var acik: Bool

    var body: some View {
        Toggle(isOn: $acik) {
            HStack(spacing: 12) {
                AyarSimgeKabi(simge: simge)
                AyarSatirYazisi(ad: ad, alt: alt)
            }
        }
        .toggleStyle(AyarAnahtari())
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

/// `.mini-parcali`: satır içi iki seçenek; seçili `--ink` zemin, `--bg` yazı
struct MiniParcali<Deger: Hashable>: View {
    let ad: String
    let secenekler: [(deger: Deger, ad: String)]
    let secili: Deger
    let sec: (Deger) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        HStack(spacing: 0) {
            ForEach(0..<secenekler.count, id: \.self) { i in
                let s = secenekler[i]
                let acik = s.deger == secili
                Button { if !acik { sec(s.deger) } } label: {
                    Text(s.ad).font(Yazi.sans(12.5, agirlik: 600, stil: .footnote))
                        .lineLimit(1).fixedSize()
                        .foregroundStyle(Color(acik ? r.zemin : r.murekkep2))
                        .padding(.horizontal, 11)
                        .frame(minWidth: 58, minHeight: 38)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color(acik ? r.murekkep : RGBA(0, 0, 0, 0))))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(acik ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(r.yuzey2)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color(r.kenarInce), lineWidth: 1))
        .frame(minHeight: 44)
        .animation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.2), value: secili)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ad)
    }
}

/// `.adim-btn`: 44 pt yuvarlak, `--surface-2`, 1 px `--border`
struct AdimDugmesi: View {
    let isaret: String
    let ad: String
    let etkin: Bool
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: eylem) {
            Text(isaret).font(Yazi.sans(19, stil: .body))
                .foregroundStyle(Color(r.murekkep))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(r.yuzey2)))
                .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(BasincBicimi(olcek: 0.95))
        .disabled(!etkin)
        .opacity(etkin ? 1 : 0.35)
        .accessibilityLabel(ad)
    }
}

/// `.cam-hap`: 44 pt hap, `--surface-2`, 1 px `--border`, 500 13 px; `tehlike`: yazı `--wrong`
struct CamHap: ButtonStyle {
    var tehlike = false
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration, tehlike: tehlike) }
    private struct Govde: View {
        let configuration: Configuration
        let tehlike: Bool
        @Environment(TemaDeposu.self) private var tema
        @Environment(\.isEnabled) private var etkin
        var body: some View {
            let r = tema.renkler
            configuration.label
                .font(Yazi.sans(13, agirlik: 500, stil: .footnote))
                .foregroundStyle(Color(tehlike ? r.yanlisIkon : r.murekkep))
                .lineLimit(1)
                .padding(.horizontal, 15)
                .frame(minHeight: 44)
                .background(Capsule().fill(Color(r.yuzey2)))
                .overlay(Capsule().strokeBorder(Color(r.kenar), lineWidth: 1))
                .contentShape(Capsule())
                .opacity(etkin ? 1 : 0.44)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
        }
    }
}

/// `.birincil-hap`: ekranın tek dolu düğmesi; `--ink` zemin, `--bg` yazı, 600 14 px
struct BirincilHap: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }
    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        @Environment(\.isEnabled) private var etkin
        var body: some View {
            let r = tema.renkler
            configuration.label
                .font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                .foregroundStyle(Color(r.zemin))
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(Capsule().fill(Color(r.murekkep)))
                .contentShape(Capsule())
                .opacity(etkin ? 1 : 0.55)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
        }
    }
}

/// `.secenek-satir`: açılan çekmecede tek seçimli satır (ad, küçük açıklama, sağda tik noktası)
struct SecenekSatiri: View {
    let ad: String
    var aciklama: String?
    let secili: Bool
    let sec: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: sec) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ad).font(Yazi.sans(13.5, agirlik: 600, stil: .subheadline)).foregroundStyle(Color(r.murekkep))
                    if let aciklama {
                        Text(aciklama).font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(r.murekkep2))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Circle()
                    .strokeBorder(Color(secili ? r.pirinc : r.kenar), lineWidth: 1.5)
                    .background(Circle().fill(Color(r.pirinc)).padding(3).opacity(secili ? 1 : 0))
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(secili ? r.yuzey2.karis(r.pirinc, 0.12) : r.yuzey2)))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color(secili ? r.pirinc : r.kenar), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(secili ? [.isSelected] : [])
    }
}

/// `.ilerleme-iz`: 3 pt çizgi; süren pirinç, biten yeşil
struct InceIlerleme: View {
    let oran: Double
    var tamam = false
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        let r = tema.renkler
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(r.kenar))
                Capsule().fill(Color(tamam ? r.dogruIkon : r.pirinc)).frame(width: g.size.width * min(1, max(0, oran)))
            }
        }
        .frame(height: 3)
        .animation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.35), value: oran)
        .accessibilityHidden(true)
    }
}

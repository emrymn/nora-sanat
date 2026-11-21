// Kaynak: sanat-atlasi js/ekranlar/ortak.js (sekmeleriCiz, sekmeRozeti, sekmeSurukle), js/ekranlar/hizliAyar.js,
// js/tasarim.js (YOLLAR), css/app.css (.sekmeler, #sekmeler "İş 190", .sekme-isaret, .sekme-rozet, .hizli-dil,
// .hizli-yaprak) @ a866b86 (site 1.90.3)
import NoraCekirdek
import SwiftUI
import UIKit

/// Yerli sekme çubuğu (T4): sitenin yüzen, yuvarlak köşeli cam çubuğunun Swift'te aynısı.
///
/// - Yer ve ölçüler `SekmeCubugu.Yerlesim`'den (sitenin CSS'iyle aynı hesap, kâhinle sınanır). Böylece taşınmış bir
///   sekmeye geçince site gizlenip bu çubuk göründüğünde çubuk aynı yerde kalır.
/// - Simgeler sitenin SVG'leri (`SekmeCubugu.Simge`), çizgi 1.5; seçili sekmede 1.7 ve zıplama.
/// - Seçili sekmenin hapı kayar; parmak çubukta gezinirken hap parmağı izler, bırakınca o sekme açılır (`sekmeSurukle`).
/// - Çalış'ta bugün bekleyen kart sayısı (`KabukDurumu.calisRozeti`).
/// - Ortadaki dişli dil hızlı ayarları açar (`HizliAyarYapragi`).
///
/// `KokGorunum` bunu yalnız en az bir sekme yerliyse kurar ve hep yüklü tutar (site görünürken saydam): hap, site
/// görünürken de seçili sekmeyi izler; yerliye geçince kaldığı yerden kayar.
struct YerliSekmeCubugu: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var durum
    @Environment(\.accessibilityReduceMotion) private var azHareket

    /// Sürüklerken hapın yeri (sekme cinsinden); nil: sürüklenmiyor
    @State private var surukle: Double?
    @State private var basla: CGPoint?
    @State private var kaydi = false
    /// Parmağın altındaki sekme (simge küçülür: `a:active .ikon { scale(.86) }`)
    @State private var basili: Int?
    @State private var yaprakYuksekligi: CGFloat = 0

    var body: some View {
        GeometryReader { g in
            let ic = g.safeAreaInsets
            let gen = g.size.width + ic.leading + ic.trailing
            let yuk = g.size.height + ic.top + ic.bottom
            let y = SekmeCubugu.Yerlesim(ekranGenisligi: gen, ekranYuksekligi: yuk, solGuvenli: ic.leading,
                                         sagGuvenli: ic.trailing, altGuvenli: ic.bottom)
            ZStack(alignment: .topLeading) {
                if durum.hizliAcik {
                    perde
                    HizliAyarYapragi(kapat: hizliKapat)
                        .frame(width: y.cubuk.genislik)
                        .background(GeometryReader { p in
                            Color.clear.onAppear { yaprakYuksekligi = p.size.height }
                                .onChange(of: p.size.height) { _, h in yaprakYuksekligi = h }
                        })
                        .alignmentGuide(.top) { $0.height - (yuk - y.alt - SekmeCubugu.Olcu.yukseklik / 2) }
                        .offset(x: y.cubuk.x)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
                cubuk(y)
                    .frame(width: y.cubuk.genislik, height: y.cubuk.yukseklik)
                    .offset(x: y.cubuk.x, y: y.cubuk.y)
                    .zIndex(2)
                dil
                    .frame(width: y.dil.genislik, height: y.dil.yukseklik)
                    .offset(x: y.dil.x, y: y.dil.y - dilKalkisi)
                    .zIndex(3)
            }
            .frame(width: gen, height: yuk, alignment: .topLeading)
            .offset(x: -ic.leading, y: -ic.top)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: durum.cubukGorunur) { _, gorunur in
            if !gorunur { durum.hizliAcik = false }
            else { durum.rozetiYenile() }
        }
    }

    // MARK: Çubuk

    private func cubuk(_ y: SekmeCubugu.Yerlesim) -> some View {
        let r = tema.renkler
        let sira = SekmeCubugu.sira(durum.secili)
        let sg = y.sekmeler[0].genislik
        let ic = SekmeCubugu.Olcu.kenar + SekmeCubugu.Olcu.ic
        return ZStack(alignment: .topLeading) {
            // Hap: hafif açık, düz (İş 190)
            Capsule()
                .fill(Color(r.murekkep).opacity(0.12))
                .frame(width: sg, height: y.sekmeler[0].yukseklik)
                .scaleEffect(surukle == nil ? 1 : 1.04)
                .offset(x: ic + (surukle ?? Double(sira)) * sg, y: ic)
                .animation(surukle == nil ? hapHareketi : nil, value: sira)
                .animation(surukle == nil ? hapHareketi : nil, value: surukle)

            HStack(spacing: 0) {
                ForEach(Array(SekmeCubugu.sekmeler.enumerated()), id: \.offset) { i, s in
                    sekme(s, sira: i, secili: i == sira)
                        .frame(width: sg, height: y.sekmeler[0].yukseklik)
                }
            }
            .offset(x: ic, y: ic)
        }
        .frame(width: y.cubuk.genislik, height: y.cubuk.yukseklik, alignment: .topLeading)
        // Gölge yalnız camın (yazılar gölgesiz): box-shadow 0 10px 30px
        .background { cam(Capsule()).shadow(color: golge, radius: 15, x: 0, y: 10) }
        .contentShape(Rectangle().inset(by: -10))
        .gesture(dokunus(y))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ana gezinme")
    }

    private func sekme(_ s: Sekme, sira i: Int, secili: Bool) -> some View {
        let r = tema.renkler
        let renk = Color(secili ? r.murekkep : r.murekkep2)
        return VStack(spacing: SekmeCubugu.Olcu.simgeAra) {
            SimgeGorunumu(simge: SekmeCubugu.Simge(s), boyut: SekmeCubugu.Olcu.simge,
                          kalinlik: secili ? SekmeCubugu.Olcu.seciliCizgi : SekmeCubugu.Olcu.simgeCizgi)
                .scaleEffect(basili == i ? 0.86 : 1)
                .animation(.easeOut(duration: 0.2), value: basili)
                .modifier(Zipla(tetik: secili && zipla, acik: secili))
            Text(s.baslik)
                .font(Font(Yazi.uiFont(.sans, SekmeCubugu.Olcu.yazi, agirlik: 600)))
                .lineLimit(1)
                .frame(height: SekmeCubugu.Olcu.yazi * 1.2)
        }
        .foregroundStyle(renk)
        .animation(.easeOut(duration: 0.3), value: secili)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            if s == .calis, let n = SekmeCubugu.rozet(durum.calisRozeti) { rozet(n) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(s.baslik)
        .accessibilityValue(s == .calis && durum.calisRozeti > 0 ? "\(durum.calisRozeti) kart bekliyor" : "")
        .accessibilityAddTraits(secili ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { durum.sec(s) }
    }

    /// `.sekme-rozet`: pirinç, sekmenin ortasının 6 sağında, üstten 3
    private func rozet(_ n: String) -> some View {
        Text(n)
            .font(Font(Yazi.uiFont(.sans, 11, agirlik: 600)))
            .monospacedDigit()
            .foregroundStyle(Color(tema.renkler.pirincYazi))
            .padding(.horizontal, 5)
            .frame(minWidth: SekmeCubugu.Olcu.rozet, minHeight: SekmeCubugu.Olcu.rozet, maxHeight: SekmeCubugu.Olcu.rozet)
            .background(Capsule().fill(Color(tema.renkler.pirinc)))
            .fixedSize()
            .padding(.top, SekmeCubugu.Olcu.rozetUst)
            // Sol kenarı sekmenin ortasının 6 sağında: `left: calc(50% + 6px)`
            .alignmentGuide(HorizontalAlignment.center) { _ in -SekmeCubugu.Olcu.rozetSag }
            .transition(.scale(scale: 0.3).combined(with: .opacity))
            .accessibilityHidden(true)
    }

    /// Dokunuş ve sürükleme (`sekmeSurukle`): 8 px'ten çok kayınca hap parmağı izler; bırakınca en yakın sekme açılır.
    /// Açık sekmeye yeniden dokunmak `durum.yenidenDokunma`'yı artırır (sitede en başa kaydırır).
    private func dokunus(_ y: SekmeCubugu.Yerlesim) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { d in
                if basla == nil {
                    basla = d.startLocation
                    kaydi = false
                    basili = y.enYakin(d.startLocation.x)
                }
                if !kaydi && abs(d.location.x - d.startLocation.x) >= SekmeCubugu.suruklemeEsigi { kaydi = true }
                if kaydi {
                    basili = nil
                    surukle = y.surukle(d.location.x)
                }
            }
            .onEnded { d in
                let kaydiMi = kaydi
                basla = nil
                kaydi = false
                basili = nil
                withAnimation(hapHareketi) { surukle = nil }
                if !kaydiMi && !y.yakin(d.location.x, d.location.y) { return }
                let s = SekmeCubugu.sekmeler[y.enYakin(d.location.x)]
                if s == durum.secili && kaydiMi { return }
                durum.hizliAcik = false
                durum.sec(s)
            }
    }

    /// `transform 0.45s cubic-bezier(0.3, 1.35, 0.5, 1)`; hareket kapalıysa ya da iOS'ta azaltılmışsa kısa
    private var hapHareketi: Animation? {
        if tema.ayar.hareket == "kapali" { return nil }
        if azHareket { return .easeOut(duration: 0.15) }
        return .timingCurve(0.3, 1.35, 0.5, 1, duration: 0.45)
    }

    private var zipla: Bool { tema.ayar.hareket == "tam" && !azHareket }

    private var golge: Color {
        tema.koyu ? .black.opacity(0.45) : Color(tema.renkler.murekkep).opacity(0.14)
    }

    /// `#sekmeler`: `--tab-bg` cam (blur 24, doygunluk 1.6), 1 px mürekkep %14 kenar
    private func cam<S: InsettableShape>(_ sekil: S) -> some View {
        ZStack {
            sekil.fill(.ultraThinMaterial)
            sekil.fill(Color(tema.renkler.sekmeZemin))
            sekil.strokeBorder(Color(tema.renkler.murekkep).opacity(0.14), lineWidth: 1)
        }
    }

    // MARK: Hızlı ayarlar

    private var perde: some View {
        Color(red: 8 / 255, green: 7 / 255, blue: 6 / 255).opacity(0.55)
            .onTapGesture { hizliKapat() }
            .transition(.opacity)
            .accessibilityLabel("Hızlı ayarları kapat")
            .accessibilityAddTraits(.isButton)
    }

    /// Dil yaprağın üst kenarına biner: `--hizli-kalk: calc(var(--hizli-h) - var(--sekme-h) / 2 - 6px)`
    private var dilKalkisi: CGFloat {
        durum.hizliAcik ? max(0, yaprakYuksekligi - SekmeCubugu.Olcu.yukseklik / 2 - 6) : 0
    }

    /// `.hizli-dil`: çubuğun üst kenarındaki dişli; dokununca ya da yukarı çekince yaprak açılır
    private var dil: some View {
        Button {
            durum.hizliAcik ? hizliKapat() : hizliAc()
        } label: {
            SimgeGorunumu(simge: .ayarlar, boyut: SekmeCubugu.Olcu.dilSimge, kalinlik: 1.5)
                .rotationEffect(.degrees(durum.hizliAcik ? 120 : 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle().inset(by: -10))
        }
        .buttonStyle(DilBicimi(tema: tema, cam: AnyView(cam(Capsule()))))
        .simultaneousGesture(DragGesture(minimumDistance: 6).onEnded { d in
            let dy = d.translation.height
            if !durum.hizliAcik && dy < -18 { hizliAc() } else if durum.hizliAcik && dy > 70 { hizliKapat() }
        })
        .accessibilityLabel(durum.hizliAcik ? "Hızlı ayarları kapat" : "Hızlı ayarlar")
        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: zipla ? 0.62 : 0.15), value: durum.hizliAcik)
    }

    private func hizliAc() {
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: zipla ? 0.5 : 0.15)) { durum.hizliAcik = true }
    }

    private func hizliKapat() {
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: zipla ? 0.4 : 0.15)) { durum.hizliAcik = false }
    }
}

/// `.hizli-dil-ic`: basılıyken mürekkep zemin, zemin rengi simge
private struct DilBicimi: ButtonStyle {
    let tema: TemaDeposu
    let cam: AnyView

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(configuration.isPressed ? tema.renkler.zemin : tema.renkler.murekkep2))
            .background {
                if configuration.isPressed { Capsule().fill(Color(tema.renkler.murekkep)) } else { cam }
            }
            .animation(.easeOut(duration: 0.4), value: configuration.isPressed)
    }
}

/// `sekme-zipla`: seçilen sekmenin simgesi %40'ta 3 px yukarı ve 1.12 büyük (0.45 s)
private struct Zipla: ViewModifier {
    let tetik: Bool
    let acik: Bool

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: ZiplaDegeri(), trigger: acik) { c, d in
            c.scaleEffect(d.olcek).offset(y: d.y)
        } keyframes: { _ in
            // Seçimi kaybeden sekme yerinde kalır (iki kare de 1 ve 0)
            KeyframeTrack(\.olcek) {
                CubicKeyframe(tetik ? 1.12 : 1, duration: 0.18)
                CubicKeyframe(1, duration: 0.27)
            }
            KeyframeTrack(\.y) {
                CubicKeyframe(tetik ? -3 : 0, duration: 0.18)
                CubicKeyframe(0, duration: 0.27)
            }
        }
    }
}

private struct ZiplaDegeri {
    var olcek: CGFloat = 1
    var y: CGFloat = 0
}

// MARK: Simge

/// Sitenin bir simgesi (`ikon(ad, boyut, kalinlik)`): 24'lük viewBox, yuvarlak uçlu çizgi, `currentColor`
struct SimgeGorunumu: View {
    let simge: SekmeCubugu.Simge
    var boyut: CGFloat = 20
    var kalinlik: CGFloat = 1.6

    var body: some View {
        SimgeSekli(komutlar: simge.komutlar)
            .stroke(style: StrokeStyle(lineWidth: kalinlik, lineCap: .round, lineJoin: .round))
            .frame(width: boyut, height: boyut)
            .accessibilityHidden(true)
    }
}

/// Çekirdeğin SVG komutlarından SwiftUI yolu (24×24 viewBox, kutuya ölçeklenir)
struct SimgeSekli: Shape {
    let komutlar: [YolKomutu]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let sx = rect.width / 24, sy = rect.height / 24
        let n = { (k: Nokta) in CGPoint(x: rect.minX + k.x * sx, y: rect.minY + k.y * sy) }
        for k in komutlar {
            switch k {
            case let .git(a): p.move(to: n(a))
            case let .cizgi(a): p.addLine(to: n(a))
            case let .egri(a, b, c): p.addCurve(to: n(c), control1: n(a), control2: n(b))
            case .kapat: p.closeSubpath()
            }
        }
        return p
    }
}

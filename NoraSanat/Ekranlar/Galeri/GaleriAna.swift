// Kaynak: sanat-atlasi js/ekranlar/gozat.js (gozAt, carkHtml, carkKur, onizlemeleriDoldur), css/app.css (.cark*,
// .zaman-kart, .akim-dizin*, İş 189 · İş 190 "Işık") @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece): kemer 210 × 269.7 (204/262), şerit aralığı 22, komşu kart
// `translateY(30k) scale(1 − 0.2k)`, kemer opaklığı 1 − 0.55k, yazı 1 − 1.6k; çark yarıçapı 700, iki akım arası 12°.
import NoraCekirdek
import SwiftUI

/// Galeri'nin ana ekranı: akımların kemerli kartları yatay bir şeritte, altında şeridi izleyen ve parmakla çevrilen çark,
/// en altta "Bütün akımlar" dizini (açılır).
struct AkimCarki: View {
    let salonlar: [AkimDurumu]
    let galeri: GaleriKatalogu
    let il: Ilerleme
    @Binding var sira: Int
    @Binding var dizinAcik: Bool
    let kapak: (String) -> (url: URL?, yedek: URL?)
    let gir: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    /// Şeridin anlık konumu (akım cinsinden, kesirli): çark ve komşu kartlar bunu izler
    @State private var konum: Double = 0
    @State private var secim: Int?
    @State private var cevirme: (bas: Double, x: CGFloat)?

    static let kartGenisligi: CGFloat = 210
    static let aralik: CGFloat = 22
    static let adim: CGFloat = kartGenisligi + aralik
    static let yaricap: Double = 700
    static let carkAdimi: Double = 12

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            VStack(spacing: 0) {
                serit(w)
                CarkTekeri(salonlar: salonlar, konum: konum, sira: sira)
                    .frame(height: 150)
                    .padding(.top, -30)
                    .contentShape(Rectangle())
                    .gesture(cevir(w))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Akımlar çarkı")
                    .accessibilityValue(salonlar.indices.contains(sira) ? "\(sira + 1) / \(salonlar.count), \(salonlar[sira].ad)" : "")
                    .accessibilityAdjustableAction { yon in
                        git(yon == .increment ? sira + 1 : sira - 1)
                    }
                dizinDugmesi.padding(.top, -42).id("dizin")
                if dizinAcik { dizin.padding(.top, 28) }
            }
            .frame(width: w)
        }
        .frame(height: yukseklik)
        .onAppear { secim = sira; konum = Double(sira) }
    }

    /// Şerit (8 + 269.7 + 16 + yazı ≈ 148 + 4) + çark (150 − 30) + dizin düğmesi (44 − 42) + açık dizin
    private var yukseklik: CGFloat {
        8 + 269.7 + 16 + 148.2 + 4 + 120 + 2 + (dizinAcik ? 28 + CGFloat(salonlar.count) * 61 : 0)
    }

    // MARK: Şerit

    private func serit(_ w: CGFloat) -> some View {
        let kenar = (w - Self.kartGenisligi) / 2
        return ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Self.aralik) {
                ForEach(Array(salonlar.enumerated()), id: \.offset) { i, salon in
                    kart(i, salon, w: w)
                        .frame(width: Self.kartGenisligi)
                        .id(i)
                }
            }
            .scrollTargetLayout()
            .padding(.top, 8).padding(.bottom, 4)
            .background(GeometryReader { p in
                Color.clear.preference(key: SeritKaymasi.self, value: p.frame(in: .named("serit")).minX)
            })
        }
        .coordinateSpace(name: "serit")
        .contentMargins(.horizontal, kenar, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $secim, anchor: .center)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .onPreferenceChange(SeritKaymasi.self) { x in
            guard cevirme == nil else { return }   // çark çevrilirken konumu parmak verir
            let p = max(0, min(Double(salonlar.count - 1), Double(kenar - x) / Double(Self.adim)))
            if abs(p - konum) > 0.001 { konum = p }
            let yeni = Int(p.rounded())
            if yeni != sira { sira = yeni }
        }
        .onChange(of: sira) { _, yeni in if secim != yeni && cevirme == nil { secim = yeni } }
        .onChange(of: secim) { _, yeni in if let yeni, cevirme == nil, yeni != sira { sira = yeni } }
        .frame(height: 8 + 269.7 + 16 + 148.2 + 4)
    }

    private func kart(_ i: Int, _ salon: AkimDurumu, w: CGFloat) -> some View {
        let r = tema.renkler
        let k = min(1, abs(Double(i) - konum))
        let (url, yedek) = kapak(salon.ad)
        let uyeler = galeri.katalog.sanatcilar.filter { $0.akim == salon.ad }
        return Button { if salon.acik { gir(salon.ad) } } label: {
            VStack(spacing: 0) {
                // `.cark-kemer`: üstte yarım daire, altta 16 px; pirinç halka (seçiliyken), altta yumuşak gölge
                ZStack {
                    Color(r.yuzey)
                    UzakGorsel(url: url, icerik: .fill, yedek: yedek)
                        .grayscale(salon.acik ? 0 : 1).brightness(salon.acik ? 0 : -0.3)
                    LinearGradient(stops: [.init(color: Color(r.zemin, 0.5), location: 0), .init(color: Color(r.zemin, 0), location: 0.34)],
                                   startPoint: .bottom, endPoint: .top)
                }
                .frame(width: Self.kartGenisligi, height: Self.kartGenisligi * 262 / 204)
                .clipShape(Kemer(alt: 16))
                .overlay(Kemer(alt: 16).stroke(Color(GaleriRenk.karis(r.pirinc, r.kenar, 1 - k * 0.7)), lineWidth: 1))
                .shadow(color: .black.opacity(0.7 * 0.45), radius: 25, y: 26 - 11)
                .opacity(1 - k * 0.55)
                // `.cark-yazi`: 320 genişlik (kartın iki yanından taşar), 3 aralık
                VStack(spacing: 3) {
                    Text(GaleriSergisi.yuzyillar(uyeler))
                        .font(Yazi.sans(13, agirlik: 600, stil: .footnote)).cssSatir(.sans, 13, 18.2)
                        .foregroundStyle(Color(r.pirinc))
                    Text(salon.ad)
                        .font(Yazi.serif(40, agirlik: 500, stil: .largeTitle)).tracking(-0.4).cssSatir(.serif, 40, 46)
                        .foregroundStyle(Color(salon.acik ? r.murekkep : r.murekkep2))
                        .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                    Group {
                        if salon.acik {
                            Text(salon.acikSayisi == salon.toplam ? "\(salon.toplam) sanatçının hepsi açık"
                                 : "\(salon.acikSayisi) / \(salon.toplam) sanatçı açık")
                        } else {
                            HStack(spacing: 6) {
                                GaleriIkon(simge: .kilit, boyut: 14, kalinlik: 1.6)
                                Text("Konu \(SiteYazisi.bulunmaEki(salon.acilacagiKonu ?? 0)) açılır")
                            }
                        }
                    }
                    .font(Yazi.sans(15, stil: .subheadline)).cssSatir(.sans, 15, 21)
                    .foregroundStyle(Color(r.murekkep2))
                    if salon.acik {
                        // `.cark-gir`: tek dolu düğme; 44 yükseklik, `--ink` zemin, 600 15 px
                        HStack(spacing: 4) {
                            Text("Salona gir").font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                            GaleriIkon(simge: .ileri, boyut: 16, kalinlik: 1.8)
                        }
                        .foregroundStyle(Color(r.zemin))
                        .padding(.leading, 22).padding(.trailing, 18)
                        .frame(height: 44)
                        .background(Capsule().fill(Color(r.murekkep)))
                        .padding(.top, 10)
                    }
                }
                .frame(width: min(320, w * 0.86))
                .padding(.top, 16)
                .opacity(max(0, 1 - k * 1.6))
            }
            .frame(width: Self.kartGenisligi)
            .contentShape(Rectangle())
        }
        .buttonStyle(KartBasma())
        .scaleEffect(1 - k * 0.2, anchor: UnitPoint(x: 0.5, y: 0.34))
        .offset(y: k * 30)
        .disabled(!salon.acik)
        .accessibilityElement(children: .combine)
        .accessibilityHint(salon.acik ? "Salona gir" : "")
    }

    // MARK: Çark

    /// Parmağın altındaki ad parmakla birlikte gider; bırakınca en yakın akıma oturur (hızlı fırlatma ilerletir).
    /// Dokunuş: dokunulan ad ortaya gelir.
    private func cevir(_ w: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard abs(v.translation.width) >= 6 || cevirme != nil else { return }
                if cevirme == nil { cevirme = (konum, v.startLocation.x) }
                // `oran`: şeridin bir adımı, çarkın bir adımının yay uzunluğuna
                let yay = Self.yaricap * Self.carkAdimi * .pi / 180
                let p = (cevirme?.bas ?? konum) - Double(v.translation.width) / yay
                konum = max(0, min(Double(salonlar.count - 1), p))
                // şerit en yakın akıma kayarak izler
                let yakin = Int(konum.rounded())
                if yakin != sira {
                    sira = yakin
                    withAnimation(.easeOut(duration: 0.25)) { secim = yakin }
                }
            }
            .onEnded { v in
                if cevirme != nil {
                    let yay = Self.yaricap * Self.carkAdimi * .pi / 180
                    let hiz = Double(v.predictedEndTranslation.width - v.translation.width) / yay
                    cevirme = nil
                    git(Int((konum - hiz * 0.35).rounded()))
                } else {
                    // dokunuş: ekranın ortasına göre açı
                    let sin = max(-1, min(1, Double(v.location.x - w / 2) / (Self.yaricap + 30)))
                    let kayma = Int((asin(sin) * 180 / .pi / Self.carkAdimi).rounded())
                    if kayma != 0 { git(sira + kayma) }
                }
            }
    }

    private func git(_ i: Int) {
        let hedef = max(0, min(salonlar.count - 1, i))
        withAnimation(hareketAz || tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.35)) {
            secim = hedef
            sira = hedef
        }
    }

    // MARK: Bütün akımlar

    private var dizinDugmesi: some View {
        Button {
            withAnimation(hareketAz ? nil : .easeOut(duration: 0.25)) { dizinAcik.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text(dizinAcik ? "Gizle" : "Bütün akımlar").font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                GaleriIkon(simge: .asagi, boyut: 16, kalinlik: 1.8).rotationEffect(.degrees(dizinAcik ? 180 : 0))
            }
            .foregroundStyle(Color(tema.renkler.murekkep2))
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(dizinAcik ? "açık" : "kapalı")
    }

    /// `.akim-dizin ol`: no (13 px), ad (500 19 px Bodoni), yüzyıllar · durum (13 px), sağda ileri ya da kilit
    private var dizin: some View {
        let r = tema.renkler
        return VStack(spacing: 0) {
            Ayrac()
            ForEach(Array(salonlar.enumerated()), id: \.offset) { i, a in
                Button { gir(a.ad) } label: {
                    HStack(spacing: 14) {
                        Text(String(format: "%02d", i + 1)).font(Yazi.sans(13, agirlik: 500, stil: .footnote)).monospacedDigit()
                            .foregroundStyle(Color(r.murekkep3)).frame(width: 22, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(a.ad).font(Yazi.serif(19, agirlik: 500)).cssSatir(.serif, 19, 22.8)
                                .foregroundStyle(Color(a.acik ? r.murekkep : r.murekkep3))
                            let yy = GaleriSergisi.yuzyillar(galeri.katalog.sanatcilar.filter { $0.akim == a.ad })
                            Text("\(yy) · " + (a.acik ? "\(a.acikSayisi) / \(a.toplam) sanatçı açık"
                                              : "Konu \(SiteYazisi.bulunmaEki(a.acilacagiKonu ?? 0)) açılır"))
                                .font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 16.9)
                                .foregroundStyle(Color(r.murekkep2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        GaleriIkon(simge: a.acik ? .ileri : .kilit, boyut: 16, kalinlik: 1.8).foregroundStyle(Color(r.murekkep3))
                    }
                    .padding(.vertical, 8).padding(.horizontal, 4)
                    .frame(minHeight: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!a.acik)
                Ayrac()
            }
        }
        .padding(.horizontal, BenOlcu.yan)
    }
}

private struct SeritKaymasi: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// `.zaman-kart:active .cark-gir { transform: scale(0.95) }` yerine bütün kart hafifçe küçülür
private struct KartBasma: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// `.cark-kemer`: üst köşeler genişliğin yarısı (yarım daire), alt köşeler `alt`
struct Kemer: Shape {
    var alt: CGFloat = 16
    func path(in r: CGRect) -> Path {
        let u = r.width / 2
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + u))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + u), radius: u, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - alt))
        p.addQuadCurve(to: CGPoint(x: r.maxX - alt, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + alt, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - alt), control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// `.cark-teker` ("Işık"): iki uca doğru silinen ince pirinç yay (yarıçap 700, merkez 748), altında hafif parıltı,
/// iki derecede bir çentik (halka 678–688, dönen), tepede ışıklı nokta, kenarda dönen komşu adlar ve "01 / 28" sayacı.
private struct CarkTekeri: View {
    let salonlar: [AkimDurumu]
    let konum: Double
    let sira: Int
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        GeometryReader { g in
            let w = g.size.width
            let merkez = CGPoint(x: w / 2, y: 48 + 700)
            ZStack(alignment: .top) {
                // `::before`: yayın altından yükselen ışık
                RadialGradient(stops: [.init(color: Color(r.pirinc, 0.16), location: 0), .init(color: Color(r.pirinc, 0.05), location: 0.55),
                                       .init(color: Color(r.pirinc, 0), location: 1)],
                               center: UnitPoint(x: 0.5, y: 0.46), startRadius: 0, endRadius: w * 0.46)
                    .scaleEffect(x: 1, y: 150 * 0.62 / (w * 0.46), anchor: UnitPoint(x: 0.5, y: 0.46))
                Canvas { c, boyut in
                    // `.cark-disk::after`: yayın üstünde 6 px, %40 pirinç, 5 px bulanık ışık
                    var yay = Path()
                    yay.addArc(center: merkez, radius: 700, startAngle: .degrees(-90 - 25), endAngle: .degrees(-90 + 25), clockwise: false)
                    var isik = c
                    isik.addFilter(.blur(radius: 5))
                    isik.stroke(yay, with: .color(Color(r.pirinc, 0.4)), lineWidth: 6)
                    c.stroke(yay, with: .color(Color(GaleriRenk.karis(r.pirinc, r.murekkep, 0.85))), lineWidth: 1)
                    // `.cark-halka`: 2°'de bir 0.16° genişliğinde çentik, 678–688 arası; şeritle döner
                    let don = -konum * AkimCarki.carkAdimi
                    var centik = Path()
                    for d in stride(from: -30.0, through: 30.0, by: 2) {
                        let a = (d + don.truncatingRemainder(dividingBy: 2)) * .pi / 180
                        centik.move(to: CGPoint(x: merkez.x + 678 * sin(a), y: merkez.y - 678 * cos(a)))
                        centik.addLine(to: CGPoint(x: merkez.x + 688 * sin(a), y: merkez.y - 688 * cos(a)))
                    }
                    c.stroke(centik, with: .color(Color(r.murekkep, 0.34)), lineWidth: 688 * 0.16 * .pi / 180)
                    _ = boyut
                }
                // `.cark-ibre`: tepede 8 px ışık
                Circle().fill(Color(RGBA(css: "#f4e3b8")!))
                    .frame(width: 8, height: 8)
                    .background(Circle().fill(Color(r.pirinc, 0.22)).frame(width: 18, height: 18))
                    .shadow(color: Color(r.pirinc, 0.4), radius: 10)
                    .position(x: w / 2, y: 48)
                // `.cark-ad`: 740 px yukarıda, (i − konum) · 12° dönmüş; seçili ad gizli (başlıkta var)
                ForEach(Array(salonlar.enumerated()), id: \.offset) { i, a in
                    let aci = (Double(i) - konum) * AkimCarki.carkAdimi
                    if abs(aci) <= 24 && abs(Double(i) - konum) >= 0.5 {
                        Text(a.ad)
                            .font(Yazi.sans(12, agirlik: 500, stil: .caption1)).cssSatir(.sans, 12, 13.8)
                            .foregroundStyle(Color(a.acik ? r.murekkep : r.soluk, a.acik ? 0.5 : 1))
                            .multilineTextAlignment(.center).lineLimit(2)
                            .frame(width: 124, height: 30, alignment: .bottom)
                            .opacity(1 - max(0, abs(aci) - 10) / 12)
                            .rotationEffect(.degrees(aci), anchor: .bottom)
                            .position(x: merkez.x + 740 * sin(aci * .pi / 180),
                                      y: merkez.y - 740 * cos(aci * .pi / 180) - 15)
                    }
                }
                // `.cark-sayac`: 500 28 px Bodoni no, 16 px "/ 28"
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%02d", sira + 1)).font(Yazi.serif(28, agirlik: 500)).monospacedDigit()
                        .foregroundStyle(Color(r.murekkep))
                    Text("/ \(salonlar.count)").font(Yazi.serif(16)).foregroundStyle(Color(r.murekkep2))
                }
                .padding(.top, 78 - 6)
            }
            .frame(width: w, height: 150)
            // `-webkit-mask`: iki uçta silinir
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.16),
                                         .init(color: .black, location: 0.84), .init(color: .clear, location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .clipped()
        }
        .accessibilityHidden(true)
    }
}

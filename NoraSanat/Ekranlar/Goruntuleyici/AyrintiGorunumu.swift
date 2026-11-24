// Kaynak: sanat-atlasi js/ayrinti.js, js/goruntuleyici.js @ a866b86; İş 180 (İncele yeniden): js/goruntuleyici.js,
// css/app.css sonundaki "İş 180" bölümü @ cca62eb (ilk commit f185307a)
import SwiftUI
import NoraCekirdek

/// İş 180'in renkleri (`css/app.css`): kartın yazıları ve düğmelerin buzlu zemini.
enum IncelemeTema {
    static let acik = Color(red: 243 / 255.0, green: 239 / 255.0, blue: 233 / 255.0)       // #f3efe9
    static let yazi = Color(red: 235 / 255.0, green: 229 / 255.0, blue: 218 / 255.0)       // #ebe5da
    static let kartZemini = Color(red: 24 / 255.0, green: 22 / 255.0, blue: 20 / 255.0)   // rgba(24, 22, 20, .52)
    static let dugmeZemini = Color(red: 30 / 255.0, green: 27 / 255.0, blue: 24 / 255.0)  // rgba(30, 27, 24, …)
    /// `.gor-inc-kart.gel`: 0.45 s bekler, 0.9 s'de 14 px aşağıdan süzülerek belirir
    static let gelEgri = Animation.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.9)
    /// Kamera (`uygula(true, 560)`: `GECIS_EGRI` = cubic-bezier(0.2, 0.8, 0.2, 1))
    static let kameraEgri = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.56)
}

/// Ayrıntıların yeri: görünmez dokunma alanları (`.gor-noktalar .gor-nokta`, İş 180: numara ve halka yok).
/// Tablo yakınlaşıp kaydıkça alan görselin üstündeki yerinde kalır; kendi boyu (44 pt) sabit.
struct AyrintiNoktalariKatmani: View {
    let kayit: AyrintiKaydi
    let tabanBoyutu: CGSize
    let olcek: CGFloat
    let kayma: CGSize
    let secildi: (Int) -> Void

    var body: some View {
        ZStack {
            ForEach(Array(kayit.noktalar.enumerated()), id: \.offset) { sira, nokta in
                let yer = nokta.yerYuzdesi
                let x = (CGFloat(yer.x) / 100.0 - 0.5) * tabanBoyutu.width * olcek + kayma.width
                let y = (CGFloat(yer.y) / 100.0 - 0.5) * tabanBoyutu.height * olcek + kayma.height

                Button {
                    secildi(sira)
                } label: {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(nokta.ad)
                .offset(x: x, y: y)
            }
        }
    }
}

/// Yarı saydam, buzlu yazı kartı (`.gor-inc-kart`): üst satır ("2 / 6", genel bakışta "6 ayrıntı"), Bodoni başlık,
/// Newsreader metin. Başlığa dokununca yalnız başlık kalır (`.kapali`).
struct IncelemeKarti: View {
    let kayit: AyrintiKaydi
    let sira: Int
    /// Genel bakışta başlık: eserin adı
    let eserAdi: String
    let kapali: Bool
    let katla: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var azSaydam

    private var nokta: AyrintiNoktasi? {
        sira >= 0 && sira < kayit.noktalar.count ? kayit.noktalar[sira] : nil
    }

    private var metinGorunur: Bool { nokta != nil && !kapali }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: katla) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AyrintiKurallari.kartUstSatiri(kayit, sira: sira).uppercased(with: Locale(identifier: "tr_TR")))
                            .font(Yazi.sans(11, agirlik: 500, stil: .caption2))
                            .tracking(11 * 0.14)
                            .foregroundStyle(IncelemeTema.yazi.opacity(0.68))
                        CssBaslik(metin: nokta?.ad ?? eserAdi, boyut: 24, satir: 24 * 1.12)
                            .foregroundStyle(IncelemeTema.acik)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .regular))
                        .frame(width: 18, height: 18)
                        .foregroundStyle(IncelemeTema.yazi.opacity(0.7))
                        .rotationEffect(.degrees(kapali ? 180 : 0))
                        .animation(.easeInOut(duration: 0.4), value: kapali)
                        .padding(.top, 2)
                }
                .padding(.top, 16)
                .padding(.horizontal, 18)
                .padding(.bottom, metinGorunur ? 0 : 16)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(nokta?.ad ?? eserAdi)
            .accessibilityHint(kapali ? "Yazıyı göster" : "Yazıyı gizle")

            if metinGorunur, let nokta {
                Text(nokta.metin)
                    .font(Yazi.okuma(17))
                    .lineSpacing(8)
                    .foregroundStyle(IncelemeTema.yazi)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if azSaydam {
                IncelemeTema.kartZemini.opacity(0.92)
            } else {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    IncelemeTema.kartZemini.opacity(0.52)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(IncelemeTema.yazi.opacity(0.14), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
    }
}

/// Alttaki gezinme (`.gor-inc-dugmeler`): küçük geri düğmesi, ayrıntı başına bir parçalı ilerleme çubuğu (parçaya
/// dokununca o ayrıntı), ilerlemeyi halkasında gösteren yuvarlak ilerle düğmesi.
struct IncelemeDugmeleri: View {
    let kayit: AyrintiKaydi
    let sira: Int
    let hareketAz: Bool
    let git: (Int) -> Void

    private var sayi: Int { kayit.noktalar.count }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                git(sira - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(IncelemeTema.acik)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.ultraThinMaterial).opacity(0.6))
                    .background(Circle().fill(IncelemeTema.dugmeZemini.opacity(0.28)))
                    .overlay(Circle().strokeBorder(IncelemeTema.acik.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(sira <= 0)
            .opacity(sira <= 0 ? 0.35 : 1)
            .accessibilityLabel("Önceki ayrıntı")

            serit

            Button {
                git(sira + 1)
            } label: {
                ZStack {
                    Circle().fill(.ultraThinMaterial).opacity(0.6)
                    Circle().fill(IncelemeTema.dugmeZemini.opacity(0.32))
                    Circle()
                        .stroke(IncelemeTema.acik.opacity(0.16), lineWidth: 1.5)
                        .padding(1)
                    Circle()
                        .trim(from: 0, to: AyrintiKurallari.halkaOrani(sira: sira, sayi: sayi))
                        .stroke(IncelemeTema.acik, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(1)
                        .animation(hareketAz ? nil : .timingCurve(0.45, 0, 0.2, 1, duration: 0.9), value: sira)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(IncelemeTema.acik)
                }
                .frame(width: 60, height: 60)
            }
            .buttonStyle(.plain)
            .disabled(sira >= sayi - 1)
            .opacity(sira >= sayi - 1 ? 0.35 : 1)
            .accessibilityLabel("Sonraki ayrıntı")
        }
        .padding(.horizontal, 6)
        .environment(\.colorScheme, .dark)
    }

    /// `.gor-inc-serit`: parçalar eşit, etkin parça 2.4 kat geniş; geçilenler yarı, etkin tam açık
    private var serit: some View {
        GeometryReader { geo in
            let ara: CGFloat = 5
            let birim = max(0, geo.size.width - ara * CGFloat(max(0, sayi - 1)))
                / (CGFloat(sayi - 1) + (sira >= 0 && sira < sayi ? 2.4 : 1))
            HStack(spacing: ara) {
                ForEach(0..<sayi, id: \.self) { k in
                    Button {
                        git(k)
                    } label: {
                        Capsule()
                            .fill(k == sira ? IncelemeTema.acik : IncelemeTema.acik.opacity(k < sira ? 0.55 : 0.22))
                            .frame(height: 3)
                            .shadow(color: .black.opacity(0.3), radius: 1.5)
                            .frame(width: birim * (k == sira ? 2.4 : 1), height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(kayit.noktalar[k].ad)
                    .accessibilityAddTraits(k == sira ? .isSelected : [])
                }
            }
            .animation(hareketAz ? nil : .timingCurve(0.45, 0, 0.2, 1, duration: 0.45), value: sira)
        }
        .frame(height: 44)
    }
}

/// İncelemeyi bitir (`.gor-inc-bitir`): "Bitir" yazısı yerine kapat düğmesinin solunda küçült simgeli buzlu yuvarlak
struct IncelemeKucultDugmesi: View {
    let bitir: () -> Void

    var body: some View {
        Button(action: bitir) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(IncelemeTema.acik)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial).opacity(0.6))
                .background(Circle().fill(IncelemeTema.dugmeZemini.opacity(0.38)))
                .overlay(Circle().strokeBorder(IncelemeTema.acik.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .environment(\.colorScheme, .dark)
        .accessibilityLabel("İncelemeyi bitir")
    }
}

/// Bir görünümün sahnedeki çerçevesini ölçer (kamera kartın ve düğmelerin dışındaki boşluğa bakar)
struct SahneCercevesi: ViewModifier {
    let alan: String
    @Binding var cerceve: CGRect

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { geo in
                let r = geo.frame(in: .named(alan))
                Color.clear
                    .onAppear { cerceve = r }
                    .onChange(of: r) { _, yeni in cerceve = yeni }
            }
        }
    }
}

extension View {
    func sahneCercevesi(_ alan: String, _ cerceve: Binding<CGRect>) -> some View {
        modifier(SahneCercevesi(alan: alan, cerceve: cerceve))
    }
}

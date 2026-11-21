// Kaynak: sanat-atlasi js/ayrinti.js, js/goruntuleyici.js @ a866b86
import SwiftUI
import NoraCekirdek

/// Tablonun üstündeki numaralı ayrıntı noktaları katmanı (`.gor-noktalar`).
/// Tablo yakınlaşıp kaydıkça noktalar görselin üzerindeki yerinde kalır; nokta işaretlerinin kendi boyu sabit kalır.
struct AyrintiNoktalariKatmani: View {
    let kayit: AyrintiKaydi
    let seciliSira: Int
    let tabanBoyutu: CGSize
    let olcek: CGFloat
    let kayma: CGSize
    let secildi: (Int) -> Void

    var body: some View {
        ZStack {
            ForEach(Array(kayit.noktalar.enumerated()), id: \.offset) { sira, nokta in
                let yer = nokta.yerYuzdesi
                let aktif = sira == seciliSira
                let x = (CGFloat(yer.x) / 100.0 - 0.5) * tabanBoyutu.width * olcek + kayma.width
                let y = (CGFloat(yer.y) / 100.0 - 0.5) * tabanBoyutu.height * olcek + kayma.height

                Button {
                    secildi(sira)
                } label: {
                    Text("\(sira + 1)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(aktif ? GoruntuleyiciTema.vurguYazi : Color(red: 244 / 255.0, green: 239 / 255.0, blue: 230 / 255.0))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(aktif ? GoruntuleyiciTema.vurgu : Color(red: 20 / 255.0, green: 18 / 255.0, blue: 16 / 255.0).opacity(0.62))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    aktif ? GoruntuleyiciTema.vurguYazi : Color.white.opacity(0.85),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 1)
                        .scaleEffect(aktif ? 1.12 : 1.0)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(sira + 1). \(nokta.ad)")
                .offset(x: x, y: y)
            }
        }
        .animation(.easeOut(duration: 0.2), value: seciliSira)
    }
}

/// Görüntüleyicinin altındaki rehberli inceleme kontrol paneli (`.gor-inceleme`).
struct AyrintiIncelemePaneli: View {
    let kayit: AyrintiKaydi
    let seciliSira: Int
    let onceki: () -> Void
    let sonraki: () -> Void
    let bitir: () -> Void

    private var seciliNokta: AyrintiNoktasi? {
        guard seciliSira >= 0, seciliSira < kayit.noktalar.count else { return nil }
        return kayit.noktalar[seciliSira]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(seciliNokta != nil ? "\(seciliSira + 1) / \(kayit.noktalar.count)" : "\(kayit.noktalar.count) \(kayit.birim)")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.7)
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)

                if let nokta = seciliNokta {
                    Text(nokta.ad)
                        .font(.system(size: 19, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                }
            }

            Text(seciliNokta?.metin ?? "Tablonun üstündeki numaralı noktalara dokun ya da Sonraki ile başla.")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(seciliNokta != nil ? GoruntuleyiciTema.murekkep : GoruntuleyiciTema.ikincilMurekkep)
                .lineSpacing(4)
                .frame(minHeight: 68, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button(action: onceki) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Önceki")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(GoruntuleyiciTema.yuzey)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1)
                    )
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                }
                .buttonStyle(.plain)
                .disabled(seciliSira <= 0)
                .opacity(seciliSira <= 0 ? 0.4 : 1.0)

                Button(action: sonraki) {
                    HStack(spacing: 4) {
                        Text("Sonraki")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(GoruntuleyiciTema.vurgu)
                    )
                    .foregroundStyle(GoruntuleyiciTema.vurguYazi)
                }
                .buttonStyle(.plain)
                .disabled(seciliSira >= kayit.noktalar.count - 1)
                .opacity(seciliSira >= kayit.noktalar.count - 1 ? 0.4 : 1.0)

                Button(action: bitir) {
                    Text("Bitir")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(GoruntuleyiciTema.yuzey)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1)
                        )
                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
}

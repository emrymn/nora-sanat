// Kaynak: sanat-atlasi js/ekranlar/hizliAyar.js, css/app.css (.hizli-yaprak, .hizli-parca, .hizli-adim, .hizli-hepsi)
// @ a866b86 (site 1.90.3)
import NoraCekirdek
import SwiftUI

/// Hızlı ayarlar (İş 172): sekme çubuğunun arkasından yükselen yaprak. Tema, Hareket, Günlük kart ve "Bütün ayarlar".
/// Değerler sitenin kaydına sitenin yaprağıyla aynı biçimde yazılır (`SekmeCubuguKoprusu.yazmaBetigi`); tema değişince
/// site `temaUygula()` yapar, `TemaKoprusu` yeni renkleri getirir.
struct HizliAyarYapragi: View {
    let kapat: () -> Void
    @Environment(TemaDeposu.self) private var tema
    @State private var ayar = SekmeCubuguKoprusu.Ayarlar()

    var body: some View {
        let r = tema.renkler
        VStack(alignment: .leading, spacing: 0) {
            Text("Hızlı ayarlar")
                .font(Font(Yazi.uiFont(.serif, 30)))
                .frame(height: 33)
                .accessibilityAddTraits(.isHeader)
            satir("Tema", HizliAyar.temalar, secili: ayar.tema) { yaz("tema", $0) }
                .padding(.top, 18)
            satir("Hareket", HizliAyar.hareketler, secili: ayar.hareket) { yaz("hareket", $0) }
                .padding(.top, 24)
            kart.padding(.top, 18)
            Button {
                kapat()
                Gezgin.shared.git("#/ayarlar")
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bütün ayarlar").font(Font(Yazi.uiFont(.sans, 16, agirlik: 600)))
                        Text("Yedek, çevrimdışı görseller, yazı boyu")
                            .font(Font(Yazi.uiFont(.sans, 13)))
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    Spacer(minLength: 8)
                    SimgeGorunumu(simge: .ileri, boyut: 18, kalinlik: 1.7)
                }
                .padding(.leading, 18).padding(.trailing, 16)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(r.pirinc).opacity(0.5), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
        }
        .foregroundStyle(Color(r.murekkep))
        .padding(.top, 26).padding(.horizontal, 20).padding(.bottom, 51)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: SekmeCubugu.Olcu.yaprakKose,
                                   topTrailingRadius: SekmeCubugu.Olcu.yaprakKose)
                .fill(Color(r.yuzey))
                .shadow(color: .black.opacity(tema.koyu ? 0.55 : 0.2), radius: 25, x: 0, y: -16)
        )
        .gesture(DragGesture(minimumDistance: 6).onEnded { d in
            let hiz = d.predictedEndTranslation.height - d.translation.height
            if d.translation.height > 70 || hiz > 120 { kapat() }
        })
        .accessibilityAddTraits(.isModal)
        .task {
            if let a = await SekmeCubuguKoprusu.ayarlar() { ayar = a }
        }
    }

    /// Küçük büyük harfli etiket (`.etiket`): 600 11px, harf arası 0.2em, mürekkep 2
    private func etiket(_ s: String) -> some View {
        Text(s.uppercased(with: Locale(identifier: "tr_TR")))
            .font(Font(Yazi.uiFont(.sans, 11, agirlik: 600)))
            .tracking(2.2)
            .foregroundStyle(Color(tema.renkler.murekkep2))
    }

    /// `.hizli-parca`: zemin renkli yuvarlak kutuda pirinç sürgülü seçim
    private func satir(_ ad: String, _ secenekler: [(String, String)], secili: String,
                       sec: @escaping (String) -> Void) -> some View {
        let r = tema.renkler
        let i = max(0, secenekler.firstIndex { $0.0 == secili } ?? 0)
        return VStack(alignment: .leading, spacing: 9) {
            etiket(ad)
            GeometryReader { g in
                let gen = (g.size.width - 8) / CGFloat(secenekler.count)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(r.pirinc))
                        .frame(width: gen, height: 46)
                        .offset(x: 4 + CGFloat(i) * gen)
                        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4), value: i)
                    HStack(spacing: 0) {
                        ForEach(Array(secenekler.enumerated()), id: \.offset) { j, s in
                            Button { sec(s.0) } label: {
                                Text(s.1)
                                    .font(Font(Yazi.uiFont(.sans, 15, agirlik: 700)))
                                    .foregroundStyle(Color(j == i ? r.pirincYazi : r.murekkep2))
                                    .frame(width: gen, height: 46)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(j == i ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(width: g.size.width, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(r.zemin)))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(r.kenar), lineWidth: 1))
            }
            .frame(height: 56)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ad)
    }

    /// Günlük kart: −5 / +5 (5…100)
    private var kart: some View {
        let r = tema.renkler
        let dugme = { (simge: SekmeCubugu.Simge, adim: Int, ad: String) in
            Button { yaz("kart", adim) } label: {
                SimgeGorunumu(simge: simge, boyut: 18, kalinlik: 1.8)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color(r.zemin)))
                    .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ad)
        }
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                etiket("Günlük kart")
                Text("Bir turda kaç kart gelsin")
                    .font(Font(Yazi.uiFont(.sans, 13)))
                    .foregroundStyle(Color(r.murekkep2))
            }
            Spacer(minLength: 8)
            dugme(.eksi, -HizliAyar.kartAdimi, "Azalt")
            Text("\(ayar.gunlukKart)")
                .font(Font(Yazi.uiFont(.serif, 40)))
                .monospacedDigit()
                .contentTransition(.numericText())
                .frame(minWidth: 56)
                .accessibilityLabel("Günlük kart \(ayar.gunlukKart)")
            dugme(.arti, HizliAyar.kartAdimi, "Artır")
        }
    }

    private func yaz(_ alan: String, _ deger: Any) {
        // Hemen göster; sitenin cevabı gelince onunla düzelt
        withAnimation(.easeOut(duration: 0.2)) {
            switch alan {
            case "tema": ayar.tema = deger as? String ?? ayar.tema
            case "hareket": ayar.hareket = deger as? String ?? ayar.hareket
            default: ayar.gunlukKart = HizliAyar.gunlukKart(ayar.gunlukKart, deger as? Int ?? 0)
            }
        }
        Task {
            if let a = await SekmeCubuguKoprusu.yaz(alan, deger) { withAnimation(.easeOut(duration: 0.2)) { ayar = a } }
        }
    }
}

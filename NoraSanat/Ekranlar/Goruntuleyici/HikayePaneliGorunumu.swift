// Kaynak: sanat-atlasi js/hikaye.js, js/goruntuleyici.js @ a866b86
import SwiftUI
import NoraCekirdek

/// Görüntüleyicide alttan açılan "Hikâyesi" paneli (`.gor-hikaye`).
/// Bölümler: "Ne oluyor?", "Kim kimdir?", "Ressamla bağı", "Gözden kaçanlar".
/// Kutusu olan karakterler varsa "Karakterleri resimde gör · N" düğmesiyle rehberli inceleme başlatılır.
struct HikayePaneliGorunumu: View {
    let hikaye: HikayeKaydi
    let kapat: () -> Void
    let karakterleriGor: (AyrintiKaydi) -> Void

    private var karakterKaydi: AyrintiKaydi? {
        hikaye.karakterKaydi
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("HİKÂYESİ")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2.2)
                            .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)

                        Spacer()

                        Button(action: kapat) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(GoruntuleyiciTema.murekkep)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Hikâyeyi kapat")
                    }

                    Text(hikaye.baslik)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(GoruntuleyiciTema.murekkep)

                    if !hikaye.sanatci.isEmpty {
                        Text(hikaye.sanatci)
                            .font(.system(size: 14))
                            .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                            .padding(.bottom, 4)
                    }

                    if let kar = karakterKaydi {
                        Button {
                            karakterleriGor(kar)
                        } label: {
                            Text("Karakterleri resimde gör · \(kar.noktalar.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(GoruntuleyiciTema.murekkep)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(GoruntuleyiciTema.vurgu.opacity(0.14))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(GoruntuleyiciTema.vurgu.opacity(0.7), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 4)
                    }

                    bolumBasligi("NE OLUYOR?")
                    ForEach(Array(hikaye.olay.enumerated()), id: \.offset) { _, paragraf in
                        Text(paragraf)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundStyle(GoruntuleyiciTema.murekkep)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !hikaye.kim.isEmpty {
                        bolumBasligi("KİM KİMDİR?")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(hikaye.kim.enumerated()), id: \.offset) { _, karakter in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                                    (Text(karakter.ad)
                                        .font(.system(size: 15, weight: .bold))
                                    + Text(" " + karakter.metin)
                                        .font(.system(size: 16, weight: .regular, design: .serif)))
                                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    if !hikaye.ressam.isEmpty {
                        bolumBasligi("RESSAMLA BAĞI")
                        ForEach(Array(hikaye.ressam.enumerated()), id: \.offset) { _, paragraf in
                            Text(paragraf)
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundStyle(GoruntuleyiciTema.murekkep)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !hikaye.gozden.isEmpty {
                        bolumBasligi("GÖZDEN KAÇANLAR")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(hikaye.gozden.enumerated()), id: \.offset) { _, madde in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                                    Text(madde)
                                        .font(.system(size: 16, weight: .regular, design: .serif))
                                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.78)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24)
                    .fill(GoruntuleyiciTema.yuzey)
                    .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: -10)
            )
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24)
                    .strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func bolumBasligi(_ metin: String) -> some View {
        Text(metin)
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.0)
            .foregroundStyle(GoruntuleyiciTema.vurgu)
            .padding(.top, 10)
    }
}

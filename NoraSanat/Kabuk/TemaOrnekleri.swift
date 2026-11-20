#if DEBUG
import NoraCekirdek
import SwiftUI

/// Yalnız geliştirme: `-ekran tema` ile açılınca temanın renk ve yazı örnekleri (T3). Solda Gece, sağda Gündüz
/// (css/app.css sabitleri); altta sitenin şu anki teması (site arkada yüklenir, `TemaKoprusu` canlı değişkenleri getirir).
struct TemaOrnekleri: View {
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    panel("Gece", .gece)
                    panel("Gündüz", .gunduz)
                }
                panel("Sitede şu an · \(tema.ayar.tema.ad) · hareket \(tema.ayar.hareket)", tema.renkler, genis: true)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }

    private func panel(_ baslik: String, _ r: TemaRenkleri, genis: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(baslik.uppercased()).font(Yazi.sans(11, agirlik: 600)).tracking(1.2).foregroundStyle(Color(r.murekkep3))
            Text("Venüs'ün Doğuşu").font(Yazi.serif(genis ? 34 : 26)).foregroundStyle(Color(r.murekkep))
            Text("Sandro Botticelli · 1485").font(Yazi.serif(15, italik: true)).foregroundStyle(Color(r.murekkep2))
            Text("Deniz kabuğunun üstünde kıyıya yaklaşan tanrıça; rüzgâr tanrıları onu üfleyerek iter.")
                .font(Yazi.okuma(15)).foregroundStyle(Color(r.murekkep))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                etiket("Doğru", r.dogruZemin, r.dogru)
                etiket("Yanlış", r.yanlisZemin, r.yanlis)
            }
            HStack(spacing: 6) {
                dugme("Başla", r.vurgu, r.vurguYazi)
                dugme("Pirinç", r.pirinc, r.pirincYazi)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: genis ? 8 : 4), spacing: 4) {
                ForEach(TemaRenkleri.degiskenler, id: \.0) { e in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3).fill(Color(r[keyPath: e.1]))
                            .frame(height: 22)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(r.kenar), lineWidth: 0.5))
                        Text(String(e.0.dropFirst(2))).font(.system(size: 7)).foregroundStyle(Color(r.murekkep3)).lineLimit(1)
                    }
                }
            }
            HStack(spacing: 8) {
                ForEach(Self.aileler, id: \.0) { e in
                    Text("\(e.0) \(Yazi.yuklu(e.1) ? "✓" : "✗")").font(Yazi.sans(10)).foregroundStyle(Color(r.murekkep3))
                }
            }
        }
        .padding(16)
        .padding(.top, genis ? 0 : 48)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(r.zemin))
    }

    private static let aileler: [(String, Yazi.Aile)] = [("Bodoni", .serif), ("Archivo", .sans), ("Newsreader", .okuma)]

    private func etiket(_ s: String, _ zemin: RGBA, _ yazi: RGBA) -> some View {
        Text(s).font(Yazi.sans(12, agirlik: 600)).padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(zemin), in: Capsule()).foregroundStyle(Color(yazi))
    }

    private func dugme(_ s: String, _ zemin: RGBA, _ yazi: RGBA) -> some View {
        Text(s).font(Yazi.sans(13, agirlik: 600)).padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(zemin), in: Capsule()).foregroundStyle(Color(yazi))
    }
}
#endif

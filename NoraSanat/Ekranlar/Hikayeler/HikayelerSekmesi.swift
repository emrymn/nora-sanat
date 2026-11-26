// Z4b · Hikâyeler sekmesi (yeni; sitede yok). Tasarım: Neon "Yön 2 · Substack Minimal" (Emre seçti; dal
// neon/hikayeler-tasarim-3, PR #75, birleştirilmedi): tasarim/hikayeler-3/yon-2.html (`.sub-ust`, `.sub-akis`,
// `.sub-yazi`), ortak.css, goruntuler/yon-2-ana-{gece,gunduz}.png. Emre'nin değişikliği: "Ben" çubukta değil, sağ üstteki
// kişi düğmesinde (Yön 2'nin ayrı yuvarlak Ben kapsülü yok).
import NoraCekirdek
import SwiftUI

/// Hikâyeler sitede yok: hep yerli
enum HikayelerGecisi {
    static var sekmeler: Set<Sekme> { [.hikayeler] }
}

struct HikayelerSekmesi: View {
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    /// Açık yazılar (bağlantılı yazıdan yazıya geçilebilir)
    @State private var yol: [String] = []
    @State private var aramaAcik = false
    @State private var basaDon = 0

    var body: some View {
        NavigationStack(path: $yol) {
            Group {
                switch depo.durum {
                case .hazir:
                    HikayeAna(ac: ac, aramaAcik: $aramaAcik, basaDon: basaDon)
                case .yukleniyor:
                    ProgressView("Hikâyeler hazırlanıyor…")
                        .font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(tema.renkler.zemin).ignoresSafeArea())
                case .yok:
                    VStack(spacing: 16) {
                        Text("Hikâyeler yüklenemedi.").font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                        Button("Yeniden dene") { Task { await depo.yukle(zorla: true) } }.buttonStyle(HapDugme())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(tema.renkler.zemin).ignoresSafeArea())
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                Group {
                    if let h = depo.hikaye(id) {
                        HikayeOkuma(hikaye: h, ac: ac)
                    } else {
                        Color(tema.renkler.zemin).ignoresSafeArea()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        // Okurken çubuk yok: altta çalar durur (tasarımda okuma ekranı sekmesiz)
        .sekmeCubuguGizli(!yol.isEmpty, sekme: .hikayeler)
        .task {
            await depo.yukle()
            #if DEBUG
            HikayeProva.sekmeAcildi()
            #endif
        }
        .onChange(of: kabuk.yerliAdres[.hikayeler], initial: true) { _, adres in
            guard let adres else { return }
            if let id = HikayeAdresi.sanatci(adres) {
                if yol.last != id { yol = [id] }
            } else {
                yol = []
            }
            kabuk.adresIslendi(.hikayeler)
        }
        .onChange(of: kabuk.yenidenDokunma[.hikayeler]) { _, _ in
            // Açık sekmeye yeniden dokunma: yazıdan ana ekrana, ana ekranda en başa
            if !yol.isEmpty { yol = [] } else { basaDon += 1 }
        }
    }

    private func ac(_ id: String) {
        Titresim.secim()
        yol.append(id)
    }
}

// MARK: - Ana ekran

/// Alt alta yazılar: yarım kalan en üstte (ilerleme çizgisiyle), sonra öbürleri. Sağ üstte arama ve Ben.
struct HikayeAna: View {
    let ac: (String) -> Void
    @Binding var aramaAcik: Bool
    let basaDon: Int

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let l = depo.sirali
        ScrollViewReader { kaydir in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(Array(l.enumerated()), id: \.element.id) { i, h in
                            satir(depo.satir(h), ilk: i == 0, son: i == l.count - 1)
                        }
                        // Küçük çalar açıkken son yazı çaların altında kalmasın
                        Color.clear.frame(height: calar.acik ? 84 : 12)
                    } header: {
                        ust.id("ust")
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .onChange(of: basaDon) { _, _ in withAnimation(.easeOut(duration: 0.35)) { kaydir.scrollTo("ust", anchor: .top) } }
        }
        .background(c.zemin.ignoresSafeArea())
        // Yapışkan başlığın üstü (saat, pil) de zemin renginde: yazılar altından geçerken görünmesin
        .overlay(alignment: .top) { c.zemin.frame(height: 0).ignoresSafeArea(edges: .top) }
        .overlay {
            if aramaAcik {
                HikayeArama(kapat: { withAnimation(.easeOut(duration: 0.2)) { aramaAcik = false } }) { id in
                    aramaAcik = false
                    ac(id)
                }
                .transition(.opacity)
            }
        }
    }

    /// `.sub-ust`: yapışkan, zemin renginde; "Hikâyeler" Newsreader 28/600, sağda büyüteç ve Ben
    private var ust: some View {
        let c = HikayeRenk(r: tema.renkler)
        return HStack(spacing: 10) {
            Text("Hikâyeler")
                .font(Yazi.okuma(28, agirlik: 600, stil: .largeTitle))
                .tracking(-0.56)
                .foregroundStyle(c.yazi)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Button {
                withAnimation(.easeOut(duration: 0.2)) { aramaAcik = true }
            } label: {
                HikayeIkon(simge: .ara, boyut: 19, kalinlik: 1.7)
            }
            .buttonStyle(HikayeCamDugme())
            .accessibilityLabel("Ara")
            BenDugmesi()
        }
        .padding(.leading, 22).padding(.trailing, 18)
        .padding(.top, 8).padding(.bottom, 12)
        .background(c.zemin)
    }

    /// `.sub-yazi`: kutusuz, sola yaslı; sanatçı · yıllar ve durum, 16:10 kapak (16 köşe), başlık, alt başlık, süreler
    private func satir(_ s: HikayeSatiri, ilk: Bool, son: Bool) -> some View {
        let c = HikayeRenk(r: tema.renkler)
        let yer = depo.yer(s.id)
        let durum = HikayeAkisi.durum(s.hikaye, yer: yer)
        return Button { ac(s.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    (Text(s.sanatci).font(Yazi.sans(13, agirlik: 600)).foregroundColor(c.yazi)
                        + Text(s.yillar.isEmpty ? "" : " · \(s.yillar)").font(Yazi.sans(13)).foregroundColor(c.yazi3))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    durumYazisi(durum, c)
                }
                .padding(.bottom, 10)
                Color.clear
                    .aspectRatio(16 / 10, contentMode: .fit)
                    .overlay {
                        UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 22])
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.bottom, 14)
                Text(s.hikaye.baslik)
                    .font(Yazi.okuma(ilk ? 27 : 24, agirlik: 600))
                    .tracking(ilk ? -0.4 : -0.36)
                    .cssSatir(.okuma, ilk ? 27 : 24, (ilk ? 27 : 24) * 1.22)
                    .foregroundStyle(c.yazi)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 7)
                if !s.hikaye.altBaslik.isEmpty {
                    Text(s.hikaye.altBaslik)
                        .font(Yazi.sans(14.5))
                        .cssSatir(.sans, 14.5, 14.5 * 1.5)
                        .foregroundStyle(c.yazi2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 12)
                }
                Text("\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme")
                    .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
                if let y = yer, y.yarim {
                    HikayeCizgi(oran: y.oran).padding(.top, 11)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, ilk ? 8 : 20).padding(.bottom, 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { if !son { Rectangle().fill(c.kenar).frame(height: 1) } }
        .padding(.horizontal, 22)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Yazıyı aç")
        .accessibilityIdentifier("hikaye-\(s.id)")
    }

    @ViewBuilder
    private func durumYazisi(_ d: HikayeAkisi.Durum, _ c: HikayeRenk) -> some View {
        switch d {
        case .yeni: Text("Yeni").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc)
        case .yarim(let dk): Text("\(dk) dk kaldı").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc)
        case .okundu: Text("Okundu").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.dogru)
        case .yok: EmptyView()
        }
    }
}

// MARK: - Arama

/// Sade arama: sanatçı adı ya da başlık (`.arama-katman`)
struct HikayeArama: View {
    let kapat: () -> Void
    let sec: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    @State private var sorgu = ""
    @FocusState private var odak: Bool

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let sonuc = HikayeAkisi.ara(depo.sirali, sorgu: sorgu, sanatciAdi: depo.sanatciAdi)
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    HikayeIkon(simge: .ara, boyut: 18, kalinlik: 1.6).foregroundStyle(c.yazi3)
                    TextField("Yazı veya sanatçı ara…", text: $sorgu)
                        .font(Yazi.sans(16))
                        .foregroundStyle(c.yazi)
                        .focused($odak)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Capsule().fill(c.yuzey))
                .overlay(Capsule().strokeBorder(c.kenar, lineWidth: 1))
                Button("Vazgeç", action: kapat)
                    .font(Yazi.sans(14, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 10)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sonuc) { h in
                        let s = depo.satir(h)
                        Button { sec(h.id) } label: {
                            HStack(spacing: 12) {
                                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 22])
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(h.baslik).font(Yazi.okuma(17, agirlik: 600)).foregroundStyle(c.yazi)
                                        .lineLimit(2)
                                    Text("\(s.sanatci) · \(s.yillar) · \(s.okumaDk) dk okuma")
                                        .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
                    }
                    if sonuc.isEmpty {
                        Text("Bu aramayla yazı yok.").font(Yazi.sans(15)).foregroundStyle(c.yazi2).padding(.top, 24)
                    }
                }
                .padding(.horizontal, 22)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(c.zemin.ignoresSafeArea())
        .onAppear { odak = true }
    }
}

// Z4f: ana ekran bütün hikâyelerin kapak ızgarası (Emre: "bütün hikâyeler gözüksün"); Z4e'nin öne çıkanları ve arşivi kalktı.
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

/// Z4f (Emre: "çok sıra sıra olmuş, ben bütün hikâyeler gözüksün istiyorum"): bütün hikâyeler iki sütunlu kapak
/// ızgarasında; üstte süzgeç (Tümü · Dönem · Beğendiklerim · Sonra oku) ve varsa Devam et şeridi. Öne çıkanlar ve ayrı
/// arşiv sayfası kalktı (Z4e). Sağ üstte arama ve Ben.
struct HikayeAna: View {
    enum Suzgec: String, CaseIterable, Identifiable {
        case tumu = "Tümü"
        case donem = "Dönem"
        case begendiklerim = "Beğendiklerim"
        case sonraOku = "Sonra oku"
        var id: String { rawValue }
    }

    let ac: (String) -> Void
    @Binding var aramaAcik: Bool
    let basaDon: Int

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared
    @State private var suzgec: Suzgec = {
        #if DEBUG
        return HikayeProva.suzgec
        #else
        return .tumu
        #endif
    }()

    private let sutunlar = [GridItem(.flexible(), spacing: 14, alignment: .top),
                            GridItem(.flexible(), spacing: 14, alignment: .top)]

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        ScrollViewReader { kaydir in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        devamEt(c)
                        suzgecler(c).padding(.top, 6)
                        izgara(c).padding(.top, 14)
                        Color.clear.frame(height: calar.acik ? 96 : 24)
                    } header: {
                        ust.id("ust")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: basaDon) { _, _ in withAnimation(.easeOut(duration: 0.35)) { kaydir.scrollTo("ust", anchor: .top) } }
        }
        // Z4f: Galeri'deki gibi hale ve dönem deseni (en yeni yazının kapağından ve sanatçısının döneminden)
        .background(SayfaZemini(donem: depo.enYeni.first.flatMap { depo.donem($0.id) },
                                tablo: depo.enYeni.first.flatMap { depo.kucukAdres($0.kapakQid, sanatci: $0.id, genislik: 400) },
                                alan: .hikayeler))
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

    /// Yapışkan başlık: "Hikâyeler" Newsreader 28/600, sağda büyüteç ve Ben
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
        .padding(.top, 8).padding(.bottom, 10)
        // Hale görünsün: yapışkan başlık buzlu cam (önce düz zemin)
        .background { Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(edges: .top) }
    }

    // MARK: Devam et

    @ViewBuilder
    private func devamEt(_ c: HikayeRenk) -> some View {
        let l = depo.devamEt
        if !l.isEmpty {
            Text("Devam et").font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 22).padding(.bottom, 10)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(l, id: \.hikaye.id) { d in devamKarti(d, c) }
                }
                .padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden)
            .padding(.bottom, 14)
        }
    }

    /// Dinlemede kalındıysa dokununca çalar kalınan yerden açılır, okumada kalındıysa yazı kalınan paragraftan
    private func devamKarti(_ d: HikayeVitrini.Devam, _ c: HikayeRenk) -> some View {
        let s = depo.satir(d.hikaye)
        let kalan = depo.kalanDakika(d)
        return Button {
            Titresim.secim()
            if d.dinleme {
                calar.baslat(d.hikaye)
                calar.tamEkran = true
            } else {
                ac(d.hikaye.id)
            }
        } label: {
            HStack(spacing: 10) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: d.dinleme ? "headphones" : "book").font(.system(size: 10, weight: .semibold))
                        Text("\(kalan) dk kaldı")
                    }
                    .font(Yazi.sans(11.5, agirlik: 600)).foregroundStyle(c.pirinc)
                    Text(d.hikaye.baslik).font(Yazi.okuma(15, agirlik: 600)).foregroundStyle(c.yazi).lineLimit(1)
                    HikayeCizgi(oran: d.dinleme ? dinlemeOrani(d) : d.yer.oran, yukseklik: 2).padding(.top, 4)
                }
                .frame(width: 168, alignment: .leading)
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.yuzey))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(d.dinleme ? "Kaldığın yerden dinle" : "Kaldığın yerden oku")
        .accessibilityIdentifier("devam-\(d.hikaye.id)")
    }

    private func dinlemeOrani(_ d: HikayeVitrini.Devam) -> Double {
        let s = depo.sureler(d.hikaye)
        let t = s.reduce(0, +)
        guard t > 0 else { return d.yer.oran }
        return HikayeSesi.gecen(s, sira: d.yer.parca ?? 0, an: d.yer.an ?? 0) / t
    }

    // MARK: Süzgeç

    private func suzgecler(_ c: HikayeRenk) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Suzgec.allCases) { s in
                    let secili = s == suzgec
                    Button {
                        Titresim.secim()
                        withAnimation(.easeOut(duration: 0.2)) { suzgec = s }
                    } label: {
                        Text(s.rawValue)
                            .font(Yazi.sans(13.5, agirlik: secili ? 600 : 500))
                            .foregroundStyle(secili ? c.zemin : c.yazi2)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(Capsule().fill(secili ? c.yazi : .clear))
                            .overlay(Capsule().strokeBorder(secili ? .clear : c.kenar, lineWidth: 1))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(secili ? .isSelected : [])
                    .accessibilityIdentifier("suzgec-\(s)")
                }
            }
            .padding(.horizontal, 22)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Izgara

    @ViewBuilder
    private func izgara(_ c: HikayeRenk) -> some View {
        switch suzgec {
        case .tumu:
            kutular(depo.enYeni)
        case .donem:
            ForEach(depo.donemler, id: \.baslik) { g in
                HStack(alignment: .firstTextBaseline) {
                    Text(g.baslik).font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(g.hikayeler.count) yazı").font(Yazi.sans(12)).foregroundStyle(c.yazi3)
                }
                .padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 10)
                kutular(g.hikayeler).padding(.bottom, 16)
            }
        case .begendiklerim:
            let l = depo.begenilenler
            if l.isEmpty { bos("Henüz beğendiğin yazı yok.", "Yazının sonundaki kalbe dokununca burada toplanır.", c) } else { kutular(l) }
        case .sonraOku:
            let l = depo.sonraOkunacaklar
            if l.isEmpty { bos("Listen boş.", "Yazının sonundaki \"Sonra oku\"ya dokununca burada toplanır.", c) } else { kutular(l) }
        }
    }

    private func kutular(_ l: [SanatciHikayesi]) -> some View {
        LazyVGrid(columns: sutunlar, alignment: .leading, spacing: 22) {
            ForEach(l) { h in HikayeKutusu(hikaye: h, ac: ac) }
        }
        .padding(.horizontal, 22)
    }

    private func bos(_ baslik: String, _ alt: String, _ c: HikayeRenk) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baslik).font(Yazi.okuma(19, agirlik: 600)).foregroundStyle(c.yazi)
            Text(alt).font(Yazi.sans(14)).foregroundStyle(c.yazi2).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22).padding(.top, 24)
    }
}

/// Izgarada bir hikâye: 4:5 kapak (köşede durum), sanatçı, başlık, süre
struct HikayeKutusu: View {
    let hikaye: SanatciHikayesi
    let ac: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let s = depo.satir(hikaye)
        let durum = depo.durum(hikaye)
        Button { ac(hikaye.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .overlay { UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 28]) }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) { etiket(durum, c).padding(8) }
                    .overlay(alignment: .bottom) {
                        if let y = depo.yer(hikaye.id), y.yarim {
                            HikayeCizgi(oran: y.oran, yukseklik: 3).padding(.horizontal, 8).padding(.bottom, 8)
                        }
                    }
                Text(s.sanatci).font(Yazi.sans(11.5, agirlik: 600)).foregroundStyle(c.pirinc).lineLimit(1)
                    .padding(.top, 9)
                Text(hikaye.baslik)
                    .font(Yazi.okuma(16, agirlik: 600))
                    .cssSatir(.okuma, 16, 16 * 1.25)
                    .foregroundStyle(c.yazi)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                Text("\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme").font(Yazi.sans(11)).foregroundStyle(c.yazi3)
                    .lineLimit(1).minimumScaleFactor(0.85)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Yazıyı aç")
        .accessibilityIdentifier("hikaye-\(hikaye.id)")
    }

    @ViewBuilder
    private func etiket(_ d: HikayeAkisi.Durum, _ c: HikayeRenk) -> some View {
        switch d {
        case .yeni: hap("Yeni", c.pirinc)
        case .yarim(let dk): hap("\(dk) dk kaldı", c.pirinc)
        case .okundu: hap("Okundu", c.dogru)
        case .yok: EmptyView()
        }
    }

    private func hap(_ s: String, _ renk: Color) -> some View {
        Text(s).font(Yazi.sans(11, agirlik: 600)).foregroundStyle(.white)
            .padding(.horizontal, 8).frame(height: 22)
            .background(Capsule().fill(renk))
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

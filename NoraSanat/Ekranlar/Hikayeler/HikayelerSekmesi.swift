// Z4e: ana ekran Neon 4. turun Yön 2'si (öne çıkanlar, devam et, sonra oku, tüm hikâyeler → `HikayeArsiv`).
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
                    HikayeAna(ac: ac, arsiv: { yol.append(HikayeArsiv.kimlik) }, aramaAcik: $aramaAcik, basaDon: basaDon)
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
                    if id == HikayeArsiv.kimlik {
                        HikayeArsiv(ac: ac)
                    } else if let h = depo.hikaye(id) {
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
            if HikayeProva.arsiv != nil, yol.isEmpty { yol = [HikayeArsiv.kimlik] }
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

/// Z4e (Neon 4. tur, Yön 2'nin ana ekranı: tasarim/hikayeler-4/yon-2.html, goruntuler/yon-2-ana-*.png):
/// Öne çıkanlar (büyük kart + yatay şerit) · Devam et (yarım kalanlar; ilk ekranda görünür) · Sonra oku · Tüm hikâyeler
/// (arşiv). Sağ üstte arama ve Ben.
struct HikayeAna: View {
    let ac: (String) -> Void
    let arsiv: () -> Void
    @Binding var aramaAcik: Bool
    let basaDon: Int

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        ScrollViewReader { kaydir in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        oneCikanlar(c)
                        devamEt(c)
                        sonraOku(c)
                        tumu(c)
                        // Küçük çalar açıkken son satır çaların altında kalmasın
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

    private func etiket(_ s: String, _ c: HikayeRenk, sag: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(s).font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc).accessibilityAddTraits(.isHeader)
            Spacer()
            if let sag { Text(sag).font(Yazi.sans(12)).foregroundStyle(c.yazi3) }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    // MARK: Öne çıkanlar

    @ViewBuilder
    private func oneCikanlar(_ c: HikayeRenk) -> some View {
        let l = depo.oneCikanlar
        if let ilk = l.first {
            etiket("Öne çıkanlar", c).padding(.top, 4)
            buyukKart(depo.satir(ilk), c)
                .padding(.horizontal, 22)
            if l.count > 1 {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(l.dropFirst()) { h in kucukKart(depo.satir(h), c) }
                    }
                    .padding(.horizontal, 22)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 12)
            }
        }
    }

    /// Büyük kart: 16:10 eser, alt kısmı koyu geçişli; üstüne sanatçı · Yeni ve başlık; altında özet, süreler, kalp, yer imi
    private func buyukKart(_ s: HikayeSatiri, _ c: HikayeRenk) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { ac(s.id) } label: {
                Color.clear
                    .aspectRatio(16 / 10, contentMode: .fit)
                    .overlay { UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 28]) }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(s.sanatci).font(Yazi.sans(12.5, agirlik: 600))
                                if depo.durum(s.hikaye) == .yeni {
                                    Text("· Yeni").font(Yazi.sans(12.5, agirlik: 600)).foregroundStyle(Color(tema.renkler.pirinc))
                                }
                            }
                            Text(s.hikaye.baslik)
                                .font(Yazi.okuma(25, agirlik: 600))
                                .tracking(-0.36)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 1)
                        .padding(.horizontal, 16).padding(.bottom, 14).padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient(colors: [.black.opacity(0), .black.opacity(0.68)],
                                                   startPoint: .top, endPoint: .bottom))
                    }
                    .clipped()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Yazıyı aç")
            .accessibilityIdentifier("hikaye-\(s.id)")
            VStack(alignment: .leading, spacing: 8) {
                if !s.hikaye.altBaslik.isEmpty {
                    Text(s.hikaye.altBaslik)
                        .font(Yazi.sans(14))
                        .cssSatir(.sans, 14, 14 * 1.45)
                        .foregroundStyle(c.yazi2)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 0) {
                    Text("\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme").font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
                    Spacer(minLength: 4)
                    HikayeBegenDugmesi(id: s.id, boyut: 18)
                    HikayeSonraDugmesi(id: s.id, boyut: 17)
                }
                .padding(.trailing, -6)
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)
        }
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(c.yuzey))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
    }

    /// Şeritteki küçük kart: solda dikey eser, sağda sanatçı, başlık, süreler
    private func kucukKart(_ s: HikayeSatiri, _ c: HikayeRenk) -> some View {
        Button { ac(s.id) } label: {
            HStack(alignment: .top, spacing: 12) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 78, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.sanatci).font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc).lineLimit(1)
                    Text(s.hikaye.baslik)
                        .font(Yazi.okuma(16.5, agirlik: 600))
                        .foregroundStyle(c.yazi)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text("\(s.okumaDk) dk · \(s.dinlemeDk) dk dinleme").font(Yazi.sans(11.5)).foregroundStyle(c.yazi3)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .frame(width: 272, height: 116)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(c.yuzey))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Yazıyı aç")
        .accessibilityIdentifier("hikaye-\(s.id)")
    }

    // MARK: Devam et

    @ViewBuilder
    private func devamEt(_ c: HikayeRenk) -> some View {
        let l = depo.devamEt
        if !l.isEmpty {
            etiket("Devam et", c).padding(.top, 30)
            VStack(spacing: 10) {
                ForEach(l, id: \.hikaye.id) { d in devamSatiri(d, c) }
            }
            .padding(.horizontal, 22)
        }
    }

    /// Yarım kalan yazı: dinlemede kalındıysa dokununca çalar kalınan yerden açılır, değilse yazı kalınan paragraftan
    private func devamSatiri(_ d: HikayeVitrini.Devam, _ c: HikayeRenk) -> some View {
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
            HStack(spacing: 12) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: d.dinleme ? "headphones" : "book").font(.system(size: 11, weight: .semibold))
                        Text("\(d.dinleme ? "Dinleme" : "Okuma") · \(kalan) dk kaldı")
                    }
                    .font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc)
                    Text(d.hikaye.baslik).font(Yazi.okuma(17, agirlik: 600)).foregroundStyle(c.yazi).lineLimit(1)
                    Text([s.sanatci, s.yillar].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3).lineLimit(1)
                    HikayeCizgi(oran: d.dinleme ? dinlemeOrani(d) : d.yer.oran).padding(.top, 5)
                }
                HikayeIkon(simge: .ileri, boyut: 16).foregroundStyle(c.yazi3)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(c.yuzey))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    // MARK: Sonra oku

    @ViewBuilder
    private func sonraOku(_ c: HikayeRenk) -> some View {
        let l = depo.sonraOkunacaklar
        if !l.isEmpty {
            etiket("Sonra oku", c, sag: "\(l.count) yazı").padding(.top, 30)
            VStack(spacing: 0) {
                ForEach(Array(l.prefix(4).enumerated()), id: \.element.id) { i, h in
                    HikayeListeSatiri(hikaye: h, ac: ac, son: i == min(l.count, 4) - 1)
                }
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: Tüm hikâyeler

    private func tumu(_ c: HikayeRenk) -> some View {
        Button {
            Titresim.secim()
            arsiv()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tüm hikâyeler").font(Yazi.okuma(21, agirlik: 600)).foregroundStyle(c.yazi)
                    Text("\(depo.hikayeler.count) yazı · En yeni, Dönem, Beğendiklerim")
                        .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
                }
                Spacer(minLength: 0)
                HikayeIkon(simge: .ileri, boyut: 18).foregroundStyle(c.yazi2)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) { Rectangle().fill(c.kenar).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
        .padding(.horizontal, 22)
        .padding(.top, 30)
        .accessibilityIdentifier("hikaye-arsiv-ac")
    }
}

/// Arşivde ve "Sonra oku"da bir satır: küçük kare kapak, başlık, sanatçı · yıllar, süreler ve durum; sağda kalp ve yer imi
struct HikayeListeSatiri: View {
    let hikaye: SanatciHikayesi
    let ac: (String) -> Void
    var son = false

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let s = depo.satir(hikaye)
        HStack(alignment: .top, spacing: 12) {
            Button { ac(hikaye.id) } label: {
                HStack(alignment: .top, spacing: 13) {
                    UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(hikaye.baslik)
                            .font(Yazi.okuma(17.5, agirlik: 600))
                            .foregroundStyle(c.yazi)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text([s.sanatci, s.yillar].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(Yazi.sans(13)).foregroundStyle(c.yazi2).lineLimit(1)
                        HStack(spacing: 0) {
                            Text("\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme").foregroundStyle(c.yazi3)
                            durumYazisi(depo.durum(hikaye), c)
                        }
                        .font(Yazi.sans(12))
                        .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Yazıyı aç")
            .accessibilityIdentifier("hikaye-\(hikaye.id)")
            VStack(spacing: -6) {
                HikayeBegenDugmesi(id: hikaye.id, boyut: 17)
                HikayeSonraDugmesi(id: hikaye.id, boyut: 16)
            }
            .padding(.top, -8)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { if !son { Rectangle().fill(c.kenar).frame(height: 1) } }
    }

    @ViewBuilder
    private func durumYazisi(_ d: HikayeAkisi.Durum, _ c: HikayeRenk) -> some View {
        switch d {
        case .yeni: Text(" · Yeni").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc)
        case .yarim(let dk): Text(" · \(dk) dk kaldı").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc)
        case .okundu: Text(" · Okundu").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.dogru)
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

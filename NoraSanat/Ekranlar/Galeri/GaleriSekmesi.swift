// Kaynak: sanat-atlasi js/ekranlar/{gozat,akim,arama,koleksiyon}.js @ a866b86
import NoraCekirdek
import SwiftUI
import SafariServices

enum GaleriYolu: Hashable {
    case akim(String), sanatci(String), eserler(String), konular(String), konu(String), ara, koleksiyon, okuma(String)
    case akimKarsilastir(String, String), sanatciKarsilastir(String, String)
    init?(adres: String) {
        let p = adres.drop(while: { $0 == "#" || $0 == "/" }).split(separator: "/").map { String($0).removingPercentEncoding ?? String($0) }
        let id = p.dropFirst().first ?? ""
        switch p.first {
        case "akim-karsilastir" where p.count == 3: self = .akimKarsilastir(id, p[2])
        case "karsilastir" where p.count == 3: self = .sanatciKarsilastir(id, p[2])
        case "akim": self = .akim(id)
        case "sanatci": self = p.last == "eserler" ? .eserler(id) : .sanatci(id)
        case "ara": self = .ara
        case "koleksiyon": self = .koleksiyon
        case "konu": self = .konu(id)
        case "konular": self = .konular(id)
        case "basyapit": self = .okuma(id)
        default: return nil
        }
    }
}

private struct AcilanEserler: Identifiable {
    let id = UUID()
    let eserler: [Eser]
    let sira: Int
    var kirpim: TanimaKirpimi?
    var aciklama = ""
}

struct GaleriSekmesi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var durum
    @State private var galeri: GaleriKatalogu?
    @State private var ilerleme: Ilerleme?
    @State private var dizin: [GaleriKaydi] = []
    @State private var yol: [GaleriYolu] = []
    @State private var acilan: AcilanEserler?
    @State private var sayfa = 0
    @State private var siteBolumu: SiteBolumu?
    @State private var sorgu = ""
    @State private var hata: String?
    @State private var deneme = 0
    @State private var dizinAcik = false
    @State private var yenilemeHatasi = false
    private static let depo = SiteVerisi()

    var body: some View {
        NavigationStack(path: $yol) {
            Group {
                if let g = galeri, let il = ilerleme {
                    anaSayfa(g, il)
                } else if let hata {
                    VStack(spacing: 16) {
                        Text(hata).font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                        Button("Yeniden dene") { deneme += 1 }.buttonStyle(HapDugme())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(tema.renkler.zemin).ignoresSafeArea())
                } else {
                    ProgressView("Galeri hazırlanıyor…")
                        .font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(tema.renkler.zemin).ignoresSafeArea())
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GaleriYolu.self) { hedef in
                Group {
                    if let g = galeri, let il = ilerleme { hedefSayfa(hedef, g, il) }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task(id: deneme) {
            do {
                hata = nil
                async let kayit = IlerlemeKoprusu.shared.oku()
                async let ek = Self.depo.veriler(GaleriKatalogu.dosyalar)
                let k = try await Self.depo.katalog()
                let dosyalar = await ek
                guard dosyalar.count == GaleriKatalogu.dosyalar.count else { throw SiteVerisi.Hata.yok("Galeri") }
                let il = try await kayit
                let (g, d) = try await Task.detached {
                    let g = try GaleriKatalogu(katalog: k, dosyalar: dosyalar)
                    return (g, g.dizin(il))
                }.value
                guard !Task.isCancelled else { return }
                galeri = g
                dizin = d
                ilerleme = il
                adresiAc()
                #if DEBUG
                let ilk = GaleriKarsilastirma.yerliHazirla()
                if let y = ilk.yol { yol = y }
                if ilk.dizinAcik { dizinAcik = true }
                #endif
            } catch { if !Task.isCancelled { hata = "Galeri yüklenemedi." } }
        }
        .task(id: durum.secili) {
            guard durum.secili == .galeri, let g = galeri else { return }
            do {
                let il = try await IlerlemeKoprusu.shared.oku()
                let yeni = await Task.detached { g.dizin(il) }.value
                guard !Task.isCancelled else { return }
                ilerleme = il
                dizin = yeni
            } catch { if !Task.isCancelled { yenilemeHatasi = true } }
        }
        .onChange(of: durum.yenidenDokunma[.galeri]) { _, _ in
            yol = []
            dizinAcik = false
        }
        .onChange(of: durum.yerliAdres[.galeri]) { _, _ in adresiAc() }
        .fullScreenCover(item: $acilan, onDismiss: {
            Task {
                do { ilerleme = try await IlerlemeKoprusu.shared.oku() }
                catch { yenilemeHatasi = true }
            }
        }) { secim in
            GaleriGoruntuleyicisi(secim: secim, depo: Self.depo) { id in
                acilan = nil
                yol.append(.konu(id))
            }
        }
        .sheet(item: $siteBolumu) { bolum in
            GaleriSiteSayfasi(adres: bolum.adres).ignoresSafeArea()
        }
        .alert("Koleksiyon güncellenemedi.", isPresented: $yenilemeHatasi) {
            Button("Yeniden dene") { deneme += 1 }
            Button("Kapat", role: .cancel) {}
        }
    }

    private func adresiAc() {
        guard galeri != nil, let a = durum.yerliAdres[.galeri] else { return }
        yol = GaleriYolu(adres: a).map { [$0] } ?? []
        durum.adresIslendi(.galeri)
    }

    private var eylem: GaleriEylemleri {
        GaleriEylemleri(
            git: { yol.append($0) },
            geri: { if !yol.isEmpty { yol.removeLast() } },
            ac: { l, i in if !l.isEmpty { acilan = AcilanEserler(eserler: l, sira: min(i, l.count - 1)) } },
            pekistir: { ad in
                durum.sec(.calis)
                Gezgin.shared.git("#/pekistir/donem/" + SiteYazisi.uriBileseni(ad))
            })
    }

    /// `gozAtUst`: bölüm sekmeleri; Başyapıtlar ve Zaman G3 / G5'e kadar sitenin sayfasını açar
    private func ust(_ etkin: GaleriUst.Bolum, _ g: GaleriKatalogu, _ il: Ilerleme) -> GaleriUst {
        GaleriUst(etkin: etkin, koleksiyonDolu: !g.koleksiyon(il).isEmpty,
                  ara: { yol.append(.ara) }, koleksiyon: { yol.append(.koleksiyon) }) { b in
            switch b {
            case .akimlar: if etkin != .akimlar { yol = [] }
            case .basyapitlar: siteBolumu = .basyapitlar
            case .konular: if etkin != .konular { yol = [.konular("")] }
            case .zaman: siteBolumu = .zaman
            }
        }
    }

    /// Galeri'nin ana ekranı (`gozAt`): Galeri üstü, akımlar çarkı, bütün akımlar. Zemin seçili akımın döneminin deseni.
    private func anaSayfa(_ g: GaleriKatalogu, _ il: Ilerleme) -> some View {
        let salonlar = Kilit.akimDurumlari(g.katalog.akimlar, g.katalog.sanatcilar, islenen: il.islenenKume)
        let resim = GaleriResim(galeri: g, il: il)
        let donem = salonlar.indices.contains(sayfa) ? GaleriDonem.akimin(g.katalog, salonlar[sayfa].ad) : nil
        return ScrollViewReader { kaydir in
          ScrollView {
            VStack(spacing: 0) {
                ust(.akimlar, g, il).padding(.horizontal, BenOlcu.yan).padding(.top, 12)
                AkimCarki(salonlar: salonlar, galeri: g, il: il, sira: $sayfa, dizinAcik: $dizinAcik,
                          kapak: { ad in
                              guard let e = g.carkKapagi(ad, il) else { return (nil, nil) }
                              return (resim.url(e, 800), resim.yedek(e))
                          },
                          gir: { yol.append(.akim($0)) })
            }
            .padding(.bottom, 24)
          }
          .scrollIndicators(.hidden)
          #if DEBUG
          // dizin açılınca alta: "Bütün akımlar" düğmesi ve ilk satırlar ekranda (sitede `.akim-dizin` başa gelir)
          .task { await GaleriKarsilastirma.kaydir(kaydir, "dizin") }
          #endif
        }
        .background(SayfaZemini(donem: donem))
    }

    @ViewBuilder private func hedefSayfa(_ hedef: GaleriYolu, _ g: GaleriKatalogu, _ il: Ilerleme) -> some View {
        let e = eylem
        switch hedef {
        case .akim(let ad):
            AkimSalonu(ad: ad, galeri: g, il: il, eylem: e)
        case .sanatci(let id):
            if let s = g.katalog.harita[id] {
                SanatciSayfasi(s: s, galeri: g, il: il, eylem: e) { k, l in AnyView(kirpim(k, l, g, il)) }
            }
        case .eserler(let id):
            if let s = g.katalog.harita[id] { TumEserler(s: s, galeri: g, il: il, eylem: e) }
        case .koleksiyon:
            KoleksiyonSayfasi(galeri: g, il: il, eylem: e)
        case .konular(let tur):
            let salonlar = Kilit.akimDurumlari(g.katalog.akimlar, g.katalog.sanatcilar, islenen: il.islenenKume)
            KonularSayfasi(galeri: g, il: il, grup: tur,
                           donem: salonlar.indices.contains(sayfa) ? GaleriDonem.akimin(g.katalog, salonlar[sayfa].ad) : nil,
                           eylem: e, ust: ust(.konular, g, il))
        case .konu(let id):
            if let k = g.konular.first(where: { $0.id == id }) {
                KonuSayfasi(konu: k, galeri: g, il: il, eylem: e) { x, l, metin in AnyView(kirpim(x, l, g, il, aciklama: metin)) }
            }
        case .akimKarsilastir(let a, let b):
            AkimKarsilastir(a: a, b: b, galeri: g, il: il, eylem: e)
        case .sanatciKarsilastir(let a, let b):
            SanatciKarsilastir(a: a, b: b, galeri: g, il: il, eylem: e)
        case .ara:
            AramaSayfasi(galeri: g, il: il, dizin: dizin, sorgu: $sorgu, eylem: e)
        case .okuma(let id):
            // G3 yakın okumayı yerli yazana kadar: başlık, özet ve bölümler
            if let b = g.basyapitlar.first(where: { $0["anahtar"]?.metin == id }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        GaleriSayfaUst(etiket: "Yakın okuma", baslik: b["baslik"]?.metin ?? "", geri: e.geri)
                        if let x = g.eslestir(id, b["sanatci"]?.metin ?? "") {
                            let r = GaleriResim(galeri: g, il: il)
                            EserKarti(eser: x, url: r.url(x, 800), yedek: r.yedek(x), oran: r.oran(x),
                                      yukseklik: 345 / CGFloat(r.oran(x) ?? 0.75), genislik: 345) { e.ac([x], 0) }
                        }
                        OkumaMetni(metin: b["ozet"]?.metin ?? "", italik: true).padding(.top, 16)
                        ForEach(Array((b["bolumler"]?.dizi ?? []).enumerated()), id: \.offset) { _, bolum in
                            GaleriBolum(etiket: bolum["baslik"]?.metin ?? "") { OkumaMetni(metin: bolum["metin"]?.metin ?? "") }
                        }
                    }
                    .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .background(SayfaZemini(donem: nil, ustHale: true))
            }
        }
    }

    /// İş 193: tanıma maddesinin yanında eserden kırpım; dokununca görüntüleyici incelemede açılır
    @ViewBuilder private func kirpim(_ k: TanimaKirpimi, _ liste: [Eser], _ g: GaleriKatalogu, _ il: Ilerleme,
                                     aciklama: String = "") -> some View {
        if let e = k.eser(liste, katalog: g.katalog, il: il),
           let secili = GorselAdresleri.secilen(e, kotuler: il.kotuGorseller) ?? e.gorseller.first {
            let oran = g.katalog.gorsel.oran(secili) ?? 1
            let r = GaleriResim(galeri: g, il: il)
            Button { acilan = AcilanEserler(eserler: [e], sira: 0, kirpim: k, aciklama: aciklama) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        let w = geo.size.width / k.w
                        let h = w / oran
                        r.gorsel(e, 800, kip: .fit).frame(width: w, height: h)
                            .offset(x: -w * k.x, y: -h * k.y)
                    }
                    .aspectRatio(oran * k.w / k.h, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if aciklama.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(k.ad).font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                                .foregroundStyle(Color(tema.renkler.murekkep))
                            Text(e.gorunenAd).font(Yazi.okuma(13, italik: true, stil: .footnote))
                                .foregroundStyle(Color(tema.renkler.murekkep2))
                        }
                        .multilineTextAlignment(.leading)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(k.ad)
        }
    }
}

private struct GaleriGoruntuleyicisi: View {
    let secim: AcilanEserler
    let depo: SiteVerisi
    let konuSecildi: (String) -> Void
    @Environment(\.dismiss) private var kapat
    @State private var baglam: GoruntuleyiciBaglami?

    var body: some View {
        Group {
            if secim.kirpim == nil {
                Goruntuleyici(eserler: secim.eserler, baslangic: secim.sira, konuSecildi: konuSecildi)
            } else if let baglam {
                Goruntuleyici(eserler: secim.eserler, baslangic: secim.sira,
                              incelemeyeBasla: secim.kirpim != nil, baglam: baglam, konuSecildi: konuSecildi)
            } else {
                VStack { ProgressView("Eser açılıyor…"); Button("Kapat") { kapat() } }
            }
        }.task {
            guard secim.kirpim != nil else { return }
            var yeni = await GoruntuleyiciBaglami.yukle(siteVerisi: depo)
            if let kirpim = secim.kirpim, let eser = secim.eserler.first {
                let kayit = kirpim.inceleme(yeni.ayrinti(eser), aciklama: secim.aciklama)
                yeni.ayrintilar.insert(kayit, at: 0)
            }
            if !Task.isCancelled { baglam = yeni }
        }
    }
}

/// G3 ve G5 kendi ekranlarını bağlayana kadar bu iki okuma bölümü yayındaki siteden açılır.
private enum SiteBolumu: String, Identifiable {
    case basyapitlar, zaman
    var id: String { rawValue }
    var adres: URL {
        var bilesenler = URLComponents(url: SiteVerisi.site, resolvingAgainstBaseURL: false)
        bilesenler?.fragment = "/" + rawValue
        return bilesenler?.url ?? SiteVerisi.site
    }
}

private struct GaleriSiteSayfasi: UIViewControllerRepresentable {
    let adres: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: adres) }
    func updateUIViewController(_ denetleyici: SFSafariViewController, context: Context) {}
}

#if DEBUG
/// CI karşılaştırması (G2b): yerli Galeri ekranı ile sitenin aynı sayfası (`-yalnizSite`) aynı bölümde yan yana.
/// `-galeriKaydir dizin|eserler|pekistir`: yerli ekran ve site o bölüme kayar. Yerli ekran hazır olunca `tmp/galeri-hazir`.
enum GaleriKarsilastirma {
    /// Bölüm → sitedeki karşılığı (önce tıklanacak öğe, sonra başa getirilecek öğe)
    static let siteSecicileri: [String: (tikla: String?, kaydir: String)] = [
        "dizin": ("[data-dizin-ac][aria-expanded=\"false\"]", ".akim-dizin"),
        "eserler": (nil, ".akim-bolum:has(.akim-eserler)"),
        "pekistir": (nil, ".donem-cta"),
    ]

    static var bolum: String? { NoraSanatApp.arguman("-galeriKaydir") }

    static let hazir = FileManager.default.temporaryDirectory.appendingPathComponent("galeri-hazir")

    /// Veriler yüklenince: istenen sayfa, istenen bölüm için dizin; bölüm istenmediyse görseller için bekleyip hazır
    @MainActor
    static func yerliHazirla() -> (yol: [GaleriYolu]?, dizinAcik: Bool) {
        let yol = NoraSanatApp.arguman("-galeriSayfa").map { GaleriYolu(adres: $0).map { [$0] } ?? [] }
        if bolum == nil {
            Task {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                try? Data().write(to: hazir)
            }
        }
        return (yol, bolum == "dizin")
    }

    /// Yerli sayfa: bölüm bu sayfadaysa başına kayar, sonra hazır yazar
    @MainActor
    static func kaydir(_ kaydir: ScrollViewProxy, _ id: String) async {
        guard bolum == id else { return }
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        kaydir.scrollTo(id, anchor: .top)
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        try? Data().write(to: hazir)
    }

    /// Site (`-yalnizSite`): yüklenince bölüm görünene kadar dener
    @MainActor
    static func siteyiKaydir() {
        guard let b = bolum, let s = siteSecicileri[b] else { return }
        func metin(_ x: String) -> String {
            (try? JSONSerialization.data(withJSONObject: [x])).flatMap { String(data: $0, encoding: .utf8) }
                .map { String($0.dropFirst().dropLast()) } ?? "''"
        }
        let tikla = s.tikla.map { "const t = document.querySelector(\(metin($0))); if (t) t.click(); " } ?? ""
        let js = "(() => { \(tikla)const e = document.querySelector(\(metin(s.kaydir))); "
            + "if (!e) return false; e.scrollIntoView({ block: 'start' }); return true; })()"
        Task {
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard Gezgin.shared.yuklendi, let w = Gezgin.shared.webView else { continue }
                if (try? await w.evaluateJavaScript(js)) as? Bool == true {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    _ = try? await w.evaluateJavaScript(js)
                    return
                }
            }
        }
    }
}
#endif

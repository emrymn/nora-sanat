// Kaynak: sanat-atlasi js/ekranlar/{ayarlar,hizliAyar}.js, js/depo.js, js/gunduzRenk.js @ a866b86 (davranış: C4, C4b, Z2c-3)
// Z3x: görünüş Neon'un "Yön 2 · Kompakt fihrist ve yapışkan bölüm şeridi" tasarımı (dal neon/ayarlar-tasarim, PR #63:
// tasarim/ayarlar/yon-2.html, BENIOKU.md; Emre seçti). Yedi grup (Görünüş · Çalışma · Hatırlatma · Çevrimdışı · Yedek ·
// Hakkında · Gelişmiş), üstte yapışkan bölüm şeridi: dokununca gruba kayar, kaydırdıkça seçili grup değişir.
// Ekranda tek dolu düğme: "İlerlemeni yedekle". Hatırlatma, Çevrimdışı, Hakkında ve Gelişmiş: BenAraclari / BenCevrimdisi.
import NoraCekirdek
import SwiftUI
import UniformTypeIdentifiers

private struct YedekBelgesi: FileDocument {
    static let readableContentTypes = [UTType.json, .plainText]
    let metin: String
    init(_ metin: String) { self.metin = metin }
    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents, let m = String(data: d, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        metin = m
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(metin.utf8))
    }
}

/// Ayarlar'ın bilgi satırları (Z2c-3: `BenDeposu.ayarBilgisi()`, Swift'te)
struct AyarBilgisi {
    var gunun = "—"
    var surum = ""
    var odak = 0
    var yuruyus = 0
    var egimVar = true
    /// Gündüz rengi örnekleri: seçim → (band, altın, yüzey, kenar); "notr" için yok
    var paletler: [String: [String]] = [:]
}

/// Ayarlar'ın grupları; `rawValue` kaydırma çapası (CI: `-benKaydir yedek|cevrimdisi`)
enum AyarGrubu: String, CaseIterable, Identifiable {
    case gorunus, calisma, hatirlatma, cevrimdisi, yedek, hakkinda, gelismis

    var id: String { rawValue }

    /// Şeritteki ad
    var serit: String {
        switch self {
        case .gorunus: return "Görünüş"
        case .calisma: return "Çalışma"
        case .hatirlatma: return "Hatırlatma"
        case .cevrimdisi: return "Çevrimdışı"
        case .yedek: return "Yedek"
        case .hakkinda: return "Hakkında"
        case .gelismis: return "Gelişmiş"
        }
    }

    /// Grubun başlığı (`.bolum-baslik`)
    var baslik: String { self == .cevrimdisi ? "Görseller ve çevrimdışı" : serit }
}

/// Grup başlıklarının kaydırma alanındaki yeri (kaydırınca seçili grup)
private struct GrupYerleri: PreferenceKey {
    static let defaultValue: [AyarGrubu: CGFloat] = [:]
    static func reduce(value: inout [AyarGrubu: CGFloat], nextValue: () -> [AyarGrubu: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Şeridin sayfadaki yeri (yapışmadan önce) ve sayfanın sonu
private struct SeritYeri: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
private struct SayfaSonu: PreferenceKey {
    static let defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct BenAyarlari: View {
    let depo: BenDeposu
    let geri: () -> Void
    @Environment(TemaDeposu.self) private var tema
    @State private var yedek = ""
    @State private var girdi = ""
    @State private var disa = false
    @State private var ice = false
    @State private var onay: Yukleme?
    @State private var bilgi = AyarBilgisi()
    @State private var renkAcik = false
    @State private var hareketAcik = false
    @State private var geriYukleAcik = false
    // Şerit
    @State private var secili: AyarGrubu = .gorunus
    @State private var kilit: AyarGrubu?
    @State private var kilitNo = 0
    @State private var seritY: CGFloat = 0
    @State private var yerler: [AyarGrubu: CGFloat] = [:]
    @State private var son: CGFloat = .infinity
    @State private var yukseklik: CGFloat = 0

    struct Yukleme: Identifiable {
        let id = UUID()
        let metin: String
        let no, konu, skor: Int
    }

    private static let seritYuksekligi: CGFloat = 44
    private static let alan = "ayarlar"

    var body: some View {
        GeometryReader { pencere in
            ScrollViewReader { kaydir in
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ust
                            // Şeridin sayfadaki yeri; şerit ayrıca üstte çizilir ve buraya ya da tepeye oturur
                            Color.clear.frame(height: Self.seritYuksekligi)
                                .background(GeometryReader { g in
                                    Color.clear.preference(key: SeritYeri.self, value: g.frame(in: .named(Self.alan)).minY)
                                })
                                .padding(.bottom, 18)
                            ForEach(AyarGrubu.allCases) { g in grup(g) }
                            Color.clear.frame(height: 1)
                                .background(GeometryReader { g in
                                    Color.clear.preference(key: SayfaSonu.self, value: g.frame(in: .named(Self.alan)).maxY)
                                })
                        }
                        .padding(.bottom, 44)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    serit(kaydir)
                        .offset(y: max(0, seritY))
                    // Şerit yapışınca durum çubuğunun arkası da şeridin zemini olsun (içerik altından geçmesin)
                    Color.clear.frame(height: 0)
                        .background { seritZemini.ignoresSafeArea(edges: .top) }
                        .opacity(seritY <= 0.5 ? 1 : 0)
                        .allowsHitTesting(false)
                }
                .coordinateSpace(name: Self.alan)
                .onPreferenceChange(SeritYeri.self) { seritY = $0 }
                .onPreferenceChange(SayfaSonu.self) { son = $0; casus() }
                .onPreferenceChange(GrupYerleri.self) { yerler = $0; casus() }
                .onAppear { yukseklik = pencere.size.height }
                .onChange(of: pencere.size.height) { _, h in yukseklik = h }
                #if DEBUG
                .task(id: depo.il != nil) {
                    if depo.il != nil { await BenKarsilastirma.kaydir(kaydir) }
                }
                #endif
            }
        }
        .disabled(depo.mesgul)
        .task(id: depo.il?.kayitNo) { bilgi = await depo.ayarBilgisi() }
        .fileExporter(isPresented: $disa, document: YedekBelgesi(yedek), contentType: .json,
                      defaultFilename: "sanat-atlasi-yedek") { if case let .failure(e) = $0 { depo.hata(e) } }
        .fileImporter(isPresented: $ice, allowedContentTypes: [.json, .plainText]) { sonuc in
            do {
                let url = try sonuc.get()
                let izin = url.startAccessingSecurityScopedResource()
                defer { if izin { url.stopAccessingSecurityScopedResource() } }
                girdi = try String(contentsOf: url, encoding: .utf8)
            } catch { depo.hata(error) }
        }
        .alert(item: $onay) { y in
            Alert(title: Text("Mevcut ilerleme değiştirilsin mi?"), message: Text("Yedekte \(y.konu) konu ve \(y.skor) sanatçı skoru var."),
                  primaryButton: .destructive(Text("Geri yükle")) {
                depo.yap {
                    try await depo.kopru.geriYukle(y.metin, beklenen: y.no)
                    girdi = ""
                    depo.mesaj = "Yedek geri yüklendi."
                }
            }, secondaryButton: .cancel(Text("Vazgeç")))
        }
    }

    // MARK: Üst ve şerit

    /// `.ust-satir`: cam geri düğmesi, 32 px Bodoni "Ayarlar", sağda sürüm
    private var ust: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: geri) { BenIkon(simge: .geri, boyut: 22, kalinlik: 1.4) }
                .buttonStyle(YuvarlakDugme())
                .accessibilityLabel("Geri")
            Text("Ayarlar")
                .font(Yazi.serif(32, agirlik: 500, stil: .largeTitle))
                .tracking(-0.32)
                .cssSatir(.serif, 32, 33.6)
                .foregroundStyle(Color(tema.renkler.murekkep))
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if !bilgi.surum.isEmpty {
                Text(bilgi.surum)
                    .font(Yazi.sans(12.5, agirlik: 500, stil: .footnote))
                    .foregroundStyle(Color(tema.renkler.murekkep3))
                    .padding(.trailing, 4)
                    .accessibilityLabel("Sürüm \(bilgi.surum)")
            }
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 6)
    }

    /// `.bolum-serit`: yapışkan, alt çizgili bölüm şeridi (seçili olanın altında 2 pt pirinç çizgi)
    private func serit(_ sayfa: ScrollViewProxy) -> some View {
        let r = tema.renkler
        return ScrollViewReader { serit in
            ScrollView(.horizontal) {
                HStack(spacing: 2) {
                    ForEach(AyarGrubu.allCases) { g in
                        let acik = g == secili
                        Button { atla(g, sayfa) } label: {
                            Text(g.serit)
                                .font(Yazi.sans(13.5, agirlik: acik ? 600 : 500, stil: .subheadline))
                                .foregroundStyle(Color(acik ? r.murekkep : r.murekkep2))
                                .lineLimit(1).fixedSize()
                                .padding(.horizontal, 10)
                                .frame(minHeight: Self.seritYuksekligi)
                                .overlay(alignment: .bottom) {
                                    if acik {
                                        Capsule().fill(Color(r.pirinc)).frame(height: 2).padding(.horizontal, 10)
                                    }
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(g)
                        .accessibilityAddTraits(acik ? [.isSelected] : [])
                    }
                }
                .padding(.leading, 16).padding(.trailing, 28)
            }
            .scrollIndicators(.hidden)
            .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.88),
                                         .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
            .onChange(of: secili) { _, g in
                withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.25)) { serit.scrollTo(g, anchor: .center) }
            }
        }
        .frame(height: Self.seritYuksekligi)
        .background {
            seritZemini.overlay(alignment: .bottom) { Rectangle().fill(Color(r.kenarInce)).frame(height: 1) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bölümler")
    }

    /// `--tab-bg` + bulanıklık (`backdrop-filter: blur(24px)`)
    private var seritZemini: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(Color(tema.renkler.sekmeZemin))
        }
    }

    /// Şeride dokununca: grubun başlığı şeridin altına gelir
    private func atla(_ g: AyarGrubu, _ sayfa: ScrollViewProxy) {
        secili = g
        kilitle(g)
        withAnimation(tema.ayar.hareketAzaltilmis ? nil : .spring(duration: 0.45, bounce: 0)) { sayfa.scrollTo(g.rawValue, anchor: .top) }
    }

    /// Kayma bitene kadar kaydırma gözcüsü seçimi değiştirmesin
    private func kilitle(_ g: AyarGrubu) {
        kilit = g
        kilitNo += 1
        let no = kilitNo
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            if kilitNo == no { kilit = nil; casus() }
        }
    }

    /// Kaydırma gözcüsü: başlığı şeridin altına varmış son grup seçilidir. Sayfanın sonunda tepeye varamayan kısa
    /// gruplar için: dokunulan grup ekrandaysa seçili kalır, değilse ekranda başlığı görünen son grup.
    private func casus() {
        guard kilit == nil, !yerler.isEmpty else { return }
        let sinir = Self.seritYuksekligi + 24
        var g = AyarGrubu.gorunus
        for x in AyarGrubu.allCases { if let y = yerler[x], y <= sinir { g = x } }
        if yukseklik > 0, son <= yukseklik + 4 {
            let gorunur = { (x: AyarGrubu) -> Bool in (yerler[x] ?? .infinity) < yukseklik - 40 }
            if secili.sira > g.sira, gorunur(secili) {
                g = secili
            } else if let x = AyarGrubu.allCases.last(where: gorunur), x.sira > g.sira {
                g = x
            }
        }
        if g != secili { secili = g }
    }

    // MARK: Gruplar

    @ViewBuilder
    private func grup(_ g: AyarGrubu) -> some View {
        let ust: CGFloat = g == .gorunus ? 0 : 28
        VStack(alignment: .leading, spacing: 0) {
            AyarGrupBasligi(metin: g.baslik)
                .background(GeometryReader { x in
                    Color.clear.preference(key: GrupYerleri.self, value: [g: x.frame(in: .named(Self.alan)).minY])
                })
            icerik(g)
        }
        .padding(.horizontal, 20)
        .padding(.top, ust)
        // Kaydırma çapası: başlığın 16 pt üstü şeridin altına gelsin (`scroll-margin-top: 56px`)
        .overlay(alignment: .top) {
            Color.clear.frame(height: 1).id(g.rawValue).padding(.top, ust - Self.seritYuksekligi - 16)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func icerik(_ g: AyarGrubu) -> some View {
        switch g {
        case .gorunus: gorunus
        case .calisma: calisma
        case .hatirlatma: HatirlatmaBolumu(depo: depo)
        case .cevrimdisi: BenCevrimdisi(depo: depo)
        case .yedek: yedekBolumu
        case .hakkinda: HakkindaBolumu(depo: depo, surum: bilgi.surum)
        case .gelismis: GelismisBolumu(depo: depo, bilgi: $bilgi)
        }
    }

    // MARK: Görünüş

    private var gorunus: some View {
        let il = depo.il
        let temaSecimi = il?.ayar("tema")?.metin ?? "gece"
        let renk = il?.ayar("gunduzRenk")?.metin ?? GunduzPaleti.varsayilan
        let yazi = il?.ayar("yazi")?.metin ?? "standart"
        let hareket = il?.ayar("hareket")?.metin ?? "tam"
        return AyarKarti {
            AyarOnizlemesi(depo: depo, durum: AyarYazilari.onizlemeDurumu(tema: temaSecimi, gunduzRenk: renk, yazi: yazi),
                           buyuk: yazi == "buyuk", oynar: (il?.ayar("egim")?.mantik ?? true) && hareket == "tam")
            AyarSatiri(simge: .tema, ad: "Tema", alt: "Kömür gece ya da sıcak kâğıt") {
                MiniParcali(ad: "Tema", secenekler: AyarYazilari.temalar, secili: temaSecimi) { sec("tema", $0) }
            }
            AyarCizgisi()
            AcilirSatir(simge: .renk, ad: "Gündüz rengi", alt: "Gündüz temasının boya paleti", acik: $renkAcik) {
                HStack(spacing: 8) {
                    renkOrnegi(renk, cap: 18)
                    SagDeger(metin: AyarYazilari.ad(AyarYazilari.gunduzRenkleri, renk), renk: \.murekkep)
                }
            } icerik: {
                VStack(alignment: .leading, spacing: 8) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(0..<AyarYazilari.gunduzRenkleri.count, id: \.self) { i in
                            let x = AyarYazilari.gunduzRenkleri[i]
                            renkDugmesi(x, secili: renk == x.deger && temaSecimi == "gunduz")
                        }
                    }
                    Text("Günün resmi: renkler her gün o günün tablosundan seçilir. Bir renk seçince tema Gündüz’e geçer.")
                        .font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(tema.renkler.murekkep3))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            AyarCizgisi()
            AyarSatiri(simge: .yazi, ad: "Yazı boyutu", alt: "Okuma ve açıklama boyu") {
                MiniParcali(ad: "Yazı boyutu", secenekler: AyarYazilari.yazilar, secili: yazi) { sec("yazi", $0) }
            }
            AyarCizgisi()
            AcilirSatir(simge: .hareket, ad: "Hareket", alt: "Geçişler ve süs hareketleri", acik: $hareketAcik) {
                SagDeger(metin: AyarYazilari.hareketAdi(hareket))
            } icerik: {
                VStack(spacing: 6) {
                    ForEach(0..<AyarYazilari.hareketler.count, id: \.self) { i in
                        let x = AyarYazilari.hareketler[i]
                        SecenekSatiri(ad: x.ad, aciklama: x.aciklama, secili: hareket == x.deger) { sec("hareket", x.deger) }
                    }
                }
            }
            AyarCizgisi()
            AnahtarSatiri(simge: .egim, ad: "Eğince tablo oynasın",
                          alt: bilgi.egimVar ? "Tuval’de ışık ve duvar sallantısı" : "Bu cihazda hareket algılayıcısı yok.",
                          acik: Binding(get: { il?.ayar("egim")?.mantik ?? true }, set: egimAyarla))
                .disabled(!bilgi.egimVar)
            // Z2c-3: uygulama hareketi CoreMotion'dan alır; sitedeki gibi hareket izni gerekmez
        }
    }

    /// `.renk-sec`: pul + ad; seçili pirinç kenar
    private func renkDugmesi(_ x: (deger: String, ad: String), secili: Bool) -> some View {
        let r = tema.renkler
        return Button { sec("gunduzRenk", x.deger) } label: {
            HStack(spacing: 8) {
                renkOrnegi(x.deger, cap: 18)
                Text(x.ad).font(Yazi.sans(13, agirlik: secili ? 600 : 500, stil: .footnote))
                    .foregroundStyle(Color(secili ? r.murekkep : r.murekkep2))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(secili ? r.yuzey2.karis(r.pirinc, 0.14) : r.yuzey2)))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color(secili ? r.pirinc : r.kenar), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(secili ? [.isSelected] : [])
    }

    /// Gündüz renginin pulu: köşegenle ikiye bölünmüş band ve altın (sitenin `renkOrnegi`'nin küçüğü). Renkler
    /// `TemaHesabi.gunduzOrnekPaleti`'nden; Nötr kâğıt sitenin sabit `.renk-ornek.notr` renkleri.
    private func renkOrnegi(_ secim: String, cap: CGFloat) -> some View {
        let p = (bilgi.paletler[secim] ?? []).compactMap { RGBA(css: $0) }
        let (ust, alt) = p.count == 4 ? (p[0], p[1]) : (RGBA(css: "#4c463f")!, RGBA(css: "#ece8e1")!)
        return ZStack {
            Circle().fill(Color(alt))
            Circle().fill(Color(ust)).mask(
                GeometryReader { g in
                    Path { y in
                        y.move(to: .zero); y.addLine(to: CGPoint(x: g.size.width, y: 0))
                        y.addLine(to: CGPoint(x: 0, y: g.size.height)); y.closeSubpath()
                    }
                })
            Circle().strokeBorder(Color.black.opacity(0.16), lineWidth: 1)
        }
        .frame(width: cap, height: cap)
        .accessibilityHidden(true)
    }

    // MARK: Çalışma

    private var calisma: some View {
        let il = depo.il
        let n = il?.ayar("gunlukKart")?.tamSayi ?? 20
        let titresim = il?.ayar("titresim")?.mantik ?? true
        return AyarKarti {
            AyarSatiri(simge: .kart, ad: "Günlük kart sayısı", alt: "Günde en çok 8 yeni sanatçı") {
                HStack(spacing: 2) {
                    AdimDugmesi(isaret: "−", ad: "Azalt", etkin: n > 5) { kart(-5) }
                    Text("\(n)").font(Yazi.serif(22, agirlik: 500)).monospacedDigit()
                        .frame(minWidth: 36)
                        .accessibilityLabel("Günlük kart sayısı \(n)")
                    AdimDugmesi(isaret: "+", ad: "Artır", etkin: n < 100) { kart(5) }
                }
            }
            AyarCizgisi()
            AnahtarSatiri(simge: .tanis, ad: "Yeni sanatçıyla önce tanış", alt: "İlk sorudan önce 3 eser ve ipucu",
                          acik: anahtar("tanisma"))
            AyarCizgisi()
            VStack(alignment: .leading, spacing: 0) {
                AnahtarSatiri(simge: .titresim, ad: "Titreşim", alt: "Cevaba dokununca hafif dokunuş", acik: anahtar("titresim"))
                if titresim {
                    Button("Titreşimi dene") { Titresim.dogru() }
                        .buttonStyle(CamHap())
                        .padding(.leading, 60).padding(.bottom, 14)
                }
            }
            AyarCizgisi()
            AyarSatiri(simge: .gunun, ad: "Günün sanatçısı", alt: bilgi.gunun) {
                Button("Değiştir") { gununSanatcisi() }
                    .buttonStyle(CamHap())
                    .accessibilityLabel("Günün sanatçısını değiştir")
            }
        }
    }

    // MARK: Yedek

    private var yedekBolumu: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 0) {
            AyarKarti {
                AyarSatiri(simge: .muhur, ad: "İlerleme yedeği",
                           alt: AyarYazilari.sonYedek(depo.il?[alan: "sonYedek"]?.metin, bugun: depo.bugun))
                VStack(alignment: .leading, spacing: 10) {
                    Button("İlerlemeni yedekle") {
                        depo.yap {
                            let sonuc = try await depo.kopru.yedekAl()
                            yedek = sonuc
                            UIPasteboard.general.string = sonuc
                            depo.mesaj = "Yedek panoya kopyalandı."
                        }
                    }
                    .buttonStyle(BirincilHap())
                    if !yedek.isEmpty {
                        Text(yedek).font(.system(size: 12, design: .monospaced)).lineLimit(4)
                            .foregroundStyle(Color(r.murekkep2))
                            .textSelection(.enabled)
                        Button("JSON dosyası olarak kaydet") { disa = true }.buttonStyle(CamHap())
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 14)
                AyarCizgisi()
                AcilirSatir(simge: .kumSaati, ad: "Yedeği geri yükle", alt: "Metin yapıştır veya JSON seç",
                            acik: $geriYukleAcik, tam: true) {
                    geriYukle
                }
            }
            AyarDipnotu("Yedek panoya kopyalanır; Notlar’a yapıştırıp sakla. Geri yüklenen yedek mevcut ilerlemenin yerine geçer.")
        }
    }

    private var geriYukle: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if girdi.isEmpty {
                    Text(#"{"uygulama":"sanat-atlasi", …}"#).font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(r.murekkep3)).padding(.horizontal, 12).padding(.vertical, 12)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $girdi)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(r.murekkep))
                    .scrollContentBackground(.hidden)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .accessibilityLabel("Geri yüklenecek yedek")
            }
            .frame(minHeight: 88)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.zemin)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            HStack(spacing: 8) {
                Button("Dosyadan seç") { ice = true }.buttonStyle(CamHap())
                Button("Geri yükle", action: denetle)
                    .buttonStyle(CamHap())
                    .disabled(girdi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: Eylemler

    private func sec(_ alan: String, _ deger: String) {
        depo.degistir { BenPanosu.sec(alan, deger, il: &$0) }
    }

    private func anahtar(_ alan: String) -> Binding<Bool> {
        Binding(get: { depo.il?.ayar(alan)?.mantik ?? true }, set: { ac in
            depo.degistir { $0.ayarla(alan, .mantik(ac)) }
        })
    }

    private func denetle() {
        let metin = girdi
        depo.yap {
            let kayit = try await depo.kopru.oku()
            let json = JSONDeger.nesne(try depo.kopru.yedekCoz(metin)).jsonMetni
            let ozet = try BenYedekOzeti(dogrulanmisJSON: json)
            onay = Yukleme(metin: metin, no: kayit.kayitNo, konu: ozet.konu, skor: ozet.skor)
        }
    }

    private func kart(_ adim: Int) { depo.degistir { BenPanosu.kart(adim, il: &$0) } }

    private func egimAyarla(_ ac: Bool) {
        depo.degistir { $0.ayarla("egim", .mantik(ac)) }
    }

    /// "Başka bir sanatçı getir" (Z2c-3: sitenin `baskaSanatci(gununHavuzu(), gununId())`'si)
    private func gununSanatcisi() {
        depo.yap {
            guard let id = await depo.baskaSanatci() else { throw URLError(.notConnectedToInternet) }
            _ = try await depo.kopru.degistir {
                $0[alan: "gununDegisim"] = .nesne([("tarih", .metin(depo.bugun)), ("id", .metin(id))])
            }
            depo.mesaj = "Bugünün sanatçısı: " + (depo.katalog?.bilinenAd(id) ?? id)
        }
    }
}

private extension AyarGrubu {
    var sira: Int { AyarGrubu.allCases.firstIndex(of: self) ?? 0 }
}

/// Görünüş kartının üstündeki canlı önizleme (Apple'ın "Ekran ve Parlaklık"ı gibi kartın içinde): *Arnolfini Portresi*,
/// Bodoni başlık ve Newsreader okuma metni. Tema, Gündüz rengi ve yazı boyu değişince anında; eğim açık ve hareket tam
/// ise tablo yavaşça nefes alır (`kart-nefes`).
struct AyarOnizlemesi: View {
    let depo: BenDeposu
    let durum: String
    let buyuk: Bool
    let oynar: Bool
    @Environment(TemaDeposu.self) private var tema
    @State private var nefes = false
    @State private var adres: URL?

    var body: some View {
        let r = tema.renkler
        HStack(alignment: .center, spacing: 14) {
            Group {
                if let adres {
                    UzakGorsel(url: adres, odak: [50, 22])
                } else {
                    Color(r.yuzey)
                }
            }
            .frame(width: 64, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .rotation3DEffect(.degrees(oynar ? (nefes ? 3 : -3) : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("Önizleme").font(Font(Yazi.uiFont(.sans, 12, agirlik: 600))).foregroundStyle(Color(r.pirinc))
                    Spacer(minLength: 0)
                    Text(durum).font(Font(Yazi.uiFont(.sans, 11.5, agirlik: 500))).foregroundStyle(Color(r.murekkep3))
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                .padding(.bottom, 3)
                // Boyutlar Dinamik Yazı'sız: önizleme seçilen boyu tam gösterir (Standart 19 / 15.5·23, Büyük 22 / 19·28)
                Text("Arnolfini Portresi")
                    .font(Font(Yazi.uiFont(.serif, buyuk ? 22 : 19, agirlik: 500)))
                    .foregroundStyle(Color(r.murekkep))
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .padding(.bottom, 4)
                Text("Arka duvardaki dışbükey aynada odanın eşiğinden bakan iki tanık seçilir.")
                    .font(Font(Yazi.uiFont(.okuma, buyuk ? 19 : 15.5)))
                    .lineSpacing(buyuk ? 28 - 19 * Yazi.Aile.okuma.satirOrani : 23 - 15.5 * Yazi.Aile.okuma.satirOrani)
                    .foregroundStyle(Color(r.murekkep2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(r.yuzey2))
        .overlay(alignment: .bottom) { Rectangle().fill(Color(r.kenarInce)).frame(height: 1) }
        .animation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.26), value: buyuk)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Önizleme, \(durum)")
        .task(id: depo.katalog != nil) {
            // Önizlemenin tablosu: katalogda Jan van Eyck'in Arnolfini Portresi
            guard let k = depo.katalog,
                  let e = k.eserler("jan-van-eyck").first(where: { $0.gorunenAd.localizedCaseInsensitiveContains("Arnolfini") })
            else { return }
            adres = k.gorselAdresi(e, genislik: 400)
        }
        .onChange(of: oynar, initial: true) { _, o in
            nefes = false
            guard o else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { nefes = true }
        }
    }
}

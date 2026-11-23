// Kaynak: sanat-atlasi js/ekranlar/{ayarlar,hizliAyar}.js, js/depo.js, js/gunduzRenk.js, css/app.css (.ayar, .parcali,
// .adimlayici, .konu, .anahtar, .dugme) @ a866b86
// C4b: görünüş ve sıra sitenin #/ayarlar sayfası gibi; davranış C4'teki gibi.
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

/// Ayarlar sayfasının siteden okunan yazıları (sitenin kendi modülleriyle; bkz. `AyarBilgisi.betik`)
struct AyarBilgisi {
    var gunun = "—"
    var surum = ""
    var yenilikler: [String] = []
    var hata = 0
    var hataSon = ""
    var odak = 0
    var yuruyus = 0
    var egimVar = true
    var izinGerekli = true
    /// Hareket izni bu oturumda verildi mi. `izinVarMi()` buradan sorulmaz: yerli koddan çağrılan betik dokunuş sayılır
    /// ve iOS izin penceresini açar (C4b CI'ında Ayarlar'ı kapattı). Düğme, izin verilene kadar görünür.
    var izinVar = false
    /// Gündüz rengi örnekleri: seçim → (band, altın, yüzey, kenar); "notr" için yok
    var paletler: [String: [String]] = [:]

    static let betik = """
    const o = await import('/js/ekranlar/ortak.js');
    const { SURUM } = await import('/js/surum.js');
    const y = await import('/js/yenilikler.js');
    const h = await import('/js/hataGunlugu.js');
    const g = await import('/js/gorsel.js');
    const e = await import('/js/egim.js');
    const { bilinenAd } = await import('/js/adlar.js');
    const { GUNDUZ_RENKLERI } = await import('/js/gunduzRenk.js');
    const d = o.d;
    const s = d.harita.get(o.gununId());
    const l = h.hatalariOku();
    const paletler = {};
    for (const r of GUNDUZ_RENKLERI) {
      const p = o.gunduzOrnekPaleti(r);
      if (p) paletler[r] = [p.band, p.altin, p.surface, p.border];
    }
    return {
      gunun: s ? bilinenAd(s.ad, d.kisaAdlar[s.id]) : '—',
      surum: SURUM,
      yenilikler: y.YENILIKLER.map(y.yenilikYazisi),
      hata: l.length,
      hataSon: l.length ? new Date(l[l.length - 1].z).toLocaleString('tr-TR') : '',
      odak: Object.keys(g.cihazdakiElleOdaklar()).length,
      yuruyus: d.yuruyus ? d.sanatcilar.filter((x) => d.yuruyus[x.id]).length : 0,
      egimVar: e.egimVar(), izinGerekli: e.izinGerekli(),
      paletler,
    };
    """

    init() {}
    init(_ s: [String: Any]) {
        gunun = s["gunun"] as? String ?? "—"
        surum = s["surum"] as? String ?? ""
        yenilikler = s["yenilikler"] as? [String] ?? []
        hata = (s["hata"] as? NSNumber)?.intValue ?? 0
        hataSon = s["hataSon"] as? String ?? ""
        odak = (s["odak"] as? NSNumber)?.intValue ?? 0
        yuruyus = (s["yuruyus"] as? NSNumber)?.intValue ?? 0
        egimVar = s["egimVar"] as? Bool ?? true
        izinGerekli = s["izinGerekli"] as? Bool ?? true
        paletler = s["paletler"] as? [String: [String]] ?? [:]
    }
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
    @State private var modOnayi = false
    @State private var bilgi = AyarBilgisi()

    struct Yukleme: Identifiable {
        let id = UUID()
        let metin: String
        let no, konu, skor: Int
    }

    private static let gunduzRenkleri = ["otomatik", "lapis", "pompei", "bakir", "safran", "notr"]
    private static let gunduzRenkAdi = ["Günün resmi", "Lapis", "Pompei", "Bakır yeşili", "Safran", "Nötr kâğıt"]

    var body: some View {
        ScrollViewReader { kaydir in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BenUst(baslik: "Ayarlar", boyut: 40, geri: geri)
                    .padding(.top, 12).padding(.bottom, 10)
                if let il = depo.il { ayarlar(il) }
                yedekle.id("yedek")
                geriYukle
                if let il = depo.il {
                    BildirimBolumu(depo: depo)
                    HataBolumu(depo: depo, bilgi: $bilgi)
                    AyarBolumu {
                        Toggle(isOn: Binding(get: { il[alan: "gelistirici"]?.nesne != nil }, set: { _ in modOnayi = true })) {
                            AnahtarYazisi(baslik: "Geliştirici modu",
                                          aciklama: "Bütün konular, sanatçılar ve harita bölümleri açılır. Kapatınca açmadan önceki ilerlemen olduğu gibi geri gelir; mod açıkken çözdüklerin sayılmaz.")
                        }
                        .toggleStyle(AnahtarBicimi())
                        .padding(.vertical, -10)
                    }
                    GununResimleriBolumu(depo: depo, yuruyus: bilgi.yuruyus)
                    if bilgi.odak > 0 || il[alan: "gelistirici"]?.nesne != nil {
                        ElleOdakBolumu(depo: depo, bilgi: $bilgi)
                    }
                    SurumBolumu(depo: depo, surum: bilgi.surum)
                }
                if !bilgi.yenilikler.isEmpty {
                    AyarBolumu(baslik: "Yenilikler") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(bilgi.yenilikler.indices, id: \.self) { i in
                                Text(bilgi.yenilikler[i]).font(Yazi.sans(14)).lineSpacing(7)
                                    .foregroundStyle(Color(tema.renkler.murekkep))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                Text("Sanat Atlası \(bilgi.surum) · Görseller: Wikimedia Commons, müze açık erişim koleksiyonları ve WikiArt · Eser listeleri: Wikidata")
                    .font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(tema.renkler.murekkep3))
                    .padding(.top, 18)
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        #if DEBUG
        .task(id: depo.il != nil) { if depo.il != nil { await BenKarsilastirma.kaydir(kaydir) } }
        #endif
        }
        .disabled(depo.mesgul)
        .task(id: depo.il?.kayitNo) {
            if let s = try? await depo.kopru.benBetigi(AyarBilgisi.betik) as? [String: Any] {
                let izin = bilgi.izinVar
                bilgi = AyarBilgisi(s)
                bilgi.izinVar = izin
            }
        }
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
                    _ = try? await depo.kopru.benBetigi("(await import('/js/ekranlar/ortak.js')).d.oturum = null;")
                    girdi = ""
                    depo.mesaj = "Yedek geri yüklendi."
                }
            }, secondaryButton: .cancel(Text("Vazgeç")))
        }
        .confirmationDialog("Mod açıkken bütün konular açılır. Kapatınca önceki ilerleme geri gelir.",
                            isPresented: $modOnayi, titleVisibility: .visible) {
            Button("Geliştirici modunu değiştir") {
                let ac = depo.il?[alan: "gelistirici"]?.nesne == nil
                depo.yap {
                    let l = try await depo.kopru.benBetigi(IlerlemeKoprusu.benGelistiriciListeleri) as? [String: Any]
                    guard let nolar = l?["nolar"] as? [NSNumber], let bolumler = l?["bolumler"] as? [String] else {
                        throw IlerlemeKoprusu.Hata.siteYok
                    }
                    try await depo.kopru.gelistirici(ac: ac, konular: nolar.map(\.intValue), bolumIdleri: bolumler)
                    _ = try? await depo.kopru.benBetigi("(await import('/js/ekranlar/ortak.js')).d.oturum = null;")
                }
            }
        }
    }

    // MARK: Görünüş ve çalışma

    @ViewBuilder
    private func ayarlar(_ il: Ilerleme) -> some View {
        let n = il.ayar("gunlukKart")?.tamSayi ?? 20
        AyarBolumu(baslik: "Günlük kart sayısı", ilk: true) {
            HStack(spacing: 12) {
                adim("−", "Azalt", etkin: n > 5) { kart(-5) }
                Text("\(n)").font(Yazi.serif(32)).monospacedDigit()
                    .frame(minWidth: 58)
                    .accessibilityLabel("Günlük kart sayısı \(n)")
                adim("+", "Artır", etkin: n < 100) { kart(5) }
            }
            .padding(.top, 8)
            AyarAciklamasi("Bir pekiştirme turundaki kart sayısı. Günde en fazla 8 yeni sanatçı eklenir.")
        }
        AyarBolumu(baslik: "Tema") {
            secim("Tema", "tema", [("gece", "Gece"), ("gunduz", "Gündüz")])
        }
        AyarBolumu(baslik: "Gündüz rengi") {
            ParcaliSecim(ad: "Gündüz rengi",
                         secenekler: Self.gunduzRenkleri.indices.map { (Self.gunduzRenkleri[$0], Self.gunduzRenkAdi[$0]) },
                         secili: il.ayar("gunduzRenk")?.metin ?? "otomatik",
                         ornek: { AnyView(renkOrnegi($0)) }) { sec("gunduzRenk", $0) }
            AyarAciklamasi("Gündüz temasında zemin, kartlar, sekme çubuğu ve çarkın rengi. Günün resmi: renkler her gün o günün tablosundan seçilir. Nötr kâğıt: eski sade Gündüz.")
        }
        AyarBolumu(baslik: "Yazı boyutu") {
            secim("Yazı boyutu", "yazi", [("standart", "Standart"), ("buyuk", "Büyük")])
            AyarAciklamasi("Büyük: okuma metinleri, açıklamalar ve küçük yazılar bir boy büyür.")
        }
        AyarBolumu(baslik: "Hareket") {
            secim("Hareket", "hareket", [("tam", "Tam"), ("sade", "Sade"), ("kapali", "Kapalı")])
            AyarAciklamasi("Sade: sayfa geçişleri ve cevap anı kalır; sürekli dönen, nefes alan, parlayan süs hareketleri durur. Kapalı: hiçbir şey hareket etmez.")
        }
        AyarBolumu {
            anahtar("Yeni sanatçıyla önce tanış", "Bir sanatçı ilk kez sorulmadan önce en bilinen 3 eseri ve “Nasıl tanırım?” notu gösterilir.", "tanisma")
        }
        AyarBolumu {
            Toggle(isOn: Binding(get: { il.ayar("rozet")?.mantik ?? false }, set: rozet)) {
                AnahtarYazisi(baslik: "Simge rozeti", aciklama: "Ana ekrandaki Atlas simgesinde tekrarı gelen sanatçı sayısı görünür. İzin ister; sayı uygulama kapanırken yarının sayısına ayarlanır.")
            }
            .toggleStyle(AnahtarBicimi()).padding(.vertical, -10)
        }
        AyarBolumu {
            anahtar("Titreşim", "Cevaba dokununca telefon hafifçe titrer. iPhone’da iOS 18 ve sonrası gerekir; Ayarlar → Sesler ve Dokunuş → Sistem Dokunuşları açık olmalı. Android’de doğruda bir, yanlışta iki kez titrer.", "titresim")
            Button("Titreşimi dene") { Titresim.dogru() }
                .buttonStyle(HapDugme(ince: true)).padding(.top, 26)
        }
        AyarBolumu {
            let egim = il.ayar("egim")?.mantik ?? true
            Toggle(isOn: Binding(get: { egim }, set: egimAyarla)) {
                AnahtarYazisi(baslik: "Telefonu eğince tablo oynasın", aciklama: bilgi.egimVar
                    ? "Tuval’deki günün tablosu telefonu sağa sola çevirdikçe, öne arkaya eğdikçe hafifçe döner, ışık üstünden kayar; sergi duvarında ve Koleksiyonum’da tablolar ipinden sallanır, Atölye’deki deste yelpaze açılır." + (bilgi.izinGerekli ? " iPhone hareket izni ister ve uygulama kapanınca çoğu zaman unutur: o zaman Tuval’deki ya da buradaki düğmeyle yeniden ver." : "")
                    : "Bu tarayıcı hareket algılayıcısını desteklemiyor.")
            }
            .toggleStyle(AnahtarBicimi()).padding(.vertical, -10)
            .disabled(!bilgi.egimVar)
            if bilgi.izinGerekli && egim && !bilgi.izinVar {
                Button { egimAyarla(true) } label: {
                    Label { Text("Hareket iznini ver") } icon: { BenIkon(simge: .hareket, boyut: 18, kalinlik: 1.6) }
                }
                .buttonStyle(HapDugme(ince: true)).padding(.top, 26)
            }
        }
        GununSanatcisiBolumu(depo: depo, ad: bilgi.gunun)
        BenCevrimdisi(depo: depo)
    }

    // MARK: Yedek

    private var yedekle: some View {
        AyarBolumu(baslik: "Yedekle", aciklama: "İlerlemen panoya kopyalanır ve aşağıda görünür. Notlar uygulamasına yapıştırıp sakla.") {
            Button {
                depo.yap {
                    let sonuc = try await depo.kopru.yedekAl()
                    yedek = sonuc
                    UIPasteboard.general.string = sonuc
                    depo.mesaj = "Yedek panoya kopyalandı."
                }
            } label: {
                HStack(spacing: 10) { PigmentDisk(simge: .muhur, renk: .okra); Text("Yedekle") }
            }
            .buttonStyle(HapDugme()).padding(.top, 8)
            if !yedek.isEmpty {
                Text(yedek).font(.system(size: 12, design: .monospaced)).lineLimit(4)
                    .foregroundStyle(Color(tema.renkler.murekkep2))
                    .textSelection(.enabled)
                    .padding(.top, 10)
                Button("JSON dosyası olarak kaydet") { disa = true }
                    .buttonStyle(HapDugme(ince: true)).padding(.top, 10)
            }
            if let t = depo.il?[alan: "sonYedek"]?.metin {
                Text("Son yedek · \(t)").font(Yazi.sans(13.5, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep2))
                    .padding(.top, 6)
            }
        }
    }

    private var geriYukle: some View {
        let r = tema.renkler
        return AyarBolumu(baslik: "Yedeği geri yükle", aciklama: "Daha önce aldığın yedeği buraya yapıştır. Mevcut ilerlemenin yerine geçer.") {
            ZStack(alignment: .topLeading) {
                if girdi.isEmpty {
                    Text(#"{"uygulama":"sanat-atlasi", …}"#).font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Color(r.murekkep3)).padding(.horizontal, 14).padding(.vertical, 12)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $girdi)
                    .font(.system(size: 16, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .accessibilityLabel("Geri yüklenecek yedek")
            }
            .frame(minHeight: 140)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .padding(.top, 8)
            HStack(spacing: 8) {
                Button(action: denetle) {
                    HStack(spacing: 10) { PigmentDisk(simge: .kumSaati, renk: .umbra); Text("Geri yükle") }
                }
                .buttonStyle(HapDugme())
                .disabled(girdi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Dosyadan seç") { ice = true }.buttonStyle(HapDugme(ince: true))
            }
            .padding(.top, 8)
        }
    }

    // MARK: Parçalar

    private func adim(_ isaret: String, _ ad: String, etkin: Bool, _ eylem: @escaping () -> Void) -> some View {
        let r = tema.renkler
        return Button(action: eylem) {
            Text(isaret).font(Yazi.sans(22, stil: .title3))
                .foregroundStyle(Color(r.murekkep))
                .frame(width: 50, height: 48)
                .background(Circle().fill(Color(r.yuzey)))
                .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.06), .white.opacity(0)], startPoint: .top, endPoint: .bottom)))
                .overlay(Circle().strokeBorder(Color(r.notrKenar), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(BasincBicimi(olcek: 0.95))
        .disabled(!etkin)
        .opacity(etkin ? 1 : 0.55)
        .accessibilityLabel(ad)
    }

    /// `renkOrnegi(secim)`: 26 px, köşegenle ikiye bölünmüş band ve altın; çevresinde yüzey ve kenar halkası
    private func renkOrnegi(_ secim: String) -> some View {
        let p = (bilgi.paletler[secim] ?? []).compactMap { RGBA(css: $0) }
        return ZStack {
            if p.count == 4 {
                Circle().fill(Color(p[1]))
                Circle().fill(Color(p[0])).mask(
                    GeometryReader { g in
                        Path { y in
                            y.move(to: .zero); y.addLine(to: CGPoint(x: g.size.width, y: 0))
                            y.addLine(to: CGPoint(x: 0, y: g.size.height)); y.closeSubpath()
                        }
                    })
                Circle().strokeBorder(Color(p[2]), lineWidth: 2).padding(-2)
                Circle().strokeBorder(Color(p[3]), lineWidth: 1).padding(-3)
            } else {
                // `.renk-ornek.notr`: linear-gradient(135deg, #4c463f 0 50%, #ece8e1 50% 100%),
                // box-shadow 0 0 0 2px #f7f5f1, 0 0 0 3px #d6d0c6
                Circle().fill(Color(RGBA(css: "#ece8e1")!))
                Circle().fill(Color(RGBA(css: "#4c463f")!)).mask(
                    GeometryReader { g in
                        Path { y in
                            y.move(to: .zero); y.addLine(to: CGPoint(x: g.size.width, y: 0))
                            y.addLine(to: CGPoint(x: 0, y: g.size.height)); y.closeSubpath()
                        }
                    })
                Circle().strokeBorder(Color(RGBA(css: "#f7f5f1")!), lineWidth: 2).padding(-2)
                Circle().strokeBorder(Color(RGBA(css: "#d6d0c6")!), lineWidth: 1).padding(-3)
            }
        }
        .frame(width: 26, height: 26)
        .padding(3)
        .accessibilityHidden(true)
    }

    private func secim(_ ad: String, _ alan: String, _ l: [(String, String)]) -> some View {
        ParcaliSecim(ad: ad, secenekler: l.map { ($0.0, $0.1) }, secili: depo.il?.ayar(alan)?.metin ?? l[0].0) { sec(alan, $0) }
    }

    private func sec(_ alan: String, _ deger: String) {
        depo.degistir(sonra: "(await import('/js/ekranlar/ortak.js')).temaUygula();") {
            BenPanosu.sec(alan, deger, il: &$0)
        }
    }

    private func anahtar(_ ad: String, _ aciklama: String, _ alan: String) -> some View {
        Toggle(isOn: Binding(get: { depo.il?.ayar(alan)?.mantik ?? true }, set: { ac in
            depo.degistir { $0.ayarla(alan, .mantik(ac)) }
        })) { AnahtarYazisi(baslik: ad, aciklama: aciklama) }
            .toggleStyle(AnahtarBicimi())
            .padding(.vertical, -10)
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
        depo.yap {
            if ac {
                let izin = try await depo.kopru.benBetigi("return await (await import('/js/egim.js')).egimIzni();")
                guard izin as? Bool == true else { depo.mesaj = "Hareket izni verilmedi."; return }
                bilgi.izinVar = true
            }
            _ = try await depo.kopru.degistir { $0.ayarla("egim", .mantik(ac)) }
        }
    }
    private func rozet(_ ac: Bool) {
        depo.yap {
            if ac {
                guard await Hatirlatici.shared.izinIste() == "granted" else {
                    depo.mesaj = "Simge rozeti için iOS Ayarlar’dan bildirim izni ver."; return
                }
            }
            let il = try await depo.kopru.degistir { $0.ayarla("rozet", .mantik(ac)) }
            Hatirlatici.shared.rozet(ac ? il.vadeSayisi(depo.katalog?.sanatcilar ?? [], tarih: depo.bugun) : 0)
        }
    }
}

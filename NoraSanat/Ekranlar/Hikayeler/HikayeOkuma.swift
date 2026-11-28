// Z4b · Hikâye okuma ve okuma içinde dinleme (yeni; sitede yok). Tasarım: Neon "Yön 2 · Substack Minimal"
// (dal neon/hikayeler-tasarim-3, PR #75): yon-2.html `makaleCiz`, `.sub-makale`, `.sub-m-baslik`, `.sub-yazar-satir`,
// `.sub-ara-baslik`; ortak.css `.okuma-ust`, `.p-blok` (dinlerken `.okunan`), `.eser-fig`, `.ic-calar`, `.son-bolum`,
// `.bag-kart`, `.kaynak-liste`; goruntuler/yon-2-{okuma-basi,okuma-eser,dinleme,son}-*.png.
import NoraCekirdek
import SwiftUI

struct HikayeOkuma: View {
    let hikaye: SanatciHikayesi
    /// Bağlantılı yazıyı açar
    let ac: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat
    @Environment(\.openURL) private var adresAc
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared
    /// Ekranın üstündeki blok (`scrollPosition`)
    @State private var gorunen: String?
    @State private var hazir = false
    /// Z4e: dokunulan eser tam ekranda (hikâyedeki ya da "Daha fazla eser"deki eserler arasında kaydırılır)
    @State private var goruntu: GoruntuSecimi?
    /// Okuma içi çalar açık (bu yazı dinleniyor)
    private var dinleme: Bool { calar.hikaye?.id == hikaye.id }
    /// Z4h: dizi bölümü mü, yoksa tek sanatçı hikâyesi mi?
    private var diziMi: Bool { hikaye.dizi != nil }
    /// Z4h: ses kaydı yoksa (dizi bölümleri ses eklenene dek) dinle düğmesi gizlenir
    private var dinlenebilir: Bool { depo.dinlenebilir(hikaye) }

    private var bloklar: [HikayeBlogu] { hikaye.bloklar }
    private var kapak: HikayeEseri? { hikaye.kapakEseri }
    private var kapakBolumu: Int? { hikaye.bolumler.firstIndex { !$0.eserler.isEmpty } }

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        ScrollViewReader { kaydir in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    bas(c).id("ust")
                    ForEach(bloklar.map { (kimlik($0), $0) }, id: \.0) { k, b in
                        blok(b, c).id(k)
                    }
                    son(c).id("son")
                        .onAppear { yeriYaz(sonda: true) }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 22)
                .padding(.bottom, dinleme ? 140 : 60)
            }
            .scrollPosition(id: $gorunen, anchor: .top)
            .scrollIndicators(.hidden)
            .onChange(of: gorunen) { _, _ in if hazir { yeriYaz(sonda: false) } }
            // Dinlerken ekran okunan paragrafı izler (paragraf değişince)
            .onChange(of: calar.paragraf) { _, p in
                guard dinleme, let p else { return }
                withAnimation(hareketAz || tema.ayar.hareketAzaltilmis ? nil : .easeInOut(duration: 0.5)) {
                    kaydir.scrollTo("p\(p)", anchor: UnitPoint(x: 0.5, y: 0.24))
                }
            }
            .task(id: hikaye.id) {
                // Kalınan yer: dinleniyorsa okunan paragraf, değilse en son okunan paragraf
                #if DEBUG
                HikayeProva.okumaAcildi(hikaye)
                #endif
                try? await Task.sleep(for: .milliseconds(120))
                if dinleme, let p = calar.paragraf {
                    kaydir.scrollTo("p\(p)", anchor: UnitPoint(x: 0.5, y: 0.24))
                } else if let y = depo.yer(hikaye.id), y.yarim, y.paragraf > 0 {
                    kaydir.scrollTo("p\(min(y.paragraf, hikaye.paragraflar.count - 1))", anchor: .top)
                }
                #if DEBUG
                if let hedef = HikayeProva.kaydir() {
                    kaydir.scrollTo(hedef, anchor: UnitPoint(x: 0.5, y: 0.12))
                    gorunen = hedef
                }
                #endif
                try? await Task.sleep(for: .milliseconds(400))
                hazir = true
            }
        }
        // Z4f/Z4h (Emre: "arkadaki renk halesi … ve semboller hiçbirinde yok"): Galeri'nin zemini: kapak tablosunun
        // renklerinden hale ve sanatçının döneminin sembol deseni
        .background(SayfaZemini(donem: depo.donem(hikaye),
                                tablo: depo.kapakAdresi(hikaye, genislik: 400),
                                alan: .hikayeler))
        .overlay(alignment: .top) { ustCubuk(c) }
        .overlay(alignment: .bottom) {
            if dinleme {
                HikayeIcCalar()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: dinleme)
        .onDisappear { yeriYaz(sonda: false) }
        .fullScreenCover(item: $goruntu) { g in
            Goruntuleyici(eserler: g.eserler, baslangic: g.baslangic).environment(tema)
        }
    }

    // MARK: Üst

    /// Yapışkan üst: geri, (kayınca) sanatçının ya da dizinin adı, kulaklık (ses varsa).
    private func ustCubuk(_ c: HikayeRenk) -> some View {
        let yapiskan = gorunen != nil && gorunen != "ust"
        let ustBaslik = diziMi ? (depo.diziAdi(hikaye) ?? hikaye.baslik) : depo.sanatciAdi(hikaye.id)
        return HStack(spacing: 8) {
            Button { kapat() } label: { HikayeIkon(simge: .geri, boyut: 20, kalinlik: 1.8) }
                .buttonStyle(HikayeCamDugme())
                .accessibilityLabel(diziMi ? "Diziye dön" : "Yazılara dön")
            Text(ustBaslik)
                .font(Yazi.serif(16, agirlik: 500))
                .foregroundStyle(c.yazi)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .opacity(yapiskan ? 1 : 0)
                .accessibilityHidden(!yapiskan)
            if dinlenebilir {
                Button {
                    if dinleme { calar.kapat() } else { dinleDugmesi() }
                } label: { HikayeIkon(simge: .kulaklik, boyut: 19, kalinlik: 1.6) }
                    .buttonStyle(HikayeCamDugme())
                    .accessibilityLabel(dinleme ? "Dinlemeyi kapat" : "Dinle")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background {
            ZStack(alignment: .bottom) {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(c.cam)
                Rectangle().fill(c.kenar).frame(height: 1)
            }
            .ignoresSafeArea(edges: .top)
            .opacity(yapiskan ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.22), value: yapiskan)
    }

    // MARK: Baş

    /// `.sub-m-baslik` (Newsreader 31/600), `.sub-m-alt` (Archivo 16), `.sub-yazar-satir` (sanatçı · yıllar, süreler,
    /// sağda ses varsa "Dinle"), kapak (ilk bölümün ilk eseri, künyesiyle)
    private func bas(_ c: HikayeRenk) -> some View {
        let s = depo.satir(hikaye)
        let yazarSatiri = diziMi
            ? s.sanatci
            : [s.sanatci, s.yillar].filter { !$0.isEmpty }.joined(separator: " · ")
        let sureSatiri = dinlenebilir
            ? "\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme"
            : "\(s.okumaDk) dk okuma"
        return VStack(alignment: .leading, spacing: 0) {
            if diziMi, let diziAdi = depo.diziAdi(hikaye) {
                let etiket = hikaye.bolumSirasi.map { "\(diziAdi) · \($0). bölüm" } ?? diziAdi
                Text(etiket)
                    .font(Yazi.sans(13, agirlik: 600))
                    .foregroundStyle(c.pirinc)
                    .padding(.bottom, 8)
            }
            Text(hikaye.baslik)
                .font(Yazi.okuma(31, agirlik: 600, stil: .largeTitle))
                .tracking(-0.62)
                .cssSatir(.okuma, 31, 31 * 1.16)
                .foregroundStyle(c.yazi)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
                .accessibilityAddTraits(.isHeader)
            if !hikaye.altBaslik.isEmpty {
                Text(hikaye.altBaslik)
                    .font(Yazi.sans(16))
                    .cssSatir(.sans, 16, 24)
                    .foregroundStyle(c.yazi2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 20)
            }
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(yazarSatiri)
                        .font(Yazi.sans(14, agirlik: 600)).foregroundStyle(c.yazi)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sureSatiri)
                        .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
                }
                Spacer(minLength: 4)
                if dinlenebilir {
                    dinleHapi(c)
                }
            }
            .padding(.vertical, 14)
            .overlay(alignment: .top) { Rectangle().fill(c.kenar).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
            .padding(.bottom, 24)
            if let k = kapak { eser(k, c, kapakMi: true) }
        }
        .padding(.top, 60)
    }

    /// Yazının başındaki "Dinle" (`.btn-dolu`); dinlerken "Dinleniyor" (`.btn-cam`)
    private func dinleHapi(_ c: HikayeRenk) -> some View {
        Button { dinleDugmesi() } label: {
            HStack(spacing: 7) {
                HikayeIkon(simge: .kulaklik, boyut: 16, kalinlik: 1.8)
                Text(dinleme ? "Dinleniyor" : "Dinle").font(Yazi.sans(14, agirlik: 600))
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .foregroundStyle(dinleme ? c.yazi : c.zemin)
            .background {
                if dinleme {
                    Capsule().fill(Color(tema.renkler.ustDugme)).overlay(Capsule().strokeBorder(c.kenar, lineWidth: 1))
                } else {
                    Capsule().fill(c.yazi)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("hikaye-dinle")
    }

    private func dinleDugmesi() {
        Titresim.dokunus()
        if dinleme {
            calar.degistir()
        } else {
            // Okunan yerden: ekranın üstündeki paragraf (yazının başındaysa baştan ya da dinlemede kalınan yerden)
            let p = ekrandakiParagraf()
            calar.baslat(hikaye, paragraf: p > 0 ? p : nil)
        }
    }

    // MARK: Bloklar

    private func kimlik(_ b: HikayeBlogu) -> String {
        switch b {
        case .paragraf(let no, _): return "p\(no)"
        case .araBaslik(let bolum, _, _): return "h\(bolum)"
        case .eser(let bolum, let sira, _): return "e\(bolum)-\(sira)"
        case .kapanis: return "k"
        }
    }

    @ViewBuilder
    private func blok(_ b: HikayeBlogu, _ c: HikayeRenk) -> some View {
        switch b {
        case .paragraf(let no, let metin):
            paragraf(no, metin, c)
        case .araBaslik(_, let baslik, let yillar):
            araBaslik(ust: yillar, baslik: baslik, c)
        case .eser(let bolum, let sira, let e):
            // Kapak yazının başında künyesiyle gösterildi
            if !(bolum == kapakBolumu && sira == 0) { eser(e, c, kapakMi: false) }
        case .kapanis:
            araBaslik(ust: "Kapanış", baslik: nil, c)
        }
    }

    /// `.p-blok`: Newsreader 19 / 1,74. Dinlerken öbür paragraflar geri çekilir (%44), okunan öne çıkar (`--aktif-p-bg`,
    /// 13×15 iç pay, sol kenarlı kutu yok). Dinlerken paragrafa dokunmak sesi oraya atlatır.
    private func paragraf(_ no: Int, _ metin: String, _ c: HikayeRenk) -> some View {
        let okunan = dinleme && calar.paragraf == no
        return paragrafYazisi(metin, okunan: okunan, c)
            .font(Yazi.okuma(19))
            .cssSatir(.okuma, 19, 19 * 1.74)
            .foregroundStyle(c.yazi)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, okunan ? 13 : 0)
            .padding(.horizontal, okunan ? 15 : 0)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(okunan ? c.okunan : .clear))
            .padding(.horizontal, okunan ? -15 : 0)
            .opacity(dinleme && !okunan ? 0.44 : 1)
            .padding(.bottom, 20)
            .animation(.easeOut(duration: 0.35), value: okunan)
            .contentShape(Rectangle())
            .onTapGesture {
                guard dinleme else { return }
                Titresim.secim()
                calar.paragrafaGit(no)
            }
            .accessibilityAction(named: "Buradan dinle") {
                guard dinlenebilir else { return }
                calar.baslat(hikaye, paragraf: no)
            }
    }

    /// Z4f (Emre: "okuma kısmında da okunan yeri belli edecek şekilde renkle ilerlesin"): dinlenen paragrafta
    /// söylenmiş kelimeler pirinç, kalanı mürekkep; söylenen kelimeyle birlikte ilerler.
    private func paragrafYazisi(_ metin: String, okunan: Bool, _ c: HikayeRenk) -> Text {
        guard okunan, let a = calar.gecerliAkis else { return Text(metin) }
        let y = a.ayir(kelime: calar.kelime)
        return Text(y.okunan).foregroundColor(c.pirinc) + Text(y.kalan).foregroundColor(c.yazi)
    }

    /// `.sub-ara-baslik`: üstte pirinç yıllar (`.ust-yazi`), altında Newsreader 24/600 başlık
    private func araBaslik(ust: String, baslik: String?, _ c: HikayeRenk) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !ust.isEmpty {
                Text(ust).font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
            }
            if let baslik {
                Text(baslik)
                    .font(Yazi.okuma(24, agirlik: 600))
                    .tracking(-0.36)
                    .cssSatir(.okuma, 24, 24 * 1.24)
                    .foregroundStyle(c.yazi)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 38).padding(.bottom, 14)
    }

    /// `.eser-fig`: kırpılmamış, tam genişlikte (12 köşe); altında Türkçe ad (Bodoni 17,5), yıl/tarih, müze ve bağ notu
    @ViewBuilder
    private func eser(_ e: HikayeEseri, _ c: HikayeRenk, kapakMi: Bool) -> some View {
        if let b = depo.eser(e, varsayilanSanatci: hikaye.id) {
            let tarihMetni = b.eser.yil.map { SiteYazisi.yilYaz($0) } ?? b.eser.tarih
            let altKunye: String = {
                if diziMi {
                    let sAdi = depo.sanatciAdi(e.sanatciKimligi(varsayilan: hikaye.id))
                    return [sAdi, b.eser.muze].filter { !$0.isEmpty }.joined(separator: " · ")
                }
                return b.eser.muze
            }()
            VStack(alignment: .leading, spacing: 0) {
                TamGorsel(url: b.url, yedek: b.yedek, oran: b.oran, kose: kapakMi ? 14 : 12)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(b.eser.gorunenAd)
                            .font(Yazi.serif(17.5, agirlik: 500))
                            .foregroundStyle(c.yazi)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if !tarihMetni.isEmpty {
                            Text(tarihMetni).font(Yazi.sans(12.5)).monospacedDigit().foregroundStyle(c.yazi3)
                        }
                    }
                    if !altKunye.isEmpty {
                        Text(altKunye).font(Yazi.sans(12.5)).foregroundStyle(c.yazi3).padding(.top, 2)
                    }
                    if !e.bag.isEmpty {
                        (Text(diziMi ? "Bu bölümle bağı  " : "Bu dönemle bağı  ")
                            .font(Yazi.sans(12.5, agirlik: 600)).foregroundColor(c.pirinc)
                            + Text(e.bag).font(Yazi.okuma(15.5)).foregroundColor(c.yazi2))
                            .cssSatir(.okuma, 15.5, 15.5 * 1.55)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    }
                }
                .padding(.top, 12)
            }
            .padding(.top, kapakMi ? 0 : 30)
            .padding(.bottom, kapakMi ? 26 : 32)
            .contentShape(Rectangle())
            .onTapGesture { eseriAc(b.eser) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Tam ekranda aç")
        }
    }

    // MARK: Son

    /// `.son-bolum`: bağlantılı yazılar (dizi bölümünde sonraki bölümler + sanatçı hikâyeleri) ve kaynaklar
    private func son(_ c: HikayeRenk) -> some View {
        let baglar = depo.baglantilar(hikaye)
        let sonrakiBolumler = diziMi ? depo.sonrakiBolumler(hikaye) : []
        let sanatciYazilari = diziMi ? depo.ilgiliSanatciHikayeleri(hikaye) : []
        return VStack(alignment: .leading, spacing: 0) {
            eylemCubugu(c)
                .padding(.bottom, 34)
            dahaFazlaEser(c)
            if !sonrakiBolumler.isEmpty {
                Text("Sıradaki bölüm")
                    .font(Yazi.serif(23, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .padding(.bottom, 16)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 12) {
                    ForEach(sonrakiBolumler) { b in
                        bolumBagKarti(b, c)
                    }
                }
                .padding(.bottom, 34)
            }
            if !sanatciYazilari.isEmpty {
                Text("Sanatçı hikâyeleri")
                    .font(Yazi.serif(23, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .padding(.bottom, 16)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 12) {
                    ForEach(sanatciYazilari) { h in bagKarti(h, c) }
                }
                .padding(.bottom, 34)
            }
            if !baglar.isEmpty {
                Text("Bağlantılı yazılar")
                    .font(Yazi.serif(23, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .padding(.bottom, 16)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 12) {
                    ForEach(baglar, id: \.sanatci) { b in
                        if let id = b.id, let h = depo.hikaye(id) { bagKarti(h, c) }
                    }
                }
                .padding(.bottom, 34)
            }
            // Z4i: sanatçının Galeri sayfası (eserleri, notları, dönemi)
            let galeridekiler = (diziMi ? hikaye.sanatcilar : [hikaye.id]).filter { depo.sanatci($0) != nil }
            if !galeridekiler.isEmpty {
                Text("Galeride")
                    .font(Yazi.serif(23, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .padding(.bottom, 8)
                    .accessibilityAddTraits(.isHeader)
                    .id("galeride")
                VStack(spacing: 0) {
                    ForEach(Array(galeridekiler.enumerated()), id: \.element) { i, sid in
                        sanatciSatiri(sid, son: i == galeridekiler.count - 1, c)
                    }
                }
                .padding(.bottom, 34)
            }
            let kaynaklar = HikayeAkisi.kaynaklar(hikaye)
            if !kaynaklar.isEmpty {
                Text("Kaynaklar").font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(kaynaklar.enumerated()), id: \.offset) { i, k in
                        Button {
                            if let u = URL(string: k.adres) { adresAc(u) }
                        } label: {
                            Text(k.baslik)
                                .font(Yazi.sans(13.5))
                                .foregroundStyle(c.yazi2)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) {
                            if i < kaynaklar.count - 1 { Rectangle().fill(c.kenar).frame(height: 1) }
                        }
                        .accessibilityHint("Safari'de açılır")
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 30)
        .overlay(alignment: .top) { Rectangle().fill(c.kenar).frame(height: 1) }
        .padding(.top, 44)
    }

    // MARK: Z4e · eylem çubuğu, daha fazla eser

    /// Substack'teki gibi yazının sonunda: Beğen · Sonra oku · Paylaş (Neon 4. tur, `yon-*-okuma-eylem-cubugu`)
    private func eylemCubugu(_ c: HikayeRenk) -> some View {
        let begendi = depo.begenildi(hikaye.id)
        let sonra = depo.sonradaMi(hikaye.id)
        return HStack(spacing: 0) {
            Button {
                Titresim.secim()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { depo.begen(hikaye.id) }
            } label: {
                eylem(begendi ? "heart.fill" : "heart", begendi ? "Beğendin" : "Beğen", etkin: begendi, c)
            }
            .accessibilityAddTraits(begendi ? .isSelected : [])
            .accessibilityIdentifier("hikaye-begen")
            Button {
                Titresim.secim()
                withAnimation(.easeOut(duration: 0.2)) { depo.sonraOku(hikaye.id) }
            } label: {
                eylem(sonra ? "bookmark.fill" : "bookmark", sonra ? "Listede" : "Sonra oku", etkin: sonra, c)
            }
            .accessibilityAddTraits(sonra ? .isSelected : [])
            ShareLink(item: paylasimMetni) {
                eylem("square.and.arrow.up", "Paylaş", etkin: false, c)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .overlay(alignment: .top) { Rectangle().fill(c.kenar).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
    }

    private func eylem(_ simge: String, _ ad: String, etkin: Bool, _ c: HikayeRenk) -> some View {
        HStack(spacing: 7) {
            Image(systemName: simge).font(.system(size: 16))
            Text(ad).font(Yazi.sans(14, agirlik: 600))
        }
        .foregroundStyle(etkin ? c.pirinc : c.yazi2)
        .frame(maxWidth: .infinity, minHeight: 48)
        .contentShape(Rectangle())
    }

    private var paylasimMetni: String {
        let s = depo.satir(hikaye)
        return [hikaye.baslik, [s.sanatci, s.yillar].filter { !$0.isEmpty }.joined(separator: " · "), hikaye.altBaslik]
            .filter { !$0.isEmpty }.joined(separator: "\n")
    }

    /// Hikâyede anılmayan öbür eserleri (katalogdan): yatay şerit; dokununca tam ekran
    @ViewBuilder
    private func dahaFazlaEser(_ c: HikayeRenk) -> some View {
        let l = depo.digerEserler(hikaye)
        if !l.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("Daha fazla eser")
                    .font(Yazi.serif(23, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .accessibilityAddTraits(.isHeader)
                Text("\(depo.sanatciAdi(hikaye.id)): yazıda anılmayan \(l.count) eser")
                    .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
                    .padding(.top, 3).padding(.bottom, 14)
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(Array(l.enumerated()), id: \.offset) { i, e in
                            Button {
                                Titresim.secim()
                                goruntu = GoruntuSecimi(eserler: l, baslangic: i)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    UzakGorsel(url: depo.gorselAdresi(e, genislik: 400), icerik: .fill)
                                        .frame(width: 132, height: 164)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    Text(e.gorunenAd).font(Yazi.serif(14, agirlik: 500)).foregroundStyle(c.yazi)
                                        .lineLimit(2).multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let y = e.yil {
                                        Text(SiteYazisi.yilYaz(y)).font(Yazi.sans(11.5)).foregroundStyle(c.yazi3)
                                    }
                                }
                                .frame(width: 132, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Tam ekranda aç")
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -22)
            }
            .padding(.bottom, 34)
        }
    }

    /// Yazıdaki esere dokununca: hikâyedeki bütün eserler arasında o eserden
    private func eseriAc(_ hedef: Eser) {
        let l = depo.hikayeEserleri(hikaye)
        guard let i = l.firstIndex(where: { $0.anahtar == hedef.anahtar }) else { return }
        Titresim.secim()
        goruntu = GoruntuSecimi(eserler: l, baslangic: i)
    }

    private func bolumBagKarti(_ b: DiziBolumu, _ c: HikayeRenk) -> some View {
        let s = depo.satir(b.hikaye)
        return Button {
            ac(b.id)
        } label: {
            HStack(spacing: 13) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(b.sira). bölüm · \(s.sanatci)")
                        .font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc).lineLimit(1)
                    Text(b.baslik)
                        .font(Yazi.serif(17, agirlik: 500))
                        .foregroundStyle(c.yazi)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2).padding(.bottom, 3)
                    Text("\(s.okumaDk) dk okuma")
                        .font(Yazi.sans(12)).foregroundStyle(c.yazi3)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(c.yuzey))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bag-bolum-\(b.id)")
    }

    /// `.bag-kart`: 68'lik kare kapak, pirinç sanatçı adı, Bodoni başlık, yıllar · okuma süresi
    /// Z4i: "Galeride" satırı: baş harf halkası, ad, "Sanatçı sayfası"; Galeri sekmesinde açılır
    private func sanatciSatiri(_ sid: String, son: Bool, _ c: HikayeRenk) -> some View {
        let ad = depo.sanatciAdi(sid)
        return Button { HikayeKoprusu.sanatciSayfasi(sid) } label: {
            HStack(spacing: 13) {
                Text(String(ad.prefix(1))).font(Yazi.serif(22)).foregroundStyle(c.pirinc)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(c.pirinc, lineWidth: 1.3))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ad).font(Yazi.serif(17, agirlik: 500)).foregroundStyle(c.yazi)
                    Text("Sanatçı sayfası · eserleri, notları").font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
                }
                Spacer(minLength: 4)
                HikayeIkon(simge: .ileri, boyut: 15, kalinlik: 1.8).foregroundStyle(c.yazi3)
            }
            .frame(minHeight: 64)
            .overlay(alignment: .bottom) { if !son { Rectangle().fill(c.kenar).frame(height: 1) } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Galeri'de açılır")
        .accessibilityIdentifier("galeride-\(sid)")
    }

    private func bagKarti(_ h: SanatciHikayesi, _ c: HikayeRenk) -> some View {
        let s = depo.satir(h)
        return Button {
            ac(h.id)
        } label: {
            HStack(spacing: 13) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    Text(s.sanatci).font(Yazi.sans(12, agirlik: 600)).foregroundStyle(c.pirinc)
                    Text(h.baslik)
                        .font(Yazi.serif(17, agirlik: 500))
                        .foregroundStyle(c.yazi)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2).padding(.bottom, 3)
                    Text([s.yillar, "\(s.okumaDk) dk okuma"].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(Yazi.sans(12)).foregroundStyle(c.yazi3)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(c.yuzey))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bag-\(h.id)")
    }

    // MARK: Okuma yeri

    /// Ekranın üstündeki bloğa göre okunan paragraf (o bloğun ya da ondan önceki son paragrafın numarası)
    private func ekrandakiParagraf() -> Int {
        guard let g = gorunen else { return 0 }
        if g == "son" { return max(0, hikaye.paragraflar.count - 1) }
        var son = 0
        for b in bloklar {
            if case .paragraf(let no, _) = b { son = no }
            if kimlik(b) == g { return son }
        }
        return 0
    }

    private func yeriYaz(sonda: Bool) {
        let p = ekrandakiParagraf()
        let onceki = depo.yer(hikaye.id)
        let y = HikayeAkisi.ilerle(onceki, paragraf: p, toplam: hikaye.paragraflar.count, sonda: sonda)
        if sonda && onceki?.bitti != true { Titresim.dogru() }
        depo.yerYaz(hikaye.id, y)
    }
}


/// Z4e: tam ekranda açılacak eserler
struct GoruntuSecimi: Identifiable {
    let id = UUID()
    let eserler: [Eser]
    let baslangic: Int
}

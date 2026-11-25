// Kaynak: sanat-atlasi js/ekranlar/ilerleme.js (ilerlemeSayfasi, parcalar, eserDuvari, konuIsaretle),
// js/ekranlar/pano.js, js/ekranlar/ortak.js (ust, tabloDugme), css/app.css (.ilr-sahne, .duvar, .ilr-govde, .ilr-buyuk,
// .ilr-cizgi, .ilr-sayilar, .eser-dugme) @ a866b86
// C4b: görünüş sitenin #/ilerleme sayfası gibi; davranış C4'teki gibi (T2 köprüsü).
import NoraCekirdek
import SwiftUI

enum BenGecisi {
    static var sekmeler: Set<Sekme> {
        #if DEBUG
        // T2 ekran görüntüsü siteye yazılan ilerlemeyi hâlâ sitede doğrular.
        if CommandLine.arguments.contains("-yalnizSite") { return [] }
        #endif
        return [.ben]
    }
}

struct BenSekmesi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(\.dynamicTypeSize) private var yaziBoyutu
    @Environment(\.scenePhase) private var evre
    @State private var depo = BenDeposu()
    @State private var ayarlar = false
    @State private var zayifOnce = false
    @State private var hizli = false
    @State private var kursSecili: Int?
    @State private var tanis: TanisKarti.Veri?

    var body: some View {
        ZStack {
            Color(tema.renkler.zemin).ignoresSafeArea()
            if ayarlar {
                BenAyarlari(depo: depo) { gecis { ayarlar = false } }
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            } else {
                ilerlemeGovdesi
                    .transition(.move(edge: .leading))
            }
        }
        .foregroundStyle(Color(tema.renkler.murekkep))
        .dynamicTypeSize(tema.ayar.yazi == "buyuk" ? max(yaziBoyutu, .xLarge) : yaziBoyutu)
        .tint(Color(tema.renkler.vurguAcik))
        // Sitede #/ayarlar'da sekme çubuğunun dişli dili gizli (HizliAyar.dilGorunur)
        .onChange(of: ayarlar, initial: true) { _, acik in kabuk.dilGizle(acik, sekme: .ben) }
        .onDisappear { kabuk.dilGizle(false, sekme: .ben) }
        .onChange(of: kabuk.yerliAdres[.ben], initial: true) { _, adres in
            if let adres {
                ayarlar = adres.hasPrefix("#/ayarlar")
                kabuk.adresIslendi(.ben)
            }
        }
        .onChange(of: kabuk.yenidenDokunma[.ben]) { _, _ in
            // Açık sekmeye yeniden dokunma: Ayarlar'dan Ben'e döner
            if ayarlar { gecis { ayarlar = false } }
        }
        .task(id: kabuk.secili == .ben) {
            if kabuk.secili == .ben {
                #if DEBUG
                if NoraSanatApp.arguman("-benSayfa") == "ayarlar" { ayarlar = true }
                #endif
                await depo.yenile()
            }
        }
        .onChange(of: evre) { _, yeni in
            if yeni == .active && kabuk.secili == .ben { Task { await depo.yenile() } }
        }
        .alert("Ben", isPresented: Binding(get: { depo.mesaj != nil }, set: { if !$0 { depo.mesaj = nil } })) {
            Button("Tamam") { depo.mesaj = nil }
        } message: { Text(depo.mesaj ?? "") }
    }

    private var hareketYok: Bool { tema.ayar.hareketAzaltilmis }

    private func gecis(_ islem: () -> Void) {
        withAnimation(hareketYok ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4), islem)
    }

    @ViewBuilder
    private var ilerlemeGovdesi: some View {
        if let il = depo.il, let k = depo.katalog {
            ilerleme(il, k)
        } else if depo.mesgul {
            ProgressView("İlerleme yükleniyor…")
                .font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Button("İlerlemeyi yeniden yükle") { Task { await depo.yenile() } }
                .buttonStyle(HapDugme())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: İlerleme

    private func ilerleme(_ il: Ilerleme, _ k: SiteKatalogu) -> some View {
        let p = BenPanosu(il, sanatcilar: k.sanatcilar, akimlar: k.akimlar, bugun: depo.bugun)
        let bilgi = KursBilgisi(katalog: k, il: il, adlar: depo.adlar)
        let acik = il.acikSanatcilar(k.sanatcilar)
        let hatalar = TurPlani.kur(.hatalar, sanatcilar: k.sanatcilar, ilerleme: il, bugun: depo.bugun,
                                   akimSira: k.akimSira, eseriVar: { _ in true }).kartlar.count
        return GeometryReader { g in
            ScrollViewReader { kaydir in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sahne(il, k, p, bilgi: bilgi, ust: g.safeAreaInsets.top).id("bas")
                        VStack(alignment: .leading, spacing: 0) {
                            CalismaTakvimi(il: il, katalog: k, bugun: depo.bugun)
                            CalismaEgrileri(il: il, acikIdler: acik.map(\.id), bugun: depo.bugun)
                            let n = il[alan: "koleksiyon"]?.dizi?.count ?? 0
                            BenSatiri(baslik: "Koleksiyonum", aciklama: n > 0 ? "\(n) eser işaretli" : "Sevdiğin eserleri işaretle",
                                      simge: .isaret) { git("#/koleksiyon", .galeri) }
                            Ayrac().padding(.bottom, 8)
                            BenSatiri(baslik: "Ayarlar", aciklama: "Tema, hareket, günlük kart, yedek", simge: .ayarlar) {
                                gecis { ayarlar = true }
                            }
                            Ayrac().padding(.bottom, 8)
                            SiradakiKonu(bilgi: bilgi) { isaretle([$0], true, kartla: true) }
                            BolumBasligi("Kurs konuları")
                            Text("Bir konuya dokun, bitirdiysen “işlendi” yap; o konunun sanatçıları açılır.")
                                .font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep2))
                                .padding(.top, -4).padding(.bottom, 10)
                            KursKitapligi(bilgi: bilgi, hizli: $hizli, secili: $kursSecili,
                                          isaretle: { isaretle($0, $1, kartla: $2) },
                                          sanatciAc: { git("#/sanatci/" + $0, .galeri) })
                                .id("kurs")
                            AkimBolumu(pano: p, il: il, katalog: k, zayifOnce: $zayifOnce) { git("#/pekistir/donem/" + $0, .calis) }
                                .id("akim")
                            ZayifBolumu(pano: p, il: il, katalog: k, hatalar: hatalar, kucuk: { bilgi.kucuk($0) },
                                        git: { git($0, $1) })
                        }
                        .padding(.horizontal, BenOlcu.yan)
                        .padding(.bottom, 32)
                    }
                    .disabled(depo.mesgul)
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)
                .refreshable { await depo.yenile() }
                .onChange(of: kabuk.yenidenDokunma[.ben]) { _, _ in
                    withAnimation(hareketYok ? nil : .easeOut(duration: 0.35)) { kaydir.scrollTo("bas", anchor: .top) }
                }
                #if DEBUG
                .task { await BenKarsilastirma.kaydir(kaydir) }
                #endif
            }
        }
        .overlay(alignment: .bottom) {
            if let t = tanis {
                TanisKarti(veri: t, katalog: k, kucuk: { bilgi.kucuk($0) }, tanis: {
                    tanis = nil
                    git("#/pekistir/konu/\(t.no)", .calis)
                }, kapat: { withAnimation { tanis = nil } })
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Sahne

    /// `.ilr-sahne`: kayan eser duvarı, üst ("Ben" ve dişli), "Kursun neresindesin" panosu
    private func sahne(_ il: Ilerleme, _ k: SiteKatalogu, _ p: BenPanosu, bilgi: KursBilgisi, ust: CGFloat) -> some View {
        let r = tema.renkler
        let acik = il.acikSanatcilar(k.sanatcilar)
        // `eserDuvari`: açık sanatçılar (kurs önce) en çok 12; 9'dan azsa yinelenir; hiç yoksa ilk 9 sanatçı soluk
        var l = acik.isEmpty ? Array(k.sanatcilar.prefix(9)) : acik
        l = Array((l.filter { $0.kaynak == "kurs" } + l.filter { $0.kaynak != "kurs" }).prefix(12))
        while !l.isEmpty && l.count < 9 { l = Array((l + l).prefix(9)) }
        let duvar = l.map { bilgi.kucuk($0.id) }
        // `.ilr-govde { margin-top: auto }`: pano 560 pt'lik sahnenin dibinde (alttan 22), üst (`.pk-ust`, 60) en üstte.
        // Z3n: sitede `padding-top: 120px` sonraki kuralla 16'ya iner (ölçüldü: 390×844, deste ve "Tekrar bekliyor"la
        // pano 155'te başlıyor). Uygulama 120'yi üstün altına boşluk olarak koyuyordu: pano uzunken sahne uzuyor, pano
        // sitedekinden ~30 pt aşağıda kalıyordu.
        return pano(il, k, p)
            .padding(.top, ust + 12 + 60)
            .padding(.horizontal, BenOlcu.yan)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, minHeight: 560 + ust, alignment: .bottomLeading)
            .overlay(alignment: .top) {
                BenUst(baslik: "Ben", geri: { kabuk.sec(.bugun) }) {
                    Button { gecis { ayarlar = true } } label: { BenIkon(simge: .ayarlar, boyut: 22, kalinlik: 1.4) }
                        .buttonStyle(YuvarlakDugme())
                        .accessibilityLabel("Ayarlar")
                }
                // `.pk-ust` 12'de başlar, 60 yüksek; geri düğmesi 22–66 (ortası 44). BenUst 52: 6 pt aşağıdan.
                .padding(.top, ust + 18)
                .padding(.horizontal, BenOlcu.yan)
            }
            .background {
            ZStack {
                Color(r.yuzey)
                EserDuvari(adresler: duvar, kilitli: acik.isEmpty, durgun: hareketYok || kabuk.secili != .ben || ayarlar)
                LinearGradient(stops: r.koyu ? [
                    .init(color: Color(r.zemin).opacity(0.92), location: 0), .init(color: Color(r.zemin).opacity(0.45), location: 0.22),
                    .init(color: Color(r.zemin).opacity(0.55), location: 0.45), .init(color: Color(r.zemin).opacity(0.96), location: 0.72),
                    .init(color: Color(r.zemin), location: 1),
                ] : [
                    .init(color: Color(r.zemin).opacity(0.8), location: 0), .init(color: Color(r.zemin).opacity(0), location: 0.2),
                    .init(color: Color(r.zemin).opacity(0), location: 0.62), .init(color: Color(r.zemin).opacity(0.55), location: 0.86),
                    .init(color: Color(r.zemin), location: 1),
                ], startPoint: .top, endPoint: .bottom)
            }
            .clipped()
        }
    }

    /// `.ilr-govde`: büyük serif sayı, ilerleme çizgisi, Sanatçı / Kalıcı / Tekrar sütunları, "Tekrar bekliyor" düğmesi
    private func pano(_ il: Ilerleme, _ k: SiteKatalogu, _ p: BenPanosu) -> some View {
        let r = tema.renkler
        let islenen = il.islenenKume
        let konular = k.kursKonulari
        let sayi = konular.filter { islenen.contains($0.no) }.count
        let yuzde = Double(sayi) / Double(max(1, konular.count))
        return VStack(alignment: .leading, spacing: 10) {
            Etiket("Kursun neresindesin")
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(sayi)").font(Yazi.serif(120, stil: .largeTitle)).tracking(-2.4)
                    .foregroundStyle(Color(r.murekkep))
                    .padding(.top, -46).padding(.bottom, -45)   // `line-height: .78`: rakamın üstü ve altı boş kalmasın
                VStack(alignment: .leading, spacing: 6) {
                    Text("/ \(konular.count)").font(Yazi.serif(28))
                    Etiket("konu işlendi", aralik: 0.18)
                }
                .padding(.bottom, 6)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(sayi) / \(konular.count) konu işlendi")
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(r.murekkep).opacity(r.koyu ? 0.14 : 0.12))
                    Capsule().fill(Color(r.vurguAcik)).frame(width: g.size.width * yuzde)
                        .shadow(color: r.koyu ? .clear : Color(r.vurguAcik), radius: 6)
                }
            }
            .frame(height: 3)
            .accessibilityLabel("%\(Int((yuzde * 100).rounded())) tamamlandı")
            HStack(alignment: .top, spacing: 0) {
                sutun("Sanatçı", "\(p.acik)", "/\(k.sanatcilar.count)", ilk: true)
                sutun("Kalıcı", "\(p.kalici)", p.acik > 0 ? " %\(Int((Double(p.kalici) * 100 / Double(p.acik)).rounded()))" : "")
                sutun("Tekrar", "\(p.vade)", "")
            }
            .padding(.top, 6)
            if p.vade > 0 {
                TabloDugme(baslik: "Tekrar bekliyor", alt: "karışık turu başlat", sayi: p.vade,
                           eserler: il.sonCalisilanlar.first.map { id in
                               // `eserKareleriDoldur`: yelpaze 0–2, zemin `zeminSirasi()` (3 + güne göre 0–6)
                               // Eseri olmayan sanatçıda yelpaze çıkmaz (sitede tuval dolmadan görünmez)
                               k.eserGorselAdresi(id, sira: 0, kotuler: il.kotuGorseller) == nil ? [] :
                               [0, 1, 2, 3 + (GunTarihi.gunNo(depo.bugun) ?? 0) % 7].map {
                                   k.eserGorselAdresi(id, sira: $0, genislik: 400, kotuler: il.kotuGorseller)
                               }
                           } ?? []) { git("#/pekistir/karisik", .calis) }
                    .padding(.top, 16)
            }
        }
        .padding(r.koyu ? 0 : 16)
        .background {
            if !r.koyu {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.notrKenar), lineWidth: 1))
                    .shadow(color: .black.opacity(0.2), radius: 18, y: 18)
            }
        }
    }

    /// `.ilr-sayilar > div`: etiket ve 32 px serif sayı; ilk sütun dışında solda çizgi
    private func sutun(_ ad: String, _ deger: String, _ ek: String, ilk: Bool = false) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 4) {
            Etiket(ad, boyut: 10.5, aralik: 0.18)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(deger).font(Yazi.serif(32)).foregroundStyle(Color(r.murekkep))
                if !ek.isEmpty { Text(ek).font(Yazi.sans(12, agirlik: 500, stil: .caption1)).foregroundStyle(Color(r.murekkep2)) }
            }
        }
        .padding(.leading, ilk ? 0 : 12).padding(.trailing, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) { if !ilk { Rectangle().fill(Color(r.kenar)).frame(width: 1) } }
        .accessibilityElement(children: .combine)
    }

    // MARK: Eylemler

    /// `konuIsaretle(nolar, islendi, { kartla })`: tek konu işlenip yeni sanatçı açıldıysa alttan "Tanış" kartı
    private func isaretle(_ nolar: [Int], _ islendi: Bool, kartla: Bool) {
        guard let k = depo.katalog, let once = depo.il else { return }
        let onceAcik = Set(once.acikSanatcilar(k.sanatcilar).map(\.id))
        withAnimation { tanis = nil }
        depo.degistir(bitti: { il in
            guard kartla, islendi, let no = nolar.first else { return }
            let yeni = il.acikSanatcilar(k.sanatcilar).map(\.id).filter { !onceAcik.contains($0) }
            if !yeni.isEmpty {
                withAnimation(hareketYok ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5)) {
                    tanis = TanisKarti.Veri(no: no, idler: yeni)
                }
            }
        }) {
            BenPanosu.isaretle(nolar, islendi: islendi, il: &$0)
        }
    }

    private func git(_ adres: String, _ sekme: Sekme) {
        kabuk.sec(sekme)
        Gezgin.shared.git(adres)
    }
}

// MARK: Eser duvarı

/// `eserDuvari`: üç sütun, -6° eğik, 1.12 büyütülmüş; sütunlar ters yönlere sonsuz süzülür (46 s + 9 s × sütun)
struct EserDuvari: View {
    let adresler: [URL?]
    let kilitli: Bool
    let durgun: Bool
    @Environment(\.accessibilityReduceMotion) private var azHareket

    var body: some View {
        GeometryReader { g in
            let w = g.size.width + 40, h = g.size.height + 80
            let kolon = (w - 16) / 3
            let kare = kolon * 4 / 3
            let sutunlar: [[URL?]] = (0..<3).map { c in stride(from: c, to: adresler.count, by: 3).map { adresler[$0] } }
            let dur = durgun || azHareket
            TimelineView(.animation(minimumInterval: 1 / 30, paused: dur)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        let l = sutunlar[i]
                        // `translateY(calc(-50% - 4px))`: şerit iki kez dizili; yarısı kadar kayınca başa döner
                        let yarim = CGFloat(l.count) * (kare + 8)
                        let sure = 46.0 + Double(i) * 9
                        let o = dur ? 0 : CGFloat(t.truncatingRemainder(dividingBy: sure) / sure)
                        let kay = -yarim * (i == 1 ? 1 - o : o) + (i == 1 ? -60 : 0)
                        VStack(spacing: 8) {
                            ForEach(0..<(l.count * 2), id: \.self) { j in
                                UzakGorsel(url: l[j % l.count])
                                    .grayscale(kilitli ? 1 : 0).colorMultiply(Color(white: kilitli ? 0.5 : 1))
                                    .frame(width: kolon, height: kare)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                        .offset(y: kay)
                        .frame(width: kolon, height: h, alignment: .top)
                        .clipped()
                    }
                }
                .frame(width: w, height: h)
            }
            .rotationEffect(.degrees(-6))
            .scaleEffect(1.12)
            .position(x: g.size.width / 2, y: g.size.height / 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: Tablo düğmesi

/// `tabloDugme`: üstünden üç eser yelpaze gibi yükselen buzlu cam düğme (başlık, alt yazı, kart sayısı)
struct TabloDugme: View {
    let baslik: String
    let alt: String
    let sayi: Int
    /// Sanatçının en bilinen eserleri: 0–2 yelpaze, 3 gövdenin zemini
    let eserler: [URL?]
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: eylem) {
            ZStack(alignment: .topLeading) {
                govde
                    .padding(.top, eserler.isEmpty ? 0 : 58)
                if !eserler.isEmpty {
                    ZStack(alignment: .bottom) {
                        ForEach(0..<min(3, eserler.count), id: \.self) { i in
                            let orta = i == 1
                            UzakGorsel(url: eserler[i])
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .padding(2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.92)))
                                .frame(width: orta ? 56 : 50, height: orta ? 72 : 64)
                                .shadow(color: .black.opacity(0.75), radius: 10, y: 10)
                                .rotationEffect(.degrees(Double(i - 1) * 13), anchor: UnitPoint(x: 0.5, y: 1.2))
                                .offset(x: CGFloat(i - 1) * 30)
                                .zIndex(orta ? 1 : 0)
                        }
                    }
                    .frame(width: 96, height: 66, alignment: .bottom)
                    .padding(.leading, 12)
                    .zIndex(-1)
                    .accessibilityHidden(true)
                }
            }
            .foregroundStyle(.white)
            .environment(\.colorScheme, .dark)
            .tint(Color(r.vurguAcik))
        }
        .buttonStyle(BasincBicimi(olcek: 0.985))
        .accessibilityLabel("\(baslik), \(alt), \(sayi) kart")
    }

    private var govde: some View {
        let r = tema.renkler
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(baslik).font(Yazi.serif(24, italik: true)).lineLimit(1)
                Text(alt).font(Yazi.sans(12, agirlik: 500, stil: .caption1)).foregroundStyle(.white.opacity(0.72)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 2) {
                Text("\(sayi)").font(Yazi.serif(28))
                Text("kart").font(Yazi.sans(10, agirlik: 600, stil: .caption2)).tracking(0.8).foregroundStyle(.white.opacity(0.65))
            }
            .padding(.leading, 12)
            .overlay(alignment: .leading) { Rectangle().fill(.white.opacity(0.2)).frame(width: 1) }
            BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.8)
        }
        .padding(.vertical, 10).padding(.leading, 18).padding(.trailing, 12)
        .frame(minHeight: 64)
        .background {
            ZStack {
                if eserler.count > 3 {
                    UzakGorsel(url: eserler[3]).blur(radius: 18).saturation(1.5)
                }
                Rectangle().fill(.ultraThinMaterial)
                Color(r.vurguKoyu).opacity(0.62)
                Color(red: 10 / 255, green: 8 / 255, blue: 6 / 255).opacity(0.55 * 0.38)
                LinearGradient(stops: [.init(color: .white.opacity(0.16), location: 0), .init(color: .white.opacity(0), location: 0.55)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#if DEBUG
/// CI karşılaştırması (C4b, C5): `-benKaydir kurs|akim|yedek|cevrimdisi` yerli ekranı ve sitenin aynı sayfasını aynı bölüme kaydırır.
/// Z3x: Ayarlar'da her grup (`AyarGrubu`: gorunus … gelismis) bir çapa; hatirlatma ve hakkinda yalnız yerli.
/// Sitenin görüntüsü `-yalnizSite` ile alınır; ikisi yan yana konur (.github/workflows/ios-derle.yml).
enum BenKarsilastirma {
    /// Bölüm → sitedeki karşılığı
    static let siteSecicileri = [
        "kurs": ".kurs-bolumleri",
        "akim": ".baslik-sira",
        "yedek": ".ayar:has([data-yedekle])",
        "cevrimdisi": "[data-test=\"devasa-indir\"]",
    ]

    static var bolum: String? { NoraSanatApp.arguman("-benKaydir") }

    /// CI bu dosyayı bekler: yerli ekran yüklendi (ve istendiyse kaydı)
    static let hazir = FileManager.default.temporaryDirectory.appendingPathComponent("ben-hazir")

    /// Yerli ekran: veriler ve görseller yüklenince bölümün başına
    @MainActor
    static func kaydir(_ kaydir: ScrollViewProxy) async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        if let b = bolum { kaydir.scrollTo(b, anchor: .top) }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        try? Data().write(to: hazir)
    }

    /// Site (`-yalnizSite`): yüklenince aynı bölüm görünene kadar dener
    @MainActor
    static func siteyiKaydir() {
        guard let b = bolum, let secici = siteSecicileri[b] else { return }
        Task {
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard Gezgin.shared.yuklendi, let w = Gezgin.shared.webView else { continue }
                let js = "(() => { const e = document.querySelector(\(JSONSerialization.metin(secici))); "
                    + "if (!e) return false; e.scrollIntoView({ block: 'start' }); return true; })()"
                if (try? await w.evaluateJavaScript(js)) as? Bool == true {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    _ = try? await w.evaluateJavaScript(js)
                    return
                }
            }
        }
    }
}

private extension JSONSerialization {
    static func metin(_ s: String) -> String {
        (try? data(withJSONObject: [s])).flatMap { String(data: $0, encoding: .utf8) }.map { String($0.dropFirst().dropLast()) } ?? "''"
    }
}
#endif

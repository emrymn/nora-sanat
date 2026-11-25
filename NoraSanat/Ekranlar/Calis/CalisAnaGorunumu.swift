// Z3u: Çalış ana ekranı Neon'un "Yön 4 · Bugünün oturumu" tasarımıyla (dal neon/calis-tasarim, PR #55:
// tasarim/calis/yon-4.html, BENIOKU.md "Yön 4"; kullanıcı olduğu gibi onayladı). Sıra: kenardan kenara kapak, bugünün dersi +
// günlük tekrar, hafıza ritmi (14 gün, 2×7), dönem yolu (+ yolculuk ufku), derinleşmek istersen (başka turlar).
// Davranış ve veriler sitenin kurallarından: js/ekranlar/ders.js (dersMenusu, bugunKarti, tekrarKarti, kilitliSatir),
// js/ekranlar/soruTurlari.js (soruTurlariHtml, hatalarSatiri), js/ekranlar/calisma.js (yukGrafigi) @ a866b86.
// Süreler, ritim yazıları ve akım yayı `CalisOturumu`'nda (Z3u, yeni, sitede yok).
import NoraCekirdek
import SwiftUI

/// Çalış ana ekranı (`#/pekistir`)
@MainActor
struct CalisAnaGorunumu: View {
    @Bindable var model: PekistirmeModeli
    /// Ekranın kaydırılacağı bölüm ("tekrar", "yuk", "turlar"); kaydırınca nil yapılır. CalisSekmesi Başka turlar
    /// adresinde "turlar" verir (eski Dersler / Başka turlar sekmelerinin yerine).
    @Binding var kaydirHedefi: String?
    let turBaslat: (PekistirmeKipi, Int?) -> Void
    let derseGit: (String) -> Void
    /// Dersin adımını açar (`dersAdresi(akim, adim)`: adım düğümleri ve devam düğmesi)
    let adimaGit: (String, DersAdimi) -> Void
    let donemlereGit: (_ salonlaraIn: Bool) -> Void
    let adreseGit: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var ustCubukAcik = false
    @State private var secilenGun = 0

    /// Tasarımın yan boşluğu (`.ekran-ic { padding: 0 20px }`)
    private let yan: CGFloat = 20

    var body: some View {
        let r = tema.renkler
        if let katalog = model.katalog, let il = model.ilerleme {
            GeometryReader { geo in
                let ust = geo.safeAreaInsets.top
                anaEkran(katalog: katalog, il: il, ust: ust, genislik: geo.size.width)
            }
        } else if model.hata == nil {
            ProgressView("Çalış hazırlanıyor…")
                .font(Yazi.sans(15))
                .foregroundStyle(Color(r.murekkep2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 12) {
                Text(model.hata ?? "")
                    .font(Yazi.okuma(16))
                    .foregroundStyle(Color(r.murekkep2))
                Button("Yeniden yükle") { Task { await model.yukle() } }
                    .buttonStyle(HapDugme())
            }
            .padding(BenOlcu.yan)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func anaEkran(katalog: SiteKatalogu, il: Ilerleme, ust: CGFloat, genislik: CGFloat) -> some View {
        let acikSanatcilar = il.acikSanatcilar(katalog.sanatcilar)
        let dersler = Self.dersler(model, katalog: katalog, il: il)
        let bugunDers = dersler.bugun
        let karisik = CalisKurallari.turBilgisi(sanatcilar: katalog.sanatcilar, ilerleme: il, bugun: model.bugun, karisik: true)
        let dersDakika = bugunDers.map(CalisOturumu.dersKalanDakika) ?? 0
        let oturumDakika = acikSanatcilar.isEmpty ? 0 : CalisOturumu.oturumDakikasi(dersDakika: dersDakika, tekrar: karisik)
        // Kapak: bugünün dersinin kapağı; ders yoksa (hepsi bitti) ilk açık dersin
        let kapakDersi = bugunDers ?? dersler.acik.first
        let kapakEser = kapakDersi.flatMap { CalisDersKurallari.dersKapakEseri($0, katalog: katalog, kotuler: il.kotuGorseller) }
        // Kaydırınca bölüm üst çubuğun altında kalmasın
        let payi = ust + 52

        return ZStack(alignment: .top) {
            ScrollViewReader { kaydir in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        kapakSahnesi(
                            eser: kapakEser,
                            akim: kapakDersi?.akim,
                            katalog: katalog,
                            dakika: oturumDakika,
                            konum: CalisKurallari.konumYazisi(islenen: il.islenenKume),
                            ust: ust,
                            genislik: genislik
                        )
                        .background(
                            GeometryReader { g in
                                Color.clear.preference(key: CalisBaslikKonumu.self, value: g.frame(in: .named("calis-kaydir")).maxY)
                            }
                        )

                        VStack(alignment: .leading, spacing: 0) {
                            if let tur = model.kayit, !tur.bitti {
                                CalisDevamKarti(model: model, tur: tur) {
                                    model.turAcik = true
                                } bitir: {
                                    Task { await model.yarimBitir() }
                                }
                                .padding(.bottom, 20)
                            }

                            if acikSanatcilar.isEmpty {
                                bosAcikKutu
                            } else {
                                if let b = bugunDers {
                                    bugununDersi(b, dakika: dersDakika, katalog: katalog, il: il)
                                    oturumBagi
                                } else if !dersler.acik.isEmpty {
                                    tumDerslerBittiKarti
                                        .padding(.bottom, 16)
                                }
                                tekrarDuragi(karisik, acikDersler: dersler.acik, katalog: katalog, il: il)
                                    .kaydirmaCapasi("tekrar", pay: payi)

                                hafizaRitmi(il: il, acikIdler: acikSanatcilar.map(\.id))
                                    .kaydirmaCapasi("yuk", pay: payi)

                                donemYolu(
                                    aciklar: dersler.acik,
                                    kilitliler: dersler.kilitli,
                                    bugunku: dersler.bugunkuAkim,
                                    katalog: katalog,
                                    il: il
                                )

                                baskaTurlar(katalog: katalog, il: il)
                                    .kaydirmaCapasi("turlar", pay: payi)
                            }
                        }
                        .padding(.horizontal, yan)
                        // `.ekran-ic { margin-top: -22px }`: içerik kapağın erimesine biner
                        .padding(.top, -22)
                        .padding(.bottom, 128)
                        .frame(maxWidth: 640, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    }
                }
                .coordinateSpace(name: "calis-kaydir")
                .ignoresSafeArea(.container, edges: .top)
                .onPreferenceChange(CalisBaslikKonumu.self) { maxY in
                    let acik = maxY < ust + 64
                    if acik != ustCubukAcik {
                        withAnimation(.easeOut(duration: 0.2)) { ustCubukAcik = acik }
                    }
                }
                .onChange(of: kaydirHedefi, initial: true) { _, hedef in
                    guard let hedef else { return }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeInOut(duration: 0.35)) {
                            kaydir.scrollTo(hedef, anchor: .top)
                        }
                        kaydirHedefi = nil
                    }
                }
                #if DEBUG
                .task { await CalisKarsilastirma.kaydir(kaydir) }
                #endif
            }

            if ustCubukAcik {
                calisUstCubugu
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    /// Açık ve kilitli dersler, bugünün dersi (`dersMenusu`). Z3m: Çalış'ın rengi bugünün dersinin kapağından
    /// (`kapaklariDoldur` → `ekranRengi(büyük kapak)`); CalisSekmesi bunu ekranın dışından okur.
    static func dersler(_ model: PekistirmeModeli, katalog: SiteKatalogu, il: Ilerleme)
        -> (acik: [DersBilgisi], kilitli: [AkimDurumu], bugun: DersBilgisi?, bugunkuAkim: String?) {
        let durumlar = Kilit.akimDurumlari(katalog.akimlar, katalog.sanatcilar, islenen: il.islenenKume)
        let sirali = durumlar.filter { CalisDersKurallari.dersBul(kaynak: model.dersKaynagi, akim: $0.ad) != nil }
        let acikDersler = sirali.filter(\.acik).compactMap {
            CalisDersKurallari.dersBilgisi(
                kaynak: model.dersKaynagi,
                yuruyus: model.yuruyus,
                katalog: katalog,
                ilerleme: il,
                akim: $0.ad
            )
        }
        let kilitliDersler = sirali.filter { !$0.acik }
        let bugunkuAkim = CalisDersKurallari.bugununDersi(
            acikAkimlar: acikDersler.map(\.akim),
            ilerleme: il,
            yolculukAkimi: CalisDersKurallari.yolculukAkimi(
                katalog: katalog,
                ilerleme: il,
                kaynak: model.dersKaynagi,
                yuruyus: model.yuruyus
            ),
            adimlar: { ad in acikDersler.first(where: { $0.akim == ad })?.adimlar ?? [.gor, .ogren, .ayirt] }
        )
        let bugunDers = acikDersler.first(where: { $0.akim == bugunkuAkim })
        return (acikDersler, kilitliDersler, bugunDers, bugunkuAkim)
    }

    // MARK: 1 · Kapak (`.sovale-sahne`): kenardan kenara, 16 sn yakınlaşma

    private func kapakSahnesi(
        eser: Eser?,
        akim: String?,
        katalog: SiteKatalogu,
        dakika: Int,
        konum: String,
        ust: CGFloat,
        genislik: CGFloat
    ) -> some View {
        let r = tema.renkler
        // Tasarımda 312 px, 46'sı durum çubuğu
        let yukseklik = 266 + ust
        return ZStack(alignment: .topLeading) {
            Button {
                if let akim { derseGit(akim) }
            } label: {
                ZStack {
                    KapakUstu.zemin
                    if let eser {
                        UzakGorsel(url: model.gorsel(eser, 960), icerik: .fill)
                            // Z3c: Çalış'ın zemini bu tablonun renklerinden
                            .task(id: eser.anahtar) { ZeminTablosu.shared.son[.calis] = model.gorsel(eser, 960) }
                            .frame(width: genislik, height: yukseklik)
                            .modifier(KapakYuruyusu())
                    }
                }
                .frame(width: genislik, height: yukseklik)
                .clipped()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(akim == nil)
            .accessibilityLabel(eser.map { "\($0.gorunenAd), \(katalog.bilinenAd($0.sid) ?? "")" } ?? "Bugünün dersi kapağı")
            .accessibilityHint(akim.map { "\($0) dersini açar" } ?? "")

            // Üstte hafif gölge (`::before`, 108 px) ve altta zemine erime (`::after`, 140 px)
            VStack(spacing: 0) {
                LinearGradient(colors: [KapakUstu.golge.opacity(0.62), KapakUstu.golge.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 62 + ust)
                Spacer(minLength: 0)
                LinearGradient(
                    stops: [
                        .init(color: Color(r.zemin).opacity(0), location: 0),
                        .init(color: Color(r.zemin).opacity(0.56), location: 0.54),
                        .init(color: Color(r.zemin).opacity(0.94), location: 0.86),
                        .init(color: Color(r.zemin), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
            }
            .allowsHitTesting(false)

            // `.sovale-ust`: "Çalış" ve süre/konum hapı
            HStack(alignment: .center, spacing: 10) {
                Text("Çalış")
                    .font(Yazi.serif(30, agirlik: 500, stil: .largeTitle))
                    .tracking(-0.3)
                    .foregroundStyle(KapakUstu.yazi)
                    .shadow(color: .black.opacity(0.45), radius: 7, y: 2)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if dakika > 0 || !konum.isEmpty {
                    (Text(dakika > 0 ? "~\(dakika) dk" : "").font(Yazi.sans(12.5, agirlik: 600)).foregroundColor(KapakUstu.altin)
                        + Text(dakika > 0 && !konum.isEmpty ? " · " : "")
                        + Text(konum))
                        .font(Yazi.sans(12.5, agirlik: 500, stil: .footnote))
                        .foregroundStyle(KapakUstu.yazi.opacity(0.94))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .background(Capsule().fill(KapakUstu.golge.opacity(0.5)))
                        .overlay(Capsule().strokeBorder(KapakUstu.yazi.opacity(0.22), lineWidth: 1))
                        .environment(\.colorScheme, .dark)
                        .accessibilityLabel([dakika > 0 ? "Bugünün oturumu yaklaşık \(dakika) dakika" : "", konum]
                            .filter { !$0.isEmpty }.joined(separator: ", "))
                        .accessibilityIdentifier("ders-konum")
                }
            }
            .padding(.horizontal, yan)
            .padding(.top, ust + 4)
            .frame(width: genislik, alignment: .leading)

            // Eser künyesi (`.odak-fisilti`): soluk nefes noktası, eser adı ve sanatçı
            if let eser {
                HStack(spacing: 7) {
                    NefesNoktasi()
                    Text([eser.gorunenAd, katalog.bilinenAd(eser.sid) ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(Yazi.okuma(12.5, italik: true, stil: .footnote))
                        .foregroundStyle(KapakUstu.yazi.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(.leading, 8)
                .padding(.trailing, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.ultraThinMaterial))
                .background(Capsule().fill(KapakUstu.golge.opacity(0.48)))
                .overlay(Capsule().strokeBorder(KapakUstu.yazi.opacity(0.16), lineWidth: 1))
                .environment(\.colorScheme, .dark)
                .padding(.leading, yan)
                .padding(.trailing, yan + 40)
                .frame(width: genislik, height: yukseklik - 46, alignment: .bottomLeading)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .frame(width: genislik, height: yukseklik)
    }

    private var calisUstCubugu: some View {
        let r = tema.renkler
        return Text("Çalış")
            .font(Yazi.serif(18, agirlik: 500))
            .foregroundStyle(Color(r.murekkep))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) { Rectangle().fill(Color(r.murekkep).opacity(0.1)).frame(height: 1) }
            .accessibilityHidden(true)
    }

    private var bosAcikKutu: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 8) {
            Text("Henüz açık sanatçı yok.")
                .font(Yazi.okuma(18))
                .foregroundStyle(Color(r.murekkep))
            Button {
                adreseGit("#/ilerleme")
            } label: {
                (Text("Ben").underline() + Text(" sayfasında işlediğin konuları işaretle."))
                    .font(Yazi.sans(14))
                    .foregroundStyle(Color(r.murekkep2))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
    }

    // MARK: 2 · Bugünün dersi (`.oturum-bas`, `.akis-izi`, `.davet-metin`, `.asil-dugme`)

    private func bugununDersi(_ b: DersBilgisi, dakika: Int, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let kunye = CalisDersKurallari.dersKunyesi(b)
        let dugme = CalisDersKurallari.devamDugmesi(b, sahne: true)
        let alt = CalisOturumu.devamAltYazisi(b)
        let harita = CalisDersKurallari.haritaBilgisi(
            b,
            katalog: katalog,
            ilerleme: il,
            kaynak: model.dersKaynagi,
            yuruyus: model.yuruyus
        )
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                UstYazi(dakika > 0 ? "Bugünün dersi · ~\(dakika) dk" : "Bugünün dersi")
                Spacer(minLength: 0)
                if !kunye.isEmpty {
                    Text(kunye)
                        .font(Yazi.sans(13, stil: .footnote))
                        .foregroundStyle(Color(r.murekkep2))
                        .lineLimit(1)
                }
            }
            Button {
                derseGit(b.akim)
            } label: {
                Text(b.akim)
                    .font(Yazi.serif(36, agirlik: 500, stil: .largeTitle))
                    .tracking(-0.54)
                    .cssSatir(.serif, 36, 37.1)
                    .foregroundStyle(Color(r.murekkep))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, 5)

            adimIzi(b)
                .padding(.top, 16)

            if b.durum.siradaki != .gor {
                dersDavetMetni(b, harita: harita)
                    .padding(.top, 10)
            }

            // Ekrandaki tek dolu düğme
            Button {
                if let a = dugme.adim { adimaGit(b.akim, a) } else { derseGit(b.akim) }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(dugme.baslik)
                            .font(Yazi.sans(15, agirlik: 600))
                        let altYazi = alt.isEmpty ? dugme.alt : alt
                        if !altYazi.isEmpty {
                            Text(altYazi)
                                .font(Yazi.sans(12.5, stil: .footnote))
                                .opacity(0.72)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .medium))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Color(r.zemin))
                .padding(.leading, 22)
                .padding(.trailing, 18)
                .padding(.vertical, 8)
                .frame(minHeight: 54)
                .background(Capsule().fill(Color(r.murekkep)))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .accessibilityIdentifier("ders-devam")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bugunun-dersi")
    }

    /// `.akis-izi`: Gör → Öğren → Ayırt et düğümleri tek hatta, sonda soluk Harita (BENIOKU: bilinçli ayrılış)
    private func adimIzi(_ b: DersBilgisi) -> some View {
        let r = tema.renkler
        let adimlar = b.durum.adimlar
        let sutun = adimlar.count + 1
        // Dolgu: sıradaki düğüme kadar, oradan bir sonraki düğüme doğru adımın ilerlemesinin yarısı kadar
        let siraIndeksi = adimlar.firstIndex { !$0.bitti } ?? adimlar.count
        let siraOrani = siraIndeksi < adimlar.count ? adimlar[siraIndeksi].i : 0
        let doluSonu = (Double(siraIndeksi) + 0.5 + min(1, max(0, siraOrani)) * 0.5) / Double(sutun)
        return HStack(alignment: .top, spacing: 0) {
            ForEach(adimlar, id: \.adim) { s in
                let simdi = !s.bitti && s.adim == b.durum.siradaki
                Button {
                    adimaGit(b.akim, s.adim)
                } label: {
                    adimDugumu(ad: s.ad, hal: s.bitti ? .bitti : (simdi ? .simdi : .bekliyor))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(s.ad): \(s.bitti ? "tamam" : (simdi ? "sırada" : "bekliyor"))")
            }
            if b.durum.bitti {
                Button { adreseGit("#/harita") } label: { adimDugumu(ad: "Harita", hal: .simdi, ufuk: true) }
                    .buttonStyle(.plain)
            } else {
                adimDugumu(ad: "Harita", hal: .bekliyor, ufuk: true)
                    .opacity(0.52)
                    .accessibilityLabel("Harita: ders bitince açılır")
            }
        }
        .background(alignment: .topLeading) {
            GeometryReader { g in
                let w = g.size.width
                let bas = w * 0.5 / CGFloat(sutun)
                let son = w * (CGFloat(sutun) - 0.5) / CGFloat(sutun)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(r.murekkep).opacity(0.14))
                        .frame(width: son - bas)
                    Capsule()
                        .fill(LinearGradient(
                            stops: [
                                .init(color: Color(r.dogru), location: 0),
                                .init(color: Color(r.dogru), location: 0.64),
                                .init(color: Color(r.pirinc), location: 1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, min(son, w * doluSonu) - bas))
                }
                .frame(height: 2)
                .offset(x: bas, y: 9)
            }
        }
    }

    private enum DugumHali { case bitti, simdi, bekliyor }

    private func adimDugumu(ad: String, hal: DugumHali, ufuk: Bool = false) -> some View {
        let r = tema.renkler
        return VStack(spacing: 6) {
            ZStack {
                if ufuk {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(r.zemin))
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color(hal == .simdi ? r.pirinc : r.murekkep).opacity(hal == .simdi ? 1 : 0.24),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2])))
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(45))
                } else {
                    switch hal {
                    case .bitti:
                        Circle().fill(Color(r.dogru))
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(Color(r.zemin))
                    case .simdi:
                        Circle().fill(Color(r.pirinc).opacity(0.2)).padding(-4)
                        Circle().fill(Color(r.zemin))
                        Circle().strokeBorder(Color(r.pirinc), lineWidth: 1.5)
                        Circle().fill(Color(r.pirinc)).frame(width: 6, height: 6)
                    case .bekliyor:
                        Circle().fill(Color(r.zemin))
                        Circle().strokeBorder(Color(r.murekkep).opacity(0.24), lineWidth: 1.5)
                    }
                }
            }
            .frame(width: 16, height: 16)
            Text(ad)
                .font(Yazi.sans(12.5, agirlik: hal == .simdi && !ufuk ? 600 : 400, stil: .footnote))
                .foregroundStyle(Color(hal == .simdi && !ufuk ? r.murekkep : r.murekkep2))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func dersDavetMetni(_ b: DersBilgisi, harita: (durak: Int, kilit: String)) -> some View {
        let r = tema.renkler
        let dv = CalisDersKurallari.davet(b, harita: harita)
        if let italik = dv.italikMadde, let son = dv.sonEk {
            (Text("Sıradaki özellik: ")
                + Text(italik).font(Yazi.okuma(17.5, italik: true))
                + Text(son))
                .font(Yazi.okuma(17.5))
                .cssSatir(.okuma, 17.5, 26.6)
                .foregroundStyle(Color(r.murekkep))
        } else if !dv.duz.isEmpty {
            Text(dv.duz)
                .font(Yazi.okuma(17.5))
                .cssSatir(.okuma, 17.5, 26.6)
                .foregroundStyle(Color(r.murekkep))
        }
    }

    /// `.oturum-bag`: dersi günlük tekrara bağlayan ince dikey iplik
    private var oturumBagi: some View {
        let r = tema.renkler
        return HStack(spacing: 10) {
            LinearGradient(colors: [Color(r.pirinc).opacity(0.55), Color(r.kenar)], startPoint: .top, endPoint: .bottom)
                .frame(width: 1, height: 18)
            Text("Ardından günlük tekrar")
                .font(Yazi.sans(12, agirlik: 500, stil: .caption1))
                .foregroundStyle(Color(r.murekkep3))
        }
        .padding(.leading, 26)
        .padding(.vertical, 10)
        .accessibilityHidden(true)
    }

    private var tumDerslerBittiKarti: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 8) {
            UstYazi("Bugünün dersi")
            Text("Açık derslerin hepsi tamam. Aşağıdan istediğini yeniden açabilir ya da günlük tekrarı yapabilirsin.")
                .font(Yazi.okuma(17.5))
                .cssSatir(.okuma, 17.5, 26.6)
                .foregroundStyle(Color(r.murekkep))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("bugunun-dersi")
    }

    // MARK: Günlük tekrar (`.tekrar-durak`)

    private func tekrarDuragi(_ tur: TurOzeti, acikDersler: [DersBilgisi], katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let kapaklar: [Eser] = Array(acikDersler.prefix(3).compactMap {
            CalisDersKurallari.dersKapakEseri($0, katalog: katalog, kotuler: il.kotuGorseller)
        })
        let alt = CalisKurallari.turAltYazisi(tur)
        return Button {
            turBaslat(.sanatci(.karisik), nil)
        } label: {
            HStack(spacing: 14) {
                if !kapaklar.isEmpty {
                    ZStack {
                        ForEach(Array(kapaklar.enumerated()), id: \.offset) { i, eser in
                            let aci: Double = i == 0 ? -8 : (i == 2 ? 8 : 0)
                            let x: CGFloat = i == 0 ? -5 : (i == 2 ? 5 : 0)
                            let y: CGFloat = i == 1 ? -1 : 2
                            UzakGorsel(url: model.gorsel(eser, 320), icerik: .fill)
                                .frame(width: 34, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .strokeBorder(Color(r.murekkep).opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.22), radius: 4.5, y: 4)
                                .rotationEffect(.degrees(aci))
                                .offset(x: x, y: y)
                                .zIndex(i == 1 ? 2 : Double(i == 2 ? 1 : 0))
                        }
                    }
                    .frame(width: 46, height: 54)
                    .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        UstYazi("Günlük tekrar")
                        (Text("\(tur.toplam)").font(Yazi.serif(22, agirlik: 500))
                            + Text(" kart").font(Yazi.serif(15.5)).foregroundColor(Color(r.murekkep2)))
                            .foregroundStyle(Color(r.murekkep))
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        if tur.toplam > 0 {
                            Text("Yaklaşık \(tur.yaklasikDakika) dk")
                        }
                        Text(alt)
                    }
                    .font(Yazi.sans(12.5, stil: .footnote))
                    .cssSatir(.sans, 12.5, 16.9)
                    .foregroundStyle(Color(r.murekkep2))
                    if tur.toplam > 0 {
                        // `.karisim-cizgi`: tekrar, pekiştirme, yeni oranı
                        GeometryReader { g in
                            let parcalar = [(tur.tekrar, r.pirinc), (tur.pekistirme, r.murekkep3), (tur.yeni, r.dogru)]
                                .filter { $0.0 > 0 }
                            let bosluk = CGFloat(max(0, parcalar.count - 1)) * 3
                            let toplam = CGFloat(max(1, parcalar.reduce(0) { $0 + $1.0 }))
                            HStack(spacing: 3) {
                                ForEach(Array(parcalar.enumerated()), id: \.offset) { _, p in
                                    Capsule().fill(Color(p.1))
                                        .frame(width: max(0, (g.size.width - bosluk) * CGFloat(p.0) / toplam))
                                }
                            }
                        }
                        .frame(height: 2.5)
                        .padding(.top, 6)
                        .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CamOk()
            }
            .padding(.vertical, 14)
            .padding(.leading, 16)
            .padding(.trailing, 14)
            .background(CamYuzey(yaricap: 22))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("karisik-dugme")
    }

    // MARK: 3 · Hafıza ritmi (14 gün, 2×7 boncuklu takvim; `gelecekYukOzeti`)

    private func hafizaRitmi(il: Ilerleme, acikIdler: [String]) -> some View {
        let r = tema.renkler
        let ozet = CalisKurallari.gelecekYukOzeti(skorlar: il.skorlar, idler: acikIdler, bugun: model.bugun)
        let gunler = CalisOturumu.ritim(gunluk: ozet.gunluk, bugun: model.bugun)
        let en = ozet.gunluk.max() ?? 0
        let secili: RitimGunu? = gunler.indices.contains(secilenGun) ? gunler[secilenGun] : gunler.first
        return VStack(alignment: .leading, spacing: 0) {
            bolumBasi(
                ust: "Önümüzdeki 14 gün",
                baslik: "Hafıza ritmin",
                sag: ozet.toplam > 0 ? CalisOturumu.ritimNotu(gunluk: ozet.gunluk) : [ozet.yazi]
            )
            VStack(alignment: .leading, spacing: 0) {
                haftaBlogu("Bu hafta", Array(gunler.prefix(7)), en: en)
                if gunler.count > 7 {
                    Rectangle().fill(Color(r.murekkep).opacity(0.1)).frame(height: 1)
                        .padding(.vertical, 14)
                    haftaBlogu("Gelecek hafta", Array(gunler.dropFirst(7).prefix(7)), en: en)
                }
                VStack(alignment: .leading, spacing: 6) {
                    if let g = secili {
                        let satir = CalisOturumu.ritimSatiri(g)
                        (Text(satir.vurgu).font(Yazi.okuma(15.5, agirlik: 500)).foregroundColor(Color(r.pirinc))
                            + Text(satir.metin))
                            .font(Yazi.okuma(15.5))
                            .cssSatir(.okuma, 15.5, 21.7)
                            .foregroundStyle(Color(r.murekkep))
                            .contentTransition(.opacity)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("Yarın seni bekleyen")
                            .foregroundStyle(Color(r.murekkep2))
                        Spacer(minLength: 8)
                        Text(CalisOturumu.yarinYazisi(gunluk: ozet.gunluk))
                            .font(Yazi.sans(12.5, agirlik: 600, stil: .footnote))
                            .foregroundStyle(Color(r.murekkep))
                    }
                    .font(Yazi.sans(12.5, stil: .footnote))
                    .accessibilityElement(children: .combine)
                }
                .padding(.top, 12)
                .overlay(alignment: .top) { Rectangle().fill(Color(r.murekkep).opacity(0.1)).frame(height: 1) }
                .padding(.top, 14)
            }
            .padding(.top, 18)
            .padding(.horizontal, 14)
            .padding(.bottom, 16)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Önümüzdeki 14 günün vadeli kart sayısı. \(ozet.yazi)")
        }
        .padding(.top, 40)
    }

    private func haftaBlogu(_ ad: String, _ gunler: [RitimGunu], en: Int) -> some View {
        let r = tema.renkler
        return VStack(spacing: 0) {
            HStack {
                Text(ad)
                Spacer(minLength: 8)
                Text(CalisOturumu.haftaAraligi(gunler))
            }
            .font(Yazi.sans(12, agirlik: 500, stil: .caption1))
            .foregroundStyle(Color(r.murekkep3))
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            HStack(spacing: 2) {
                ForEach(gunler) { g in
                    gunHucresi(g, en: en)
                }
            }
            .background(alignment: .top) {
                // `.hafta-dalga`: kart sayısını izleyen ince ritim eğrisi
                Canvas { c, boyut in
                    guard gunler.count > 1 else { return }
                    let w = Double(boyut.width), ust = max(1, Double(en))
                    let nokta = gunler.enumerated().map { i, g in
                        CGPoint(x: Double(i) / Double(gunler.count - 1) * w, y: 30 - Double(g.n) / ust * 24)
                    }
                    var p = Path()
                    p.move(to: nokta[0])
                    for k in 1..<nokta.count {
                        let a = nokta[k - 1], b = nokta[k], mx = (a.x + b.x) / 2
                        p.addCurve(to: b, control1: CGPoint(x: mx, y: a.y), control2: CGPoint(x: mx, y: b.y))
                    }
                    c.stroke(p, with: .color(Color(r.pirinc).opacity(0.22)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                }
                .frame(height: 36)
                .padding(.horizontal, 10 + 12)
                .padding(.top, 14)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }

    private func gunHucresi(_ g: RitimGunu, en: Int) -> some View {
        let r = tema.renkler
        let bugun = g.sira == 0
        let secili = g.sira == secilenGun
        let cap = CalisOturumu.boncukCapi(g.n, en: en)
        return Button {
            withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.15)) { secilenGun = g.sira }
        } label: {
            VStack(spacing: 0) {
                Text(g.harf)
                    .font(Yazi.sans(10.5, agirlik: bugun ? 700 : 500, stil: .caption2))
                    .foregroundStyle(Color(bugun ? r.pirinc : r.murekkep3))
                Spacer(minLength: 2)
                ZStack {
                    if g.dinlenme {
                        Circle()
                            .strokeBorder(Color(r.murekkep).opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                            .frame(width: cap, height: cap)
                    } else if bugun {
                        Circle().fill(Color(r.pirinc).opacity(0.22)).frame(width: cap + 8, height: cap + 8)
                        Circle().fill(Color(r.pirinc)).frame(width: cap, height: cap)
                        Text("\(g.n)")
                            .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                            .foregroundStyle(Color(r.pirincYazi))
                    } else {
                        Circle().fill(Color(r.murekkep).opacity(r.koyu ? 0.22 : 0.14)).frame(width: cap, height: cap)
                        Circle().strokeBorder(Color(r.murekkep).opacity(0.14), lineWidth: 1).frame(width: cap, height: cap)
                        Text("\(g.n)")
                            .font(Yazi.sans(11, agirlik: 600, stil: .caption2))
                            .foregroundStyle(Color(r.murekkep))
                    }
                }
                .frame(width: 34, height: 34)
                .minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                Text("\(g.gun)")
                    .font(Yazi.sans(10, agirlik: bugun ? 600 : 400, stil: .caption2))
                    .foregroundStyle(Color(bugun ? r.murekkep : r.soluk))
            }
            .padding(.top, 4)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(secili ? Color(r.pirinc).opacity(0.11) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(g.ad): \(g.n > 0 ? "\(g.n) kart" : "dinlenme günü")")
        .accessibilityAddTraits(secili ? .isSelected : [])
    }

    // MARK: 4 · Dönem yolu (`.omurga`) ve yolculuk ufku (`.yolculuk-ufuk`)

    @ViewBuilder
    private func donemYolu(
        aciklar: [DersBilgisi],
        kilitliler: [AkimDurumu],
        bugunku: String?,
        katalog: SiteKatalogu,
        il: Ilerleme
    ) -> some View {
        let r = tema.renkler
        VStack(alignment: .leading, spacing: 0) {
            bolumBasi(
                ust: "Dersler · \(aciklar.count) açık",
                baslik: "Dönem yolun",
                sag: aciklar.isEmpty ? [] : [CalisOturumu.yolOzeti(aciklar)]
            )
            if aciklar.isEmpty {
                Text(model.dersKaynagi == nil
                     ? "Dersler yüklenemedi; bağlantı gelince yeniden dene."
                     : "Açık dönemlerin dersi henüz yok.")
                    .font(Yazi.sans(14))
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.vertical, 8)
            } else {
                let ilkKilitli = kilitliler.first
                let haller: [YolHali] = aciklar.map { b in
                    b.durum.bitti ? .bitti : (b.akim == bugunku ? .bugun : .sirada)
                } + (ilkKilitli == nil ? [] : [.kilitli])
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(aciklar.enumerated()), id: \.element.akim) { i, b in
                        yolSatiri(
                            hal: haller[i],
                            ustRenk: i > 0 ? yolRengi(haller[i]) : nil,
                            altRenk: i + 1 < haller.count ? yolRengi(haller[i + 1]) : nil
                        ) {
                            dersSatiri(b, hal: haller[i], katalog: katalog, il: il)
                        }
                    }
                    if let k = ilkKilitli {
                        yolSatiri(hal: .kilitli, ustRenk: yolRengi(.kilitli), altRenk: nil) {
                            kilitliSatiri(k, islenen: il.islenenKume)
                        }
                    }
                }
                if kilitliler.count > 1 {
                    Text("\(kilitliler.count - 1) ders daha, konular işlendikçe açılacak.")
                        .font(Yazi.sans(12.5, stil: .footnote))
                        .foregroundStyle(Color(r.murekkep3))
                        .padding(.leading, 38)
                        .padding(.top, 10)
                }
            }

            yolculukUfku(
                yay: CalisOturumu.akimYayi(aciklar: aciklar.map(\.akim), kilitliler: kilitliler.map(\.ad), bugunku: bugunku)
            )
        }
        .padding(.top, 40)
    }

    private enum YolHali { case bitti, bugun, sirada, kilitli }

    /// Omurganın bir satıra gelen parçasının rengi: bitmiş derse yeşil, bugüne pirinç, gerisi ince kenar
    private func yolRengi(_ hal: YolHali) -> Color {
        let r = tema.renkler
        switch hal {
        case .bitti: return Color(r.dogru)
        case .bugun: return Color(r.pirinc)
        case .sirada: return Color(r.kenar)
        case .kilitli: return Color(r.murekkep).opacity(0.1)
        }
    }

    private func yolSatiri<Icerik: View>(
        hal: YolHali,
        ustRenk: Color?,
        altRenk: Color?,
        @ViewBuilder icerik: () -> Icerik
    ) -> some View {
        icerik()
            .padding(.leading, 38)
            .background(alignment: .leading) {
                VStack(spacing: 0) {
                    (ustRenk ?? .clear).frame(width: 1.5).frame(maxHeight: .infinity).padding(.top, -5)
                    (altRenk ?? .clear).frame(width: 1.5).frame(maxHeight: .infinity).padding(.bottom, -5)
                }
                .overlay { yolMuhru(hal) }
                .frame(width: 32)
                .accessibilityHidden(true)
            }
    }

    @ViewBuilder
    private func yolMuhru(_ hal: YolHali) -> some View {
        let r = tema.renkler
        ZStack {
            switch hal {
            case .bitti:
                Circle().fill(Color(r.dogru))
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(Color(r.zemin))
            case .bugun:
                Circle().fill(Color(r.pirinc).opacity(0.22)).padding(-4)
                Circle().fill(Color(r.zemin))
                Circle().strokeBorder(Color(r.pirinc), lineWidth: 1.5)
                Circle().fill(Color(r.pirinc)).frame(width: 6, height: 6)
            case .sirada:
                Circle().fill(Color(r.zemin))
                Circle().strokeBorder(Color(r.kenar), lineWidth: 1.5)
            case .kilitli:
                Circle().fill(Color(r.zemin))
                Circle().strokeBorder(Color(r.kenar), style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2]))
                BenIkon(simge: .kilit, boyut: 9, kalinlik: 2)
                    .foregroundStyle(Color(r.murekkep3))
            }
        }
        .frame(width: 16, height: 16)
    }

    private func dersSatiri(_ b: DersBilgisi, hal: YolHali, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let kapak = CalisDersKurallari.dersKapakEseri(b, katalog: katalog, kotuler: il.kotuGorseller)
        let etiket = hal == .bugun ? "Bugün" : b.hal.etiket
        let etiketRengi = hal == .bitti ? r.dogru : (hal == .bugun ? r.pirinc : r.murekkep3)
        let bitti = hal == .bitti
        return Button {
            derseGit(b.akim)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(b.akim)
                            .font(Yazi.serif(19, agirlik: 500))
                            .tracking(-0.19)
                            .foregroundStyle(Color(r.murekkep))
                            .lineLimit(1)
                            .layoutPriority(1)
                        Text(etiket)
                            .font(Yazi.sans(12, agirlik: 600, stil: .caption1))
                            .foregroundStyle(Color(etiketRengi))
                            .lineLimit(1)
                    }
                    HStack(spacing: 10) {
                        Text(CalisOturumu.yolAltYazisi(b))
                            .font(Yazi.sans(12.5, stil: .footnote))
                            .foregroundStyle(Color(r.murekkep2))
                            .lineLimit(1)
                        if !bitti {
                            miniCizgiler(b, bugun: hal == .bugun)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Color(r.yuzey)
                    if let kapak {
                        UzakGorsel(url: model.gorsel(kapak, 160), icerik: .fill)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(r.murekkep).opacity(0.1), lineWidth: 1)
                )
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, bitti ? 10 : (hal == .bugun ? 14 : 12))
            .frame(minHeight: bitti ? 54 : 62)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(bitti ? Color.clear : Color(r.yuzey))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        bitti ? Color(r.murekkep).opacity(0.1) : (hal == .bugun ? Color(r.pirinc).opacity(0.45) : Color(r.kenar)),
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    /// `.mini-cizgiler`: adımların üç ince çizgisi (biten yeşil, süren pirinç)
    private func miniCizgiler(_ b: DersBilgisi, bugun: Bool) -> some View {
        let r = tema.renkler
        return HStack(spacing: 3) {
            ForEach(b.durum.adimlar, id: \.adim) { s in
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(s.bitti ? Color(r.dogru) : Color(r.murekkep).opacity(0.14))
                        if !s.bitti && s.i > 0 {
                            Capsule().fill(Color(r.pirinc))
                                .frame(width: g.size.width * min(1, max(0.06, s.i)))
                        }
                    }
                }
                .frame(height: 3)
            }
        }
        .frame(width: 56)
        .accessibilityHidden(true)
    }

    private func kilitliSatiri(_ a: AkimDurumu, islenen: Set<Int>) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 3) {
            Text(a.ad)
                .font(Yazi.sans(15.5, agirlik: 500))
                .foregroundStyle(Color(r.murekkep2))
            Text(CalisOturumu.kilitliAltYazisi(a, islenen: islenen))
                .font(Yazi.sans(12.5, stil: .footnote))
                .foregroundStyle(Color(r.murekkep2))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(r.kenar), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("ders-kilitli")
    }

    private func yolculukUfku(yay: AkimYayi?) -> some View {
        let r = tema.renkler
        return Button {
            adreseGit("#/harita")
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bir sonraki durağın seni bekliyor.")
                            .font(Yazi.sans(15, agirlik: 600))
                            .foregroundStyle(Color(r.murekkep))
                        Text("Yolculuğunu haritada gör · ders bitince sınav açılır")
                            .font(Yazi.sans(13, stil: .footnote))
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.7)
                        .foregroundStyle(Color(r.murekkep2))
                }
                if let yay {
                    AkimYayiCizimi(yay: yay)
                        .frame(height: 36)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(CamYuzey(yaricap: 22))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .padding(.top, 26)
    }

    // MARK: 5 · Derinleşmek istersen (`.hatalar-serit`, `.tepsi-izgara`)

    private func baskaTurlar(katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let hatalar = CalisKurallari.hatalarBilgisi(sanatcilar: katalog.sanatcilar, ilerleme: il, bugun: model.bugun)
        let bolumSayisi = CalisKurallari.bolumTuruKartSayisi(katalog: katalog, ilerleme: il)
        let kars = CalisKurallari.karsilastirSecimi(katalog: katalog, ilerleme: il)
        let sutunlar = [
            GridItem(.flexible(), spacing: 10, alignment: .top),
            GridItem(.flexible(), spacing: 10, alignment: .top),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            bolumBasi(ust: "Başka turlar", baslik: "Derinleşmek istersen", sag: ["Aynı eserlere", "farklı sorularla"])

            if !hatalar.idler.isEmpty {
                Button {
                    turBaslat(.sanatci(.hatalar), nil)
                } label: {
                    HStack(spacing: 14) {
                        Text("\(hatalar.idler.count)")
                            .font(Yazi.serif(17, agirlik: 500))
                            .foregroundStyle(Color(r.pirinc))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(Color(r.pirinc).opacity(0.45), lineWidth: 1))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hatalarım")
                                .font(Yazi.serif(18, agirlik: 500))
                                .tracking(-0.18)
                                .foregroundStyle(Color(r.murekkep))
                            Text("~\(TurOzeti(toplam: hatalar.idler.count).yaklasikDakika) dk · \(hatalar.altYazi)")
                                .font(Yazi.sans(12.5, stil: .footnote))
                                .foregroundStyle(Color(r.murekkep2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.7)
                            .foregroundStyle(Color(r.murekkep3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 60)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(r.yuzey)))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("hatalar-satir")
                .padding(.bottom, 10)
            }

            LazyVGrid(columns: sutunlar, spacing: 10) {
                tepsiKarti(
                    baslik: "Döneme göre",
                    alt: "Salon salon çalış",
                    ust: .isaretleme(#"<path d="M5.5 4.5h13M7 4.5V7h10V4.5M9 7v10M12 7v10M15 7v10M7 19.5V17h10v2.5M5.5 19.5h13"/>"#)
                ) {
                    donemlereGit(true)
                }
                .accessibilityIdentifier("tur-donem")

                if bolumSayisi > 0 {
                    tepsiKarti(baslik: "Bölüm turu", alt: "Hangi bölümde?", ust: .sayi(bolumSayisi)) {
                        turBaslat(.kursBolumu, nil)
                    }
                    .accessibilityIdentifier("tur-bolum")
                }

                tepsiKarti(
                    baslik: "Konu turu",
                    alt: "İncil, mitoloji, tarih",
                    ust: .isaretleme(#"<rect x="5" y="3" width="14" height="18" rx="1.5"/><circle cx="12" cy="10" r="2.3"/><path d="M8 18c.6-2.2 2.2-3.3 4-3.3s3.4 1.1 4 3.3"/>"#)
                ) {
                    turBaslat(.ikonografi, nil)
                }
                .accessibilityIdentifier("tur-ikonografi")

                if let kars {
                    tepsiKarti(baslik: "Karşılaştır", alt: kars.alt, ust: .isaretleme(BenSimge.karsilastir.isaretleme)) {
                        adreseGit(kars.adres)
                    }
                    .accessibilityIdentifier("tur-karsilastir")
                }
            }
        }
        .padding(.top, 40)
    }

    private enum TepsiUstu {
        case sayi(Int)
        case isaretleme(String)
    }

    private func tepsiKarti(baslik: String, alt: String, ust: TepsiUstu, eylem: @escaping () -> Void) -> some View {
        let r = tema.renkler
        return Button(action: eylem) {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    switch ust {
                    case .sayi(let n):
                        Text("\(n)").font(Yazi.serif(17, agirlik: 500))
                    case .isaretleme(let svg):
                        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: svg))
                            .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                            .frame(width: 18, height: 18)
                    }
                }
                .foregroundStyle(Color(r.pirinc))
                .frame(height: 20)
                .accessibilityHidden(true)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(baslik)
                        .font(Yazi.serif(18, agirlik: 500))
                        .tracking(-0.18)
                        .foregroundStyle(Color(r.murekkep))
                        .multilineTextAlignment(.leading)
                    Text(alt)
                        .font(Yazi.sans(12.5, stil: .footnote))
                        .foregroundStyle(Color(r.murekkep2))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: Ortak

    /// `.bolum-bas`: solda pirinç üst yazı ve Bodoni başlık, sağda soluk not
    private func bolumBasi(ust: String, baslik: String, sag: [String]) -> some View {
        let r = tema.renkler
        return HStack(alignment: .lastTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                UstYazi(ust)
                Text(baslik)
                    .font(Yazi.serif(26, agirlik: 500, stil: .title1))
                    .tracking(-0.26)
                    .cssSatir(.serif, 26, 29.1)
                    .foregroundStyle(Color(r.murekkep))
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            if !sag.isEmpty {
                Text(sag.joined(separator: "\n"))
                    .font(Yazi.sans(13, stil: .footnote))
                    .cssSatir(.sans, 13, 16.9)
                    .foregroundStyle(Color(r.murekkep2))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.bottom, 14)
    }
}

// MARK: Ortak Çalış bileşenleri

private struct CalisBaslikKonumu: PreferenceKey {
    static let defaultValue: CGFloat = 1000
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Kapağın üstündeki yazı ve haplar: tablonun üstünde durdukları için iki temada da aynı (tasarımdaki sabitler;
/// eski kapak kartı da böyleydi). Tema renkleri değil.
private enum KapakUstu {
    /// `#141210`: görsel yüklenene kadar
    static let zemin = Color(red: 20 / 255, green: 18 / 255, blue: 16 / 255)
    /// `rgba(16, 15, 14, …)` / `rgba(18, 17, 16, …)`
    static let golge = Color(red: 17 / 255, green: 16 / 255, blue: 15 / 255)
    /// `#f4f0e8`
    static let yazi = Color(red: 244 / 255, green: 240 / 255, blue: 232 / 255)
    /// `#ecd08f`
    static let altin = Color(red: 236 / 255, green: 208 / 255, blue: 143 / 255)
}

/// `.ust-yazi`: 600 13px, pirinç, cümle düzeninde (büyük harf yok)
private struct UstYazi: View {
    let metin: String
    @Environment(TemaDeposu.self) private var tema
    init(_ metin: String) { self.metin = metin }
    var body: some View {
        Text(metin)
            .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
            .foregroundStyle(Color(tema.renkler.pirinc))
            .lineLimit(1)
    }
}

/// `--surface-cam` + bulanıklık + `--border`
private struct CamYuzey: View {
    let yaricap: CGFloat
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        let r = tema.renkler
        let sekil = RoundedRectangle(cornerRadius: yaricap, style: .continuous)
        sekil.fill(.ultraThinMaterial)
            .overlay(sekil.fill(Color(r.yuzey).opacity(r.koyu ? 0.76 : 0.86)))
            .overlay(sekil.strokeBorder(Color(r.kenar), lineWidth: 1))
    }
}

/// `.cam-ok`: 44'lük yuvarlak ok (dolu düğme değil)
private struct CamOk: View {
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        let r = tema.renkler
        ZStack {
            Circle().fill(Color(r.ustDugme))
            Circle().strokeBorder(Color(r.kenar), lineWidth: 1)
            Image(systemName: "arrow.right")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(r.murekkep))
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}

/// `.nefes-nokta`: 4 sn'de bir yavaşça büyüyüp sönen altın nokta; hareket azaltılmışsa durur
private struct NefesNoktasi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var acik = false
    var body: some View {
        Circle()
            .fill(KapakUstu.altin)
            .frame(width: 6, height: 6)
            .background(Circle().fill(KapakUstu.altin.opacity(0.28)).padding(-3))
            .scaleEffect(acik ? 1.15 : 0.9)
            .opacity(acik ? 1 : 0.55)
            .onAppear {
                guard !hareketAz, !tema.ayar.hareketAzaltilmis else { return }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { acik = true }
            }
    }
}

/// Yolculuk ufkundaki önceki → bugünkü → sonraki akım yayı (`.ufuk-harita`, 314 × 36)
private struct AkimYayiCizimi: View {
    let yay: AkimYayi
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Canvas { c, boyut in
            let k = boyut.width / 314
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y) }
            var ilk = Path()
            ilk.move(to: p(18, 18))
            ilk.addCurve(to: p(157, 18), control1: p(72, 4), control2: p(108, 32))
            var ikinci = Path()
            ikinci.move(to: p(157, 18))
            ikinci.addCurve(to: p(296, 16), control1: p(206, 4), control2: p(242, 30))
            let kesik = StrokeStyle(lineWidth: 1.5, dash: [3, 4])
            if yay.onceki != nil {
                c.stroke(ilk, with: .color(Color(r.dogru)), lineWidth: 1.6)
                c.fill(Path(ellipseIn: CGRect(x: 18 * k - 4.5, y: 13.5, width: 9, height: 9)), with: .color(Color(r.dogru)))
            }
            if yay.sonraki != nil {
                c.stroke(ikinci, with: .color(Color(r.kenar)), style: kesik)
                let halka = Path(ellipseIn: CGRect(x: 296 * k - 4, y: 12, width: 8, height: 8))
                c.fill(halka, with: .color(Color(r.yuzey)))
                c.stroke(halka, with: .color(Color(r.murekkep3)),
                         style: StrokeStyle(lineWidth: 1.5, dash: yay.sonrakiKilitli ? [2, 2] : []))
            }
            c.fill(Path(ellipseIn: CGRect(x: 157 * k - 6, y: 12, width: 12, height: 12)), with: .color(Color(r.pirinc).opacity(0.22)))
            c.fill(Path(ellipseIn: CGRect(x: 157 * k - 4, y: 14, width: 8, height: 8)), with: .color(Color(r.pirinc)))
        }
        .overlay(alignment: .bottom) {
            // Adlar: yay noktalarının altında (Canvas'ta değil, Dinamik Yazı'yla büyüyebilsin diye üç sütun)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(yay.onceki ?? "")
                    .foregroundStyle(Color(tema.renkler.murekkep3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(yay.bugunku)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(tema.renkler.pirinc))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .layoutPriority(1)
                Text(yay.sonraki ?? "")
                    .foregroundStyle(Color(tema.renkler.soluk))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(Yazi.sans(9.5, stil: .caption2))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .offset(y: 8)
        }
    }
}

private extension View {
    /// `ScrollViewReader` çapası: `scrollTo(ad, anchor: .top)` bölümü üst çubuğun (ve durum çubuğunun) altına getirir.
    func kaydirmaCapasi(_ ad: String, pay: CGFloat) -> some View {
        overlay(alignment: .top) {
            Color.clear
                .frame(height: 1)
                .alignmentGuide(.top) { $0[.top] + pay }
                .id(ad)
                .accessibilityHidden(true)
        }
    }
}

/// `.devam-kart`: Yarım kalan tur kartı (`js/ekranlar/pekistir.js` `devamKarti`)
struct CalisDevamKarti: View {
    let model: PekistirmeModeli
    let tur: TurKaydi
    let devamEt: () -> Void
    let bitir: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let toplam = max(1, tur.oturum.kuyruk.count)
        let sira = min(tur.gorunenKonum + 1, toplam)
        let oran = Double(sira) / Double(toplam)
        let resim = tur.sonResim ?? tur.kart?.resim
        ZStack(alignment: .topTrailing) {
            Button(action: devamEt) {
                HStack(spacing: 14) {
                    if let resim {
                        UzakGorsel(url: model.gorsel(resim.eser, 320), icerik: .fill)
                            .frame(width: 58, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.45), radius: 7, y: 4)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YARIM KALAN TUR")
                            .font(Yazi.sans(11, agirlik: 600, stil: .caption2))
                            .tracking(2.2)
                            .foregroundStyle(Color(r.vurguAcik))
                        Text("\(CevapYazilari.kipAdi(tur.kip)) · \(sira) / \(toplam)")
                            .font(Yazi.okuma(19, agirlik: 500))
                            .foregroundStyle(Color(r.murekkep))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle()
                            .fill(Color(r.vurgu).opacity(0.10))
                        Circle()
                            .stroke(Color(r.vurgu).opacity(0.18), lineWidth: 2)
                            .padding(2)
                        Circle()
                            .trim(from: 0, to: oran)
                            .stroke(Color(r.vurguAcik), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(2)
                        BenIkon(simge: .ileri, boyut: 18, kalinlik: 2.0)
                            .foregroundStyle(Color(r.vurguAcik))
                    }
                    .frame(width: 56, height: 56)
                }
                .padding(.vertical, 12)
                .padding(.leading, 12)
                .padding(.trailing, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(r.yuzey))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(r.vurgu).opacity(0.18), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(r.vurgu).opacity(0.32), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("devam-kart")

            Button(action: bitir) {
                BenIkon(simge: .kapat, boyut: 16, kalinlik: 1.6)
                    .foregroundStyle(Color(r.murekkep2))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .padding(.trailing, 72)
            .accessibilityLabel("Yarım kalan turu sil")
            .accessibilityIdentifier("devam-bitir")
        }
    }
}

/// Sitenin İş 191'i (css/app.css `kapak-yuru`): Bugünün dersi kapağında resim yavaşça bir ayrıntıya yakınlaşır, geri
/// döner, öbür ayrıntıya yakınlaşır. 16 sn döngü; duruşlar 0–8 %, 22–38 % (translate(−10 %, 6 %) scale(1,8)),
/// 50–58 %, 72–90 % (translate(14 %, −4 %) scale(1,9)); eğri cubic-bezier(0.65, 0, 0.35, 1), merkez 50 % 40 %.
/// Z3j: Swift'e geçişte eksik kalmıştı. Hareket azaltma ya da Ayarlar'da hareket kapalıysa durur.
private struct KapakYuruyusu: ViewModifier {
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz

    struct Kare {
        var olcek: CGFloat = 1
        var x: CGFloat = 0
        var y: CGFloat = 0
    }

    func body(content: Content) -> some View {
        if hareketAz || tema.ayar.hareketAzaltilmis {
            content
        } else {
            content.keyframeAnimator(initialValue: Kare(), repeating: true) { c, k in
                c.scaleEffect(k.olcek, anchor: UnitPoint(x: 0.5, y: 0.4))
                    .visualEffect { v, g in v.offset(x: k.x * g.size.width, y: k.y * g.size.height) }
            } keyframes: { _ in
                KeyframeTrack(\.olcek) { Self.iz(1, 1.8, 1, 1.9) }
                KeyframeTrack(\.x) { Self.iz(0, -0.10, 0, 0.14) }
                KeyframeTrack(\.y) { Self.iz(0, 0.06, 0, -0.04) }
            }
        }
    }

    /// 16 sn: dur 1,28 · git 2,24 · dur 2,56 · dön 1,92 · dur 1,28 · git 2,24 · dur 2,88 · dön 1,6
    @KeyframeTrackContentBuilder<CGFloat>
    static func iz(_ bas: CGFloat, _ a: CGFloat, _ orta: CGFloat, _ b: CGFloat) -> some KeyframeTrackContent<CGFloat> {
        let egri = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.65, y: 0), endControlPoint: UnitPoint(x: 0.35, y: 1))
        LinearKeyframe(bas, duration: 1.28)
        LinearKeyframe(a, duration: 2.24, timingCurve: egri)
        LinearKeyframe(a, duration: 2.56)
        LinearKeyframe(orta, duration: 1.92, timingCurve: egri)
        LinearKeyframe(orta, duration: 1.28)
        LinearKeyframe(b, duration: 2.24, timingCurve: egri)
        LinearKeyframe(b, duration: 2.88)
        LinearKeyframe(bas, duration: 1.6, timingCurve: egri)
    }
}

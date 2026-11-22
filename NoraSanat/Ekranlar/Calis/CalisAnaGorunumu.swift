// Kaynak: sanat-atlasi js/ekranlar/ders.js (dersMenusu, bugunKarti, tekrarKarti, dersSatiri, kilitliSatir, dersSayfasi),
// js/ekranlar/soruTurlari.js (soruTurlariHtml, hatalarSatiri), js/ekranlar/calisma.js (yukGrafigi),
// css/app.css (.ders-bas, .ders-bugun, .ders-tekrar, .calis-atolye, .calis-sekmeler, .ders-liste, .tur-izgara) @ a866b86
import NoraCekirdek
import SwiftUI

/// Çalış ana ekranı (`#/pekistir`): bugünün dersi kartı, günlük tekrar, çalışma masan (Dersler / Başka turlar),
/// yolculuk bağlantısı ve 14 günlük yük grafiği (`js/ekranlar/calisma.js`).
@MainActor
struct CalisAnaGorunumu: View {
    @Bindable var model: PekistirmeModeli
    @Binding var masaSekmesi: CalisMasaSekmesi
    let turBaslat: (PekistirmeKipi, Int?) -> Void
    let derseGit: (String) -> Void
    /// Dersin adımını açar (`dersAdresi(akim, adim)`: adım halkaları ve devam satırı)
    let adimaGit: (String, DersAdimi) -> Void
    let donemlereGit: (_ salonlaraIn: Bool) -> Void
    let adreseGit: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var ustCubukAcik = false

    enum CalisMasaSekmesi: String, CaseIterable {
        case dersler
        case turlar
    }

    var body: some View {
        let r = tema.renkler
        if let katalog = model.katalog, let il = model.ilerleme {
            let acikSanatcilar = il.acikSanatcilar(katalog.sanatcilar)
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

            ZStack(alignment: .top) {
                ScrollViewReader { kaydir in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            baslikSatiri(il: il)
                                .id("ust")
                                .background(
                                    GeometryReader { g in
                                        Color.clear.preference(
                                            key: CalisBaslikKonumu.self,
                                            value: g.frame(in: .named("calis-kaydir")).maxY
                                        )
                                    }
                                )

                            if let tur = model.kayit, !tur.bitti {
                                CalisDevamKarti(model: model, tur: tur) {
                                    model.turAcik = true
                                } bitir: {
                                    Task { await model.yarimBitir() }
                                }
                                .padding(.top, 16)
                            }

                            if acikSanatcilar.isEmpty {
                                bosAcikKutu
                                    .padding(.top, 16)
                            } else {
                                if let b = bugunDers {
                                    bugunKarti(b, katalog: katalog, il: il)
                                        .padding(.top, 16)
                                } else if !acikDersler.isEmpty {
                                    tumDerslerBittiKarti
                                        .padding(.top, 16)
                                }

                                let karisik = CalisKurallari.turBilgisi(
                                    sanatcilar: katalog.sanatcilar,
                                    ilerleme: il,
                                    bugun: model.bugun,
                                    karisik: true
                                )
                                tekrarKarti(karisik, acikDersler: acikDersler, katalog: katalog, il: il)
                                    .padding(.top, 24)
                                    .id("tekrar")

                                calismaMasasiBasligi
                                    .id("turlar")
                                calismaMasasiSekmeleri

                                if masaSekmesi == .dersler {
                                    derslerPaneli(
                                        aciklar: acikDersler,
                                        kilitliler: kilitliDersler,
                                        bugunku: bugunkuAkim,
                                        katalog: katalog,
                                        il: il
                                    )
                                } else {
                                    baskaTurlarPaneli(katalog: katalog, il: il)
                                }

                                yolculukBaglantisi

                                yukBolumu(il: il, acikIdler: acikSanatcilar.map(\.id))
                                    .id("yuk")
                            }
                        }
                        .padding(.horizontal, BenOlcu.yan)
                        .padding(.bottom, 128)
                        .frame(maxWidth: 640, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    }
                    .coordinateSpace(name: "calis-kaydir")
                    .onPreferenceChange(CalisBaslikKonumu.self) { maxY in
                        let acik = maxY < 12
                        if acik != ustCubukAcik {
                            withAnimation(.easeOut(duration: 0.2)) { ustCubukAcik = acik }
                        }
                    }
                    #if DEBUG
                    .task { await CalisKarsilastirma.kaydir(kaydir, masaSekmesi: $masaSekmesi) }
                    #endif
                }

                if ustCubukAcik {
                    calisUstCubugu
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
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

    // MARK: Başlık (`.ders-bas` ve `.calis-cubuk`)

    private func baslikSatiri(il: Ilerleme) -> some View {
        let r = tema.renkler
        let konum = CalisKurallari.konumYazisi(islenen: il.islenenKume)
        return HStack(alignment: .bottom, spacing: 12) {
            Text("Çalış")
                .font(Yazi.serif(44, stil: .largeTitle))
                .cssSatir(.serif, 44, 44)
                .foregroundStyle(Color(r.murekkep))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if !konum.isEmpty {
                Text(konum)
                    .font(Yazi.sans(13, stil: .footnote))
                    .cssSatir(.sans, 13, 16.9)
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.bottom, 6)
                    .accessibilityIdentifier("ders-konum")
            }
        }
        .padding(.top, 8)
        .frame(minHeight: 52, alignment: .bottom)
    }

    private var calisUstCubugu: some View {
        let r = tema.renkler
        return Text("Çalış")
            .font(Yazi.serif(18, agirlik: 500))
            .foregroundStyle(Color(r.murekkep))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) { Ayrac() }
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
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
    }

    // MARK: Bugünün dersi kartı (`.ders-bugun`)

    private func bugunKarti(_ b: DersBilgisi, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let kunye = CalisDersKurallari.dersKunyesi(b)
        let dugme = CalisDersKurallari.devamDugmesi(b, sahne: true)
        let kapakEser = CalisDersKurallari.dersKapakEseri(b, katalog: katalog, kotuler: il.kotuGorseller)
        let harita = CalisDersKurallari.haritaBilgisi(
            b,
            katalog: katalog,
            ilerleme: il,
            kaynak: model.dersKaynagi,
            yuruyus: model.yuruyus
        )
        return VStack(alignment: .leading, spacing: 0) {
            // Kapak (`.ders-bugun-kapak`, 236 pt)
            Button {
                derseGit(b.akim)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Color(RGBA(css: "#1a1816")!)
                    if let kapakEser {
                        UzakGorsel(url: model.gorsel(kapakEser, 960), icerik: .fill)
                            // Z3c: Çalış'ın zemini bu tablonun renklerinden
                            .task(id: kapakEser.anahtar) { ZeminTablosu.shared.son[.calis] = model.gorsel(kapakEser, 960) }
                            .frame(maxWidth: .infinity, minHeight: 236, maxHeight: 236)
                            .clipped()
                    }
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 18 / 255, green: 17 / 255, blue: 16 / 255).opacity(0), location: 0.35),
                            .init(color: Color(red: 18 / 255, green: 17 / 255, blue: 16 / 255).opacity(0.92), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bugünün dersi")
                            .font(Yazi.sans(13, agirlik: 600))
                            .cssSatir(.sans, 13, 18.2)
                            .foregroundStyle(Color(red: 244 / 255, green: 240 / 255, blue: 232 / 255).opacity(0.85))
                        Text(b.akim)
                            .font(Yazi.serif(40, agirlik: 500))
                            .tracking(-0.8)
                            .cssSatir(.serif, 40, 42)
                            .foregroundStyle(Color(RGBA(css: "#ebe5da")!))
                            .multilineTextAlignment(.leading)
                        if !kunye.isEmpty {
                            Text(kunye)
                                .font(Yazi.sans(13))
                                .cssSatir(.sans, 13, 16.9)
                                .foregroundStyle(Color(RGBA(css: "#cfc7bc")!))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
                .frame(height: 236)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Adımlar (`.ders-adimlar`: Gör, Öğren, Ayırt et + Harita)
            HStack(spacing: 6) {
                ForEach(b.durum.adimlar, id: \.adim) { s in
                    let simdi = !s.bitti && s.adim == b.durum.siradaki
                    Button {
                        adimaGit(b.akim, s.adim)
                    } label: {
                        dersAdimSutunu(baslik: s.ad, bitti: s.bitti, simdi: simdi, oran: s.i)
                    }
                    .buttonStyle(.plain)
                }
                // Harita sütunu (`.ders-adim.haritaya`)
                Group {
                    if b.durum.bitti {
                        Button { adreseGit("#/harita") } label: {
                            dersAdimSutunu(baslik: "Harita", bitti: false, simdi: true, oran: 0.06)
                        }
                        .buttonStyle(.plain)
                    } else {
                        dersAdimSutunu(baslik: "Harita", bitti: false, simdi: false, oran: 0)
                            .opacity(0.55)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 2)

            // Alt kısım (`.ders-bugun-alt`: davet metni + devam satırı)
            VStack(alignment: .leading, spacing: 0) {
                if b.durum.siradaki != .gor {
                    dersDavetMetni(b, harita: harita)
                        .padding(.top, 10)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 12)
                }
                Button {
                    if let a = dugme.adim { adimaGit(b.akim, a) } else { derseGit(b.akim) }
                } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(dugme.baslik)
                                .font(Yazi.sans(17, agirlik: 600))
                                .cssSatir(.sans, 17, 21.25)
                                .foregroundStyle(Color(r.murekkep))
                            if !dugme.alt.isEmpty {
                                Text(dugme.alt)
                                    .font(Yazi.sans(14))
                                    .cssSatir(.sans, 14, 18.9)
                                    .foregroundStyle(Color(r.murekkep2))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ZStack {
                            Circle().fill(Color(r.murekkep))
                            BenIkon(simge: .ileri, boyut: 20, kalinlik: 2.0)
                                .foregroundStyle(Color(r.zemin))
                        }
                        .frame(width: 46, height: 46)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                    .padding(.leading, 22)
                    .padding(.trailing, 18)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color(r.murekkep).opacity(0.14))
                            .frame(height: 0.5)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ders-devam")
            }
        }
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(r.koyu ? 0.32 : 0.08), radius: 25, y: 12)
        .accessibilityIdentifier("bugunun-dersi")
    }

    private func dersAdimSutunu(baslik: String, bitti: Bool, simdi: Bool, oran: Double) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 8) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(r.murekkep).opacity(0.16))
                    if bitti {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(r.dogru))
                    } else if simdi {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(r.pirinc))
                            .frame(width: max(g.size.width * 0.06, g.size.width * min(1, max(0, oran))))
                    }
                }
            }
            .frame(height: 3)
            Text(baslik)
                .font(Yazi.sans(13, agirlik: simdi ? 600 : 400))
                .cssSatir(.sans, 13, 15.6)
                .foregroundStyle(Color(simdi ? r.murekkep : r.murekkep2))
                .lineLimit(1)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
    }

    @ViewBuilder
    private func dersDavetMetni(_ b: DersBilgisi, harita: (durak: Int, kilit: String)) -> some View {
        let r = tema.renkler
        let renk = Color(r.murekkep).opacity(0.84)
        let dv = CalisDersKurallari.davet(b, harita: harita)
        if let italik = dv.italikMadde, let son = dv.sonEk {
            (Text("Sıradaki özellik: ")
                + Text(italik).italic()
                + Text(son))
                .font(Yazi.okuma(17))
                .cssSatir(.okuma, 17, 24.65)
                .foregroundStyle(renk)
        } else {
            Text(dv.duz)
                .font(Yazi.okuma(17))
                .cssSatir(.okuma, 17, 24.65)
                .foregroundStyle(renk)
        }
    }

    private var tumDerslerBittiKarti: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 10) {
            Etiket("Bugünün dersi")
            Text("Açık derslerin hepsi tamam. Aşağıdan istediğini yeniden açabilir ya da günlük tekrarı yapabilirsin.")
                .font(Yazi.okuma(17))
                .cssSatir(.okuma, 17, 24.65)
                .foregroundStyle(Color(r.murekkep).opacity(0.84))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
        .accessibilityIdentifier("bugunun-dersi")
    }

    // MARK: Günlük tekrar (`.calis-atolye .ders-tekrar.tek-satir`)

    private func tekrarKarti(_ tur: TurOzeti, acikDersler: [DersBilgisi], katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let kapaklar: [Eser] = Array(acikDersler.prefix(3).compactMap {
            CalisDersKurallari.dersKapakEseri($0, katalog: katalog, kotuler: il.kotuGorseller)
        })
        let alt = CalisKurallari.turAltYazisi(tur)
        return VStack(spacing: 0) {
            Ayrac()
            Button {
                turBaslat(.sanatci(.karisik), nil)
            } label: {
                HStack(spacing: 20) {
                    if !kapaklar.isEmpty {
                        ZStack {
                            ForEach(Array(kapaklar.enumerated()), id: \.offset) { i, eser in
                                let aci: Double = i == 0 ? -8 : (i == 2 ? 8 : 0)
                                let x: CGFloat = i == 0 ? -6 : (i == 2 ? 6 : 0)
                                let y: CGFloat = i == 1 ? -2 : 2
                                UzakGorsel(url: model.gorsel(eser, 320), icerik: .fill)
                                    .frame(width: 44, height: 58)
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .strokeBorder(Color(r.murekkep).opacity(0.18), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.16), radius: 5, y: 4)
                                    .rotationEffect(.degrees(aci))
                                    .offset(x: x, y: y)
                                    .zIndex(Double(i))
                            }
                        }
                        .frame(width: 52, height: 60)
                        .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Günlük tekrar")
                            .font(Yazi.sans(14, agirlik: 600))
                            .cssSatir(.sans, 14, 19.6)
                            .foregroundStyle(Color(r.murekkep2))
                        (Text("\(tur.toplam)").font(Yazi.serif(26, agirlik: 500))
                            + Text(" kart").font(Yazi.serif(18, agirlik: 500)))
                            .foregroundStyle(Color(r.murekkep))
                        VStack(alignment: .leading, spacing: 2) {
                            if tur.toplam > 0 {
                                Text("Yaklaşık \(tur.yaklasikDakika) dk")
                                    .font(Yazi.sans(14))
                                    .cssSatir(.sans, 14, 18.9)
                                    .foregroundStyle(Color(r.murekkep2))
                            }
                            Text(alt)
                                .font(Yazi.sans(14))
                                .cssSatir(.sans, 14, 18.9)
                                .foregroundStyle(Color(r.murekkep2))
                        }
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle().fill(Color(r.yuzey))
                        Circle().strokeBorder(Color(r.kenar), lineWidth: 1)
                        BenIkon(simge: .ileri, boyut: 20, kalinlik: 1.8)
                            .foregroundStyle(Color(r.murekkep))
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.vertical, 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("karisik-dugme")
            Ayrac()
        }
    }

    // MARK: Çalışma masan (`.calis-masa-bas` ve `.calis-sekmeler`)

    private var calismaMasasiBasligi: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 8) {
            Text("Çalışma masan")
                .font(Yazi.serif(32, agirlik: 500))
                .tracking(-0.8)
                .cssSatir(.serif, 32, 34.5)
                .foregroundStyle(Color(r.murekkep))
                .accessibilityAddTraits(.isHeader)
            Text("Önce keşfet. Sonra kendini dene.")
                .font(Yazi.sans(14))
                .cssSatir(.sans, 14, 21)
                .foregroundStyle(Color(r.murekkep2))
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var calismaMasasiSekmeleri: some View {
        let r = tema.renkler
        return HStack(spacing: 0) {
            masaSekmeDugmesi(
                sekme: .dersler,
                baslik: "Dersler",
                isaretleme: #"<path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H11v16H5.5A1.5 1.5 0 0 1 4 18.5z"/><path d="M20 5.5A1.5 1.5 0 0 0 18.5 4H13v16h5.5a1.5 1.5 0 0 0 1.5-1.5z"/>"#
            )
            masaSekmeDugmesi(
                sekme: .turlar,
                baslik: "Başka turlar",
                isaretleme: BenSimge.karsilastir.isaretleme
            )
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
    }

    private func masaSekmeDugmesi(sekme: CalisMasaSekmesi, baslik: String, isaretleme: String) -> some View {
        let r = tema.renkler
        let secili = masaSekmesi == sekme
        return Button {
            withAnimation(.easeOut(duration: 0.18)) { masaSekmesi = sekme }
        } label: {
            HStack(spacing: 8) {
                SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: isaretleme))
                    .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
                Text(baslik)
                    .font(Yazi.sans(14, agirlik: 500))
                    .lineLimit(1)
            }
            .foregroundStyle(Color(secili ? r.yuzey : r.murekkep2))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(secili ? Color(r.murekkep) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(secili ? .isSelected : [])
        .accessibilityIdentifier("calis-\(sekme.rawValue)-sekme")
    }

    // MARK: Dersler paneli (`#calis-dersler-panel`)

    @ViewBuilder
    private func derslerPaneli(
        aciklar: [DersBilgisi],
        kilitliler: [AkimDurumu],
        bugunku: String?,
        katalog: SiteKatalogu,
        il: Ilerleme
    ) -> some View {
        let r = tema.renkler
        if aciklar.isEmpty {
            Text(model.dersKaynagi == nil
                 ? "Dersler yüklenemedi; bağlantı gelince yeniden dene."
                 : "Açık dönemlerin dersi henüz yok.")
                .font(Yazi.sans(14))
                .foregroundStyle(Color(r.murekkep2))
                .padding(.vertical, 20)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(aciklar.count) açık ders · Her döneme bir eserden başla.")
                    .font(Yazi.sans(14))
                    .cssSatir(.sans, 14, 21)
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.vertical, 20)

                let sutunlar = [
                    GridItem(.flexible(), spacing: 16, alignment: .top),
                    GridItem(.flexible(), spacing: 16, alignment: .top),
                ]
                LazyVGrid(columns: sutunlar, spacing: 24) {
                    ForEach(aciklar) { b in
                        dersIzgaraKarti(b, bugunku: bugunku, katalog: katalog, il: il)
                    }
                }

                if let ilkKilitli = kilitliler.first {
                    kilitliDersSatiri(ilkKilitli)
                        .padding(.top, 24)
                }

                if kilitliler.count > 1 {
                    Text("\(kilitliler.count - 1) ders daha, konular işlendikçe açılacak.")
                        .font(Yazi.sans(14))
                        .cssSatir(.sans, 14, 21)
                        .foregroundStyle(Color(r.murekkep2))
                        .padding(.top, 12)
                }
            }
        }
    }

    private func dersIzgaraKarti(_ b: DersBilgisi, bugunku: String?, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let hal = b.hal
        let bugun = b.akim == bugunku && hal != .bitti
        let kapak = CalisDersKurallari.dersKapakEseri(b, katalog: katalog, kotuler: il.kotuGorseller)
        return Button {
            derseGit(b.akim)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                Color(r.yuzey)
                    .aspectRatio(4.0 / 5.0, contentMode: .fit)
                    .overlay {
                        if let kapak {
                            UzakGorsel(url: model.gorsel(kapak, 640), icerik: .fill)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        Text(bugun ? "Bugünün dersi" : hal.etiket)
                            .font(Yazi.sans(14, agirlik: 500))
                            .foregroundStyle(Color(bugun ? r.yuzey : r.murekkep))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(bugun ? r.murekkep : r.yuzey))
                            )
                            .padding(10)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        ZStack {
                            Circle().fill(Color(r.yuzey))
                            BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.6)
                                .foregroundStyle(Color(r.murekkep))
                        }
                        .frame(width: 36, height: 36)
                        .padding(10)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(b.akim)
                        .font(Yazi.serif(21, agirlik: 500))
                        .tracking(-0.3)
                        .cssSatir(.serif, 21, 25.2)
                        .foregroundStyle(Color(r.murekkep))
                        .lineLimit(1)
                    Text("\(b.acikSanatcilar.count) sanatçı · \(b.adimlar.count) adım")
                        .font(Yazi.sans(14))
                        .cssSatir(.sans, 14, 19.6)
                        .foregroundStyle(Color(r.murekkep2))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        ForEach(b.durum.adimlar, id: \.adim) { s in
                            let simdi = bugun && !s.bitti && s.adim == b.durum.siradaki
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(r.kenar))
                                    if s.bitti {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(r.murekkep))
                                    } else if simdi {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(r.murekkep))
                                            .frame(width: g.size.width * min(1, max(0, s.i)))
                                    }
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func kilitliDersSatiri(_ a: AkimDurumu) -> some View {
        let r = tema.renkler
        let alt = a.acilacagiKonu.map { "Konu \(CalisKurallari.bulunmaEki($0)) açılır" } ?? "Henüz açılmadı"
        return HStack(spacing: 16) {
            BenIkon(simge: .kilit, boyut: 20, kalinlik: 1.6)
                .foregroundStyle(Color(r.murekkep2))
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 6) {
                Text(a.ad)
                    .font(Yazi.sans(16, agirlik: 500))
                    .cssSatir(.sans, 16, 20.8)
                    .foregroundStyle(Color(r.murekkep))
                Text(alt)
                    .font(Yazi.sans(14))
                    .cssSatir(.sans, 14, 19.6)
                    .foregroundStyle(Color(r.murekkep2))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(minHeight: 84)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(r.kenar), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .accessibilityIdentifier("ders-kilitli")
    }

    // MARK: Başka turlar paneli (`#calis-turlar-panel`)

    private func baskaTurlarPaneli(katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let hatalar = CalisKurallari.hatalarBilgisi(
            sanatcilar: katalog.sanatcilar,
            ilerleme: il,
            bugun: model.bugun
        )
        let bolumSayisi = CalisKurallari.bolumTuruKartSayisi(katalog: katalog, ilerleme: il)
        let kars = CalisKurallari.karsilastirSecimi(katalog: katalog, ilerleme: il)
        let sutunlar = [
            GridItem(.flexible(), spacing: 16, alignment: .top),
            GridItem(.flexible(), spacing: 16, alignment: .top),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            Text("Aynı eserlere, farklı sorularla yeniden bak.")
                .font(Yazi.sans(14))
                .cssSatir(.sans, 14, 21)
                .foregroundStyle(Color(r.murekkep2))
                .padding(.vertical, 20)

            if !hatalar.idler.isEmpty {
                turKutusu(
                    baslik: "Hatalarım",
                    alt: hatalar.altYazi,
                    ustRozet: .sayi(hatalar.idler.count)
                ) {
                    turBaslat(.sanatci(.hatalar), nil)
                }
                .padding(.bottom, 16)
                .accessibilityIdentifier("hatalar-satir")
            }

            LazyVGrid(columns: sutunlar, spacing: 16) {
                turKutusu(
                    baslik: "Döneme göre",
                    alt: "Salon salon çalış",
                    ustRozet: .isaretleme(#"<path d="M5.5 4.5h13M7 4.5V7h10V4.5M9 7v10M12 7v10M15 7v10M7 19.5V17h10v2.5M5.5 19.5h13"/>"#)
                ) {
                    donemlereGit(true)
                }
                .accessibilityIdentifier("tur-donem")

                if bolumSayisi > 0 {
                    turKutusu(
                        baslik: "Bölüm turu",
                        alt: "Hangi bölümde?",
                        ustRozet: .sayi(bolumSayisi)
                    ) {
                        turBaslat(.kursBolumu, nil)
                    }
                    .accessibilityIdentifier("tur-bolum")
                }

                turKutusu(
                    baslik: "Konu turu",
                    alt: "İncil, mitoloji, tarih",
                    ustRozet: .isaretleme(#"<rect x="5" y="3" width="14" height="18" rx="1"/><circle cx="12" cy="10" r="2.5"/><path d="M8 18c.6-2.4 2.2-3.6 4-3.6s3.4 1.2 4 3.6"/>"#)
                ) {
                    turBaslat(.ikonografi, nil)
                }
                .accessibilityIdentifier("tur-ikonografi")

                if let kars {
                    turKutusu(
                        baslik: "Karşılaştır",
                        alt: kars.alt,
                        ustRozet: .isaretleme(BenSimge.karsilastir.isaretleme)
                    ) {
                        adreseGit(kars.adres)
                    }
                    .accessibilityIdentifier("tur-karsilastir")
                }
            }
        }
    }

    private enum TurRozeti {
        case sayi(Int)
        case isaretleme(String)
    }

    private func turKutusu(baslik: String, alt: String, ustRozet: TurRozeti, eylem: @escaping () -> Void) -> some View {
        let r = tema.renkler
        return Button(action: eylem) {
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Circle().fill(Color(r.murekkep).opacity(0.09))
                    switch ustRozet {
                    case .sayi(let n):
                        Text("\(n)")
                            .font(Yazi.serif(16, agirlik: 500))
                            .foregroundStyle(Color(r.murekkep))
                    case .isaretleme(let svg):
                        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: svg))
                            .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Color(r.murekkep))
                    }
                }
                .frame(width: 36, height: 36)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text(baslik)
                        .font(Yazi.serif(24, agirlik: 500))
                        .tracking(-0.36)
                        .cssSatir(.serif, 24, 27.6)
                        .foregroundStyle(Color(r.murekkep))
                        .multilineTextAlignment(.leading)
                    Text(alt)
                        .font(Yazi.sans(14))
                        .cssSatir(.sans, 14, 19.6)
                        .foregroundStyle(Color(r.murekkep2))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Yolculuk bağlantısı (`.calis-yolculuk`)

    private var yolculukBaglantisi: some View {
        let r = tema.renkler
        let haritaYolu = #"<path d="M9 4 3 6.5v13.5l6-2.5 6 2.5 6-2.5V4l-6 2.5z"/><path d="M9 4v13.5"/><path d="M15 6.5V20"/>"#
        return VStack(spacing: 0) {
            Ayrac()
            Button {
                adreseGit("#/harita")
            } label: {
                HStack(spacing: 16) {
                    SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: haritaYolu))
                        .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color(r.murekkep2))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bir sonraki durağın seni bekliyor.")
                            .font(Yazi.sans(15, agirlik: 500))
                            .cssSatir(.sans, 15, 20.25)
                            .foregroundStyle(Color(r.murekkep))
                        Text("Yolculuğunu haritada gör")
                            .font(Yazi.sans(14))
                            .cssSatir(.sans, 14, 19.6)
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.6)
                        .foregroundStyle(Color(r.murekkep2))
                }
                .padding(.vertical, 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Ayrac()
        }
        .padding(.top, 28)
    }

    // MARK: 14 Günlük Yük Grafiği (`js/ekranlar/calisma.js` `yukGrafigi`)

    private func yukBolumu(il: Ilerleme, acikIdler: [String]) -> some View {
        let r = tema.renkler
        let ozet = CalisKurallari.gelecekYukOzeti(skorlar: il.skorlar, idler: acikIdler, bugun: model.bugun)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Etiket("Önümüzdeki 14 gün")
                Spacer(minLength: 0)
                Text(ozet.yazi)
                    .font(Yazi.sans(13, stil: .footnote))
                    .foregroundStyle(Color(r.murekkep2))
                    .multilineTextAlignment(.trailing)
            }
            if ozet.toplam > 0 {
                CalisYukGrafigi(gunluk: ozet.gunluk, bugun: model.bugun)
                    .aspectRatio(340.0 / 114.0, contentMode: .fit)
                    .accessibilityLabel("Önümüzdeki 14 günün vadeli kart sayısı. \(ozet.yazi)")
            }
        }
        .padding(.top, 28)
    }
}

// MARK: Ortak Çalış bileşenleri

private struct CalisBaslikKonumu: PreferenceKey {
    static let defaultValue: CGFloat = 100
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// `js/ekranlar/calisma.js` `yukGrafigi`: 14 günlük vadeli kart yükü çubuk grafiği
struct CalisYukGrafigi: View {
    let gunluk: [Int]
    let bugun: String
    @Environment(TemaDeposu.self) private var tema
    private static let gunHarfi = ["P", "P", "S", "Ç", "P", "C", "C"]

    var body: some View {
        Canvas { c, boyut in
            let r = tema.renkler
            let k = boyut.width / 340
            let G: CGFloat = 340, Y: CGFloat = 84
            let adim = (G - 8) / 14
            let en = CGFloat(max(1, gunluk.max() ?? 1))
            var eksen = Path()
            eksen.move(to: CGPoint(x: 4 * k, y: Y * k))
            eksen.addLine(to: CGPoint(x: (G - 4) * k, y: Y * k))
            c.stroke(eksen, with: .color(Color(r.kenar)), lineWidth: 1)
            var takvim = Calendar(identifier: .gregorian)
            takvim.timeZone = TimeZone(identifier: "UTC")!
            for (i, n) in gunluk.enumerated() {
                let t = GunTarihi.ekle(bugun, i)
                let h: CGFloat = n > 0 ? max(3, CGFloat(n) / en * (Y - 16)) : 0
                let cx = 4 + CGFloat(i) * adim + adim / 2
                if h > 0 {
                    let kutu = CGRect(x: (cx - adim * 0.3) * k, y: (Y - h) * k, width: adim * 0.6 * k, height: h * k)
                    c.fill(Path(kutu), with: .color(Color(i == 0 ? r.vurguAcik : r.murekkep2)))
                    c.draw(
                        Text("\(n)").font(Yazi.sans(9.5, agirlik: 500, stil: .caption2)).foregroundColor(Color(r.murekkep3)),
                        at: CGPoint(x: cx * k, y: (Y - h - 4) * k),
                        anchor: .bottom
                    )
                }
                if let p = GunTarihi.ayir(t),
                   let tarih = takvim.date(from: DateComponents(year: p.yil, month: p.ay, day: p.gun)) {
                    let hg = takvim.component(.weekday, from: tarih) - 1
                    c.draw(
                        Text(Self.gunHarfi[hg]).font(Yazi.sans(9.5, agirlik: 500, stil: .caption2)).foregroundColor(Color(r.murekkep3)),
                        at: CGPoint(x: cx * k, y: (Y + 13) * k),
                        anchor: .bottom
                    )
                    c.draw(
                        Text("\(p.gun)").font(Yazi.sans(8.5, agirlik: 500, stil: .caption2)).foregroundColor(Color(r.soluk)),
                        at: CGPoint(x: cx * k, y: (Y + 25) * k),
                        anchor: .bottom
                    )
                }
            }
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

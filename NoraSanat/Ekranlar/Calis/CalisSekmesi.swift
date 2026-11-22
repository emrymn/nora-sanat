// Kaynak: sanat-atlasi js/ekranlar/ders.js (dersMenusu, dersSayfasi, haritaSatiri),
// js/ekranlar/pekistir.js (pekistir, pekistirMenusu), css/app.css (.ders-sayfa-kapak, .ders-adim-liste, .ders-adim-satir) @ a866b86
import NoraCekirdek
import SwiftUI

/// Çalış sekmesinin yerli ekranı (ISLER.md: C1 + C2 + C3).
/// - Ana ekran (`#/pekistir`): `CalisAnaGorunumu`
/// - Döneme göre / Turlar (`#/pekistir/donem`): `DonemTurlariGorunumu`
/// - Ders özeti (`#/pekistir/ders/<akım>`): `CalisDersSayfasi`
/// - Dersin adımları (`#/pekistir/ders/<akım>/gor|ogren|ayirt`): `DersAdimEkrani` (C3)
/// - Aktif tur (`model.turAcik`): `PekistirmeEkrani` (sekme çubuğunu `.sekmeCubuguGizli(true, sekme: .calis)` ile gizler)
@MainActor
struct CalisSekmesi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(\.dynamicTypeSize) private var yaziBoyutu
    @Environment(\.scenePhase) private var evre

    @State private var model = PekistirmeModeli()
    @State private var altSayfa: AltSayfa = .ana
    @State private var masaSekmesi: CalisAnaGorunumu.CalisMasaSekmesi = .dersler
    @State private var onayKipi: PekistirmeKipi?
    @State private var onaySeviyesi: Int?

    enum AltSayfa: Equatable {
        case ana
        case donem(salonlaraIn: Bool)
        case ders(String)
        case adim(String, DersAdimi)
    }

    var body: some View {
        let r = tema.renkler
        ZStack {
            Color(r.zemin).ignoresSafeArea()

            if model.turAcik {
                PekistirmeEkrani(
                    disModel: model,
                    disAdreseGit: { adreseGit($0) }
                )
                .transition(.opacity)
                .zIndex(2)
            } else {
                switch altSayfa {
                case .ana:
                    CalisAnaGorunumu(
                        model: model,
                        masaSekmesi: $masaSekmesi,
                        turBaslat: { kip, seviye in turBaslatIstegi(kip, seviye: seviye) },
                        derseGit: { akim in gecis { altSayfa = .ders(akim) } },
                        adimaGit: { akim, adim in gecis { altSayfa = .adim(akim, adim) } },
                        donemlereGit: { salonlaraIn in gecis { altSayfa = .donem(salonlaraIn: salonlaraIn) } },
                        adreseGit: { adreseGit($0) }
                    )
                    .transition(.move(edge: .leading))
                case .donem(let salonlaraIn):
                    DonemTurlariGorunumu(
                        model: model,
                        salonlaraIn: salonlaraIn,
                        geri: { gecis { altSayfa = .ana } },
                        turBaslat: { kip, seviye in turBaslatIstegi(kip, seviye: seviye) }
                    )
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                case .ders(let akim):
                    CalisDersSayfasi(
                        model: model,
                        akim: akim,
                        geri: { gecis { altSayfa = .ana } },
                        turBaslat: { kip, seviye in turBaslatIstegi(kip, seviye: seviye) },
                        adreseGit: { adreseGit($0) },
                        adimaGit: { adim in gecis { altSayfa = .adim(akim, adim) } }
                    )
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                case .adim(let akim, let adim):
                    // Adımdan adıma geçiş yer değiştirir (`data-ders-gec` → gezin(…, 'bolum')): geri ders sayfasına
                    DersAdimEkrani(
                        model: model,
                        akim: akim,
                        adim: adim,
                        derseDon: { gecis { altSayfa = .ders(akim) } },
                        adimaGit: { yeni in gecis { altSayfa = .adim(akim, yeni) } },
                        adreseGit: { adreseGit($0) },
                        turBaslat: { kip, seviye in turBaslatIstegi(kip, seviye: seviye) }
                    )
                    .id("\(akim)|\(adim.rawValue)")
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
                }
            }
        }
        .foregroundStyle(Color(r.murekkep))
        .dynamicTypeSize(tema.ayar.yazi == "buyuk" ? max(yaziBoyutu, .xLarge) : yaziBoyutu)
        .tint(Color(r.vurguAcik))
        .sekmeCubuguGizli(model.turAcik || adimAcik, sekme: .calis)
        .onChange(of: kabuk.yerliAdres[.calis], initial: true) { _, adres in
            if let adres {
                kabuk.adresIslendi(.calis)
                Task { await rotayiIsle(adres) }
            }
        }
        .onChange(of: kabuk.yenidenDokunma[.calis]) { _, _ in
            if model.turAcik {
                model.turAcik = false
            } else if altSayfa != .ana {
                gecis { altSayfa = .ana }
            }
        }
        .task(id: kabuk.secili == .calis) {
            if kabuk.secili == .calis {
                await model.yukle()
                #if DEBUG
                if let sayfa = NoraSanatApp.arguman("-calisSayfa") {
                    if sayfa == "donem" {
                        altSayfa = .donem(salonlaraIn: NoraSanatApp.arguman("-calisKaydir") == "salon")
                    } else if sayfa == "turlar" {
                        altSayfa = .ana
                        masaSekmesi = .turlar
                    } else if sayfa.hasPrefix("ders:") {
                        // `ders:<akım>` ya da `ders:<akım>:<adım>`
                        let p = sayfa.dropFirst(5).split(separator: ":", maxSplits: 1).map(String.init)
                        if p.count == 2, let a = DersAdimi(rawValue: p[1]) {
                            altSayfa = .adim(p[0], a)
                        } else {
                            altSayfa = .ders(String(sayfa.dropFirst(5)))
                        }
                    }
                }
                #endif
            }
        }
        .onChange(of: evre) { _, yeni in
            if yeni == .active && kabuk.secili == .calis && !model.turAcik {
                Task { await model.yukle() }
            }
        }
        .confirmationDialog(
            "Yarım tur yerine yeni tur başlatılsın mı?",
            isPresented: Binding(
                get: { onayKipi != nil },
                set: { if !$0 { onayKipi = nil } }
            ),
            titleVisibility: .visible,
            presenting: onayKipi
        ) { kip in
            Button("Sil, yeni başla", role: .destructive) {
                Task { await model.basla(kip, seviye: onaySeviyesi) }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: { _ in
            Text("Yeni tur başlarsa yarım kalan tur silinir.")
        }
    }

    private var hareketYok: Bool { tema.ayar.hareketAzaltilmis }

    /// Adım ekranları tam ekrandır (sitede `#/pekistir/ders/<akım>/<adım>` sekme çubuğu göstermez)
    private var adimAcik: Bool {
        if case .adim = altSayfa { return true }
        return false
    }

    private func gecis(_ islem: () -> Void) {
        withAnimation(hareketYok ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.35), islem)
    }

    private func turBaslatIstegi(_ kip: PekistirmeKipi, seviye: Int? = nil) {
        if let k = model.kayit, !k.bitti {
            onaySeviyesi = seviye
            onayKipi = kip
        } else {
            Task { await model.basla(kip, seviye: seviye) }
        }
    }

    /// Çalış içindeki ya da diğer sekmelerdeki site adreslerine yönlendirir (C1c devir notu)
    private func adreseGit(_ adres: String) {
        let h = SiteRotalari.hash(adres)
        if h.hasPrefix("#/pekistir") {
            Task { await rotayiIsle(h) }
            return
        }
        model.turAcik = false
        if kabuk.yerliyeGit(h) { return }
        if let hedefSekme = SiteRotalari.sekme(h) {
            kabuk.sec(hedefSekme)
        }
        Gezgin.shared.git(h)
    }

    private func rotayiIsle(_ adres: String) async {
        if model.katalog == nil {
            await model.yukle()
        }
        let h = SiteRotalari.hash(adres)
        let yol = h.hasPrefix("#/") ? String(h.dropFirst(2)) : h
        let parcalar = yol.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard parcalar.first == "pekistir" else { return }

        if parcalar.count == 1 {
            model.turAcik = false
            gecis { altSayfa = .ana }
            return
        }

        switch parcalar[1] {
        case "devam":
            if model.kayit != nil {
                model.turAcik = true
            } else {
                gecis { altSayfa = .ana }
            }
        case "karisik":
            await model.basla(.sanatci(.karisik))
        case "hatalar":
            await model.basla(.sanatci(.hatalar))
        case "bolum":
            await model.basla(.kursBolumu)
        case "ikonografi":
            await model.basla(.ikonografi)
        case "konu":
            if parcalar.count >= 3, let no = Int(parcalar[2]) {
                await model.basla(.sanatci(.konu(no)))
            }
        case "donem":
            if parcalar.count == 2 {
                model.turAcik = false
                gecis { altSayfa = .donem(salonlaraIn: false) }
            } else {
                let secim = parcalar[2].removingPercentEncoding ?? parcalar[2]
                let seviye = parcalar.count >= 4 ? Int(parcalar[3]) : nil
                if secim == "hepsi" {
                    await model.basla(.sanatci(.donem(nil)), seviye: seviye)
                } else {
                    await model.basla(.sanatci(.donem(secim)), seviye: seviye)
                }
            }
        case "ders":
            if parcalar.count >= 3 {
                let akim = parcalar[2].removingPercentEncoding ?? parcalar[2]
                model.turAcik = false
                // `#/pekistir/ders/<akım>/sina` (eski adres) ders sayfasını açar
                if parcalar.count >= 4, let adim = DersAdimi(rawValue: parcalar[3]) {
                    gecis { altSayfa = .adim(akim, adim) }
                } else {
                    gecis { altSayfa = .ders(akim) }
                }
            }
        default:
            break
        }
    }
}

// MARK: Ders Özeti Sayfası (`js/ekranlar/ders.js` `dersSayfasi`)

@MainActor
struct CalisDersSayfasi: View {
    let model: PekistirmeModeli
    let akim: String
    let geri: () -> Void
    let turBaslat: (PekistirmeKipi, Int?) -> Void
    let adreseGit: (String) -> Void
    /// Dersin adımını açar (`dersAdresi(akim, adim)`)
    let adimaGit: (DersAdimi) -> Void

    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Etiket("Ders")
                        .padding(.leading, 44)
                    BenUst(baslik: akim, boyut: 40, geri: geri)
                }
                .padding(.top, 8)

                if let katalog = model.katalog, let il = model.ilerleme {
                    if let b = CalisDersKurallari.dersBilgisi(
                        kaynak: model.dersKaynagi,
                        yuruyus: model.yuruyus,
                        katalog: katalog,
                        ilerleme: il,
                        akim: akim
                    ) {
                        if b.acikSanatcilar.isEmpty {
                            let durum = Kilit.akimDurumlari(
                                katalog.akimlar,
                                katalog.sanatcilar,
                                islenen: il.islenenKume
                            ).first(where: { $0.ad == akim })
                            let yazi = durum?.acilacagiKonu.map {
                                "Bu ders Konu \(CalisKurallari.bulunmaEki($0)) açılır."
                            } ?? "Bu ders henüz açılmadı."
                            bosKutu(yazi: yazi)
                        } else {
                            dersGovdesi(b, katalog: katalog, il: il)
                        }
                    } else {
                        bosKutu(
                            yazi: model.dersKaynagi == nil
                                ? "Ders yüklenemedi; bağlantı gelince yeniden dene."
                                : "Bu dönemin dersi yok."
                        )
                    }
                }
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.bottom, 128)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(alignment: .topLeading) {
            CalisSayfaHalesi()
        }
        .foregroundStyle(Color(r.murekkep))
    }

    private func bosKutu(yazi: String) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 12) {
            Text(yazi)
                .font(Yazi.okuma(18))
                .foregroundStyle(Color(r.murekkep))
            Button("Çalış’a dön", action: geri)
                .buttonStyle(HapDugme())
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
        .padding(.top, 16)
    }

    private func dersGovdesi(_ b: DersBilgisi, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let kapak = CalisDersKurallari.dersKapakEseri(b, katalog: katalog, kotuler: il.kotuGorseller)
        let kunye = CalisDersKurallari.dersKunyesi(b)
        let harita = CalisDersKurallari.haritaBilgisi(
            b,
            katalog: katalog,
            ilerleme: il,
            kaynak: model.dersKaynagi,
            yuruyus: model.yuruyus
        )
        let dugme = CalisDersKurallari.devamDugmesi(b, sahne: false)
        let dv = CalisDersKurallari.davet(b, harita: harita)

        return VStack(alignment: .leading, spacing: 0) {
            // `.ders-sayfa-kapak` (200 pt)
            ZStack {
                Color(r.yuzey)
                if let kapak {
                    UzakGorsel(url: model.gorsel(kapak, 960), icerik: .fill)
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                        .clipped()
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 6)

            // `.ders-kunye`
            HStack(spacing: 4) {
                Text("\(kunye) · ")
                    .font(Yazi.sans(14))
                    .foregroundStyle(Color(r.murekkep2))
                Button {
                    adreseGit("#/akim/\(SiteYazisi.uriBileseni(b.akim))")
                } label: {
                    Text("Dönem sayfası")
                        .font(Yazi.sans(14, agirlik: 500))
                        .underline()
                        .foregroundStyle(Color(r.murekkep))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)

            // `.ders-adim-liste`
            VStack(spacing: 8) {
                ForEach(Array(b.durum.adimlar.enumerated()), id: \.element.adim) { i, s in
                    let say = CalisDersKurallari.adimSayisi(b, s.adim)
                    let simdi = !s.bitti && s.adim == b.durum.siradaki
                    Button { adimaGit(s.adim) } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(s.bitti ? Color(r.dogru) : Color.clear)
                            Circle()
                                .strokeBorder(
                                    s.bitti ? Color.clear : (simdi ? Color(r.pirinc) : Color(r.kenar)),
                                    lineWidth: simdi ? 2 : 1
                                )
                            if s.bitti {
                                BenIkon(simge: .dogru, boyut: 16, kalinlik: 2.2)
                                    .foregroundStyle(Color(r.zemin))
                            } else {
                                Text("\(i + 1)")
                                    .font(Yazi.sans(simdi ? 12 : 13, agirlik: simdi ? 600 : 400))
                                    .foregroundStyle(Color(simdi ? r.pirinc : r.murekkep2))
                            }
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.ad)
                                .font(Yazi.serif(21))
                                .foregroundStyle(Color(r.murekkep))
                            Text(CalisDersKurallari.adimAciklamasi(b, s.adim))
                                .font(Yazi.sans(14))
                                .foregroundStyle(Color(r.murekkep2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(s.bitti ? "Tamam" : say.yazi)
                            .font(Yazi.sans(13))
                            .monospacedDigit()
                            .foregroundStyle(Color(s.bitti ? r.dogruIkon : (simdi ? r.pirinc : r.murekkep3)))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 68)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(simdi ? r.pirinc : r.kenar), lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ders-adim-\(s.adim.rawValue)")
                }

                haritaSatiri(b, harita: harita)
            }
            .padding(.top, 10)

            if !b.adimlar.contains(.gor) {
                Text("Bu dönemin Gör adımı henüz yazılmadı; ders iki adımla ilerler.")
                    .font(Yazi.sans(13))
                    .foregroundStyle(Color(r.murekkep3))
                    .padding(.top, 8)
            }

            Group {
                if let italik = dv.italikMadde, let son = dv.sonEk {
                    (Text("Sıradaki özellik: ") + Text(italik).italic() + Text(son))
                } else {
                    Text(dv.duz)
                }
            }
            .font(Yazi.okuma(17))
            .cssSatir(.okuma, 17, 24.65)
            .foregroundStyle(Color(r.murekkep).opacity(0.84))
            .padding(.top, 16)
            .padding(.bottom, 12)

            Button {
                // `devamDugmesi(b)`: ders bittiyse haritaya, yoksa sıradaki (ya da ilk) adıma
                if let a = dugme.adim {
                    adimaGit(a)
                } else {
                    adreseGit("#/harita")
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dugme.baslik)
                            .font(Yazi.sans(16, agirlik: 600))
                        if !dugme.alt.isEmpty {
                            Text(dugme.alt)
                                .font(Yazi.sans(14))
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.8)
                }
                // `html .ders-dugme.dolu`: hap, `--pg-asil` (= `--vurgu-acik`)
                .foregroundStyle(Color(r.vurguAcikYazi))
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .frame(minHeight: 52)
                .background(Capsule().fill(Color(r.vurguAcik)))
            }
            .buttonStyle(.plain)

            Button {
                turBaslat(.sanatci(.donem(b.akim)), nil)
            } label: {
                Text("Bu dönemin tekrar turu")
                    .font(Yazi.sans(15, agirlik: 500))
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.horizontal, 22)
                    .frame(minHeight: 46)
                    .background(Capsule().fill(Color(r.vurgu).opacity(0.05)))
                    .overlay(Capsule().strokeBorder(Color(r.vurgu).opacity(0.22), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
        }
    }

    @ViewBuilder
    private func haritaSatiri(_ b: DersBilgisi, harita: (durak: Int, kilit: String)) -> some View {
        let r = tema.renkler
        let haritaYolu = #"<path d="M9 4 3 6.5v13.5l6-2.5 6 2.5 6-2.5V4l-6 2.5z"/><path d="M9 4v13.5"/><path d="M15 6.5V20"/>"#
        if b.durum.bitti {
            let alt = !harita.kilit.isEmpty ? harita.kilit : (harita.durak > 0 ? "\(harita.durak) durak · sınavın orada" : "Dönemin durakları")
            Button {
                adreseGit("#/harita")
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().strokeBorder(Color(r.pirinc), lineWidth: 2)
                        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: haritaYolu))
                            .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color(r.pirinc))
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haritaya geç")
                            .font(Yazi.serif(21))
                            .foregroundStyle(Color(r.murekkep))
                        Text(alt)
                            .font(Yazi.sans(14))
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.6)
                        .foregroundStyle(Color(r.pirinc))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: 68)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.pirinc), lineWidth: 1))
            }
            .buttonStyle(.plain)
        } else {
            let alt = "\(b.adimlar.count == 3 ? "Üç" : "İki") adımı bitirince dönemin durakları açılır"
            HStack(spacing: 14) {
                ZStack {
                    Circle().strokeBorder(Color(r.kenar), lineWidth: 1)
                    BenIkon(simge: .kilit, boyut: 16, kalinlik: 1.7)
                        .foregroundStyle(Color(r.murekkep3))
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Haritaya geç")
                        .font(Yazi.serif(21))
                        .foregroundStyle(Color(r.murekkep2))
                    Text(alt)
                        .font(Yazi.sans(14))
                        .foregroundStyle(Color(r.murekkep3))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 68)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .opacity(0.75)
        }
    }
}

#if DEBUG
/// CI karşılaştırması (C2): `-calisKaydir tekrar|turlar|yuk|salon` yerli Çalış ekranını ilgili bölüme kaydırır ve
/// `tmp/calis-hazir` işaret dosyasını yazar.
enum CalisKarsilastirma {
    static var bolum: String? { NoraSanatApp.arguman("-calisKaydir") }
    static let hazir = FileManager.default.temporaryDirectory.appendingPathComponent("calis-hazir")

    @MainActor
    static func kaydir(
        _ kaydir: ScrollViewProxy,
        masaSekmesi: Binding<CalisAnaGorunumu.CalisMasaSekmesi>
    ) async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        if let b = bolum {
            if b == "turlar" {
                masaSekmesi.wrappedValue = .turlar
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            kaydir.scrollTo(b, anchor: .top)
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        try? Data().write(to: hazir)
    }
}
#endif

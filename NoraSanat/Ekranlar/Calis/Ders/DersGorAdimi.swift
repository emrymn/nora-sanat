// Kaynak: sanat-atlasi js/ekranlar/ders.js (gorAdimi, gorKare, gorMetniDegistir, gorResmiYukle, gorHedef, gorKamera,
// gorIleri), js/kamera.js, css/app.css (.ders-gor, .ders-gor-sahne, .ders-gor-perde, .ders-gor-panel, .ders-gor-eser,
// .ders-gor-metin, .ders-gor-alt, .ders-noktalar) @ a866b86
// Gör: dersin ilk eserlerinde yürüyüş. Önce eserin tamamı, sonra ayrıntıdan ayrıntıya; kamera aynı resmin içinde kayar ve
// yakınlaşır (DersKamerasi: uzak iki ayrıntı arasında önce biraz geri çekilir). Sahne her temada koyu.
import NoraCekirdek
import SwiftUI
import UIKit

@MainActor
struct DersGorAdimi: View {
    let model: PekistirmeModeli
    let b: DersBilgisi
    let eserler: [GorEseri]
    let geri: () -> Void
    let bitir: () -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var konum = 0
    @State private var gorulen = 0
    @State private var hazir = false
    /// Ölçüler (sahneye göre): üst çubuğun altı ve panelin üstü
    @State private var ustAlt: CGFloat = 64
    @State private var panelUst: CGFloat = 540
    @State private var sahneBoyu: CGSize = .zero
    @State private var kamera = GorKamerasi()
    @State private var metinNo = 0

    private var kareler: [GorKaresi] { DersAdimKurallari.gorKareleri(eserler.map(\.noktalar.count)) }
    private var hareketAz: Bool { tema.ayar.hareketAzaltilmis }

    var body: some View {
        let kareler = self.kareler
        let k = kareler[min(konum, kareler.count - 1)]
        let es = eserler[k.ei]
        let katalog = model.katalog
        let kisa = katalog.map { DersAdimKurallari.kisaAd(es.sanatci, katalog: $0) } ?? ""
        let eserAdi = katalog.map { DersAdimKurallari.yuruyusEserAdi(es, katalog: $0) } ?? es.eser
        let y = DersAdimKurallari.gorYazilari(eserler: eserler, kareler: kareler, konum: konum, kisaAd: kisa, eserAdi: eserAdi)

        GeometryReader { g in
            let guvenli = g.safeAreaInsets
            ZStack(alignment: .top) {
                DersRenkleri.sahne.zemin

                GorSahnesi(kamera: kamera)
                    .accessibilityLabel(DersAdimKurallari.gorEserAdi(es, kisaAd: kisa, eserAdi: eserAdi))
                    .accessibilityAddTraits(.isImage)

                // `.ders-gor-perde`
                LinearGradient(stops: [
                    .init(color: DersRenkleri.sahne.zemin.opacity(0.86), location: 0),
                    .init(color: DersRenkleri.sahne.zemin.opacity(0), location: 0.17),
                ], startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    DersAdimUst(
                        etiket: DersAdimKurallari.ustEtiketi(akim: b.akim, adim: .gor, adimlar: b.adimlar),
                        baslik: "Gör",
                        durum: b.durum,
                        adim: .gor,
                        sahne: true,
                        geri: geri
                    )
                    .padding(.top, guvenli.top + 12)
                    .padding(.horizontal, 16)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("gor-sahne")).maxY } action: { ustAlt = $0 }

                    Spacer(minLength: 0)

                    panel(y, k: k, es: es, guvenliAlt: guvenli.bottom, ekranBoyu: g.size.height + guvenli.top + guvenli.bottom)
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("gor-sahne")).minY } action: { panelUst = $0 }
                }
            }
            .coordinateSpace(.named("gor-sahne"))
            .ignoresSafeArea()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { sahneBoyu = $0 }
        }
        .environment(\.colorScheme, .dark)
        .accessibilityIdentifier("ders-gor")
        .task {
            let toplam = b.gor.toplam
            konum = DersAdimKurallari.gorBaslangici(kareler, i: b.kayit.gor.i, toplam: toplam)
            gorulen = DersAdimKurallari.gorulen(i: b.kayit.gor.i, toplam: toplam)
            hazir = true
            await resmiYukle()
        }
        .onChange(of: konum) { eski, yeni in
            let kr = kareler
            guard kr.indices.contains(eski), kr.indices.contains(yeni) else { return }
            if kr[eski].ei != kr[yeni].ei { Task { await resmiYukle() } } else { kameraKur(aninda: false) }
        }
        .onChange(of: panelUst) { _, _ in kameraKur(aninda: !kamera.hareketli) }
        .onChange(of: ustAlt) { _, _ in kameraKur(aninda: true) }
        .onChange(of: sahneBoyu) { _, _ in kameraKur(aninda: true) }
        #if DEBUG
        .task {
            // CI karşılaştırması: resim yerine oturunca işaret
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            DersKarsilastirma.hazirYaz()
        }
        #endif
    }

    // MARK: Panel (`.ders-gor-panel`)

    @ViewBuilder
    private func panel(_ y: GorYazilari, k: GorKaresi, es: GorEseri, guvenliAlt: CGFloat, ekranBoyu: CGFloat) -> some View {
        let s = DersRenkleri.sahne
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                Text(y.eser)
                    .font(Yazi.sans(13, stil: .footnote))
                    .cssSatir(.sans, 13, 17.55)
                    .foregroundStyle(s.yazi2)
                // `.ders-gor-panel h2`: 28/1.1, `text-wrap: balance` (Z3b: satır arası ve kırılım sitedeki gibi)
                CssBaslik(metin: y.baslik, boyut: 28, satir: 30.8)
                    .foregroundStyle(s.yazi)
                    .accessibilityAddTraits(.isHeader)
                GorMetni(metin: y.metin, enCok: ekranBoyu * 0.34)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(metinNo)
            .transition(hareketAz ? .identity : .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 10)),
                removal: .opacity.animation(.timingCurve(0.4, 0, 1, 1, duration: 0.15))
            ))

            HStack(spacing: 10) {
                // `.ders-noktalar`
                HStack(spacing: 6) {
                    ForEach(es.noktalar.indices, id: \.self) { i in
                        Circle()
                            .fill(i < k.ni ? Color(RGBA(css: "#8f7c4f")!) : i == k.ni ? Color(RGBA(css: "#ecd08f")!) : s.iz)
                            .frame(width: 8, height: 8)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(y.noktalar)
                .frame(maxWidth: .infinity, alignment: .leading)

                if !y.geriGizli {
                    Button("Geri") { git(konum - 1) }
                        .buttonStyle(DersDugme(tur: .sahneBos, yatay: 20))
                        .accessibilityIdentifier("gor-geri")
                }
                Button(y.ileri) { ileri() }
                    .buttonStyle(DersDugme(tur: .sahneDolu, yatay: 20))
                    .accessibilityIdentifier("gor-ileri")
            }
            .padding(.top, 6)
        }
        .padding(.top, 34)
        .padding(.horizontal, 22)
        .padding(.bottom, guvenliAlt + 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(stops: [
                .init(color: s.zemin.opacity(0), location: 0),
                .init(color: s.zemin.opacity(0.94), location: 0.09),
                .init(color: s.zemin, location: 0.17),
            ], startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: Gezinme

    private func git(_ yeni: Int) {
        guard kareler.indices.contains(yeni) else { return }
        if hareketAz {
            konum = yeni
            metinNo += 1
        } else {
            withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.52).delay(0.12)) {
                konum = yeni
                metinNo += 1
            }
        }
    }

    /// `gorIleri`: ayrıntı ilk kez geçiliyorsa ilerleme yazılır; son karede adım biter
    private func ileri() {
        let kr = kareler
        let k = kr[konum]
        let toplam = b.gor.toplam
        if let yeni = DersAdimKurallari.gorIlerle(k, gorulen: gorulen) {
            gorulen = yeni
            let son = konum >= kr.count - 1
            Task {
                await model.dersAdimiIsle(akim: b.akim, adim: .gor, gorulen: yeni, toplam: toplam)
                if son { bitir() }
            }
            if son { return }
        } else if konum >= kr.count - 1 {
            bitir()
            return
        }
        git(konum + 1)
    }

    // MARK: Resim ve kamera

    /// `gorResmiYukle`: 1280'lik kopya (`yuruyusAdresleri`), gelince yerine oturur; varsa büyük kopya arkadan
    private func resmiYukle() async {
        guard let katalog = model.katalog else { return }
        let ei = kareler[konum].ei
        let es = eserler[ei]
        let adres = katalog.gorsel.yuruyusAdresleri(ad: es.gorsel, buyuk: es.buyuk)
        guard let resim = await GorselCozucu.shared.resim(URL(string: adres.kucuk), piksel: 1280) else {
            kamera.resimsiz(ei: ei)
            return
        }
        guard kareler[konum].ei == ei else { return }
        let boyut = CGSize(width: resim.size.width * resim.scale, height: resim.size.height * resim.scale)
        kamera.yeniResim(ei: ei, resim: resim, boyut: boyut)
        kameraKur(aninda: hareketAz, oturma: !hareketAz)
        if !adres.buyuk.isEmpty, let buyuk = await GorselCozucu.shared.resim(URL(string: adres.buyuk), piksel: 2560) {
            kamera.keskinlestir(ei: ei, resim: buyuk)
        }
    }

    /// `gorKamera(aninda)`: kamera hedefe gider (anında ya da o an bulunduğu yerden yumuşak yolla)
    private func kameraKur(aninda: Bool, oturma: Bool = false) {
        guard hazir, let boyut = kamera.boyut, sahneBoyu.width > 0 else { return }
        let kr = kareler
        let k = kr[min(konum, kr.count - 1)]
        guard k.ei == kamera.ei else { return }
        let n = k.ni >= 0 ? eserler[k.ei].noktalar[k.ni] : nil
        let h = DersKamerasi.hedef(
            W: sahneBoyu.width,
            ust: ustAlt + 8,
            alt: panelUst - 8,
            resim: (boyut.width, boyut.height),
            nokta: n.map { ($0.x, $0.y, $0.w, $0.h) }
        )
        kamera.git(h.p, W: sahneBoyu.width, orta: h.orta, aninda: aninda || hareketAz, oturma: oturma)
    }
}

/// `.ders-gor-metin`: en çok ekranın %34'ü; uzunsa kendi içinde kayar
private struct GorMetni: View {
    let metin: String
    let enCok: CGFloat

    var body: some View {
        let t = Text(metin)
            .font(Yazi.okuma(18))
            .cssSatir(.okuma, 18, 27)
            .foregroundStyle(DersRenkleri.sahne.metin)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        ViewThatFits(in: .vertical) {
            t
            ScrollView { t }.frame(height: enCok)
        }
        .frame(maxHeight: enCok)
    }
}

// MARK: - Kamera durumu

/// Sahnedeki resim katmanları ve kameranın hareketi. Yeni eserin resmi ayrı katmanda gelir; eski katman yerinde kalıp
/// solar (çapraz geçiş). Kamera `DersKamerasi.kameraYolu` ile yürür ya da yeni resimde yerine oturur.
struct GorKamerasi {
    struct Katman: Identifiable {
        let id: Int
        var resim: UIImage
        let boyut: CGSize
        let gelis: Date
        var gidis: Date?
        var sabit: KameraDurusu?
    }

    enum Hareket {
        case yol(KameraYolu)
        /// yerine oturma: biraz yakından başlar, yavaşça geri çekilir (1.6 sn)
        case oturma(KameraDurusu, KameraDurusu)
    }

    var katmanlar: [Katman] = []
    var ei: Int?
    var boyut: CGSize?
    var durus: KameraDurusu?
    var hareket: Hareket?
    var baslangic = Date()
    var sure: Double = 0
    var yokOlmaSonu = Date.distantPast

    static let oturmaEgrisi = DersKamerasi.egri(0.15, 0.6, 0.25, 1)

    var hareketli: Bool { hareket != nil && Date().timeIntervalSince(baslangic) < sure }
    var canli: Date { max(baslangic.addingTimeInterval(sure), yokOlmaSonu) }

    /// O anki duruş (hareket sürüyorsa yolun üstündeki yer)
    func simdiki(_ an: Date) -> KameraDurusu? {
        guard let durus else { return nil }
        guard let hareket, sure > 0 else { return durus }
        let t = min(1, max(0, an.timeIntervalSince(baslangic) / sure))
        switch hareket {
        case .yol(let y): return y.ornek(DersKamerasi.kameraEgrisi(t))
        case .oturma(let a, let b):
            let e = Self.oturmaEgrisi(t)
            return KameraDurusu(tx: a.tx + (b.tx - a.tx) * e, ty: a.ty + (b.ty - a.ty) * e, s: a.s + (b.s - a.s) * e)
        }
    }

    mutating func yeniResim(ei: Int, resim: UIImage, boyut: CGSize) {
        let an = Date()
        let son = simdiki(an)
        for i in katmanlar.indices where katmanlar[i].gidis == nil {
            katmanlar[i].gidis = an
            katmanlar[i].sabit = son
        }
        katmanlar.removeAll { $0.gidis.map { an.timeIntervalSince($0) > 1.1 } ?? false }
        katmanlar.append(Katman(id: ei * 1000 + katmanlar.count, resim: resim, boyut: boyut, gelis: an))
        self.ei = ei
        self.boyut = boyut
        durus = nil
        hareket = nil
        yokOlmaSonu = an.addingTimeInterval(1.1)
    }

    mutating func resimsiz(ei: Int) {
        self.ei = ei
        boyut = nil
    }

    mutating func keskinlestir(ei: Int, resim: UIImage) {
        guard self.ei == ei, let i = katmanlar.lastIndex(where: { $0.gidis == nil }) else { return }
        katmanlar[i].resim = resim
    }

    mutating func git(_ hedef: KameraDurusu, W: Double, orta: Double, aninda: Bool, oturma: Bool) {
        let an = Date()
        if oturma, !aninda {
            let g = DersKamerasi.gorusAlani(hedef, W: W, orta: orta)
            let bas = DersKamerasi.durusa(GorusAlani(ux: g.ux, uy: g.uy, w: g.w / 1.06), W: W, orta: orta)
            hareket = .oturma(bas, hedef)
            baslangic = an
            sure = 1.6
            durus = hedef
            return
        }
        guard !aninda, let simdi = simdiki(an) else {
            durus = hedef
            hareket = nil
            sure = 0
            return
        }
        let yol = DersKamerasi.kameraYolu(simdi, hedef, W: W, orta: orta)
        durus = hedef
        if yol.uzunluk < 0.002 {
            hareket = nil
            sure = 0
            return
        }
        hareket = .yol(yol)
        baslangic = an
        sure = Double(yol.sure) / 1000
    }
}

/// `.ders-gor-sahne`: katmanlar kameranın duruşuyla çizilir (transform-origin 0 0: x = tx, y = ty, ölçek s)
private struct GorSahnesi: View {
    let kamera: GorKamerasi
    @Environment(TemaDeposu.self) private var tema
    @State private var tik = 0

    var body: some View {
        let durgun = tik >= 0 && (tema.ayar.hareketAzaltilmis || Date() > kamera.canli)
        TimelineView(.animation(minimumInterval: nil, paused: durgun)) { z in
            Canvas { c, _ in
                let an = z.date
                let simdi = kamera.simdiki(an)
                for k in kamera.katmanlar {
                    let p: KameraDurusu?
                    var saydamlik: Double
                    if let gidis = k.gidis {
                        p = k.sabit
                        // `img.gidiyor`: 0.9 sn, 0.15 sn gecikmeyle solar
                        saydamlik = tema.ayar.hareketAzaltilmis ? 0 : 1 - min(1, max(0, (an.timeIntervalSince(gidis) - 0.15) / 0.9))
                    } else {
                        p = simdi
                        // `img.acik`: 0.8 sn'de belirir
                        saydamlik = tema.ayar.hareketAzaltilmis ? 1 : min(1, an.timeIntervalSince(k.gelis) / 0.8)
                    }
                    guard let p, saydamlik > 0 else { continue }
                    c.opacity = saydamlik
                    c.draw(Image(uiImage: k.resim), in: CGRect(x: p.tx, y: p.ty, width: k.boyut.width * p.s, height: k.boyut.height * p.s))
                }
            }
        }
        // hareket bitince TimelineView durur; yeniden çizim için hareketin sonunda bir kez tetiklenir
        .task(id: kamera.canli) {
            let kalan = kamera.canli.timeIntervalSinceNow
            guard kalan > 0 else { return }
            try? await Task.sleep(nanoseconds: UInt64((kalan + 0.05) * 1_000_000_000))
            if !Task.isCancelled { tik += 1 }
        }
        .ignoresSafeArea()
    }
}

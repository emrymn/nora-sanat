// Kaynak: sanat-atlasi js/ekranlar/basyapit.js (basyapitSayfasi, ayrintiHtml, kirpResmi, kunyeHtml, dersiBagla,
// basyapitDersSayfasi), js/basyapitSayfa.js, js/eserDersi.js, js/hikaye.js (hikayeHtml), css/app.css (.bsy*, .hikaye-bolum)
// @ a866b86. Kurallar: NoraCekirdek/Basyapit (kâhin: Testler/kahin/basyapit.mjs).
// Ölçüler canlı sitenin hesaplanmış stillerinden (iPhone 15 Pro, 393 pt, Gece).
import NoraCekirdek
import SwiftUI

/// Eser derslerinin yayın kapısı ve ders dosyaları (`dersYayini`, `DERS.json`, `DERS_ORTA.md`); bellekte tutulur
@MainActor
final class DersDeposu {
    let depo: SiteVerisi
    private var yayin: DersYayini?
    private var dersler: [String: (ders: JSONDeger?, orta: String)] = [:]

    init(depo: SiteVerisi) { self.depo = depo }

    func yayinAl() async -> DersYayini {
        if let yayin { return yayin }
        let y = DersYayini((await depo.veri("ders_yayin.json")).flatMap { try? JSONDeger.coz($0) })
        if !y.dersler.isEmpty { yayin = y }
        return y
    }

    func ders(_ klasor: String) async -> (ders: JSONDeger?, orta: String) {
        if let d = dersler[klasor] { return d }
        guard let jy = DersYayini.yol(klasor, "DERS.json"), let my = DersYayini.yol(klasor, "DERS_ORTA.md") else { return (nil, "") }
        let depo = self.depo
        async let j = depo.kokDosyasi(jy)
        async let m = depo.kokDosyasi(my)
        let d = (await j).flatMap { try? JSONDeger.coz($0) }
        let orta = (await m).flatMap { String(data: $0, encoding: .utf8) }.map(DersMetni.temizle) ?? ""
        let sonuc = (d, orta)
        if d != nil || !orta.isEmpty { dersler[klasor] = sonuc }
        return sonuc
    }
}

/// `basyapitSayfasi(anahtar, { derin })` (İş 188): tek akış. Tablo kapakta; yakın okuma bölümleri hikâye gibi akar,
/// rehberli inceleme ayrıntıları metnin anlattığı yerde kırpım olarak araya girer (dokununca görüntüleyici o ayrıntıda
/// açılır), ders "Daha derine in" ile aynı sayfada açılır; sözlük terimleri metinde, künye ve sıradaki eser sonda.
struct YakinOkuma: View {
    let b: Basyapit
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let baglam: BasyapitBaglami?
    let dersler: DersDeposu
    var derinAcik = false
    let eylem: GaleriEylemleri
    @Environment(TemaDeposu.self) private var tema

    @State private var ders: DersDurumu?
    @State private var metinler: BasyapitSayfasi.Metinler?
    @State private var derin = false
    @State private var sozcuk: BasyapitSayfasi.Terim?
    @State private var cubuk = false
    @State private var koleksiyonda = false
    @State private var yanYana: YanYanaSecimi?

    /// Dersten gelenler (`dersiBagla`)
    struct DersDurumu {
        var durum: DersYayini.Durum
        var kunye: [BasyapitSayfasi.KunyeSatiri]
        var terimler: [BasyapitSayfasi.Terim]
        var kiyaslar: [BasyapitSayfasi.Karsilastirma]
        var bolumler: [BasyapitSayfasi.DersBolumu]
        var dakika: Int
    }

    private var k: SiteKatalogu { galeri.katalog }
    private var s: Sanatci? { k.harita[b.sanatci] }
    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }
    private var eser: Eser? { BasyapitKurallari.eser(galeri.eserler[b.sanatci] ?? [], b) }
    private var gorsel: Gorsel? { eser.flatMap { GorselAdresleri.secilen($0, kotuler: il.kotuGorseller) } }
    /// Resmin yüksekliği / genişliği (yerel kopyanın oranından; bilinmiyorsa nil)
    private var oran: Double? { gorsel.flatMap { k.gorsel.oran($0) }.map { 1 / $0 } }
    /// Rehberli inceleme kaydı (`ayrintiBul(anahtar) || eserinAyrintisi(e)`); görseli yoksa yok
    private var kayit: AyrintiKaydi? {
        guard gorsel != nil, let baglam else { return nil }
        return AyrintiKurallari.ayrintiBul(baglam.ayrintilar, anahtar: b.anahtar) ?? baglam.ayrinti(eser)
    }
    private var yerler: [[Int]]? {
        guard let kayit, oran != nil else { return nil }
        return BasyapitSayfasi.noktalariYerlestir(b.bolumler, kayit.noktalar)
    }

    var body: some View {
        let r = tema.renkler
        let donem = s.map { Donem.akimin(k, $0.akim).id }
        ZStack(alignment: .top) {
            ScrollViewReader { kaydir in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        kapak.id("bas")
                        bas
                        if let baglam, let h = baglam.hikaye(eser) { HikayeBolumu(h: h) }
                        let ilkAyrinti = yerler?.firstIndex { !$0.isEmpty }
                        ForEach(Array(b.bolumler.enumerated()), id: \.offset) { i, x in
                            OkumaBolumu(baslik: x.baslik) {
                                MetinGorunumu(html: metinler?.bolumler[safe: i] ?? JSMetinKacis.kacis(x.metin), duz: true)
                                ayrintilar(yerler?[safe: i] ?? []).id(i == ilkAyrinti ? "okuma-ayrinti" : "ayrinti-\(i)")
                            }
                        }
                        if baglam != nil, kayit == nil, !b.bak.isEmpty {
                            OkumaBolumu(baslik: "Yakından bak") { NumaraliListe(maddeler: b.bak) }
                        }
                        derinBolumu(kaydir)
                        sonBolumler
                    }
                    .padding(.horizontal, BenOlcu.yan)
                    .padding(.bottom, 96)
                    .environment(\.openURL, OpenURLAction { url in bagla(url) })
                }
                .coordinateSpace(name: "okuma")
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)
                .onPreferenceChange(BaslikYeri.self) { y in
                    let acik = y < 0
                    if acik != cubuk { withAnimation(.easeOut(duration: 0.25)) { cubuk = acik } }
                }
                .overlay(alignment: .top) { ustCubuk(kaydir) }
                #if DEBUG
                // CI karşılaştırması: ayrıntılar ve ders gelince istenen bölüme kay ya da yan yana aç
                .task(id: baglam != nil && ders != nil) {
                    guard baglam != nil, let d = ders else { return }
                    if GaleriKarsilastirma.bolum == "yanyana" {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        if let x = d.kiyaslar.first(where: { $0.anahtar != nil }) { yanYanaAc(x) }
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        try? Data().write(to: GaleriKarsilastirma.hazir)
                        return
                    }
                    for id in ["okuma-ayrinti", "okuma-derin", "okuma-son"] { await GaleriKarsilastirma.kaydir(kaydir, id) }
                }
                #endif
            }
        }
        // `bottom: calc(var(--sekme-alt) + var(--sekme-h) + 34px)`: dişli dilin de üstünde (CI'da siteyle ölçüldü)
        .overlay(alignment: .bottom) { altOgeler.padding(.bottom, 83) }
        .background(SayfaZemini(donem: donem, tablo: eser.flatMap { resim.url($0, 400) }))
        .tint(Color(r.murekkep))
        .task(id: b.anahtar) { await yukle() }
        .task(id: "\(baglam != nil)|\(ders != nil)|\(derin)") { metinleriKur() }
        .fullScreenCover(item: $yanYana) { x in YanYana(secim: x) { eylem.git(.okuma(x.anahtar)) } }
        .onAppear { if derinAcik { derin = true } }
    }

    // MARK: Veri

    private func yukle() async {
        if let il = try? await IlerlemeKoprusu.shared.oku() { koleksiyonda = KoleksiyonKurallari.koleksiyondaMi(il, eser: eser) }
        let yayin = await dersler.yayinAl()
        let durum = yayin.durum(b.anahtar, gelistirici: il[alan: "gelistirici"]?.dogru ?? false)
        guard DersYayini.gorunur(durum), let klasor = yayin.klasor(b.anahtar) else { return }
        let (d, orta) = await dersler.ders(klasor)
        guard !Task.isCancelled else { return }
        let liste = galeri.basyapitlar
        ders = DersDurumu(durum: durum, kunye: BasyapitSayfasi.kunyeSatirlari(b, d), terimler: BasyapitSayfasi.sozlukAl(d),
                          kiyaslar: BasyapitSayfasi.karsilastirmalariAl(d, liste, bu: b.anahtar) { k.harita[$0]?.ad ?? "" },
                          bolumler: BasyapitSayfasi.dersBolumleri(orta), dakika: BasyapitSayfasi.okumaDakikasi(orta))
    }

    private func metinleriKur() {
        let d = ders
        metinler = BasyapitSayfasi.metinler(b, yerler: yerler, noktalar: kayit?.noktalar ?? [], derin: d?.bolumler ?? [],
                                            kiyasVar: !(d?.kiyaslar.isEmpty ?? true), terimler: d?.terimler ?? [])
    }

    /// Metindeki bağlantılar: sözlük terimi, sanatçı, akım
    private func bagla(_ url: URL) -> OpenURLAction.Result {
        switch url.scheme {
        case "nora-terim":
            if let i = Int(url.host ?? ""), let t = ders?.terimler[safe: i] { withAnimation(.easeOut(duration: 0.3)) { sozcuk = t } }
        case "nora-sanatci": eylem.git(.sanatci(b.sanatci))
        case "nora-akim": if let s { eylem.git(.akim(s.akim)) }
        default: return .systemAction
        }
        return .handled
    }

    // MARK: Kapak

    /// `.bsy-kapak`: kenardan kenara (en çok ekranın %74'ü, `object-position: 50% 28%`); üstte gölge, altta zemine
    /// eriyen geçiş (dik tablolarda %42 yükseklikte), sol üstte geri, sağ üstte kalp
    private var kapak: some View {
        let r = tema.renkler
        let ekran = UIScreen.main.bounds
        let w = ekran.width
        let dik = (oran ?? 0) >= 1.05
        let h = gorsel == nil ? 200 : min(w * CGFloat(oran ?? 1.25), ekran.height * 0.74)
        return ZStack(alignment: .top) {
            Color(r.yuzey)
            if let e = eser, gorsel != nil {
                Button { eylem.goruntule(e, false, nil) } label: {
                    GeometryReader { g in
                        let ih = w * CGFloat(oran ?? 1.25)
                        resim.gorsel(e, 1200, kip: .fill)
                            .frame(width: w, height: max(ih, g.size.height))
                            .offset(y: -max(0, ih - g.size.height) * 0.28)
                    }
                    .clipped()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(b.baslik) — büyüt")
            } else {
                Text("Bu eserin görseli bulunamadı.").font(Yazi.sans(14, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.38), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: guvenliUst + 96)
                Spacer(minLength: 0)
                LinearGradient(stops: dik
                               ? [.init(color: Color(r.zemin, 0), location: 0), .init(color: Color(r.zemin, 0.82), location: 0.64), .init(color: Color(r.zemin), location: 1)]
                               : [.init(color: Color(r.zemin, 0), location: 0), .init(color: Color(r.zemin), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: dik ? h * 0.42 : 56)
            }
            .allowsHitTesting(false)
            HStack {
                Button(action: eylem.geri) { GaleriIkon(simge: .geri, boyut: 22, kalinlik: 1.4) }
                    .buttonStyle(CamDugme())
                    .accessibilityLabel("Geri")
                Spacer()
                if let e = eser, gorsel != nil {
                    Button { Task { await kalp(e) } } label: {
                        GaleriIkon(simge: .kalp, boyut: 21, kalinlik: 1.7, dolu: koleksiyonda)
                    }
                    .buttonStyle(CamDugme())
                    .accessibilityLabel("Koleksiyona ekle")
                    .accessibilityAddTraits(koleksiyonda ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, guvenliUst + 8)
        }
        .frame(width: w, height: h)
        .clipped()
        .padding(.horizontal, -BenOlcu.yan)
        .padding(.bottom, dik ? -64 : 16)
    }

    private var guvenliUst: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 59
    }

    private func kalp(_ e: Eser) async {
        let bugun = GunTarihi.gun(Date())
        var yeni = !koleksiyonda
        do {
            try await IlerlemeKoprusu.shared.degistir { il in yeni = KoleksiyonKurallari.degistir(&il, eser: e, tarih: bugun) }
            koleksiyonda = yeni
        } catch {}
    }

    // MARK: Başlık

    /// `.bsy-bas`: akım etiketi (dokununca akım), 34 px Bodoni ad, "Sanatçı · tarih · müze", özgün ad, giriş
    private var bas: some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 0) {
            if let s {
                Button { eylem.git(.akim(s.akim)) } label: { Etiket(s.akim).frame(minHeight: 32, alignment: .bottomLeading) }
                    .buttonStyle(.plain)
            }
            Text(b.gorunenBaslik).font(Yazi.serif(34, agirlik: 500, stil: .largeTitle)).tracking(-0.34).cssSatir(.serif, 34, 38.08)
                .foregroundStyle(Color(r.murekkep))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                .background(GeometryReader { g in
                    Color.clear.preference(key: BaslikYeri.self, value: g.frame(in: .named("okuma")).maxY)
                })
            Text(metaSatiri).font(Yazi.sans(15, stil: .subheadline)).cssSatir(.sans, 15, 22)
                .foregroundStyle(Color(r.murekkep2))
                .padding(.top, 8)
            if let o = b.ozgunSatiri {
                Text(o).font(Yazi.okuma(15, italik: true, stil: .subheadline)).cssSatir(.okuma, 15, 22)
                    .foregroundStyle(Color(r.murekkep2)).padding(.top, 2)
            }
            if !b.ozet.isEmpty {
                Text(b.ozet).font(Yazi.okuma(18)).cssSatir(.okuma, 18, 28)
                    .foregroundStyle(Color(r.murekkep))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
            }
        }
    }

    private var metaSatiri: AttributedString {
        var a = AttributedString(s?.ad ?? "")
        a.foregroundColor = Color(tema.renkler.murekkep)
        a.underlineStyle = Text.LineStyle(pattern: .solid, color: Color(tema.renkler.murekkep))
        a.link = URL(string: "nora-sanatci://s")
        for x in [b.tarih, b.muze] where !x.isEmpty { a += AttributedString(" · " + x) }
        return a
    }

    // MARK: Ayrıntılar

    /// `ayrintiHtml(sira)`: tek ayrıntı büyük kırpım (8:5) ve açıklamasıyla; birden çoğu yana kayan şeritte (4:3)
    @ViewBuilder private func ayrintilar(_ sira: [Int]) -> some View {
        let r = tema.renkler
        if let kayit, let e = eser, let oran, !sira.isEmpty {
            if sira.count == 1, let n = kayit.noktalar[safe: sira[0]] {
                VStack(alignment: .leading, spacing: 12) {
                    Button { eylem.goruntule(e, true, sira[0]) } label: {
                        AyrintiKirpimi(eser: e, resim: resim, nokta: n, oran: oran, kutu: BasyapitSayfasi.buyukKutu, pay: 1.8, enCok: 3.2)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(alignment: .bottomTrailing) {
                                GaleriIkon(simge: .buyut, boyut: 16, kalinlik: 1.8)
                                    .foregroundStyle(Color(r.murekkep))
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(.ultraThinMaterial).overlay(Circle().fill(Color(r.ustDugme))))
                                    .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                                    .padding(10)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(n.ad): yakından bak")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(n.ad).font(Yazi.sans(17, agirlik: 600)).cssSatir(.sans, 17, 22).foregroundStyle(Color(r.murekkep))
                        MetinGorunumu(html: metinler?.aciklamalar[sira[0]] ?? JSMetinKacis.kacis(n.metin), duz: true,
                                      yazi: .sans(15), satir: 22, renk: r.murekkep2)
                    }
                }
                .padding(.top, 24)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(sira, id: \.self) { i in
                            if let n = kayit.noktalar[safe: i] {
                                Button { eylem.goruntule(e, true, i) } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        AyrintiKirpimi(eser: e, resim: resim, nokta: n, oran: oran, kutu: BasyapitSayfasi.kucukKutu, pay: 1.4, enCok: 4)
                                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        Text(n.ad).font(Yazi.sans(15, agirlik: 600, stil: .subheadline)).cssSatir(.sans, 15, 20)
                                            .foregroundStyle(Color(r.murekkep))
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(width: 168, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(n.ad): yakından bak")
                            }
                        }
                    }
                    .padding(.horizontal, BenOlcu.yan)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -BenOlcu.yan)
                .padding(.top, 24)
            }
        }
    }

    // MARK: Daha derine in

    /// "Daha derine in" kartı; açılınca ayrıntılı anlatımın bölümleri (karşılaştırma bölümü yerine kartlar) ve "Daha az göster"
    @ViewBuilder private func derinBolumu(_ kaydir: ScrollViewProxy) -> some View {
        let r = tema.renkler
        if let d = ders, !d.bolumler.isEmpty {
            if derin {
                VStack(alignment: .leading, spacing: 0) {
                    if d.durum == .taslak {
                        Text("Taslak ders: yalnız geliştirici modunda görünür.").font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 19)
                            .foregroundStyle(Color(r.murekkep2)).padding(.top, 24)
                    }
                    let kiyasYeri = d.bolumler.contains { $0.karsilastirma }
                    ForEach(Array(d.bolumler.enumerated()), id: \.offset) { i, x in
                        if x.karsilastirma && !d.kiyaslar.isEmpty {
                            kiyasBolumu(d.kiyaslar)
                        } else {
                            OkumaBolumu(baslik: x.baslik) {
                                MetinGorunumu(html: metinler?.derin[safe: i].flatMap { $0 } ?? DersMetni.mdHtml(x.govde))
                            }
                        }
                    }
                    if !kiyasYeri && !d.kiyaslar.isEmpty { kiyasBolumu(d.kiyaslar) }
                    Button {
                        derin = false
                        kaydir.scrollTo("okuma-derin", anchor: .center)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Daha az göster")
                            GaleriIkon(simge: .cik, boyut: 18, kalinlik: 1.8)
                        }
                        .font(Yazi.sans(15, agirlik: 500, stil: .subheadline))
                        .foregroundStyle(Color(r.murekkep2))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 28)
                }
                .id("okuma-derin")
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Etiket("Ayrıntılı okuma · yaklaşık \(d.dakika) dk")
                    Text("Daha derine in").font(Yazi.serif(24, agirlik: 500, stil: .title2)).tracking(-0.24).cssSatir(.serif, 24, 30)
                        .foregroundStyle(Color(r.murekkep)).padding(.top, 6)
                    Text(d.bolumler.prefix(4).map(\.baslik).joined(separator: ", ") + (d.bolumler.count > 4 ? "…" : ""))
                        .font(Yazi.sans(15, stil: .subheadline)).cssSatir(.sans, 15, 22)
                        .foregroundStyle(Color(r.murekkep2)).padding(.top, 6)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { withAnimation(.easeOut(duration: 0.25)) { derin = true } } label: {
                        HStack(spacing: 8) {
                            Text("Okumayı sürdür")
                            GaleriIkon(simge: .asagi, boyut: 18, kalinlik: 1.8)
                        }
                    }
                    .buttonStyle(DoluDugme())
                    .padding(.top, 16)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(r.yuzey)))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                .padding(.top, 36)
                .id("okuma-derin")
            }
        }
    }

    /// Karşılaştırmalar: başyapıt kaydı olan öneri resimli kart (dokununca yan yana), olmayan düz kart
    private func kiyasBolumu(_ l: [BasyapitSayfasi.Karsilastirma]) -> some View {
        let r = tema.renkler
        return OkumaBolumu(baslik: "Karşılaştırmalar") {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(l.enumerated()), id: \.offset) { _, x in
                        let oteki = x.anahtar.flatMap { BasyapitKurallari.bul(galeri.basyapitlar, $0) }
                        let e2 = oteki.flatMap { BasyapitKurallari.eser(galeri.eserler[$0.sanatci] ?? [], $0) }
                        let yazi = VStack(alignment: .leading, spacing: 0) {
                            Text(x.sanatci).font(Yazi.sans(13, agirlik: 600, stil: .footnote)).cssSatir(.sans, 13, 18)
                                .foregroundStyle(Color(r.murekkep2))
                            Text(x.eser).font(Yazi.serif(20, agirlik: 500, stil: .title3)).tracking(-0.2).cssSatir(.serif, 20, 26)
                                .foregroundStyle(Color(r.murekkep)).padding(.top, 2)
                            Text(x.gerekce).font(Yazi.sans(15, stil: .subheadline)).cssSatir(.sans, 15, 22)
                                .foregroundStyle(Color(r.murekkep2)).padding(.top, 4)
                        }
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        if oteki != nil, let e2, eser != nil {
                            Button { yanYanaAc(x) } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    resim.gorsel(e2, 900).frame(width: 280, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    yazi
                                }
                                .frame(width: 280, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(x.eser) ile yan yana aç")
                        } else {
                            yazi.padding(18).frame(width: 280, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(r.yuzey)))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, BenOlcu.yan)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -BenOlcu.yan)
            .padding(.top, 12)
        }
    }

    /// `yanYanaAc({ bu, oteki, k })`: bu eser ve önerinin başyapıt kaydındaki eseri
    private func yanYanaAc(_ x: BasyapitSayfasi.Karsilastirma) {
        guard let e = eser, let oteki = x.anahtar.flatMap({ BasyapitKurallari.bul(galeri.basyapitlar, $0) }),
              let e2 = BasyapitKurallari.eser(galeri.eserler[oteki.sanatci] ?? [], oteki) else { return }
        yanYana = YanYanaSecimi(bu: e, buAd: [b.baslik, b.tarih].filter { !$0.isEmpty }.joined(separator: " · "),
                                oteki: e2, otekiAd: x.eser, k: x, anahtar: oteki.anahtar, resim: resim)
    }

    // MARK: Künye, sözlük, sıradaki

    @ViewBuilder private var sonBolumler: some View {
        let r = tema.renkler
        let kunye = ders?.kunye ?? BasyapitSayfasi.kunyeSatirlari(b, nil)
        if !kunye.isEmpty {
            SonBolum(baslik: "Künye") {
                KutuListe(satirlar: kunye.map { ($0.ad, $0.deger) }, sozluk: false)
            }
            .id("okuma-son")
        }
        if let t = ders?.terimler, !t.isEmpty {
            SonBolum(baslik: "Sözlük") { KutuListe(satirlar: t.map { ($0.ad, $0.tanim) }, sozluk: true) }
        }
        if let sonraki = BasyapitKurallari.sonraki(galeri.basyapitlar, b) {
            let e2 = BasyapitKurallari.eser(galeri.eserler[sonraki.sanatci] ?? [], sonraki)
            SonBolum(baslik: "Sıradaki") {
                Button { eylem.git(.okuma(sonraki.anahtar)) } label: {
                    ZStack(alignment: .bottomLeading) {
                        Color(r.yuzey)
                        if let e2 { resim.gorsel(e2, 900) }
                        LinearGradient(colors: [.black.opacity(0), .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 232 * 0.6).frame(maxHeight: .infinity, alignment: .bottom)
                        VStack(alignment: .leading, spacing: 2) {
                            Text([k.harita[sonraki.sanatci]?.ad ?? "", sonraki.tarih].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(Yazi.sans(13, agirlik: 600, stil: .footnote)).cssSatir(.sans, 13, 18)
                                .foregroundStyle(Color(RGBA(css: "#e6e0d6")!))
                            Text(sonraki.baslik).font(Yazi.serif(22, agirlik: 500, stil: .title2)).tracking(-0.22).cssSatir(.serif, 22, 27)
                                .foregroundStyle(.white)
                        }
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 18).padding(.bottom, 16)
                    }
                    .frame(height: 232)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        Text("Metni Claude yazdı, ikinci bir istekte olgu ve dil açısından denetledi. Yine de hata görürsen not al.")
            .font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 19)
            .foregroundStyle(Color(r.murekkep2))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 24)
    }

    // MARK: Sabit öğeler

    /// `.bsy-cubuk`: başlık ekrandan çıkınca beliren cam çubuk (geri, ad, başa dönen küçük resim)
    private func ustCubuk(_ kaydir: ScrollViewProxy) -> some View {
        let r = tema.renkler
        return HStack(spacing: 0) {
            Button(action: eylem.geri) {
                GaleriIkon(simge: .geri, boyut: 22, kalinlik: 1.8).frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Geri")
            Text(b.gorunenBaslik).font(Yazi.serif(17, agirlik: 500, stil: .headline)).lineLimit(1)
                .frame(maxWidth: .infinity)
            Button { withAnimation { kaydir.scrollTo("bas", anchor: .top) } } label: {
                Group {
                    if let e = eser { resim.gorsel(e, 1200).frame(width: 26, height: 36).clipShape(RoundedRectangle(cornerRadius: 5)) }
                }
                .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Başa dön")
        }
        .foregroundStyle(Color(r.murekkep))
        .padding(.horizontal, 8)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .padding(.top, guvenliUst)
        .background(Color(r.sekmeZemin).background(.ultraThinMaterial))
        .overlay(alignment: .bottom) { Rectangle().fill(Color(r.kenar)).frame(height: 1) }
        .opacity(cubuk ? 1 : 0)
        .allowsHitTesting(cubuk)
        .accessibilityHidden(!cubuk)
    }

    /// Altta: "Yakından bak · n ayrıntı" hapı ya da açık sözlük kartı
    @ViewBuilder private var altOgeler: some View {
        let r = tema.renkler
        if let t = sozcuk {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Etiket("Sözlük")
                    Text(t.ad).font(Yazi.serif(24, agirlik: 500, stil: .title2)).tracking(-0.24).cssSatir(.serif, 24, 30).padding(.top, 4)
                    Text(t.tanim).font(Yazi.sans(16)).cssSatir(.sans, 16, 24).padding(.top, 6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { withAnimation(.easeOut(duration: 0.2)) { sozcuk = nil } } label: {
                    GaleriIkon(simge: .kapat, boyut: 18, kalinlik: 1.8)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color(r.vurgu, 0.16)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Kapat")
            }
            .foregroundStyle(Color(r.murekkep))
            .padding(.top, 20).padding(.leading, 22).padding(.trailing, 14).padding(.bottom, 22)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(r.sekmeZemin)).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 15, y: 10)
            .padding(.horizontal, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Sözlük")
        } else if let kayit, let e = eser {
            Button { eylem.goruntule(e, true, nil) } label: {
                HStack(spacing: 10) {
                    GaleriIkon(simge: .ara, boyut: 20, kalinlik: 1.7)
                    Text("Yakından bak").font(Yazi.sans(16, agirlik: 600))
                    Text("\(kayit.noktalar.count) ayrıntı").font(Yazi.sans(16)).foregroundStyle(Color(r.murekkep2))
                }
                .foregroundStyle(Color(r.murekkep))
                .padding(.leading, 18).padding(.trailing, 22)
                .frame(height: 50)
                .background(Capsule().fill(Color(r.sekmeZemin)).background(.ultraThinMaterial, in: Capsule()))
                .overlay(Capsule().strokeBorder(Color(r.kenar), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 15, y: 10)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: Parçalar

private enum JSMetinKacis {
    static func kacis(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }
}

private struct BaslikYeri: PreferenceKey {
    static var defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// `.bsy-kalp`, `.bsy-cam`: 44 px cam daire
struct CamDugme: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }
    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        var body: some View {
            configuration.label
                .foregroundStyle(Color(tema.renkler.murekkep))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial).overlay(Circle().fill(Color(tema.renkler.ustDugme))))
                .overlay(Circle().strokeBorder(Color(tema.renkler.kenar), lineWidth: 1))
                .contentShape(Circle())
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

/// `.bsy-dugme`: tek dolu düğme (48 px, mürekkep zemin, 600 16 px)
struct DoluDugme: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Govde(configuration: configuration) }
    private struct Govde: View {
        let configuration: Configuration
        @Environment(TemaDeposu.self) private var tema
        var body: some View {
            configuration.label
                .font(Yazi.sans(16, agirlik: 600))
                .foregroundStyle(Color(tema.renkler.zemin))
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Capsule().fill(Color(tema.renkler.murekkep)))
                .contentShape(Capsule())
                .opacity(configuration.isPressed ? 0.8 : 1)
        }
    }
}

/// `.bsy-bolum`: 44 üstte, 28 px Bodoni başlık, 12 aralık
struct OkumaBolumu<Icerik: View>: View {
    let baslik: String
    @ViewBuilder var icerik: Icerik
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(baslik).font(Yazi.serif(28, agirlik: 500, stil: .title1)).tracking(-0.28).cssSatir(.serif, 28, 33.6)
                .foregroundStyle(Color(tema.renkler.murekkep))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 12)
            icerik
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 44)
    }
}

/// `.bsy-son`: 40 üstte, 22 px Bodoni başlık
private struct SonBolum<Icerik: View>: View {
    let baslik: String
    @ViewBuilder var icerik: Icerik
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(baslik).font(Yazi.serif(22, agirlik: 500, stil: .title2)).tracking(-0.22).cssSatir(.serif, 22, 27.5)
                .foregroundStyle(Color(tema.renkler.murekkep))
                .accessibilityAddTraits(.isHeader)
            icerik
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
    }
}

/// `.bsy-liste`: 20 px köşeli yüzey kutusu; satırlar 14 iç boşluklu, aralarında çizgi. Künyede ad solda, değer sağda;
/// sözlükte terim üstte (600), tanım altta.
private struct KutuListe: View {
    let satirlar: [(String, String)]
    let sozluk: Bool
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        let r = tema.renkler
        VStack(spacing: 0) {
            ForEach(Array(satirlar.enumerated()), id: \.offset) { i, x in
                Group {
                    if sozluk {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(x.0).font(Yazi.sans(15, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                            Text(x.1).font(Yazi.sans(15)).foregroundStyle(Color(r.murekkep2))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            Text(x.0).foregroundStyle(Color(r.murekkep2)).fixedSize()
                            Text(x.1).foregroundStyle(Color(r.murekkep)).multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(Yazi.sans(15))
                    }
                }
                .cssSatir(.sans, 15, 22)
                .padding(.vertical, 14)
                .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Color(r.kenar)).frame(height: 1) } }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
        .padding(.top, 12)
    }
}

/// `ol.bsy-metin.bsy-bak`: numaralı maddeler (18 / 29 Newsreader, 22 girinti, 8 aralık)
private struct NumaraliListe: View {
    let maddeler: [String]
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(maddeler.enumerated()), id: \.offset) { i, m in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(i + 1).").frame(width: 22, alignment: .leading)
                    Text(m).fixedSize(horizontal: false, vertical: true)
                }
                .font(Yazi.okuma(18)).cssSatir(.okuma, 18, 29)
                .foregroundStyle(Color(tema.renkler.murekkep))
            }
        }
    }
}

/// `kirpResmi(n, oran, kutu)`: ayrıntı bölgesini kutuya sığdıran resim yerleşimi (`BasyapitSayfasi.kirpim`)
private struct AyrintiKirpimi: View {
    let eser: Eser
    let resim: GaleriResim
    let nokta: AyrintiNoktasi
    let oran: Double
    let kutu: Double
    let pay: Double
    let enCok: Double
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let k = BasyapitSayfasi.kirpim(nokta, oran: oran, kutu: kutu, pay: pay, enCok: enCok)
        Color(tema.renkler.yuzey)
            .aspectRatio(kutu, contentMode: .fit)
            .overlay {
                GeometryReader { g in
                    let w = g.size.width, h = g.size.height
                    resim.gorsel(eser, 1200, kip: .fill)
                        .frame(width: w * k.w / 100, height: h * k.h / 100)
                        .offset(x: w * k.l / 100, y: h * k.t / 100)
                }
            }
            .clipped()
    }
}

/// `hikayeHtml(h)` (`.basyapit-hikaye`): Ne oluyor?, Kim kimdir?, Ressamla bağı, Gözden kaçanlar
private struct HikayeBolumu: View {
    let h: HikayeKaydi
    @Environment(TemaDeposu.self) private var tema

    private enum Icerik { case paragraf([String]), madde([AttributedString]) }

    var body: some View {
        var l: [(String, Icerik)] = [("Ne oluyor?", .paragraf(h.olay))]
        if !h.kim.isEmpty {
            l.append(("Kim kimdir?", .madde(h.kim.map { c in
                var a = AttributedString(c.ad)
                a.font = Yazi.sans(15, agirlik: 700)
                return a + AttributedString(" " + c.metin)
            })))
        }
        if !h.ressam.isEmpty { l.append(("Ressamla bağı", .paragraf(h.ressam))) }
        if !h.gozden.isEmpty { l.append(("Gözden kaçanlar", .madde(h.gozden.map { AttributedString($0) }))) }
        return OkumaBolumu(baslik: "Hikâyesi") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(l.enumerated()), id: \.offset) { i, x in
                    // `.hikaye-bolum h3`: 600 20 / 26 Newsreader, büyük harf, 0.08em, vurgu rengi; 14 üstte (önceki bölümün
                    // 16'lık alt boşluğuyla birleşir), 8 altta
                    Text(x.0.uppercased(with: Locale(identifier: "tr_TR")))
                        .font(Yazi.okuma(20, agirlik: 600)).tracking(1.6).cssSatir(.okuma, 20, 26)
                        .foregroundStyle(Color(tema.renkler.vurgu))
                        .padding(.top, i == 0 ? 2 : 0).padding(.bottom, 8)
                    icerik(x.1).padding(.bottom, i == l.count - 1 ? 0 : 16)
                }
            }
        }
    }

    @ViewBuilder private func icerik(_ x: Icerik) -> some View {
        switch x {
        case .paragraf(let l):
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(l.enumerated()), id: \.offset) { _, p in
                    Text(p).font(Yazi.okuma(16)).cssSatir(.okuma, 16, 24.8).foregroundStyle(Color(tema.renkler.murekkep))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        case .madde(let l):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(l.enumerated()), id: \.offset) { _, m in
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("•").frame(width: 22, alignment: .leading)
                        Text(m).fixedSize(horizontal: false, vertical: true)
                    }
                    .font(Yazi.okuma(16)).cssSatir(.okuma, 16, 24.8)
                    .foregroundStyle(Color(tema.renkler.murekkep))
                }
            }
        }
    }
}

/// `.bsy-metin` (18 / 29 Newsreader): sitenin ürettiği HTML'in (kaçırılmış metin, `mdHtml`, `terimIsaretle`) yerli hâli.
/// Sözlük terimleri noktalı pirinç altı çizili bağlantı (`nora-terim://i`); kanıt etiketleri gösterilmez.
struct MetinGorunumu: View {
    let html: String
    /// Tek paragraflık düz metin (bölüm metni, ayrıntı açıklaması): alt boşluk yok
    var duz = false
    var yazi: Aile = .okuma(18)
    var satir: CGFloat = 29
    var renk: RGBA?
    @Environment(TemaDeposu.self) private var tema

    enum Aile {
        case okuma(CGFloat), sans(CGFloat)
        var boyut: CGFloat { switch self { case .okuma(let b), .sans(let b): return b } }
        func font(kalin: Bool = false, italik: Bool = false) -> Font {
            switch self {
            case .okuma(let b): return Yazi.okuma(b, agirlik: kalin ? 600 : 400, italik: italik)
            case .sans(let b): return Yazi.sans(b, agirlik: kalin ? 600 : 400)
            }
        }
        var css: Yazi.Aile { if case .sans = self { return .sans }; return .okuma }
    }

    var body: some View {
        let bloklar = MetinBloklari.oku(html)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(bloklar.enumerated()), id: \.offset) { i, b in
                blok(b).padding(.bottom, duz || i == bloklar.count - 1 ? 0 : 16)
            }
        }
        .foregroundStyle(Color(renk ?? tema.renkler.murekkep))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func blok(_ b: MetinBlogu) -> some View {
        switch b {
        case .paragraf(let p):
            metin(p)
        case .baslik(_, let p):
            // `.bsy-metin :is(h3, h4)`: 600 20 / 26 Newsreader, 26 üstte, 8 altta (alt boşluk paragrafınkine eklenmez)
            Text(yaz(p, aile: .okuma(20), kalin: true)).cssSatir(.okuma, 20, 26)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10).padding(.bottom, -8)
        case .liste(let sirali, let l):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(l.enumerated()), id: \.offset) { i, m in
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(sirali ? "\(i + 1)." : "•").font(yazi.font()).frame(width: 22, alignment: .leading)
                        metin(m)
                    }
                }
            }
        case .alinti(let p):
            metin(p).padding(.leading, 40)
        case .cizgi:
            Rectangle().fill(Color(tema.renkler.kenar)).frame(height: 1)
        case .tablo(let bas, let satirlar):
            VStack(alignment: .leading, spacing: 6) {
                if !bas.isEmpty { HStack(alignment: .top) { ForEach(Array(bas.enumerated()), id: \.offset) { _, h in metin(h, kalin: true) } } }
                ForEach(Array(satirlar.enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .top) { ForEach(Array(s.enumerated()), id: \.offset) { _, h in metin(h) } }
                }
            }
        }
    }

    private func metin(_ p: [MetinParcasi], kalin: Bool = false) -> some View {
        Text(yaz(p, aile: yazi, kalin: kalin)).cssSatir(yazi.css, yazi.boyut, satir)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func yaz(_ p: [MetinParcasi], aile: Aile, kalin: Bool = false) -> AttributedString {
        var a = AttributedString()
        for x in p where !x.ust {
            var s = AttributedString(x.metin)
            s.font = x.kod ? Font.system(size: aile.boyut * 0.9, design: .monospaced) : aile.font(kalin: kalin || x.kalin, italik: x.italik)
            if let t = x.terim {
                s.link = URL(string: "nora-terim://\(t)")
                s.underlineStyle = Text.LineStyle(pattern: .dot, color: Color(tema.renkler.pirinc))
            }
            a += s
        }
        return a
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

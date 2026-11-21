// Kaynak: sanat-atlasi js/ekranlar/gozat.js (akimSayfasi, sanatciSatiri), js/ekranlar/akim.js (kimlikDoldur, bolumBasligi,
// tanimaNotlari, eserIzgarasi, pekistirDugmesi, dugmeBilgisi, donemHikayesi, konuDizini, akimKarsilastirSayfasi,
// USLUPLAR, TEKNIKLER), css/app.css (.akim-sahne, .akim-bolum*, .akim-hikaye*, .akim-ipucu*, .akim-eser*, .donem-dugme*,
// .akim-komsu*, .akim-konu-dizin, .akim-karsi*) @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece).
import NoraCekirdek
import SwiftUI

/// Galeri sayfalarının ortak eylemleri (GaleriSekmesi verir)
struct GaleriEylemleri {
    var git: (GaleriYolu) -> Void
    var geri: () -> Void
    /// Görüntüleyici: eser listesi ve başlangıç sırası
    var ac: ([Eser], Int) -> Void
    /// Çalış'ta dönem turu (`#/pekistir/donem/<akım>`)
    var pekistir: (String) -> Void
    /// Tek eseri görüntüleyicide aç (G3): rehberli incelemeyle mi, hangi ayrıntı noktasında
    var goruntule: (Eser, Bool, Int?) -> Void = { _, _, _ in }
}

/// Görsel adresleri (kullanıcının "kötü" işaretlediği görseller atlanır)
struct GaleriResim {
    let galeri: GaleriKatalogu
    let il: Ilerleme
    var k: SiteKatalogu { galeri.katalog }

    func url(_ e: Eser, _ boy: Int = 400) -> URL? { k.gorselAdresi(e, genislik: boy, kotuler: il.kotuGorseller) }
    func yedek(_ e: Eser) -> URL? {
        GorselAdresleri.secilen(e, kotuler: il.kotuGorseller).flatMap { GorselAdresleri.url(k.gorsel.yedek($0)) }
    }
    func oran(_ e: Eser) -> Double? { Temsil.kucukGorsel(e, kotuler: il.kotuGorseller).flatMap(k.gorsel.oran) }
    func gorsel(_ e: Eser, _ boy: Int = 400, kip: ContentMode = .fill) -> UzakGorsel {
        UzakGorsel(url: url(e, boy), icerik: kip, yedek: yedek(e))
    }
    func bilinenAd(_ sid: String) -> String { k.bilinenAd(sid) ?? "" }
}

// MARK: Üslup

/// `akimUslubu(ad)` (USLUPLAR): her akım sayfası kendi döneminin üslubuyla giyinir (bölüm başlıkları, pekiştir düğmesi)
enum AkimUslubu: String {
    case antik, ortacag, ronesans, barok, rokoko, neoklasik, romantik, realizm, empresyonizm, ukiyoe, artnouveau,
         ekspresyonizm, kubizm, dada, surrealizm

    private static let harita: [String: AkimUslubu] = {
        let l: [(AkimUslubu, [String])] = [
            (.antik, ["Antik Yunan ve Roma"]),
            (.ortacag, ["Romanesk", "Gotik", "Uluslararası Gotik"]),
            (.ronesans, ["Erken Rönesans", "Kuzey Rönesansı", "Yüksek Rönesans", "Venedik Rönesansı", "Maniyerizm", "Fransız Klasisizmi"]),
            (.barok, ["İtalyan Barok ve Caravaggizm", "İspanyol Barok", "Flaman Barok", "Hollanda Altın Çağı", "Geç İtalyan Barok"]),
            (.rokoko, ["Rokoko"]),
            (.neoklasik, ["Neoklasisizm", "Akademizm ve Oryantalizm"]),
            (.romantik, ["Romantizm", "Prerafaelitler", "Sembolizm"]),
            (.realizm, ["Barbizon ve Realizm"]),
            (.empresyonizm, ["Empresyonizm", "Post-Empresyonizm"]),
            (.ukiyoe, ["Ukiyo-e (Japon baskısı)"]),
            (.artnouveau, ["Art Nouveau ve Viyana Secession"]),
            (.ekspresyonizm, ["Ekspresyonizm", "Savaş sonrası figürasyon"]),
            (.kubizm, ["Kübizm"]),
            (.dada, ["Dada"]),
            (.surrealizm, ["Sürrealizm"]),
        ]
        return Dictionary(uniqueKeysWithValues: l.flatMap { u, adlar in adlar.map { ($0, u) } })
    }()

    static func bul(_ ad: String) -> AkimUslubu { harita[ad] ?? .ronesans }

    /// `TEKNIKLER`: düğmedeki tablo, dönemin kendi tekniğiyle
    var teknik: String {
        switch self {
        case .antik: return "Mozaik — taş taş döşenir"
        case .ortacag: return "Vitray — ışık camdan süzülür"
        case .ronesans: return "Perspektif — kaçış noktasından kurulur"
        case .barok: return "Chiaroscuro — karanlıktan ışığa"
        case .rokoko: return "Yelpaze — zarafetle açılır"
        case .neoklasik: return "Sütunlar — düzen ve simetri"
        case .romantik: return "Fırtına — sisin ardından şimşek"
        case .realizm: return "Örtü — olduğu gibi, süssüz"
        case .empresyonizm: return "Fırça lekeleri — ışığın izlenimi"
        case .ukiyoe: return "Kalıp baskı — önce çizgi, sonra renk"
        case .artnouveau: return "Kamçı çizgisi — doğadan doğan biçim"
        case .ekspresyonizm: return "Bıçak darbesi — ham duygu"
        case .kubizm: return "Yüzeyler — aynı anda her açıdan"
        case .dada: return "Kolaj — yırt, yapıştır, karıştır"
        case .surrealizm: return "Rüya — akar, süzülür"
        }
    }
}

/// `bolumBasligi(ust, baslik)` (`.akim-bolum-bas`): küçük renkli etiket, büyük serif başlık, altta çizgi ve kısa renkli
/// vurgu. Üsluba göre: Orta Çağ'da düz yazı ve altın baş harf; Rönesans ve Rokoko'da ortalı; Barok'ta altın geçişli çizgi…
struct AkimBolumBasligi: View {
    let ust: String
    let baslik: String
    let uslup: AkimUslubu
    let renk: RGBA
    @Environment(TemaDeposu.self) private var tema
    private static let altin = RGBA(css: "#c9a24a")!

    var body: some View {
        let r = tema.renkler
        let ortali = uslup == .ronesans || uslup == .rokoko
        VStack(alignment: ortali ? .center : .leading, spacing: 4) {
            // `span`: 600 11px/1, 0.18em; renk akımın rengi mürekkeple %45
            Text(ust.uppercased(with: Locale(identifier: "tr_TR")))
                .font(Yazi.sans(11, agirlik: 600, stil: .caption2)).tracking(11 * 0.18)
                .foregroundStyle(Color(GaleriRenk.karis(renk, r.murekkep, 0.45)))
            baslikYazisi(r)
                .multilineTextAlignment(ortali ? .center : .leading)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: ortali ? .center : .leading)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            ZStack(alignment: ortali ? .bottom : .bottomLeading) {
                Rectangle().fill(Color(r.kenar)).frame(height: 1)
                vurguCizgisi.offset(y: 0.5)
            }
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder private func baslikYazisi(_ r: TemaRenkleri) -> some View {
        switch uslup {
        case .ortacag:
            // `::first-letter { font-size: 1.5em; color: var(--altin) }`
            let ilk = String(baslik.prefix(1)), kalan = String(baslik.dropFirst())
            (Text(ilk).font(Yazi.serif(45, stil: .title1)).foregroundColor(Color(Self.altin))
                + Text(kalan).font(Yazi.serif(30, stil: .title1)).foregroundColor(Color(r.murekkep)))
                .cssSatir(.serif, 30, 33)
        case .neoklasik:
            Text(baslik.uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.serif(21, stil: .title1)).tracking(21 * 0.12)
                .foregroundStyle(Color(r.murekkep)).cssSatir(.serif, 21, 23.1)
        case .ekspresyonizm:
            Text(baslik.uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(22, agirlik: 800, stil: .title1))
                .tracking(22 * 0.02).foregroundStyle(Color(r.murekkep)).rotationEffect(.degrees(-1))
        case .barok:
            Text(baslik).font(Yazi.serif(32, italik: true, stil: .title1)).foregroundStyle(Color(r.murekkep))
                .shadow(color: Color(renk, 0.6), radius: 9, y: 2).cssSatir(.serif, 32, 35.2)
        case .realizm, .ukiyoe:
            Text(baslik).font(Yazi.serif(30, stil: .title1)).foregroundStyle(Color(r.murekkep)).cssSatir(.serif, 30, 33)
        case .romantik:
            Text(baslik).font(Yazi.serif(30, italik: true, stil: .title1)).foregroundStyle(Color(r.murekkep))
                .shadow(color: Color(renk, 0.7), radius: 11).cssSatir(.serif, 30, 33)
        default:
            Text(baslik).font(Yazi.serif(30, italik: true, stil: .title1)).foregroundStyle(Color(r.murekkep)).cssSatir(.serif, 30, 33)
        }
    }

    /// `::after`: 44 × 2 akım rengi (üsluba göre değişir)
    @ViewBuilder private var vurguCizgisi: some View {
        switch uslup {
        case .barok:
            LinearGradient(colors: [Color(Self.altin), .clear], startPoint: .leading, endPoint: .trailing).frame(height: 1)
        case .realizm:
            Rectangle().fill(Color(renk, 0.5)).frame(height: 3)
        case .rokoko:
            Circle().fill(Color(renk)).frame(width: 10, height: 10).offset(y: 5)
        case .ukiyoe:
            EmptyView()
        case .ekspresyonizm:
            Rectangle().fill(Color(renk)).frame(height: 5).frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(x: 0.7, anchor: .leading).rotationEffect(.degrees(-1))
        default:
            Rectangle().fill(Color(renk)).frame(width: 44, height: 2)
        }
    }
}

// MARK: Akım salonu

/// `akimSayfasi(ad)` + `kimlikDoldur(ad)`. Sıra en önemliden: sahne → palet ve künye → hikâye → tanıma → eserler →
/// sanatçılar → pekiştir → dönem → karşılaştırma → tipik konular.
struct AkimSalonu: View {
    let ad: String
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri
    @Environment(TemaDeposu.self) private var tema
    @State private var hikayeAcik = false

    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }

    var body: some View {
        let k = galeri.katalog
        let uyeler = k.sanatcilar.filter { $0.akim == ad }.enumerated()
            .sorted { ($0.element.dogum ?? $0.element.olum ?? 0, $0.offset) < ($1.element.dogum ?? $1.element.olum ?? 0, $1.offset) }
            .map(\.element)
        let islenen = il.islenenKume
        let acik = uyeler.filter { $0.konu.map(islenen.contains) == true }
        let kapali = uyeler.filter { $0.konu.map(islenen.contains) != true }
        let eserler = galeri.enBilinenler(ad, il)
        let uslup = AkimUslubu.bul(ad)
        let renk = GaleriRenk.akim(k, ad)
        let r = tema.renkler
        GeometryReader { ekran in
          ScrollViewReader { kaydir in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sahne(uyeler, eserler.first, ust: ekran.safeAreaInsets.top, h: ekran.size.height + ekran.safeAreaInsets.top)
                    VStack(alignment: .leading, spacing: 0) {
                        if let ilk = eserler.first {
                            // `.akim-sahne-kunye`: 12.5 px, `--ink-2`; eser adı italik; dokununca büyür
                            Button { eylem.ac(eserler.map(\.eser), 0) } label: {
                                (Text("Arkadaki eser: \(resim.bilinenAd(ilk.sanatci.id)), ")
                                    + Text(ilk.eser.gorunenAd).italic()
                                    + Text(ilk.eser.tarih.isEmpty ? "" : ", \(ilk.eser.tarih)"))
                                    .font(Yazi.sans(12.5, stil: .footnote)).cssSatir(.sans, 12.5, 17.5)
                                    .foregroundStyle(Color(r.murekkep2))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        }
                        if let b = galeri.bilgi[ad], let metin = b["metin"], !metin.isEmpty {
                            bolum("Kısaca", "Dönemin hikâyesi", uslup, renk) { hikaye(b, metin, renk) }
                        }
                        if let maddeler = galeri.ozellikler[ad], !maddeler.isEmpty {
                            bolum("Göz eğitimi", "Nasıl tanınır?", uslup, renk) { tanima(maddeler, eserler.map(\.eser), renk) }
                        }
                        if !eserler.isEmpty {
                            bolum("Duvardakiler", "En bilinen eserler", uslup, renk) { eserIzgarasi(eserler) }.id("eserler")
                        }
                        bolum("Ustalar", "Sanatçılar", uslup, renk) {
                            GaleriListe(ogeler: acik + kapali) { s in
                                let a = s.konu.map(islenen.contains) == true
                                GaleriSatir(ad: s.ad, alt: a ? s.yillar : "\(s.yillar) · Konu \(SiteYazisi.bulunmaEki(s.konu ?? 0)) açılır",
                                            rozet: s.kaynak == "ek" ? "kurs dışı" : nil,
                                            kare: k.kucukGorselAdresi(s.id, kotuler: il.kotuGorseller), kilitli: !a) {
                                    eylem.git(.sanatci(s.id))
                                }
                            }
                        }
                        if !acik.isEmpty {
                            PekistirKarti(ad: ad, uslup: uslup, adet: acik.count, bilgi: galeri.bilgi[ad],
                                          eser: eserler.first.map { ($0.eser, resim.bilinenAd($0.sanatci.id)) },
                                          gorsel: eserler.first.map { resim.gorsel($0.eser, 800) }) { eylem.pekistir(ad) }
                                .padding(.top, 34)
                                .id("pekistir")
                        }
                        bolum("Zaman çizgisi", "Dönemi", uslup, renk) {
                            DonemCizelgesi(akimlar: k.akimlar, ad: ad) { eylem.git(.akim($0)) }
                        }
                        let komsular = Array((k.akimlar.first { $0.ad == ad }?.komsular ?? [])
                            .filter { x in x != ad && k.akimlar.contains { $0.ad == x } }.prefix(3))
                        if !komsular.isEmpty {
                            bolum("Karıştırma", "Yan yana koy", uslup, renk) { komsuListesi(komsular, renk) }
                        }
                        let tipik = galeri.tipikKonular(ad, il)
                        if !tipik.isEmpty {
                            bolum("Tuvallerde en çok", "Tipik konular", uslup, renk) { konuDizini(tipik, acik, renk) }
                        }
                    }
                    .padding(.horizontal, BenOlcu.yan)
                    .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            #if DEBUG
            .task {
                await GaleriKarsilastirma.kaydir(kaydir, "eserler")
                await GaleriKarsilastirma.kaydir(kaydir, "pekistir")
            }
            #endif
          }
        }
        .background(SayfaZemini(donem: GaleriDonem.akimin(k, ad)))
    }

    private func bolum<I: View>(_ ust: String, _ baslik: String, _ uslup: AkimUslubu, _ renk: RGBA,
                                @ViewBuilder _ icerik: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AkimBolumBasligi(ust: ust, baslik: baslik, uslup: uslup, renk: renk)
            icerik()
        }
        .padding(.top, 34).padding(.bottom, 8)
    }

    // MARK: Sahne

    /// `.akim-sahne.dolu`: en bilinen eser kenardan kenara (min(56vh, 470), en az 320); üstte geri, altta yüzyıllar ve
    /// büyük başlık. Sahne her temada koyu.
    private func sahne(_ uyeler: [Sanatci], _ ilk: (sanatci: Sanatci, eser: Eser)?, ust: CGFloat, h: CGFloat) -> some View {
        let yukseklik = min(470, max(320, h * 0.56))
        let yazi = RGBA(css: "#ebe5da")!
        return ZStack(alignment: .bottomLeading) {
            Color(RGBA(css: "#1a1816")!)
            if let ilk { resim.gorsel(ilk.eser, 960).frame(height: yukseklik).clipped() }
            LinearGradient(stops: [
                .init(color: Color(RGBA(css: "#121110")!, 0.5), location: 0), .init(color: Color(RGBA(css: "#121110")!, 0), location: 0.2),
                .init(color: Color(RGBA(css: "#121110")!, 0), location: 0.44), .init(color: Color(RGBA(css: "#121110")!, 0.82), location: 0.8),
                .init(color: Color(RGBA(css: "#121110")!), location: 1),
            ], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                VurguEtiket(GaleriSergisi.yuzyillar(uyeler))
                Text(ad).font(Yazi.serif(64, agirlik: 500, stil: .largeTitle)).cssSatir(.serif, 64, 64)
                    .foregroundStyle(Color(yazi))
                    .lineLimit(2).minimumScaleFactor(0.5)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.bottom, 12)
        }
        .frame(height: ilk == nil ? nil : yukseklik)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            // `.ust .geri`: 44 px, `rgba(18,17,16,.62)`, %25 açık kenar
            Button(action: eylem.geri) {
                GaleriIkon(simge: .geri, boyut: 22, kalinlik: 1.4).foregroundStyle(Color(yazi))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(RGBA(css: "#121110")!, 0.62)))
                    .overlay(Circle().strokeBorder(Color(yazi, 0.25), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Geri")
            .padding(.top, ust + 18).padding(.leading, 16)
        }
        .clipped()
    }

    // MARK: Hikâye

    /// `donemHikayesi(ad)`: künye (dönem · yerin ilk parçası), birkaç satıra kısaltılmış okuma metni, "Devamını oku"
    private func hikaye(_ b: [String: String], _ metin: String, _ renk: RGBA) -> some View {
        let r = tema.renkler
        let yer = (b["yer"] ?? "").split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        let kunye = [b["donem"] ?? "", yer].filter { !$0.isEmpty }.joined(separator: " · ")
        return VStack(alignment: .leading, spacing: 0) {
            if !kunye.isEmpty {
                Text(kunye).font(Yazi.sans(12, agirlik: 600, stil: .caption1)).tracking(0.48).cssSatir(.sans, 12, 16.8)
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.top, -4).padding(.bottom, 10)
            }
            OkumaMetni(metin: metin)
                .lineLimit(hikayeAcik ? nil : 6)
                .mask {
                    LinearGradient(stops: hikayeAcik ? [.init(color: .black, location: 0), .init(color: .black, location: 1)]
                                   : [.init(color: .black, location: 0), .init(color: .black, location: 0.6), .init(color: .black.opacity(0.15), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                }
            Button {
                withAnimation(.easeOut(duration: 0.3)) { hikayeAcik.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text(hikayeAcik ? "Kısalt" : "Devamını oku")
                    Text(hikayeAcik ? "↑" : "↓")
                }
                .font(Yazi.sans(12, agirlik: 600, stil: .caption1)).tracking(12 * 0.14).textCase(.uppercase)
                .foregroundStyle(Color(GaleriRenk.karis(renk, r.murekkep, 0.45)))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: Tanıma

    /// `tanimaNotlari(l, eserler, palet)`: her ipucunun yanında akımın bir eserinden yakın plan (64 px büyüteç, 2.4 kat);
    /// tek sıradakiler solda, çiftler sağda; Roma rakamı italik.
    private func tanima(_ maddeler: [String], _ eserler: [Eser], _ renk: RGBA) -> some View {
        let r = tema.renkler
        let odaklar: [UnitPoint] = [.init(x: 0.3, y: 0.35), .init(x: 0.68, y: 0.28), .init(x: 0.45, y: 0.7),
                                    .init(x: 0.22, y: 0.6), .init(x: 0.75, y: 0.65), .init(x: 0.5, y: 0.45)]
        let roma = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
        return VStack(spacing: 0) {
            ForEach(Array(maddeler.enumerated()), id: \.offset) { i, madde in
                let eser = eserler.isEmpty ? nil : eserler[i % eserler.count]
                let no = i < roma.count ? roma[i] : String(i + 1)
                HStack(alignment: .center, spacing: 16) {
                    if i % 2 == 1 { yazi(no, madde, eser != nil, renk) }
                    if let eser {
                        let odak = odaklar[i % odaklar.count]
                        resim.gorsel(eser, 400)
                            .scaleEffect(2.4, anchor: odak)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .padding(1).background(Circle().fill(Color(r.kenar)))
                            .padding(3).background(Circle().fill(Color(r.zemin)))
                            .padding(1).background(Circle().fill(Color(RGBA(css: "#a8842c")!, 0.55)))
                            .padding(-5)
                            .accessibilityHidden(true)
                    }
                    if i % 2 == 0 { yazi(no, madde, eser != nil, renk) }
                }
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) { Ayrac() }
            }
        }
    }

    private func yazi(_ no: String, _ madde: String, _ numarali: Bool, _ renk: RGBA) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 4) {
            if numarali {
                Text(no).font(Yazi.okuma(15, italik: true, stil: .subheadline)).tracking(0.6)
                    .foregroundStyle(Color(GaleriRenk.karis(renk, r.murekkep, 0.45)))
            }
            Text(madde).font(Yazi.okuma(18)).cssSatir(.okuma, 18, 25.2).foregroundStyle(Color(r.murekkep))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Eserler

    /// `eserIzgarasi`: iki sütun (14 / 12 aralık); kare çerçeve, 17 px Newsreader ad, "Sanatçı · tarih"
    private func eserIzgarasi(_ l: [(sanatci: Sanatci, eser: Eser)]) -> some View {
        let r = tema.renkler
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                         alignment: .leading, spacing: 14) {
            ForEach(Array(l.enumerated()), id: \.offset) { i, x in
                Button { eylem.ac(l.map(\.eser), i) } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Color(r.yuzey).aspectRatio(1, contentMode: .fit)
                            .overlay(resim.gorsel(x.eser, 400))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        Text(x.eser.gorunenAd).font(Yazi.okuma(17)).cssSatir(.okuma, 17, 20.74)
                            .foregroundStyle(Color(r.murekkep)).multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 12)
                        Text(resim.bilinenAd(x.sanatci.id) + (x.eser.tarih.isEmpty ? "" : " · \(x.eser.tarih)"))
                            .font(Yazi.sans(13, agirlik: 500, stil: .footnote)).cssSatir(.sans, 13, 17.55)
                            .foregroundStyle(Color(r.murekkep2))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(x.eser.gorunenAd) — büyüt")
            }
        }
        .padding(.top, 8).padding(.bottom, 16)
    }

    // MARK: Karşılaştırma, konular

    /// `.akim-komsu-liste a`: iki rengin yarım yarım noktası, "Gotik *ile* Erken Rönesans", sağda ok
    private func komsuListesi(_ komsular: [String], _ renk: RGBA) -> some View {
        let r = tema.renkler
        return VStack(spacing: 0) {
            ForEach(komsular, id: \.self) { x in
                Button { eylem.git(.akimKarsilastir(ad, x)) } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: 0) {
                            Rectangle().fill(Color(renk))
                            Rectangle().fill(Color(GaleriRenk.akim(galeri.katalog, x)))
                        }
                        .frame(width: 22, height: 12).clipShape(Capsule())
                        (Text(ad + " ") + Text("ile").italic() + Text(" " + x))
                            .font(Yazi.okuma(19)).foregroundStyle(Color(r.murekkep))
                            .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                        Text("→").font(Yazi.okuma(19)).foregroundStyle(Color(r.murekkep2))
                    }
                    .padding(.horizontal, 2)
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { Ayrac() }
            }
        }
    }

    /// `konuDizini`: sergi kataloğunun dizini gibi; iri serif adlar (17 + 13 · ağırlık px), üstte eser sayısı, aralarda "·"
    private func konuDizini(_ konular: [GaleriKonusu], _ acik: [Sanatci], _ renk: RGBA) -> some View {
        let r = tema.renkler
        let uye = Set(acik.map(\.id))
        let sayilar = konular.map { k in k.baglar.filter { uye.contains($0.sanatci) }.count }
        let enCok = max(1, sayilar.max() ?? 1)
        return AkisDuzeni(aralik: 8) {
            ForEach(Array(konular.enumerated()), id: \.offset) { i, k in
                let agirlik = 0.55 + 0.45 * Double(sayilar[i]) / Double(enCok)
                HStack(alignment: .top, spacing: 8) {
                    Button { eylem.git(.konu(k.id)) } label: {
                        HStack(alignment: .top, spacing: 2) {
                            Text(k.ad).font(Yazi.serif(17 + 13 * agirlik, stil: .title2))
                                .foregroundStyle(Color(GaleriRenk.karis(r.murekkep, r.murekkep2, agirlik)))
                            Text("\(sayilar[i])").font(Yazi.sans(11, agirlik: 600, stil: .caption2))
                                .foregroundStyle(Color(GaleriRenk.karis(renk, r.murekkep, 0.45)))
                                .padding(.top, 4)
                        }
                    }
                    .buttonStyle(.plain)
                    if i < konular.count - 1 {
                        Text("·").font(Yazi.serif(17)).foregroundStyle(Color(r.murekkep3)).padding(.top, 8)
                    }
                }
            }
        }
    }
}

// MARK: Pekiştir kartı

/// `pekistirDugmesi(ad, uslup, adet)` (`.donem-dugme`): koyu kart; kemerli sahnede dönemin en bilinen eseri, altında
/// "Bu dönemi pekiştir · n sanatçı", akımın adı, teknik, künye, ilk cümle, eser ve "Tura başla →" şeridi. Her temada koyu.
struct PekistirKarti: View {
    let ad: String
    let uslup: AkimUslubu
    let adet: Int
    let bilgi: [String: String]?
    let eser: (Eser, String)?
    let gorsel: UzakGorsel?
    let basla: () -> Void

    private let zemin = RGBA(css: "#16110c")!
    private let yazi = RGBA(css: "#f1e6cf")!
    private let altin = RGBA(css: "#d4ad55")!

    var body: some View {
        Button(action: basla) {
            VStack(alignment: .leading, spacing: 0) {
                // `.donem-sahne`: 18 / 22 kenar boşluğu, üst köşeler %50 / %40 kemer, iki halkalı çerçeve, altın ışık
                ZStack {
                    Color(RGBA(css: "#0a0806")!)
                    gorsel
                }
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 120, topTrailingRadius: 120, style: .continuous))
                .padding(3).background(UnevenRoundedRectangle(topLeadingRadius: 123, topTrailingRadius: 123).fill(Color(RGBA(css: "#0a0806")!)))
                .padding(2).background(UnevenRoundedRectangle(topLeadingRadius: 125, topTrailingRadius: 125).fill(Color(RGBA(css: "#3a2c18")!)))
                .shadow(color: Color(RGBA(css: "#d4ad55")!, 0.45), radius: 23, y: 10)
                .padding(.top, 18).padding(.horizontal, 22)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Bu dönemi pekiştir")
                        Spacer()
                        Text("\(adet) sanatçı")
                    }
                    .font(Yazi.sans(10, agirlik: 700, stil: .caption2)).tracking(2).textCase(.uppercase)
                    .foregroundStyle(Color(altin))
                    Text(ad).font(Yazi.serif(30, stil: .title1)).cssSatir(.serif, 30, 31.2).foregroundStyle(Color(yazi))
                    HStack(spacing: 8) {
                        Rectangle().fill(Color(altin)).frame(width: 18, height: 1)
                        Text(uslup.teknik).font(Yazi.okuma(14, italik: true, stil: .subheadline))
                    }
                    .foregroundStyle(Color(altin))
                    let ozet = Self.dugmeBilgisi(bilgi)
                    if !ozet.kunye.isEmpty {
                        Text(ozet.kunye).font(Yazi.sans(12, agirlik: 600, stil: .caption1)).tracking(0.48)
                            .foregroundStyle(Color(yazi)).opacity(0.8)
                    }
                    if !ozet.soz.isEmpty {
                        Text(ozet.soz).font(Yazi.okuma(15, stil: .subheadline)).cssSatir(.okuma, 15, 22.5)
                            .foregroundStyle(Color(yazi)).lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let x = eser {
                        Text("\(x.0.gorunenAd) — \(x.1)").font(Yazi.okuma(13, italik: true, stil: .footnote)).cssSatir(.okuma, 13, 18.2)
                            .foregroundStyle(Color(yazi)).opacity(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 18).padding(.top, 18)
                // `.donem-dugme-ok`: 58 yükseklik, altın zemin, 700 16 px
                HStack {
                    Text("Tura başla").font(Yazi.sans(16, agirlik: 700)).tracking(0.32)
                    Spacer()
                    Text("→").font(Yazi.sans(20, agirlik: 700))
                }
                .foregroundStyle(Color(zemin))
                .padding(.horizontal, 20)
                .frame(height: 58)
                .background(Color(altin))
                .padding(.top, 16)
            }
            .background(Color(zemin))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color(yazi, 0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.65 * 0.5), radius: 22, y: 22 - 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ad) dönemini pekiştir")
    }

    /// `dugmeBilgisi(ad)`: "dönem · yerin ilk parçası" ve açıklamanın ilk cümlesi (`ILK_CUMLE`)
    static func dugmeBilgisi(_ b: [String: String]?) -> (kunye: String, soz: String) {
        guard let b else { return ("", "") }
        let yer = (b["yer"] ?? "").split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        let kunye = [b["donem"] ?? "", yer].filter { !$0.isEmpty }.joined(separator: " · ")
        let metin = (b["metin"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        // /^(.+?[.!?])(?=\s+[A-ZÇĞİÖŞÜ])/s
        let kalip = try? NSRegularExpression(pattern: "^(.+?[.!?])(?=\\s+[A-ZÇĞİÖŞÜ])", options: [.dotMatchesLineSeparators])
        let ns = metin as NSString
        let cumle = kalip?.firstMatch(in: metin, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range(at: 1)) } ?? metin
        return (kunye, cumle)
    }
}

// MARK: Akım karşılaştırma

/// `akimKarsilastirSayfasi(a, b)`: iki sütun; üstte 4 px akım rengi, ad, yüzyıllar, ilk iki eser, tanıma maddeleri,
/// üç tipik konu hapı
struct AkimKarsilastir: View {
    let a: String
    let b: String
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri
    @Environment(TemaDeposu.self) private var tema

    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GaleriSayfaUst(etiket: "Akım karşılaştır", baslik: "Yan yana", geri: eylem.geri)
                HStack(alignment: .top, spacing: 14) {
                    sutun(a)
                    sutun(b)
                }
            }
            .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: GaleriDonem.akimin(galeri.katalog, a)))
        .sekmeCubuguGizli(true, sekme: .galeri)   // sitede karşılaştırma sekmesiz sayfa
    }

    private func sutun(_ ad: String) -> some View {
        let r = tema.renkler
        let k = galeri.katalog
        let renk = GaleriRenk.akim(k, ad)
        let eserler = Array(galeri.enBilinenler(ad, il).prefix(2))
        let acik = Set(k.sanatcilar.filter { $0.akim == ad && $0.konu.map(il.islenenKume.contains) == true }.map(\.id))
        return VStack(alignment: .leading, spacing: 0) {
            Button { eylem.git(.akim(ad)) } label: {
                HStack(spacing: 6) {
                    AkimNoktasi(renk: k.akimlar.first { $0.ad == ad }?.renk ?? "")
                    Text(ad).font(Yazi.okuma(21)).cssSatir(.okuma, 21, 24.15).foregroundStyle(Color(r.murekkep))
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            Text(GaleriSergisi.yuzyillar(k.sanatcilar.filter { $0.akim == ad }))
                .font(Yazi.sans(12, agirlik: 500, stil: .caption1)).foregroundStyle(Color(r.murekkep2))
                .padding(.top, 2).padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(eserler.enumerated()), id: \.offset) { i, x in
                    Button { eylem.ac(eserler.map(\.eser), i) } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Color(r.yuzey).aspectRatio(1, contentMode: .fit)
                                .overlay(resim.gorsel(x.eser, 400))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            Text(x.eser.gorunenAd).font(Yazi.okuma(17)).cssSatir(.okuma, 17, 20.74)
                                .foregroundStyle(Color(r.murekkep)).multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true).padding(.top, 12)
                            Text(resim.bilinenAd(x.sanatci.id) + (x.eser.tarih.isEmpty ? "" : " · \(x.eser.tarih)"))
                                .font(Yazi.sans(13, agirlik: 500, stil: .footnote)).foregroundStyle(Color(r.murekkep2)).padding(.top, 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 16)
            // `.akim-ozellik li`: 15 px Newsreader, 7 px dikey boşluk, altta çizgi
            // `.akim-ozellik li::before`: sayaç (600 13 px, akımın rengi), 26 px sütun
            ForEach(Array((galeri.ozellikler[ad] ?? []).enumerated()), id: \.offset) { i, m in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(i + 1)").font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                        .foregroundStyle(Color(renk)).frame(width: 20, alignment: .leading)
                    Text(m).font(Yazi.okuma(15, stil: .subheadline)).cssSatir(.okuma, 15, 21).foregroundStyle(Color(r.murekkep))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 7)
                .overlay(alignment: .bottom) { Ayrac() }
            }
            // `.akim-konular a`: 34 px hap, 1 px `--ink` kenar, 13 px
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(galeri.tipikKonular(ad, il).prefix(3))) { konu in
                    let n = konu.baglar.filter { acik.contains($0.sanatci) }.count
                    Button { eylem.git(.konu(konu.id)) } label: {
                        HStack(spacing: 6) {
                            Text(konu.ad).lineLimit(1)
                            Text("\(n)").foregroundStyle(Color(r.murekkep2))
                        }
                        .font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep))
                        .padding(.horizontal, 10).frame(height: 34)
                        .overlay(Capsule().strokeBorder(Color(r.murekkep), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
        }
        .padding(.top, 8)
        .overlay(alignment: .top) { Rectangle().fill(Color(renk)).frame(height: 4) }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// Kaynak: sanat-atlasi js/ekranlar/harita.js (durakPenceresi, kursPenceresi, motifPenceresi, motifEseri, kapakDoldur,
// motifKapakDoldur, pencereAc, yildizHtml, SEVIYE_AD), js/bolum.js (tanismaGruplari, gorulenGruplar, grupSoruSayisi,
// BOLUM_SORU), css/app.css (.harita-pencere, .harita-pencere-ic, .harita-pencere-kapat, .harita-pencere-dugmeler, .hp-kapak*,
// .hp-baslik, .hp-basla, .kurs-pencere, .kurs-siradaki, .motif-kapak, #uygulama .hp2*, .hp2-*) @ a866b86
// Sitede pencereler sekme çubuğunun 10 pt üstünde, kenarlardan 12 pt içeride yüzen kartlardır; aşağı çekince kapanır.
import NoraCekirdek
import SwiftUI

// MARK: Ortak parçalar

/// `.yildiz-sekil`: `clip-path: polygon(…)` yıldızı
struct YildizSekli: Shape {
    func path(in r: CGRect) -> Path {
        let n: [(CGFloat, CGFloat)] = [(50, 2), (61.5, 36), (97, 36), (68.5, 57), (79, 92), (50, 71), (21, 92), (31.5, 57), (3, 36), (38.5, 36)]
        var p = Path()
        for (i, (x, y)) in n.enumerated() {
            let nokta = CGPoint(x: r.minX + r.width * x / 100, y: r.minY + r.height * y / 100)
            if i == 0 { p.move(to: nokta) } else { p.addLine(to: nokta) }
        }
        p.closeSubpath()
        return p
    }
}

/// Üç yıldız (`yildizHtml`, `.durak-yildizlar`, `.st-yildizlar`)
struct UcYildiz: View {
    let n: Int
    var boyut: CGFloat = 18
    var aralik: CGFloat = 2
    var bos: Color = .white.opacity(0.16)
    var dolu: Color = Color(red: 0.788, green: 0.635, blue: 0.29)
    var body: some View {
        HStack(spacing: aralik) {
            ForEach(0..<3, id: \.self) { i in
                YildizSekli().fill(i < n ? dolu : bos).frame(width: boyut, height: boyut)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(n) / 3 yıldız")
    }
}

/// Sitenin sabit harita renkleri (`#uygulama .hp2`: `--hp2-yazi` #f2ece2, `--hp2-soluk` %62, `--hp2-cizgi` %16;
/// `--hp-yaldiz` #c9a24a; `--pirinc` #c9a45c)
enum HaritaRenk {
    static let yazi = Color(red: 0.949, green: 0.925, blue: 0.886)
    static func yazi(_ a: Double) -> Color { yazi.opacity(a) }
    static let hp2Zemin = Color(red: 0.102, green: 0.082, blue: 0.067)
    static let yaldiz = Color(red: 0.788, green: 0.635, blue: 0.29)
    static let pirinc = Color(red: 0.788, green: 0.643, blue: 0.361)
    static let koyuYazi = Color(red: 0.09, green: 0.075, blue: 0.059)
    /// `.durak-etiket`, `.kurs-rozet`: rgba(24, 22, 20, …) zemin, #ebe5da yazı, #cfc7bc ikincil
    static let rozetZemin = Color(red: 24 / 255, green: 22 / 255, blue: 20 / 255)
    static let rozetYazi = Color(red: 235 / 255, green: 229 / 255, blue: 218 / 255)
    static let rozetSoluk = Color(red: 207 / 255, green: 199 / 255, blue: 188 / 255)
}

/// `.hp2-onay`: 16 pt onay çizgisi
struct OnayIsareti: View {
    var boyut: CGFloat = 16
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 5, y: 12.5)); p.addLine(to: CGPoint(x: 9.5, y: 17)); p.addLine(to: CGPoint(x: 19, y: 7.5))
        }
        .applying(CGAffineTransform(scaleX: boyut / 24, y: boyut / 24))
        .stroke(style: StrokeStyle(lineWidth: 2 * boyut / 24 * 1.5, lineCap: .round, lineJoin: .round))
        .frame(width: boyut, height: boyut)
        .accessibilityLabel("Tamam")
    }
}

/// `.harita-pencere`: kenarlardan 12, sekme çubuğunun 10 üstünde yüzen kart; aşağı çekince kapanır (`surukleKapatKur`)
struct YuzenPencere<Icerik: View>: View {
    enum Stil { case hp2, eski }
    let stil: Stil
    var zemin: URL? = nil
    let kapat: () -> Void
    @ViewBuilder var icerik: Icerik
    @Environment(TemaDeposu.self) private var tema
    @State private var cekme: CGFloat = 0
    @State private var icerikBoyu: CGFloat = 0

    var body: some View {
        GeometryReader { g in
            // hp2: `max-height: calc(100svh - üst güvenli alan - sekme - 84px)`; eski: `62vh`
            let enCok = stil == .hp2 ? g.size.height - 74 : (g.size.height + g.safeAreaInsets.bottom) * 0.62
            VStack {
                Spacer(minLength: 0)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) { icerik }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GeometryReader { ic in
                            Color.clear.onAppear { icerikBoyu = ic.size.height }
                                .onChange(of: ic.size.height) { _, h in icerikBoyu = h }
                        })
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(Self.altta ? .bottom : nil)
                .frame(height: min(max(1, icerikBoyu), enCok))
                .background { arka }
                .clipShape(RoundedRectangle(cornerRadius: stil == .hp2 ? 30 : 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: stil == .hp2 ? 30 : 20, style: .continuous)
                    .strokeBorder(.white.opacity(stil == .hp2 ? 0.14 : 0.09), lineWidth: stil == .hp2 ? 0.5 : 1))
                .overlay(alignment: .topTrailing) { kapatDugmesi }
                .shadow(color: .black.opacity(stil == .hp2 ? 0.55 : 0.9), radius: stil == .hp2 ? 20 : 30, y: stil == .hp2 ? -6 : 30)
                .frame(maxWidth: 520)
                .offset(y: max(0, cekme))
                .gesture(DragGesture(minimumDistance: 12).onChanged { v in cekme = v.translation.height }
                    .onEnded { v in
                        if v.translation.height > 90 || v.predictedEndTranslation.height > 240 { kapat() }
                        withAnimation(.spring(response: 0.3)) { cekme = 0 }
                    })
            }
            .padding(.horizontal, 12).padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// CI (`-pencereAlta`): pencere en altı görünerek açılır (Z4i'nin hikâye şeridi)
    private static var altta: Bool {
        #if DEBUG
        return CommandLine.arguments.contains("-pencereAlta")
        #else
        return false
        #endif
    }

    @ViewBuilder private var arka: some View {
        switch stil {
        case .hp2:
            // `.hp2-zemin`: kapak eserinin bulanık kopyası (44 pt, doygunluk 1.3, parlaklık 0.6) ve aşağı koyulaşan perde
            ZStack {
                HaritaRenk.hp2Zemin
                if let zemin {
                    UzakGorsel(url: zemin, icerik: .fill).scaleEffect(1.4).blur(radius: 44).saturation(1.3).brightness(-0.4)
                }
                LinearGradient(stops: [.init(color: Color(red: 0.078, green: 0.063, blue: 0.047).opacity(0.12), location: 0),
                                       .init(color: Color(red: 0.078, green: 0.063, blue: 0.047).opacity(0.5), location: 0.5),
                                       .init(color: Color(red: 0.078, green: 0.063, blue: 0.047).opacity(0.82), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
        case .eski:
            // `rgba(var(--bg-rgb), 0.9)` + bulanıklık
            ZStack { Rectangle().fill(.ultraThinMaterial); Color(tema.renkler.zemin).opacity(0.9) }
        }
    }

    @ViewBuilder private var kapatDugmesi: some View {
        Button(action: kapat) {
            switch stil {
            case .hp2:
                // 44 pt dokunma alanı, içte %14 yazı renginde 32 pt daire; ikon 16 / 2.2
                GaleriIkon(simge: .kapat, boyut: 16, kalinlik: 2.2).foregroundStyle(HaritaRenk.yazi(0.85))
                    .frame(width: 32, height: 32).background(Circle().fill(HaritaRenk.yazi(0.14)))
                    .frame(width: 44, height: 44).contentShape(Circle())
            case .eski:
                GaleriIkon(simge: .kapat, boyut: 20, kalinlik: 1.7).foregroundStyle(Color(tema.renkler.murekkep))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.ultraThinMaterial).overlay(Circle().fill(Color(tema.renkler.zemin).opacity(0.5))))
                    .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1))
                    .contentShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .padding(stil == .hp2 ? 12 : 8)
        .accessibilityLabel("Kapat")
    }
}

/// `.harita-pencere-ic .etiket`: 600 10.5 px, 0.2em, büyük harf, `--hp-yaldiz`
struct YaldizEtiket: View {
    let metin: String
    init(_ metin: String) { self.metin = metin }
    var body: some View {
        Text(metin.uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(10.5, agirlik: 600)).tracking(2.1)
            .foregroundStyle(HaritaRenk.yaldiz)
    }
}

// MARK: Durak penceresi (1.89 "G2")

struct DurakPenceresi: View {
    let durak: YolculukDuragi
    let katalog: SiteKatalogu
    let il: Ilerleme
    let kapat: () -> Void
    let basla: (BolumSeviyesi) -> Void
    let adreseGit: (String, Sekme) -> Void
    @State private var hikayeDeposu = HikayeDeposu.shared

    private var kayit: SiraliNesne { BolumKurallari.kayit(il, durak.id) }
    private var gruplar: [[String]] { durak.gruplar }
    private var bolunmus: Bool { gruplar.count > 1 }
    private func seviyeAcik(_ sv: String) -> Bool {
        sv == "kolay" ? durak.acik : sv == "orta" ? durak.gecti("kolay") : durak.gecti("orta")
    }
    /// `siradakiSeviye(x)`
    private var siradaki: String? {
        durak.acik ? BolumKurallari.seviyeler.first { seviyeAcik($0) && (kayit[$0]?.sayi ?? 0) < BolumKurallari.gecme } : nil
    }
    private var grupSirada: Int? {
        guard durak.acik, bolunmus, siradaki == "kolay" else { return nil }
        let g = Set(BolumKurallari.gorulenGruplar(kayit, orta: false, adet: gruplar.count))
        return gruplar.indices.first { !g.contains($0) }
    }
    private static let seviyeAd = ["kolay": "Kolay", "orta": "Orta", "zor": "Zor"]
    private func seviye(_ s: String) -> BolumSeviyesi { s == "kolay" ? .kolay : s == "orta" ? .orta : .zor }

    /// `kapakDoldur`: ilk altı sanatçının en bilinen eserlerinden en yatayı
    private var kapak: URL? {
        let adaylar = durak.sanatcilar.prefix(6).compactMap { id -> (Gorsel, Double)? in
            guard let e = Temsil.enBilinen(katalog.eserler(id), kotuler: il.kotuGorseller),
                  let g = Temsil.kucukGorsel(e, kotuler: il.kotuGorseller) else { return nil }
            return (g, katalog.gorsel.oran(g) ?? 0)
        }
        guard let en = adaylar.max(by: { $0.1 < $1.1 }) else { return nil }
        return GorselAdresleri.url(katalog.gorsel.url(en.0, genislik: 640))
    }

    private func kisaAd(_ id: String) -> String { katalog.bilinenAd(id) ?? katalog.harita[id]?.ad ?? id }

    var body: some View {
        let kapakAdresi = self.kapak
        YuzenPencere(stil: .hp2, zemin: kapakAdresi, kapat: kapat) {
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(HaritaRenk.yazi(0.35)).frame(width: 36, height: 5).padding(.top, 8)
                    .frame(maxWidth: .infinity)
                if !durak.sanatcilar.isEmpty {
                    UzakGorsel(url: kapakAdresi, icerik: .fill)
                        .frame(height: 208).frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.5), radius: 23, y: 22)
                        .padding(.top, 22)
                        .accessibilityHidden(true)
                }
                Text("\(YolculukHaritasi.adlar[YolculukHaritasi.bolgeler.firstIndex(of: durak.bolge) ?? 0]) · \(durak.sanatcilar.count) sanatçı")
                    .font(Yazi.sans(13, agirlik: 500)).foregroundStyle(HaritaRenk.yazi(0.62)).padding(.top, 18)
                Text(durak.ad).font(Yazi.serif(28, agirlik: 500)).tracking(-0.28).foregroundStyle(HaritaRenk.yazi)
                    .padding(.top, 4).accessibilityAddTraits(.isHeader)
                if durak.acik { UcYildiz(n: durak.yildiz, boyut: 17).padding(.top, 8) }
                baslaKismi
                VStack(spacing: 0) { ForEach(gruplar.indices, id: \.self) { tanisSatiri($0) } }.padding(.top, 14)
                VStack(spacing: 0) {
                    if durak.acik {
                        ForEach(BolumKurallari.seviyeler, id: \.self) { seviyeSatiri($0) }
                        if seviyeAcik("orta") {
                            ForEach(bolunmus ? Array(gruplar.indices) : [-1], id: \.self) { ortaSatiri($0) }
                        }
                    }
                    akimSatiri
                }
                hikayeKismi
            }
            .padding(.horizontal, 20).padding(.bottom, 18)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(durak.ad)
        .task { await hikayeDeposu.yukle() }
    }

    /// Kilitliyse kilit yazısı (ve "Derse git"); açıksa tek dolu düğme: grup tanışması ya da sıradaki seviye
    @ViewBuilder private var baslaKismi: some View {
        if let kilit = durak.kilit {
            Text(kilit).font(Yazi.sans(15)).lineSpacing(15 * 0.45 - 15 * 0.2).foregroundStyle(HaritaRenk.yazi(0.62)).padding(.top, 12)
            if durak.dersGerekli { anaDugme("Derse git") { adreseGit("#/pekistir/ders/" + SiteYazisi.uriBileseni(durak.akim), .calis) } }
        } else if let g = grupSirada {
            anaDugme("\(g + 1). grupla tanış") { basla(.tanitim(orta: false, grup: g)) }
        } else if let s = siradaki {
            anaDugme("\(Self.seviyeAd[s] ?? s)’\(s == "orta" ? "ya" : "a") başla") { basla(seviye(s)) }
        }
    }

    /// `.hp2-basla`: 52 yükseklik, 14 köşe, `--hp2-yazi` zemin, #17130f yazı 600 16
    private func anaDugme(_ ad: String, _ eylem: @escaping () -> Void) -> some View {
        Button(action: eylem) {
            Text(ad).font(Yazi.sans(16, agirlik: 600)).foregroundStyle(HaritaRenk.koyuYazi)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(HaritaRenk.yazi))
        }
        .buttonStyle(.plain).padding(.top, 18)
    }

    /// `.hp2-satir`: 58 yükseklik, 42 baş (küçük resim ya da simge), 15 ad, 13 sağ yazı; alt çizgi %16
    private func satir<Bas: View>(bas: Bas, ad: Text, son: AnyView?, soluk: Bool = false, sirada: Bool = false,
                                  kapali: Bool = false, gecti: Bool = false, eylem: (() -> Void)?) -> some View {
        let govde = HStack(spacing: 12) {
            bas.frame(width: 42, height: 42).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            HStack(spacing: 12) {
                ad.font(Yazi.sans(15, agirlik: sirada ? 600 : 400)).lineLimit(2)
                    .foregroundStyle(kapali ? HaritaRenk.yazi(0.5) : soluk ? HaritaRenk.yazi(0.55) : HaritaRenk.yazi)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let son {
                    son.font(Yazi.sans(13)).foregroundStyle(gecti ? HaritaRenk.pirinc : HaritaRenk.yazi(0.62))
                }
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottom) { Rectangle().fill(HaritaRenk.yazi(0.16)).frame(height: 0.5) }
        }
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        return Group {
            if let eylem { Button(action: eylem) { govde }.buttonStyle(.plain) } else { govde.accessibilityElement(children: .combine) }
        }
    }

    private func kucuk(_ id: String, soluk: Bool) -> some View {
        UzakGorsel(url: katalog.kucukGorselAdresi(id, genislik: 120, kotuler: il.kotuGorseller), icerik: .fill)
            .opacity(soluk ? 0.55 : 1)
    }

    private func simge<S: View>(_ s: S, dolu: Bool = false) -> some View {
        ZStack { HaritaRenk.yazi(0.1); s.foregroundStyle(dolu ? HaritaRenk.pirinc : HaritaRenk.yazi(0.75)) }
    }

    private func tanisSatiri(_ i: Int) -> some View {
        let g = gruplar[i]
        let gorulen = Set(BolumKurallari.gorulenGruplar(kayit, orta: false, adet: gruplar.count))
        let tamam = bolunmus ? gorulen.contains(i) : kayit["tanitim"]?.mantik == true
        let adlar = Text(g.map(kisaAd).joined(separator: ", "))
        let son: AnyView = tamam ? AnyView(OnayIsareti()) : AnyView(Text(bolunmus ? "\(g.count * 2) soru" : "Tanış"))
        return satir(bas: kucuk(g.first ?? "", soluk: tamam || !durak.acik), ad: adlar, son: durak.acik ? son : nil,
                     soluk: tamam, sirada: grupSirada == i, kapali: !durak.acik,
                     eylem: durak.acik ? { basla(.tanitim(orta: false, grup: bolunmus ? i : nil)) } : nil)
    }

    private func seviyeSatiri(_ sv: String) -> some View {
        let acik = seviyeAcik(sv)
        let en = kayit[sv]?.sayi
        let gecti = (en ?? 0) >= BolumKurallari.gecme
        let bas = simge(Group {
            if acik { YildizCizgi().stroke(style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)).frame(width: 18, height: 18) }
            else { GaleriIkon(simge: .kilit, boyut: 16, kalinlik: 1.7) }
        }, dolu: gecti)
        let ad = Text(Self.seviyeAd[sv] ?? sv) + (sv == "zor" ? Text(" isteğe bağlı").font(Yazi.sans(13)).foregroundColor(HaritaRenk.yazi(0.62)) : Text(""))
        let yazi: String
        if !acik { yazi = sv == "orta" ? "Kolay’ı geçince" : "Orta’yı geçince" }
        else if let en { yazi = gecti ? "%\(Int((en * 100).rounded()))" : "en iyi %\(Int((en * 100).rounded()))" }
        else { yazi = "\(BolumKurallari.soruSayisi(sv)) soru" }
        let son = AnyView(HStack(spacing: 6) { Text(yazi); if gecti { OnayIsareti() } })
        return satir(bas: bas, ad: ad, son: son, sirada: sv == siradaki && grupSirada == nil, kapali: !acik, gecti: gecti,
                     eylem: acik ? { basla(seviye(sv)) } : nil)
    }

    private func ortaSatiri(_ i: Int) -> some View {
        let g = i < 0 ? durak.sanatcilar : gruplar[i]
        let tamam = i < 0 ? kayit["tanitimOrta"]?.mantik == true
            : BolumKurallari.gorulenGruplar(kayit, orta: true, adet: gruplar.count).contains(i)
        return satir(bas: kucuk(g.last ?? "", soluk: tamam), ad: Text("Orta eserleri" + (i < 0 ? "" : " · \(i + 1). grup")),
                     son: tamam ? AnyView(OnayIsareti()) : nil, soluk: tamam,
                     eylem: { basla(.tanitim(orta: true, grup: i < 0 ? nil : i)) })
    }

    /// Z4i: bu konunun sanatçılarının hikâyeleri (yatay şerit; dokununca pencere kapanır, yazı Hikâyeler'de açılır)
    @ViewBuilder private var hikayeKismi: some View {
        if durak.sanatcilar.contains(where: { hikayeDeposu.hikaye($0) != nil }) {
            YaldizEtiket("Hikâyeler").padding(.top, 22).padding(.bottom, 12)
            HikayeSeridi(sanatcilar: durak.sanatcilar, renk: .harita, once: kapat)
                .padding(.horizontal, -20)
                .contentMargins(.horizontal, 20, for: .scrollContent)
        }
    }

    private var akimSatiri: some View {
        satir(bas: simge(Image(systemName: "building.columns").font(.system(size: 16, weight: .light))),
              ad: Text("Akım sayfası"), son: AnyView(GaleriIkon(simge: .ileri, boyut: 14, kalinlik: 1.8)),
              eylem: { adreseGit("#/akim/" + SiteYazisi.uriBileseni(durak.akim), .galeri) })
    }
}

/// Seviye satırının yıldız çizgisi (24'lük viewBox)
private struct YildizCizgi: Shape {
    func path(in r: CGRect) -> Path {
        let n: [(CGFloat, CGFloat)] = [(12, 3.5), (14.6, 8.8), (20.4, 9.6), (16.2, 13.7), (17.2, 19.5), (12, 16.8), (6.8, 19.5), (7.8, 13.7), (3.6, 9.6), (9.4, 8.8)]
        var p = Path()
        for (i, (x, y)) in n.enumerated() {
            let nokta = CGPoint(x: r.minX + r.width * x / 24, y: r.minY + r.height * y / 24)
            if i == 0 { p.move(to: nokta) } else { p.addLine(to: nokta) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: Kurs penceresi (İş 171)

struct KursPenceresi: View {
    let bilgi: KursBilgisi
    let kapat: () -> Void
    let isle: (Int) -> Void
    let hepsi: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let sayi = bilgi.konular.filter { bilgi.islenen.contains($0.no) }.count
        YuzenPencere(stil: .eski, kapat: kapat) {
            VStack(alignment: .leading, spacing: 0) {
                // `.hp-baslik`: etiket ve 30 px başlık ("n" pirinç)
                VStack(alignment: .leading, spacing: 4) {
                    YaldizEtiket("Kursun neresindesin")
                    (Text("\(sayi)").foregroundColor(Color(r.pirinc)) + Text(" / \(bilgi.konular.count) konu işlendi"))
                        .font(Yazi.serif(30)).foregroundStyle(Color(r.murekkep)).cssSatir(.serif, 30, 30.6)
                        .shadow(color: .black.opacity(0.6), radius: 9, y: 2)
                }
                .padding(.trailing, 36).padding(.top, 18)
                if let s = bilgi.siradaki {
                    let acilacak = bilgi.katalog.sanatcilar.filter { $0.konu == s.no }.count
                    VStack(alignment: .leading, spacing: 4) {
                        YaldizEtiket("Sıradaki · Konu \(s.no)")
                        Text(bilgi.baslik(s)).font(Yazi.serif(24)).foregroundStyle(Color(r.murekkep)).cssSatir(.serif, 24, 27.6)
                        Text(acilacak > 0 ? "\(acilacak) sanatçı açılacak" : "yeni sanatçı açılmaz").font(Yazi.sans(14))
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    .padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .top) { Ayrac() }.overlay(alignment: .bottom) { Ayrac() }
                    .padding(.top, 10)
                    // `.kurs-pencere .hp-basla`: tam genişlik, 58, pirinç
                    Button { isle(s.no) } label: {
                        HStack(spacing: 10) {
                            OnayIsareti(boyut: 20)
                            Text("İşlendi yap").font(Yazi.sans(17, agirlik: 600))
                        }
                        .foregroundStyle(Color(r.pirincYazi))
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(Capsule().fill(Color(r.pirinc)))
                    }
                    .buttonStyle(.plain).padding(.top, 10)
                    .accessibilityIdentifier("kurs-isle")
                } else {
                    Text("Bütün konular işlendi.").font(Yazi.sans(14)).foregroundStyle(Color(r.murekkep2)).padding(.top, 12)
                }
            }
            .padding(.horizontal, 18)
            // `.harita-pencere-dugmeler`: üst çizgi, 48 yükseklik, 600 12 px büyük harf
            Button(action: hepsi) {
                Text("BÜTÜN KONULAR").font(Yazi.sans(12, agirlik: 600)).tracking(1.44).foregroundStyle(Color(r.murekkep))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.1)).frame(height: 1) }
            .padding(.top, 16).padding(.bottom, 16)
        }
    }
}

// MARK: Saklı motif penceresi (İş 111)

struct MotifPenceresi: View {
    let anahtar: String
    let harita: JSONDeger?
    let motifler: JSONDeger?
    let katalog: SiteKatalogu
    let il: Ilerleme
    let kapat: () -> Void
    let eserAc: (Eser) -> Void
    let sanatciAc: (String) -> Void
    @Environment(TemaDeposu.self) private var tema

    private var m: JSONDeger? { harita?["eserler"]?[anahtar] }
    private var uzun: JSONDeger? { motifler?["motifler"]?[anahtar] }

    /// `motifEseri(k)`: sanatçının eserlerinden anahtarı (QID ya da "sanatçı|başlık") tutan, görseli olan
    private var eser: Eser? {
        guard let sid = uzun?["sid"]?.metin, let k = uzun?["eser"]?.metin else { return nil }
        return katalog.eserler(sid).first { ($0.qid ?? "\(sid)|\($0.baslik)") == k && !$0.gorseller.isEmpty }
    }

    /// `m.sanatci_id`, yoksa adla eşleşen sanatçı
    private var sanatci: Sanatci? {
        if let id = m?["sanatci_id"]?.metin, let s = katalog.harita[id] { return s }
        guard let ad = m?["sanatci"]?.metin else { return nil }
        return katalog.sanatcilar.first { ad == $0.ad || ad.contains($0.ad) }
    }

    var body: some View {
        let r = tema.renkler
        let kunye = ["sanatci", "yil", "yer", "teknik"].compactMap { m?[$0]?.doluMetin }.joined(separator: " · ")
        let uzunHikaye = uzun?["hikaye"]?.dizi?.compactMap(\.doluMetin) ?? []
        let hikaye = uzunHikaye.isEmpty ? [m?["hikaye"]?.doluMetin].compactMap { $0 } : uzunHikaye
        let haritada = uzun?["haritada"]?.doluMetin ?? m?["haritada"]?.doluMetin
        YuzenPencere(stil: .eski, kapat: kapat) {
            VStack(alignment: .leading, spacing: 0) {
                if let e = eser { kapak(e) }
                VStack(alignment: .leading, spacing: 0) {
                    YaldizEtiket("Saklı motif").padding(.top, eser == nil ? 20 : 0)
                    Text(m?["eser_tr"]?.doluMetin ?? anahtar).font(Yazi.serif(30)).cssSatir(.serif, 30, 30.6)
                        .foregroundStyle(Color(r.murekkep)).shadow(color: .black.opacity(0.6), radius: 9, y: 2)
                        .padding(.top, 6).accessibilityAddTraits(.isHeader)
                    if !kunye.isEmpty {
                        Text(kunye).font(Yazi.okuma(13.5, italik: true)).foregroundStyle(Color(r.murekkep3)).padding(.top, 6)
                    }
                    ForEach(hikaye, id: \.self) { p in
                        Text(p).font(Yazi.okuma(15)).lineSpacing(15 * 0.55 - 15 * 0.2).foregroundStyle(Color(r.murekkep2)).padding(.top, 10)
                    }
                    if let haritada {
                        Text(haritada).font(Yazi.sans(12.5, italik: true)).foregroundStyle(Color(r.murekkep3)).padding(.top, 8)
                    }
                }
                .padding(.horizontal, 18)
                if let s = sanatci {
                    Button { sanatciAc(s.id) } label: {
                        Text("\(s.ad) sayfası".uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(12, agirlik: 600)).tracking(1.44)
                            .foregroundStyle(Color(r.murekkep)).frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.1)).frame(height: 1) }
                    .padding(.top, 16)
                }
            }
            .padding(.bottom, 16)
        }
    }

    /// `button.motif-kapak` (232): çizgili duvar, spot ışığı, yaldız çerçeveli eser ve fildişi künye levhası; dokununca tam ekran
    private func kapak(_ e: Eser) -> some View {
        let g = Temsil.kucukGorsel(e, kotuler: il.kotuGorseller)
        let url = g.flatMap { GorselAdresleri.url(katalog.gorsel.url($0, genislik: 640)) }
        let oran = g.flatMap { katalog.gorsel.oran($0) } ?? 0.8
        return Button { eserAc(e) } label: {
            ZStack(alignment: .bottom) {
                // duvar: ince dikey çizgiler, vurgu renginde üstten alta koyulaşan
                LinearGradient(colors: [Color(tema.renkler.vurgu).opacity(0.12), .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                Canvas { c, b in
                    var x: CGFloat = 0
                    while x < b.width { c.fill(Path(CGRect(x: x, y: 0, width: 2, height: b.height)), with: .color(.white.opacity(0.022))); x += 14 }
                }
                // spot ışığı
                RadialGradient(colors: [Color(red: 1, green: 0.925, blue: 0.784).opacity(0.32), Color(red: 1, green: 0.925, blue: 0.784).opacity(0.08), .clear],
                               center: .top, startRadius: 0, endRadius: 200)
                    .scaleEffect(x: 0.6, y: 1.2, anchor: .top)
                VStack(spacing: 10) {
                    UzakGorsel(url: url, icerik: .fit)
                        .aspectRatio(oran, contentMode: .fit)
                        .overlay(Rectangle().strokeBorder(HaritaRenk.yaldiz, lineWidth: 4))
                        .overlay(Rectangle().strokeBorder(.black.opacity(0.6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.9), radius: 11, y: 18)
                        .frame(maxHeight: .infinity)
                    Text(e.gorunenAd).font(Yazi.okuma(12, italik: true)).lineLimit(1).foregroundStyle(Color(red: 0.169, green: 0.141, blue: 0.125))
                        .padding(.horizontal, 14).padding(.top, 5).padding(.bottom, 6)
                        .background(Rectangle().fill(Color(red: 0.957, green: 0.933, blue: 0.886).opacity(0.94))
                            .overlay(Rectangle().strokeBorder(Color(red: 0.169, green: 0.141, blue: 0.125).opacity(0.22), lineWidth: 1).padding(3)))
                        .shadow(color: .black.opacity(0.7), radius: 6, y: 6)
                        .padding(.bottom, 14)
                }
                .padding(.top, 18).padding(.horizontal, 14)
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.12), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 22)
                    .overlay(alignment: .top) { Rectangle().fill(Color(red: 1, green: 0.9, blue: 0.667).opacity(0.18)).frame(height: 1) }
                    .allowsHitTesting(false)
            }
            .frame(height: 232).frame(maxWidth: .infinity).clipped()
            .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 16)
        .accessibilityLabel("\(m?["eser_tr"]?.doluMetin ?? e.gorunenAd): tam ekran aç")
    }
}

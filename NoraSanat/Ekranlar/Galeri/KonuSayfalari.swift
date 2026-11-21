// Kaynak: sanat-atlasi js/ekranlar/gozat.js (konularCiz, knGovdeCiz, knSahne, knKart, hepsineBak, konuGrupSeridi,
// bsySahneBagla, konuSayfasi, konuSahnesiniDoldur, metniKatla, konuGalerisiAc), js/ikonografi.js (TUR_AD, TUR_SIRA),
// css/app.css (.by-haplar, .by-sahne*, .by-noktalar, .by-bas, .by-hepsi, .by-duvar, .by-cerceve, .by-yazi, .vitrin-akim,
// .serit-son, .konu-sahne*, .konu-baslik, .konu-ust, .konu-ad, .konu-kaynak, .konu-galeri-ac, .konu-ozet, .konu-bolum,
// .konu-ilk, .konu-uzat, .konu-ipuclari, .konu-yol*, .konu-duraklar, .konu-durak*, .konu-dipnot) @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece).
import NoraCekirdek
import SwiftUI

// MARK: Konular

/// `konularCiz(t)`: Galeri üstü (Konular seçili), yapışkan grup sekmeleri; "Hepsi"de öne çıkan beş konunun büyük kartı
/// ve her grubun ilk altı konusu yana kayan bir şeritte ("Hepsine bak" okuyla); bir grup seçilince o grubun bütün
/// konuları iki sütunda (en çok işlenenden aza).
struct KonularSayfasi: View {
    let galeri: GaleriKatalogu
    let il: Ilerleme
    @State var grup: String
    let donem: String?
    let eylem: GaleriEylemleri
    let ust: GaleriUst
    @Environment(TemaDeposu.self) private var tema

    private static let seritSayi = 6
    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }

    /// Grup içinde en çok işlenenden aza (eşitlerde verideki sıra)
    private var gruplar: [(tur: String, ad: String, konular: [GaleriKonusu])] {
        GaleriKatalogu.turler.indices.compactMap { i in
            let t = GaleriKatalogu.turler[i]
            let l = galeri.konular.enumerated().filter { $0.element.tur == t }
                .sorted { ($1.element.baglar.count, $0.offset) < ($0.element.baglar.count, $1.offset) }.map(\.element)
            return l.isEmpty ? nil : (t, GaleriKatalogu.turAdlari[i], l)
        }
    }

    var body: some View {
        let g = gruplar
        let secili = g.first { $0.tur == grup }
        let one = secili.map { Array($0.konular.prefix(3)) } ?? Array(g.compactMap { $0.konular.first }.prefix(5))
        ScrollViewReader { kaydir in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ust.padding(.horizontal, BenOlcu.yan).padding(.top, 12).id("bas")
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            OneCikanlar(konular: one, galeri: galeri, resim: resim) { eylem.git(.konu($0)) }
                                .padding(.top, 8)
                            if let secili {
                                // `.by-bas-donem`
                                HStack(alignment: .lastTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(secili.ad).font(Yazi.serif(26, agirlik: 500, stil: .title1)).tracking(-0.26)
                                        Text("En çok işlenenden aza").font(Yazi.sans(13, stil: .footnote))
                                            .foregroundStyle(Color(tema.renkler.murekkep2))
                                    }
                                    Spacer()
                                    Text("\(secili.konular.count) konu").font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                                        .foregroundStyle(Color(tema.renkler.murekkep2))
                                }
                                .padding(.top, 30).padding(.bottom, 14)
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                          alignment: .leading, spacing: 22) {
                                    ForEach(secili.konular) { k in kart(k) }
                                }
                            } else {
                                ForEach(g.indices, id: \.self) { i in grupBolumu(g[i]) }
                            }
                        }
                        .padding(.horizontal, BenOlcu.yan)
                        .padding(.bottom, 32)
                    } header: {
                        sekmeler(g, kaydir)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(SayfaZemini(donem: donem))
    }

    /// `konuGrupSeridi` (`.by-haplar`): yana kayan yazılı sekmeler; seçilinin altında 2 px pirinç çizgi, yanında sayı
    private func sekmeler(_ g: [(tur: String, ad: String, konular: [GaleriKonusu])], _ kaydir: ScrollViewProxy) -> some View {
        let r = tema.renkler
        let l: [(String, String, Int)] = [("", "Hepsi", galeri.konular.count)] + g.map { ($0.tur, $0.ad, $0.konular.count) }
        return ScrollViewReader { yatay in
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(l.indices, id: \.self) { i in
                        let t = l[i].0, ad = l[i].1, n = l[i].2
                        let acik = t == grup
                        Button {
                            grup = t
                            kaydir.scrollTo("bas", anchor: .top)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(ad).font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                                    .foregroundStyle(Color(acik ? r.murekkep : r.murekkep2))
                                Text("\(n)").font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                            }
                            .frame(height: 44)
                            .overlay(alignment: .bottom) {
                                if acik { Rectangle().fill(Color(r.pirinc)).frame(height: 2) }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(t)
                        .accessibilityAddTraits(acik ? .isSelected : [])
                    }
                }
                .padding(.horizontal, BenOlcu.yan)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color(r.zemin, 0.84).background(.ultraThinMaterial))
            .onChange(of: grup) { _, t in withAnimation { yatay.scrollTo(t, anchor: .leading) } }
            .onAppear { yatay.scrollTo(grup, anchor: .leading) }
        }
        .accessibilityLabel("Konu grupları")
    }

    /// `.by-bolum`: başlık (26 px Bodoni) ve "n konu ›"; altında ilk altı konu yana kayan şeritte
    private func grupBolumu(_ x: (tur: String, ad: String, konular: [GaleriKonusu])) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(x.ad).font(Yazi.serif(26, agirlik: 500, stil: .title1)).tracking(-0.26).cssSatir(.serif, 26, 29.9)
                    .foregroundStyle(Color(r.murekkep))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if x.konular.count > 2 {
                    Button { grup = x.tur } label: {
                        HStack(spacing: 4) {
                            Text("\(x.konular.count) konu")
                            GaleriIkon(simge: .ileri, boyut: 16, kalinlik: 1.8)
                        }
                        .font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                        .foregroundStyle(Color(r.murekkep2))
                        .frame(height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(x.ad): \(x.konular.count) konunun hepsi")
                }
            }
            .frame(minHeight: 44)
            .padding(.bottom, 14)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(x.konular.prefix(Self.seritSayi))) { k in kart(k).frame(width: 148.5) }
                    if x.konular.count > Self.seritSayi {
                        // `hepsineBak`: sırayı bitiren ok
                        Button { grup = x.tur } label: {
                            VStack(spacing: 8) {
                                GaleriIkon(simge: .ileri, boyut: 22, kalinlik: 1.6)
                                    .frame(width: 52, height: 52)
                                    .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                                Text("Hepsine bak").font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                                Text("\(x.konular.count) konu").font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(r.murekkep2))
                            }
                            .foregroundStyle(Color(r.murekkep))
                            .frame(width: 112, height: 185.6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(x.ad): \(x.konular.count) konunun hepsi")
                    }
                }
                .padding(.horizontal, BenOlcu.yan)
                .padding(.bottom, 4)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .padding(.horizontal, -BenOlcu.yan)
        }
        .padding(.top, 30)
    }

    /// `knKart(k)` (`.by-kart`): 148.5 × 185.6 kapak (4 px köşe), 17 px Newsreader ad, "n eser", küçük grup adı
    private func kart(_ k: GaleriKonusu) -> some View {
        let r = tema.renkler
        let kapak = galeri.konuKapagi(galeri.konuEserleri(k))
        return Button { eylem.git(.konu(k.id)) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color(r.yuzey)
                    .aspectRatio(148.5 / 185.6, contentMode: .fit)
                    .overlay { if let kapak { resim.gorsel(kapak, 400) } }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text(k.ad).font(Yazi.okuma(17)).cssSatir(.okuma, 17, 20.4).foregroundStyle(Color(r.murekkep))
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)
                Text("\(k.baglar.count) eser").font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 16.9)
                    .foregroundStyle(Color(r.murekkep2)).padding(.top, 4)
                Text(Self.turAdi(k.tur).uppercased(with: Locale(identifier: "tr_TR")))
                    .font(Yazi.sans(9.5, agirlik: 600, stil: .caption2)).tracking(1.33)
                    .foregroundStyle(Color(r.murekkep3)).padding(.top, 2 + 4)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    static func turAdi(_ t: String) -> String {
        GaleriKatalogu.turler.firstIndex(of: t).map { GaleriKatalogu.turAdlari[$0] } ?? ""
    }
}

/// `knSahne(one)` (`.by-sahne`): 372 px, 28 px köşeli büyük kart; resim, alttan gölge, "Öne çıkan · grup", 32 px Bodoni ad,
/// "n eserde bu konu"; altta noktalar. "Tam" harekette 6 sn'de bir kendiliğinden değişir; kaydırınca ya da noktaya
/// dokununca elle.
private struct OneCikanlar: View {
    let konular: [GaleriKonusu]
    let galeri: GaleriKatalogu
    let resim: GaleriResim
    let ac: (String) -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var secili = 0
    @State private var elle = false

    var body: some View {
        let yazi = RGBA(css: "#f3eee4")!
        ZStack(alignment: .bottomLeading) {
            TabView(selection: $secili) {
                ForEach(Array(konular.enumerated()), id: \.offset) { i, k in
                    Button { ac(k.id) } label: {
                        ZStack(alignment: .bottomLeading) {
                            Color(tema.renkler.yuzey)
                            if let kapak = galeri.konuKapagi(galeri.konuEserleri(k)) { resim.gorsel(kapak, 800) }
                            LinearGradient(stops: [.init(color: .black.opacity(0), location: 0.35), .init(color: .black.opacity(0.75), location: 1)],
                                           startPoint: .top, endPoint: .bottom)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Öne çıkan · \(KonularSayfasi.turAdi(k.tur))").font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                                    .foregroundStyle(Color(RGBA(css: "#e6e0d6")!))
                                Text(k.ad).font(Yazi.serif(32, agirlik: 500, stil: .title1)).tracking(-0.32).cssSatir(.serif, 32, 37.76)
                                    .foregroundStyle(Color(yazi)).lineLimit(2)
                                Text("\(k.baglar.count) eserde bu konu").font(Yazi.sans(15, stil: .subheadline))
                                    .foregroundStyle(Color(yazi, 0.84))
                            }
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 18).padding(.bottom, 64)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            if konular.count > 1 {
                HStack(spacing: 10) {
                    ForEach(konular.indices, id: \.self) { i in
                        Button { elle = true; withAnimation { secili = i } } label: {
                            Capsule().fill(Color(RGBA(css: "#f4f0e8")!, i == secili ? 1 : 0.5))
                                .frame(width: i == secili ? 20 : 6, height: 6)
                                .frame(width: 20, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(i + 1). öne çıkan konu")
                    }
                }
                .padding(.leading, 18 - 7)
            }
        }
        .frame(height: 372)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 25, y: 24)
        .onChange(of: konular.map(\.id)) { _, _ in secili = 0 }
        .task(id: konular.map(\.id)) {
            guard !hareketAz, !tema.ayar.hareketAzaltilmis, tema.ayar.hareket == "tam", konular.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                guard !Task.isCancelled, !elle else { return }
                withAnimation(.easeInOut(duration: 0.6)) { secili = (secili + 1) % konular.count }
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 20).onChanged { _ in elle = true })
    }
}

// MARK: Konu

/// `konuSayfasi(id)`: üstte grup etiketi; kenardan kenara kapak sahnesi (künye hapı, büyüt), grup · n eser, 44 px ad,
/// kaynak, "Bütün resimler"; italik özet; hikâye (ilk harf büyük, katlanır); tanıma maddeleri (kırpımlarla);
/// "Aynı hikâye, n kez" şeridi (zaman sırasıyla); dipnot.
struct KonuSayfasi: View {
    let konu: GaleriKonusu
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri
    let kirpim: (TanimaKirpimi, [Eser], String) -> AnyView
    @Environment(TemaDeposu.self) private var tema
    @State private var acik = false
    @State private var galeriAcik = false

    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }

    var body: some View {
        let r = tema.renkler
        let eserler = galeri.konuEserleri(konu)
        let kapak = galeri.konuKapagi(eserler)
        let tur = KonularSayfasi.turAdi(konu.tur)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SanatciUst(etiket: tur, geri: eylem.geri) { eylem.git(.konular(konu.tur)) }
                sahne(kapak, eserler)
                    .padding(.horizontal, -BenOlcu.yan)
                    .padding(.top, -6)
                // `.konu-baslik`: sahnenin üstüne 56 px biner
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text(tur); Text("·").accessibilityHidden(true); Text("\(konu.baglar.count) eser")
                    }
                    .font(Yazi.sans(12, agirlik: 600, stil: .caption1)).tracking(1.92).textCase(.uppercase)
                    .foregroundStyle(Color(r.murekkep2))
                    .padding(.bottom, 8)
                    Text(konu.ad).font(Yazi.serif(44, stil: .largeTitle)).tracking(-0.44).cssSatir(.serif, 44, 44.88)
                        .foregroundStyle(Color(r.murekkep))
                        .accessibilityAddTraits(.isHeader)
                    if !konu.kaynak.isEmpty {
                        HStack(spacing: 10) {
                            Rectangle().fill(Color(r.murekkep3)).frame(width: 18, height: 1)
                            Text(konu.kaynak)
                        }
                        .font(Yazi.sans(14, stil: .subheadline)).foregroundStyle(Color(r.murekkep3))
                        .padding(.top, 12)
                    }
                    Button { galeriAcik = true } label: {
                        HStack(spacing: 10) {
                            GaleriIkon(simge: .izgara, boyut: 18, kalinlik: 1.6)
                            Text("Bütün resimler").font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                            Text("\(eserler.count)").font(Yazi.sans(13, agirlik: 700, stil: .footnote))
                                .foregroundStyle(Color(r.zemin))
                                .padding(.horizontal, 8).frame(minWidth: 30, minHeight: 30)
                                .background(Capsule().fill(Color(GaleriRenk.karis(r.vurgu, r.murekkep, 0.5))))
                        }
                        .foregroundStyle(Color(r.murekkep))
                        .padding(.leading, 16).padding(.trailing, 8)
                        .frame(height: 44)
                        .background(Capsule().fill(Color(r.notrYuzey)))
                        .overlay(Capsule().strokeBorder(Color(r.notrKenar), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(eserler.isEmpty)
                    .padding(.top, 18)
                }
                .padding(.top, kapak == nil ? 8 : -56)
                if !konu.ozet.isEmpty {
                    Text(konu.ozet).font(Yazi.serif(22, italik: true, stil: .title2)).cssSatir(.serif, 22, 30.8)
                        .foregroundStyle(Color(r.murekkep))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 18).padding(.top, 26)
                }
                hikaye
                if !konu.tanima.isEmpty { tanima(eserler) }
                yol(eserler)
                Text("Metni Claude yazdı, ikinci bir istekte denetledi. Konu, eserlerin adından çıkarıldı; arada yanlış eşleşme olabilir.")
                    .font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 19.5)
                    .foregroundStyle(Color(r.murekkep3))
                    .padding(.top, 36)
            }
            .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: nil, ustHale: true))
        .sheet(isPresented: $galeriAcik) {
            KonuGalerisi(baslik: konu.ad, eserler: eserler, resim: resim) { i in
                galeriAcik = false
                eylem.ac(eserler, i)
            }
        }
    }

    /// `.konu-sahne`: 408 px kapak, sağ üstte künye hapı, sağ altta büyüt; alttan zemine silinir
    @ViewBuilder private func sahne(_ kapak: Eser?, _ eserler: [Eser]) -> some View {
        let r = tema.renkler
        if let kapak {
            Button { eylem.ac(eserler, eserler.firstIndex(of: kapak) ?? 0) } label: {
                ZStack(alignment: .topTrailing) {
                    resim.gorsel(kapak, 1000).frame(height: 408.6).clipped()
                    LinearGradient(stops: [.init(color: Color(r.zemin, 0), location: 0.55), .init(color: Color(r.zemin), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                    Text("\(resim.bilinenAd(kapak.sid)) · \(kapak.gorunenAd)" + (kapak.tarih.isEmpty ? "" : ", \(kapak.tarih)"))
                        .font(Yazi.sans(12, stil: .caption1)).cssSatir(.sans, 12, 15.6).lineLimit(2)
                        .foregroundStyle(Color(r.murekkep2))
                        .padding(.vertical, 6).padding(.horizontal, 10)
                        .background(Capsule().fill(Color(r.zemin, 0.6)))
                        .padding(.top, 14).padding(.trailing, BenOlcu.yan)
                        .frame(maxWidth: 260, alignment: .trailing)
                    GaleriIkon(simge: .buyut, boyut: 18, kalinlik: 1.6).foregroundStyle(Color(r.murekkep))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color(r.zemin, 0.6)))
                        .overlay(Circle().strokeBorder(Color(r.notrKenar), lineWidth: 1))
                        .padding(.trailing, BenOlcu.yan).padding(.bottom, 44)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 408.6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Resmi büyüt")
        }
    }

    /// `.konu-hikaye`: ilk paragrafın ilk harfi büyük; uzunsa ilk satırlar görünür, gerisi solar ("Devamını oku")
    private var hikaye: some View {
        let r = tema.renkler
        let ilk = konu.hikaye.first ?? ""
        return VStack(alignment: .leading, spacing: 14) {
            Etiket("Hikâye").padding(.top, 1)
            VStack(alignment: .leading, spacing: 14) {
                IlkHarfliParagraf(metin: ilk)
                ForEach(Array(konu.hikaye.dropFirst().enumerated()), id: \.offset) { _, p in OkumaMetni(metin: p) }
            }
            .frame(maxHeight: acik ? nil : 300, alignment: .top)
            .clipped()
            .mask {
                LinearGradient(stops: acik ? [.init(color: .black, location: 0), .init(color: .black, location: 1)]
                               : [.init(color: .black, location: 0), .init(color: .black, location: 0.55), .init(color: .black.opacity(0), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            if konu.hikaye.count > 1 || ilk.count > 400 {
                Button { withAnimation(.easeOut(duration: 0.5)) { acik.toggle() } } label: {
                    HStack(spacing: 6) {
                        Text(acik ? "Daha az göster" : "Devamını oku").font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                        GaleriIkon(simge: .asagi, boyut: 18, kalinlik: 1.8).rotationEffect(.degrees(acik ? 180 : 0))
                    }
                    .foregroundStyle(Color(r.murekkep))
                    .padding(.horizontal, 2).frame(height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 14)
        .overlay(alignment: .top) { Ayrac() }
        .overlay(alignment: .bottom) { Ayrac() }
        .padding(.top, 40)
    }

    /// `.konu-ipuclari li`: `--surface` kart (14 px köşe), solda eserden kırpım, yanında madde (16 px)
    private func tanima(_ eserler: [Eser]) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 12) {
            VurguEtiket("Resimde nasıl tanınır?", renk: r.murekkep2).padding(.top, 1)
            ForEach(Array(konu.tanima.enumerated()), id: \.offset) { i, metin in
                HStack(alignment: .center, spacing: 12) {
                    if let k = galeri.konuKirpimlari[konu.id]?.first(where: { $0.madde == i }) {
                        kirpim(k, eserler, metin).frame(width: 76).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        GaleriIkon(simge: .ara, boyut: 18, kalinlik: 1.6).foregroundStyle(Color(r.murekkep2)).frame(width: 24)
                    }
                    Text(metin).font(Yazi.sans(16)).cssSatir(.sans, 16, 24).foregroundStyle(Color(r.murekkep))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 12).padding(.leading, 12).padding(.trailing, 16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            }
        }
        .padding(.top, 40)
    }

    /// `.konu-yol`: "Aynı hikâye, n kez", "Tümünü göster ›", not; zaman sırasıyla duraklar (yıl, 240 × 300 resim, ad)
    private func yol(_ eserler: [Eser]) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Etiket("Aynı hikâye, \(eserler.count) kez")
                Spacer()
                if !eserler.isEmpty {
                    Button { galeriAcik = true } label: {
                        HStack(spacing: 4) {
                            Text("Tümünü göster").font(Yazi.sans(14, agirlik: 500, stil: .subheadline))
                            GaleriIkon(simge: .ileri, boyut: 15, kalinlik: 1.7)
                        }
                        .foregroundStyle(Color(r.murekkep)).frame(height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Zaman sırasıyla; kaydır, dokunup büyüt.").font(Yazi.sans(14, stil: .subheadline))
                .foregroundStyle(Color(r.murekkep3)).padding(.top, -2).padding(.bottom, 14)
            if eserler.isEmpty {
                Text("Bu konudaki eserlerin görseli bulunamadı.").font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(Array(eserler.enumerated()), id: \.offset) { i, e in
                            Button { eylem.ac(eserler, i) } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(e.tarih.isEmpty ? "—" : e.tarih).font(Yazi.sans(12, agirlik: 600, stil: .caption1)).tracking(0.48)
                                        .foregroundStyle(Color(r.murekkep2))
                                    resim.gorsel(e, 500).frame(width: 240, height: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        .shadow(color: .black.opacity(0.6 * 0.5), radius: 14, y: 10 - 7)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(resim.bilinenAd(e.sid)).font(Yazi.serif(19)).foregroundStyle(Color(r.murekkep))
                                        Text(e.gorunenAd).font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                                            .lineLimit(2)
                                    }
                                    .multilineTextAlignment(.leading)
                                }
                                .frame(width: 240, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(resim.bilinenAd(e.sid)), \(e.gorunenAd) — büyüt")
                        }
                    }
                    .padding(.horizontal, BenOlcu.yan)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .padding(.horizontal, -BenOlcu.yan)
            }
        }
        .padding(.top, 26)
        .overlay(alignment: .top) { Ayrac() }
        .padding(.top, 40)
    }
}

/// `.konu-ilk::first-letter`: ilk harf dört satır boyu, `--ink-2`; metin yanından akar
private struct IlkHarfliParagraf: View {
    let metin: String
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let ilk = String(metin.prefix(1)), kalan = String(metin.dropFirst())
        (Text(ilk).font(Yazi.serif(56)).foregroundColor(Color(GaleriRenk.karis(tema.renkler.vurgu, tema.renkler.murekkep, 0.5)))
            + Text(kalan).font(Yazi.okuma(19)).foregroundColor(Color(tema.renkler.murekkep)))
            .cssSatir(.okuma, 19, 27.55)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `konuGalerisiAc`: "Bütün resimler · n", konunun adı; iki sütunlu kırpmasız duvar
private struct KonuGalerisi: View {
    let baslik: String
    let eserler: [Eser]
    let resim: GaleriResim
    let ac: (Int) -> Void
    @Environment(\.dismiss) private var kapat
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiket("Bütün resimler · \(eserler.count)")
                        Text(baslik).font(Yazi.serif(30, stil: .title1)).foregroundStyle(Color(r.murekkep))
                    }
                    Spacer()
                    Button { kapat() } label: { GaleriIkon(simge: .kapat, boyut: 22, kalinlik: 1.6) }
                        .buttonStyle(YuvarlakDugme())
                        .accessibilityLabel("Kapat")
                }
                IkiSutunDuvar(eserler: eserler, resim: resim, ac: ac)
            }
            .padding(.horizontal, BenOlcu.yan).padding(.vertical, 20)
        }
        .background(Color(r.zemin).ignoresSafeArea())
        .environment(TemaDeposu.shared)
    }
}

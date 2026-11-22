// Kaynak: sanat-atlasi js/ekranlar/gozat.js (basyapitListesi, bsyGovdeCiz, bsyGruplari, bsySahne, bsyKart, bsySahneBagla,
// hepsineBak, eserRozetleri), js/basyapit.js (oneCikanlar, gorunenBaslik), css/app.css (.by-haplar, .by-sahne*, .by-noktalar,
// .by-bolum, .by-bas, .by-bas-donem, .by-say, .by-akim, .by-hepsi, .by-duvar, .ritim, .serit, .by-kart, .by-cerceve,
// .by-kilit, .by-yazi, .vitrin-akim, .serit-son, .eser-rozetler, .eser-rozet) @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (iPhone 15 Pro, 393 pt, Gece).
import NoraCekirdek
import SwiftUI

/// Başyapıtlar sayfasının yardımcı verisi: hikâyesi ve rehberli incelemesi olan eserler (rozetler, öne çıkanlar)
struct BasyapitBaglami {
    var hikayeler: [HikayeKaydi] = []
    var ayrintilar: [AyrintiKaydi] = []

    var hikayeli: Set<String> { Set(hikayeler.map(\.anahtar)) }
    func hikaye(_ e: Eser?) -> HikayeKaydi? { HikayeKurallari.eserinHikayesi(hikayeler, eser: e) }
    func ayrinti(_ e: Eser?) -> AyrintiKaydi? { AyrintiKurallari.eserinAyrintisi(ayrintilar, eser: e) }
}

/// `basyapitListesi()`: Galeri üstü (Başyapıtlar seçili), yapışkan dönem sekmeleri; öne çıkan dört eserin büyük kartı;
/// "Hepsi"de her dönemin ilk altı eseri yana kayan şeritte ("Hepsine bak" okuyla), bir dönem seçilince o dönemin
/// akımları ve bütün eserleri iki sütunda (beşte bir geniş kart).
struct BasyapitListesi: View {
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let baglam: BasyapitBaglami
    @Binding var donem: String
    let eylem: GaleriEylemleri
    let ust: GaleriUst
    @Environment(TemaDeposu.self) private var tema
    @State private var zeminRenk: TabloRenkleri.Cift?

    private static let seritSayi = 6
    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }
    private var k: SiteKatalogu { galeri.katalog }

    var body: some View {
        let liste = galeri.basyapitlar
        let gruplar = BasyapitKurallari.gruplar(liste, katalog: k)
        let secili = gruplar.first { $0.bolge.id == donem }
        let islenen = il.islenenKume
        let one = BasyapitKurallari.oneCikanlar(secili?.eserler ?? liste, hikayeli: baglam.hikayeli) { b in
            k.harita[b.sanatci]?.konu.map(islenen.contains) ?? false
        }
        let zemin = secili?.bolge.id ?? one.first.flatMap { k.harita[$0.sanatci] }.map { Donem.akimin(k, $0.akim).id }
        ScrollViewReader { kaydir in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ust.padding(.horizontal, BenOlcu.yan).padding(.top, 12).id("bas")
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            if liste.isEmpty {
                                Text("Henüz yakın okuma yok.").font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                                    .padding(.top, 16)
                            }
                            if !one.isEmpty {
                                BasyapitSahnesi(eserler: one, galeri: galeri, baglam: baglam, resim: resim,
                                                ac: { eylem.git(.okuma($0)) }, secildi: zemineAl)
                                    .padding(.top, 8)
                                    .id("sahne-" + donem)
                            }
                            if let secili {
                                donemGorunumu(secili)
                            } else {
                                ForEach(gruplar, id: \.bolge.id) { g in seritBolumu(g).id(g.bolge.id == gruplar.first?.bolge.id ? "serit" : g.bolge.id) }
                            }
                        }
                        .padding(.horizontal, BenOlcu.yan)
                        .padding(.bottom, 32)
                    } header: {
                        sekmeler(liste.count, gruplar, kaydir)
                    }
                }
            }
            .scrollIndicators(.hidden)
            #if DEBUG
            .task { for id in ["serit", "donem"] { await GaleriKarsilastirma.kaydir(kaydir, id) } }
            #endif
        }
        .background(SayfaZemini(donem: zemin, renkler: zeminRenk))
    }

    /// Z3c: zeminin iki rengi öne çıkan kartta görünen tablodan
    private func zemineAl(_ b: Basyapit) {
        let url = BasyapitKurallari.eser(galeri.eserler[b.sanatci] ?? [], b).flatMap { resim.url($0, 400) }
        Task { if let c = await TabloRengi.cift(url) { zeminRenk = c } }
    }

    // MARK: Dönem sekmeleri

    /// `.by-haplar`: yana kayan yazılı sekmeler; seçilinin altında 2 px pirinç çizgi, yanında sayı. Seçim değişince sayfa
    /// sekmelerin hizasına gelir (sekmeler yapışkan, yerinde kalır).
    private func sekmeler(_ toplam: Int, _ g: [BasyapitGrubu], _ kaydir: ScrollViewProxy) -> some View {
        let r = tema.renkler
        let l: [(String, String, Int)] = [("", "Hepsi", toplam)] + g.map { ($0.bolge.id, $0.bolge.ad, $0.eserler.count) }
        return ScrollViewReader { yatay in
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(l.indices, id: \.self) { i in
                        let id = l[i].0, ad = l[i].1, n = l[i].2
                        let acik = id == donem
                        Button {
                            donem = id
                            kaydir.scrollTo("bas", anchor: .top)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(ad).font(Yazi.sans(15, agirlik: acik ? 600 : 500, stil: .subheadline))
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
                        .id(id)
                        .accessibilityAddTraits(acik ? .isSelected : [])
                    }
                }
                .padding(.horizontal, BenOlcu.yan)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color(r.zemin, 0.84).background(.ultraThinMaterial))
            .onChange(of: donem) { _, t in withAnimation { yatay.scrollTo(t, anchor: .leading) } }
            .onAppear { yatay.scrollTo(donem, anchor: .leading) }
        }
        .accessibilityLabel("Dönemler")
    }

    // MARK: Hepsi: dönem şeritleri

    /// `.by-bolum` + `.by-bas`: 26 px Bodoni dönem adı, altında yüzyıl; sağda "n eser ›"; ilk altı eser şeritte
    private func seritBolumu(_ g: BasyapitGrubu) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(g.bolge.ad).font(Yazi.serif(26, agirlik: 500, stil: .title1)).tracking(-0.26).cssSatir(.serif, 26, 29.9)
                        .foregroundStyle(Color(r.murekkep))
                    Text(g.bolge.yuzyil).font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 16.9)
                        .foregroundStyle(Color(r.murekkep2))
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if g.eserler.count > 2 {
                    Button { donem = g.bolge.id } label: {
                        HStack(spacing: 4) {
                            Text("\(g.eserler.count) eser")
                            GaleriIkon(simge: .ileri, boyut: 16, kalinlik: 1.8)
                        }
                        .font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                        .foregroundStyle(Color(r.murekkep2))
                        .frame(height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(g.bolge.ad): \(g.eserler.count) eserin hepsi")
                }
            }
            .padding(.bottom, 14)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(g.eserler.prefix(Self.seritSayi))) { b in kart(b).frame(width: 148.5) }
                    if g.eserler.count > Self.seritSayi {
                        // `hepsineBak`
                        Button { donem = g.bolge.id } label: {
                            VStack(spacing: 8) {
                                GaleriIkon(simge: .ileri, boyut: 22, kalinlik: 1.6)
                                    .frame(width: 52, height: 52)
                                    .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                                Text("Hepsine bak").font(Yazi.sans(14, agirlik: 600, stil: .subheadline))
                                Text("\(g.eserler.count) eser").font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(r.murekkep2))
                            }
                            .foregroundStyle(Color(r.murekkep))
                            .frame(width: 112, height: 185.6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(g.bolge.ad): \(g.eserler.count) eserin hepsi")
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

    // MARK: Bir dönem: akımlar ve ızgara

    /// `.by-bas-donem` (28 üstte) ve akım bölümleri (`.by-akim`: noktalı küçük büyük harfli ad ve sayı; `.ritim` ızgara)
    private func donemGorunumu(_ g: BasyapitGrubu) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(g.bolge.ad).font(Yazi.serif(26, agirlik: 500, stil: .title1)).tracking(-0.26).cssSatir(.serif, 26, 29.9)
                        .foregroundStyle(Color(r.murekkep))
                    Text(g.bolge.yuzyil).font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 16.9)
                        .foregroundStyle(Color(r.murekkep2))
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Text("\(g.eserler.count) eser").font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 16.9)
                    .foregroundStyle(Color(r.murekkep2))
            }
            .padding(.top, 28).padding(.bottom, 14)
            .id("donem")
            ForEach(Array(g.akimlar.enumerated()), id: \.offset) { i, x in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Circle().fill(Color(GaleriRenk.akim(k, x.ad))).frame(width: 7, height: 7)
                        Text(x.ad.uppercased(with: Locale(identifier: "tr_TR")))
                            .foregroundStyle(Color(r.murekkep2))
                        Text("\(x.eserler.count)").foregroundStyle(Color(r.murekkep3))
                    }
                    .font(Yazi.sans(12, agirlik: 600, stil: .caption1)).tracking(1.68)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 12)
                    ritim(x.eserler)
                }
                .padding(.top, i == 0 ? 18 : 30)
            }
        }
    }

    /// `.by-duvar.ritim`: iki sütun (12 / 20 aralık); 5n+1. kart iki sütun genişliğinde, 16:10 kapakla
    private func ritim(_ l: [Basyapit]) -> some View {
        // satırlar: [0] geniş, [1, 2], [3, 4], [5] geniş, …
        let satirlar = Self.ritimSatirlari(l)
        return VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(satirlar.enumerated()), id: \.offset) { _, s in
                if l.firstIndex(of: s[0]).map({ $0 % 5 == 0 }) == true {
                    kart(s[0], genis: true, akimYok: true)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(s) { b in kart(b, akimYok: true).frame(maxWidth: .infinity, alignment: .leading) }
                        if s.count == 1 { Color.clear.frame(maxWidth: .infinity, maxHeight: 1) }
                    }
                }
            }
        }
    }

    /// Beşli öbekler: ilki tek (geniş), kalan dördü ikişer
    private static func ritimSatirlari(_ l: [Basyapit]) -> [[Basyapit]] {
        var satirlar: [[Basyapit]] = []
        var i = 0
        while i < l.count {
            let oge = l[i]
            if i % 5 == 0 {
                satirlar.append([oge])
                i += 1
            } else {
                let son: Int = min(i + 2, l.count, (i / 5 + 1) * 5)
                satirlar.append(Array(l[i..<son]))
                i = son
            }
        }
        return satirlar
    }

    // MARK: Kart

    /// `bsyKart(b)` (`.by-kart`): 4:5 kapak (geniş kartta 16:10; 4 px köşe), kursta değilse "Henüz kursta yok",
    /// sol altta hikâye ve inceleme rozetleri; 17 px Newsreader ad (en çok iki satır), "Sanatçı · tarih", akımın küçük adı
    private func kart(_ b: Basyapit, genis: Bool = false, akimYok: Bool = false) -> some View {
        let r = tema.renkler
        let s = k.harita[b.sanatci]
        let e = BasyapitKurallari.eser(galeri.eserler[b.sanatci] ?? [], b)
        let acik = s?.konu.map(il.islenenKume.contains) ?? false
        return Button { eylem.git(.okuma(b.anahtar)) } label: {
            VStack(alignment: .leading, spacing: 9) {
                Color(r.yuzey)
                    .aspectRatio(genis ? 16.0 / 10 : 4.0 / 5, contentMode: .fit)
                    .overlay { if let e { resim.gorsel(e, genis ? 800 : 500) } }
                    .overlay(alignment: .topLeading) {
                        if !acik {
                            Text("HENÜZ KURSTA YOK").font(Yazi.sans(9.5, agirlik: 600, stil: .caption2)).tracking(0.95)
                                .foregroundStyle(Color(RGBA(css: "#f3eee4")!))
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(Capsule().fill(Color(RGBA(css: "#0c0b0a")!, 0.72)))
                                .padding(8)
                        }
                    }
                    .overlay(alignment: .bottomLeading) { EserRozetleri(hikaye: baglam.hikaye(e) != nil, ayrinti: baglam.ayrinti(e)).padding(6) }
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(b.baslik).font(Yazi.okuma(17)).cssSatir(.okuma, 17, 20.4)
                        .foregroundStyle(Color(r.murekkep)).lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(BasyapitSatiri.sanatci(b, k)).font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 16.9)
                        .foregroundStyle(Color(r.murekkep2)).lineLimit(2)
                    if !akimYok, let s {
                        HStack(spacing: 6) {
                            Circle().fill(Color(GaleriRenk.akim(k, s.akim))).frame(width: 7, height: 7)
                            Text(s.akim.uppercased(with: Locale(identifier: "tr_TR")))
                                .font(Yazi.sans(9.5, agirlik: 600, stil: .caption2)).tracking(1.33)
                                .foregroundStyle(Color(r.murekkep3)).lineLimit(1)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

enum BasyapitSatiri {
    /// `bsySanatci(b)`: "Bilinen ad · tarih"
    static func sanatci(_ b: Basyapit, _ k: SiteKatalogu) -> String {
        [k.bilinenAd(b.sanatci) ?? "", b.tarih].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// `eserRozetleri(e, uzun)`: hikâyesi olana kitap, rehberli incelemesi olana büyüteç. Küçükte yalnız simge (24 px, sol alt),
/// büyük kartta adıyla (28 px, "Hikâye", "n ayrıntı").
struct EserRozetleri: View {
    let hikaye: Bool
    let ayrinti: AyrintiKaydi?
    var uzun = false

    var body: some View {
        if hikaye || ayrinti != nil {
            HStack(spacing: uzun ? 6 : 4) {
                if hikaye { rozet(.kitap, "Hikâye", "Hikâyesi var") }
                if let a = ayrinti { rozet(.ara, a.noktalar.isEmpty ? "İncele" : "\(a.noktalar.count) ayrıntı", "Rehberli incelemesi var") }
            }
            .allowsHitTesting(false)
        }
    }

    private func rozet(_ simge: GaleriSimge, _ ad: String, _ etiket: String) -> some View {
        HStack(spacing: 5) {
            if !uzun { GaleriIkon(simge: simge, boyut: 14, kalinlik: 1.8).foregroundStyle(Color(RGBA(css: "#c9a45c")!)) }
            if uzun { Text(ad).font(Yazi.sans(12, agirlik: 500, stil: .caption1)) }
        }
        .foregroundStyle(Color(RGBA(css: "#ebe5da")!))
        .padding(.horizontal, uzun ? 10 : 5)
        .frame(minWidth: 24, minHeight: uzun ? 28 : 24)
        .background(Capsule().fill(Color(RGBA(css: "#121110")!, 0.74)))
        .accessibilityLabel(etiket)
    }
}

/// `bsySahne(one)` (`.by-sahne`): 372 px, 28 px köşeli büyük kart; resim, alttan gölge, sol üstte rozetler,
/// "Öne çıkan · akım", 32 px Bodoni ad, "Sanatçı · tarih"; altta noktalar. "Tam" harekette 6 sn'de bir kendiliğinden
/// değişir; kaydırınca ya da noktaya dokununca elle.
struct BasyapitSahnesi: View {
    let eserler: [Basyapit]
    let galeri: GaleriKatalogu
    let baglam: BasyapitBaglami
    let resim: GaleriResim
    let ac: (String) -> Void
    /// Görünen kart değişince (zeminin rengi için)
    var secildi: ((Basyapit) -> Void)? = nil
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var secili = 0
    @State private var elle = false

    var body: some View {
        let yazi = RGBA(css: "#f3eee4")!
        let k = galeri.katalog
        ZStack(alignment: .bottomLeading) {
            TabView(selection: $secili) {
                ForEach(Array(eserler.enumerated()), id: \.offset) { i, b in
                    let e = BasyapitKurallari.eser(galeri.eserler[b.sanatci] ?? [], b)
                    Button { ac(b.anahtar) } label: {
                        ZStack(alignment: .bottomLeading) {
                            Color(tema.renkler.yuzey)
                            if let e { resim.gorsel(e, 900) }
                            LinearGradient(stops: [.init(color: .black.opacity(0), location: 0.35), .init(color: .black.opacity(0.75), location: 1)],
                                           startPoint: .top, endPoint: .bottom)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Öne çıkan · \(k.harita[b.sanatci]?.akim ?? "")").font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                                    .foregroundStyle(Color(RGBA(css: "#e6e0d6")!))
                                Text(b.gorunenBaslik).font(Yazi.serif(32, agirlik: 500, stil: .title1)).tracking(-0.32).cssSatir(.serif, 32, 37.76)
                                    .foregroundStyle(Color(yazi)).lineLimit(2)
                                Text(BasyapitSatiri.sanatci(b, k)).font(Yazi.sans(15, stil: .subheadline))
                                    .foregroundStyle(Color(yazi, 0.84))
                            }
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 18).padding(.bottom, 44)
                        }
                        .overlay(alignment: .topLeading) {
                            EserRozetleri(hikaye: baglam.hikaye(e) != nil, ayrinti: baglam.ayrinti(e), uzun: true).padding(14)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            if eserler.count > 1 {
                HStack(spacing: 10) {
                    ForEach(eserler.indices, id: \.self) { i in
                        Button { elle = true; withAnimation { secili = i } } label: {
                            // `by-nok-*`: seçili nokta pirinç, öbürleri soluk
                            Capsule().fill(i == secili ? Color(tema.renkler.pirinc) : Color(RGBA(css: "#f3eee4")!, 0.42))
                                .frame(width: i == secili ? 20 : 6, height: 6)
                                .frame(width: 20, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(i + 1). öne çıkan eser")
                    }
                }
                .padding(.leading, 18 - 7)
            }
        }
        .frame(height: 372)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 25, y: 24)
        .onChange(of: eserler.map(\.anahtar)) { _, _ in secili = 0; eserler.first.map { secildi?($0) } }
        .onChange(of: secili, initial: true) { _, i in if eserler.indices.contains(i) { secildi?(eserler[i]) } }
        .task(id: eserler.map(\.anahtar)) {
            guard !hareketAz, !tema.ayar.hareketAzaltilmis, tema.ayar.hareket == "tam", eserler.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                guard !Task.isCancelled, !elle else { return }
                withAnimation(.easeInOut(duration: 0.6)) { secili = (secili + 1) % eserler.count }
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 20).onChanged { _ in elle = true })
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Öne çıkan eserler")
    }
}

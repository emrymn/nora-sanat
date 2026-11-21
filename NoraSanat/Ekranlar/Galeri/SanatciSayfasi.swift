// Kaynak: sanat-atlasi js/ekranlar/gozat.js (sanatciSayfasi, tumEserler, basyapitBaglariniDoldur, karsilastirSecici,
// karsilastirmaSutunu, karsilastirSayfasi), js/ekranlar/bugun.js (seritUst, eserSeridi, notBolumleri, donemCizelgesi),
// css/app.css (.sanatci-ust, .isim-blok, .serit-ust, .tumunu-goster, .eserler, .eser, .tumu, .izgara, .bolum,
// .basyapit-bag, .karsilastir-sec, .kars*) @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece).
import NoraCekirdek
import SwiftUI

/// `sanatciSayfasi(id)`: üstte akım etiketi, isim bloğu, eser şeridi (236 px, kırpmasız; sonunda "Tümü (n)"), notlar,
/// "Nasıl tanırım?" ve kırpımlar, yakın okumalar, dönem, Karşılaştır
struct SanatciSayfasi: View {
    let s: Sanatci
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri
    /// Tanıma kırpımları (GaleriSekmesi.kirpim): kırpım ve eser listesi → görünüm
    let kirpim: (TanimaKirpimi, [Eser]) -> AnyView
    @Environment(TemaDeposu.self) private var tema
    @State private var karsilastirAcik = false

    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }

    var body: some View {
        let r = tema.renkler
        let eserler = galeri.eserler[s.id] ?? []
        let k = galeri.katalog
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SanatciUst(etiket: s.akim, geri: eylem.geri) { eylem.git(.akim(s.akim)) }
                SanatciKunyesi(s: s, g: galeri, il: il)
                if eserler.isEmpty {
                    Text("Bu sanatçı için doğrulanmış görsel bulunamadı.").font(Yazi.sans(13, stil: .footnote))
                        .foregroundStyle(Color(r.murekkep2)).padding(.top, 22)
                } else {
                    // `seritUst`: "Eserleri · n" ve "Tümünü göster ›"
                    HStack {
                        Etiket("Eserleri · \(eserler.count)")
                        Spacer()
                        Button { eylem.git(.eserler(s.id)) } label: {
                            HStack(spacing: 4) {
                                Text("Tümünü göster").font(Yazi.sans(14, agirlik: 500, stil: .subheadline))
                                GaleriIkon(simge: .ileri, boyut: 15, kalinlik: 1.7)
                            }
                            .foregroundStyle(Color(r.murekkep))
                            .frame(height: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 22)
                    EserSeridi(eserler: eserler, resim: resim, ac: { eylem.ac(eserler, $0) }) {
                        Button { eylem.git(.eserler(s.id)) } label: {
                            Text("Tümü (\(eserler.count))").font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                                .foregroundStyle(Color(r.vurguAcik))
                                .frame(width: 120, height: 236)
                                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color(r.yuzey)))
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                }
                // `notBolumleri(s)`
                if let not = s.kursNotu ?? s.anlatim {
                    GaleriBolum(etiket: "Notlarımdan", vurgu: true) { OkumaMetni(metin: SiteYazisi.notTemizle(not), italik: true) }
                }
                let tanima = GoruntuleyiciKurallari.taninmaMetni(s, tanimaNotlari: galeri.tanimaNotlari)
                if !tanima.isEmpty {
                    GaleriBolum(etiket: "Nasıl tanırım?") {
                        OkumaMetni(metin: tanima)
                        let kirpimlar = galeri.sanatciKirpimlari[s.id] ?? []
                        if !kirpimlar.isEmpty {
                            ScrollView(.horizontal) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(Array(kirpimlar.enumerated()), id: \.offset) { _, x in
                                        kirpim(x, eserler).frame(width: 168)
                                    }
                                }
                                .padding(.horizontal, BenOlcu.yan)
                            }
                            .scrollIndicators(.hidden)
                            .padding(.horizontal, -BenOlcu.yan)
                            .padding(.top, 14)
                        }
                    }
                }
                // `basyapitBaglariniDoldur`: "Yakın okuma"
                let okumalar = galeri.basyapitlar.filter { $0["sanatci"]?.metin == s.id }
                if !okumalar.isEmpty {
                    GaleriBolum(etiket: "Yakın okuma") {
                        VStack(spacing: 0) {
                            ForEach(Array(okumalar.enumerated()), id: \.offset) { _, b in
                                GaleriSatir(ad: b["baslik"]?.metin ?? "", alt: b["ozet"]?.metin ?? "", kareVar: false) {
                                    eylem.git(.okuma(b["anahtar"]?.metin ?? ""))
                                }
                            }
                        }
                    }
                }
                GaleriBolum(etiket: "Dönemi") {
                    DonemCizelgesi(akimlar: k.akimlar, ad: s.akim) { eylem.git(.akim($0)) }
                }
                karsilastirSecici
                // `onemli_eserler`: "Önemli eserler" (tr ya da başlık, yıl)
                let onemli = (s.ham["onemli_eserler"]?.dizi ?? []).compactMap { e -> (String, String)? in
                    guard let ad = e["tr"]?.metin ?? e["baslik"]?.metin else { return nil }
                    return (ad, e["yil"]?.metin ?? e["yil"]?.tamSayi.map(String.init) ?? "")
                }
                if !onemli.isEmpty {
                    GaleriBolum(etiket: "Önemli eserler") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(onemli.enumerated()), id: \.offset) { _, e in
                                (Text("• " + e.0) + Text(e.1.isEmpty ? "" : " (\(e.1))").foregroundColor(Color(r.murekkep2)))
                                    .font(Yazi.okuma(19)).foregroundStyle(Color(r.murekkep))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: nil, ustHale: true))
    }

    /// `karsilastirSecici(s)`: "Karşılaştır" düğmesi (`details`); açılınca aynı / komşu akımdan en çok 8 sanatçı
    @ViewBuilder private var karsilastirSecici: some View {
        let k = galeri.katalog
        let benzer = Array(GoruntuleyiciKurallari.benzerSanatcilar(s, sanatcilar: k.sanatcilar, akimlar: k.akimlar).prefix(8))
        let acikIdler = Set(il.acikSanatcilar(k.sanatcilar).map(\.id))
        if !benzer.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.easeOut(duration: 0.25)) { karsilastirAcik.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        GaleriIkon(simge: .karsilastir, boyut: 18, kalinlik: 1.6)
                        Text("Karşılaştır")
                    }
                }
                .buttonStyle(HapDugme())
                .fixedSize()
                if karsilastirAcik {
                    Text("Benzer bir sanatçıyla yan yana gör:").font(Yazi.sans(13, stil: .footnote))
                        .foregroundStyle(Color(tema.renkler.murekkep2))
                    GaleriListe(ogeler: benzer) { x in
                        GaleriSatir(ad: x.ad, alt: "\(x.yillar) · \(x.akim)",
                                    rozet: acikIdler.contains(x.id) ? nil : "Henüz kursta yok", kareVar: false) {
                            eylem.git(.sanatciKarsilastir(s.id, x.id))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 26)
            .overlay(alignment: .top) { Ayrac() }
            .padding(.top, 16)
        }
    }
}

/// `eserSeridi`: yatay kayan eserler; 236 px yükseklik, oranına göre genişlik (en çok ekran − 48), kırpma yok
struct EserSeridi<Son: View>: View {
    let eserler: [Eser]
    let resim: GaleriResim
    let ac: (Int) -> Void
    @ViewBuilder var son: Son

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(Array(eserler.enumerated()), id: \.offset) { i, e in
                    let oran = resim.oran(e) ?? 0.75
                    let w = min(345, max(90, 236 * CGFloat(oran)))
                    EserKarti(eser: e, url: resim.url(e, 400), yedek: resim.yedek(e), oran: oran, yukseklik: 236,
                              genislik: w) { ac(i) }
                }
                son
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.top, 4).padding(.bottom, 8)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .padding(.horizontal, -BenOlcu.yan)
    }
}

// MARK: Tüm eserler

/// `tumEserler(id)`: üstte "Tüm eserler · n" ve sanatçının bilinen adı; iki sütunlu, kırpmasız duvar
struct TumEserler: View {
    let s: Sanatci
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri

    var body: some View {
        let eserler = galeri.eserler[s.id] ?? []
        let resim = GaleriResim(galeri: galeri, il: il)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GaleriSayfaUst(etiket: "Tüm eserler · \(eserler.count)", baslik: resim.bilinenAd(s.id), geri: eylem.geri)
                if eserler.isEmpty {
                    Text("Bu sanatçı için doğrulanmış görsel bulunamadı.").font(Yazi.sans(13, stil: .footnote))
                } else {
                    IkiSutunDuvar(eserler: eserler, resim: resim) { eylem.ac(eserler, $0) }.padding(.top, 8)
                }
            }
            .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: nil, ustHale: true))
    }
}

/// `.izgara`: iki sütun (12 aralık), resim sütun genişliğinde, kırpmasız; her eser kısa olan sütuna (18 px alt boşluk)
struct IkiSutunDuvar: View {
    let eserler: [Eser]
    let resim: GaleriResim
    let ac: (Int) -> Void

    var body: some View {
        GeometryReader { g in
            let w = (g.size.width - 12) / 2
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<2, id: \.self) { sutun in
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(dagit(w)[sutun], id: \.self) { i in
                            let e = eserler[i]
                            let oran = resim.oran(e) ?? 0.75
                            EserKarti(eser: e, url: resim.url(e, 400), yedek: resim.yedek(e), oran: oran,
                                      yukseklik: w / CGFloat(oran), genislik: w) { ac(i) }
                        }
                    }
                    .frame(width: w, alignment: .topLeading)
                }
            }
        }
        .frame(height: yukseklik)
    }

    /// Kartın tahmini yüksekliği: resim + ad (iki satır) + tarih
    private func boy(_ i: Int, _ w: CGFloat) -> CGFloat {
        w / CGFloat(resim.oran(eserler[i]) ?? 0.75) + 12 + 41.5 + 21.5
    }

    private func dagit(_ w: CGFloat) -> [[Int]] {
        var l: [[Int]] = [[], []], h: [CGFloat] = [0, 0]
        for i in eserler.indices {
            let s = h[0] <= h[1] ? 0 : 1
            l[s].append(i)
            h[s] += boy(i, w) + 18
        }
        return l
    }

    private var yukseklik: CGFloat {
        let w = (UIScreen.main.bounds.width - 2 * BenOlcu.yan - 12) / 2
        var h: [CGFloat] = [0, 0]
        for i in eserler.indices { let s = h[0] <= h[1] ? 0 : 1; h[s] += boy(i, w) + 18 }
        return max(h[0], h[1])
    }
}

// MARK: Sanatçı karşılaştırma

/// `karsilastirSayfasi(a, b)`: "Yan yana / Karşılaştır"; iki sütun: ad (30 px Bodoni, tam ad italik), yıllar ve akım,
/// "Nasıl tanırım?" (15 px), en bilinen dört eser
struct SanatciKarsilastir: View {
    let a: String
    let b: String
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let k = galeri.katalog
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GaleriSayfaUst(etiket: "Yan yana", baslik: "Karşılaştır", geri: eylem.geri)
                HStack(alignment: .top, spacing: 16) {
                    if let sa = k.harita[a] { sutun(sa) }
                    if let sb = k.harita[b] { sutun(sb) }
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: nil, ustHale: true))
        .sekmeCubuguGizli(true, sekme: .galeri)   // sitede karşılaştırma sekmesiz sayfa
    }

    private func sutun(_ s: Sanatci) -> some View {
        let r = tema.renkler
        let k = galeri.katalog
        let p = k.adParcalari(s)
        let resim = GaleriResim(galeri: galeri, il: il)
        let eserler = Array(Temsil.bilinirlikSirasi(galeri.eserler[s.id] ?? []).filter { !$0.gorseller.isEmpty }.prefix(4))
        let kilitli = !il.acikSanatcilar(k.sanatcilar).contains { $0.id == s.id }
        let tanima = GoruntuleyiciKurallari.taninmaMetni(s, tanimaNotlari: galeri.tanimaNotlari)
        return VStack(alignment: .leading, spacing: 10) {
            Button { eylem.git(.sanatci(s.id)) } label: {
                VStack(alignment: .leading, spacing: 0) {
                    if !p.ilk.isEmpty { Text(p.ilk).font(Yazi.okuma(15, italik: true)).foregroundStyle(Color(r.murekkep2)) }
                    Text(p.son).font(Yazi.serif(30, stil: .title1)).cssSatir(.serif, 30, 30.6).foregroundStyle(Color(r.murekkep))
                        .lineLimit(2).minimumScaleFactor(0.6)
                    if let tam = p.tam { Text(tam).font(Yazi.okuma(15, italik: true)).cssSatir(.okuma, 15, 18).foregroundStyle(Color(r.murekkep2)) }
                }
                .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(s.ad) — sanatçı sayfası")
            VStack(alignment: .leading, spacing: 0) {
                Text(s.yillar)
                HStack(spacing: 6) {
                    AkimNoktasi(renk: k.akimlar.first { $0.ad == s.akim }?.renk ?? "")
                    Text(s.akim)
                }
            }
            .font(Yazi.sans(12.5, stil: .footnote)).cssSatir(.sans, 12.5, 18.125)
            .foregroundStyle(Color(r.murekkep2))
            if kilitli { Rozet(metin: "Henüz kursta yok") }
            if tanima.isEmpty {
                Text("Bu sanatçı için “Nasıl tanırım?” notu henüz yok.").font(Yazi.sans(13, stil: .footnote))
                    .foregroundStyle(Color(r.murekkep2))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Etiket("Nasıl tanırım?")
                    Text(tanima).font(Yazi.okuma(15, stil: .subheadline)).cssSatir(.okuma, 15, 21.75)
                        .foregroundStyle(Color(r.murekkep)).fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(eserler.enumerated()), id: \.offset) { i, e in
                    GeometryReader { g in
                        EserKarti(eser: e, url: resim.url(e, 400), yedek: resim.yedek(e), oran: resim.oran(e),
                                  yukseklik: g.size.width / CGFloat(resim.oran(e) ?? 0.75), genislik: g.size.width) {
                            eylem.ac(eserler, i)
                        }
                    }
                    .frame(height: 164.5 / CGFloat(resim.oran(e) ?? 0.75) + 12 + 41.5 + 21.5)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

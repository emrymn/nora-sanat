// Kaynak: sanat-atlasi js/ekranlar/zaman.js (zamanSayfasi, cetvelHtml, guncelle, satirHtml, olaylariBagla),
// js/zaman.js (akimlaraAyir), css/app.css (.zm-panel, .zm-okur, .zm-adim, .zm-yil, .zm-cetvel, .zm-olcek, .zm-cubuklar,
// .zm-centik*, .zm-ibre, .zm-ipucu, .zm-grup, .zm-akim, .zm-nokta, .zm-satir*, .zm-kare, .zm-hayat, .zm-bos) @ a866b86
// Sitede Zaman Galeri'nin dördüncü sekmesidir (`gozAtUst('zaman')`); burada da GaleriSekmesi'nin `GaleriYolu.zaman`'ı açar.
import SwiftUI
import NoraCekirdek

struct ZamanEkrani: View {
    let katalog: SiteKatalogu
    let ilerleme: Ilerleme
    let ust: GaleriUst
    let sanatciAc: (String) -> Void
    @State private var yil: Int
    @State private var suruklemeBasi: Int?
    private let cubuklar: [ZamanKadrani.Cubuk]
    @Environment(TemaDeposu.self) private var tema

    /// `PX`: cetvelde bir yıl; `CUBUK_EN_YUKSEK`
    private let px: CGFloat = 4
    private let cubukEnYuksek = 30.0

    init(katalog: SiteKatalogu, ilerleme: Ilerleme, ust: GaleriUst, sanatciAc: @escaping (String) -> Void) {
        self.katalog = katalog
        self.ilerleme = ilerleme
        self.ust = ust
        self.sanatciAc = sanatciAc
        _yil = State(initialValue: ZamanKadrani.baslangic(katalog.sanatcilar, islenen: ilerleme.islenenKume))
        cubuklar = ZamanKadrani.yogunluk(katalog.sanatcilar, islenen: ilerleme.islenenKume)
    }

    private var r: TemaRenkleri { tema.renkler }

    var body: some View {
        let liste = ZamanKadrani.yasayanlar(katalog.sanatcilar, yil: yil)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ust.padding(.horizontal, BenOlcu.yan).padding(.top, 12)
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        // `.zm-ipucu`: 13px/1.45, --ink-3, 12 4 0
                        Text("Cetveli kaydır ya da dokun: o yıl hayatta olanlar aşağıda.")
                            .font(Yazi.sans(13)).lineSpacing(5.85 - 13 * 0.2).foregroundStyle(Color(r.murekkep3))
                            .padding(.top, 12).padding(.horizontal, 4)
                        if liste.isEmpty {
                            Text("Bu yıl için kayıtlı sanatçı yok. Cetveli biraz kaydır.")
                                .font(Yazi.sans(15)).foregroundStyle(Color(r.murekkep2))
                                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                .padding(.vertical, 28).padding(.horizontal, 4)
                        }
                        // `.zm-liste`: margin-top 8; her grup margin-top 24
                        ForEach(gruplar(liste), id: \.ad) { g in grup(g.ad, g.l).padding(.top, 24) }
                    }
                    .padding(.top, 0).padding(.bottom, 24)
                    .padding(.horizontal, BenOlcu.yan)
                } header: { panel(liste.count) }
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(r.zemin).ignoresSafeArea())
        .foregroundStyle(Color(r.murekkep))
        #if DEBUG && targetEnvironment(simulator)
        .task {
            if YolculukProva.ad == "zaman" {
                try? await Task.sleep(for: .seconds(3))
                YolculukProva.hazir("zaman")
            }
        }
        #endif
    }

    /// `akimlaraAyir(liste, d.akimlar)`: akımın sırasına göre (bilinmeyen akım sona)
    private func gruplar(_ liste: [ZamanKadrani.Yasam]) -> [(ad: String, l: [ZamanKadrani.Yasam])] {
        var sira = [String: Double]()
        for a in katalog.akimlar { sira[a.ad] = a.sira }
        var adlar = [String]()
        var harita = [String: [ZamanKadrani.Yasam]]()
        for x in liste {
            if harita[x.sanatci.akim] == nil { adlar.append(x.sanatci.akim) }
            harita[x.sanatci.akim, default: []].append(x)
        }
        let sirali = adlar.enumerated().sorted { a, b in
            let sa = sira[a.element] ?? 999, sb = sira[b.element] ?? 999
            return sa == sb ? a.offset < b.offset : sa < sb
        }
        return sirali.map { ($0.element, harita[$0.element] ?? []) }
    }

    // MARK: Panel (`.zm-panel`: yapışkan, %86 zemin + bulanık, alt çizgi)

    private func panel(_ sayi: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                adim(-10)
                // `.zm-yil`: etiket (vurgu), 52px/0.95 Bodoni yıl, 13px "n sanatçı hayatta" (sayı pirinç, kalın); 6 aralık
                VStack(spacing: 6) {
                    VurguEtiket(ZamanKadrani.evre(yil))
                    Text(String(yil)).font(Yazi.serif(52)).monospacedDigit().cssSatir(.serif, 52, 49.4)
                        .foregroundStyle(Color(r.murekkep))
                        .contentTransition(.numericText())
                    (Text("\(sayi)").font(Yazi.sans(13, agirlik: 700)).foregroundColor(Color(r.pirinc))
                     + Text(" sanatçı hayatta").font(Yazi.sans(13)).foregroundColor(Color(r.murekkep2)))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                adim(10)
            }
            .padding(.horizontal, BenOlcu.yan)
            cetvel.padding(.top, 10)
        }
        .padding(.top, 8)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color(r.zemin).opacity(0.86))
            }
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) { Ayrac() }
    }

    /// `.zm-olcek` (64 yükseklik): çubuklar alttan 30'da, çentik çizgisi alttan 30'da (22 + 8), yüzyıl yazıları altında;
    /// `.zm-ibre`: ortada pirinç çizgi (alttan 22, 40 boy) ve ucunda 11 pt elmas. Kenarlar %14'te solar (`mask`).
    private var cetvel: some View {
        GeometryReader { g in
            Canvas { baglam, boyut in
                let orta = boyut.width / 2
                let enCok = Double(max(1, cubuklar.map(\.sayi).max() ?? 1))
                let taban: CGFloat = 34
                for c in cubuklar where c.sayi > 0 {
                    let x = orta + CGFloat(c.id - yil) * px + 1
                    guard x > -50 && x < boyut.width + 10 else { continue }
                    let h = CGFloat(3 + (Double(cubukEnYuksek - 3) * Double(c.sayi) / enCok).rounded())
                    let renk = Color(GaleriRenk.akim(katalog, c.akim ?? ""), c.acik ? 0.85 : 0.25)
                    let yol = Path(roundedRect: CGRect(x: x, y: taban - h, width: 10 * px - 2, height: h),
                                   cornerRadii: .init(topLeading: 2, bottomLeading: 0, bottomTrailing: 0, topTrailing: 2))
                    baglam.fill(yol, with: .color(renk))
                }
                baglam.fill(Path(CGRect(x: 0, y: taban, width: boyut.width, height: 1)), with: .color(Color(r.murekkep3)))
                for y in stride(from: 1250, through: 2000, by: 10) {
                    let x = orta + CGFloat(y - yil) * px
                    guard x > -30 && x < boyut.width + 30 else { continue }
                    let buyuk = y % 100 == 0, ortaCentik = y % 50 == 0
                    let h: CGFloat = buyuk ? 10 : ortaCentik ? 7 : 4
                    let renk = buyuk ? r.murekkep : ortaCentik ? r.murekkep2 : r.murekkep3
                    baglam.fill(Path(CGRect(x: x, y: taban, width: 1, height: h)), with: .color(Color(renk)))
                    if buyuk {
                        baglam.draw(Text(String(y)).font(Yazi.sans(11, agirlik: 500)).monospacedDigit()
                                        .foregroundColor(Color(r.murekkep2)),
                                    at: CGPoint(x: x, y: taban + 12), anchor: .top)
                    }
                }
            }
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.14),
                                         .init(color: .black, location: 0.86), .init(color: .clear, location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .overlay {
                // ibre: alttan 22, 40 boy; elmas üst ucunda
                let x = g.size.width / 2
                ZStack {
                    Rectangle().fill(Color(r.pirinc)).frame(width: 1, height: 40).position(x: x + 0.5, y: 64 - 22 - 20)
                    Rectangle().fill(Color(r.pirinc)).frame(width: 11, height: 11).rotationEffect(.degrees(45))
                        .position(x: x + 0.5, y: 64 - 22 - 40 + 0.5)
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                let bas = suruklemeBasi ?? yil
                suruklemeBasi = bas
                yil = ZamanKadrani.sinirla(Double(bas) - Double(v.translation.width) / Double(px))
            }.onEnded { v in
                // cetvelde dokunulan yıl ibrenin altına gelir
                if abs(v.translation.width) < 3 {
                    let hedef = ZamanKadrani.sinirla(Double(yil) + Double(v.location.x - g.size.width / 2) / Double(px))
                    withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.3)) { yil = hedef }
                }
                suruklemeBasi = nil
            })
        }
        .frame(height: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yıl").accessibilityValue("\(yil)")
        .accessibilityAdjustableAction { yon in yil = ZamanKadrani.sinirla(Double(yil + (yon == .increment ? 1 : -1))) }
    }

    /// `.zm-adim`: 44, 1 px `--border`, saydam zemin, `--ink`; ikon 22 / 1.6
    private func adim(_ fark: Int) -> some View {
        Button {
            withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.3)) { yil = ZamanKadrani.sinirla(Double(yil + fark)) }
        } label: {
            GaleriIkon(simge: fark < 0 ? .geri : .ileri, boyut: 22, kalinlik: 1.6)
                .foregroundStyle(Color(r.murekkep))
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fark < 0 ? "10 yıl geri" : "10 yıl ileri")
    }

    // MARK: Liste

    /// `.zm-grup`: başlık (8 pt akım noktası, 500 21px Bodoni, sağda sayı 13px --ink-3), üst çizgili liste
    private func grup(_ ad: String, _ uyeler: [ZamanKadrani.Yasam]) -> some View {
        let renk = GaleriRenk.akim(katalog, ad)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Circle().fill(Color(renk)).frame(width: 8, height: 8).offset(y: -2)
                Text(ad).font(Yazi.serif(21, agirlik: 500)).foregroundStyle(Color(r.murekkep))
                Spacer(minLength: 0)
                Text("\(uyeler.count)").font(Yazi.sans(13, agirlik: 500)).monospacedDigit().foregroundStyle(Color(r.murekkep3))
            }
            .padding(.horizontal, 4).padding(.bottom, 8)
            .accessibilityAddTraits(.isHeader)
            Ayrac()
            ForEach(uyeler) { x in satir(x, renk) }
        }
    }

    /// `satirHtml`: 48 kare (en bilinen eser), 18px Newsreader ad, 13px yaş · yıllar (kilitliyse kilit + "Konu n'de açılır"),
    /// 3 pt hayat çizgisi (akım rengi, ucunda nokta); açıksa sağda ileri. En az 72 yükseklik, 10 4 iç boşluk.
    private func satir(_ x: ZamanKadrani.Yasam, _ renk: RGBA) -> some View {
        let s = x.sanatci
        let acik = ilerleme.islenenKume.contains(s.konu ?? -1)
        let govde = HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4).fill(Color(r.yuzey))
                .overlay {
                    if acik { UzakGorsel(url: katalog.kucukGorselAdresi(s.id, genislik: 200, kotuler: ilerleme.kotuGorseller), icerik: .fill) }
                }
                .frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 4))
                .opacity(acik ? 1 : 0.5)
            VStack(alignment: .leading, spacing: 4) {
                Text(katalog.bilinenAd(s.id) ?? s.ad).font(Yazi.okuma(18)).lineLimit(1)
                    .foregroundStyle(Color(acik ? r.murekkep : r.murekkep3))
                HStack(spacing: 4) {
                    Text(x.yas(yil) + " ·")
                    if acik {
                        Text(SiteYazisi.yillarYaz(dogum: s.dogum, olum: s.olum))
                    } else {
                        GaleriIkon(simge: .kilit, boyut: 12, kalinlik: 1.8).padding(.trailing, 2)
                        Text("Konu \(SiteYazisi.bulunmaEki(s.konu ?? 0)) açılır")
                    }
                }
                .font(Yazi.sans(13)).foregroundStyle(Color(r.murekkep2)).lineLimit(1)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(r.kenar))
                        Capsule().fill(Color(renk)).frame(width: g.size.width * x.pay(yil)).opacity(acik ? 1 : 0.35)
                        Circle().fill(Color(r.murekkep)).frame(width: 7, height: 7)
                            .offset(x: g.size.width * x.pay(yil) - 3.5)
                    }
                }
                .frame(height: 3).padding(.top, 2)
            }
            if acik { GaleriIkon(simge: .ileri, boyut: 18, kalinlik: 1.6).foregroundStyle(Color(r.murekkep3)) }
        }
        .padding(.vertical, 10).padding(.horizontal, 4)
        .frame(minHeight: 72)
        .overlay(alignment: .bottom) { Ayrac() }
        return Group {
            if acik {
                Button { sanatciAc(s.id) } label: { govde.contentShape(Rectangle()) }.buttonStyle(.plain)
            } else {
                govde.accessibilityElement(children: .combine)
            }
        }
    }
}

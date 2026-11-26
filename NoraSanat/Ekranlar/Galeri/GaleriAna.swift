// Z3w (yeni tasarım, sitede yok): Galeri › Akımlar, Neon'un "Yön 2 · Kemerlerin yayı" tasarımı (Emre seçti).
// Kaynak: dal `neon/galeri-akimlar-2` (PR #60, birleştirilmedi, yalnız referans): `tasarim/galeri-akimlar-2/yon-2.html`,
// `BENIOKU.md` "Yön 2", `goruntuler/yon-2-{gece,gunduz,gecis}.png`. Geometri ve geçişler `NoraCekirdek/Galeri/KemerYayi`.
// Önceki ekran (sitenin çarkı, gozat.js `carkHtml`/`carkKur` @ a866b86) yerini bu tasarıma bıraktı; sitede hâlâ çark var.
import NoraCekirdek
import SwiftUI

/// Galeri'nin ana ekranı: akımların kemerli salon kartları yatay bir şeritte geniş bir yay boyunca süzülür; altında sabit
/// "Salona gir", 52 pt'lik ışık kılavuzu (‹ önceki · dönem · sonraki ›) ve alttan açılan cam "Bütün akımlar" çekmecesi.
struct KemerSalonlari: View {
    let salonlar: [AkimDurumu]
    let galeri: GaleriKatalogu
    let il: Ilerleme
    @Binding var sira: Int
    @Binding var dizinAcik: Bool
    let kapak: (String) -> (url: URL?, yedek: URL?)
    /// Çekmecedeki küçük kapak (400 px)
    let pul: (String) -> URL?
    let gir: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    /// Şeridin anlık konumu (akım cinsinden, kesirli). Z3z2: her karede değiştiği için `@State` değil; yalnız kılavuzun
    /// çentikleri ve eylem yuvasının saydamlığı okur, ekranın geri kalanı (kartlar) kaydırırken yeniden kurulmaz.
    @State private var iz = SeritKonumu()
    /// Z3z3: şeridin kendi seçili akımı (kılavuz, eylem yuvası, erişilebilirlik). `sira` (üst görünüm: sayfa zemini,
    /// tablonun renkleri, katalog süzmesi) kaydırma sürerken değişmez, şerit durunca bir kez yazılır. Önceden her akım
    /// geçişinde bütün Galeri sayfası yeniden kuruluyor, zeminin tam ekran renk geçişi kaydırmanın ortasında başlıyordu.
    @State private var yerel = 0
    @State private var kayiyor = false
    @State private var secim: Int?
    /// Z3z: akımın yılları (`KemerYayi.yillar`); kaydırırken her karede katalog taranmasın diye bir kez hesaplanır
    @State private var yillar: [String: String] = [:]
    /// Z3z2: akımın kapak adresi (`carkKapagi`, her çağrıda bütün sanatçıları süzüp sıralıyor); bir kez hesaplanır.
    /// Önceden kaydırırken her karede görünen her kart için yeniden aranıyordu (Z3z'den sonra da "kasıyor").
    @State private var kapaklar: [String: KapakAdresi] = [:]

    private var kartG: CGFloat { CGFloat(KemerYayi.kartGenisligi) }
    private var kartY: CGFloat { CGFloat(KemerYayi.kartYuksekligi) }
    /// `.kemer-yazi`: 10 üst pay, en az 82 (iki satırlık ad sığsın diye 100)
    static let yaziYuksekligi: CGFloat = 100
    /// `.kemer-serit`: 10 üst + kemer + yazı + yay düşüşü (15) ve gölge payı
    static var seritYuksekligi: CGFloat { 10 + CGFloat(KemerYayi.kartYuksekligi) + 10 + yaziYuksekligi + 18 }

    private var kurulumAnahtari: [String] {
        salonlar.map { "\($0.ad)|\($0.acik)" } + [String(il.kotuGorseller.values.reduce(0) { $0 + $1.count })]
    }

    private var hareketYok: Bool { hareketAz || tema.ayar.hareketAzaltilmis }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            VStack(spacing: 0) {
                serit(w)
                eylemYuvasi.padding(.top, 2)
                kilavuz(w).padding(.top, 10)
                dizinTetigi.padding(.top, 2).id("dizin")
            }
            .frame(width: w)
        }
        .frame(height: Self.seritYuksekligi + 2 + 46 + 10 + 52 + 2 + 44)
        .onAppear { secim = sira; yerel = sira; iz.deger = Double(sira); yillariKur() }
        // Kapak açılan akıma ve bozuk görsellere de bağlı (`carkKapagi`)
        .onChange(of: kurulumAnahtari) { _, _ in yillariKur() }
        .sheet(isPresented: $dizinAcik) {
            AkimDizini(salonlar: salonlar, galeri: galeri, sira: yerel, pul: pul) { i in
                dizinAcik = false
                git(i)
            }
            .environment(tema)
            .presentationDetents([.fraction(0.78), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
            .presentationBackground {
                // buzlu cam (`--surface-cam` + `backdrop-filter: blur(28px)`)
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color(tema.renkler.yuzey, tema.renkler.koyu ? 0.78 : 0.84)
                }
            }
        }
    }

    // MARK: Kemer şeridi

    private func serit(_ w: CGFloat) -> some View {
        let kenar = (w - kartG) / 2
        return ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: CGFloat(KemerYayi.aralik)) {
                ForEach(Array(salonlar.enumerated()), id: \.offset) { i, salon in
                    kart(i, salon)
                        .frame(width: kartG)
                        .id(i)
                }
            }
            .scrollTargetLayout()
            .padding(.top, 10)
            .background(GeometryReader { p in
                Color.clear.preference(key: SeritKaymasi.self, value: p.frame(in: .named("kemer-serit")).minX)
            })
        }
        .coordinateSpace(name: "kemer-serit")
        // Z3e: iOS 18'de kaydırma içindeki GeometryReader tercihi kaydırırken güncellenmiyor; orada kaydırma geometrisi
        .modifier(SeritKaymaIzi { yol in konumYaz(yol) })
        .contentMargins(.horizontal, kenar, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $secim, anchor: .center)
        .scrollIndicators(.hidden)
        // eğilen kartlar, gölge ve kemere bağlı yazı şeridin kutusundan taşar
        .scrollClipDisabled()
        .onPreferenceChange(SeritKaymasi.self) { x in
            if #available(iOS 18, *) { return }
            konumYaz(kenar - x)
        }
        .onChange(of: sira) { _, yeni in
            if yerel != yeni { yerel = yeni }
            if secim != yeni { secim = yeni }
        }
        .modifier(SeritEvresi { kayiyor = $0; if !$0 { siraYaz(yerel) } })
        .onChange(of: secim) { _, yeni in
            guard let yeni else { return }
            siraYaz(yeni)
            // Şerit bir karta oturduysa konum da orada olmalı (kaydırma bildirimi gelmese bile)
            if abs(iz.deger - Double(yeni)) > 0.5 { iz.deger = Double(yeni) }
        }
        .frame(height: Self.seritYuksekligi, alignment: .top)
        // Kart değişince sesli okuyucu ve sayfa zemini için yalnız `sira` değişir; şerit yalnız yatay sürüklemeyi alır,
        // dikey sürükleme sayfanındır (yatay ScrollView dikeyi bırakır).
    }

    private func yillariKur() {
        var y: [String: String] = [:]
        var k: [String: KapakAdresi] = [:]
        for s in salonlar {
            y[s.ad] = KemerYayi.yillar(galeri.katalog.sanatcilar.filter { $0.akim == s.ad })
            let a = kapak(s.ad)
            k[s.ad] = KapakAdresi(url: a.url, yedek: a.yedek)
        }
        yillar = y
        kapaklar = k
    }

    /// Şeridin kaydığı yol (içerik başından) → anlık konum ve seçili akım
    private func konumYaz(_ yol: CGFloat) {
        let p = KemerYayi.konum(yol: Double(yol), sayi: salonlar.count)
        if abs(p - iz.deger) > 0.001 { iz.deger = p }
        siraYaz(Int(p.rounded()))
    }

    /// Şeridin seçili akımı hemen; üst görünüme (`sira`) yalnız şerit dururken
    private func siraYaz(_ yeni: Int) {
        if yeni != yerel { yerel = yeni }
        if !kayiyor && yeni != sira { sira = yeni }
    }

    /// `.kemer-oge`: kemer ve ona bağlı yazı birlikte eğilir, alçalır ve küçülür.
    /// Z3z2: eğim, ölçek, düşüş ve saydamlıklar `visualEffect` ile kartın şeritteki yerinden her karede çizim sırasında
    /// hesaplanır (`seritteKart`); kartın gövdesi kaydırırken yeniden kurulmaz.
    private func kart(_ i: Int, _ salon: AkimDurumu) -> some View {
        let acik = salon.acik, az = hareketYok
        return Button {
            if i != yerel { git(i) } else if salon.acik { gir(salon.ad) }
        } label: {
            VStack(spacing: 0) {
                kemer(salon)
                yazi(salon)
                    .visualEffect { c, g in
                        let k = seritteKart(g, acik: acik, hareketAz: az)
                        return c.opacity(k.yaziOpakligi).offset(y: CGFloat(k.yaziKaymasi))
                    }
            }
            .frame(width: kartG)
            .contentShape(Rectangle())
        }
        .buttonStyle(KartBasma())
        .visualEffect { c, g in
            let k = seritteKart(g, acik: acik, hareketAz: az)
            return c.scaleEffect(CGFloat(k.olcek))
                .rotationEffect(.degrees(k.aci))
                .offset(y: CGFloat(k.kayma))
                .opacity(k.opaklik)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(i == yerel && salon.acik ? "Salona gir" : "")
    }

    /// `.kemer-dis` + `.kemer-kutu`: çift ince çerçeve (dışta 1 pt pirinç, 5 pt pay, içte kapağın kendi ince kenarı)
    private func kemer(_ salon: AkimDurumu) -> some View {
        let r = tema.renkler
        let adres = kapaklar[salon.ad] ?? KapakAdresi(url: nil, yedek: nil)
        let ic = CGSize(width: kartG - 10, height: kartY - 10)
        let acik = salon.acik, az = hareketYok
        let golge: RGBA = r.koyu ? r.zemin : r.murekkep
        let altGolge: [Gradient.Stop] = [.init(color: Color(golge, 0), location: 0.76),
                                         .init(color: Color(golge, r.koyu ? 0.32 : 0.14), location: 1)]
        // Z3z (akıcılık): kaydırırken her karede değişen bulanıklık yarıçapı, parlaklık filtresi ve gölge yarıçapı
        // görseli her karede yeniden işletiyordu (Emre: "kasıyor"). Kapak katmanı artık kaydırmayla değişmiyor ve bir kez
        // dokuya çiziliyor (`drawingGroup`): kilitli kapağın bulanıklığı sabit, komşu kartın bulanıklığı kalktı (tasarımda da
        // yoktu, yalnız soluyorlardı), parlaklık üstte bir peçe, gölge sabit yarıçaplı; yakınlık yalnız saydamlıkla.
        return ZStack {
            Color(r.yuzey)
            UzakGorsel(url: adres.url, icerik: .fill, yedek: adres.yedek)
                .saturation(salon.acik ? 1 : 0.45)
                .brightness(salon.acik ? 0 : (r.koyu ? -0.22 : -0.1))
                .scaleEffect(salon.acik ? 1 : 1.06)
                .blur(radius: salon.acik ? 0 : CGFloat(KemerYayi.kilitBulanikligi), opaque: true)
            LinearGradient(stops: altGolge, startPoint: .top, endPoint: .bottom)
            if !salon.acik { kilitPecesi }
        }
        .frame(width: ic.width, height: ic.height)
        .clipShape(Kemer(alt: 16))
        .drawingGroup()
        // Kaydırmaya bağlı katmanlar yalnız saydamlıklarıyla değişir (`visualEffect`, gövde yeniden kurulmaz)
        .overlay {
            if acik {
                Kemer(alt: 16).fill(Color.black)
                    .visualEffect { c, g in c.opacity(1 - seritteKart(g, acik: true, hareketAz: az).parlaklik) }
            }
        }
        .overlay(Kemer(alt: 16).stroke(Color(r.pirinc), lineWidth: 0.5)
            .visualEffect { c, g in c.opacity(0.12 + 0.2 * kartYakinligi(seritteKart(g, acik: acik, hareketAz: az))) })
        .padding(5)
        .overlay(Kemer(alt: 21).stroke(Color(r.pirinc), lineWidth: 1)
            .visualEffect { c, g in c.opacity(seritteKart(g, acik: acik, hareketAz: az).cerceve) })
        .frame(width: kartG, height: kartY)
        // `--kart-golge` (ortada) ↔ `--kart-golge-yan`: yarıçap sabit, yakınlık yalnız saydamlıkta
        .background(
            Kemer(alt: 21).fill(Color(golge))
                .shadow(color: Color(golge, r.koyu ? 0.52 : 0.17), radius: 24, y: 22)
                .padding(4)
                .visualEffect { c, g in c.opacity(0.45 + 0.55 * kartYakinligi(seritteKart(g, acik: acik, hareketAz: az))) }
        )
    }

    /// `.kilit-pece` + `.kilit-muhur`: kenarlara doğru koyulaşan peçe, ortada camdan 44 pt'lik kilit mührü
    private var kilitPecesi: some View {
        let r = tema.renkler
        let pece: [Gradient.Stop] = [.init(color: Color(r.zemin, 0), location: 0.16),
                                     .init(color: Color(r.zemin, r.koyu ? 0.26 : 0.24), location: 1)]
        return ZStack {
            RadialGradient(stops: pece, center: .center, startRadius: 0, endRadius: kartY * 0.6)
            GaleriIkon(simge: .kilit, boyut: 18, kalinlik: 1.6)
                .foregroundStyle(Color(r.murekkep, 0.9))
                .frame(width: 44, height: 44)
                // `drawingGroup` içinde malzeme (ultraThinMaterial) çizilmez: arkası zaten bulanık, düz cam rengi yeter
                .background(Circle().fill(Color(r.zemin, r.koyu ? 0.62 : 0.72)))
                .overlay(Circle().stroke(Color(r.murekkep, r.koyu ? 0.24 : 0.16), lineWidth: 1))
                .clipShape(Circle())
        }
    }

    /// `.kemer-yazi`: 300 genişlik (kartın iki yanından taşar): dönem sembolüyle yıllar, akım adı, durum
    private func yazi(_ salon: AkimDurumu) -> some View {
        let r = tema.renkler
        let donem = DonemSembolu.bul(salon.sira)
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                DonemIkonu(donem: donem, boyut: 14)
                Text(yillar[salon.ad] ?? "").monospacedDigit()
            }
            .font(Yazi.sans(13, agirlik: 600, stil: .footnote)).cssSatir(.sans, 13, 16.9)
            .foregroundStyle(Color(r.pirinc))
            Text(salon.ad)
                .font(Yazi.serif(31, agirlik: 500, stil: .title1)).tracking(-0.31).cssSatir(.serif, 31, 33.5)
                .foregroundStyle(Color(salon.acik ? r.murekkep : r.murekkep2))
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                .padding(.top, 4)
            HStack(spacing: 6) {
                if !salon.acik { GaleriIkon(simge: .kilit, boyut: 13, kalinlik: 1.6) }
                Text(KemerYayi.durum(salon))
            }
            .font(Yazi.sans(14, stil: .subheadline)).cssSatir(.sans, 14, 18.2)
            .foregroundStyle(Color(r.murekkep2))
            .padding(.top, 5)
        }
        .frame(width: 300, height: Self.yaziYuksekligi, alignment: .top)
        .padding(.top, 10)
    }

    // MARK: Eylem yuvası

    /// `.eylem-yuva`: sabit yerde tek dolu düğme; başparmak düğmeyi kovalamaz. Kilitliyse cam bir hap.
    private var eylemYuvasi: some View {
        let r = tema.renkler
        let salon = salonlar.indices.contains(yerel) ? salonlar[yerel] : nil
        return ZStack {
            if let salon, salon.acik {
                Button { gir(salon.ad) } label: {
                    HStack(spacing: 7) {
                        Text("Salona gir").font(Yazi.sans(15, agirlik: 600, stil: .subheadline))
                        GaleriIkon(simge: .ileri, boyut: 16, kalinlik: 2)
                    }
                    .foregroundStyle(Color(r.zemin))
                    .padding(.leading, 26).padding(.trailing, 22)
                    .frame(height: 46)
                    .background(Capsule().fill(Color(r.murekkep)))
                    .contentShape(Capsule())
                }
                .buttonStyle(KartBasma(olcek: 0.96))
                .accessibilityLabel("Salona gir, \(salon.ad)")
            } else if let salon {
                HStack(spacing: 7) {
                    GaleriIkon(simge: .kilit, boyut: 14, kalinlik: 1.6)
                    Text("\(salon.toplam) sanatçı · yakında")
                }
                .font(Yazi.sans(13.5, agirlik: 500, stil: .footnote))
                .foregroundStyle(Color(r.murekkep2))
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background(Capsule().fill(.ultraThinMaterial))
                .background(Capsule().fill(Color(r.ustDugme)))
                .overlay(Capsule().stroke(Color(r.kenar), lineWidth: 1))
                .clipShape(Capsule())
                .accessibilityElement(children: .combine)
            }
        }
        .frame(height: 46)
        .frame(maxWidth: .infinity)
        .modifier(EylemSoluklugu(iz: iz, aciklar: salonlar.map(\.acik)))
    }

    // MARK: Işık kılavuzu

    /// `.isik-kilavuzu`: 52 pt; ince pirinç ufuk yayı, şeritle kayan çentikler, tepede ışık noktası; iki yanda önceki ve
    /// sonraki akım. Hiçbir sürükleme yakalamaz (yalnız düğmeler): dikey sayfa kaydırması hep geçer.
    private func kilavuz(_ w: CGFloat) -> some View {
        let r = tema.renkler
        let onceki = KemerYayi.komsu(yerel, yon: -1, sayi: salonlar.count)
        let sonraki = KemerYayi.komsu(yerel, yon: 1, sayi: salonlar.count)
        let donem = salonlar.indices.contains(yerel) ? DonemSembolu.bul(salonlar[yerel].sira) : nil
        return ZStack(alignment: .top) {
            KilavuzCizimi(iz: iz) { c, boyut, konum in kilavuzCiz(&c, boyut, konum) }
                .frame(width: w, height: 52)
                .allowsHitTesting(false)
            HStack(spacing: 0) {
                komsuDugmesi(onceki, yon: -1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 6) {
                    if let donem {
                        DonemIkonu(donem: donem, boyut: 14).foregroundStyle(Color(r.pirinc))
                        Text(donem.kisa)
                    }
                }
                .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                .foregroundStyle(Color(r.murekkep))
                .padding(.horizontal, 10)
                .fixedSize()
                komsuDugmesi(sonraki, yon: 1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .frame(height: 52, alignment: .top)
        }
        .frame(width: w, height: 52)
        .clipped()
        // Erişilebilirlik: eski çarkın ayarlanabilir eylemi ve değeri kılavuzda
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Akımlar çarkı")
        .accessibilityValue(salonlar.indices.contains(yerel) ? "\(yerel + 1) / \(salonlar.count), \(salonlar[yerel].ad)" : "")
        .accessibilityAdjustableAction { yon in
            git(yon == .increment ? yerel + 1 : yerel - 1)
        }
    }

    /// `.kilavuz-donem-btn`: ‹ önceki / sonraki › akım; uçta görünmez
    private func komsuDugmesi(_ hedef: Int?, yon: Int) -> some View {
        let r = tema.renkler
        let ad = hedef.map { salonlar[$0].ad } ?? ""
        return Button { if let hedef { git(hedef) } } label: {
            HStack(spacing: 4) {
                if yon < 0 { GaleriIkon(simge: .geri, boyut: 13, kalinlik: 1.8) }
                Text(ad).lineLimit(1).truncationMode(.tail)
                if yon > 0 { GaleriIkon(simge: .ileri, boyut: 13, kalinlik: 1.8) }
            }
            .font(Yazi.sans(12.5, agirlik: 500, stil: .caption1))
            .foregroundStyle(Color(r.murekkep3))
            .padding(.horizontal, 6)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(hedef == nil ? 0 : 1)
        .disabled(hedef == nil)
    }

    /// SVG `viewBox 0 0 390 54`, `preserveAspectRatio="none"`: `M 18 24 Q 195 4 372 24` (iki uca silinen pirinç),
    /// çentikler (`centikCiz`), `circle 195 14` ışık (r 11 hale, r 3 nokta)
    private func kilavuzCiz(_ c: inout GraphicsContext, _ boyut: CGSize, _ konum: Double) {
        let r = tema.renkler
        let sx = boyut.width / 390, sy = boyut.height / 54
        func n(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
        var yay = Path()
        yay.move(to: n(18, 24))
        yay.addQuadCurve(to: n(372, 24), control: n(195, 4))
        let silinme = Gradient(stops: [.init(color: Color(r.pirinc, 0), location: 0), .init(color: Color(r.pirinc, 0.34), location: 0.22),
                                       .init(color: Color(r.pirinc, 0.72), location: 0.5), .init(color: Color(r.pirinc, 0.34), location: 0.78),
                                       .init(color: Color(r.pirinc, 0), location: 1)])
        c.stroke(yay, with: .linearGradient(silinme, startPoint: .zero, endPoint: CGPoint(x: boyut.width, y: 0)), lineWidth: 1)
        for k in KemerYayi.centikler(konum: konum, genislik: Double(boyut.width)) {
            var p = Path()
            p.move(to: CGPoint(x: CGFloat(k.x), y: CGFloat(k.y + 3) * sy))
            p.addLine(to: CGPoint(x: CGFloat(k.x), y: CGFloat(k.y + 8) * sy))
            c.stroke(p, with: .color(Color(r.murekkep, 0.28 * k.opaklik)), lineWidth: 1)
        }
        let orta = n(195, 14)
        let hale = Gradient(stops: [.init(color: Color(r.pirinc, 0.45), location: 0), .init(color: Color(r.pirinc, 0), location: 1)])
        c.fill(Path(ellipseIn: CGRect(x: orta.x - 11, y: orta.y - 11, width: 22, height: 22)),
               with: .radialGradient(hale, center: orta, startRadius: 0, endRadius: 11))
        c.fill(Path(ellipseIn: CGRect(x: orta.x - 3, y: orta.y - 3, width: 6, height: 6)), with: .color(Color(r.pirinc)))
    }

    // MARK: Bütün akımlar

    /// `.dizin-tetik`: "Bütün akımlar · 28 salon ⌃"; dokununca cam çekmece açılır
    private var dizinTetigi: some View {
        let r = tema.renkler
        return Button { dizinAcik = true } label: {
            HStack(spacing: 6) {
                Text("Bütün akımlar").font(Yazi.sans(13.5, agirlik: 500, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                Text("· \(salonlar.count) salon").font(Yazi.sans(13.5, stil: .footnote)).foregroundStyle(Color(r.murekkep3))
                GaleriIkon(simge: .asagi, boyut: 14, kalinlik: 1.8).rotationEffect(.degrees(180))
                    .foregroundStyle(Color(r.murekkep2))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(dizinAcik ? "açık" : "kapalı")
    }

    private func git(_ i: Int) {
        guard !salonlar.isEmpty else { return }
        let hedef = max(0, min(salonlar.count - 1, i))
        withAnimation(hareketYok ? nil : .easeOut(duration: 0.35)) {
            secim = hedef
            yerel = hedef
            sira = hedef
        }
        if hareketYok { iz.deger = Double(hedef) }
    }
}

// MARK: Çekmece

/// `.cekmece`: "Bütün akımlar" başlığı, dönem dönem gruplanmış akımlar (dönem sembolü, "a / n açık"), satırda küçük kapak
/// (kilitliyse bulanık ve soluk), ad, yıllar · durum. Dokunulan akım şeritte ortaya gelir.
private struct AkimDizini: View {
    let salonlar: [AkimDurumu]
    let galeri: GaleriKatalogu
    let sira: Int
    let pul: (String) -> URL?
    let sec: (Int) -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat

    private struct Grup: Identifiable {
        let donem: DonemSembolu
        var oge: [(i: Int, a: AkimDurumu)]
        var id: String { donem.rawValue }
    }

    /// Dönem dönem (akımlar zaten dönem sırasında; aynı dönem art arda gelir)
    private var gruplar: [Grup] {
        var sonuc: [Grup] = []
        for (i, a) in salonlar.enumerated() {
            let d = DonemSembolu.bul(a.sira)
            if let son = sonuc.indices.last, sonuc[son].donem == d {
                sonuc[son].oge.append((i, a))
            } else {
                sonuc.append(Grup(donem: d, oge: [(i, a)]))
            }
        }
        return sonuc
    }

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 0) {
            HStack {
                Text("Bütün akımlar").font(Yazi.serif(24, agirlik: 500)).tracking(-0.24)
                    .foregroundStyle(Color(r.murekkep))
                Spacer()
                Button { kapat() } label: {
                    GaleriIkon(simge: .kapat, boyut: 18, kalinlik: 1.8).foregroundStyle(Color(r.murekkep2))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, -10)
                .accessibilityLabel("Kapat")
            }
            .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 10)
            Rectangle().fill(Color(r.kenar, 0.6)).frame(height: 1)
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(gruplar) { g in grup(g.donem, g.oge) }
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func grup(_ d: DonemSembolu, _ oge: [(i: Int, a: AkimDurumu)]) -> some View {
        let r = tema.renkler
        return VStack(spacing: 8) {
            HStack {
                HStack(spacing: 7) {
                    DonemIkonu(donem: d, boyut: 14)
                    Text(d.ad).font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                }
                .foregroundStyle(Color(r.pirinc))
                Spacer()
                Text("\(oge.filter { $0.a.acik }.count) / \(oge.count) açık")
                    .font(Yazi.sans(12.5, stil: .caption1)).foregroundStyle(Color(r.murekkep3))
            }
            .padding(.horizontal, 2)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(oge.enumerated()), id: \.offset) { j, x in
                    if j > 0 { Rectangle().fill(Color(r.kenar, 0.6)).frame(height: 1) }
                    satir(x.i, x.a)
                }
            }
            .background(RoundedRectangle(cornerRadius: 22).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(r.kenar), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    private func satir(_ i: Int, _ a: AkimDurumu) -> some View {
        let r = tema.renkler
        let yillar = KemerYayi.yillar(galeri.katalog.sanatcilar.filter { $0.akim == a.ad })
        return Button { sec(i) } label: {
            HStack(spacing: 12) {
                ZStack {
                    Color(r.zemin)
                    UzakGorsel(url: pul(a.ad), icerik: .fill)
                        .saturation(a.acik ? 1 : 0.4)
                        .brightness(a.acik ? 0 : (r.koyu ? -0.22 : -0.1))
                        .scaleEffect(a.acik ? 1 : 1.08)
                        .blur(radius: a.acik ? 0 : 1.4, opaque: true)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(r.kenar, 0.6), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(a.ad).font(Yazi.serif(17.5, agirlik: 500)).tracking(-0.17)
                        .foregroundStyle(Color(a.acik ? r.murekkep : r.murekkep2))
                        .multilineTextAlignment(.leading)
                    Text([yillar, KemerYayi.durum(a)].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(Yazi.sans(12.5, stil: .caption1)).foregroundStyle(Color(r.murekkep2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                GaleriIkon(simge: a.acik ? .ileri : .kilit, boyut: 16, kalinlik: 1.8)
                    .foregroundStyle(Color(a.acik ? r.pirinc : r.murekkep3))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(minHeight: 60)
            .background(i == sira ? Color(r.pirinc, 0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(i == sira ? .isSelected : [])
    }
}

// MARK: Dönemler

/// Tasarımın dönem sembolleri (`DONEMLER`, yon-2.html): `GaleriDonem.bolgeler` ile aynı dokuz dönem
enum DonemSembolu: String, CaseIterable, Hashable {
    case ortacag, ronesans, barok, barok2, aydinlanma, romantik, empresyonizm, postempresyonizm, modern

    static func bul(_ sira: Double) -> DonemSembolu { DonemSembolu(rawValue: GaleriDonem.bul(sira)) ?? .modern }

    var ad: String {
        switch self {
        case .ortacag: return "Orta Çağ"
        case .ronesans: return "Rönesans"
        case .barok: return "Barok"
        case .barok2: return "Klasisizm ve Geç Barok"
        case .aydinlanma: return "Rokoko ve Neoklasisizm"
        case .romantik: return "Romantizmden Realizme"
        case .empresyonizm: return "Empresyonizm"
        case .postempresyonizm: return "Post-Empresyonizm ve Sembolizm"
        case .modern: return "Modern sanat"
        }
    }

    var kisa: String {
        switch self {
        case .barok2: return "Klasisizm"
        case .aydinlanma: return "Rokoko"
        case .romantik: return "Romantizm"
        case .postempresyonizm: return "Post-Emp."
        case .modern: return "Modern"
        default: return ad
        }
    }

    /// 24 × 24 SVG (Orta Çağ'ın `translate(0 3)`'ü yola işlendi)
    var isaretleme: String {
        switch self {
        case .ortacag:
            return #"<path d="M12 7c1.4 2.4 2.8 3.2 5.2 4.6-2.4 1.4-3.8 2.2-5.2 4.6-1.4-2.4-2.8-3.2-5.2-4.6C9.2 10.2 10.6 9.4 12 7Z"/><circle cx="12" cy="11.6" r="1.4"/>"#
        case .ronesans:
            return #"<circle cx="12" cy="12" r="7.5"/><rect x="6.7" y="6.7" width="10.6" height="10.6"/><path d="m6.7 6.7 10.6 10.6M17.3 6.7 6.7 17.3"/>"#
        case .barok:
            return #"<path d="M12 5c2.2 2.2 2.2 5.4 0 7.6-2.2-2.2-2.2-5.4 0-7.6Z"/><path d="M5 16c0-3 2.5-4.5 4.8-3 1.4-2 3-2 4.4 0 2.3-1.5 4.8 0 4.8 3"/>"#
        case .barok2:
            return #"<path d="M8 18c-3-2.5-3.5-8.5 0-12M16 18c3-2.5 3.5-8.5 0-12M9.5 19.5 12 17.5l2.5 2"/>"#
        case .aydinlanma:
            return #"<path d="M4.5 15.5c0-5 3.4-9 7.5-9s7.5 4 7.5 9c-2.5 1.4-12.5 1.4-15 0Z"/><path d="M12 16.5V6.5M12 16.5l-4.5-7M12 16.5l4.5-7"/>"#
        case .romantik:
            return #"<path d="M14.8 5.5a6.5 6.5 0 1 0 3.7 11.4 5.4 5.4 0 0 1-3.7-11.4Z"/>"#
        case .empresyonizm:
            return #"<path d="M5 9l4 2M13 7l5 2M7 15l5 2M15 14l4 2"/><circle cx="11" cy="11" r="1.2"/>"#
        case .postempresyonizm:
            return #"<path d="M12 12c0-1.5 1.4-2.2 2.6-1.4 1.6 1 1.6 3.6-.2 4.8-2.4 1.6-5.6.4-6.4-2.4-1-3.4 1.4-7 5-7.6 4.2-.8 8 2.4 8.2 6.6"/>"#
        case .modern:
            return #"<circle cx="12" cy="12" r="5.5"/><path d="M5 19 19 5"/>"#
        }
    }
}

struct DonemIkonu: View {
    let donem: DonemSembolu
    var boyut: CGFloat = 14

    var body: some View {
        SimgeSekli(komutlar: SVGYolu.komutlar(isaretleme: donem.isaretleme))
            .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .frame(width: boyut, height: boyut)
            .accessibilityHidden(true)
    }
}

// MARK: Yardımcılar

/// Z3z2: şeridin anlık konumu. Yalnız okuyan görünümler (kılavuz çizimi, eylem yuvasının saydamlığı) her karede yenilenir.
@MainActor @Observable
final class SeritKonumu {
    var deger: Double = 0
}

struct KapakAdresi {
    let url: URL?
    let yedek: URL?
}

/// Kartın şeritteki yerinden `KemerYayi.kart`: `fark` = (kartın ortası − şeridin ortası) / adım. Önceden `konum`'dan
/// (i − konum) hesaplanıyordu; ikisi aynı, yalnız uçtaki esnek taşmada kart da hafifçe eğilir.
func seritteKart(_ g: GeometryProxy, acik: Bool, hareketAz: Bool) -> KemerYayi.Kart {
    let f = g.frame(in: .scrollView(axis: .horizontal))
    let genislik = g.bounds(of: .scrollView(axis: .horizontal))?.width ?? f.width
    let fark = Double(f.midX - genislik / 2) / KemerYayi.adim
    return KemerYayi.kart(fark: fark, acik: acik, hareketAz: hareketAz)
}

/// Yakınlık ölçekten (0,89 → 1)
func kartYakinligi(_ k: KemerYayi.Kart) -> Double { (k.olcek - 0.89) / 0.11 }

/// Eylem yuvası açık ile kilitli akım arasında geçerken söner (`KemerYayi.eylemOpakligi`); konumu yalnız bu okur
private struct EylemSoluklugu: ViewModifier {
    let iz: SeritKonumu
    let aciklar: [Bool]
    func body(content: Content) -> some View {
        content.opacity(KemerYayi.eylemOpakligi(konum: iz.deger, aciklar: aciklar))
    }
}

/// Işık kılavuzunun çizimi; konumu yalnız bu okur
private struct KilavuzCizimi: View {
    let iz: SeritKonumu
    let ciz: (inout GraphicsContext, CGSize, Double) -> Void
    var body: some View {
        let p = iz.deger
        Canvas { c, boyut in ciz(&c, boyut, p) }
    }
}

/// iOS 18: şeridin kaydırma geometrisi; `degisti`'ye içeriğin başından kayılan yol verilir
/// (`contentOffset.x + contentInsets.leading`; ilk kart ortadayken 0). iOS 17'de tercih (`SeritKaymasi`) kullanılır.
private struct SeritKaymaIzi: ViewModifier {
    let degisti: (CGFloat) -> Void
    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x + $0.contentInsets.leading } action: { _, x in
                degisti(x)
            }
        } else {
            content
        }
    }
}

/// Z3z3, iOS 18: şerit kayıyor mu (sürükleme, fırlatma, oturma); iOS 17'de hep "durgun" (eski davranış)
private struct SeritEvresi: ViewModifier {
    let degisti: (Bool) -> Void
    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.onScrollPhaseChange { _, yeni in degisti(yeni != .idle) }
        } else {
            content
        }
    }
}

private struct SeritKaymasi: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Basınca hafifçe küçülür (`.salona-gir:active { transform: scale(0.96) }`)
private struct KartBasma: ButtonStyle {
    var olcek: CGFloat = 0.98
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? olcek : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Kemer: üst köşeler genişliğin yarısı (yarım daire), alt köşeler `alt`
struct Kemer: Shape {
    var alt: CGFloat = 16
    func path(in r: CGRect) -> Path {
        let u = r.width / 2
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + u))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + u), radius: u, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - alt))
        p.addQuadCurve(to: CGPoint(x: r.maxX - alt, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + alt, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - alt), control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

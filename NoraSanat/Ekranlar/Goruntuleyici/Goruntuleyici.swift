// Kaynak: sanat-atlasi js/goruntuleyici.js, js/ayrinti.js, js/hikaye.js, js/keskin.js, js/koleksiyon.js, js/bildirim.js, js/karsilastir.js @ a866b86
import SwiftUI
import NoraCekirdek

/// Tam ekran eser görüntüleyici (`Goruntuleyici(eserler:baslangic:)`).
///
/// Sitedeki `js/goruntuleyici.js` davranışlarını SwiftUI ile taşır:
/// - İki parmakla yakınlaştırma (1x…6x), çift dokunuşla 2.5x ↔ 1x yakınlaştırma, kaydırma.
/// - Tek dokunuşla sade görünüm (düğmeler ve alt künye kartı gizlenir, zemin tam siyah olur).
/// - Eserler arası geçiş (yatay kaydırma veya sol/sağ ok düğmeleri; ilk eserde sağa çekince kapanma).
/// - Aşağı çekince tablonun küçülüp zeminin şeffaflaşması ve bırakınca kapanma.
/// - Künye (başlık, tarih, özgün ad, eser notu, konu bağlantısı, ortak atıf, müze, görsel kaynağı, büyük kopya kaynağı, kaynak sayfası, sıra).
/// - Rehberli ayrıntı noktaları ("İncele · N nokta", numaralı noktalar, noktaya otomatik yakınlaşma).
/// - Resmin hikâyesi ("Hikâyesi" paneli ve "Karakterleri resimde gör").
/// - Koleksiyon işareti ve "⋯" hata/kötü görsel bildirim menüsü (`IlerlemeKoprusu` üzerinden ilerlemeye yazar).
/// - Keskin üst kopya: önce 1280/800 px kopya açılır, 4096 px en büyük kopya arkada inip yerine geçer.
/// - Z2c-3b: geliştirici modunda ve Ayarlar → "Sırayla ortala"da (`ortalama`) "Odağı işaretle": tabloya dokunulan nokta
///   bu cihazın elle odağı olur (`ElleOdaklar`); çerçeve Bugün'ün açılışta göstereceği alan (sitenin İş 150/159/161'i).
@MainActor
public struct Goruntuleyici: View {
    public let eserler: [Eser]
    public let baslangic: Int
    public var gizli: Bool
    public var incelemeyeBasla: Bool
    /// İncelemeyi bu ayrıntı noktasında aç (`incelemeNokta`, G3: başyapıt sayfasındaki kırpımlar)
    public var incelemeNokta: Int?
    public var hikayeyeBasla: Bool
    public var baglam: GoruntuleyiciBaglami?
    public var konuSecildi: ((String) -> Void)?
    public var kapaninca: ((Int) -> Void)?
    /// Ayarlar → "Sırayla ortala": her yeni eserde odak kipi kendiliğinden açılır
    public var ortalama: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var sira: Int
    @State private var yuklenenBaglam: GoruntuleyiciBaglami?
    @State private var kotuler: [String: [String]] = [:]
    @State private var koleksiyonda: Bool = false
    @State private var zorlananGorsel: Gorsel? = nil

    // Yakınlaştırma ve kaydırma durumu
    @State private var olcek: CGFloat = 1.0
    @State private var sonOlcek: CGFloat = 1.0
    @State private var kayma: CGSize = .zero
    @State private var sonKayma: CGSize = .zero
    @State private var asagiCekme: CGFloat = 0.0
    @State private var sadeGorunum: Bool = false
    @State private var dogalUzunKenar: Double = 1280.0

    // Alt paneller ve menüler
    @State private var bildirMenuAcik: Bool = false
    @State private var mesaj: String = ""
    @State private var etkinInceleme: AyrintiKaydi? = nil
    @State private var incelemeSira: Int = -1
    @State private var hikayeAcik: Bool = false
    @State private var ilkAcilisYapildi: Bool = false
    @State private var bekleyenNokta: Int? = nil
    /// Y1: "Dinleyerek bak"
    @State private var dinleAcik = false

    // Z2c-3b: elle odak
    @State private var gelistirici = false
    @State private var odakModu = false
    @State private var kendiliginden: Int? = nil
    @State private var odakVerisi = OdakVerisi()
    @State private var elleSurum = 0

    public init(
        eserler: [Eser],
        baslangic: Int = 0,
        gizli: Bool = false,
        incelemeyeBasla: Bool = false,
        incelemeNokta: Int? = nil,
        hikayeyeBasla: Bool = false,
        baglam: GoruntuleyiciBaglami? = nil,
        konuSecildi: ((String) -> Void)? = nil,
        kapaninca: ((Int) -> Void)? = nil,
        ortalama: Bool = false
    ) {
        self.ortalama = ortalama
        self.eserler = eserler
        let guvenliBaslangic = eserler.isEmpty ? 0 : min(max(0, baslangic), eserler.count - 1)
        self.baslangic = guvenliBaslangic
        self.gizli = gizli
        self.incelemeyeBasla = incelemeyeBasla
        self.incelemeNokta = incelemeNokta
        self.hikayeyeBasla = hikayeyeBasla
        self.baglam = baglam
        self.konuSecildi = konuSecildi
        self.kapaninca = kapaninca
        self._sira = State(initialValue: guvenliBaslangic)
    }

    private var etkinBaglam: GoruntuleyiciBaglami {
        baglam ?? yuklenenBaglam ?? GoruntuleyiciBaglami()
    }

    private var simdikiEser: Eser? {
        guard sira >= 0, sira < eserler.count else { return nil }
        return eserler[sira]
    }

    private var simdikiGorsel: Gorsel? {
        guard let e = simdikiEser else { return nil }
        return zorlananGorsel ?? etkinBaglam.secilenGorsel(e, kotuler: kotuler)
    }

    private var simdikiAyrinti: AyrintiKaydi? {
        guard !gizli, let e = simdikiEser else { return nil }
        return etkinBaglam.ayrinti(e)
    }

    private var simdikiHikaye: HikayeKaydi? {
        guard !gizli, let e = simdikiEser else { return nil }
        return etkinBaglam.hikaye(e)
    }

    private var cekOrani: Double {
        min(1.0, max(0.0, Double(asagiCekme) / 420.0))
    }

    private var arayuzOpakligi: Double {
        if sadeGorunum { return 0.0 }
        return max(0.0, 1.0 - cekOrani * 3.0)
    }

    public var body: some View {
        GeometryReader { geo in
            let sahneBoyutu = geo.size
            let zeminOpakligi = sadeGorunum ? 1.0 : max(0.08, 1.0 - cekOrani * 0.92)

            ZStack {
                (sadeGorunum ? Color.black : GoruntuleyiciTema.zemin)
                    .opacity(zeminOpakligi)
                    .ignoresSafeArea()

                if let eser = simdikiEser {
                    let gorsel = simdikiGorsel
                    let adresler = gorsel.map { etkinBaglam.adresler($0) } ?? GoruntuleyiciGorselAdresleri()
                    let oran = gorsel.flatMap { etkinBaglam.gorselAdresleri.oran($0) } ?? 1.0
                    let tabanBoyutu = sigdirBoyutu(sahne: sahneBoyutu, oran: oran)

                    // Sahne: tablo ışığı + görsel + ayrıntı noktaları
                    ZStack {
                        TabloIsigiGorunumu(
                            url: adresler.isik,
                            opaklikCarpani: 1.0 - cekOrani
                        )

                        GoruntuleyiciGorseli(
                            birincil: adresler.birincil,
                            yedek: adresler.yedek,
                            devasa: adresler.devasa
                        ) { boyut in
                            dogalUzunKenar = max(Double(boyut.width), Double(boyut.height))
                        }
                        .scaleEffect(olcek * CGFloat(1.0 - cekOrani * 0.45))
                        .offset(x: kayma.width, y: kayma.height)

                        if odakModu, let r = tuvalCercevesi(taban: tabanBoyutu, sahne: sahneBoyutu) {
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                .frame(width: r.width, height: r.height)
                                .position(x: r.midX, y: r.midY)
                                .allowsHitTesting(false)
                        }

                        if let inceleme = etkinInceleme {
                            AyrintiNoktalariKatmani(
                                kayit: inceleme,
                                seciliSira: incelemeSira,
                                tabanBoyutu: tabanBoyutu,
                                olcek: olcek * CGFloat(1.0 - cekOrani * 0.45),
                                kayma: kayma
                            ) { secilenNokta in
                                noktayaGit(secilenNokta, taban: tabanBoyutu, sahne: sahneBoyutu, gorsel: gorsel)
                            }
                            .opacity(asagiCekme > 0 ? 0 : 1)
                            .task {
                                // `incelemeNokta`: inceleme açılınca doğrudan o ayrıntıya git
                                guard let n = bekleyenNokta else { return }
                                bekleyenNokta = nil
                                try? await Task.sleep(nanoseconds: 350_000_000)
                                noktayaGit(n, taban: tabanBoyutu, sahne: sahneBoyutu, gorsel: gorsel)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        ciftDokunus(taban: tabanBoyutu, sahne: sahneBoyutu)
                    }
                    .onTapGesture(count: 1, coordinateSpace: .local) { konum in
                        if odakModu {
                            odakIsaretle(konum, taban: tabanBoyutu, sahne: sahneBoyutu)
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            sadeGorunum.toggle()
                        }
                    }
                    .gesture(yakinlastirmaJesti(taban: tabanBoyutu, sahne: sahneBoyutu))
                    .simultaneousGesture(kaydirmaJesti(taban: tabanBoyutu, sahne: sahneBoyutu))

                    // Üst ve yan yuvarlak düğmeler + alt künye kartı
                    VStack(spacing: 0) {
                        ustCubuk(eser: eser)
                            .padding(.horizontal, 12)
                            .padding(.top, 10)

                        Spacer()

                        if eserler.count > 1 {
                            yanOklar(sahne: sahneBoyutu, taban: tabanBoyutu)
                                .padding(.horizontal, 8)
                            Spacer()
                        }

                        if !sadeGorunum {
                            altKart(eser: eser, gorsel: gorsel, taban: tabanBoyutu, sahne: sahneBoyutu)
                        }
                    }
                    .opacity(arayuzOpakligi)
                    .allowsHitTesting(!sadeGorunum && asagiCekme == 0)

                    // Hikâye paneli
                    if hikayeAcik, let hikaye = simdikiHikaye {
                        HikayePaneliGorunumu(
                            hikaye: hikaye,
                            kapat: {
                                withAnimation(.easeOut(duration: 0.22)) {
                                    hikayeAcik = false
                                }
                            },
                            karakterleriGor: { karKaydi in
                                hikayeAcik = false
                                incelemeBaslat(karKaydi)
                                noktayaGit(0, taban: tabanBoyutu, sahne: sahneBoyutu, gorsel: gorsel)
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(6)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await verileriYukle()
        }
        .onChange(of: sira) { _, _ in
            eserDegisti()
        }
        .fullScreenCover(isPresented: $dinleAcik) {
            if let e = simdikiEser {
                DinleEkrani(eser: e, baglam: etkinBaglam, gorsel: simdikiGorsel)
            }
        }
    }

    // MARK: - Üst çubuk ve yan oklar

    private func ustCubuk(eser: Eser) -> some View {
        HStack {
            if !eser.sid.isEmpty {
                Button {
                    Task { await koleksiyonDegistir(eser: eser) }
                } label: {
                    Image(systemName: koleksiyonda ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(koleksiyonda ? GoruntuleyiciTema.zemin : GoruntuleyiciTema.murekkep)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(koleksiyonda ? GoruntuleyiciTema.murekkep : GoruntuleyiciTema.yuvarlakDugmeZemini)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(koleksiyonda ? GoruntuleyiciTema.murekkep : GoruntuleyiciTema.kenar, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(koleksiyonda ? "Koleksiyonumdan çıkar" : "Koleksiyonuma ekle")
            }

            Spacer()

            Button {
                kapat()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(GoruntuleyiciTema.yuvarlakDugmeZemini))
                    .overlay(Circle().strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kapat")
        }
    }

    private func yanOklar(sahne: CGSize, taban: CGSize) -> some View {
        HStack {
            Button {
                git(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(GoruntuleyiciTema.yuvarlakDugmeZemini))
                    .overlay(Circle().strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Önceki eser")
            .opacity(sira > 0 ? 1 : 0.35)
            .disabled(sira <= 0)

            Spacer()

            Button {
                git(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(GoruntuleyiciTema.yuvarlakDugmeZemini))
                    .overlay(Circle().strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sonraki eser")
            .opacity(sira < eserler.count - 1 ? 1 : 0.35)
            .disabled(sira >= eserler.count - 1)
        }
    }

    // MARK: - Alt künye ve eylem kartı (`.gor-alt`)

    private func altKart(eser: Eser, gorsel: Gorsel?, taban: CGSize, sahne: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let inceleme = etkinInceleme {
                AyrintiIncelemePaneli(
                    kayit: inceleme,
                    seciliSira: incelemeSira,
                    onceki: {
                        noktayaGit(incelemeSira - 1, taban: taban, sahne: sahne, gorsel: gorsel)
                    },
                    sonraki: {
                        noktayaGit(incelemeSira + 1, taban: taban, sahne: sahne, gorsel: gorsel)
                    },
                    bitir: {
                        incelemeBitir(geriDon: true)
                    }
                )
            } else {
                if !gizli {
                    kunyeGorunumu(eser: eser, gorsel: gorsel)
                }

                eylemSatiri(eser: eser, gorsel: gorsel)

                if odakGorunur {
                    odakSatiri()
                }

                if bildirMenuAcik {
                    bildirMenusu(eser: eser, gorsel: gorsel)
                }
            }

            if !mesaj.isEmpty {
                Text(mesaj)
                    .font(.system(size: 13))
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24)
                .fill(GoruntuleyiciTema.yuzey)
        )
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24)
                .strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func kunyeGorunumu(eser: Eser, gorsel: Gorsel?) -> some View {
        let baslik = eser.gorunenAd
        let ozgun = SiteYazisi.notTemizle(eser.baslik)
        let notMetni = etkinBaglam.eserNotu(eser)
        let konu = etkinBaglam.konu(eser)
        let kaynakMetni = GoruntuleyiciKurallari.kaynakYazisi(eser, gorsel: gorsel)
        let devasaKaynagi = gorsel.map { etkinBaglam.gorselAdresleri.devasaKaynagi($0) } ?? ""
        let sayfaStr = gorsel.map { etkinBaglam.gorselAdresleri.sayfa($0) } ?? ""
        let sayfaUrl = GorselAdresleri.url(sayfaStr)

        // Başlık + tarih
        (Text(baslik)
            .font(.system(size: 21, weight: .regular, design: .serif))
            .italic()
            .foregroundStyle(GoruntuleyiciTema.murekkep)
        + Text(eser.tarih.isEmpty ? "" : " · \(eser.tarih)")
            .font(.system(size: 18, weight: .regular, design: .serif))
            .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep))

        // Özgün ad (Türkçe addan farklıysa)
        if let ad = eser.ad, !ad.isEmpty, ad != eser.baslik, !ozgun.isEmpty {
            Text(ozgun)
                .font(.system(size: 13.5))
                .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
        }

        // Eser notu
        if !notMetni.isEmpty {
            Text(notMetni)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(GoruntuleyiciTema.murekkep)
                .lineSpacing(3)
                .padding(.top, 2)
        }

        // İkonografi konusu bağlantısı
        if let konu {
            Button {
                let hedef = "#/konu/\(SiteYazisi.uriBileseni(konu.id))"
                kapat()
                if let konuSecildi {
                    konuSecildi(konu.id)
                } else {
                    Gezgin.shared.git(hedef)
                }
            } label: {
                Text("Konu: \(konu.ad) →")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }

        // Kaynak satırı + büyük kopya + kaynak sayfası + sıra
        HStack(spacing: 4) {
            let parcalar: [String] = [
                kaynakMetni,
                devasaKaynagi.isEmpty ? "" : "büyük kopya: \(devasaKaynagi) · CC0",
                eserler.count > 1 ? "\(sira + 1) / \(eserler.count)" : "",
            ].filter { !$0.isEmpty }

            Text(parcalar.joined(separator: " · "))
                .font(.system(size: 12.5))
                .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)

            if let sayfaUrl {
                Text("·")
                    .font(.system(size: 12.5))
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)

                Button {
                    openURL(sayfaUrl)
                } label: {
                    Text(gorsel?.k == "wikiart" ? "eser sayfası" : "kaynak sayfası")
                        .font(.system(size: 12.5))
                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private func eylemSatiri(eser: Eser, gorsel: Gorsel?) -> some View {
        HStack(spacing: 8) {
            if let ayrinti = simdikiAyrinti {
                Button {
                    incelemeBaslat(ayrinti)
                } label: {
                    Text("İncele · \(ayrinti.noktalar.count) nokta")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.zemin))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if simdikiHikaye != nil {
                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        hikayeAcik.toggle()
                    }
                } label: {
                    Text("Hikâyesi")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.zemin))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if !gizli {
                // Y1: yer varsa yazıyla, yoksa yalnız simge
                Button {
                    dinleAcik = true
                } label: {
                    ViewThatFits(in: .horizontal) {
                        Label("Dinleyerek bak", systemImage: "headphones").padding(.horizontal, 14)
                        Image(systemName: "headphones").frame(width: 44)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .frame(minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.zemin))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dinleyerek bak")
            }

            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    bildirMenuAcik.toggle()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.zemin))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bu görsel hatalı mı?")
        }
        .padding(.top, 4)
    }

    private func bildirMenusu(eser: Eser, gorsel: Gorsel?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().overlay(GoruntuleyiciTema.kenar)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(BildirimKurallari.nedenler, id: \.self) { neden in
                    Button {
                        Task { await nedenSec(neden: neden, eser: eser, gorsel: gorsel) }
                    } label: {
                        Text(neden)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GoruntuleyiciTema.murekkep)
                            .underline(color: GoruntuleyiciTema.yanlisIkon)
                            .frame(minHeight: 38, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Etkileşimler ve jestler

    private func sigdirBoyutu(sahne: CGSize, oran: Double) -> CGSize {
        guard sahne.width > 0, sahne.height > 0 else { return CGSize(width: 320, height: 320) }
        let gecerliOran = oran > 0 ? CGFloat(oran) : 1.0
        var w = sahne.width
        var h = w / gecerliOran
        if h > sahne.height {
            h = sahne.height
            w = h * gecerliOran
        }
        return CGSize(width: w, height: h)
    }

    private func kaymaSinirla(_ aday: CGSize, olcek: CGFloat, taban: CGSize, sahne: CGSize) -> CGSize {
        let g = taban.width * olcek
        let y = taban.height * olcek
        let mx = max(0, (g - sahne.width) / 2.0)
        let my = max(0, (y - sahne.height) / 2.0)
        return CGSize(
            width: min(mx, max(-mx, aday.width)),
            height: min(my, max(-my, aday.height))
        )
    }

    private func yakinlastirmaJesti(taban: CGSize, sahne: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { deger in
                let yeni = min(CGFloat(GoruntuleyiciKurallari.enBuyukOlcek), max(1.0, sonOlcek * deger))
                olcek = yeni
                kayma = kaymaSinirla(sonKayma, olcek: yeni, taban: taban, sahne: sahne)
            }
            .onEnded { _ in
                if olcek <= 1.02 {
                    sifirla(animasyonlu: true)
                } else {
                    sonOlcek = olcek
                    kayma = kaymaSinirla(kayma, olcek: olcek, taban: taban, sahne: sahne)
                    sonKayma = kayma
                }
            }
    }

    private func kaydirmaJesti(taban: CGSize, sahne: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { deger in
                let dx = deger.translation.width
                let dy = deger.translation.height
                if olcek > 1.01 {
                    let aday = CGSize(width: sonKayma.width + dx, height: sonKayma.height + dy)
                    kayma = kaymaSinirla(aday, olcek: olcek, taban: taban, sahne: sahne)
                } else if dy > 0 && abs(dy) > abs(dx) {
                    asagiCekme = dy
                    kayma = CGSize(width: dx * 0.7, height: dy)
                } else {
                    asagiCekme = 0
                    kayma = CGSize(width: dx, height: max(0, dy) * 0.6)
                }
            }
            .onEnded { deger in
                let dx = deger.translation.width
                let dy = deger.translation.height
                if olcek > 1.01 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        kayma = kaymaSinirla(kayma, olcek: olcek, taban: taban, sahne: sahne)
                        sonKayma = kayma
                    }
                } else if abs(dx) > 60 && abs(dx) > abs(dy) {
                    if dx > 0 && sira == 0 {
                        kapat()
                    } else {
                        git(dx < 0 ? 1 : -1)
                    }
                } else if dy > 120 && abs(dy) > abs(dx) {
                    kapat()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        asagiCekme = 0
                        kayma = .zero
                        sonKayma = .zero
                    }
                }
            }
    }

    private func ciftDokunus(taban: CGSize, sahne: CGSize) {
        if olcek > 1.01 {
            sifirla(animasyonlu: true)
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                olcek = 2.5
                sonOlcek = 2.5
                kayma = kaymaSinirla(.zero, olcek: 2.5, taban: taban, sahne: sahne)
                sonKayma = kayma
            }
        }
    }

    private func sifirla(animasyonlu: Bool = false) {
        let islem = {
            olcek = 1.0
            sonOlcek = 1.0
            kayma = .zero
            sonKayma = .zero
            asagiCekme = 0.0
        }
        if animasyonlu {
            withAnimation(.easeOut(duration: 0.25), islem)
        } else {
            islem()
        }
    }

    private func git(_ fark: Int) {
        let yeni = sira + fark
        guard yeni >= 0, yeni < eserler.count else {
            withAnimation(.easeOut(duration: 0.2)) {
                kayma = .zero
                sonKayma = .zero
                asagiCekme = 0
            }
            return
        }
        withAnimation(.easeOut(duration: 0.2)) {
            sira = yeni
        }
    }

    private func kapat() {
        kapaninca?(sira)
        dismiss()
    }

    // MARK: - Rehberli inceleme (`js/ayrinti.js`)

    private func incelemeBaslat(_ kayit: AyrintiKaydi) {
        bildirMenuAcik = false
        mesaj = ""
        etkinInceleme = kayit
        incelemeSira = -1
        sifirla(animasyonlu: true)
    }

    private func incelemeBitir(geriDon: Bool) {
        etkinInceleme = nil
        incelemeSira = -1
        if geriDon && olcek > 1.01 {
            sifirla(animasyonlu: true)
        }
    }

    private func noktayaGit(_ hedefSira: Int, taban: CGSize, sahne: CGSize, gorsel: Gorsel?) {
        guard let inceleme = etkinInceleme,
              hedefSira >= 0, hedefSira < inceleme.noktalar.count else { return }
        let nokta = inceleme.noktalar[hedefSira]
        incelemeSira = hedefSira
        let devasaVar = !(gorsel.map { etkinBaglam.gorselAdresleri.devasaUrl($0) } ?? "").isEmpty
        let kaynakBoyut = devasaVar ? max(dogalUzunKenar, 4096.0) : dogalUzunKenar
        let enCok = AyrintiKurallari.yakinlasmaSiniri(
            kaynak: kaynakBoyut,
            taban: Double(max(taban.width, taban.height)),
            dpr: Double(UIScreen.main.scale),
            enCok: GoruntuleyiciKurallari.enBuyukOlcek
        )
        if let odak = AyrintiKurallari.noktaOdagi(
            nokta,
            taban: (Double(taban.width), Double(taban.height)),
            sahne: (Double(sahne.width), Double(sahne.height)),
            enCok: enCok
        ) {
            withAnimation(.easeInOut(duration: 0.56)) {
                olcek = CGFloat(odak.olcek)
                sonOlcek = CGFloat(odak.olcek)
                kayma = CGSize(width: odak.tx, height: odak.ty)
                sonKayma = kayma
                asagiCekme = 0
            }
        }
    }

    // MARK: - Veri yükleme, koleksiyon ve bildirimler

    private func verileriYukle() async {
        if baglam == nil && yuklenenBaglam == nil {
            yuklenenBaglam = await GoruntuleyiciBaglami.yukle()
        }
        if let il = try? await IlerlemeKoprusu.shared.oku() {
            kotuler = il.kotuGorseller
            koleksiyonda = KoleksiyonKurallari.koleksiyondaMi(il, eser: simdikiEser)
            gelistirici = il[alan: "gelistirici"]?.nesne != nil
        }
        if (gelistirici || ortalama) && !gizli {
            odakVerisi = OdakVerisi(veriler: await SiteVerisi().veriler(OdakVerisi.dosyalar))
            kendiliginOdak()
        }
        if !ilkAcilisYapildi {
            ilkAcilisYapildi = true
            if incelemeyeBasla, let ayrinti = simdikiAyrinti {
                bekleyenNokta = incelemeNokta
                incelemeBaslat(ayrinti)
            } else if hikayeyeBasla, simdikiHikaye != nil {
                hikayeAcik = true
            }
        }
    }

    private func eserDegisti() {
        if odakModu { odakModu = false }
        zorlananGorsel = nil
        sifirla(animasyonlu: false)
        bildirMenuAcik = false
        mesaj = ""
        hikayeAcik = false
        if etkinInceleme != nil {
            incelemeBitir(geriDon: false)
        }
        kendiliginOdak()
        Task {
            if let il = try? await IlerlemeKoprusu.shared.oku() {
                kotuler = il.kotuGorseller
                koleksiyonda = KoleksiyonKurallari.koleksiyondaMi(il, eser: simdikiEser)
            }
        }
    }

    private func koleksiyonDegistir(eser: Eser) async {
        let bugun = GunTarihi.gun(Date())
        do {
            var yeniDurum = !koleksiyonda
            try await IlerlemeKoprusu.shared.degistir { il in
                yeniDurum = KoleksiyonKurallari.degistir(&il, eser: eser, tarih: bugun)
            }
            koleksiyonda = yeniDurum
            mesaj = yeniDurum ? "Koleksiyonuna eklendi." : "Koleksiyonundan çıkarıldı."
        } catch {
            // Site köprüsü henüz hazır değilse yerel durumu güncelle
            koleksiyonda.toggle()
            mesaj = koleksiyonda ? "Koleksiyonuna eklendi." : "Koleksiyonundan çıkarıldı."
        }
    }

    private func nedenSec(neden: String, eser: Eser, gorsel: Gorsel?) async {
        bildirMenuAcik = false
        let bugun = GunTarihi.gun(Date())
        var sonraki: Gorsel? = nil
        do {
            try await IlerlemeKoprusu.shared.degistir { il in
                sonraki = BildirimKurallari.eseriBildir(&il, eser: eser, gorsel: gorsel, neden: neden, tarih: bugun)
                kotuler = il.kotuGorseller
            }
        } catch {
            // Köprü hazır değilse bellekteki `kotuler` üzerinde uygula
            var gecici = (try? Ilerleme(json: .nesne(.bos))) ?? Ilerleme(hamBos: true)
            gecici.kotuGorseller = kotuler
            sonraki = BildirimKurallari.eseriBildir(&gecici, eser: eser, gorsel: gorsel, neden: neden, tarih: bugun)
            kotuler = gecici.kotuGorseller
        }

        if neden == "Kötü görsel" {
            if let sonraki {
                zorlananGorsel = sonraki
                mesaj = "Başka bir görsele geçildi."
            } else {
                mesaj = "Bu eserin başka görseli yok; pekiştirmede gösterilmeyecek."
            }
        } else {
            mesaj = "Bildirildi: bu eser artık pekiştirmede çıkmayacak."
        }
    }
}

// MARK: - Z2c-3b: elle odak (sitenin js/goruntuleyici.js odak kipi, İş 150/159/161)

extension Goruntuleyici {
    /// Odak düğmesi geliştirici modunda ve "Sırayla ortala"da görünür
    private var odakGorunur: Bool { !gizli && (gelistirici || ortalama) && simdikiGorsel != nil }

    /// Görselin yerel adı (`gorselAdi(g)`); yoksa odak kaydedilemez
    private var simdikiAd: String { simdikiGorsel.flatMap { etkinBaglam.gorselAdresleri.yerelAd($0) } ?? "" }

    /// Odak verisi, bu cihazdaki elle odaklarla (her işaretten sonra `elleSurum` artar)
    private var guncelOdak: OdakVerisi {
        _ = elleSurum
        var o = odakVerisi
        o.cihaz = ElleOdaklar.hepsi
        return o
    }

    /// `elleOdakKaynagi(g)`: "cihaz", "depo" ya da nil
    private func odakKaynagi(_ ad: String) -> String? {
        let o = guncelOdak
        if OdakVerisi.gecerli(o.cihaz[ad]) { return "cihaz" }
        return OdakVerisi.gecerli(o.elleDosya[ad]) ? "depo" : nil
    }

    private func odakDurumu() -> String {
        let ad = simdikiAd
        let yazi: String
        switch odakKaynagi(ad) {
        case "cihaz": yazi = "Elle ortalandı ✓"
        case "depo": yazi = "Elle ortalandı ✓ (kalıcı)"
        default: yazi = guncelOdak.odak(ad) != nil ? "Otomatik (yüz bulma)" : "Otomatik (ortadan)"
        }
        var sayac = ""
        if ortalama {
            let n = eserler.filter { e in
                etkinBaglam.secilenGorsel(e, kotuler: kotuler).flatMap { etkinBaglam.gorselAdresleri.yerelAd($0) }
                    .map { odakKaynagi($0) != nil } ?? false
            }.count
            sayac = " · ortalanan \(n) / \(eserler.count)"
        }
        return "Odak: \(yazi)\(sayac)"
    }

    @ViewBuilder
    private func odakSatiri() -> some View {
        HStack(spacing: 8) {
            Button {
                if odakModu { odakModu = false; mesaj = "" } else { odakBasla() }
            } label: {
                Text(odakModu ? "Bitti" : "Odağı işaretle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoruntuleyiciTema.murekkep)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.zemin))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
            }
            .buttonStyle(.plain)
            if odakModu && odakKaynagi(simdikiAd) == "cihaz" {
                Button {
                    ElleOdaklar.koy(simdikiAd, nil)
                    elleSurum += 1
                    mesaj = "Elle odak kaldırıldı; otomatik odağa dönüldü."
                } label: {
                    Text("Otomatiğe dön")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GoruntuleyiciTema.murekkep)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        Text(odakDurumu())
            .font(.system(size: 12.5))
            .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
    }

    private func odakBasla() {
        sifirla(animasyonlu: true)
        odakModu = true
        mesaj = "Ekranın ortasına gelecek noktaya dokun (yüz, ana figür). Çerçeve Tuval’de görünen alan."
    }

    /// "Sırayla ortala"da her yeni eserde odak kipi kendiliğinden açılır (Bitti ile kapatılan eserde yeniden açılmaz)
    private func kendiliginOdak() {
        guard ortalama, odakGorunur, !odakModu, kendiliginden != sira else { return }
        kendiliginden = sira
        odakBasla()
    }

    /// Tablonun ekrandaki dikdörtgeni (sahnenin yerel koordinatında)
    private func resimCercevesi(taban: CGSize, sahne: CGSize) -> CGRect {
        let s = olcek * CGFloat(1.0 - cekOrani * 0.45)
        let w = taban.width * s, h = taban.height * s
        return CGRect(x: sahne.width / 2 + kayma.width - w / 2, y: sahne.height / 2 + kayma.height - h / 2, width: w, height: h)
    }

    /// Bugün'ün açılışta göstereceği alan: ekranı kaplar, odak yatayda ortada, dikeyde %36 (`cerceveGoster`)
    private func tuvalCercevesi(taban: CGSize, sahne: CGSize) -> CGRect? {
        guard sahne.width > 0, sahne.height > 0, taban.width > 0, taban.height > 0 else { return nil }
        let r = resimCercevesi(taban: taban, sahne: sahne)
        let ekranOrani = sahne.width / sahne.height
        let o = taban.width / taban.height
        let fw = o > ekranOrani ? ekranOrani / o : 1
        let fh = o > ekranOrani ? 1 : o / ekranOrani
        let p = guncelOdak.odak(simdikiAd) ?? [50, 50]
        let sol = min(1 - fw, max(0, p[0] / 100 - fw * 0.5))
        let ust = min(1 - fh, max(0, p[1] / 100 - fh * 0.36))
        return CGRect(x: r.minX + sol * r.width, y: r.minY + ust * r.height, width: fw * r.width, height: fh * r.height)
    }

    private func odakIsaretle(_ konum: CGPoint, taban: CGSize, sahne: CGSize) {
        let r = resimCercevesi(taban: taban, sahne: sahne)
        guard r.contains(konum) else { return }
        let nokta = [Double((konum.x - r.minX) / r.width * 100), Double((konum.y - r.minY) / r.height * 100)]
        let ad = simdikiAd
        guard !ad.isEmpty else { mesaj = "Bu görselin yerel kopyası yok; odak kaydedilemedi."; return }
        ElleOdaklar.koy(ad, nokta)
        elleSurum += 1
        mesaj = ortalama
            ? "Kaydedildi ✓ Beğenmezsen yeniden dokun; sonraki tabloya kaydır."
            : "Kaydedildi ✓ (%\(Int(nokta[0].rounded())), %\(Int(nokta[1].rounded()))). Beğenmezsen yeniden dokun, bitince “Bitti”. Kalıcı olması için Ayarlar → Elle odaklar’dan kopyala."
    }
}

private extension Ilerleme {
    init(hamBos: Bool) {
        try! self.init(json: .nesne(.bos))
    }
}

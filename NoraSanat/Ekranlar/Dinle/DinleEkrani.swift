// Y1 · Sesli rehberli bakış: tam ekran "Dinleyerek bak" (sitede karşılığı yok).
// Z4a: Neon'un "Yön 3 · Canlı Ses · Kelime Akışı" tasarımı (dal neon/dinle-tasarim, PR #70, yalnız referans:
// tasarim/dinle/yon-3.html, kamera.js, BENIOKU.md). Kamera NoraCekirdek `DinleKamerasi` (nefesli yay, canlı süzülme,
// fren); her karede yalnız `TimelineView` içindeki tablo ve ışık yeniden çizilir, bulanıklık ya da gölge yarıçapı kareyle
// değişmez (Z3z dersi). İçerik: data/eser_ayrintilari.json, yuruyus.json, eser_notlari.json, eser_hikayeleri.json,
// ses_dizini.json (`DinlemePlani`, `DinlemeKurallari`, `SesDizini`).
import NoraCekirdek
import SwiftUI
import UIKit

/// Bir tabloya dokunmadan, uzun ve yavaş bakmak: rehber anlatır, tablo ayrıntıdan ayrıntıya kendiliğinden süzülür.
/// Başlangıç: tablo, ad, künye, tek satır tanıtım, süre (3 / 5 / 10 dk), Altyazı düğmesi, "Dinlemeye başla".
/// Anlatım: tablo tam ekran, altta kelime kelime aydınlanan altyazı, en altta parçalı ilerleme rayı; dokununca denetimler
/// açılır, 3,5 sn sonra kaybolur. Bitiş: tablonun tamamı, "Tur tamamlandı", "Bir daha" ve "Kapat".
struct DinleEkrani: View {
    let eser: Eser
    let baglam: GoruntuleyiciBaglami
    /// Görüntüleyicide gösterilen görsel (kullanıcının "kötü" işaretleri ayıklanmış); yoksa seçilen görsel
    var gorsel: Gorsel? = nil
    /// DEBUG/CI: başlangıcı atlayıp bu adımdan başlar (`hemenSesli` değilse yalnız altyazı)
    var hemenAdim: Int? = nil
    var hemenSesli = false
    /// DEBUG/CI: denetimler açık ve duraklatılmış
    var hemenDenetim = false
    /// DEBUG/CI: doğrudan bitiş
    var hemenBitis = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var sistemHareketAz
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.displayScale) private var ekranOlcegi
    @AppStorage("dinleSuresi") private var sureDegeri = DinlemeSuresi.bes.rawValue
    @AppStorage("dinleSessiz") private var sessiz = false

    @State private var kaynak: DinlemeKaynagi?
    @State private var dizin: SesDizini?
    @State private var resim: UIImage?
    @State private var hata = false
    @State private var oynatici: DinleOynatici?
    @State private var sahne: CGSize = .zero
    // Kamera: yol ve saati (değer türleri; kare başına durum saklanmaz)
    @State private var gecis = KameraGecisi.sabit(KameraDurumu(u: 0.5, v: 0.5, z: 0, capaY: 0))
    @State private var saat = KameraSaati(an: Date().timeIntervalSinceReferenceDate)
    /// Işık: şimdiki ayrıntı ve sönen önceki (kutu, söndüğü an, o andaki opaklık)
    @State private var isikKutusu: DinlemeKutusu?
    @State private var oncekiIsik: (kutu: DinlemeKutusu, an: Double, deger: Double, gecis: KameraGecisi, saat: KameraSaati)?
    @State private var denetimAcik = false
    @State private var gizleIsi: Task<Void, Never>?
    /// Bitişte kamera yerine oturdu: kare döngüsü durur
    @State private var sakin = false

    private var tema: TemaDeposu { TemaDeposu.shared }
    private var r: TemaRenkleri { tema.renkler }
    private var sure: DinlemeSuresi { DinlemeSuresi(rawValue: sureDegeri) ?? .bes }
    private var plan: DinlemePlani? { kaynak.map { DinlemePlani.kur($0, sure: sure, dizin: dizin) } }
    private var sanatciAdi: String { baglam.katalog?.harita[eser.sid]?.ad ?? "" }
    /// Hareket azaltılmışsa (sistem ya da uygulama ayarı) ya da VoiceOver açıksa kamera kaymaz, yakınlaşmaz
    private var duragan: Bool { sistemHareketAz || tema.ayar.hareketAzaltilmis || voiceOver }
    private var oynuyor: Bool { oynatici.map { $0.durum != .bitti } ?? false }
    private var bitti: Bool { oynatici?.durum == .bitti }
    private var kunyeAlt: String { [sanatciAdi, eser.tarih].filter { !$0.isEmpty }.joined(separator: " · ") }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(r.zemin)
                kameraKatmani
                    .contentShape(Rectangle())
                    .onTapGesture { sahneyeDokun() }
                perdeler
                if oynatici == nil {
                    if resim == nil {
                        Text(hata ? "Görsel yüklenemedi." : "Yükleniyor…")
                            .font(Yazi.sans(15))
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    baslangic.transition(.opacity.combined(with: .offset(y: duragan ? 0 : 18)))
                }
                if let o = oynatici {
                    if o.durum == .bitti {
                        bitis(o).transition(.opacity.combined(with: .offset(y: duragan ? 0 : 20)))
                    } else {
                        altyaziAlani(o)
                        ray(o)
                        if denetimAcik {
                            denetimler(o).transition(.opacity.combined(with: .offset(y: duragan ? 0 : 14)))
                        }
                    }
                }
                ustCubuk
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onChange(of: geo.size, initial: true) { _, yeni in
                guard yeni != sahne else { return }
                sahne = yeni
                yerlestir()
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: denetimAcik)
        .animation(.easeInOut(duration: 0.5), value: oynatici?.durum)
        .preferredColorScheme(tema.koyu ? .dark : .light)
        .statusBarHidden(oynuyor && !denetimAcik)
        .persistentSystemOverlays(oynuyor ? .hidden : .automatic)
        .onChange(of: oynatici?.kameraSayac) { _, _ in kamerayiGotur() }
        .onChange(of: oynatici?.durum) { _, yeni in durumDegisti(yeni) }
        .onChange(of: resim == nil) { eski, _ in if eski { yerlestir() } }
        .onChange(of: sureDegeri) { _, _ in
            if let o = oynatici, let p = plan { o.planiDegistir(p) }
        }
        .onChange(of: dizin) { _, _ in
            // Dizin başladıktan sonra geldiyse (yavaş ağ) sıradaki adımlar doğal sesi bulsun
            if let o = oynatici, o.durum != .bitti, let p = plan { o.planiDegistir(p) }
        }
        .task { await yukle() }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            gizleIsi?.cancel()
            oynatici?.kapat()
        }
    }

    // MARK: - Kamera

    @ViewBuilder
    private var kameraKatmani: some View {
        if let resim {
            if duragan {
                // Hareket azaltılmış: kayma ve yakınlaşma yok; iki katman 0,9 sn çapraz geçiş
                ZStack {
                    tablo(resim, gecis.hedef)
                        .overlay { isik(gecis.hedef, opaklik: isikKutusu == nil ? 0 : 1, kutu: isikKutusu, zaman: 0) }
                        .id(oynatici?.kameraSayac ?? -1)
                        .transition(.opacity)
                }
                .animation(.timingCurve(0.4, 0, 0.2, 1, duration: DinleKamerasi.caprazSure),
                           value: oynatici?.kameraSayac)
            } else {
                TimelineView(.animation(paused: !kareDongusu)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let g = saat.gecen(t)
                    let d = gecis.durum(gecen: g)
                    tablo(resim, d)
                        .overlay {
                            ZStack {
                                if let o = oncekiIsik {
                                    let p = max(0, 1 - (t - o.an) * 2.5)
                                    if p > 0 {
                                        isik(o.gecis.durum(gecen: o.saat.gecen(t)), opaklik: o.deger * p, kutu: o.kutu,
                                             zaman: t)
                                    }
                                }
                                isik(d, opaklik: isikKutusu == nil ? 0 : gecis.isik(gecen: g), kutu: isikKutusu, zaman: t)
                            }
                        }
                }
            }
        }
    }

    /// Kare döngüsü yalnız kamera hareket ederken (başlangıçta tablo durur, bitişte yerine oturunca durur)
    private var kareDongusu: Bool {
        guard let o = oynatici else { return false }
        return o.durum != .bitti || !sakin
    }

    private func olcu(_ resim: UIImage) -> (en: Double, boy: Double) {
        (Double(max(1, resim.size.width)), Double(max(1, resim.size.height)))
    }

    /// Tablo: tam görünümde sahneye sığan boy, merkezden ölçek ve kayma (tek dönüşüm)
    private func tablo(_ resim: UIImage, _ d: KameraDurumu) -> some View {
        let o = olcu(resim)
        let y = DinleKamerasi.yerlesim(d, en: o.en, boy: o.boy, sahneW: Double(sahne.width), sahneH: Double(sahne.height))
        return Image(uiImage: resim)
            .resizable()
            .interpolation(.high)
            .frame(width: max(1, y.tabanW), height: max(1, y.tabanH))
            .scaleEffect(y.olcek)
            .offset(x: y.tx, y: y.ty)
            .frame(width: sahne.width, height: sahne.height)
            .clipped()
            .accessibilityLabel(eser.gorunenAd)
    }

    /// Ayrıntı ışığı (Yön 3): yumuşak chiaroscuro iris (%28 çevre karartması) + çizgisiz, nefes alan sıcak hale.
    /// Konum canlı kameradan; yalnız degrade çizilir, bulanıklık yok.
    private func isik(_ d: KameraDurumu, opaklik: Double, kutu: DinlemeKutusu?, zaman: Double) -> some View {
        let koyu = tema.koyu
        let pirinc = Color(r.pirinc)
        let resimOlcu: (en: Double, boy: Double) = resim.map { olcu($0) } ?? (en: 1, boy: 1)
        return Canvas { ctx, boyut in
            guard let kutu, opaklik > 0.01 else { return }
            let y = DinleKamerasi.yerlesim(d, en: resimOlcu.en, boy: resimOlcu.boy,
                                           sahneW: Double(boyut.width), sahneH: Double(boyut.height))
            let k = DinleKamerasi.ekranda(kutu, y, sahneW: Double(boyut.width), sahneH: Double(boyut.height))
            let rx = max(95, k.w * 0.96), ry = max(95, k.h * 0.96)
            let guc = koyu ? 0.28 : 0.20
            let vinyet = koyu ? Color(red: 8 / 255, green: 7 / 255, blue: 6 / 255) : Color(red: 24 / 255, green: 20 / 255, blue: 16 / 255)
            // İris: birim çember elipse ölçeklenir; dışı son rengi sürdürür
            var c = ctx
            c.opacity = opaklik
            c.translateBy(x: k.ortaX, y: k.ortaY)
            c.scaleBy(x: rx, y: ry)
            let buyuk = max(boyut.width / rx, boyut.height / ry) * 3
            c.fill(Path(CGRect(x: -buyuk, y: -buyuk, width: buyuk * 2, height: buyuk * 2)),
                   with: .radialGradient(Gradient(stops: [
                       .init(color: vinyet.opacity(0), location: 0.40),
                       .init(color: vinyet.opacity(guc * 0.6), location: 0.74),
                       .init(color: vinyet.opacity(guc), location: 1.0),
                   ]), center: .zero, startRadius: 0, endRadius: 1))
            // Hale: 5,6 sn'de bir nefes (%3,5 büyür); hareket azaltılmışsa sabit
            let cap = min(240, max(112, max(k.w, k.h) * 1.18))
            let nefes = zaman == 0 ? 1 : 1 + 0.0175 * (1 - cos(2 * Double.pi * zaman / 5.6))
            let yari = cap * nefes / 2
            var h = ctx
            h.opacity = opaklik * 0.72
            let renkler: [Gradient.Stop] = koyu
                ? [.init(color: pirinc.opacity(0.16), location: 0), .init(color: pirinc.opacity(0.08), location: 0.46),
                   .init(color: pirinc.opacity(0), location: 0.74)]
                : [.init(color: Color(red: 1, green: 248 / 255, blue: 232 / 255).opacity(0.24), location: 0),
                   .init(color: pirinc.opacity(0.06), location: 0.52), .init(color: pirinc.opacity(0), location: 0.76)]
            if koyu { h.blendMode = .screen }
            h.fill(Path(ellipseIn: CGRect(x: k.ortaX - yari, y: k.ortaY - yari, width: yari * 2, height: yari * 2)),
                   with: .radialGradient(Gradient(stops: renkler), center: CGPoint(x: k.ortaX, y: k.ortaY),
                                         startRadius: 0, endRadius: yari))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Başlangıçta ve sahne değişince: kamera yerinde (tablonun tamamı ya da sürmekte olan adımın hedefi)
    private func yerlestir() {
        guard resim != nil, sahne.width > 0 else { return }
        let t = Date().timeIntervalSinceReferenceDate
        if let o = oynatici, o.durum != .bitti, let a = o.simdikiAdim {
            gecis = .sabit(hedef(o.kamera, a.tur))
        } else {
            gecis = .sabit(hedef(nil, .kapanis))
        }
        saat = KameraSaati(an: t, calisiyor: oynatici?.durum != .duraklatildi)
    }

    private func hedef(_ kutu: DinlemeKutusu?, _ tur: DinlemeAdimi.Tur) -> KameraDurumu {
        guard let resim else { return gecis.hedef }
        let o = olcu(resim)
        return DinleKamerasi.hedef(kutu: kutu, tur: tur, en: o.en, boy: o.boy,
                                   kaynakEn: Double(resim.size.width * resim.scale), dpr: Double(ekranOlcegi),
                                   sahneW: Double(sahne.width), sahneH: Double(sahne.height), ust: 100)
    }

    /// Yeni adım: o anki canlı durumdan yeni hedefe (adım yarı yolda atlansa da sıçrama yok)
    private func kamerayiGotur() {
        guard let o = oynatici, resim != nil, sahne.width > 0 else { return }
        let t = Date().timeIntervalSinceReferenceDate
        let g = saat.gecen(t)
        let canli = gecis.durum(gecen: g)
        if let k = isikKutusu {
            oncekiIsik = (k, t, gecis.isik(gecen: g), gecis, saat)
        } else {
            oncekiIsik = nil
        }
        if o.durum == .bitti {
            isikKutusu = nil
            gecis = .yeni(canli: canli, hedef: hedef(nil, .kapanis), tur: .kapanis, sira: o.sira, sure: 2.8,
                          suzulme: false)
        } else {
            let a = o.simdikiAdim
            let tur = a?.tur ?? .kapanis
            isikKutusu = tur == .nokta ? o.kamera : nil
            gecis = .yeni(canli: canli, hedef: hedef(o.kamera, tur), tur: tur, sira: o.sira)
        }
        saat.sifirla(t)
    }

    private func durumDegisti(_ d: DinleOynatici.Durum?) {
        let t = Date().timeIntervalSinceReferenceDate
        sakin = false
        switch d {
        case .duraklatildi?:
            saat.duraklat(t)
            gizleIsi?.cancel()
            denetimAcik = true
        case .oynuyor?:
            saat.surdur(t)
            if denetimAcik { gizlemeyiKur() }
        case .bitti?:
            denetimAcik = false
            gizleIsi?.cancel()
            Task {
                try? await Task.sleep(for: .seconds(3.2))
                if oynatici?.durum == .bitti { sakin = true }
            }
        case nil:
            break
        }
    }

    // MARK: - Perdeler

    /// Altyazının arkasındaki geçiş: ekranın en çok alt %22'si, en koyu yerinde %55 (Gündüz'de tablo beyaza boğulmasın);
    /// okunurluğu yazının gölgesi sağlar. Denetimler açıkken üstte de ince bir geçiş.
    private var perdeler: some View {
        let perde = Color(r.zemin)
        return ZStack {
            VStack(spacing: 0) {
                LinearGradient(stops: [.init(color: perde.opacity(0.55), location: 0),
                                       .init(color: perde.opacity(0), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 126)
                    .opacity(denetimAcik || oynatici == nil || bitti ? 1 : 0)
                Spacer(minLength: 0)
                LinearGradient(stops: [.init(color: perde.opacity(0), location: 0),
                                       .init(color: perde.opacity(0.22), location: 0.45),
                                       .init(color: perde.opacity(0.55), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: sahne.height * 0.22)
                    .opacity(oynuyor ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Üst çubuk

    private var ustCubuk: some View {
        let gizli = oynuyor && !denetimAcik
        return VStack {
            HStack(spacing: 10) {
                camDaire("xmark", "Kapat") { dismiss() }
                Spacer(minLength: 0)
                if let o = oynatici, o.durum != .bitti {
                    VStack(spacing: 2) {
                        Text(evreYazisi(o))
                            .font(Yazi.sans(12, agirlik: 600, stil: .caption1))
                            .foregroundStyle(Color(r.pirinc))
                        Text(eser.gorunenAd)
                            .font(Yazi.serif(15.5, agirlik: 500, stil: .subheadline))
                            .foregroundStyle(Color(r.murekkep))
                    }
                    .lineLimit(1)
                    .opacity(denetimAcik ? 1 : 0)
                    Spacer(minLength: 0)
                    camDaire(o.sesli ? "speaker.wave.2" : "captions.bubble", o.sesli ? "Sesi kapat" : "Sesi aç",
                             vurgulu: o.sesli) {
                        etkilesim()
                        sessiz = o.sesli
                        o.sesiDegistir(!o.sesli)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .safeAreaPadding(.top)
            Spacer()
        }
        .opacity(gizli ? 0 : 1)
        .offset(y: gizli && !duragan ? -6 : 0)
        .allowsHitTesting(!gizli)
    }

    private func evreYazisi(_ o: DinleOynatici) -> String {
        guard let a = o.simdikiAdim else { return "" }
        return a.tur == .nokta ? "Ayrıntı · \(a.baslik)" : Self.evreAdi(a.tur)
    }

    static func evreAdi(_ t: DinlemeAdimi.Tur) -> String {
        switch t {
        case .acilis: return "Açılış"
        case .anlati: return "Anlatı"
        case .nokta: return "Ayrıntılar"
        case .sessiz: return "Sessiz"
        case .kapanis: return "Kapanış"
        }
    }

    private func camDaire(_ simge: String, _ ad: String, vurgulu: Bool = false, _ yap: @escaping () -> Void) -> some View {
        Button(action: yap) {
            Image(systemName: simge)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(vurgulu ? r.pirinc : r.murekkep))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
                .background(Circle().fill(Color(r.yuzey).opacity(tema.koyu ? 0.64 : 0.80)))
                .overlay(Circle().strokeBorder(vurgulu ? Color(r.pirinc).opacity(0.55) : Color(r.kenar), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ad)
    }

    // MARK: - Başlangıç

    private var baslangic: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("Sesli rehber · Dinleyerek bak")
                    .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                    .foregroundStyle(Color(r.pirinc))
                Text(eser.gorunenAd)
                    .font(Yazi.serif(38, agirlik: 500, stil: .largeTitle))
                    .foregroundStyle(Color(r.murekkep))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 2)
                    .accessibilityAddTraits(.isHeader)
                if !kunyeAlt.isEmpty {
                    Text(kunyeAlt)
                        .font(Yazi.sans(14, stil: .subheadline))
                        .foregroundStyle(Color(r.murekkep2))
                        .padding(.top, 4)
                }
            }
            if let plan {
                Text(Self.tanitim(plan))
                    .font(Yazi.okuma(16, italik: true))
                    .foregroundStyle(Color(r.murekkep2))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 316)
            }
            HStack(spacing: 8) {
                sureSecici(kucuk: false)
                Button {
                    sessiz.toggle()
                } label: {
                    Label(sessiz ? "Altyazı" : "Sesli", systemImage: sessiz ? "captions.bubble" : "speaker.wave.2")
                        .font(Yazi.sans(13.5, agirlik: 500, stil: .footnote))
                        .foregroundStyle(Color(sessiz ? r.murekkep : r.pirinc))
                        .padding(.horizontal, 14)
                        .frame(minHeight: 50)
                        .background(camKapsul(vurgulu: !sessiz))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sessiz ? "Yalnız altyazı" : "Sesli")
                .accessibilityHint("Sesli ile yalnız altyazı arasında geçer")
            }
            .padding(.top, 4)
            let hazir = kaynak != nil && resim != nil
            Button {
                baslat()
            } label: {
                Label("Dinlemeye başla", systemImage: "headphones")
                    .font(Yazi.sans(16, agirlik: 600, stil: .body))
                    .foregroundStyle(Color(r.zemin))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Capsule().fill(Color(r.murekkep)))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!hazir)
            .opacity(hazir ? 1 : 0.5)
            .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    /// Tek satır tanıtım
    static func tanitim(_ p: DinlemePlani) -> String {
        let n = p.adimlar.filter { $0.tur == .nokta }.count
        let dk = max(1, Int((p.toplam / 60).rounded()))
        let hikaye = p.adimlar.contains { $0.tur == .anlati }
        if n == 0 { return "Tablonun üzerinde yaklaşık \(dk) dakikalık yavaş bir gezinti." }
        return "\(n) ayrıntı\(hikaye ? " ve hikâyesiyle" : "da") yaklaşık \(dk) dakikalık sakin bir bakış."
    }

    private func camKapsul(vurgulu: Bool = false) -> some View {
        Capsule()
            .fill(Color(r.yuzey).opacity(tema.koyu ? 0.64 : 0.80))
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(vurgulu ? Color(r.pirinc).opacity(0.55) : Color(r.kenar), lineWidth: 1))
    }

    /// 3 / 5 / 10 dk: başlangıçta "3 dk", denetimlerde yalnız sayı
    private func sureSecici(kucuk: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(DinlemeSuresi.allCases) { s in
                let secili = s == sure
                Button {
                    etkilesim()
                    sureDegeri = s.rawValue
                } label: {
                    Text(kucuk ? "\(s.rawValue)" : s.yazi)
                        .font(Yazi.sans(kucuk ? 12 : 13.5, agirlik: 600, stil: .footnote))
                        .foregroundStyle(Color(secili ? r.zemin : r.murekkep2))
                        .padding(.horizontal, kucuk ? 7 : 12)
                        .frame(minWidth: kucuk ? 36 : 56, minHeight: 44)
                        .background(Capsule().fill(Color(secili ? r.murekkep : RGBA(0, 0, 0, 0))))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(s.rawValue) dakika")
                .accessibilityAddTraits(secili ? .isSelected : [])
            }
        }
        .padding(kucuk ? 2 : 3)
        .background(camKapsul())
    }

    // MARK: - Anlatım: kelime akışı

    private func etiket(_ o: DinleOynatici) -> String {
        guard let a = o.simdikiAdim else { return "" }
        switch a.tur {
        case .nokta: return a.baslik
        case .acilis: return [eser.gorunenAd, kunyeAlt].filter { !$0.isEmpty }.joined(separator: " · ")
        case .anlati: return "Anlatı"
        case .sessiz: return "Sessiz bakış"
        case .kapanis: return "Kapanış"
        }
    }

    private func altyaziAlani(_ o: DinleOynatici) -> some View {
        let perde = Color(r.zemin)
        let gorunur = !o.altyazi.isEmpty
        return VStack(alignment: .leading, spacing: 7) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                SesDalgasi(renk: Color(r.pirinc), canli: o.durum == .oynuyor && !duragan)
                Text(etiket(o))
                    .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                    .foregroundStyle(Color(r.pirinc))
                    .lineLimit(1)
            }
            .shadow(color: perde.opacity(0.7), radius: 4)
            .opacity(gorunur ? 1 : 0)
            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                Text(kelimeler(o))
                    .font(Yazi.okuma(20))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Okunurluk: tablo görünür kalsın diye peçe yerine yazının kendi yumuşak gölgesi (sabit yarıçap)
            .shadow(color: perde.opacity(0.85), radius: 6)
            .shadow(color: perde.opacity(0.6), radius: 1.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, denetimAcik ? 184 : 42)
        .animation(.easeInOut(duration: 0.4), value: o.altyazi)
        .allowsHitTesting(false)
        // VoiceOver: kelime kelime değil, adımın bütün metni okunur
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(gorunur ? "\(etiket(o)). \(o.altyazi)" : "")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// Söylenmiş kelimeler koyu, söylenen tam parlak ve pirinç alt çizgili, sıradakiler soluk. Yalnız içinde bulunulan
    /// cümle gösterilir (en çok iki-üç satır).
    private func kelimeler(_ o: DinleOynatici) -> AttributedString {
        guard let a = o.akis, !a.kelimeler.isEmpty else { return AttributedString(o.altyazi) }
        let k = o.kelimeSirasi()
        let c = a.cumle(kelime: min(k, a.kelimeler.count - 1))
        let m = Color(r.murekkep)
        let aktif = tema.koyu ? Color(red: 1, green: 250 / 255, blue: 240 / 255) : m
        var s = AttributedString()
        for j in c {
            var w = AttributedString(a.kelimeler[j].yazi)
            if j < k {
                w.foregroundColor = m.opacity(0.84)
            } else if j == k {
                w.foregroundColor = aktif
                w.underlineStyle = Text.LineStyle(pattern: .solid, color: Color(r.pirinc).opacity(0.65))
            } else {
                w.foregroundColor = m.opacity(tema.koyu ? 0.36 : 0.40)
            }
            s += w
            if j < c.upperBound - 1 { s += AttributedString(" ") }
        }
        return s
    }

    // MARK: - Ray ve denetimler

    /// En altta ince parçalı ilerleme rayı: geçenler yeşil, süren pirinç, kalanlar soluk
    private func ray(_ o: DinleOynatici) -> some View {
        let n = o.adimSayisi
        let agirlik = o.plan.adimlar.map { $0.tur == .nokta ? 1.4 : 1.0 }
        let toplam = agirlik.reduce(0, +)
        let genislik = max(0, Double(sahne.width) - 48 - 5 * Double(max(0, n - 1)))
        return VStack {
            Spacer()
            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                HStack(spacing: 5) {
                    ForEach(0..<n, id: \.self) { i in
                        let w = genislik * agirlik[i] / max(1, toplam)
                        let dolu = i < o.sira ? 1 : (i == o.sira ? o.ilerleme() : 0)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(r.murekkep).opacity(0.16))
                            Capsule().fill(Color(i < o.sira ? r.dogru : r.pirinc))
                                .frame(width: w * dolu)
                        }
                        .frame(width: w, height: 2.5)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel("Adım \(o.sira + 1) / \(n)")
    }

    private func denetimler(_ o: DinleOynatici) -> some View {
        VStack(spacing: 12) {
            Spacer()
            HStack(spacing: 0) {
                sureSecici(kucuk: true)
                Spacer(minLength: 6)
                HStack(spacing: 12) {
                    tasi("backward.end.fill", "Önceki adım") { o.onceki() }
                    Button {
                        o.degistir()
                    } label: {
                        Image(systemName: o.durum == .oynuyor ? "pause.fill" : "play.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Color(r.zemin))
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Color(r.murekkep)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(o.durum == .oynuyor ? "Duraklat" : "Sürdür")
                    tasi("forward.end.fill", "Sonraki adım") { o.sonraki() }
                }
                Spacer(minLength: 6)
                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                    Text(Self.sureYazisi(o.kalan()))
                        .font(Yazi.sans(12, agirlik: 500, stil: .caption1))
                        .monospacedDigit()
                        .foregroundStyle(Color(r.murekkep2))
                }
                .frame(minWidth: 44, alignment: .trailing)
                .accessibilityLabel("Kalan süre")
            }
            .padding(.horizontal, 4)
            evreler(o)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private func tasi(_ simge: String, _ ad: String, _ yap: @escaping () -> Void) -> some View {
        Button {
            etkilesim()
            yap()
        } label: {
            Image(systemName: simge)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(r.murekkep))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
                .background(Circle().fill(Color(r.yuzey).opacity(tema.koyu ? 0.64 : 0.80)))
                .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ad)
    }

    /// Adım şeridi: Açılış · Anlatı · Ayrıntılar · Sessiz · Kapanış (planda olanlar); dokununca o evrenin ilk adımı
    private func evreler(_ o: DinleOynatici) -> some View {
        let turler: [DinlemeAdimi.Tur] = [.acilis, .anlati, .nokta, .sessiz, .kapanis]
        let adimlar = o.plan.adimlar
        return HStack(spacing: 4) {
            ForEach(turler.filter { t in adimlar.contains { $0.tur == t } }, id: \.self) { t in
                let ilk = adimlar.firstIndex { $0.tur == t } ?? 0
                let son = adimlar.lastIndex { $0.tur == t } ?? 0
                let aktif = o.sira >= ilk && o.sira <= son
                Button {
                    etkilesim()
                    o.adimaGit(ilk)
                } label: {
                    Text(Self.evreAdi(t))
                        .font(Yazi.sans(11.5, agirlik: aktif ? 600 : 500, stil: .caption1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(Color(aktif ? r.pirinc : (o.sira > son ? r.murekkep2 : r.murekkep3)))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(Color(r.pirinc).opacity(aktif ? 0.14 : 0)))
                        .overlay(Capsule().strokeBorder(Color(r.pirinc).opacity(aktif ? 0.45 : 0), lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(aktif ? .isSelected : [])
            }
        }
        .shadow(color: Color(r.zemin).opacity(0.6), radius: 3)
    }

    static func sureYazisi(_ sn: Double) -> String {
        let s = max(0, Int(sn.rounded()))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func sahneyeDokun() {
        guard let o = oynatici, o.durum != .bitti else { return }
        denetimAcik.toggle()
        if denetimAcik { gizlemeyiKur() } else { gizleIsi?.cancel() }
    }

    /// Denetimlere her dokunuşta gizleme süresi baştan
    private func etkilesim() {
        if denetimAcik { gizlemeyiKur() }
    }

    /// Oynarken 3,5 sn dokunulmazsa denetimler kaybolur (VoiceOver açıkken kalır)
    private func gizlemeyiKur() {
        gizleIsi?.cancel()
        guard !voiceOver, !hemenDenetim else { return }
        gizleIsi = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled, oynatici?.durum == .oynuyor else { return }
            denetimAcik = false
        }
    }

    // MARK: - Bitiş

    private func bitis(_ o: DinleOynatici) -> some View {
        let n = o.plan.adimlar.filter { $0.tur == .nokta }.count
        let tur = o.sesli ? "sesli bakış" : "altyazılı bakış"
        let ozet = n > 0 ? "\(n) ayrıntı · \(sure.rawValue) dakikalık \(tur)" : "\(sure.rawValue) dakikalık \(tur)"
        return VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Tur tamamlandı")
                    .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                    .foregroundStyle(Color(r.pirinc))
                Text(eser.gorunenAd)
                    .font(Yazi.serif(30, agirlik: 500, italik: true, stil: .title1))
                    .foregroundStyle(Color(r.murekkep))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(ozet)
                .font(Yazi.sans(14, stil: .subheadline))
                .foregroundStyle(Color(r.murekkep2))
            HStack(spacing: 10) {
                Button {
                    o.surdur()
                } label: {
                    Text("Bir daha")
                        .font(Yazi.sans(15, agirlik: 600, stil: .body))
                        .foregroundStyle(Color(r.murekkep))
                        .padding(.horizontal, 20)
                        .frame(minHeight: 52)
                        .background(camKapsul())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                Button {
                    dismiss()
                } label: {
                    Text("Kapat")
                        .font(Yazi.sans(16, agirlik: 600, stil: .body))
                        .foregroundStyle(Color(r.zemin))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(Color(r.murekkep)))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Yükleme ve başlatma

    private func yukle() async {
        let g = gorsel ?? baglam.secilenGorsel(eser)
        let adresler = g.map(baglam.adresler) ?? GoruntuleyiciGorselAdresleri()
        async let yuruyusVerisi = SiteVerisi().veri("yuruyus.json")
        async let sesDizini = DinleSesKaynagi.shared.dizin()
        var ilk: UIImage?
        for case let url? in [adresler.birincil, adresler.yedek] {
            if let r = await GorselCozucu.shared.resim(url, piksel: 1280) {
                ilk = r
                break
            }
        }
        resim = ilk
        hata = ilk == nil
        let yuruyus = await yuruyusVerisi.flatMap { try? JSONDeger.coz($0) }
        let yerel = eser.gorseller.compactMap { baglam.gorselAdresleri.yerelAd($0) }
        kaynak = DinlemeKurallari.kaynak(
            eser: eser, sanatci: sanatciAdi, notMetni: baglam.eserNotu(eser),
            ayrinti: baglam.ayrinti(eser), hikaye: baglam.hikaye(eser),
            yuruyus: DinlemeKurallari.yuruyusNoktalari(yuruyus, eser: eser, yerelAdlar: yerel))
        dizin = await sesDizini
        if let n = hemenAdim, resim != nil {
            baslat(adim: n, sesli: hemenSesli)
            if hemenBitis { oynatici?.bitir() }
            if hemenDenetim {
                try? await Task.sleep(for: .seconds(8))
                oynatici?.duraklat()
            }
        }
        // Yakınlaşmada keskin kalsın: en büyük kopya arkada iner
        if let devasa = adresler.devasa, !Task.isCancelled,
           let keskin = await GorselCozucu.shared.resim(devasa, piksel: 4096), !Task.isCancelled {
            resim = keskin
        }
    }

    private func baslat(adim: Int = 0, sesli: Bool? = nil) {
        guard let plan, oynatici == nil else { return }
        let o = DinleOynatici(plan: plan, sesli: sesli ?? !sessiz, baslik: eser.gorunenAd, sanatci: sanatciAdi,
                              kunye: kaynak?.kunye ?? "", sesKoku: baglam.gorselAdresleri.adres, kapak: resim)
        withAnimation(.easeInOut(duration: 0.45)) { oynatici = o }
        o.baslat(adim: min(max(0, adim), plan.adimlar.count - 1))
    }
}

/// Konuşurken hafifçe kıpırdayan üç çubuk (Yön 3 `.ses-dalgasi`); duraklatınca ya da hareket azaltılmışsa durur
private struct SesDalgasi: View {
    let renk: Color
    let canli: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !canli)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5) {
                ForEach(0..<3, id: \.self) { i in
                    let faz = sin(2 * Double.pi * (t - Double(i) * 0.2) / 1.3)
                    Capsule()
                        .fill(renk)
                        .frame(width: 2, height: [5.0, 10.0, 7.0][i])
                        .scaleEffect(y: canli ? 0.85 + 0.3 * faz : 1)
                        .opacity(canli ? 0.825 + 0.175 * faz : 0.5)
                }
            }
            .frame(height: 12)
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
/// DEBUG `-ekran dinle`: ayrıntı noktası olan ilk eserde "Dinleyerek bak" (CI görüntüsü).
/// `-dinleAdim n`: başlangıç atlanır, o adımdan başlar (yalnız altyazı; `-dinleSesli` ile sesli).
/// `-dinleDenetim`: 8 sn sonra duraklatır, denetimler açık kalır. `-dinleBitis`: doğrudan bitiş.
/// `-dinleTema gunduz`: Gündüz teması. `-dinleSesYok`: ses dizini yokmuş gibi (R2'ye ulaşılamayınca AVSpeech'e dönüş).
struct DinleOnizleme: View {
    @State private var hazir: (GoruntuleyiciBaglami, Eser)?

    var body: some View {
        Group {
            if let h = hazir {
                let a = CommandLine.arguments
                DinleEkrani(eser: h.1, baglam: h.0, hemenAdim: NoraSanatApp.arguman("-dinleAdim").flatMap(Int.init),
                            hemenSesli: a.contains("-dinleSesli"), hemenDenetim: a.contains("-dinleDenetim"),
                            hemenBitis: a.contains("-dinleBitis"))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(TemaDeposu.shared.renkler.zemin).ignoresSafeArea())
            }
        }
        .environment(TemaDeposu.shared)
        .task {
            if NoraSanatApp.arguman("-dinleTema") == "gunduz" {
                TemaDeposu.shared.uygula(TemaRenkleri.gunduz, ayar: TemaAyari(tema: .gunduz),
                                         zemin: TemaRenkleri.gunduz.zemin)
            }
            try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory
                .appendingPathComponent("dinle-ses"))
            let b = await GoruntuleyiciBaglami.yukle()
            guard let k = b.katalog else { return }
            for s in k.sanatcilar {
                if let e = k.eserler(s.id).first(where: { b.ayrinti($0) != nil }) {
                    hazir = (b, e)
                    return
                }
            }
        }
    }
}
#endif

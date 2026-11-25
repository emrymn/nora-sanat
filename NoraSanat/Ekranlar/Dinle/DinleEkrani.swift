// Y1 · Sesli rehberli bakış: tam ekran "Dinleyerek bak" (sitede karşılığı yok).
// İçerik: data/eser_ayrintilari.json, data/yuruyus.json, data/eser_notlari.json, data/eser_hikayeleri.json
// (NoraCekirdek `DinlemePlani`, `DinlemeKurallari`). Kamera `AyrintiKurallari.noktaOdagi` ile ayrıntıya yaklaşır.
import NoraCekirdek
import SwiftUI
import UIKit

/// Bir tabloya dokunmadan, uzun ve yavaş bakmak: rehber anlatır, tablo ayrıntıdan ayrıntıya kendiliğinden süzülür.
/// Önce süre (3 / 5 / 10 dk) ve sesli ya da yalnız altyazı seçilir. Mod sürerken ekran sönmez; ses arka planda ve kilit
/// ekranında sürer. Hareket azaltılmışsa yakınlaşma yerine yumuşak bir geçiş.
struct DinleEkrani: View {
    let eser: Eser
    let baglam: GoruntuleyiciBaglami
    /// Görüntüleyicide gösterilen görsel (kullanıcının "kötü" işaretleri ayıklanmış); yoksa seçilen görsel
    var gorsel: Gorsel? = nil
    /// DEBUG/CI: kurulum ekranını atlayıp sessiz seçenekte bu adımdan başlar
    var hemenAdim: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @AppStorage("dinleSuresi") private var sureDegeri = DinlemeSuresi.bes.rawValue
    @AppStorage("dinleSessiz") private var sessiz = false

    @State private var kaynak: DinlemeKaynagi?
    @State private var resim: UIImage?
    @State private var hata = false
    @State private var oynatici: DinleOynatici?
    @State private var olcek: CGFloat = 1
    @State private var kayma: CGSize = .zero
    @State private var gorunurluk = 1.0
    @State private var arayuzGizli = false
    @State private var gecisIsi: Task<Void, Never>?

    private var sure: DinlemeSuresi { DinlemeSuresi(rawValue: sureDegeri) ?? .bes }
    private var plan: DinlemePlani? { kaynak.map { DinlemePlani.kur($0, sure: sure) } }
    private var sanatciAdi: String { baglam.katalog?.harita[eser.sid]?.ad ?? "" }

    var body: some View {
        GeometryReader { geo in
            let sahne = geo.size
            let taban = sigdir(sahne: sahne)
            ZStack {
                Color.black.ignoresSafeArea()
                if let resim {
                    Image(uiImage: resim).resizable().scaledToFit()
                        .frame(width: taban.width, height: taban.height)
                        .scaleEffect(olcek)
                        .offset(kayma)
                        .opacity(gorunurluk)
                        .frame(width: sahne.width, height: sahne.height)
                        .clipped()
                        .accessibilityLabel(eser.gorunenAd)
                } else {
                    Text(hata ? "Görsel yüklenemedi." : "Yükleniyor…")
                        .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard oynatici != nil else { return }
                withAnimation(.easeInOut(duration: 0.25)) { arayuzGizli.toggle() }
            }
            .overlay(alignment: .top) { ustCubuk.opacity(arayuzGizli ? 0 : 1) }
            .overlay(alignment: .bottom) { altKatman.opacity(arayuzGizli ? 0 : 1) }
            .onChange(of: oynatici?.kameraSayac) { _, _ in
                kamerayiGotur(taban: taban, sahne: sahne)
            }
            .onChange(of: arayuzGizli) { _, _ in
                kamerayiGotur(taban: taban, sahne: sahne, sure: 0.6)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden(oynatici != nil && arayuzGizli)
        .persistentSystemOverlays(oynatici != nil ? .hidden : .automatic)
        .task { await yukle() }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            gecisIsi?.cancel()
            oynatici?.kapat()
        }
    }

    // MARK: - Üst ve alt

    private var ustCubuk: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
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
        .padding(.horizontal, 12)
        .safeAreaPadding(.top)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var altKatman: some View {
        Group {
            if let o = oynatici {
                if o.durum == .bitti {
                    bitis(o)
                } else {
                    oynatma(o)
                }
            } else {
                kurulum
            }
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.bottom)
        .padding(.bottom, 12)
    }

    private func kart<Icerik: View>(@ViewBuilder _ icerik: () -> Icerik) -> some View {
        VStack(alignment: .leading, spacing: 10) { icerik() }
            .padding(18)
            .frame(maxWidth: 560, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 22).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 22).fill(GoruntuleyiciTema.yuzey.opacity(0.55))
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
            .environment(\.colorScheme, .dark)
            .foregroundStyle(GoruntuleyiciTema.murekkep)
    }

    private var kurulum: some View {
        kart {
            Text("Dinleyerek bak")
                .font(Yazi.sans(13, agirlik: 600))
                .foregroundStyle(GoruntuleyiciTema.vurgu)
                .textCase(.uppercase)
            Text(eser.gorunenAd)
                .font(Yazi.serif(24, italik: true))
            if !sanatciAdi.isEmpty {
                Text([sanatciAdi, eser.tarih].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(Yazi.sans(14))
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
            }
            Picker("Süre", selection: $sureDegeri) {
                ForEach(DinlemeSuresi.allCases) { Text($0.yazi).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.top, 4)
            Picker("Ses", selection: $sessiz) {
                Text("Sesli").tag(false)
                Text("Yalnız altyazı").tag(true)
            }
            .pickerStyle(.segmented)
            if let plan {
                Text(ozet(plan))
                    .font(Yazi.sans(13))
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
            }
            Button {
                baslat()
            } label: {
                Label("Başla", systemImage: sessiz ? "captions.bubble" : "headphones")
                    .font(Yazi.sans(16, agirlik: 600))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(GoruntuleyiciTema.vurguYazi)
                    .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.vurgu))
            }
            .buttonStyle(.plain)
            .disabled(kaynak == nil || resim == nil)
            .opacity(kaynak == nil || resim == nil ? 0.5 : 1)
            .padding(.top, 4)
        }
    }

    private func ozet(_ p: DinlemePlani) -> String {
        let n = p.adimlar.filter { $0.tur == .nokta }.count
        let dk = max(1, Int((p.toplam / 60).rounded()))
        let parca = n > 0 ? "\(n) ayrıntı" : "Tablonun üzerinde yavaş bir gezinti"
        return "\(parca) · yaklaşık \(dk) dk"
    }

    private func oynatma(_ o: DinleOynatici) -> some View {
        VStack(spacing: 10) {
            if !o.altyazi.isEmpty {
                kart {
                    if !o.altyaziBaslik.isEmpty {
                        Text(o.altyaziBaslik)
                            .font(Yazi.serif(21))
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(o.altyazi)
                        .font(Yazi.okuma(17))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
                .id(o.sira)
            }
            HStack(spacing: 14) {
                denetim("backward.fill", "Önceki") { o.onceki() }
                denetim(o.durum == .oynuyor ? "pause.fill" : "play.fill",
                        o.durum == .oynuyor ? "Duraklat" : "Sürdür", buyuk: true) { o.degistir() }
                denetim("forward.fill", "Sonraki") { o.sonraki() }
            }
            ilerleme(o)
        }
        .animation(.easeInOut(duration: 0.5), value: o.altyazi)
    }

    private func ilerleme(_ o: DinleOynatici) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<o.adimSayisi, id: \.self) { i in
                Capsule()
                    .fill(i <= o.sira ? GoruntuleyiciTema.vurgu : GoruntuleyiciTema.kenar)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: 320)
        .accessibilityElement()
        .accessibilityLabel("Adım \(o.sira + 1) / \(o.adimSayisi)")
    }

    private func denetim(_ simge: String, _ ad: String, buyuk: Bool = false, _ yap: @escaping () -> Void) -> some View {
        Button(action: yap) {
            Image(systemName: simge)
                .font(.system(size: buyuk ? 22 : 16, weight: .semibold))
                .foregroundStyle(GoruntuleyiciTema.murekkep)
                .frame(width: buyuk ? 60 : 48, height: buyuk ? 60 : 48)
                .background(Circle().fill(GoruntuleyiciTema.yuvarlakDugmeZemini))
                .overlay(Circle().strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ad)
    }

    private func bitis(_ o: DinleOynatici) -> some View {
        let noktalar = o.plan.adimlar.filter { $0.tur == .nokta }
        return kart {
            Text(DinlemeKurallari.bitisSorusu)
                .font(Yazi.serif(24, italik: true))
            if !noktalar.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(noktalar.enumerated()), id: \.offset) { _, a in
                            Button(a.baslik) { o.bak(a.kutu) }
                                .font(Yazi.sans(14, agirlik: 600))
                                .padding(.horizontal, 14)
                                .frame(minHeight: 40)
                                .background(Capsule().fill(GoruntuleyiciTema.zemin.opacity(0.7)))
                                .overlay(Capsule().strokeBorder(GoruntuleyiciTema.kenar, lineWidth: 1))
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                Button {
                    o.surdur()
                } label: {
                    Label("Yeniden dinle", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 14).strokeBorder(GoruntuleyiciTema.kenar))
                }
                Button {
                    dismiss()
                } label: {
                    Text("Bitir")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(GoruntuleyiciTema.vurguYazi)
                        .background(RoundedRectangle(cornerRadius: 14).fill(GoruntuleyiciTema.vurgu))
                }
            }
            .buttonStyle(.plain)
            .font(Yazi.sans(15, agirlik: 600))
            .padding(.top, 4)
        }
    }

    // MARK: - Kamera

    private func sigdir(sahne: CGSize) -> CGSize {
        guard let r = resim, r.size.width > 0, r.size.height > 0, sahne.width > 0, sahne.height > 0 else {
            return sahne
        }
        let oran = r.size.width / r.size.height
        var w = sahne.width
        var h = w / oran
        if h > sahne.height {
            h = sahne.height
            w = h * oran
        }
        return CGSize(width: w, height: h)
    }

    /// Ayrıntı altyazının üstündeki alana gelir (altyazı açıkken ekranın alt üçte biri kartındır).
    private func hedef(_ kutu: DinlemeKutusu?, taban: CGSize, sahne: CGSize) -> (CGFloat, CGSize) {
        guard let kutu else { return (1, .zero) }
        let alt = arayuzGizli ? 0 : min(260, sahne.height * 0.34)
        let gorunen = CGSize(width: sahne.width, height: max(1, sahne.height - alt))
        guard let o = AyrintiKurallari.noktaOdagi(
            kutu.nokta(),
            taban: (Double(taban.width), Double(taban.height)),
            sahne: (Double(gorunen.width), Double(gorunen.height)),
            pay: 0.72, enAz: 1.1, enCok: 4
        ) else { return (1, .zero) }
        return (CGFloat(o.olcek), CGSize(width: o.tx, height: o.ty - alt / 2))
    }

    private func kamerayiGotur(taban: CGSize, sahne: CGSize, sure: Double? = nil) {
        guard let o = oynatici else { return }
        let (s, k) = hedef(o.kamera, taban: taban, sahne: sahne)
        gecisIsi?.cancel()
        if hareketAz {
            // Yakınlaşma yerine: sön, yerini değiştir, yavaşça belir
            gecisIsi = Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.8)) { gorunurluk = 0 }
                try? await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }
                olcek = s
                kayma = k
                withAnimation(.easeInOut(duration: 1.2)) { gorunurluk = 1 }
            }
        } else {
            gorunurluk = 1
            withAnimation(.easeInOut(duration: max(0.6, sure ?? o.kameraSuresi))) {
                olcek = s
                kayma = k
            }
        }
    }

    // MARK: - Yükleme ve başlatma

    private func yukle() async {
        let g = gorsel ?? baglam.secilenGorsel(eser)
        let adresler = g.map(baglam.adresler) ?? GoruntuleyiciGorselAdresleri()
        async let yuruyusVerisi = SiteVerisi().veri("yuruyus.json")
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
        if let n = hemenAdim, resim != nil {
            baslat(adim: n, sesli: false)
        }
        // Yakınlaşmada keskin kalsın: en büyük kopya arkada iner
        if let devasa = adresler.devasa, !Task.isCancelled,
           let keskin = await GorselCozucu.shared.resim(devasa, piksel: 4096), !Task.isCancelled {
            resim = keskin
        }
    }

    private func baslat(adim: Int = 0, sesli: Bool? = nil) {
        guard let plan, oynatici == nil else { return }
        let o = DinleOynatici(plan: plan, sesli: sesli ?? !sessiz, baslik: eser.gorunenAd, sanatci: sanatciAdi, kapak: resim)
        oynatici = o
        o.baslat(adim: min(max(0, adim), plan.adimlar.count - 1))
    }
}

#if DEBUG
/// DEBUG `-ekran dinle [-dinleAdim n]`: ayrıntı noktası olan ilk eserde "Dinleyerek bak" (CI görüntüsü).
/// `-dinleAdim` verilirse kurulum atlanır, sessiz seçenekte o adımdan başlar.
struct DinleOnizleme: View {
    @State private var hazir: (GoruntuleyiciBaglami, Eser)?

    var body: some View {
        Group {
            if let h = hazir {
                DinleEkrani(eser: h.1, baglam: h.0, hemenAdim: NoraSanatApp.arguman("-dinleAdim").flatMap(Int.init))
            } else {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
        .task {
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

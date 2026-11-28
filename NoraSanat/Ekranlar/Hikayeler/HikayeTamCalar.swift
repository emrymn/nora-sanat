// Z4e · Hikâyeler tam ekran çaları. Tasarım: Neon 4. tur (dal neon/hikayeler-tasarim-4, PR #83; birleştirilmedi):
// Emre'nin seçtiği karışık: Yön 1'in çaları (yon-1.html `.calar-tam`: büyük eser, ilerleme çubuğunda bölüm çentikleri,
// önceki bölüm · −15 · oynat · +15 · sonraki bölüm, altta Hız · Bölümler · Uyku · Metin şeridi), Yön 2'nin "Sıradaki"
// satırı ve otomatik geçiş düğmesi; goruntuler/yon-1-calar-{tam,bolumler,uyku,metin}-*.png, yon-2-calar-tam-*.png.
// Z4f (Emre: "dinleme kısmında resim büyük ekran, altta altyazı gibi hikâye anlatımı olsun"): o an dinlenen bölümün
// eseri bütün ekranda (kırpılmadan, yavaşça yakınlaşır; bölümde birden çok eser varsa 14 sn'de bir değişir), altta
// okunan cümle kelime kelime renklenir. Resme dokununca denetimler gizlenir; Sıradaki "Bölümler" yaprağında.
import AVKit
import NoraCekirdek
import SwiftUI

struct HikayeTamCalar: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var calar = HikayeCalari.shared
    @State private var depo = HikayeDeposu.shared
    @State private var bolumlerAcik = false
    @State private var metinAcik = false
    /// İlerleme çubuğu sürüklenirken (0…1)
    @State private var surukle: Double?
    /// Bölümün eserlerinden hangisi gösteriliyor
    @State private var eserSirasi = 0
    @State private var asagi: CGFloat = 0
    /// Denetimler görünür (resme dokununca gizlenir/açılır; altyazı hep görünür)
    @State private var arayuz = true
    /// Eserin yavaş yakınlaşması (hareket azaltılmışsa yok)
    @State private var yakin = false

    private var azHareket: Bool { hareketAz || tema.ayar.hareketAzaltilmis }
    private var pirinc: Color { Color(tema.renkler.pirinc) }

    var body: some View {
        Group {
            if let h = calar.hikaye {
                let isaret = calar.simdikiIsaret
                let eserler = depo.bolumEserleri(h, isaret)
                let e = eserler.isEmpty ? nil : eserler[eserSirasi % eserler.count]
                ZStack {
                    Color.black.ignoresSafeArea()
                    hale(e)
                    eser(e)
                    LinearGradient(stops: [.init(color: .black.opacity(0.55), location: 0),
                                           .init(color: .black.opacity(0), location: 0.16),
                                           .init(color: .black.opacity(0), location: 0.46),
                                           .init(color: .black.opacity(0.8), location: 0.8),
                                           .init(color: .black.opacity(0.9), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    VStack(spacing: 0) {
                        ust(h).opacity(arayuz ? 1 : 0).allowsHitTesting(arayuz)
                        Spacer(minLength: 0)
                        altyazi(e, isaret)
                        if arayuz {
                            VStack(spacing: 0) {
                                ilerleme().padding(.top, 16)
                                denetimler().padding(.top, 4)
                                altSerit().padding(.top, 6)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, arayuz ? 4 : 28)
                }
                .foregroundStyle(.white)
                .environment(\.colorScheme, .dark)
                .offset(y: asagi)
                .animation(.easeOut(duration: 0.25), value: arayuz)
                .task(id: "\(h.id)|\(calar.isaretSirasi)") {
                    eserSirasi = 0
                    guard eserler.count > 1 else { return }
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(14))
                        if Task.isCancelled { return }
                        withAnimation(azHareket ? nil : .easeInOut(duration: 1.4)) { eserSirasi += 1 }
                    }
                }
                .sheet(isPresented: $bolumlerAcik) { HikayeBolumlerYapragi().environment(tema) }
                .sheet(isPresented: $metinAcik) { HikayeMetinYapragi().environment(tema) }
            } else {
                Color.black.ignoresSafeArea().onAppear { calar.tamEkran = false }
            }
        }
        .accessibilityIdentifier("hikaye-tam-calar")
    }

    private func kapat() {
        Titresim.dokunus()
        calar.tamEkran = false
    }

    /// Aşağı çekince kapanır
    private var asagiCek: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { d in asagi = max(0, d.translation.height) }
            .onEnded { d in
                if d.translation.height > 120 || d.predictedEndTranslation.height > 260 {
                    kapat()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { asagi = 0 }
                }
            }
    }

    /// Emre: "arkadaki renk halesi gitmiş": eserin renkleri arkada bulanık yayılır (Z4e'deki gibi), net eser önünde
    @ViewBuilder
    private func hale(_ e: HikayeEserBilgisi?) -> some View {
        if let e, let u = depo.gorselAdresi(e.eser, genislik: 400) {
            UzakGorsel(url: u, icerik: .fill, yedek: e.yedek)
                .blur(radius: 60, opaque: true)
                .scaleEffect(1.3)
                .opacity(0.7)
                .ignoresSafeArea()
                .id("hale-\(e.eser.qid ?? u.absoluteString)")
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: Eser (büyük ekran)

    /// Z4f (Emre: "dinleme kısmında resim büyük ekran, altta altyazı gibi hikâye anlatımı"): bölümün eseri bütün ekranda,
    /// kırpılmadan; yavaşça yakınlaşır. Dokununca denetimler gizlenir/açılır.
    private func eser(_ e: HikayeEserBilgisi?) -> some View {
        GeometryReader { g in
            ZStack {
                if let e {
                    UzakGorsel(url: e.url, icerik: .fit, yedek: e.yedek)
                        .frame(width: g.size.width, height: g.size.height)
                        .scaleEffect(yakin && !azHareket ? 1.07 : 1)
                        .animation(azHareket ? nil : .linear(duration: 14), value: yakin)
                        .id(e.eser.qid ?? "")
                        .transition(.opacity)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            // Eser altyazının biraz üstünde dursun
            .offset(y: -g.size.height * 0.08)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { arayuz.toggle() }
        .gesture(asagiCek)
        .onChange(of: e?.eser.qid, initial: true) { _, _ in
            yakin = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(60))
                yakin = true
            }
        }
        .accessibilityLabel(e.map { "Eser: \($0.eser.gorunenAd)" } ?? "Eser")
        .accessibilityHint("Denetimleri göster ya da gizle")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Üst

    private func ust(_ h: SanatciHikayesi) -> some View {
        HStack(spacing: 8) {
            Button { kapat() } label: {
                Image(systemName: "chevron.down").font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.black.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Çaları küçült")
            VStack(spacing: 1) {
                Text(calar.uykuYazisi ?? depo.sanatciAdlari(h))
                    .font(Yazi.sans(12, agirlik: 600)).foregroundStyle(pirinc).lineLimit(1)
                Text(h.baslik).font(Yazi.sans(13, agirlik: 600)).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            HikayeBegenDugmesi(id: h.id, boyut: 19, beyaz: true)
            AirPlayDugmesi(renk: .white)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Ses çıkışı")
        }
        .padding(.top, 6)
    }

    // MARK: Altyazı

    /// Okunan cümle, kelime kelime renklenir (söylenen beyaz, kalan soluk); üstünde bölüm ve eserin adı
    private func altyazi(_ e: HikayeEserBilgisi?, _ i: HikayeBolumIsareti?) -> some View {
        let k = calar.kelime
        let (okunan, kalan) = altyaziParcasi(k)
        let kunye = eserKunyesi(e)
        let satir: CGFloat = 22 * 1.42
        let soz: Text = Text(okunan).foregroundColor(.white) + Text(kalan).foregroundColor(.white.opacity(0.42))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let i { Text(i.ad).foregroundStyle(pirinc) }
                if !kunye.isEmpty { Text("· " + kunye).foregroundStyle(.white.opacity(0.55)) }
            }
            .font(Yazi.sans(12, agirlik: 600))
            .lineLimit(1)
            soz
                .font(Yazi.okuma(22, agirlik: 500))
                .cssSatir(.okuma, 22, satir)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 1)
                .frame(maxWidth: .infinity, minHeight: satir * 3, alignment: .bottomLeading)
                .fixedSize(horizontal: false, vertical: true)
                .animation(nil, value: k)
                .accessibilityLabel(okunan + kalan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { arayuz.toggle() }
        .accessibilityIdentifier("hikaye-altyazi")
    }

    /// Okunan cümlenin söylenmiş ve kalan kısmı
    private func altyaziParcasi(_ k: Int) -> (String, String) {
        guard let a = calar.gecerliAkis else { return ("", "") }
        let r = a.cumle(kelime: max(0, k))
        let y = a.ayir(kelime: k, aralik: r)
        return (y.okunan, y.kalan)
    }

    /// "Küçük Sokak, 1658"
    private func eserKunyesi(_ e: HikayeEserBilgisi?) -> String {
        guard let e else { return "" }
        var l = [e.eser.gorunenAd]
        if let y = e.eser.yil { l.append(SiteYazisi.yilYaz(y)) }
        return l.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    // MARK: İlerleme

    /// İnce çubuk; bölüm başları çentik. Sürükleyince bırakılan yere gider (sürüklerken o anın bölümü yazar).
    private func ilerleme() -> some View {
        let toplam = max(calar.toplam, 0.001)
        let oran = surukle ?? min(1, calar.gecen / toplam)
        let an = oran * toplam
        return VStack(spacing: 4) {
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.22)).frame(height: 3)
                    Capsule().fill(pirinc).frame(width: max(0, w * oran), height: 3)
                    ForEach(Array(calar.isaretler.dropFirst().enumerated()), id: \.offset) { _, i in
                        Rectangle().fill(.black.opacity(0.85)).frame(width: 2, height: 3)
                            .offset(x: w * i.bas / toplam - 1)
                    }
                    Circle().fill(pirinc)
                        .frame(width: surukle == nil ? 11 : 19, height: surukle == nil ? 11 : 19)
                        .offset(x: w * oran - (surukle == nil ? 5.5 : 9.5))
                        .animation(.easeOut(duration: 0.15), value: surukle == nil)
                }
                .frame(height: 28)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { d in surukle = min(1, max(0, d.location.x / max(1, w))) }
                        .onEnded { _ in
                            if let s = surukle { calar.git(s * toplam) }
                            Titresim.secim()
                            surukle = nil
                        })
            }
            .frame(height: 28)
            HStack {
                Text(HikayeSesi.saat(an)).monospacedDigit()
                Spacer()
                if surukle != nil, !calar.isaretler.isEmpty {
                    Text(calar.isaretler[HikayeSesi.isaret(calar.isaretler, gecen: an)].ad)
                        .foregroundStyle(pirinc).lineLimit(1)
                    Spacer()
                }
                Text("-" + HikayeSesi.saat(max(0, toplam - an))).monospacedDigit()
            }
            .font(Yazi.sans(11.5))
            .foregroundStyle(.white.opacity(0.6))
        }
        .accessibilityElement()
        .accessibilityLabel("İlerleme")
        .accessibilityValue("\(HikayeSesi.saat(calar.gecen)), toplam \(HikayeSesi.saat(calar.toplam))")
        .accessibilityAdjustableAction { yon in
            switch yon {
            case .increment: calar.atla(15)
            case .decrement: calar.atla(-15)
            @unknown default: break
            }
        }
    }

    // MARK: Denetimler

    private func denetimler() -> some View {
        HStack {
            Button { Titresim.dokunus(); calar.oncekiBolum() } label: {
                Image(systemName: "backward.end.fill").font(.system(size: 18)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Önceki bölüm")
            Spacer()
            Button { Titresim.dokunus(); calar.atla(-15) } label: {
                HikayeIkon(simge: .geri15, boyut: 24, kalinlik: 1.7).frame(width: 48, height: 48)
            }
            .accessibilityLabel("15 saniye geri")
            Spacer()
            Button { calar.degistir() } label: {
                Image(systemName: calar.caliyor ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 62, height: 62)
                    .background(Circle().fill(.white))
            }
            .accessibilityLabel(calar.caliyor ? "Duraklat" : "Oynat")
            .accessibilityIdentifier("hikaye-tam-oynat")
            Spacer()
            Button { Titresim.dokunus(); calar.atla(15) } label: {
                HikayeIkon(simge: .ileri15, boyut: 24, kalinlik: 1.7).frame(width: 48, height: 48)
            }
            .accessibilityLabel("15 saniye ileri")
            Spacer()
            Button { Titresim.dokunus(); calar.sonrakiBolum() } label: {
                Image(systemName: "forward.end.fill").font(.system(size: 18)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Sonraki bölüm")
            .disabled(calar.isaretSirasi >= calar.isaretler.count - 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: Alt şerit

    private func altSerit() -> some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(HikayeSesi.hizlar, id: \.self) { h in
                    Button { calar.hizSec(h) } label: {
                        if abs(h - calar.hiz) < 0.001 {
                            Label(HikayeSesi.hizYazisi(h), systemImage: "checkmark")
                        } else {
                            Text(HikayeSesi.hizYazisi(h))
                        }
                    }
                }
            } label: {
                seritOgesi(ust: AnyView(Text(HikayeSesi.hizYazisi(calar.hiz)).font(Yazi.sans(15, agirlik: 600))
                    .monospacedDigit()), ad: "Hız")
            }
            .accessibilityLabel("Hız \(HikayeSesi.hizYazisi(calar.hiz))")
            Button { bolumlerAcik = true } label: {
                seritOgesi(ust: AnyView(Image(systemName: "list.bullet").font(.system(size: 17))), ad: "Bölümler")
            }
            Menu {
                Button("15 dakika") { calar.uykuKur(dakika: 15) }
                Button("30 dakika") { calar.uykuKur(dakika: 30) }
                Button("45 dakika") { calar.uykuKur(dakika: 45) }
                Button("1 saat") { calar.uykuKur(dakika: 60) }
                Button("Bölüm sonunda") { calar.uykuBolumSonu() }
                if calar.uyku != nil {
                    Button("Kapat", role: .destructive) { calar.uykuKur(dakika: nil) }
                }
            } label: {
                seritOgesi(ust: AnyView(Image(systemName: calar.uyku == nil ? "moon" : "moon.fill")
                    .font(.system(size: 17))), ad: "Uyku", etkin: calar.uyku != nil)
            }
            .accessibilityLabel(calar.uykuYazisi ?? "Uyku zamanlayıcı")
            Button { metinAcik = true } label: {
                seritOgesi(ust: AnyView(Image(systemName: "text.alignleft").font(.system(size: 17))), ad: "Metin")
            }
        }
        .buttonStyle(.plain)
    }

    private func seritOgesi(ust: AnyView, ad: String, etkin: Bool = false) -> some View {
        VStack(spacing: 3) {
            ust.frame(height: 22)
            Text(ad).font(Yazi.sans(11))
        }
        .foregroundStyle(etkin ? pirinc : .white.opacity(0.85))
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(Rectangle())
    }
}

// MARK: - Beğen / sonra oku düğmeleri

/// Kalp: beğen (telefonda saklanır)
struct HikayeBegenDugmesi: View {
    let id: String
    var boyut: CGFloat = 20
    /// Tam ekran çalarda (koyu sahne) beyaz
    var beyaz = false
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let b = depo.begenildi(id)
        Button {
            Titresim.secim()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { depo.begen(id) }
        } label: {
            Image(systemName: b ? "heart.fill" : "heart")
                .font(.system(size: boyut, weight: .regular))
                .foregroundStyle(b ? c.pirinc : (beyaz ? Color.white.opacity(0.85) : c.yazi2))
                .scaleEffect(b ? 1.08 : 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(b ? "Beğenildi" : "Beğen")
        .accessibilityAddTraits(b ? .isSelected : [])
    }
}

/// Yer imi: sonra oku
struct HikayeSonraDugmesi: View {
    let id: String
    var boyut: CGFloat = 19
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let s = depo.sonradaMi(id)
        Button {
            Titresim.secim()
            withAnimation(.easeOut(duration: 0.2)) { depo.sonraOku(id) }
        } label: {
            Image(systemName: s ? "bookmark.fill" : "bookmark")
                .font(.system(size: boyut, weight: .regular))
                .foregroundStyle(s ? c.pirinc : c.yazi2)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(s ? "Sonra oku listesinde" : "Sonra oku")
        .accessibilityAddTraits(s ? .isSelected : [])
    }
}

/// AirPlay / ses çıkışı seçici
struct AirPlayDugmesi: UIViewRepresentable {
    let renk: UIColor

    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.prioritizesVideoDevices = false
        v.tintColor = renk
        v.activeTintColor = renk
        return v
    }

    func updateUIView(_ v: AVRoutePickerView, context: Context) {
        v.tintColor = renk
        v.activeTintColor = renk
    }
}

// MARK: - Bölümler yaprağı

/// Bölümler (dokununca o bölüme) ve sıradaki yazılar (otomatik geçiş düğmesiyle)
struct HikayeBolumlerYapragi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat
    @State private var calar = HikayeCalari.shared
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        VStack(spacing: 0) {
            HStack {
                Text("Bölümler").font(Yazi.okuma(24, agirlik: 600)).foregroundStyle(c.yazi)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { kapat() } label: { HikayeIkon(simge: .kapat, boyut: 17, kalinlik: 1.7) }
                    .buttonStyle(HikayeCamDugme())
                    .accessibilityLabel("Kapat")
            }
            .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(calar.isaretler.enumerated()), id: \.offset) { n, i in
                        let simdiki = n == calar.isaretSirasi
                        Button {
                            Titresim.secim()
                            calar.bolumeGit(n)
                            kapat()
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(i.ad).font(Yazi.okuma(17.5, agirlik: simdiki ? 600 : 500))
                                        .foregroundStyle(simdiki ? c.pirinc : c.yazi)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text([i.yillar, "\(HikayeAkisi.dakika(i.sure)) dk"].filter { !$0.isEmpty }
                                        .joined(separator: " · "))
                                        .font(Yazi.sans(12)).foregroundStyle(c.yazi3)
                                }
                                Spacer(minLength: 8)
                                Text(HikayeSesi.saat(i.bas)).font(Yazi.sans(12.5, agirlik: simdiki ? 600 : 400))
                                    .monospacedDigit().foregroundStyle(simdiki ? c.pirinc : c.yazi3)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
                        .accessibilityAddTraits(simdiki ? .isSelected : [])
                    }
                    let sira = calar.siradaki
                    if !sira.isEmpty {
                        HStack {
                            Text("Sıradaki").font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                            Spacer()
                            Toggle(isOn: $calar.otomatik) {
                                Text("Otomatik sonraki").font(Yazi.sans(13)).foregroundStyle(c.yazi2)
                            }
                            .tint(c.pirinc)
                            .fixedSize()
                        }
                        .padding(.top, 28).padding(.bottom, 6)
                        ForEach(sira) { h in
                            let s = depo.satir(h)
                            Button {
                                Titresim.secim()
                                calar.siradakineGec(h)
                                kapat()
                            } label: {
                                HStack(spacing: 12) {
                                    UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(h.baslik).font(Yazi.okuma(16.5, agirlik: 600)).foregroundStyle(c.yazi)
                                            .lineLimit(1)
                                        Text("\(s.sanatci) · \(s.dinlemeDk) dk dinleme")
                                            .font(Yazi.sans(12)).foregroundStyle(c.yazi3).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                    HikayeIkon(simge: .ileri, boyut: 16).foregroundStyle(c.yazi3)
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(c.zemin)
    }
}

// MARK: - Metin yaprağı

/// Okunan metin, sesle birlikte akar (okunan paragraf öne çıkar). Paragrafa dokununca oradan; "Okumaya dön" yazıyı açar.
struct HikayeMetinYapragi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var calar = HikayeCalari.shared
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        if let h = calar.hikaye {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(depo.sanatciAdlari(h)).font(Yazi.sans(13.5, agirlik: 600)).foregroundStyle(c.yazi)
                            .lineLimit(1)
                        Text(calar.simdikiIsaret?.ad ?? h.baslik).font(Yazi.sans(12)).foregroundStyle(c.pirinc)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    Button {
                        Titresim.secim()
                        kapat()
                        calar.tamEkran = false
                        let adres = h.dizi.map { HikayeAdresi.diziBolumu($0, h.id) } ?? HikayeAdresi.yazi(h.id)
                        Gezgin.shared.git(adres)
                    } label: {
                        Text("Okumaya dön").font(Yazi.sans(13.5, agirlik: 600)).foregroundStyle(c.yazi)
                            .padding(.horizontal, 14).frame(height: 40)
                            .background(Capsule().fill(Color(tema.renkler.ustDugme)))
                            .overlay(Capsule().strokeBorder(c.kenar, lineWidth: 1))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    Button { kapat() } label: { Image(systemName: "chevron.down").font(.system(size: 16, weight: .semibold)) }
                        .buttonStyle(HikayeCamDugme())
                        .accessibilityLabel("Kapat")
                }
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)
                .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
                ScrollViewReader { kaydir in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            ForEach(Array(h.paragraflar.enumerated()), id: \.offset) { no, p in
                                let okunan = calar.paragraf == no
                                Text(p)
                                    .font(Yazi.okuma(19))
                                    .cssSatir(.okuma, 19, 19 * 1.7)
                                    .foregroundStyle(c.yazi)
                                    .opacity(okunan ? 1 : 0.44)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Titresim.secim()
                                        calar.paragrafaGit(no)
                                    }
                                    .id(no)
                                    .accessibilityAction(named: "Buradan dinle") { calar.paragrafaGit(no) }
                            }
                        }
                        .padding(.horizontal, 22).padding(.vertical, 20)
                    }
                    .onAppear { if let p = calar.paragraf { kaydir.scrollTo(p, anchor: UnitPoint(x: 0.5, y: 0.2)) } }
                    .onChange(of: calar.paragraf) { _, p in
                        guard let p else { return }
                        withAnimation(hareketAz || tema.ayar.hareketAzaltilmis ? nil : .easeInOut(duration: 0.5)) {
                            kaydir.scrollTo(p, anchor: UnitPoint(x: 0.5, y: 0.2))
                        }
                    }
                }
                VStack(spacing: 6) {
                    HikayeCizgi(oran: calar.toplam > 0 ? calar.gecen / calar.toplam : 0)
                    HStack {
                        Text(HikayeSesi.saat(calar.gecen)).font(Yazi.sans(11.5)).monospacedDigit().foregroundStyle(c.yazi3)
                        Spacer()
                        Button { Titresim.dokunus(); calar.atla(-15) } label: {
                            HikayeIkon(simge: .geri15, boyut: 21).frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("15 saniye geri")
                        Button { calar.degistir() } label: {
                            Image(systemName: calar.caliyor ? "pause.fill" : "play.fill")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(c.zemin)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(c.yazi))
                        }
                        .accessibilityLabel(calar.caliyor ? "Duraklat" : "Oynat")
                        Button { Titresim.dokunus(); calar.atla(15) } label: {
                            HikayeIkon(simge: .ileri15, boyut: 21).frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("15 saniye ileri")
                        Spacer()
                        Text(HikayeSesi.hizYazisi(calar.hiz)).font(Yazi.sans(12.5, agirlik: 600)).monospacedDigit()
                            .foregroundStyle(c.yazi3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(c.yazi)
                }
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 10)
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(c.zemin)
        }
    }
}

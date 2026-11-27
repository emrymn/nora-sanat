// Z4e · Hikâyeler tam ekran çaları. Tasarım: Neon 4. tur (dal neon/hikayeler-tasarim-4, PR #83; birleştirilmedi):
// Emre'nin seçtiği karışık: Yön 1'in çaları (yon-1.html `.calar-tam`: büyük eser, ilerleme çubuğunda bölüm çentikleri,
// önceki bölüm · −15 · oynat · +15 · sonraki bölüm, altta Hız · Bölümler · Uyku · Metin şeridi), Yön 2'nin "Sıradaki"
// satırı ve otomatik geçiş düğmesi; goruntuler/yon-1-calar-{tam,bolumler,uyku,metin}-*.png, yon-2-calar-tam-*.png.
// Emre'nin eki: "dinleme modunda arkaplanda resim olsun" → arka planda o an dinlenen bölümün eseri (bulanık), bölümde
// birden çok eser varsa 14 sn'de bir yumuşakça değişir ("resimleri arttırabilir miyiz").
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

    private var azHareket: Bool { hareketAz || tema.ayar.hareketAzaltilmis }

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        Group {
            if let h = calar.hikaye {
                let isaret = calar.simdikiIsaret
                let eserler = depo.bolumEserleri(h, isaret)
                let e = eserler.isEmpty ? nil : eserler[eserSirasi % eserler.count]
                ZStack {
                    arkaPlan(h, e, c)
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ust(c)
                            Spacer(minLength: 10)
                            kapak(e, c)
                            Spacer(minLength: 14)
                        }
                        .contentShape(Rectangle())
                        .gesture(asagiCek)
                        bilgi(h, isaret, c)
                        ilerleme(c).padding(.top, 18)
                        denetimler(c).padding(.top, 8)
                        siradakiSatiri(c).padding(.top, 10)
                        altSerit(c).padding(.top, 12)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 6)
                }
                .offset(y: asagi)
                .task(id: "\(h.id)|\(calar.isaretSirasi)") {
                    eserSirasi = 0
                    guard eserler.count > 1 else { return }
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(14))
                        if Task.isCancelled { return }
                        withAnimation(azHareket ? nil : .easeInOut(duration: 1.2)) { eserSirasi += 1 }
                    }
                }
                .sheet(isPresented: $bolumlerAcik) { HikayeBolumlerYapragi().environment(tema) }
                .sheet(isPresented: $metinAcik) { HikayeMetinYapragi().environment(tema) }
            } else {
                c.zemin.ignoresSafeArea().onAppear { calar.tamEkran = false }
            }
        }
        .accessibilityIdentifier("hikaye-tam-calar")
    }

    private func kapat() {
        Titresim.dokunus()
        calar.tamEkran = false
    }

    /// Aşağı çekince kapanır (Yön 1: "aşağı kaydırınca küçük çalara döner")
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

    // MARK: Arka plan

    /// Bölümün eseri, büyük bulanıklıkla ekranı doldurur; üstünde temanın zemini (okunurluk)
    private func arkaPlan(_ h: SanatciHikayesi, _ e: HikayeEserBilgisi?, _ c: HikayeRenk) -> some View {
        ZStack {
            c.zemin
            if let e, let u = depo.gorselAdresi(e.eser, genislik: 400) {
                UzakGorsel(url: u, icerik: .fill, yedek: e.yedek)
                    .blur(radius: 44, opaque: true)
                    .scaleEffect(1.25)
                    .opacity(tema.renkler.koyu ? 0.75 : 0.6)
                    .id(e.eser.qid ?? u.absoluteString)
                    .transition(.opacity)
            }
            LinearGradient(colors: [c.zemin.opacity(0.45), c.zemin.opacity(0.72), c.zemin.opacity(0.92)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: Üst

    private func ust(_ c: HikayeRenk) -> some View {
        HStack {
            Button { kapat() } label: {
                Image(systemName: "chevron.down").font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(HikayeCamDugme())
            .accessibilityLabel("Çaları küçült")
            Spacer()
            Text(calar.uykuYazisi ?? "Şimdi dinleniyor")
                .font(Yazi.sans(12.5, agirlik: 600))
                .foregroundStyle(c.pirinc)
            Spacer()
            AirPlayDugmesi(renk: UIColor(c.yazi))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(tema.renkler.ustDugme)))
                .overlay(Circle().strokeBorder(c.kenar, lineWidth: 1))
                .accessibilityLabel("Ses çıkışı")
        }
        .padding(.top, 6)
    }

    // MARK: Eser

    /// Bölümün eseri, kırpılmadan; altında adı ve yılı
    private func kapak(_ e: HikayeEserBilgisi?, _ c: HikayeRenk) -> some View {
        VStack(spacing: 10) {
            ZStack {
                if let e {
                    TamGorsel(url: e.url, yedek: e.yedek, oran: e.oran, kose: 16)
                        .shadow(color: c.golge, radius: 24, x: 0, y: 16)
                        .id(e.eser.qid ?? "")
                        .transition(.opacity)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(c.yuzey).aspectRatio(1, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let e {
                Text([e.eser.gorunenAd, e.eser.yil.map { SiteYazisi.yilYaz($0) } ?? ""].filter { !$0.isEmpty }
                    .joined(separator: " · "))
                    .font(Yazi.serif(14, agirlik: 500))
                    .foregroundStyle(c.yazi2)
                    .lineLimit(1)
                    .id("ad-\(e.eser.qid ?? "")")
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Bilgi

    private func bilgi(_ h: SanatciHikayesi, _ i: HikayeBolumIsareti?, _ c: HikayeRenk) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(h.baslik)
                    .font(Yazi.okuma(24, agirlik: 600))
                    .tracking(-0.36)
                    .foregroundStyle(c.yazi)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text([depo.sanatciAdi(h.id), depo.yillar(h.id)].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(Yazi.sans(13.5)).foregroundStyle(c.yazi2).lineLimit(1)
                if let i {
                    Text(i.ad).font(Yazi.sans(12.5, agirlik: 600)).foregroundStyle(c.pirinc).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            HikayeBegenDugmesi(id: h.id)
            HikayeSonraDugmesi(id: h.id)
        }
    }

    // MARK: İlerleme

    /// İnce çubuk; bölüm başları çentik. Sürükleyince bırakılan yere gider (sürüklerken o anın bölümü yazar).
    private func ilerleme(_ c: HikayeRenk) -> some View {
        let toplam = max(calar.toplam, 0.001)
        let oran = surukle ?? min(1, calar.gecen / toplam)
        let an = oran * toplam
        return VStack(spacing: 6) {
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(c.kenar).frame(height: 4)
                    Capsule().fill(c.pirinc).frame(width: max(0, w * oran), height: 4)
                    ForEach(Array(calar.isaretler.dropFirst().enumerated()), id: \.offset) { _, i in
                        Rectangle().fill(c.zemin.opacity(0.9)).frame(width: 2, height: 4)
                            .offset(x: w * i.bas / toplam - 1)
                    }
                    Circle().fill(c.pirinc)
                        .frame(width: surukle == nil ? 12 : 20, height: surukle == nil ? 12 : 20)
                        .offset(x: w * oran - (surukle == nil ? 6 : 10))
                        .animation(.easeOut(duration: 0.15), value: surukle == nil)
                }
                .frame(height: 30)
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
            .frame(height: 30)
            HStack {
                Text(HikayeSesi.saat(an)).monospacedDigit()
                Spacer()
                if surukle != nil {
                    Text(calar.isaretler.isEmpty ? "" : calar.isaretler[HikayeSesi.isaret(calar.isaretler, gecen: an)].ad)
                        .foregroundStyle(c.pirinc).lineLimit(1)
                    Spacer()
                }
                Text("-" + HikayeSesi.saat(max(0, toplam - an))).monospacedDigit()
            }
            .font(Yazi.sans(11.5))
            .foregroundStyle(c.yazi3)
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

    private func denetimler(_ c: HikayeRenk) -> some View {
        HStack {
            Button { Titresim.dokunus(); calar.oncekiBolum() } label: {
                Image(systemName: "backward.end.fill").font(.system(size: 19)).frame(width: 44, height: 44)
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
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(c.zemin)
                    .frame(width: 66, height: 66)
                    .background(Circle().fill(c.yazi))
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
                Image(systemName: "forward.end.fill").font(.system(size: 19)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Sonraki bölüm")
            .disabled(calar.isaretSirasi >= calar.isaretler.count - 1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(c.yazi)
    }

    // MARK: Sıradaki (Yön 2)

    @ViewBuilder
    private func siradakiSatiri(_ c: HikayeRenk) -> some View {
        if let s = calar.siradaki.first {
            HStack(spacing: 10) {
                Button {
                    Titresim.secim()
                    calar.siradakineGec(s)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sıradaki").font(Yazi.sans(11.5, agirlik: 600)).foregroundStyle(c.pirinc)
                        Text("\(depo.sanatciAdi(s.id)) · \(s.baslik)")
                            .font(Yazi.serif(15, agirlik: 500)).foregroundStyle(c.yazi).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Sıradaki yazıyı dinle")
                Toggle(isOn: $calar.otomatik) {
                    Text("Otomatik").font(Yazi.sans(12.5)).foregroundStyle(c.yazi2)
                }
                .toggleStyle(.switch)
                .tint(c.pirinc)
                .fixedSize()
                .accessibilityHint("Yazı bitince sıradakine geç")
            }
            .padding(.vertical, 4)
            .overlay(alignment: .top) { Rectangle().fill(c.kenar).frame(height: 1) }
        }
    }

    // MARK: Alt şerit

    private func altSerit(_ c: HikayeRenk) -> some View {
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
                    .monospacedDigit()), ad: "Hız", c)
            }
            .accessibilityLabel("Hız \(HikayeSesi.hizYazisi(calar.hiz))")
            Button { bolumlerAcik = true } label: {
                seritOgesi(ust: AnyView(Image(systemName: "list.bullet").font(.system(size: 17))), ad: "Bölümler", c)
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
                    .font(.system(size: 17))), ad: "Uyku", c, etkin: calar.uyku != nil)
            }
            .accessibilityLabel(calar.uykuYazisi ?? "Uyku zamanlayıcı")
            Button { metinAcik = true } label: {
                seritOgesi(ust: AnyView(Image(systemName: "text.alignleft").font(.system(size: 17))), ad: "Metin", c)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .overlay(alignment: .top) { Rectangle().fill(c.kenar).frame(height: 1) }
    }

    private func seritOgesi(ust: AnyView, ad: String, _ c: HikayeRenk, etkin: Bool = false) -> some View {
        VStack(spacing: 4) {
            ust.frame(height: 22)
            Text(ad).font(Yazi.sans(11.5))
        }
        .foregroundStyle(etkin ? c.pirinc : c.yazi)
        .frame(maxWidth: .infinity, minHeight: 52)
        .contentShape(Rectangle())
    }
}

// MARK: - Beğen / sonra oku düğmeleri

/// Kalp: beğen (telefonda saklanır)
struct HikayeBegenDugmesi: View {
    let id: String
    var boyut: CGFloat = 20
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
                .foregroundStyle(b ? c.pirinc : c.yazi2)
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
                        Text(depo.sanatciAdi(h.id)).font(Yazi.sans(13.5, agirlik: 600)).foregroundStyle(c.yazi)
                            .lineLimit(1)
                        Text(calar.simdikiIsaret?.ad ?? h.baslik).font(Yazi.sans(12)).foregroundStyle(c.pirinc)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    Button {
                        Titresim.secim()
                        kapat()
                        calar.tamEkran = false
                        Gezgin.shared.git(HikayeAdresi.yazi(h.id))
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

// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (turCubugu, secenekDugmesi, gecDugme), js/ekranlar/ortak.js (etiket,
// yaprakDugmeYazisi), css/app.css (.etiket, .soru-ust, .ince-cubuk.parcali, .secenek, .alt-yaprak .dugme, .tanisma-gec) @ a866b86
// Ölçüler sitenin hesaplanmış stillerinden (iPhone 15 Pro, 393 pt).
import NoraCekirdek
import SwiftUI

/// `.etiket`: 11 px Archivo 600, büyük harf, 0.2em harf aralığı
struct PkEtiket: View {
    let yazi: String
    var renk: Color?
    var boyut: CGFloat = 11
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        Text(yazi.uppercased(with: Locale(identifier: "tr")))
            .font(Yazi.sans(boyut, agirlik: 600, stil: .caption2))
            .tracking(boyut * 0.2)
            .foregroundStyle(renk ?? Color(tema.renkler.murekkep2))
            .lineLimit(1)
    }
}

/// `.soru-ust`: kapat, kipin adı, sayaç
struct SoruUstu: View {
    let baslik: String
    let sayac: String
    let kapat: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        HStack(spacing: 8) {
            Button(action: kapat) {
                Image(systemName: "xmark").font(.system(size: 17, weight: .light)).frame(width: 44, height: 44)
            }
            .foregroundStyle(Color(tema.renkler.murekkep2))
            .accessibilityLabel("Kapat")
            PkEtiket(yazi: baslik, renk: Color(tema.renkler.murekkep))
            Spacer(minLength: 8)
            Text(sayac).font(Yazi.sans(13, agirlik: 500, stil: .caption1)).monospacedDigit()
                .foregroundStyle(Color(tema.renkler.murekkep2))
                .accessibilityIdentifier("sayac")
        }
        .padding(.leading, 12).padding(.trailing, 18)
        .frame(height: 44)
    }
}

/// `turCubugu`: kart kart parçalı çizgi (bitenler pirinç, şimdiki mürekkep); 24'ten çok kartta tek çizgi
struct TurCubugu: View {
    let toplam: Int
    let konum: Int
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Group {
            if toplam > 24 {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(r.murekkep).opacity(0.22))
                        Capsule().fill(Color(r.vurguAcik))
                            .frame(width: g.size.width * CGFloat(konum) / CGFloat(max(1, toplam)))
                    }
                }
            } else {
                HStack(spacing: 4) {
                    ForEach(0..<max(1, toplam), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < konum ? Color(r.pirinc) : i == konum ? Color(r.murekkep) : Color(r.murekkep).opacity(0.2))
                    }
                }
            }
        }
        .frame(height: 3)
        .animation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.4), value: konum)
        .accessibilityHidden(true)
    }
}

/// `.secenek`: harfli şık; cevaptan sonra doğru yeşil ✓, seçilen yanlış kırmızı ×, kalanlar soluk
struct SecenekDugmesi: View {
    enum Durum { case bos, dogru, yanlis, soluk }
    let harf: String
    let ad: String
    let durum: Durum
    var daralmis = false
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: eylem) {
            Group {
                if daralmis {
                    HStack(spacing: 8) { adYazisi; isaret }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(harf).font(Yazi.sans(12, agirlik: 600, stil: .caption1))
                            .foregroundStyle(Color(r.murekkep2))
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color(r.vurgu), lineWidth: 1))
                        adYazisi
                    }
                }
            }
            .padding(.vertical, 10).padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: daralmis ? 56 : 88, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(zemin))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(durum != .bos)
        .accessibilityLabel(ad)
        .accessibilityValue(durum == .dogru ? "Doğru cevap" : durum == .yanlis ? "Senin cevabın, yanlış" : "")
    }

    private var adYazisi: some View {
        Text(ad).font(Yazi.sans(17, agirlik: 500))
            .foregroundStyle(Color(durum == .soluk ? tema.renkler.soluk : tema.renkler.murekkep))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var isaret: some View {
        let r = tema.renkler
        if durum == .dogru || durum == .yanlis {
            Image(systemName: durum == .dogru ? "checkmark" : "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(r.zemin))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color(durum == .dogru ? r.dogru : r.yanlis)))
        }
    }

    private var zemin: Color {
        let r = tema.renkler
        switch durum {
        case .bos: return Color(r.yuzey)
        case .dogru: return Color(r.dogruZemin)
        case .yanlis: return Color(r.yanlisZemin)
        case .soluk: return .clear
        }
    }

    private var kenar: Color {
        let r = tema.renkler
        switch durum {
        case .bos, .soluk: return Color(r.kenar)
        case .dogru: return Color(r.dogru)
        case .yanlis: return Color(r.yanlis)
        }
    }
}

/// Cevap yaprağının ana düğmesi (`yaprakDugmeYazisi`): yazı ve yuvarlak içinde ok
struct YaprakDugmesi: View {
    let yazi: String
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: eylem) {
            HStack(spacing: 8) {
                Text(yazi).font(Yazi.sans(17, agirlik: 600)).lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.16)))
            }
            .padding(.leading, 22).padding(.trailing, 8)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(Color(r.vurguAcikYazi))
            .background(Capsule().fill(Color(r.vurguAcik)))
        }
        .buttonStyle(.plain)
    }
}

/// Yapraktaki "Sanatçı" düğmesi: portre diski ve yazı
struct PkSanatciDugmesi: View {
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        Button(action: eylem) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.square").font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(r.zemin))
                    .frame(width: 34, height: 34).background(Circle().fill(Color(r.vurgu)))
                Text("Sanatçı").font(Yazi.sans(15, agirlik: 600)).foregroundStyle(Color(r.murekkep))
            }
            .padding(.leading, 8).padding(.trailing, 18)
            .frame(minHeight: 56)
            .background(Capsule().fill(Color(r.yuzey)))
            .overlay(Capsule().stroke(Color(r.kenar), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sanatçı sayfası")
    }
}

/// Tanışmanın ileri düğmesi (`gecDugme`): müze kartelası gibi; üstte küçük yön yazısı, altta sıradaki adım, sağda ok.
/// `toplam` > 1 ise üstünde tanışma adımlarının çentikleri; `geri` verilirse solda geri düğmesi.
struct GecDugmesi: View {
    let ust: String
    let ana: String
    var adim = 0
    var toplam = 0
    var geri: String?
    var geriEylem: () -> Void = {}
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 10) {
            if toplam > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<toplam, id: \.self) { i in
                        Capsule().fill(i < adim ? Color(r.pirinc) : i == adim ? Color(r.murekkep) : Color(r.murekkep).opacity(0.2))
                            .frame(height: 3)
                    }
                }
                .accessibilityHidden(true)
            }
            HStack(spacing: 10) {
                if let geri {
                    Button(action: geriEylem) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .regular))
                            .frame(width: 52, height: 64)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color(r.yuzey)))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(r.kenar), lineWidth: 1))
                    }
                    .foregroundStyle(Color(r.murekkep2))
                    .accessibilityLabel("Önceki sanatçı: \(geri)")
                }
                Button(action: eylem) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ust.uppercased(with: Locale(identifier: "tr")))
                                .font(Yazi.sans(11, agirlik: 600, stil: .caption2)).tracking(1.76).opacity(0.6)
                            Text(ana).font(Yazi.okuma(21, italik: true)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right").font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(r.vurguAcik))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(r.vurguAcikYazi)))
                            .padding(5)
                            .overlay(Circle().stroke(Color(r.vurguAcikYazi).opacity(0.45),
                                                     style: StrokeStyle(lineWidth: 1, dash: [2, 3])))
                    }
                    .foregroundStyle(Color(r.vurguAcikYazi))
                    .padding(.leading, 18).padding(.trailing, 5)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color(r.vurguAcik)))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: .black.opacity(0.5), radius: 14, y: 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tanisma-gec")
            }
        }
    }
}

/// Soru görseli: kutuya sığar, hiç kırpılmaz; açılmazsa `hata` (sitede `baskaEser`).
struct SoruGorseli: View {
    let url: URL?
    var yedek: URL?
    let yukseklik: CGFloat
    let enGenis: CGFloat
    /// Köşe yarıçapı (Çalış 4; Yolculuk Z3y "Geniş Tuval" 16)
    var kose: CGFloat = 4
    var hata: () -> Void = {}
    @Environment(\.displayScale) private var olcek
    @Environment(TemaDeposu.self) private var tema
    @State private var resim: UIImage?
    @State private var olmadi = false

    var body: some View {
        Group {
            if let resim {
                let oran = resim.size.width / max(1, resim.size.height)
                let h = min(yukseklik, enGenis / max(oran, 0.01))
                Image(uiImage: resim).resizable().aspectRatio(contentMode: .fit)
                    .frame(width: h * oran, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: kose))
                    .shadow(color: .black.opacity(0.6), radius: 30, y: 24)
                    .transition(.opacity)
            } else {
                RoundedRectangle(cornerRadius: kose).fill(Color(tema.renkler.yuzey))
                    .frame(width: min(enGenis, yukseklik * 0.75), height: yukseklik)
                    .overlay(Text(olmadi ? "Görsel yüklenemedi." : "Yükleniyor…")
                        .font(Yazi.sans(13)).foregroundStyle(Color(tema.renkler.murekkep3)))
            }
        }
        .task(id: url) {
            resim = nil
            olmadi = false
            let piksel = Int((max(yukseklik, enGenis) * olcek).rounded(.up))
            var r = await GorselCozucu.shared.resim(url, piksel: piksel)
            if r == nil, let yedek { r = await GorselCozucu.shared.resim(yedek, piksel: piksel) }
            guard !Task.isCancelled else { return }
            if let r {
                withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.3)) { resim = r }
            } else {
                olmadi = true
                hata()
            }
        }
    }
}

/// Soru sahnesinin arkası: üstte eserin bulanık ışığı (`.soru-isik`)
struct SoruIsigi: View {
    let url: URL?
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        GeometryReader { g in
            UzakGorsel(url: url, icerik: .fill)
                .frame(width: g.size.width + 80, height: g.size.height * 0.72)
                .blur(radius: 40)
                .colorMultiply(Color(white: tema.ayar.tema == .gece ? 0.36 : 1))
                .opacity(tema.ayar.tema == .gece ? 1 : 0.5)
                .mask(LinearGradient(stops: [.init(color: .black, location: 0.45), .init(color: .clear, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
                .offset(x: -40, y: -40)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Eserin arkasında nefes alan hale (`.hale-nefes`)
struct HaleNefes: View {
    @Environment(TemaDeposu.self) private var tema
    @State private var nefes = false

    var body: some View {
        let v = Color(tema.renkler.vurgu)
        Ellipse()
            .fill(RadialGradient(stops: [.init(color: v.opacity(0.55), location: 0), .init(color: v.opacity(0.18), location: 0.55),
                                         .init(color: v.opacity(0), location: 1)], center: .center, startRadius: 0, endRadius: 190))
            .blur(radius: 18)
            .scaleEffect(nefes ? 1.06 : 0.92)
            .opacity(nefes ? 0.95 : 0.55)
            .onAppear {
                guard !tema.ayar.hareketAzaltilmis else { return }
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { nefes = true }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

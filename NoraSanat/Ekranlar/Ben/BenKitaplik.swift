// Kaynak: sanat-atlasi js/ekranlar/ilerleme.js (siradakiKonuHtml, kursBolumleriHtml, konuKarti, kitapKapagi),
// css/app.css (.siradaki, .isle-ince, .kilitli-kare, .kurs-kip, .salon-raf, .destek, .kitap, .konu-karti, .konu-portre) @ a866b86
import NoraCekirdek
import SwiftUI

/// Kitaplıkta gereken ortak bilgi
struct KursBilgisi {
    let katalog: SiteKatalogu
    let il: Ilerleme
    let adlar: JSONDeger?

    var islenen: Set<Int> { il.islenenKume }
    var konular: [Konu] { katalog.kursKonulari }
    var siradaki: Konu? { konular.first { !islenen.contains($0.no) } }

    /// `konuBasligi(konu)`: kısa Türkçe başlık (data/konular_tr.json), yoksa özgün başlık
    func baslik(_ k: Konu) -> String { adlar?["konular"]?[String(k.no)]?.metin ?? k.baslik }
    func bolumAdi(_ bolum: String, _ yedek: String) -> String { adlar?["bolumler"]?[bolum]?.metin ?? yedek }

    /// `konuSanatcilari(no)`: kurs kaynaklılar önce
    func sanatcilar(_ no: Int) -> [Sanatci] {
        let l = katalog.sanatcilar.filter { $0.konu == no }
        return l.filter { $0.kaynak == "kurs" } + l.filter { $0.kaynak != "kurs" }
    }

    /// Sanatçının en bilinen eserinin küçük görseli (`data-kucuk`)
    func kucuk(_ id: String, genislik: Int = 400) -> URL? {
        katalog.eserler(id).first.flatMap { katalog.gorselAdresi($0, genislik: genislik, kotuler: il.kotuGorseller) }
    }

    /// `kitapKapagi`: konunun kapak dosyası; yoksa ilk sanatçısının en bilinen eseri
    func kapak(_ k: Konu) -> URL? {
        if let d = k.kapak?.dosya, !d.isEmpty {
            return GorselAdresleri.url(katalog.gorsel.url(Gorsel(k: "commons", d: d), genislik: 400))
        }
        if let s = sanatcilar(k.no).first { return kucuk(s.id) }
        return k.kapak.flatMap { kucuk($0.sanatci) }
    }

    struct Bolum: Identifiable {
        let id: String
        let ad: String
        let konular: [Konu]
    }

    var bolumler: [Bolum] {
        var l: [Bolum] = []
        for k in konular {
            if let i = l.firstIndex(where: { $0.id == k.bolum }) {
                l[i] = Bolum(id: k.bolum, ad: l[i].ad, konular: l[i].konular + [k])
            } else {
                l.append(Bolum(id: k.bolum, ad: bolumAdi(k.bolum, k.bolumAd), konular: [k]))
            }
        }
        return l
    }
}

private let kitapYazisi = Color(red: 246 / 255, green: 241 / 255, blue: 231 / 255)   // #f6f1e7

// MARK: Sıradaki konu

/// `siradakiKonuHtml`: büyük numara, başlık ve "İşlendi yap"; konunun sanatçıları kilitli kareler olarak sağda
struct SiradakiKonu: View {
    let bilgi: KursBilgisi
    let isle: (Int) -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var azHareket
    @State private var doldu: Int?

    var body: some View {
        let r = tema.renkler
        if let x = bilgi.siradaki {
            let l = bilgi.sanatcilar(x.no)
            let onizleme = Array(l.prefix(4))
            let resimli = !onizleme.isEmpty
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 16) {
                    Text("\(x.no)").font(Yazi.serif(64)).foregroundStyle(Color(r.murekkep))
                        .frame(minWidth: 40, alignment: .leading)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Etiket("Sıradaki konu")
                        Text(bilgi.baslik(x)).font(Yazi.okuma(21)).foregroundStyle(Color(r.murekkep))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(l.isEmpty ? "yeni sanatçı açılmaz" : "\(l.count) sanatçı açılacak") · Konu \(x.no)")
                            .font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                isleDugmesi(x.no)
                    .padding(.leading, 56)
            }
            .padding(.vertical, resimli ? 18 : 14).padding(.horizontal, resimli ? 16 : 0)
            .background {
                if resimli {
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey))
                        kilitliKareler(onizleme)
                        LinearGradient(stops: [.init(color: Color(r.yuzey), location: 0.3),
                                               .init(color: Color(r.zemin).opacity(0.4), location: 1)],
                                       startPoint: .leading, endPoint: .trailing)
                        BenIkon(simge: .kilit, boyut: 18, kalinlik: 1.6)
                            .foregroundStyle(Color(r.murekkep))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(r.zemin).opacity(0.7)))
                            .padding(.trailing, 44)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                }
            }
            .overlay(alignment: .top) { if !resimli { Ayrac(renk: \.murekkep) } }
            .overlay(alignment: .bottom) { if !resimli { Ayrac() } }
            .padding(.top, resimli ? 28 : 6).padding(.bottom, 22)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Sıradaki konu")
        } else {
            Text("Bütün konular işlendi.").font(Yazi.okuma(18, italik: true)).foregroundStyle(Color(r.murekkep2))
                .padding(.top, 6).padding(.bottom, 18)
        }
    }

    private func kilitliKareler(_ l: [Sanatci]) -> some View {
        HStack(spacing: -22) {
            ForEach(l.indices, id: \.self) { i in
                UzakGorsel(url: bilgi.kucuk(l[i].id))
                    .frame(width: 62, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .rotationEffect(.degrees((Double(i) - 1.5) * 7))
                    .grayscale(0.6).colorMultiply(Color(white: 0.8))
                    .blur(radius: 3)
            }
        }
        .padding(.trailing, 8)
        .accessibilityHidden(true)
    }

    /// `.siradaki-dugme.isle-ince`: dokununca soldan sağa dolar, "İşlendi" olur, sonra konu işlenir
    private func isleDugmesi(_ no: Int) -> some View {
        let r = tema.renkler
        let dolu = doldu == no
        return Button {
            guard doldu == nil else { return }
            if azHareket || tema.ayar.hareketAzaltilmis { return isle(no) }
            withAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.45)) { doldu = no }
            Task {
                try? await Task.sleep(nanoseconds: 520_000_000)
                isle(no)
                doldu = nil
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().strokeBorder(dolu ? .clear : Color(r.vurguAcik), lineWidth: 1.5)
                    BenIkon(simge: .dogru, boyut: 14, kalinlik: 2.2)
                        .opacity(dolu ? 1 : 0).scaleEffect(dolu ? 1 : 0.4)
                }
                .frame(width: 20, height: 20)
                Text(dolu ? "İşlendi" : "İşlendi yap").font(Yazi.sans(15, agirlik: 600)).tracking(0.3)
            }
            .foregroundStyle(Color(dolu ? r.vurguAcikYazi : r.murekkep))
            .padding(.leading, 16).padding(.trailing, 22)
            .frame(minHeight: 48)
            .background(alignment: .leading) {
                GeometryReader { g in
                    Rectangle().fill(Color(r.vurguAcik)).frame(width: dolu ? g.size.width : 0)
                }
            }
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color(r.vurguAcik), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(BasincBicimi())
    }
}

/// Basınca hafifçe küçülür (`:active { transform: scale(.97) }`)
struct BasincBicimi: ButtonStyle {
    var olcek: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? olcek : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: Kitaplık

/// `kursBolumleriHtml`: kip seçimi ve bölüm rafları; her konu bir kitap (kapak resmi), seçili konunun kartı rafın altında
struct KursKitapligi: View {
    let bilgi: KursBilgisi
    @Binding var hizli: Bool
    @Binding var secili: Int?
    /// (konular, işlendi, kartla)
    let isaretle: ([Int], Bool, Bool) -> Void
    let sanatciAc: (String) -> Void
    @Environment(TemaDeposu.self) private var tema

    private static let roma = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            kip
            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(bilgi.bolumler.enumerated()), id: \.element.id) { _, bl in raf(bl) }
            }
        }
    }

    private var kip: some View {
        let r = tema.renkler
        return HStack(spacing: 0) {
            ForEach([(false, "Dokununca bilgi"), (true, "Dokununca işaretle")], id: \.0) { deger, yazi in
                let acik = hizli == deger
                Button { withAnimation(.easeOut(duration: 0.2)) { hizli = deger } } label: {
                    Text(yazi).font(Yazi.sans(15, agirlik: acik ? 650 : 500))
                        .foregroundStyle(Color(acik ? r.murekkep : r.murekkep2))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(alignment: .bottom) { Rectangle().fill(acik ? Color(r.murekkep) : .clear).frame(height: 2) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(acik ? [.isSelected] : [])
            }
        }
        .overlay(alignment: .bottom) { Ayrac() }
        .padding(.bottom, 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kitaba dokununca")
    }

    private func bolumNo(_ bl: KursBilgisi.Bolum) -> String {
        let n = Int(bl.id.filter(\.isNumber)) ?? 0
        return n >= 1 && n <= Self.roma.count ? Self.roma[n - 1] : bl.id
    }

    private func raf(_ bl: KursBilgisi.Bolum) -> some View {
        let r = tema.renkler
        let bitti = bl.konular.filter { bilgi.islenen.contains($0.no) }.count
        let tam = bitti == bl.konular.count
        let y = Double(bitti) / Double(max(1, bl.konular.count))
        let kartBurada = !hizli && bl.konular.contains { $0.no == secili }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(bolumNo(bl)).font(Yazi.okuma(17, italik: true))
                    .foregroundStyle(Color(tam ? r.zemin : r.murekkep))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(tam ? Color(r.vurgu).opacity(0.9) : .clear))
                    .overlay(Circle().strokeBorder(tam ? .clear : Color(r.vurgu).opacity(0.55), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(bl.ad).font(Yazi.okuma(18)).lineLimit(2).foregroundStyle(Color(r.murekkep))
                    Text("\(bitti)/\(bl.konular.count) konu".uppercased(with: Locale(identifier: "tr_TR")))
                        .font(Yazi.sans(11, agirlik: 600, stil: .caption2)).tracking(0.88)
                        .foregroundStyle(Color(r.murekkep2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().stroke(Color(r.kenar), lineWidth: 4.5)
                    Circle().trim(from: 0, to: y).stroke(Color(r.vurgu).opacity(0.95), lineWidth: 4.5)
                        .rotationEffect(.degrees(-90))
                }
                .padding(2.25)
                .frame(width: 36, height: 36)
                .accessibilityLabel("%\(Int((y * 100).rounded()))")
            }
            .padding(.bottom, 10)
            .accessibilityElement(children: .combine)
            ScrollViewReader { kaydir in
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(bl.konular) { x in kitap(x).id(x.no) }
                    }
                    .padding(.horizontal, BenOlcu.yan)
                    .padding(.top, 14).padding(.bottom, 18)
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .padding(.horizontal, -BenOlcu.yan)
                .onAppear {
                    // sıradaki konunun salonunda şerit o kitaba kayar
                    if let s = bilgi.siradaki?.no, bl.konular.contains(where: { $0.no == s }) {
                        kaydir.scrollTo(s, anchor: .leading)
                    }
                }
            }
            if kartBurada, let x = bl.konular.first(where: { $0.no == secili }) {
                KonuKarti(bilgi: bilgi, konu: x, isaretle: isaretle, sanatciAc: sanatciAc)
                    .transition(.asymmetric(insertion: .scale(scale: 0.96, anchor: .top).combined(with: .opacity), removal: .opacity))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bölüm \(bolumNo(bl)): \(bl.ad)")
    }

    private func kitap(_ x: Konu) -> some View {
        let r = tema.renkler
        let l = bilgi.sanatcilar(x.no)
        let isl = bilgi.islenen.contains(x.no)
        let sira = x.no == bilgi.siradaki?.no
        let sec = secili == x.no && !hizli
        let kapak = bilgi.kapak(x)
        return Button {
            if hizli { return isaretle([x.no], !isl, true) }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.35)) { secili = secili == x.no ? nil : x.no }
        } label: {
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    LinearGradient(colors: [Color(r.yuzey), Color(r.zemin)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    RadialGradient(colors: [Color(r.vurgu).opacity(0.38), .clear], center: UnitPoint(x: 0.25, y: 0.15),
                                   startRadius: 0, endRadius: 120)
                    if let kapak {
                        UzakGorsel(url: kapak)
                            .scaleEffect(sec ? 1.14 : 1.06)
                            .grayscale(isl ? 0 : sira ? 0.35 : 1)
                            .colorMultiply(Color(white: isl ? 1 : sira ? 0.8 : 0.66))
                    }
                }
                LinearGradient(stops: [.init(color: .black.opacity(0.28), location: 0), .init(color: .clear, location: 0.24),
                                       .init(color: .clear, location: 0.58), .init(color: .black.opacity(0.78), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 0) {
                    Text(bilgi.baslik(x)).font(Yazi.okuma(13, stil: .caption1)).lineLimit(2)
                        .shadow(color: .black.opacity(0.85), radius: 1.5, y: 1)
                        .padding(.horizontal, 10)
                    Text(l.isEmpty ? " " : "\(l.count) sanatçı".uppercased(with: Locale(identifier: "tr_TR")))
                        .font(Yazi.sans(9, agirlik: 600, stil: .caption2)).tracking(0.72).opacity(0.65)
                        .padding(.horizontal, 10).padding(.top, 4).padding(.bottom, 10)
                }
                .foregroundStyle(kitapYazisi)
            }
            .overlay(alignment: .topLeading) {
                Text("\(x.no)").font(Yazi.okuma(21)).foregroundStyle(kitapYazisi).opacity(0.9)
                    .shadow(color: .black.opacity(0.75), radius: 3, y: 1)
                    .padding(.top, 6).padding(.leading, 10)
            }
            .overlay(alignment: .topTrailing) {
                if isl || !sira {
                    BenIkon(simge: isl ? .dogru : .kilit, boyut: isl ? 14 : 13, kalinlik: isl ? 2 : 1.8)
                        .foregroundStyle(isl ? Color(r.zemin) : kitapYazisi)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(isl ? Color(r.vurgu).opacity(0.95) : .black.opacity(0.45)))
                        .padding(10)
                }
            }
            .overlay(alignment: .topLeading) {
                if sira {
                    Text("Sıradaki".uppercased(with: Locale(identifier: "tr_TR")))
                        .font(Yazi.sans(10, agirlik: 700, stil: .caption2)).tracking(1)
                        .foregroundStyle(Color(r.zemin))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color(r.vurgu).opacity(0.95)))
                        .padding(.top, 38).padding(.leading, 10)
                }
            }
            .frame(width: sira ? 156 : 132, height: 178)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(sec ? Color(r.murekkep) : isl || sira ? Color(r.vurgu).opacity(isl ? 0.9 : 1) : Color(r.notrKenar),
                            lineWidth: sec || isl || sira ? 2 : 1)
            )
            .shadow(color: sira ? Color(r.vurgu).opacity(0.55) : .black.opacity(0.7), radius: sira ? 13 : 8, y: sira ? 0 : 8)
            .offset(y: sec ? -8 : 0)
            .scaleEffect(sec ? 1.03 : 1)
        }
        .buttonStyle(BasincBicimi())
        .accessibilityLabel("Konu \(x.no): \(bilgi.baslik(x))\(isl ? ", işlendi" : "")")
        .accessibilityAddTraits(sec ? [.isSelected] : [])
    }
}

/// `konuKarti`: seçili konunun başlığı, sanatçı portreleri, "İşlendi" anahtarı ve "1–n arası hepsi işlendi"
struct KonuKarti: View {
    let bilgi: KursBilgisi
    let konu: Konu
    let isaretle: ([Int], Bool, Bool) -> Void
    let sanatciAc: (String) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let l = bilgi.sanatcilar(konu.no)
        let acik = bilgi.islenen.contains(konu.no)
        let oncekiAcik = bilgi.konular.contains { $0.no <= konu.no && !bilgi.islenen.contains($0.no) }
        let baslik = bilgi.baslik(konu)
        HStack(alignment: .top, spacing: 14) {
            Text("\(konu.no)").font(Yazi.serif(48)).foregroundStyle(Color(r.murekkep2))
            VStack(alignment: .leading, spacing: 3) {
                Text(baslik).font(Yazi.okuma(19)).foregroundStyle(Color(r.murekkep))
                    .fixedSize(horizontal: false, vertical: true)
                if baslik != konu.baslik {
                    Text(konu.baslik).font(Yazi.sans(12.5, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                        .environment(\.locale, Locale(identifier: "en"))
                }
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        if l.isEmpty {
                            Text("Bu konuda yeni sanatçı yok").font(Yazi.sans(13, stil: .footnote).italic())
                                .foregroundStyle(Color(r.murekkep3))
                        }
                        ForEach(l) { s in portre(s, acik: acik) }
                    }
                    .padding(.vertical, 4).padding(.trailing, 16).padding(.leading, 2)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 10).padding(.trailing, -16)
                Toggle(isOn: Binding(get: { acik }, set: { isaretle([konu.no], $0, true) })) {
                    Text("İşlendi").font(Yazi.sans(15, agirlik: 600))
                }
                .toggleStyle(AnahtarBicimi(murekkep: true))
                .frame(minHeight: 44)
                .accessibilityLabel("Konu \(konu.no) işlendi")
                if oncekiAcik {
                    Button {
                        isaretle(bilgi.konular.filter { $0.no <= konu.no }.map(\.no), true, false)
                    } label: {
                        Text("1–\(konu.no) arası hepsi işlendi").font(Yazi.sans(15, agirlik: 500)).underline()
                            .foregroundStyle(Color(r.murekkep))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(LinearGradient(stops: [.init(color: Color(r.vurgu).opacity(0.12), location: 0), .init(color: .clear, location: 0.6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color(r.vurgu).opacity(0.4), lineWidth: 1))
        .padding(.top, 2)
    }

    private func portre(_ s: Sanatci, acik: Bool) -> some View {
        let r = tema.renkler
        let ad = bilgi.katalog.bilinenAd(s.id) ?? s.ad
        let icerik = VStack(alignment: .leading, spacing: 6) {
            UzakGorsel(url: bilgi.kucuk(s.id))
                .grayscale(acik ? 0 : 1).colorMultiply(Color(white: acik ? 1 : 0.6))
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(acik ? Color(r.vurgu).opacity(0.7) : Color(r.kenar), lineWidth: acik ? 2 : 1))
            Text(ad).font(Yazi.sans(12, agirlik: 500, stil: .caption1)).lineLimit(2)
                .foregroundStyle(Color(acik ? r.murekkep : r.murekkep3))
        }
        .frame(width: 72, alignment: .leading)
        return Group {
            if acik {
                Button { sanatciAc(s.id) } label: { icerik }.buttonStyle(BasincBicimi())
            } else {
                icerik
            }
        }
    }
}

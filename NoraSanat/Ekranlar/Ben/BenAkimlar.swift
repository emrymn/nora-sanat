// Kaynak: sanat-atlasi js/ekranlar/ilerleme.js (parcalar: akım kartları, cevapsız akımlar, karisanlarBolumu, zayıflar,
// tanisKartiHtml), js/ekranlar/pano.js, css/app.css (.akim-kart, .cevapsiz-akimlar, .hatalar-satir, .zayif-liste,
// .tanis-karti) @ a866b86
import NoraCekirdek
import SwiftUI

/// "Akımlara göre doğruluk": cevaplanmış akımlar resimli kart, cevapsızlar küçük hap
struct AkimBolumu: View {
    let pano: BenPanosu
    let il: Ilerleme
    let katalog: SiteKatalogu
    @Binding var zayifOnce: Bool
    let ac: (String) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let sira = zayifOnce ? pano.akimlar.sorted { ($0.oran ?? 2) < ($1.oran ?? 2) } : pano.akimlar
        let satirlar = sira.filter { $0.toplam > 0 }
        let cevapsiz = sira.filter { $0.toplam == 0 }
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Etiket("Akımlara göre doğruluk").accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if satirlar.count > 1 {
                    KucukHap(secenekler: [(false, "Sırayla"), (true, "Zayıf önce")], secili: $zayifOnce)
                        .accessibilityLabel("Akımları sırala")
                }
            }
            .padding(.top, 28).padding(.bottom, 10)
            if !satirlar.isEmpty {
                VStack(spacing: 10) { ForEach(satirlar) { kart($0) } }
            }
            if !cevapsiz.isEmpty {
                Text(satirlar.isEmpty ? "\(cevapsiz.count) açık akımda henüz cevap yok · dokun, o dönemin turu başlasın"
                                      : "Henüz cevap vermediğin \(cevapsiz.count) akım · dokun, o dönemin turu başlasın")
                    .font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                    .padding(.top, satirlar.isEmpty ? 0 : 14)
                AkisDuzeni(aralik: 6) {
                    ForEach(cevapsiz) { a in
                        Button { ac(a.id) } label: {
                            HStack(spacing: 7) {
                                AkimNoktasi(renk: katalog.akimRenk[a.id] ?? "")
                                Text(a.id).font(Yazi.sans(13.5, agirlik: 500, stil: .footnote))
                            }
                            .foregroundStyle(Color(r.murekkep))
                            .padding(.horizontal, 14).frame(minHeight: 44)
                            .overlay(Capsule().strokeBorder(Color(r.kenar), lineWidth: 1))
                            .contentShape(Capsule())
                        }
                        .buttonStyle(BasincBicimi())
                    }
                }
                .padding(.top, 8).padding(.bottom, 18)
            }
            if satirlar.isEmpty && cevapsiz.isEmpty {
                Text("Henüz açık akım yok.").font(Yazi.sans(15)).foregroundStyle(Color(r.murekkep2))
            }
        }
    }

    /// `.akim-kart`: sağda dönemin bir eseri, adı, seviyesi, yüzdesi, çubuğu ve alt satır
    private func kart(_ a: AkimBasarisi) -> some View {
        let r = tema.renkler
        let kayit = Seviye.kayit(il.seviyeler, a.id)
        let sv = Seviye.bul(kayit.s)
        let y = a.oran.map { Int(($0 * 100).rounded()) }
        let alt = ["\(a.dogru)/\(a.toplam) doğru", "\(a.sanatci) sanatçı", a.vade > 0 ? "\(a.vade) tekrar" : "",
                   a.kalici > 0 ? "\(a.kalici) kalıcı" : ""].filter { !$0.isEmpty }.joined(separator: " · ")
        let tl = il.acikSanatcilar(katalog.sanatcilar).filter { $0.akim == a.id }
        let tm = tl.first { $0.kaynak == "kurs" } ?? tl.first
        let resim = tm.flatMap { katalog.eserler($0.id).first }.flatMap { katalog.gorselAdresi($0, genislik: 500, kotuler: il.kotuGorseller) }
        return Button { ac(a.id) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    AkimNoktasi(renk: katalog.akimRenk[a.id] ?? "")
                    Text(a.id).font(Yazi.okuma(22)).lineLimit(2).foregroundStyle(Color(r.murekkep))
                    seviyeEtiketi(sv)
                    Spacer(minLength: 0)
                    Text(y.map { "%\($0)" } ?? "–").font(Yazi.serif(24)).foregroundStyle(Color(r.murekkep))
                }
                OranCubugu(oran: a.oran ?? 0)
                HStack(spacing: 10) {
                    Text(alt).font(Yazi.sans(12.5, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                    Spacer(minLength: 0)
                    SeviyeIzi(kayit: kayit, genislik: 60)
                }
            }
            .padding(16)
            .background {
                ZStack {
                    Color(r.yuzey)
                    if let resim {
                        GeometryReader { g in
                            UzakGorsel(url: resim)
                                .frame(width: g.size.width * 0.6, height: g.size.height)
                                .overlay(LinearGradient(stops: [.init(color: Color(r.yuzey), location: 0),
                                                                .init(color: Color(r.yuzey).opacity(0.7), location: 0.5),
                                                                .init(color: Color(r.zemin).opacity(0.3), location: 1)],
                                                        startPoint: .leading, endPoint: .trailing))
                                .clipped()
                                .offset(x: g.size.width * 0.4)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(BasincBicimi(olcek: 0.985))
        .accessibilityLabel("\(a.id), \(sv.ad), \(y.map { "yüzde \($0) doğru" } ?? "veri yok"), \(alt)")
    }

    /// `.seviye-etiket.sv-*`
    private func seviyeEtiketi(_ sv: Seviye.Tanim) -> some View {
        let r = tema.renkler
        let renk: Color = switch sv.anahtar {
        case "orta": Color(r.vurguYazi)
        case "zor": Color(r.vurguAcikYazi)
        default: Color(r.murekkep2)
        }
        return Text(sv.ad).font(Yazi.sans(11, agirlik: 500, stil: .caption2)).lineLimit(1)
            .foregroundStyle(renk)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(sv.anahtar == "zor" ? Color(r.vurguAcik) : .clear))
            .overlay(Capsule().strokeBorder(sv.anahtar == "zor" ? .clear : sv.anahtar == "orta" ? renk : Color(r.kenar), lineWidth: 1))
            .fixedSize()
    }
}

/// "En çok karıştırdıkların" ve "En zayıf sanatçılar"
struct ZayifBolumu: View {
    let pano: BenPanosu
    let il: Ilerleme
    let katalog: SiteKatalogu
    let hatalar: Int
    let kucuk: (String) -> URL?
    let git: (String, Sekme) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let ikililer = Ogrenme.enCok(il.karisanlarSirali, varMi: { katalog.harita[$0] != nil })
        VStack(alignment: .leading, spacing: 0) {
            if !ikililer.isEmpty {
                BolumBasligi("En çok karıştırdıkların")
                liste(ikililer.indices.map { i in
                    let x = ikililer[i]
                    return AnyView(satir(baslik: "\(katalog.bilinenAd(x.a) ?? x.a) ↔ \(katalog.bilinenAd(x.b) ?? x.b)",
                                         alt: "\(x.n) kez karıştırdın · yan yana bak", simge: .karsilastir) {
                        git("#/karsilastir/\(x.a)/\(x.b)", .galeri)
                    })
                })
            }
            BolumBasligi("En zayıf sanatçılar")
            if hatalar > 0 {
                Button { git("#/pekistir/hatalar", .calis) } label: {
                    HStack(spacing: 14) {
                        Text("\(hatalar)").font(Yazi.serif(44)).foregroundStyle(Color(r.yanlis))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hatalarım turu").font(Yazi.okuma(19)).foregroundStyle(Color(r.murekkep))
                            Text("son 7 günün yanlışları tek turda").font(Yazi.sans(13.5, stil: .footnote))
                                .foregroundStyle(Color(r.murekkep2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        BenIkon(simge: .ileri, boyut: 20, kalinlik: 1.4).foregroundStyle(Color(r.murekkep3))
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { Ayrac(renk: \.murekkep) }
                    .overlay(alignment: .bottom) { Ayrac() }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 4).padding(.bottom, 6)
            }
            if pano.zayiflar.isEmpty {
                Text("Henüz zayıf sanatçı yok — biraz pekiştir.").font(Yazi.sans(13, stil: .footnote))
                    .foregroundStyle(Color(r.murekkep2))
            } else {
                liste(pano.zayiflar.map { z in
                    AnyView(zayif(z))
                })
            }
        }
    }

    private func liste(_ satirlar: [AnyView]) -> some View {
        VStack(spacing: 0) {
            Ayrac()
            ForEach(satirlar.indices, id: \.self) { i in
                satirlar[i]
                Ayrac()
            }
        }
    }

    private func satir(baslik: String, alt: String, simge: BenSimge, eylem: @escaping () -> Void) -> some View {
        let r = tema.renkler
        return Button(action: eylem) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(baslik).font(Yazi.serif(22)).foregroundStyle(Color(r.murekkep))
                    Text(alt).font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BenIkon(simge: simge, boyut: 20, kalinlik: 1.4).foregroundStyle(Color(r.murekkep3))
            }
            .padding(.vertical, 10).frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func zayif(_ z: SanatciBasarisi) -> some View {
        let r = tema.renkler
        let y = Int((z.oran * 100).rounded())
        return Button { git("#/sanatci/" + z.id, .galeri) } label: {
            HStack(spacing: 14) {
                UzakGorsel(url: kucuk(z.id))
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(katalog.harita[z.id]?.ad ?? z.id).font(Yazi.serif(22)).foregroundStyle(Color(r.murekkep))
                    Text("%\(y) doğru · \(z.dogru)/\(z.toplam)").font(Yazi.sans(13, stil: .footnote))
                        .foregroundStyle(Color(r.murekkep2))
                    HStack(spacing: 10) {
                        OranCubugu(oran: z.oran, yukseklik: 3, renk: \.yanlis)
                        KutuPip(kutu: z.kutu)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BenIkon(simge: .ileri, boyut: 20, kalinlik: 1.4).foregroundStyle(Color(r.murekkep3))
            }
            .padding(.vertical, 10).frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(katalog.harita[z.id]?.ad ?? z.id), yüzde \(y) doğru")
    }
}

/// Ö6 · Konu işlenince alttan kart: "4 yeni sanatçı açıldı · Tanış" → #/pekistir/konu/<no>
struct TanisKarti: View {
    struct Veri: Equatable {
        let no: Int
        let idler: [String]
    }
    let veri: Veri
    let katalog: SiteKatalogu
    let kucuk: (String) -> URL?
    let tanis: () -> Void
    let kapat: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let l = veri.idler.compactMap { katalog.harita[$0] }
        HStack(spacing: 10) {
            HStack(spacing: -12) {
                ForEach(Array(l.prefix(4).enumerated()), id: \.offset) { i, s in
                    UzakGorsel(url: kucuk(s.id))
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color(r.murekkep), lineWidth: 2))
                        .rotationEffect(.degrees((Double(i) - 1.5) * 6))
                }
            }
            .padding(.leading, 10)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(l.count) yeni sanatçı açıldı").font(Yazi.okuma(16))
                Text("Konu \(veri.no) · " + l.map { katalog.bilinenAd($0.id) ?? $0.ad }.joined(separator: ", "))
                    .font(Yazi.sans(12.5, stil: .footnote)).opacity(0.75).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: tanis) {
                Text("Tanış").font(Yazi.sans(15, agirlik: 650))
                    .foregroundStyle(Color(r.murekkep))
                    .padding(.horizontal, 16).frame(minHeight: 44)
                    .background(Capsule().fill(Color(r.zemin)))
            }
            .buttonStyle(BasincBicimi())
            Button(action: kapat) {
                BenIkon(simge: .kapat, boyut: 18, kalinlik: 1.7).frame(width: 36, height: 44).opacity(0.7)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kapat")
        }
        .foregroundStyle(Color(r.zemin))
        .padding(.vertical, 10).padding(.leading, 12).padding(.trailing, 4)
        .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color(r.murekkep)))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        .frame(maxWidth: 520)
        .padding(.horizontal, 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Yeni açılan sanatçılar")
    }
}

/// Satır satır akan düzen (`flex-wrap: wrap`)
struct AkisDuzeni: Layout {
    var aralik: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let genislik = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, satir: CGFloat = 0, enGenis: CGFloat = 0
        for s in subviews {
            let b = s.sizeThatFits(.unspecified)
            if x > 0 && x + b.width > genislik { x = 0; y += satir + aralik; satir = 0 }
            x += b.width + aralik
            satir = max(satir, b.height)
            enGenis = max(enGenis, x - aralik)
        }
        return CGSize(width: min(enGenis, genislik), height: y + satir)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, satir: CGFloat = 0
        for s in subviews {
            let b = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + b.width > bounds.maxX { x = bounds.minX; y += satir + aralik; satir = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(b))
            x += b.width + aralik
            satir = max(satir, b.height)
        }
    }
}

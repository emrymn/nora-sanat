// Z4h · Hikâyeler'e "Diziler" rafı: kapak kolajı, ana ekrandaki dizi kartı ve dizi sayfası.
// Renkler TemaRenkleri'nden (Emre'nin Gece/Gündüz paleti), zemin SayfaZemini halesi ve dönem deseniyle.
import NoraCekirdek
import SwiftUI

// MARK: - Kapak kolajı

/// Dizideki bölümlerin eserlerinden 3'lü editoryal kolaj (2 eserde ikili, 1 eserde tek kapak).
struct DiziKolaj: View {
    let eserler: [HikayeEserBilgisi]
    var yukseklik: CGFloat = 176
    var kose: CGFloat = 16

    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let aralik: CGFloat = 2
            Group {
                switch eserler.count {
                case 0:
                    ZStack {
                        c.yuzey
                        LinearGradient(
                            colors: [c.pirinc.opacity(0.18), c.zemin.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "books.vertical")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(c.pirinc.opacity(0.65))
                    }
                case 1:
                    parca(eserler[0], w: w, h: h)
                case 2:
                    let yarim = (w - aralik) / 2
                    HStack(spacing: aralik) {
                        parca(eserler[0], w: yarim, h: h)
                        parca(eserler[1], w: yarim, h: h)
                    }
                default:
                    let solW = (w - aralik) * 0.57
                    let sagW = w - aralik - solW
                    let sagH = (h - aralik) / 2
                    HStack(spacing: aralik) {
                        parca(eserler[0], w: solW, h: h)
                        VStack(spacing: aralik) {
                            parca(eserler[1], w: sagW, h: sagH)
                            parca(eserler[2], w: sagW, h: sagH)
                        }
                    }
                }
            }
            .background(c.zemin)
        }
        .frame(height: yukseklik)
        .clipShape(RoundedRectangle(cornerRadius: kose, style: .continuous))
    }

    private func parca(_ e: HikayeEserBilgisi, w: CGFloat, h: CGFloat) -> some View {
        UzakGorsel(url: e.url, icerik: .fill, yedek: e.yedek, odak: [50, 14])
            .frame(width: max(1, w), height: max(1, h))
            .clipped()
    }
}

// MARK: - Ana ekrandaki dizi kartı

/// HikayeAna'daki "Diziler" rafında tek bir dizi kartı.
/// Tek dizi varken tam içerik genişliğine yayılır, birden çok dizi varken yatay kaydırılır.
struct DiziKarti: View {
    let dizi: Dizi
    let genislik: CGFloat
    let ac: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let kapaklar = depo.diziKapaklari(dizi, enCok: 3, genislik: 800)
        let ilerleme = depo.diziIlerleme(dizi)
        let toplamDk = depo.diziOkumaDakikasi(dizi)

        Button { ac(dizi.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                DiziKolaj(eserler: kapaklar, yukseklik: 184, kose: 14)
                    .overlay(alignment: .bottomLeading) {
                        durumHapi(ilerleme: ilerleme, c: c)
                            .padding(10)
                    }
                    .padding(10)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(ilerleme.toplam) bölüm · ~\(toplamDk) dk okuma")
                        .font(Yazi.sans(12, agirlik: 600))
                        .foregroundStyle(c.pirinc)

                    Text(dizi.ad)
                        .font(Yazi.okuma(22, agirlik: 600, stil: .title2))
                        .tracking(-0.35)
                        .foregroundStyle(c.yazi)
                        .lineLimit(1)
                        .padding(.top, 3)

                    if !dizi.aciklama.isEmpty {
                        Text(dizi.aciklama)
                            .font(Yazi.sans(13.5, stil: .subheadline))
                            .cssSatir(.sans, 13.5, 19.5)
                            .foregroundStyle(c.yazi2)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5)
                    }

                    if ilerleme.baslandi {
                        HikayeCizgi(oran: ilerleme.oran, bitti: ilerleme.bitti, yukseklik: 3)
                            .padding(.top, 12)
                    }

                    HStack(spacing: 6) {
                        Text(ilerleme.bitti ? "Yeniden göz at" : (ilerleme.baslandi ? "Kaldığın yerden devam et" : "Bölümleri gör"))
                            .font(Yazi.sans(13, agirlik: 600))
                            .foregroundStyle(c.yazi)
                        Spacer(minLength: 4)
                        HikayeIkon(simge: .ileri, boyut: 15, kalinlik: 1.8)
                            .foregroundStyle(c.pirinc)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 2)
            }
            .frame(width: genislik, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(c.yuzey.opacity(tema.renkler.koyu ? 0.9 : 0.96))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(c.kenar, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dizi.ad) dizisi, \(ilerleme.toplam) bölüm. \(dizi.aciklama)")
        .accessibilityHint("Dizi sayfasını açar")
        .accessibilityIdentifier("dizi-\(dizi.id)")
    }

    private func durumHapi(ilerleme: DiziIlerleme, c: HikayeRenk) -> some View {
        let metin: String
        let renk: Color
        if ilerleme.bitti {
            metin = "Okundu"
            renk = c.dogru
        } else if ilerleme.baslandi {
            metin = "\(ilerleme.okunan) / \(ilerleme.toplam) okundu"
            renk = c.pirinc
        } else {
            metin = "Dizi · \(ilerleme.toplam) bölüm"
            renk = .black.opacity(0.62)
        }
        return Text(metin)
            .font(Yazi.sans(11, agirlik: 600))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background {
                if !ilerleme.baslandi {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(renk)
                    }
                } else {
                    Capsule().fill(renk)
                }
            }
    }
}

// MARK: - Dizi sayfası

/// Diziye dokununca açılan sayfa: kapak kolajı, başlık, açıklama ve bölümler sırayla.
struct DiziSayfasi: View {
    let dizi: Dizi
    let bolumAc: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared
    @State private var ustCubukAcik = false

    private var hareketKapali: Bool { hareketAz || tema.ayar.hareketAzaltilmis }

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let bolumler = depo.diziBolumleri(dizi.id)
        let ilerleme = depo.diziIlerleme(dizi)
        let kapaklar = depo.diziKapaklari(dizi, enCok: 3, genislik: 1280)
        let toplamDk = depo.diziOkumaDakikasi(dizi)
        let siradaki = depo.siradakiBolum(dizi)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Kapak kolajı + kaydırma eşiği
                DiziKolaj(eserler: kapaklar, yukseklik: 212, kose: 18)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(c.kenar, lineWidth: 1)
                    }
                    .padding(.top, 60)
                    .onGeometryChange(for: Bool.self) { proxy in
                        proxy.frame(in: .named("dizi-kaydir")).maxY < 110
                    } action: { acik in
                        if acik != ustCubukAcik {
                            withAnimation(hareketKapali ? nil : .easeOut(duration: 0.2)) {
                                ustCubukAcik = acik
                            }
                        }
                    }

                // Başlık ve açıklama
                VStack(alignment: .leading, spacing: 0) {
                    Text("Dizi · \(bolumler.count) bölüm · ~\(toplamDk) dk okuma")
                        .font(Yazi.sans(12.5, agirlik: 600))
                        .foregroundStyle(c.pirinc)
                        .padding(.top, 20)

                    Text(dizi.ad)
                        .font(Yazi.okuma(31, agirlik: 600, stil: .largeTitle))
                        .tracking(-0.62)
                        .cssSatir(.okuma, 31, 31 * 1.15)
                        .foregroundStyle(c.yazi)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)

                    if !dizi.aciklama.isEmpty {
                        Text(dizi.aciklama)
                            .font(Yazi.sans(15.5, stil: .body))
                            .cssSatir(.sans, 15.5, 23)
                            .foregroundStyle(c.yazi2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }

                    if ilerleme.baslandi {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(ilerleme.bitti ? "Tüm bölümler okundu" : "\(ilerleme.okunan) / \(ilerleme.toplam) bölüm okundu")
                                    .font(Yazi.sans(12.5, agirlik: 600))
                                    .foregroundStyle(ilerleme.bitti ? c.dogru : c.pirinc)
                                Spacer()
                                Text("%\(Int((ilerleme.oran * 100).rounded()))")
                                    .font(Yazi.sans(12))
                                    .monospacedDigit()
                                    .foregroundStyle(c.yazi3)
                            }
                            HikayeCizgi(oran: ilerleme.oran, bitti: ilerleme.bitti, yukseklik: 3)
                        }
                        .padding(.top, 16)
                    }

                    if let ilk = siradaki {
                        Button {
                            Titresim.secim()
                            bolumAc(ilk.id)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(ilerleme.baslandi && !ilerleme.bitti ? "\(ilk.sira). bölüme devam et" : "1. bölümden başla")
                                    .font(Yazi.sans(14.5, agirlik: 600))
                            }
                            .foregroundStyle(c.zemin)
                            .padding(.horizontal, 22)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(c.yazi))
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 18)
                        .accessibilityIdentifier("dizi-basla")
                    }
                }

                // Ayraç ve bölüm listesi
                Rectangle()
                    .fill(c.kenar)
                    .frame(height: 1)
                    .padding(.top, 26)
                    .padding(.bottom, 22)

                HStack(alignment: .firstTextBaseline) {
                    Text("Bölümler")
                        .font(Yazi.okuma(21, agirlik: 600, stil: .title2))
                        .tracking(-0.3)
                        .foregroundStyle(c.yazi)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(bolumler.count) bölüm")
                        .font(Yazi.sans(12.5))
                        .foregroundStyle(c.yazi3)
                }
                .padding(.bottom, 14)

                VStack(spacing: 14) {
                    ForEach(bolumler) { b in
                        bolumKarti(b, c: c)
                    }
                }
                .padding(.bottom, calar.acik ? 110 : 44)
            }
            .padding(.horizontal, 22)
        }
        .coordinateSpace(name: "dizi-kaydir")
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: depo.diziDonem(dizi), tablo: depo.diziZeminTablosu(dizi), alan: .hikayeler))
        .overlay(alignment: .top) { ustCubuk(c) }
        .accessibilityIdentifier("dizi-sayfasi-\(dizi.id)")
    }

    // MARK: Üst çubuk

    private func ustCubuk(_ c: HikayeRenk) -> some View {
        HStack(spacing: 8) {
            Button { kapat() } label: { HikayeIkon(simge: .geri, boyut: 20, kalinlik: 1.8) }
                .buttonStyle(HikayeCamDugme())
                .accessibilityLabel("Hikâyelere dön")
            Text(dizi.ad)
                .font(Yazi.serif(16, agirlik: 500))
                .foregroundStyle(c.yazi)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .opacity(ustCubukAcik ? 1 : 0)
                .accessibilityHidden(!ustCubukAcik)
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background {
            ZStack(alignment: .bottom) {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(c.cam)
                Rectangle().fill(c.kenar).frame(height: 1)
            }
            .ignoresSafeArea(edges: .top)
            .opacity(ustCubukAcik ? 1 : 0)
        }
        .animation(hareketKapali ? nil : .easeOut(duration: 0.22), value: ustCubukAcik)
    }

    // MARK: Bölüm satırı

    private func bolumKarti(_ b: DiziBolumu, c: HikayeRenk) -> some View {
        let s = depo.satir(b.hikaye)
        let durum = depo.bolumDurumu(b)
        let yer = depo.yer(b.id)
        let dinlenebilir = depo.dinlenebilir(b.hikaye)
        let sureMetni = dinlenebilir ? "\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme" : "\(s.okumaDk) dk okuma"

        return Button {
            Titresim.secim()
            bolumAc(b.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 14) {
                    UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 16])
                        .frame(width: 72, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            Text(String(format: "%02d", b.sira))
                                .font(Yazi.sans(11, agirlik: 700))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .frame(height: 20)
                                .background(Capsule().fill(.black.opacity(0.62)))
                                .padding(6)
                        }

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text("\(b.sira). bölüm")
                                .font(Yazi.sans(12, agirlik: 600))
                                .foregroundStyle(c.pirinc)
                            Spacer(minLength: 4)
                            bolumDurumRozeti(durum, c: c)
                        }

                        Text(b.baslik)
                            .font(Yazi.okuma(18, agirlik: 600))
                            .cssSatir(.okuma, 18, 18 * 1.24)
                            .foregroundStyle(c.yazi)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 3)

                        if !b.altBaslik.isEmpty {
                            Text(b.altBaslik)
                                .font(Yazi.sans(13))
                                .cssSatir(.sans, 13, 18)
                                .foregroundStyle(c.yazi2)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 3)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.sanatci)
                                .font(Yazi.sans(12, agirlik: 500))
                                .foregroundStyle(c.yazi2)
                                .lineLimit(1)
                            Text(sureMetni)
                                .font(Yazi.sans(11.5))
                                .foregroundStyle(c.yazi3)
                                .lineLimit(1)
                        }
                        .padding(.top, 7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let y = yer, y.yarim {
                    HikayeCizgi(oran: y.oran, yukseklik: 2.5)
                }
            }
            .padding(13)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(c.yuzey.opacity(tema.renkler.koyu ? 0.88 : 0.95))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(c.kenar, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(b.sira). bölüm: \(b.baslik). \(s.sanatci). \(sureMetni)")
        .accessibilityHint("Bölümü açar")
        .accessibilityIdentifier("bolum-\(b.id)")
    }

    @ViewBuilder
    private func bolumDurumRozeti(_ d: DiziKurallari.BolumDurumu, c: HikayeRenk) -> some View {
        switch d {
        case .okundu:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Okundu")
                    .font(Yazi.sans(11.5, agirlik: 600))
            }
            .foregroundStyle(c.dogru)
        case .yarim(let dk, let dinleme):
            HStack(spacing: 4) {
                Image(systemName: dinleme ? "headphones" : "book")
                    .font(.system(size: 10.5, weight: .semibold))
                Text("\(dk) dk kaldı")
                    .font(Yazi.sans(11.5, agirlik: 600))
            }
            .foregroundStyle(c.pirinc)
        case .okunmadi:
            EmptyView()
        }
    }
}

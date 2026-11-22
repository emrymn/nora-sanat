// Kaynak: sanat-atlasi js/ekranlar/ders.js (ogrenAdimi, ogrenCiz, ogrenIleri, olaylariBagla: data-ogren-*), css/app.css
// (.ders-ogren, .ders-kanit-buyuk, .ders-madde, .ders-kanit, .ders-kanit-yok, .ders-kanit-serit, .ders-aciklama) @ a866b86
// Öğren: her "Nasıl tanınır?" maddesi bir sayfa. Doğrulanmış kanıtın eseri ve cümlesi, altında maddeyi açıklayan cümleler;
// doğrulanmış kanıtı olmayan madde eser göstermeden, yalnız metinle anlatılır.
import NoraCekirdek
import SwiftUI

/// Tam ekran görüntüleyiciye giden eserler
struct DersGosterimi: Identifiable {
    let id = UUID()
    let eserler: [Eser]
    let baslangic: Int
}

@MainActor
struct DersOgrenAdimi: View {
    let model: PekistirmeModeli
    let b: DersBilgisi
    let geri: () -> Void
    let bitir: () -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var konum = 0
    @State private var gorulen = 0
    @State private var secili = 0
    @State private var basladi = false
    @State private var gosterim: DersGosterimi?

    private var hareketAz: Bool { tema.ayar.hareketAzaltilmis }

    var body: some View {
        let r = tema.renkler
        let d = DersRenkleri(r)
        let toplam = b.ogren.count
        let m = b.ogren[min(konum, toplam - 1)]
        let eserler = m.kanitlar.map(eseriBul)
        let sec = min(secili, max(0, m.kanitlar.count - 1))
        let kanit = m.kanitlar.indices.contains(sec) ? m.kanitlar[sec] : nil
        let eser = kanit != nil ? eserler[sec] : nil

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                DersAdimUst(
                    etiket: DersAdimKurallari.ustEtiketi(akim: b.akim, adim: .ogren, adimlar: b.adimlar),
                    baslik: DersAdimKurallari.ogrenBasligi(konum: konum, toplam: toplam),
                    durum: b.durum,
                    adim: .ogren,
                    geri: geri
                )
                .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 14) {
                    if let kanit {
                        // `.ders-kanit-buyuk`
                        let alt = altyazi(kanit.sanatci, kanit.eser, eser)
                        VStack(alignment: .leading, spacing: 6) {
                            if let eser {
                                Button {
                                    let cift = eserler.compactMap { $0 }
                                    gosterim = DersGosterimi(eserler: cift, baslangic: cift.firstIndex { $0.anahtar == eser.anahtar } ?? 0)
                                } label: {
                                    ZStack {
                                        Color(r.murekkep).karis(Color(r.zemin), 0.93)
                                        UzakGorsel(url: model.gorsel(eser, 960), icerik: .fit)
                                    }
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(alt) · büyüt")
                            }
                            Text(alt)
                                .font(Yazi.sans(13, stil: .footnote))
                                .cssSatir(.sans, 13, 17.55)
                                .foregroundStyle(Color(r.murekkep2))
                        }
                        .accessibilityIdentifier("ders-kanit-eser")
                    }

                    Text(m.madde)
                        .font(Yazi.serif(27))
                        .dersSatir(.serif, 27, 31.05)
                        .foregroundStyle(Color(r.murekkep))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("ders-madde")

                    if let kanit {
                        // `.ders-kanit`
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bu eserde")
                                .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                                .cssSatir(.sans, 13, 16.9)
                                .foregroundStyle(d.altinYazi)
                            Text(kanit.cumle)
                                .font(Yazi.okuma(17))
                                .cssSatir(.okuma, 17, 25.5)
                                .foregroundStyle(Color(r.murekkep).karis(Color(r.zemin), 0.12))
                        }
                        .padding(.top, 12).padding(.horizontal, 14).padding(.bottom, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                        .accessibilityIdentifier("ders-kanit")
                    } else {
                        Text("Bu özellik için doğrulanmış bir eser örneği henüz yok; şimdilik yalnız metinle.")
                            .font(Yazi.okuma(16, italik: true))
                            .cssSatir(.okuma, 16, 23.2)
                            .foregroundStyle(Color(r.murekkep2))
                            .accessibilityIdentifier("ders-kanit-yok")
                    }

                    if m.kanitlar.count > 1 {
                        serit(m, eserler: eserler, secili: sec)
                    }

                    if !m.aciklamalar.isEmpty {
                        // `.ders-aciklama`
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Açıklama")
                                .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                                .cssSatir(.sans, 13, 16.9)
                                .foregroundStyle(Color(r.murekkep2))
                            ForEach(m.aciklamalar, id: \.id) { a in
                                let kisa = a.sanatci.map(kisaAd) ?? ""
                                ((kisa.isEmpty ? Text("") : Text("\(kisa): ").font(Yazi.okuma(17, agirlik: 500)).foregroundStyle(Color(r.murekkep)))
                                    + Text(a.cumle).font(Yazi.okuma(17)).foregroundStyle(Color(r.murekkep).karis(Color(r.zemin), 0.12)))
                                    .cssSatir(.okuma, 17, 25.5)
                            }
                        }
                        .accessibilityIdentifier("ders-aciklama")
                    }
                }
                .id(konum)
                .transition(hareketAz ? .identity : .opacity.combined(with: .offset(y: 10)))
                .padding(.bottom, 92)
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.top, 12)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            DersAltCubuk {
                if konum > 0 {
                    Button("Geri") { git(konum - 1) }
                        .buttonStyle(DersDugme(tur: .bos))
                        .accessibilityIdentifier("ogren-geri")
                }
                Button { ileri() } label: {
                    Text(DersAdimKurallari.ogrenIleri(konum: konum, toplam: toplam)).frame(maxWidth: .infinity)
                }
                .buttonStyle(DersDugme(tur: .dolu))
                .accessibilityIdentifier("ogren-ileri")
            }
        }
        .accessibilityIdentifier("ders-ogren")
        .fullScreenCover(item: $gosterim) { g in
            Goruntuleyici(eserler: g.eserler, baslangic: g.baslangic).environment(tema)
        }
        .onAppear {
            guard !basladi else { return }
            basladi = true
            konum = CalisDersKurallari.kalinanYer(i: b.kayit.ogren.i, toplam: toplam)
            gorulen = DersAdimKurallari.gorulen(i: b.kayit.ogren.i, toplam: toplam)
            #if DEBUG
            Task {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                DersKarsilastirma.hazirYaz()
            }
            #endif
        }
    }

    // `.ders-kanit-serit`: aynı özellik başka eserlerde
    private func serit(_ m: OgrenMaddesi, eserler: [Eser?], secili: Int) -> some View {
        let r = tema.renkler
        let d = DersRenkleri(r)
        return HStack(alignment: .top, spacing: 10) {
            ForEach(Array(m.kanitlar.enumerated()), id: \.offset) { i, k in
                let s = i == secili
                Button {
                    var islem = Transaction()
                    islem.disablesAnimations = true
                    withTransaction(islem) { self.secili = i }
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack {
                            Color(r.yuzey)
                            if let e = eserler[i] {
                                UzakGorsel(url: model.gorsel(e, 330), icerik: .fill)
                            }
                        }
                        .frame(height: 72)
                        .clipped()
                        Text(kisaAd(k.sanatci))
                            .font(Yazi.sans(12, stil: .caption1))
                            .cssSatir(.sans, 12, 15)
                            .lineLimit(1)
                            .foregroundStyle(Color(s ? r.murekkep : r.murekkep2))
                            .padding(.top, 6).padding(.horizontal, 8).padding(.bottom, 7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(r.yuzey))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(s ? d.altinYazi : Color(r.kenar), lineWidth: s ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(altyazi(k.sanatci, k.eser, eserler[i]))
                .accessibilityAddTraits(s ? .isSelected : [])
            }
            ForEach(0..<max(0, 3 - m.kanitlar.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity, maxHeight: 1) }
        }
    }

    private func kisaAd(_ sid: String) -> String {
        model.katalog.map { DersAdimKurallari.kisaAd(sid, katalog: $0) } ?? ""
    }

    private func altyazi(_ sid: String, _ eserAdi: String, _ e: Eser?) -> String {
        DersAdimKurallari.kanitAltyazisi(kisaAd: kisaAd(sid), kanitEseri: eserAdi, eser: e)
    }

    /// `eseriBul(ref)`: sanatçının doğrulanmış eser listesinden (görseli olmayan sayılmaz)
    private func eseriBul(_ k: OgrenMaddesi.Kanit) -> Eser? {
        guard let katalog = model.katalog, katalog.harita[k.sanatci] != nil else { return nil }
        let ref = DersEserRef(sanatci: k.sanatci, eser: k.eser, qid: k.qid, anahtar: k.anahtar)
        return CalisDersKurallari.eserEslestir(katalog.eserler(k.sanatci), sid: k.sanatci, ref: ref)
    }

    private func git(_ yeni: Int) {
        guard b.ogren.indices.contains(yeni) else { return }
        if hareketAz {
            konum = yeni
            secili = 0
        } else {
            withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.4)) {
                konum = yeni
                secili = 0
            }
        }
    }

    /// `ogrenIleri`
    private func ileri() {
        let toplam = b.ogren.count
        let son = konum >= toplam - 1
        if let yeni = DersAdimKurallari.ilerle(konum: konum, gorulen: gorulen) {
            gorulen = yeni
            Task {
                await model.dersAdimiIsle(akim: b.akim, adim: .ogren, gorulen: yeni, toplam: toplam)
                if son { bitir() }
            }
            if son { return }
        } else if son {
            bitir()
            return
        }
        git(konum + 1)
    }
}

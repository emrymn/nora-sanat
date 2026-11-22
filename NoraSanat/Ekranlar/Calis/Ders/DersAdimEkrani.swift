// Kaynak: sanat-atlasi js/ekranlar/ders.js (dersiAl, gorAdimi, ogrenAdimi, ayirtAdimi, adimSonu, SON_YAZI,
// olaylariBagla: data-ders-gec), js/ekranlar/yonlendirme.js (#/pekistir/ders/<akım>/<adım>) @ a866b86
// Dersin bir adımı: Gör, Öğren ya da Ayırt et; adım bitince kapanış ekranı. Ders yoksa ya da kilitliyse ders sayfası
// (CalisDersSayfasi) kendi boş kutusunu gösterir.
import NoraCekirdek
import SwiftUI

@MainActor
struct DersAdimEkrani: View {
    let model: PekistirmeModeli
    let akim: String
    let adim: DersAdimi
    let derseDon: () -> Void
    let adimaGit: (DersAdimi) -> Void
    let adreseGit: (String) -> Void
    let turBaslat: (PekistirmeKipi, Int?) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var bitti = false

    var body: some View {
        if let katalog = model.katalog, let il = model.ilerleme,
           let b = CalisDersKurallari.dersBilgisi(kaynak: model.dersKaynagi, yuruyus: model.yuruyus, katalog: katalog,
                                                  ilerleme: il, akim: akim),
           !b.acikSanatcilar.isEmpty {
            Group {
                if bitti {
                    sonEkrani(b, katalog: katalog, il: il)
                } else {
                    adimEkrani(b)
                }
            }
            .background(Color(tema.renkler.zemin).ignoresSafeArea())
        } else if model.katalog == nil {
            Color(tema.renkler.zemin).ignoresSafeArea()
        } else {
            CalisDersSayfasi(model: model, akim: akim, geri: derseDon, turBaslat: turBaslat, adreseGit: adreseGit, adimaGit: adimaGit)
        }
    }

    @ViewBuilder
    private func adimEkrani(_ b: DersBilgisi) -> some View {
        switch adim {
        case .gor:
            let eserler = DersAdimKurallari.gorEserleri(ders: CalisDersKurallari.dersBul(kaynak: model.dersKaynagi, akim: akim),
                                                       yuruyus: model.yuruyus)
            if eserler.isEmpty {
                gorYok(b)
            } else {
                DersGorAdimi(model: model, b: b, eserler: eserler, geri: derseDon, bitir: bitir)
            }
        case .ogren:
            if b.ogren.isEmpty {
                Color.clear.onAppear { bitti = true }
            } else {
                DersOgrenAdimi(model: model, b: b, geri: derseDon, bitir: bitir)
            }
        case .ayirt:
            if b.ayirt.isEmpty {
                Color.clear.onAppear { bitti = true }
            } else {
                DersAyirtAdimi(model: model, b: b, geri: derseDon, bitir: bitir, adreseGit: adreseGit)
            }
        }
    }

    private func bitir() {
        if tema.ayar.hareketAzaltilmis { bitti = true } else { withAnimation(.easeOut(duration: 0.3)) { bitti = true } }
    }

    // MARK: Gör verisi yok (Dada, Sürrealizm, Savaş sonrası figürasyon)

    private func gorYok(_ b: DersBilgisi) -> some View {
        let r = tema.renkler
        let tumu = CalisDersKurallari.dersDurumu(b.kayit, adimlar: DersAdimi.allCases)
        return ScrollView {
            VStack(spacing: 0) {
                DersAdimUst(etiket: DersAdimKurallari.ustEtiketi(akim: akim, adim: .gor, adimlar: DersAdimi.allCases),
                            baslik: "Gör", durum: tumu, adim: .gor, geri: derseDon)
                    .padding(.bottom, 14)
                VStack(spacing: 12) {
                    Text("Gör adımı yakında")
                        .font(Yazi.serif(34, stil: .largeTitle))
                        .cssSatir(.serif, 34, 37.4)
                        .foregroundStyle(Color(r.murekkep))
                    Text("Bu dönemin eserleri için yürüyüş henüz yazılmadı. Ders Öğren adımıyla başlar.")
                        .font(Yazi.okuma(17))
                        .cssSatir(.okuma, 17, 24.65)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(r.murekkep2))
                    Button { adimaGit(.ogren) } label: {
                        HStack {
                            Text("Öğren adımını aç")
                            Spacer(minLength: 8)
                            BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DersDugme(tur: .dolu))
                    .padding(.top, 20)
                }
                .padding(.top, 88)
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.top, 12)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("gor-yok")
    }

    // MARK: Adım sonu (`adimSonu`)

    private func sonEkrani(_ b: DersBilgisi, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let sonraki = DersAdimKurallari.sonrakiAdim(adim, adimlar: b.adimlar, durum: b.durum)
        let harita = b.durum.bitti
            ? CalisDersKurallari.haritaBilgisi(b, katalog: katalog, ilerleme: il, kaynak: model.dersKaynagi, yuruyus: model.yuruyus)
            : nil
        var yazilar = [DersAdimKurallari.sonYazisi(adim, gorEser: b.gor.eserler.count, gorToplam: b.gor.toplam,
                                                  ogren: b.ogren.count, ayirt: b.ayirt.count)]
        if let harita { yazilar.append(DersAdimKurallari.dersBittiYazisi(akim: akim, kilit: harita.kilit)) }
        var dugmeler: [DersAdimSonu.Dugme] = []
        if let sonraki {
            dugmeler.append(.init(id: "ders-sonraki-adim", yazi: "Sıradaki adım: \(sonraki.ad)", simge: .ileri) { adimaGit(sonraki) })
        }
        if harita != nil {
            dugmeler.append(.init(id: "ders-haritaya-gec", yazi: "Haritaya geç", harita: true) { adreseGit("#/harita") })
        }
        dugmeler.append(.init(id: "ders-derse-don", yazi: "Derse dön", dolu: false) { derseDon() })

        return ScrollView {
            VStack(spacing: 0) {
                DersAdimUst(etiket: DersAdimKurallari.ustEtiketi(akim: akim, adim: adim, adimlar: b.adimlar),
                            baslik: adim.ad, durum: b.durum, adim: adim, geri: derseDon)
                    .padding(.bottom, 14)
                DersAdimSonu(baslik: "\(adim.ad) tamam", yazilar: yazilar, dugmeler: dugmeler)
                    .padding(.top, 88)
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.top, 12)
            .padding(.bottom, 128)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        #if DEBUG
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            DersKarsilastirma.hazirYaz()
        }
        #endif
    }
}

#if DEBUG
/// CI karşılaştırması (C3): `-calisSayfa ders:<akım>:<adım>` adım ekranını açar; ekran hazır olunca `tmp/ders-hazir`
/// işaret dosyası yazılır. `-dersCevapla`: Ayırt et'te soldaki esere dokunur (fark bölümü görünsün).
enum DersKarsilastirma {
    static let hazir = FileManager.default.temporaryDirectory.appendingPathComponent("ders-hazir")
    static func hazirYaz() { try? Data().write(to: hazir) }
}
#endif

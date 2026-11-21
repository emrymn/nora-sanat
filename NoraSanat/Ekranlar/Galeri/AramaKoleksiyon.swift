// Kaynak: sanat-atlasi js/ekranlar/arama.js (aramaSayfasi, satirHtml, sonuclariCiz), js/arama.js GRUPLAR,
// js/ekranlar/koleksiyon.js, css/app.css (.arama-alan, .arama-ipucu, .arama-grup, .liste, .satir) @ a866b86
// Ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece).
import NoraCekirdek
import SwiftUI

/// `aramaSayfasi()`: "Göz At / Ara"; altı çizili büyük arama alanı (24 px Bodoni), ipucu; sonuçlar dört grupta
/// (Sanatçılar, Eserler, Konular, Başyapıtlar), her grupta en çok 8 satır
struct AramaSayfasi: View {
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let dizin: [GaleriKaydi]
    @Binding var sorgu: String
    let eylem: GaleriEylemleri
    @Environment(TemaDeposu.self) private var tema
    @FocusState private var odak: Bool

    private var resim: GaleriResim { GaleriResim(galeri: galeri, il: il) }
    private static let gruplar: [(GaleriKaydi.Tur, String)] = [(.sanatci, "Sanatçılar"), (.eser, "Eserler"), (.konu, "Konular"),
                                                                 (.basyapit, "Başyapıtlar")]

    var body: some View {
        let r = tema.renkler
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GaleriSayfaUst(etiket: "Göz At", baslik: "Ara", geri: eylem.geri)
                // `.arama-alan`: 54 yükseklik, altta 2 px vurgu çizgisi, 10 aralık; girdi 24 px Bodoni
                HStack(spacing: 10) {
                    GaleriIkon(simge: .ara, boyut: 20, kalinlik: 1.6).foregroundStyle(Color(r.murekkep2))
                    TextField("", text: $sorgu, prompt: Text("Sanatçı, eser, konu…").foregroundColor(Color(r.murekkep3)))
                        .font(Yazi.serif(24, stil: .title2))
                        .foregroundStyle(Color(r.murekkep))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($odak)
                        .accessibilityLabel("Ara")
                    if !sorgu.isEmpty {
                        Button { sorgu = "" } label: { GaleriIkon(simge: .kapat, boyut: 18, kalinlik: 1.7) }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color(r.murekkep2))
                            .frame(width: 44, height: 44)
                            .accessibilityLabel("Temizle")
                    }
                }
                .frame(height: 52)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(GaleriRenk.karis(r.vurgu, r.murekkep, 0.55))).frame(height: 2)
                }
                .padding(.top, 4).padding(.bottom, 18)
                sonuclar
            }
            .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(SayfaZemini(donem: nil, ustHale: true))
        .onAppear {
            #if DEBUG
            // CI görüntüsü: klavye açılmasın (sitenin görüntüsünde de klavye yok)
            if NoraSanatApp.arguman("-galeriSayfa") != nil { return }
            #endif
            odak = true
        }
    }

    @ViewBuilder private var sonuclar: some View {
        let r = tema.renkler
        let bulunan = GaleriAramasi.ara(dizin, sorgu: sorgu)
        if sorgu.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            ipucu("Ad yazmaya başla: “Rembrandt”, “Gece Nöbeti” ya da “Night Watch”, “Müjde”. Türkçe harfler şart değil.")
        } else if bulunan.isEmpty {
            ipucu("“\(sorgu)” için sonuç yok.")
        } else {
            let eserler = bulunan.filter { $0.tur == .eser }.prefix(8).compactMap { x in
                galeri.eserler[x.sanatci ?? ""]?.first { $0.anahtar == x.anahtar }
            }
            ForEach(Self.gruplar.indices, id: \.self) { i in
                let tur = Self.gruplar[i].0, ad = Self.gruplar[i].1
                let grup = bulunan.filter { $0.tur == tur }
                if !grup.isEmpty {
                    GaleriBolum(etiket: "\(ad) · \(grup.count)") {
                        GaleriListe(ogeler: Array(grup.prefix(8))) { x in satir(x, eserler) }
                        if grup.count > 8 {
                            Text("ve \(grup.count - 8) sonuç daha; aramayı daralt.").font(Yazi.sans(13, stil: .footnote))
                                .foregroundStyle(Color(r.murekkep2)).padding(.top, 6)
                        }
                    }
                }
            }
        }
    }

    private func ipucu(_ metin: String) -> some View {
        Text(metin).font(Yazi.sans(13, stil: .footnote)).cssSatir(.sans, 13, 19.5)
            .foregroundStyle(Color(tema.renkler.murekkep2))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 6)
    }

    /// `satirHtml(x)`
    @ViewBuilder private func satir(_ x: GaleriKaydi, _ eserler: [Eser]) -> some View {
        let k = galeri.katalog
        switch x.tur {
        case .sanatci:
            if let s = k.harita[x.anahtar] {
                let acik = s.konu.map(il.islenenKume.contains) == true
                GaleriSatir(ad: s.ad, alt: acik ? "\(s.yillar) · \(s.akim)" : "\(s.yillar) · Konu \(SiteYazisi.bulunmaEki(s.konu ?? 0)) açılır",
                            kare: k.kucukGorselAdresi(s.id, kotuler: il.kotuGorseller), kilitli: !acik) {
                    eylem.git(.sanatci(s.id))
                }
            }
        case .eser:
            if let e = galeri.eserler[x.sanatci ?? ""]?.first(where: { $0.anahtar == x.anahtar }) {
                let alt = [resim.bilinenAd(e.sid), e.yil.map(String.init) ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
                GaleriSatir(ad: e.gorunenAd, alt: alt, kare: resim.url(e, 400)) {
                    eylem.ac(eserler, eserler.firstIndex(of: e) ?? 0)
                }
            }
        case .konu:
            let konu = galeri.konular.first { $0.id == x.anahtar }
            GaleriSatir(ad: x.baslik, alt: [konu?.ozet ?? "", "\(konu?.baglar.count ?? 0) eser"].filter { !$0.isEmpty }.joined(separator: " · "),
                        kareVar: false) {
                eylem.git(.konu(x.anahtar))
            }
        case .basyapit:
            GaleriSatir(ad: x.baslik, alt: "Yakın okuma" + (x.sanatci.flatMap { k.bilinenAd($0) }.map { " · " + $0 } ?? ""),
                        kareVar: false) {
                eylem.git(.okuma(x.anahtar))
            }
        }
    }
}

/// `koleksiyonSayfasi()`: "n eser / Koleksiyonum"; boşsa okuma metniyle ipucu, değilse asılı tablolar duvarı
struct KoleksiyonSayfasi: View {
    let galeri: GaleriKatalogu
    let il: Ilerleme
    let eylem: GaleriEylemleri

    var body: some View {
        let eserler = galeri.koleksiyon(il)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GaleriSayfaUst(etiket: "\(eserler.count) eser", baslik: "Koleksiyonum", geri: eylem.geri)
                if eserler.isEmpty {
                    OkumaMetni(metin: "Henüz eser işaretlemedin. Bir eseri büyütüp sağ üstteki işarete dokun.")
                } else {
                    KoleksiyonDuvari(eserler: eserler, galeri: galeri, ilerleme: il) { eylem.ac(eserler, $0) }
                }
            }
            .padding(.horizontal, BenOlcu.yan).padding(.top, 12).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(SayfaZemini(donem: nil, ustHale: true))
    }
}

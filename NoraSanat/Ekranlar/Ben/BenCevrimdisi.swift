// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (ayarlarSayfasi'ndaki data-test="devasa-indir" bölümü, devasaBilgisi,
// devasaGoster, devasaSil) @ a866b86
// Z3x: görünüş Neon'un Yön 2'si (yon-2.html "Görseller ve çevrimdışı"): "En büyük kopyalar" satırı, yüzde, 3 pt ilerleme
// çizgisi (süren pirinç, biten yeşil), İndir / İndirmeyi sürdür · Durdur · Telefondan sil; sitenin uzun açıklaması
// kartın altında dipnot. Davranış C5'teki gibi.
import NoraCekirdek
import SwiftUI

/// "En büyük kopyaları telefona indir" (C5). İndirme Swift'te (`CevrimdisiIndirici`); yazılar ve düğmeler sitenin
/// kurallarıyla (`CevrimdisiGorunum`), satırın özeti `CevrimdisiOzeti`.
struct BenCevrimdisi: View {
    let depo: BenDeposu
    @State private var silOnay = false
    @Environment(TemaDeposu.self) private var tema
    private var ind: CevrimdisiIndirici { CevrimdisiIndirici.shared }

    var body: some View {
        Group {
            if let l = ind.liste, let g = ind.gorunum {
                if l.telefonAdresleri.isEmpty {
                    AyarKarti { AyarSatiri(simge: .indir, ad: "En büyük kopyalar", alt: "İndirilecek görsel yok") }
                } else {
                    kart(l, g)
                }
            } else {
                AyarKarti { AyarSatiri(simge: .indir, ad: "En büyük kopyalar", alt: "Hesaplanıyor…") }
            }
        }
        .task(id: depo.katalog != nil) {
            guard let k = depo.katalog else { return }
            ind.baslat()
            await ind.hazirla(k)
            #if DEBUG
            // CI: -cevrimdisiIndir -cevrimdisiParca 2 → küçük bir parça gerçekten iner
            if CommandLine.arguments.contains("-cevrimdisiIndir") { ind.indir() }
            #endif
        }
        .alert("En büyük kopyalar telefondan silinsin mi? Görüntüleyici internet varken yine indirir.", isPresented: $silOnay) {
            Button("Vazgeç", role: .cancel) {}
            Button("Sil", role: .destructive) { Task { await ind.sil() } }
        }
    }

    private func kart(_ l: CevrimdisiListe, _ g: CevrimdisiGorunum) -> some View {
        let r = tema.renkler
        let o = CevrimdisiOzeti(liste: l, telefonda: ind.telefonda, durum: ind.durum)
        let mesaj = ind.silindi && ind.durum == nil ? "Silindi." : g.mesaj
        let tur: CevrimdisiGorunum.Tur = ind.silindi && ind.durum == nil ? .tamam : g.mesajTuru
        return VStack(alignment: .leading, spacing: 0) {
            AyarKarti {
                AyarSatiri(simge: .indir, ad: "En büyük kopyalar", alt: o.altYazi) {
                    SagDeger(metin: o.yuzdeYazisi, renk: o.tamam ? \TemaRenkleri.dogruIkon : \TemaRenkleri.pirinc)
                        .accessibilityLabel("Yüzde \(o.yuzde)")
                }
                VStack(alignment: .leading, spacing: 12) {
                    InceIlerleme(oran: o.oran, tamam: o.tamam)
                        .accessibilityElement()
                        .accessibilityLabel("İndirme")
                        .accessibilityValue("\(o.telefonda) / \(o.hepsi)")
                    // Satır yetmezse düğmeler alt alta
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { dugmeler(g, o) }
                        VStack(alignment: .leading, spacing: 8) { dugmeler(g, o) }
                    }
                    if !mesaj.isEmpty {
                        // .mesaj: .hata --wrong-ikon, .tamam --right-ikon
                        Text(mesaj)
                            .font(Yazi.sans(12.5, agirlik: 500, stil: .footnote))
                            .foregroundStyle(Color(tur == .hata ? r.yanlisIkon : tur == .tamam ? r.dogruIkon : r.murekkep2))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }
            AyarDipnotu(g.bilgi)
        }
    }

    @ViewBuilder
    private func dugmeler(_ g: CevrimdisiGorunum, _ o: CevrimdisiOzeti) -> some View {
        if g.indir {
            Button(o.telefonda > 0 && !o.tamam ? "İndirmeyi sürdür" : "İndir") { ind.indir() }
                .buttonStyle(CamHap())
                .disabled(g.indirKapali)
        }
        if g.durdur { Button("Durdur") { ind.durdur() }.buttonStyle(CamHap()) }
        if g.sil { Button("Telefondan sil") { silOnay = true }.buttonStyle(CamHap(tehlike: true)) }
    }
}

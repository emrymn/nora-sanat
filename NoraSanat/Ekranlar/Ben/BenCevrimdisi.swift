// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (ayarlarSayfasi'ndaki data-test="devasa-indir" bölümü, devasaBilgisi,
// devasaGoster, devasaSil), css/app.css (.ayar, .ayar .dugme, progress, .mesaj) @ a866b86
import NoraCekirdek
import SwiftUI

/// "En büyük kopyaları telefona indir" (C5). İndirme Swift'te (`CevrimdisiIndirici`); yazılar ve düğmeler sitenin
/// kurallarıyla (`CevrimdisiGorunum`). Sitedeki gibi yalnız indirilecek görsel varsa görünür. (C4b'de bu bölüm gizli
/// sitenin #/ayarlar sayfasını okuyordu; artık siteye dokunmaz.)
struct BenCevrimdisi: View {
    let depo: BenDeposu
    @State private var silOnay = false
    @Environment(TemaDeposu.self) private var tema
    private var ind: CevrimdisiIndirici { CevrimdisiIndirici.shared }

    var body: some View {
        let g = ind.gorunum
        Group {
            if let l = ind.liste, !l.telefonAdresleri.isEmpty, let g {
                bolum(g)
            } else if depo.katalog != nil, ind.liste == nil {
                AyarBolumu(baslik: "En büyük kopyaları telefona indir", aciklama: "Hesaplanıyor…") { EmptyView() }
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

    private func bolum(_ g: CevrimdisiGorunum) -> some View {
        let r = tema.renkler
        return AyarBolumu(baslik: "En büyük kopyaları telefona indir", aciklama: g.bilgi) {
            // .ayar .dugme: satır içi, üstte 8 px
            HStack(spacing: 8) {
                if g.indir {
                    Button("İndir") { ind.indir() }.buttonStyle(HapDugme()).disabled(g.indirKapali)
                }
                if g.durdur { Button("Durdur") { ind.durdur() }.buttonStyle(HapDugme(ince: true)) }
                if g.sil { Button("Telefondan sil") { silOnay = true }.buttonStyle(HapDugme(ince: true)) }
            }
            .padding(.top, 8)
            if let c = g.cubuk {
                // progress: tam genişlik, 6 px, --vurgu-acik
                ProgressView(value: min(c.deger, c.enCok), total: c.enCok)
                    .progressViewStyle(.linear)
                    .tint(Color(r.vurguAcik))
                    .frame(height: 6)
                    .padding(.top, 8)
                    .accessibilityLabel("İndirme")
            }
            let mesaj = ind.silindi && ind.durum == nil ? "Silindi." : g.mesaj
            let tur: CevrimdisiGorunum.Tur = ind.silindi && ind.durum == nil ? .tamam : g.mesajTuru
            if !mesaj.isEmpty {
                // .mesaj: 13.5 px; .hata --wrong-ikon, .tamam --right-ikon
                Text(mesaj)
                    .font(Yazi.sans(13.5, stil: .footnote))
                    .foregroundStyle(Color(tur == .hata ? r.yanlisIkon : tur == .tamam ? r.dogruIkon : r.murekkep))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }
        }
        .id("cevrimdisi")
    }
}

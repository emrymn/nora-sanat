// Kaynak: sanat-atlasi js/ekranlar/basyapit.js (yanYanaAc), css/app.css (.bsy-yan, .bsy-yan-resim, .bsy-yan-ad,
// .bsy-yan-kapat, .bsy-yan-kart) @ a866b86
import NoraCekirdek
import SwiftUI

struct YanYanaSecimi: Identifiable {
    let id = UUID()
    let bu: Eser
    let buAd: String
    let oteki: Eser
    let otekiAd: String
    let k: BasyapitSayfasi.Karsilastirma
    /// Öteki eserin başyapıt anahtarı ("Eserin sayfası"); Z3q: katalogdan bulunan eserde nil (düğme çıkmaz)
    let anahtar: String?
    let resim: GaleriResim
}

/// `yanYanaAc({ bu, oteki, k })`: iki eser üst üste (sığdırılmış, sol altta adları), sağ üstte kapat; altta kart:
/// sanatçı, eser, gerekçe ve "Eserin sayfası". Sekme çubuğunun üstünde tam ekran açılır.
struct YanYana: View {
    let secim: YanYanaSecimi
    let sayfayaGit: () -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 4) {
            // `.bsy-yan` ekranın tepesinden başlar (durum çubuğunun altı da resim alanı)
            resim(secim.bu, secim.buAd, "\(secim.buAd)").ignoresSafeArea(edges: .top)
            resim(secim.oteki, secim.otekiAd, "\(secim.k.sanatci), \(secim.k.eser)")
            VStack(alignment: .leading, spacing: 0) {
                Etiket(secim.k.sanatci)
                Text(secim.k.eser).font(Yazi.serif(24, agirlik: 500, stil: .title2)).tracking(-0.24).cssSatir(.serif, 24, 30)
                    .foregroundStyle(Color(r.murekkep)).padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                Text(secim.k.gerekce).font(Yazi.okuma(17)).cssSatir(.okuma, 17, 26)
                    .foregroundStyle(Color(r.murekkep)).padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
                if secim.anahtar != nil {
                    Button {
                        kapat()
                        sayfayaGit()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Eserin sayfası")
                            GaleriIkon(simge: .ileri, boyut: 18, kalinlik: 1.8)
                        }
                    }
                    .buttonStyle(DoluDugme())
                    .padding(.top, 16)
                }
            }
            .padding(.top, 20).padding(.horizontal, 22).padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(r.zemin).ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { kapat() } label: { GaleriIkon(simge: .kapat, boyut: 20, kalinlik: 1.8) }
                .buttonStyle(CamDugme())
                .accessibilityLabel("Kapat")
                .padding(.trailing, 12).padding(.top, 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Yan yana karşılaştır")
    }

    /// `.bsy-yan-resim`: esnek yükseklik, sığdırılmış resim; sol altta cam etiket (600 13 / 18)
    private func resim(_ e: Eser, _ ad: String, _ alt: String) -> some View {
        let r = tema.renkler
        return ZStack(alignment: .bottomLeading) {
            secim.resim.gorsel(e, 1200, kip: .fit)
                .background(Color(r.zemin))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(alt)
            Text(ad).font(Yazi.sans(13, agirlik: 600, stil: .footnote)).cssSatir(.sans, 13, 18)
                .foregroundStyle(Color(r.murekkep))
                .lineLimit(1).truncationMode(.tail)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(r.ustDugme))))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
                .padding(.leading, 12).padding(.bottom, 10)
                .padding(.trailing, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

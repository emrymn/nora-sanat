import NoraCekirdek
import SwiftUI

/// Ben sekmesinin yerli ekranı (ISLER.md: C4). Kabuk (T3) bunu, sekme `Gecis.tasinanlar`'a eklenince gösterir.
/// Şerit işi gövdeyi kendi ekranıyla değiştirir. Sitenin bağlantısıyla, widget'la ya da bildirimle gelinen adres:
/// `durum.yerliAdres[.ben]` (gösterince `durum.adresIslendi(.ben)`).
struct BenSekmesi: View {
    var body: some View {
        SekmeYeri(sekme: .ben)
    }
}

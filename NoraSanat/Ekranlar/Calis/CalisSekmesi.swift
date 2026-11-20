import NoraCekirdek
import SwiftUI

/// Calis sekmesinin yerli ekranı (ISLER.md: C1 + C2 + C3). Kabuk (T3) bunu, sekme `Gecis.tasinanlar`'a eklenince gösterir.
/// Şerit işi gövdeyi kendi ekranıyla değiştirir. Sitenin bağlantısıyla, widget'la ya da bildirimle gelinen adres:
/// `durum.yerliAdres[.calis]` (gösterince `durum.adresIslendi(.calis)`).
struct CalisSekmesi: View {
    var body: some View {
        SekmeYeri(sekme: .calis)
    }
}

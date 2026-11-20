import NoraCekirdek
import SwiftUI

/// Bugun sekmesinin yerli ekranı (ISLER.md: G4). Kabuk (T3) bunu, sekme `Gecis.tasinanlar`'a eklenince gösterir.
/// Şerit işi gövdeyi kendi ekranıyla değiştirir. Sitenin bağlantısıyla, widget'la ya da bildirimle gelinen adres:
/// `durum.yerliAdres[.bugun]` (gösterince `durum.adresIslendi(.bugun)`).
struct BugunSekmesi: View {
    var body: some View {
        SekmeYeri(sekme: .bugun)
    }
}

import NoraCekirdek
import SwiftUI

/// Galeri sekmesinin yerli ekranı (ISLER.md: G1 + G2 + G3). Kabuk (T3) bunu, sekme `Gecis.tasinanlar`'a eklenince gösterir.
/// Şerit işi gövdeyi kendi ekranıyla değiştirir. Sitenin bağlantısıyla, widget'la ya da bildirimle gelinen adres:
/// `durum.yerliAdres[.galeri]` (gösterince `durum.adresIslendi(.galeri)`).
struct GaleriSekmesi: View {
    var body: some View {
        SekmeYeri(sekme: .galeri)
    }
}

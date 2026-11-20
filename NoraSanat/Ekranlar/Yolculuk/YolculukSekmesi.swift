import NoraCekirdek
import SwiftUI

/// Yolculuk sekmesinin yerli ekranı (ISLER.md: G5). Kabuk (T3) bunu, sekme `Gecis.tasinanlar`'a eklenince gösterir.
/// Şerit işi gövdeyi kendi ekranıyla değiştirir. Sitenin bağlantısıyla, widget'la ya da bildirimle gelinen adres:
/// `durum.yerliAdres[.yolculuk]` (gösterince `durum.adresIslendi(.yolculuk)`).
struct YolculukSekmesi: View {
    var body: some View {
        SekmeYeri(sekme: .yolculuk)
    }
}

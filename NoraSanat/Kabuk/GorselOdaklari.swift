// Kaynak: sanat-atlasi js/ekranlar/ortak.js (odaklariYukle, odakliGorsel, odagaKaydir), js/gorsel.js
// (gorselOdakNoktasi, cihazdakiElleOdaklar) @ cca62eb
import NoraCekirdek
import SwiftUI

/// Z3m: kırpılan kartların odak noktaları (`odakliGorsel`). Sitedeki gibi odak dosyaları bir kez yüklenir
/// (`odaklariYukle`); gelene kadar görseller ortadan kırpılır, gelince odağa kayar (`odagaKaydir`). Bu cihazda elle
/// işaretlenenler (`ElleOdaklar`, görüntüleyicide "Odağı işaretle") her okumada güncel.
@MainActor
@Observable
final class GorselOdaklari {
    static let shared = GorselOdaklari()

    private(set) var veri = OdakVerisi()
    @ObservationIgnored private var yukleniyor = false
    @ObservationIgnored private var yuklendi = false

    /// `odaklariYukle()`: bir kez (olmazsa sonraki çağrıda yeniden)
    func yukle() async {
        guard !yuklendi, !yukleniyor else { return }
        yukleniyor = true
        defer { yukleniyor = false }
        let v = await SiteVerisi().veriler(OdakVerisi.dosyalar)
        guard v["gorsel_odak.json"] != nil else { return }
        veri = OdakVerisi(veriler: v)
        yuklendi = true
    }

    /// `gorselOdakNoktasi(secilenGorsel(e, kotuler) || e.gorseller[0])`
    func odak(_ e: Eser, adresler: GorselAdresleri, kotuler: [String: [String]]) -> [Double]? {
        var o = veri
        o.cihaz = ElleOdaklar.hepsi
        return o.odak(e, adresler: adresler, kotuler: kotuler)
    }
}

/// Z3m: `odakliGorsel(el, e, genislik)`: kutuyu kaplayan görsel, eserin odağının çevresinden kırpılır (çağıran kırpar:
/// `.clipped()` / `.clipShape`)
struct OdakliGorsel: View {
    let url: URL?
    var yedek: URL?
    let eser: Eser
    let adresler: GorselAdresleri
    var kotuler: [String: [String]] = [:]

    var body: some View {
        UzakGorsel(url: url, icerik: .fill, yedek: yedek,
                   odak: GorselOdaklari.shared.odak(eser, adresler: adresler, kotuler: kotuler))
            .task { await GorselOdaklari.shared.yukle() }
    }
}

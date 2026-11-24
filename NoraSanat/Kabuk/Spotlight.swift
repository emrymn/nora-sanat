import CoreSpotlight
import CryptoKit
import Foundation
import NoraCekirdek
import UniformTypeIdentifiers

/// Z3o (yeni, sitede yok): iPhone aramasında (Spotlight) sanatçılar ve akımlar. "Caravaggio" yazınca sanatçının
/// Galeri'deki sayfası, "Barok" yazınca akım salonu çıkar; dokununca uygulama o sayfada açılır (`ac`).
/// Kayıtlar katalogdan; katalog değişmediyse (imza aynı) yeniden yazılmaz.
@MainActor
enum Spotlight {
    static let alan = "norasanat.galeri"
    private static let imzaAnahtari = "nora.spotlight.imza.v1"

    /// Açılışta bir kez (KokGorunum)
    static func guncelle() async {
        guard CSSearchableIndex.isIndexingAvailable(),
              let k = try? await SiteVerisi().katalog() else { return }
        let ogeler = k.sanatcilar.map(sanatciOgesi) + k.akimlar.map(akimOgesi)
        // `hashValue` her açılışta değişir; kalıcı imza SHA-256 (başlık ve açıklama da dahil)
        let metin = ogeler.map { "\($0.uniqueIdentifier)|\($0.attributeSet.title ?? "")|\($0.attributeSet.contentDescription ?? "")" }
            .joined(separator: "\n")
        let imza = SHA256.hash(data: Data(metin.utf8)).map { String(format: "%02x", $0) }.joined()
        guard UserDefaults.standard.string(forKey: imzaAnahtari) != imza else { return }
        let dizin = CSSearchableIndex.default()
        do {
            try await dizin.deleteSearchableItems(withDomainIdentifiers: [alan])
            try await dizin.indexSearchableItems(ogeler)
            UserDefaults.standard.set(imza, forKey: imzaAnahtari)
        } catch {
            // Bir sonraki açılışta yeniden denenir (imza yazılmadı)
        }
    }

    private static func sanatciOgesi(_ s: Sanatci) -> CSSearchableItem {
        let a = CSSearchableItemAttributeSet(contentType: .content)
        a.title = s.ad
        a.contentDescription = [s.yillar, s.akim].filter { !$0.isEmpty }.joined(separator: " · ")
        a.keywords = [s.ad, s.adArama, s.akim, "ressam", "sanatçı"].compactMap { $0 }
        return CSSearchableItem(uniqueIdentifier: "sanatci/" + s.id, domainIdentifier: alan, attributeSet: a)
    }

    private static func akimOgesi(_ m: Akim) -> CSSearchableItem {
        let a = CSSearchableItemAttributeSet(contentType: .content)
        a.title = m.ad
        a.contentDescription = "Akım · Galeri'de salonu"
        a.keywords = [m.ad, "akım", "dönem"]
        return CSSearchableItem(uniqueIdentifier: "akim/" + m.ad, domainIdentifier: alan, attributeSet: a)
    }

    /// Spotlight sonucuna dokununca (`CSSearchableItemActionType`): kimlikten sitenin adresi
    static func adres(_ kimlik: String) -> String? {
        if kimlik.hasPrefix("sanatci/") { return "#/sanatci/" + SiteYazisi.uriBileseni(String(kimlik.dropFirst(8))) }
        if kimlik.hasPrefix("akim/") { return "#/akim/" + SiteYazisi.uriBileseni(String(kimlik.dropFirst(5))) }
        return nil
    }

    static func ac(_ etkinlik: NSUserActivity) {
        guard let kimlik = etkinlik.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let adres = adres(kimlik) else { return }
        Gezgin.shared.git(adres)
    }
}

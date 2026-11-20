import NoraCekirdek
import UIKit

/// Dokunsal geri bildirim (sitenin js/titresim.js'i, İş 106): doğru cevapta tek, yanlışta çift darbe.
///
/// - Site `navigator.vibrate(14)` / `vibrate([18, 70, 18])` çağırır; `WebKabugu` bunu `desen(_:)`'e bağlar (site
///   ayarı kapalıysa zaten çağırmaz).
/// - Yerli ekranlar `Titresim.dogru(acik:)` / `yanlis(acik:)`; `acik` sitenin Ayarlar → Titreşim seçimi:
///   `Titresim.acik(il)` (ilerleme `ayarlar.titresim`, yoksa açık).
@MainActor
enum Titresim {
    private static let bildirim = UINotificationFeedbackGenerator()
    private static let secimUreteci = UISelectionFeedbackGenerator()
    private static let darbe = UIImpactFeedbackGenerator(style: .light)

    /// Sitenin ayarı: `ayarlar.titresim !== false` (js/depo.js)
    static func acik(_ il: Ilerleme?) -> Bool {
        guard let il, let d = il.ayar("titresim") else { return true }
        if case .mantik(let b) = d { return b }
        return true
    }

    /// Cevap gelmeden önce çağrılırsa gecikme azalır
    static func hazirla() { bildirim.prepare() }

    static func dogru(acik: Bool = true) {
        guard acik else { return }
        bildirim.notificationOccurred(.success)
    }

    static func yanlis(acik: Bool = true) {
        guard acik else { return }
        bildirim.notificationOccurred(.error)
    }

    /// Seçim değişti (sekme, kaydırıcı)
    static func secim(acik: Bool = true) {
        guard acik else { return }
        secimUreteci.selectionChanged()
    }

    /// Hafif dokunuş (düğme)
    static func dokunus(acik: Bool = true) {
        guard acik else { return }
        darbe.impactOccurred()
    }

    /// `navigator.vibrate(desen)`: tek darbe doğru, birden çok darbe yanlış; `vibrate(0)` titreşimi durdurur (hiçbir şey)
    static func desen(_ d: [Double]) {
        guard d.contains(where: { $0 > 0 }) else { return }
        d.count > 1 ? yanlis() : dogru()
    }
}

import SwiftUI

/// Sitenin `main[data-hareket='giris']` (css/app.css "Hareket", `sahne-gir`): yeni ekranın içeriği hafifçe yükselerek
/// belirir (opaklık 0 → 1, 12 px aşağıdan yerine; 0,5 sn, cubic-bezier(0.2, 0.7, 0.2, 1)). Z3j: sekmeler arasında ve
/// Galeri'nin bölümleri (Akımlar, Başyapıtlar, Konular, Zaman) arasında geçişte. Hareket azaltma ya da Ayarlar'da
/// hareket kapalıysa oynamaz.
enum GirisHareketi {
    static let egri = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.5)
}

private struct GirisHareketiDegistirici: ViewModifier {
    /// Her değişişte bir kez oynar
    let tetik: Int
    let kayma: CGFloat
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var gorunur = true

    func body(content: Content) -> some View {
        content
            .opacity(gorunur ? 1 : 0)
            .offset(y: gorunur ? 0 : kayma)
            .onChange(of: tetik) { _, _ in oynat() }
    }

    private func oynat() {
        guard !hareketAz, !tema.ayar.hareketAzaltilmis else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { gorunur = false }
        Task { @MainActor in withAnimation(GirisHareketi.egri) { gorunur = true } }
    }
}

extension View {
    /// `tetik` her değiştiğinde içerik sitenin `sahne-gir`'i gibi belirir
    func girisHareketi(_ tetik: Int, kayma: CGFloat = 12) -> some View {
        modifier(GirisHareketiDegistirici(tetik: tetik, kayma: kayma))
    }
}

/// iOS 18: bir sayfa dokunulan öğeden büyüyerek açılır (sitenin js/gecis.js `sekilGecis`'i: arama hapı tam ekrana
/// açılır). iOS 17'de sistemin olağan geçişi.
struct BuyuyerekAcilanKaynak: ViewModifier {
    let id: String
    let alan: Namespace.ID?
    func body(content: Content) -> some View {
        if #available(iOS 18, *), let alan {
            content.matchedTransitionSource(id: id, in: alan)
        } else {
            content
        }
    }
}

struct BuyuyerekAcilanHedef: ViewModifier {
    let id: String?
    let alan: Namespace.ID?
    func body(content: Content) -> some View {
        if #available(iOS 18, *), let alan, let id {
            content.navigationTransition(.zoom(sourceID: id, in: alan))
        } else {
            content
        }
    }
}

#if DEBUG
import NoraCekirdek
import SwiftUI

/// DEBUG `-ekran goruntuleyici`: katalog yüklenince ayrıntı noktası olan ilk eseri görüntüleyicide açar (CI görüntüsü).
/// Z3p: `-incele n` incelemeyi n. ayrıntıda açar (`-incele -1`: genel bakış).
struct GoruntuleyiciOnizleme: View {
    private struct Hazir {
        let baglam: GoruntuleyiciBaglami
        let eserler: [Eser]
        let sira: Int
    }

    @State private var hazir: Hazir?

    var body: some View {
        Group {
            if let h = hazir {
                let incele = NoraSanatApp.arguman("-incele").flatMap { Int($0) }
                Goruntuleyici(
                    eserler: h.eserler,
                    baslangic: h.sira,
                    incelemeyeBasla: incele != nil,
                    incelemeNokta: incele.flatMap { $0 >= 0 ? $0 : nil },
                    baglam: h.baglam
                )
            } else {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
        .task {
            let b = await GoruntuleyiciBaglami.yukle()
            guard let k = b.katalog else { return }
            for s in k.sanatcilar {
                let l = k.eserler(s.id)
                if let i = l.firstIndex(where: { b.ayrinti($0) != nil }) {
                    hazir = Hazir(baglam: b, eserler: l, sira: i)
                    return
                }
            }
        }
    }
}
#endif

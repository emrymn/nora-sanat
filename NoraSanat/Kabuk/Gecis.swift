import NoraCekirdek
import SwiftUI

/// Sekme sekme Swift'e geçiş (ISLER.md K1).
///
/// - `tasinanlar`'da olmayan sekme sitenin o adresini gösterir; site tam ekrandır, sekme geçişi sitenin kendi çubuğuyla
///   olur ve yerli çubuk görünmez (bugünkü uygulamanın aynısı).
/// - Taşınmış bir sekmeye gelince (sitenin çubuğundan, sitenin bir bağlantısından, widget'tan ya da bildirimden) site
///   gizlenir, yerli ekran ve yerli sekme çubuğu görünür. Yerli çubukta taşınmamış bir sekmeye dokununca site o sekmeyle
///   geri gelir. Bütün sekmeler taşınınca site hiç görünmez.
/// - Bir sekmenin bütün işleri bitince (Sekmeler ne zaman yerli olur: ISLER.md) adı `tasinanlar`'a eklenir. Ekranı
///   `NoraSanat/Ekranlar/<Sekme>/<Sekme>Sekmesi.swift`'tedir.
enum Gecis {
    /// Swift'e taşınmış sekmeler
    static let tasinanlar: Set<Sekme> = []

    /// Bu açılışta yerli olan sekmeler. DEBUG'da `-yerliSekme galeri,ben` ile yarım ekranlar da denenebilir.
    static let yerliSekmeler: Set<Sekme> = {
        #if DEBUG
        let l = CommandLine.arguments
        if let i = l.firstIndex(of: "-yerliSekme"), i + 1 < l.count {
            return tasinanlar.union(l[i + 1].split(separator: ",").compactMap { Sekme(rawValue: String($0)) })
        }
        #endif
        return tasinanlar
    }()

    static func yerli(_ s: Sekme) -> Bool { yerliSekmeler.contains(s) }

    /// Sitenin adresini (hash) uygulamaya bildiren betik (sayfa açılmadan eklenir)
    static let adresBetigi = """
    (function () {
      if (window.__noraAdres) return;
      window.__noraAdres = true;
      function gonder() { try { window.webkit.messageHandlers.adres.postMessage(location.hash || '#/'); } catch (e) {} }
      addEventListener('hashchange', gonder);
      addEventListener('DOMContentLoaded', gonder);
    })();
    """
}

extension Sekme {
    /// Yerli sekme çubuğundaki simge (SF Symbols; sitenin çizimlerine en yakın)
    var simge: String {
        switch self {
        case .bugun: return "sun.horizon"
        case .yolculuk: return "map"
        case .galeri: return "square.grid.2x2"
        case .calis: return "paintbrush.pointed"
        case .ben: return "person.crop.circle"
        }
    }
}

/// Kabuğun durumu: seçili sekme ve sitenin adresi. Ekranlar `@Environment(KabukDurumu.self)` ile okur.
@MainActor
@Observable
final class KabukDurumu {
    static let shared = KabukDurumu()

    /// Seçili sekme (yerli ya da site)
    private(set) var secili: Sekme = .bugun
    /// Sitenin son bildirdiği adres
    private(set) var siteAdresi = "#/"
    /// Yerli sekmenin açması istenen adres (sitenin bağlantısı, widget, bildirim): ör. Galeri yerliyken
    /// "#/sanatci/rembrandt". Yerli ekran bunu okuyup gösterir ve `adresIslendi` çağırır.
    private(set) var yerliAdres: [Sekme: String] = [:]

    /// Site mi görünür (seçili sekme taşınmadıysa)
    var siteGorunur: Bool { !Gecis.yerli(secili) }

    /// Site bir adrese gitti
    func siteAdresiGeldi(_ adres: String) {
        siteAdresi = SiteRotalari.hash(adres)
        guard let s = SiteRotalari.sekme(siteAdresi) else { return }   // sekmesiz sayfa: açıldığı sekmede kalır
        if Gecis.yerli(s) { yerliAdres[s] = siteAdresi }
        if secili != s { secili = s }
    }

    /// Widget, bildirim, `-adres`: hedef yerli bir sekmedeyse orada açılır (true); değilse site gider (false)
    func yerliyeGit(_ adres: String) -> Bool {
        guard let s = SiteRotalari.sekme(adres), Gecis.yerli(s) else { return false }
        yerliAdres[s] = SiteRotalari.hash(adres)
        secili = s
        return true
    }

    /// Yerli sekme çubuğunda dokunuş
    func sec(_ s: Sekme) {
        guard s != secili else { return }
        secili = s
        guard !Gecis.yerli(s) else { return }
        // Site o sekmeye zaten geçmediyse sitenin kendi sekme düğmesine basılır: site sekmenin kalınan yerini açar
        if SiteRotalari.sekme(siteAdresi) != s { Gezgin.shared.sekmeyeGec(s) }
    }

    func adresIslendi(_ s: Sekme) { yerliAdres[s] = nil }
}

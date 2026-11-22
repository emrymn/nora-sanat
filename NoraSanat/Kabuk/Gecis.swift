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
    /// Swift'e taşınmış sekmeler. Ben: C4 + C4b; Galeri: G1 + G2 + G2b + G3; Çalış: C1 + C2 + C3 (T6);
    /// Bugün: G4 + G4b, Yolculuk: G5 + G5b (T7). Hepsi yerli: site artık görünmez (yalnız ilerleme köprüsü, Z2'ye kadar).
    /// DEBUG `-yalnizSite` ile site; bkz. `BenGecisi`, `GaleriGecisi`, `CalisGecisi`, `BugunGecisi`, `YolculukGecisi`.
    static let tasinanlar: Set<Sekme> = BenGecisi.sekmeler.union(GaleriGecisi.sekmeler).union(CalisGecisi.sekmeler)
        .union(BugunGecisi.sekmeler).union(YolculukGecisi.sekmeler)

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

    /// Sitenin kendi sekme düğmesine basar (kullanıcı dokunmuş gibi; sekme kalınan yerde açılır). Çubuk gizliyse
    /// sekmenin ana sayfasına gider. Argümanlar: `kimlik` (sitenin sekme kimliği), `adres` (sekmenin ana sayfası),
    /// `onceki` (yerli çubukta seçili sekmenin sırası ya da null), `bas` (false: site zaten o sekmede, yalnız hap kayar).
    /// T4: basmadan önce sitenin hapı, hareketsiz, yerli çubuğun hapının yerine konur; site hapı oradan yeni sekmeye
    /// kaydırır. Böylece yerliden siteye geçerken çubuk yerinde kalmış gibi görünür. Kâhin: kabuk_koprusu.mjs.
    static let sekmeyeGecBetigi = """
    const nav = document.getElementById('sekmeler');
    const a = nav && nav.querySelector('a[data-sekme="' + kimlik + '"]');
    if (!a || nav.hidden) {
      if (bas) location.hash = adres;
      return 'adres';
    }
    const isaret = nav.querySelector('.sekme-isaret');
    const simdiki = nav.style.getPropertyValue('--i');
    if (isaret && onceki !== null && onceki !== undefined) {
      isaret.style.transition = 'none';
      nav.style.setProperty('--i', String(onceki));
      void isaret.offsetWidth;
      isaret.style.transition = '';
    }
    if (!bas) {
      nav.style.setProperty('--i', simdiki);
      return 'hap';
    }
    a.click();
    return 'dugme';
    """
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
        let onceki = siteAdresi
        siteAdresi = SiteRotalari.hash(adres)
        if siteAdresi != onceki, let s = SiteRotalari.yerliSekme(siteAdresi), Gecis.yerli(s) { yerliAdres[s] = siteAdresi }
        if let s = SiteRotalari.secim(onceki: onceki, yeni: siteAdresi, secili: secili, yerli: Gecis.yerli) { secili = s }
        rozetiYenile()   // sitenin rozeti de her sayfa çiziminde yenilenir (sekmeleriCiz)
    }

    /// Widget, bildirim, `-adres`: hedef yerli bir sekmedeyse orada açılır (true); değilse site gider (false)
    func yerliyeGit(_ adres: String) -> Bool {
        guard let s = SiteRotalari.yerliSekme(adres), Gecis.yerli(s) else { return false }
        yerliAdres[s] = SiteRotalari.hash(adres)
        secili = s
        return true
    }

    /// Yerli sekme çubuğunda dokunuş
    func sec(_ s: Sekme) {
        guard s != secili else { return yenidenDokunma[s, default: 0] += 1 }
        let onceki = SekmeCubugu.sira(secili)
        secili = s
        guard !Gecis.yerli(s) else { return }
        // Site o sekmeye zaten geçmediyse sitenin kendi sekme düğmesine basılır: site sekmenin ana ekranını kalınan
        // kaydırma yerinde açar (kullanıcı sitenin çubuğuna dokunmuş gibi)
        // Site zaten o sekmedeyse yalnız sitenin hapı yerli hapın yerinden kayar.
        Gezgin.shared.sekmeyeGec(s, onceki: onceki, bas: SiteRotalari.sekme(siteAdresi) != s)
    }

    func adresIslendi(_ s: Sekme) { yerliAdres[s] = nil }

    // MARK: Yerli sekme çubuğu (T4)

    /// Açık sekmeye yeniden dokunma sayacı. Sitede açık sekmenin ana ekranındayken dokunmak en başa kaydırır; yerli
    /// ekran bunu `.onChange(of: durum.yenidenDokunma[.galeri])` ile dinleyip köküne döner ya da başa kayar.
    private(set) var yenidenDokunma: [Sekme: Int] = [:]

    /// Çalış rozetindeki sayı (bugün bekleyen kart; sitenin `turBilgisi('karisik').toplam`'ı)
    private(set) var calisRozeti = 0

    /// Yerli çubuğu gizleyen sekmeler (sitede sekmesiz sayfalar gibi: ör. tam ekran bir kart). Bkz. `cubuguGizle`.
    private var gizleyenler: Set<Sekme> = []

    /// Hızlı ayarlar yaprağı açık mı (DEBUG `-hizliAcik`: açık başlar; CI ekran görüntüsü)
    var hizliAcik: Bool = {
        #if DEBUG
        return CommandLine.arguments.contains("-hizliAcik")
        #else
        return false
        #endif
    }()

    /// Yerli çubuk görünür mü: seçili sekme yerli ve onu gizleyen yok
    var cubukGorunur: Bool { !siteGorunur && !gizleyenler.contains(secili) }

    /// Yerli ekran, sitedeki sekmesiz sayfalar gibi çubuğu gizlemek isterse: `.sekmeCubuguGizli(true, sekme: .calis)`
    func cubuguGizle(_ gizli: Bool, sekme: Sekme) {
        if gizli { gizleyenler.insert(sekme) } else { gizleyenler.remove(sekme) }
    }

    /// Dişli dili gizleyen sekmeler (sitede `HizliAyar.dilGorunur`: #/ayarlar'da gizli). C4b: Ben, Ayarlar açıkken.
    private var dilGizleyenler: Set<Sekme> = []

    /// Yerli çubuğun dişli dili görünür mü
    var dilGorunur: Bool { !dilGizleyenler.contains(secili) }

    func dilGizle(_ gizli: Bool, sekme: Sekme) {
        if gizli { dilGizleyenler.insert(sekme) } else { dilGizleyenler.remove(sekme) }
        if gizli && secili == sekme { hizliAcik = false }
    }

    private var rozetGorevi: Task<Void, Never>?

    /// Rozeti siteden yeniden okur. Yerli çubuk hiç yoksa sormaz. Site (ya da `d.ilerleme`) henüz hazır değilse
    /// hazır olana kadar saniyede bir, en çok 30 kez yeniden dener (açılışta adres iletisi modüllerden önce gelir).
    func rozetiYenile() {
        guard !Gecis.yerliSekmeler.isEmpty else { return }
        rozetGorevi?.cancel()
        rozetGorevi = Task {
            for _ in 0..<30 {
                if let n = await SekmeCubuguKoprusu.rozet() {
                    if n != calisRozeti { calisRozeti = n }
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
            }
        }
    }
}

extension View {
    /// Yerli ekranın sekme çubuğunu gizlemesi (bkz. `KabukDurumu.cubuguGizle`)
    func sekmeCubuguGizli(_ gizli: Bool, sekme: Sekme) -> some View {
        modifier(CubukGizleyici(gizli: gizli, sekme: sekme))
    }
}

private struct CubukGizleyici: ViewModifier {
    let gizli: Bool
    let sekme: Sekme
    @Environment(KabukDurumu.self) private var durum

    func body(content: Content) -> some View {
        content
            .onChange(of: gizli, initial: true) { _, g in durum.cubuguGizle(g, sekme: sekme) }
            .onDisappear { durum.cubuguGizle(false, sekme: sekme) }
    }
}

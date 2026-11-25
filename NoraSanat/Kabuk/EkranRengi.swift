// Kaynak: sanat-atlasi js/ekranlar/ortak.js (ekranRengi, renkSabitle, gununRengi, eserPaleti, renkleriYaz),
// js/renk.js (paletGetir, renkTemasi), js/gorsel.js (paletUrl) @ cca62eb
import NoraCekirdek
import SwiftUI

/// Z3m: sitede her ekran vurgu renklerini (`--vurgu` ailesi) o ekranın eserinin paletinden alır (`ekranRengi`); sekme
/// ana ekranları günün tablosunun rengini taşır (`gununRengi`, uygulamada `TemaHesabi`). Uygulamada bir ekranın
/// görünümüne `.ekranRengi(...)` verilir: altındaki her şey ortamdan kendi `TemaDeposu`'nu okur (tema aynı, vurgu o
/// eserden). Ekrandan çıkınca altındakiler yok olur, öbür ekranlar zaten günün rengini okur.
///
/// Sitedeki gibi:
/// - Palet gelene kadar bir önceki renk durur (sitede yeni renk yazılana kadar eskisi kalır; burada önce günün rengi,
///   aynı ekranda kart değişince bir önceki kartın rengi).
/// - Görsel açılmazsa yedek renk (sanatçı ve başyapıt sayfasında akımın rengi, konu sayfasında `#8A827A`); yedek yoksa
///   (pekiştirme kartları: cevaptan önce akım rengi ipucu olurdu) temanın nötr vurgusu.
/// - `notr`: rengi hemen nötre sabitler (`renkSabitle(null)`; ters soruda cevaptan önce).
/// Renk değişimi yumuşak; hareket azaltılmışsa anında.
@MainActor
struct EkranRengiDegistirici: ViewModifier {
    /// Eserin paletinin hesaplandığı görsel (sitenin `paletUrl(g)`'si: 400'lük kopya); nil ise eser yok (yedek de
    /// yoksa ortamın rengi kalır)
    let url: URL?
    /// `yedekRenk` (CSS rengi)
    let yedek: String?
    var notr = false

    @Environment(TemaDeposu.self) private var ust
    @Environment(\.accessibilityReduceMotion) private var sistemHareketi
    @State private var palet: Durum = .bekliyor

    enum Durum: Equatable {
        case bekliyor
        case palet([ResimRengi.PaletRengi]?)
    }

    func body(content: Content) -> some View {
        content
            .environment(depo)
            .task(id: "\(url?.absoluteString ?? "-")|\(yedek ?? "-")") { await yukle() }
    }

    /// Ortamdaki temanın aynısı, vurgu bu ekranın paletinden
    private var depo: TemaDeposu {
        let etkin: Durum = notr ? .palet(nil) : palet
        guard case .palet(let p) = etkin else { return ust }
        let r = TemaRenkleri.ekran(ust.ayar.tema, gunduz: ust.gunduz, palet: p)
        return TemaDeposu(renkler: r, ayar: ust.ayar, siteRengi: ust.siteRengi, gunduz: ust.gunduz)
    }

    private func yukle() async {
        // Eser de yedek de yoksa (ör. dersin kapağı bulunamadı: sitede `ekranRengi` hiç çağrılmaz) renk değişmez
        if url == nil, yedek == nil { palet = .bekliyor; return }
        let p: [ResimRengi.PaletRengi]?
        if let url, let hazir = EkranPaletleri.bellek[url] {
            p = hazir
        } else if let url {
            let hesap = await TemaHesabi.pikseller(url, uzun: 64).map { ResimRengi.paletHesapla($0) }
            guard !Task.isCancelled else { return }
            if let hesap, !hesap.isEmpty { EkranPaletleri.bellek[url] = hesap }
            p = ResimRengi.eserPaleti(hesap, yedek: yedek)
        } else {
            p = ResimRengi.eserPaleti(nil, yedek: yedek)
        }
        let yeni = Durum.palet(p)
        guard yeni != palet else { return }
        let ani = ust.ayar.hareketAzaltilmis || sistemHareketi
        withAnimation(ani ? nil : .easeInOut(duration: 0.45)) { palet = yeni }
    }
}

/// Hesaplanan paletler (sitenin `paletGetir` belleği ve IndexedDB'si): adres → palet
@MainActor
enum EkranPaletleri {
    static var bellek: [URL: [ResimRengi.PaletRengi]] = [:]
}

extension View {
    /// Z3m: bu ekranın vurgusu `url`'deki görselin paletinden (`ekranRengi(eser, yedekRenk)`)
    func ekranRengi(url: URL?, yedek: String? = nil, notr: Bool = false) -> some View {
        modifier(EkranRengiDegistirici(url: url, yedek: yedek, notr: notr))
    }

    func ekranRengi(_ r: (url: URL?, yedek: String?)) -> some View { ekranRengi(url: r.url, yedek: r.yedek) }
}

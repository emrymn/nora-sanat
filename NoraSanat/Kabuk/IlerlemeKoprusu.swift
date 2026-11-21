import Foundation
import NoraCekirdek
import WebKit

/// Sitenin ilerlemesini Swift'ten okur ve yazar (ISLER.md K2). Geçiş boyunca tek kaynak sitedir: okuma ve yazma
/// sitenin kendi modülleriyle, uygulamadaki tek WKWebView üzerinden yapılır. Böylece localStorage, IndexedDB yansısı,
/// kayıt numarası ve kayıt kilidi sitenin kodundan geçer; site ile Swift ekranları hep aynı veriyi görür.
///
/// - `oku()`: site yüklenmediyse yüklenmesini bekler (en çok `bekleme` saniye).
/// - `yaz(_:)`: okunduğundan beri sitede kayıt olduysa (`kayitNo` değiştiyse) yazmaz, `.cakisma` atar; üstüne yazılmasın.
/// - `degistir { … }`: oku → değiştir → yaz; çakışmada taze kayıtla yeniden dener. Swift ekranları bunu kullanmalı.
///
/// Betikler `Testler/kahin/ilerleme_koprusu.mjs` ile canlı sitede sınanır (BETIK-… işaretleri arası okunur).
@MainActor
final class IlerlemeKoprusu {
    static let shared = IlerlemeKoprusu()

    enum Hata: Error, Equatable {
        /// Site açılmadı (internet yok, ilk açılış) ya da beklerken süre doldu
        case siteYok
        /// Site bu açılışta ilerlemeyi okuyamadı ve kaydı kilitledi (js/depo.js kayitKilidi)
        case kilitli
        /// Okunduktan sonra sitede kayıt oldu
        case cakisma
        case bozuk(String)
    }

    /// Sitenin yüklenmesi için en çok bu kadar beklenir
    var bekleme: TimeInterval = 30

    /// Site (ve `d.ilerleme`) hazır olana kadar bekleyip ilerlemenin JSON'unu verir
    static let okumaBetigi = """
    /* OKU-BASI */
    const o = await import('/js/ekranlar/ortak.js');
    for (let i = 0; i < 100 && !o.d.ilerleme; i++) await new Promise((r) => setTimeout(r, 100));
    if (!o.d.ilerleme) return null;
    return JSON.stringify(o.d.ilerleme);
    /* OKU-SONU */
    """

    /// Argümanlar: `metin` (yeni ilerleme JSON'u), `beklenen` (okunduğu andaki kayitNo). Dönen: "tamam:<yeni kayitNo>",
    /// "cakisma", "kilitli" ya da null (site hazır değil).
    static let yazmaBetigi = """
    /* YAZ-BASI */
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    for (let i = 0; i < 100 && !o.d.ilerleme; i++) await new Promise((r) => setTimeout(r, 100));
    if (!o.d.ilerleme) return null;
    if (depo.kayitKilitliMi()) return 'kilitli';
    if ((o.d.ilerleme.kayitNo || 0) !== beklenen) return 'cakisma';
    const yeni = JSON.parse(metin);
    if (!yeni || typeof yeni !== 'object' || Array.isArray(yeni)) throw new Error('ilerleme nesne değil');
    Object.assign(o.d.ilerleme, yeni);
    o.kaydet();
    return 'tamam:' + (o.d.ilerleme.kayitNo || 0);
    /* YAZ-SONU */
    """

    private func betik(_ kaynak: String, _ bas: String, _ son: String) -> String {
        guard let a = kaynak.range(of: bas), let b = kaynak.range(of: son) else { return kaynak }
        return String(kaynak[a.upperBound..<b.lowerBound])
    }

    /// Site yüklenene kadar bekler; WKWebView'i verir
    private func hazirSite() async throws -> WKWebView {
        let son = Date().addingTimeInterval(bekleme)
        while Date() < son {
            if Gezgin.shared.yuklendi, let w = Gezgin.shared.webView { return w }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        throw Hata.siteYok
    }

    private func calistir(_ govde: String, _ arguman: [String: Any] = [:]) async throws -> Any? {
        let w = try await hazirSite()
        do {
            return try await w.callAsyncJavaScript(govde, arguments: arguman, in: nil, contentWorld: .page)
        } catch {
            // "Bağlantı yok" sayfasında modüller yok
            throw Hata.siteYok
        }
    }

    func oku() async throws -> Ilerleme {
        let sonuc = try await calistir(betik(Self.okumaBetigi, "/* OKU-BASI */", "/* OKU-SONU */"))
        guard let metin = sonuc as? String else { throw Hata.siteYok }
        do { return try Ilerleme(veri: Data(metin.utf8)) } catch { throw Hata.bozuk("\(error)") }
    }

    /// `ilerleme` okunduğundan beri sitede kayıt olmadıysa siteye yazar; yeni kayıt numarasını döndürür
    @discardableResult
    func yaz(_ ilerleme: Ilerleme) async throws -> Int {
        let sonuc = try await calistir(betik(Self.yazmaBetigi, "/* YAZ-BASI */", "/* YAZ-SONU */"),
                                       ["metin": ilerleme.jsonMetni, "beklenen": ilerleme.kayitNo])
        switch sonuc as? String {
        case "cakisma": throw Hata.cakisma
        case "kilitli": throw Hata.kilitli
        case let s? where s.hasPrefix("tamam:"):
            KabukDurumu.shared.rozetiYenile()   // Çalış rozeti (T4): yazılan kart vadeyi değiştirmiş olabilir
            return Int(s.dropFirst(6)) ?? 0
        default: throw Hata.siteYok
        }
    }

    /// Oku → değiştir → yaz. Arada sitede kayıt olduysa taze kayıtla en çok 3 kez yeniden dener.
    @discardableResult
    func degistir(_ blok: (inout Ilerleme) throws -> Void) async throws -> Ilerleme {
        var deneme = 0
        while true {
            var il = try await oku()
            try blok(&il)
            do {
                try await yaz(il)
                return il
            } catch Hata.cakisma where deneme < 2 {
                deneme += 1
            }
        }
    }
}

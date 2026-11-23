import SwiftUI
import UIKit
import NoraCekirdek
import WebKit

/// Sanat Atlası'nı tam ekran, Safari çubukları olmadan gösteren pencere.
///
/// - Çevrimdışı: Info.plist'teki `WKAppBoundDomains` sayesinde sitenin service worker'ı çalışır;
///   bir kez internetle açıldıktan sonra internetsiz de açılır.
/// - İlerleme ve ayarlar (localStorage, IndexedDB) uygulamanın kalıcı veri deposunda durur.
/// - `confirm()` / `alert()` / `prompt()` iOS'un kendi pencereleriyle gösterilir.
/// - `navigator.vibrate` iPhone'un titreşim motoruna bağlanır (doğru: tek, yanlış: çift titreşim).
/// - Başka sitelere giden linkler Safari'de açılır.
/// - Sitenin adresi (`Gecis.adresBetigi`) kabuğa bildirilir (T3). Renkler Z2c-2'den beri `TemaHesabi`'nda.
/// Uygulamada tek örneği vardır; `KokGorunum` onu hep yüklü tutar.
struct WebKabugu: UIViewRepresentable {
    static let adres = URL(string: "https://sanat-atlasi.pages.dev/")!

    /// Z2c-3b: site artık yalnız gerektiğinde kurulur. Bütün ekranlar, ilerleme, renkler ve sayaçlar Swift'te; site
    /// (1) ilerleme bir kez taşınmadıysa (dosya yok), (2) cihazdaki elle odaklar alınmadıysa ve (3) DEBUG `-yalnizSite`
    /// (CI karşılaştırmaları) ile açılır. Açılışta bir kez karar verilir.
    @MainActor static let gerekli: Bool = {
        #if DEBUG
        if CommandLine.arguments.contains("-yalnizSite") { return true }
        #endif
        return !IlerlemeKoprusu.shared.dosya.varMi || !ElleOdaklar.alindiMi
    }()

    let tema: TemaDeposu

    func makeCoordinator() -> Koordinator { Koordinator(tema: tema) }

    func makeUIView(context: Context) -> WKWebView {
        let ayar = WKWebViewConfiguration()
        ayar.limitsNavigationsToAppBoundDomains = true
        ayar.allowsInlineMediaPlayback = true
        ayar.websiteDataStore = .default()

        let icerik = WKUserContentController()
        icerik.addUserScript(WKUserScript(source: Koordinator.titresimBetigi,
                                          injectionTime: .atDocumentStart,
                                          forMainFrameOnly: true))
        icerik.add(context.coordinator, name: "titresim")
        icerik.addUserScript(WKUserScript(source: Gecis.adresBetigi, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        icerik.add(context.coordinator, name: "adres")
        ayar.userContentController = icerik

        let w = WKWebView(frame: .zero, configuration: ayar)
        w.navigationDelegate = context.coordinator
        w.uiDelegate = context.coordinator
        w.allowsBackForwardNavigationGestures = true
        w.isOpaque = false
        w.scrollView.contentInsetAdjustmentBehavior = .never   // site çentiği kendi hesaplar (viewport-fit=cover)
        w.scrollView.bounces = false
        #if DEBUG
        if #available(iOS 16.4, *) { w.isInspectable = true }   // Mac'te Safari → Geliştir ile incelenebilir
        #endif
        context.coordinator.baglan(w)
        Gezgin.shared.webView = w
        w.load(URLRequest(url: Self.adres))
        return w
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@MainActor
final class Koordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    private let tema: TemaDeposu
    private weak var webView: WKWebView?

    init(tema: TemaDeposu) {
        self.tema = tema
    }

    func baglan(_ w: WKWebView) {
        webView = w
        renkUygula(tema.siteRengi)
    }

    private func renkUygula(_ renk: UIColor) {
        webView?.backgroundColor = renk
        webView?.underPageBackgroundColor = renk
        webView?.scrollView.backgroundColor = renk
    }

    // MARK: Gezinti

    private func iceride(_ url: URL) -> Bool {
        if let sema = url.scheme, ["about", "blob", "data"].contains(sema) { return true }
        return url.host == WebKabugu.adres.host
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .allow }
        // Ana pencerede başka bir siteye gidiliyorsa (Wikipedia, müze sayfası…) Safari'de aç.
        let anaPencere = navigationAction.targetFrame?.isMainFrame ?? true
        if anaPencere && !iceride(url) {
            await UIApplication.shared.open(url)
            return .cancel
        }
        return .allow
    }

    /// target="_blank" linkler: yeni pencere yerine Safari.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if iceride(url) {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Gezgin.shared.yuklemeBitti()
        #if DEBUG
        if let betik = NoraSanatApp.arguman("-siteBetik") {
            Task { @MainActor in
                let metin: String
                do {
                    let sonuc = try await webView.callAsyncJavaScript(betik, arguments: [:], in: nil, contentWorld: .page)
                    if let yazi = sonuc as? String {
                        metin = yazi
                    } else {
                        let veri = try JSONSerialization.data(withJSONObject: sonuc ?? NSNull(), options: [.fragmentsAllowed])
                        metin = String(decoding: veri, as: UTF8.self)
                    }
                } catch {
                    // WebKit istisnanın kendi metnini userInfo'da verir; localizedDescription yalnız genel cümle.
                    let ayrinti = (error as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String
                    metin = "Hata: " + (ayrinti ?? error.localizedDescription)
                }
                try? Data(metin.utf8).write(to: FileManager.default.temporaryDirectory
                    .appendingPathComponent("site-betik"), options: .atomic)
            }
        }
        // T5 (CI): -hareketIzniDene → sayfa hareket izni ister; sonuç tmp/hareket-izni'ye yazılır. Pencere çıkmamalı.
        if CommandLine.arguments.contains("-hareketIzniDene") {
            Task { @MainActor in
                let betik = """
                const t = [window.DeviceMotionEvent, window.DeviceOrientationEvent].find((x) => x && typeof x.requestPermission === 'function');
                return t ? await t.requestPermission() : 'gerekmiyor';
                """
                let sonuc = (try? await webView.callAsyncJavaScript(betik, arguments: [:], in: nil, contentWorld: .page)) as? String ?? "hata"
                try? Data(sonuc.utf8).write(to: FileManager.default.temporaryDirectory.appendingPathComponent("hareket-izni"))
            }
        }
        #endif
    }

    /// İlk açılışta internet yoksa (önbellek henüz dolmadıysa) sade bir bilgi sayfası.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let kod = (error as NSError).code
        guard kod != NSURLErrorCancelled else { return }
        webView.loadHTMLString(Koordinator.baglantiYokSayfasi, baseURL: WebKabugu.adres)
    }

    /// iOS belleği boşaltmak için sayfayı kapattıysa yeniden yükle.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: Pencereler (alert / confirm / prompt)

    private func goster(_ a: UIAlertController) -> Bool {
        var vc = webView?.window?.rootViewController
        while let ust = vc?.presentedViewController { vc = ust }
        guard let vc else { return false }
        vc.present(a, animated: true)
        return true
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo) async {
        await withCheckedContinuation { (devam: CheckedContinuation<Void, Never>) in
            let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in devam.resume() })
            if !goster(a) { devam.resume() }
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo) async -> Bool {
        await withCheckedContinuation { (devam: CheckedContinuation<Bool, Never>) in
            let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Vazgeç", style: .cancel) { _ in devam.resume(returning: false) })
            a.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in devam.resume(returning: true) })
            if !goster(a) { devam.resume(returning: false) }
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo) async -> String? {
        await withCheckedContinuation { (devam: CheckedContinuation<String?, Never>) in
            let a = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            a.addTextField { $0.text = defaultText }
            a.addAction(UIAlertAction(title: "Vazgeç", style: .cancel) { _ in devam.resume(returning: nil) })
            a.addAction(UIAlertAction(title: "Tamam", style: .default) { [weak a] _ in
                devam.resume(returning: a?.textFields?.first?.text ?? "")
            })
            if !goster(a) { devam.resume(returning: nil) }
        }
    }

    /// "Telefonu eğince tablo hareketi" için hareket izni: uygulama zaten izin istediği için doğrudan ver.
    /// T5: tamamlama bloklu biçim. `async` karşılığı WebKit'e ulaşmıyordu; site ya da yerli kod (`izinVarMi`)
    /// izin isteyince iOS'un "Harekete ve Yöne Erişmek İstiyor" penceresi çıkıyordu (C4b ve G2b CI'ları).
    func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }

    // MARK: Titreşim

    /// Sitenin titreşim kodu `navigator.vibrate` varsa onu kullanır (doğru: 14 ms, yanlış: [18, 70, 18]).
    /// iPhone Safari'de bu yoktur; burada eklenip iPhone'un titreşim motoruna bağlanır.
    static let titresimBetigi = """
    (function () {
      if (typeof navigator.vibrate === 'function') return;
      navigator.vibrate = function (desen) {
        try {
          var liste = Array.isArray(desen) ? desen : [desen];
          window.webkit.messageHandlers.titresim.postMessage(liste);
          return true;
        } catch (e) { return false; }
      };
    })();
    """

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "adres":
            if let a = message.body as? String { KabukDurumu.shared.siteAdresiGeldi(a) }
        case "titresim":
            Titresim.desen((message.body as? [Any])?.compactMap { ($0 as? NSNumber)?.doubleValue } ?? [1])
        default:
            return
        }
    }

    // MARK: Bağlantı yok

    static let baglantiYokSayfasi = """
    <!doctype html><html lang="tr"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <meta name="theme-color" content="#121110">
    <style>
      body { margin:0; min-height:100vh; display:flex; flex-direction:column; align-items:center; justify-content:center;
             background:#121110; color:#e9e4dc; font:17px -apple-system, system-ui; text-align:center; padding:32px; box-sizing:border-box; }
      h1 { font-family: "New York", Georgia, serif; font-weight:600; font-size:28px; margin:0 0 12px; }
      p { color:#a8a199; line-height:1.5; margin:0 0 28px; max-width:320px; }
      a { color:#121110; background:#e9e4dc; text-decoration:none; padding:12px 28px; border-radius:999px; font-weight:600; }
    </style></head><body>
      <h1>Nora Sanat</h1>
      <p>İlk açılış için internete bağlanman gerekiyor. Bir kez açıldıktan sonra internetsiz de çalışır.</p>
      <a href="https://sanat-atlasi.pages.dev/">Tekrar dene</a>
    </body></html>
    """
}

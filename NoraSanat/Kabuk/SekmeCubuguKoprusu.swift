// Kaynak: sanat-atlasi js/ekranlar/ortak.js (sekmeRozetiBagla), js/ekranlar/bugun.js (turBilgisi),
// js/ekranlar/hizliAyar.js @ a866b86
import Foundation
import NoraCekirdek
import WebKit

/// Yerli sekme çubuğunun (T4) siteyle konuştuğu yer: Çalış rozeti ve hızlı ayarlar. Kurallar sitede kalır; betikler
/// sitenin kendi modüllerini çağırır. Betikler `Testler/kahin/sekme_cubugu.mjs` ile canlı sitede sınanır.
@MainActor
enum SekmeCubuguKoprusu {
    /// Çalış rozetindeki sayı: sitenin `sekmeRozetiBagla(() => (d.ilerleme ? turBilgisi('karisik').toplam : 0))`'ı
    static let rozetBetigi = """
    const o = await import('/js/ekranlar/ortak.js');
    if (!o.d.ilerleme) return null;
    const b = await import('/js/ekranlar/bugun.js');
    return b.turBilgisi('karisik').toplam;
    """

    /// Hızlı ayarların bugünkü değerleri
    static let okumaBetigi = """
    const o = await import('/js/ekranlar/ortak.js');
    if (!o.d.ilerleme) return null;
    const a = o.d.ilerleme.ayarlar;
    return { tema: a.tema, hareket: a.hareket || 'tam', gunlukKart: a.gunlukKart };
    """

    /// Argümanlar: `alan` ("tema" | "hareket" | "kart"), `deger` (tema/hareket adı ya da kart adımı ±5).
    /// Sitenin yaprağındaki dinleyicilerle aynı: değer geçerliyse yazılır, `kaydet()`; tema ve harekette `temaUygula()`.
    static let yazmaBetigi = """
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    if (!o.d.ilerleme) return null;
    const a = o.d.ilerleme.ayarlar;
    if (alan === 'kart') {
      a.gunlukKart = Math.min(100, Math.max(5, a.gunlukKart + Number(deger)));
      o.kaydet();
    } else {
      if (alan === 'tema' && depo.TEMALAR.includes(deger)) a.tema = deger;
      else if (alan === 'hareket' && depo.HAREKETLER.includes(deger)) a.hareket = deger;
      else return null;
      o.kaydet();
      o.temaUygula();
    }
    return { tema: a.tema, hareket: a.hareket || 'tam', gunlukKart: a.gunlukKart };
    """

    struct Ayarlar: Equatable {
        var tema = "gece", hareket = "tam", gunlukKart = 20

        init() {}
        init?(_ x: Any?) {
            guard let d = x as? [String: Any] else { return nil }
            tema = d["tema"] as? String ?? tema
            hareket = d["hareket"] as? String ?? hareket
            gunlukKart = (d["gunlukKart"] as? NSNumber)?.intValue ?? gunlukKart
        }
    }

    private static func calistir(_ govde: String, _ arguman: [String: Any] = [:]) async -> Any? {
        guard Gezgin.shared.yuklendi, let w = Gezgin.shared.webView else { return nil }
        return try? await w.callAsyncJavaScript(govde, arguments: arguman, in: nil, contentWorld: .page)
    }

    static func rozet() async -> Int? { (await calistir(rozetBetigi) as? NSNumber)?.intValue }

    static func ayarlar() async -> Ayarlar? { Ayarlar(await calistir(okumaBetigi)) }

    static func yaz(_ alan: String, _ deger: Any) async -> Ayarlar? {
        let sonuc = Ayarlar(await calistir(yazmaBetigi, ["alan": alan, "deger": deger]))
        if sonuc != nil { KabukDurumu.shared.rozetiYenile() }   // günlük kart turu değiştirir
        return sonuc
    }
}

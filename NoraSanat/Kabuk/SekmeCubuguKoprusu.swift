// Kaynak: sanat-atlasi js/ekranlar/ortak.js (sekmeRozetiBagla), js/ekranlar/bugun.js (turBilgisi),
// js/ekranlar/hizliAyar.js @ a866b86
import Foundation
import NoraCekirdek
import WebKit

/// Yerli sekme çubuğunun (T4) Çalış rozeti (sitenin betiği; Z2b'den beri site Swift'in aynası) ve hızlı ayarlar
/// (Z2b: Swift'teki kayıt). Betikler `Testler/kahin/sekme_cubugu.mjs` ile canlı sitede sınanır.
@MainActor
enum SekmeCubuguKoprusu {
    /// Çalış rozetindeki sayı: sitenin `sekmeRozetiBagla(() => (d.ilerleme ? turBilgisi('karisik').toplam : 0))`'ı
    static let rozetBetigi = """
    const o = await import('/js/ekranlar/ortak.js');
    if (!o.d.ilerleme) return null;
    const b = await import('/js/ekranlar/bugun.js');
    return b.turBilgisi('karisik').toplam;
    """

    struct Ayarlar: Equatable {
        var tema = "gece", hareket = "tam", gunlukKart = 20

        init() {}
        init(_ il: Ilerleme) {
            tema = il.ayar("tema")?.metin ?? tema
            hareket = il.ayar("hareket")?.metin ?? hareket
            gunlukKart = il.ayar("gunlukKart")?.tamSayi ?? gunlukKart
        }
    }

    private static func calistir(_ govde: String, _ arguman: [String: Any] = [:]) async -> Any? {
        guard Gezgin.shared.yuklendi, let w = Gezgin.shared.webView else { return nil }
        return try? await w.callAsyncJavaScript(govde, arguments: arguman, in: nil, contentWorld: .page)
    }

    static func rozet() async -> Int? { (await calistir(rozetBetigi) as? NSNumber)?.intValue }

    /// Z2b: ayarlar Swift'teki kayıttan
    static func ayarlar() async -> Ayarlar? { (try? await IlerlemeKoprusu.shared.oku()).map(Ayarlar.init) }

    /// Sitenin yaprağındaki dinleyicilerle aynı kural (js/ekranlar/hizliAyar.js): `alan` "tema" | "hareket" | "kart";
    /// değer geçerliyse yazılır. Kayıt siteye aynalanır, site temayı uygular (`TemaKoprusu` oradan okur).
    static func yaz(_ alan: String, _ deger: Any) async -> Ayarlar? {
        let kopru = IlerlemeKoprusu.shared
        guard let il = try? await kopru.degistir({ il in
            switch alan {
            case "kart":
                let n = il.ayar("gunlukKart")?.tamSayi ?? 20
                il.ayarla("gunlukKart", .sayi(Double(min(100, max(5, n + ((deger as? Int) ?? 0))))))
            case "tema" where IlerlemeKurallari.temalar.contains(deger as? String ?? ""):
                il.ayarla("tema", .metin(deger as! String))
            case "hareket" where IlerlemeKurallari.hareketler.contains(deger as? String ?? ""):
                il.ayarla("hareket", .metin(deger as! String))
            default: break
            }
        }) else { return nil }
        await kopru.aynaBitsin()
        KabukDurumu.shared.rozetiYenile()   // günlük kart turu değiştirir
        return Ayarlar(il)
    }
}

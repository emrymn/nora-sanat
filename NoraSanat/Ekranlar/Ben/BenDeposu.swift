// Kaynak: sanat-atlasi js/depo.js, js/ekranlar/{ortak,ayarlar}.js, js/devam.js @ a866b86
// Z2b: yedek, geri yükleme ve geliştirici modu Swift'te (IlerlemeKoprusu, IlerlemeKurallari); site yalnız ayna.
import NoraCekirdek
import SwiftUI
import WebKit

extension IlerlemeKoprusu {
    /// Sitedeki kayıt doğrulaması ve yarım oturum aynı WebKit oturumunda çalışır.
    func benBetigi(_ kaynak: String, _ veri: [String: Any] = [:]) async throws -> Any? {
        let web = try await hazirSite()
        await aynaBitsin()
        return try await web.callAsyncJavaScript(kaynak, arguments: veri, in: nil, contentWorld: .page)
    }
    /// Geliştirici modunun açtığı her şey: bütün konu numaraları ve harita bölümleri (sitenin listeleri; Z2c'de Swift)
    static let benGelistiriciListeleri = """
    const o = await import('/js/ekranlar/ortak.js');
    const { bolumler } = await import('/js/ekranlar/harita.js');
    const d = o.d;
    const nolar = [...d.konular.map(k => k.no), ...d.sanatcilar.map(s => s.konu)].filter(Number.isInteger);
    return { nolar, bolumler: bolumler().map(b => b.id) };
    """
}

@MainActor @Observable
final class BenDeposu {
    let kopru = IlerlemeKoprusu.shared
    private let veri = SiteVerisi()
    var il: Ilerleme?
    var katalog: SiteKatalogu?
    var adlar: JSONDeger?
    var mesgul = false
    var mesaj: String?
    var bugun: String { GunTarihi.gun(Date()) }
    func yenile() async {
        guard !mesgul else { return }
        mesgul = true
        defer { mesgul = false }
        do {
            il = try await kopru.oku()
            if katalog == nil {
                async let k = veri.katalog()
                async let ceviri = veri.veri("konular_tr.json")
                katalog = try await k
                if let data = await ceviri { adlar = try? JSONDeger.coz(data) }
            }
        } catch { hata(error) }
    }
    /// `bitti`: işlem ve yeniden okuma başarılıysa yeni ilerlemeyle çağrılır (C4b: Tanış kartı)
    func yap(bitti: (@MainActor (Ilerleme) -> Void)? = nil, _ islem: @escaping @MainActor () async throws -> Void) {
        guard !mesgul else { return }
        mesgul = true
        Task {
            defer { mesgul = false }
            var tamam = true
            do { try await islem() } catch { hata(error); tamam = false }
            do {
                let yeni = try await kopru.oku()
                il = yeni
                if tamam { bitti?(yeni) }
            } catch { hata(error) }
        }
    }
    func degistir(sonra: String? = nil, bitti: (@MainActor (Ilerleme) -> Void)? = nil,
                  _ islem: @escaping (inout Ilerleme) -> Void) {
        yap(bitti: bitti) {
            _ = try await self.kopru.degistir(islem)
            await self.kopru.aynaBitsin()
            if let sonra { _ = try await self.kopru.benBetigi(sonra) }
        }
    }
    func hata(_ error: Error) {
        let e = error as NSError
        mesaj = (e.userInfo["WKJavaScriptExceptionMessage"] as? String) ?? e.localizedDescription
    }
}

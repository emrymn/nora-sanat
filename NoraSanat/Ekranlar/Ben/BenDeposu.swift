// Kaynak: sanat-atlasi js/depo.js, js/ekranlar/{ortak,ayarlar}.js, js/devam.js @ a866b86
import NoraCekirdek
import SwiftUI
import WebKit

extension IlerlemeKoprusu {
    /// Sitedeki kayıt doğrulaması ve yarım oturum aynı WebKit oturumunda çalışır.
    func benBetigi(_ kaynak: String, _ veri: [String: Any] = [:]) async throws -> Any? {
        guard let web = Gezgin.shared.webView, Gezgin.shared.yuklendi else { throw Hata.siteYok }
        return try await web.callAsyncJavaScript(kaynak, arguments: veri, in: nil, contentWorld: .page)
    }
    static let benYedekAl = """
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    if (!o.d.ilerleme) throw Error('İlerleme yüklenmedi.');
    (await import('/js/ekranlar/bugun.js')).yedekTarihiYaz();
    return depo.yedekMetni(o.d.ilerleme, o.d.yarim);
    """
    static let benGeriYukle = """
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    const { kayitGecerliMi } = await import('/js/devam.js');
    const { idbKoy } = await import('/js/idb.js');
    const { yarimSil } = await import('/js/ekranlar/pekistir.js');
    const yeni = depo.yedekCoz(metin);
    const yarim = depo.yedekYarimOturum(metin);
    if ((o.d.ilerleme?.kayitNo || 0) !== beklenen) throw Error('İlerleme değişti. Yedeği yeniden denetle.');
    depo.kayitKilidiniAc();
    o.d.ilerleme = yeni;
    o.d.oturum = null;
    if (kayitGecerliMi(yarim)) {
      o.d.yarim = yarim;
      idbKoy('oturum', 'yarim', yarim);
    } else yarimSil();
    o.kaydet();
    o.temaUygula();
    return true;
    """
    static let benGelistirici = """
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    const { bolumler } = await import('/js/ekranlar/harita.js');
    const { kayitGecerliMi } = await import('/js/devam.js');
    const { yarimSil } = await import('/js/ekranlar/pekistir.js');
    const { idbKoy } = await import('/js/idb.js');
    if (depo.kayitKilitliMi()) throw Error('Kayıt kilitli.');
    const d = o.d;
    if (!!d.ilerleme.gelistirici === ac) return;
    if (ac) {
      const nolar = [...d.konular.map(k => k.no), ...d.sanatcilar.map(s => s.konu)].filter(Number.isInteger);
      d.ilerleme = depo.gelistiriciAc(d.ilerleme, nolar, bolumler().map(b => b.id), d.yarim);
    } else {
      const { ilerleme, yarim } = depo.gelistiriciKapat(d.ilerleme);
      d.ilerleme = ilerleme;
      if (kayitGecerliMi(yarim)) {
        d.yarim = yarim;
        idbKoy('oturum', 'yarim', yarim);
      } else yarimSil();
    }
    d.oturum = null;
    o.kaydet();
    o.temaUygula();
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
    func yap(_ islem: @escaping @MainActor () async throws -> Void) {
        guard !mesgul else { return }
        mesgul = true
        Task {
            defer { mesgul = false }
            do { try await islem() } catch { hata(error) }
            do { il = try await kopru.oku() } catch { hata(error) }
        }
    }
    func degistir(sonra: String? = nil, _ islem: @escaping (inout Ilerleme) -> Void) {
        yap {
            _ = try await self.kopru.degistir(islem)
            if let sonra { _ = try await self.kopru.benBetigi(sonra) }
        }
    }
    func hata(_ error: Error) {
        let e = error as NSError
        mesaj = (e.userInfo["WKJavaScriptExceptionMessage"] as? String) ?? e.localizedDescription
    }
}

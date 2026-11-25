// Kaynak: sanat-atlasi js/depo.js, js/ekranlar/{ortak,ayarlar}.js, js/devam.js @ a866b86
// Z2b: yedek, geri yükleme ve geliştirici modu Swift'te (IlerlemeKoprusu, IlerlemeKurallari); site yalnız ayna.
import NoraCekirdek
import SwiftUI
import WebKit

extension IlerlemeKoprusu {
    /// Sitedeki kayıt doğrulaması ve yarım oturum aynı WebKit oturumunda çalışır. Kayıt artık dosyadan anında
    /// okunduğu için betikten önce sitenin kendi ilerlemesinin (`d.ilerleme`) yüklenmesi ve aynanın bitmesi beklenir.
    func benBetigi(_ kaynak: String, _ veri: [String: Any] = [:]) async throws -> Any? {
        let web = try await hazirSite()
        await aynaBitsin()
        guard try await web.callAsyncJavaScript(Self.siteIlerlemesiBetigi, arguments: [:], in: nil, contentWorld: .page) as? Bool == true
        else { throw Hata.siteYok }
        return try await web.callAsyncJavaScript(kaynak, arguments: veri, in: nil, contentWorld: .page)
    }
    /// Sitenin açılışı `d.ilerleme`'yi kurana kadar (en çok 10 sn) bekler
    static let siteIlerlemesiBetigi = """
    const o = await import('/js/ekranlar/ortak.js');
    for (let i = 0; i < 100 && !o.d.ilerleme; i++) await new Promise((r) => setTimeout(r, 100));
    return !!o.d.ilerleme;
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
    func degistir(bitti: (@MainActor (Ilerleme) -> Void)? = nil, _ islem: @escaping (inout Ilerleme) -> Void) {
        yap(bitti: bitti) {
            _ = try await self.kopru.degistir(islem)
            await self.kopru.aynaBitsin()
        }
    }

    // MARK: Z2c-3: sitenin Ayarlar betikleri Swift'te

    /// Günün sanatçısı havuzu ve bugünkü (sitenin `gununHavuzu()` / `gununId()`'si)
    private func gunun() async -> (havuz: [String], id: String?) {
        guard let y = await veri.veri("yuruyus.json") else { return ([], nil) }
        let havuz = GununTablosuCozucu.havuz(yuruyus: y)
        let d = il?[alan: "gununDegisim"]
        if d?["tarih"]?.metin == bugun, let id = d?["id"]?.metin, havuz.contains(id) { return (havuz, id) }
        return (havuz, GununSanatcisi.sec(havuz: havuz, tarih: bugun))
    }

    /// "Başka bir sanatçı getir": `baskaSanatci(gununHavuzu(), gununId(), Math.random)`
    func baskaSanatci() async -> String? {
        let g = await gunun()
        guard let id = g.id else { return nil }
        return GununSanatcisi.baska(havuz: g.havuz, haric: id)
    }

    /// Sitenin sürümü (`js/surum.js` `SURUM`); `zorla`: önbelleği atlayıp siteden yeniden indir
    func siteSurumu(zorla: Bool = false) async -> String? {
        guard let d = await veri.kokDosyasi("js/surum.js", zorla: zorla) else { return nil }
        let m = String(decoding: d, as: UTF8.self)
        guard let r = m.range(of: #"SURUM\s*=\s*['"]([^'"]+)['"]"#, options: .regularExpression) else { return nil }
        let p = m[r]
        guard let a = p.firstIndex(where: { $0 == "'" || $0 == "\"" }) else { return nil }
        return String(p[p.index(after: a)...].dropLast())
    }

    /// "Yeni sürüm var mı?": sitenin verisini yeniden indirir. Katalog hemen; öteki dosyalar (Bugün'ün yürüyüş ve
    /// odak dosyaları dahil) eskimiş sayılır ve ekran onları ilk istediğinde yenisi iner.
    func veriyiYenile() async -> String {
        let eski = await siteSurumu()
        guard let yeni = await siteSurumu(zorla: true) else { return "Siteye ulaşılamadı; çevrimdışı veriyle devam." }
        await veri.hepsiniEskit()
        _ = await veri.kokDosyasi("js/yenilikler.js", zorla: true)   // Z3x: sürüm notları da yenilensin
        if let k = try? await veri.katalog(zorla: true) { katalog = k }
        return yeni == eski ? "Güncel: \(yeni)" : "\(yeni) indirildi."
    }

    /// Geliştirici modunun açtığı her şey: bütün konu numaraları ve harita bölümleri
    /// (`[...d.konular.map(k => k.no), ...d.sanatcilar.map(s => s.konu)].filter(Number.isInteger)`, `bolumler()`)
    func gelistiriciListeleri() -> (nolar: [Int], bolumler: [String])? {
        guard let k = katalog else { return nil }
        let nolar = k.konular.map(\.no) + k.sanatcilar.compactMap(\.konu)
        let bolumler = CalisDersKurallari.bolumleriKur(akimlar: k.akimlar, sanatcilar: k.sanatcilar).map(\.id)
        return (nolar, bolumler)
    }

    /// "Sırayla ortala": günün resmi olabilecek yürüyüş eserleri, yalnız yürüyüş görseliyle (sitenin `odakAc`'ı)
    func yuruyusEserleri() async -> [Eser] {
        guard let k = katalog, let y = await veri.veri("yuruyus.json"),
              let es = (try? JSONDeger.coz(y))?["eserler"] else { return [] }
        return k.sanatcilar.compactMap { s -> Eser? in
            guard let ad = es[s.id]?["gorsel"]?.metin, !ad.isEmpty else { return nil }
            let uygun: (Gorsel) -> Bool = { k.gorsel.yerelAd($0) == ad }
            guard var e = k.eserler(s.id).first(where: { $0.gorseller.contains(where: uygun) }) else { return nil }
            e.gorseller = e.gorseller.filter(uygun)
            return e
        }
    }

    /// Ayarlar'ın bilgi satırları (sitenin betiği yerine)
    func ayarBilgisi() async -> AyarBilgisi {
        var b = AyarBilgisi()
        let g = await gunun()
        if let id = g.id { b.gunun = katalog?.bilinenAd(id) ?? id }
        b.surum = await siteSurumu() ?? ""
        b.odak = ElleOdaklar.hepsi.count
        if let y = await veri.veri("yuruyus.json"), let k = katalog {
            let havuz = Set(GununTablosuCozucu.havuz(yuruyus: y))
            let kayitli = (try? JSONDeger.coz(y))?["eserler"]?.nesne.map { Set($0.ciftler.map(\.anahtar)) } ?? havuz
            b.yuruyus = k.sanatcilar.filter { kayitli.contains($0.id) }.count
        }
        b.egimVar = BugunHareketi.egimVarMi
        for r in GunduzPaleti.renkler {
            if let p = TemaHesabi.gunduzOrnekPaleti(r) { b.paletler[r] = [p.band, p.altin, p.surface, p.border] }
        }
        return b
    }
    func hata(_ error: Error) {
        let e = error as NSError
        let m = (e.userInfo["WKJavaScriptExceptionMessage"] as? String) ?? e.localizedDescription
        mesaj = m
        HataGunluguDeposu.shared.ekle("ben", m)   // Z3x: Ayarlar → Gelişmiş → Hata günlüğü
    }

    // MARK: Z3x: Hakkında

    /// Sitenin sürüm notları (`js/yenilikler.js`; tek kaynak site, çevrimdışıyken son inen). `zorla`: yeniden indir.
    func yenilikler(zorla: Bool = false) async -> [Yenilik] {
        guard let d = await veri.kokDosyasi("js/yenilikler.js", zorla: zorla) else { return [] }
        return Yenilikler.coz(String(decoding: d, as: UTF8.self))
    }
}

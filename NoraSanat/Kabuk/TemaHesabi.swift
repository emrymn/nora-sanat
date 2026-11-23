// Kaynak: sanat-atlasi js/ekranlar/ortak.js (temaUygula, gununRengi, ekranRengi, renkleriYaz, gunduzRenginiUygula,
// temaZemini), js/renk.js (resimdenOku, paletGetir, tonlariGetir) @ a866b86
import NoraCekirdek
import UIKit

/// Z2c-2: uygulamanın renkleri artık siteden okunmaz. Sitenin yaptığı gibi:
/// - tema (Gece / Gündüz), hareket ve yazı ayarları kayıttan (`IlerlemeKoprusu`);
/// - renkli Gündüz'de palet hazır pigmentlerden ya da (otomatik) günün tablosunun renk ailelerinden (`GunduzPaleti`);
/// - vurgu (`--vurgu…`) günün tablosunun paletinden (`ResimRengi.renkTemasi`; sitenin `gununRengi`'si), görsel yoksa
///   sanatçının akım rengi.
/// Tablodan çıkan paletler cihazda saklanır (sitedeki gibi): açılışta önce saklı renkler, tablo gelince yenisi.
@MainActor
enum TemaHesabi {
    private static let site = SiteVerisi()
    private static var gorev: Task<Void, Never>?
    /// Son hesabın girdileri: kayıt her yazıldığında çağrılır, yalnız bunlar değişince yeniden hesaplanır
    private static var sonImza = ""
    private static var katalog: SiteKatalogu?

    private enum Anahtar {
        static let gunduz = "nora.tema.gunduz.v1"
        static let vurgu = "nora.tema.vurgu.v1"
    }

    /// Otomatik Gündüz paleti, günün tablosuna bağlı (sitenin `sanat-atlasi:gunduz-renk`'i)
    private struct GunduzKaydi: Codable { var id: String; var palet: GunduzPaleti }
    /// Vurgu paleti, tablonun adresine bağlı (sitenin IndexedDB `palet`'i)
    private struct VurguKaydi: Codable { var url: String; var palet: [ResimRengi.PaletRengi] }

    private static func oku<T: Decodable>(_ anahtar: String) -> T? {
        UserDefaults.standard.data(forKey: anahtar).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private static func yaz<T: Encodable>(_ deger: T, _ anahtar: String) {
        UserDefaults.standard.set(try? JSONEncoder().encode(deger), forKey: anahtar)
    }

    /// Açılışta, uygulamaya dönünce (gün değişmiş olabilir) ve kayıt her yazıldığında. Tema ayarları, günün sanatçısı
    /// değişimi ve tarih aynıysa bir şey yapmaz.
    static func yenile() {
        gorev?.cancel()
        gorev = Task { await hesapla() }
    }

    private static func hesapla() async {
        guard let il = try? await IlerlemeKoprusu.shared.oku() else { return }
        let imza = ["tema", "gunduzRenk", "hareket", "yazi"].map { il.ayar($0)?.jsonMetni ?? "-" }.joined(separator: "|")
            + "|" + (il[alan: "gununDegisim"]?.jsonMetni ?? "-") + "|" + GunTarihi.gun(Date())
        guard imza != sonImza else { return }
        let ad = TemaAdi(rawValue: il.ayar("tema")?.metin ?? "") ?? .gece
        var ayar = TemaAyari(tema: ad)
        if let h = il.ayar("hareket")?.metin, !h.isEmpty { ayar.hareket = h }
        if let y = il.ayar("yazi")?.metin, !y.isEmpty { ayar.yazi = y }
        let secim = il.ayar("gunduzRenk")?.metin ?? GunduzPaleti.varsayilan

        // Önce saklı renklerle (beklemeden)
        let sakliGunduz: GunduzKaydi? = oku(Anahtar.gunduz)
        let sakliVurgu: VurguKaydi? = oku(Anahtar.vurgu)
        func gunduzPaleti(_ otomatik: GunduzPaleti?) -> GunduzPaleti? {
            guard ad == .gunduz else { return nil }
            if secim == "otomatik" { return otomatik ?? GunduzPaleti.hazir[GunduzPaleti.yedek] }
            return GunduzPaleti.sec(secim, tonlar: nil)
        }
        func uygula(_ g: GunduzPaleti?, _ palet: [ResimRengi.PaletRengi]?) {
            let zemin = TemaRenkleri.zeminHex(ad, gunduz: g)
            let vurgu = palet.flatMap { ResimRengi.renkTemasi($0, zemin: zemin) }
            TemaDeposu.shared.uygula(TemaRenkleri.hesapla(ad, gunduz: g, vurgu: vurgu), ayar: ayar,
                                     zemin: RGBA(css: zemin) ?? TemaRenkleri.sabit(ad).zemin)
        }
        uygula(gunduzPaleti(sakliGunduz?.palet), sakliVurgu?.palet)

        // Sonra günün tablosundan
        guard let (id, url, akimRengi) = await gununTablosu(il), !Task.isCancelled else { return }
        var otomatik = sakliGunduz?.palet
        if ad == .gunduz, secim == "otomatik", sakliGunduz?.id != id, let url,
           let tonlar = await pikseller(url, uzun: 96).map(ResimRengi.tonlariHesapla) {
            // Renksiz tabloda (gravür) hazır yedek; görsel açılmadıysa saklanmaz, sonra yeniden denenir
            let p = GunduzPaleti.sec("otomatik", tonlar: tonlar) ?? GunduzPaleti.hazir[GunduzPaleti.yedek]!
            yaz(GunduzKaydi(id: id, palet: p), Anahtar.gunduz)
            otomatik = p
        }
        var palet = sakliVurgu?.url == url?.absoluteString ? sakliVurgu?.palet : nil
        if palet == nil, let url, let px = await pikseller(url, uzun: 64) {
            let p = ResimRengi.paletHesapla(px)
            if !p.isEmpty { yaz(VurguKaydi(url: url.absoluteString, palet: p), Anahtar.vurgu); palet = p }
        }
        // Görsel açılmadıysa sitenin yedeği: akımın rengi (tek renkli palet)
        if palet == nil, let akimRengi, !akimRengi.isEmpty { palet = [.init(renk: akimRengi, pay: 1)] }
        guard !Task.isCancelled else { return }
        uygula(gunduzPaleti(otomatik), palet)
        // Görsel açılmadıysa (çevrimdışı) imza yazılmaz: sonraki çağrıda yeniden denenir
        if url == nil || palet != nil { sonImza = imza }
    }

    /// Günün sanatçısı (kimlik: tarih + sanatçı), tablosunun görseli ve akımının rengi (Bugün'deki tablo)
    private static func gununTablosu(_ il: Ilerleme) async -> (String, URL?, String?)? {
        let tarih = GunTarihi.gun(Date())
        async let dosyalar = site.veriler(GununTablosuCozucu.dosyalar + ["biyografiler.json", "tanima_notlari.json", "imzalar.json", "kunye.json"])
        if katalog == nil { katalog = try? await site.katalog() }
        guard let katalog,
              let s = try? BugunTablosu(tarih: tarih, degisim: il[alan: "gununDegisim"], veriler: await dosyalar, katalog: katalog)
        else { return nil }
        let akim = katalog.sanatcilar.first { $0.id == s.tablo.sanatciId }?.akim
        let renk = katalog.akimlar.first { $0.ad == akim }?.renk
        return (tarih + "|" + s.tablo.sanatciId, s.tablo.gorsel, renk)
    }

    /// Sitenin `resimdenOku(url, n)`'u: uzun kenarı `uzun` piksel RGBA
    private static func pikseller(_ url: URL, uzun n: Int) async -> [UInt8]? {
        guard let resim = await GorselCozucu.shared.resim(url, piksel: 400), let cg = resim.cgImage else { return nil }
        return await Task.detached(priority: .utility) { () -> [UInt8]? in
            let oran = Double(cg.width) / Double(max(1, cg.height))
            let w = oran >= 1 ? n : max(8, Int((Double(n) * oran).rounded()))
            let h = oran >= 1 ? max(8, Int((Double(n) / oran).rounded())) : n
            var veri = [UInt8](repeating: 0, count: w * h * 4)
            let tamam = veri.withUnsafeMutableBytes { tampon -> Bool in
                guard let baglam = CGContext(data: tampon.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                baglam.interpolationQuality = .high
                baglam.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
                return true
            }
            return tamam ? veri : nil
        }.value
    }
}

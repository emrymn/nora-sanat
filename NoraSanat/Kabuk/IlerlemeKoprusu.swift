import Foundation
import NoraCekirdek
import WebKit

/// İlerlemenin okunup yazıldığı tek yer (ISLER.md K2, Z2).
///
/// Z2b'den beri asıl kayıt Swift'te: `Application Support/Ilerleme/ilerleme.json` (`IlerlemeDosyasi`; sitenin
/// js/depo.js kuralları `IlerlemeKurallari`'nda). Uygulama bu sürümle ilk açıldığında sitenin ilerlemesi bir kez okunup
/// dosyaya yazılır (taşıma; sitedeki veri silinmez). Sonra site yalnız bir aynadır: her kayıt siteye de yazılır
/// (`aynaBetigi`), böylece sitenin hâlâ okuduğu şeyler (tema renkleri, Çalış rozeti, tekrar takvimi, Ben'in bazı
/// betikleri, CI'daki site karşılaştırmaları) aynı veriyi görür. Z2c'de site tamamen kalkar.
///
/// - `oku()`: kaydı verir (ilk açılışta taşımayı bekler).
/// - `yaz(_:)`: okunduğundan beri başka kayıt olduysa (`kayitNo` değiştiyse) yazmaz, `.cakisma` atar.
/// - `degistir { … }`: oku → değiştir → yaz; çakışmada taze kayıtla yeniden dener. Swift ekranları bunu kullanmalı.
@MainActor
final class IlerlemeKoprusu {
    static let shared = IlerlemeKoprusu()

    enum Hata: Error, Equatable {
        /// Taşıma için site açılmadı (internet yok, ilk açılış) ya da beklerken süre doldu
        case siteYok
        /// Kayıt okunamadı ve kilitlendi (dosyada ya da taşımada sitenin kayitKilidi)
        case kilitli
        /// Okunduktan sonra başka bir kayıt oldu
        case cakisma
        case bozuk(String)
    }

    /// Taşımada sitenin yüklenmesi için en çok bu kadar beklenir
    var bekleme: TimeInterval = 30

    let dosya: IlerlemeDosyasi = {
        let kok = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return IlerlemeDosyasi(klasor: kok.appendingPathComponent("Ilerleme", isDirectory: true))
    }()
    private var kayit: SiraliNesne?
    private var yukleme: Task<SiraliNesne, Error>?

    static var bugun: String { GunTarihi.gun(Date()) }
    static var simdi: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    /// Taşımada sitenin ilerlemesi: site hazır olana kadar bekler. Site kaydı okuyamayıp kilitlediyse (boş ilerlemeyle
    /// açıldıysa) taşınmaz.
    static let okumaBetigi = """
    /* OKU-BASI */
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    for (let i = 0; i < 100 && !o.d.ilerleme; i++) await new Promise((r) => setTimeout(r, 100));
    if (!o.d.ilerleme) return null;
    if (depo.kayitKilitliMi()) return 'kilitli';
    return JSON.stringify(o.d.ilerleme);
    /* OKU-SONU */
    """

    /// Ayna: Swift'teki kaydı sitenin belleğine ve deposuna yazar (`metin`), temayı uygular. Dönen: true ya da null.
    static let aynaBetigi = """
    /* AYNA-BASI */
    const o = await import('/js/ekranlar/ortak.js');
    const depo = await import('/js/depo.js');
    for (let i = 0; i < 100 && !o.d.ilerleme; i++) await new Promise((r) => setTimeout(r, 100));
    if (!o.d.ilerleme) return null;
    const yeni = JSON.parse(metin);
    if (!yeni || typeof yeni !== 'object' || Array.isArray(yeni)) throw new Error('ilerleme nesne değil');
    depo.kayitKilidiniAc();
    for (const k of Object.keys(o.d.ilerleme)) if (!(k in yeni)) delete o.d.ilerleme[k];
    Object.assign(o.d.ilerleme, yeni);
    o.kaydet();
    o.temaUygula();
    return true;
    /* AYNA-SONU */
    """

    private func betik(_ kaynak: String, _ bas: String, _ son: String) -> String {
        guard let a = kaynak.range(of: bas), let b = kaynak.range(of: son) else { return kaynak }
        return String(kaynak[a.upperBound..<b.lowerBound])
    }

    /// Site yüklenene kadar bekler (en çok `bekleme`); WKWebView'i verir. Site betiği çalıştıran her yer bunu kullanır:
    /// Z2b'den beri `oku()` siteyi beklemediği için betikler sitenin yüklenmesini kendileri beklemeli.
    func hazirSite() async throws -> WKWebView {
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

    /// Dosyadaki kayıt; yoksa siteden taşıma. Başarısız olursa bir sonraki çağrıda yeniden denenir.
    private func yuklu() async throws -> SiraliNesne {
        if let kayit { return kayit }
        if let yukleme { return try await yukleme.value }
        let t = Task { () throws -> SiraliNesne in
            do {
                if let k = try dosya.oku(bugun: Self.bugun, simdi: Self.simdi) { return k }
            } catch IlerlemeDosyasi.Hata.okunamadi(let m) {
                throw Hata.bozuk(m)
            }
            return try await tasi()
        }
        yukleme = t
        do {
            let k = try await t.value
            kayit = k
            yukleme = nil
            return k
        } catch {
            yukleme = nil
            throw error
        }
    }

    /// Z2b taşıması: sitenin ilerlemesi bir kez Swift dosyasına (site verisine dokunulmaz)
    private func tasi() async throws -> SiraliNesne {
        let sonuc = try await calistir(betik(Self.okumaBetigi, "/* OKU-BASI */", "/* OKU-SONU */"))
        if sonuc as? String == "kilitli" { throw Hata.kilitli }
        guard let metin = sonuc as? String else { throw Hata.siteYok }
        let il: SiraliNesne
        do {
            il = try IlerlemeKurallari.dogrula(try JSONDeger.coz(Data(metin.utf8)), bugun: Self.bugun, simdi: Self.simdi)
        } catch { throw Hata.bozuk("\(error)") }
        // Dosya bu arada başka bir yoldan oluştuysa (iki çağrı) onu koru
        if dosya.varMi, let k = try? dosya.oku(bugun: Self.bugun, simdi: Self.simdi) { return k }
        return try dosya.yaz(il, beklenen: nil)
    }

    func oku() async throws -> Ilerleme {
        let k = try await yuklu()
        do { return try Ilerleme(json: .nesne(k)) } catch { throw Hata.bozuk("\(error)") }
    }

    /// `ilerleme` okunduğundan beri kayıt olmadıysa yazar; yeni kayıt numarasını döndürür
    @discardableResult
    func yaz(_ ilerleme: Ilerleme) async throws -> Int {
        _ = try await yuklu()
        guard let n = ilerleme.json.nesne else { throw Hata.bozuk("ilerleme nesne değil") }
        return try yazHam(n, beklenen: ilerleme.kayitNo)
    }

    /// Denetimsiz yazım (yedekten geri yükleme, geliştirici modu): `beklenen` nil ise numara denetlenmez
    @discardableResult
    func yazHam(_ n: SiraliNesne, beklenen: Int?) throws -> Int {
        let yeni: SiraliNesne
        do {
            yeni = try dosya.yaz(n, beklenen: beklenen)
        } catch IlerlemeDosyasi.Hata.cakisma {
            throw Hata.cakisma
        } catch IlerlemeDosyasi.Hata.okunamadi {
            throw Hata.kilitli
        }
        kayit = yeni
        aynala(yeni)
        KabukDurumu.shared.rozetiYenile()   // Çalış rozeti (T4): yazılan kart vadeyi değiştirmiş olabilir
        return Int(yeni["kayitNo"]?.sayi ?? 0)
    }

    private var aynaGorevi: Task<Void, Never>?
    /// Kaydı siteye de yazar (sırayla; hata olursa yalnız ayna eksik kalır, asıl kayıt dosyada)
    private func aynala(_ n: SiraliNesne) {
        let onceki = aynaGorevi
        let metin = JSONDeger.nesne(n).jsonMetni
        aynaGorevi = Task {
            await onceki?.value
            _ = try? await self.calistir(self.betik(Self.aynaBetigi, "/* AYNA-BASI */", "/* AYNA-SONU */"), ["metin": metin])
        }
    }

    /// Ayna yazımı bitene kadar bekler (sitenin hâlâ okuduğu bir şeyden önce: tema, rozet, site betikleri)
    func aynaBitsin() async { await aynaGorevi?.value }

    /// Oku → değiştir → yaz. Arada başka kayıt olduysa taze kayıtla en çok 3 kez yeniden dener.
    @discardableResult
    func degistir(_ blok: (inout Ilerleme) throws -> Void) async throws -> Ilerleme {
        var deneme = 0
        while true {
            var il = try await oku()
            try blok(&il)
            do {
                try await yaz(il)
                return try await oku()
            } catch Hata.cakisma where deneme < 2 {
                deneme += 1
            }
        }
    }

    // MARK: Yedek ve geliştirici modu (Ben → Ayarlar)

    /// "Yedekle": son yedek günü yazılır (`yedekTarihiYaz`), sitenin biçiminde yedek metni
    func yedekAl() async throws -> String {
        let il = try await degistir { $0[alan: "sonYedek"] = .metin(Self.bugun) }
        return IlerlemeKurallari.yedekMetni(il.json, tarih: Self.simdi)
    }

    /// Yedek metnini doğrular (`yedekCoz`); hata metni sitenin
    func yedekCoz(_ metin: String) throws -> SiraliNesne {
        do { return try IlerlemeKurallari.yedekCoz(metin, bugun: Self.bugun, simdi: Self.simdi) } catch let e as IlerlemeKurallari.Hata {
            throw NSError(domain: "Yedek", code: 1, userInfo: [NSLocalizedDescriptionKey: e.description])
        }
    }

    /// Yedekten geri yükler: kayıt denetlendiği andan beri değiştiyse yazmaz; kilit açılır
    func geriYukle(_ metin: String, beklenen: Int) async throws {
        let yeni = try yedekCoz(metin)
        guard try await oku().kayitNo == beklenen else {
            throw NSError(domain: "Yedek", code: 2, userInfo: [NSLocalizedDescriptionKey: "İlerleme değişti. Yedeği yeniden denetle."])
        }
        dosya.kilidiAc()
        try yazHam(yeni, beklenen: nil)
        await aynaBitsin()
    }

    /// Geliştirici modu (İş 42). `konular`, `bolumIdleri`: bütün konu numaraları ve harita bölümleri
    func gelistirici(ac: Bool, konular: [Int], bolumIdleri: [String]) async throws {
        let il = try await oku()
        guard let n = il.json.nesne, (n["gelistirici"]?.dogruMu ?? false) != ac else { return }
        let yeni: SiraliNesne
        if ac {
            yeni = IlerlemeKurallari.gelistiriciAc(n, konular: konular, bolumIdleri: bolumIdleri, simdi: Self.simdi)
        } else {
            yeni = try IlerlemeKurallari.gelistiriciKapat(n, bugun: Self.bugun, simdi: Self.simdi).ilerleme
        }
        try yazHam(yeni, beklenen: il.kayitNo)
        await aynaBitsin()
    }
}

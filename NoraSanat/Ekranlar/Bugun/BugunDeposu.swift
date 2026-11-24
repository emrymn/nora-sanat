// Kaynak: sanat-atlasi js/ekranlar/bugun.js, js/egim.js, js/gorsel.js (adlaOdak, yuruyusEki) @ a866b86
import CoreMotion
import NoraCekirdek
import SwiftUI

@Observable @MainActor
final class BugunDeposu {
  let site = SiteVerisi()
  var sayfa: BugunTablosu?
  var baglam: GoruntuleyiciBaglami?
  var imza: UIImage?
  var resim: UIImage?
  var odak = CGPoint(x: 0.5, y: 0.4)
  var yakin = 1.0
  var kirp: [Double]?
  var hata: String?
  var egimAcik = true
  var kucukler: [URL?] = []
  var kunye: JSONDeger?

  func yukle(tarih: String) async {
    do {
      let kopru = IlerlemeKoprusu.shared
      async let dosyalar = site.veriler(
        GununTablosuCozucu.dosyalar + [
          "biyografiler.json", "tanima_notlari.json", "imzalar.json", "kunye.json",
        ])
      async let kayitOku: Ilerleme? = try? kopru.oku()
      async let baglamYukle = GoruntuleyiciBaglami.yukle(siteVerisi: site)
      async let odakDosyalari = site.veriler(OdakVerisi.dosyalar)
      let b = await baglamYukle
      guard let katalog = b.katalog else { throw URLError(.notConnectedToInternet) }
      let ilerleme = await kayitOku
      let veriler = await dosyalar
      var degisim = ilerleme?[alan: "gununDegisim"]
      #if DEBUG
        if NoraSanatApp.arguman("-bugunKaydir") != nil, let id = NoraSanatApp.arguman("-bugunSanatci") {
          degisim = .nesne([("tarih", .metin(tarih)), ("id", .metin(id))])
        }
      #endif
      let s = try BugunTablosu(
        tarih: tarih, degisim: degisim,
        veriler: veriler, katalog: katalog)
      // Z2c-3: odak ve açılış ayarları sitenin veri dosyalarından ve bu cihazdaki elle odaklardan (js/gorsel.js)
      let odaklar = OdakVerisi(veriler: await odakDosyalari, cihaz: ElleOdaklar.hepsi)
      let ek = odaklar.yuruyusEki(s.kayit.gorsel)
      let imzalar = veriler["imzalar.json"].flatMap { try? JSONDeger.coz($0) }
      let imzaURL = imzalar?["imzalar"]?[s.tablo.sanatciId]?.metin.map { _ in
        SiteVerisi.site.appendingPathComponent("gorseller/imza/" + s.tablo.sanatciId + ".png")
      }
      async let imzaResmi = GorselCozucu.shared.resim(imzaURL, piksel: 640)
      // Z3r (telefon: "resimler bekleyince netleşiyor"): büyük kopya telefondaysa (dün önceden indi) küçük kopya hiç
      // gösterilmez; yoksa önce 1280'lik küçük kopya, büyük kopya inince o.
      let hdHazir = s.buyuk.map { $0 != s.tablo.gorsel && GorselDeposu.shared.diskte($0) != nil } ?? false
      var ilk: UIImage?
      if hdHazir { ilk = await GorselCozucu.shared.resim(s.buyuk, piksel: 4096) }
      if ilk == nil { ilk = await GorselCozucu.shared.resim(s.tablo.gorsel, piksel: 1920) }
      let imza = await imzaResmi
      try Task.checkCancellation()
      guard let ilk else { throw URLError(.cannotDecodeContentData) }
      egimAcik = ilerleme?.ayar("egim")?.mantik ?? true
      let merkez = odaklar.adlaOdak(s.kayit.gorsel) ?? [50, 40]
      odak = CGPoint(x: merkez[0] / 100, y: merkez[1] / 100)
      yakin = ek.yakin
      kirp = s.kayit.kirp ?? ek.kirp
      kucukler = (0..<4).map {
        katalog.eserGorselAdresi(
          s.tablo.sanatciId, sira: $0, kotuler: ilerleme?.kotuGorseller ?? [:])
      }
      kunye = veriler["kunye.json"].flatMap { try? JSONDeger.coz($0) }?["kunye"]?[s.tablo.sanatciId]
      self.imza = imza
      resim = ilk
      baglam = b
      sayfa = s
      hata = nil
      Self.yarinkiniHazirla(degisim: degisim, veriler: veriler, katalog: katalog)
      if !hdHazir, s.buyuk != s.tablo.gorsel, let hd = await GorselCozucu.shared.resim(s.buyuk, piksel: 4096),
        !Task.isCancelled
      {
        resim = hd
      }
    } catch {
      if !Task.isCancelled { hata = "Günün tablosu yüklenemedi." }
    }
  }
}

extension BugunDeposu {
  /// Z3r: yarının tablosunun büyük ve küçük kopyası bugünden, arka planda iner. Görsel önbelleğine (Caches/Gorseller,
  /// 400 MB) yazılır; ertesi gün açılışta doğrudan büyük kopya görünür.
  static func yarinkiniHazirla(degisim: JSONDeger?, veriler: [String: Data], katalog: SiteKatalogu) {
    guard let gun = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
      let y = try? BugunTablosu(tarih: GunTarihi.gun(gun), degisim: degisim, veriler: veriler, katalog: katalog)
    else { return }
    for u in [y.buyuk, y.tablo.gorsel].compactMap({ $0 }) where GorselDeposu.shared.diskte(u) == nil {
      Task.detached(priority: .background) { _ = try? await GorselDeposu.shared.veri(u) }
    }
  }
}

@MainActor @Observable
final class BugunHareketi {
  private let aygit = CMMotionManager()
  var deger: CGPoint?
  /// Sitedeki `egimVar()` gibi: simülatörde de eğim "var" (WKWebView orada da devicemotion verir; CI site ile aynı kalsın)
  /// Ayarlar'daki "Telefonu eğince tablo oynasın" (sitenin `egimVar()`'ı)
  static var egimVarMi: Bool {
    #if targetEnvironment(simulator)
      true
    #else
      CMMotionManager().isGyroAvailable
    #endif
  }
  var varMi: Bool {
    #if targetEnvironment(simulator)
      true
    #else
      aygit.isGyroAvailable
    #endif
  }

  func durdur() {
    aygit.stopGyroUpdates()
    deger = nil
  }

  func baslat() {
    // js/egim.js egimDegeri: dinleme başlayınca değer hemen {0, 0}; resim her yandan 26 px taşar (ilk örneği beklemez)
    if deger == nil { deger = .zero }
    guard aygit.isGyroAvailable, !aygit.isGyroActive else { return }
    var iz = YuruyusEgimi()
    // js/egim.js: hedef her ölçümde, ekrandaki değer ona her karede %20 yaklaşır (sitede devicemotion ve
    // requestAnimationFrame ikisi de ~60/sn; burada ölçüm başına bir adım, ölçüm de 60/sn)
    var yumusak = EgimYumusatici()
    var son: TimeInterval?
    aygit.gyroUpdateInterval = 1 / 60
    aygit.startGyroUpdates(to: .main) { [weak self] ornek, _ in
      guard let self, self.aygit.isGyroActive, let ornek else { return }
      defer { son = ornek.timestamp }
      guard let son else { return }
      let hiz = ornek.rotationRate
      self.deger = yumusak.izle(
        iz.izle(
          hiz: CGPoint(x: hiz.y * 180 / .pi, y: hiz.x * 180 / .pi),
          sure: min(0.05, ornek.timestamp - son)))
    }
  }
}

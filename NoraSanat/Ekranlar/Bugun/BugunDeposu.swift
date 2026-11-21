// Kaynak: sanat-atlasi js/ekranlar/bugun.js, js/egim.js, js/gunduzRenk.js, js/renk.js @ a866b86
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
      async let baglamYukle = GoruntuleyiciBaglami.yukle(siteVerisi: site)
      let b = await baglamYukle
      guard let katalog = b.katalog else { throw URLError(.notConnectedToInternet) }
      // Kabuk ilk açılışta site köprüsünü katalogdan sonra hazırlayabilir.
      var ilerleme: Ilerleme?
      for _ in 0..<20 {
        ilerleme = try? await kopru.oku()
        if ilerleme != nil { break }
        try await Task.sleep(for: .milliseconds(250))
      }
      let veriler = await dosyalar
      let s = try BugunTablosu(
        tarih: tarih, degisim: ilerleme?[alan: "gununDegisim"],
        veriler: veriler, katalog: katalog)
      let ayar =
        try? await kopru.benBetigi(
          """
          const o = await import('/js/ekranlar/ortak.js'), g = await import('/js/gorsel.js');
          await o.odaklariYukle();
          return { ...g.yuruyusEki(ad), odak:g.adlaOdak(ad) || [50,40] };
          """, ["ad": s.kayit.gorsel]) as? [String: Any]
      let imzalar = veriler["imzalar.json"].flatMap { try? JSONDeger.coz($0) }
      let imzaURL = imzalar?["imzalar"]?[s.tablo.sanatciId]?.metin.map { _ in
        SiteVerisi.site.appendingPathComponent("gorseller/imza/" + s.tablo.sanatciId + ".png")
      }
      async let imzaResmi = GorselCozucu.shared.resim(imzaURL, piksel: 640)
      let ilk = await GorselCozucu.shared.resim(s.tablo.gorsel, piksel: 1920)
      let imza = await imzaResmi
      try Task.checkCancellation()
      guard let ilk else { throw URLError(.cannotDecodeContentData) }
      egimAcik = ilerleme?.ayar("egim")?.mantik ?? true
      if let merkez = ayar?["odak"] as? [Double], merkez.count == 2 {
        odak = CGPoint(x: merkez[0] / 100, y: merkez[1] / 100)
      } else {
        odak = CGPoint(x: 0.5, y: 0.4)
      }
      yakin = ayar?["yakin"] as? Double ?? 1
      kirp = s.kayit.kirp ?? (ayar?["kirp"] as? [Double])
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
      if s.buyuk != s.tablo.gorsel, let hd = await GorselCozucu.shared.resim(s.buyuk, piksel: 4096),
        !Task.isCancelled
      {
        resim = hd
      }
    } catch {
      if !Task.isCancelled { hata = "Günün tablosu yüklenemedi." }
    }
  }
}

@MainActor @Observable
final class BugunHareketi {
  private let aygit = CMMotionManager()
  var deger: CGPoint?
  var varMi: Bool { aygit.isGyroAvailable }

  func durdur() {
    aygit.stopGyroUpdates()
    deger = nil
  }

  func baslat() {
    guard varMi, !aygit.isGyroActive else { return }
    var iz = YuruyusEgimi()
    var son: TimeInterval?
    aygit.gyroUpdateInterval = 1 / 30
    aygit.startGyroUpdates(to: .main) { [weak self] ornek, _ in
      guard let self, self.aygit.isGyroActive, let ornek else { return }
      defer { son = ornek.timestamp }
      guard let son else { return }
      let hiz = ornek.rotationRate
      self.deger = iz.izle(
        hiz: CGPoint(x: hiz.y * 180 / .pi, y: hiz.x * 180 / .pi),
        sure: min(0.05, ornek.timestamp - son))
    }
  }
}

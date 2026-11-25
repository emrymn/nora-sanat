// Z3v (yeni, sitede yok): Bugün'ün "Paylaş" kartı. Tasarım: dal neon/paylas-karti-tasarim (PR #54), Yön 4
// ("Perde ve ayrıntı", tasarim/paylas-karti/yon-4.html). Bu dosya kartın arayüzden bağımsız geometrisi: tablonun
// kapaktaki yerleşimi, ayrıntı çerçevesinin kapaktaki yeri ve not kartındaki kare kırpım.
//
// Neon'un HTML'inde çerçeve yüzdeyle elle konmuştu ve tablo kırpılınca kayıyordu. Burada çerçeve, tablonun gerçekten
// çizildiği dikdörtgenden hesaplanır: tablo "cover" ile yürüyüşün kırpımını (`kirp`) kaplar ve Bugün'deki odakla
// (yuruyus_odak / elle odak, `OdakVerisi.adlaOdak`) ortalanır; noktanın x, y, w, h'si (tablonun 0–1 kesirleri) aynı
// dikdörtgene göre kutuya çevrilir.
import Foundation

public enum PaylasKarti {
  /// Kartın iki boyu (piksel; ImageRenderer scale 1)
  public enum Boy: String, CaseIterable, Sendable {
    /// Instagram hikâyesi (varsayılan)
    case hikaye
    /// Gönderi / mesaj
    case gonderi

    public var boyut: CGSize { self == .hikaye ? CGSize(width: 1080, height: 1920) : CGSize(width: 1080, height: 1350) }
    /// Tablonun kenardan kenara kapağı (`.kapak-resim`)
    public var kapak: CGSize { CGSize(width: 1080, height: self == .hikaye ? 1030 : 756) }
    /// Odak kapağın bu noktasına gelir (yatayda orta; dikeyde Bugün'ün açılışı gibi biraz yukarıda: alt kenar zemine erir)
    public var hedef: CGPoint { CGPoint(x: 0.5, y: 0.42) }
    /// Kapağın görünen payı: çerçeve bunun içinde kalmalı. `.kapak-erime` %66'dan sonra koyulaşır ve %93'te
    /// zeminin %86'sına varır; tasarımda servinin çerçevesi kapağın %90'ına iner (yon-4.html, hikâye).
    public var gorunurAlt: Double { 0.93 }
  }

  /// Yürüyüşün kırpımı (`yuruyus.json` `kirp` ya da `yuruyus_odak.json` eki): [x, y, w, h], tablonun 0–1 kesirleri.
  /// Geçersizse bütün tablo (`YuruyusKamerasi` ile aynı kural).
  public static func kirpim(_ kirp: [Double]?) -> CGRect {
    let r = kirp ?? []
    if r.count == 4, r.allSatisfy({ (0...1).contains($0) }), r[2] > 0, r[3] > 0 {
      return CGRect(x: r[0], y: r[1], width: min(r[2], 1 - r[0]), height: min(r[3], 1 - r[1]))
    }
    return CGRect(x: 0, y: 0, width: 1, height: 1)
  }

  /// Tablonun kutudaki dikdörtgeni (kutunun sol üstüne göre, kutu birimiyle). `resim`: tablonun boyu (oran yeter),
  /// `kirp`: tablonun kutuyu kaplayacak bölgesi (0–1), `odak`: kutunun `hedef` noktasına gelecek nokta (tablonun 0–1
  /// kesirleri). Tablo kırpımın dışını göstermeyecek biçimde kaydırılır (odak kenara yakınsa tam ortaya gelmez).
  public static func yerlesim(resim: CGSize, kirp: CGRect, kutu: CGSize, odak: CGPoint, hedef: CGPoint) -> CGRect {
    guard resim.width > 0, resim.height > 0, kutu.width > 0, kutu.height > 0 else { return .zero }
    let b = CGRect(
      x: kirp.minX * resim.width, y: kirp.minY * resim.height,
      width: max(1e-9, kirp.width * resim.width), height: max(1e-9, kirp.height * resim.height))
    let s = max(kutu.width / b.width, kutu.height / b.height)
    func sinirla(_ v: Double, _ enAz: Double, _ enCok: Double) -> Double { min(enCok, max(enAz, v)) }
    let x = sinirla(kutu.width * hedef.x - odak.x * resim.width * s, kutu.width - b.maxX * s, -b.minX * s)
    let y = sinirla(kutu.height * hedef.y - odak.y * resim.height * s, kutu.height - b.maxY * s, -b.minY * s)
    return CGRect(x: x, y: y, width: resim.width * s, height: resim.height * s)
  }

  /// Tablonun 0–1 kesirleriyle bir alan (yürüyüş noktası) → tablonun `yerlesim` ile çizildiği kutudaki dikdörtgen
  public static func alan(_ a: CGRect, yerlesim y: CGRect) -> CGRect {
    CGRect(
      x: y.minX + a.minX * y.width, y: y.minY + a.minY * y.height,
      width: a.width * y.width, height: a.height * y.height)
  }

  public struct Kapak: Equatable, Sendable {
    /// Tablonun kapaktaki dikdörtgeni
    public var resim: CGRect
    /// Ayrıntının kapaktaki çerçevesi; ayrıntı yoksa ya da görünen payın dışına düşüyorsa nil
    public var cerceve: CGRect?
  }

  /// Kartın kapağı: tablo Bugün'deki odakla kırpımı kaplar. Ayrıntı o yerleşimde kapağın görünen payına
  /// (`gorunurAlt`'tan yukarısı) sığmıyorsa odak ayrıntının ortasına alınır; o da sığdırmıyorsa çerçeve çizilmez.
  public static func kapak(resim: CGSize, kirp: [Double]?, odak: CGPoint, nokta: CGRect?, boy: Boy) -> Kapak {
    let k = kirpim(kirp)
    let kutu = boy.kapak
    let gorunur = CGRect(x: 0, y: 0, width: kutu.width, height: kutu.height * boy.gorunurAlt)
    func dene(_ o: CGPoint) -> Kapak {
      let y = yerlesim(resim: resim, kirp: k, kutu: kutu, odak: o, hedef: boy.hedef)
      let c = nokta.map { alan($0, yerlesim: y) }
      return Kapak(resim: y, cerceve: c.flatMap { gorunur.insetBy(dx: -0.5, dy: -0.5).contains($0) ? $0 : nil })
    }
    let ilk = dene(odak)
    guard let n = nokta, ilk.cerceve == nil else { return ilk }
    return dene(CGPoint(x: n.midX, y: n.midY))
  }

  /// Not kartındaki küçük kare kırpım: ayrıntının ortasında, ayrıntıyı (biraz payla) içine alan kare. Tablonun piksel
  /// dikdörtgeni (`CGImage.cropping` için); tablonun dışına taşmaz. Kare tablodan büyükse tablonun kısa kenarı kadar.
  public static func kareKirpim(_ a: CGRect, resim: CGSize, pay: Double = 0.06) -> CGRect {
    guard resim.width > 0, resim.height > 0 else { return .zero }
    let w = a.width * resim.width, h = a.height * resim.height
    let kenar = min(max(w, h) * (1 + 2 * pay), resim.width, resim.height)
    let mx = a.midX * resim.width, my = a.midY * resim.height
    let x = min(resim.width - kenar, max(0, mx - kenar / 2))
    let y = min(resim.height - kenar, max(0, my - kenar / 2))
    return CGRect(x: x, y: y, width: kenar, height: kenar)
  }

  /// "Vincent van Gogh · 1889"
  public static func sanatciYil(_ t: GununTablosu) -> String {
    [t.sanatci, t.yil.map(String.init)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  /// Paylaşılan dosyanın adı: "nora-sanat-2026-11-24.png"
  public static func dosyaAdi(tarih: String) -> String { "nora-sanat-\(tarih).png" }

  /// Yürüyüşte o an açık olan nokta: adım 0 kapak, 1 künye, 2… noktalar; değilse (kapak, künye, tanıma) ilk nokta
  public static func noktaSirasi(adim: Int, noktaSayisi: Int) -> Int? {
    guard noktaSayisi > 0 else { return nil }
    let i = adim - 2
    return (0..<noktaSayisi).contains(i) ? i : 0
  }
}

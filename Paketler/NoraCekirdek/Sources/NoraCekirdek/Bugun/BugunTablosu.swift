// Kaynak: sanat-atlasi js/ekranlar/{bugun,ortak}.js, js/gorsel.js, js/gunun.js @ a866b86
import Foundation

public struct BugunTablosu {
  public struct Nokta: Decodable {
    public let ad, metin: String
    let x, y, w, h: Double
    public var alan: CGRect { CGRect(x: x, y: y, width: w, height: h) }
  }
  public struct Kayit: Decodable {
    public let gorsel: String
    public let buyuk: String?
    public let kirp: [Double]?
    public let noktalar: [Nokta]
  }
  private struct Dosya: Decodable { let eserler: [String: Kayit] }
  public let tablo: GununTablosu
  public let kayit: Kayit
  public let ad: AdParcalari
  public let kunye, taninma, hayat, kaynak: String
  public let eser: Eser?
  public let buyuk: URL?

  public init(tarih: String, degisim: JSONDeger?, veriler: [String: Data], katalog: SiteKatalogu)
    throws
  {
    guard var yuruyus = veriler["yuruyus.json"], let sanatcilar = veriler["sanatcilar.json"] else {
      throw GununTablosuCozucu.Hata.bozukVeri
    }
    let kayitlar = try JSONDecoder().decode(Dosya.self, from: yuruyus).eserler
    // Ayarlardan yalnız o güne seçilmiş geçerli bir sanatçı varsa çözücü aynı eseri tek üyeli havuzdan alır.
    if degisim?["tarih"]?.metin == tarih, let id = degisim?["id"]?.metin,
      kayitlar[id]?.noktalar.isEmpty == false,
      let kok = try JSONSerialization.jsonObject(with: yuruyus) as? [String: Any],
      let kayit = (kok["eserler"] as? [String: Any])?[id]
    {
      yuruyus = try JSONSerialization.data(withJSONObject: ["eserler": [id: kayit]])
    }
    tablo = try GununTablosuCozucu.coz(
      tarih: tarih, yuruyus: yuruyus, sanatcilar: sanatcilar,
      adlar: veriler["eser_adlari_tr.json"], kaynak: veriler["gorsel_kaynagi.json"])
    let id = tablo.sanatciId
    guard let k = kayitlar[id], let s = katalog.harita[id] else {
      throw GununTablosuCozucu.Hata.bozukVeri
    }
    kayit = k
    ad = katalog.adParcalari(s)
    kunye = [s.ad, tablo.yil.map(String.init), s.akim].compactMap { $0 }.joined(separator: " · ")
    func json(_ dosya: String) -> JSONDeger? { veriler[dosya].flatMap { try? JSONDeger.coz($0) } }
    let bio = json("biyografiler.json")?["sanatcilar"]?[id]
    hayat = bio?["metin"]?.metin ?? ""
    kaynak = bio?["kaynak"]?["ad"]?.metin ?? ""
    let not = json("tanima_notlari.json")?["notlar"]?[id]?.metin ?? ""
    taninma = GoruntuleyiciKurallari.taninmaMetni(s, tanimaNotlari: [id: not])
    eser = katalog.eserler(id).first { e in
      e.gorseller.contains { katalog.gorsel.yerelAd($0) == k.gorsel }
    }
    let adres = katalog.gorsel.yuruyusAdresleri(ad: k.gorsel, buyuk: k.buyuk)
    buyuk = GorselAdresleri.url(adres.buyuk)
  }
}

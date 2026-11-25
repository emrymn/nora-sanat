// Z3x: Ayarlar → Gelişmiş → "Hata günlüğü". Sitede `js/gunluk.js`'in günlüğü vardı (Ayarlar'da sayısı, Kopyala, Temizle);
// site uygulamadan kalkınca (Z2c-3) bölüm de kalkmıştı. Uygulamanın kendi hataları (Ben/Ayarlar işlemleri, çevrimdışı
// indirme) burada tutulur; kopyalanan metin bir Claude oturumuna verilir.
import Foundation

public struct HataKaydi: Codable, Equatable, Sendable {
    /// ISO 8601 zaman
    public var t: String
    /// Nerede oldu ("ayarlar", "cevrimdisi" …)
    public var yer: String
    public var metin: String

    public init(t: String, yer: String, metin: String) {
        self.t = t; self.yer = yer; self.metin = metin
    }
}

public struct HataGunlugu: Codable, Equatable, Sendable {
    /// En yeni başta
    public private(set) var kayitlar: [HataKaydi] = []
    /// En çok bu kadar kayıt tutulur (eskiler düşer)
    public static let enCok = 50

    public init(kayitlar: [HataKaydi] = []) {
        self.kayitlar = Array(kayitlar.prefix(Self.enCok))
    }

    /// Yeni kaydı başa ekler. Aynı yerden aynı hata art arda gelirse yalnız zamanı yenilenir.
    public mutating func ekle(_ k: HataKaydi) {
        let metin = k.metin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !metin.isEmpty else { return }
        var k = k
        k.metin = metin
        if let ilk = kayitlar.first, ilk.yer == k.yer, ilk.metin == k.metin {
            kayitlar[0].t = k.t
            return
        }
        kayitlar.insert(k, at: 0)
        if kayitlar.count > Self.enCok { kayitlar.removeLast(kayitlar.count - Self.enCok) }
    }

    public mutating func temizle() { kayitlar = [] }

    /// Satırın altındaki yazı
    public var ozet: String {
        kayitlar.isEmpty ? "Kayıt yok" : "\(kayitlar.count) kayıt · son: \(kayitlar[0].metin)"
    }

    /// Panoya kopyalanan metin: `{ "uygulama": "nora-sanat", "tur": "hata-gunlugu", "kayitlar": [...] }`
    public var metin: String {
        let kayit = kayitlar.map { k in
            JSONDeger.nesne(SiraliNesne([("t", .metin(k.t)), ("yer", .metin(k.yer)), ("metin", .metin(k.metin))]))
        }
        return JSONDeger.nesne(SiraliNesne([
            ("uygulama", .metin("nora-sanat")), ("tur", .metin("hata-gunlugu")), ("kayitlar", .dizi(kayit)),
        ])).girintiliMetin(girinti: 1)
    }
}

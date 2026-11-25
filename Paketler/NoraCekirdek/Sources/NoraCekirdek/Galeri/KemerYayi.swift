// Z3w (yeni tasarım, sitede yok): Galeri › Akımlar, Neon'un "Yön 2 · Kemerlerin yayı" tasarımı (Emre seçti).
// Kaynak: dal `neon/galeri-akimlar-2` (PR #60, birleştirilmedi), `tasarim/galeri-akimlar-2/yon-2.html` → `cizKonum(p)`,
// `centikCiz(p)`, eylem yuvası. Kâhin yok (sitede karşılığı yok): davranış testi `KemerYayiTests`.
//
// Kemerler kayarken geniş bir mimari yay boyunca hafifçe eğilir (akım başına ±2,6°, en çok ±3,2°) ve yayla alçalır (15 pt).
// Komşu kartlar yumuşakça küçülür, solar ve bulanıklaşır; yazı kendi kemerine bağlı akar. Hareket azaltılmışsa eğim,
// kayma ve bulanıklık kapanır, yalnız ölçek ve opaklık kalır.
import Foundation

public enum KemerYayi {
    /// `.kemer-oge`: 234 genişlik, 278 yükseklik (çift çerçeve dahil), aralık 18
    public static let kartGenisligi: Double = 234
    public static let kartYuksekligi: Double = 278
    public static let aralik: Double = 18
    public static var adim: Double { kartGenisligi + aralik }
    /// Bir akım ötedeki kartın eğimi (derece) ve eğimin sınırı
    public static let egim: Double = 2.6
    public static let egimSiniri: Double = 3.2
    /// Yayın düşüşü: komşu kart bu kadar alçalır (nokta)
    public static let yayDususu: Double = 15
    /// Yazının yayla düşüşü
    public static let yaziDususu: Double = 7
    /// Bir akım ötedeki kartın bulanıklığı (nokta; tasarımda komşu yalnız soluyordu, Emre "bulanıklaşma" da istedi)
    public static let komsuBulanikligi: Double = 2.4
    /// Kilitli akımın kapağı her zaman bulanık (`.kemer-oge.kilitli .kemer-resim { filter: blur(4.4px) }`)
    public static let kilitBulanikligi: Double = 4.4

    /// Bir kartın o anki görünüşü
    public struct Kart: Equatable, Sendable {
        /// `scale(0.89 + 0.11·yakınlık)`
        public var olcek: Double
        /// Yay boyunca aşağı kayma (nokta)
        public var kayma: Double
        /// Eğim (derece; sağdaki kart saat yönünde)
        public var aci: Double
        /// Kartın opaklığı
        public var opaklik: Double
        /// Dış pirinç çerçevenin opaklığı (`--dis-op`)
        public var cerceve: Double
        /// Konuma göre bulanıklık (nokta)
        public var bulaniklik: Double
        /// Açık akımın kapağının parlaklığı (1 = olduğu gibi)
        public var parlaklik: Double
        /// Kemere bağlı yazının opaklığı ve kayması
        public var yaziOpakligi: Double
        public var yaziKaymasi: Double
        /// Ortadaki kart (gölgesi derin)
        public var odak: Bool
    }

    /// `yakinlik = cos(min(1, |d|) · π/2)`: ortada 1, bir akım ötede 0
    public static func yakinlik(_ fark: Double) -> Double {
        cos(min(1, abs(fark)) * Double.pi / 2)
    }

    /// `fark`: kartın sırası − şeridin anlık konumu (kesirli)
    public static func kart(fark: Double, acik: Bool = true, hareketAz: Bool = false) -> Kart {
        let uzak = min(1.4, abs(fark))
        let y = yakinlik(fark)
        let aci = hareketAz ? 0 : max(-egimSiniri, min(egimSiniri, fark * egim))
        return Kart(
            olcek: 0.89 + 0.11 * y,
            kayma: hareketAz ? 0 : (1 - y) * yayDususu,
            aci: aci,
            opaklik: 0.64 + 0.36 * y,
            cerceve: 0.10 + 0.62 * y,
            bulaniklik: hareketAz ? 0 : min(1, uzak) * komsuBulanikligi,
            parlaklik: acik ? 0.86 + 0.14 * y : 1,
            yaziOpakligi: pow(max(0, 1 - uzak / 0.58), 1.15),
            yaziKaymasi: hareketAz ? 0 : (1 - y) * yaziDususu,
            odak: uzak < 0.35)
    }

    /// Konum şeridin sınırları içinde
    public static func sinirla(_ p: Double, sayi: Int) -> Double {
        guard sayi > 0 else { return 0 }
        return max(0, min(Double(sayi - 1), p))
    }

    /// Şeridin kaydığı yol (ilk kart ortadayken 0) → anlık konum (akım cinsinden)
    public static func konum(yol: Double, sayi: Int) -> Double {
        sinirla(yol / adim, sayi: sayi)
    }

    /// Bırakılınca oturulacak akım: konum + fırlatma payı, en yakın akım
    public static func oturma(konum p: Double, hiz: Double = 0, sayi: Int) -> Int {
        Int(sinirla(p + hiz, sayi: sayi).rounded())
    }

    /// Işık kılavuzu: önceki ya da sonraki akım (uçta yok)
    public static func komsu(_ sira: Int, yon: Int, sayi: Int) -> Int? {
        let h = sira + yon
        return h >= 0 && h < sayi ? h : nil
    }

    /// `smoothstep`
    public static func yumusak(_ t: Double) -> Double {
        let c = max(0, min(1, t))
        return c * c * (3 - 2 * c)
    }

    /// Eylem yuvası ("Salona gir" ↔ kilitli hap): açık ile kilitli arasında geçerken ortada %38'e kadar söner;
    /// iki komşu aynıysa tam görünür
    public static func eylemOpakligi(konum p: Double, aciklar: [Bool]) -> Double {
        guard !aciklar.isEmpty else { return 1 }
        let q = sinirla(p, sayi: aciklar.count)
        let i0 = Int(q.rounded(.down))
        let i1 = min(aciklar.count - 1, i0 + 1)
        guard aciklar[i0] != aciklar[i1] else { return 1 }
        let f = q - Double(i0)
        return 0.38 + 0.62 * abs(f - 0.5) * 2
    }

    /// Işık kılavuzunun bir çentiği (kılavuz 52 pt yüksek; `x` kılavuz genişliğinde)
    public struct Centik: Equatable, Sendable {
        public var x: Double
        /// Yay üstündeki y (çentik y + 3'ten y + 8'e)
        public var y: Double
        public var opaklik: Double
    }

    /// `centikCiz(p)`: 390 genişlikte 14'te bir çentik, şeritle birlikte akım başına bir çentik kayar; iki uca doğru
    /// yay alçalır ve çentik söner. Genişlik farklıysa yatayda ölçeklenir (SVG `preserveAspectRatio="none"`).
    public static func centikler(konum p: Double, genislik: Double = 390) -> [Centik] {
        let s = genislik / 390
        let kayma = -(p * 14).truncatingRemainder(dividingBy: 14)
        var sonuc: [Centik] = []
        var x = 28 + kayma
        while x <= 362 {
            let u = (x - 195) / 177
            if abs(u) <= 0.96 {
                sonuc.append(Centik(x: x * s, y: 14 + 10 * u * u, opaklik: (1 - u * u) * 0.65))
            }
            x += 14
        }
        return sonuc
    }

    /// Kartın altındaki yıllar: akımın sanatçılarının en erken doğumu – en geç ölümü (tasarımda "1582–1682").
    /// Doğumu bilinmeyenin ölümü, ölümü bilinmeyenin doğumu sayılır.
    public static func yillar(_ uyeler: [Sanatci]) -> String {
        let bas = uyeler.compactMap { $0.dogum ?? $0.olum }.min()
        let son = uyeler.compactMap { $0.olum ?? $0.dogum }.max()
        guard let bas, let son else { return "" }
        return SiteYazisi.yillarYaz(dogum: bas, olum: son)
    }

    /// Kartın durum satırı
    public static func durum(_ a: AkimDurumu) -> String {
        a.acik ? "\(a.acikSayisi) / \(a.toplam) sanatçı açık" : "Konu \(SiteYazisi.bulunmaEki(a.acilacagiKonu ?? 0)) açılır"
    }
}

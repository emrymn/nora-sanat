// Z3y (yeni tasarım, sitede yok): Yolculuk bölüm turunun soru ekranı, "Yön 3 · Geniş Tuval" üstü ve
// "Şık 5 · El Yelpazesi" şıkları. Kaynak: Neon'un tasarımı, dal `neon/soru-tasarim` (PR #67, birleştirilmedi):
// tasarim/soru/sik-5.html (`.muze-kart[data-i]` açı ve düşüşleri, `.muze-kart.basili`, `.yelpaze.biri-basili`,
// `.deste-bolge` yüksekliği, `.yelpaze.cevapli .muze-kart`, `.kart-ad`), tasarim/soru/yon-3.html (`.birlesik-hap`),
// tasarim/soru/BENIOKU.md "Üçüncü Tur". Kâhin yok: davranış testi (SoruYelpazesiTests).
//
// Tasarımdan bilinçli fark: kartlar ekran genişliğine göre hesaplanır (tasarımda sabit 90 pt) ve uzun ad
// ("Rogier van der Weyden") en çok 2 satıra inecek kadar yazı küçülür (tasarımda 3 satır).
import Foundation

public enum SoruYelpazesi {
    // MARK: Yelpaze (sik-5.html `.muze-kart[data-i]`)

    /// Dört kartın açısı (derece): `--aci`
    public static let acilar: [Double] = [-8.5, -2.8, 2.8, 8.5]
    /// Dört kartın aşağı düşüşü (pt): `--y`; kenardakiler elde tutuş yayında daha aşağıda
    public static let dususler: [Double] = [8, 1, 1, 8]

    /// i. kartın açısı. Dörtten az ya da çok kartta açılar aynı yayın üstüne eşit aralıkla yayılır.
    public static func aci(_ i: Int, adet: Int) -> Double {
        guard adet > 1, i >= 0, i < adet else { return 0 }
        if adet == acilar.count { return acilar[i] }
        let t = Double(i) / Double(adet - 1) * 2 - 1    // -1 … 1
        return t * acilar[acilar.count - 1]
    }

    /// i. kartın düşüşü: kenarlarda 8, ortaya yaklaştıkça 1 (dört kartta tablo; öbürlerinde aynı eğri)
    public static func dusus(_ i: Int, adet: Int) -> Double {
        guard adet > 1, i >= 0, i < adet else { return 0 }
        if adet == dususler.count { return dususler[i] }
        let t = abs(Double(i) / Double(adet - 1) * 2 - 1)
        return 1 + 7 * t * t
    }

    /// Basılı kart (`.muze-kart.basili`): 24 pt yukarı, açı 0, 1,08 büyür; ötekiler %48 (`.yelpaze.biri-basili`)
    public static let kalkma: Double = 24
    public static let basiliOlcek: Double = 1.08
    public static let digerOpaklik: Double = 0.48

    public struct KartDurumu: Equatable, Sendable {
        public var aci: Double
        /// Dikey kayma (pt; artı aşağı)
        public var y: Double
        public var olcek: Double
        public var opaklik: Double
        /// Üst üste binme sırası (sağdaki üstte; basılı en üstte)
        public var z: Double
        public var basili: Bool
    }

    /// Cevaptan önce i. kartın duruşu. `basili`: parmağın altındaki kart. Hareket azaltılmışsa kart sallanmaz,
    /// sıyrılmaz, büyümez: yelpaze aynı kalır, yalnız öbür kartlar söner (sade anlık geçiş).
    public static func kart(_ i: Int, adet: Int, basili: Int?, hareketAz: Bool) -> KartDurumu {
        let benim = basili == i
        let soluk = basili != nil && !benim
        if benim && !hareketAz {
            return KartDurumu(aci: 0, y: -kalkma, olcek: basiliOlcek, opaklik: 1, z: 10, basili: true)
        }
        return KartDurumu(aci: aci(i, adet: adet), y: dusus(i, adet: adet), olcek: 1, opaklik: soluk ? digerOpaklik : 1,
                          z: benim ? 10 : Double(i + 1), basili: benim)
    }

    // MARK: Ölçüler (`.deste-bolge`, `.muze-kart`, `.kart-ad`; `.telefon.kucuk`)

    public struct Olcu: Equatable, Sendable {
        /// 375×667 düzeni (`.telefon.kucuk`)
        public var kucuk: Bool
        /// Şık alanının sabit yüksekliği: başlık satırı + yelpaze + geçiş satırı. Cevaptan önce ve sonra aynı;
        /// eser bu yüksekliği ayırdıktan kalan alana sığar (cevapta eser küçülmez).
        public var altYukseklik: Double
        public var kartGenisligi: Double
        public var kartYuksekligi: Double
        /// Komşu kartların üst üste bindiği pay (`margin: 0 -7px` → 14)
        public var ustUste: Double
        /// Kart içi yatay boşluk (iki yan toplamı): `padding 8` + `.kart-ad padding 2`
        public var icPay: Double
        /// Addaki yazı boyu (pt)
        public var punto: Double
        /// Bu punto ve genişlikte en uzun adın satır sayısı
        public var satir: Int
        /// Cevaptan sonra yan yana düzleşen kartlar (`.yelpaze.cevapli .muze-kart`)
        public var cevapGenisligi: Double
        public var cevapYuksekligi: Double
        public var cevapAraligi: Double
    }

    /// Ekran yüksekliği (güvenli alan içi) bundan kısaysa küçük düzen. 390×844'te ≈ 763, 375×667'de ≈ 647.
    public static let kucukEsigi: Double = 700
    /// Ekran kenarından en az boşluk (yatay taşma olmasın; dönük kartın üst köşesi dahil)
    public static let kenarPayi: Double = 8
    /// Denenen yazı boyları, büyükten küçüğe (tasarım 13,5; küçükte 12,5)
    public static let puntolar: [Double] = [13.5, 13, 12.5, 12, 11.5, 11]
    /// Tasarımdaki kart genişliği; ekran izin verirse bundan geniş, en çok `enGenis`
    public static let tasarimGenisligi: Double = 90
    public static let enGenis: Double = 104

    public static func olcu(genislik: Double, yukseklik: Double, adlar: [String]) -> Olcu {
        let kucuk = yukseklik < kucukEsigi
        let kartH: Double = kucuk ? 126 : 146
        let ustUste: Double = kucuk ? 12 : 14
        let icPay: Double = 20
        let adet = Double(max(1, min(4, adlar.count)))
        // Yelpazenin eni: n kart − (n−1) bindirme + iki uçtaki dönük kartın taşması (alt orta eksende döner:
        // üst köşe h·sin(açı) kadar dışa çıkar).
        let tasma = kartH * sin(acilar[acilar.count - 1] * .pi / 180)
        let sigan = ((genislik - 2 * kenarPayi) + (adet - 1) * ustUste - 2 * tasma) / adet
        let w = max(kucuk ? 80 : 84, min(enGenis, floor(sigan)))
        let ic = w - icPay
        let tabanPunto = kucuk ? 12.5 : 13.5
        let adaylar = puntolar.filter { $0 <= tabanPunto }
        var punto = adaylar.last ?? tabanPunto
        var satir = enCokSatir(adlar, genislik: ic, punto: punto)
        for p in adaylar {
            // en çok 2 satır ve hiçbir sözcük ortasından kırılmasın
            let s = enCokSatir(adlar, genislik: ic, punto: p)
            if s <= 2 && sozcuklerSigar(adlar, genislik: ic, punto: p) { punto = p; satir = s; break }
        }
        let cevapW = min(kucuk ? 152 : 158, floor((genislik - 2 * 14 - 14) / 2))
        return Olcu(kucuk: kucuk, altYukseklik: kucuk ? 228 : 260, kartGenisligi: w, kartYuksekligi: kartH,
                    ustUste: ustUste, icPay: icPay, punto: punto, satir: satir,
                    cevapGenisligi: cevapW, cevapYuksekligi: kucuk ? 98 : 112, cevapAraligi: 14)
    }

    /// Yelpazenin toplam eni (iki uçtaki dönük kart dahil); `genislik − 2·kenarPayi`'yı aşmamalı
    public static func yelpazeEni(_ o: Olcu, adet: Int = 4) -> Double {
        let n = Double(max(1, adet))
        let tasma = o.kartYuksekligi * sin(acilar[acilar.count - 1] * .pi / 180)
        return n * o.kartGenisligi - (n - 1) * o.ustUste + 2 * tasma
    }

    // MARK: Satır hesabı (Archivo 500; yaklaşık harf enleri, em cinsinden)

    /// Yazının yaklaşık eni (pt). Archivo'nun harf enlerine yakın bir tablo; %3 güvenlik payıyla.
    public static func yaziGenisligi(_ metin: String, punto: Double) -> Double {
        var em = 0.0
        for c in metin {
            em += harfEni(c)
        }
        return em * punto * 1.03
    }

    static func harfEni(_ c: Character) -> Double {
        switch c {
        case " ": return 0.23
        case "i", "l", "j", "ı", "İ", "I", "'", "’", ".", ",", "·": return 0.26
        case "f", "t", "-", "(", ")": return 0.34
        case "r": return 0.38
        case "m", "M": return 0.88
        case "w": return 0.78
        case "W": return 0.94
        default:
            if c.isUppercase { return 0.68 }
            if c.isNumber { return 0.58 }
            return 0.56
        }
    }

    /// Sözcük sözcük kırılan yazının satır sayısı; tek başına sığmayan sözcük harf harf kırılır.
    public static func satirSayisi(_ metin: String, genislik: Double, punto: Double) -> Int {
        let sozcukler = metin.split(separator: " ").map(String.init)
        guard !sozcukler.isEmpty, genislik > 0 else { return 1 }
        let bosluk = yaziGenisligi(" ", punto: punto)
        var satir = 0
        var dolu = 0.0
        for s in sozcukler {
            let en = yaziGenisligi(s, punto: punto)
            if en > genislik {
                // sözcük kendi satırlarına harf harf bölünür
                // her parça kendi satırında; son parçanın satırı açık kalır, sonraki sözcük ona eklenebilir
                let parca = Int(ceil(en / genislik))
                satir += parca
                dolu = en - Double(parca - 1) * genislik
                continue
            }
            if dolu == 0 {
                satir += 1
                dolu = en
            } else if dolu + bosluk + en <= genislik {
                dolu += bosluk + en
            } else {
                satir += 1
                dolu = en
            }
        }
        return max(1, satir)
    }

    /// Her sözcük tek başına satıra sığıyor mu (sözcük ortasından kırılma yok)
    public static func sozcuklerSigar(_ adlar: [String], genislik: Double, punto: Double) -> Bool {
        adlar.allSatisfy { $0.split(separator: " ").allSatisfy { yaziGenisligi(String($0), punto: punto) <= genislik } }
    }

    public static func enCokSatir(_ adlar: [String], genislik: Double, punto: Double) -> Int {
        adlar.map { satirSayisi($0, genislik: genislik, punto: punto) }.max() ?? 1
    }

    // MARK: Üst çubuk (yon-3.html `.birlesik-hap`)

    /// Birleşik hapta nokta en çok bu kadar kart için çizilir; daha uzun turda (yanlışların tekrarı) ince çubuk.
    public static let enCokNokta = 12

    public enum NoktaDurumu: Equatable, Sendable { case gecildi, simdi, dogru, yanlis, bekliyor }

    /// Noktalar: geçilen kartlar dolu (sonuçları turda saklanmadığı için tek renk), şimdiki büyük mürekkep;
    /// cevaptan sonra şimdiki nokta doğruysa yeşil, değilse mercan halka (`.birlesik-noktalar i.yanlis`).
    public static func noktalar(toplam: Int, konum: Int, sonuc: Bool?) -> [NoktaDurumu]? {
        guard toplam > 0, toplam <= enCokNokta else { return nil }
        return (0..<toplam).map { i in
            if i < konum { return .gecildi }
            if i == konum { return sonuc.map { $0 ? .dogru : .yanlis } ?? .simdi }
            return .bekliyor
        }
    }

    // MARK: Cevaptan sonra (`.yelpaze.cevapli`)

    /// Cevaptan sonra ekranda kalan şıklar (D3): doğru ve seçilen; ikisi aynıysa ya da "Bilmiyorum"sa yalnız doğru.
    /// Sıra şıkların kendi sırası (tasarımda doğru solda değil; yerinden düzleşir).
    public static func kalanlar(_ liste: [String], dogru: String, secilen: String?) -> [String] {
        liste.filter { $0 == dogru || $0 == secilen }
    }
}

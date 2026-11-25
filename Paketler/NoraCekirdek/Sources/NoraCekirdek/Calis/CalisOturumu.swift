// Z3u (yeni, sitede yok): Çalış ana ekranının "Bugünün oturumu" düzeni (tasarim/calis/yon-4.html, Neon; kullanıcı onayladı).
// Sitede karşılığı yok: dersin kalan süresi, 2×7 hafıza ritmi takviminin yazıları, dönem yolu yazıları ve akım yayı.
// Kullandığı site kuralları: `CalisDersKurallari.adimSayisi` (js/ekranlar/ders.js), `TurOzeti.yaklasikDakika` (js/oturum.js),
// `CalisKurallari.gelecekYukOzeti` (js/ekranlar/calisma.js).
import Foundation

/// Bir ders adımında kalan iş (Z3u)
public struct DersAdimKalani: Equatable, Sendable {
    public var adim: DersAdimi
    /// Kalan birim sayısı (ayrıntı, özellik ya da ikili)
    public var kalan: Int
    public var birim: String
    /// Tahmini kalan süre (saniye)
    public var saniye: Double
}

/// Hafıza ritmi takviminin bir günü (Z3u)
public struct RitimGunu: Equatable, Sendable, Identifiable {
    public var id: Int { sira }
    /// 0 = bugün
    public var sira: Int
    public var tarih: String
    /// Vadesi gelen kart (sanatçı) sayısı
    public var n: Int
    /// Haftanın günü harfi (P, P, S, Ç, P, C, C)
    public var harf: String
    /// Ayın günü
    public var gun: Int
    /// "Bugün, 24 Kas", "Yarın, 25 Kas", "Perşembe, 26 Kas"
    public var ad: String
    public var dakika: Int
    /// 14 günün en yüklü günü (eşitse ilki)
    public var yogun: Bool
    public var dinlenme: Bool { n == 0 }
}

/// Önceki → bugünkü → sonraki akım yayı (Z3u)
public struct AkimYayi: Equatable, Sendable {
    public var onceki: String?
    public var bugunku: String
    public var sonraki: String?
    public var sonrakiKilitli: Bool
}

public enum CalisOturumu {
    // MARK: Süre tahmini (Z3u, yeni, sitede yok)

    /// Gör adımında bir ayrıntı (yürüyüş noktası) ~20 sn: bir eser 3–5 ayrıntı, ~1–1,5 dk.
    public static let gorAyrintiSaniyesi: Double = 20
    /// Öğren adımında bir özellik (madde ve kanıt eserleri) ~1 dk.
    public static let ogrenMaddeSaniyesi: Double = 60
    /// Ayırt et adımında bir komşu ikilisi ~1 dk.
    public static let ayirtIkiliSaniyesi: Double = 60

    static func birimSaniyesi(_ a: DersAdimi) -> Double {
        switch a {
        case .gor: return gorAyrintiSaniyesi
        case .ogren: return ogrenMaddeSaniyesi
        case .ayirt: return ayirtIkiliSaniyesi
        }
    }

    static func birimAdi(_ a: DersAdimi) -> String {
        switch a {
        case .gor: return "ayrıntı"
        case .ogren: return "özellik"
        case .ayirt: return "ikili"
        }
    }

    /// Saniyeyi dakikaya çevirir: iş yoksa 0, varsa en az 1 (`TurOzeti.yaklasikDakika` gibi yuvarlanır).
    public static func dakika(_ saniye: Double) -> Int {
        saniye <= 0 ? 0 : max(1, Int((saniye / 60).rounded()))
    }

    /// Adımda kalan: bitmiş adım 0; süren adımda kalan oran (1 − i) × birim sayısı × birim süresi.
    public static func adimKalani(_ b: DersBilgisi, _ a: DersAdimi) -> DersAdimKalani {
        let say = CalisDersKurallari.adimSayisi(b, a)
        guard b.adimlar.contains(a), !CalisDersKurallari.adimBittiMi(b.kayit, a), say.toplam > 0 else {
            return DersAdimKalani(adim: a, kalan: 0, birim: birimAdi(a), saniye: 0)
        }
        let oran = 1 - min(1, max(0, b.kayit[a].i))
        let kalan = max(1, say.toplam - say.gorulen)
        return DersAdimKalani(adim: a, kalan: kalan, birim: birimAdi(a), saniye: Double(say.toplam) * oran * birimSaniyesi(a))
    }

    /// Dersin bütün kalan adımlarının süresi (dakika); ders bittiyse 0.
    public static func dersKalanDakika(_ b: DersBilgisi) -> Int {
        dakika(b.adimlar.reduce(0) { $0 + adimKalani(b, $1).saniye })
    }

    /// Devam düğmesinin alt yazısı: sıradaki adımın süresi ve kalanı, "~4 dk · 2 özellik kaldı". Ders bittiyse boş.
    public static func devamAltYazisi(_ b: DersBilgisi) -> String {
        guard let a = b.durum.siradaki else { return "" }
        let k = adimKalani(b, a)
        guard k.kalan > 0 else { return CalisDersKurallari.adimAciklamasi(b, a) }
        return "~\(dakika(k.saniye)) dk · \(k.kalan) \(k.birim) kaldı"
    }

    /// Kapaktaki hapın süresi: dersin kalanı + günlük tekrar (kart yoksa yalnız ders).
    public static func oturumDakikasi(dersDakika: Int, tekrar: TurOzeti) -> Int {
        dersDakika + (tekrar.toplam > 0 ? tekrar.yaklasikDakika : 0)
    }

    // MARK: Hafıza ritmi (14 gün, 2×7)

    static let gunHarfi = ["P", "P", "S", "Ç", "P", "C", "C"]
    static let gunAdi = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    static let ayAdi = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]

    /// Haftanın günü (0 = pazar)
    static func haftaGunu(_ t: String) -> Int? {
        guard let p = GunTarihi.ayir(t) else { return nil }
        var takvim = Calendar(identifier: .gregorian)
        takvim.timeZone = TimeZone(identifier: "UTC")!
        guard let d = takvim.date(from: DateComponents(year: p.yil, month: p.ay, day: p.gun)) else { return nil }
        return takvim.component(.weekday, from: d) - 1
    }

    /// `gelecekYukOzeti(...).gunluk`'tan takvimin günleri (bugünden başlar)
    public static func ritim(gunluk: [Int], bugun: String) -> [RitimGunu] {
        let en = gunluk.max() ?? 0
        let yogunSira = en > 0 ? gunluk.firstIndex(of: en) : nil
        return gunluk.enumerated().map { i, n in
            let t = GunTarihi.ekle(bugun, i)
            let p = GunTarihi.ayir(t)
            let hg = haftaGunu(t) ?? 0
            let tarihYazi = p.map { "\($0.gun) \(ayAdi[max(0, min(11, $0.ay - 1))])" } ?? t
            let on = i == 0 ? "Bugün" : (i == 1 ? "Yarın" : gunAdi[hg])
            return RitimGunu(
                sira: i,
                tarih: t,
                n: n,
                harf: gunHarfi[hg],
                gun: p?.gun ?? 0,
                ad: "\(on), \(tarihYazi)",
                dakika: n > 0 ? TurOzeti(toplam: n).yaklasikDakika : 0,
                yogun: i == yogunSira
            )
        }
    }

    /// Haftanın tarih aralığı: "24–30 Kas", ay değişirse "28 Kas – 4 Ara"
    public static func haftaAraligi(_ gunler: [RitimGunu]) -> String {
        guard let ilk = gunler.first, let son = gunler.last,
              let a = GunTarihi.ayir(ilk.tarih), let b = GunTarihi.ayir(son.tarih) else { return "" }
        let ayA = ayAdi[max(0, min(11, a.ay - 1))], ayB = ayAdi[max(0, min(11, b.ay - 1))]
        if a.ay == b.ay && a.yil == b.yil { return "\(a.gun)–\(b.gun) \(ayB)" }
        return "\(a.gun) \(ayA) – \(b.gun) \(ayB)"
    }

    /// Seçili günün satırı: kalın kısım ("Bugün, 24 Kas:") ve devamı (" 14 kart (~5 dk) · en yoğun gün.")
    public static func ritimSatiri(_ g: RitimGunu) -> (vurgu: String, metin: String) {
        guard g.n > 0 else { return ("\(g.ad):", " dinlenme günü, tekrar yok.") }
        let not = g.yogun ? " · en yoğun gün." : "."
        return ("\(g.ad):", " \(g.n) kart (~\(g.dakika) dk)\(not)")
    }

    /// "Yarın seni bekleyen" satırının sağı: "6 kart · ~2 dk"; yarın boşsa "Dinlenme günü"
    public static func yarinYazisi(gunluk: [Int]) -> String {
        let n = gunluk.count > 1 ? gunluk[1] : 0
        return n > 0 ? "\(n) kart · ~\(TurOzeti(toplam: n).yaklasikDakika) dk" : "Dinlenme günü"
    }

    /// Bölüm başlığının sağ notu: "52 sanatçı", "3 dinlenme günü"
    public static func ritimNotu(gunluk: [Int]) -> [String] {
        let toplam = gunluk.reduce(0, +)
        let bos = gunluk.filter { $0 == 0 }.count
        var l = ["\(toplam) sanatçı"]
        if bos > 0 { l.append("\(bos) dinlenme günü") }
        return l
    }

    /// Boncuk çapı (pt): boş gün 10 (kesikli çember), dolu gün 16…32, alanı kart sayısıyla büyür.
    public static func boncukCapi(_ n: Int, en: Int) -> Double {
        guard n > 0 else { return 10 }
        return (16 + (Double(n) / Double(max(n, en))).squareRoot() * 16).rounded()
    }

    // MARK: Dönem yolu

    /// Ders satırının alt yazısı: "5 sanatçı · 3 adım tamam" (bitti) ya da "6 sanatçı · 3 adım"
    public static func yolAltYazisi(_ b: DersBilgisi) -> String {
        "\(b.acikSanatcilar.count) sanatçı · \(b.adimlar.count) adım\(b.durum.bitti ? " tamam" : "")"
    }

    /// Kilitli dersin alt yazısı: "Konu 14'te açılır · 1 konu kaldı"
    public static func kilitliAltYazisi(_ a: AkimDurumu, islenen: Set<Int>) -> String {
        guard let k = a.acilacagiKonu else { return "Henüz açılmadı" }
        let kalan = k - (islenen.max() ?? 0)
        return "Konu \(CalisKurallari.bulunmaEki(k)) açılır" + (kalan > 0 ? " · \(kalan) konu kaldı" : "")
    }

    /// Bölüm başlığının sağ notu: "2 bitti · 1 sürüyor"; ikisi de yoksa "4 sırada"
    public static func yolOzeti(_ dersler: [DersBilgisi]) -> String {
        let bitti = dersler.filter { $0.hal == .bitti }.count
        let suruyor = dersler.filter { $0.hal == .suruyor }.count
        let l = [bitti > 0 ? "\(bitti) bitti" : "", suruyor > 0 ? "\(suruyor) sürüyor" : ""].filter { !$0.isEmpty }
        return l.isEmpty ? "\(dersler.count) sırada" : l.joined(separator: " · ")
    }

    /// Önceki → bugünkü → sonraki: açık dersler sırasıyla, ardından kilitliler. Bugünün dersi yoksa son açık ders ortada.
    public static func akimYayi(aciklar: [String], kilitliler: [String], bugunku: String?) -> AkimYayi? {
        let sira = aciklar + kilitliler
        guard let orta = bugunku.flatMap({ b in aciklar.firstIndex(of: b) }) ?? (aciklar.isEmpty ? nil : aciklar.count - 1)
        else { return nil }
        let sonraki = orta + 1 < sira.count ? sira[orta + 1] : nil
        return AkimYayi(
            onceki: orta > 0 ? sira[orta - 1] : nil,
            bugunku: sira[orta],
            sonraki: sonraki,
            sonrakiKilitli: orta + 1 >= aciklar.count && sonraki != nil
        )
    }
}

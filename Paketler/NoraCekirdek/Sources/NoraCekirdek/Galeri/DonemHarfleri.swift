// Kaynak: sanat-atlasi js/harfler.js (AKIM_HARFLERI, BOLGE_HARFLERI, fontAdresi) @ a866b86 — İş 48: akım sayfasının
// büyük başlığı ve haritadaki dönem adları o dönemin yazısına yakın bir yazı tipiyle (Gotik'te kırık harf, Rönesans'ta
// Roma büyük harfleri…). Yazı tipi yalnız başlığın harfleri için Google Fonts'tan iner (css2 `&text=`); inmezse
// uygulamanın serifi kalır. Tablo sitenin dosyasından üretildi; site değiştirirse yeniden üret (bkz. DonemHarfleriTests).
import Foundation

public struct DonemHarfi: Equatable, Sendable {
    /// Google Fonts adı
    public var aile: String
    public var italik: Bool
    public var kalinlik: Int?
    /// Yazı tipi gözle büyük ya da küçük duruyorsa başlık boyu çarpanı
    public var olcek: Double

    public init(_ aile: String, italik: Bool = false, kalinlik: Int? = nil, olcek: Double = 1) {
        self.aile = aile; self.italik = italik; self.kalinlik = kalinlik; self.olcek = olcek
    }

    /// `fontAdresi(h, metin)`: Google Fonts css2 adresi; metin verilirse yalnız onun harfleri
    public func adres(metin: String = "") -> String {
        let ad = aile.replacingOccurrences(of: " ", with: "+")
        let eksen = italik ? ":ital,wght@1,\(kalinlik ?? 400)" : kalinlik.map { ":wght@\($0)" } ?? ""
        var harfler = ""
        if !metin.isEmpty {
            // `[...new Set(metin)].sort().join('')`: kod noktaları tekil, UTF-16 sırasıyla
            var gorulen = Set<Character>()
            let tekil = metin.filter { gorulen.insert($0).inserted }.map(String.init)
            let sirali = tekil.sorted { $0.utf16.lexicographicallyPrecedes($1.utf16) }.joined()
            harfler = "&text=" + Self.uriBileseni(sirali)
        }
        return "https://fonts.googleapis.com/css2?family=\(ad)\(eksen)\(harfler)&display=swap"
    }

    /// `encodeURIComponent`
    static func uriBileseni(_ s: String) -> String {
        let izinli = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        return s.addingPercentEncoding(withAllowedCharacters: izinli) ?? s
    }
}

public enum DonemHarfleri {
    public static let akimlar: [String: DonemHarfi] = [
        "Antik Yunan ve Roma": DonemHarfi("Marcellus"),
        "Romanesk": DonemHarfi("Uncial Antiqua", olcek: 0.86),
        "Gotik": DonemHarfi("Grenze Gotisch", kalinlik: 500, olcek: 1.14),
        "Uluslararası Gotik": DonemHarfi("Grenze Gotisch", kalinlik: 500, olcek: 1.14),
        "Erken Rönesans": DonemHarfi("Cinzel", olcek: 0.86),
        "Kuzey Rönesansı": DonemHarfi("Pirata One"),
        "Yüksek Rönesans": DonemHarfi("Cinzel", olcek: 0.86),
        "Venedik Rönesansı": DonemHarfi("EB Garamond", italik: true, olcek: 1.08),
        "Maniyerizm": DonemHarfi("Cinzel Decorative", olcek: 0.8),
        "İtalyan Barok ve Caravaggizm": DonemHarfi("Libre Caslon Display"),
        "İspanyol Barok": DonemHarfi("Libre Caslon Display"),
        "Flaman Barok": DonemHarfi("Libre Caslon Display"),
        "Hollanda Altın Çağı": DonemHarfi("Libre Caslon Display"),
        "Fransız Klasisizmi": DonemHarfi("Cormorant Garamond", kalinlik: 500, olcek: 1.06),
        "Geç İtalyan Barok": DonemHarfi("Libre Caslon Display"),
        "Rokoko": DonemHarfi("Petit Formal Script", olcek: 0.84),
        "Neoklasisizm": DonemHarfi("Bodoni Moda"),
        "Romantizm": DonemHarfi("Playfair Display", italik: true),
        "Prerafaelitler": DonemHarfi("Almendra"),
        "Akademizm ve Oryantalizm": DonemHarfi("Gilda Display"),
        "Barbizon ve Realizm": DonemHarfi("Old Standard TT"),
        "Empresyonizm": DonemHarfi("Fraunces", italik: true, kalinlik: 300),
        "Ukiyo-e (Japon baskısı)": DonemHarfi("Shippori Mincho", kalinlik: 500),
        "Post-Empresyonizm": DonemHarfi("Gloock"),
        "Sembolizm": DonemHarfi("Fredericka the Great", olcek: 0.9),
        "Art Nouveau ve Viyana Secession": DonemHarfi("Poiret One"),
        "Ekspresyonizm": DonemHarfi("Big Shoulders Display", kalinlik: 800, olcek: 1.06),
        "Kübizm": DonemHarfi("Major Mono Display", olcek: 0.78),
        "Dada": DonemHarfi("Rubik Mono One", olcek: 0.72),
        "Sürrealizm": DonemHarfi("Syne", kalinlik: 700, olcek: 0.86),
        "Savaş sonrası figürasyon": DonemHarfi("Space Grotesk", kalinlik: 600, olcek: 0.9),
    ]

    /// Haritanın dokuz dönemi (js/harita.js BOLGELER kimlikleri)
    public static let bolgeler: [String: DonemHarfi] = [
        "ortacag": DonemHarfi("Grenze Gotisch", kalinlik: 500, olcek: 1.14),
        "ronesans": DonemHarfi("Cinzel", olcek: 0.86),
        "barok": DonemHarfi("Libre Caslon Display"),
        "barok2": DonemHarfi("Cormorant Garamond", kalinlik: 500, olcek: 1.06),
        "aydinlanma": DonemHarfi("Petit Formal Script", olcek: 0.84),
        "romantik": DonemHarfi("Playfair Display", italik: true),
        "empresyonizm": DonemHarfi("Fraunces", italik: true, kalinlik: 300),
        "postempresyonizm": DonemHarfi("Gloock"),
        "modern": DonemHarfi("Space Grotesk", kalinlik: 600, olcek: 0.9),
    ]
}

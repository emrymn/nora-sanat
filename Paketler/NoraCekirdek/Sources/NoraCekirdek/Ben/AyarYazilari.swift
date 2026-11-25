// Z3x: Ayarlar'ın (Yön 2) kısa yazıları. Seçenek adları sitenin Ayarlar'ıyla aynı (js/ekranlar/ayarlar.js @ a866b86:
// Tema, Gündüz rengi, Yazı boyutu, Hareket); kısa açıklamalar ve önizleme durumu tasarımdan (yon-2.html).
import Foundation

public enum AyarYazilari {
    /// `gunduzRenk` seçenekleri ve adları (sitenin `.gunduz-renkleri`; `GunduzPaleti`)
    public static let gunduzRenkleri: [(deger: String, ad: String)] =
        GunduzPaleti.renkler.map { ($0, GunduzPaleti.adlar[$0] ?? $0) }
    public static let temalar: [(deger: String, ad: String)] = [("gece", "Gece"), ("gunduz", "Gündüz")]
    public static let yazilar: [(deger: String, ad: String)] = [("standart", "Standart"), ("buyuk", "Büyük")]
    /// Hareket: ad ve tek satırlık açıklama
    public static let hareketler: [(deger: String, ad: String, aciklama: String)] = [
        ("tam", "Tam", "Bütün geçişler ve süs hareketleri"),
        ("sade", "Sade", "Sayfa geçişleri ve cevap anı kalır; dönen, nefes alan, parlayan süsler durur"),
        ("kapali", "Kapalı", "Hiçbir şey hareket etmez"),
    ]

    public static func ad(_ l: [(deger: String, ad: String)], _ d: String?) -> String {
        l.first { $0.deger == d }?.ad ?? l[0].ad
    }

    public static func hareketAdi(_ d: String?) -> String {
        hareketler.first { $0.deger == d }?.ad ?? hareketler[0].ad
    }

    /// Önizleme kartının sağ üstü: "Gece · Standart", Gündüz'de rengin adı ("Lapis · Büyük")
    public static func onizlemeDurumu(tema: String?, gunduzRenk: String?, yazi: String?) -> String {
        let t = tema == "gunduz" ? ad(gunduzRenkleri, gunduzRenk) : "Gece"
        return "\(t) · \(ad(yazilar, yazi))"
    }

    private static let aylar = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül",
                                "Ekim", "Kasım", "Aralık"]

    /// "2026-11-22" → "22 Kasım" (bugünse "bugün", başka yılsa "22 Kasım 2025"); okunamazsa olduğu gibi
    public static func tarih(_ t: String, bugun: String) -> String {
        guard let (y, a, g) = GunTarihi.ayir(t), (1...12).contains(a) else { return t }
        if t == bugun { return "bugün" }
        let buYil = GunTarihi.ayir(bugun)?.yil
        return "\(g) \(aylar[a - 1])" + (buYil == y ? "" : " \(y)")
    }

    /// Yedek satırının alt yazısı
    public static func sonYedek(_ t: String?, bugun: String) -> String {
        guard let t, !t.isEmpty else { return "Henüz yedek alınmadı" }
        return "Son yedek: \(tarih(t, bugun: bugun))"
    }
}

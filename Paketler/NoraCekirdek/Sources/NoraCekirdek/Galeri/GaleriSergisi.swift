// Kaynak: sanat-atlasi js/cerceve.js, js/tasarim.js @ a866b86
import Foundation

public enum GaleriSergisi {
    private static let cerceveler = [
        "Antik Yunan ve Roma": "tas",
        "Romanesk": "kemer",
        "Gotik": "kemer",
        "Uluslararası Gotik": "kemer",
        "Erken Rönesans": "tabernakel",
        "Kuzey Rönesansı": "tabernakel",
        "Yüksek Rönesans": "tabernakel",
        "Venedik Rönesansı": "tabernakel",
        "Maniyerizm": "tabernakel",
        "İtalyan Barok ve Caravaggizm": "barok",
        "İspanyol Barok": "barok",
        "Flaman Barok": "barok",
        "Hollanda Altın Çağı": "abanoz",
        "Fransız Klasisizmi": "barok",
        "Geç İtalyan Barok": "barok",
        "Rokoko": "rokoko",
        "Neoklasisizm": "salon",
        "Romantizm": "salon",
        "Prerafaelitler": "salon",
        "Akademizm ve Oryantalizm": "salon",
        "Barbizon ve Realizm": "salon",
        "Empresyonizm": "beyaz",
        "Ukiyo-e (Japon baskısı)": "cita-kagit",
        "Post-Empresyonizm": "beyaz",
        "Sembolizm": "secession",
        "Art Nouveau ve Viyana Secession": "secession",
        "Ekspresyonizm": "cita",
        "Kübizm": "cita",
        "Dada": "cita",
        "Sürrealizm": "cita",
        "Savaş sonrası figürasyon": "cita",
    ]

    public static func cerceve(_ ad: String?) -> String { cerceveler[ad ?? ""] ?? "altin" }

    public static func yuzyillar(_ uyeler: [Sanatci]) -> String {
        let bas = uyeler.compactMap { $0.dogum.map { $0 + 20 } ?? $0.olum.map { $0 - 30 } }.min()
        let son = uyeler.compactMap { $0.olum ?? $0.dogum.map { $0 + 60 } }.max()
        guard let bas, let son else { return "" }
        func yuzyil(_ y: Int) -> String {
            let sayi = y > 0 ? (y - 1) / 100 + 1 : (-y) / 100 + 1
            let birler = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
            return (y > 0 ? "" : "MÖ ") + String(repeating: "X", count: sayi / 10) + birler[sayi % 10]
        }
        let a = yuzyil(bas), b = yuzyil(son)
        return (a == b ? a : a + "–" + b) + ". yüzyıl"
    }
}

// Z3x: Ayarlar → Hatırlatma (yeni; sitede yok). Açma/kapama ve saat iki yerden değişir: uygulamanın Ayarlar'ı ve iPhone
// Ayarlar → Nora Sanat (`NoraSanat/Settings.bundle`). İkisi aynı UserDefaults anahtarlarını kullanır; buradaki
// kurallar Settings.bundle'ın değerleriyle aynı olmalı (`DefaultValue`, `Values`: 7…23).
import Foundation

public enum HatirlatmaAyari {
    /// Settings.bundle `Key`'leri
    public static let acikAnahtari = "hatirlatma"
    public static let saatAnahtari = "hatirlatmaSaati"
    /// Settings.bundle `DefaultValue`'ları
    public static let varsayilanAcik = true
    public static let varsayilanSaat = 20
    /// Settings.bundle `Values`: 07:00 … 23:00
    public static let saatler = Array(7...23)

    /// Kayıttaki saat → geçerli saat: yoksa 20, aralık dışındaysa en yakın uç (7 ya da 23)
    public static func saat(_ ham: Int?) -> Int {
        guard let ham else { return varsayilanSaat }
        return min(saatler.last!, max(saatler.first!, ham))
    }

    /// 7 → "07:00"
    public static func yazi(_ saat: Int) -> String {
        (saat < 10 ? "0" : "") + "\(saat):00"
    }

    /// Bildirim izninin durumu (`UNAuthorizationStatus`'un sadeleşmişi)
    public enum Izin: Sendable, Equatable { case sorulmadi, var_, yok }

    /// Satırların altındaki yazılar
    public static func altYazi(acik: Bool) -> String {
        acik ? "Günde bir bildirim" : "Kapalı"
    }

    public static let saatAltYazisi = "\(yazi(saatler.first!)) – \(yazi(saatler.last!)) arası"

    /// Kartın altındaki dipnot. İzin kapalıysa iPhone Ayarlar'ının yolu.
    public static func dipnot(acik: Bool, rozet: Bool, izin: Izin) -> String {
        if izin == .yok && (acik || rozet) {
            return "Bildirim izni kapalı: iPhone Ayarlar → Nora Sanat → Bildirimler’den aç."
        }
        return "O gün tekrarın yoksa bildirim gelmez; sayı ilerlemenden otomatik hesaplanır."
    }
}

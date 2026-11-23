// Kaynak: sanat-atlasi js/ekranlar/hizliAyar.js @ a866b86
import Foundation
import NoraCekirdek

/// Yerli sekme çubuğunun (T4) hızlı ayarları (Z2b: Swift'teki kayıt). Çalış rozeti Z2c'den beri `SayacDeposu`'nda.
@MainActor
enum SekmeCubuguKoprusu {
    struct Ayarlar: Equatable {
        var tema = "gece", hareket = "tam", gunlukKart = 20

        init() {}
        init(_ il: Ilerleme) {
            tema = il.ayar("tema")?.metin ?? tema
            hareket = il.ayar("hareket")?.metin ?? hareket
            gunlukKart = il.ayar("gunlukKart")?.tamSayi ?? gunlukKart
        }
    }

    /// Z2b: ayarlar Swift'teki kayıttan
    static func ayarlar() async -> Ayarlar? { (try? await IlerlemeKoprusu.shared.oku()).map(Ayarlar.init) }

    /// Sitenin yaprağındaki dinleyicilerle aynı kural (js/ekranlar/hizliAyar.js): `alan` "tema" | "hareket" | "kart";
    /// değer geçerliyse yazılır. Kayıt siteye aynalanır; renkleri `TemaHesabi` yeniden hesaplar.
    static func yaz(_ alan: String, _ deger: Any) async -> Ayarlar? {
        let kopru = IlerlemeKoprusu.shared
        guard let il = try? await kopru.degistir({ il in
            switch alan {
            case "kart":
                let n = il.ayar("gunlukKart")?.tamSayi ?? 20
                il.ayarla("gunlukKart", .sayi(Double(min(100, max(5, n + ((deger as? Int) ?? 0))))))
            case "tema" where IlerlemeKurallari.temalar.contains(deger as? String ?? ""):
                il.ayarla("tema", .metin(deger as! String))
            case "hareket" where IlerlemeKurallari.hareketler.contains(deger as? String ?? ""):
                il.ayarla("hareket", .metin(deger as! String))
            default: break
            }
        }) else { return nil }
        await kopru.aynaBitsin()
        KabukDurumu.shared.rozetiYenile()   // günlük kart turu değiştirir
        return Ayarlar(il)
    }
}

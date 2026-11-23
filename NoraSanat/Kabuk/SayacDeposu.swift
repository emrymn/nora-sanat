// Kaynak: sanat-atlasi js/app.js (rozetiBagla), js/ekranlar/ayarlar.js (rozetiGuncelle), js/ekranlar/ortak.js
// (sekmeRozetiBagla), js/ekranlar/bugun.js (turBilgisi) @ a866b86
import Foundation
import NoraCekirdek

/// Z2c: siteye sorulmadan hesaplanan sayılar. Çalış rozeti, simge rozeti ve tekrar hatırlatmaları Swift'teki kayıttan
/// (`IlerlemeKoprusu.oku()`) ve sitenin verisinden (`SiteVerisi`, diskte önbellekli) gelir.
@MainActor
enum SayacDeposu {
    private static let site = SiteVerisi()
    private static var katalog: SiteKatalogu?
    private static var yukleme: Task<SiteKatalogu?, Never>?

    /// Sitenin kataloğu (bir kez yüklenir; çevrimdışıyken önbellekten)
    static func katalogu() async -> SiteKatalogu? {
        if let katalog { return katalog }
        if let yukleme { return await yukleme.value }
        let g = Task { try? await site.katalog() }
        yukleme = g
        let k = await g.value
        yukleme = nil
        if let k { katalog = k }
        return k
    }

    /// Çalış rozeti: sitenin `turBilgisi('karisik').toplam`'ı
    static func calisRozeti() async -> Int? {
        guard let k = await katalogu(), let il = try? await IlerlemeKoprusu.shared.oku() else { return nil }
        return CalisKurallari.turBilgisi(sanatcilar: k.sanatcilar, ilerleme: il, bugun: GunTarihi.gun(Date()), karisik: true).toplam
    }

    /// Açılışta, arka plana geçerken ve kayıt değişince: hatırlatma takvimi (eski köprü betiğinin `takvim`'i) ve
    /// "Simge rozeti" açıksa simgedeki sayı (açıkken bugünün, kapanırken yarının vadeli sanatçı sayısı; sitenin
    /// `rozetiGuncelle(kapaniyor)`'u).
    static func hatirlatmalariYenile(kapaniyor: Bool = false) async {
        guard let il = try? await IlerlemeKoprusu.shared.oku() else { return }
        let bugun = GunTarihi.gun(Date())
        if let t = TekrarTakvimi.hesapla(il.json, bugun: bugun) { Hatirlatici.shared.takvimGeldi(t) }
        guard il.ayar("rozet")?.dogruMu == true, let k = await katalogu() else { return }
        let idler = il.acikSanatcilar(k.sanatcilar).map(\.id)
        let n = kapaniyor ? Gecmis.yarinVade(il.skorlar, idler: idler, bugun: bugun)
                          : Gecmis.vadeSayisi(il.skorlar, idler: idler, tarih: bugun)
        Hatirlatici.shared.rozet(n)
    }
}

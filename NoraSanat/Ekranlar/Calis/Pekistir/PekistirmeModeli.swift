// Kaynak: sanat-atlasi js/devam.js, js/ekranlar/pekistir.js @ a866b86
import Foundation
import NoraCekirdek
import Observation

@MainActor @Observable
final class PekistirmeModeli {
    private static let depo = SiteVerisi()
    // Site, yedekten geri yüklerken tanımadığı ayarları korur.
    private static let alan = "noraPekistirmeOturumu"
    var katalog: SiteKatalogu?
    var veri = PekistirmeVerileri(ikonografi: nil, zorluk: nil)
    var ilerleme: Ilerleme?
    var kayit: TurKaydi?
    var turAcik = false
    var mesgul = false
    var hata: String?
    private var beklenen: JSONDeger?

    func yukle() async {
        guard !mesgul else { return }
        mesgul = true
        defer { mesgul = false }
        do {
            async let k = Self.depo.katalog()
            async let ek = Self.depo.veriler(["eser_zorluk.json", "ikonografi.json"])
            let il = try await IlerlemeKoprusu.shared.oku()
            katalog = try await k
            let d = await ek
            veri = .init(ikonografi: d["ikonografi.json"], zorluk: d["eser_zorluk.json"])
            ilerleme = il
            beklenen = il.ayar(Self.alan)
            kayit = nil
            if let metin = beklenen?.metin,
               let eski = try? JSONDecoder().decode(TurKaydi.self, from: Data(metin.utf8)),
               Date().timeIntervalSince(eski.zaman) <= 7 * 86400 {
                kayit = eski
            }
            turAcik = false
            hata = nil
        } catch {
            hata = "Katalog ve ilerleme okunamadı. Bağlantını kontrol edip yeniden dene."
        }
    }

    /// Her deneme aynı ekran durumundan başlar. Skor ile devam kaydı tek yazmada gider.
    private func yaz(_ islem: (inout Ilerleme) -> TurKaydi) async -> Bool {
        guard !mesgul else { return false }
        mesgul = true
        defer { mesgul = false }
        do {
            var yeni: TurKaydi?
            let il = try await IlerlemeKoprusu.shared.degistir { il in
                guard il.ayar(Self.alan) == beklenen else { throw IlerlemeKoprusu.Hata.cakisma }
                var tur = islem(&il)
                tur.zaman = Date()
                let d = try JSONEncoder().encode(tur)
                il.ayarla(Self.alan, tur.kart == nil ? nil : .metin(String(decoding: d, as: UTF8.self)))
                yeni = tur
            }
            ilerleme = il
            beklenen = il.ayar(Self.alan)
            kayit = yeni
            turAcik = true
            hata = nil
            return true
        } catch {
            hata = "İlerleme kaydedilemedi. Tekrar deneyebilir veya güncel kaydı yükleyebilirsin."
            return false
        }
    }

    func basla(_ kip: PekistirmeKipi, seviye: Int? = nil) async {
        guard let katalog else { return }
        _ = await yaz { il in
            var tur = TurKaydi(kip: kip, seviye: seviye, katalog: katalog, veri: veri, ilerleme: il, gun: GunTarihi.gun(Date()))
            tur.hazirla(katalog: katalog, veri: veri, ilerleme: &il)
            return tur
        }
    }

    func cevapla(_ secim: String?) async {
        guard let once = kayit, once.kart?.sonuc == nil, let katalog else { return }
        let kura = Double.random(in: 0..<1)
        let gun = GunTarihi.gun(Date())
        if await yaz({ il in
            var tur = once
            tur.cevapla(secim, katalog: katalog, gun: gun, ilerleme: &il, rastgele: { kura })
            return tur
        }), let sonuc = kayit?.kart?.sonuc {
            let acik = Titresim.acik(ilerleme)
            if sonuc { Titresim.dogru(acik: acik) } else { Titresim.yanlis(acik: acik) }
        }
    }

    func sonraki() async {
        guard let once = kayit, let katalog, once.kart?.sonuc != nil else { return }
        _ = await yaz { il in
            var tur = once
            tur.sonraki(katalog: katalog, veri: veri, ilerleme: &il)
            return tur
        }
    }
}

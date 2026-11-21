// Kaynak: sanat-atlasi js/temsil.js (TEMSIL_DISI, temsilOlabilir), js/ekranlar/ortak.js (enBilinen, kucukGorsel,
// bilinirlikSirasi, eserKareleriDoldur) @ a866b86
// Kâhin: Testler/kahin/temsil.mjs → Tests/NoraCekirdekTests/Ornekler/temsil/cevaplar.json (TemsilTests)
import Foundation

/// Sanatçıyı temsil eden eser: küçük görseller (`data-kucuk`), kitap kapakları, portreler, Tanış kartı, akım kartları.
public enum Temsil {
    /// `TEMSIL_DISI`: bir akımı, dönemi, konuyu ya da sanatçıyı temsil eden yerlerde hiç kullanılmayan eserler
    public static let disi: Set<String> = [
        "Q3947103", // Bonaventura Berlinghieri, Aziz Francesco ve hayatından sahneler (Pescia, 1235)
    ]

    /// `temsilOlabilir(e)`: eserin QID'i ya da anahtarı ("q:" öneki atılarak) temsil dışı değilse
    public static func olabilir(_ e: Eser) -> Bool {
        let a = e.anahtar.hasPrefix("q:") ? String(e.anahtar.dropFirst(2)) : e.anahtar
        return !(e.qid.map(disi.contains) ?? false) && !disi.contains(a)
    }

    /// `enBilinen(eserler)`: temsil edebilen, reddedilmemiş görseli olan ve pekiştirmeye açık eserler arasında bilinirliği
    /// (`sl`) en yüksek olan; eşitlikte listede önce gelen. Hiçbiri uygun değilse nil (temsilî görsel gösterilmez).
    public static func enBilinen(_ eserler: [Eser], kotuler: [String: [String]] = [:]) -> Eser? {
        let uygun = eserler.filter { olabilir($0) && GorselAdresleri.secilen($0, kotuler: kotuler) != nil && $0.pekistirme }
        guard var en = uygun.first else { return nil }
        for e in uygun where e.sl > en.sl { en = e }
        return en
    }

    /// `bilinirlikSirasi(eserler)`: `sl` büyükten küçüğe, eşitlikte listedeki sıra
    public static func bilinirlikSirasi(_ eserler: [Eser]) -> [Eser] {
        eserler.enumerated().sorted { $0.element.sl != $1.element.sl ? $0.element.sl > $1.element.sl : $0.offset < $1.offset }
            .map(\.element)
    }

    /// `eserKareleriDoldur`: `[data-eser-kucuk][data-sira=n]` kutusunun eseri (görseli olanlar, bilinirlik sırasıyla)
    public static func siradaki(_ eserler: [Eser], sira: Int) -> Eser? {
        let l = bilinirlikSirasi(eserler).filter { !$0.gorseller.isEmpty }
        return l.isEmpty ? nil : l[sira % l.count]
    }

    /// `kucukGorsel(e)`: kullanıcının reddetmediği ilk görsel, yoksa ilk görsel
    public static func kucukGorsel(_ e: Eser, kotuler: [String: [String]] = [:]) -> Gorsel? {
        GorselAdresleri.secilen(e, kotuler: kotuler) ?? e.gorseller.first
    }
}

extension SiteKatalogu {
    /// Sanatçının küçük görselinin adresi (`kucukKareleriDoldur`): en bilinen eserin `kucukGorsel`'i
    public func kucukGorselAdresi(_ sanatciId: String, genislik: Int = 400, kotuler: [String: [String]] = [:]) -> URL? {
        guard let e = Temsil.enBilinen(eserler(sanatciId), kotuler: kotuler),
              let g = Temsil.kucukGorsel(e, kotuler: kotuler) else { return nil }
        return GorselAdresleri.url(gorsel.url(g, genislik: genislik))
    }

    /// `eserKareleriDoldur`: sanatçının bilinirlik sırasıyla `sira`. eserinin küçük görseli (tablo düğmesi)
    public func eserGorselAdresi(_ sanatciId: String, sira: Int, genislik: Int = 400, kotuler: [String: [String]] = [:]) -> URL? {
        guard let e = Temsil.siradaki(eserler(sanatciId), sira: sira), let g = Temsil.kucukGorsel(e, kotuler: kotuler) else { return nil }
        return GorselAdresleri.url(gorsel.url(g, genislik: genislik))
    }
}

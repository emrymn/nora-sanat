// Kaynak: sanat-atlasi js/temsil.js (TEMSIL_DISI, temsilOlabilir, AKIM_KAPAK), js/ekranlar/ortak.js (enBilinen, kucukGorsel,
// bilinirlikSirasi, eserKareleriDoldur), js/akim.js (DORTLU_SECIMI, enBilinenEserler), js/ikonografi.js (kapakSec) @ a866b86
// Kâhin: Testler/kahin/temsil.mjs → Tests/NoraCekirdekTests/Ornekler/temsil/cevaplar.json (TemsilTests)
import Foundation

/// Sanatçıyı temsil eden eser: küçük görseller (`data-kucuk`), kitap kapakları, portreler, Tanış kartı, akım kartları.
public enum Temsil {
    /// `TEMSIL_DISI`: bir akımı, dönemi, konuyu ya da sanatçıyı temsil eden yerlerde hiç kullanılmayan eserler
    public static let disi: Set<String> = [
        "Q3947103", // Bonaventura Berlinghieri, Aziz Francesco ve hayatından sahneler (Pescia, 1235)
    ]

    /// `AKIM_KAPAK`: Galeri çarkında kemeri elle seçilmiş eserle dolan akımlar (akım → QID)
    public static let akimKapak: [String: String] = [
        "Gotik": "Q948745",
    ]

    /// `DORTLU_SECIMI`: akımın en bilinen eserlerinde bilinirliğe göre değil elle seçilen eser
    /// (sanatçı → QID ya da "sanatçıId|başlık"). Sanatçının sırası yine en bilinen eserinin `sl`'sine göredir.
    public static let dortluSecimi: [String: String] = [
        "pierre-puvis-de-chavannes": "Q19820268", // Çölde Mecdelli Meryem: Tatlı Manzara'nın tek görseli 500 px
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

    /// `kapakSec(eserler)` (konu kapağı): temsil edebilenler arasında `sl`'si en yüksek; eşitlikte önce gelen.
    /// Sitede eşitlikte `e.kurs` olan öne geçer, ama `onbellekEseri` nesnelerinde `kurs` alanı yok (yalnız `kaynak: 'kurs'`):
    /// koşul hiç tutmuyor. Site gibi davranmak için burada da yok (kâhin: galeri.mjs `kapaklar`).
    public static func kapakSec(_ eserler: [Eser]) -> Eser? {
        var en: Eser?
        for e in eserler where olabilir(e) {
            if let m = en, e.sl <= m.sl { continue }
            en = e
        }
        return en
    }

    /// `enBilinenEserler(listeler, adet)`: her sanatçıdan en çok bir eser (görseli olan, temsil edebilen; `dortluSecimi`
    /// yoksa en bilinen), sanatçılar en bilinen eserlerinin `sl`'sine göre (eşitlikte listedeki sıra)
    public static func enBilinenEserler(_ listeler: [(sanatci: Sanatci, eserler: [Eser])], adet: Int = 4)
        -> [(sanatci: Sanatci, eser: Eser)] {
        var ilk: [(sanatci: Sanatci, eser: Eser, sl: Int)] = []
        for (s, eserler) in listeler {
            let l = bilinirlikSirasi(eserler.filter { !$0.gorseller.isEmpty && olabilir($0) })
            guard let bas = l.first else { continue }
            let istenen = dortluSecimi[s.id]
            let e = istenen.flatMap { i in l.first { ($0.qid ?? "\(s.id)|\($0.baslik)") == i } } ?? bas
            ilk.append((s, e, bas.sl))
        }
        return ilk.enumerated().sorted { $0.element.sl != $1.element.sl ? $0.element.sl > $1.element.sl : $0.offset < $1.offset }
            .prefix(adet).map { ($0.element.sanatci, $0.element.eser) }
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

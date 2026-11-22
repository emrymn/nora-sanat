// Kaynak: sanat-atlasi js/gorsel.js (devasaSuz, devasaAdresleri, telefonAdresleri, tahminiBayt, telefonToplamBayt),
// js/eserler.js (gosterilenGorseller), js/ekranlar/ayarlar.js (devasaIndir'in parça seçimi) @ a866b86 (site 1.90.3)
import Foundation

/// "En büyük kopyaları telefona indir"in listesi (C5). Sitedeki gibi yalnız uygulamada gösterilen görseller:
/// en büyük kopyası olanların en büyük kopyası (d/), olmayanların 1280'liği (b/), sonra bütün 400'lükler (gorseller/k/),
/// sonra kalan 1280'likler. Sıra indirme sırasıdır (sayfaları en çok hızlandıranlar önce).
public struct CevrimdisiListe: Codable, Sendable, Equatable {
    /// Ayarlar'da "n eserin … en yüksek kalitedeki hali" (`devasaAdresleri()`)
    public let devasaAdresleri: [String]
    /// İndirilecek bütün dosyalar, sırayla (`telefonAdresleri()`)
    public let telefonAdresleri: [String]
    /// Gösterilen görseller hesaplanabildi mi (`suzulduMu()`); hesaplanamadıysa telefondakiler silinmez
    public let suzuldu: Bool
    let devasaSayisi: Int
    let devasaBayt: Double
    /// Bütün listenin tahmini boyu; bilinmiyorsa 0 — `telefonToplamBayt()` (bir kez hesaplanır)
    public private(set) var toplamBayt = 0.0

    public static let bOrtalamaBayt = 330.0 * 1024   // B_ORTALAMA_BAYT
    public static let kOrtalamaBayt = 42.0 * 1024    // K_ORTALAMA_BAYT

    /// - Parameters:
    ///   - gosterilen: gösterilen görsellerin yerel anahtarları (`gosterilenGorseller()`); nil: hesaplanamadı
    ///   - yalnizDevasa: sitenin `__atlasYalnizDevasa`'sı (testler)
    public init(gorsel g: GorselAdresleri, gosterilen: [String]?, yalnizDevasa: Bool = false) {
        devasaSayisi = g.devasa.count
        devasaBayt = g.devasaBayt
        guard let gosterilen else {
            suzuldu = false
            devasaAdresleri = g.devasaListesi.map(g.devasaYolu)
            telefonAdresleri = devasaAdresleri
            toplamBayt = hesaplaToplam()
            return
        }
        suzuldu = true
        // devasaSuz: Set'lerin ekleme sırası korunur
        var adlar: [String] = [], b: [String] = [], gs: [String] = []
        var adlarK = Set<String>(), bK = Set<String>(), gK = Set<String>()
        for a in gosterilen {
            guard let ad = dolu(g.yerel[a]) else { continue }
            if gK.insert(ad).inserted { gs.append(ad) }
            if g.devasa.contains(ad) { if adlarK.insert(ad).inserted { adlar.append(ad) } }
            else if g.hepsiBuyuk { if bK.insert(ad).inserted { b.append(ad) } }
        }
        devasaAdresleri = adlar.map(g.devasaYolu)
        var l = devasaAdresleri + b.map(g.buyukYolu)
        if !yalnizDevasa {
            l += gs.map { g.tam("gorseller/k/\($0).jpg") }
            if g.hepsiBuyuk { l += gs.filter { !bK.contains($0) }.map(g.buyukYolu) }
        }
        telefonAdresleri = l
        toplamBayt = hesaplaToplam()
    }

    public init(katalog k: SiteKatalogu) {
        self.init(gorsel: k.gorsel, gosterilen: k.gosterilenGorseller())
    }

    /// Adresin tahmini boyu (bayt) — `tahminiBayt(u)`
    public func tahminiBayt(_ u: String) -> Double {
        if u.range(of: "/d/[0-9a-f]", options: .regularExpression) != nil {
            return devasaSayisi > 0 && devasaBayt > 0 ? devasaBayt / Double(devasaSayisi) : 3.3e6
        }
        if u.range(of: "/k/[0-9a-f]", options: .regularExpression) != nil { return Self.kOrtalamaBayt }
        return Self.bOrtalamaBayt
    }

    private func hesaplaToplam() -> Double {
        devasaBayt > 0 || telefonAdresleri.count > devasaAdresleri.count
            ? telefonAdresleri.reduce(0) { $0 + tahminiBayt($1) }.rounded() : 0
    }

    // MARK: Parçalar

    /// Bir parçada en çok bu kadar en büyük kopya boyu (`PARCA`, ~0,7 GB)
    public static let parcaGorsel = 200
    /// Bir parçada en çok bu kadar dosya (`PARCA_ADET`)
    public static let parcaAdet = 1000

    public struct Parca: Sendable, Equatable {
        /// Bu parçada inecekler
        public let urller: [String]
        /// Kaçıncı parça, kaç parça
        public let parca: Int
        public let parcaSayisi: Int
        /// Parçadan önce telefonda olanlar (sayı ve tahmini bayt)
        public let onceden: Int
        public let oncedenBayt: Double
        /// Listenin tamamı
        public let hepsi: Int
        /// Kalanların hepsi bu parçada
        public let sonParca: Bool
    }

    /// Sıradaki parça: telefonda olmayanlar sırayla, parça boyu (`parcaGorsel` en büyük kopya kadar bayt) ya da
    /// `parcaAdet` dosya dolana kadar (`devasaIndir`)
    public func parca(telefonda: Set<String>, parcaGorsel: Int = CevrimdisiListe.parcaGorsel) -> Parca {
        let hepsi = telefonAdresleri
        let kalan = hepsi.filter { !telefonda.contains($0) }
        let boy = Double(parcaGorsel) * tahminiBayt("/d/0")
        var urller: [String] = []
        var parcaBayt = 0.0
        for u in kalan {
            if !urller.isEmpty && (parcaBayt + tahminiBayt(u) > boy + 1 || urller.count >= Self.parcaAdet) { break }
            urller.append(u)
            parcaBayt += tahminiBayt(u)
        }
        let bayt = { (l: [String]) in l.reduce(0.0) { $0 + tahminiBayt($1) } }
        let hepsiBayt = bayt(hepsi), kalanBayt = bayt(kalan)
        let parca = Int(((hepsiBayt - kalanBayt + 1) / boy).rounded(.down)) + 1
        let parcaSayisi = max(parca + Int(((kalanBayt - parcaBayt - 1) / boy).rounded(.up)), parca,
                              Int(((hepsiBayt - 1) / boy).rounded(.up)))
        return Parca(urller: urller, parca: parca, parcaSayisi: parcaSayisi, onceden: hepsi.count - kalan.count,
                     oncedenBayt: hepsiBayt - kalanBayt, hepsi: hepsi.count, sonParca: urller.count >= kalan.count)
    }
}

extension SiteKatalogu {
    /// Uygulamada gösterilen bütün görsellerin yerel anahtarları, eser önbelleğindeki sırayla (görünmeyen sanatçılar
    /// dahil; kopya kayıtlar ve çıkarılan görseller hariç). Önbellek yoksa nil — `gosterilenGorseller()`
    public func gosterilenGorseller() -> [String]? {
        guard let onbellek else { return nil }
        var s: [String] = [], gorulen = Set<String>()
        for sid in onbellekSirasi {
            let l = kurallar.kopyalariAyikla(sid, kurallar.duzeltmeleriUygula(sid, kurallar.cikarilanlariAyikla(onbellek[sid] ?? [])))
            for e in l { for g in e.gorseller where gorulen.insert(g.yerelAnahtar).inserted { s.append(g.yerelAnahtar) } }
        }
        return s
    }
}

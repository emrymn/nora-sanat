// Kaynak: sanat-atlasi js/soruTurlari.js, js/ekranlar/soruTurlari.js @ a866b86
import Foundation

/// Eserin kurs bölümünü veya ikonografi konusunu soran ek turlar.
/// Haritadaki bölüm turundan ve işlenen konunun sanatçı turundan ayrı skorları vardır.
public enum SoruTuru {
    case kursBolumu, ikonografi

    public func kartlar(adaylar: [String], ilerleme: Ilerleme, bugun: String,
                        rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> [String] {
        let skorlar = self == .ikonografi ? ilerleme.skorlarKonu : ilerleme.skorlar.compactMapValues(\.bolumKart)
        func kategori(_ s: Skor?) -> Int {
            if !Leitner.goruldu(s) { return 2 }
            if Leitner.vadesiGeldi(s, bugun) { return 0 }
            return Leitner.zayif(s) ? 1 : 3
        }
        // Site eşitlikler için önce her adayda bir çekiliş, sonra Fisher–Yates yapar.
        for _ in adaylar { _ = rastgele() }
        let liste = karistir(adaylar, rastgele).sorted { a, b in
            let x = skorlar[a], y = skorlar[b]
            let k = kategori(x), l = kategori(y)
            if k != l { return k < l }
            if k < 2 { return (x?.kutu ?? 0) < (y?.kutu ?? 0) }
            return k == 3 && (x?.son ?? "") < (y?.son ?? "")
        }
        return Array(liste.prefix(max(0, ilerleme.ayar("gunlukKart")?.tamSayi ?? 20)))
    }

    public static func bolumSecenekleri(dogru: String, siraliBolumler: [String],
                                        rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> [String] {
        guard let i = siraliBolumler.firstIndex(of: dogru) else { return [] }
        let diger = siraliBolumler.enumerated().map { (id: $0.element, uzak: abs($0.offset - i), kura: rastgele()) }
            .filter { $0.id != dogru }.sorted { ($0.uzak, $0.kura) < ($1.uzak, $1.kura) }
        return karistir([dogru] + diger.prefix(3).map(\.id), rastgele)
    }

    public static func konuSecenekleri(dogru: String, konular: [(id: String, tur: String)],
                                       rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> [String] {
        guard let konu = konular.first(where: { $0.id == dogru }) else { return [] }
        let kalan = konular.filter { $0.id != dogru }
        let ayni = karistir(kalan.filter { $0.tur == konu.tur }, rastgele)
        let diger = karistir(kalan.filter { $0.tur != konu.tur }, rastgele)
        return karistir([dogru] + (ayni + diger).prefix(3).map(\.id), rastgele)
    }

    public func cevapla(oturum: inout PekistirmeOturumu, konum: Int, dogru: Bool, akim: String?,
                        bugun: String, ilerleme: inout Ilerleme,
                        rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard konum == oturum.konum, let id = oturum.simdiki?.id else { return }
        switch self {
        case .kursBolumu:
            var skor = ilerleme.skorlar[id] ?? SkorKaydi()
            skor.bolumKart = Leitner.cevapla(skor.bolumKart, dogru: dogru, bugun: bugun)
            ilerleme.skorlar[id] = skor
        case .ikonografi:
            let once = ilerleme.skorlarKonu[id]
            ilerleme.skorlarKonu[id] = Leitner.cevapla(once, dogru: dogru, bugun: bugun)
        }
        ilerleme.gecmisEkle(tarih: bugun, dogru: dogru, akim: akim)
        oturum.ilerle(dogruMu: dogru, rastgele: rastgele)
    }
}

// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (oturumKur, kartHazirla) @ a866b86
import Foundation

public extension TurPlani {
    static func kur(_ tur: PekistirmeTuru, katalog: SiteKatalogu, ilerleme: Ilerleme, bugun: String,
                    rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Self {
        kur(tur, sanatcilar: katalog.sanatcilar, ilerleme: ilerleme, bugun: bugun, akimSira: katalog.akimSira,
            eseriVar: { !$0.kursEserleri.isEmpty || !katalog.eserler($0.id).isEmpty }, rastgele: rastgele)
    }
}

public struct PekistirmeKarti {
    public let sanatci: Sanatci
    public let eser: Eser
    public let seviye: Int
    public let secenekler: [String]
    public let akimSecenekleri: [String]?
    public let ters: [KartEseri.Secenek]?

    /// Yalnız kart başarıyla kurulunca son sekiz eseri tazeler.
    /// - `kolaylik`: `data/eser_zorluk.json`'un `kolaylik` sözlüğü (anahtar QID ya da `sanatçıId|başlık`).
    /// - `konu(eser, sanatçıId)`: sitenin `eserKonusu`'u (ikonografi haritasında önce QID, yoksa `sanatçıId|başlık`);
    ///   ters soruda yanlış eserler mümkünse doğru eserle aynı konudan seçilir.
    public static func hazirla(_ kart: PekistirmeOturumu.Kart, tur: PekistirmeTuru, plan: TurPlani,
                               katalog: SiteKatalogu, ilerleme: inout Ilerleme, seciliSeviye: Int? = nil,
                               kolaylik: [String: Double] = [:], tanismadaGorulen: [String] = [],
                               konu: (Eser, String) -> String? = { _, _ in nil },
                               rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Self? {
        guard let s = katalog.harita[kart.id] else { return nil }
        let sv: Int
        var karma = false
        if case let .bolum(_, _, seviye) = tur {
            switch seviye {
            case .kolay, .tanitim(false, _): sv = 0
            case .orta, .tanitim(true, _): sv = 1
            case .zor: sv = 2
            }
            karma = sv < 2
        } else {
            sv = Seviye.kartSeviyesi(Seviye.kayit(ilerleme.seviyeler, s.akim), secili: seciliSeviye)
        }
        let eserler = katalog.eserler(s.id)
        var puanlar: [String: Double] = [:]
        for e in eserler {
            puanlar[e.anahtar] = e.qid.flatMap { kolaylik[$0] } ?? kolaylik["\(s.id)|\(e.baslik)"]
        }
        let koleksiyon = ilerleme[alan: "koleksiyon"]?.dizi ?? []
        let isaretli = Set(koleksiyon.filter { $0["s"]?.metin == s.id }.compactMap { $0["a"]?.metin })
        let sonEserler = ilerleme[alan: "sonEserler"]?.nesne ?? .bos
        let son = sonEserler[s.id]?.dizi?.compactMap(\.metin) ?? []
        let kotuler = ilerleme.kotuGorseller
        guard let eser = KartEseri.sec(eserler, tur: tur, seviye: sv, son: son, tanismadaGorulen: tanismadaGorulen,
                                       kolaylik: puanlar, isaretli: isaretli, kotuler: kotuler, rastgele: rastgele) else { return nil }
        let yeni = (son.filter { $0 != eser.anahtar } + [eser.anahtar]).suffix(8)
        ilerleme[alan: "sonEserler"] = .nesne(sonEserler.ayarlandi(s.id, .dizi(yeni.map(JSONDeger.metin))))
        let acik = Set(ilerleme.acikSanatcilar(katalog.sanatcilar).map(\.id))
        let zorluk: Celdirici.Zorluk = karma ? .karma : (sv == 0 ? .kolay : sv == 1 ? .orta : .zor)
        func sec(_ es: String?) -> [String] {
            Celdirici.sanatciSecenekleri(s, sanatcilar: katalog.sanatcilar, akimlar: katalog.akimlar, acik: acik,
                                         zorluk: zorluk, ortak: eser.ortak, es: es, rastgele: rastgele)
        }
        let secenekler = sec(plan.esler[s.id])
        let akimlar = tur == .karisik ? Celdirici.akimSecenekleri(s.akim, akimlar: katalog.akimlar, kolay: sv == 0, rastgele: rastgele) : nil
        if KartEseri.tersSorulur(tur, seviye: sv, rastgele: rastgele) {
            var gorulen = Set([s.id])
            let idler = (secenekler + sec(nil)).filter { gorulen.insert($0).inserted }
            let adaylar = idler.map { (id: $0, eserler: katalog.eserler($0)) }
            if let ters = KartEseri.tersSecenekleri(dogru: (s.id, eser), adaylar: adaylar, kotuler: kotuler,
                                                    konu: konu, rastgele: rastgele) {
                return Self(sanatci: s, eser: eser, seviye: sv, secenekler: ters.map(\.id), akimSecenekleri: nil, ters: ters)
            }
        }
        return Self(sanatci: s, eser: eser, seviye: sv, secenekler: secenekler, akimSecenekleri: akimlar, ters: nil)
    }
}

// Kaynak: sanat-atlasi js/oturum.js, js/turlar.js, js/bolum.js, js/ekranlar/pekistir.js @ a866b86
import Foundation

public enum PekistirmeTuru: Equatable {
    case karisik
    /// nil bütün dönemleri kronolojik sırayla sorar.
    case donem(String?)
    case konu(Int)
    case bolum(id: String, sanatcilar: [String], seviye: BolumSeviyesi)
    case hatalar
}

public enum BolumSeviyesi: Equatable {
    case kolay, orta, zor
    /// Grup sıfırdan başlar. nil bütün bölümün tanışmasıdır.
    case tanitim(orta: Bool, grup: Int?)
}

public typealias PekistirmeRastgele = () -> Double

/// Sitenin Fisher–Yates sırası. Verilen üreteç 0..<1 aralığında olmalıdır.
func karistir<T>(_ liste: [T], _ rastgele: PekistirmeRastgele) -> [T] {
    var sonuc = liste
    for i in sonuc.indices.dropFirst().reversed() {
        sonuc.swapAt(i, Int(rastgele() * Double(i + 1)))
    }
    return sonuc
}

public struct TurPlani {
    public var kartlar: [String] = []
    public var tanisma: [String] = []
    public var esler: [String: String] = [:]

    public static func kur(_ tur: PekistirmeTuru, sanatcilar: [Sanatci], ilerleme: Ilerleme,
                           bugun: String, akimSira: [String: Double], eseriVar: (Sanatci) -> Bool,
                           rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Self {
        let acik = ilerleme.acikSanatcilar(sanatcilar).filter(eseriVar)
        let skorlar = ilerleme.skorlar
        switch tur {
        case .karisik, .donem:
            var adaylar = acik
            if case let .donem(akim?) = tur { adaylar = acik.filter { $0.akim == akim } }
            let yeni = ilerleme.gunluk.tarih == bugun ? ilerleme.gunluk.yeni : 0
            var kartlar = kartlariSec(adaylar, skorlar: skorlar, bugun: bugun,
                                      adet: ilerleme.ayar("gunlukKart")?.tamSayi ?? 20,
                                      kota: Leitner.gunlukYeniSiniri - yeni,
                                      karisik: tur == .karisik, rastgele: rastgele)
            if tur == .donem(nil) {
                kartlar.sort { (akimSira[$0.akim] ?? 0) < (akimSira[$1.akim] ?? 0) }
            }
            return Self(kartlar: kartlar.map(\.id))
        case let .konu(no):
            let adaylar = acik.filter { $0.konu == no }
            let yeni = adaylar.filter { Ogrenme.tanismaGerekir(skorlar[$0.id]) }
            let eski = adaylar.filter { !Ogrenme.tanismaGerekir(skorlar[$0.id]) }
            let ilk = Array((karistir(yeni, rastgele) + karistir(eski, rastgele)).prefix(8)).map(\.id)
            var kartlar = ilk
            var kalan = karistir(ilk, rastgele)
            while !ilk.isEmpty && kartlar.count < 6 {
                if kalan.isEmpty { kalan = karistir(ilk, rastgele) }
                let i = kalan.firstIndex { $0 != kartlar.last } ?? 0
                kartlar.append(kalan.remove(at: i))
            }
            let tanisma = yeni.filter { $0.kaynak == "kurs" } + yeni.filter { $0.kaynak != "kurs" }
            return Self(kartlar: kartlar, tanisma: ilerleme.ayar("tanisma")?.mantik == false ? [] : tanisma.map(\.id))
        case let .bolum(id, sanatcilar, seviye):
            return bolum(id, sanatcilar, seviye, acik: Set(acik.map(\.id)), ilerleme: ilerleme, rastgele: rastgele)
        case .hatalar:
            let alt = GunTarihi.ekle(bugun, -7)
            func yakin(_ tarih: String) -> Bool { tarih > alt && tarih <= bugun }
            let ids = Set(acik.map(\.id))
            let ikililer = ilerleme.karisanlarSirali.filter { $0.deger.n > 0 && yakin($0.deger.son) }
                .sorted { a, b in a.deger.n == b.deger.n ? a.deger.son > b.deger.son : a.deger.n > b.deger.n }
            var plan = Self()
            for ikili in ikililer {
                let parca = ikili.anahtar.components(separatedBy: "|")
                guard parca.count == 2 else { continue }
                let a = parca[0], b = parca[1]
                guard a != b, ids.contains(a), ids.contains(b), plan.esler[a] == nil, plan.esler[b] == nil else { continue }
                plan.esler[a] = b
                plan.esler[b] = a
                plan.kartlar += rastgele() < 0.5 ? [a, b] : [b, a]
                if plan.kartlar.count == 8 { break }
            }
            let hatali = acik.filter {
                guard let s = skorlar[$0.id]?.sanatci else { return false }
                return s.kutu == 0 && s.yanlis > 0 && yakin(s.son ?? "")
            }
            let diger = karistir(hatali, rastgele).map(\.id).filter { plan.esler[$0] == nil }
            plan.kartlar += diger.prefix(20 - plan.kartlar.count)
            return plan
        }
    }

    private static func bolum(_ id: String, _ idler: [String], _ seviye: BolumSeviyesi,
                              acik: Set<String>, ilerleme: Ilerleme, rastgele: PekistirmeRastgele) -> Self {
        let adet = idler.count < 6 ? 1 : (idler.count + 3) / 4
        var gruplar: [[String]] = []
        var bas = 0
        for i in 0..<adet {
            let son = bas + idler.count / adet + (i < idler.count % adet ? 1 : 0)
            gruplar.append(idler[bas..<son].filter(acik.contains))
            bas = son
        }
        var adaylar = gruplar.flatMap { $0 }
        var tanisma: [String] = []
        var soru = seviye == .kolay ? 8 : 10
        if case let .tanitim(_, grup) = seviye {
            guard let grup, gruplar.indices.contains(grup) else { return Self(tanisma: adaylar) }
            adaylar = gruplar[grup]
            tanisma = adaylar
            soru = adaylar.count * 2
        } else if seviye != .zor {
            let kayit = ilerleme[alan: "bolumler"]?[id]
            let alan = seviye == .orta ? "tanitimOrta" : "tanitim"
            if kayit?[alan]?.mantik != true {
                let gorulen = Set(kayit?[alan + "Grup"]?.dizi?.compactMap(\.tamSayi) ?? [])
                tanisma = gruplar.indices.filter { !gorulen.contains($0) }.flatMap { gruplar[$0] }
            }
        }
        var kartlar: [String] = []
        while !adaylar.isEmpty && kartlar.count < soru {
            var tur = karistir(adaylar, rastgele)
            if tur.count > 1 && tur.first == kartlar.last { tur.swapAt(0, 1) }
            kartlar += tur
        }
        return Self(kartlar: Array(kartlar.prefix(soru)), tanisma: tanisma)
    }

    static func kartlariSec(_ adaylar: [Sanatci], skorlar: [String: SkorKaydi], bugun: String,
                            adet: Int, kota: Int, karisik: Bool, rastgele: PekistirmeRastgele) -> [Sanatci] {
        var yeniKalan = max(0, kota)
        var bilgi = adaylar.map { s -> (s: Sanatci, k: Int, kutu: Int, son: String) in
            let sk = skorlar[s.id]
            let adaySkorlar: [Skor?] = karisik ? [sk?.sanatci, sk?.akim] : [sk?.sanatci]
            let ilgili: [Skor] = adaySkorlar.compactMap { $0 }.filter { Leitner.goruldu($0) }
            let k: Int
            if ilgili.isEmpty { k = 2 }
            else if ilgili.contains(where: { Leitner.vadesiGeldi($0, bugun) }) { k = 0 }
            else if ilgili.contains(where: Leitner.zayif) { k = 1 }
            else { k = 3 }
            return (s, k, ilgili.map(\.kutu).min() ?? 99, ilgili.compactMap(\.son).min() ?? "")
        }
        var secilen: [Sanatci] = []
        if karisik {
            let agirlik = [6, 4, 3, 1]
            while secilen.count < adet {
                if yeniKalan <= 0 { bilgi.removeAll { $0.k == 2 } }
                guard !bilgi.isEmpty else { break }
                var r = rastgele() * Double(bilgi.reduce(0) { $0 + agirlik[$1.k] })
                let i = bilgi.firstIndex { r -= Double(agirlik[$0.k]); return r < 0 } ?? bilgi.count - 1
                let x = bilgi.remove(at: i)
                secilen.append(x.s)
                if x.k == 2 { yeniKalan -= 1 }
            }
        } else {
            let sirali = karistir(bilgi, rastgele).sorted { a, b in
                if a.k != b.k { return a.k < b.k }
                if a.k <= 1 { return a.kutu < b.kutu }
                if a.k == 2 { return (a.s.dogum ?? 0) < (b.s.dogum ?? 0) }
                return a.son < b.son
            }
            for x in sirali where secilen.count < adet {
                if x.k == 2 && yeniKalan == 0 { continue }
                if x.k == 2 { yeniKalan -= 1 }
                secilen.append(x.s)
            }
        }
        return secilen
    }
}

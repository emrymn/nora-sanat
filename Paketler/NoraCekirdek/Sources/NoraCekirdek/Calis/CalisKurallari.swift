// Kaynak: sanat-atlasi js/oturum.js, js/ekranlar/bugun.js, js/ekranlar/pekistir.js, js/ekranlar/soruTurlari.js,
// js/ekranlar/gozat.js, js/soruTurlari.js, js/ikonografi.js, js/ekranlar/calisma.js, js/yardimci.js @ a866b86
import Foundation

/// Tur önizlemesi (`js/oturum.js` `turOzeti`): turun kaç kart seçeceği ve türleri.
public struct TurOzeti: Equatable, Sendable, Codable {
    public var toplam: Int
    public var tekrar: Int
    public var zayif: Int
    public var yeni: Int
    public var diger: Int

    public init(toplam: Int = 0, tekrar: Int = 0, zayif: Int = 0, yeni: Int = 0, diger: Int = 0) {
        self.toplam = toplam
        self.tekrar = tekrar
        self.zayif = zayif
        self.yeni = yeni
        self.diger = diger
    }

    /// Pekiştirme kartları (`zayif + diger`)
    public var pekistirme: Int { zayif + diger }

    /// Yaklaşık süre (dakika): `Math.max(1, Math.round((toplam * 20) / 60))`
    public var yaklasikDakika: Int { max(1, Int((Double(toplam * 20) / 60.0).rounded())) }
}

/// Hatalarım turunun özeti (`js/turlar.js` `hatalarTuru` + `js/ekranlar/pekistir.js` `hatalarBilgisi`, `hatalarSatiri`)
public struct HatalarOzeti: Equatable, Sendable, Codable {
    public struct Ikili: Equatable, Sendable, Codable {
        public var a: String
        public var b: String
        public var n: Int
        public var son: String

        public init(a: String, b: String, n: Int, son: String) {
            self.a = a; self.b = b; self.n = n; self.son = son
        }
    }

    public var idler: [String]
    public var esler: [String: String]
    public var ikililer: [Ikili]
    public var hatalilar: [String]

    /// `"X sanatçı · Y karıştırılan ikili · son 7 gün"`
    public var altYazi: String {
        let parca = ["\(hatalilar.count) sanatçı", ikililer.isEmpty ? "" : "\(ikililer.count) karıştırılan ikili"]
            .filter { !$0.isEmpty }.joined(separator: " · ")
        return "\(parca) · son 7 gün"
    }

    /// Karıştırılan ikililerin bilinen adlarıyla yazısı: `"A ↔ B · C ↔ D"`
    public func ikiliYazisi(_ katalog: SiteKatalogu) -> String {
        ikililer.map { x in
            let adA = katalog.bilinenAd(x.a) ?? x.a
            let adB = katalog.bilinenAd(x.b) ?? x.b
            return "\(adA) ↔ \(adB)"
        }.joined(separator: " · ")
    }
}

/// Çalış'taki "Karşılaştır" karosu (`js/ekranlar/gozat.js` `karsilastirSecimi`)
public struct KarsilastirSecimi: Equatable, Sendable, Codable {
    public var adres: String
    public var alt: String

    public init(adres: String, alt: String) {
        self.adres = adres
        self.alt = alt
    }
}

/// Dönem salonu satırı (`js/ekranlar/pekistir.js` `pekistirMenusu`, `donemSatiri`)
public struct DonemSalonu: Equatable, Sendable, Codable, Identifiable {
    public var id: String { ad }
    public var ad: String
    public var acikSayisi: Int
    public var temsilciId: String?
    public var seviyeKaydi: SeviyeKaydi
    public var seviyeRozeti: String
    public var tur: TurOzeti
    public var turYazisi: String
    public var dogru: Int
    public var toplam: Int
    public var vade: Int
    public var oranYuzde: Int?
}

/// Dönem sıralama seçenekleri (`DONEM_SIRALARI`)
public enum DonemSiralamasi: String, CaseIterable, Sendable, Codable {
    case sira = "sira"
    case tekrar = "tekrar"
    case zayif = "zayif"

    public var baslik: String {
        switch self {
        case .sira: return "Sırayla"
        case .tekrar: return "Tekrarı olan"
        case .zayif: return "Zayıf önce"
        }
    }
}

/// Kurs bölümü bilgisi (`js/soruTurlari.js` `kursBolumleri`, `bolumKisaAdi`, `yuzyilAraligi`)
public struct KursBolumuBilgisi: Equatable, Sendable, Codable, Identifiable {
    public var id: String
    public var no: Int
    public var ad: String
    public var kisaAd: String
    public var konular: [Int]
}

/// İkonografi konusu tam detayı (`js/ikonografi.js` `konulariAl`, `TUR_AD`)
public struct IkonografiKonusu: Equatable, Sendable, Codable, Identifiable {
    public var id: String
    public var ad: String
    public var tur: String
    public var turAdi: String
    public var ozet: String
    public var kaynak: String
    public var hikaye: [String]
    public var tanima: [String]
    public var eserler: [[String]]
}

/// Çalış ve Turlar ekranlarının kural mantığı
public enum CalisKurallari {

    // MARK: - Bulunma eki ve konum yazısı (js/yardimci.js, js/ekranlar/ders.js)

    /// `bulunmaEki(n)`: `3'te`, `9'da`, `11'de`, `40'ta`…
    public static func bulunmaEki(_ n: Int) -> String {
        let sayi = abs(n)
        let birler = ["", "de", "de", "te", "te", "te", "da", "de", "de", "da"]
        let onlar = ["", "da", "de", "da", "ta", "de", "ta", "de", "de", "da"]
        if sayi == 0 { return "\(n)'da" }
        if sayi % 10 != 0 { return "\(n)'\(birler[sayi % 10])" }
        if sayi % 100 != 0 { return "\(n)'\(onlar[(sayi / 10) % 10])" }
        return "\(n)'de"
    }

    /// `konumYazisi()` (`js/ekranlar/ders.js`): `"Konu 11'desin"`
    public static func konumYazisi(islenen: Set<Int>) -> String {
        guard let enSon = islenen.max() else { return "" }
        let ek = bulunmaEki(enSon)
        let kalin = ek.hasSuffix("a") || ek.hasSuffix("ı")
        return "Konu \(ek)\(kalin ? "sın" : "sin")"
    }

    // MARK: - Tur özeti ve alt yazısı (js/oturum.js, js/ekranlar/bugun.js)

    /// `kategori(skorlar, id, kip, bugun)` (`js/oturum.js`): 0 vadesi gelmiş, 1 zayıf, 2 yeni, 3 diğer
    public static func kategori(skorlar: [String: SkorKaydi], id: String, karisik: Bool, bugun: String) -> Int {
        let sk = skorlar[id]
        let ss: [Skor] = (karisik ? [sk?.sanatci, sk?.akim] : [sk?.sanatci]).compactMap { $0 }
        let gorulen = ss.filter { Leitner.goruldu($0) }
        if gorulen.isEmpty { return 2 }
        if gorulen.contains(where: { Leitner.vadesiGeldi($0, bugun) }) { return 0 }
        if gorulen.contains(where: Leitner.zayif) { return 1 }
        return 3
    }

    /// `turOzeti({ adaylar, skorlar, bugun, adet, yeniKota, kip })` (`js/oturum.js`)
    public static func turOzeti(
        adaylar: [Sanatci],
        skorlar: [String: SkorKaydi],
        bugun: String,
        adet: Int,
        yeniKota: Int,
        karisik: Bool
    ) -> TurOzeti {
        var say = [0, 0, 0, 0]
        for s in adaylar {
            say[kategori(skorlar: skorlar, id: s.id, karisik: karisik, bugun: bugun)] += 1
        }
        let yeniUygun = min(say[2], max(0, yeniKota))
        let toplam = max(0, min(adet, say[0] + say[1] + say[3] + yeniUygun))
        let tekrar = min(say[0], toplam)
        let zayif = min(say[1], toplam - tekrar)
        let yeni = min(yeniUygun, toplam - tekrar - zayif)
        return TurOzeti(toplam: toplam, tekrar: tekrar, zayif: zayif, yeni: yeni, diger: toplam - tekrar - zayif - yeni)
    }

    /// `turBilgisi(kip, akim)` (`js/ekranlar/bugun.js`)
    public static func turBilgisi(
        sanatcilar: [Sanatci],
        ilerleme: Ilerleme,
        bugun: String,
        karisik: Bool = true,
        akim: String? = nil
    ) -> TurOzeti {
        let acik = ilerleme.acikSanatcilar(sanatcilar).filter { s in
            guard !karisik, let akim, akim != "hepsi" else { return true }
            return s.akim == akim
        }
        let yeni = ilerleme.gunluk.tarih == bugun ? ilerleme.gunluk.yeni : 0
        let adet = ilerleme.ayar("gunlukKart")?.tamSayi ?? 20
        return turOzeti(
            adaylar: acik,
            skorlar: ilerleme.skorlar,
            bugun: bugun,
            adet: adet,
            yeniKota: Leitner.gunlukYeniSiniri - yeni,
            karisik: karisik
        )
    }

    /// `turAltYazisi(o)` (`js/oturum.js`): `"0 tekrar · 8 yeni"` veya `"bugünkü kartlar bitti"`
    public static func turAltYazisi(_ o: TurOzeti) -> String {
        guard o.toplam > 0 else { return "bugünkü kartlar bitti" }
        var parca = ["\(o.tekrar) tekrar"]
        if o.zayif + o.diger > 0 { parca.append("\(o.zayif + o.diger) pekiştirme") }
        parca.append("\(o.yeni) yeni")
        return parca.joined(separator: " · ")
    }

    /// Dönem satırlarındaki tur yazısı (`pekistir.js` `turYazi`): `"12 kart · 3 tekrar"`
    public static func donemTurYazisi(_ t: TurOzeti) -> String {
        "\(t.toplam) kart\(t.tekrar > 0 ? " · \(t.tekrar) tekrar" : "")"
    }

    // MARK: - Başka turlar: Hatalarım, Bölüm turu, Karşılaştır

    /// `hatalarBilgisi()` (`js/turlar.js` `hatalarTuru` + `js/ekranlar/pekistir.js` `rng: () => 0.5`)
    public static func hatalarBilgisi(sanatcilar: [Sanatci], ilerleme: Ilerleme, bugun: String) -> HatalarOzeti {
        let acik = ilerleme.acikSanatcilar(sanatcilar)
        let alt = GunTarihi.ekle(bugun, -7)
        func yakin(_ tarih: String?) -> Bool {
            guard let tarih, !tarih.isEmpty else { return false }
            return tarih > alt && tarih <= bugun
        }
        let ids = Set(acik.map(\.id))
        let ikiliAdaylari = ilerleme.karisanlarSirali.filter { $0.deger.n > 0 && yakin($0.deger.son) }
            .sorted { a, b in
                if a.deger.n != b.deger.n { return a.deger.n > b.deger.n }
                return a.deger.son > b.deger.son
            }
        var idler: [String] = []
        var esler: [String: String] = [:]
        var ikililer: [HatalarOzeti.Ikili] = []
        var alindi = Set<String>()
        for ikili in ikiliAdaylari {
            let p = ikili.anahtar.components(separatedBy: "|")
            guard p.count == 2 else { continue }
            let a = p[0], b = p[1]
            guard a != b, ids.contains(a), ids.contains(b), !alindi.contains(a), !alindi.contains(b) else { continue }
            alindi.insert(a); alindi.insert(b)
            esler[a] = b; esler[b] = a
            ikililer.append(.init(a: a, b: b, n: ikili.deger.n, son: ikili.deger.son))
            // rng: () => 0.5 → 0.5 < 0.5 false → [b, a]
            idler.append(contentsOf: [b, a])
            if idler.count >= 8 { break }
        }
        let hatalilar = acik.filter { s in
            guard let sk = ilerleme.skorlar[s.id]?.sanatci else { return false }
            return sk.kutu == 0 && sk.yanlis > 0 && yakin(sk.son)
        }
        let rng05: PekistirmeRastgele = { 0.5 }
        for s in karistir(hatalilar, rng05) {
            if idler.count >= 20 { break }
            if !alindi.contains(s.id) {
                alindi.insert(s.id)
                idler.append(s.id)
            }
        }
        return HatalarOzeti(idler: idler, esler: esler, ikililer: ikililer, hatalilar: hatalilar.map(\.id))
    }

    /// `bolumAdaylari` sayısı (`js/ekranlar/soruTurlari.js`): `Math.min(gunlukKart, bolumAdaylari.length)`
    public static func bolumTuruKartSayisi(katalog: SiteKatalogu, ilerleme: Ilerleme) -> Int {
        let bolumKonulari = Set(katalog.konular.map(\.no))
        let adaySayisi = ilerleme.acikSanatcilar(katalog.sanatcilar).filter { s in
            s.konu.map(bolumKonulari.contains) == true
        }.count
        let hedef = ilerleme.ayar("gunlukKart")?.tamSayi ?? 20
        return min(hedef, adaySayisi)
    }

    /// `akimKarsilastirmaAdresi(a, b)` (`js/akim.js`)
    public static func akimKarsilastirmaAdresi(_ a: String, _ b: String) -> String {
        "#/akim-karsilastir/\(SiteYazisi.uriBileseni(a))/\(SiteYazisi.uriBileseni(b))"
    }

    /// `karsilastirSecimi()` (`js/ekranlar/gozat.js`): en çok karıştırılan ikili (eşik 1), yoksa açık ilk iki akım
    public static func karsilastirSecimi(katalog: SiteKatalogu, ilerleme: Ilerleme) -> KarsilastirSecimi? {
        if let ilk = Ogrenme.enCok(ilerleme.karisanlarSirali, adet: 1, esik: 1, varMi: { katalog.harita[$0] != nil }).first {
            let adA = katalog.bilinenAd(ilk.a) ?? ilk.a
            let adB = katalog.bilinenAd(ilk.b) ?? ilk.b
            return KarsilastirSecimi(
                adres: GoruntuleyiciKurallari.karsilastirmaAdresi(ilk.a, ilk.b),
                alt: "\(adA) ↔ \(adB)"
            )
        }
        let acik = Kilit.akimDurumlari(katalog.akimlar, katalog.sanatcilar, islenen: ilerleme.islenenKume).filter(\.acik)
        guard acik.count >= 2 else { return nil }
        return KarsilastirSecimi(
            adres: akimKarsilastirmaAdresi(acik[0].ad, acik[1].ad),
            alt: "\(acik[0].ad) ↔ \(acik[1].ad)"
        )
    }

    // MARK: - Döneme göre / Turlar ekranı (#/pekistir/donem, js/ekranlar/pekistir.js)

    /// Sahnedeki 3 kartlık deste (`turSahnesi` `deste`)
    public static func sahneDestesi(sanatcilar: [Sanatci], ilerleme: Ilerleme, bugun: String) -> [Sanatci] {
        let acik = ilerleme.acikSanatcilar(sanatcilar)
        let skorlar = ilerleme.skorlar
        var liste: [(sira: Int, s: Sanatci, k: Int)] = []
        for (i, s) in acik.enumerated() {
            liste.append((i, s, kategori(skorlar: skorlar, id: s.id, karisik: true, bugun: bugun)))
        }
        liste.sort { a, b in a.k != b.k ? a.k < b.k : a.sira < b.sira }
        return liste.prefix(3).map(\.s)
    }

    /// Günlük hedef seçenekleri (`[...new Set([10, 20, 30, hedef])].sort((x, y) => x - y)`)
    public static func gunlukHedefSecenekleri(mevcut: Int) -> [Int] {
        Array(Set([10, 20, 30, mevcut])).sorted()
    }

    /// "Hepsi, dönem sırasıyla" salonunun 4 sanatçılık mozaiği (`hepsiSalonu`)
    public static func hepsiMozaikSanatcilari(acik: [Sanatci]) -> [Sanatci] {
        var ornek: [Sanatci] = []
        var gorulen = Set<String>()
        for s in acik where !gorulen.contains(s.akim) && ornek.count < 4 {
            gorulen.insert(s.akim)
            ornek.append(s)
        }
        return ornek
    }

    /// Dönemin temsilci sanatçısı (`temsilci(ad, acik)`: önce `kaynak == 'kurs'`, yoksa ilki)
    public static func donemTemsilcisi(akim: String, acik: [Sanatci]) -> Sanatci? {
        let l = acik.filter { $0.akim == akim }
        return l.first { $0.kaynak == "kurs" } ?? l.first
    }

    /// Dönem salonları (`pekistirMenusu`): sıralı açık dönem salonları
    public static func donemSalonlari(
        katalog: SiteKatalogu,
        ilerleme: Ilerleme,
        bugun: String,
        siralama: DonemSiralamasi = .sira
    ) -> [DonemSalonu] {
        let durumlar = Kilit.akimDurumlari(katalog.akimlar, katalog.sanatcilar, islenen: ilerleme.islenenKume).filter(\.acik)
        let acik = ilerleme.acikSanatcilar(katalog.sanatcilar)
        let pano = BenPanosu(ilerleme, sanatcilar: katalog.sanatcilar, akimlar: katalog.akimlar, bugun: bugun)
        let istHarita = Dictionary(pano.akimlar.map { ($0.id, $0) }, uniquingKeysWith: { _, b in b })
        let seviyeler = ilerleme.seviyeler

        var sirali = Array(durumlar.enumerated())
        switch siralama {
        case .sira:
            break
        case .tekrar:
            sirali.sort { a, b in
                let va = istHarita[a.element.ad]?.vade ?? 0
                let vb = istHarita[b.element.ad]?.vade ?? 0
                return va != vb ? va > vb : a.offset < b.offset
            }
        case .zayif:
            sirali.sort { a, b in
                let sa = Seviye.kayit(seviyeler, a.element.ad).s
                let sb = Seviye.kayit(seviyeler, b.element.ad).s
                if sa != sb { return sa < sb }
                let oa = istHarita[a.element.ad]?.oran ?? 2.0
                let ob = istHarita[b.element.ad]?.oran ?? 2.0
                if oa != ob { return oa < ob }
                return a.offset < b.offset
            }
        }

        return sirali.map { _, a in
            let kayit = Seviye.kayit(seviyeler, a.ad)
            let tur = turBilgisi(sanatcilar: katalog.sanatcilar, ilerleme: ilerleme, bugun: bugun, karisik: false, akim: a.ad)
            let ist = istHarita[a.ad] ?? AkimBasarisi(id: a.ad)
            let yuzde = ist.oran.map { Int(($0 * 100).rounded()) }
            return DonemSalonu(
                ad: a.ad,
                acikSayisi: a.acikSayisi,
                temsilciId: donemTemsilcisi(akim: a.ad, acik: acik)?.id,
                seviyeKaydi: kayit,
                seviyeRozeti: Seviye.kisa(kayit),
                tur: tur,
                turYazisi: donemTurYazisi(tur),
                dogru: ist.dogru,
                toplam: ist.toplam,
                vade: ist.vade,
                oranYuzde: yuzde
            )
        }
    }

    // MARK: - Soru turları ayrıntıları (js/soruTurlari.js, js/ikonografi.js)

    private static let kisaBolumAdlari: [Int: String] = [
        1: "Floransa’da Rönesans",
        2: "Antik klasikler",
        3: "Gotik, erken Rönesans",
    ]

    /// `bolumKisaAdi(b)` (`js/soruTurlari.js`)
    public static func bolumKisaAdi(no: Int, ad: String) -> String {
        if let kisa = kisaBolumAdlari[no] { return kisa }
        return ad.replacingOccurrences(of: "\\s+sanatı$", with: "", options: .regularExpression)
    }

    /// `kursBolumleri(konular, konularTr)` (`js/soruTurlari.js`)
    public static func kursBolumleri(konular: [Konu], konularTr: JSONDeger? = nil) -> [KursBolumuBilgisi] {
        var liste: [KursBolumuBilgisi] = []
        for k in konular {
            if let i = liste.firstIndex(where: { $0.id == k.bolum }) {
                liste[i].konular.append(k.no)
            } else {
                let rakamlar = k.bolum.filter(\.isNumber)
                let no = Int(rakamlar) ?? (liste.count + 1)
                let ceviri = konularTr?["bolumler"]?[k.bolum]?.metin
                let tamAd = (ceviri?.isEmpty == false ? ceviri : nil) ?? (k.bolumAd.isEmpty ? k.bolum : k.bolumAd)
                liste.append(KursBolumuBilgisi(
                    id: k.bolum,
                    no: no,
                    ad: tamAd,
                    kisaAd: bolumKisaAdi(no: no, ad: tamAd),
                    konular: [k.no]
                ))
            }
        }
        return liste.sorted { $0.no < $1.no }
    }

    /// `yuzyilAraligi(bolum, sanatcilar)` (`js/soruTurlari.js`)
    public static func yuzyilAraligi(konular: [Int], sanatcilar: [Sanatci]) -> String {
        let kume = Set(konular)
        let yillar = sanatcilar.filter { s in s.konu.map(kume.contains) == true }
            .compactMap { s -> Int? in
                if let d = s.dogum { return d + 30 }
                if let o = s.olum { return o - 10 }
                return nil
            }
            .sorted()
        guard !yillar.isEmpty else { return "" }
        func yuzyil(_ y: Int) -> Int {
            if y > 0 { return (y - 1) / 100 + 1 }
            return -((-y) / 100 + 1)
        }
        func yuzyilYaz(_ c: Int) -> String { c > 0 ? "\(c)." : "MÖ \(-c)." }
        let kes = yillar.count >= 5 ? Int(Double(yillar.count) * 0.1) : 0
        let a = yuzyil(yillar[kes])
        let b = yuzyil(yillar[yillar.count - 1 - kes])
        if a == b { return "\(yuzyilYaz(a)) yüzyıl" }
        return a > 0 || b < 0 ? "\(yuzyilYaz(a))–\(yuzyilYaz(b)) yüzyıl" : "\(yuzyilYaz(a)) yüzyıl – \(yuzyilYaz(b)) yüzyıl"
    }

    /// `TUR_AD` (`js/ikonografi.js`)
    public static let ikonografiTurAdlari: [String: String] = [
        "eski_ahit": "Eski Ahit",
        "yeni_ahit": "Yeni Ahit",
        "aziz": "Azizler",
        "mitoloji": "Mitoloji",
        "tarih_edebiyat": "Tarih ve edebiyat",
        "diger": "Diğer",
    ]

    /// `konulariAl(json, varMi)` (`js/ikonografi.js`)
    public static func ikonografiKonulari(_ veri: Data?, varMi: (String) -> Bool = { _ in true }) -> [IkonografiKonusu] {
        guard let veri, let json = try? JSONDeger.coz(veri), let dizi = json["konular"]?.dizi else { return [] }
        func dolu(_ m: String?) -> String? {
            guard let m else { return nil }
            return m.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : m
        }
        return dizi.compactMap { k in
            guard let id = dolu(k["id"]?.metin),
                  let ad = dolu(k["ad"]?.metin),
                  let hamHikaye = k["hikaye"]?.dizi else { return nil }
            let hikaye = hamHikaye.compactMap { dolu($0.metin) }
            guard !hikaye.isEmpty else { return nil }
            let hamTur = k["tur"]?.metin ?? ""
            let tur = ikonografiTurAdlari[hamTur] != nil ? hamTur : "diger"
            let turAdi = ikonografiTurAdlari[tur] ?? "Diğer"
            let ozet = dolu(k["ozet"]?.metin) ?? ""
            let kaynak = dolu(k["kaynak"]?.metin) ?? ""
            let tanima = (k["tanima"]?.dizi ?? []).compactMap { dolu($0.metin) }
            let eserler: [[String]] = (k["eserler"]?.dizi ?? []).compactMap { x in
                guard let cift = x.dizi, cift.count >= 2,
                      let ea = dolu(cift[0].metin),
                      let sid = dolu(cift[1].metin),
                      varMi(sid) else { return nil }
                return [ea, sid]
            }
            guard !eserler.isEmpty else { return nil }
            return IkonografiKonusu(id: id, ad: ad, tur: tur, turAdi: turAdi, ozet: ozet, kaynak: kaynak,
                                    hikaye: hikaye, tanima: tanima, eserler: eserler)
        }
    }

    // MARK: - 14 günlük yük grafiği özeti (js/ekranlar/calisma.js)

    /// `yukGrafigi` özeti (`js/ekranlar/calisma.js`):
    /// `"Bugün X · yarın Y · 14 günde Z sanatçı"` ya da `"Tekrarı gelen sanatçı yok"`
    public static func gelecekYukOzeti(skorlar: [String: SkorKaydi], idler: [String], bugun: String) -> (gunluk: [Int], toplam: Int, yazi: String) {
        let gunluk = Gecmis.gelecekYuk(skorlar, idler: idler, bugun: bugun, gun: 14)
        let toplam = gunluk.reduce(0, +)
        guard toplam > 0 else { return (gunluk, 0, "Tekrarı gelen sanatçı yok") }
        let b = gunluk.first ?? 0
        let y = gunluk.count > 1 ? gunluk[1] : 0
        return (gunluk, toplam, "Bugün \(b) · yarın \(y) · 14 günde \(toplam) sanatçı")
    }
}

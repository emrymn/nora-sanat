// Kaynak: sanat-atlasi js/app.js basla(), js/eserler.js sanatciEserleri, js/kurs.js @ a866b86 (site 1.90.3)
import Foundation

/// Sitenin açılışta kurduğu veri (`js/ekranlar/ortak.js` `d`): görünür sanatçılar ve akımlar, kurs konuları,
/// sanatçıların eser listeleri ve görsel adresleri. `SiteVerisi`'nin indirdiği dosyalardan kurulur.
///
/// Sitenin `sanatciEserleri`'nden tek farkı: eser önbellek dosyası 30 günden eskiyse site canlı Wikidata'daki yeni
/// eserleri listenin sonuna ekler; burada eklenmez (kâhin `canli: false` ile alınır).
public struct SiteKatalogu: Sendable {
    public enum Hata: Error, Equatable { case eksikDosya(String), bozukDosya(String) }

    /// Birleşmiş bütün sanatçılar (heykeltıraş ve mimarlar dahil) — `d.tumSanatcilar`
    public let tumSanatcilar: [Sanatci]
    /// Yalnız resim yapan sanatçılar — `d.sanatcilar`
    public let sanatcilar: [Sanatci]
    /// En az bir görünür sanatçısı olan akımlar, sıralı — `d.akimlar`
    public let akimlar: [Akim]
    /// `d.konular`
    public let konular: [Konu]
    /// Eseri olan kurs konuları, kapaklarıyla — `d.kursKonulari`
    public let kursKonulari: [Konu]
    /// id → görünür sanatçı — `d.harita`
    public let harita: [String: Sanatci]
    /// `d.kisaAdlar`
    public let kisaAdlar: [String: KisaAd]
    /// Akım → renk (birleşen akımlar hariç bütün akımlar) — `d.akimRenk`
    public let akimRenk: [String: String]
    /// Akım → sıra (görünür akımlar) — `d.akimSira`
    public let akimSira: [String: Double]
    /// Dikey görseller (yerel adlar) — `d.dikeyler`
    public let dikeyler: Set<String>?
    public let gorsel: GorselAdresleri
    public let kurallar: EserKurallari
    /// Eser önbelleğinin oluşturulma zamanı (yoksa nil)
    public let onbellekTarihi: Date?
    /// sanatçı → önbellekteki eserler (`onbellekEseri` uygulanmış, süzülmemiş)
    let onbellek: [String: [Eser]]?
    let suzgec: ResimSuzgeci

    /// - Parameter dosyalar: `data/` altındaki dosya adı → içerik ("sanatcilar.json" …). İlk üçü zorunlu.
    public init(dosyalar: [String: Data]) throws {
        func oku(_ ad: String) -> JSONDeger? { dosyalar[ad].flatMap { try? JSONDeger.coz($0) } }
        func zorunlu(_ ad: String) throws -> [JSONDeger] {
            guard let d = dosyalar[ad] else { throw Hata.eksikDosya(ad) }
            guard let l = (try? JSONDeger.coz(d))?.dizi else { throw Hata.bozukDosya(ad) }
            return l
        }
        let hamSanatcilar = try zorunlu("sanatcilar.json").map(Sanatci.init(json:))
        let hamAkimlar = try zorunlu("akimlar.json").map(Akim.init(json:))
        let konular = try zorunlu("konular.json").map(Konu.init(json:))
        let turler = oku("eser_turleri.json")

        // hazirOnbellek: surum ≥ 3
        var onbellekSirali: [(sid: String, eserler: [JSONDeger])] = []
        var onbellek: [String: [Eser]]? = nil
        var tarih: Date? = nil
        if let h = oku("eserler_onbellek.json"), let s = h["surum"]?.sayi, s >= 3 {
            var o: [String: [Eser]] = [:]
            for (sid, v) in h["sanatcilar"]?.nesne?.ciftler ?? [] {
                let l = v["eserler"]?.dizi ?? []
                onbellekSirali.append((sid, l))
                o[sid] = l.compactMap(Eser.init(onbellek:))
            }
            onbellek = h["sanatcilar"]?.nesne == nil ? nil : o
            tarih = h["olusturma"]?.metin.flatMap(Self.isoTarih)
        }
        self.onbellek = onbellek
        onbellekTarihi = tarih
        let hamSayilar = onbellek == nil ? nil
            : Dictionary(onbellekSirali.map { ($0.sid, $0.eserler.count) }, uniquingKeysWith: { _, b in b })

        let suzgec = ResimSuzgeci(turler)
        self.suzgec = suzgec
        let tum = Birlesme.sanatcilar(hamSanatcilar)
        tumSanatcilar = tum
        let sanatcilar = tum.filter { suzgec.resimSanatcisi($0, onbellek: hamSayilar) }
        self.sanatcilar = sanatcilar
        let akimlarB = Birlesme.akimlar(hamAkimlar)
        let gorunurAkimAdlari = Set(sanatcilar.map(\.akim))
        // JS sort kararlıdır
        akimlar = akimlarB.enumerated().sorted { $0.element.sira != $1.element.sira ? $0.element.sira < $1.element.sira : $0.offset < $1.offset }
            .map(\.element).filter { gorunurAkimAdlari.contains($0.ad) }
        self.konular = konular
        kursKonulari = KursKonulari.hesapla(konular, sanatcilar: sanatcilar, tum: tum, suzgec: suzgec)
        harita = Dictionary(sanatcilar.map { ($0.id, $0) }, uniquingKeysWith: { _, b in b })
        var kisa: [String: KisaAd] = [:]
        for (id, v) in oku("kisa_adlar.json")?["adlar"]?.nesne?.ciftler ?? [] {
            kisa[id] = KisaAd(buyuk: v["buyuk"]?.doluMetin, kucuk: v["kucuk"]?.doluMetin)
        }
        kisaAdlar = kisa
        akimRenk = Dictionary(akimlarB.map { ($0.ad, $0.renk) }, uniquingKeysWith: { _, b in b })
        akimSira = Dictionary(akimlar.map { ($0.ad, $0.sira) }, uniquingKeysWith: { _, b in b })
        let oranlar = oku("gorsel_oranlari.json")
        dikeyler = oranlar?["dikeyler"]?.dizi.map { Set($0.map(\.jsMetni)) }
        gorsel = GorselAdresleri(yerel: oku("yerel_gorseller.json"), oranlar: oranlar, kaynak: oku("gorsel_kaynagi.json"))
        kurallar = EserKurallari(kopya: oku("kopya_eserler.json"), cikarilan: oku("cikarilan_gorseller.json"),
                                 duzeltme: oku("eser_duzeltmeleri.json"), adlar: oku("eser_adlari_tr.json"),
                                 onbellek: onbellekSirali,
                                 sanatciAdlari: Dictionary(tum.map { ($0.id, $0.ad) }, uniquingKeysWith: { _, b in b }))
    }

    static func isoTarih(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }

    /// Sanatçının birleşik eser listesi (en bilinenler önce; kurs eserleri en başta) — `sanatciEserleri(s)`
    public func eserler(_ sanatciId: String) -> [Eser] {
        guard let s = harita[sanatciId] ?? tumSanatcilar.first(where: { $0.id == sanatciId }) else { return [] }
        let ham: [Eser]
        if let o = onbellek?[s.id] {
            ham = o
        } else {
            // Önbellekte kaydı yok: kurs resimleri (sitede canlı Wikidata eserleri de eklenir)
            ham = Self.kursEserleri(suzgec.kursResimleri(s))
        }
        return kurallar.isle(s, ham)
    }

    /// `eserleriBirlestir(kursEserleri, [])`: kurs eserleri, yinelenenler atılarak
    static func kursEserleri(_ l: [KursEseri]) -> [Eser] {
        var sonuc: [Eser] = []
        var dosyalar = Set<String>(), basliklar = Set<String>()
        for e in l {
            let d = SiteYazisi.dosyaNormal(e.commonsDosya).lowercased()
            let b = SiteYazisi.baslikNormal(e.baslik)
            if e.commonsDosya.isEmpty || dosyalar.contains(d) || (!b.isEmpty && basliklar.contains(b)) { continue }
            dosyalar.insert(d)
            if !b.isEmpty { basliklar.insert(b) }
            let g = Gorsel(k: "commons", d: SiteYazisi.dosyaNormal(e.commonsDosya), l: e.lisans)
            sonuc.append(Eser(anahtar: "c:" + d, kaynak: "kurs", kaynaklar: ["kurs"], baslik: e.baslik,
                              tarih: SiteYazisi.notTemizle(e.tarih), yil: nil, muze: SiteYazisi.notTemizle(e.yer),
                              kursKonu: e.konu, qid: nil, gorseller: [g], pekistirme: true, sl: 0))
        }
        return sonuc
    }

    /// Görünür sanatçının bilinen adı (`bilinenAd(s.ad, d.kisaAdlar[s.id])`)
    public func bilinenAd(_ sanatciId: String) -> String? {
        harita[sanatciId].map { Adlar.bilinen($0.ad, kisa: kisaAdlar[$0.id]) }
    }

    /// `adParcala(s.ad, d.kisaAdlar[s.id])`
    public func adParcalari(_ s: Sanatci) -> AdParcalari { Adlar.parcala(s.ad, kisa: kisaAdlar[s.id]) }

    /// Eserin ekrandaki görseli (kullanıcının "kötü" işaretleri dışındaki ilk görsel) ve adresi
    public func gorselAdresi(_ e: Eser, genislik: Int, kotuler: [String: [String]] = [:]) -> URL? {
        GorselAdresleri.secilen(e, kotuler: kotuler).flatMap { GorselAdresleri.url(gorsel.url($0, genislik: genislik)) }
    }
}

// MARK: - Kurs konuları (js/kurs.js)

enum KursKonulari {
    /// `kelimeler`: küçük harf, [a-zà-ÿ] dışı ayırıcı
    static func kelimeler(_ x: String?) -> [String] {
        var l: [String] = []
        var k = String.UnicodeScalarView()
        for u in (x ?? "").lowercased().unicodeScalars {
            if ("a"..."z").contains(u) || (0xE0...0xFF).contains(u.value) { k.append(u) } else if !k.isEmpty {
                l.append(String(k)); k = String.UnicodeScalarView()
            }
        }
        if !k.isEmpty { l.append(String(k)) }
        return l
    }

    struct Ders { let s: Sanatci; let e: KursEseri }

    static func soyadi(_ s: Sanatci) -> String { kelimeler(dolu(s.adArama) ?? s.ad).last ?? "" }
    static func baslikta(_ s: Sanatci, _ baslik: String) -> Bool { kelimeler(baslik).contains(soyadi(s)) }
    static func baslikIlk(_ s: Sanatci, _ baslik: String) -> Bool { kelimeler(baslik).first == soyadi(s) }

    static func dersEserleri(_ no: Int, _ sanatcilar: [Sanatci], _ sec: (Sanatci) -> [KursEseri]) -> [Ders] {
        sanatcilar.flatMap { s in sec(s).filter { $0.konu == no && !$0.commonsDosya.isEmpty }.map { Ders(s: s, e: $0) } }
    }

    static func enUygun(_ l: [Ders], _ baslik: String) -> Ders? {
        let b = Set(kelimeler(baslik).filter { $0.utf16.count >= 4 })
        func puan(_ x: Ders) -> Int { kelimeler(x.e.baslik).filter { b.contains($0) }.count }
        let adli = l.filter { baslikta($0.s, baslik) }
        guard var en = adli.first else { return nil }
        for x in adli.dropFirst() where puan(x) > puan(en) { en = x }
        return en
    }

    static func eserKapagi(_ x: Ders, resimDegil: Bool? = nil) -> KonuKapagi {
        KonuKapagi(sanatci: x.s.id, dosya: SiteYazisi.dosyaNormal(x.e.commonsDosya), baslik: x.e.baslik, resimDegil: resimDegil)
    }

    /// `konuKapagi(konu, sanatcilar, turler, tumSanatcilar)`
    static func kapak(_ konu: Konu, sanatcilar: [Sanatci], tum: [Sanatci], suzgec: ResimSuzgeci) -> KonuKapagi? {
        let no = konu.no
        let l = sanatcilar.filter { $0.konu == no }
        if let ilk = l.first { return KonuKapagi(sanatci: (l.first { $0.kaynak == "kurs" } ?? ilk).id) }
        let resimler = dersEserleri(no, sanatcilar, suzgec.kursResimleri)
        if let adli = enUygun(resimler, konu.baslik) { return eserKapagi(adli) }
        if let adi = sanatcilar.first(where: { baslikIlk($0, konu.baslik) }) { return KonuKapagi(sanatci: adi.id) }
        let hepsi = dersEserleri(no, tum, \.kursEserleri)
        func resimMi(_ x: Ders) -> Bool { resimler.contains { $0.s.id == x.s.id && $0.e.sira == x.e.sira } }
        if let foto = enUygun(hepsi, konu.baslik) { return eserKapagi(foto, resimDegil: resimMi(foto) ? nil : true) }
        if let r = resimler.first { return eserKapagi(r) }
        return hepsi.first.map { eserKapagi($0, resimDegil: true) }
    }

    /// `kursKonulari`: kapağı olan konular
    static func hesapla(_ konular: [Konu], sanatcilar: [Sanatci], tum: [Sanatci], suzgec: ResimSuzgeci) -> [Konu] {
        konular.compactMap { k in
            guard let kapak = kapak(k, sanatcilar: sanatcilar, tum: tum, suzgec: suzgec) else { return nil }
            var y = k
            y.kapak = kapak
            return y
        }
    }
}

// Kaynak: sanat-atlasi js/depo.js (şema: varsayilanIlerleme, ilerlemeDogrula), js/gecmis.js, js/ogrenme.js @ a866b86
import Foundation

/// Bir sanatçının skorları: `skorlar[id] = { sanatci?, akim?, bolumKart? }`
public struct SkorKaydi: Equatable, Sendable {
    public var sanatci: Skor?
    public var akim: Skor?
    /// Bölüm turu (İş 105)
    public var bolumKart: Skor?
    var ham: SiraliNesne = .bos

    public init(sanatci: Skor? = nil, akim: Skor? = nil, bolumKart: Skor? = nil) {
        self.sanatci = sanatci; self.akim = akim; self.bolumKart = bolumKart
    }

    init(json j: JSONDeger) {
        sanatci = Skor(json: j["sanatci"])
        akim = Skor(json: j["akim"])
        bolumKart = Skor(json: j["bolumKart"])
        ham = j.nesne ?? .bos
    }

    public var json: JSONDeger {
        .nesne(ham.ayarlandi("sanatci", sanatci?.json).ayarlandi("akim", akim?.json).ayarlandi("bolumKart", bolumKart?.json))
    }

    public static func == (a: SkorKaydi, b: SkorKaydi) -> Bool {
        a.sanatci == b.sanatci && a.akim == b.akim && a.bolumKart == b.bolumKart
    }
}

/// Bugünün sayaçları: `gunluk = { tarih, yeni, kart, yeniIdler }`
public struct Gunluk: Equatable, Sendable {
    public var tarih: String
    public var yeni: Int
    public var kart: Int
    public var yeniIdler: [String]
    var ham: SiraliNesne = .bos

    public init(tarih: String, yeni: Int = 0, kart: Int = 0, yeniIdler: [String] = []) {
        self.tarih = tarih; self.yeni = yeni; self.kart = kart; self.yeniIdler = yeniIdler
    }

    init(json j: JSONDeger?) {
        tarih = j?["tarih"]?.metin ?? ""
        yeni = j?["yeni"]?.tamSayi ?? 0
        kart = j?["kart"]?.tamSayi ?? 0
        yeniIdler = (j?["yeniIdler"]?.dizi ?? []).compactMap(\.metin)
        ham = j?.nesne ?? .bos
    }

    public var json: JSONDeger {
        .nesne(ham.ayarlandi("tarih", .metin(tarih)).ayarlandi("yeni", .sayi(yeni)).ayarlandi("kart", .sayi(kart))
            .ayarlandi("yeniIdler", .dizi(yeniIdler.map { .metin($0) })))
    }

    public static func == (a: Gunluk, b: Gunluk) -> Bool {
        a.tarih == b.tarih && a.yeni == b.yeni && a.kart == b.kart && a.yeniIdler == b.yeniIdler
    }
}

/// Sitenin ilerleme kaydı (`localStorage['sanat-atlasi:ilerleme']`, şema js/depo.js).
///
/// Ham JSON tutulur, tipli alanlar onun üstünden okunup yazılır: Swift'in bilmediği alanlar (bölümler, dersler,
/// koleksiyon, geliştirici yedeği…) ve anahtar sırası olduğu gibi kalır (K2). Site kaydı açılışta zaten doğruladığı
/// (`ilerlemeDogrula`) için okuma hoşgörülüdür; tam doğrulama Z2'de (kayıt Swift'e geçince) gerekir.
public struct Ilerleme: Equatable, Sendable {
    public static let anahtar = "sanat-atlasi:ilerleme"
    /// `SON_CALISILAN`
    public static let sonCalisilanSiniri = 12

    public private(set) var ham: SiraliNesne

    public enum Hata: Error, Equatable { case nesneDegil }

    public init(json: JSONDeger) throws {
        // Yedek biçimi ({ uygulama, ilerleme }) de kabul edilir
        if let i = json["ilerleme"], i.nesne != nil { self = try Ilerleme(json: i); return }
        guard let n = json.nesne else { throw Hata.nesneDegil }
        ham = n
    }

    public init(veri: Data) throws { try self.init(json: JSONDeger.coz(veri)) }

    /// Siteye yazılacak JSON
    public var json: JSONDeger { .nesne(ham) }
    public var jsonMetni: String { json.jsonMetni }

    public subscript(alan alan: String) -> JSONDeger? {
        get { ham[alan] }
        set { ham = ham.ayarlandi(alan, newValue) }
    }

    // MARK: Tipli alanlar

    /// İşlenen kurs konuları (sıralı)
    public var islenen: [Int] {
        get { (ham["islenen"]?.dizi ?? []).compactMap(\.tamSayi) }
        set { self[alan: "islenen"] = .dizi(Array(Set(newValue)).sorted().map { .sayi($0) }) }
    }

    public var islenenKume: Set<Int> { Set(islenen) }

    public var skorlar: [String: SkorKaydi] {
        get { sozluk("skorlar", SkorKaydi.init(json:)) }
        set { sozlukYaz("skorlar", newValue) { $0.json } }
    }

    /// Konu (ikonografi) turu skorları
    public var skorlarKonu: [String: Skor] {
        get { sozluk("skorlarKonu") { Skor(json: $0) } }
        set { sozlukYaz("skorlarKonu", newValue) { $0.json } }
    }

    public var gecmis: [String: GunKaydi] {
        get { sozluk("gecmis") { GunKaydi(json: $0) } }
        set { sozlukYaz("gecmis", newValue) { $0.json } }
    }

    public var seviyeler: [String: SeviyeKaydi] {
        get { Seviye.dogrula(ham["seviyeler"]) }
        set { sozlukYaz("seviyeler", newValue) { $0.json } }
    }

    public var karisanlar: [String: Karisan] {
        get { Ogrenme.dogrula(ham["karisanlar"]) }
        set { sozlukYaz("karisanlar", newValue) { $0.json } }
    }

    /// Kayıttaki sırasıyla (en çok karıştırılanlarda eşitlik sırası için)
    public var karisanlarSirali: [(anahtar: String, deger: Karisan)] { Ogrenme.dogrulaSirali(ham["karisanlar"]) }

    /// Konusu işlenmemiş ama pekiştirmeye eklenmiş sanatçılar
    public var ekSanatcilar: [String] {
        get { (ham["ekSanatcilar"]?.dizi ?? []).compactMap(\.metin) }
        set { self[alan: "ekSanatcilar"] = .dizi(newValue.map { .metin($0) }) }
    }

    /// En son pekiştirilen sanatçılar (en yeni başta)
    public var sonCalisilanlar: [String] {
        get { (ham["sonCalisilanlar"]?.dizi ?? []).compactMap(\.metin) }
        set { self[alan: "sonCalisilanlar"] = .dizi(newValue.map { .metin($0) }) }
    }

    /// Kullanıcının reddettiği görseller: eser anahtarı → görsel anahtarları (`GorselAdresleri.secilen`'e verilir)
    public var kotuGorseller: [String: [String]] {
        get { sozluk("kotuGorseller") { $0.dizi.map { $0.compactMap(\.metin) } } }
        set { sozlukYaz("kotuGorseller", newValue) { .dizi($0.map { .metin($0) }) } }
    }

    public var gunluk: Gunluk {
        get { Gunluk(json: ham["gunluk"]) }
        set { self[alan: "gunluk"] = newValue.json }
    }

    /// Her kayıtta artan numara (İş 143); köprü yazarken çakışmayı bununla anlar
    public var kayitNo: Int { ham["kayitNo"]?.tamSayi ?? 0 }

    /// Ayar (`ayarlar.<ad>`)
    public func ayar(_ ad: String) -> JSONDeger? { ham["ayarlar"]?[ad] }
    public mutating func ayarla(_ ad: String, _ deger: JSONDeger?) {
        self[alan: "ayarlar"] = .nesne((ham["ayarlar"]?.nesne ?? .bos).ayarlandi(ad, deger))
    }

    // MARK: Site işlemleri

    /// `gunlukGuncelle`: tarih değişince günlük sayaçları sıfırla
    @discardableResult
    public mutating func gunlukGuncelle(bugun: String) -> Gunluk {
        if ham["gunluk"]?.nesne == nil || gunluk.tarih != bugun { gunluk = Gunluk(tarih: bugun) }
        return gunluk
    }

    /// `sonCalisilanEkle`
    public mutating func sonCalisilanEkle(_ id: String) {
        sonCalisilanlar = Array(([id] + sonCalisilanlar.filter { $0 != id }).prefix(Self.sonCalisilanSiniri))
    }

    /// `gecmisEkle`
    public mutating func gecmisEkle(tarih: String, dogru: Bool, akim: String?) {
        var g = gecmis
        Gecmis.ekle(&g, tarih: tarih, dogru: dogru, akim: akim)
        gecmis = g
    }

    /// `acikSanatcilar(d.sanatcilar, islenen, ekSanatcilar)` — sitenin `acikListe()`'si
    public func acikSanatcilar(_ sanatcilar: [Sanatci]) -> [Sanatci] {
        Kilit.acikSanatcilar(sanatcilar, islenen: islenenKume, ek: ekSanatcilar)
    }

    /// Bugün'deki "tekrar bekliyor" sayısı (açık sanatçılar)
    public func vadeSayisi(_ sanatcilar: [Sanatci], tarih: String) -> Int {
        Gecmis.vadeSayisi(skorlar, idler: acikSanatcilar(sanatcilar).map(\.id), tarih: tarih)
    }

    // MARK: Yardımcılar

    func sozluk<T>(_ alan: String, _ cevir: (JSONDeger) -> T?) -> [String: T] {
        var s: [String: T] = [:]
        for (a, v) in ham[alan]?.nesne?.ciftler ?? [] { if let x = cevir(v) { s[a] = x } }
        return s
    }

    mutating func sozlukYaz<T>(_ alan: String, _ yeni: [String: T], _ cevir: (T) -> JSONDeger) {
        // Değişmeyen öğelerin ham JSON'u aynen kalsın: yalnız farklı olanlar yeniden yazılır
        let eski = ham[alan]?.nesne ?? .bos
        self[alan: alan] = .nesne(eski.yerine(yeni.mapValues(cevir)))
    }
}

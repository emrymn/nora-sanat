// Kaynak: sanat-atlasi js/depo.js (varsayilanIlerleme, ilerlemeDogrula, gelistirici*, sonCalisilanEkle, yedekMetni,
// yedekYarimOturum, yedekCoz, gunlukGuncelle, enYeniKayit, yedekHatirlatmasi) ve doğrulamanın çağırdıkları:
// js/ogrenme.js karisanlarDogrula, js/seviye.js seviyelerDogrula, js/birlesme.js seviyeleriBirlestir, js/ders.js
// derslerDogrula, js/gecmis.js gecmisDogrula, js/koleksiyon.js koleksiyonDogrula, js/harita.js gorulenDogrula,
// js/bolum.js bolumlerDogrula, js/bildirim.js bildirimlerDogrula, js/gunduzRenk.js @ a866b86 (site 1.90.3).
//
// Z2: ilerleme artık Swift'te saklanır; site yalnız bir kez (taşıma) okunur. Kurallar JSONDeger üzerinde, sitenin
// çıktısıyla aynı yapıyı (anahtar sırası dahil, JS'in tam sayı anahtarı kuralı hariç) üretir. Sınama:
// Testler/kahin/depo.mjs → Ornekler/depo/cevaplar.json (IlerlemeKurallariTests).
import Foundation

public enum IlerlemeKurallari {
    public static let surum = 2
    public static let temalar = ["gece", "gunduz"]
    public static let varsayilanTema = "gece"
    public static let hareketler = ["tam", "sade", "kapali"]
    public static let yazilar = ["standart", "buyuk"]
    public static let gunduzRenkleri = ["otomatik", "lapis", "pompei", "bakir", "safran", "notr"]
    public static let varsayilanGunduzRengi = "otomatik"
    /// `SON_CALISILAN`
    public static let sonCalisilanSiniri = 12
    /// `YEDEK_ARALIGI` (gün)
    public static let yedekAraligi = 14

    public enum Hata: Error, Equatable, CustomStringConvertible {
        /// Sitenin `Error` metni (Ayarlar'da gösterilir)
        case gecersiz(String)
        public var description: String { if case .gecersiz(let m) = self { return m }; return "" }
    }

    // MARK: - Varsayılan

    /// `varsayilanIlerleme(islenen)`. `bugun`: "YYYY-MM-DD" (yerel gün), `simdi`: `new Date().toISOString()`
    public static func varsayilan(islenen: [JSONDeger] = [], bugun: String, simdi: String) -> SiraliNesne {
        SiraliNesne([
            ("surum", .sayi(Double(surum))),
            ("islenen", .dizi(islenen)),
            ("ayarlar", .nesne(varsayilanAyarlar)),
            ("skorlar", bosNesne),
            ("skorlarKonu", bosNesne),
            ("gunluk", bosGunluk(bugun)),
            ("sonEserler", bosNesne),
            ("kotuGorseller", bosNesne),
            ("ekSanatcilar", .dizi([])),
            ("sonCalisilanlar", .dizi([])),
            ("karisanlar", bosNesne),
            ("seviyeler", bosNesne),
            ("sonYedek", .bos),
            ("gecmis", bosNesne),
            ("koleksiyon", .dizi([])),
            ("haritaGorulen", .dizi([])),
            ("haritaYolcu", .bos),
            ("haritaYolcuOn", .mantik(false)),
            ("bolumler", bosNesne),
            ("bildirimler", .dizi([])),
            ("sonSurum", .bos),
            ("gelistirici", .bos),
            ("olusturma", .metin(simdi)),
        ])
    }

    static let varsayilanAyarlar = SiraliNesne([
        ("gunlukKart", .sayi(20)), ("tema", .metin(varsayilanTema)), ("tanisma", .mantik(true)), ("rozet", .mantik(false)),
        ("egim", .mantik(true)), ("titresim", .mantik(true)), ("hareket", .metin("tam")), ("yazi", .metin("standart")),
        ("gunduzRenk", .metin(varsayilanGunduzRengi)),
    ])
    static let bosNesne = JSONDeger.nesne(SiraliNesne([]))
    static func bosGunluk(_ bugun: String) -> JSONDeger {
        .nesne(SiraliNesne([("tarih", .metin(bugun)), ("yeni", .sayi(0)), ("kart", .sayi(0)), ("yeniIdler", .dizi([]))]))
    }

    // MARK: - Doğrulama

    /// `ilerlemeDogrula(nesne)`: yedekten gelen ya da depodan okunan nesneyi doğrular, eksikleri tamamlar.
    /// Geçersizse sitenin hata metniyle `Hata.gecersiz` atar.
    public static func dogrula(_ nesne: JSONDeger, bugun: String, simdi: String) throws -> SiraliNesne {
        guard nesne.dogruMu, nesne.nesneMi else { throw Hata.gecersiz("Yedek bir JSON nesnesi değil.") }
        let v: JSONDeger = (nesne["ilerleme"].map { $0.dogruMu && $0.nesneMi } ?? false) ? nesne["ilerleme"]! : nesne
        guard let islenen = v["islenen"]?.dizi, islenen.allSatisfy(\.tamSayiMi) else {
            throw Hata.gecersiz("“islenen” konu listesi bulunamadı.")
        }
        if let s = v["skorlar"], s != .bos, s.nesneMi == false || s.diziMi { throw Hata.gecersiz("“skorlar” geçersiz.") }
        var skorlar: [(String, JSONDeger)] = []
        for (id, s) in v["skorlar"].map(Self.girdiler) ?? [] {
            guard s.dogruMu, s.nesneMi, skorGecerli(s["sanatci"]), skorGecerli(s["akim"]) else {
                throw Hata.gecersiz("“\(id)” için skor geçersiz.")
            }
            var t: [(String, JSONDeger)] = []
            if let x = s["sanatci"], x.dogruMu { t.append(("sanatci", skorTemizle(x, bugun))) }
            if let x = s["akim"], x.dogruMu { t.append(("akim", skorTemizle(x, bugun))) }
            if let x = s["bolumKart"], x.dogruMu, skorGecerli(x) { t.append(("bolumKart", skorTemizle(x, bugun))) }
            skorlar.append((id, .nesne(SiraliNesne(t))))
        }
        var skorlarKonu: [(String, JSONDeger)] = []
        if let k = v["skorlarKonu"], k.dogruMu, k.nesneMi, !k.diziMi {
            for (id, s) in girdiler(k) where s.dogruMu && skorGecerli(s) && id.utf16.count < 120 {
                skorlarKonu.append((id, skorTemizle(s, bugun)))
            }
        }
        let t = varsayilan(bugun: bugun, simdi: simdi)
        let ayarlar = ayarlariDogrula(v)
        let gunluk: JSONDeger
        if let g = v["gunluk"], g.dogruMu, g.nesneMi {
            let yeniIdler = g["yeniIdler"]?.diziMi == true ? g["yeniIdler"]! : .dizi([])
            gunluk = .nesne(birlestir(t["gunluk"]!.nesne!, girdiler(g)).ayarlandi("yeniIdler", yeniIdler))
        } else {
            gunluk = t["gunluk"]!
        }
        let sonEserler = (v["sonEserler"].map { $0.dogruMu && $0.nesneMi } ?? false) ? v["sonEserler"]! : bosNesne

        var degerler: [(String, JSONDeger)] = [
            ("islenen", .dizi(tekil(islenen.map { $0.sayi! }).sorted().map { .sayi($0) })),
            ("ayarlar", .nesne(ayarlar)),
            ("skorlar", .nesne(SiraliNesne(skorlar))),
            ("skorlarKonu", .nesne(SiraliNesne(skorlarKonu))),
            ("gunluk", gunluk),
            ("sonEserler", sonEserler),
            ("kotuGorseller", kotuGorselleriDogrula(v["kotuGorseller"])),
            ("ekSanatcilar", .dizi(tekilMetinler(v["ekSanatcilar"]))),
            ("sonCalisilanlar", .dizi(Array(tekilMetinler(v["sonCalisilanlar"]).prefix(sonCalisilanSiniri)))),
            ("karisanlar", karisanlarDogrula(v["karisanlar"])),
            ("seviyeler", seviyeleriBirlestir(seviyelerDogrula(v["seviyeler"]))),
            ("sonYedek", v["sonYedek"]?.metin.flatMap { tarihMi($0) ? JSONDeger.metin($0) : nil } ?? .bos),
            ("gecmis", gecmisDogrula(v["gecmis"])),
            ("koleksiyon", koleksiyonDogrula(v["koleksiyon"])),
            ("haritaGorulen", .dizi(Array(tekilMetinler(v["haritaGorulen"], diziDegilse: []).prefix(300)))),
            ("haritaYolcu", v["haritaYolcu"]?.metin.flatMap { $0.utf16.count < 40 ? JSONDeger.metin($0) : nil } ?? .bos),
            ("haritaYolcuOn", .mantik(v["haritaYolcuOn"] == .mantik(true))),
            ("bolumler", bolumlerDogrula(v["bolumler"])),
            ("dersler", derslerDogrula(v["dersler"])),
            ("bildirimler", bildirimlerDogrula(v["bildirimler"])),
            ("sonSurum", v["sonSurum"]?.metin.flatMap { surumMu($0) ? JSONDeger.metin($0) : nil } ?? .bos),
            ("gelistirici", gelistiriciDogrula(v["gelistirici"], bugun: bugun, simdi: simdi)),
        ]
        let gd = v["gununDegisim"]
        if let gd, gd.dogruMu, let id = gd["id"]?.metin, tarihMi(gd["tarih"].map { $0.dogruMu ? $0.jsMetni : "" } ?? "") {
            degerler.append(("gununDegisim", .nesne(SiraliNesne([("tarih", gd["tarih"]!), ("id", .metin(id))]))))
        } else {
            degerler.append(("gununDegisim", .bos))
        }
        degerler.append(("olusturma", (v["olusturma"].map(\.dogruMu) ?? false) ? v["olusturma"]! : t["olusturma"]!))
        let kayitNo = v["kayitNo"].flatMap { $0.tamSayiMi && $0.sayi! >= 0 ? $0 : nil } ?? .sayi(0)
        degerler.append(("kayitNo", kayitNo))
        return birlestir(t, degerler)
    }

    /// `Ilerleme` için
    public static func dogrulaIlerleme(_ nesne: JSONDeger, bugun: String, simdi: String) throws -> Ilerleme {
        try Ilerleme(json: .nesne(dogrula(nesne, bugun: bugun, simdi: simdi)))
    }

    static func ayarlariDogrula(_ v: JSONDeger) -> SiraliNesne {
        var a = birlestir(varsayilanAyarlar, v["ayarlar"].map(yayilim) ?? [])
        // Sürüm 1'de varsayılan Sepya'ydı ve Koyu tema vardı: ikisi de bir kez Gece'ye geçer
        let tema = a["tema"]
        if !(jsSayi(v["surum"]) >= 2), tema == .metin("sepya") || tema == .metin("koyu") { a = a.ayarlandi("tema", .metin(varsayilanTema)) }
        // İş 140: kaldırılan Sepya ve Açık Gündüz'e geçer
        if a["tema"] == .metin("sepya") || a["tema"] == .metin("acik") { a = a.ayarlandi("tema", .metin("gunduz")) }
        if !(a["tema"]?.metin.map(temalar.contains) ?? false) { a = a.ayarlandi("tema", .metin(varsayilanTema)) }
        let kart = jsParseInt(a["gunlukKart"]).flatMap { $0 == 0 ? nil : $0 } ?? 20
        a = a.ayarlandi("gunlukKart", .sayi(min(100, max(5, kart))))
        a = a.ayarlandi("tanisma", .mantik(a["tanisma"] != .mantik(false)))
        a = a.ayarlandi("rozet", .mantik(a["rozet"] == .mantik(true)))
        a = a.ayarlandi("egim", .mantik(a["egim"] != .mantik(false)))
        a = a.ayarlandi("titresim", .mantik(a["titresim"] != .mantik(false)))
        if !(a["hareket"]?.metin.map(hareketler.contains) ?? false) { a = a.ayarlandi("hareket", .metin("tam")) }
        if !(a["yazi"]?.metin.map(yazilar.contains) ?? false) { a = a.ayarlandi("yazi", .metin("standart")) }
        if !(a["gunduzRenk"]?.metin.map(gunduzRenkleri.contains) ?? false) { a = a.ayarlandi("gunduzRenk", .metin(varsayilanGunduzRengi)) }
        return a
    }

    /// `skorGecerli`: yok (undefined) ya da kutu 0…5 tam sayı, dogru ve yanlis sonlu sayı
    static func skorGecerli(_ s: JSONDeger?) -> Bool {
        guard let s else { return true }
        guard s.dogruMu, s.nesneMi, let kutu = s["kutu"], kutu.tamSayiMi, let k = kutu.sayi, k >= 0, k <= 5 else { return false }
        return s["dogru"]?.sayi?.isFinite == true && s["yanlis"]?.sayi?.isFinite == true
    }

    /// `skorTemizle` (İş 135)
    static func skorTemizle(_ s: JSONDeger, _ bugun: String) -> JSONDeger {
        var t = SiraliNesne(yayilim(s))
        t = t.ayarlandi("dogru", .sayi(max(0, (s["dogru"]?.sayi ?? 0).rounded(.down))))
        t = t.ayarlandi("yanlis", .sayi(max(0, (s["yanlis"]?.sayi ?? 0).rounded(.down))))
        let son: JSONDeger = s["son"]?.metin.flatMap { tarihMi($0) ? JSONDeger.metin($0) : nil }
            ?? ((s["son"]?.dogruMu ?? false) ? .metin(bugun) : .bos)
        t = t.ayarlandi("son", son)
        let sonraki: JSONDeger = s["sonraki"]?.metin.flatMap { tarihMi($0) ? JSONDeger.metin($0) : nil }
            ?? (son.dogruMu ? .metin(bugun) : .bos)
        return .nesne(t.ayarlandi("sonraki", sonraki))
    }

    static func kotuGorselleriDogrula(_ k: JSONDeger?) -> JSONDeger {
        guard let k, k.dogruMu, k.nesneMi, !k.diziMi else { return bosNesne }
        var s: [(String, JSONDeger)] = []
        for (a, liste) in girdiler(k) {
            if let l = liste.dizi { s.append((a, .dizi(l.filter { $0.metin != nil }))) }
        }
        return .nesne(SiraliNesne(s))
    }

    /// `karisanlarDogrula` (js/ogrenme.js)
    static func karisanlarDogrula(_ k: JSONDeger?) -> JSONDeger {
        guard let k, k.dogruMu, k.nesneMi, !k.diziMi else { return bosNesne }
        var s = SiraliNesne([])
        for (anahtar, v) in girdiler(k) {
            let p = anahtar.components(separatedBy: "|")
            guard p.count == 2, !p[0].isEmpty, !p[1].isEmpty, p[0] != p[1] else { continue }
            guard v.dogruMu, let n = v["n"], n.tamSayiMi, n.sayi! >= 1 else { continue }
            let son = v["son"]?.metin ?? ""
            s = s.ayarlandi(jsSirali([p[0], p[1]]).joined(separator: "|"), .nesne(SiraliNesne([("n", n), ("son", .metin(son))])))
        }
        return .nesne(s)
    }

    /// `seviyelerDogrula` (js/seviye.js; PENCERE 10, BILMIYORUM 2)
    static func seviyelerDogrula(_ v: JSONDeger?) -> SiraliNesne {
        guard let v, v.dogruMu, v.nesneMi, !v.diziMi else { return SiraliNesne([]) }
        var s: [(String, JSONDeger)] = []
        for (id, k) in girdiler(v) {
            guard k.dogruMu, let sv = k["s"], [0, 1, 2].contains(sv.sayi ?? -1), let son = k["son"]?.dizi else { continue }
            let l = son.filter { $0 == .sayi(0) || $0 == .sayi(1) || $0 == .sayi(2) }.suffix(10)
            s.append((id, .nesne(SiraliNesne([("s", sv), ("son", .dizi(Array(l)))]))))
        }
        return SiraliNesne(s)
    }

    /// `seviyeleriBirlestir` (js/birlesme.js)
    static func seviyeleriBirlestir(_ sv: SiraliNesne) -> JSONDeger {
        var sv = sv
        for (kaynak, hedef) in Birlesme.akimlar {
            guard let k = sv[kaynak] else { continue }
            let h = sv[hedef]
            if h == nil || (k["s"]?.sayi ?? 0) > (h?["s"]?.sayi ?? 0) {
                sv = sv.ayarlandi(hedef, k)
            } else if k["s"]?.sayi == h?["s"]?.sayi {
                let son = Array(((k["son"]?.dizi ?? []) + (h?["son"]?.dizi ?? [])).suffix(10))
                sv = sv.ayarlandi(hedef, .nesne(SiraliNesne([("s", h!["s"]!), ("son", .dizi(son))])))
            }
            sv = sv.ayarlandi(kaynak, nil)
        }
        return .nesne(sv)
    }

    /// `gecmisDogrula` (js/gecmis.js)
    static func gecmisDogrula(_ g: JSONDeger?) -> JSONDeger {
        guard let g, g.dogruMu, g.nesneMi, !g.diziMi else { return bosNesne }
        func sayi(_ x: JSONDeger?) -> Double? { x.flatMap { $0.tamSayiMi && $0.sayi! >= 0 ? $0.sayi : nil } }
        var s: [(String, JSONDeger)] = []
        for (tarih, k) in girdiler(g) {
            guard tarihMi(tarih), k.dogruMu, k.nesneMi, let kart = sayi(k["kart"]), let dogru = sayi(k["dogru"]) else { continue }
            var akimlar = SiraliNesne([])
            let a = k["akimlar"].flatMap { $0.dogruMu && $0.nesneMi ? $0 : nil }
            for (ad, n) in a.map(girdiler) ?? [] {
                guard let n = sayi(n), n > 0 else { continue }
                let hedef = Birlesme.akimAdi(ad)
                akimlar = akimlar.ayarlandi(hedef, .sayi((akimlar[hedef]?.sayi ?? 0) + n))
            }
            s.append((tarih, .nesne(SiraliNesne([("kart", .sayi(kart)), ("dogru", .sayi(min(dogru, kart))), ("akimlar", .nesne(akimlar))]))))
        }
        return .nesne(SiraliNesne(s))
    }

    /// `koleksiyonDogrula` (js/koleksiyon.js, sınır 500)
    static func koleksiyonDogrula(_ k: JSONDeger?) -> JSONDeger {
        guard let l = k?.dizi else { return .dizi([]) }
        var goruldu = Set<String>()
        var s: [JSONDeger] = []
        for x in l {
            guard x.dogruMu, let a = x["a"]?.metin, let sa = x["s"]?.metin, !goruldu.contains(a) else { continue }
            goruldu.insert(a)
            s.append(.nesne(SiraliNesne([("a", .metin(a)), ("s", .metin(sa)), ("t", .metin(x["t"]?.metin ?? ""))])))
        }
        return .dizi(Array(s.prefix(500)))
    }

    /// `bolumlerDogrula` (js/bolum.js)
    static func bolumlerDogrula(_ v: JSONDeger?) -> JSONDeger {
        guard let v, v.dogruMu, v.nesneMi, !v.diziMi else { return bosNesne }
        var s: [(String, JSONDeger)] = []
        for (id, k) in girdiler(v) {
            guard bolumKimligiMi(id), k.dogruMu, k.nesneMi else { continue }
            var t: [(String, JSONDeger)] = []
            for sv in ["kolay", "orta", "zor"] { if let x = k[sv]?.sayi, x >= 0, x <= 1 { t.append((sv, .sayi(x))) } }
            if k["tanitim"] == .mantik(true) { t.append(("tanitim", .mantik(true))) }
            if k["tanitimOrta"] == .mantik(true) { t.append(("tanitimOrta", .mantik(true))) }
            for alan in ["tanitimGrup", "tanitimOrtaGrup"] {
                let l = (k[alan]?.dizi ?? []).filter { $0.tamSayiMi && $0.sayi! >= 0 && $0.sayi! < 10 }.map { $0.sayi! }
                let t2 = tekil(l).sorted()
                if !t2.isEmpty { t.append((alan, .dizi(t2.map { .sayi($0) }))) }
            }
            s.append((id, .nesne(SiraliNesne(t))))
        }
        return .nesne(SiraliNesne(s))
    }

    /// `derslerDogrula` (js/ders.js): birleşen akımın kaydı hedefe katılır (yüksek ilerleme, erken gün)
    static func derslerDogrula(_ v: JSONDeger?) -> JSONDeger {
        guard let v, v.dogruMu, v.nesneMi, !v.diziMi else { return bosNesne }
        var sonuc = SiraliNesne([])
        for (ham, k) in girdiler(v) {
            guard k.dogruMu, k.nesneMi, !k.diziMi, ham.utf16.count <= 80 else { continue }
            let ad = Birlesme.akimAdi(ham)
            let eski = sonuc[ad]
            var t: [(String, JSONDeger)] = []
            for a in ["gor", "ogren", "ayirt"] {
                let x = k[a]
                let i: Double = x.flatMap { $0.dogruMu ? $0["i"]?.sayi : nil }.flatMap { $0.isFinite ? sinirla($0) : nil } ?? 0
                let gun: String? = x.flatMap { $0.dogruMu ? $0["t"]?.metin : nil }.flatMap { tarihMi($0) ? $0 : nil }
                let o = eski?[a]
                let oi = o?["i"]?.sayi ?? 0
                let ot = o?["t"]?.metin
                let enIyi = max(i, oi)
                let gunler = jsSirali([gun, ot].compactMap { $0 }.filter { !$0.isEmpty })
                if enIyi > 0 || !gunler.isEmpty {
                    var c: [(String, JSONDeger)] = [("i", .sayi(enIyi))]
                    if !gunler.isEmpty && enIyi >= 1 - 1e-9 { c.append(("t", .metin(gunler[0]))) }
                    t.append((a, .nesne(SiraliNesne(c))))
                }
            }
            if !t.isEmpty { sonuc = sonuc.ayarlandi(ad, .nesne(SiraliNesne(t))) }
        }
        return .nesne(sonuc)
    }

    /// `Math.min(1, Math.max(0, Math.round(x * 1000) / 1000))`
    static func sinirla(_ x: Double) -> Double { min(1, max(0, jsRound(x * 1000) / 1000)) }

    static let bildirimNedenleri = ["Yanlış sanatçı", "Heykel/mimari", "Kötü görsel", "Yanlış ad"]

    /// `bildirimlerDogrula` (js/bildirim.js, sınır 300)
    static func bildirimlerDogrula(_ b: JSONDeger?) -> JSONDeger {
        guard let l = b?.dizi else { return .dizi([]) }
        let s: [JSONDeger] = l.compactMap { x in
            guard x.dogruMu, let a = x["a"]?.metin, let sa = x["s"]?.metin, let neden = x["neden"]?.metin,
                  bildirimNedenleri.contains(neden) else { return nil }
            let baslik = x["baslik"].map { $0.dogruMu ? $0.jsMetni : "" } ?? ""
            return .nesne(SiraliNesne([("a", .metin(a)), ("s", .metin(sa)), ("baslik", .metin(baslik)), ("neden", .metin(neden)),
                                       ("g", .metin(x["g"]?.metin ?? "")), ("t", .metin(x["t"]?.metin ?? ""))]))
        }
        return .dizi(Array(s.prefix(300)))
    }

    /// `gelistiriciDogrula`: yedek geçerliyse { tarih, yedek, yarim }, değilse null
    static func gelistiriciDogrula(_ g: JSONDeger?, bugun: String, simdi: String) -> JSONDeger {
        guard let g, g.dogruMu, g.nesneMi, let y = g["yedek"], y.dogruMu else { return .bos }
        let ham = SiraliNesne(yayilim(y)).ayarlandi("gelistirici", .bos)
        guard let yedek = try? dogrula(.nesne(ham), bugun: bugun, simdi: simdi) else { return .bos }
        let tarih = g["tarih"]?.metin.map(JSONDeger.metin) ?? .bos
        let yarim = g["yarim"].flatMap { $0.dogruMu && $0.nesneMi ? $0 : nil } ?? .bos
        return .nesne(SiraliNesne([("tarih", tarih), ("yedek", .nesne(yedek)), ("yarim", yarim)]))
    }

    // MARK: - Geliştirici modu (İş 42)

    /// `gelistiriciAc(ilerleme, konular, bolumIdleri, yarim)`
    public static func gelistiriciAc(_ il: SiraliNesne, konular: [Int], bolumIdleri: [String], yarim: JSONDeger? = nil,
                                     simdi: String) -> SiraliNesne {
        if il["gelistirici"]?.dogruMu == true { return il }
        let yedek = il.ayarlandi("gelistirici", .bos)
        var bolumler = il["bolumler"]?.nesne ?? SiraliNesne([])
        for id in bolumIdleri {
            let eski = bolumler[id]?.nesne ?? SiraliNesne([])
            bolumler = bolumler.ayarlandi(id, .nesne(eski.ayarlandi("kolay", .sayi(1)).ayarlandi("orta", .sayi(1))))
        }
        let islenen = tekil((il["islenen"]?.dizi ?? []).compactMap(\.sayi) + konular.map(Double.init)).sorted()
        return il
            .ayarlandi("islenen", .dizi(islenen.map { .sayi($0) }))
            .ayarlandi("bolumler", .nesne(bolumler))
            .ayarlandi("gelistirici", .nesne(SiraliNesne([("tarih", .metin(simdi)), ("yedek", .nesne(yedek)),
                                                          ("yarim", yarim.flatMap { $0.dogruMu ? $0 : nil } ?? .bos)])))
    }

    /// `gelistiriciKapat(ilerleme)`: { ilerleme: geri gelen (güncel ayarlarla), yarim }
    public static func gelistiriciKapat(_ il: SiraliNesne, bugun: String, simdi: String) throws -> (ilerleme: SiraliNesne, yarim: JSONDeger) {
        guard let g = il["gelistirici"], g.dogruMu, let y = g["yedek"] else { return (il, .bos) }
        let ham = SiraliNesne(yayilim(y)).ayarlandi("ayarlar", il["ayarlar"] ?? .bos).ayarlandi("gelistirici", .bos)
        let geri: SiraliNesne = try dogrula(.nesne(ham), bugun: bugun, simdi: simdi)
        let yarim = g["yarim"].flatMap { $0.dogruMu ? $0 : nil } ?? .bos
        return (geri, yarim)
    }

    // MARK: - Küçük kurallar

    /// `sonCalisilanEkle(ilerleme, id)`
    public static func sonCalisilanEkle(_ il: SiraliNesne, _ id: String) -> SiraliNesne {
        let eski = (il["sonCalisilanlar"]?.dizi ?? []).filter { $0 != .metin(id) }
        return il.ayarlandi("sonCalisilanlar", .dizi(Array(([.metin(id)] + eski).prefix(sonCalisilanSiniri))))
    }

    /// `gunlukGuncelle(ilerleme, bugun)`: tarih değişince günlük sayaçlar sıfırlanır
    public static func gunlukGuncelle(_ il: SiraliNesne, bugun: String) -> SiraliNesne {
        if let g = il["gunluk"], g.dogruMu, g["tarih"] == .metin(bugun) { return il }
        return il.ayarlandi("gunluk", bosGunluk(bugun))
    }

    /// `enYeniKayit(ls, idb)`: numarası büyük olan; eşitse ilki (localStorage)
    public static func enYeniKayit(_ a: SiraliNesne?, _ b: SiraliNesne?) -> SiraliNesne? {
        guard let a else { return b }
        guard let b else { return a }
        return (b["kayitNo"]?.sayi ?? 0) > (a["kayitNo"]?.sayi ?? 0) ? b : a
    }

    /// `yedekHatirlatmasi(ilerleme, bugun)`: { gun, metin } ya da nil
    public static func yedekHatirlatmasi(_ il: SiraliNesne?, bugun: String) -> (gun: Int, metin: String)? {
        guard let il, let skorlar = il["skorlar"]?.nesne, skorlar.count > 0 else { return nil }
        if let son = il["sonYedek"], son.dogruMu {
            let gun = gunFarki(son.jsMetni, bugun)
            return gun >= yedekAraligi ? (gun, "Son yedek \(gun) gün önce") : nil
        }
        let ilk = String((il["olusturma"].map { $0.dogruMu ? $0.jsMetni : "" } ?? "").utf16.prefix(10)) ?? ""
        guard tarihMi(ilk) else { return nil }
        let gun = gunFarki(ilk, bugun)
        return gun >= yedekAraligi ? (gun, "Henüz yedek almadın") : nil
    }

    static func gunFarki(_ a: String, _ b: String) -> Int {
        func g(_ x: String) -> Double {
            let p = x.split(separator: "-", omittingEmptySubsequences: false).map { Double($0) ?? .nan }
            guard p.count >= 3 else { return .nan }
            var c = DateComponents(); c.year = Int(p[0]); c.month = Int(p[1]); c.day = Int(p[2])
            var t = Calendar(identifier: .gregorian); t.timeZone = TimeZone(identifier: "UTC")!
            return (t.date(from: c)?.timeIntervalSince1970 ?? .nan) * 1000
        }
        return Int(jsRound((g(b) - g(a)) / 86_400_000))
    }

    // MARK: - Yedek

    /// `yedekMetni(ilerleme, yarimOturum)`: `JSON.stringify(y, null, 1)`
    public static func yedekMetni(_ il: JSONDeger, yarim: JSONDeger? = nil, tarih: String) -> String {
        var y: [(String, JSONDeger)] = [("uygulama", .metin("sanat-atlasi")), ("surum", .sayi(Double(surum))),
                                        ("tarih", .metin(tarih)), ("ilerleme", il)]
        if let yarim, yarim.dogruMu { y.append(("yarimOturum", yarim)) }
        return JSONDeger.nesne(SiraliNesne(y)).girintiliMetin(girinti: 1)
    }

    /// `yedekYarimOturum(metin)`
    public static func yedekYarimOturum(_ metin: String) -> JSONDeger? {
        guard let n = try? JSONDeger.coz(Data(jsTrim(metin).utf8)), let y = n["yarimOturum"], y.dogruMu else { return nil }
        return y
    }

    /// `yedekCoz(metin)`
    public static func yedekCoz(_ metin: String, bugun: String, simdi: String) throws -> SiraliNesne {
        let n: JSONDeger
        do { n = try JSONDeger.coz(Data(jsTrim(metin).utf8)) } catch { throw Hata.gecersiz("Metin geçerli JSON değil.") }
        return try dogrula(n, bugun: bugun, simdi: simdi)
    }

    // MARK: - JS yardımcıları

    /// JS nesne girdileri (`Object.entries`); dizide indeksler
    static func girdiler(_ v: JSONDeger) -> [(String, JSONDeger)] {
        switch v {
        case .nesne(let n): return n.ciftler.map { ($0.anahtar, $0.deger) }
        case .dizi(let d): return d.enumerated().map { (String($0.offset), $0.element) }
        default: return []
        }
    }

    /// `{ ...x }`: nesne ve dizi girdileri, metnin UTF-16 birimleri; diğerleri boş
    static func yayilim(_ v: JSONDeger) -> [(String, JSONDeger)] {
        if case .metin(let m) = v { return Array(m.utf16).enumerated().map { (String($0.offset), .metin(String(utf16CodeUnits: [$0.element], count: 1))) } }
        return girdiler(v)
    }

    /// `{ ...a, ...b }`: a'nın sırası, yeni anahtarlar sona
    static func birlestir(_ a: SiraliNesne, _ b: [(String, JSONDeger)]) -> SiraliNesne {
        SiraliNesne(a.ciftler.map { ($0.anahtar, $0.deger) } + b)
    }

    /// `[...new Set(l)]` (ilk görülen sırası)
    static func tekil<T: Hashable>(_ l: [T]) -> [T] {
        var g = Set<T>()
        return l.filter { g.insert($0).inserted }
    }

    /// `[...new Set(v.filter(string))]`; dizi değilse `diziDegilse`
    static func tekilMetinler(_ v: JSONDeger?, diziDegilse: [JSONDeger] = []) -> [JSONDeger] {
        guard let l = v?.dizi else { return diziDegilse }
        return tekil(l.compactMap(\.metin)).map(JSONDeger.metin)
    }

    /// JS varsayılan `sort()`: UTF-16 birim sırası
    static func jsSirali(_ l: [String]) -> [String] { l.sorted { Array($0.utf16).lexicographicallyPrecedes(Array($1.utf16)) } }

    /// `/^\d{4}-\d{2}-\d{2}$/`
    static func tarihMi(_ s: String) -> Bool {
        let u = Array(s.utf16)
        guard u.count == 10 else { return false }
        for (i, c) in u.enumerated() {
            if i == 4 || i == 7 { if c != 45 { return false } } else if !(48...57).contains(c) { return false }
        }
        return true
    }

    /// `/^\d+\.\d+\.\d+$/`
    static func surumMu(_ s: String) -> Bool {
        let p = s.split(separator: ".", omittingEmptySubsequences: false)
        return p.count == 3 && p.allSatisfy { !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } }
    }

    /// `/^\d+-\d+$/`
    static func bolumKimligiMi(_ s: String) -> Bool {
        let p = s.split(separator: "-", omittingEmptySubsequences: false)
        return p.count == 2 && p.allSatisfy { !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } }
    }

    /// `Math.round`: yarım yukarı (+∞ yönüne)
    static func jsRound(_ x: Double) -> Double {
        guard x.isFinite else { return x }
        let f = x.rounded(.down)
        return x - f >= 0.5 ? f + 1 : f
    }

    /// Karşılaştırmada JS sayıya çevirme (`v.surum >= 2`): sayı, sayısal metin, true/false, null → 0; diğerleri NaN
    static func jsSayi(_ v: JSONDeger?) -> Double {
        switch v {
        case .sayi(let d)?: return d
        case .mantik(let b)?: return b ? 1 : 0
        case .bos?: return 0
        case .metin(let m)?:
            let t = jsTrim(m)
            return t.isEmpty ? 0 : (Double(t) ?? .nan)
        default: return .nan
        }
    }

    /// `parseInt(String(x), 10)`; NaN → nil
    static func jsParseInt(_ v: JSONDeger?) -> Double? {
        guard let v else { return nil }
        var u = Substring(jsTrim(v.jsMetni))
        var isaret = 1.0
        if u.first == "-" { isaret = -1; u = u.dropFirst() } else if u.first == "+" { u = u.dropFirst() }
        let rakam = u.prefix { $0.isASCII && $0.isNumber }
        guard !rakam.isEmpty, let d = Double(rakam) else { return nil }
        return isaret * d
    }

    /// `String.prototype.trim`
    static func jsTrim(_ s: String) -> String {
        let bosluk: Set<UInt32> = [9, 10, 11, 12, 13, 32, 0xA0, 0x1680, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF]
        let b = { (u: Unicode.Scalar) in bosluk.contains(u.value) || (0x2000...0x200A).contains(u.value) }
        let sc = s.unicodeScalars
        guard let ilk = sc.firstIndex(where: { !b($0) }), let son = sc.lastIndex(where: { !b($0) }) else { return "" }
        return String(sc[ilk...son])
    }
}

// MARK: - JSONDeger: JS doğruluk ve tür denetimleri

public extension JSONDeger {
    /// JS doğruluğu: null, false, 0, "" yanlış; nesne ve dizi doğru
    var dogruMu: Bool {
        switch self {
        case .bos: return false
        case .mantik(let b): return b
        case .sayi(let d): return d != 0 && !d.isNaN
        case .metin(let m): return !m.isEmpty
        case .dizi, .nesne: return true
        }
    }
    /// `typeof x === 'object'` (null hariç): nesne ya da dizi
    var nesneMi: Bool { switch self { case .nesne, .dizi: return true; default: return false } }
    var diziMi: Bool { if case .dizi = self { return true }; return false }
    /// `Number.isInteger(x)`
    var tamSayiMi: Bool { if case .sayi(let d) = self { return d.isFinite && d.rounded() == d }; return false }

    /// `JSON.stringify(x, null, girinti)`
    func girintiliMetin(girinti: Int) -> String {
        var s = ""
        girintiliYaz(&s, String(repeating: " ", count: girinti), "")
        return s
    }

    private func girintiliYaz(_ s: inout String, _ g: String, _ simdiki: String) {
        switch self {
        case .dizi(let l) where !l.isEmpty:
            let ic = simdiki + g
            s += "[\n"
            for (i, x) in l.enumerated() {
                if i > 0 { s += ",\n" }
                s += ic
                x.girintiliYaz(&s, g, ic)
            }
            s += "\n" + simdiki + "]"
        case .nesne(let n) where n.count > 0:
            let ic = simdiki + g
            s += "{\n"
            for (i, c) in n.ciftler.enumerated() {
                if i > 0 { s += ",\n" }
                s += ic
                Self.metinYaz(c.anahtar, &s)
                s += ": "
                c.deger.girintiliYaz(&s, g, ic)
            }
            s += "\n" + simdiki + "}"
        default:
            yaz(&s)
        }
    }
}

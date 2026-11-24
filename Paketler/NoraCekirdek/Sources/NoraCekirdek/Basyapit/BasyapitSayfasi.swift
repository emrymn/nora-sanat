// Kaynak: sanat-atlasi js/basyapitSayfa.js (sade, noktalariYerlestir, kirpim, sozlukAl, kunyeSatirlari,
// karsilastirmalariAl, terimIsaretle, dersBolumleri, okumaDakikasi) @ a866b86
// Başyapıt sayfasının (İş 188) saf yardımcıları; ekran: NoraSanat/Ekranlar/Galeri/BasyapitSayfasi.swift
import Foundation

public enum BasyapitSayfasi {
    // MARK: sade

    /// `sade(s)`: Türkçe küçük harf, işaretsiz, yalnız harf ve rakam (aralar tek boşluk)
    public static func sade(_ s: String) -> String {
        let k = JSMetin.kucuk(s).decomposedStringWithCanonicalMapping
        var c = ""
        var bosluk = false
        for u in k.unicodeScalars {
            if (0x300...0x36F).contains(u.value) { continue }
            let h: Unicode.Scalar = u == "ı" ? "i" : u
            if ("a"..."z").contains(h) || ("0"..."9").contains(h) {
                if bosluk && !c.isEmpty { c += " " }
                bosluk = false
                c.unicodeScalars.append(h)
            } else {
                bosluk = true
            }
        }
        return c
    }

    // MARK: Ayrıntıların metindeki yeri

    private static let atlanan: Set<String> = ["ve", "ile", "bir", "tek", "iki", "uc", "sol", "sag", "ust", "alt", "on", "arka",
                                                "kucuk", "buyuk", "eser", "resim", "tablo", "icin", "gibi"]

    static func kokler(_ ad: String) -> [String] {
        sade(ad).split(separator: " ").map(String.init)
            .filter { $0.count >= 3 && !atlanan.contains($0) }
            .map { String($0.prefix(max(3, min($0.count, 5)))) }
    }

    /// `noktalariYerlestir(bolumler, noktalar)`: noktanın adındaki sözcük kökleri bölüm metinlerinde aranır; en çok kökü
    /// geçen bölüm kazanır (eşitlikte önce gelen), hiçbirinde geçmeyen ilk bölüme. Dönen: bölüm başına nokta sıraları.
    public static func noktalariYerlestir(_ bolumler: [Basyapit.Bolum], _ noktalar: [AyrintiNoktasi]) -> [[Int]] {
        var gruplar = Array(repeating: [Int](), count: max(1, bolumler.count))
        let sozcukler = bolumler.map { sade($0.baslik + " " + $0.metin).split(separator: " ").map(String.init) }
        for (i, nokta) in noktalar.enumerated() {
            let k = kokler(nokta.ad)
            var en = 0, yer = 0
            for (j, s) in sozcukler.enumerated() {
                let puan = k.filter { kok in s.contains { $0.hasPrefix(kok) } }.count
                if puan > en { en = puan; yer = j }
            }
            gruplar[yer].append(i)
        }
        return gruplar
    }

    // MARK: Ayrıntı kırpımı

    public struct Kirpim: Equatable, Sendable {
        /// Yüzde: w ve l kutunun genişliğine, h ve t kutunun yüksekliğine göre
        public let w, h, l, t: Double
    }

    /// `kirpim(n, oran, kutu, { pay, enCok })`: ayrıntı bölgesini (0–1) kutuya sığdıran resim yerleşimi. oran: resmin
    /// yüksekliği / genişliği; kutu: kutunun genişliği / yüksekliği. Bölge bütünüyle (pay kadar çevresiyle) görünür,
    /// resim kutuyu her zaman doldurur, enCok'tan fazla büyütülmez.
    public static func kirpim(_ n: AyrintiNoktasi, oran: Double, kutu: Double, pay: Double = 1.6, enCok: Double = 4) -> Kirpim {
        let r = oran > 0 ? oran : 1
        let k = kutu > 0 ? kutu : 1
        func sinir(_ v: Double, _ alt: Double, _ ust: Double) -> Double { min(ust, max(alt, v)) }
        let doldur = max(1, 1 / (r * k))
        let sigdir = min(1 / (max(n.w, 0.01) * pay), 1 / (max(n.h, 0.01) * r * k * pay))
        let w = max(doldur, min(sigdir, max(doldur, enCok)))
        let h = w * r * k
        func yuvarla(_ v: Double) -> Double { (v * 10000 + 0.5).rounded(.down) / 100 }
        return Kirpim(w: yuvarla(w), h: yuvarla(h),
                      l: yuvarla(sinir(0.5 - (n.x + n.w / 2) * w, 1 - w, 0)),
                      t: yuvarla(sinir(0.5 - (n.y + n.h / 2) * h, 1 - h, 0)))
    }

    /// Metnin arasına giren tek ayrıntı (`BUYUK_KUTU`) ve yana kayan şeritteki ayrıntılar (`KUCUK_KUTU`)
    public static let buyukKutu = 8.0 / 5, kucukKutu = 4.0 / 3

    // MARK: Ders verisi: sözlük, künye, karşılaştırmalar

    private static let kanit = JSDuzen(#"\s*\[[CKSDE]\d{1,4}\]"#)
    private static let belirsiz = JSDuzen(#"\s*\((belirsiz|tartışma|yorum)[^()]*\)"#, i: true)
    private static let arti = JSDuzen(#"\s+\+\s+"#)
    private static let cokBosluk = JSDuzen(#"\s{2,}"#)

    /// `yazi(x)`: metinse kırpılmış, değilse ""
    static func yazi(_ j: JSONDeger?) -> String { j?.metin.map(JSMetin.kirp) ?? "" }

    /// `ayikla(s)`: modelin çalışma izleri (kanıt etiketleri, "(belirsiz)" notları) atılır
    static func ayikla(_ j: JSONDeger?) -> String {
        var s = yazi(j)
        s = kanit.degistir(s, "")
        s = belirsiz.degistir(s, "")
        s = arti.degistir(s, " ve ")
        s = cokBosluk.degistir(s, " ")
        return JSMetin.kirp(s)
    }

    public struct Terim: Equatable, Hashable, Sendable {
        public let ad, tanim: String
    }

    /// `sozlukAl(ders, enCok)`: dersin temel kavramları (tekrarsız, en çok 8)
    public static func sozlukAl(_ ders: JSONDeger?, enCok: Int = 8) -> [Terim] {
        var gorulen = Set<String>()
        var l: [Terim] = []
        for k in ders?["temel_kavramlar"]?.dizi ?? [] {
            let ad = ayikla(k["ad"]), tanim = ayikla(k["tanim"])
            guard JSMetin.boy(ad) >= 3, JSMetin.boy(tanim) >= 8, !gorulen.contains(sade(ad)) else { continue }
            gorulen.insert(sade(ad))
            l.append(Terim(ad: ad, tanim: tanim))
        }
        return l.prefix(enCok).map { Terim(ad: JSMetin.ilkBuyuk($0.ad), tanim: JSMetin.ilkBuyuk($0.tanim)) }
    }

    public struct KunyeSatiri: Equatable, Hashable, Sendable {
        public let ad, deger: String
    }

    /// `kunyeSatirlari(b, ders)`: Tarih, Teknik, Boyut, Yer (boş olanlar yok)
    public static func kunyeSatirlari(_ b: Basyapit, _ ders: JSONDeger?) -> [KunyeSatiri] {
        let k: JSONDeger? = ders?["kunye"].flatMap { $0.nesne != nil ? $0 : nil }
        // `sayiYaz(x)`: String(x), ilk nokta virgül
        func sayiYaz(_ j: JSONDeger) -> String {
            let s = j.jsMetni
            guard let r = s.range(of: ".") else { return s }
            return s.replacingCharacters(in: r, with: ",")
        }
        var boyut = ""
        if let bc = k?["boyut_cm"], bc.dogru,
           let y = bc["yukseklik"], let g = bc["genislik"], jsSayi(y) > 0, jsSayi(g) > 0 {
            boyut = sayiYaz(y) + " × " + sayiYaz(g) + " cm"
        }
        let muze = JSMetin.kirp(b.muze)
        return [("Tarih", JSMetin.kirp(b.tarih)), ("Teknik", JSMetin.ilkBuyuk(ayikla(k?["teknik"]))), ("Boyut", boyut),
                ("Yer", muze.isEmpty ? ayikla(k?["muze"]) : muze)]
            .filter { !$0.1.isEmpty }
            .map { KunyeSatiri(ad: $0.0, deger: $0.1) }
    }

    /// JS `Number(x)` (sayı ya da sayı yazısı; değilse NaN → 0 sayılır, `> 0` sınaması için)
    private static func jsSayi(_ j: JSONDeger) -> Double {
        switch j {
        case .sayi(let s): return s
        case .metin(let m):
            let t = JSMetin.kirp(m)
            return t.isEmpty ? 0 : Double(t) ?? .nan
        case .mantik(let b): return b ? 1 : 0
        default: return .nan
        }
    }

    public struct Karsilastirma: Equatable, Hashable, Sendable {
        public let eser, sanatci, gerekce: String
        /// Uygulamada başyapıt kaydı olan eşi (yoksa nil: görselsiz kart)
        public let anahtar: String?
    }

    private static let parantezler = JSDuzen(#"\s*\([^)]*\)"#)

    /// `karsilastirmalariAl(ders, liste, bu, adlar)`: dersin karşılaştırma önerileri; başyapıt kaydı olan eserler anahtarıyla
    /// eşlenir (başlık ya da özgün ad; birden çok aday varsa sanatçının soyadıyla). adlar: sanatçı kimliği → ad.
    public static func karsilastirmalariAl(_ ders: JSONDeger?, _ liste: [Basyapit], bu: String,
                                           adlar: (String) -> String = { _ in "" }) -> [Karsilastirma] {
        (ders?["karsilastirma_onerileri"]?.dizi ?? [])
            .map { k in (eser: ayikla(k["eser"]), sanatci: ayikla(k["sanatci"]), gerekce: JSMetin.ilkBuyuk(ayikla(k["gerekce"]))) }
            .filter { !$0.eser.isEmpty && !$0.gerekce.isEmpty }
            .map { k in
                let ad = sade(k.eser)
                let soyad = sade(k.sanatci).split(separator: " ", omittingEmptySubsequences: false).last.map(String.init) ?? ""
                let adaylar = liste.filter { b in
                    if b.anahtar == bu || JSMetin.boy(ad) < 5 { return false }
                    let basliklar = [sade(parantezler.degistir(b.baslik, "")), sade(b.ozgun)].filter { !$0.isEmpty }
                    return basliklar.contains { x in x == ad || (JSMetin.boy(x) >= 8 && ad.contains(x)) || x.contains(ad) }
                }
                let es = adaylar.first { b in !soyad.isEmpty && sade(adlar(b.sanatci)).contains(soyad) }
                    ?? (adaylar.count == 1 ? adaylar[0] : nil)
                return Karsilastirma(eser: k.eser, sanatci: k.sanatci, gerekce: k.gerekce, anahtar: es?.anahtar)
            }
    }

    /// Z3q (uygulamaya özgü; sitede yok, kullanıcı isteği): başyapıt kaydı olmayan karşılaştırma önerisinin görseli için
    /// sanatçının katalogundaki eser. Yanlış eser göstermemek için kesin eşleşme:
    /// - sanatçı: önerideki adın son sözcüğü (en az 4 harf) tek bir sanatçının adında ya da arama adında tam sözcük olarak;
    /// - eser: parantezler atılınca `sade` başlık (en az 5 harf) eserin özgün ya da Türkçe adıyla birebir aynı;
    /// - açık olan eser (`haric`) sayılmaz; tam bir eser kalmalı ve görseli olmalı.
    /// Gerçek veride (sanat-atlasi 05f9039) görselsiz 197 önerinin 31'i böyle bulunuyor.
    public static func katalogEseri(_ k: Karsilastirma, sanatcilar: [(id: String, adlar: [String])], eserler: [String: [Eser]],
                                    haric: Set<String>) -> Eser? {
        let soyad = sade(k.sanatci).split(separator: " ").last.map(String.init) ?? ""
        guard JSMetin.boy(soyad) >= 4 else { return nil }
        let adaylar = sanatcilar.filter { s in s.adlar.contains { sade($0).split(separator: " ").map(String.init).contains(soyad) } }
        guard adaylar.count == 1 else { return nil }
        let hedef = sade(parantezler.degistir(k.eser, ""))
        guard JSMetin.boy(hedef) >= 5 else { return nil }
        let bulunan = (eserler[adaylar[0].id] ?? []).filter { e in
            !haric.contains(e.anahtar) && !(e.qid.map(haric.contains) ?? false) && !e.gorseller.isEmpty
                && [e.baslik, e.ad ?? ""].contains { !$0.isEmpty && sade(parantezler.degistir($0, "")) == hedef }
        }
        return bulunan.count == 1 ? bulunan[0] : nil
    }

    // MARK: Sözlük terimlerini metinde işaretleme

    private static let etiket = JSDuzen("(<[^>]+>)")
    private static let acan = JSDuzen(#"^<(button|h[1-6])\b"#, i: true)
    private static let kapatan = JSDuzen(#"^<\/(button|h[1-6])\b"#, i: true)

    /// `terimIsaretle(metin, terimler, kullanilan)`: HTML'deki her terimin (sayfadaki) ilk geçtiği yer
    /// `<button class="bsy-terim" data-bsy-terim="i">` olur (Türkçe ekleriyle). Etiketlerin, düğmelerin ve başlıkların içi
    /// aranmaz. kullanilan: sayfa boyunca işaretlenmiş terim sıraları.
    public static func terimIsaretle(_ metin: String, _ terimler: [Terim], _ kullanilan: inout Set<Int>) -> String {
        var cikti = metin
        for (i, t) in terimler.enumerated() where !kullanilan.contains(i) {
            let aranan = JSMetin.kucuk(t.ad)
            if JSMetin.boy(aranan) < 3 { continue }
            var parcalar = bolKoru(cikti)
            var kapali = 0
            let desen = try! NSRegularExpression(pattern: "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: aranan) + "\\p{L}*")
            for p in parcalar.indices {
                let x = parcalar[p]
                if x.hasPrefix("<") {
                    if acan.var_(x) { kapali += 1 } else if kapatan.var_(x) { kapali -= 1 }
                    continue
                }
                if kapali > 0 { continue }
                let kucuk = JSMetin.kucuk(x)
                let kn = kucuk as NSString, xn = x as NSString
                guard kn.length == xn.length,
                      let m = desen.firstMatch(in: kucuk, range: NSRange(location: 0, length: kn.length)) else { continue }
                parcalar[p] = xn.substring(to: m.range.location)
                    + "<button type=\"button\" class=\"bsy-terim\" data-bsy-terim=\"\(i)\">" + xn.substring(with: m.range) + "</button>"
                    + xn.substring(from: m.range.location + m.range.length)
                kullanilan.insert(i)
                break
            }
            cikti = parcalar.joined()
        }
        return cikti
    }

    /// `s.split(/(<[^>]+>)/)`: yakalanan etiketler de listede
    private static func bolKoru(_ s: String) -> [String] {
        let ns = s as NSString
        var l: [String] = []
        var son = 0
        for m in etiket.r.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            l.append(ns.substring(with: NSRange(location: son, length: m.range.location - son)))
            l.append(ns.substring(with: m.range))
            son = m.range.location + m.range.length
        }
        l.append(ns.substring(from: son))
        return l
    }

    // MARK: Ayrıntılı anlatım

    public struct DersBolumu: Equatable, Hashable, Sendable {
        public let baslik, govde: String
        /// Bu bölümün yerine karşılaştırma kartları konabilir
        public let karsilastirma: Bool
    }

    private static let ikiDiyez = JSDuzen(#"^##\s+(.*)$"#)
    private static let karsilastir = JSDuzen("karşılaştır", i: true)

    /// `dersBolumleri(md)`: `temizle` çıktısı "## Başlık" satırlarıyla bölünür; başlıksız baştaki metin atılır
    public static func dersBolumleri(_ md: String) -> [DersBolumu] {
        var bolumler: [(baslik: String, govde: [String])] = []
        for s in md.components(separatedBy: "\n") {
            if let b = ikiDiyez.ilk(s) {
                bolumler.append((JSMetin.kirp(b[1]), []))
            } else if !bolumler.isEmpty {
                bolumler[bolumler.count - 1].govde.append(s)
            }
        }
        return bolumler
            .map { DersBolumu(baslik: $0.baslik, govde: JSMetin.kirp($0.govde.joined(separator: "\n")),
                              karsilastirma: karsilastir.var_($0.baslik)) }
            .filter { !$0.baslik.isEmpty && !$0.govde.isEmpty }
    }

    /// `okumaDakikasi(md)`: dakikada 180 sözcük, en az 1
    public static func okumaDakikasi(_ md: String) -> Int {
        let n = md.split(whereSeparator: { $0.isWhitespace }).count
        return max(1, Int((Double(n) / 180 + 0.5).rounded(.down)))
    }

    // MARK: Sayfanın metinleri

    /// Sayfanın terim işaretli metinleri. Site (`terimleriIsle`) `[data-bsy-terimli]` öğelerini belge sırasıyla işler:
    /// her bölümün metni, ardından o bölümde tek ayrıntı varsa onun açıklaması; en sonda ayrıntılı anlatımın bölümleri
    /// (karşılaştırma kartlarının yerini aldığı bölüm hariç). Bir terim sayfada yalnız ilk geçtiği yerde işaretlenir.
    public struct Metinler: Equatable, Sendable {
        /// Bölüm metinleri (HTML)
        public var bolumler: [String]
        /// Tek ayrıntılı bölümlerin ayrıntı açıklaması: nokta sırası → HTML
        public var aciklamalar: [Int: String]
        /// Ayrıntılı anlatımın bölümleri (HTML; karşılaştırmanın yerini aldığı bölümde nil)
        public var derin: [String?]
    }

    public static func metinler(_ b: Basyapit, yerler: [[Int]]?, noktalar: [AyrintiNoktasi], derin: [DersBolumu],
                                kiyasVar: Bool, terimler: [Terim]) -> Metinler {
        var kullanilan = Set<Int>()
        func isle(_ h: String) -> String { terimler.isEmpty ? h : terimIsaretle(h, terimler, &kullanilan) }
        var m = Metinler(bolumler: [], aciklamalar: [:], derin: [])
        for (i, x) in b.bolumler.enumerated() {
            m.bolumler.append(isle(JSMetin.kacis(x.metin)))
            if let sira = yerler?[safe: i], sira.count == 1, noktalar.indices.contains(sira[0]) {
                m.aciklamalar[sira[0]] = isle(JSMetin.kacis(noktalar[sira[0]].metin))
            }
        }
        m.derin = derin.map { x in x.karsilastirma && kiyasVar ? nil : isle(DersMetni.mdHtml(x.govde)) }
        return m
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

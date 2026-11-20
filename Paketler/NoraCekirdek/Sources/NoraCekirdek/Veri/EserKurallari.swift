// Kaynak: sanat-atlasi js/eserler.js, js/resim.js, js/birlesme.js @ a866b86 (site 1.90.3)
// Bir sanatçının eser listesi sitenin kurduğu gibi:
//   önbellek dosyasındaki kayıtlar (yoksa yalnız kurs resimleri) → çıkarılan görseller → elle düzeltmeler →
//   aynı tablonun kopya kaydı → ortak atıf, şüpheli yıl, Türkçe ad.
// Sitenin canlı Wikidata yolu (önbellek 30 günden eskiyse yeni eserleri sona ekler; önbellekte kaydı olmayan sanatçıya
// Wikidata'dan eser getirir) burada yok: uygulama sitenin yayımladığı önbellek dosyasıyla çalışır. Bkz. ISLER.md T1 devir notu.
import Foundation

public struct EserKurallari: Sendable {
    // data/eser_turleri.json
    let kursKararlari: [String: String]?
    let anaUgrasDisi: Set<String>
    // data/eserler_onbellek.json (surum ≥ 3)
    let onbellek: [String: OnbellekDosyasi.Kayit]?
    let onbellekSirasi: [String]
    /// "2026-11-13T20:33:44.410Z"
    public let onbellekTarihi: String?
    // data/kopya_eserler.json: sanatçı → [(sil, kalan)]
    let kopyalar: [String: [(sil: String?, kalan: String?)]]
    // data/cikarilan_gorseller.json
    let cikarilan: Set<String>
    // data/eser_duzeltmeleri.json
    let cikar: [String: Set<String>]
    let gorselCikar: [String: [String: Set<String>]]
    let muze: [String: String]
    let tarih: [String: (yil: Int, tarih: String)]
    // data/eser_adlari_tr.json
    let adlar: [String: String]
    /// qid → sanatçılar (ortak atıf)
    let ortaklar: [String: [String]]
    let ortakAdlari: [String: String]

    public init(turler: Data?, onbellek: Data?, kopyalar: Data?, cikarilan: Data?, duzeltmeler: Data?, adlar: Data?,
                sanatciAdlari: [String: String] = [:]) {
        let t = JSONNesne.sozluk(turler)
        if let k = JSONNesne.sozluk(t?["kurs"]) {
            var m: [String: String] = [:]
            for (a, v) in k { m[a] = (JSONNesne.sozluk(v)?["karar"] as? String) ?? "" }
            kursKararlari = m
        } else {
            kursKararlari = nil
        }
        anaUgrasDisi = Set((JSONNesne.sozluk(t?["ana_ugras_disi"]) ?? [:]).filter { JSONNesne.dogruMu($0.value) }.keys)

        if let onbellek, let o = try? JSONDecoder().decode(OnbellekDosyasi.self, from: onbellek), o.surum >= 3 {
            self.onbellek = o.sanatcilar
            onbellekTarihi = o.olusturma
            let sira = SiraliJSON.anahtarlar(onbellek, alan: "sanatcilar")
            onbellekSirasi = sira.count == o.sanatcilar.count ? sira : o.sanatcilar.keys.sorted()
        } else {
            self.onbellek = nil
            onbellekTarihi = nil
            onbellekSirasi = []
        }

        var kp: [String: [(String?, String?)]] = [:]
        for (sid, l) in JSONNesne.sozluk(JSONNesne.sozluk(kopyalar)?["sanatcilar"]) ?? [:] {
            guard let l = l as? [Any] else { continue }
            kp[sid] = l.map { c in
                let c = JSONNesne.sozluk(c)
                return (c?["sil"] as? String, c?["kalan"] as? String)
            }
        }
        self.kopyalar = kp

        self.cikarilan = Set(((JSONNesne.sozluk(cikarilan)?["anahtarlar"] as? [Any]) ?? [])
            .map { JSONNesne.jsMetni($0).precomposedStringWithCanonicalMapping })

        let dz = JSONNesne.sozluk(duzeltmeler)
        var ck: [String: Set<String>] = [:]
        for (sid, l) in JSONNesne.sozluk(dz?["cikar"]) ?? [:] {
            guard let l = l as? [Any] else { continue }
            ck[sid] = Set(l.compactMap { JS.dolu(JSONNesne.sozluk($0)?["qid"] as? String) })
        }
        cikar = ck
        var gc: [String: [String: Set<String>]] = [:]
        for (sid, kayitlar) in JSONNesne.sozluk(dz?["gorsel_cikar"]) ?? [:] {
            guard let kayitlar = JSONNesne.sozluk(kayitlar) else { continue }
            var m: [String: Set<String>] = [:]
            for (q, l) in kayitlar {
                guard let l = l as? [Any] else { continue }
                m[q] = Set(l.map { Yardimci.dosyaNormal(JSONNesne.jsMetni($0)).lowercased().precomposedStringWithCanonicalMapping })
            }
            gc[sid] = m
        }
        gorselCikar = gc
        var mz: [String: String] = [:]
        for (q, v) in JSONNesne.sozluk(dz?["muze"]) ?? [:] { mz[q] = JSONNesne.dogruMu(v) ? JSONNesne.jsMetni(v) : "" }
        muze = mz
        var tr: [String: (Int, String)] = [:]
        for (q, v) in JSONNesne.sozluk(dz?["tarih"]) ?? [:] {
            guard let v = JSONNesne.sozluk(v), let yil = JSONNesne.tamSayi(v["yil"]) else { continue }
            tr[q] = (yil, JSONNesne.dogruMu(v["tarih"]) ? JSONNesne.jsMetni(v["tarih"]) : String(yil))
        }
        tarih = tr

        var ad: [String: String] = [:]
        for (k, v) in JSONNesne.sozluk(JSONNesne.sozluk(adlar)?["adlar"]) ?? [:] {
            if let s = v as? String { let t = JS.kirp(s); if !t.isEmpty { ad[k] = t } }
        }
        self.adlar = ad

        // ortakAtiflariAyarla: önbellekteki sanatçı sırasıyla (JSON'daki sıra)
        var m: [String: [String]] = [:]
        if let o = self.onbellek {
            for sid in onbellekSirasi {
                for e in o[sid]?.eserler ?? [] {
                    guard let q = JS.dolu(e.qid), !(ck[sid]?.contains(q) ?? false) else { continue }
                    if !(m[q]?.contains(sid) ?? false) { m[q, default: []].append(sid) }
                }
            }
        }
        ortaklar = m.filter { $0.value.count > 1 }
        ortakAdlari = sanatciAdlari
    }

    // MARK: resim.js

    /// `kursEseriResimMi`: kararı yalnız tablo verir; tabloda olmayan eser gösterilir
    func kursEseriResimMi(_ e: Sanatci.KursEseri) -> Bool {
        guard let k = kursKararlari?[Yardimci.dosyaNormal(e.commonsDosya).lowercased()] else { return true }
        return k == "resim"
    }

    /// `kursResimleri` (sırayla, `kurs_eserleri` içindeki yerleriyle)
    func kursResimleri(_ s: Sanatci) -> [(sira: Int, eser: Sanatci.KursEseri)] {
        (s.kursEserleri ?? []).enumerated().filter { kursEseriResimMi($0.element) }.map { ($0.offset, $0.element) }
    }

    /// `resimSanatcisiMi`: yalnız iki boyutlu resim yapan sanatçılar gösterilir
    public func resimSanatcisiMi(_ s: Sanatci) -> Bool {
        if anaUgrasDisi.contains(s.id) { return false }
        if !kursResimleri(s).isEmpty { return true }
        let kursYok = (s.kursEserleri ?? []).isEmpty
        guard let onbellek else { return kursYok }
        guard let k = onbellek[s.id] else { return kursYok }
        return !(k.eserler ?? []).isEmpty
    }

    // MARK: eserler.js

    /// `yilSupheliMi`: eserin yılı sanatçının yaşamıyla çelişiyor mu (ölümünden 2 yıl sonra ya da 12 yaşından önce)
    public static func yilSupheliMi(_ yil: Int?, _ s: Sanatci?) -> Bool {
        guard let yil, let s else { return false }
        if let o = s.olum, yil > o + 2 { return true }
        if let d = s.dogum, yil < d + 12 { return true }
        return false
    }

    /// `onbellekEseri`; ilk görseli olmayan (anahtarı kurulamayan) kayıtta nil (sitede hata → kurs listesine düşer)
    static func onbellekEseri(_ e: OnbellekDosyasi.HamEser) -> Eser? {
        let ilk = e.gorseller.first
        let anahtar: String
        if e.kurs == true || JS.dolu(e.qid) == nil {
            guard let ilk else { return nil }
            anahtar = GorselKaynagi.anahtar(ilk)
        } else {
            anahtar = "q:" + e.qid!
        }
        let t = Yardimci.notTemizle(e.tarih)
        return Eser(anahtar: anahtar, kaynak: e.kurs == true ? "kurs" : (e.kaynaklar.first ?? ""), kaynaklar: e.kaynaklar,
                    baslik: e.baslik, tarih: t.isEmpty ? Yardimci.tarihYaz(e.yil) : t, yil: e.yil,
                    muze: Yardimci.notTemizle(e.muze ?? ""), kursKonu: e.konu, qid: JS.dolu(e.qid), gorseller: e.gorseller,
                    pekistirme: e.pekistirme != false, sl: e.sl ?? 0)
    }

    /// `eserleriBirlestir` (Wikidata'sız): kurs resimleri, aynı dosya ya da başlık bir kez
    static func kursListesi(_ kurs: [Sanatci.KursEseri]) -> [Eser] {
        var sonuc: [Eser] = []
        var dosyalar = Set<String>(), basliklar = Set<String>()
        for e in kurs {
            guard let dosya = JS.dolu(e.commonsDosya) else { continue }
            let d = Yardimci.dosyaNormal(dosya).lowercased()
            let b = Yardimci.baslikNormal(e.baslik)
            if dosyalar.contains(d) || (!b.isEmpty && basliklar.contains(b)) { continue }
            dosyalar.insert(d)
            if !b.isEmpty { basliklar.insert(b) }
            let g = Gorsel(k: "commons", d: Yardimci.dosyaNormal(e.commonsDosya), l: e.lisans ?? "")
            sonuc.append(Eser(anahtar: "c:" + d, kaynak: "kurs", kaynaklar: ["kurs"], baslik: e.baslik,
                              tarih: Yardimci.notTemizle(e.tarih ?? ""), yil: nil, muze: Yardimci.notTemizle(e.yer ?? ""),
                              kursKonu: e.konu, qid: nil, gorseller: [g], pekistirme: true))
        }
        return sonuc
    }

    static func cikarAnahtari(_ g: Gorsel) -> String {
        (g.k == "commons" ? Yardimci.dosyaNormal(g.d).lowercased() : "\(g.k):\(JS.dolu(g.d) ?? JS.dolu(g.i) ?? JS.dolu(g.u) ?? "")")
            .precomposedStringWithCanonicalMapping
    }

    /// `cikarilanlariAyikla` (İş 117): çıkarılan görseller atılır; görseli kalmayan eser düşer
    func cikarilanlariAyikla(_ liste: [Eser]) -> [Eser] {
        guard !cikarilan.isEmpty else { return liste }
        return liste.compactMap { e in
            var e = e
            e.gorseller = e.gorseller.filter { !cikarilan.contains(Self.cikarAnahtari($0)) }
            return e.gorseller.isEmpty ? nil : e
        }
    }

    /// `duzeltmeleriUygula` (İş 174): elle eser düzeltmeleri
    func duzeltmeleriUygula(_ sid: String, _ liste: [Eser]) -> [Eser] {
        let ck = cikar[sid], gc = gorselCikar[sid]
        return liste.compactMap { e in
            if let q = e.qid, ck?.contains(q) == true { return nil }
            var y = e
            if let q = e.qid, let atilan = gc?[q] {
                y.gorseller = e.gorseller.filter { !($0.k == "commons" && atilan.contains(Self.cikarAnahtari($0))) }
                if y.gorseller.isEmpty { return nil }
            }
            if let q = e.qid, let m = muze[q] { y.muze = m }
            if let q = e.qid, let t = tarih[q] { y.yil = t.yil; y.tarih = t.tarih }
            return y
        }
    }

    /// `kopyalariAyikla` (İş 101): aynı tablonun ikinci kaydı çıkar; kurs bilgisi ve bilinirlik kalana geçer
    func kopyalariAyikla(_ sid: String, _ liste: [Eser]) -> [Eser] {
        guard let ciftler = kopyalar[sid], !ciftler.isEmpty else { return liste }
        var liste = liste
        var yer: [String: Int] = [:]
        for (i, e) in liste.enumerated() { yer[e.anahtar] = i }
        var silinecek = Set<String>()
        for c in ciftler {
            guard let sa = c.sil, let ka = c.kalan, let si = yer[sa], let ki = yer[ka], si != ki,
                  !silinecek.contains(ka) else { continue }
            silinecek.insert(sa)
            let sil = liste[si]
            if sil.kaynak == "kurs" && liste[ki].kaynak != "kurs" {
                liste[ki].kaynak = "kurs"
                liste[ki].kaynaklar = ["kurs"] + liste[ki].kaynaklar.filter { $0 != "kurs" }
                liste[ki].kursKonu = liste[ki].kursKonu ?? sil.kursKonu
                liste[ki].baslik = sil.baslik
            }
            liste[ki].sl = max(liste[ki].sl, sil.sl)
        }
        return silinecek.isEmpty ? liste : liste.filter { !silinecek.contains($0.anahtar) }
    }

    /// `eserAdiBul`: Türkçe ad (QID ya da "sanatçı|başlık"); yoksa ""
    public func eserAdi(_ sid: String, _ e: Eser) -> String {
        (e.qid.flatMap { JS.dolu(adlar[$0]) }) ?? JS.dolu(adlar["\(sid)|\(e.baslik)"]) ?? ""
    }

    /// Türkçe eser adı (QID ya da "sanatçı|özgün başlık"); yoksa nil
    public func eserAdi(sanatci sid: String, qid: String?, baslik: String) -> String? {
        (qid.flatMap { JS.dolu(adlar[$0]) }) ?? JS.dolu(adlar["\(sid)|\(baslik)"])
    }

    /// `sanatciEserleri`: sanatçının birleşik eser listesi (en bilinenler önce; kurs eserleri en başta)
    public func eserler(_ s: Sanatci) -> [Eser] {
        var liste: [Eser]
        if let hk = onbellek?[s.id], let ham = hk.eserler,
           case let l = ham.map(Self.onbellekEseri), !l.contains(where: { $0 == nil }) {
            liste = l.compactMap { $0 }
        } else {
            liste = Self.kursListesi(kursResimleri(s).map(\.eser))
        }
        liste = kopyalariAyikla(s.id, duzeltmeleriUygula(s.id, cikarilanlariAyikla(liste)))
        for i in liste.indices {
            liste[i].sid = s.id
            let ortak = (liste[i].qid.flatMap { ortaklar[$0] } ?? []).filter { $0 != s.id }
            if !ortak.isEmpty {
                liste[i].ortak = ortak
                liste[i].ortakAdlar = ortak.map { ortakAdlari[$0] ?? $0 }
            }
            // İş 143: sanatçının yaşamıyla çelişen yıl gösterilmez
            if Self.yilSupheliMi(liste[i].yil, s) && liste[i].tarih == Yardimci.tarihYaz(liste[i].yil) {
                liste[i].yil = nil
                liste[i].tarih = ""
            }
            let ad = eserAdi(s.id, liste[i])
            if !ad.isEmpty && ad != liste[i].baslik { liste[i].ad = ad }
        }
        return liste
    }
}

// MARK: - birlesme.js

public enum AkimBirlesmesi {
    /// Uygulamada birleştirilen akımlar (1.78.0)
    public static let birlesenler = ["Uluslararası Gotik": "Gotik"]

    public static func akimAdi(_ ad: String) -> String { birlesenler[ad] ?? ad }

    /// `sanatcilariBirlestir`
    public static func sanatcilar(_ l: [Sanatci]) -> [Sanatci] {
        l.map { s in
            guard let hedef = birlesenler[s.akim] else { return s }
            var y = s
            y.birlesen = s.akim
            y.akim = hedef
            return y
        }
    }

    /// `akimlariBirlestir`: birleşen akım çıkar; komşu adları hedefe döner, tekrarlar ve akımın kendisi atılır
    public static func akimlar(_ l: [Akim]) -> [Akim] {
        l.filter { birlesenler[$0.ad] == nil }.map { a in
            var y = a
            var gorulen = Set<String>()
            y.komsular = a.komsular.map(akimAdi).filter { gorulen.insert($0).inserted && $0 != a.ad }
            return y
        }
    }
}

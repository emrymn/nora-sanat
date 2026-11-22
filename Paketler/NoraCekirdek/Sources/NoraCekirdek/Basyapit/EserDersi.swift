// Kaynak: sanat-atlasi js/eserDersi.js (yayinAl, dersKlasoru, dersDurumu, dersGorunurMu, dersYolu, temizle, satirIci,
// mdHtml), js/ekranlar/eserDersi.js (dersinDurumu) @ a866b86
// Eser dersleri (basyapit-dersleri/eserler/<klasör>/): yayın kapısı ve ders metninin ekranda gösterilecek hâli.
// Başyapıt sayfasının "Daha derine in" bölümü kullanır (G3); eser dersi ekranları (C3) da kullanabilir.
import Foundation

public struct DersYayini: Equatable, Sendable {
    /// başyapıt anahtarı → klasör
    public let dersler: [String: String]
    public let onayli: Set<String>

    public enum Durum: String, Sendable { case onayli, taslak, kapali, yok }

    public static let kok = "basyapit-dersleri/eserler/"
    private static let klasorDeseni = JSDuzen("^[A-Za-z0-9-]+$")
    private static let dosyaDeseni = JSDuzen(#"^[A-Z_]+\.(json|md)$"#)

    /// `yayinAl(json)` (data/ders_yayin.json): `{ dersler: { anahtar: klasör }, onayli: [klasör] }`
    public init(_ json: JSONDeger?) {
        var d: [String: String] = [:]
        if let n = json?["dersler"]?.nesne {
            for a in n.anahtarlar { if let k = n[a]?.metin, Self.klasorDeseni.var_(k) { d[a] = k } }
        }
        dersler = d
        let klasorler = Set(d.values)
        onayli = Set((json?["onayli"]?.dizi ?? []).compactMap(\.metin).filter(klasorler.contains))
    }

    /// `dersKlasoru`
    public func klasor(_ anahtar: String) -> String? { dersler[anahtar] }

    /// `dersDurumu(yayin, anahtar, gelistirici)`: onaylı herkese açık, onaysız yalnız geliştirici modunda (taslak)
    public func durum(_ anahtar: String, gelistirici: Bool = false) -> Durum {
        guard let k = klasor(anahtar) else { return .yok }
        if onayli.contains(k) { return .onayli }
        return gelistirici ? .taslak : .kapali
    }

    /// `dersGorunurMu`
    public static func gorunur(_ d: Durum) -> Bool { d == .onayli || d == .taslak }

    /// `dersYolu(klasor, dosya)`: güvenli yol (yoksa nil)
    public static func yol(_ klasor: String, _ dosya: String) -> String? {
        klasorDeseni.var_(klasor) && dosyaDeseni.var_(dosya) ? kok + klasor + "/" + dosya : nil
    }
}

public enum DersMetni {
    // MARK: temizle

    private static let atla = JSDuzen("kimlik|etkinlik|kanıt|kaynak|sınır|kalite|öğrenme|sıra sizde|seminer|standart|yöntem", i: true)
    private static let meta = JSDuzen(
        #"⟨b⟩(NG|WD|Wikidata|Wikipedia|Commons|[a-z]{2}wiki|föy⟨w⟩*|birincil|ikincil|envanter⟨w⟩*|data|vision|oturum⟨w⟩*|HTTP|URL|P\d{2,}|Q\d{3,}|[KSDE]\d{1,2}|C\d{3})⟨b⟩|⟨b⟩wiki⟨b⟩|⟨b⟩Parti \d|erişil⟨w⟩*|⟨b⟩p\.\s?\d|kaynak betim⟨w⟩*|\.md⟨b⟩|§|https?:"#,
        i: true)
    private static let kaynakKalibi = JSDuzen(
        #"[^.;:!?]{0,60}?⟨b⟩(betimlediği|betimlediğine|betimine|betimlemesine|kaydına|föyüne|föyünün)\s*(gibi|göre)?[:,]?\s+"#, i: true)
    private static let cumleAyraci = JSDuzen(#"(?<=[.!?])\s+(?=["“(]?[A-ZÇĞİÖŞÜ0-9])"#)
    private static let ilkKucuk = JSDuzen(#"^\s*([a-zçğıöşü])"#)

    private static func say(_ s: String, _ h: Character) -> Int { s.reduce(0) { $0 + ($1 == h ? 1 : 0) } }

    static func cumleleriSuz(_ metin: String) -> String {
        let c = cumleAyraci.bol(kaynakKalibi.degistir(metin, ""))
            .filter { !JSMetin.kirp($0).isEmpty && !meta.var_($0) && say($0, "(") == say($0, ")") }
        return ilkKucuk.degistir(c.joined(separator: " "), ilkTek: true) { JSMetin.buyuk($0[1]) }
    }

    private static let tekDiyez = JSDuzen(#"^#\s"#)
    private static let ustBilgi = JSDuzen(#"^\*\*(Eser|Ön koşul|Standart|Kaynak)"#, i: true)
    private static let baslik = JSDuzen(#"^#{2,}\s+(.*)$"#)
    private static let kimlik = JSDuzen("kimlik", i: true)
    private static let basNo = JSDuzen(#"^\d+[.)]\s*"#)
    private static let parantez = JSDuzen(#"\s*\([^)]*\)"#)
    private static let kaynakKuyrugu = JSDuzen(#"\s*[—–-]\s*[^—–-]*⟨b⟩(NG|WD|wiki|föy)⟨b⟩.*$"#, i: true)
    private static let listeSatiri = JSDuzen(#"^\s*([-*]|\d+[.)])\s"#)
    private static let tablo = JSDuzen(#"^\s*\|"#)
    private static let onEk = JSDuzen(#"^(\s*(?:[-*]|\d+[.)])\s+)"#)
    private static let kod = JSDuzen("`[^`]*`")
    private static let kanit = JSDuzen(#"\s*\[[CKSDE]\d{1,4}\]"#)
    private static let not1 = JSDuzen(#"\s*\((belirsiz|tartışma|yorum|karşılaştırma)[^()]*\)"#, i: true)
    private static let not2 = JSDuzen(#"\s*\((?:[ABCDE](?:\s*[\/–-]\s*[ABCDE])?)\)"#)
    private static let not3 = JSDuzen(#"\s*\([^()]*oturum[^()]*\)\.?"#, i: true)
    private static let noktalamaOnu = JSDuzen(#"\s+([.,;:])"#)
    private static let ikiBosluk = JSDuzen(#"(\S) {2,}"#)
    private static let bosSatir = JSDuzen(#"^[\s.,;:—–-]*$"#)

    /// `temizle(md)` (İş 185, 187): modelin çalışma notları ayıklanır (kanıt etiketleri, (belirsiz)/(yorum) notları,
    /// kaynak/katalog cümleleri, "X'in betimlediği gibi:" kalıpları, kod); kimlik/kaynak/etkinlik… bölümleri atlanır.
    public static func temizle(_ md: String) -> String {
        var bolumler: [String] = []
        var atlaKipi = ""
        for s in md.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n") {
            if tekDiyez.var_(s) || ustBilgi.var_(s) { continue }
            if let b = baslik.ilk(s) {
                atlaKipi = !atla.var_(b[1]) ? "" : kimlik.var_(b[1]) ? "liste" : "tam"
                if atlaKipi.isEmpty {
                    bolumler.append("## " + kaynakKuyrugu.degistir(parantez.degistir(basNo.degistir(b[1], ""), ""), ""))
                }
                continue
            }
            if atlaKipi == "tam" || (atlaKipi == "liste" && listeSatiri.var_(s)) { continue }
            if tablo.var_(s) { continue }
            let on = onEk.ilk(s)?[0] ?? ""
            var g = (s as NSString).substring(from: (on as NSString).length)
            for (r, y) in [(kod, ""), (kanit, ""), (not1, ""), (not2, ""), (not3, "")] { g = r.degistir(g, y) }
            g = JSMetin.kirp(ikiBosluk.degistir(noktalamaOnu.degistir(cumleleriSuz(g), "$1"), "$1 "))
            if g.isEmpty || bosSatir.var_(g) { continue }
            bolumler.append(on + g)
        }
        // boş kalan alt başlıklar atılır
        return bolumler.enumerated().filter { i, x in
            !x.hasPrefix("## ") || (i + 1 < bolumler.count && !bolumler[i + 1].hasPrefix("## "))
        }.map(\.element).joined(separator: "\n")
    }

    // MARK: Markdown → HTML

    private static let kodS = JSDuzen("`([^`]+)`")
    private static let kalin = JSDuzen(#"\*\*([^*]+)\*\*"#)
    private static let italik = JSDuzen(#"(^|[^*])\*([^*\s][^*]*)\*"#)
    private static let kanitS = JSDuzen(#"\[([CKS]\d{1,4})\]"#)

    /// `satirIci(metin)`: kaçış, `kod`, **kalın**, *italik*, [C012] kanıt etiketi
    public static func satirIci(_ metin: String) -> String {
        var s = JSMetin.kacis(metin)
        s = kodS.degistir(s, "<code>$1</code>")
        s = kalin.degistir(s, "<b>$1</b>")
        s = italik.degistir(s, "$1<i>$2</i>")
        s = kanitS.degistir(s, "<sup class=\"drs-kanit\" data-kanit=\"$1\">$1</sup>")
        return s
    }

    private static func tabloSatiri(_ s: String) -> [String] {
        var t = JSMetin.kirp(s)
        if t.hasPrefix("|") { t.removeFirst() }
        if t.hasSuffix("|") { t.removeLast() }
        return t.components(separatedBy: "|").map(JSMetin.kirp)
    }

    private static let mdBaslik = JSDuzen(#"^(#{1,6})\s+(.*)$"#)
    private static let ul = JSDuzen(#"^\s*[-*]\s+"#)
    private static let ol = JSDuzen(#"^\s*\d+[.)]\s+"#)
    private static let hr = JSDuzen(#"^-{3,}\s*$"#)
    private static let ayracSatiri = JSDuzen(#"^[\s|:-]+$"#)
    private static let blokBasi = JSDuzen(#"^(#{1,6}\s|\s*[-*]\s+|\s*\d+[.)]\s+|\||>|-{3,}\s*$)"#)
    private static let alintiBasi = JSDuzen(#"^>\s?"#)

    /// `mdHtml(md, { ilkBaslikYok })`: derslerde geçen yapılar (başlık, paragraf, liste, tablo, çizgi, alıntı)
    public static func mdHtml(_ md: String, ilkBaslikYok: Bool = true) -> String {
        let satirlar = md.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        var cikti: [String] = []
        var i = 0
        var ilk = ilkBaslikYok
        func liste(_ desen: JSDuzen, _ etiket: String) {
            var ogeler: [String] = []
            while i < satirlar.count && desen.var_(satirlar[i]) {
                ogeler.append(desen.degistir(satirlar[i], ilkTek: true) { _ in "" })
                i += 1
            }
            cikti.append("<\(etiket)>" + ogeler.map { "<li>\(satirIci($0))</li>" }.joined() + "</\(etiket)>")
        }
        while i < satirlar.count {
            let s = satirlar[i]
            if JSMetin.kirp(s).isEmpty {
                i += 1
            } else if let b = mdBaslik.ilk(s) {
                i += 1
                let n = (b[1] as NSString).length
                if n == 1 && ilk { ilk = false } else {
                    let h = min(4, n + 1)
                    cikti.append("<h\(h)>\(satirIci(b[2]))</h\(h)>")
                }
            } else if ul.var_(s) {
                liste(ul, "ul")
            } else if ol.var_(s) {
                liste(ol, "ol")
            } else if hr.var_(s) {
                cikti.append("<hr>")
                i += 1
            } else if s.hasPrefix("|") {
                var t: [String] = []
                while i < satirlar.count && satirlar[i].hasPrefix("|") { t.append(satirlar[i]); i += 1 }
                let ayrac = t.count > 1 && ayracSatiri.var_(t[1])
                let govde = (ayrac ? Array(t.dropFirst(2)) : t).map { r in
                    "<tr>" + tabloSatiri(r).map { "<td>\(satirIci($0))</td>" }.joined() + "</tr>"
                }
                let bas = ayrac ? "<thead><tr>" + tabloSatiri(t[0]).map { "<th>\(satirIci($0))</th>" }.joined() + "</tr></thead>" : ""
                cikti.append("<div class=\"drs-tablo\"><table>\(bas)<tbody>\(govde.joined())</tbody></table></div>")
            } else if s.hasPrefix(">") {
                var a: [String] = []
                while i < satirlar.count && satirlar[i].hasPrefix(">") {
                    a.append(alintiBasi.degistir(satirlar[i], ilkTek: true) { _ in "" })
                    i += 1
                }
                cikti.append("<blockquote>\(satirIci(a.joined(separator: " ")))</blockquote>")
            } else {
                var p: [String] = []
                while i < satirlar.count && !JSMetin.kirp(satirlar[i]).isEmpty && !blokBasi.var_(satirlar[i]) {
                    p.append(JSMetin.kirp(satirlar[i]))
                    i += 1
                }
                if p.isEmpty { i += 1 } // sitede bu satırda döngü takılırdı; olmayan bir durum, yine de ilerle
                cikti.append("<p>\(satirIci(p.joined(separator: " ")))</p>")
            }
        }
        return cikti.joined(separator: "\n")
    }
}

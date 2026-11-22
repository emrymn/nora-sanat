// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (pekistir 'bolum', kartCiz, konuTanismaGoster, kartiBitir, sergiyeEkle,
// grupOzeti, bolumOzeti, seviyeTamamHtml, tamamlananDonem, pkUst, kipKisa), js/ekranlar/ortak.js (ust),
// css/app.css (.ust, .ust-yazi, .pk-ust, .ozet, .ozet .ad, .grup-ozet, .bolum-sonuc, .sergi-duvar, .sergi-asilar, .asi*,
// .sergi-isik, .sonuc-alt, .seviye-tamam, .st-*, .skor*, .yol*, .durak-nokta, .durak-ad, .gecis*, .sonuc-harita) @ a866b86
// Sitede bölüm turu pekiştirme ekranında oynar (`#/pekistir/bolum/<id>/<seviye>`): tanışma ve sorular Çalış'ın yerli
// `TanismaGorunumu` / `KartGorunumu`'yla aynen çizilir; tur sonu (grup tamam, sergi, seviye tamam) burada.
import NoraCekirdek
import SwiftUI

/// Bir durağın süren turu. Tur ilerlemeye `noraYolculuk-<id>` olarak yazılır (yarım kalırsa sürer).
@MainActor @Observable
final class BolumOyunu {
    let durak: YolculukDuragi
    let katalog: SiteKatalogu
    let veri: PekistirmeVerileri
    private(set) var bolum: BolumTuru
    private(set) var ilerleme: Ilerleme
    /// Tanışma ve soru ekranları için çizim modeli (eylemler buraya döner)
    let model = PekistirmeModeli()
    var hata: String?
    /// Haritadaki bütün duraklar (dönem kutlaması için; `tamamlananDonem`)
    var haritaDuraklari: [YolculukDuragi]?
    private var mesgul = false
    private var beklenen: JSONDeger?
    /// CI provası: ilerleme yalnız bellekte değişir
    private let kalici: Bool
    static func alan(_ id: String) -> String { "noraYolculuk-" + id }

    init(durak: YolculukDuragi, katalog: SiteKatalogu, veri: PekistirmeVerileri, bolum: BolumTuru, ilerleme: Ilerleme, kalici: Bool) {
        self.durak = durak
        self.katalog = katalog
        self.veri = veri
        self.bolum = bolum
        self.ilerleme = ilerleme
        self.kalici = kalici
        beklenen = ilerleme.ayar(Self.alan(durak.id))
        model.katalog = katalog
        model.veri = veri
        model.turBasligi = bolum.baslik(durak.ad)
        model.tanismaYazilari = { [weak self] tur in
            guard let self else { return ("", "", "", "") }
            let t = tur.tanisma
            let sonraki = t.flatMap { t in t.sira.indices.contains(t.konum + 1) ? self.katalog.harita[t.sira[t.konum + 1]]?.ad : nil }
            return self.bolum.tanismaYazilari(durakAdi: self.durak.ad, sonrakiAd: sonraki)
        }
        model.disEylem = { [weak self] e in await self?.yap(e) }
        esitle()
    }

    /// Turu başlatır ya da aynı seviyenin yarım turunu sürdürür (`pekistir(… { yeni })`)
    static func baslat(durak: YolculukDuragi, seviye: BolumSeviyesi, katalog: SiteKatalogu, veri: PekistirmeVerileri) async throws -> BolumOyunu {
        let alan = alan(durak.id)
        var yeni: BolumTuru?
        let il = try await IlerlemeKoprusu.shared.degistir { il in
            if let metin = il.ayar(alan)?.metin, let eski = try? JSONDecoder().decode(BolumTuru.self, from: Data(metin.utf8)),
               eski.seviye == seviye, !eski.tur.bitti {
                yeni = eski
                return
            }
            let tur = BolumTuru(durak: durak, seviye: seviye, katalog: katalog, veri: veri, il: &il)
            il.ayarla(alan, tur.tur.bitti ? nil : .metin(String(decoding: try JSONEncoder().encode(tur), as: UTF8.self)))
            yeni = tur
        }
        guard let yeni else { throw IlerlemeKoprusu.Hata.cakisma }
        return BolumOyunu(durak: durak, katalog: katalog, veri: veri, bolum: yeni, ilerleme: il, kalici: true)
    }

    private func esitle() {
        model.ilerleme = ilerleme
        model.kayit = bolum.tur
        model.turAcik = true
    }

    func yap(_ e: PekistirmeModeli.DisEylem) async {
        let k = katalog, v = veri
        switch e {
        case .cevapla(let secim):
            let kura = Double.random(in: 0..<1)
            if await yaz({ b, il in b.cevapla(secim, katalog: k, il: &il, rastgele: { kura }) }), let sonuc = bolum.tur.kart?.sonuc {
                let acik = Titresim.acik(ilerleme)
                if sonuc { Titresim.dogru(acik: acik) } else { Titresim.yanlis(acik: acik) }
            }
        case .sonraki, .tanismaGec: await yaz { b, il in b.ilerle(katalog: k, veri: v, il: &il) }
        case .tanismaGeri: await yaz { b, il in b.tanismaGeri(katalog: k, veri: v, il: il) }
        case .baskaEser: await yaz { b, il in b.baskaEser(katalog: k, il: il) }
        }
    }

    #if DEBUG && targetEnvironment(simulator)
    /// CI provası: istenen ekrana kadar kendi oynar (yerli tarafta yalnız bellekte)
    func prova(_ ad: String) async {
        let k = katalog, v = veri
        for _ in 0..<350 {
            let t = bolum.tur
            if t.bitti || (ad == "tanisma" && t.tanismaBekliyor) { break }
            if let kart = t.kart, kart.tanisma == nil, !t.tanismaBekliyor {
                if ad == "soru" && kart.sonuc == nil { break }
                if ad == "cevap" && kart.sonuc != nil { break }
                if kart.sonuc == nil {
                    let dogru = kart.ikinci ? katalog.harita[kart.resim.id]?.akim : kart.dogru
                    await yaz { b, il in b.cevapla(dogru, katalog: k, il: &il, rastgele: { 0.5 }) }
                    continue
                }
            }
            await yaz { b, il in b.ilerle(katalog: k, veri: v, il: &il) }
        }
    }
    #endif

    @discardableResult
    private func yaz(_ islem: (inout BolumTuru, inout Ilerleme) -> Void) async -> Bool {
        guard !mesgul else { return false }
        if !kalici {
            var b = bolum, il = ilerleme
            islem(&b, &il)
            bolum = b; ilerleme = il; esitle()
            return true
        }
        mesgul = true
        defer { mesgul = false }
        let alan = Self.alan(durak.id)
        let once = bolum, bekle = beklenen
        do {
            var yeni: BolumTuru?
            let il = try await IlerlemeKoprusu.shared.degistir { il in
                guard il.ayar(alan) == bekle else { throw IlerlemeKoprusu.Hata.cakisma }
                var b = once
                islem(&b, &il)
                il.ayarla(alan, b.tur.bitti ? nil : .metin(String(decoding: try JSONEncoder().encode(b), as: UTF8.self)))
                yeni = b
            }
            if let yeni { bolum = yeni }
            ilerleme = il
            beklenen = il.ayar(alan)
            hata = nil
            esitle()
            return true
        } catch {
            hata = "İlerleme kaydedilemedi. Haritaya dönüp yeniden dene."
            return false
        }
    }
}

/// Bölüm turunun ekranı: tanışma → sorular → tur sonu
struct BolumTuruEkrani: View {
    let oyun: BolumOyunu
    let vakit: String
    /// Haritaya dön (`#/harita`)
    let haritaya: () -> Void
    /// Aynı durakta yeni tur (sıradaki grup, sonraki salon, tekrar)
    let yeniTur: (BolumSeviyesi) -> Void
    let adreseGit: (String) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let tur = oyun.bolum.tur
        Group {
            if tur.tanismaBekliyor || tur.kart?.tanisma != nil {
                TanismaGorunumu(model: oyun.model, tur: tur, kapat: haritaya)
            } else if let k = tur.kart {
                KartGorunumu(model: oyun.model, tur: tur, k: k, kapat: haritaya, disAdreseGit: adreseGit)
                    .id("\(tur.gorunenKonum)|\(k.resim.eser.anahtar)|\(k.ikinci)")
            } else if oyun.bolum.seviye.grup != nil {
                GrupOzeti(oyun: oyun, haritaya: haritaya, yeniTur: yeniTur)
            } else if let r = oyun.bolum.sonuc {
                BolumSonucuGorunumu(oyun: oyun, sonuc: r, vakit: vakit, haritaya: haritaya, yeniTur: yeniTur)
            } else {
                // Tanıtım turu bitti: site haritaya döner (`location.replace('#/harita')`)
                Color(tema.renkler.zemin).onAppear(perform: haritaya)
            }
        }
        .overlay(alignment: .bottom) {
            if let hata = oyun.hata {
                Text(hata).font(Yazi.okuma(16)).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(tema.renkler.yuzey))).padding(12)
            }
        }
        .background(Color(tema.renkler.zemin).ignoresSafeArea())
        .foregroundStyle(Color(tema.renkler.murekkep))
    }
}

// MARK: Ortak

/// `ust(baslik, '#/harita', { ustEtiket })`: geri düğmesi, vurgulu etiket, 40 px başlık (`.ust h1`; `.pk-ust` sarmalı yok)
private struct TurSonuUst: View {
    let etiket: String
    let baslik: String
    let boyut: CGFloat
    let geri: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: geri) { GaleriIkon(simge: .geri, boyut: 22, kalinlik: 1.4) }
                .buttonStyle(YuvarlakDugme())
                .accessibilityLabel("Haritaya dön")
                .padding(.top, 16)
            VStack(alignment: .leading, spacing: 4) {
                VurguEtiket(etiket)
                Text(baslik).font(Yazi.serif(boyut, stil: .largeTitle)).cssSatir(.serif, boyut, boyut)
                    .foregroundStyle(Color(tema.renkler.murekkep))
                    .shadow(color: Color(tema.renkler.zemin).opacity(0.6), radius: 12, y: 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, -12)
    }
}

/// `.hp-basla`: 58 yükseklik, hap, `--pirinc` zemin, `--pirinc-yazi` 600 17
private struct PirincDugme: View {
    let ad: String
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema
    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 10) {
                Text(ad).font(Yazi.sans(17, agirlik: 600))
                GaleriIkon(simge: .ileri, boyut: 20, kalinlik: 1.9)
            }
            .foregroundStyle(Color(tema.renkler.pirincYazi))
            .padding(.horizontal, 26).frame(minHeight: 58)
            .background(Capsule().fill(Color(tema.renkler.pirinc)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: Grup sonu (`grupOzeti`)

private struct GrupOzeti: View {
    let oyun: BolumOyunu
    let haritaya: () -> Void
    let yeniTur: (BolumSeviyesi) -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let b = oyun.bolum
        let grup = b.seviye.grup ?? 0
        let orta = b.seviye.anahtar == "orta"
        let gruplar = oyun.durak.gruplar
        let gorulen = Set(BolumKurallari.gorulenGruplar(BolumKurallari.kayit(oyun.ilerleme, oyun.durak.id), orta: orta, adet: gruplar.count))
        let sonraki = gruplar.indices.first { !gorulen.contains($0) }
        let svAd = orta ? "Orta" : "Kolay"
        ScrollView {
            VStack(spacing: 0) {
                TurSonuUst(etiket: "Grup tamam", baslik: b.baslik(oyun.durak.ad), boyut: 40, geri: haritaya)
                // `.ozet`: 40 üst boşluk, ortalı, 6 aralık
                VStack(spacing: 6) {
                    VurguEtiket("\(oyun.durak.ad) · \(grup + 1). grup")
                    Text("\(b.tur.oturum.ilkDogru) / \(b.tur.oturum.ilkToplam)").font(Yazi.serif(64)).monospacedDigit()
                        .cssSatir(.serif, 64, 64)
                    Text("doğru").font(Yazi.sans(14)).foregroundStyle(Color(r.murekkep2))
                    Text(sonraki.map { "Sırada \($0 + 1). grup var." } ?? "Bütün gruplarla tanıştın; \(svAd) bütün durağı soracak.")
                        .font(Yazi.okuma(19, italik: true)).multilineTextAlignment(.center).padding(.top, 8)
                    PirincDugme(ad: sonraki.map { "\($0 + 1). grupla tanış" } ?? "\(svAd)’\(orta ? "ya" : "a") başla") {
                        if let s = sonraki { yeniTur(.tanitim(orta: orta, grup: s)) } else { yeniTur(orta ? .orta : .kolay) }
                    }
                    .padding(.top, 14)
                    Button("Haritaya dön", action: haritaya).buttonStyle(HapDugme()).padding(.top, 14)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
            .padding(.horizontal, BenOlcu.yan).padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("grup-ozet")
    }
}

// MARK: Bölüm sonucu (`bolumOzeti`): sergi duvarı, seviye tamam, skor, salonlar, geçişler

private struct BolumSonucuGorunumu: View {
    let oyun: BolumOyunu
    let sonuc: BolumSonucu
    let vakit: String
    let haritaya: () -> Void
    let yeniTur: (BolumSeviyesi) -> Void
    @Environment(TemaDeposu.self) private var tema

    private var r: TemaRenkleri { tema.renkler }
    private var sv: String { oyun.bolum.seviye.anahtar }
    private var svAd: String { oyun.bolum.seviye.ad }
    private var sonrakiSv: String? { sv == "kolay" ? "orta" : sv == "orta" ? "zor" : nil }
    private static let ad = ["kolay": "Kolay", "orta": "Orta", "zor": "Zor"]

    var body: some View {
        ScrollViewReader { vekil in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TurSonuUst(etiket: "\(sonuc.gecti ? "Sergi açıldı" : "Sergi hazırlanıyor") · \(svAd)", baslik: oyun.durak.ad, boyut: 40,
                               geri: haritaya)
                    VStack(alignment: .leading, spacing: 22) {
                        if !oyun.bolum.sergi.isEmpty { sergiDuvari }
                        VStack(alignment: .leading, spacing: 36) {
                            seviyeTamam.id("seviye-tamam")
                            skor
                            yol
                            menu
                        }
                    }
                    .padding(.top, 18)
                }
                .padding(.horizontal, BenOlcu.yan).padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            #if DEBUG && targetEnvironment(simulator)
            .task {
                if YolculukProva.ad == "seviye-tamam" {
                    try? await Task.sleep(for: .milliseconds(300))
                    vekil.scrollTo("seviye-tamam", anchor: .top)
                }
            }
            #endif
        }
        .accessibilityIdentifier("bolum-ozet")
    }

    // `.sergi-duvar`: --surface, 26 4 18 iç boşluk, üstte 3 pt ray; asılar ortalı, 18 / 12 aralık, 84 genişlik
    private var sergiDuvari: some View {
        let l = oyun.bolum.sergi
        return ZStack(alignment: .top) {
            RadialGradient(colors: [Color(r.vurgu).opacity(sonuc.gecti ? 0.28 : 0.11), .clear], center: .top, startRadius: 0, endRadius: 220)
                .scaleEffect(x: 0.76, y: 1.4, anchor: .top)
            Capsule().fill(LinearGradient(colors: [Color(r.kenar), Color(r.vurgu), Color(r.kenar)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 3).padding(.horizontal, 10).padding(.top, 10)
            OrtaliAkis(yatay: 12, dikey: 18) {
                ForEach(Array(l.enumerated()), id: \.offset) { i, e in asi(i, e) }
            }
            .padding(.top, 26).padding(.bottom, 18).padding(.horizontal, 4)
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(r.kenar), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bu bölümde karşına çıkan eserler")
    }

    /// `.asi`: ip (10–28 pt), 4:5 yaldız çerçeve (vurgu degradesi, 4 pt), eğim; tanınmayan soluk ve "?" pullu
    private func asi(_ i: Int, _ e: BolumTuru.AsiliEser) -> some View {
        let egim = e.dogru ? Double((i * 37) % 5 - 2) : (i % 2 == 1 ? 7 : -8)
        let ip = CGFloat(10 + ((i * 13) % 4) * 6)
        let url = oyun.katalog.gorselAdresi(e.resim.eser, genislik: 240, kotuler: oyun.ilerleme.kotuGorseller)
        return VStack(spacing: 0) {
            Rectangle().fill(LinearGradient(colors: [Color(r.vurgu), Color(r.vurgu).opacity(0.3)], startPoint: .top, endPoint: .bottom))
                .frame(width: 1, height: ip)
            GeometryReader { g in
                UzakGorsel(url: url, icerik: .fill)
                    .frame(width: g.size.width, height: g.size.height)
                    .clipped()
            }
            .aspectRatio(4 / 5, contentMode: .fit)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 2).fill(LinearGradient(stops: [.init(color: Color(r.vurguAcik), location: 0),
                                                                                       .init(color: Color(r.vurgu), location: 0.55),
                                                                                       .init(color: Color(r.vurguKoyu), location: 1)],
                                                                               startPoint: .topLeading, endPoint: .bottomTrailing)))
            .shadow(color: .black.opacity(0.6), radius: 9, y: 10)
            .saturation(e.dogru ? 1 : 0.15).brightness(e.dogru ? 0 : -0.3)
            .overlay(alignment: .bottomTrailing) {
                if !e.dogru {
                    Text("?").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(Color(r.vurguYazi))
                        .frame(width: 20, height: 20).background(Circle().fill(Color(r.yanlis)))
                        .overlay(Circle().strokeBorder(Color(r.yuzey), lineWidth: 2).padding(-2))
                        .offset(x: 6, y: 6)
                }
            }
        }
        .frame(width: 84)
        .rotationEffect(.degrees(egim * 0.5), anchor: UnitPoint(x: 0.5, y: -0.1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(oyun.katalog.harita[e.resim.id]?.ad ?? ""): \(e.dogru ? "tanıdın" : "tanıyamadın")")
    }

    /// `seviyeTamamHtml`: ışık, 148 pt madalyon (durağın sembolü, halka yıldıza göre), etiket, 36 px başlık, 36 px yıldızlar
    private var seviyeTamam: some View {
        let d = oyun.durak
        return VStack(spacing: 8) {
            // halka: 64'lük viewBox'ta r = 29, çizgi 2.5 (148 pt'ye ölçekli)
            let cizgi: CGFloat = 2.5 * 148 / 64
            ZStack {
                Group {
                    Circle().fill(Color(r.pirinc).opacity(0.08))
                    Circle().stroke(Color(r.murekkep).opacity(0.2), lineWidth: cizgi)
                    if sonuc.yildizSonra > 0 {
                        Circle().trim(from: 0, to: CGFloat(sonuc.yildizSonra) / 3)
                            .stroke(Color(r.pirinc), style: StrokeStyle(lineWidth: cizgi, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 148 * 58 / 64, height: 148 * 58 / 64)
                UzakGorselSaydam(url: haritaGorseli("sembol_\(d.bolge)_\(d.sembol)_\(vakit)"))
                    .frame(width: 148 * 0.46, height: 148 * 0.62)
                    .shadow(color: .black.opacity(0.5), radius: 5, y: 6)
            }
            .frame(width: 148, height: 148)
            .padding(.bottom, 8)
            VurguEtiket("\(svAd) \(sonuc.gecti ? "seviye tamam" : "· az kaldı")")
            Text(d.ad).font(Yazi.serif(36)).cssSatir(.serif, 36, 37.8).multilineTextAlignment(.center)
            UcYildiz(n: sonuc.yildizSonra, boyut: 36, aralik: 10, bos: Color(r.murekkep).opacity(0.2), dolu: Color(r.pirinc))
                .padding(.top, 8)
            if let donem = tamamlananDonem {
                HStack(spacing: 10) {
                    OnayIsareti(boyut: 18).foregroundStyle(Color(r.pirinc))
                    (Text("\(donem) tamamlandı").font(Yazi.sans(15, agirlik: 600)) + Text(" · bütün duraklar üç yıldız").font(Yazi.sans(15)))
                }
                .padding(.vertical, 12).padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(r.pirinc).opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(r.pirinc).opacity(0.45), lineWidth: 1))
                .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20).padding(.bottom, 24)
        .background(alignment: .top) {
            if sonuc.gecti {
                Circle().fill(RadialGradient(colors: [Color(r.pirinc).opacity(0.3), Color(r.pirinc).opacity(0)], center: .center,
                                             startRadius: 0, endRadius: 102))
                    .frame(width: 300, height: 300).offset(y: -30)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// `tamamlananDonem`: bu yıldızla dönemin bütün durakları üç yıldız olduysa dönemin adı
    private var tamamlananDonem: String? {
        guard sonuc.yeniGecti, sonuc.yildizSonra >= 3, let harita = oyun.haritaDuraklari else { return nil }
        let ayni = harita.filter { $0.bolge == oyun.durak.bolge }
        guard ayni.allSatisfy({ $0.acik && ($0.id == oyun.durak.id || $0.yildiz >= 3) }) else { return nil }
        return YolculukHaritasi.adlar[YolculukHaritasi.bolgeler.firstIndex(of: oyun.durak.bolge) ?? 0]
    }

    /// `.skor`: "Senin gözün", italik 56 px yüzde ve durum hapı, hedef çizgisi, izler, sayılar, not
    private var skor: some View {
        let t = oyun.bolum.tur.oturum
        let yuzde = Int((sonuc.oran * 100).rounded())
        let izler = oyun.bolum.sergi.isEmpty ? (0..<t.ilkToplam).map { $0 < t.ilkDogru } : oyun.bolum.sergi.map(\.dogru)
        let durumRenk = Color(sonuc.gecti ? r.dogru : r.yanlis)
        let metin = sonuc.gecti
            ? (sv == "orta" ? "Orta’yı geçtin: sıradaki bölümün yolu açıldı." : sv == "kolay" ? "Kolay’ı geçtin: Orta açıldı." : "Zor’u da geçtin: bu bölümü ustaca bitirdin.")
            : "Geçmek için %75 gerekiyor. Yanlış yaptıkların daha sık karşına çıkacak."
        return VStack(alignment: .leading, spacing: 0) {
            (Text("Senin gözün").font(Yazi.sans(12.5, agirlik: 600)).foregroundColor(Color(r.murekkep2))
             + Text(" · \(oyun.durak.ad) · \(svAd)").font(Yazi.sans(12.5, agirlik: 500)).foregroundColor(Color(r.murekkep3)))
            HStack {
                Text("%\(yuzde)").font(Yazi.serif(56, italik: true)).tracking(-1.68).monospacedDigit().cssSatir(.serif, 56, 56)
                Spacer()
                Text(sonuc.gecti ? "GEÇTİ" : "AZ KALDI").font(Yazi.sans(11, agirlik: 600)).tracking(1.76).foregroundStyle(durumRenk)
                    .padding(.horizontal, 12).padding(.vertical, 6).overlay(Capsule().strokeBorder(durumRenk, lineWidth: 1))
            }
            .padding(.top, 4)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(r.soluk)).frame(height: 2)
                    Capsule().fill(sonuc.gecti ? Color(r.vurgu) : Color(r.murekkep2)).frame(width: g.size.width * sonuc.oran, height: 4)
                    Circle().fill(Color(r.murekkep)).frame(width: 10, height: 10)
                        .shadow(color: Color(r.vurgu).opacity(0.4), radius: 4)
                        .offset(x: g.size.width * sonuc.oran - 5)
                    Rectangle().fill(Color(r.murekkep2)).frame(width: 1, height: 14).offset(x: g.size.width * BolumKurallari.gecme)
                    Text("Hedef %75").font(Yazi.sans(10.5, agirlik: 500)).tracking(0.63).foregroundStyle(Color(r.murekkep3))
                        .fixedSize().position(x: g.size.width * BolumKurallari.gecme, y: 18 + 6)
                }
            }
            .frame(height: 14).padding(.top, 18)
            HStack(alignment: .bottom, spacing: 9) {
                ForEach(Array(izler.enumerated()), id: \.offset) { _, ok in
                    RoundedRectangle(cornerRadius: 2).fill(ok ? Color(r.vurgu) : Color(r.yanlis)).frame(width: 4, height: ok ? 30 : 12)
                }
            }
            .frame(height: 30, alignment: .bottom).padding(.top, 40)
            HStack(spacing: 18) {
                sayi(t.ilkDogru, "doğru")
                sayi(t.ilkToplam - t.ilkDogru, "yanlış")
                sayi(t.ilkToplam, "eser")
            }
            .padding(.top, 10)
            Text(metin).font(Yazi.serif(22, italik: true)).cssSatir(.serif, 22, 28.6).padding(.top, 22)
        }
        .accessibilityElement(children: .combine)
    }

    private func sayi(_ n: Int, _ ad: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(n)").font(Yazi.okuma(18)).foregroundStyle(Color(r.murekkep))
            Text(ad).font(Yazi.sans(13, agirlik: 500)).foregroundStyle(Color(r.murekkep3))
        }
    }

    /// `.yol`: üç salon (I Kolay, II Orta, III Zor); geçilenler dolu, yeni açılan vurgulu, kilitliler kilitli
    private var yol: some View {
        let sira = BolumKurallari.seviyeler
        let yeni = sonuc.gecti ? sonrakiSv : nil
        let burada = max(0, sira.firstIndex(of: sv) ?? 0)
        let hedef = yeni.flatMap { sira.firstIndex(of: $0) } ?? burada
        return GeometryReader { g in
            let w = g.size.width / 3
            ZStack(alignment: .topLeading) {
                Path { p in p.move(to: CGPoint(x: w / 2, y: 11)); p.addLine(to: CGPoint(x: g.size.width - w / 2, y: 11)) }
                    .stroke(Color(r.soluk), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                Rectangle().fill(Color(r.vurgu)).frame(width: CGFloat(hedef) * w, height: 2).offset(x: w / 2, y: 10)
                HStack(spacing: 0) {
                    ForEach(sira.indices, id: \.self) { i in
                        let x = sira[i]
                        let durum = i < sonuc.yildizSonra ? "gecti" : x == yeni ? "acildi" : "kilitli"
                        VStack(spacing: 0) {
                            ZStack {
                                Circle().fill(durum == "gecti" ? Color(r.vurgu) : Color(r.zemin))
                                Circle().strokeBorder(durum == "gecti" ? Color(r.vurgu) : durum == "acildi" ? Color(r.vurguAcik) : Color(r.murekkep3), lineWidth: 2)
                                if durum == "kilitli" { GaleriIkon(simge: .kilit, boyut: 11, kalinlik: 1.8).foregroundStyle(Color(r.murekkep3)) }
                            }
                            .frame(width: 22, height: 22).padding(.bottom, 6)
                            Text(["I", "II", "III"][i]).font(Yazi.serif(22))
                            Text((Self.ad[x] ?? x).uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(11, agirlik: 600)).tracking(1.54)
                                .foregroundStyle(Color(r.murekkep2))
                            Text(i == burada ? "Buradasın" : durum == "acildi" ? "Açıldı" : durum == "gecti" ? "Geçildi" : "Kapalı")
                                .font(Yazi.sans(12)).foregroundStyle(Color(r.murekkep3)).padding(.top, 2)
                        }
                        .frame(width: w)
                    }
                }
            }
        }
        .frame(height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Salonlar")
    }

    /// `.sonuc-menu`: geçtiyse "… salonuna geç", geçemediyse "Tekrar dene"; altında "Haritaya dön"
    private var menu: some View {
        VStack(spacing: 8) {
            if sonuc.gecti, let s = sonrakiSv {
                gecis("\(Self.ad[s] ?? s) salonu açıldı", "\(Self.ad[s] ?? s) salonuna geç") { yeniTur(s == "orta" ? .orta : .zor) }
            }
            if !sonuc.gecti {
                gecis("Eserler yeniden asılsın", "Tekrar dene") { yeniTur(oyun.bolum.seviye) }
            }
            Button(action: haritaya) {
                HStack(spacing: 8) {
                    Image(systemName: "map").font(.system(size: 15, weight: .light))
                    Text("Haritaya dön").underline(color: Color(r.kenar))
                }
                .font(Yazi.sans(14)).foregroundStyle(Color(r.murekkep2)).padding(.vertical, 10).padding(.horizontal, 14)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    /// `.gecis`: vurgu kenarlı hap; solda küçük üst yazı (10.5, vurgu-açık) ve 23 px ad, sağda 46 pt ok dairesi
    private func gecis(_ ust: String, _ ad: String, _ eylem: @escaping () -> Void) -> some View {
        Button(action: eylem) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ust.uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(10.5, agirlik: 600)).tracking(1.68)
                        .foregroundStyle(Color(r.vurguAcik))
                    Text(ad).font(Yazi.serif(23)).foregroundStyle(Color(r.murekkep))
                }
                Spacer(minLength: 0)
                GaleriIkon(simge: .ileri, boyut: 20, kalinlik: 1.7).foregroundStyle(Color(r.vurguAcikYazi))
                    .frame(width: 46, height: 46).background(Circle().fill(Color(r.vurguAcik)))
            }
            .padding(.leading, 26).padding(.trailing, 14).padding(.vertical, 14)
            .overlay(Capsule().strokeBorder(Color(r.vurgu).opacity(0.55), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Saydam PNG/WebP sembol: zeminsiz (UzakGorsel'in yüzey zemini olmadan)
struct UzakGorselSaydam: View {
    let url: URL?
    @Environment(\.displayScale) private var olcek
    @State private var resim: UIImage?
    var body: some View {
        GeometryReader { g in
            let piksel = Int((max(g.size.width, g.size.height) * olcek).rounded(.up))
            ZStack {
                if let resim { Image(uiImage: resim).resizable().aspectRatio(contentMode: .fit).frame(width: g.size.width, height: g.size.height) }
            }
            .frame(width: g.size.width, height: g.size.height)
            .task(id: "\(url?.absoluteString ?? "")|\(piksel)") {
                guard piksel > 0 else { return }
                if let hazir = GorselCozucu.shared.bellekte(url, piksel) { resim = hazir; return }
                resim = await GorselCozucu.shared.resim(url, piksel: piksel)
            }
        }
    }
}

/// Satır satır akan, satırları ortalanan düzen (`display: flex; flex-wrap: wrap; justify-content: center`)
struct OrtaliAkis: Layout {
    var yatay: CGFloat
    var dikey: CGFloat

    private func satirlar(_ en: CGFloat, _ alt: Subviews) -> [[(Int, CGSize)]] {
        var l: [[(Int, CGSize)]] = [[]]
        var x: CGFloat = 0
        for (i, a) in alt.enumerated() {
            let b = a.sizeThatFits(.unspecified)
            if x > 0 && x + b.width > en { l.append([]); x = 0 }
            l[l.count - 1].append((i, b))
            x += b.width + yatay
        }
        return l
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let en = proposal.width ?? 320
        let l = satirlar(en, subviews)
        let boy = l.reduce(CGFloat(0)) { $0 + ($1.map(\.1.height).max() ?? 0) } + dikey * CGFloat(max(0, l.count - 1))
        return CGSize(width: en, height: boy)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for satir in satirlar(bounds.width, subviews) {
            let w = satir.map(\.1.width).reduce(0, +) + yatay * CGFloat(max(0, satir.count - 1))
            var x = bounds.minX + (bounds.width - w) / 2
            let h = satir.map(\.1.height).max() ?? 0
            for (i, b) in satir {
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(b))
                x += b.width + yatay
            }
            y += h + dikey
        }
    }
}

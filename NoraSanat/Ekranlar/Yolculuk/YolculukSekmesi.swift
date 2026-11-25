// Kaynak: sanat-atlasi js/ekranlar/harita.js (haritaSayfasi, durakHtml, madalyonHtml, siradakiIs, motifHtml, resimHtml,
// gecisHtml, yolcuHtml, yuru, konumaKaydir, kaydirmaIzle, kursRozetiHtml, olaylariBagla), js/harita.js (BOLGELER, W, H, ARA,
// sepyaSiniri, vakit), css/app.css (.harita-ust, .harita-ozet, .kurs-rozet*, .harita-vakit, .harita-zaman*, .harita-durak*,
// .durak-halka, .durak-yildizlar, .durak-kilit, .durak-etiket, .harita-gecis-yazi, .harita-gecis-yuzyil, .harita-gecis-cizgi,
// .harita-gecis-bilgi, .harita-resim.sepya) @ a866b86
import SwiftUI
import NoraCekirdek

/// T7: Yolculuk yerli sekme (G5 + G5b). DEBUG `-yalnizSite` ile site.
enum YolculukGecisi {
    static var sekmeler: Set<Sekme> {
        #if DEBUG
        if CommandLine.arguments.contains("-yalnizSite") { return [] }
        #endif
        return [.yolculuk]
    }
}

@MainActor @Observable
final class YolculukDeposu {
    let site = SiteVerisi()
    var katalog: SiteKatalogu?
    var ilerleme: Ilerleme?
    var dosyalar = [String: JSONDeger]()
    var veri = PekistirmeVerileri(ikonografi: nil, zorluk: nil)
    var duraklar = [YolculukDuragi]()
    var hata: String?

    func yukle() async {
        do {
            if katalog == nil {
                async let k = site.katalog()
                async let ek = site.veriler(["eser_zorluk.json", "tanima_notlari.json"])
                let dosya = await site.veriler(["harita.json", "harita_yolcu.json", "harita_patikalar.json", "harita_motifler.json",
                                                "ders_kaynaklari.json", "yuruyus.json", "konular_tr.json"])
                dosyalar = try dosya.mapValues(JSONDeger.coz)
                guard dosyalar["harita.json"] != nil else { throw URLError(.cannotDecodeContentData) }
                let e = await ek
                veri = PekistirmeVerileri(ikonografi: nil, zorluk: e["eser_zorluk.json"], tanima: e["tanima_notlari.json"])
                katalog = try await k
            }
            var il = try await IlerlemeKoprusu.shared.oku()
            #if DEBUG && targetEnvironment(simulator)
            if let ad = YolculukProva.ad {
                if ad == "durak" || YolculukProva.turlar.contains(ad) { YolculukProva.ornek(&il) }
                guncelle(il)
                return
            }
            #endif
            guncelle(il)
            // `haritaGorulen`: yeni açılan duraklar bir kez belirir
            let eski = ilerleme?[alan: "haritaGorulen"]?.dizi ?? []
            let yeni = duraklar.filter { $0.acik && !eski.contains(.metin($0.id)) }.map(\.id)
            if !yeni.isEmpty {
                await yaz { il in
                    var idler = il[alan: "haritaGorulen"]?.dizi?.compactMap(\.metin) ?? []
                    for id in yeni where !idler.contains(id) { idler.append(id) }
                    il[alan: "haritaGorulen"] = .dizi(idler.prefix(300).map(JSONDeger.metin))
                }
            }
        } catch { hata = "Yolculuk verileri okunamadı." }
    }

    func yaz(_ islem: (inout Ilerleme) -> Void) async {
        do { guncelle(try await IlerlemeKoprusu.shared.degistir(islem)) }
        catch { hata = "İlerleme kaydedilemedi. Yeniden dene." }
    }

    func guncelle(_ il: Ilerleme) {
        ilerleme = il
        if let katalog, let veri = dosyalar["harita.json"] {
            duraklar = YolculukHaritasi.kur(katalog, ilerleme: il, harita: veri, dersler: dosyalar["ders_kaynaklari.json"], yuruyus: dosyalar["yuruyus.json"])
        }
        hata = nil
    }

    /// "Buradasın": açık olup Orta'sı geçilmemiş ilk durak, yoksa son açık durak
    var simdiki: YolculukDuragi? { duraklar.first { $0.acik && !$0.gecti("orta") } ?? duraklar.last(where: \.acik) }
    var yolcu: YolculukDuragi? { duraklar.first { $0.acik && $0.id == ilerleme?[alan: "haritaYolcu"]?.metin } ?? simdiki }
    var kurs: KursBilgisi? {
        guard let katalog, let ilerleme else { return nil }
        return KursBilgisi(katalog: katalog, il: ilerleme, adlar: dosyalar["konular_tr.json"])
    }
}

struct YolculukSekmesi: View {
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = YolculukDeposu()
    @State private var oyun: BolumOyunu?
    @State private var yenile = 0
    @State private var tur = YolculukHaritasi.vakit(saat: Calendar.current.component(.hour, from: Date()))

    var body: some View {
        Group {
            if let hata = depo.hata, oyun == nil {
                ContentUnavailableView { Text(hata) } actions: {
                    Button("Yeniden dene") { Task { await depo.yukle() } }
                }
            } else if let oyun {
                BolumTuruEkrani(oyun: oyun, vakit: tur, haritaya: { haritayaDon() }, yeniTur: { sv in basla(oyun.durak, sv) },
                                adreseGit: { adreseGit($0) })
                    .id(ObjectIdentifier(oyun))
            } else if let k = depo.katalog, let il = depo.ilerleme {
                YolculukHaritaEkrani(depo: depo, katalog: k, il: il, tur: $tur,
                                     basla: { d, sv in basla(d, sv) }, adreseGit: { a, s in git(a, s) })
                    .id(yenile)
            } else {
                ProgressView("Yolculuk hazırlanıyor…").font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(tema.renkler.zemin).ignoresSafeArea())
        .foregroundStyle(Color(tema.renkler.murekkep))
        .task {
            await depo.yukle()
            #if DEBUG && targetEnvironment(simulator)
            await provaTuru()
            #endif
        }
        .onChange(of: kabuk.yerliAdres[.yolculuk], initial: true) { _, adres in
            if adres != nil { oyun = nil; kabuk.adresIslendi(.yolculuk) }
        }
        .onChange(of: kabuk.yenidenDokunma[.yolculuk]) { _, _ in oyun = nil; yenile += 1 }
    }

    private func haritayaDon() {
        oyun = nil
        Task { await depo.yukle(); yenile += 1 }
    }

    private func git(_ adres: String, _ sekme: Sekme) {
        kabuk.sec(sekme)
        Gezgin.shared.git(adres)
    }

    /// Turdaki bağlantılar (sanatçı, akım sayfası…) sitedeki adresine göre ilgili sekmede açılır
    private func adreseGit(_ adres: String) {
        if adres.hasPrefix("#/harita") { haritayaDon(); return }
        git(adres, SiteRotalari.sekme(adres) ?? .galeri)
    }

    /// Durak penceresindeki satırlar (`#/pekistir/bolum/<id>/<seviye>`)
    private func basla(_ d: YolculukDuragi, _ sv: BolumSeviyesi) {
        guard let k = depo.katalog else { return }
        let veri = depo.veri
        Task {
            do {
                let yeni = try await BolumOyunu.baslat(durak: d, seviye: sv, katalog: k, veri: veri)
                yeni.haritaDuraklari = depo.duraklar
                oyun = yeni
            } catch { depo.hata = "Tur başlatılamadı. Yeniden dene." }
        }
    }

    #if DEBUG && targetEnvironment(simulator)
    /// CI: tanışma, soru, cevap, grup sonu, sergi, seviye tamam (yerli tarafta yalnız bellekte; durak 4-1)
    private func provaTuru() async {
        guard let ad = YolculukProva.ad, YolculukProva.turlar.contains(ad), let k = depo.katalog, var il = depo.ilerleme,
              let d = depo.duraklar.first(where: { $0.id == "4-1" }) else { return }
        let sv: BolumSeviyesi = ad == "tanisma" || ad == "grup-sonu" ? .tanitim(orta: false, grup: 0) : .kolay
        let b = BolumTuru(durak: d, seviye: sv, katalog: k, veri: depo.veri, il: &il)
        let o = BolumOyunu(durak: d, katalog: k, veri: depo.veri, bolum: b, ilerleme: il, kalici: false)
        o.haritaDuraklari = depo.duraklar
        await o.prova(ad)
        oyun = o
        try? await Task.sleep(for: .seconds(4))
        YolculukProva.hazir(ad)
    }
    #endif
}

func haritaGorseli(_ ad: String) -> URL? {
    URL(string: "https://sanat-atlasi.pages.dev/gorseller/harita/\(ad).webp")
}

private struct DonemYerleri: PreferenceKey {
    static let defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) { value.merge(nextValue()) { $1 } }
}

private enum Pencere: Equatable {
    case durak(String), kurs, motif(String)
}

private struct YolculukHaritaEkrani: View {
    let depo: YolculukDeposu
    let katalog: SiteKatalogu
    let il: Ilerleme
    @Binding var tur: String
    let basla: (YolculukDuragi, BolumSeviyesi) -> Void
    let adreseGit: (String, Sekme) -> Void
    @Environment(TemaDeposu.self) private var tema
    @State private var pencere: Pencere?
    @State private var gorunenDonem: Int?
    @State private var ilkKonumKuruldu = false
    @State private var motifEser: Eser?
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var animasyonYeri: YolcuPatikasi.Nokta?
    @State private var animasyonOn = false
    @State private var yuruyus: Task<Void, Never>?
    /// DEBUG `-yolculukProva gecis`: Rönesans köprüsü ortaya kaydırılır (CI karşılaştırması)
    @State private var provaKaydir: String?
    private let bolgeler = YolculukHaritasi.bolgeler
    /// `BOLGELER[i].yuzyil`
    private static let yuzyillar = ["Antik çağdan XV. yüzyıla", "XV–XVI. yüzyıl", "XVII. yüzyıl", "XVII–XVIII. yüzyıl", "XVIII. yüzyıl",
                                    "XIX. yüzyılın ilk yarısı", "XIX. yüzyılın son çeyreği", "XIX. yüzyıl sonu – XX. yüzyıl başı", "XX. yüzyıl"]

    var body: some View {
        GeometryReader { g in
            let en = g.size.width
            ScrollViewReader { vekil in
                ScrollView {
                    VStack(spacing: 0) {
                        ust.padding(.horizontal, BenOlcu.yan).padding(.top, 6).padding(.bottom, 10)
                        ForEach(bolgeler.indices.reversed(), id: \.self) { i in
                            donem(i, en)
                                .background(GeometryReader { r in
                                    Color.clear.preference(key: DonemYerleri.self, value: [i: r.frame(in: .named("harita")).midY])
                                })
                            if i > 0 { gecis(i, en).id("gecis-\(bolgeler[i])") }
                        }
                        Color.clear.frame(height: 1).id("son")
                    }
                }
                .coordinateSpace(name: "harita")
                .scrollIndicators(.hidden)
                // Z3n (telefon: "haritada aşağıda boşluk var"): harita sitedeki gibi yüzen sekme çubuğunun arkasına
                // kadar iner. Kabuğun alt payı (çubuk yüksekliği) kaydırma alanını kısaltıyor, altta zemin rengi bir
                // şerit kalıyordu. Pay içerik kenar boşluğu olarak kalır: haritanın sonu yine çubuğun üstüne kayar.
                .contentMargins(.bottom, g.safeAreaInsets.bottom, for: .scrollContent)
                .ignoresSafeArea(.container, edges: .bottom)
                .onPreferenceChange(DonemYerleri.self) { yerler in
                    // js/ekranlar/harita.js konumaKaydir, .harita-durak.simdiki (@ a866b86).
                    // Hedefi dönemler gerçek yerlerini bildirdiğinde bir kez yerleştir.
                    if !ilkKonumKuruldu, yerler.count == bolgeler.count {
                        ilkKonumKuruldu = true
                        if depo.simdiki != nil {
                            vekil.scrollTo("konum", anchor: UnitPoint(x: 0.5, y: 0.55))
                        } else {
                            vekil.scrollTo("son", anchor: .bottom)
                        }
                    }
                    // `kaydirmaIzle`: ekranın ortasına en yakın dönem
                    let orta = g.size.height / 2
                    gorunenDonem = yerler.min { abs($0.value - orta) < abs($1.value - orta) }?.key
                }
                #if DEBUG && targetEnvironment(simulator)
                .task { await prova() }
                .onChange(of: provaKaydir) { _, hedef in if let hedef { vekil.scrollTo(hedef, anchor: .center) } }
                #endif
            }
            .overlay(alignment: .top) { ustDugmeler }
            .overlay {
                if let p = pencere {
                    pencereGorunumu(p).transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(tema.ayar.hareketAzaltilmis ? nil : .spring(response: 0.38, dampingFraction: 0.86), value: pencere)
        }
        .onDisappear { yuruyus?.cancel() }
        .fullScreenCover(item: $motifEser) { e in Goruntuleyici(eserler: [e], baslangic: 0).environment(tema) }
    }

    #if DEBUG && targetEnvironment(simulator)
    private func prova() async {
        guard let ad = YolculukProva.ad else { return }
        try? await Task.sleep(for: .seconds(2))
        switch ad {
        case "harita": break
        case "kurs": pencere = .kurs
        case "motif":
            guard let id = depo.dosyalar["harita.json"]?["bolgeler"]?["ortacag"]?["motifler"]?.dizi?.first?["eser"]?.metin else { return }
            pencere = .motif(id)
        case "kilit": if let d = depo.duraklar.first(where: { !$0.acik }) { pencere = .durak(d.id) }
        case "durak": pencere = .durak("4-1")
        case "gecis": provaKaydir = "gecis-ronesans"
        default: return
        }
        try? await Task.sleep(for: .seconds(4))
        YolculukProva.hazir(ad)
    }
    #endif

    // MARK: Üst

    /// `.harita-ust`: 30 px "Yolculuk" ve özet (açık / toplam bölüm · yıldız)
    private var ust: some View {
        let r = tema.renkler
        let acik = depo.duraklar.filter(\.acik).count
        let yildiz = depo.duraklar.reduce(0) { $0 + $1.yildiz }
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("Yolculuk").font(Yazi.serif(30)).cssSatir(.serif, 30, 30).accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                Text("\(acik)").font(Yazi.sans(14, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                Text("/\(depo.duraklar.count) bölüm · ").font(Yazi.sans(14)).foregroundStyle(Color(r.murekkep2))
                Text("\(yildiz) ").font(Yazi.sans(14, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                YildizSekli().fill(Color(red: 0.827, green: 0.635, blue: 0.29)).frame(width: 13, height: 13)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(acik)/\(depo.duraklar.count) bölüm · \(yildiz) yıldız")
            Spacer(minLength: 0)
        }
        .padding(.trailing, 52)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Sabit üst öğeler: kurs rozeti (sol), gündüz/gece (sağ) ve altında dönem göstergesi
    private var ustDugmeler: some View {
        HStack(alignment: .top) {
            // Z3n: sitede (harita.js kursRozetiHtml) hapın yanında madalyon yok; madalyon (`madalyonHtml`) durağın
            // çevresindeki halka. Z3a'da eklenen şimdiki durak simgesi hapı daraltıyordu: "16 / 57 konu" iki satıra
            // bölünüyor, "Sıradaki: Konu 17" kesiliyordu (telefon, 2026-11-24). Kaldırıldı.
            kursRozeti
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
                vakitDugmesi
                donemGostergesi
            }
        }
        .padding(.horizontal, 12).padding(.top, 10)
    }

    /// `.kurs-rozet`: 52 yükseklik, 36 pt halka, "n / 57 konu", "Sıradaki: Konu k", pirinç nokta
    private var kursRozeti: some View {
        let konular = katalog.kursKonulari
        let sayi = konular.filter { il.islenenKume.contains($0.no) }.count
        let siradaki = konular.first { !il.islenenKume.contains($0.no) }
        return Button { pencere = pencere == .kurs ? nil : .kurs } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(HaritaRenk.rozetYazi.opacity(0.2), lineWidth: 3)
                    if sayi > 0 {
                        Circle().trim(from: 0, to: CGFloat(sayi) / CGFloat(max(1, konular.count)))
                            .stroke(HaritaRenk.pirinc, style: StrokeStyle(lineWidth: 3, lineCap: .round)).rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 30, height: 30).frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(sayi) / \(konular.count) konu").font(Yazi.sans(15, agirlik: 600)).foregroundStyle(HaritaRenk.rozetYazi)
                    Text(siradaki.map { "Sıradaki: Konu \($0.no)" } ?? "Bütün konular işlendi").font(Yazi.sans(13))
                        .foregroundStyle(HaritaRenk.rozetSoluk)
                }
                if siradaki != nil { Circle().fill(HaritaRenk.pirinc).frame(width: 8, height: 8) }
            }
            .padding(.leading, 8).padding(.trailing, 16).frame(height: 52)
            .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().fill(HaritaRenk.rozetZemin.opacity(0.8))))
            .overlay(Capsule().strokeBorder(HaritaRenk.rozetYazi.opacity(0.14), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 8, y: 6)
            .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Kurs: \(sayi) / \(konular.count) konu işlendi\(siradaki.map { ", sıradaki konu \($0.no)" } ?? ""). Aç")
    }

    /// `.harita-vakit`: 44 daire, `--border`, %72 zemin + bulanık, güneş/ay 20
    private var vakitDugmesi: some View {
        let r = tema.renkler
        return Button { tur = tur == "gece" ? "gunduz" : "gece" } label: {
            Image(systemName: tur == "gece" ? "sun.max" : "moon").font(.system(size: 18, weight: .light))
                .foregroundStyle(Color(r.murekkep2))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial).overlay(Circle().fill(Color(r.zemin).opacity(0.72))))
                .overlay(Circle().strokeBorder(Color(r.kenar), lineWidth: 1))
                .shadow(color: .black.opacity(0.6), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tur == "gece" ? "Gündüze geç" : "Geceye geç")
    }

    /// `.harita-zaman`: ekranın ortasındaki dönemin adı (16 px Newsreader) ve yüzyılı (600 10 px, #b08530); yaldız kenar
    @ViewBuilder private var donemGostergesi: some View {
        if let i = gorunenDonem, bolgeler.indices.contains(i) {
            let r = tema.renkler
            VStack(alignment: .trailing, spacing: 1) {
                Text(YolculukHaritasi.adlar[i]).font(Yazi.okuma(16)).foregroundStyle(Color(r.murekkep)).multilineTextAlignment(.trailing)
                Text(Self.yuzyillar[i].uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(10, agirlik: 600)).tracking(1)
                    .foregroundStyle(Color(red: 0.69, green: 0.522, blue: 0.188)).multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 7)
            .frame(maxWidth: 190, alignment: .trailing)
            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 12).fill(Color(r.zemin).opacity(0.72))))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(red: 0.788, green: 0.635, blue: 0.29).opacity(0.45), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 8, y: 6)
            .allowsHitTesting(false)
            .transition(.opacity)
            .id(i)
            .accessibilityHidden(true)
        }
    }

    // MARK: Pencereler

    @ViewBuilder private func pencereGorunumu(_ p: Pencere) -> some View {
        switch p {
        case .durak(let id):
            if let d = depo.duraklar.first(where: { $0.id == id }) {
                DurakPenceresi(durak: d, katalog: katalog, il: il, kapat: { pencere = nil },
                               basla: { sv in pencere = nil; basla(d, sv) }, adreseGit: { a, s in pencere = nil; adreseGit(a, s) })
            }
        case .kurs:
            if let bilgi = depo.kurs {
                KursPenceresi(bilgi: bilgi, kapat: { pencere = nil },
                              isle: { no in Task { await depo.yaz { BenPanosu.isaretle([no], islendi: true, il: &$0) } } },
                              hepsi: { pencere = nil; adreseGit("#/ilerleme", .ben) })
            }
        case .motif(let id):
            MotifPenceresi(anahtar: id, harita: depo.dosyalar["harita.json"], motifler: depo.dosyalar["harita_motifler.json"],
                           katalog: katalog, il: il, kapat: { pencere = nil }, eserAc: { motifEser = $0 },
                           sanatciAc: { pencere = nil; adreseGit("#/sanatci/" + SiteYazisi.uriBileseni($0), .galeri) })
        }
    }

    // MARK: Harita

    private func donem(_ i: Int, _ en: CGFloat) -> some View {
        let bolge = bolgeler[i]
        let motifler = depo.dosyalar["harita.json"]?["bolgeler"]?[bolge]?["motifler"]?.dizi ?? []
        let bunlar = depo.duraklar.filter { $0.bolge == bolge }
        return ZStack(alignment: .topLeading) {
            donemResmi(i)
            ForEach(motifler.indices, id: \.self) { j in motifDugmesi(motifler[j], no: j, en: en) }
            ForEach(bunlar) { d in durakDugmesi(d, en: en) }
            if let d = depo.yolcu, d.bolge == bolge { yolcu(d, en: en) }

        }
        .frame(width: en, height: en * 3, alignment: .topLeading).clipped()
        .overlay(alignment: .topLeading) {
            if let d = depo.simdiki, d.bolge == bolge {
                let ust = CGFloat(d.y) * en * 3 - CGFloat(d.ay * d.boy) * en / 390
                VStack(spacing: 0) {
                    Color.clear.frame(height: max(0, ust))
                    Color.clear.frame(width: 1, height: 1).id("konum")
                }
                .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
    }

    /// `resimHtml`: son açık durağın SEPYA_PAY üstü sepya (`grayscale(1) sepia(0.55)`), sınırda 0.04'lük yumuşak geçiş
    private func donemResmi(_ i: Int) -> some View {
        let resim = haritaGorseli("donem_\(bolgeler[i])_\(tur)")
        let ust = Double(8 - i) * 1.34
        let sinir = sepyaSiniri
        let alt = min(1, max(0, sinir - ust))
        let renk: Color = sinir >= ust + 1 ? .white : .clear
        let gecis = Gradient(stops: [.init(color: .white, location: max(0, alt - 0.04)), .init(color: renk, location: alt)])
        return UzakGorsel(url: resim).overlay {
            if sinir > ust {
                UzakGorsel(url: resim).saturation(0).colorMultiply(Color(red: 0.93, green: 0.85, blue: 0.72)).contrast(0.92)
                    .mask(LinearGradient(gradient: gecis, startPoint: .top, endPoint: .bottom))
            }
        }
    }

    @ViewBuilder private func motifDugmesi(_ m: JSONDeger, no: Int, en: CGFloat) -> some View {
        if let p = m["kutu"]?.dizi?.compactMap(\.sayi), p.count == 4, let id = m["eser"]?.metin {
            let w = CGFloat(p[2] - p[0]) * en
            let h = CGFloat(p[3] - p[1]) * en * 3
            Button { pencere = .motif(id) } label: { Color.clear.contentShape(Rectangle()) }
                .frame(width: w, height: h).offset(x: CGFloat(p[0]) * en, y: CGFloat(p[1]) * en * 3)
                .accessibilityLabel("Saklı motif \(no + 1)")
        }
    }

    /// `durakHtml` + `madalyonHtml`: sembol (`scale: 1.14`), çevresinde halka (genişlik + 34; yıldız / 3 kadar pirinç),
    /// altında üç yıldız ya da sağ altta kilit; "buradasın" durağının altında ad ve sıradaki iş
    private func durakDugmesi(_ d: YolculukDuragi, en: CGFloat) -> some View {
        let olcek = en / 390
        let w = CGFloat(d.en) * olcek, h = CGFloat(d.boy) * olcek
        let x = CGFloat(d.x) * en + CGFloat(0.5 - d.ax) * w
        let y = CGFloat(d.y) * en * 3 + CGFloat(0.5 - d.ay) * h
        let simdiki = d.id == depo.simdiki?.id
        let halka = w + 34
        let gunduz = tur == "gunduz"
        return Button { sec(d) } label: {
            ZStack {
                // `.durak-halka`
                ZStack {
                    Circle().fill(gunduz ? Color(red: 247 / 255, green: 245 / 255, blue: 241 / 255).opacity(0.42) : Color(red: 18 / 255, green: 17 / 255, blue: 16 / 255).opacity(0.3))
                    Circle().stroke(gunduz ? Color(red: 31 / 255, green: 27 / 255, blue: 23 / 255).opacity(0.34) : Color(red: 235 / 255, green: 229 / 255, blue: 218 / 255).opacity(d.acik ? 0.34 : 0.4),
                                    style: StrokeStyle(lineWidth: 3 * halka / 64, dash: d.acik ? [] : [2 * halka / 64, 4 * halka / 64]))
                    if d.acik && d.yildiz > 0 {
                        Circle().trim(from: 0, to: CGFloat(d.yildiz) / 3)
                            .stroke(HaritaRenk.pirinc, style: StrokeStyle(lineWidth: 3 * halka / 64, lineCap: .round)).rotationEffect(.degrees(-90))
                    }
                    if simdiki { Circle().stroke(HaritaRenk.pirinc, lineWidth: 2) }
                }
                .frame(width: halka * 58 / 64, height: halka * 58 / 64)
                .frame(width: halka, height: halka)
                .overlay(alignment: .bottom) {
                    if d.acik {
                        UcYildiz(n: d.yildiz, boyut: 12, aralik: 2, bos: Color(red: 235 / 255, green: 229 / 255, blue: 218 / 255).opacity(0.5), dolu: HaritaRenk.pirinc)
                            .shadow(color: Color(red: 18 / 255, green: 17 / 255, blue: 16 / 255).opacity(0.7), radius: 1, y: 1)
                            .offset(y: 13)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !d.acik {
                        GaleriIkon(simge: .kilit, boyut: 12, kalinlik: 1.8).foregroundStyle(HaritaRenk.rozetSoluk)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(HaritaRenk.rozetZemin.opacity(0.86)))
                            .overlay(Circle().strokeBorder(HaritaRenk.rozetYazi.opacity(0.3), lineWidth: 1))
                            .offset(x: -4, y: -4)
                    }
                }
                UzakGorselSaydam(url: haritaGorseli("sembol_\(d.bolge)_\(d.sembol)_\(tur)"))
                    .frame(width: w, height: h)
                    .saturation(d.acik ? (simdiki ? 1.2 : 1) : 0.3)
                    .shadow(color: Color(red: 1, green: 0.94, blue: 0.8).opacity(0.95), radius: 0.8)
                    .shadow(color: Color(red: 0.08, green: 0.05, blue: 0.02).opacity(0.45), radius: 3, y: 4)
            }
            .frame(width: w, height: h)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(1.14)
        .overlay(alignment: etiketHizasi(d)) {
            // `.durak-etiket`: halkanın 18 altında (haritanın dibindeyse 30 üstünde); x > 0.6 sağa, x < 0.4 sola yaslı (17 taşar)
            if simdiki {
                let ustte = d.bolge == "ortacag" && d.y * 1170 > 1170 - 190
                let mesafe = h / 2 + halka * 1.14 / 2
                durakEtiketi(d)
                    .offset(x: d.x > 0.6 ? 17 : d.x < 0.4 ? -17 : 0,
                            y: ustte ? -(mesafe + 30) : mesafe + 18)
            }
        }
        .frame(width: w, height: h)
        .accessibilityLabel(d.ad + (d.acik ? ", \(d.yildiz) yıldız" : ", kilitli") + (simdiki ? ", buradasın" : ""))
        .position(x: x, y: y)
    }

    private func etiketHizasi(_ d: YolculukDuragi) -> Alignment {
        let ustte = d.bolge == "ortacag" && d.y * 1170 > 1170 - 190
        let yatay: HorizontalAlignment = d.x > 0.6 ? .trailing : d.x < 0.4 ? .leading : .center
        return Alignment(horizontal: yatay, vertical: ustte ? .bottom : .top)
    }

    /// `.durak-etiket`: koyu kart: 18 px ad, 13 px sıradaki iş
    private func durakEtiketi(_ d: YolculukDuragi) -> some View {
        let sv = BolumKurallari.seviyeler.first { s in
            (s == "kolay" || d.gecti(s == "orta" ? "kolay" : "orta")) && !d.gecti(s)
        }
        let ad = ["kolay": "Kolay", "orta": "Orta", "zor": "Zor"]
        return VStack(alignment: .leading, spacing: 1) {
            Text(d.ad).font(Yazi.serif(18)).foregroundStyle(HaritaRenk.rozetYazi)
            Text(sv.map { "\(ad[$0] ?? $0) · \(BolumKurallari.soruSayisi($0)) soru seni bekliyor" } ?? "Üç yıldız tamam")
                .font(Yazi.sans(13)).foregroundStyle(HaritaRenk.rozetSoluk)
        }
        .fixedSize()
        .padding(.horizontal, 12).padding(.top, 7).padding(.bottom, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(HaritaRenk.rozetZemin.opacity(0.86)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HaritaRenk.rozetYazi.opacity(0.14), lineWidth: 1))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func yolcu(_ d: YolculukDuragi, en: CGFloat) -> some View {
        if let v = depo.dosyalar["harita_yolcu.json"]?["bolgeler"]?[d.bolge], let ad = v["ad"]?.metin {
            let p = animasyonYeri ?? YolcuPatikasi.yer(d)
            let on = animasyonYeri == nil ? il[alan: "haritaYolcuOn"]?.mantik == true : animasyonOn
            let poz = on ? "on" : "dur"
            let olcu = v["pozlar"]?[poz]
            let w = CGFloat(olcu?["w"]?.sayi ?? 33) * en / 390
            let y = CGFloat(p.y + 96 * (0.5 - (olcu?["ay"]?.sayi ?? 1))) * en / 390
            UzakGorselSaydam(url: haritaGorseli("\(ad)_\(d.bolge)_\(poz)_\(tur)"))
                .frame(width: w, height: 96 * en / 390)
                .scaleEffect(x: d.x > 0.5 && !on ? -1 : 1, y: 1)
                .position(x: CGFloat(p.x) * en / 390, y: y).allowsHitTesting(false)
        }
    }

    private func sec(_ x: YolculukDuragi) {
        guard yuruyus == nil else { return }
        guard x.acik, let eski = depo.yolcu, eski.id != x.id,
              let yol = YolcuPatikasi(duraklar: depo.duraklar, eski: eski.id, yeni: x.id, veri: depo.dosyalar["harita_patikalar.json"])
        else { pencere = .durak(x.id); return }
        pencere = nil
        yuruyus = Task { @MainActor in
            defer { yuruyus = nil; animasyonYeri = nil }
            if yol.yurunur && !hareketAz && !tema.ayar.hareketAzaltilmis {
                let bas = Date()
                while !Task.isCancelled {
                    let t = Date().timeIntervalSince(bas) / yol.sure
                    let nokta = yol.konum(t)
                    animasyonYeri = nokta.yer; animasyonOn = nokta.on
                    if t >= 1 { break }
                    try? await Task.sleep(for: .milliseconds(20))
                }
            }
            guard !Task.isCancelled else { return }
            await depo.yaz { il in
                il[alan: "haritaYolcu"] = .metin(x.id)
                il[alan: "haritaYolcuOn"] = .mantik(yol.geri && !hareketAz && !tema.ayar.hareketAzaltilmis)
            }
            if !Task.isCancelled { pencere = .durak(x.id) }
        }
    }

    /// `gecisHtml`: iki dönemin aynalanan kenarları, ortada yüzyıl, elmaslı çizgi, dönemin adı ve "n bölüm · k açık"
    private func gecis(_ i: Int, _ en: CGFloat) -> some View {
        let gece = tur == "gece"
        let bunlar = depo.duraklar.filter { $0.bolge == bolgeler[i] }
        let acik = bunlar.filter(\.acik).count
        let yazi = gece ? Color(red: 0.937, green: 0.906, blue: 0.855) : Color(red: 0.208, green: 0.169, blue: 0.129)
        let golge = gece ? Color(red: 20 / 255, green: 16 / 255, blue: 13 / 255) : Color(red: 248 / 255, green: 242 / 255, blue: 230 / 255)
        let cizgi = Color(red: 0.886, green: 0.761, blue: 0.478)
        // Z3e: sitenin köprüsü (css/app.css .harita-gecis*, İş 43/99). Üstteki dönemin alt kenarı aşağı, alttakinin üst
        // kenarı yukarı aynalanır; her biri iki katman: bulanık (14 px, yanlardan 36 px taşar, %12 → %92 erir) ve net
        // (1,5 px, kenardan %32'de biter). Ortada sis tülü, bulut tutamları; alttaki dönem sepyaysa köprü de sepya.
        // (Önceden iki resim maskesiz ve köprünün tamamında duruyordu: telefonda ters bir "hayalet" görünüyordu.)
        let gok = gece ? Color(red: 20 / 255, green: 24 / 255, blue: 33 / 255) : Color(red: 216 / 255, green: 210 / 255, blue: 196 / 255)
        let sis = gece ? Color(red: 118 / 255, green: 130 / 255, blue: 158 / 255) : Color(red: 250 / 255, green: 244 / 255, blue: 232 / 255)
        let isik = Color(red: 1, green: gece ? 208 / 255 : 224 / 255, blue: gece ? 140 / 255 : 160 / 255)
        let sepya = Double(8 - (i - 1)) * 1.34 <= sepyaSiniri
        let h = en * 1.02
        func kenar(_ ad: String, ust: Bool, yumusak: Bool) -> some View {
            let tasma: CGFloat = yumusak ? 36 : 4
            let stops: [Gradient.Stop] = yumusak
                ? [.init(color: .white, location: 0.12), .init(color: .clear, location: 0.92)]
                : [.init(color: .white, location: 0), .init(color: .clear, location: 0.32)]
            return UzakGorsel(url: haritaGorseli(ad))
                .frame(width: en + 2 * tasma, height: h)
                .scaleEffect(x: 1, y: -1)
                .saturation(sepya ? 0 : (yumusak ? 1.08 : 1))
                .colorMultiply(sepya ? Color(red: 0.93, green: 0.85, blue: 0.72) : .white)
                .blur(radius: yumusak ? 14 : 1.5)
                .mask(LinearGradient(stops: stops, startPoint: ust ? .top : .bottom, endPoint: ust ? .bottom : .top))
        }
        return ZStack {
            gok
            ZStack {
                kenar("yansima_\(bolgeler[i])_alt_\(tur)", ust: true, yumusak: true)
                kenar("yansima_\(bolgeler[i - 1])_ust_\(tur)", ust: false, yumusak: true)
                kenar("yansima_\(bolgeler[i])_alt_\(tur)", ust: true, yumusak: false)
                kenar("yansima_\(bolgeler[i - 1])_ust_\(tur)", ust: false, yumusak: false)
            }
            .frame(width: en, height: h)
            // `.harita-gecis-sis`: ortada yatay, yumuşak kenarlı tül
            LinearGradient(stops: [.init(color: sis.opacity(0), location: 0.16), .init(color: sis.opacity(0.32), location: 0.5),
                                   .init(color: sis.opacity(0), location: 0.84)], startPoint: .top, endPoint: .bottom)
            Canvas { c, boyut in
                // `.harita-gecis-sis` ve bulut tutamları (a, b, c): yarı saydam elipsler
                let tutamlar: [(Double, Double, Double, Double, Double, Color)] = [
                    (0.28, 0.46, 0.38 * 1.44, 0.46 * 0.68, 0.5, sis), (0.70, 0.56, 0.44 * 1.44, 0.40 * 0.68, 0.45, sis),
                    (0.20, 0.24 + 0.30 * 0.55, 0.18 * 1.6, 0.46 * 0.30, 0.55, sis), (0.66, 0.24 + 0.30 * 0.58, 0.20 * 1.6, 0.50 * 0.30, 0.5, sis),
                    (0.46, 0.50 + 0.28 * 0.46, 0.22 * 1.6, 0.52 * 0.28, 0.5, sis), (0.30, 0.38 + 0.24 * 0.5, 0.10 * 1.6, 0.40 * 0.24, 0.32, isik),
                ]
                for (x, y, rx, ry, a, renk) in tutamlar {
                    // CSS `radial-gradient(ellipse …, renk, saydam 72%)`: elips boyunca söner (kenarda sert çizgi kalmaz).
                    // Daire çizip yatayda gerilir.
                    let w = 2 * rx * boyut.width, h = 2 * ry * boyut.height
                    var k = c
                    k.translateBy(x: x * boyut.width, y: y * boyut.height)
                    k.scaleBy(x: w / h, y: 1)
                    let yaricap = h / 2
                    k.fill(Path(ellipseIn: CGRect(x: -yaricap, y: -yaricap, width: h, height: h)),
                           with: .radialGradient(Gradient(colors: [renk.opacity(a), renk.opacity(0)]),
                                                 center: .zero, startRadius: 0, endRadius: yaricap * 0.72))
                }
            }
            .allowsHitTesting(false)
            VStack(spacing: 6) {
                Text(Self.yuzyillar[i].uppercased(with: Locale(identifier: "tr_TR"))).font(Yazi.sans(11, agirlik: 600)).tracking(1.76)
                    .foregroundStyle(gece ? Color(red: 0.847, green: 0.702, blue: 0.416) : Color(red: 0.541, green: 0.373, blue: 0.102))
                HStack(spacing: 0) {
                    Rectangle().fill(LinearGradient(colors: [cizgi.opacity(0), cizgi], startPoint: .leading, endPoint: .trailing)).frame(height: 1.5)
                    Rectangle().fill(Color(red: 0.208, green: 0.169, blue: 0.129)).frame(width: 9, height: 9)
                        .overlay(Rectangle().strokeBorder(cizgi, lineWidth: 1.5)).rotationEffect(.degrees(45))
                        .padding(.horizontal, 8)
                    Rectangle().fill(LinearGradient(colors: [cizgi, cizgi.opacity(0)], startPoint: .leading, endPoint: .trailing)).frame(height: 1.5)
                }
                .frame(width: en * 0.84 * 0.78, height: 10)
                .shadow(color: Color(red: 1, green: 0.925, blue: 0.745).opacity(0.55), radius: 3)
                // Z3f: dönemin harfi (İş 48; js/harfler.js BOLGE_HARFLERI); `.donem-harfi { letter-spacing: 0 }`
                DonemYazisi(metin: YolculukHaritasi.adlar[i], harf: DonemHarfleri.bolgeler[bolgeler[i]], boyut: 30, stil: .title1)
                    .multilineTextAlignment(.center)
                    .opacity(acik > 0 ? 1 : 0.75)
                Text("\(bunlar.count) bölüm · \(acik > 0 ? "\(acik) açık" : "kilitli")").font(Yazi.sans(13, agirlik: 500)).opacity(0.85)
            }
            .foregroundStyle(yazi)
            .shadow(color: golge.opacity(0.95), radius: 1)
            .shadow(color: golge.opacity(0.9), radius: 7)
            .padding(.horizontal, en * 0.08)
        }
        .frame(width: en, height: h).clipped()
    }

    /// `sepyaSiniri(harita)`: son açık durağın biraz üstü (resim boyu cinsinden, haritanın üstünden); bkz. `donemResmi`
    private var sepyaSiniri: Double {
        depo.duraklar.filter(\.acik).map { d in Double(8 - (bolgeler.firstIndex(of: d.bolge) ?? 0)) * 1.34 + d.y - 0.07 }.min() ?? 11.72
    }
}

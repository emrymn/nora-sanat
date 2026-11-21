// Kaynak: sanat-atlasi js/ekranlar/{gozat,akim,arama,koleksiyon}.js @ a866b86
import NoraCekirdek
import SwiftUI
import SafariServices

enum GaleriYolu: Hashable {
    case akim(String), sanatci(String), eserler(String), konular(String), konu(String), ara, koleksiyon, okuma(String)
    case akimKarsilastir(String, String), sanatciKarsilastir(String, String)
    init?(adres: String) {
        let p = adres.drop(while: { $0 == "#" || $0 == "/" }).split(separator: "/").map { String($0).removingPercentEncoding ?? String($0) }
        let id = p.dropFirst().first ?? ""
        switch p.first {
        case "akim-karsilastir" where p.count == 3: self = .akimKarsilastir(id, p[2])
        case "karsilastir" where p.count == 3: self = .sanatciKarsilastir(id, p[2])
        case "akim": self = .akim(id)
        case "sanatci": self = p.last == "eserler" ? .eserler(id) : .sanatci(id)
        case "ara": self = .ara
        case "koleksiyon": self = .koleksiyon
        case "konu": self = .konu(id)
        case "konular": self = .konular(id)
        case "basyapit": self = .okuma(id)
        default: return nil
        }
    }
}

private struct AcilanEserler: Identifiable {
    let id = UUID()
    let eserler: [Eser]
    let sira: Int
    var kirpim: TanimaKirpimi?
    var aciklama = ""
}

struct GaleriSekmesi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var durum
    @State private var galeri: GaleriKatalogu?
    @State private var ilerleme: Ilerleme?
    @State private var dizin: [GaleriKaydi] = []
    @State private var yol: [GaleriYolu] = []
    @State private var acilan: AcilanEserler?
    @State private var sayfa = 0
    @State private var siteBolumu: SiteBolumu?
    @State private var sorgu = ""
    @State private var hata: String?
    @State private var deneme = 0
    @State private var dizinAcik = false
    private static let depo = SiteVerisi()

    var body: some View {
        NavigationStack(path: $yol) {
            Group {
                if let g = galeri, let il = ilerleme {
                    sayfaGovdesi { anaSayfa(g, il) }
                } else if let hata {
                    VStack { Text(hata); Button("Yeniden dene") { deneme += 1 } }
                } else { ProgressView("Galeri hazırlanıyor…") }
            }
            .navigationTitle("Galeri")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GaleriYolu.self) { hedef in
                if let g = galeri, let il = ilerleme { hedefSayfa(hedef, g, il).toolbar(.visible, for: .navigationBar) }
            }
        }
        .task(id: deneme) {
            do {
                hata = nil
                async let kayit = IlerlemeKoprusu.shared.oku()
                async let ek = Self.depo.veriler(GaleriKatalogu.dosyalar)
                let k = try await Self.depo.katalog()
                let dosyalar = await ek
                guard dosyalar.count == GaleriKatalogu.dosyalar.count else { throw SiteVerisi.Hata.yok("Galeri") }
                let il = try await kayit
                let (g, d) = try await Task.detached {
                    let g = try GaleriKatalogu(katalog: k, dosyalar: dosyalar)
                    return (g, g.dizin(il))
                }.value
                guard !Task.isCancelled else { return }
                galeri = g
                dizin = d
                ilerleme = il
                adresiAc()
                #if DEBUG
                // Aynı kabuk, WKWebView ve köprüyle CI'da istenen Galeri yolunu açar.
                if let hedef = NoraSanatApp.arguman("-galeriSayfa") {
                    yol = GaleriYolu(adres: hedef).map { [$0] } ?? []
                }
                #endif
            } catch { if !Task.isCancelled { hata = "Galeri yüklenemedi." } }
        }
        .task(id: durum.secili) {
            guard durum.secili == .galeri, let g = galeri else { return }
            do {
                let il = try await IlerlemeKoprusu.shared.oku()
                let yeni = await Task.detached { g.dizin(il) }.value
                guard !Task.isCancelled else { return }
                ilerleme = il
                dizin = yeni
            } catch { if !Task.isCancelled { yenilemeHatasi = true } }
        }
        .onChange(of: durum.yenidenDokunma[.galeri]) { _, _ in
            yol = []
            sayfa = 0
            dizinAcik = false
        }
        .onChange(of: durum.yerliAdres[.galeri]) { _, _ in adresiAc() }
        .fullScreenCover(item: $acilan, onDismiss: {
            Task {
                do { ilerleme = try await IlerlemeKoprusu.shared.oku() }
                catch { yenilemeHatasi = true }
            }
        }) { secim in
            GaleriGoruntuleyicisi(secim: secim, depo: Self.depo) { id in
                acilan = nil
                yol.append(.konu(id))
            }
        }
        .sheet(item: $siteBolumu) { bolum in
            GaleriSiteSayfasi(adres: bolum.adres).ignoresSafeArea()
        }
        .alert("Koleksiyon güncellenemedi.", isPresented: $yenilemeHatasi) {
            Button("Yeniden dene") { deneme += 1 }
            Button("Kapat", role: .cancel) {}
        }
    }

    @State private var yenilemeHatasi = false

    private func adresiAc() {
        guard galeri != nil, let a = durum.yerliAdres[.galeri] else { return }
        yol = GaleriYolu(adres: a).map { [$0] } ?? []
        durum.adresIslendi(.galeri)
    }

    private func sayfaGovdesi<V: View>(@ViewBuilder _ icerik: () -> V) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) { icerik() }.padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(tema.renkler.zemin))
        .foregroundStyle(Color(tema.renkler.murekkep))
    }

    private func resim(_ e: Eser, _ g: GaleriKatalogu, boy: Int = 400, kip: ContentMode = .fit) -> some View {
        let kotuler = ilerleme?.kotuGorseller ?? [:]
        let yedek = GorselAdresleri.secilen(e, kotuler: kotuler).flatMap { GorselAdresleri.url(g.katalog.gorsel.yedek($0)) }
        return UzakGorsel(url: g.katalog.gorselAdresi(e, genislik: boy, kotuler: kotuler), icerik: kip, yedek: yedek).clipped()
    }

    private func anaSayfa(_ g: GaleriKatalogu, _ il: Ilerleme) -> some View {
        let salonlar = Kilit.akimDurumlari(g.katalog.akimlar, g.katalog.sanatcilar, islenen: il.islenenKume)
        return Group {
            HStack(spacing: 10) {
                Text("Galeri").font(Yazi.serif(34)).accessibilityAddTraits(.isHeader)
                NavigationLink(value: GaleriYolu.ara) {
                    Label("Sanatçı, eser ara", systemImage: "magnifyingglass")
                        .font(Yazi.sans(14)).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10).overlay(Capsule().stroke(.secondary.opacity(0.35)))
                }
                NavigationLink(value: GaleriYolu.koleksiyon) {
                    Image(systemName: g.koleksiyon(il).isEmpty ? "heart" : "heart.fill")
                        .frame(width: 40, height: 40).overlay(Circle().stroke(.secondary.opacity(0.35)))
                }.accessibilityLabel("Koleksiyonum")
            }
            HStack(spacing: 0) {
                Text("Akımlar").padding(9).foregroundStyle(Color(tema.renkler.zemin))
                    .background(Color(tema.renkler.murekkep), in: Capsule())
                Spacer()
                Button("Başyapıtlar") { siteBolumu = .basyapitlar }
                Spacer()
                NavigationLink("Konular", value: GaleriYolu.konular(""))
                Spacer()
                Button("Zaman") { siteBolumu = .zaman }
            }.font(Yazi.sans(13)).padding(5).padding(.trailing, 9)
                .overlay(Capsule().stroke(.secondary.opacity(0.35)))
            TabView(selection: $sayfa) {
                ForEach(Array(salonlar.enumerated()), id: \.element.ad) { i, salon in
                    VStack(spacing: 12) {
                        if let e = g.carkKapagi(salon.ad, il) {
                            resim(e, g, boy: 800, kip: .fill).frame(width: 188, height: 240)
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 94, topTrailingRadius: 94))
                        }
                        Text(GaleriSergisi.yuzyillar(g.katalog.sanatcilar.filter { $0.akim == salon.ad })).font(.caption)
                        Text(salon.ad).font(Yazi.serif(36)).multilineTextAlignment(.center)
                        Text(durumYazisi(salon)).font(.caption)
                        if salon.acik {
                            NavigationLink(value: GaleriYolu.akim(salon.ad)) {
                                Label("Salona gir", systemImage: "chevron.right").labelStyle(.titleAndIcon)
                                    .font(Yazi.sans(15, agirlik: 600)).padding(.vertical, 10).padding(.horizontal, 18)
                                    .foregroundStyle(Color(tema.renkler.zemin))
                                    .background(Color(tema.renkler.murekkep), in: Capsule())
                            }
                        }
                    }.padding(.horizontal).tag(i)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 410)
            if !salonlar.isEmpty {
                GaleriCarki(salonlar: salonlar, sira: $sayfa)
                HStack {
                    Button { sayfa -= 1 } label: { Image(systemName: "chevron.left") }.disabled(sayfa == 0).accessibilityLabel("Önceki akım")
                    Spacer()
                    Text("\(sayfa + 1) / \(salonlar.count)").monospacedDigit()
                    Spacer()
                    Button { sayfa += 1 } label: { Image(systemName: "chevron.right") }.disabled(sayfa + 1 >= salonlar.count).accessibilityLabel("Sonraki akım")
                }
            }
            DisclosureGroup("Bütün akımlar", isExpanded: $dizinAcik) {
                ForEach(salonlar, id: \.ad) { a in
                    NavigationLink(value: GaleriYolu.akim(a.ad)) {
                        LabeledContent(a.ad, value: durumYazisi(a))
                    }.disabled(!a.acik).padding(.vertical, 5)
                }
            }
        }
    }

    private func durumYazisi(_ a: AkimDurumu) -> String {
        if a.acik && a.acikSayisi == a.toplam { return "\(a.toplam) sanatçının hepsi açık" }
        if a.acik { return "\(a.acikSayisi) / \(a.toplam) sanatçı açık" }
        return a.acilacagiKonu.map { "Konu \($0) işlenince açılır" } ?? "Kilitli"
    }

    @ViewBuilder private func hedefSayfa(_ yol: GaleriYolu, _ g: GaleriKatalogu, _ il: Ilerleme) -> some View {
        switch yol {
        case .akim(let ad):
            sayfaGovdesi {
                let dortlu = g.dortlu(ad, il)
                if let ilk = dortlu.first { resim(ilk, g, boy: 800).frame(height: 225) }
                if let maddeler = g.ozellikler[ad] {
                    Text("Nasıl tanınır?").font(.headline)
                    ForEach(maddeler, id: \.self) { Text($0) }
                }
                if !dortlu.isEmpty { izgara(dortlu, g) }
                Text("Sanatçılar").font(.headline)
                let uyeler = g.katalog.sanatcilar.filter { $0.akim == ad }.sorted { ($0.dogum ?? $0.olum ?? 0) < ($1.dogum ?? $1.olum ?? 0) }
                ForEach([true, false], id: \.self) { acik in
                    ForEach(uyeler.filter { ($0.konu.map(il.islenenKume.contains) == true) == acik }) { s in sanatciSatiri(s, il) }
                }
                if !dortlu.isEmpty {
                    Button("Bu dönemi pekiştir") {
                        durum.sec(.calis)
                        Gezgin.shared.git("#/pekistir/donem/" + SiteYazisi.uriBileseni(ad))
                    }
                }
                if let akim = g.katalog.akimlar.first(where: { $0.ad == ad }) {
                    DisclosureGroup("Akımları karşılaştır") {
                        ForEach(akim.komsular.filter { komsu in komsu != ad && g.katalog.akimlar.contains { $0.ad == komsu } }, id: \.self) { komsu in
                            NavigationLink(komsu, value: GaleriYolu.akimKarsilastir(ad, komsu))
                        }
                    }
                }
                let tipik = g.tipikKonular(ad, il)
                if !tipik.isEmpty {
                    Text("Tipik konular").font(.headline)
                    ForEach(tipik) { k in NavigationLink(k.ad, value: GaleriYolu.konu(k.id)) }
                }
                if let bilgi = g.bilgi[ad] {
                    Text(bilgi["donem"] ?? "").font(.headline)
                    Text(bilgi["yer"] ?? "").font(.caption)
                    Text(bilgi["metin"] ?? "")
                }
            }.navigationTitle(ad)
        case .sanatci(let id), .eserler(let id):
            if let s = g.katalog.harita[id] {
                let eserler = g.eserler[id] ?? []
                sayfaGovdesi {
                    if yol == .sanatci(id) {
                        NavigationLink(s.akim, value: GaleriYolu.akim(s.akim))
                        SanatciKunyesi(s: s, g: g)
                        NavigationLink("Tüm eserler (\(eserler.count))", value: GaleriYolu.eserler(id))
                        ScrollView(.horizontal) {
                            LazyHStack { ForEach(eserler.indices, id: \.self) { i in kart(eserler, i, g).frame(width: 155) } }
                        }
                        let tanima = GoruntuleyiciKurallari.taninmaMetni(s, tanimaNotlari: g.tanimaNotlari)
                        if !tanima.isEmpty { Text("Nasıl tanırım?").font(.headline); Text(tanima) }
                        ForEach(Array((g.sanatciKirpimlari[id] ?? []).enumerated()), id: \.offset) { _, k in
                            kirpim(k, eserler, g, il)
                        }
                        if let not = s.kursNotu ?? s.anlatim { Text("Notlarımdan").font(.headline); Text(not) }
                        DisclosureGroup("Karşılaştır") {
                            ForEach(GoruntuleyiciKurallari.benzerSanatcilar(s, sanatcilar: g.katalog.sanatcilar, akimlar: g.katalog.akimlar)) { diger in
                                NavigationLink(diger.ad, value: GaleriYolu.sanatciKarsilastir(s.id, diger.id))
                            }
                        }
                    } else { izgara(eserler, g) }
                    if eserler.isEmpty { Text("Bu sanatçı için doğrulanmış görsel bulunamadı.") }
                }.navigationTitle(s.ad)
            }
        case .koleksiyon:
            let eserler = g.koleksiyon(il)
            sayfaGovdesi {
                if eserler.isEmpty { Text("Henüz eser işaretlemedin. Bir eseri büyütüp sağ üstteki işarete dokun.") }
                else {
                    Text("\(eserler.count) eser")
                    KoleksiyonDuvari(eserler: eserler, galeri: g, ilerleme: il) { i in
                        acilan = AcilanEserler(eserler: eserler, sira: i)
                    }
                }
            }.navigationTitle("Koleksiyonum")
        case .konular(let tur):
            sayfaGovdesi {
                ForEach(GaleriKatalogu.turler.indices, id: \.self) { i in
                    let t = GaleriKatalogu.turler[i]
                    let l = g.konular.filter { $0.tur == t }.sorted { $0.baglar.count > $1.baglar.count }
                    if (tur.isEmpty || tur == t) && !l.isEmpty {
                        NavigationLink(GaleriKatalogu.turAdlari[i], value: GaleriYolu.konular(t)).font(.headline).disabled(tur == t)
                        ForEach(tur.isEmpty ? Array(l.prefix(6)) : l) { k in
                            NavigationLink(value: GaleriYolu.konu(k.id)) {
                                HStack {
                                    if let kapak = g.konuKapagi(g.konuEserleri(k)) { resim(kapak, g, kip: .fill).frame(width: 68, height: 80) }
                                    LabeledContent(k.ad, value: "\(k.baglar.count) eser")
                                }
                            }
                        }
                    }
                }
            }.navigationTitle("Konular")
        case .konu(let id):
            if let k = g.konular.first(where: { $0.id == id }) {
                sayfaGovdesi {
                    let eserler = g.konuEserleri(k)
                    if let kapak = g.konuKapagi(eserler), let i = eserler.firstIndex(of: kapak) {
                        Button { acilan = AcilanEserler(eserler: eserler, sira: i) } label: {
                            resim(kapak, g, boy: 800).frame(height: 235)
                        }.accessibilityLabel(kapak.gorunenAd)
                    }
                    Text(k.kaynak).font(.caption)
                    Text(k.ozet).font(.headline)
                    ForEach(k.hikaye, id: \.self) { Text($0) }
                    if !k.tanima.isEmpty { Text("Resimde nasıl tanınır?").font(.headline) }
                    ForEach(Array(k.tanima.enumerated()), id: \.offset) { i, metin in
                        Text(metin)
                        if let kayit = g.konuKirpimlari[k.id]?.first(where: { $0.madde == i }) {
                            kirpim(kayit, eserler, g, il, aciklama: metin)
                        }
                    }
                    izgara(eserler, g)
                }.navigationTitle(k.ad)
            }
        case .akimKarsilastir(let a, let b), .sanatciKarsilastir(let a, let b):
            sayfaGovdesi {
                HStack(alignment: .top) {
                    ForEach([a, b], id: \.self) { id in
                        VStack(alignment: .leading, spacing: 10) {
                            if case .akimKarsilastir = yol {
                                NavigationLink(id, value: GaleriYolu.akim(id)).font(.headline)
                                Text(GaleriSergisi.yuzyillar(g.katalog.sanatcilar.filter { $0.akim == id })).font(.caption)
                                let eserler = Array(g.dortlu(id, il).prefix(2))
                                ForEach(eserler.indices, id: \.self) { i in kart(eserler, i, g) }
                                ForEach(g.ozellikler[id] ?? [], id: \.self) { Text($0) }
                                ForEach(Array(g.tipikKonular(id, il).prefix(3))) { k in NavigationLink(k.ad, value: GaleriYolu.konu(k.id)) }
                            } else if let s = g.katalog.harita[id] {
                                NavigationLink(s.ad, value: GaleriYolu.sanatci(id)).font(.headline)
                                Text(s.yillar).font(.caption)
                                Text(GoruntuleyiciKurallari.taninmaMetni(s, tanimaNotlari: g.tanimaNotlari))
                                let eserler = Array((g.eserler[id] ?? []).sorted { $0.sl > $1.sl }.prefix(4))
                                ForEach(eserler.indices, id: \.self) { i in kart(eserler, i, g) }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.navigationTitle("Yan yana")
        case .ara:
            sayfaGovdesi { aramaSonuclari(g, il) }.navigationTitle("Ara")
                .searchable(text: $sorgu, placement: .navigationBarDrawer(displayMode: .always), prompt: "Sanatçı, eser, konu…")
        case .okuma(let id):
            if let b = g.basyapitlar.first(where: { $0["anahtar"]?.metin == id }) {
                sayfaGovdesi {
                    if let e = g.eslestir(id, b["sanatci"]?.metin ?? "") { kart([e], 0, g) }
                    Text(b["ozet"]?.metin ?? "")
                    ForEach(Array((b["bolumler"]?.dizi ?? []).enumerated()), id: \.offset) { _, bolum in
                        Text(bolum["baslik"]?.metin ?? "").font(.headline)
                        Text(bolum["metin"]?.metin ?? "")
                    }
                }.navigationTitle(b["baslik"]?.metin ?? "")
            }
        }
    }

    @ViewBuilder private func kirpim(_ k: TanimaKirpimi, _ liste: [Eser], _ g: GaleriKatalogu, _ il: Ilerleme, aciklama: String = "") -> some View {
        if let e = k.eser(liste, katalog: g.katalog, il: il),
           let secili = GorselAdresleri.secilen(e, kotuler: il.kotuGorseller) ?? e.gorseller.first {
            let oran = g.katalog.gorsel.oran(secili) ?? 1
            Button { acilan = AcilanEserler(eserler: [e], sira: 0, kirpim: k, aciklama: aciklama) } label: {
                GeometryReader { geo in
                    let w = geo.size.width / k.w
                    let h = w / oran
                    resim(e, g, boy: 800).frame(width: w, height: h)
                        .offset(x: -w * k.x, y: -h * k.y)
                }.aspectRatio(oran * k.w / k.h, contentMode: .fit).clipped()
            }.accessibilityLabel(k.ad)
        }
    }

    private func sanatciSatiri(_ s: Sanatci, _ il: Ilerleme) -> some View {
        let acik = s.konu.map(il.islenenKume.contains) == true
        return NavigationLink(value: GaleriYolu.sanatci(s.id)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(s.ad)
                    Text(acik ? s.yillar : "Konu \(s.konu ?? 0) işlenince açılır").font(.caption)
                }
                Spacer()
                Image(systemName: acik ? "chevron.right" : "lock")
            }
        }.disabled(!acik)
    }

    private func izgara(_ eserler: [Eser], _ g: GaleriKatalogu) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 18) {
            ForEach(eserler.indices, id: \.self) { i in kart(eserler, i, g) }
        }
    }

    private func kart(_ eserler: [Eser], _ i: Int, _ g: GaleriKatalogu) -> some View {
        let e = eserler[i]
        return Button { acilan = AcilanEserler(eserler: eserler, sira: i) } label: {
            VStack(alignment: .leading) {
                resim(e, g).frame(height: 145)
                Text(e.gorunenAd).font(Yazi.serif(17)).lineLimit(3)
                if !e.tarih.isEmpty { Text(e.tarih).font(.caption).foregroundStyle(.secondary) }
            }
        }.buttonStyle(.plain)
    }

    @ViewBuilder private func aramaSonuclari(_ g: GaleriKatalogu, _ il: Ilerleme) -> some View {
        let sonuc = GaleriAramasi.ara(dizin, sorgu: sorgu)
        if sorgu.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            Text("Ad yazmaya başla. Türkçe harfler şart değil.")
        } else if sonuc.isEmpty { Text("“\(sorgu)” için sonuç yok.") }
        ForEach(GaleriKaydi.Tur.allCases, id: \.self) { tur in
            let grup = sonuc.filter { $0.tur == tur }
            if !grup.isEmpty {
                let adlar: [GaleriKaydi.Tur: String] = [.sanatci: "Sanatçılar", .eser: "Eserler", .konu: "Konular", .basyapit: "Başyapıtlar"]
                Text("\(adlar[tur] ?? "") · \(grup.count)").font(.headline)
                ForEach(Array(grup.prefix(8))) { x in
                    switch tur {
                    case .sanatci:
                        if let s = g.katalog.harita[x.anahtar] { sanatciSatiri(s, il) }
                    case .eser:
                        if let e = g.eserler[x.sanatci ?? ""]?.first(where: { $0.anahtar == x.anahtar }) {
                            Button { acilan = AcilanEserler(eserler: [e], sira: 0) } label: {
                                HStack { resim(e, g).frame(width: 50, height: 50); Text(x.baslik) }
                            }
                        }
                    case .konu: NavigationLink(x.baslik, value: GaleriYolu.konu(x.anahtar))
                    case .basyapit: NavigationLink(x.baslik, value: GaleriYolu.okuma(x.anahtar))
                    }
                }
                if grup.count > 8 { Text("\(grup.count - 8) sonuç daha. Aramayı daralt.").font(.caption) }
            }
        }
    }
}

private struct GaleriGoruntuleyicisi: View {
    let secim: AcilanEserler
    let depo: SiteVerisi
    let konuSecildi: (String) -> Void
    @Environment(\.dismiss) private var kapat
    @State private var baglam: GoruntuleyiciBaglami?

    var body: some View {
        Group {
            if secim.kirpim == nil {
                Goruntuleyici(eserler: secim.eserler, baslangic: secim.sira, konuSecildi: konuSecildi)
            } else if let baglam {
                Goruntuleyici(eserler: secim.eserler, baslangic: secim.sira,
                              incelemeyeBasla: secim.kirpim != nil, baglam: baglam, konuSecildi: konuSecildi)
            } else {
                VStack { ProgressView("Eser açılıyor…"); Button("Kapat") { kapat() } }
            }
        }.task {
            guard secim.kirpim != nil else { return }
            var yeni = await GoruntuleyiciBaglami.yukle(siteVerisi: depo)
            if let kirpim = secim.kirpim, let eser = secim.eserler.first {
                let kayit = kirpim.inceleme(yeni.ayrinti(eser), aciklama: secim.aciklama)
                yeni.ayrintilar.insert(kayit, at: 0)
            }
            if !Task.isCancelled { baglam = yeni }
        }
    }
}

/// G3 ve G5 kendi ekranlarını bağlayana kadar bu iki okuma bölümü yayındaki siteden açılır.
private enum SiteBolumu: String, Identifiable {
    case basyapitlar, zaman
    var id: String { rawValue }
    var adres: URL {
        var bilesenler = URLComponents(url: SiteVerisi.site, resolvingAgainstBaseURL: false)
        bilesenler?.fragment = "/" + rawValue
        return bilesenler?.url ?? SiteVerisi.site
    }
}

private struct GaleriSiteSayfasi: UIViewControllerRepresentable {
    let adres: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: adres) }
    func updateUIViewController(_ denetleyici: SFSafariViewController, context: Context) {}
}

// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (kartGoster, tersGoster, kartpostalAc, seviyeHaplari, ipucuMetni,
// karsiSeritHtml, kutuSatiri, seviyeSatiri, baskaEser), css/app.css (.soru-sahne, .soru-baslik, .secenekler,
// .alt-yaprak, .karsi-serit, .kutu-satir, .ters-levha, .seviye-hap) @ a866b86
import NoraCekirdek
import SwiftUI

/// Görüntüleyiciyi açma isteği (sitede `goruntuleyiciAc`)
struct GosterimIstegi: Identifiable {
    let id = UUID()
    let eserler: [Eser]
    var baslangic = 0
    var gizli = false
}

/// Soru kartı ve cevap yaprağı (`kartGoster`, `tersGoster`)
struct KartGorunumu: View {
    let model: PekistirmeModeli
    let tur: TurKaydi
    let k: TurKarti
    let kapat: () -> Void
    var disAdreseGit: ((String) -> Void)? = nil
    @Environment(TemaDeposu.self) private var tema
    @State private var gosterim: GosterimIstegi?
    @State private var tersBuyuk: Int?
    @State private var ipucuAcik = false
    @State private var hikayeAcik = false
    @State private var ayrintiAcik = false

    private var r: TemaRenkleri { tema.renkler }
    private var sanatci: Sanatci? { model.sanatci(k.resim.id) }
    private var cevaplandi: Bool { k.sonuc != nil }
    private var toplam: Int { tur.oturum.kuyruk.count }
    private var sira: Int { min(tur.gorunenKonum + 1, max(1, toplam)) }
    private var karisik: Bool { k.akimlar != nil }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .top) {
                Color(r.zemin).ignoresSafeArea()
                SoruIsigi(url: model.gorsel(k.resim.eser, 400))
                ScrollView {
                    VStack(spacing: 0) {
                        SoruUstu(baslik: model.turBasligi ?? CevapYazilari.kipAdi(tur.kip), sayac: "\(sira) / \(toplam)", kapat: kapat)
                        TurCubugu(toplam: toplam, konum: tur.gorunenKonum)
                            .padding(.horizontal, 24).padding(.top, 8)
                        seviyeHaplari
                        if k.ters != nil { tersGovde(g.size) } else { soruGovde(g.size) }
                        if cevaplandi {
                            yaprak.padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .animation(tema.ayar.hareketAzaltilmis ? nil : .spring(response: 0.42, dampingFraction: 0.86), value: cevaplandi)
        .fullScreenCover(item: $gosterim) { g in
            Goruntuleyici(eserler: g.eserler, baslangic: g.baslangic, gizli: g.gizli).environment(tema)
        }
        .fullScreenCover(isPresented: Binding(get: { tersBuyuk != nil }, set: { if !$0 { tersBuyuk = nil } })) {
            if let ters = k.ters { TersKartpostallar(model: model, ters: ters, baslangic: tersBuyuk ?? 0).environment(tema) }
        }
    }

    // MARK: Seviye hapları (Ö9)

    @ViewBuilder private var seviyeHaplari: some View {
        if let il = model.ilerleme, let haplar = tur.seviyeHaplari(il) {
            HStack(spacing: 8) {
                ForEach(haplar, id: \.tanim.no) { h in
                    if h.acik {
                        Button { Task { await model.seviyeSec(h.tanim.no) } } label: {
                            HStack(spacing: 4) {
                                Text(h.tanim.ad).font(Yazi.sans(13, agirlik: 600))
                                if h.isinma { Text("ısınma").font(Yazi.sans(10, agirlik: 500)).opacity(0.75) }
                            }
                            .padding(.horizontal, 14).frame(height: 32)
                            .foregroundStyle(Color(h.secili ? r.vurguAcikYazi : r.murekkep2))
                            .background(Capsule().fill(h.secili ? Color(r.vurguAcik) : Color(r.yuzey)))
                            .overlay(Capsule().stroke(Color(r.kenar), lineWidth: h.secili ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(h.secili ? .isSelected : [])
                    } else {
                        Label(h.tanim.ad, systemImage: "lock").font(Yazi.sans(13, agirlik: 500))
                            .padding(.horizontal, 12).frame(height: 32)
                            .foregroundStyle(Color(r.soluk))
                            .overlay(Capsule().stroke(Color(r.kenar), lineWidth: 1))
                            .accessibilityLabel("\(h.tanim.ad), kilitli")
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24).padding(.top, 12)
        }
    }

    // MARK: Soru (sanatçı, akım, kurs bölümü, ikonografi)

    private func gorselYuksekligi(_ boyut: CGSize) -> CGFloat {
        cevaplandi ? 150 : min(430, max(190, boyut.height - 430))
    }

    @ViewBuilder private func soruGovde(_ boyut: CGSize) -> some View {
        let h = gorselYuksekligi(boyut)
        ZStack {
            HaleNefes().padding(.horizontal, -16).padding(.vertical, -h * 0.08)
            Button {
                gosterim = GosterimIstegi(eserler: [k.resim.eser], gizli: !cevaplandi)
            } label: {
                SoruGorseli(url: model.gorsel(k.resim.eser, 800), yedek: yedekAdres(k.resim.eser), yukseklik: h,
                            enGenis: boyut.width - 24) {
                    if !cevaplandi { Task { await model.baskaEser() } }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(cevaplandi ? CevapYazilari.eserAdi(k.resim.eser) : "Sorulan eser. Görseli büyüt")
            .accessibilityIdentifier("soru-resim")
        }
        .frame(maxWidth: .infinity, minHeight: h)
        .padding(.top, 14)

        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(soruYazisi).font(Yazi.serif(28)).lineLimit(1).minimumScaleFactor(0.75)
                .foregroundStyle(Color(r.murekkep))
                .accessibilityAddTraits(.isHeader)
            PkEtiket(yazi: soruEtiketi)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24).padding(.top, 12)

        secenekler.padding(.horizontal, 24).padding(.top, 10)

        if !cevaplandi {
            Button { Task { await model.cevapla(nil) } } label: {
                Text("Bilmiyorum").font(Yazi.okuma(17, italik: true)).foregroundStyle(Color(r.murekkep2))
                    .padding(.horizontal, 18).frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 6).padding(.bottom, 24)
            .accessibilityIdentifier("bilmiyorum")
        }
    }

    private var soruYazisi: String {
        if k.ikinci { return "Hangi akım?" }
        switch tur.kip {
        case .kursBolumu: return "Bu eser hangi bölümde?"
        case .ikonografi: return "Bu eserin konusu ne?"
        case .sanatci: return "Bu eser kimin?"
        }
    }

    private var soruEtiketi: String {
        switch tur.kip {
        case .kursBolumu: return "Kursun bölümleri"
        case .ikonografi: return "Resmin konusu"
        case .sanatci:
            let soru = karisik ? "Soru \(k.ikinci ? 2 : 1) / 2" : "Soru 1 / 1"
            return "\(soru) · \(Seviye.bul(k.seviye ?? 0).ad)"
        }
    }

    private func ad(_ id: String) -> String {
        if k.ikinci { return id }
        switch tur.kip {
        case .ikonografi: return model.veri.ad(id)
        case .kursBolumu:
            if let b = model.kursBolumleri().first(where: { $0.id == id }) {
                return "\(b.id) · \(b.kisaAd)"
            }
            return model.katalog?.konular.first { $0.bolum == id }.map { "\(id) · \($0.bolumAd)" } ?? id
        case .sanatci: return model.sanatci(id)?.ad ?? id
        }
    }

    @ViewBuilder private var secenekler: some View {
        let liste = k.ikinci ? (k.akimlar ?? []) : k.secenekler
        let dogruDeger = k.ikinci ? (sanatci?.akim ?? "") : k.dogru
        let secilen = k.ikinci ? k.akimCevabi : k.sanatciCevabi
        let harfler = Array("ABCD")
        // Cevaptan sonra (D3) yalnız doğru ve seçilen şık kalır
        let kalan = liste.enumerated().filter { !cevaplandi || $0.element == dogruDeger || $0.element == secilen }
        let dugme = { (i: Int, deger: String) -> SecenekDugmesi in
            let durum: SecenekDugmesi.Durum = !cevaplandi ? .bos : deger == dogruDeger ? .dogru : deger == secilen ? .yanlis : .soluk
            return SecenekDugmesi(harf: i < harfler.count ? String(harfler[i]) : "", ad: ad(deger), durum: durum, daralmis: cevaplandi) {
                Task { await model.cevapla(deger) }
            }
        }
        Group {
            if cevaplandi {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(kalan, id: \.element) { i, deger in dugme(i, deger) }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(kalan, id: \.element) { i, deger in dugme(i, deger) }
                }
            }
        }
        .accessibilityIdentifier(k.ikinci ? "akim-secenekleri" : "sanatci-secenekleri")
    }

    private func yedekAdres(_ e: Eser) -> URL? {
        guard let katalog = model.katalog, let g = GorselAdresleri.secilen(e, kotuler: model.ilerleme?.kotuGorseller ?? [:]) else { return nil }
        return URL(string: katalog.gorsel.yedek(g))
    }

    // MARK: Ters soru (Ö1)

    @ViewBuilder private func tersGovde(_ boyut: CGSize) -> some View {
        let ters = k.ters ?? []
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                PkEtiket(yazi: "Ters soru · \(Seviye.bul(k.seviye ?? 0).ad)")
                Spacer()
                Text(sanatci.map(CevapYazilari.yillar) ?? "").font(Yazi.sans(12, agirlik: 500)).foregroundStyle(Color(r.murekkep2))
            }
            Text("Hangisi bir").font(Yazi.okuma(17, italik: true)).foregroundStyle(Color(r.murekkep2)).padding(.top, 6)
            Text(sanatci?.ad ?? "").font(Yazi.serif(cevaplandi ? 26 : 34)).foregroundStyle(Color(r.murekkep))
                .lineLimit(2).minimumScaleFactor(0.7).accessibilityAddTraits(.isHeader)
            Text("eseri?").font(Yazi.okuma(17, italik: true)).foregroundStyle(Color(r.murekkep2))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 24).padding(.top, 14)

        if !cevaplandi {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(ters.enumerated()), id: \.element.id) { i, x in
                    Button { tersBuyuk = i } label: {
                        kartpostal(x.eser, harf: String(Array("ABCD")[i]))
                    }
                    .buttonStyle(.plain)
                    .rotationEffect(.degrees([-2.5, 1.8, 1.4, -1.6][i % 4]))
                    .accessibilityLabel("\(String(Array("ABCD")[i])) eserini büyüt")
                }
            }
            .padding(.horizontal, 24).padding(.top, 12)
            .accessibilityIdentifier("ters-secenekleri")
            Button { Task { await model.cevapla(nil) } } label: {
                Text("Bilmiyorum").font(Yazi.okuma(17, italik: true)).foregroundStyle(Color(r.murekkep2))
                    .padding(.horizontal, 18).frame(minHeight: 44)
            }
            .buttonStyle(.plain).padding(.vertical, 10)
        } else if let dogru = ters.first(where: { $0.id == k.dogru }) {
            Button { gosterim = GosterimIstegi(eserler: ters.map(\.eser), baslangic: ters.firstIndex { $0.id == k.dogru } ?? 0) } label: {
                SoruGorseli(url: model.gorsel(dogru.eser, 800), yedek: yedekAdres(dogru.eser), yukseklik: 170, enGenis: boyut.width - 24)
            }
            .buttonStyle(.plain).padding(.top, 12)
            HStack(alignment: .top, spacing: 8) {
                ForEach(ters, id: \.id) { x in
                    let renk: Color = x.id == k.dogru ? Color(r.dogru) : x.id == k.sanatciCevabi ? Color(r.yanlis) : Color(r.kenar)
                    VStack(spacing: 4) {
                        UzakGorsel(url: model.gorsel(x.eser, 400), icerik: .fill)
                            .frame(height: 74).clipShape(RoundedRectangle(cornerRadius: 3))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(renk, lineWidth: x.id == k.dogru || x.id == k.sanatciCevabi ? 2 : 1))
                            .opacity(x.id == k.dogru || x.id == k.sanatciCevabi ? 1 : 0.55)
                        Text(kisaAd(x.id)).font(Yazi.sans(11, agirlik: 600)).foregroundStyle(Color(r.murekkep2))
                            .lineLimit(2).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24).padding(.top, 12)
            .accessibilityIdentifier("ters-secenekleri")
        }
    }

    private func kartpostal(_ e: Eser, harf: String) -> some View {
        UzakGorsel(url: model.gorsel(e, 400), icerik: .fill)
            .aspectRatio(0.8, contentMode: .fit)
            .clipShape(Rectangle())
            .padding(6)
            .background(Color(r.yuzey))
            .overlay(alignment: .topTrailing) {
                Text(harf).font(Yazi.sans(12, agirlik: 700)).foregroundStyle(Color(r.zemin))
                    .frame(width: 24, height: 24).background(Circle().fill(Color(r.pirinc))).offset(x: 6, y: -6)
            }
            .shadow(color: .black.opacity(0.45), radius: 12, y: 8)
    }

    private func kisaAd(_ id: String) -> String {
        guard let s = model.sanatci(id) else { return id }
        return model.katalog?.bilinenAd(s.id) ?? s.ad
    }

    // MARK: Cevap yaprağı (D3)

    private var sanatciDogru: Bool { k.sanatciCevabi == k.dogru }

    /// Sanatçı soran turlardan mı (kurs bölümü ve ikonografi turları değil)
    private var sanatciTuru: Bool {
        if case .sanatci = tur.kip { return true }
        return false
    }

    /// Yaprağın üst satırları: sonuç, bilgi, ipucu (`kartGoster`, `tersGoster`, `soruTurlari.js` `yaprakAc`)
    private func yaprakBilgisi() -> (sonuc: (String, String), dogru: Bool, bilgi: (String, String), not: String) {
        let s = sanatci
        let dogru = k.sonuc == true
        if k.ikinci, let s {
            return (CevapYazilari.akimSonucu(akimDogru: dogru, sanatciDogru: sanatciDogru, bilmiyorum: k.bilmiyorum), dogru,
                    (s.akim, "\(s.ad) (\(CevapYazilari.yillar(s)))"),
                    CevapYazilari.akimNotu(akim: s.akim, akimlar: model.katalog?.akimlar ?? [], ipucu: model.ipucu(s.id)))
        }
        let sonuc = CevapYazilari.sonuc(dogru: dogru, bilmiyorum: k.bilmiyorum)
        let eserSatiri: String = {
            guard let s else { return CevapYazilari.eserAdi(k.resim.eser) }
            let yil = CevapYazilari.yillar(s)
            return "\(s.ad)\(yil.isEmpty ? "" : " (\(yil))") · \(CevapYazilari.eserAdi(k.resim.eser))"
        }()
        if case .kursBolumu = tur.kip {
            let b = model.kursBolumleri().first(where: { $0.id == k.dogru })
            let baslik = b.map { "\($0.id) · \($0.ad)" } ?? ad(k.dogru)
            let aralik = b.map { CalisKurallari.yuzyilAraligi(konular: $0.konular, sanatcilar: model.katalog?.sanatcilar ?? []) } ?? ""
            let alt = aralik.isEmpty ? eserSatiri : "\(aralik) · \(eserSatiri)"
            let not = s.map { "\($0.ad) kursta \($0.konu ?? 0). konuda işleniyor (\($0.akim))." } ?? ""
            return (sonuc, dogru, (baslik, alt), not)
        }
        if case .ikonografi = tur.kip {
            if let konu = model.ikonografiKonusu(k.dogru) {
                let alt = konu.turAdi.isEmpty ? eserSatiri : "\(konu.turAdi) · \(eserSatiri)"
                return (sonuc, dogru, (konu.ad, alt), konu.ozet)
            }
            return (sonuc, dogru, (ad(k.dogru), eserSatiri), "")
        }
        let ipucu = model.ipucu(k.resim.id)
        if k.ters != nil {
            return (sonuc, dogru, (CevapYazilari.eserAdi(k.resim.eser), "\(s?.ad ?? "") · \(s?.akim ?? "")"), ipucu)
        }
        // karışıkta akım henüz söylenmez
        let not = karisik && CevapYazilari.akimiAciklarMi(ipucu, s?.akim ?? "") ? "" : ipucu
        return (sonuc, dogru, (s?.ad ?? "", CevapYazilari.eserAdi(k.resim.eser)), not)
    }

    private func adreseGit(_ adres: String) {
        if let disAdreseGit {
            disAdreseGit(adres)
        } else {
            kapat()
            Gezgin.shared.git(adres)
        }
    }

    private var yaprak: some View {
        let (sonuc, dogru, bilgi, not) = yaprakBilgisi()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: dogru ? "checkmark" : "xmark").font(.system(size: 15, weight: .semibold))
                Text(sonuc.0).font(Yazi.okuma(21, italik: true))
                if !sonuc.1.isEmpty {
                    Text(sonuc.1).font(Yazi.sans(12)).foregroundStyle(Color(r.murekkep2))
                }
            }
            .foregroundStyle(Color(dogru ? r.dogruIkon : r.yanlisIkon))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("sonuc")
            VStack(alignment: .leading, spacing: 2) {
                Text(bilgi.0).font(Yazi.serif(22)).foregroundStyle(Color(r.murekkep))
                Text(bilgi.1).font(Yazi.okuma(15, italik: true)).foregroundStyle(Color(r.murekkep2))
            }
            if k.ters != nil, !sanatciDogru, let c = k.sanatciCevabi, let x = k.ters?.first(where: { $0.id == c }) {
                Text("Seçtiğin: \(CevapYazilari.eserAdi(x.eser)) · \(model.sanatci(c)?.ad ?? c)")
                    .font(Yazi.sans(13)).foregroundStyle(Color(r.murekkep2))
            }
            if !not.isEmpty { ipucuKutusu(not) }
            ikonografiHikaye
            karsilastirma
            ayrintilar
            HStack(spacing: 10) {
                PkSanatciDugmesi { adreseGit("#/sanatci/\(SiteYazisi.uriBileseni(k.resim.id))") }
                YaprakDugmesi(yazi: k.akimBekliyor ? "Hangi akım?" : tur.oturum.simdiki == nil ? "Turu bitir" : "Sonraki kart") {
                    Task { await model.sonraki() }
                }
                .accessibilityIdentifier("sonraki")
            }
            .padding(.top, 4)
        }
        .padding(.top, 16).padding(.horizontal, 18).padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(r.zemin).opacity(0.88)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(r.murekkep).opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 24, y: 24)
    }

    /// İkonografi turunda açılır hikâye ve konu sayfası bağlantısı (`soruTurlari.js` `yaprakAc`)
    @ViewBuilder private var ikonografiHikaye: some View {
        if case .ikonografi = tur.kip, let konu = model.ikonografiKonusu(k.dogru) {
            if !konu.hikaye.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { hikayeAcik.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Hikâyesi").font(Yazi.sans(13, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                            Image(systemName: hikayeAcik ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(r.murekkep2))
                        }
                    }
                    .buttonStyle(.plain)
                    if hikayeAcik {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(konu.hikaye.enumerated()), id: \.offset) { _, p in
                                Text(p).font(Yazi.sans(13.5)).foregroundStyle(Color(r.murekkep2)).lineSpacing(3)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }
            Button {
                adreseGit("#/konu/\(SiteYazisi.uriBileseni(konu.id))")
            } label: {
                HStack(spacing: 6) {
                    Text("Konu sayfası: \(konu.ad)").font(Yazi.sans(14, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                    Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(r.murekkep2))
                }
            }
            .buttonStyle(.plain).padding(.vertical, 4)
        }
    }

    /// İpucu sığmıyorsa dokununca tamamı açılır ("Devamı ↓" / "Kısalt ↑")
    private func ipucuKutusu(_ metin: String) -> some View {
        Button { withAnimation(.easeOut(duration: 0.2)) { ipucuAcik.toggle() } } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(metin).font(Yazi.sans(13.5)).foregroundStyle(Color(r.murekkep2))
                    .lineSpacing(3).lineLimit(ipucuAcik ? nil : 3).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if metin.count > 150 {
                    Text(ipucuAcik ? "Kısalt ↑" : "Devamı ↓").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(Color(r.murekkep2))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ipucu")
    }

    /// Yanlış cevapta: karıştırılan ikili şeridi (`KARISAN_ESIGI` kez) ve karşılaştırma bağlantısı
    @ViewBuilder private var karsilastirma: some View {
        if !k.ikinci, sanatciTuru, let c = k.sanatciCevabi, c != k.dogru, let secilen = model.sanatci(c), let s = sanatci {
            if (k.karisan ?? 0) >= Ogrenme.karisanEsigi {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu ikisini \(k.karisan ?? 0). kez karıştırdın. Yan yana bak:")
                        .font(Yazi.sans(13, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                    HStack(alignment: .top, spacing: 12) {
                        karsiSutun(s, etiket: "Doğrusu")
                        karsiSutun(secilen, etiket: "Senin cevabın")
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(r.yuzey)))
                .accessibilityIdentifier("karsi-serit")
            }
            Button {
                adreseGit(GoruntuleyiciKurallari.karsilastirmaAdresi(s.id, c))
            } label: {
                Label("Karşılaştır: \(kisaAd(s.id)) ↔ \(kisaAd(c))", systemImage: "square.split.2x1")
                    .font(Yazi.sans(14, agirlik: 600)).foregroundStyle(Color(r.murekkep))
            }
            .buttonStyle(.plain).padding(.vertical, 6)
            .accessibilityIdentifier("karsilastir")
        } else if k.ikinci, let a = k.akimCevabi, let s = sanatci, a != s.akim {
            Button {
                adreseGit("#/akim-karsilastir/\(SiteYazisi.uriBileseni(s.akim))/\(SiteYazisi.uriBileseni(a))")
            } label: {
                Label("Karşılaştır: \(s.akim) ↔ \(a)", systemImage: "square.split.2x1")
                    .font(Yazi.sans(14, agirlik: 600)).foregroundStyle(Color(r.murekkep))
            }
            .buttonStyle(.plain).padding(.vertical, 6)
            .accessibilityIdentifier("akim-karsilastir")
        }
    }

    private func karsiSutun(_ s: Sanatci, etiket: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text("\(etiket) · ").foregroundColor(Color(r.murekkep2)) + Text(kisaAd(s.id)).bold().foregroundColor(Color(r.murekkep)))
                .font(Yazi.sans(12))
                .lineLimit(1)
            HStack(spacing: 6) {
                let iki = model.karsiEserler(s.id, haric: k.resim.eser.anahtar)
                ForEach(0..<2, id: \.self) { i in
                    Group {
                        if i < iki.count {
                            UzakGorsel(url: model.gorsel(iki[i], 400), icerik: .fill)
                        } else {
                            Color(r.kenar)
                        }
                    }
                    .frame(height: 64).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Kapalı "Ayrıntılar": tekrar kutusu, seviye ve kaynak satırı
    @ViewBuilder private var ayrintilar: some View {
        let kutu = kutuBilgisi
        let seviye = seviyeYazisi
        let kaynak = GoruntuleyiciKurallari.kaynakYazisi(k.resim.eser,
            gorsel: GorselAdresleri.secilen(k.resim.eser, kotuler: model.ilerleme?.kotuGorseller ?? [:]))
        if kutu != nil || seviye != nil || !kaynak.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button { withAnimation(.easeOut(duration: 0.2)) { ayrintiAcik.toggle() } } label: {
                    HStack(spacing: 4) {
                        Text("Ayrıntılar").font(Yazi.sans(13, agirlik: 500)).tracking(0.26)
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .medium))
                            .rotationEffect(.degrees(ayrintiAcik ? 180 : 0))
                    }
                    .foregroundStyle(Color(r.murekkep2)).frame(minHeight: 32)
                }
                .buttonStyle(.plain)
                if ayrintiAcik {
                    if let kutu {
                        HStack {
                            HStack(spacing: 7) {
                                ForEach(0..<Leitner.araliklar.count, id: \.self) { i in
                                    Circle().fill(i < kutu.kutu ? Color(r.pirinc) : .clear)
                                        .overlay(Circle().stroke(i < kutu.kutu ? Color(r.pirinc) : Color(r.soluk), lineWidth: 1))
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .accessibilityLabel("Tekrar kutusu: \(Leitner.araliklar.count) kutudan \(kutu.kutu).")
                            Spacer()
                            Text(kutu.yazi).font(Yazi.sans(14)).foregroundStyle(Color(r.murekkep2))
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color(r.kenar)).frame(height: 1) }
                    }
                    if let seviye {
                        HStack(spacing: 6) {
                            if k.seviyeSonucu?.gecti == true { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)) }
                            Text(seviye)
                        }
                        .font(Yazi.sans(12)).foregroundStyle(Color(k.seviyeSonucu?.gecti == true ? r.dogruIkon : r.murekkep2))
                        .accessibilityIdentifier("seviye-satir")
                    }
                    if !kaynak.isEmpty {
                        Text(kaynak).font(Yazi.sans(11.5)).foregroundStyle(Color(r.murekkep3))
                    }
                }
            }
        }
    }

    /// Bu cevapla kutunun yeri. Karışık kartın birinci sorusunda skor henüz yazılmadı: aynı kuralla önceden hesaplanır.
    private var kutuBilgisi: (kutu: Int, ilerledi: Bool, yazi: String)? {
        guard case .sanatci = tur.kip, let il = model.ilerleme else { return nil }
        let gun = GunTarihi.gun(Date())
        let sk = il.skorlar[k.resim.id]
        if k.ikinci { return CevapYazilari.kutu(sk?.akim, bugun: gun) }
        if k.akimBekliyor { return CevapYazilari.kutu(Leitner.cevapla(sk?.sanatci, dogru: sanatciDogru, bugun: gun), bugun: gun) }
        return CevapYazilari.kutu(sk?.sanatci, bugun: gun)
    }

    private var seviyeYazisi: String? {
        guard let sonuc = k.seviyeSonucu, let s = sanatci, let il = model.ilerleme else { return nil }
        var kayit = Seviye.kayit(il.seviyeler, s.akim)
        // karışıkta birinci sorudan sonra seviye henüz yazılmadı
        if k.akimBekliyor && !sonuc.isinma {
            kayit = Seviye.cevapla(kayit, k.sanatciCevabi == nil ? .bilmiyorum : sanatciDogru ? .dogru : .yanlis).kayit
        }
        return CevapYazilari.seviyeSatiri(sonuc, akim: s.akim, kartSeviyesi: k.seviye, kayit: kayit)
    }
}

/// Ters sorunun kartpostalları büyük (`kartpostalAc`): yana kaydırarak öbürleri, "Bu eser" ile cevap
struct TersKartpostallar: View {
    let model: PekistirmeModeli
    let ters: [TurKarti.Resim]
    let baslangic: Int
    @Environment(\.dismiss) private var kapat
    @Environment(TemaDeposu.self) private var tema
    @State private var sira = 0

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 16) {
            TabView(selection: $sira) {
                ForEach(Array(ters.enumerated()), id: \.offset) { i, x in
                    UzakGorsel(url: model.gorsel(x.eser, 800), icerik: .fit)
                        .padding(12).background(Color(r.yuzey))
                        .overlay(alignment: .topTrailing) {
                            Text(String(Array("ABCD")[i])).font(Yazi.sans(14, agirlik: 700)).foregroundStyle(Color(r.zemin))
                                .frame(width: 30, height: 30).background(Circle().fill(Color(r.pirinc))).offset(x: 8, y: -8)
                        }
                        .padding(.horizontal, 28).padding(.vertical, 20)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            HStack(spacing: 10) {
                Button("Masaya bırak") { kapat() }
                    .font(Yazi.sans(15, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                    .padding(.horizontal, 18).frame(minHeight: 56)
                    .background(Capsule().fill(Color(r.yuzey))).overlay(Capsule().stroke(Color(r.kenar), lineWidth: 1))
                YaprakDugmesi(yazi: "Bu eser · \(String(Array("ABCD")[min(sira, 3)]))") {
                    let id = ters[sira].id
                    kapat()
                    Task { await model.cevapla(id) }
                }
                .accessibilityIdentifier("kp-bu")
            }
            .padding(.horizontal, 24).padding(.bottom, 12)
        }
        .background(Color(r.zemin).ignoresSafeArea())
        .onAppear { sira = baslangic }
    }
}

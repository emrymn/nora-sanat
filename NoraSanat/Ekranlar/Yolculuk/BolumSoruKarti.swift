// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (kartGoster, tersGoster, kartpostalAc, seviyeHaplari, ipucuMetni,
// karsiSeritHtml, kutuSatiri, seviyeSatiri, baskaEser), css/app.css (.soru-sahne, .soru-baslik, .secenekler,
// .alt-yaprak, .karsi-serit, .kutu-satir, .ters-levha, .seviye-hap) @ a866b86
import NoraCekirdek
import SwiftUI

/// Soru kartı ve cevap yaprağı (`kartGoster`, `tersGoster`).
///
/// Z3y: soru kısmı Neon'un tasarımıyla (dal `neon/soru-tasarim`, PR #67, birleştirilmedi; Emre seçti):
/// üst "Yön 3 · Geniş Tuval" (`tasarim/soru/yon-3.html`), şıklar "Şık 5 · El Yelpazesi" (`tasarim/soru/sik-5.html`).
/// Ölçüler ve yelpaze geometrisi çekirdekte: `SoruYelpazesi`. Alttaki şık alanının yüksekliği sabittir; eser
/// cevaptan önce ve sonra aynı boydadır. Cevap yaprağı (içeriği değişmedi) sabit alanın altından gelir.
struct BolumSoruKarti: View {
    let model: PekistirmeModeli
    let tur: TurKaydi
    let k: TurKarti
    let kapat: () -> Void
    let disAdreseGit: (String) -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var sistemHareketAz
    @State private var gosterim: GosterimIstegi?
    @State private var ipucuAcik = false
    @State private var ayrintiAcik = false
    /// Parmağın altındaki şık (sik-5.html `.muze-kart.basili`)
    @State private var basili: Int?

    private var r: TemaRenkleri { tema.renkler }
    private var sanatci: Sanatci? { model.sanatci(k.resim.id) }
    private var cevaplandi: Bool { k.sonuc != nil }
    private var toplam: Int { tur.oturum.kuyruk.count }
    private var sira: Int { min(tur.gorunenKonum + 1, max(1, toplam)) }
    private var karisik: Bool { k.akimlar != nil }
    private var hareketAz: Bool { tema.ayar.hareketAzaltilmis || sistemHareketAz }
    private var titresimAcik: Bool { Titresim.acik(model.ilerleme) }
    static let ustYukseklik: CGFloat = 52

    private var liste: [String] { k.ikinci ? (k.akimlar ?? []) : k.secenekler }
    private var dogruDeger: String { k.ikinci ? (sanatci?.akim ?? "") : k.dogru }
    private var secilen: String? { k.ikinci ? k.akimCevabi : k.sanatciCevabi }

    var body: some View {
        GeometryReader { g in
            let o = SoruYelpazesi.olcu(genislik: Double(g.size.width), yukseklik: Double(g.size.height), adlar: liste.map(ad))
            let tuvalH = max(140, g.size.height - Self.ustYukseklik - CGFloat(o.altYukseklik))
            ZStack(alignment: .top) {
                Color(r.zemin).ignoresSafeArea()
                SoruHalesi()
                ScrollViewReader { kaydir in
                    ScrollView {
                        VStack(spacing: 0) {
                            ustCubuk.frame(height: Self.ustYukseklik)
                            tuval(yukseklik: tuvalH, genislik: g.size.width)
                            deste(o).frame(height: CGFloat(o.altYukseklik))
                            if cevaplandi {
                                Color.clear.frame(height: 1).id("yaprak-ucu")
                                yaprak.padding(.horizontal, 10).padding(.top, 4).padding(.bottom, 16)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDisabled(!cevaplandi)
                    .onChange(of: cevaplandi) { _, simdi in
                        guard simdi else { return }
                        AccessibilityNotification.Announcement(durumYazisi.0).post()
                        // Yaprak alttan gelir: kartlar döndükten sonra başı görünecek kadar kaydırılır (eser küçülmez)
                        Task { @MainActor in
                            if !hareketAz { try? await Task.sleep(for: .milliseconds(520)) }
                            withAnimation(hareketAz ? nil : .spring(response: 0.5, dampingFraction: 0.9)) {
                                kaydir.scrollTo("yaprak-ucu", anchor: UnitPoint(x: 0.5, y: 0.8))
                            }
                        }
                    }
                }
            }
        }
        .animation(hareketAz ? nil : .spring(response: 0.42, dampingFraction: 0.86), value: cevaplandi)
        .fullScreenCover(item: $gosterim) { g in
            Goruntuleyici(eserler: g.eserler, baslangic: g.baslangic, gizli: g.gizli).environment(tema)
        }
    }

    // MARK: Üst çubuk (yon-3.html `.ust-bar`: cam ×, birleşik nokta + sayaç hapı, pirinç seviye)

    private var ustCubuk: some View {
        ZStack {
            HStack(spacing: 10) {
                Button(action: kapat) {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(r.murekkep))
                        .frame(width: 44, height: 44)
                        .background(CamZemin(sekil: Circle()))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Turdan çık")
                Spacer(minLength: 0)
                Text(k.seviye.map { Seviye.bul($0).ad } ?? "")
                    .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                    .foregroundStyle(Color(r.pirinc))
                    .lineLimit(1)
                    .frame(minWidth: 44, alignment: .trailing)
                    .accessibilityLabel(k.seviye.map { "Seviye: \(Seviye.bul($0).ad)" } ?? "")
            }
            birlesikHap
        }
        .padding(.horizontal, 16).padding(.top, 2).padding(.bottom, 4)
    }

    private var birlesikHap: some View {
        HStack(spacing: 10) {
            if let n = SoruYelpazesi.noktalar(toplam: toplam, konum: sira - 1, sonuc: k.sonuc) {
                HStack(spacing: 5) {
                    ForEach(Array(n.enumerated()), id: \.offset) { _, d in nokta(d) }
                }
            } else {
                GeometryReader { c in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(r.murekkep).opacity(0.22))
                        Capsule().fill(Color(r.pirinc)).frame(width: c.size.width * CGFloat(sira) / CGFloat(max(1, toplam)))
                    }
                }
                .frame(width: 64, height: 3)
            }
            Text("\(sira) / \(toplam)").font(Yazi.sans(12, agirlik: 500, stil: .caption1)).monospacedDigit()
                .foregroundStyle(Color(r.murekkep2))
                .padding(.leading, 8)
                .overlay(alignment: .leading) { Rectangle().fill(Color(r.murekkep).opacity(0.12)).frame(width: 1, height: 14) }
        }
        .padding(.horizontal, 14).frame(minHeight: 36)
        .background(CamZemin(sekil: Capsule()))
        .animation(hareketAz ? nil : .easeOut(duration: 0.3), value: k.sonuc)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Soru \(sira) / \(toplam)")
        .accessibilityIdentifier("sayac")
    }

    @ViewBuilder private func nokta(_ d: SoruYelpazesi.NoktaDurumu) -> some View {
        switch d {
        case .gecildi: Circle().fill(Color(r.pirinc)).frame(width: 5, height: 5)
        case .simdi: Circle().fill(Color(r.murekkep)).frame(width: 5, height: 5).scaleEffect(1.4)
        case .dogru: Circle().fill(Color(r.dogru)).frame(width: 5, height: 5).scaleEffect(1.4)
        case .yanlis: Circle().strokeBorder(Color(r.yanlis), lineWidth: 1.6).frame(width: 7, height: 7)
        case .bekliyor: Circle().fill(Color(r.murekkep).opacity(0.24)).frame(width: 5, height: 5)
        }
    }

    // MARK: Eser (kırpılmaz, ekranın en büyük öğesi; dokununca adı gizli tam ekran)

    private func tuval(yukseklik h: CGFloat, genislik w: CGFloat) -> some View {
        Button {
            Titresim.secim(acik: titresimAcik)
            gosterim = GosterimIstegi(eserler: [k.resim.eser], gizli: !cevaplandi)
        } label: {
            SoruGorseli(url: model.gorsel(k.resim.eser, 800), yedek: yedekAdres(k.resim.eser), yukseklik: h - 10,
                        enGenis: w - 28, kose: 16) {
                if !cevaplandi { Task { await model.baskaEser() } }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cevaplandi ? CevapYazilari.eserAdi(k.resim.eser) : "Sorulan eser. Görseli büyüt")
        .accessibilityIdentifier("soru-resim")
        .frame(width: w, height: h)
    }

    // MARK: Şık alanı (sik-5.html `.deste-bolge`): sabit yükseklik

    private func deste(_ o: SoruYelpazesi.Olcu) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(soruYazisi).font(Yazi.serif(o.kucuk ? 19 : 22, stil: .title3)).lineLimit(1).minimumScaleFactor(0.8)
                    .foregroundStyle(Color(r.murekkep))
                    .accessibilityAddTraits(.isHeader)
                if karisik {
                    Text("Soru \(k.ikinci ? 2 : 1) / 2").font(Yazi.sans(12, agirlik: 600, stil: .caption1))
                        .foregroundStyle(Color(r.pirinc)).lineLimit(1)
                }
                Spacer(minLength: 4)
                if !cevaplandi {
                    Button { Task { await model.cevapla(nil) } } label: {
                        Text("Bilmiyorum").font(Yazi.okuma(15.5, italik: true)).foregroundStyle(Color(r.murekkep2))
                            .padding(.leading, 10).padding(.trailing, 2).frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -6)
                    .accessibilityIdentifier("bilmiyorum")
                }
            }
            .frame(height: o.kucuk ? 30 : 34)
            .padding(.horizontal, 6)

            ZStack {
                if cevaplandi {
                    donukKartlar(o).transition(.opacity)
                } else {
                    yelpaze(o).transition(hareketAz ? .opacity : .opacity.combined(with: .offset(y: 28)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if cevaplandi {
                gecisSatiri.transition(hareketAz ? .opacity : .opacity.combined(with: .offset(y: 10)))
            }
        }
        .padding(.horizontal, o.kucuk ? 12 : 14)
        .padding(.top, o.kucuk ? 4 : 6).padding(.bottom, o.kucuk ? 12 : 18)
    }

    private var soruYazisi: String { k.ikinci ? "Hangi akım?" : "Bu eser kimin?" }

    private func ad(_ id: String) -> String { k.ikinci ? id : model.sanatci(id)?.ad ?? id }

    /// Dört dikey müze kartı yelpaze gibi (`.yelpaze`, `.muze-kart[data-i]`)
    private func yelpaze(_ o: SoruYelpazesi.Olcu) -> some View {
        let adet = liste.count
        return HStack(spacing: -CGFloat(o.ustUste)) {
            ForEach(Array(liste.enumerated()), id: \.element) { i, deger in
                let d = SoruYelpazesi.kart(i, adet: adet, basili: basili, hareketAz: hareketAz)
                Button {
                    basili = nil
                    Task { await model.cevapla(deger) }
                } label: {
                    MuzeKarti(ad: ad(deger), olcu: o, akim: k.ikinci, parlak: d.basili)
                }
                .buttonStyle(KartBasisi(i: i, basili: $basili))
                .rotationEffect(.degrees(d.aci), anchor: .bottom)
                .scaleEffect(d.olcek, anchor: .bottom)
                .offset(y: d.y)
                .opacity(d.opaklik)
                .zIndex(d.z)
                .accessibilityLabel("Şık \(i + 1), \(ad(deger))")
                .accessibilityIdentifier("sik-\(i)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, o.kucuk ? 10 : 14)
        .animation(hareketAz ? nil : .spring(response: 0.26, dampingFraction: 0.78), value: basili)
        .onChange(of: basili) { _, yeni in
            if yeni != nil { Titresim.secim(acik: titresimAcik) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(k.ikinci ? "akim-secenekleri" : "sanatci-secenekleri")
    }

    /// Cevaptan sonra: elenen iki kart çekilir; doğru ve seçilen düzleşip ters döner (D3)
    private func donukKartlar(_ o: SoruYelpazesi.Olcu) -> some View {
        HStack(spacing: CGFloat(o.cevapAraligi)) {
            ForEach(SoruYelpazesi.kalanlar(liste, dogru: dogruDeger, secilen: secilen), id: \.self) { deger in
                let dogruMu = deger == dogruDeger
                KartArkasi(ad: ad(deger), dogru: dogruMu, olcu: o)
                    .frame(width: CGFloat(o.cevapGenisligi), height: CGFloat(o.cevapYuksekligi))
                    .transition(hareketAz ? .identity : .asymmetric(
                        insertion: .modifier(active: KartDonusu(aci: 90, olcek: 0.94, opaklik: 0.5),
                                             identity: KartDonusu(aci: 0, olcek: 1, opaklik: 1)),
                        removal: .opacity))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(dogruMu ? "Doğrusu" : "Seçtiğin"): \(ad(deger))")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(k.ikinci ? "akim-secenekleri" : "sanatci-secenekleri")
    }

    private var durumYazisi: (String, String) {
        if k.ikinci { return CevapYazilari.akimSonucu(akimDogru: k.sonuc == true, sanatciDogru: sanatciDogru, bilmiyorum: k.bilmiyorum) }
        return CevapYazilari.sonuc(dogru: k.sonuc == true, bilmiyorum: k.bilmiyorum)
    }

    /// Durum yazısı ve tek dolu geçiş düğmesi (`.gecis-satir`; "Tekrar" yok)
    private var gecisSatiri: some View {
        let (ana, ek) = durumYazisi
        let dogru = k.sonuc == true
        return HStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: dogru ? "checkmark" : "xmark").font(.system(size: 12, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(ana).font(Yazi.sans(14, agirlik: 600))
                    if !ek.isEmpty {
                        Text(ek).font(Yazi.sans(11, stil: .caption2)).foregroundStyle(Color(r.murekkep2))
                            .lineLimit(2).minimumScaleFactor(0.8)
                    }
                }
            }
            .foregroundStyle(Color(dogru ? r.dogruIkon : r.yanlisIkon))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("sonuc")
            Spacer(minLength: 4)
            Button {
                if k.akimBekliyor { Titresim.dokunus(acik: titresimAcik) }
                Task { await model.sonraki() }
            } label: {
                HStack(spacing: 6) {
                    Text(gecisYazisi).font(Yazi.sans(14.5, agirlik: 600)).lineLimit(1).minimumScaleFactor(0.8)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 22).frame(minHeight: 46)
                .foregroundStyle(Color(r.zemin))
                .background(Capsule().fill(Color(r.murekkep)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("sonraki")
        }
        .padding(.top, 10)
        .overlay(alignment: .top) { Rectangle().fill(Color(r.murekkep).opacity(0.12)).frame(height: 1) }
    }

    private var gecisYazisi: String {
        k.akimBekliyor ? "Hangi akım?" : tur.oturum.simdiki == nil ? "Turu bitir" : "Sonraki"
    }

    private func yedekAdres(_ e: Eser) -> URL? {
        guard let katalog = model.katalog, let g = GorselAdresleri.secilen(e, kotuler: model.ilerleme?.kotuGorseller ?? [:]) else { return nil }
        return URL(string: katalog.gorsel.yedek(g))
    }

    private func kisaAd(_ id: String) -> String {
        guard let s = model.sanatci(id) else { return id }
        return model.katalog?.bilinenAd(s.id) ?? s.ad
    }

    // MARK: Cevap yaprağı (D3)

    private var sanatciDogru: Bool { k.sanatciCevabi == k.dogru }

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
        let ipucu = model.ipucu(k.resim.id)
        // karışıkta akım henüz söylenmez
        let not = karisik && CevapYazilari.akimiAciklarMi(ipucu, s?.akim ?? "") ? "" : ipucu
        return (sonuc, dogru, (s?.ad ?? "", CevapYazilari.eserAdi(k.resim.eser)), not)
    }

    /// Cevap yaprağı: içerik Z3y'den önceki gibi. Sonuç satırı ve "Sonraki" düğmesi yaprağın üstündeki geçiş
    /// satırına çıktı (sik-5.html `.gecis-satir`); yaprakta "Sanatçı" düğmesi kaldı.
    private var yaprak: some View {
        let (_, _, bilgi, not) = yaprakBilgisi()
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bilgi.0).font(Yazi.serif(22)).foregroundStyle(Color(r.murekkep))
                Text(bilgi.1).font(Yazi.okuma(15, italik: true)).foregroundStyle(Color(r.murekkep2))
            }
            if !not.isEmpty { ipucuKutusu(not) }
            karsilastirma
            ayrintilar
            HStack(spacing: 10) {
                PkSanatciDugmesi { disAdreseGit("#/sanatci/\(SiteYazisi.uriBileseni(k.resim.id))") }
                Spacer(minLength: 0)
            }
            .padding(.top, 4)
        }
        .padding(.top, 16).padding(.horizontal, 18).padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(r.yuzey).opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(r.murekkep).opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(tema.ayar.tema == .gece ? 0.5 : 0.12), radius: 20, y: 12)
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
        if !k.ikinci, let c = k.sanatciCevabi, c != k.dogru, let secilen = model.sanatci(c), let s = sanatci {
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
                disAdreseGit(GoruntuleyiciKurallari.karsilastirmaAdresi(s.id, c))
            } label: {
                Label("Karşılaştır: \(kisaAd(s.id)) ↔ \(kisaAd(c))", systemImage: "square.split.2x1")
                    .font(Yazi.sans(14, agirlik: 600)).foregroundStyle(Color(r.murekkep))
            }
            .buttonStyle(.plain).padding(.vertical, 6)
            .accessibilityIdentifier("karsilastir")
        } else if k.ikinci, let a = k.akimCevabi, let s = sanatci, a != s.akim {
            Button {
                disAdreseGit("#/akim-karsilastir/\(SiteYazisi.uriBileseni(s.akim))/\(SiteYazisi.uriBileseni(a))")
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

// MARK: Z3y parçaları (sik-5.html, yon-3.html)

/// Cam zemin (`.cam-yuvarlak`, `.birlesik-hap`): yarı saydam zemin + bulanık arka + ince kenar
private struct CamZemin<S: InsettableShape>: View {
    let sekil: S
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        sekil.fill(Color(r.zemin).opacity(tema.ayar.tema == .gece ? 0.62 : 0.85))
            .background(.ultraThinMaterial, in: sekil)
            .overlay(sekil.strokeBorder(Color(r.murekkep).opacity(0.12), lineWidth: 1))
    }
}

/// Zeminde eserin paletinden sakin, sabit hale (yon-3 / sik-5 `.zemin-hale`). Vurgu `ekranRengi`'nden gelir
/// (sorulan eserin paleti, BolumTuruEkrani); akım rengi kullanılmaz.
private struct SoruHalesi: View {
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let gece = tema.ayar.tema == .gece
        GeometryReader { g in
            ZStack {
                RadialGradient(colors: [Color(r.vurgu).opacity(gece ? 0.32 : 0.15), .clear],
                               center: UnitPoint(x: 0.5, y: 0.24), startRadius: 0, endRadius: 0.62 * g.size.width)
                RadialGradient(colors: [Color(r.vurguKoyu).opacity(gece ? 0.15 : 0.08), .clear],
                               center: UnitPoint(x: 0.84, y: 0.78), startRadius: 0, endRadius: 0.42 * g.size.width)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Kartın nötr elmas süsü (`.kart-sus`, 16'lık kutuda yıldız-elmas)
private struct Elmas: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 16
        func n(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * s, y: r.minY + y * s) }
        var p = Path()
        p.move(to: n(8, 1))
        p.addLine(to: n(10.2, 5.8)); p.addLine(to: n(15, 8)); p.addLine(to: n(10.2, 10.2)); p.addLine(to: n(8, 15))
        p.addLine(to: n(5.8, 10.2)); p.addLine(to: n(1, 8)); p.addLine(to: n(5.8, 5.8))
        p.closeSubpath()
        return p
    }
}

/// Kartın yüzü: Gece'de koyu karton, Gündüz'de keten karton (`--kart-bg`, `--doku`)
private struct KartZemini: View {
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let gece = tema.ayar.tema == .gece
        ZStack {
            Color(r.yuzey)
            LinearGradient(colors: gece ? [Color.white.opacity(0.06), Color.black.opacity(0.08)]
                                        : [Color.white.opacity(0.7), Color(r.zemin).opacity(0.55)],
                           startPoint: UnitPoint(x: 0.42, y: 0), endPoint: UnitPoint(x: 0.58, y: 1))
            if !gece {
                // keten: ince yatay ve dikey iplikler
                Canvas { c, boyut in
                    let renk = Color(r.murekkep).opacity(0.035)
                    var y: CGFloat = 0
                    while y < boyut.height {
                        c.fill(Path(CGRect(x: 0, y: y, width: boyut.width, height: 0.5)), with: .color(renk))
                        y += 2
                    }
                    var x: CGFloat = 0
                    while x < boyut.width {
                        c.fill(Path(CGRect(x: x, y: 0, width: 0.5, height: boyut.height)), with: .color(renk))
                        x += 3
                    }
                }
            }
        }
    }
}

/// Önyüz (`.muze-kart .kart-govde`): elmas süs, ad, alt çizgi; ince pirinç iç çerçeve (akım sorusunda çift çizgi).
/// İpucu yok: renk, yıl, akım yazılmaz.
private struct MuzeKarti: View {
    let ad: String
    let olcu: SoruYelpazesi.Olcu
    let akim: Bool
    let parlak: Bool
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let sekil = RoundedRectangle(cornerRadius: 13, style: .continuous)
        ZStack {
            KartZemini().clipShape(sekil)
            icCerceve(Color(r.pirinc))
            VStack(spacing: 0) {
                Elmas().fill(Color(r.pirinc).opacity(0.75)).frame(width: 10, height: 10)
                Spacer(minLength: 4)
                Text(ad).font(Yazi.sans(CGFloat(olcu.punto), agirlik: 500, stil: .footnote))
                    .lineSpacing(1)
                    .multilineTextAlignment(.center)
                    .lineLimit(3).minimumScaleFactor(0.75)
                    .foregroundStyle(Color(r.murekkep))
                    .frame(width: CGFloat(olcu.kartGenisligi - olcu.icPay))
                Spacer(minLength: 4)
                Capsule().fill(Color(r.pirinc).opacity(0.42)).frame(width: 18, height: 1.5)
            }
            .padding(.vertical, 10)
        }
        .frame(width: CGFloat(olcu.kartGenisligi), height: CGFloat(olcu.kartYuksekligi))
        .overlay(sekil.strokeBorder(parlak ? Color(r.pirinc) : Color(r.murekkep).opacity(0.17), lineWidth: 1))
        .shadow(color: parlak ? Color(r.pirinc).opacity(0.45) : .clear, radius: 1)
        .shadow(color: .black.opacity(tema.ayar.tema == .gece ? (parlak ? 0.62 : 0.56) : (parlak ? 0.22 : 0.16)),
                radius: parlak ? 19 : 12, x: parlak ? 0 : -4, y: parlak ? 22 : 10)
        .contentShape(sekil)
    }

    @ViewBuilder private func icCerceve(_ p: Color) -> some View {
        let ic = RoundedRectangle(cornerRadius: 8, style: .continuous)
        if akim {
            // `.akim-sus`: çift pirinç çizgi
            ic.inset(by: 5).strokeBorder(p.opacity(0.3), lineWidth: 1)
            ic.inset(by: 7).strokeBorder(p.opacity(0.3), lineWidth: 1)
        } else {
            ic.inset(by: 5).strokeBorder(p.opacity(0.22), lineWidth: 1)
        }
    }
}

/// Arka yüz (`.yelpaze.cevapli .muze-kart`): yeşil ya da mercan mühür, ad, "Doğrusu" / "Seçtiğin"; çift iç çerçeve
private struct KartArkasi: View {
    let ad: String
    let dogru: Bool
    let olcu: SoruYelpazesi.Olcu
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let renk = Color(dogru ? r.dogru : r.yanlis)
        let sekil = RoundedRectangle(cornerRadius: 13, style: .continuous)
        let ic = RoundedRectangle(cornerRadius: 8, style: .continuous)
        ZStack {
            KartZemini().clipShape(sekil)
            sekil.fill(Color(dogru ? r.dogruZemin : r.yanlisZemin))
            ic.inset(by: 5).strokeBorder(renk.opacity(0.48), lineWidth: 1)
            ic.inset(by: 7.5).strokeBorder(renk.opacity(0.48), lineWidth: 1)
            VStack(spacing: olcu.kucuk ? 4 : 7) {
                Image(systemName: dogru ? "checkmark" : "xmark").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(r.zemin))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(renk))
                Text(ad).font(Yazi.sans(14, agirlik: 500, stil: .footnote)).foregroundStyle(Color(r.murekkep))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
                Text(dogru ? "Doğrusu" : "Seçtiğin").font(Yazi.sans(11.5, agirlik: 600, stil: .caption2))
                    .foregroundStyle(Color(r.murekkep2))
            }
        }
        .overlay(sekil.strokeBorder(renk, lineWidth: 1))
    }
}

/// `@keyframes kartDon`: y ekseninde 90°'den düzleşir
private struct KartDonusu: ViewModifier {
    let aci: Double
    let olcek: CGFloat
    let opaklik: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(aci), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
            .scaleEffect(olcek)
            .opacity(opaklik)
    }
}

/// Basılı an: parmağın altındaki kartı bildirir (yelpaze ona göre sıyrılır, ötekiler söner; titreşim yelpazede)
private struct KartBasisi: ButtonStyle {
    let i: Int
    @Binding var basili: Int?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, basiyor in
                if basiyor {
                    basili = i
                } else if basili == i {
                    basili = nil
                }
            }
    }
}

// Kaynak: sanat-atlasi js/ekranlar/{pekistir,soruTurlari}.js (pekistir, kartCiz, ozetCiz, gecenlerHtml, eylemKarti),
// css/app.css (.ozet, .devam-kart) @ a866b86
import SwiftUI
import NoraCekirdek

@MainActor
struct PekistirmeEkrani: View {
    @Environment(TemaDeposu.self) private var tema
    @State private var icModel = PekistirmeModeli()
    @State private var yeniKip: PekistirmeKipi?
    @State private var yeniSeviye: Int?
    var disModel: PekistirmeModeli? = nil
    var ilkTur: PekistirmeKipi? = nil
    var disAdreseGit: ((String) -> Void)? = nil
    private var model: PekistirmeModeli { disModel ?? icModel }
    private var murekkep: Color { Color(tema.renkler.murekkep) }
    private var yuzey: Color { Color(tema.renkler.yuzey) }

    /// Ekranda ne var (DEBUG CI adımları ve erişilebilirlik için)
    private var ekranAdi: String {
        guard model.turAcik, let tur = model.kayit else { return model.katalog == nil ? "yukleniyor" : "menu" }
        if tur.tanismaBekliyor || tur.kart?.tanisma != nil { return "tanisma" }
        guard let k = tur.kart else { return "ozet" }
        return k.sonuc == nil ? "kart" : "yaprak"
    }

    private func adreseGit(_ adres: String) {
        if let disAdreseGit {
            disAdreseGit(adres)
        } else {
            model.turAcik = false
            Gezgin.shared.git(adres)
        }
    }

    var body: some View {
        Group {
            if model.turAcik, let tur = model.kayit {
                if tur.tanismaBekliyor || tur.kart?.tanisma != nil {
                    TanismaGorunumu(model: model, tur: tur) { model.turAcik = false }
                } else if let k = tur.kart {
                    KartGorunumu(
                        model: model,
                        tur: tur,
                        k: k,
                        kapat: { model.turAcik = false },
                        disAdreseGit: { adreseGit($0) }
                    )
                    .id("\(tur.gorunenKonum)|\(k.resim.eser.anahtar)|\(k.ikinci)")
                } else {
                    ScrollView { ozet(tur).padding(.horizontal, 24) }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let katalog = model.katalog { menu(katalog) }
                        else if model.hata == nil { ProgressView("Kartlar hazırlanıyor…") }
                    }
                    .padding(20).frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let hata = model.hata {
                VStack(alignment: .leading, spacing: 8) {
                    Text(hata).font(Yazi.okuma(16))
                    Button("Güncel kaydı yükle") { Task { await model.yukle() } }.font(Yazi.sans(15, agirlik: 600))
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(yuzey)).padding(12)
            }
        }
        .background(Color(tema.renkler.zemin).ignoresSafeArea())
        .foregroundStyle(murekkep).font(Yazi.sans(16)).tint(murekkep)
        .disabled(model.mesgul)
        .task {
            guard model.katalog == nil else { return }
            await model.yukle()
            #if DEBUG
            if NoraSanatApp.arguman("-pekistirAdim") != nil, model.kayit != nil {
                model.turAcik = true   // CI: önceki açılışın turu sürer
                return
            }
            #endif
            if model.kayit == nil, let ilkTur { await model.basla(ilkTur) }
        }
        #if DEBUG
        .onChange(of: ekranAdi, initial: true) { _, ad in ciAdimi(ad) }
        #endif
        .confirmationDialog("Yarım tur yerine yeni tur başlatılsın mı?", isPresented: Binding(
            get: { yeniKip != nil }, set: { if !$0 { yeniKip = nil } }
        ), titleVisibility: .visible, presenting: yeniKip) { kip in
            Button("Sil, yeni başla", role: .destructive) { Task { await model.basla(kip, seviye: yeniSeviye) } }
            Button("Vazgeç", role: .cancel) {}
        } message: { _ in
            Text("Yeni tur başlarsa yarım kalan tur silinir.")
        }
    }

    #if DEBUG
    /// CI (`-ekran pekistir -pekistirAdim <tanisma|kart|yaprak>`): istenen adıma kadar kendi yürür, varınca işaret dosyası yazar.
    /// Açılışlar arası tur sürer: tanışma → kart → (yanlış bir şıkla) cevap yaprağı.
    private func ciAdimi(_ ad: String) {
        guard let hedef = NoraSanatApp.arguman("-pekistirAdim") ?? (NoraSanatApp.arguman("-ekran") == "pekistir" ? "ilk" : nil) else { return }
        let isaret = FileManager.default.temporaryDirectory.appendingPathComponent("pekistirme-hazir")
        let vardi = hedef == "ilk" ? ["tanisma", "kart"].contains(ad) : hedef == ad
        if vardi { try? Data(ad.utf8).write(to: isaret); return }
        guard let tur = model.kayit, model.turAcik else { return }
        Task {
            try? await Task.sleep(for: .seconds(2))
            if ad == "tanisma", hedef != "tanisma" { await model.tanismaGec() }
            if ad == "kart", hedef == "yaprak", let k = tur.kart {
                let yanlis: String? = k.ters == nil
                    ? k.secenekler.first(where: { $0 != k.dogru })
                    : k.ters?.first(where: { $0.id != k.dogru })?.id
                await model.cevapla(yanlis)
            }
        }
    }
    #endif

    private func basla(_ kip: PekistirmeKipi, seviye: Int? = nil) {
        if let k = model.kayit, !k.bitti {
            yeniSeviye = seviye
            yeniKip = kip
        } else { Task { await model.basla(kip, seviye: seviye) } }
    }

    @ViewBuilder private func menu(_ katalog: SiteKatalogu) -> some View {
        Text("Pekiştir").font(Yazi.serif(38))
        if let tur = model.kayit, !tur.bitti {
            Button { model.turAcik = true } label: {
                satir("Yarım kalan tur", "\(CevapYazilari.kipAdi(tur.kip)) · \(min(tur.gorunenKonum + 1, tur.oturum.kuyruk.count)) / \(tur.oturum.kuyruk.count)")
            }
            .buttonStyle(.plain)
        }
        Button { basla(.sanatci(.karisik)) } label: { satir("Karışık tur", "Sanatçıyı ve akımı bul") }.buttonStyle(.plain)
        Menu("Döneme göre") {
            Button("Bütün dönemler") { basla(.sanatci(.donem(nil))) }
            ForEach(katalog.akimlar) { akim in
                Button(akim.ad) { basla(.sanatci(.donem(akim.ad))) }
            }
        }
        Menu("İşlenen konular") {
            ForEach(katalog.konular.filter { model.ilerleme?.islenenKume.contains($0.no) == true }) { k in
                Button("\(k.no) · \(k.baslik)") { basla(.sanatci(.konu(k.no))) }
            }
        }
        Button("Bölüm turu") { basla(.kursBolumu) }
        Button("İkonografi turu") { basla(.ikonografi) }
        Button("Hatalarım") { basla(.sanatci(.hatalar)) }
    }

    private func satir(_ baslik: String, _ alt: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(baslik).font(Yazi.serif(24))
                Text(alt).font(Yazi.sans(14)).foregroundStyle(Color(tema.renkler.murekkep2))
            }
            Spacer()
            Image(systemName: "chevron.right")
        }.padding().background(yuzey, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Tur özeti (`ozetCiz`)

    @ViewBuilder private func ozet(_ tur: TurKaydi) -> some View {
        let r = tema.renkler
        let toplam = tur.oturum.dogru + tur.oturum.yanlis
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    PkEtiket(yazi: "Tur bitti")
                    Text(CevapYazilari.kipAdi(tur.kip)).font(Yazi.serif(34)).accessibilityAddTraits(.isHeader)
                }
                Spacer()
                Button { model.turAcik = false } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .light)).frame(width: 44, height: 44)
                }
                .foregroundStyle(Color(r.murekkep2)).accessibilityLabel("Kapat")
            }
            .padding(.top, 16)
            if toplam == 0 {
                Text("Bu seçim için şu an kart yok.").font(Yazi.serif(26)).padding(.top, 28)
                Text(bosNotu(tur.kip)).font(Yazi.sans(14)).foregroundStyle(Color(r.murekkep2)).padding(.top, 8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    PkEtiket(yazi: "Sonuç", renk: Color(r.murekkep2))
                    Text("\(tur.oturum.dogru) / \(toplam)").font(Yazi.serif(64)).monospacedDigit()
                        .contentTransition(.numericText())
                    Text("kart doğru").font(Yazi.sans(14, agirlik: 500)).foregroundStyle(Color(r.murekkep2))
                    Text(CevapYazilari.ozetNotu(yanlis: tur.oturum.yanlis)).font(Yazi.okuma(19, italik: true))
                        .foregroundStyle(Color(r.murekkep)).padding(.top, 10)
                }
                .padding(.top, 32)
                .accessibilityElement(children: .combine)
                gecenler(tur)
            }
            eylemKarti(tur).padding(.top, 32)
            Button { adreseGit("#/") } label: {
                Text("Tuval’e dön").font(Yazi.sans(15, agirlik: 600)).underline().foregroundStyle(Color(r.murekkep2))
                    .frame(maxWidth: .infinity).frame(minHeight: 44)
            }
            .buttonStyle(.plain).padding(.top, 12)
        }
        .accessibilityIdentifier("ozet")
    }

    private func bosNotu(_ kip: PekistirmeKipi) -> String {
        switch kip {
        case .sanatci(.hatalar): return "Son 7 günde yanlış yaptığın sanatçı kalmadı."
        case .sanatci(.konu): return "Bu konunun açık sanatçısı yok ya da görselleri bulunamadı."
        default: return "Bugünkü yeni sanatçı sınırına (\(Leitner.gunlukYeniSiniri)) ulaşmış olabilirsin ya da bu sanatçıların görseli bulunamadı."
        }
    }

    /// Bu turda seviye atlayan dönemler (`gecenlerHtml`)
    @ViewBuilder private func gecenler(_ tur: TurKaydi) -> some View {
        let r = tema.renkler
        let akimlar = Set(model.katalog?.akimlar.map(\.ad) ?? [])
        let liste = (tur.gecenler ?? []).filter { akimlar.contains($0.akim) }
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                PkEtiket(yazi: "Seviye atlayan dönemler")
                ForEach(Array(liste.enumerated()), id: \.offset) { _, g in
                    Button { basla(.sanatci(.donem(g.akim))) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(g.akim).font(Yazi.sans(16, agirlik: 600))
                                Text("\(Seviye.bul(g.seviye).ad) seviyeye geçti").font(Yazi.sans(13)).foregroundStyle(Color(r.murekkep2))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color(r.murekkep2))
                        }
                        .padding(14).background(RoundedRectangle(cornerRadius: 14).fill(Color(r.yuzey)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 28)
            .accessibilityIdentifier("gecenler")
        }
    }

    /// "Bir tur daha" (`eylemKarti`): solda son kartın eseri, sağda halkalı düğme
    private func eylemKarti(_ tur: TurKaydi) -> some View {
        let r = tema.renkler
        return Button { Task { await model.basla(tur.kip, seviye: tur.seviye) } } label: {
            HStack(spacing: 14) {
                if let son = tur.sonResim {
                    UzakGorsel(url: model.gorsel(son.eser, 400), icerik: .fill)
                        .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 6))
                }
                VStack(alignment: .leading, spacing: 4) {
                    PkEtiket(yazi: "Yeni tur")
                    Text("Bir tur daha").font(Yazi.sans(17, agirlik: 600)).foregroundStyle(Color(r.murekkep))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(r.vurguAcikYazi))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color(r.vurguAcik)))
                    .overlay(Circle().stroke(Color(r.vurguAcik).opacity(0.5), lineWidth: 1).padding(-3))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(r.yuzey)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(r.kenar), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bir-tur-daha")
    }
}

// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (bildirimBolumu, elleOdakBolumu, gununResmiBolumu, Sürüm, Yenilikler),
// js/yenilikler.js, js/bildirim.js (bildirimMetni), js/gorsel.js (elle odaklar) @ a866b86
// Z3x: Ayarlar'ın Hatırlatma (yeni: uygulamanın içinde; iPhone Ayarlar'ındaki Settings.bundle ile aynı anahtarlar),
// Hakkında (Yenilikler yaprağı, Sürüm, Kaynaklar) ve kapalı Gelişmiş bölümü (geliştirici modu, hata günlüğü, bildirdiğim
// görseller, elle odaklar, ana ekranın resimleri). Görünüş: Neon'un Yön 2'si (yon-2.html). Davranış C4b / Z2c-3'teki gibi.
import NoraCekirdek
import SwiftUI

/// Panoya kopyala
@MainActor
private func kopyala(_ depo: BenDeposu, _ metin: String) {
    UIPasteboard.general.string = metin
    depo.mesaj = "Panoya kopyalandı."
}

// MARK: Hata günlüğü

/// Uygulamanın hata günlüğü (`HataGunlugu`, UserDefaults'ta; en çok 50 kayıt)
@MainActor @Observable
final class HataGunluguDeposu {
    static let shared = HataGunluguDeposu()
    private static let anahtar = "nora.hataGunlugu.v1"
    private(set) var gunluk: HataGunlugu

    private init() {
        gunluk = UserDefaults.standard.data(forKey: Self.anahtar)
            .flatMap { try? JSONDecoder().decode(HataGunlugu.self, from: $0) } ?? HataGunlugu()
    }

    func ekle(_ yer: String, _ metin: String) {
        gunluk.ekle(HataKaydi(t: ISO8601DateFormatter().string(from: Date()), yer: yer, metin: metin))
        kaydet()
    }

    func temizle() {
        gunluk.temizle()
        kaydet()
    }

    private func kaydet() {
        UserDefaults.standard.set(try? JSONEncoder().encode(gunluk), forKey: Self.anahtar)
    }
}

// MARK: Hatırlatma

/// Tekrar hatırlatması (aç/kapa), saati (07:00–23:00) ve simge rozeti. Açma/kapama ve saat `Hatirlatici`'nin
/// UserDefaults anahtarlarına yazılır (iPhone Ayarlar → Nora Sanat ile aynı); değişince bildirimler yeniden kurulur.
struct HatirlatmaBolumu: View {
    let depo: BenDeposu
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.scenePhase) private var evre
    @State private var acik = Hatirlatici.shared.acik
    @State private var saat = Hatirlatici.shared.saat
    @State private var saatAcik = false
    @State private var izin: HatirlatmaAyari.Izin = .sorulmadi

    var body: some View {
        let rozet = depo.il?.ayar("rozet")?.mantik ?? false
        VStack(alignment: .leading, spacing: 0) {
            AyarKarti {
                AnahtarSatiri(simge: .zil, ad: "Tekrar hatırlatması", alt: HatirlatmaAyari.altYazi(acik: acik),
                              acik: Binding(get: { acik }, set: hatirlatma))
                AyarCizgisi()
                AcilirSatir(simge: .saat, ad: "Saat", alt: HatirlatmaAyari.saatAltYazisi, acik: $saatAcik) {
                    SagDeger(metin: HatirlatmaAyari.yazi(saat), renk: \.pirinc)
                } icerik: {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(HatirlatmaAyari.saatler, id: \.self) { s in saatDugmesi(s) }
                    }
                }
                .disabled(!acik)
                AyarCizgisi()
                AnahtarSatiri(simge: .rozet, ad: "Simge rozeti", alt: "Ana ekranda bekleyen sayı",
                              acik: Binding(get: { rozet }, set: rozetAyarla))
            }
            AyarDipnotu(HatirlatmaAyari.dipnot(acik: acik, rozet: rozet, izin: izin))
        }
        .onChange(of: acik) { _, a in if !a { saatAcik = false } }
        .task(id: evre) { if evre == .active { yenile(); izin = await Hatirlatici.shared.izinDurumu() } }
        // iPhone Ayarlar'dan (Settings.bundle) değişirse satırlar da değişsin
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in yenile() }
    }

    private func yenile() {
        if acik != Hatirlatici.shared.acik { acik = Hatirlatici.shared.acik }
        if saat != Hatirlatici.shared.saat { saat = Hatirlatici.shared.saat }
    }

    /// `.saat-btn`: 44 pt, seçili pirinç kenar
    private func saatDugmesi(_ s: Int) -> some View {
        let r = tema.renkler
        let secili = s == saat
        return Button {
            saat = s
            Hatirlatici.shared.ayarla(saat: s)
        } label: {
            Text(HatirlatmaAyari.yazi(s))
                .font(Yazi.sans(13, agirlik: secili ? 700 : 500, stil: .footnote)).monospacedDigit()
                .foregroundStyle(Color(secili ? r.murekkep : r.murekkep2))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(secili ? r.yuzey2.karis(r.pirinc, 0.16) : r.yuzey2)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(secili ? r.pirinc : r.kenar), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(secili ? [.isSelected] : [])
    }

    private func hatirlatma(_ ac: Bool) {
        acik = ac
        Hatirlatici.shared.ayarla(acik: ac)
        guard ac else { return }
        Task {
            // Açınca izni hemen sor (Hatirlatici yalnız bekleyen bir tekrar olunca soruyordu)
            _ = await Hatirlatici.shared.izinVar(sor: true)
            izin = await Hatirlatici.shared.izinDurumu()
            if izin == .yok { depo.mesaj = "Hatırlatma için iPhone Ayarlar → Nora Sanat → Bildirimler’den izin ver." }
        }
    }

    private func rozetAyarla(_ ac: Bool) {
        depo.yap {
            if ac {
                guard await Hatirlatici.shared.izinVar(sor: true) else {
                    izin = await Hatirlatici.shared.izinDurumu()
                    depo.mesaj = "Simge rozeti için iOS Ayarlar’dan bildirim izni ver."; return
                }
            }
            let il = try await depo.kopru.degistir { $0.ayarla("rozet", .mantik(ac)) }
            Hatirlatici.shared.rozet(ac ? il.vadeSayisi(depo.katalog?.sanatcilar ?? [], tarih: depo.bugun) : 0)
            izin = await Hatirlatici.shared.izinDurumu()
        }
    }
}

// MARK: Hakkında

/// Yenilikler (alttan yükselen yaprak), Sürüm (Denetle) ve Kaynaklar
struct HakkindaBolumu: View {
    let depo: BenDeposu
    let surum: String
    @Environment(TemaDeposu.self) private var tema
    @State private var yenilikler: [Yenilik] = []
    @State private var yaprak = false
    @State private var mesaj = ""

    var body: some View {
        AyarKarti {
            Button { yaprak = true } label: {
                HStack(spacing: 12) {
                    AyarSimgeKabi(simge: .yildiz)
                    AyarSatirYazisi(ad: "Yenilikler", alt: "Sürüm notları ve son eklenenler")
                    if let ilk = yenilikler.first { SagDeger(metin: ilk.surum, renk: \.pirinc) }
                    BenIkon(simge: .ileri, boyut: 16, kalinlik: 1.8).foregroundStyle(Color(tema.renkler.murekkep3))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(SatirBasinci())
            .disabled(yenilikler.isEmpty)
            AyarCizgisi()
            VStack(alignment: .leading, spacing: 0) {
                AyarSatiri(simge: .bilgi, ad: "Sürüm", alt: "Veri \(surum.isEmpty ? "—" : surum)") {
                    Button("Denetle") {
                        // Z2c-3: sitenin verisi (sanatçılar, eserler, sürüm, sürüm notları) yeniden indirilir; uygulamanın
                        // kendisi Xcode'dan gelir
                        Task {
                            mesaj = await depo.veriyiYenile()
                            yenilikler = await depo.yenilikler()
                        }
                    }
                    .buttonStyle(CamHap())
                    .accessibilityLabel("Yeni sürüm var mı? Denetle")
                }
                if !mesaj.isEmpty {
                    Text(mesaj).font(Yazi.sans(12.5, agirlik: 500, stil: .footnote))
                        .foregroundStyle(Color(tema.renkler.dogruIkon))
                        .padding(.leading, 60).padding(.trailing, 16).padding(.bottom, 12)
                }
            }
            AyarCizgisi()
            AyarSatiri(simge: .kitap, ad: "Kaynaklar",
                       alt: "Görseller: Wikimedia Commons, müzelerin açık erişim koleksiyonları, WikiArt · Eser listeleri: Wikidata")
        }
        .task { yenilikler = await depo.yenilikler() }
        .sheet(isPresented: $yaprak) {
            YeniliklerYapragi(yenilikler: yenilikler).environment(tema)
        }
    }
}

/// `.yaprak`: sürüm notlarının tamamı (sitenin Ayarlar'ındaki `.yenilik-liste`)
struct YeniliklerYapragi: View {
    let yenilikler: [Yenilik]
    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var kapat

    var body: some View {
        let r = tema.renkler
        VStack(spacing: 0) {
            HStack {
                Text("Yenilikler").font(Yazi.serif(24, agirlik: 500, stil: .title2))
                    .foregroundStyle(Color(r.murekkep))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { kapat() } label: { BenIkon(simge: .kapat, boyut: 18, kalinlik: 1.6) }
                    .buttonStyle(YuvarlakDugme())
                    .accessibilityLabel("Kapat")
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(Color(r.kenarInce)).frame(height: 1) }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(yenilikler.enumerated()), id: \.offset) { i, y in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Yenilikler.surumAdi(y.surum)).font(Yazi.sans(12.5, agirlik: 600, stil: .footnote))
                                .foregroundStyle(Color(r.pirinc))
                            Text(y.metin).font(Yazi.okuma(15.5)).cssSatir(.okuma, 15.5, 23)
                                .foregroundStyle(Color(r.murekkep2))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                        .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Color(r.kenarInce)).frame(height: 1) } }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
            }
        }
        .background(Color(r.yuzey).ignoresSafeArea())
        .presentationDetents([.fraction(0.78), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: Gelişmiş

/// "Geliştirici ve bakım": kapalı bölüm. Açınca geliştirici modu, hata günlüğü, bildirdiğim görseller, elle odaklar
/// ve ana ekranın resimleri.
struct GelismisBolumu: View {
    let depo: BenDeposu
    @Binding var bilgi: AyarBilgisi
    @Environment(TemaDeposu.self) private var tema
    @State private var acik = false
    @State private var modOnayi = false
    @State private var bildirimSil = false
    @State private var odakSil = false
    @State private var gunlukSil = false
    @State private var eserler: [Eser] = []
    @State private var ortala = false
    private var gunluk: HataGunluguDeposu { HataGunluguDeposu.shared }

    var body: some View {
        let il = depo.il
        let gelistirici = il?[alan: "gelistirici"]?.nesne != nil
        let bildirimler = il?[alan: "bildirimler"]?.dizi ?? []
        AyarKarti {
            AcilirSatir(simge: .kod, ad: "Geliştirici ve bakım", alt: "Geliştirici modu, günlük, odaklar, bildirimler",
                        acik: $acik, tam: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Toggle(isOn: Binding(get: { gelistirici }, set: { _ in modOnayi = true })) {
                        AyarSatirYazisi(ad: "Geliştirici modu",
                                        alt: "Bütün konular, sanatçılar ve harita bölümleri açılır. Kapatınca açmadan önceki ilerlemen olduğu gibi geri gelir; mod açıkken çözdüklerin sayılmaz.")
                    }
                    .toggleStyle(AyarAnahtari())
                    .padding(.vertical, 10)
                    altBolum("Hata günlüğü", gunluk.gunluk.ozet) {
                        if !gunluk.gunluk.kayitlar.isEmpty {
                            Button("Kopyala") { kopyala(depo, gunluk.gunluk.metin) }.buttonStyle(CamHap())
                            Button("Temizle") { gunlukSil = true }.buttonStyle(CamHap(tehlike: true))
                        }
                    }
                    altBolum("Bildirdiğim görseller", bildirimler.isEmpty
                             ? "Henüz yok. Görüntüleyicide ya da cevap yaprağında “⋯” ile bildirebilirsin."
                             : "\(bildirimler.count) bildirim. Bildirilen görseller ve eserler pekiştirmede çıkmaz; listeyi bir Claude oturumuna ver.") {
                        if !bildirimler.isEmpty {
                            Button("JSON kopyala") {
                                // bildirimMetni: JSON.stringify({ uygulama, tur, bildirimler }, null, 1)
                                kopyala(depo, JSONDeger.nesne(SiraliNesne(ciftler: [
                                    ("uygulama", .metin("sanat-atlasi")), ("tur", .metin("gorsel-bildirimleri")),
                                    ("bildirimler", depo.il?[alan: "bildirimler"] ?? .dizi([])),
                                ])).girintiliMetin(girinti: 1))
                            }
                            .buttonStyle(CamHap())
                            Button("Temizle") { bildirimSil = true }.buttonStyle(CamHap(tehlike: true))
                        }
                    } liste: {
                        if !bildirimler.isEmpty { bildirimListesi(bildirimler) }
                    }
                    altBolum("Elle odaklar", (bilgi.odak > 0 ? "Bu cihazda \(bilgi.odak) tablonun odağı elle işaretlendi." : "Henüz yok.")
                             + " Kalıcı olması için listeyi kopyalayıp Claude’a gönder; sitede kalıcı olunca bu cihazdakileri silebilirsin.") {
                        if bilgi.odak > 0 {
                            Button("Kopyala") { kopyala(depo, ElleOdaklar.metin) }.buttonStyle(CamHap())
                            Button("Bu cihazdakileri sil") { odakSil = true }.buttonStyle(CamHap(tehlike: true))
                        }
                    }
                    altBolum("Ana ekranın resimleri",
                             "Günün ressamının yürüyüş eseri\(bilgi.yuruyus > 0 ? " (\(bilgi.yuruyus) eser)" : ""). “Sırayla ortala” bu eserleri sırayla açar: “Odağı işaretle”ye dokun, sonra ekranın ortasına gelecek noktaya.") {
                        Button("Sırayla ortala") {
                            depo.yap {
                                eserler = await depo.yuruyusEserleri()
                                guard !eserler.isEmpty else { depo.mesaj = "Yürüyüş eserleri bulunamadı."; return }
                                ortala = true
                            }
                        }
                        .buttonStyle(CamHap())
                    }
                }
            }
        }
        .confirmationDialog("Mod açıkken bütün konular açılır. Kapatınca önceki ilerleme geri gelir.",
                            isPresented: $modOnayi, titleVisibility: .visible) {
            Button("Geliştirici modunu değiştir") {
                let ac = depo.il?[alan: "gelistirici"]?.nesne == nil
                depo.yap {
                    guard let l = depo.gelistiriciListeleri() else { throw URLError(.notConnectedToInternet) }
                    try await depo.kopru.gelistirici(ac: ac, konular: l.nolar, bolumIdleri: l.bolumler)
                }
            }
        }
        .alert("Görsel bildirimleri temizlensin mi?", isPresented: $bildirimSil) {
            Button("Temizle", role: .destructive) { depo.degistir { $0[alan: "bildirimler"] = .dizi([]) } }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Cihazdaki elle odaklar silinsin mi?", isPresented: $odakSil) {
            Button("Sil", role: .destructive) {
                ElleOdaklar.sil()
                bilgi.odak = 0
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Hata günlüğü temizlensin mi?", isPresented: $gunlukSil) {
            Button("Temizle", role: .destructive) { gunluk.temizle() }
            Button("Vazgeç", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $ortala) {
            Goruntuleyici(eserler: eserler, ortalama: true).environment(tema)
        }
    }

    /// Gelişmiş içindeki bir araç: ince çizgi, ad, açıklama, düğmeler
    private func altBolum<Dugmeler: View>(_ ad: String, _ aciklama: String,
                                          @ViewBuilder dugmeler: () -> Dugmeler) -> some View {
        altBolum(ad, aciklama, dugmeler: dugmeler, liste: { EmptyView() })
    }

    private func altBolum<Dugmeler: View, Liste: View>(_ ad: String, _ aciklama: String,
                                                       @ViewBuilder dugmeler: () -> Dugmeler,
                                                       @ViewBuilder liste: () -> Liste) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AyarCizgisi()
            AyarSatirYazisi(ad: ad, alt: aciklama).padding(.top, 6)
            liste()
            HStack(spacing: 8) { dugmeler() }
        }
        .padding(.bottom, 6)
    }

    private func bildirimListesi(_ liste: [JSONDeger]) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(liste.prefix(8).indices, id: \.self) { i in
                let x = liste[i]
                VStack(alignment: .leading, spacing: 1) {
                    Text(x["baslik"]?.metin ?? x["a"]?.metin ?? "").font(Yazi.sans(13, agirlik: 500, stil: .footnote))
                        .foregroundStyle(Color(r.murekkep))
                    Text([x["neden"]?.metin, x["t"]?.metin].compactMap { $0 }.joined(separator: " · "))
                        .font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(r.murekkep3))
                }
            }
            if liste.count > 8 {
                Text("ve \(liste.count - 8) bildirim daha").font(Yazi.sans(12, stil: .caption1))
                    .foregroundStyle(Color(r.murekkep3))
            }
        }
    }
}

// Kaynak: sanat-atlasi js/ekranlar/{pekistir,soruTurlari}.js, css/app.css @ a866b86
import SwiftUI
import NoraCekirdek

@MainActor
struct PekistirmeEkrani: View {
    @Environment(TemaDeposu.self) private var tema
    @State private var model = PekistirmeModeli()
    @State private var yeniKip: PekistirmeKipi?
    @State private var yeniSeviye: Int?
    var ilkTur: PekistirmeKipi? = nil
    private var murekkep: Color { Color(tema.renkler.murekkep) }
    private var yuzey: Color { Color(tema.renkler.yuzey) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if model.turAcik, let tur = model.kayit {
                    Button { model.turAcik = false } label: { Label("Pekiştir", systemImage: "chevron.left") }
                    if let k = tur.kart {
                        kartGorunumu(tur, k)
                            .onAppear {
                                #if DEBUG
                                if NoraSanatApp.arguman("-ekran") == "pekistir" {
                                    try? Data().write(to: FileManager.default.temporaryDirectory.appendingPathComponent("pekistirme-hazir"))
                                }
                                #endif
                            }
                    } else { ozet(tur) }
                } else if let katalog = model.katalog { menu(katalog) }
                else if model.hata == nil { ProgressView("Kartlar hazırlanıyor…") }
                if let hata = model.hata {
                    Text(hata).font(Yazi.okuma(16))
                    Button("Güncel kaydı yükle") { Task { await model.yukle() } }
                }
            }
            .padding(20).frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
        }
        .background(Color(tema.renkler.zemin).ignoresSafeArea())
        .foregroundStyle(murekkep).font(Yazi.sans(16)).tint(murekkep)
        .disabled(model.mesgul)
        .task {
            guard model.katalog == nil else { return }
            await model.yukle()
            if model.kayit == nil, let ilkTur { await model.basla(ilkTur) }
        }
        .confirmationDialog("Yarım tur yerine yeni tur başlatılsın mı?", isPresented: Binding(
            get: { yeniKip != nil }, set: { if !$0 { yeniKip = nil } }
        ), titleVisibility: .visible, presenting: yeniKip) { kip in
            Button("Yeni tur başlat", role: .destructive) { Task { await model.basla(kip, seviye: yeniSeviye) } }
            Button("Vazgeç", role: .cancel) {}
        }
    }

    private func basla(_ kip: PekistirmeKipi, seviye: Int? = nil) {
        if model.kayit?.kart != nil {
            yeniSeviye = seviye
            yeniKip = kip
        } else { Task { await model.basla(kip, seviye: seviye) } }
    }

    @ViewBuilder private func menu(_ katalog: SiteKatalogu) -> some View {
        Text("Pekiştir").font(Yazi.serif(38))
        if let tur = model.kayit, tur.kart != nil {
            Button { model.turAcik = true } label: {
                satir("Kaldığın yerden sürdür", "\(kipAdi(tur.kip)) · \(sira(tur)) / \(tur.oturum.kuyruk.count)")
            }
        }
        Button { basla(.sanatci(.karisik)) } label: { satir("Karışık tur", "Sanatçıyı ve akımı bul") }
        Menu("Döneme göre") {
            Button("Bütün dönemler") { basla(.sanatci(.donem(nil))) }
            ForEach(katalog.akimlar) { akim in
                Menu(akim.ad) {
                    Button("Güncel seviye") { basla(.sanatci(.donem(akim.ad))) }
                    let sv = model.ilerleme?.seviyeler[akim.ad]?.s ?? 0
                    ForEach(Seviye.seviyeler.filter { $0.no < sv }, id: \.no) { alt in
                        Button(alt.ad) { basla(.sanatci(.donem(akim.ad)), seviye: alt.no) }
                    }
                }
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

    private func kipAdi(_ kip: PekistirmeKipi) -> String {
        switch kip {
        case .kursBolumu: return "Bölüm turu"
        case .ikonografi: return "İkonografi"
        case .sanatci(.karisik): return "Karışık tur"
        case .sanatci(.hatalar): return "Hatalarım"
        case .sanatci(.donem(let ad)): return ad ?? "Bütün dönemler"
        case .sanatci(.konu(let no)): return "Konu \(no)"
        case .sanatci(.bolum(let id, _, _)): return id
        }
    }

    private func sira(_ tur: TurKaydi) -> Int {
        let tamam = tur.kart.map { $0.sonuc != nil && !$0.akimBekliyor } ?? false
        return tur.oturum.konum + (tamam ? 0 : 1)
    }

    private func satir(_ baslik: String, _ alt: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(baslik).font(Yazi.serif(24))
                Text(alt).font(Yazi.sans(14))
            }
            Spacer()
            Image(systemName: "chevron.right")
        }.padding().background(yuzey, in: RoundedRectangle(cornerRadius: 14))
    }

    private func resim(_ e: Eser) -> some View {
        UzakGorsel(url: model.katalog?.gorselAdresi(e, genislik: 1280, kotuler: model.ilerleme?.kotuGorseller ?? [:]), icerik: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func ad(_ id: String, _ tur: TurKaydi, _ k: TurKarti) -> String {
        if k.ikinci { return id }
        switch tur.kip {
        case .ikonografi: return model.veri.ad(id)
        case .kursBolumu: return model.katalog?.konular.first { $0.bolum == id }.map { "\(id) · \($0.bolumAd)" } ?? id
        case .sanatci: return model.katalog?.harita[id]?.ad ?? id
        }
    }

    private func soru(_ tur: TurKaydi, _ k: TurKarti) -> String {
        if k.ikinci { return "Hangi akım?" }
        if k.ters != nil { return "\(ad(k.dogru, tur, k)) hangi eseri yaptı?" }
        switch tur.kip {
        case .kursBolumu: return "Bu eser hangi bölümde?"
        case .ikonografi: return "Bu eserin konusu ne?"
        case .sanatci: return "Bu eseri kim yaptı?"
        }
    }

    @ViewBuilder private func kartGorunumu(_ tur: TurKaydi, _ k: TurKarti) -> some View {
        HStack {
            Text(kipAdi(tur.kip))
            Spacer()
            Text("\(sira(tur)) / \(tur.oturum.kuyruk.count)").monospacedDigit()
        }.font(Yazi.sans(13))
        ProgressView(value: Double(sira(tur) - 1), total: Double(max(1, tur.oturum.kuyruk.count)))
        if k.ters == nil { resim(k.resim.eser).frame(height: 228).accessibilityLabel("Sorudaki eser") }
        Text(soru(tur, k)).font(Yazi.serif(27))
        if let sonuc = k.sonuc { cevapYapragi(tur, k, sonuc) }
        else {
            if let ters = k.ters {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(Array(ters.enumerated()), id: \.element.id) { i, sec in
                        Button { Task { await model.cevapla(sec.id) } } label: {
                            resim(sec.eser).frame(height: 146)
                        }.accessibilityLabel("Eser \(i + 1)")
                    }
                }
            } else {
                ForEach(k.ikinci ? (k.akimlar ?? []) : k.secenekler, id: \.self) { id in
                    Button { Task { await model.cevapla(id) } } label: {
                        Text(ad(id, tur, k)).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12).background(yuzey, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            Button("Bilmiyorum") { Task { await model.cevapla(nil) } }
        }
    }

    private func cevapYapragi(_ tur: TurKaydi, _ k: TurKarti, _ dogru: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(k.bilmiyorum ? "Bilmiyorum" : dogru ? "Doğru" : "Yanlış",
                  systemImage: dogru ? "checkmark.circle.fill" : "arrow.counterclockwise.circle")
            Text(k.ikinci ? model.katalog?.harita[k.resim.id]?.akim ?? "" : ad(k.dogru, tur, k)).font(Yazi.serif(25))
            Text(k.resim.eser.gorunenAd).font(Yazi.okuma(17, italik: true))
            if k.ters != nil { resim(k.resim.eser).frame(height: 132) }
            Button(k.akimBekliyor ? "Hangi akım?" : tur.oturum.simdiki == nil ? "Turu bitir" : "Sonraki kart") {
                Task { await model.sonraki() }
            }.buttonStyle(.bordered)
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(yuzey, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private func ozet(_ tur: TurKaydi) -> some View {
        let toplam = tur.oturum.dogru + tur.oturum.yanlis
        if toplam == 0 { Text("Bu tur için şu an kart yok.").font(Yazi.serif(28)) }
        else {
            Text("Tur bitti").font(Yazi.serif(32))
            Text("\(tur.oturum.dogru) / \(toplam)").font(Yazi.serif(54))
            Text("kart doğru")
            Text(tur.oturum.yanlis == 0 ? "Hepsi doğru, harika." : "Yanlış yaptıkların daha sık karşına çıkacak.").font(Yazi.okuma(18, italik: true))
            Button("Bir tur daha") { basla(tur.kip, seviye: tur.seviye) }
        }
        Button("Pekiştirmeye dön") { model.turAcik = false }
    }
}

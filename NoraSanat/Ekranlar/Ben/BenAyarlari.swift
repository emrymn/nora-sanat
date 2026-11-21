// Kaynak: sanat-atlasi js/ekranlar/{ayarlar,hizliAyar}.js, js/depo.js, js/gunduzRenk.js @ a866b86
import NoraCekirdek
import SwiftUI
import UniformTypeIdentifiers

private struct YedekBelgesi: FileDocument {
    static let readableContentTypes = [UTType.json, .plainText]
    let metin: String
    init(_ metin: String) { self.metin = metin }
    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents, let m = String(data: d, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        metin = m
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(metin.utf8))
    }
}

struct BenAyarlari: View {
    let depo: BenDeposu
    @State private var yedek = ""
    @State private var girdi = ""
    @State private var disa = false
    @State private var ice = false
    @State private var onay: Yukleme?
    @State private var modOnayi = false

    struct Yukleme: Identifiable {
        let id = UUID()
        let metin: String
        let no, konu, skor: Int
    }

    var body: some View {
        Form {
            if let il = depo.il {
                Section("Çalışma") {
                    let n = il.ayar("gunlukKart")?.tamSayi ?? 20
                    Stepper("Günlük kart sayısı · \(n)", onIncrement: n < 100 ? { kart(5) } : nil,
                            onDecrement: n > 5 ? { kart(-5) } : nil)
                    anahtar("Yeni sanatçıyla önce tanış", "tanisma")
                }
                Section("Görünüş") {
                    secim("Tema", "tema", ["gece","gunduz"], ["Gece","Gündüz"])
                    secim("Gündüz rengi", "gunduzRenk", ["otomatik","lapis","pompei","bakir","safran","notr"],
                          ["Günün resmi","Lapis","Pompei","Bakır yeşili","Safran","Nötr kâğıt"])
                    secim("Yazı boyutu", "yazi", ["standart","buyuk"], ["Standart","Büyük"])
                    secim("Hareket", "hareket", ["tam","sade","kapali"], ["Tam","Sade","Kapalı"])
                }
                Section("Telefon") {
                    Toggle("Simge rozeti", isOn: Binding(get: { il.ayar("rozet")?.mantik ?? false }, set: rozet))
                    anahtar("Titreşim", "titresim")
                    Button("Titreşimi dene") { Titresim.dogru() }
                    Toggle("Telefonu eğince tablo oynasın", isOn: Binding(get: { il.ayar("egim")?.mantik ?? true }, set: egim))
                    if il.ayar("egim")?.mantik != false { Button("Hareket iznini ver") { egim(true) } }
                }
            }
            Section("Yedekle") {
                Button("Yedek oluştur ve kopyala") {
                    depo.yap {
                        guard let sonuc = try await depo.kopru.benBetigi(IlerlemeKoprusu.benYedekAl) as? String else {
                            throw IlerlemeKoprusu.Hata.siteYok
                        }
                        yedek = sonuc
                        UIPasteboard.general.string = sonuc
                        depo.mesaj = "Yedek panoya kopyalandı."
                    }
                }
                if !yedek.isEmpty { Button("JSON dosyası olarak kaydet") { disa = true } }
                if let t = depo.il?[alan: "sonYedek"]?.metin { Text("Son yedek · \(t)").font(.caption) }
            }
            Section("Yedeği geri yükle") {
                TextEditor(text: $girdi).frame(minHeight: 64).autocorrectionDisabled()
                    .textInputAutocapitalization(.never).accessibilityLabel("Yedek JSON metni")
                Button("Dosyadan seç") { ice = true }
                Button("Yedeği denetle", action: denetle).disabled(girdi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let il = depo.il {
                BenAraclari(depo: depo)
                Section {
                    Toggle("Geliştirici modu", isOn: Binding(get: { il[alan: "gelistirici"]?.nesne != nil },
                                                             set: { _ in modOnayi = true }))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .disabled(depo.mesgul)
        .fileExporter(isPresented: $disa, document: YedekBelgesi(yedek), contentType: .json,
                      defaultFilename: "sanat-atlasi-yedek") { if case let .failure(e) = $0 { depo.hata(e) } }
        .fileImporter(isPresented: $ice, allowedContentTypes: [.json, .plainText]) { sonuc in
            do {
                let url = try sonuc.get()
                let izin = url.startAccessingSecurityScopedResource()
                defer { if izin { url.stopAccessingSecurityScopedResource() } }
                girdi = try String(contentsOf: url, encoding: .utf8)
            } catch { depo.hata(error) }
        }
        .alert(item: $onay) { y in
            Alert(title: Text("Mevcut ilerleme değiştirilsin mi?"), message: Text("Yedekte \(y.konu) konu ve \(y.skor) sanatçı skoru var."),
                  primaryButton: .destructive(Text("Geri yükle")) {
                depo.yap {
                    _ = try await depo.kopru.benBetigi(IlerlemeKoprusu.benGeriYukle, ["metin": y.metin, "beklenen": y.no])
                    girdi = ""
                    depo.mesaj = "Yedek geri yüklendi."
                }
            }, secondaryButton: .cancel(Text("Vazgeç")))
        }
        .confirmationDialog("Mod açıkken bütün konular açılır. Kapatınca önceki ilerleme geri gelir.",
                            isPresented: $modOnayi, titleVisibility: .visible) {
            Button("Geliştirici modunu değiştir") {
                let ac = depo.il?[alan: "gelistirici"]?.nesne == nil
                depo.yap { _ = try await depo.kopru.benBetigi(IlerlemeKoprusu.benGelistirici, ["ac": ac]) }
            }
        }
    }

    private func denetle() {
        let metin = girdi
        depo.yap {
            let kayit = try await depo.kopru.oku()
            let sonuc = try await depo.kopru.benBetigi("return JSON.stringify((await import('/js/depo.js')).yedekCoz(metin));",
                                                        ["metin": metin])
            guard let json = sonuc as? String else { throw IlerlemeKoprusu.Hata.siteYok }
            let il = try Ilerleme(veri: Data(json.utf8))
            onay = Yukleme(metin: metin, no: kayit.kayitNo, konu: il.islenen.count, skor: il.skorlar.count)
        }
    }
    private func kart(_ adim: Int) { depo.degistir { BenPanosu.kart(adim, il: &$0) } }
    private func secim(_ ad: String, _ alan: String, _ degerler: [String], _ adlar: [String]) -> some View {
        Picker(ad, selection: Binding(get: { depo.il?.ayar(alan)?.metin ?? degerler[0] }, set: { deger in
            depo.degistir(sonra: "(await import('/js/ekranlar/ortak.js')).temaUygula();") {
                BenPanosu.sec(alan, deger, il: &$0)
            }
        })) { ForEach(degerler.indices, id: \.self) { i in Text(adlar[i]).tag(degerler[i]) } }
    }
    private func anahtar(_ ad: String, _ alan: String) -> some View {
        Toggle(ad, isOn: Binding(get: { depo.il?.ayar(alan)?.mantik ?? true }, set: { ac in
            depo.degistir { $0.ayarla(alan, .mantik(ac)) }
        }))
    }
    private func egim(_ ac: Bool) {
        depo.yap {
            if ac {
                let izin = try await depo.kopru.benBetigi("return await (await import('/js/egim.js')).egimIzni();")
                guard izin as? Bool == true else { depo.mesaj = "Hareket izni verilmedi."; return }
            }
            _ = try await depo.kopru.degistir { $0.ayarla("egim", .mantik(ac)) }
        }
    }
    private func rozet(_ ac: Bool) {
        depo.yap {
            if ac {
                guard await Hatirlatici.shared.izinIste() == "granted" else {
                    depo.mesaj = "Simge rozeti için iOS Ayarlar’dan bildirim izni ver."; return
                }
            }
            let il = try await depo.kopru.degistir { $0.ayarla("rozet", .mantik(ac)) }
            Hatirlatici.shared.rozet(ac ? il.vadeSayisi(depo.katalog?.sanatcilar ?? [], tarih: depo.bugun) : 0)
        }
    }
}

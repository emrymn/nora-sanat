// Kaynak: sanat-atlasi js/ekranlar/ilerleme.js, js/ekranlar/pano.js @ a866b86
import Charts
import NoraCekirdek
import SwiftUI

struct BenSekmesi: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(\.dynamicTypeSize) private var yaziBoyutu
    @Environment(\.scenePhase) private var evre
    @State private var depo = BenDeposu()
    @State private var ayarlar = false
    @State private var zayifOnce = false
    @State private var hizli = false

    var body: some View {
        NavigationStack {
            Group {
                if ayarlar { BenAyarlari(depo: depo) }
                else if let il = depo.il, let k = depo.katalog { ilerleme(il, k) }
                else if depo.mesgul { ProgressView("İlerleme yükleniyor…") }
                else { Button("İlerlemeyi yeniden yükle") { Task { await depo.yenile() } } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(tema.renkler.zemin))
            .foregroundStyle(Color(tema.renkler.murekkep))
            .navigationTitle(ayarlar ? "Ayarlar" : "Ben")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { ayarlar.toggle() } label: {
                        Label(ayarlar ? "İlerleme" : "Ayarlar", systemImage: ayarlar ? "chart.bar" : "gearshape")
                    }
                }
            }
        }
        .dynamicTypeSize(tema.ayar.yazi == "buyuk" ? max(yaziBoyutu, .xLarge) : yaziBoyutu)
        .tint(Color(tema.renkler.pirinc))
        .onChange(of: kabuk.yerliAdres[.ben], initial: true) { _, adres in
            if let adres {
                ayarlar = adres.hasPrefix("#/ayarlar")
                kabuk.adresIslendi(.ben)
            }
        }
        .task(id: kabuk.secili == .ben) {
            if kabuk.secili == .ben {
                #if DEBUG
                if NoraSanatApp.arguman("-benSayfa") == "ayarlar" { ayarlar = true }
                #endif
                await depo.yenile()
            }
        }
        .onChange(of: evre) { _, yeni in
            if yeni == .active && kabuk.secili == .ben { Task { await depo.yenile() } }
        }
        .alert("Ben", isPresented: Binding(get: { depo.mesaj != nil }, set: { if !$0 { depo.mesaj = nil } })) {
            Button("Tamam") { depo.mesaj = nil }
        } message: { Text(depo.mesaj ?? "") }
    }

    private func baslik(_ konu: Konu) -> String { depo.adlar?["konular"]?[String(konu.no)]?.metin ?? konu.baslik }

    private func ilerleme(_ il: Ilerleme, _ k: SiteKatalogu) -> some View {
        let p = BenPanosu(il, sanatcilar: k.sanatcilar, akimlar: k.akimlar, bugun: depo.bugun)
        let islenen = il.islenenKume
        let konular = k.kursKonulari
        let sayi = konular.filter { islenen.contains($0.no) }.count
        return List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    let acik = il.acikSanatcilar(k.sanatcilar)
                    let adaylar = acik.isEmpty ? Array(k.sanatcilar.prefix(9)) : acik
                    let duvar = Array((adaylar.filter { $0.kaynak == "kurs" } + adaylar.filter { $0.kaynak != "kurs" }).prefix(3))
                    if !duvar.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(duvar) { s in
                                if let eser = k.eserler(s.id).first {
                                    UzakGorsel(url: k.gorselAdresi(eser, genislik: 400, kotuler: il.kotuGorseller))
                                        .frame(maxWidth: .infinity).clipped()
                                }
                            }
                        }.frame(height: 94).clipped().accessibilityHidden(true)
                    }
                    Text("Kursun neresindesin").font(Yazi.sans(13))
                    Text("\(sayi) / \(konular.count) konu işlendi").font(Yazi.serif(30))
                    ProgressView(value: Double(sayi), total: Double(max(1, konular.count)))
                    Text("\(p.acik) sanatçı · \(p.kalici) kalıcı · \(p.vade) tekrar").font(.subheadline)
                }.padding(.vertical, 8)
                if p.vade > 0 { Button("Karışık tekrarı başlat") { git("#/pekistir/karisik", .calis) } }
            }
            Section("Çalışma geçmişi") {
                Label("\(Gecmis.seri(il.gecmis, bugun: depo.bugun)) günlük seri", systemImage: "calendar")
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(7), spacing: 2), count: 7), spacing: 4) {
                    ForEach(Gecmis.takvim(il.gecmis, bugun: depo.bugun), id: \.tarih) { g in
                        RoundedRectangle(cornerRadius: 2).fill(Color(tema.renkler.pirinc).opacity(g.kart > 0 ? 1 : 0.15))
                            .frame(width: 9, height: 7).accessibilityLabel("\(g.tarih), \(g.kart) kart")
                    }
                }
                Chart(Gecmis.haftalikOran(il.gecmis, bugun: depo.bugun), id: \.bas) { h in
                    if let oran = h.oran { BarMark(x: .value("Hafta", h.bas), y: .value("Doğruluk", oran)) }
                }.chartYScale(domain: 0...1).chartXAxis(.hidden).frame(height: 55)
                Button("Koleksiyonum") { git("#/koleksiyon", .galeri) }
            }
            if let s = konular.first(where: { !islenen.contains($0.no) }) {
                Section("Sıradaki konu") {
                    Text(baslik(s)).font(Yazi.serif(22))
                    Button("Konu \(s.no) işlendi") { isaretle([s.no], true) }
                }
            }
            kurs(k, islenen)
            akimlar(p, il)
            let ikililer = Ogrenme.enCok(il.karisanlarSirali, varMi: { k.harita[$0] != nil })
            if !ikililer.isEmpty {
                Section("En çok karıştırdıkların") {
                    ForEach(ikililer.indices, id: \.self) { i in
                        let x = ikililer[i]
                        Button("\(k.bilinenAd(x.a) ?? x.a) ↔ \(k.bilinenAd(x.b) ?? x.b) · \(x.n) kez") {
                            git("#/karsilastir/\(x.a)/\(x.b)", .galeri)
                        }
                    }
                }
            }
            Section("En zayıf sanatçılar") {
                if p.zayiflar.isEmpty { Text("Henüz zayıf sanatçı yok.").foregroundStyle(.secondary) }
                ForEach(p.zayiflar) { s in
                    Button("\(k.harita[s.id]?.ad ?? s.id) · \(s.dogru)/\(s.toplam) doğru") { git("#/sanatci/" + s.id, .galeri) }
                }
                if !TurPlani.kur(.hatalar, sanatcilar: k.sanatcilar, ilerleme: il, bugun: depo.bugun,
                                 akimSira: k.akimSira, eseriVar: { _ in true }).kartlar.isEmpty {
                    Button("Hatalarım turu") { git("#/pekistir/hatalar", .calis) }
                }
            }
        }
        .disabled(depo.mesgul).scrollContentBackground(.hidden)
        .refreshable { await depo.yenile() }
    }

    private func kurs(_ k: SiteKatalogu, _ islenen: Set<Int>) -> some View {
        let konular = k.kursKonulari
        let bolumler = konular.reduce(into: [String]()) { if !$0.contains($1.bolum) { $0.append($1.bolum) } }
        return Section("Kurs konuları") {
            Toggle("Hızlı işaretle", isOn: $hizli)
            ForEach(bolumler, id: \.self) { bolum in
                let grup = konular.filter { $0.bolum == bolum }
                DisclosureGroup(depo.adlar?["bolumler"]?[bolum]?.metin ?? grup.first?.bolumAd ?? bolum) {
                    ForEach(grup) { konu in
                        let secili = islenen.contains(konu.no)
                        if hizli {
                            Toggle(baslik(konu), isOn: Binding(get: { secili }, set: { isaretle([konu.no], $0) }))
                        } else {
                            DisclosureGroup("\(konu.no). \(baslik(konu))") {
                                Text(k.sanatcilar.filter { $0.konu == konu.no }.map(\.ad).joined(separator: ", ")).font(.footnote)
                                Button(secili ? "İşlenmedi yap" : "İşlendi yap") { isaretle([konu.no], !secili) }
                                Button("Buraya kadar işlendi") { isaretle(k.konular.filter { $0.no <= konu.no }.map(\.no), true) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func akimlar(_ p: BenPanosu, _ il: Ilerleme) -> some View {
        let sira = zayifOnce ? p.akimlar.sorted { ($0.oran ?? 2) < ($1.oran ?? 2) } : p.akimlar
        return Section("Akımlara göre doğruluk") {
            Toggle("Zayıf önce", isOn: $zayifOnce)
            ForEach(sira.filter { $0.toplam > 0 }) { x in
                Button { git("#/pekistir/donem/" + x.id, .calis) } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(x.id).font(Yazi.serif(20))
                        ProgressView(value: x.oran ?? 0)
                        Text("\(x.dogru)/\(x.toplam) doğru · \(Seviye.kisa(Seviye.kayit(il.seviyeler, x.id)))")
                            .font(.caption)
                    }
                }
            }
            let bos = sira.filter { $0.toplam == 0 }
            if !bos.isEmpty {
                DisclosureGroup("Henüz cevaplanmamış \(bos.count) akım") {
                    ForEach(bos) { x in Button(x.id) { git("#/pekistir/donem/" + x.id, .calis) } }
                }
            }
        }
    }

    private func isaretle(_ nolar: [Int], _ islendi: Bool) {
        depo.degistir(sonra: "(await import('/js/ekranlar/ortak.js')).d.oturum = null;") {
            BenPanosu.isaretle(nolar, islendi: islendi, il: &$0)
        }
    }

    private func git(_ adres: String, _ sekme: Sekme) {
        kabuk.sec(sekme)
        Gezgin.shared.git(adres)
    }
}

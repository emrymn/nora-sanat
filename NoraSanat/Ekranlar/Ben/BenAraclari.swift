// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (bildirimBolumu, elleOdakBolumu, gununResmiBolumu, Günün sanatçısı,
// Sürüm), js/gunun.js (baskaSanatci), js/bildirim.js (bildirimMetni), js/gorsel.js (elle odaklar) @ a866b86
// C4b: her bölüm sitedeki gibi ayrı bir `.ayar`. Z2c-3: betikler Swift'te; hata günlüğü sitenin kendi günlüğüydü,
// site kalktığı için bölümü de kalktı. "Sırayla ortala" yerli görüntüleyiciyi açar (Z2c-3b).
import NoraCekirdek
import SwiftUI

/// Panoya kopyala
@MainActor
private func kopyala(_ depo: BenDeposu, _ metin: String) {
    UIPasteboard.general.string = metin
    depo.mesaj = "Panoya kopyalandı."
}

/// "Günün sanatçısı": bugünün adı ve "Başka bir sanatçı getir"
struct GununSanatcisiBolumu: View {
    let depo: BenDeposu
    let ad: String

    var body: some View {
        AyarBolumu(baslik: "Günün sanatçısı",
                   aciklama: "Bugün: \(ad). Başka biriyle değiştirebilirsin; gün boyunca o kalır, yarın yeni sanatçı kendiliğinden gelir.") {
            Button("Başka bir sanatçı getir") {
                depo.yap {
                    // Z2c-3: sitenin baskaSanatci(gununHavuzu(), gununId())'si
                    guard let id = await depo.baskaSanatci() else { throw URLError(.notConnectedToInternet) }
                    _ = try await depo.kopru.degistir {
                        $0[alan: "gununDegisim"] = .nesne([("tarih", .metin(depo.bugun)), ("id", .metin(id))])
                    }
                    depo.mesaj = "Bugünün sanatçısı: " + (depo.katalog?.bilinenAd(id) ?? id)
                }
            }
            .buttonStyle(HapDugme(ince: true)).padding(.top, 26)
        }
    }
}

/// "Bildirdiğim görseller": ilk 8 bildirim, JSON olarak kopyala, listeyi temizle
struct BildirimBolumu: View {
    let depo: BenDeposu
    @State private var temizle = false
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let liste = depo.il?[alan: "bildirimler"]?.dizi ?? []
        AyarBolumu(baslik: "Bildirdiğim görseller",
                   aciklama: liste.isEmpty
                       ? "Henüz bildirdiğin görsel yok. Eser görüntüleyicide ya da cevap yaprağında “⋯” ile bildirebilirsin."
                       : "\(liste.count) bildirim. Bildirilen görseller ve eserler pekiştirmede çıkmaz. Listeyi kopyalayıp bir Claude oturumuna ver; görsel kararlarına işlensin.") {
            if !liste.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(liste.prefix(8).indices, id: \.self) { i in
                        let x = liste[i]
                        VStack(alignment: .leading, spacing: 2) {
                            Text(x["baslik"]?.metin ?? x["a"]?.metin ?? "").font(Yazi.sans(14))
                            Text([x["neden"]?.metin, x["t"]?.metin].compactMap { $0 }.joined(separator: " · "))
                                .font(Yazi.sans(12, stil: .caption1)).foregroundStyle(Color(tema.renkler.murekkep2))
                        }
                    }
                    if liste.count > 8 {
                        Text("ve \(liste.count - 8) bildirim daha").font(Yazi.sans(12, stil: .caption1))
                            .foregroundStyle(Color(tema.renkler.murekkep2))
                    }
                }
                .padding(.top, 6)
                HStack(spacing: 8) {
                    Button("JSON olarak kopyala") {
                        // bildirimMetni: JSON.stringify({ uygulama, tur, bildirimler }, null, 1)
                        kopyala(depo, JSONDeger.nesne(SiraliNesne([
                            ("uygulama", .metin("sanat-atlasi")), ("tur", .metin("gorsel-bildirimleri")),
                            ("bildirimler", depo.il?[alan: "bildirimler"] ?? .dizi([])),
                        ])).girintiliMetin(girinti: 1))
                    }
                    Button("Listeyi temizle") { temizle = true }
                }
                .buttonStyle(HapDugme()).padding(.top, 8)
            }
        }
        .alert("Görsel bildirimleri temizlensin mi?", isPresented: $temizle) {
            Button("Temizle", role: .destructive) { depo.degistir { $0[alan: "bildirimler"] = .dizi([]) } }
            Button("Vazgeç", role: .cancel) {}
        }
    }
}

/// "Ana ekranın resimleri": yürüyüş eserlerini sırayla ortalama (Z2c-3b: yerli görüntüleyicide)
struct GununResimleriBolumu: View {
    let depo: BenDeposu
    let yuruyus: Int
    @Environment(TemaDeposu.self) private var tema
    @State private var eserler: [Eser] = []
    @State private var acik = false

    var body: some View {
        AyarBolumu(baslik: "Ana ekranın resimleri",
                   aciklama: "Ana ekranda günün ressamının yürüyüş eseri görünür\(yuruyus > 0 ? " (\(yuruyus) eser)" : ""). “Sırayla ortala” bu eserleri sırayla açar: “Odağı işaretle”ye dokun, sonra ekranın ortasına gelecek noktaya; çerçeve ana ekranın açılışında görünen alanı gösterir. Ortaladıkların aşağıdaki “Elle ortalanan tablolar” listesine girer.") {
            Button("Sırayla ortala") {
                depo.yap {
                    eserler = await depo.yuruyusEserleri()
                    guard !eserler.isEmpty else { depo.mesaj = "Yürüyüş eserleri bulunamadı."; return }
                    acik = true
                }
            }
            .buttonStyle(HapDugme()).padding(.top, 8)
        }
        .fullScreenCover(isPresented: $acik) {
            Goruntuleyici(eserler: eserler, ortalama: true).environment(tema)
        }
    }
}

/// "Elle odaklar": bu cihazda elle işaretlenen odaklar (yalnız varsa ya da geliştirici modunda)
struct ElleOdakBolumu: View {
    let depo: BenDeposu
    @Binding var bilgi: AyarBilgisi
    @State private var sil = false

    var body: some View {
        AyarBolumu(baslik: "Elle odaklar",
                   aciklama: (bilgi.odak > 0 ? "Bu cihazda \(bilgi.odak) tablonun odağı elle işaretlendi." : "Henüz yok.")
                       + " Günün resimlerinde (ya da geliştirici modunda) bir eseri büyütüp “Odağı işaretle”ye dokun, sonra tablonun önemli noktasına. Kırpılan görseller (Galeri, Atölye, Tuval, Konular) o noktanın çevresinden kırpılır. Kalıcı olması için listeyi kopyalayıp Claude’a gönder; sitede kalıcı olunca bu cihazdakileri silebilirsin (sitedekiler geçerli kalır).") {
            if bilgi.odak > 0 {
                HStack(spacing: 8) {
                    Button("Kopyala") {
                        kopyala(depo, ElleOdaklar.metin)
                    }
                    Button("Bu cihazdakileri sil") { sil = true }
                }
                .buttonStyle(HapDugme(ince: true)).padding(.top, 8)
            }
        }
        .alert("Cihazdaki elle odaklar silinsin mi?", isPresented: $sil) {
            Button("Sil", role: .destructive) {
                ElleOdaklar.sil()
                bilgi.odak = 0
            }
            Button("Vazgeç", role: .cancel) {}
        }
    }
}

/// "Sürüm": bu cihazdaki sürüm ve "Yeni sürüm var mı?"
struct SurumBolumu: View {
    let depo: BenDeposu
    let surum: String
    @State private var mesaj = ""
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        AyarBolumu(baslik: "Sürüm", aciklama: "Sitenin verisi \(surum.isEmpty ? "—" : surum). Yeni veri kendiliğinden gelmezse buradan denetle.") {
            Button("Yeni sürüm var mı?") {
                // Z2c-3: sitenin verisi (sanatçılar, eserler, sürüm) yeniden indirilir; uygulamanın kendisi Xcode'dan gelir
                Task { mesaj = await depo.veriyiYenile() }
            }
            .buttonStyle(HapDugme(ince: true)).padding(.top, 26)
            if !mesaj.isEmpty {
                Text(mesaj).font(Yazi.sans(13.5, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep))
                    .padding(.top, 6)
            }
        }
    }
}

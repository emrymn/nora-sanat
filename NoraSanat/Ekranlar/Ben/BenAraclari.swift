// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (bildirimBolumu, hataBolumu, elleOdakBolumu, gununResmiBolumu, Günün
// sanatçısı, Sürüm), js/yenilikler.js, js/hataGunlugu.js @ a866b86
// C4b: her bölüm sitedeki gibi ayrı bir `.ayar`; davranış ve betikler C4'teki gibi.
import NoraCekirdek
import SwiftUI

/// Panoya kopyalayan ya da çıktısını gösteren site betiği
@MainActor
private func calistir(_ depo: BenDeposu, _ kaynak: String, kopyala: Bool = false, sonuc: ((String) -> Void)? = nil) {
    depo.yap {
        let metin = try await depo.kopru.benBetigi(kaynak) as? String ?? ""
        sonuc?(metin)
        if kopyala { UIPasteboard.general.string = metin; depo.mesaj = "Panoya kopyalandı." }
    }
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
                    let sonuc = try await depo.kopru.benBetigi("""
                    const o = await import('/js/ekranlar/ortak.js');
                    return (await import('/js/gunun.js')).baskaSanatci(o.gununHavuzu(), o.gununId(), Math.random);
                    """)
                    guard let id = sonuc as? String else { throw IlerlemeKoprusu.Hata.siteYok }
                    _ = try await depo.kopru.degistir {
                        $0[alan: "gununDegisim"] = .nesne([("tarih", .metin(depo.bugun)), ("id", .metin(id))])
                    }
                    _ = try await depo.kopru.benBetigi("(await import('/js/ekranlar/ortak.js')).d.perdeAcildi = false;")
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
                        calistir(depo, "return (await import('/js/bildirim.js')).bildirimMetni((await import('/js/ekranlar/ortak.js')).d.ilerleme);", kopyala: true)
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

/// "Hata günlüğü": kayıt sayısı, Kopyala, Temizle
struct HataBolumu: View {
    let depo: BenDeposu
    @Binding var bilgi: AyarBilgisi
    @State private var temizle = false

    var body: some View {
        AyarBolumu(baslik: "Hata günlüğü",
                   aciklama: bilgi.hata > 0
                       ? "\(bilgi.hata) kayıt (son: \(bilgi.hataSon)). Bir şey bozulursa kopyalayıp Claude’a gönder."
                       : "Kayıtlı hata yok.") {
            if bilgi.hata > 0 {
                HStack(spacing: 8) {
                    Button("Kopyala") {
                        calistir(depo, "const h = await import('/js/hataGunlugu.js'); return h.gunlukMetni(h.hatalariOku());", kopyala: true)
                    }
                    .buttonStyle(HapDugme())
                    Button("Temizle") { temizle = true }.buttonStyle(HapDugme(ince: true))
                }
                .padding(.top, 8)
            }
        }
        .alert("Hata günlüğü temizlensin mi?", isPresented: $temizle) {
            Button("Temizle", role: .destructive) {
                depo.yap {
                    _ = try await depo.kopru.benBetigi("(await import('/js/hataGunlugu.js')).hatalariTemizle();")
                    bilgi.hata = 0
                }
            }
            Button("Vazgeç", role: .cancel) {}
        }
    }
}

/// "Ana ekranın resimleri": yürüyüş eserlerini sırayla ortalama
struct GununResimleriBolumu: View {
    let depo: BenDeposu
    let yuruyus: Int
    @Environment(KabukDurumu.self) private var kabuk

    var body: some View {
        AyarBolumu(baslik: "Ana ekranın resimleri",
                   aciklama: "Ana ekranda günün ressamının yürüyüş eseri görünür\(yuruyus > 0 ? " (\(yuruyus) eser)" : ""). “Sırayla ortala” bu eserleri sırayla açar: “Odağı işaretle”ye dokun, sonra ekranın ortasına gelecek noktaya; çerçeve ana ekranın açılışında görünen alanı gösterir. Ortaladıkların aşağıdaki “Elle ortalanan tablolar” listesine girer.") {
            Button("Sırayla ortala") { depo.yap { try await odakAc() } }
                .buttonStyle(HapDugme()).padding(.top, 8)
        }
    }

    private func odakAc() async throws {
        // Görüntüleyici ana sitede kaldığı sürece aynı WebKit oturumunda açılır.
        kabuk.sec(.galeri)
        _ = try await depo.kopru.benBetigi("""
        const { d } = await import('/js/ekranlar/ortak.js');
        const { sanatciEserleri } = await import('/js/eserler.js');
        const { gorselAdi } = await import('/js/gorsel.js');
        const { goruntuleyiciAc } = await import('/js/goruntuleyici.js');
        const sanatcilar = d.sanatcilar.filter(s => d.yuruyus?.[s.id]);
        const listeler = await Promise.all(sanatcilar.map(s => sanatciEserleri(s).catch(() => [])));
        const eserler = sanatcilar.flatMap((s,i) => {
          const uygun = g => gorselAdi(g) === d.yuruyus[s.id].gorsel;
          const e = listeler[i].find(e => e.gorseller?.some(uygun));
          return e ? [{ ...e, gorseller:e.gorseller.filter(uygun) }] : [];
        });
        if (!eserler.length) throw Error('Yürüyüş eserleri bulunamadı.');
        goruntuleyiciAc({eserler, kotuler:{}, ortalama:true});
        """)
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
                        calistir(depo, "return JSON.stringify({surum:1, odak:(await import('/js/gorsel.js')).cihazdakiElleOdaklar()});", kopyala: true)
                    }
                    Button("Bu cihazdakileri sil") { sil = true }
                }
                .buttonStyle(HapDugme(ince: true)).padding(.top, 8)
            }
        }
        .alert("Cihazdaki elle odaklar silinsin mi?", isPresented: $sil) {
            Button("Sil", role: .destructive) {
                depo.yap {
                    _ = try await depo.kopru.benBetigi("localStorage.removeItem((await import('/js/gorsel.js')).ELLE_ANAHTAR);")
                    bilgi.odak = 0
                }
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
        AyarBolumu(baslik: "Sürüm", aciklama: "Bu cihazda \(surum). Yeni sürüm kendiliğinden gelmezse buradan denetle.") {
            Button("Yeni sürüm var mı?") {
                calistir(depo, """
                const g = await import('/js/guncelleme.js');
                const { SURUM } = await import('/js/surum.js');
                const site = await g.sitedekiSurum();
                if (!site || site === SURUM) return 'Güncel: ' + SURUM;
                const sonuc = await g.guncellemeyiDene(site);
                if (sonuc === 'kuruldu') { setTimeout(() => location.reload(), 800); return site + ' kuruldu.'; }
                return 'Yeni sürüm kurulamadı.';
                """) { mesaj = $0 }
            }
            .buttonStyle(HapDugme(ince: true)).padding(.top, 26)
            if !mesaj.isEmpty {
                Text(mesaj).font(Yazi.sans(13.5, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep))
                    .padding(.top, 6)
            }
        }
    }
}

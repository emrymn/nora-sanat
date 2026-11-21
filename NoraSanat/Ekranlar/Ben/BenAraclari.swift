// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js, js/yenilikler.js, js/hataGunlugu.js @ a866b86
import NoraCekirdek
import SwiftUI

struct BenAraclari: View {
    let depo: BenDeposu
    @Environment(KabukDurumu.self) private var kabuk
    @State private var cikti = ""
    @State private var temizle: Silinecek?
    enum Silinecek: String, Identifiable {
        case bildirim = "Görsel bildirimleri", hata = "Hata günlüğü", odak = "Cihazdaki elle odaklar"
        var id: String { rawValue }
    }

    var body: some View {
        Section("Günün sanatçısı") {
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
            Button("Ana ekranın resimlerini sırayla ortala") {
                depo.yap {
                    try await odakAc()
                }
            }
        }
        Section("Cihaz ve sürüm") {
            DisclosureGroup("Bildirdiğim görseller") {
                let liste = depo.il?[alan: "bildirimler"]?.dizi ?? []
                if liste.isEmpty { Text("Henüz bildirim yok.") }
                ForEach(liste.prefix(8).indices, id: \.self) { i in
                    Text(liste[i]["baslik"]?.metin ?? liste[i]["a"]?.metin ?? "")
                }
                if !liste.isEmpty {
                    Button("Bildirimleri kopyala") { oku("return (await import('/js/bildirim.js')).bildirimMetni((await import('/js/ekranlar/ortak.js')).d.ilerleme);", kopyala: true) }
                    Button("Listeyi temizle", role: .destructive) { temizle = .bildirim }
                }
            }
            DisclosureGroup("Hata günlüğü ve elle odaklar") {
                Button("Hata günlüğünü kopyala") { oku("const h = await import('/js/hataGunlugu.js'); return h.gunlukMetni(h.hatalariOku());", kopyala: true) }
                Button("Hata günlüğünü temizle", role: .destructive) { temizle = .hata }
                Button("Elle odakları kopyala") { oku("return JSON.stringify({surum:1, odak:(await import('/js/gorsel.js')).cihazdakiElleOdaklar()});", kopyala: true) }
                Button("Cihazdaki elle odakları sil", role: .destructive) { temizle = .odak }
            }
            Button("Yeni sürüm var mı?") {
                oku("""
                const g = await import('/js/guncelleme.js');
                const { SURUM } = await import('/js/surum.js');
                const site = await g.sitedekiSurum();
                if (!site || site === SURUM) return 'Güncel: ' + SURUM;
                const sonuc = await g.guncellemeyiDene(site);
                if (sonuc === 'kuruldu') { setTimeout(() => location.reload(), 800); return site + ' kuruldu.'; }
                return 'Yeni sürüm kurulamadı.';
                """)
            }
            Button("Yenilikleri göster") { oku("const y = await import('/js/yenilikler.js'); return y.YENILIKLER.map(y.yenilikYazisi).join(String.fromCharCode(10,10));") }
            if !cikti.isEmpty { Text(cikti).font(.footnote).textSelection(.enabled) }
        }
        .alert(item: $temizle) { secim in
            Alert(title: Text("\(secim.rawValue) temizlensin mi?"),
                  primaryButton: .destructive(Text("Temizle")) { sil(secim) }, secondaryButton: .cancel(Text("Vazgeç")))
        }
    }

    private func oku(_ kaynak: String, kopyala: Bool = false) {
        depo.yap {
            cikti = try await depo.kopru.benBetigi(kaynak) as? String ?? ""
            if kopyala { UIPasteboard.general.string = cikti; depo.mesaj = "Panoya kopyalandı." }
        }
    }

    private func sil(_ secim: Silinecek) {
        cikti = ""
        switch secim {
        case .bildirim: depo.degistir { $0[alan: "bildirimler"] = .dizi([]) }
        case .hata: depo.yap { _ = try await depo.kopru.benBetigi("(await import('/js/hataGunlugu.js')).hatalariTemizle();") }
        case .odak: depo.yap { _ = try await depo.kopru.benBetigi("localStorage.removeItem((await import('/js/gorsel.js')).ELLE_ANAHTAR);") }
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

#if DEBUG
import NoraCekirdek
import SwiftUI

/// Yalnız geliştirme: `-ekran ilerleme` ile açılınca köprüden okunan ilerlemenin özeti (T2).
/// `-ilerlemeYaz` de verilirse önce bir deneme yazar (7 ve 8. konular işlendi, bugüne 12 kart / 9 doğru):
/// CI bunu sonra sitenin `#/ilerleme` sayfasında görür. Site arkada (WKWebView) yüklü kalır; köprü onu kullanır.
@MainActor
struct IlerlemeOzeti: View {
    let yaz: Bool

    @State private var ilerleme: Ilerleme?
    @State private var katalog: SiteKatalogu?
    @State private var durum = "Site bekleniyor…"
    @State private var yazilan: Int?

    private var bugun: String { GunTarihi.gun(Date()) }

    var body: some View {
        List {
            Section {
                Text(durum).font(.footnote).foregroundStyle(.secondary)
                if let yazilan { Label("Siteye yazıldı · kayıt \(yazilan)", systemImage: "checkmark.circle") }
            } header: { Text("İlerleme köprüsü (T2)") }

            if let i = ilerleme {
                Section("Kayıt") {
                    satir("Kayıt no", "\(i.kayitNo)")
                    satir("İşlenen konu", "\(i.islenen.count)")
                    satir("Skoru olan sanatçı", "\(i.skorlar.count)")
                    if let k = katalog { satir("Açık sanatçı", "\(i.acikSanatcilar(k.sanatcilar).count) / \(k.sanatcilar.count)") }
                    satir("Seri", "\(Gecmis.seri(i.gecmis, bugun: bugun)) gün")
                    satir("Bugün", "\(i.gecmis[bugun]?.kart ?? 0) kart · \(i.gecmis[bugun]?.dogru ?? 0) doğru")
                }
                if let k = katalog {
                    let acik = i.acikSanatcilar(k.sanatcilar).map(\.id)
                    Section("Tekrar") {
                        satir("Bugün bekleyen", "\(Gecmis.vadeSayisi(i.skorlar, idler: acik, tarih: bugun))")
                        satir("Yarın (rozet)", "\(Gecmis.yarinVade(i.skorlar, idler: acik, bugun: bugun))")
                        yukGrafigi(Gecmis.gelecekYuk(i.skorlar, idler: acik, bugun: bugun))
                    }
                }
                let sv = i.seviyeler.sorted { $0.key < $1.key }
                if !sv.isEmpty {
                    Section("Seviyeler") {
                        ForEach(sv, id: \.key) { x in satir(x.key, Seviye.kisa(x.value)) }
                    }
                }
                let kar = Ogrenme.enCok(i.karisanlarSirali, adet: 3)
                if !kar.isEmpty {
                    Section("En çok karıştırılan") {
                        ForEach(Array(kar.enumerated()), id: \.offset) { e in satir("\(e.element.a) · \(e.element.b)", "\(e.element.n)") }
                    }
                }
            }
        }
        .task { await yukle() }
    }

    private func satir(_ a: String, _ b: String) -> some View {
        HStack { Text(a); Spacer(); Text(b).monospacedDigit().foregroundStyle(.secondary) }
    }

    private func yukGrafigi(_ l: [Int]) -> some View {
        let en = max(1, l.max() ?? 1)
        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(l.enumerated()), id: \.offset) { e in
                RoundedRectangle(cornerRadius: 2).fill(Color.accentColor)
                    .frame(height: max(2, 50 * CGFloat(e.element) / CGFloat(en)))
            }
        }
        .frame(height: 54)
        .accessibilityLabel("14 günlük yük: \(l.map(String.init).joined(separator: ", "))")
    }

    private func yukle() async {
        async let k = try? SiteVerisi().katalog()
        do {
            if yaz {
                durum = "Deneme yazılıyor…"
                let gun = bugun
                try await IlerlemeKoprusu.shared.degistir { il in
                    il.islenen = il.islenen + [7, 8]
                    for n in 0..<12 { il.gecmisEkle(tarih: gun, dogru: n < 9, akim: "Barok") }
                }
                yazilan = try await IlerlemeKoprusu.shared.oku().kayitNo
            }
            ilerleme = try await IlerlemeKoprusu.shared.oku()
            durum = "Siteden okundu · \(Date().formatted(date: .omitted, time: .standard))"
        } catch {
            durum = "Hata: \(error)"
        }
        katalog = await k
    }
}
#endif

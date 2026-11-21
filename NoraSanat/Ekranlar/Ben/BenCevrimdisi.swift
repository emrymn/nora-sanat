// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (devasaBilgisi, devasaIndir, devasaSil) @ a866b86
import SwiftUI

/// "En büyük kopyaları telefona indir". C5 indirme deposunu devralana kadar mevcut sitenin indirme işlemi kullanılır.
/// Kalıcı dosyalar, durdurma, yeniden başlatma ve silme onayı aynı site oturumuna aittir. Bölüm sitedeki gibi
/// yalnız sitede de varsa (telefon paketi) görünür; Ayarlar açıkken durum saniyede bir buçuk okunur.
struct BenCevrimdisi: View {
    let depo: BenDeposu
    @State private var gorunur = false
    @State private var bilgi = ""
    @State private var mesaj = ""
    @State private var indir = false
    @State private var durdur = false
    @State private var sil = false
    @State private var oran: Double?
    @Environment(TemaDeposu.self) private var tema

    static let durumBetigi = """
    const { ekran } = await import('/js/ekranlar/ortak.js');
    const dugme = ad => ekran.querySelector('[data-devasa-' + ad + ']');
    const etkin = ad => { const b = dugme(ad); return !!b && !b.hidden && !b.disabled; };
    const cubuk = ekran.querySelector('#devasa-cubuk');
    return { var: !!ekran.querySelector('[data-test="devasa-indir"]'),
             bilgi: ekran.querySelector('#devasa-bilgi')?.textContent || '',
             mesaj: ekran.querySelector('#devasa-mesaj')?.textContent || '',
             indir: etkin('indir'), durdur: etkin('durdur'), sil: etkin('sil'),
             oran: cubuk && !cubuk.hidden ? cubuk.value / (cubuk.max || 1) : -1 };
    """

    var body: some View {
        Group {
            if gorunur {
                AyarBolumu(baslik: "En büyük kopyaları telefona indir", aciklama: bilgi.isEmpty ? "Hesaplanıyor…" : bilgi) {
                    if let oran {
                        ProgressView(value: oran).tint(Color(tema.renkler.vurguAcik)).padding(.top, 8)
                    }
                    HStack(spacing: 8) {
                        if indir { Button("İndir") { tikla("indir") }.buttonStyle(HapDugme()) }
                        if durdur { Button("Durdur") { tikla("durdur") }.buttonStyle(HapDugme(ince: true)) }
                        if sil { Button("Telefondan sil") { tikla("sil") }.buttonStyle(HapDugme(ince: true)) }
                    }
                    .padding(.top, 8)
                    if !mesaj.isEmpty {
                        Text(mesaj).font(Yazi.sans(13.5, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep))
                            .padding(.top, 6)
                    }
                }
            }
        }
        .task {
            do {
                _ = try await depo.kopru.benBetigi("""
                if (location.hash !== '#/ayarlar') location.hash = '#/ayarlar';
                const { ekran } = await import('/js/ekranlar/ortak.js');
                for (let i=0; i<50 && !ekran.querySelector('[data-yedekle]'); i++) await new Promise(r => setTimeout(r,100));
                """)
                while !Task.isCancelled {
                    let d = try await depo.kopru.benBetigi(Self.durumBetigi) as? [String: Any]
                    gorunur = d?["var"] as? Bool ?? false
                    bilgi = d?["bilgi"] as? String ?? ""
                    mesaj = d?["mesaj"] as? String ?? ""
                    indir = d?["indir"] as? Bool ?? false
                    durdur = d?["durdur"] as? Bool ?? false
                    sil = d?["sil"] as? Bool ?? false
                    let o = (d?["oran"] as? NSNumber)?.doubleValue ?? -1
                    oran = o >= 0 ? o : nil
                    try await Task.sleep(nanoseconds: 1_500_000_000)
                }
            } catch { if !Task.isCancelled { depo.hata(error) } }
        }
    }

    private func tikla(_ eylem: String) {
        depo.yap {
            _ = try await depo.kopru.benBetigi("""
            const { ekran } = await import('/js/ekranlar/ortak.js');
            const b = ekran.querySelector('[data-devasa-' + eylem + ']');
            if (b && !b.disabled && !b.hidden) b.click();
            """, ["eylem": eylem])
        }
    }
}

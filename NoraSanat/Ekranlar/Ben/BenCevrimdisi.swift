// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (devasaBilgisi, devasaIndir, devasaSil) @ a866b86
import SwiftUI

/// C5 indirme deposunu devralana kadar mevcut sitenin indirme işlemi kullanılır.
/// Kalıcı dosyalar, durdurma, yeniden başlatma ve silme onayı aynı site oturumuna aittir.
struct BenCevrimdisi: View {
    let depo: BenDeposu
    @State private var acik = false
    @State private var bilgi = ""
    @State private var mesaj = ""
    @State private var indir = false
    @State private var durdur = false
    @State private var sil = false

    static let durumBetigi = """
    const { ekran } = await import('/js/ekranlar/ortak.js');
    const dugme = ad => ekran.querySelector('[data-devasa-' + ad + ']');
    const etkin = ad => { const b = dugme(ad); return !!b && !b.hidden && !b.disabled; };
    return { bilgi: ekran.querySelector('#devasa-bilgi')?.textContent || '',
             mesaj: ekran.querySelector('#devasa-mesaj')?.textContent || '',
             indir: etkin('indir'), durdur: etkin('durdur'), sil: etkin('sil') };
    """

    var body: some View {
        Section {
            DisclosureGroup("Çevrimdışı görseller", isExpanded: $acik) {
                Text(bilgi.isEmpty ? "Görseller denetleniyor…" : bilgi).font(.footnote)
                if !mesaj.isEmpty { Text(mesaj).font(.footnote) }
                if indir { Button("En büyük kopyaları indir") { tikla("indir") } }
                if durdur { Button("İndirmeyi durdur") { tikla("durdur") } }
                if sil { Button("Telefondan sil", role: .destructive) { tikla("sil") } }
            }
        }
        .task(id: acik) {
            guard acik else { return }
            do {
                _ = try await depo.kopru.benBetigi("""
                if (location.hash !== '#/ayarlar') location.hash = '#/ayarlar';
                const { ekran } = await import('/js/ekranlar/ortak.js');
                for (let i=0; i<50 && !ekran.querySelector('[data-yedekle]'); i++) await new Promise(r => setTimeout(r,100));
                """)
                while !Task.isCancelled {
                    let d = try await depo.kopru.benBetigi(Self.durumBetigi) as? [String: Any]
                    bilgi = d?["bilgi"] as? String ?? ""
                    if bilgi.isEmpty { bilgi = "Bu cihaz için indirilebilir paket bulunamadı." }
                    mesaj = d?["mesaj"] as? String ?? ""
                    indir = d?["indir"] as? Bool ?? false
                    durdur = d?["durdur"] as? Bool ?? false
                    sil = d?["sil"] as? Bool ?? false
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

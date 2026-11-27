// Z4b · Hikâyeler çaları: okuma içinde ince çalar (`.ic-calar`) ve başka sekmede küçük çalar (`.mini-calar`).
// Tasarım: Neon "Yön 2" (dal neon/hikayeler-tasarim-3, PR #75): ortak.css, goruntuler/yon-2-{dinleme,mini}-*.png.
import NoraCekirdek
import SwiftUI

/// `.ic-calar`: altta yüzen ince cam çalar. Üstte 3 pt ilerleme, bölüm adı ve süre; altta hız, −15, oynat, +15, kapat.
struct HikayeIcCalar: View {
    @Environment(TemaDeposu.self) private var tema
    @State private var calar = HikayeCalari.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        VStack(spacing: 0) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(c.kenar)
                    Rectangle().fill(c.pirinc)
                        .frame(width: g.size.width * (calar.toplam > 0 ? min(1, calar.gecen / calar.toplam) : 0))
                        .animation(.easeOut(duration: 0.25), value: calar.gecen)
                }
            }
            .frame(height: 3)
            .accessibilityHidden(true)
            HStack(spacing: 8) {
                // Z4e: bölüm adına dokununca tam ekran çalar
                Button {
                    Titresim.secim()
                    calar.tamEkran = true
                } label: {
                    HStack(spacing: 5) {
                        Text(calar.bolumBasligi).font(Yazi.sans(12.5, agirlik: 600)).foregroundStyle(c.yazi).lineLimit(1)
                        Image(systemName: "chevron.up").font(.system(size: 10, weight: .bold)).foregroundStyle(c.yazi3)
                    }
                    .frame(minHeight: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tam ekran çalar: \(calar.bolumBasligi)")
                .accessibilityIdentifier("hikaye-cal-tam")
                Spacer(minLength: 4)
                Text("\(HikayeSesi.saat(calar.gecen)) / \(HikayeSesi.saat(calar.toplam))")
                    .font(Yazi.sans(11.5)).monospacedDigit().foregroundStyle(c.yazi3)
                    .accessibilityLabel("\(HikayeSesi.saat(calar.gecen)), toplam \(HikayeSesi.saat(calar.toplam))")
            }
            .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 4)
            HStack {
                Button {
                    Titresim.dokunus()
                    calar.hiziDegistir()
                } label: {
                    Text(HikayeSesi.hizYazisi(calar.hiz)).font(Yazi.sans(12.5, agirlik: 600)).monospacedDigit()
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Hız \(HikayeSesi.hizYazisi(calar.hiz))")
                Spacer()
                Button { Titresim.dokunus(); calar.atla(-15) } label: {
                    HikayeIkon(simge: .geri15, boyut: 19).frame(width: 44, height: 44)
                }
                .accessibilityLabel("15 saniye geri")
                Spacer()
                Button { calar.degistir() } label: {
                    Image(systemName: calar.caliyor ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(c.zemin)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(c.yazi))
                }
                .accessibilityLabel(calar.caliyor ? "Duraklat" : "Oynat")
                .accessibilityIdentifier("hikaye-oynat")
                Spacer()
                Button { Titresim.dokunus(); calar.atla(15) } label: {
                    HikayeIkon(simge: .ileri15, boyut: 19).frame(width: 44, height: 44)
                }
                .accessibilityLabel("15 saniye ileri")
                Spacer()
                Button { calar.kapat() } label: {
                    HikayeIkon(simge: .kapat, boyut: 17, kalinlik: 1.7).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Çaları kapat")
            }
            .buttonStyle(.plain)
            .foregroundStyle(c.yazi)
            .padding(.horizontal, 8).padding(.top, 2).padding(.bottom, 8)
        }
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(c.cam)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
        .shadow(color: c.golge, radius: 18, x: 0, y: 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Fola ses çaları")
    }
}

/// `.mini-calar`: sekme çubuğunun hemen üstünde ince cam çalar (başka sekmede ya da Hikâyeler'in ana ekranında).
/// Dokununca yazının okunan paragrafına döner.
struct HikayeMiniCalar: View {
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @State private var calar = HikayeCalari.shared

    var body: some View {
        GeometryReader { g in
            let ic = g.safeAreaInsets
            let y = SekmeCubugu.Yerlesim(ekranGenisligi: g.size.width + ic.leading + ic.trailing,
                                         ekranYuksekligi: g.size.height + ic.top + ic.bottom,
                                         solGuvenli: ic.leading, sagGuvenli: ic.trailing, altGuvenli: ic.bottom)
            if let h = calar.hikaye {
                cubuk(h)
                    .frame(width: y.cubuk.genislik)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, y.alt + SekmeCubugu.Olcu.yukseklik + 10 - ic.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: calar.hikaye?.id)
    }

    private func cubuk(_ h: SanatciHikayesi) -> some View {
        let c = HikayeRenk(r: tema.renkler)
        return VStack(spacing: 7) {
            HStack(spacing: 10) {
                Group {
                    if let k = calar.kapak {
                        Image(uiImage: k).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        c.yuzey
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(HikayeDeposu.shared.sanatciAdi(h.id)) · \(calar.bolumBasligi)")
                        .font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.yazi).lineLimit(1)
                    Text(calar.paragrafMetni)
                        .font(Yazi.okuma(13)).foregroundStyle(c.yazi2).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 2) {
                    Button { Titresim.dokunus(); calar.atla(-15) } label: {
                        HikayeIkon(simge: .geri15, boyut: 19).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("15 saniye geri")
                    Button { calar.degistir() } label: {
                        Image(systemName: calar.caliyor ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(c.zemin)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(c.yazi))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(calar.caliyor ? "Duraklat" : "Oynat")
                }
                .buttonStyle(.plain)
                .foregroundStyle(c.yazi)
            }
            HikayeCizgi(oran: calar.toplam > 0 ? calar.gecen / calar.toplam : 0)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 9)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(c.cam)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
        .shadow(color: c.golge, radius: 15, x: 0, y: 12)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        // Z4e: dokununca tam ekran çalar (önce yazının okunan paragrafına dönüyordu; o artık çalardaki "Metin"de)
        .onTapGesture {
            Titresim.secim()
            calar.tamEkran = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hikâye çaları: \(h.baslik)")
        .accessibilityAction(named: "Çaları aç") { calar.tamEkran = true }
        .accessibilityAction(named: "Yazıya dön") { Gezgin.shared.git(HikayeAdresi.yazi(h.id)) }
        .accessibilityIdentifier("hikaye-mini")
    }
}

#if DEBUG
/// CI ekran görüntüleri için açılış argümanları (`Testler/ci/ekran.sh`):
/// - `-adres "#/hikaye/<id>"`: yazı açılır (uygulamanın kendi adresi)
/// - `-hikayeKaydir eser|son`: yazı ikinci esere ya da sona kayar
/// - `-hikayeDinle <paragraf>`: çalar o paragrafta, duraklatılmış açılır (`-hikayeSesli`: çalarak)
/// - `-hikayeMini <id>`: çalar o yazıda açılır ve Bugün'e geçilir (küçük çalar)
/// - `-hikayeTema gunduz`: Gündüz teması
/// - Z4e: `-hikayeArsiv enYeni|donem|begendiklerim`: arşiv o sekmede açılır
/// - Z4e: `-hikayeCalar <id>`: çalar o yazıda (duraklatılmış, 2. bölümde) tam ekran açılır
/// - Z4e: `-hikayeDevam`: Devam et ve Sonra oku dolu (Vermeer dinlemede, Rembrandt okumada yarım; Goya sonra oku,
///   Vermeer beğenildi)
enum HikayeProva {
    static var arsiv: String? { NoraSanatApp.arguman("-hikayeArsiv") }
    static var arsivSekmesi: HikayeArsiv.Sekme {
        switch arsiv {
        case "donem": return .donem
        case "begendiklerim": return .begendiklerim
        default: return .enYeni
        }
    }

    static func kaydir() -> String? {
        switch NoraSanatApp.arguman("-hikayeKaydir") {
        case "eser": return "e0-1"
        case "son": return "son"
        default: return nil
        }
    }

    static var dinleParagrafi: Int? { NoraSanatApp.arguman("-hikayeDinle").flatMap(Int.init) }
    static var sesli: Bool { CommandLine.arguments.contains("-hikayeSesli") }

    /// Okuma ekranı açılınca
    @MainActor
    static func okumaAcildi(_ h: SanatciHikayesi) {
        guard let p = dinleParagrafi else { return }
        HikayeCalari.shared.baslat(h, paragraf: p, oynat: sesli)
    }

    /// Sekme açılınca (veri hazır)
    @MainActor
    static func sekmeAcildi() {
        if NoraSanatApp.arguman("-hikayeTema") == "gunduz" {
            TemaDeposu.shared.uygula(TemaRenkleri.gunduz, ayar: TemaAyari(tema: .gunduz), zemin: TemaRenkleri.gunduz.zemin)
        }
        if CommandLine.arguments.contains("-hikayeDevam") { HikayeDeposu.shared.provaDoldur() }
        if let id = NoraSanatApp.arguman("-hikayeCalar"), let h = HikayeDeposu.shared.hikaye(id) {
            let c = HikayeCalari.shared
            c.baslat(h, oynat: false)
            if c.isaretler.count > 2 { c.git(c.isaretler[2].bas + 4) }
            c.tamEkran = true
            return
        }
        guard let id = NoraSanatApp.arguman("-hikayeMini"), let h = HikayeDeposu.shared.hikaye(id) else { return }
        HikayeCalari.shared.baslat(h, paragraf: 3, oynat: false)
        KabukDurumu.shared.sec(.bugun)
    }
}
#endif

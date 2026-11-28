// Z4i · Hikâyeleri uygulamanın öbür yerlerine bağlamak (Emre: "uygulamayı daha bütüncül hale getirmek istiyorum,
// ressamın sayfası onun hikâyesine göndersin"; harita, Bugün ve geri bağlantı da istendi).
// - Sanatçı sayfası (Galeri): künyenin altında hikâye kartı ve "Dizilerde" bölümleri
// - Yolculuk haritası: durak penceresinde o konunun sanatçılarının hikâyeleri (yatay şerit)
// - Bugün: "Resmi gezdin" kısmında günün sanatçısının hikâyesi
// - Hikâye okuma: sonunda sanatçının Galeri sayfasına bağlantı (eserlere dokununca görüntüleyici zaten açılıyordu)
// "Oku" Hikâyeler sekmesine geçip yazıyı açar (`HikayeAdresi`), "Dinle" tam ekran çaları bulunduğun yerde açar.
import NoraCekirdek
import SwiftUI

/// Öbür sekmelerden Hikâyeler'e (ve geri) geçişler
@MainActor
enum HikayeKoprusu {
    /// Sanatçının yazısını Hikâyeler sekmesinde açar
    static func oku(_ id: String) {
        Titresim.secim()
        _ = KabukDurumu.shared.yerliyeGit(HikayeAdresi.yazi(id))
    }

    /// Dizi bölümünü dizi sayfasının üstünde açar
    static func bolumAc(_ b: DiziBolumu) {
        Titresim.secim()
        _ = KabukDurumu.shared.yerliyeGit(HikayeAdresi.diziBolumu(b.dizi, b.id))
    }

    /// Bulunduğun yerde tam ekran çaları açar (yazı Hikâyeler'de açılmaz; küçük çalar altta kalır)
    static func dinle(_ h: SanatciHikayesi) {
        Titresim.dokunus()
        let c = HikayeCalari.shared
        c.baslat(h)
        c.tamEkran = true
    }

    /// Galeri'de sanatçının sayfası
    static func sanatciSayfasi(_ id: String) {
        Titresim.secim()
        let adres = "#/sanatci/" + id
        if !KabukDurumu.shared.yerliyeGit(adres) {
            KabukDurumu.shared.sec(.galeri)
            Gezgin.shared.git(adres)
        }
    }
}

/// Kartın renkleri: her ekran kendi paletini verir
struct HikayeKopruRengi {
    let yazi: Color
    let yazi2: Color
    let vurgu: Color
    let zemin: Color
    let kenar: Color
    /// Dolu düğmenin yazısı
    let doluYazi: Color

    /// Galeri ve okuma ekranı: temanın renkleri
    static func tema(_ r: TemaRenkleri) -> HikayeKopruRengi {
        HikayeKopruRengi(yazi: Color(r.murekkep), yazi2: Color(r.murekkep2), vurgu: Color(r.pirinc),
                         zemin: Color(r.yuzey), kenar: Color(r.notrKenar), doluYazi: Color(r.zemin))
    }

    /// Bugün'ün koyu cam kartları (`.yur-karo`)
    static let bugun = HikayeKopruRengi(yazi: YurRenk.yazi, yazi2: YurRenk.ikincil, vurgu: YurRenk.pirinc(1),
                                        zemin: YurRenk.cam(0.5), kenar: YurRenk.acik(0.2),
                                        doluYazi: Color(red: 0.09, green: 0.075, blue: 0.059))

    /// Yolculuk'un durak penceresi (`.hp2`)
    static let harita = HikayeKopruRengi(yazi: HaritaRenk.yazi, yazi2: HaritaRenk.yazi(0.62), vurgu: HaritaRenk.pirinc,
                                         zemin: HaritaRenk.yazi(0.08), kenar: HaritaRenk.yazi(0.16),
                                         doluYazi: HaritaRenk.koyuYazi)
}

/// Sanatçının hikâyesi: kapak, başlık, süreler; Oku · Dinle. Hikâyesi yoksa hiçbir şey çizmez.
struct SanatciHikayeKarti: View {
    let sanatci: String
    let renk: HikayeKopruRengi
    /// Kartın üstündeki etiket
    var etiket = "Hikâyesi"
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        Group {
            if let h = depo.hikaye(sanatci) { kart(h) }
        }
        .task { await depo.yukle() }
    }

    private func kart(_ h: SanatciHikayesi) -> some View {
        let s = depo.satir(h)
        let dinlenir = depo.dinlenebilir(h)
        let sure = dinlenir ? "\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme" : "\(s.okumaDk) dk okuma"
        return VStack(alignment: .leading, spacing: 14) {
            Button { HikayeKoprusu.oku(h.id) } label: {
                HStack(alignment: .top, spacing: 14) {
                    UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                        .frame(width: 76, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(etiket.uppercased(with: Locale(identifier: "tr_TR")))
                            .font(Yazi.sans(11, agirlik: 600)).tracking(1.6).foregroundStyle(renk.vurgu)
                        Text(h.baslik)
                            .font(Yazi.serif(19, agirlik: 500)).foregroundStyle(renk.yazi)
                            .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5).padding(.bottom, 4)
                        Text(sure).font(Yazi.sans(12.5)).foregroundStyle(renk.yazi2)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Hikâyeler'de açılır")
            HStack(spacing: 10) {
                hap("Oku", simge: "book", dolu: !dinlenir) { HikayeKoprusu.oku(h.id) }
                if dinlenir { hap("Dinle", simge: "headphones", dolu: true) { HikayeKoprusu.dinle(h) } }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(renk.zemin))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(renk.kenar, lineWidth: 1))
        .accessibilityIdentifier("hikaye-koprusu-\(sanatci)")
    }

    private func hap(_ ad: String, simge: String, dolu: Bool, _ eylem: @escaping () -> Void) -> some View {
        Button(action: eylem) {
            HStack(spacing: 7) {
                Image(systemName: simge).font(.system(size: 14, weight: .medium))
                Text(ad).font(Yazi.sans(15, agirlik: 600))
            }
            .foregroundStyle(dolu ? renk.doluYazi : renk.yazi)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Capsule().fill(dolu ? renk.yazi : Color.clear))
            .overlay(Capsule().strokeBorder(dolu ? Color.clear : renk.kenar, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Sanatçının geçtiği dizi bölümleri ("Dizilerde"): dizi adı · bölüm, başlık. Yoksa hiçbir şey çizmez.
struct SanatciDiziBolumleri: View {
    let sanatci: String
    let renk: HikayeKopruRengi
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let bolumler = depo.sanatcininBolumleri(sanatci)
        Group {
            if !bolumler.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("DİZİLERDE").font(Yazi.sans(11, agirlik: 600)).tracking(1.6).foregroundStyle(renk.vurgu)
                        .padding(.bottom, 4)
                    ForEach(Array(bolumler.enumerated()), id: \.element.id) { i, b in
                        satir(b, son: i == bolumler.count - 1)
                    }
                }
            }
        }
        .task { await depo.yukle() }
    }

    private func satir(_ b: DiziBolumu, son: Bool) -> some View {
        let diziAdi = depo.dizi(b.dizi)?.ad ?? ""
        return Button { HikayeKoprusu.bolumAc(b) } label: {
            HStack(spacing: 12) {
                UzakGorsel(url: depo.kapakAdresi(b.hikaye, genislik: 160), icerik: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(diziAdi) · \(b.sira). bölüm").font(Yazi.sans(12, agirlik: 600)).foregroundStyle(renk.yazi2)
                    Text(b.baslik).font(Yazi.serif(16, agirlik: 500)).foregroundStyle(renk.yazi).lineLimit(2)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(renk.yazi2)
            }
            .frame(minHeight: 60)
            .overlay(alignment: .bottom) { if !son { Rectangle().fill(renk.kenar).frame(height: 1) } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Hikâyeler'de açılır")
    }
}

/// Bir grup sanatçının hikâyeleri, yatay şerit (Yolculuk durak penceresi). Hiçbirinin hikâyesi yoksa çizmez.
struct HikayeSeridi: View {
    let sanatcilar: [String]
    let renk: HikayeKopruRengi
    /// Dokunmadan önce (ör. pencereyi kapat)
    var once: () -> Void = {}
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let hikayeler = sanatcilar.compactMap { depo.hikaye($0) }
        Group {
            if !hikayeler.isEmpty {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(hikayeler) { kutu($0) }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .task { await depo.yukle() }
    }

    private func kutu(_ h: SanatciHikayesi) -> some View {
        let s = depo.satir(h)
        return Button {
            once()
            HikayeKoprusu.oku(h.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 112, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(renk.kenar, lineWidth: 0.5))
                Text(s.sanatci).font(Yazi.sans(12, agirlik: 600)).foregroundStyle(renk.vurgu).lineLimit(1)
                Text(h.baslik).font(Yazi.serif(14, agirlik: 500)).foregroundStyle(renk.yazi)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text("\(s.okumaDk) dk").font(Yazi.sans(11.5)).foregroundStyle(renk.yazi2)
            }
            .frame(width: 112, alignment: .leading)
            .multilineTextAlignment(.leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Hikâyeler'de açılır")
    }
}

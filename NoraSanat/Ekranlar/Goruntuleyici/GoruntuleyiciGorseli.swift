// Kaynak: sanat-atlasi js/goruntuleyici.js, js/keskin.js @ a866b86
import SwiftUI
import NoraCekirdek

/// T3'ün görsel bileşeni (`Kabuk/Gorsel.swift`) henüz olmadığından görüntüleyici klasöründe kullanılan
/// geçici `AsyncImage` tabanlı keskin görsel bileşeni.
/// - Önce birincil kopya (1280/800 px) yüklenir; hata verirse `yedek` adres denenir.
/// - Birincil kopya göründükten sonra `devasa` (4096 px, en büyük kopya) varsa arka planda indirilir ve
///   hazır olduğunda sarsıntısız yerine geçer.
struct GoruntuleyiciGorseli: View {
    let birincil: URL?
    let yedek: URL?
    let devasa: URL?
    var yuklendiMi: ((CGSize) -> Void)? = nil

    @State private var yedekKullan = false
    @State private var devasaHazir = false
    @State private var birincilYuklendi = false

    private var etkinBirincil: URL? {
        if yedekKullan, let yedek { return yedek }
        return birincil ?? yedek
    }

    var body: some View {
        ZStack {
            if let url = etkinBirincil {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.18))) { faz in
                    switch faz {
                    case .empty:
                        Text("Yükleniyor…")
                            .font(.subheadline)
                            .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                    case .success(let resim):
                        resim
                            .resizable()
                            .scaledToFit()
                            .opacity(devasaHazir ? 0 : 1)
                            .onAppear {
                                birincilYuklendi = true
                                yuklendiMi?(CGSize(width: 1280, height: 1280))
                            }
                    case .failure:
                        if !yedekKullan, let yedek, yedek != birincil {
                            Color.clear.onAppear { yedekKullan = true }
                        } else {
                            Text("Görsel yüklenemedi.")
                                .font(.subheadline)
                                .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("Görsel yüklenemedi.")
                    .font(.subheadline)
                    .foregroundStyle(GoruntuleyiciTema.ikincilMurekkep)
            }

            // İş 58 / js/keskin.js: birincil görsel yüklendikten sonra en büyük kopya (4096 px) arkada iner,
            // hazır olunca aynı oranda yerine geçer.
            if birincilYuklendi, let devasa, devasa != etkinBirincil {
                AsyncImage(url: devasa) { faz in
                    if case .success(let buyukResim) = faz {
                        buyukResim
                            .resizable()
                            .scaledToFit()
                            .onAppear {
                                devasaHazir = true
                                yuklendiMi?(CGSize(width: 4096, height: 4096))
                            }
                    }
                }
            }
        }
        .onChange(of: birincil) { _, _ in
            yedekKullan = false
            devasaHazir = false
            birincilYuklendi = false
        }
    }
}

/// Tablonun ışığı (İş 69): 400 px'lik küçük kopya çok bulanık ve büyütülmüş olarak tablonun arkasından yayılır.
struct TabloIsigiGorunumu: View {
    let url: URL?
    let opaklikCarpani: Double

    var body: some View {
        if let url {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.7))) { faz in
                if case .success(let resim) = faz {
                    resim
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(1.7)
                        .blur(radius: 34)
                        .saturation(1.4)
                        .brightness(-0.15)
                        .opacity(0.55 * opaklikCarpani)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Görüntüleyicinin gece renkleri (`css/app.css` `.gor` değişkenleri: her temada gece renkleri kullanılır).
enum GoruntuleyiciTema {
    static let zemin = Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0)          // #121110
    static let yuzey = Color(red: 28 / 255.0, green: 26 / 255.0, blue: 24 / 255.0)          // #1c1a18
    static let kenar = Color(red: 46 / 255.0, green: 43 / 255.0, blue: 40 / 255.0)          // #2e2b28
    static let murekkep = Color(red: 235 / 255.0, green: 229 / 255.0, blue: 218 / 255.0)    // #ebe5da
    static let ikincilMurekkep = Color(red: 172 / 255.0, green: 164 / 255.0, blue: 152 / 255.0) // #aca498
    static let ucunculMurekkep = Color(red: 138 / 255.0, green: 131 / 255.0, blue: 121 / 255.0) // #8a8379
    static let vurgu = Color(red: 201 / 255.0, green: 164 / 255.0, blue: 92 / 255.0)        // #c9a45c (pirinç)
    static let vurguYazi = Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0)      // #121110
    static let yanlisIkon = Color(red: 240 / 255.0, green: 154 / 255.0, blue: 134 / 255.0)  // #f09a86
    static let yuvarlakDugmeZemini = Color(red: 18 / 255.0, green: 17 / 255.0, blue: 16 / 255.0).opacity(0.6)
}

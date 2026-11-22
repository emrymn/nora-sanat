// Kaynak: sanat-atlasi js/ekranlar/{harita,pekistir}.js @ a866b86
import SwiftUI
import NoraCekirdek

struct YolculukDurakEkrani: View {
    let durak: YolculukDuragi
    let katalog: SiteKatalogu
    let tur: String
    @Environment(\.dismiss) private var kapat
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @State private var oyun: BolumTuru?
    @State private var beklenen: JSONDeger?
    @State private var il: Ilerleme?
    @State private var veri = PekistirmeVerileri(ikonografi:nil,zorluk:nil)
    @State private var hata: String?
    @State private var mesgul = false
    private var alan: String { "noraYolculuk-" + durak.id }
    private var kayit: JSONDeger? { il?[alan:"bolumler"]?[durak.id] ?? durak.kayit }
    private func gecti(_ ad:String) -> Bool { (kayit?[ad]?.sayi ?? 0) >= 0.75 }

    var body: some View {
        ScrollViewReader { vekil in ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack { Spacer(); Button { kapat() } label: { GaleriIkon(simge:.kapat) }.buttonStyle(YuvarlakDugme()).accessibilityLabel("Kapat") }
                if let hata {
                    Text(hata)
                    Button("Yeniden yükle") { Task { await yukle() } }
                } else if let oyun { kart(oyun) }
                else if il == nil { ProgressView() }
                else { icerik }
            }.padding(24)
        }
        #if DEBUG && targetEnvironment(simulator)
        .onChange(of:oyun?.tur.bitti) { _,son in
            if son == true && YolculukProva.ad == "seviye-tamam" { vekil.scrollTo("madalyon",anchor:.top) }
        }
        #endif
        }.background(Color(tema.renkler.zemin)).foregroundStyle(Color(tema.renkler.murekkep))
         .disabled(mesgul).task { await yukle() }
    }

    private func yukle() async {
        do {
            let ek = await SiteVerisi().veriler(["eser_zorluk.json","tanima_notlari.json"])
            veri = .init(ikonografi:nil,zorluk:ek["eser_zorluk.json"],tanima:ek["tanima_notlari.json"])
            var gelen = try await IlerlemeKoprusu.shared.oku()
            #if DEBUG && targetEnvironment(simulator)
            if let ad = YolculukProva.ad {
                if ad != "kilit" { YolculukProva.ornek(&gelen) }
                if YolculukProva.turlar.contains(ad) {
                    let grup = ad == "tanisma" || ad == "grup-sonu"
                    let sv: BolumSeviyesi = grup ? .tanitim(orta:false,grup:0) : .kolay
                    var o = BolumTuru(durak:durak,seviye:sv,katalog:katalog,veri:veri,il:&gelen)
                    for _ in 0..<350 {
                        if o.tur.bitti || (ad == "tanisma" && o.tur.tanismaBekliyor) { break }
                        if let kart = o.tur.kart, kart.tanisma == nil, !o.tur.tanismaBekliyor {
                            if ad == "soru" && kart.sonuc == nil { break }
                            if ad == "cevap" && kart.sonuc != nil { break }
                            if kart.sonuc == nil {
                                o.cevapla(kart.ikinci ? katalog.harita[kart.resim.id]?.akim : kart.dogru,katalog:katalog,il:&gelen)
                                continue
                            }
                        }
                        o.ilerle(katalog:katalog,veri:veri,il:&gelen)
                    }
                    oyun = o
                }
                il = gelen; YolculukProva.hazir(ad); return
            }
            #endif
            il = gelen; beklenen = gelen.ayar(alan)
            if let s = beklenen?.metin { oyun = try JSONDecoder().decode(BolumTuru.self,from:Data(s.utf8)) }
            else { oyun = nil }
            hata = nil
        } catch { hata = "Durak okunamadı." }
    }

    @ViewBuilder private var icerik: some View {
        if let id = durak.sanatcilar.first {
            UzakGorsel(url:katalog.kucukGorselAdresi(id,genislik:640)).aspectRatio(1.8,contentMode:.fit).clipShape(RoundedRectangle(cornerRadius:12))
        }
        Etiket("\(YolculukHaritasi.adlar[YolculukHaritasi.bolgeler.firstIndex(of:durak.bolge) ?? 0]) · \(durak.sanatcilar.count) sanatçı")
        Text(durak.ad).font(Yazi.serif(32))
        if let kilit = durak.kilit {
            Text(kilit).font(Yazi.okuma(18))
            if durak.dersGerekli { Button("Derse git") { git("#/pekistir/ders/"+durak.akim,.calis) }.buttonStyle(HapDugme()) }
        } else {
            yildizlar
            let gruplar = durak.gruplar
            if !gecti("kolay"), gruplar.count > 1, let i = gruplar.indices.first(where:{ !goruldu(false,$0) }) {
                Button("\(i+1). grupla tanış") { basla(.tanitim(orta:false,grup:i)) }.buttonStyle(HapDugme())
            } else if let s = ["kolay","orta","zor"].first(where:{ !gecti($0) }) {
                Button("\(s.capitalized) seviyeye başla") { basla(seviye(s)) }.buttonStyle(HapDugme())
            }
        }
        ForEach(durak.gruplar.indices,id:\.self) { i in
            let grup = durak.gruplar[i]
            Button { basla(.tanitim(orta:false,grup:durak.gruplar.count > 1 ? i : nil)) } label: {
                HStack { UzakGorsel(url:grup.first.flatMap { katalog.kucukGorselAdresi($0,genislik:120) }).frame(width:40,height:40).clipped()
                    Text(grup.map { katalog.bilinenAd($0) ?? $0 }.joined(separator:", ")); Spacer()
                    Text(goruldu(false,i) ? "✓" : durak.gruplar.count > 1 ? "\(grup.count*2) soru" : "Tanış")
                }
            }.disabled(!durak.acik)
            Divider()
        }
        if durak.acik {
            ForEach(["kolay","orta","zor"], id:\.self) { s in
                let acik = s == "kolay" || gecti(s == "orta" ? "kolay" : "orta")
                Button { basla(seviye(s)) } label: {
                    HStack { Image(systemName:acik ? "star" : "lock"); Text(s.capitalized); Spacer()
                        Text(kayit?[s]?.sayi.map { "%\(Int(($0*100).rounded()))" } ?? (acik ? "\(s == "kolay" ? 8 : 10) soru" : "Kilitli"))
                    }
                }.disabled(!acik)
                Divider()
            }
            if gecti("kolay") { ForEach(durak.gruplar.indices,id:\.self) { i in
                Button("Orta eserleri" + (durak.gruplar.count > 1 ? " · \(i+1). grup" : "") + (goruldu(true,i) ? " ✓" : "")) {
                    basla(.tanitim(orta:true,grup:durak.gruplar.count > 1 ? i : nil))
                }
            } }
        }
        Button("Akım sayfası") { git("#/akim/"+durak.akim,.galeri) }
    }

    private func git(_ adres:String,_ sekme:Sekme) { kapat(); kabuk.sec(sekme); Gezgin.shared.git(adres) }
    private func goruldu(_ orta:Bool,_ i:Int) -> Bool {
        let alan = orta ? "tanitimOrta" : "tanitim"
        return kayit?[alan]?.mantik == true || kayit?[alan+"Grup"]?.dizi?.contains(.sayi(Double(i))) == true
    }
    private func seviye(_ ad:String) -> BolumSeviyesi { ad == "kolay" ? .kolay : ad == "orta" ? .orta : .zor }
    private func basla(_ s:BolumSeviyesi) {
        yaz { il in BolumTuru(durak:durak,seviye:s,katalog:katalog,veri:veri,il:&il) }
    }
    private func yaz(_ islem:@escaping (inout Ilerleme)->BolumTuru) {
        guard !mesgul else { return }
        mesgul = true
        Task {
            defer { mesgul = false }
            do {
                var yeni: BolumTuru?
                let gelen = try await IlerlemeKoprusu.shared.degistir { il in
                    guard il.ayar(alan) == beklenen else { throw IlerlemeKoprusu.Hata.cakisma }
                    let tur = islem(&il)
                    let d = try JSONEncoder().encode(tur)
                    il.ayarla(alan,tur.tur.bitti ? nil : .metin(String(decoding:d,as:UTF8.self)))
                    yeni = tur
                }
                beklenen = gelen.ayar(alan); il = gelen; oyun = yeni
            } catch { hata = "Tur kaydedilemedi. Güncel ilerlemeyi yükleyip tekrar dene." }
        }
    }

    @ViewBuilder private func kart(_ o:BolumTuru) -> some View {
        if o.tur.tanismaBekliyor, let t = o.tur.tanisma, let id = t.simdiki {
            Etiket("Tanış · \(t.konum+1) / \(t.sira.count)")
            Text(katalog.harita[id]?.ad ?? id).font(Yazi.serif(30))
            ForEach(t.gosterilen,id:\.self) { anahtar in
                if let e = katalog.eserler(id).first(where:{$0.anahtar == anahtar}) { resim(e); Text(e.gorunenAd) }
            }
            ileri(o,"Devam")
        } else if let k = o.tur.kart {
            Etiket("\(durak.ad) · \(o.tur.gorunenKonum+1) / \(o.tur.oturum.kuyruk.count)")
            if let ters = k.ters {
                Text("\(katalog.bilinenAd(k.dogru) ?? k.dogru) hangi eseri yaptı?").font(Yazi.serif(23))
                ForEach(ters,id:\.id) { r in Button { cevap(o,r.id) } label: { resim(r.eser) }.disabled(k.sonuc != nil) }
            } else {
                resim(k.resim.eser)
                Text(k.ikinci ? "Hangi akım?" : "Bu eseri kim yaptı?").font(Yazi.serif(24))
                ForEach(k.ikinci ? k.akimlar ?? [] : k.secenekler,id:\.self) { id in
                    Button(k.ikinci ? id : katalog.bilinenAd(id) ?? id) { cevap(o,id) }.buttonStyle(HapDugme(ince:true)).disabled(k.sonuc != nil)
                }
            }
            if let dogru = k.sonuc {
                Text(dogru ? "Doğru" : "Doğru cevap · " + (k.ikinci ? katalog.harita[k.resim.id]?.akim ?? "" : katalog.bilinenAd(k.dogru) ?? k.dogru))
                ileri(o,"Devam")
            } else { Button("Bilmiyorum") { cevap(o,nil) } }
        } else {
            if case .tanitim(_,let grup) = o.seviye {
                Etiket(grup == nil ? "Tanışma tamam" : "Grup tamam")
            } else {
                Etiket(o.oran >= 0.75 ? "Sergi açıldı" : "Sergi hazırlanıyor")
                ScrollView(.horizontal) { HStack(spacing:12) {
                    ForEach(Array(o.sergi.enumerated()),id:\.offset) { i,e in
                        UzakGorsel(url:katalog.gorselAdresi(e.resim.eser,genislik:240)).frame(width:72,height:88).clipped()
                            .border(.brown,width:3).rotationEffect(.degrees(e.dogru ? Double(i*37%5-2)/2 : i%2 == 1 ? 3.5 : -4))
                            .accessibilityLabel(e.resim.eser.gorunenAd + (e.dogru ? ", tanıdın" : ", tanıyamadın"))
                    }
                }.padding(8) }
                UzakGorsel(url:haritaGorseli("sembol_\(durak.bolge)_\(durak.sembol)_\(tur)"),icerik:.fit)
                    .frame(width:64,height:64).overlay(Circle().stroke(Color(tema.renkler.vurguAcik),lineWidth:2))
                 .id("madalyon")
                Text(o.oran >= 0.75 ? "Seviye tamam" : "Az kaldı").font(Yazi.serif(28))
                yildizlar
                OranCubugu(oran:o.oran)
                Text("%\(Int((o.oran*100).rounded())) · Hedef %75")
            }
            Text(durak.ad).font(Yazi.serif(24))
            if o.tur.oturum.ilkToplam > 0 { Text("\(o.tur.oturum.ilkDogru) / \(o.tur.oturum.ilkToplam) doğru") }
            Button("Durağa dön") { oyun = nil }.buttonStyle(HapDugme())
            Button("Haritaya dön") { kapat() }
        }
    }
    private var yildizlar: some View {
        HStack { ForEach(["kolay","orta","zor"],id:\.self) { ad in Image(systemName:gecti(ad) ? "star.fill" : "star") } }
            .foregroundStyle(Color(tema.renkler.vurguAcik))
    }
    private func resim(_ e:Eser) -> some View {
        UzakGorsel(url:katalog.gorselAdresi(e,genislik:640,kotuler:il?.kotuGorseller ?? [:]),icerik:.fit).frame(maxWidth:.infinity).frame(height:230)
    }
    private func cevap(_ once:BolumTuru,_ secim:String?) {
        yaz { il in var o = once; o.cevapla(secim,katalog:katalog,il:&il); return o }
    }
    private func ileri(_ once:BolumTuru,_ ad:String) -> some View {
        Button(ad) { yaz { il in var o = once; o.ilerle(katalog:katalog,veri:veri,il:&il); return o } }.buttonStyle(HapDugme())
    }
}

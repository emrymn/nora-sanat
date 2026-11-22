// Kaynak: sanat-atlasi js/ekranlar/harita.js, js/harita.js, css/app.css @ a866b86
import SwiftUI
import NoraCekirdek

@MainActor @Observable
final class YolculukDeposu {
    let site = SiteVerisi()
    var katalog: SiteKatalogu?
    var ilerleme: Ilerleme?
    var dosyalar = [String:JSONDeger]()
    var duraklar = [YolculukDuragi]()
    var hata: String?

    func yukle() async {
        do {
            if katalog == nil {
                async let k = site.katalog()
                let dosya = await site.veriler(["harita.json","harita_yolcu.json","harita_patikalar.json","harita_motifler.json","ders_kaynaklari.json","yuruyus.json"])
                dosyalar = try dosya.mapValues(JSONDeger.coz)
                guard dosyalar["harita.json"] != nil else { throw URLError(.cannotDecodeContentData) }
                katalog = try await k
            }
            var il = try await IlerlemeKoprusu.shared.oku()
            #if DEBUG && targetEnvironment(simulator)
            if let ad = YolculukProva.ad {
                if ad == "durak" || YolculukProva.turlar.contains(ad) { YolculukProva.ornek(&il) }
                guncelle(il)
                return
            }
            #endif
            guncelle(il)
            let eski = ilerleme?[alan:"haritaGorulen"]?.dizi ?? []
            let yeni = duraklar.filter { $0.acik && !eski.contains(.metin($0.id)) }.map(\.id)
            if !yeni.isEmpty {
                await yaz { il in
                    var idler = il[alan:"haritaGorulen"]?.dizi?.compactMap(\.metin) ?? []
                    for id in yeni where !idler.contains(id) { idler.append(id) }
                    il[alan:"haritaGorulen"] = .dizi(idler.prefix(300).map(JSONDeger.metin))
                }
            }
        } catch { hata = "Yolculuk verileri okunamadı." }
    }

    func yaz(_ islem: (inout Ilerleme) -> Void) async {
        do { guncelle(try await IlerlemeKoprusu.shared.degistir(islem)) }
        catch { hata = "İlerleme kaydedilemedi. Yeniden dene." }
    }

    func guncelle(_ il: Ilerleme) {
        ilerleme = il
        if let katalog, let veri = dosyalar["harita.json"] {
            duraklar = YolculukHaritasi.kur(katalog,ilerleme:il,harita:veri,dersler:dosyalar["ders_kaynaklari.json"],yuruyus:dosyalar["yuruyus.json"])
        }
        hata = nil
    }

    var simdiki: YolculukDuragi? { duraklar.first { $0.acik && !$0.gecti("orta") } ?? duraklar.last(where: \.acik) }
    var yolcu: YolculukDuragi? { duraklar.first { $0.acik && $0.id == ilerleme?[alan:"haritaYolcu"]?.metin } ?? simdiki }
}

struct YolculukSekmesi: View {
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = YolculukDeposu()
    @State private var zaman = false
    @State private var yenile = 0
    var body: some View {
        Group {
            if let hata = depo.hata {
                ContentUnavailableView { Text(hata) } actions: {
                    Button("Yeniden dene") { Task { await depo.yukle() } }
                } 
            } else if let k = depo.katalog, let il = depo.ilerleme {
                if zaman { ZamanEkrani(katalog:k, ilerleme:il) }
                else { YolculukHaritaEkrani(depo:depo, katalog:k, il:il, zaman:{ zaman = true }).id(yenile) }
            } else { ProgressView("Yolculuk hazırlanıyor…") }
        }.frame(maxWidth:.infinity,maxHeight:.infinity)
         .background(Color(tema.renkler.zemin)).foregroundStyle(Color(tema.renkler.murekkep))
         .task {
             await depo.yukle()
             #if DEBUG && targetEnvironment(simulator)
             if depo.ilerleme != nil, YolculukProva.ad == "zaman" { YolculukProva.hazir("zaman") }
             #endif
         }
         .onChange(of:kabuk.yerliAdres[.yolculuk],initial:true) { _, adres in
             if let adres { zaman = adres == "#/zaman"; kabuk.adresIslendi(.yolculuk) }
             #if DEBUG
             if NoraSanatApp.arguman("-yolculukProva") == "zaman" { zaman = true }
             #endif
         }
         .onChange(of:kabuk.yenidenDokunma[.yolculuk]) { _,_ in zaman = false; yenile += 1 }
    }
}

func haritaGorseli(_ ad: String) -> URL? {
    URL(string:"https://sanat-atlasi.pages.dev/gorseller/harita/\(ad).webp")
}

private struct YolculukHaritaEkrani: View {
    let depo: YolculukDeposu
    let katalog: SiteKatalogu
    let il: Ilerleme
    let zaman: () -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @State private var tur = YolculukHaritasi.vakit(saat:Calendar.current.component(.hour,from:Date()))
    @State private var durak: YolculukDuragi?
    @State private var kurs = false
    @State private var motif: String?
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var animasyonYeri: YolcuPatikasi.Nokta?
    @State private var animasyonOn = false
    @State private var yuruyus: Task<Void,Never>?
    private let bolgeler = YolculukHaritasi.bolgeler

    var body: some View {
        GeometryReader { g in
            ScrollViewReader { vekil in
                ScrollView {
                    VStack(spacing:0) {
                        HStack(alignment:.firstTextBaseline) {
                            Text("Yolculuk").font(Yazi.serif(30))
                            Text("\(depo.duraklar.filter(\.acik).count)/\(depo.duraklar.count) bölüm · \(depo.duraklar.reduce(0){$0+$1.yildiz}) ★").font(Yazi.sans(14))
                            Spacer()
                        }.padding(.horizontal,24).frame(height:48)
                        ForEach(bolgeler.indices.reversed(),id:\.self) { i in
                            donem(i,g.size.width)
                            if i > 0 { gecis(i,g.size.width) }
                        }
                        Color.clear.frame(height:1).id("son")
                    }
                }.defaultScrollAnchor(.bottom)
                 .task {
                     await Task.yield()
                     #if DEBUG && targetEnvironment(simulator)
                     if let ad = YolculukProva.ad {
                         switch ad {
                         case "harita": YolculukProva.hazir(ad)
                         case "kurs": kurs = true; YolculukProva.hazir(ad)
                         case "motif":
                             if let id = depo.dosyalar["harita.json"]?["bolgeler"]?["ortacag"]?["motifler"]?.dizi?.first?["eser"]?.metin {
                                 motif = id; YolculukProva.hazir(ad)
                             }
                         case "kilit": durak = depo.duraklar.first { !$0.acik }
                         default: if ad == "durak" || YolculukProva.turlar.contains(ad) { durak = depo.duraklar.first { $0.id == "4-1" } }
                         }
                     }
                     #endif
                     vekil.scrollTo(depo.simdiki?.id ?? "son",anchor:UnitPoint(x:0.5,y:0.55))
                 }
            }
            .overlay(alignment:.top) {
                HStack(alignment:.top) {
                    Button { kurs = true } label: {
                        HStack(spacing:10) {
                            let sayi = katalog.kursKonulari.filter { il.islenenKume.contains($0.no) }.count
                            ZStack { Circle().stroke(.secondary,lineWidth:2)
                                Circle().trim(from:0,to:CGFloat(sayi)/CGFloat(max(1,katalog.kursKonulari.count))).stroke(.yellow,lineWidth:2).rotationEffect(.degrees(-90))
                            }.frame(width:32,height:32)
                            VStack(alignment:.leading) {
                                Text("\(sayi) / \(katalog.kursKonulari.count) konu").font(Yazi.sans(15,agirlik:600))
                                Text(katalog.kursKonulari.first { !il.islenenKume.contains($0.no) }.map { "Sıradaki: Konu \($0.no)" } ?? "Bütün konular işlendi").font(Yazi.sans(12))
                            }
                        }.padding(.leading,10).padding(.trailing,16).frame(height:52).background(.ultraThinMaterial,in:Capsule())
                    }
                    Spacer()
                    Button { tur = tur == "gece" ? "gunduz" : "gece" } label: {
                        Image(systemName:tur == "gece" ? "sun.max" : "moon").frame(width:44,height:44).background(.ultraThinMaterial,in:Circle())
                    }.accessibilityLabel(tur == "gece" ? "Gündüze geç" : "Geceye geç")
                }.buttonStyle(.plain).padding(.horizontal,12).padding(.top,10)
            }
        }
        .onDisappear { yuruyus?.cancel() }
        .sheet(item:$durak,onDismiss:{ Task { await depo.yukle() } }) { x in
            YolculukDurakEkrani(durak:x,katalog:katalog,tur:tur).presentationDragIndicator(.visible)
        }
        .sheet(isPresented:$kurs) {
            VStack(spacing:18) {
                Etiket("Kursun neresindesin")
                Text("\(katalog.kursKonulari.filter { il.islenenKume.contains($0.no) }.count) / \(katalog.kursKonulari.count) konu işlendi").font(Yazi.serif(28))
                if let konu = katalog.kursKonulari.first(where:{ !il.islenenKume.contains($0.no) }) {
                    Etiket("Sıradaki · Konu \(konu.no)")
                    Text(konu.baslik).font(Yazi.serif(20))
                    Button("İşlendi yap") { Task { await depo.yaz { BenPanosu.isaretle([konu.no],islendi:true,il:&$0) } } }.buttonStyle(HapDugme())
                }
                Button("Bütün konular") { kurs = false; kabuk.sec(.ben); Gezgin.shared.git("#/ilerleme") }
                Button("Zaman") { kurs = false; zaman() }
            }.padding(24).presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(get:{ motif != nil },set:{ if !$0 { motif = nil } })) {
            if let id = motif, let eser = depo.dosyalar["harita.json"]?["eserler"]?[id] {
                ScrollView { VStack(alignment:.leading,spacing:14) {
                    Etiket("Saklı motif")
                    Text(eser["eser_tr"]?.metin ?? id).font(Yazi.serif(32))
                    Text([eser["sanatci"],eser["yil"],eser["yer"]].compactMap{$0?.metin}.joined(separator:" · ")).font(Yazi.sans(14))
                    Text(eser["hikaye"]?.metin ?? "").font(Yazi.okuma(18))
                    ForEach(depo.dosyalar["harita_motifler.json"]?["motifler"]?[id]?["hikaye"]?.dizi?.compactMap(\.metin) ?? [],id:\.self) { Text($0).font(Yazi.okuma(18)) }
                }.padding(24) }.presentationDragIndicator(.visible)
            }
        }
    }

    private func donem(_ i: Int, _ en: CGFloat) -> some View {
        let bolge = bolgeler[i]
        let motifler = depo.dosyalar["harita.json"]?["bolgeler"]?[bolge]?["motifler"]?.dizi ?? []
        return ZStack(alignment: .topLeading) {
            donemResmi(i)
            ForEach(motifler.indices, id: \.self) { j in motifDugmesi(motifler[j], no:j, en:en) }
            ForEach(depo.duraklar.filter { $0.bolge == bolge }) { d in durakDugmesi(d, en:en) }
            if let d = depo.yolcu, d.bolge == bolge { yolcu(d,en:en) }
        }.frame(width:en,height:en*3).clipped()
    }

    private func donemResmi(_ i:Int) -> some View {
        let resim = haritaGorseli("donem_\(bolgeler[i])_\(tur)")
        let ust = Double(8-i)*1.34
        let acik = depo.duraklar.filter(\.acik)
        let sinir = acik.map { d in Double(8-(bolgeler.firstIndex(of:d.bolge) ?? 0))*1.34 + d.y - 0.07 }.min() ?? 11.72
        let alt = min(1,max(0,sinir-ust))
        let renk:Color = sinir >= ust+1 ? .white : .clear
        let gecis = Gradient(stops:[.init(color:.white,location:max(0,alt-0.04)),.init(color:renk,location:alt)])
        return UzakGorsel(url:resim).overlay {
            if sinir > ust {
                UzakGorsel(url:resim).saturation(0.15).colorMultiply(Color(red:0.88,green:0.83,blue:0.74))
                    .mask(LinearGradient(gradient:gecis,startPoint:.top,endPoint:.bottom))
            }
        }
    }

    @ViewBuilder private func motifDugmesi(_ m:JSONDeger,no:Int,en:CGFloat) -> some View {
        if let p = m["kutu"]?.dizi?.compactMap(\.sayi), p.count == 4 {
            let w = CGFloat(p[2]-p[0])*en
            let h = CGFloat(p[3]-p[1])*en*3
            Button { motif = m["eser"]?.metin } label: { Color.clear.contentShape(Rectangle()) }
                .frame(width:w,height:h).offset(x:CGFloat(p[0])*en,y:CGFloat(p[1])*en*3)
                .accessibilityLabel("Saklı motif \(no+1)")
        }
    }

    private func durakDugmesi(_ d:YolculukDuragi,en:CGFloat) -> some View {
        let olcek = en/390
        let w = CGFloat(d.en)*olcek, h = CGFloat(d.boy)*olcek
        let x = CGFloat(d.x)*en + CGFloat(0.5-d.ax)*w
        let y = CGFloat(d.y)*en*3 + CGFloat(0.5-d.ay)*h
        return Button { sec(d) } label: {
            UzakGorsel(url:haritaGorseli("sembol_\(d.bolge)_\(d.sembol)_\(tur)"),icerik:.fit)
                .overlay { Circle().stroke(d.acik ? Color.yellow.opacity(0.8) : Color.gray,lineWidth:2) }
                .overlay(alignment:.bottom) {
                    if d.acik {
                        HStack(spacing:1) { ForEach(0..<3,id:\.self) { i in Image(systemName:i<d.yildiz ? "star.fill" : "star") } }.font(.system(size:8))
                    } else { Image(systemName:"lock.fill").font(.caption2) }
                }
        }.buttonStyle(.plain).frame(width:w,height:h)
         .overlay(alignment:.bottom) {
            if d.id == depo.simdiki?.id {
                let sv = ["kolay","orta","zor"].first { !d.gecti($0) }
                VStack(spacing:2) {
                    Text(d.ad).font(Yazi.serif(16))
                    Text(sv.map { "\($0.capitalized) · \($0 == "kolay" ? 8 : 10) soru seni bekliyor" } ?? "Üç yıldız tamam").font(Yazi.sans(11))
                }.fixedSize().padding(6).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:8)).offset(y:d.y>0.84 ? -75 : 46)
            }
         }
         .position(x:x,y:y).accessibilityLabel(d.ad + (d.kilit.map { ", "+$0 } ?? ", \(d.yildiz) yıldız")).id(d.id)
    }

    @ViewBuilder private func yolcu(_ d:YolculukDuragi,en:CGFloat) -> some View {
        if let v = depo.dosyalar["harita_yolcu.json"]?["bolgeler"]?[d.bolge], let ad = v["ad"]?.metin {
            let p = animasyonYeri ?? YolcuPatikasi.yer(d)
            let on = animasyonYeri == nil ? il[alan:"haritaYolcuOn"]?.mantik == true : animasyonOn
            let poz = on ? "on" : "dur"
            let olcu = v["pozlar"]?[poz]
            let w = CGFloat(olcu?["w"]?.sayi ?? 33)*en/390
            let y = CGFloat(p.y + 96*(0.5-(olcu?["ay"]?.sayi ?? 1)))*en/390
            UzakGorsel(url:haritaGorseli("\(ad)_\(d.bolge)_\(poz)_\(tur)"),icerik:.fit)
                .frame(width:w,height:96*en/390).position(x:CGFloat(p.x)*en/390,y:y).allowsHitTesting(false)
        }
    }

    private func sec(_ x:YolculukDuragi) {
        guard yuruyus == nil else { return }
        guard x.acik, let eski = depo.yolcu, let yol = YolcuPatikasi(duraklar:depo.duraklar,eski:eski.id,yeni:x.id,veri:depo.dosyalar["harita_patikalar.json"]) else { durak = x; return }
        yuruyus = Task { @MainActor in
            defer { yuruyus = nil; animasyonYeri = nil }
            if yol.yurunur && !hareketAz && !tema.ayar.hareketAzaltilmis {
                let bas = Date()
                while !Task.isCancelled {
                    let t = Date().timeIntervalSince(bas)/yol.sure
                    let nokta = yol.konum(t)
                    animasyonYeri = nokta.yer; animasyonOn = nokta.on
                    if t >= 1 { break }
                    try? await Task.sleep(for:.milliseconds(20))
                }
            }
            guard !Task.isCancelled else { return }
            await depo.yaz { il in
                il[alan:"haritaYolcu"] = .metin(x.id)
                il[alan:"haritaYolcuOn"] = .mantik(yol.geri && !hareketAz && !tema.ayar.hareketAzaltilmis)
            }
            if !Task.isCancelled { durak = x }
        }
    }

    private func gecis(_ i:Int,_ en:CGFloat) -> some View {
        ZStack {
            UzakGorsel(url:haritaGorseli("yansima_\(bolgeler[i])_alt_\(tur)")).scaleEffect(x:1,y:-1)
            UzakGorsel(url:haritaGorseli("yansima_\(bolgeler[i-1])_ust_\(tur)")).scaleEffect(x:1,y:-1)
                .mask(LinearGradient(colors:[.clear,.white],startPoint:.top,endPoint:.bottom))
            Text(YolculukHaritasi.adlar[i]).font(Yazi.serif(30)).shadow(radius:5)
        }.frame(width:en,height:en*1.02).clipped()
    }
}

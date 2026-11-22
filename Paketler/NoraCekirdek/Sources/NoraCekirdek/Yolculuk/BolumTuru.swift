// Kaynak: sanat-atlasi js/bolum.js, js/ekranlar/pekistir.js (kartiBitir, grupOzeti, bolumOzeti) @ a866b86
import Foundation

public struct BolumTuru: Codable {
    public struct AsiliEser: Codable { public let resim: TurKarti.Resim; public let dogru: Bool }
    public private(set) var tur: TurKaydi
    public private(set) var sergi = [AsiliEser]()
    public let id: String
    public let seviye: BolumSeviyesi
    let grupSayisi: Int

    public init(durak: YolculukDuragi, seviye: BolumSeviyesi, katalog: SiteKatalogu, veri: PekistirmeVerileri, il: inout Ilerleme) {
        id = durak.id
        self.seviye = seviye
        grupSayisi = durak.gruplar.count
        tur = TurKaydi(kip:.sanatci(.bolum(id:id,sanatcilar:durak.sanatcilar,seviye:seviye)), seviye:nil, katalog:katalog,veri:veri,ilerleme:il,gun:GunTarihi.gun(Date()))
        tur.hazirla(katalog:katalog,veri:veri,ilerleme:&il)
    }

    public mutating func cevapla(_ secim:String?, katalog:SiteKatalogu, il:inout Ilerleme) {
        guard let kart = tur.kart, kart.sonuc == nil else { return }
        let toplam = tur.oturum.ilkToplam, dogru = tur.oturum.ilkDogru
        tur.cevapla(secim,katalog:katalog,gun:GunTarihi.gun(Date()),ilerleme:&il)
        if tur.oturum.ilkToplam > toplam { sergi.append(.init(resim:kart.resim,dogru:tur.oturum.ilkDogru > dogru)) }
    }

    public mutating func ilerle(katalog:SiteKatalogu, veri:PekistirmeVerileri, il:inout Ilerleme) {
        let tanisma = tur.tanismaBekliyor
        if tanisma || tur.kart?.tanisma != nil { tur.tanismaGec(katalog:katalog,veri:veri,ilerleme:&il) }
        else { tur.sonraki(katalog:katalog,veri:veri,ilerleme:&il) }
        var hepsi = il[alan:"bolumler"]?.nesne ?? .bos
        var k = hepsi[id]?.nesne ?? .bos
        let orta = seviye == .orta || { if case .tanitim(true,_) = seviye { return true }; return false }()
        let alan = orta ? "tanitimOrta" : "tanitim"
        let grup: Int? = { if case let .tanitim(_,g) = seviye { return g }; return nil }()
        if tanisma && !tur.tanismaBekliyor && grup == nil { k = k.ayarlandi(alan,.mantik(true)) }
        if tur.bitti {
            if let grup {
                var gorulen = Set(k[alan+"Grup"]?.dizi?.compactMap(\.tamSayi) ?? [])
                gorulen.insert(grup)
                k = k.ayarlandi(alan+"Grup",.dizi(gorulen.sorted().map { .sayi(Double($0)) }))
                if gorulen.filter({ $0 < grupSayisi }).count >= grupSayisi { k = k.ayarlandi(alan,.mantik(true)) }
            } else if case .tanitim = seviye {} else {
                let ad = seviye == .zor ? "zor" : orta ? "orta" : "kolay"
                k = k.ayarlandi(ad,.sayi(max(k[ad]?.sayi ?? 0,(oran*1000).rounded()/1000)))
            }
        }
        if !k.ciftler.isEmpty {
            hepsi = hepsi.ayarlandi(id,.nesne(k))
            il[alan:"bolumler"] = .nesne(hepsi)
        }
    }
    public var oran: Double { tur.oturum.ilkToplam == 0 ? 0 : Double(tur.oturum.ilkDogru)/Double(tur.oturum.ilkToplam) }
}

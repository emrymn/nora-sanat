// Kaynak: sanat-atlasi js/depo.js (yedekCoz), js/ekranlar/ayarlar.js (geri yükleme onayı) @ a866b86
import Foundation

/// Eski biçimleri site doğrular. Onay ekranı aynı doğrulanmış nesneyi T2 üzerinden okur.
public struct BenYedekOzeti {
    public let konu, skor: Int

    public init(dogrulanmisJSON: String) throws {
        let il = try Ilerleme(veri: Data(dogrulanmisJSON.utf8))
        konu = il.islenen.count
        skor = il.skorlar.count
    }
}

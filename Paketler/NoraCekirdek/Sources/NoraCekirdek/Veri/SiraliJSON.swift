import Foundation

/// JSON nesnesinin anahtarlarını dosyadaki sırasıyla verir. Swift'in çözücüleri sırayı korumaz; site ise bazı
/// kurallarda `Object.entries` sırasını kullanır (ör. ortak atıflarda sanatçı sırası, js/eserler.js `ortakAtiflariAyarla`).
enum SiraliJSON {
    /// Kök nesnenin `alan` alanındaki nesnenin anahtarları; bulunamazsa boş
    static func anahtarlar(_ veri: Data, alan: String) -> [String] {
        let b = [UInt8](veri)
        var i = 0
        func bosluk() { while i < b.count, b[i] == 0x20 || b[i] == 0x0A || b[i] == 0x0D || b[i] == 0x09 { i += 1 } }
        /// i bir '"' üstünde; dizgenin sonrasına geçer, ham baytları döndürür
        func dizge() -> ArraySlice<UInt8>? {
            guard i < b.count, b[i] == 0x22 else { return nil }
            let bas = i
            i += 1
            while i < b.count {
                if b[i] == 0x5C { i += 2; continue }
                if b[i] == 0x22 { i += 1; return b[bas..<i] }
                i += 1
            }
            return nil
        }
        func coz(_ d: ArraySlice<UInt8>) -> String? {
            (try? JSONSerialization.jsonObject(with: Data(d), options: [.fragmentsAllowed])) as? String
        }
        /// Bir değeri atlar
        func atla() -> Bool {
            bosluk()
            guard i < b.count else { return false }
            switch b[i] {
            case 0x22: return dizge() != nil
            case 0x7B, 0x5B:
                var derinlik = 0
                while i < b.count {
                    switch b[i] {
                    case 0x22: guard dizge() != nil else { return false }; continue
                    case 0x7B, 0x5B: derinlik += 1
                    case 0x7D, 0x5D:
                        derinlik -= 1
                        if derinlik == 0 { i += 1; return true }
                    default: break
                    }
                    i += 1
                }
                return false
            default:
                while i < b.count, ![0x2C, 0x7D, 0x5D, 0x20, 0x0A, 0x0D, 0x09].contains(b[i]) { i += 1 }
                return true
            }
        }
        /// i bir '{' üstünde; her anahtar için `her` çağrılır (true dönerse değer çağıran tarafından okunmuştur)
        func nesne(_ her: (String) -> Bool) -> Bool {
            bosluk()
            guard i < b.count, b[i] == 0x7B else { return false }
            i += 1
            while true {
                bosluk()
                guard i < b.count else { return false }
                if b[i] == 0x7D { i += 1; return true }
                if b[i] == 0x2C { i += 1; continue }
                guard let ham = dizge(), let anahtar = coz(ham) else { return false }
                bosluk()
                guard i < b.count, b[i] == 0x3A else { return false }
                i += 1
                if !her(anahtar) { guard atla() else { return false } }
            }
        }

        var sonuc: [String] = []
        _ = nesne { anahtar in
            guard anahtar == alan else { return false }
            bosluk()
            guard i < b.count, b[i] == 0x7B else { return false }
            _ = nesne { k in sonuc.append(k); return false }
            return true
        }
        return sonuc
    }
}

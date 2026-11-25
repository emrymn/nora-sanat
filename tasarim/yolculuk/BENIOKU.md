# Yolculuk — Harita ve Durak Paneli Yeniden Tasarım Önerileri

Nora Sanat uygulamasının **Yolculuk** sekmesi (`NoraSanat/Ekranlar/Yolculuk/YolculukSekmesi.swift`, `YolculukPencereleri.swift`; site karşılığı `js/ekranlar/harita.js`, `js/harita.js`, `js/bolum.js`) için üç tasarım yönü. Uygulama koduna dokunulmamıştır.

Üç HTML dosyası da `390×844` iPhone genişliğinde, yerel yazı tipleriyle (`NoraSanat/YaziTipleri/`), dönem desen karolarıyla (`NoraSanat/Ekranlar/Galeri/Desenler/`) ve `gorseller/` altındaki **23 benzersiz kamu malı tablo** ile tamamen **internetsiz** çalışır; dış bağlantı ve görsel tekrarı yoktur.

Her yönde:
- **Gece / Gündüz** geçişi canlıdır (hem masaüstü önizleme çubuğundan hem telefon içindeki güneş/ay düğmesinden).
- **Hareketi azalt** (`prefers-reduced-motion: reduce` ve önizleme çubuğundaki *Tam hareket / Hareketi azalt* anahtarı) tüm nabız ve kaydırma geçişlerini sadeleştirir.
- Harita kaydırması, dönem göstergesi güncellemesi, durağa dokununca **durak paneli** açılışı, `"16 / 57 konu"` özetine dokununca **kurs paneli** açılışı ve tek dolu **`Turu başlat`** eylemi HTML içinde çalışır.

İki temada ilk ekran ve durak paneli açık hâlinin `@2x` PNG görüntüleri (`780×1688 px`, `deviceScaleFactor: 2`) [`goruntuler/`](goruntuler/) klasöründedir.

---

## Bugünkü ekranın sorunları ve çözüm yaklaşımı

Mevcut `YolculukSekmesi.swift` + `YolculukPencereleri.swift` incelendiğinde ve Emre’nin geçmiş geri bildirimleri değerlendirildiğinde dört somut sorun öne çıkıyor:

1. **Altta kalan boşluk:** Harita yüzen sekme çubuğunun üstünde kesiliyor, altta zemin renginde gereksiz bir şerit görünüyordu.
   - *Çözüm:* Üç yönde de kaydırma alanı sekme çubuğunun arkasına kadar kesintisiz iner; altta yalnızca son durağın sekme çubuğunun üstüne rahatça kayabilmesi için iç pay bırakılır.
2. **İlk açılış konumunun belirsizliği:** Haritanın açılışta nerede duracağı her zaman net değildi.
   - *Çözüm:* Üç yönde de harita açılır açılmaz **sıradaki durağı** (`Kuzey Rönesansı · 1. bölüm`) ekranın ortasına oturtur; böylece ilk karede geçmiş yıldızlı duraklar, sıradaki durak ve önümdeki kilitli duraklar bir arada görülür.
3. **Üst hap ve yanındaki madalyonun sıkışması:** `"16 / 57 konu"` iki satıra kırılıyor, `"Sıradaki: Konu 19"` kesiliyordu; sağdaki dönem kutusu da büyük harfli harf aralıklı etiketle kalabalık duruyordu.
   - *Çözüm:* Sıkışan yan madalyon kaldırıldı; her yönde nefes alan tek bir ilerleme özeti (`16 / 57 konu`) ve cümle düzeninde sakin dönem göstergesi kuruldu.
4. **Durak panelinde tema uyumu ve uzunluk (`hp2` ve `v0/sade-durak-paneli` değerlendirmesi):** Mevcut `hp2` paneli Gündüz temasında bile koyu kalıyor; 6+ sanatçılı duraklarda tanışma grupları + 3 seviye + Orta eserleri + Akım sayfası uzun bir duvar oluşturuyordu. `sanat-atlasi`’ndaki `v0/sade-durak-paneli` denemesinden **eser odaklı kapak başlığı**, **Gündüz’de açık yüzey uyumu** ve **aşamalı açılım (`<details>`)** fikirleri alındı; ancak v0’daki büyük harfli etiketler ve asimetrik düğme köşeleri `TASARIM_DILI.md` uyarınca elendi.

### Korunanlar ve `TASARIM_DILI.md` uyumu

- **Eksiksiz veri:** 9 dönem (*Orta Çağ* → *Modern sanat*), gerçek akım/dönem renkleri ve 41 gerçek bölüm (`bolumleriKur` çıktısıyla birebir). Örnek durum: `16 / 57 konu` işlendi (Rönesans), 9 açık bölüm / 22 yıldız, sıradaki durak `5-1 Kuzey Rönesansı · 1. bölüm` (1 yıldız, Kolay `%88`, Orta sırada).
- **Durak durumları:** Bitti + yıldızlar (`1–3 ★`), sıradaki durak vurgusu, kilitli duraklarda açık sebep (`"Konu 21’de açılır"`, `"Konu 24’te açılır"`…).
- **İlk ekranda `"konu"` kelimesi:** CI denetimiyle uyumlu olarak üç yönde de açılış ekranında `"16 / 57 konu"` görünürdür.
- **Üç katmanlı zemin ve yazı üçlüsü:** Kömür / sıcak kâğıt + `3×3 px` nokta dokusu + aktif dönemin renginden yumuşak hale + çok silik dönem deseni (Gece `%4`, Gündüz `%4,5`); başlıklarda **Bodoni Moda**, künyelerde **Newsreader**, arayüzde **Archivo**.
- **Yapma kuralları:** Büyük harfli harf aralıklı etiket, emoji, birden fazla dolu düğme ve `44 px` altı dokunma hedefi yok; `390 px` genişlikte yatay taşma yok (`scrollWidth = 390`).

---

## Yön 1 — Toparlanmış Harita · Kıvrılan Dönem Yolu (`yon-1.html`)

**Büyük fikir:** *Bugünkü alttan yukarıya kıvrılan yolculuk haritasının ruhunu koruyup bütün sıkışıklıkları, görsel gürültüyü ve Gündüz tema uyumsuzluklarını gideren en sakin evrim.*

- **Nasıl çalışır?**
  - Alttan (*Orta Çağ*) yukarıya (*Modern sanat*) kıvrılan kesintisiz SVG patikası: geçilen bölümler pirinç sürekli çizgiyle, gelecek kilitli bölümler kesikli çizgiyle bağlanır.
  - Her durak **yuvarlak eser madalyonu** olarak durur: çevresinde dönem renginde yıldız ilerleme yayı, altında yıldızlar ya da kilit pulu. Sıradaki durak (`Kuzey Rönesansı · 1. bölüm`) biraz daha büyük halka, sakin pirinç nefes ışığı ve yanındaki cam etiket kartıyla açılışta ekranı ortalar (`midY ≈ 405 px`).
  - Üstte sıkışmayan ferah kurs hapı (`16 / 57 konu · Sıradaki: Konu 19`) ve sağda tek tema düğmesi; bunların hemen altında çakışmayan sakin dönem rozeti (`Rönesans · XV–XVI. yüzyıl`) ve toplam bölüm/yıldız özeti (`9/41 · 22 ★`).
  - Sıradaki durak ekrandan çıkınca alt ortada cam `"Sıradaki durağa çık/in"` hapı belirir.
  - **Durak paneli:** Mevcut `hp2` yapısının toparlanmış hâli — yuvarlatılmış kapak tablosu + yumuşak atmosferik arka plan (Gündüz’de sıcak kâğıda uyumlu), tek dolu `"Turu başlat"` hapı (`Orta · 10 soru · ~3 dk`), gruplu kartlarda Tanışma grupları (*Dürer* ve *Weyden* pullarıyla), Kolay/Orta/Zor seviyeleri ve Akım sayfası.
- **En güçlü olduğu yer:** Bugünkü alışkanlığı hiç kırmadan haritayı çok daha okunaklı, tutarlı ve Gece/Gündüz uyumlu hâle getirmesi; SwiftUI’da mevcut `YolculukSekmesi` yapısına en az değişiklikle uygulanabilmesi.
- **Ödün:** 41 durağın tamamı kıvrımlı yol boyunca dizildiğinden uzak dönemlere gitmek için uzun dikey kaydırma gerekir.
- **Görüntüler:** [Gece](goruntuler/yon-1-gece.png) · [Gündüz](goruntuler/yon-1-gunduz.png) · Durak paneli: [Gece](goruntuler/yon-1-durak-gece.png) · [Gündüz](goruntuler/yon-1-durak-gunduz.png)

---

## Yön 2 — Müze İstasyonu · Yeniden Düşünülen Durak Paneli (`yon-2.html`)

**Büyük fikir:** *Haritayı sadeleştirip dönemler arası tek dokunuşla atlanabilir kılarken, asıl yeniliği durak panelinde yapan — tek ekrana sığan, aşamalı açılan sergi yaprağı.*

- **Harita tarafı:**
  - Üst cam başlıkta `Yolculuk`, yanında ferah `"16 / 57 konu"` hapı ve hemen altında `TASARIM_DILI.md` alt seçim kuralıyla **2 px pirinç alt çizgili dönem atlama şeridi** (*Orta Çağ · Rönesans · Barok · Klasisizm · …*). Herhangi bir döneme dokununca harita doğrudan oraya kayar.
  - Merkezde ince dönem renkli eksen çizgisi, iki yanında temiz galeri istasyonu kartları (`44×48` eser karesi, hareket adı + bölüm satırı hiç kesilmeden, yıldızlar ya da `"Konu N’de açılır"`). Sıradaki durak tam genişlik odak kartı olarak açılışta ortalanır (`midY ≈ 388 px`).
- **Yeniden düşünülen Durak Paneli (başrol):**
  - **Kenardan kenara eser sahnesi:** Kapak tablosu yaprağın tepesine tam genişlikte oturur ve alt kenarı yumuşakça doğrudan panel yüzeyine (`--surface`) erir; bulanık arka plan karmaşası olmadan hem Gece’de hem Gündüz’de tablo ön planda kalır. Eser künyesi tablonun yüzlerini kapatmadan başlığın hemen altında italik `Newsreader` satırıyla durur.
  - **3 Basamaklı Yatay Seviye Şeridi (`Kolay · Orta · Zor`):** Uzun dikey sınav listesi yerine 3 yan yana dokunulabilir kutu (`3 px` çizgi: geçen yeşil `%88 ✓`, sıradaki pirinç `10 soru`, kilitli soluk). Açık bir seviyeye dokunulduğunda seçili seviye ve altındaki süre notu anında güncellenir.
  - **Tek dolu `"Turu başlat"` hapı** + altında sakin tek satır süre fısıltısı (`Orta · 10 soru · ~3 dk`).
  - **Aşamalı açılım (`Sanatçılar ve tanışma`):** Varsayılan hâlde kapalı tek satır olarak durur (üst üste binen küçük sanatçı pulları + `"6 sanatçı · 2/2 grup tamam"`). Dokununca gruplar ve *Orta eserleri* yerinde açılır; altında `"Akım sayfası"` satırı yer alır. Böylece durak paneli ilk açılışta kaydırma gerektirmeden tek bakışta kavranır.
- **En güçlü olduğu yer:** Durak panelindeki yığılmayı tamamen ortadan kaldırması, dönemler arasında üst şeritle anında gezilebilmesi ve Gündüz temasında bile pırıl pırıl görünmesi.
- **Ödün:** Tanışma gruplarının sanatçı listesini görmek için bir ek dokunuş (açılır satır) gerekir.
- **Görüntüler:** [Gece](goruntuler/yon-2-gece.png) · [Gündüz](goruntuler/yon-2-gunduz.png) · Durak paneli: [Gece](goruntuler/yon-2-durak-gece.png) · [Gündüz](goruntuler/yon-2-durak-gunduz.png)

---

## Yön 3 — Zaman Atlası · Kronolojik Omurga ve Canlı Odak (`yon-3.html`)

**Büyük fikir:** *Çalış’ta çok beğenilen “Yön 4 · Bugünün oturumu”ndaki sol dikey kronolojik omurga, sakin süre fısıltısı ve tek kahraman kartı disiplinini Yolculuk’a taşıyan cesur ama sade sanat tarihi atlası.*

- **Nasıl çalışır?**
  - **Tek satırlık sakin üst çubuk:** Solda `"16 / 57 konu"` + aktif dönem adı (`Rönesans`) ve altında `3 px` ince kurs ilerleme çizgisi; sağda tek dokunuşla `"Sıradaki"` odak düğmesi ve tema düğmesi.
  - **Yukarıdan aşağıya kronolojik omurga:** Solda kesintisiz dönem renkli zaman çizgisi akar; her dönemin başında yüzyıl, Bodoni Moda dönem adı ve `3 px` dönem ilerleme çizgisi (`4/9 · 9 ★`) yer alır. Sağ kenardaki dokunmasız mini nokta dizisi (9 dönem) haritanın neresinde olunduğunu sessizce fısıldar.
  - **Üçlü görsel hiyerarşi (sıfır kalabalık):**
    1. *Tamamlanan duraklar:* Yeşil omurga düğümü + `44×44` eser karesi + bölüm adı + sağda 3 pirinç yıldız (tek satır, hızla taranır).
    2. *Sıradaki durak (`Kuzey Rönesansı · 1. bölüm`):* Haritanın **tek kahraman kartı** olarak açılışta ortada durur — geniş *Arnolfini Portresi* kapağı, yıldızlar, `"Orta · 10 soru · ~3 dk"` fısıltısı ve **haritadan tek dokunuşla** `"Turu başlat"` dolu düğmesi + cam `"Ayrıntılar"` düğmesi.
    3. *Önümdeki kilitli duraklar:* Soluk sepya eser kareleri ve `"Konu 21’de açılır"` / `"Konu 24’te açılır"` ufuk notlarıyla kesikli omurgada sıralanır.
  - **Durak paneli:** Herhangi bir durağa ya da `"Ayrıntılar"`a dokunulunca harita perdelenir ve durak paneli tek dolu `"Turu başlat"` düğmesi, tanışma grupları, seviyeler ve Akım sayfasıyla açılır.
- **En güçlü olduğu yer:** Çalış sekmesiyle kusursuz tasarım akrabalığı kurması; sıradaki durağı açar açmaz **tek dokunuşla** (panel bile açmadan) başlatabilme hızı ve 41 durağı en az görsel yorgunlukla tarama kolaylığı.
- **Ödün:** Mevcut alttan yukarıya kıvrılan oyun haritası metaforundan uzaklaşıp kronolojik dikey atlasa geçer.
- **Görüntüler:** [Gece](goruntuler/yon-3-gece.png) · [Gündüz](goruntuler/yon-3-gunduz.png) · Durak paneli: [Gece](goruntuler/yon-3-durak-gece.png) · [Gündüz](goruntuler/yon-3-durak-gunduz.png)

---

## Kısa karşılaştırma ve doğrulama

| Ölçüt | Yön 1 · Toparlanmış Harita | Yön 2 · Müze İstasyonu | Yön 3 · Zaman Atlası |
|---|---|---|---|
| **Akış yönü ve yapı** | Alttan yukarıya kıvrılan SVG patika | Alttan yukarıya merkez eksenli istasyonlar | Yukarıdan aşağıya sol kronolojik omurga |
| **Dönemler arası gezinme** | Kaydırma + üstte canlı dönem rozeti | Üstte alt çizgili dönem atlama şeridi | Kaydırma + üstte dönem adı + sağda sessiz pusula |
| **Sıradaki durağa başlama** | Durağa dokun → panelde `Turu başlat` | Odak karta dokun → panelde `Turu başlat` | Haritadaki kahraman kartta doğrudan `Turu başlat` |
| **Durak paneli** | Toparlanmış `hp2` (Gece/Gündüz uyumlu) | Kenardan kenara kapak + 3’lü seviye şeridi + açılır tanışma | Temiz yuvarlatılmış kapak + gruplu liste |
| **Açılışta sıradaki durak (`midY`)** | `405 px` (tam orta) | `388 px` (tam orta) | `305 px` (üst yarı-orta odak) |
| **Doğrulama (`390×844 @2x`)** | `scrollWidth=390`, `konu` görünür, `0` küçük hedef, dış adres yok | `scrollWidth=390`, `konu` görünür, `0` küçük hedef, dış adres yok | `scrollWidth=390`, `konu` görünür, `0` küçük hedef, dış adres yok |

---

## Kullanılan kamu malı eserler (`gorseller/`, 23 benzersiz tablo)

Tüm görseller Wikimedia Commons’tan `1280 px` (özgünü daha küçük olan 2 WGA/Giotto eseri özgün boyunda) olarak yerelleştirilmiştir; hiçbir durakta tekrar kullanılmaz:

1. `01-antik-yunan.jpg` — Pompei, İksion Odası freski (*Antik Yunan ve Roma*)
2. `02-romanesk.jpg` — Sant Climent de Taüll, *Pantokrator*, 1123 (*Romanesk*)
3. `03-gotik-1.jpg` — Giotto di Bondone, *İsa’ya Ağıt*, 1305 (*Gotik · 1. bölüm*)
4. `04-gotik-2.jpg` — Simone Martini, *Müjde*, 1333 (*Gotik · 2. bölüm*)
5. `05-gotik-3.jpg` — Gentile da Fabriano, *Müneccim Kralların Tapınması*, 1423 (*Gotik · 3. bölüm*)
6. `06-erken-ronesans-1.jpg` — Masaccio, *Vergi Parası*, 1425 (*Erken Rönesans · 1. bölüm*)
7. `07-erken-ronesans-2.jpg` — Piero della Francesca, *İsa’nın Vaftizi*, 1448 (*Erken Rönesans · 2. bölüm*)
8. `08-erken-ronesans-3.jpg` — Sandro Botticelli, *Venüs’ün Doğuşu*, 1485 (*Erken Rönesans · 3. bölüm*)
9. `09-kuzey-ronesans-1.jpg` — Jan van Eyck, *Arnolfini Portresi*, 1434 (*Kuzey Rönesansı · 1. bölüm — sıradaki durak*)
10. `10-kuzey-ronesans-2.jpg` — Pieter Bruegel (Yaşlı), *Karda Avcılar*, 1565 (*Kuzey Rönesansı · 2. bölüm*)
11. `11-yuksek-ronesans.jpg` — Raffaello, *Atina Okulu*, 1511 (*Yüksek Rönesans*)
12. `12-venedik-ronesans.jpg` — Titian, *Urbino Venüsü*, 1538 (*Venedik Rönesansı*)
13. `13-maniyerizm.jpg` — El Greco, *Toledo Manzarası*, 1599 (*Maniyerizm · 2. bölüm*)
14. `14-barok-italyan.jpg` — Caravaggio, *Aziz Matta’nın Çağrılışı*, 1600 (*İtalyan Barok · 2. bölüm*)
15. `15-hollanda-altin.jpg` — Johannes Vermeer, *Delft Manzarası*, 1660 (*Hollanda Altın Çağı*)
16. `16-fransiz-klasisizm.jpg` — Nicolas Poussin, *Arkadya’da Ben de Varım*, 1638 (*Fransız Klasisizmi*)
17. `17-rokoko.jpg` — Jean-Honoré Fragonard, *Salıncak*, 1767 (*Rokoko · 1. bölüm*)
18. `18-romantizm.jpg` — Caspar David Friedrich, *Sis Denizi Üzerinde Gezgin*, 1818 (*Romantizm · 1. bölüm*)
19. `19-empresyonizm.jpg` — Claude Monet, *İzlenim: Gün Doğumu*, 1872 (*Empresyonizm · 2. bölüm*)
20. `20-postempresyonizm.jpg` — Vincent van Gogh, *Yıldızlı Gece*, 1889 (*Post-Empresyonizm · 2. bölüm*)
21. `21-modern.jpg` — Franz Marc, *Büyük Mavi Atlar*, 1911 (*Ekspresyonizm / Modern sanat*)
22. `22-durer-grup.jpg` — Albrecht Dürer, *Otoportre*, 1500 (*Kuzey Rönesansı · 1. bölüm · 1. tanışma grubu*)
23. `23-weyden-grup.jpg` — Rogier van der Weyden, *Çarmıhtan İndiriliş*, 1435 (*Kuzey Rönesansı · 1. bölüm · 2. tanışma grubu*)

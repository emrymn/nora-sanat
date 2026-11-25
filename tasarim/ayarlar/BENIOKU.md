# Ayarlar — Yeniden Tasarım Önerileri

Nora Sanat uygulamasının **Ayarlar** ekranı (`NoraSanat/Ekranlar/Ben/BenAyarlari.swift`, `BenCevrimdisi.swift`, `BenAraclari.swift`, `NoraSanat/Settings.bundle`, `NoraSanat/Hatirlatici.swift`; site karşılığı `js/ekranlar/ayarlar.js` ve `js/yenilikler.js`) için iki ayrı tasarım yönü.

İki dosya da `390×844` iPhone genişliğinde, yerel yazı tipleriyle (`NoraSanat/YaziTipleri/`), dönem desen karolarıyla (`NoraSanat/Ekranlar/Galeri/Desenler/`) ve yerel kamu malı görsellerle (`gorseller/`) tamamen **internetsiz** çalışır; dış bağlantı içermez. Üst çubuktan ya da sayfa içindeki **Tema** denetiminden **Gece / Gündüz** geçişi canlıdır; tüm anahtarlar, parçalı seçiciler, 6 Gündüz paleti, yazı boyutu önizlemesi, saat seçici (`07:00–23:00`), indirme akışı, yedekleme/geri yükleme, Yenilikler ve kapalı Gelişmiş bölümü HTML içinde çalışır.

İki temada tam sayfa PNG görüntüleri (`deviceScaleFactor: 2`, `780 px` en) [`goruntuler/`](goruntuler/) klasöründedir.

---

## Bugünkü ekranın sorunları ve çözüm yaklaşımı

Bugünkü `BenAyarlari.swift` ekranı, sitedeki `.ayar` bloklarının art arda dizildiği uzun ve düz bir listedir:
- Görünüş, çalışma, çevrimdışı indirme, yedek ve geliştirici araçları arasında görsel grup ayrımı yoktur; aranan ayar gözle hızlıca taranamaz.
- **Tekrar hatırlatması** ve **saat** ayarı yalnız iPhone’un sistem Ayarlar uygulamasındadır (`NoraSanat/Settings.bundle`), uygulama içinden erişilemez.
- **Yenilikler** (`js/yenilikler.js`) sitede Ayarlar’ın altındadır ancak iOS uygulamasında eksiktir.
- **Yedeği geri yükle** her zaman `140 px` yüksekliğinde boş bir metin kutusu açarak sayfayı gereksiz uzatır; geliştirici araçları (geliştirici modu, bildirdiğim görseller, elle odaklar, ana ekranın resimleri) günlük ayarlarla aynı düzeyde görünür.
- **Tema, Gündüz rengi ve Yazı boyutu** değişince sonucu görmek için başka bir ekrana geçmek gerekir.

**Ortak çözüm ilkeleri (`TASARIM_DILI.md` uyumlu):**
- **Apple Ayarlar kadar kolay tarama, Sanat Atlası’nın tasarım diliyle:** 7 mantıklı grup, gruplu kartlar (`--surface`, `24 px` köşe, aralarında ince çizgi), cümle düzeninde `13 px` pirinç bölüm başlıkları (büyük harfli, harf aralıklı etiket yok; bölüm numarası ve emoji yok).
- **Canlı önizleme kartı:** En üstte gerçek bir başyapıt ve `Newsreader` okuma metni içeren küçük bir örnek kart yer alır. Tema (`Gece`/`Gündüz`), Gündüz rengi (`Günün resmi`, `Lapis`, `Pompei`, `Bakır yeşili`, `Safran`, `Nötr kâğıt`), Yazı boyutu (`Standart`/`Büyük`), Hareket ve Eğim değiştikçe kart ve sayfa anında güncellenir.
- **Kısa açıklamalar, sıfır kalabalık:** Her ayarın tek satırlık sade bir açıklaması vardır; seyrek kullanılan büyük alanlar (saat seçici, yedek yapıştırma alanı, Yenilikler, Gelişmiş araçlar) dokununca açılır.
- **Tek dolu düğme kuralı:** İki yönde de tüm ekranda en çok **1 dolu hap düğme** bulunur; öteki eylemler cam/yüzey hap düğmeleri veya satır içi ok/değer biçimindedir.
- **Üç katmanlı zemin:** Kömür `#121110` / sıcak kâğıt (veya seçili Gündüz pigment paleti) + `3×3 px` nokta dokusu + hafif hale + çok silik dönem deseni (Gece `%4`, Gündüz `%4,5`).
- **Erişilebilirlik ve ölçü:** Tüm etkileşimli hedefler en az `44 px`, `390 px` genişlikte sıfır yatay taşma (`scrollWidth = 390`).

---

## Hangi ayar nereye kondu? (Eksiksiz harita)

| Grup | Ayar | Bugünkü kaynak | Yeni durum ve not |
|---|---|---|---|
| **Görünüş** | **Canlı önizleme kartı** | *(Yeni)* | Tema, 6 Gündüz paleti, Standart/Büyük yazı boyutu, Hareket ve Eğim değişimini anında gösterir. |
| **Görünüş** | Tema (`Gece` / `Gündüz`) | `BenAyarlari.swift` | En sık kullanılan ayar olarak grubun başında. |
| **Görünüş** | Gündüz rengi (`6 palet`) | `BenAyarlari.swift` / `gunduzRenk.js` | Bir palet seçilince tema doğrudan Gündüz’e geçer (mevcut kural korunur). |
| **Görünüş** | Yazı boyutu (`Standart` / `Büyük`) | `BenAyarlari.swift` | Değişince önizleme kartındaki `Newsreader` metni ve açıklamalar anında büyür. |
| **Görünüş** | Hareket (`Tam` / `Sade` / `Kapalı`) | `BenAyarlari.swift` | Uzun tek paragraf yerine seçime göre sade açıklama. |
| **Görünüş** | Telefonu eğince tablo oynasın | `BenAyarlari.swift` | Görsel hareket grubunda toplandı; önizleme kartına bağlı. |
| **Çalışma** | Günlük kart sayısı (`5–100`, `±5`) | `BenAyarlari.swift` | Sağda `44×44` `−` / `+` ve `Bodoni Moda` sayı. |
| **Çalışma** | Yeni sanatçıyla önce tanış | `BenAyarlari.swift` | Kısa açıklama + anahtar. |
| **Çalışma** | Titreşim + `Titreşimi dene` | `BenAyarlari.swift` | Çalışma sırasındaki cevap geri bildirimi; kapalıyken `Dene` gizlenir. |
| **Çalışma** | Günün sanatçısı (`Başka getir`) | `BenAraclari.swift` | Bugünün sanatçısı adı ve tek dokunuşla değiştirme satırı. |
| **Hatırlatma** | **Tekrar hatırlatması** (aç/kapa) | `Settings.bundle` + `Hatirlatici.swift` | **Uygulama içine taşındı** (`hatirlatma` anahtarı; varsayılan açık). |
| **Hatırlatma** | **Hatırlatma saati** (`07:00–23:00`) | `Settings.bundle` + `Hatirlatici.swift` | **Uygulama içi saat seçici** (`hatirlatmaSaati`; varsayılan `20:00`). Hatırlatma kapalıysa pasifleşir. |
| **Hatırlatma** | Simge rozeti | `BenAyarlari.swift` + `Hatirlatici.swift` | Bildirim/rozet ailesi tek grupta birleşti. |
| **Görseller ve çevrimdışı** | En büyük kopyalar | `BenCevrimdisi.swift` | Durum yüzdesi, `3 px` ince ilerleme çizgisi (süren pirinç, biten yeşil), kapladığı yer / toplam GB ve `İndir` / `Durdur` / `Telefondan sil`. |
| **Yedek** | Yedekle + Son yedek | `BenAyarlari.swift` | Son yedek tarihi hemen görünür; `Panoya yedekle` sonrası `JSON kaydet` açılır. |
| **Yedek** | Yedeği geri yükle | `BenAyarlari.swift` | Başlangıçta kapalı satır; dokununca metin kutusu, `Dosyadan seç` ve `Geri yükle` açılır. |
| **Hakkında** | **Yenilikler** (sürüm notları) | `ayarlar.js` + `yenilikler.js` | **Uygulama içine eklendi**; `1.90.3` ve önceki sürümlerin gerçek notları. |
| **Hakkında** | Sürüm + `Denetle` | `BenAraclari.swift` | Sürüm numarası (`1.90.3`) ve veri güncelleme denetimi. |
| **Hakkında** | Kaynaklar | `BenAyarlari.swift` alt notu | Wikimedia Commons, açık erişim müzeler, WikiArt ve Wikidata bilgisi düzenli satırda. |
| **Gelişmiş** *(kapalı)* | Geliştirici modu | `BenAyarlari.swift` | Günlük kullanımı kalabalıklaştırmamak için kapalı bölüm içinde. |
| **Gelişmiş** *(kapalı)* | Bildirdiğim görseller | `BenAraclari.swift` | Kayıt listesi, `JSON kopyala` ve `Temizle`. |
| **Gelişmiş** *(kapalı)* | Hata günlüğü | `ayarlar.js` | Kayıt sayısı, `Kopyala` ve `Temizle`. |
| **Gelişmiş** *(kapalı)* | Elle odaklar | `BenAraclari.swift` | İşaretlenen tablo sayısı, `Kopyala` ve `Bu cihazdakileri sil`. |
| **Gelişmiş** *(kapalı)* | Ana ekranın resimleri | `BenAraclari.swift` | `145` yürüyüş eseri ve `Sırayla ortala`. |

---

## Yön 1 — Canlı Önizleme ve Gruplu Kartlar (`yon-1.html`)

**Büyük fikir:** *Sık değiştirilen görünüş ayarları doğrudan elin altında; üstte editoryal bir başyapıt kartı her değişikliği anında yansıtır.*

- **Üst çerçeve:** Solda cam `< Ben` düğmesi, büyük `Bodoni Moda` `Ayarlar` başlığı; sayfa aşağı kaydırılınca üstte ortada `Ayarlar` yazan buzlu cam çubuk belirir (`TASARIM_DILI.md` cam çubuk kuralı).
- **Ayrı editoryal önizleme kartı:** *Johannes Vermeer · İnci Küpeli Kız* (`1665`) ve altında `Newsreader` okuma metni. Tema, 6 Gündüz rengi, Yazı boyutu ve Hareket/Eğim değişince anında güncellenir.
- **Doğrudan görünür Görünüş denetimleri:** Tema (`Gece`/`Gündüz`), Gündüz rengi (`2×3` pigment pulu ızgarası — hiçbir etiket kırpılmaz), Yazı boyutu (`Standart`/`Büyük`) ve Hareket (`Tam`/`Sade`/`Kapalı`) ek dokunuş istemeden açık durur.
- **Tek dolu düğme:** **Görseller ve çevrimdışı** bölümündeki `İndirmeyi sürdür` (`İndir`) düğmesi ekranın tek dolu hap düğmesidir; öteki eylemler cam düğme ve açılır satırlardır.
- **Yenilikler:** Hakkında kartı içinde yerinde açılan sürüm notları listesi.
- **En güçlü olduğu yer:** En az dokunuşla (0 açılır menüyle) Tema, Gündüz paleti, Yazı boyutu ve Hareket değiştirmeyi sağlaması; yüksek okunaklılık ve sakin editoryal görünüm.
- **Ödün:** Tüm Görünüş seçicileri açık olduğu için sayfa Yön 2’ye göre biraz daha uzundur (`2933 px`).
- **Görüntüler:** [Gece](goruntuler/yon-1-gece.png) · [Gündüz](goruntuler/yon-1-gunduz.png)

---

## Yön 2 — Kompakt Fihrist ve Yapışkan Bölüm Şeridi (`yon-2.html`)

**Büyük fikir:** *Apple Ayarlar’ın hızlı taranan simgeli ve değer özetli satır disiplini; üstte alt çizgili bölüm şeridiyle tek dokunuşta atlama.*

- **Yapışkan alt çizgili bölüm şeridi:** `Görünüş · Çalışma · Hatırlatma · Çevrimdışı · Yedek · Hakkında` sekmeleri (`TASARIM_DILI.md` alt seçimler: seçili olanın altında `2 px` pirinç çizgi) kaydırırken üstte kalır; uzun sayfada aranan gruba tek dokunuşla atlanır.
- **Kart içi gömülü önizleme:** *Jan van Eyck · Arnolfini Portresi* (`1434`) Apple’ın *Ekran ve Parlaklık* ayarındaki gibi doğrudan **Görünüş** kartının üst bölmesine oturur.
- **Simgeli kompakt satırlar ve yerinde açılan çekmeceler:** Her satırın solunda Sanat Atlası çizgi dilinde (`1.6 px` kontur) nötr küçük bir simge, sağında ise anlık değer (`Günün resmi ⌄`, `Tam ⌄`, `20:00 ⌄`, `1.90.3 ›`) durur. Tema ve Yazı boyutu tek satır içinde hemen değişir; Gündüz rengi ve Hareket ise yalnızca dokununca satır altında açılır. Böylece ilk ekran çok daha kompakt ve taranabilirdir (`2242 px` — Yön 1’den `~690 px` daha kısa).
- **Kart altı dipnotlar:** Hatırlatma ve Çevrimdışı gruplarında uzun açıklamalar satırları şişirmek yerine Apple Ayarlar’daki gibi kartın altında tek satırlık sakin dipnot olarak durur.
- **Tek dolu düğme:** **Yedek** bölümündeki `İlerlemeni yedekle` düğmesi ekranın tek dolu hap düğmesidir.
- **Yenilikler:** Dokununca alttan yükselen iOS tarzı **alt yaprak (sheet)** içinde tam sürüm notları açılır.
- **En güçlü olduğu yer:** Tek bakışta tüm grupları tarama hızı, daha kısa sayfa boyu ve bölüm şeridiyle doğrudan erişim.
- **Ödün:** Gündüz rengi ve Hareket seçeneklerini görmek için bir ek dokunuş gerekir.
- **Görüntüler:** [Gece](goruntuler/yon-2-gece.png) · [Gündüz](goruntuler/yon-2-gunduz.png)

---

## Kısa karşılaştırma ve doğrulama

| Ölçüt | Yön 1 · Canlı Önizleme ve Gruplu Kartlar | Yön 2 · Kompakt Fihrist ve Bölüm Şeridi |
|---|---|---|
| **Önizleme yerleşimi** | Ayrı editoryal kart (*İnci Küpeli Kız*) | Görünüş kartı içinde gömülü (*Arnolfini Portresi*) |
| **Görünüş denetimleri** | Hepsi doğrudan açık (`0` ek dokunuş) | Tema ve Yazı satır içi; Renk ve Hareket açılır |
| **Gezinme** | Kaydırınca beliren cam üst çubuk | Yapışkan alt çizgili bölüm atlama şeridi |
| **Satır stili** | Saf tipografik gruplu satırlar | İnce çizgi simgeli, sağda değer özetli satırlar |
| **Yenilikler görünümü** | Kart içinde açılır liste | Alttan yükselen yaprak (sheet) |
| **Tek dolu düğme** | `İndirmeyi sürdür` (Görseller ve çevrimdışı) | `İlerlemeni yedekle` (Yedek) |
| **Tam sayfa boyu (`390 px`)** | `2933 px` | `2242 px` |
| **Doğrulama (`@2x` PNG)** | `scrollWidth=390`, `0` küçük hedef (`≥44 px`), `1` dolu düğme, 3 yerel yazı tipi | `scrollWidth=390`, `0` küçük hedef (`≥44 px`), `1` dolu düğme, 3 yerel yazı tipi |

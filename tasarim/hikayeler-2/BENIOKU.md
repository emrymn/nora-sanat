# Hikâyeler Sekmesi — Üç Yeni Tasarım Yönü (2. Tur)

Nora Sanat’ın **Hikâyeler** sekmesi için, ilk turdaki (`neon/hikayeler-tasarim`, PR #73) kart listesi, dönem çipleri ve “Kaldığın yerden devam” kalıbının bütünüyle dışına çıkan üç özgün yön. **Uygulama koduna dokunulmamıştır.**

Bu turun iki temel tasarım ilkesi:
1. **Kategorisiz gezinme:** Akım, dönem veya yüzyıl sekmeleri; `"Tümü · Barok · Altın Çağ"` çipleri; filtre düğmeleri ve gruplu raflar **yoktur**. 55 sanatçı (Giotto’dan Gauguin/Munch’a kronolojik evren) tek bir kesintisiz yüzeyde yaşar.
2. **Kart listesi + “Kaldığın yerden devam” kalıbının dışına çıkmak:** Üç yön, 55 hikâye içinde kaybolmadan gezinme ve dinlenen/yarım kalan hikâyeyi organik olarak hissettirme sorununu üç bambaşka mekânsal fikirle çözer.

Her üç prototip de (`yon-1.html`, `yon-2.html`, `yon-3.html`) `390×844` iPhone ölçüsünde, uygulamanın yerel yazı tipleriyle (`Bodoni Moda`, `Newsreader`, `Archivo`), dönem desen karolarıyla (`NoraSanat/Ekranlar/Galeri/Desenler/`), `sanat-atlasi` deposundaki gerçek `data/sanatci_hikayeleri.json` metinleriyle (13 hazır hikâyenin tamamı, 5–7 bölüm, kırpılmamış eserler ve “Bu dönemle bağı” cümleleri, gerçek sanatçı bağlantıları) ve Wikimedia Commons kamu malı görselleriyle (`gorseller/`, 55/55 sanatçı kapağı + bölüm eserleri) tamamen **çevrimdışı** çalışır.

Tüm `390×844` (`deviceScaleFactor: 2`, `780×1688 px`) Gece ve Gündüz çıktıları [`goruntuler/`](goruntuler/) klasöründedir (30 PNG, tümünde `scrollWidth = 390`, sıfır kırık görsel, ekran başına en çok 1 dolu düğme, tüm dokunma hedefleri `≥ 44 px`).

---

## Ortak Tasarım Dili ve Kurallar

- **Üç katmanlı zemin (`TASARIM_DILI.md`):** Kömür `#121110` (Gece) / sıcak kâğıt `#ece8e1` (Gündüz) + `3×3 px` nokta dokusu + aktif sanatçının tablosundan sabit hale (`--hale-rgb`) + çok silik dönem deseni (Gece `%4`, Gündüz `%4,5`).
- **Tipografi üçlüsü:** Başlıklarda **Bodoni Moda** (500, `−0,015 em`), okuma metni ve Fola kelime-kelime altyazısında **Newsreader**, arayüz ve cümle düzeni pirinç üst yazılarda **Archivo**.
- **“Yapma” kuralları:** Bölüm numarası (`"BÖLÜM 2 / 7"`), büyük harfli harf aralıklı etiket, sol kenarlı renkli kutu, emoji ve aynı ekranda birden çok dolu düğme yoktur.
- **Kırpılmamış eserler:** Okuma ekranında tüm eserler doğal en-boy oranında (`width: 100%; height: auto`), sıfır kırpmayla metnin tam anlattığı yerde açılır; hemen altında künye ve **“Bu dönemle bağı”** yer alır.
- **Fola kelime-kelime zamanlama:** Her üç yönde de dinleme ekranı gerçek paragraflardan üretilmiş kelime zamanlamasıyla canlı oynar (`±15 sn`, bölüm atlama, `0,85× / 1× / 1,25× / 1,5×` hız, `Oku` ve `Bağlantılar` geçişleri).

---

## Sekme Çubuğu Önerisi

Uygulamada bugün 5 sekme var: **Bugün · Çalış · Galeri · Yolculuk · Ben**. Hikâyeler birinci sınıf sekme olarak eklendiğinde `390 px` genişlikte oluşacak üç gerçek seçeneği üç yöne dağıtıp doğrudan ölçülebilir kıldık:

| Yön | Sekme Çubuğu Düzeni | Yuvaya Düşen Genişlik | Değerlendirme |
|---|---|---|---|
| **Yön 1 · Takımyıldız** *(Önerilen)* | **5 sekme altta** (`Bugün · Hikâyeler · Çalış · Galeri · Yolculuk`) + **`Ben` sağ üst cam düğme** | `~70 px` (en ferah) | `Ben` zaten kişisel profil/ayar alanı olduğu için üst sağ köşede cam profil dairesine taşınır. Altta 5 içerik sekmesi Apple HIG ideal yoğunluğunda, 10,5–11 px rahat etiketlerle nefes alır. |
| **Yön 2 · Zaman Nehri** | **`5 + 1` ayrık cam kapsül** (`Bugün · Hikâyeler · Çalış · Galeri · Yolculuk` ana kapsülde + sağda ayrı yuvarlak cam `Ben`) | `~57 px` + `62 px` ayrık | `Ben` başparmak erişiminden kopmaz; `8 px` aralıkla 5 sanat/öğrenme sekmesinden zihinsel olarak ayrılır. Yüzen cam dilini bozmadan 6 hedefi taşır. |
| **Yön 3 · Portre Duvarı** | **6 sekme tek cam çubukta** (`Bugün · Hikâyeler · Çalış · Galeri · Yolculuk · Ben`) | `~58 px` × 6 | Mevcut sekmelerin yeri hiç değişmez; ancak `9,5 px` etiket yoğunluğunu `390 px` ekranda gerçek hâliyle görüp kıyaslamak için doğrudan kuruldu. |

**Öneri:** Günlük kullanım rahatlığı ve görsel ferahlık açısından **Yön 1 (5 sekme + sağ üstte `Ben`)** en temiz çözümdür. `Ben` mutlaka alt çubukta kalsın istenirse **Yön 2 (`5 + 1` ayrık cam)**, 6’lı tek çubuğa göre çok daha okunaklı bir ayrım verir.

---

## Yön 1 — Takımyıldız (`yon-1.html`)

**Fikir:** *Sanatçılar kategorilere ayrılmış kartlar değil, birbirine gerçek etki bağlarıyla dokunan tek bir canlı gökyüzü.* 55 sanatçı (13 hazır hikâye parlak tablo madalyonlarıyla, yaklaşan 42 sanatçı ince yıldız noktalarıyla) aralarında 90 gerçek hoca–öğrenci–rakip–etki yayıyla organik bir uzayda yer alır.

### 55 hikâye nasıl bulunur, yarım kalan nasıl görünür?
- **Kaldığın yerden devam kutusu yok:** Yarım kalan hikâyeler (ör. Rembrandt van Rijn `%58`, Goya `%42`, Van Gogh `%24`) kendi yıldızlarının çevresinde **pirinç SVG ilerleme yayı** taşır ve açılışta kamera doğrudan son dinlediğin yıldızı (Rembrandt) merkeze alır. Biten hikâyeler (Caravaggio, Bosch, Leonardo) ince zümrüt yeşili halkayla parlar.
- **Kaybolmadan gezinme:** Parmağı sürükleyerek serbest gezinme, `+ / − / 55` cam düğmeleriyle tüm 55 sanatçıyı tek bakışta görme veya yakınlaşma, seçili yıldızın parlayan pirinç yaylarından doğrudan komşu sanatçıya atlama ve sağ üstteki cam **Ara** düğmesiyle 55 sanatçı içinde anında yıldızı merkeze uçurma.

### Ekranlar
1. **Ana ekran** ([Gece](goruntuler/yon-1-ana-gece.png) · [Gündüz](goruntuler/yon-1-ana-gunduz.png)): Etkileşimli 55 sanatçılık takımyıldız, seçili yıldızın (Rembrandt) pirinç yaylı odağı, alt cam mercek yaprağında tek dolu `Dinlemeyi sürdür` + `Oku` + `Bağlantılar`, altta 5 ferah sekme + sağ üstte `Ben`.
2. **Okuma** ([Gece](goruntuler/yon-1-okuma-gece.png) · [Gündüz](goruntuler/yon-1-okuma-gunduz.png)): Kırpılmamış eser levhaları ve `Bu dönemle bağı` notlarıyla kesintisiz okuma; sağ kenarda dokunmatik **yıldız izi** (bölüm konum noktaları), altta yüzen tek dolu `Fola ile dinle` hapı.
3. **Dinleme** ([Gece](goruntuler/yon-1-dinleme-gece.png) · [Gündüz](goruntuler/yon-1-dinleme-gunduz.png)): Aktif bölümün eseri tüm `390×844` ekranı kaplar; üstte numarasız ince bölüm çizgileri, alt-ortada kelime-kelime vurgulanan Fola altyazısı ve tek satır cam denetim kapsülü.
4. **Bağlantılar** ([Gece](goruntuler/yon-1-baglantilar-gece.png) · [Gündüz](goruntuler/yon-1-baglantilar-gunduz.png)): Merkezde okunan sanatçı, çevresinde gerçek bağlantıları; bir uyduya dokununca pirinç yay yanar, altta gerçek ilişki metni açılır ve hikâyesi hazırsa tek dolu düğmeyle (ör. `Francisco de Goya hikâyesine geç ›`) doğrudan geçilir.
5. **Başka sekmede küçük çalar** ([Gece](goruntuler/yon-1-mini-gece.png) · [Gündüz](goruntuler/yon-1-mini-gunduz.png)): `Galeri` sekmesinde alt 5’li çubuğun üstünde yüzen cam çalar (kapak, aktif cümle vurgusu, oynat/duraklat, kapat).

### Etkileşimler ve Titreşim
- **Kaydırma & Yakınlaşma:** İki parmakla kıstırma (`MagnificationGesture`) ve sürükleme (`DragGesture`); `55` düğmesi tüm ağı `0,34×` geniş bakışa çekip yeniden dokununca odak yıldıza yumuşakça (`timingCurve(0.22, 1, 0.36, 1)`) uçar.
- **Titreşim (`Titresim.swift`):** Ağda bir yıldıza dokununca ve bağlantılarda uydu değiştirirken `Titresim.secim()`; `55` geniş bakışa geçerken veya bölüm atlarken `Titresim.dokunus()`; hikâye bitince `Titresim.dogru()`.

---

## Yön 2 — Zaman Nehri (`yon-2.html`)

**Fikir:** *Akım kutuları ve yüzyıl çipleri olmadan, 1267’den 1944’e akan tek bir kesintisiz zaman nehri.* Kart listesi yerine, sol kenarda akan ince bir zaman omurgası boyunca sıralanan 55 sanatçı durağı; odaktaki sanatçı kart çerçevesine sıkışmadan nehrin kıyısında kendiliğinden genişler.

### 55 hikâye nasıl bulunur, yarım kalan nasıl görünür?
- **Kaldığın yerden devam kutusu yok:** Nehir açıldığında doğrudan **son dinlediğin sanatçının kıvrımında** (ör. Francisco de Goya, `1746–1828`, `%42`, `10 dk kaldı`) genişlemiş olarak açılır; nehir damlası o noktada sıcak pirinç halkayla parlar ve tek dolu `Dinlemeyi sürdür` düğmesi doğrudan nehrin içindedir.
- **Kaybolmadan gezinme:** Sağ kenardaki dokunmatik **yıl sıyırıcısı** (`1300 · 1450 · 1600 · 1750 · 1880`) boyunca parmağı kaydırınca yüzen bir yıl kabarcığı (`1606 · Rembrandt`) açılır ve 55 sanatçı arasında tek harekette süzülürsün. Sağ üstteki cam **Ara** düğmesi ad veya yılla doğrudan durağa atlatır.

### Ekranlar
1. **Ana ekran** ([Gece](goruntuler/yon-2-ana-gece.png) · [Gündüz](goruntuler/yon-2-ana-gunduz.png)): Kesintisiz 55 sanatçılık zaman nehri, ortada genişlemiş Goya kıvrımı, sağ kenarda dokunmatik yıl sıyırıcısı, altta **`5 + 1` ayrık cam sekme çubuğu**.
2. **Okuma** ([Gece](goruntuler/yon-2-okuma-gece.png) · [Gündüz](goruntuler/yon-2-okuma-gunduz.png)): Sol kenarda sanatçının kendi ömür çizgisi akarken, kırpılmamış eserler kenardan kenara tam enli açılır; alt kenarda sabit **Fola eşlik şeridi** (okurken tek dokunuşla `Dinle`).
3. **Dinleme** ([Gece](goruntuler/yon-2-dinleme-gece.png) · [Gündüz](goruntuler/yon-2-dinleme-gunduz.png)): Tam ekran tablo üstünde sanatçının dönem yıllarından oluşan yatay zaman durakları, büyük kelime-kelime Fola altyazısı ve yuvarlak cam denetimler.
4. **Bağlantılar** ([Gece](goruntuler/yon-2-baglantilar-gece.png) · [Gündüz](goruntuler/yon-2-baglantilar-gunduz.png)): *“Nehirden ayrılan kollar”* — üstte `Yukarı akış · Ondan beslendi` (Velázquez, Rembrandt…), merkezde sanatçının kendi havuzu, altta `Aşağı akış · Ondan doğdu`; hazır hikâyeye tek dokunuşla geçiş.
5. **Başka sekmede küçük çalar** ([Gece](goruntuler/yon-2-mini-gece.png) · [Gündüz](goruntuler/yon-2-mini-gunduz.png)): `Bugün` tam ekran tablosunun ve `5 + 1` ayrık sekme çubuğunun üstünde yüzen cam çalar (`−15 sn` + oynat/duraklat).

### Etkileşimler ve Titreşim
- **Kaydırma & Yıl Sıyırıcısı:** Sağ kenardaki yıl sıyırıcısı `DragGesture` ile her sanatçıdan geçerken yüzen kabarcığı günceller; bir durağa dokununca önceki kıvrım yumuşakça kapanıp seçilen kıvrım genişler ve zemin haleyi kendi tablo rengine boyar.
- **Titreşim (`Titresim.swift`):** Yıl sıyırıcısında yeni yüzyıl/hazır sanatçı geçerken ince `Titresim.secim()`; nehir kıvrımı açılırken ve `±15 sn` dokunuşunda `Titresim.dokunus()`; hikâye bitince `Titresim.dogru()`.

---

## Yön 3 — Bugünün Kapısı & Portre Duvarı (`yon-3.html`)

**Fikir:** *Her gün tek bir sanatçının açtığı kapı ve hemen altında 55 yüzün tamamını tek bakışta sunan çerçevesiz bir portre duvarı.* Kategori yok, raf yok, liste kartı yok — yalnızca resimler ve bir yüzden ötekine geçiş.

### 55 hikâye nasıl bulunur, yarım kalan nasıl görünür?
- **Bugünün hikâyesi:** Ekranın üst yarısında her gün tek bir sanatçı kapıyı kenardan kenara açar (ör. **Johannes Vermeer**, *Gürültülü Bir Evde Kurulan Sessizlik*). Sağ üstteki `‹ / ›` oklarıyla doğrudan bir yüzden ötekine geçilir.
- **55 yüz, tek duvar:** Hemen altında 5 sütun × 11 satırlık kesintisiz portre duvarı 55 sanatçının tamamını tek yüzeyde toplar. Hazır 13 hikâye tam canlı renkte parlar, yaklaşan 42 yüz düşük doygunluklu gravür tonundadır. Yarım kalan hikâyelerin (Rembrandt, Goya, Van Gogh) portresinin alt kenarında `3 px` pirinç çizgi ve köşesinde pirinç nokta, bitenlerin köşesinde zümrüt nokta yanar.
- **Kaybolmadan gezinme:** 11 satırlık duvar iki kaydırmada tüm 55 yüzü gösterir; herhangi bir yüze dokununca üst kapı o sanatçıya dönüşür. Sağ üstteki cam **Ara** düğmesi 55 yüz içinde ad veya yılla anlık bulur.

### Ekranlar
1. **Ana ekran** ([Gece](goruntuler/yon-3-ana-gece.png) · [Gündüz](goruntuler/yon-3-ana-gunduz.png)): Üstte tam enli Bugünün Kapısı (Vermeer, tek dolu `Fola ile dinle` + `Oku` + bağlantılar), altında 55 sanatçılık çerçevesiz portre duvarı, altta **6 sekmeli tek cam çubuk**.
2. **Okuma** ([Gece](goruntuler/yon-3-okuma-gece.png) · [Gündüz](goruntuler/yon-3-okuma-gunduz.png)): Paspartulu kapak ve sergi kataloğu sakinliği; üstte ince okuma çizgisi, metin içinde kırpılmamış eserler ve `Bu dönemle bağı`, sağ altta yüzen tek dolu `Fola ile dinle`.
3. **Dinleme** ([Gece](goruntuler/yon-3-dinleme-gece.png) · [Gündüz](goruntuler/yon-3-dinleme-gunduz.png)): Tam ekran tablo üstünde büyük kelime-kelime altyazı; boş alana tek dokunuşla denetimlerin gizlendiği sade sinema kipi.
4. **Bağlantılar** ([Gece](goruntuler/yon-3-baglantilar-gece.png) · [Gündüz](goruntuler/yon-3-baglantilar-gunduz.png)): *“Yüzden yüze geçiş”* — üst yarıda bağlı sanatçının tam enli portresi (ör. Vermeer → Vincent van Gogh), ortada gerçek ilişki hikâyesi, altta yatay yüz şeridi ve tek dolu geçiş düğmesi.
5. **Başka sekmede küçük çalar** ([Gece](goruntuler/yon-3-mini-gece.png) · [Gündüz](goruntuler/yon-3-mini-gunduz.png)): `Yolculuk` sekmesinin ve 6 sekmeli çubuğun üstünde yüzen cam çalar.

### Etkileşimler ve Titreşim
- **Yüzden Yüze Geçiş:** Duvar karosuna dokununca o yüz `matchedGeometryEffect` ile üst kapıya genişler; dinleme sahnesinde boş alana tek dokunuş denetimleri gizleyip yalnız tablo + kelime-kelime altyazıyı bırakır.
- **Titreşim (`Titresim.swift`):** Portre duvarında yüz seçerken ve kapı oklarıyla yüz değiştirirken `Titresim.secim()`; dinlemede sade kipe geçerken hafif `Titresim.dokunus()`; hikâye bitince `Titresim.dogru()`.

---

## Hangi Yön Ne Zaman Seçilmeli?

- **Sanatçılar arasındaki bağları uygulamanın kalbine koymak ve 55 kişilik bir evrende keşif duygusu yaratmak** için → **Yön 1 · Takımyıldız** *(ve 5 sekme + sağ üstte `Ben` çubuğu)*.
- **Giotto’dan Gauguin’e tarihsel sürekliliği kategorisiz tek akışta hissetmek ve yıl sıyırıcısıyla 55 sanatçı arasında sıfır sürtünmeyle dolaşmak** için → **Yön 2 · Zaman Nehri** *(ve `5 + 1` ayrık cam çubuk)*.
- **Her gün tek bir hikâyenin davet ettiği sakin bir ritim + 55 yüzün tamamını görsel hafızayla bir bakışta taramak** için → **Yön 3 · Bugünün Kapısı & Portre Duvarı**.

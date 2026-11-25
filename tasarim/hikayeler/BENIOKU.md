# Hikâyeler Sekmesi — Üç Tasarım Yönü

Nora Sanat için yeni **“Hikâyeler”** sekmesinin (uzun, araştırmalı sanatçı yaşamöyküleri + Fola doğal sesli kelime-kelime anlatım + kırpılmamış eserler + sanatçı bağlantıları + kaynaklar) üç ayrı tasarım önerisi. **Uygulama koduna dokunulmamıştır.**

Her üç dosya da (`yon-1.html`, `yon-2.html`, `yon-3.html`) `390×844` iPhone ölçüsünde, yerel yazı tipleriyle (`NoraSanat/YaziTipleri/`), Barok dönem desen karosuyla (`NoraSanat/Ekranlar/Galeri/Desenler/desen-barok@3x.png`), Wikimedia Commons’tan alınmış yerel eser görselleriyle (`gorseller/`) ve ortak veri + Fola zamanlama motoruyla (`hikaye-verisi.js`) tamamen **internetsiz** çalışır.

Her HTML dosyası tarayıcıda açıldığında üst vitrin çubuğundan **Ana ekran · Okuma · Dinleme · Bağlantılar · Küçük çalar**, **Caravaggio · Artemisia Gentileschi** ve **Gece · Gündüz** canlı olarak değiştirilebilir; Fola çaları gerçek zamanlı kelime vurgusu, `±15 sn`, bölüm atlama ve hız (`0,85× / 1× / 1,25× / 1,5×`) ile oynar; Bağlantılar’da Caravaggio ↔ Artemisia geçişi çalışır.

Tüm `390×844` (`deviceScaleFactor: 2`, `780×1688 px`) Gece ve Gündüz PNG çıktıları [`goruntuler/`](goruntuler/) klasöründedir.

---

## Ortak Tasarım Dili ve Veri Uyumu

Üç yön de `TASARIM_DILI.md` ve mevcut 5 ekran (`Bugün`, `Çalış`, `Galeri`, `Yolculuk`, `Ben`, `Dinleyerek bak`) ile aynı ailedendir:

- **Üç katmanlı zemin:** Kömür `#121110` (Gece) / sıcak kâğıt `#ece8e1` (Gündüz) + `3×3 px` nokta dokusu + aktif sanatçının tablosundan sol üst / sağ alt sabit hale + çok silik dönem deseni (Gece `%4`, Gündüz `%4,5`).
- **Yazı üçlüsü:** Başlıklarda **Bodoni Moda** (500, `−0,015 em`), hikâye metni ve kelime-kelime Fola altyazısında **Newsreader** (`18–22,5 px`), arayüz ve üst yazılarda **Archivo** (`13–15 px`).
- **“Yapma” kuralları:** Bölüm numarası (`"BÖLÜM 2 / 5"`) yok; büyük harfli harf aralıklı etiket yok (tüm üst yazılar cümle düzeni, `13 px`, yarı kalın, pirinç); aynı ekranda en çok **1 dolu hap düğme**; sol kenarlı renkli kutu ve emoji yok; tüm dokunma hedefleri `≥ 44 px`; `390 px` genişlikte sıfır yatay taşma (`scrollWidth = 390`).
- **Kırpılmamış eserler:** Okuma ekranında tüm tablolar doğal en-boy oranında (`width: 100%; height: auto`), sıfır kırpmayla gösterilir; hemen altında eser künyesi ve **“Bu dönemle bağı”** yer alır.
- **Veri biçimi (`hikaye-verisi.js`):** İstenen JSON şemasını doğrudan taşır:
  `{ baslik, alt_baslik, giris, bolumler: [{ baslik, yillar, paragraflar, eserler: [{ qid, bag }] }], kapanis, baglantilar: [{ sanatci, id, iliski }], kaynaklar: [{ baslik, adres }], kelime }`.

---

## Sekme Çubuğu Önerisi (Üç Yönde Üç Ayrı Çözüm)

Bugünkü uygulamada 5 mantıksal sekme var (`Bugün`, `Yolculuk`, `Galeri`, `Çalış`, `Ben`). Emre **Hikâyeler’i ayrı sekme** olarak istediği için üç yönde de **Hikâyeler** doğrudan `Bugün`’ün hemen yanında, birinci sınıf sekme olarak durur; üç yön `Ben`’in konumunu farklı çözerek `390 px` genişlikte gerçek görsel kıyas imkânı verir:

| Yön | Sekme Çubuğu Düzeni | Yuvaya Düşen Genişlik | Kısa Gerekçe |
|---|---|---|---|
| **Yön 1 · Monografi** *(Önerilen)* | **5 sekme altta** (`Bugün · Hikâyeler · Yolculuk · Galeri · Çalış`) + **`Ben` sağ üst cam düğme** | `~69 px` (en ferah) | `Ben` (istatistik, koleksiyon, ayarlar) zaten sitede de üst köşedeydi ve içerik gezintisi değil kişisel profil alanıdır. `Ben` sağ üste alınınca alt cam çubuk Apple HIG’in ideal 5 sekme sınırında ferah kalır, etiketler küçülmez ve `Hikâyeler` kendi ayrı sekmesine kavuşur. |
| **Yön 2 · Sinema Odası** | **5 + 1 ayrık cam düzen** (`Bugün · Hikâyeler · Yolculuk · Galeri · Çalış` ana kapsülde + sağda ayrı yuvarlak cam `Ben` kapsülü) | `~58 px` + `58 px` ayrık | `Ben` alt başparmak erişiminden kopmaz, ama ince bir `8 px` nefes boşluğuyla 5 sanat/öğrenme sekmesinden zihinsel olarak ayrılır. iOS 26 cam ayrışımı hissini Nora Sanat’ın yüzen çubuğuna taşır. |
| **Yön 3 · Kırılma Ekseni** | **6 sekme tek yüzen çubukta** (`Bugün · Hikâyeler · Yolculuk · Galeri · Çalış · Ben`) | `~59 px` × 6 | Hiçbir mevcut sekmenin alışılan yeri değişmez. `390 px` ekranda 6 sekmenin gerçek yoğunluğunu (ve `9,5 px` etiket sıkılığını) yan yana görüp karar verebilmek için doğrudan tasarıma kondu. |

**Öneri:** Günlük okuma ve başparmak rahatlığı açısından **Yön 1 (5 sekme + üstte `Ben`)** en temiz çözüm; `Ben` mutlaka altta kalsın istenirse **Yön 2 (`5 + 1` ayrık cam)**, 6 sekmeli tek çubuğa göre çok daha okunaklı bir görsel hiyerarşi verir.

---

## Yön 1 — Monografi (`yon-1.html`)

**Fikir:** *Bir sanat dergisi ve Phaidon kitap monografisi sakinliği.* Uzun metin okuma konforunu ve düzenli editoryal hiyerarşiyi öne çıkarır.

### Ekranlar
1. **Ana ekran** ([Gece](goruntuler/yon-1-ana-gece.png) · [Gündüz](goruntuler/yon-1-ana-gunduz.png)): Üstte `Hikâyeler` başlığı ve sağ üst cam `Ben` düğmesi; hemen altında büyük **“Kaldığın yerden devam”** kapak kartı (Caravaggio, `9 dk kaldı`, `3 px` pirinç çizgi, ekranın tek dolu hapı `Dinlemeye devam` + cam `Oku`); altında alt çizgili dönem şeridi (`Tümü · Barok · Altın Çağ · Romantizm`) ve tek kart içinde gruplu sanatçı kitaplığı.
2. **Hikâye okuma** ([Gece](goruntuler/yon-1-okuma-gece.png) · [Gündüz](goruntuler/yon-1-okuma-gunduz.png) · [Artemisia](goruntuler/yon-1-artemisia-okuma-gece.png)): Sayfa başında numarasız **Dönemler fihristi** (yıllar + durum noktası), ilk paragrafta zarif `Bodoni Moda` baş harf, kaydırınca üstte sabitlenen ince okuma çizgisi + `9 dk kaldı` cam çubuğu; metnin içinde paspartulu, **büyük ve kırpılmamış müze levhaları** ve altlarında `Bu dönemle bağı` açıklaması.
3. **Dinleme (Fola)** ([Gece](goruntuler/yon-1-dinleme-gece.png) · [Gündüz](goruntuler/yon-1-dinleme-gunduz.png)): Üstte bölümün eseri yumuşak çerçevede hafif nefes yakınlaşmasıyla durur; ortada **kelime kelime vurgulanan Fola altyazısı** (geçmiş kelimeler tam mürekkep, aktif kelime altı ince çizgili pirinç, gelecek kelimeler soluk); altta bölüm çentikli zaman çizgisi, bölüm atlama, `−15 / +15 sn`, büyük dolu oynat/duraklat, hız (`1×`) ve `Metne dön`.
4. **Bağlantılar ve Kaynaklar** ([Bağlantılar Gece](goruntuler/yon-1-baglantilar-gece.png) · [Gündüz](goruntuler/yon-1-baglantilar-gunduz.png) · [Kaynaklar Gece](goruntuler/yon-1-kaynaklar-gece.png) · [Gündüz](goruntuler/yon-1-kaynaklar-gunduz.png)): İlişki türüne göre gruplu soykütüğü kartları (*Hocası ve etkilendikleri*, *Dostlar, rakipler ve kırılmalar*, *Etkilediği sanatçılar*) — her satırda kim kime ne geçirdi ve hikâyesi olanlarda `Hikâyeye geç ›`; altında sade kaynak listesi.
5. **Başka sekmede küçük çalar** ([Galeri üstünde Gece](goruntuler/yon-1-mini-gece.png) · [Gündüz](goruntuler/yon-1-mini-gunduz.png)): `Galeri` sekmesine geçildiğinde alt sekme çubuğunun `10 px` üstünde süzülen cam çalar (eser kapağı, sanatçı + aktif bölüm, akan cümle, `2 px` pirinç ilerleme çizgisi, oynat/duraklat ve kapat).

### Etkileşimler ve Titreşim
- **Kaydırma:** Okumada bölüm başlığı geçildikçe üst cam çubuktaki aktif bölüm adı ve `3 px` ilerleme çizgisi yumuşakça güncellenir.
- **Dokunma & Geçişler:** Kitaplık satırına dokununca okuma sayfası sağdan iterek açılır (`0,35 s`, `timingCurve(0.22, 1, 0.36, 1)`); `Fola ile dinle` tam ekran alttan yükselir (`fullScreenCover`); dinleme ekranı aşağı çekilince küçük çalara katlanır (`matchedGeometryEffect` ile eser kapağı küçülür).
- **Titreşim (`Titresim.swift`):** Dönem sekmesi değiştirirken `Titresim.secim()`, bölüm atlarken ve `±15 sn` dokunuşunda `Titresim.dokunus()`, hikâye tamamlanınca `Titresim.dogru()`.

---

## Yön 2 — Sinema Odası (`yon-2.html`)

**Fikir:** *Tablo her an sahnenin tek efendisi.* `Bugün` ve `Dinleyerek bak` ekranlarının tam ekran dramatik dilini Hikâyeler’e taşır.

### Ekranlar
1. **Ana ekran** ([Gece](goruntuler/yon-2-ana-gece.png) · [Gündüz](goruntuler/yon-2-ana-gunduz.png)): Üst yarısı tamamen kenardan kenara **"Kaldığın yerden devam"** Caravaggio sahnesi (`Dinlemeye devam` tek dolu hap + cam `Oku`); altında cam kapsül dönem seçici ve yatay kaydırılan büyük dikey sinema afişleri; altta **`5 + 1` ayrık cam sekme çubuğu**.
2. **Hikâye okuma** ([Gece](goruntuler/yon-2-okuma-gece.png) · [Gündüz](goruntuler/yon-2-okuma-gunduz.png)): Üstte numarasız ince **bölüm ışık çubukları** (biten yeşil, aktif pirinç, bekleyen soluk); eserler metnin içinde **kenardan kenara tam enli ve kırpılmadan** açılır; sağ alt köşede sabit yüzen `Fola ile dinle` hapı her an tek dokunuşla sinema dinlemesine geçirir.
3. **Dinleme (Fola)** ([Gece](goruntuler/yon-2-dinleme-gece.png) · [Gündüz](goruntuler/yon-2-dinleme-gunduz.png) · [Artemisia](goruntuler/yon-2-artemisia-dinleme-gece.png)): Aktif bölümün eseri **tüm `390×844` ekranı** doldurur; ağır kart yoktur — **büyük kelime-kelime sinema altyazısı** doğrudan yumuşak perde üzerinde akar; altta tek satırlık yüzen cam denetim kapsülü (`|<`, `−15`, oynat, `+15`, `>|`) + hız ve bağlantılar bağlantısı.
4. **Bağlantılar (Etkileşim Ağı) ve Kaynaklar** ([Bağlantılar Gece](goruntuler/yon-2-baglantilar-gece.png) · [Gündüz](goruntuler/yon-2-baglantilar-gunduz.png) · [Kaynaklar Gece](goruntuler/yon-2-kaynaklar-gece.png) · [Gündüz](goruntuler/yon-2-kaynaklar-gunduz.png)): Merkezde sanatçının madalyonu, çevresinde yönlü etki yaylarıyla konumlanan sanatçılar (SVG takımyıldızı). Herhangi bir düğüme dokununca pirinç yay yanar, alttaki kartta *“Kim kime ne geçirdi”* özeti ve hikâyesi varsa tek dolu `Artemisia Gentileschi hikâyesine geç` düğmesi açılır; altında sade kaynak listesi.
5. **Başka sekmede küçük çalar** ([Bugün üstünde Gece](goruntuler/yon-2-mini-gece.png) · [Gündüz](goruntuler/yon-2-mini-gunduz.png)): `Bugün` tam ekran tablosunun ve `5 + 1` ayrık çubuğun üstünde süzülen koyu/gündüz cam mini çalar (`−15 sn` ve oynat/duraklat doğrudan erişilebilir).

### Etkileşimler ve Titreşim
- **Kaydırma:** Yatay afiş şeridi `viewAligned` mıknatıslı kaydırmayla çalışır; okumada tam enli eser ekrana girerken kenar boşluksuz nefes alır.
- **Dokunma & Geçişler:** Sinema dinleme ekranında boş alana tek dokunuş denetim kapsülünü gizleyip yalnız eser + kelime-kelime altyazıyı bırakır (`Dinleyerek bak` davranışı); etkileşim ağında düğüm seçimi yay rengini `0,28 s` içinde çapraz geçirir.
- **Titreşim:** Afiş mıknatısı oturunca ve ağ düğümü seçilince `Titresim.secim()`; sinema dinlemede bölüm değiştiğinde çok hafif `Titresim.dokunus()`.

---

## Yön 3 — Kırılma Ekseni (`yon-3.html`)

**Fikir:** *Özgün öneri — Bir sanatçının hayatını gerçekten “kırılma anları → tuvale yansıması” ekseninde, metin ve sesi birbirine kilitleyerek yaşamak.*

### Ekranlar
1. **Ana ekran** ([Gece](goruntuler/yon-3-ana-gece.png) · [Gündüz](goruntuler/yon-3-ana-gunduz.png)): Üstte kompakt **“Kaldığın yerden devam”** şeridi (`Sürdür` dolu hap + `Metni aç`); altında `Akıma göre / Yüzyıla göre` cam bölme ve dönem şeridi; her sanatçı dosyasında o sanatçının **4 kırılma durağı** (*Roma · Contarelli · 1606 düellosu · Malta*) ve `3 px` ilerleme çizgisi; altta **6 sekmeli tek cam çubuk**.
2. **Hikâye okuma (Eşzamanlı Fola Eşlik Çubuğu)** ([Gece](goruntuler/yon-3-okuma-gece.png) · [Gündüz](goruntuler/yon-3-okuma-gunduz.png)): Üstte etkileşimli **yıl ekseni** (`1592 · 1599 · 1601 · 1606`) — dokununca doğrudan o döneme kayar; her bölüm sakin bir **kırılma mührüyle** (yıl, başlık, tek satır kırılma olayı) açılır ve hemen ardında kırpılmamış büyük tablo + `Bu dönemle bağı` gelir. Alt kenarda sabit **Fola eşlik çubuğu** bulunur: okurken tek dokunuşla sesi başlatır ya da yukarı okla tam ekran dinlemeye büyütür.
3. **Dinleme (Eser + Kırılma Bandı)** ([Gece](goruntuler/yon-3-dinleme-gece.png) · [Gündüz](goruntuler/yon-3-dinleme-gunduz.png)): Eser sahnesinin hemen altında 4 parçalı **yatay kırılma bandı** (`1592 Roma · 1599 Contarelli · 1601 Emmaus · 1606 Sürgün`) dinlerken sanatçının hayatındaki tam yeri gösterir ve tek dokunuşla bölüm atlatır; altında kelime-kelime akan Fola altyazısı ve tam denetimler.
4. **Bağlantılar (Kronolojik Etki Çizgisi) ve Kaynaklar** ([Bağlantılar Gece](goruntuler/yon-3-baglantilar-gece.png) · [Gündüz](goruntuler/yon-3-baglantilar-gunduz.png) · [Artemisia Gündüz](goruntuler/yon-3-artemisia-baglantilar-gunduz.png) · [Kaynaklar Gece](goruntuler/yon-3-kaynaklar-gece.png) · [Gündüz](goruntuler/yon-3-kaynaklar-gunduz.png)): Dikey kronolojik omurga üzerinde sanatçının kendisi merkezde (`1571–1610`), öncesinde `← Ondan aldı` hocaları, hizasında `↔ Aynı yıllarda` dost/rakipleri, sonrasında `→ Ona aktardı` etkilediği sanatçılar sıralanır; altında sade `Arşiv ve kaynaklar` listesi.
5. **Başka sekmede küçük çalar** ([Yolculuk üstünde Gece](goruntuler/yon-3-mini-gece.png) · [Gündüz](goruntuler/yon-3-mini-gunduz.png)): `Yolculuk` sekmesinin ve 6 sekmeli çubuğun üstünde kalan, aktif yıl + bölüm bilgisini gösteren cam mini çalar.

### Etkileşimler ve Titreşim
- **Kaydırma:** Okuma kaydırıldıkça üstteki yıl omurgasındaki çizgiler anlık dolar; kırılma mührüne gelindiğinde aktif yıl pirince döner.
- **Dokunma & Geçişler:** Okuma altındaki Fola eşlik çubuğu yukarı çekildiğinde veya sağdaki okla dokunulduğunda yaylı geçişle (`spring(response: 0.42, dampingFraction: 0.86)`) tam ekran dinlemeye açılır; `Okumaya geç` aynı cümlenin tam paragrafına hizalayarak döner.
- **Titreşim:** Yıl omurgasında bölüm atlarken ve kırılma bandında dönem seçerken `Titresim.secim()`; eşlik çubuğu tam ekrana açılırken hafif `Titresim.dokunus()`.

---

## Hangi Yön Ne Zaman Seçilmeli?

- **En sakin, okuma odaklı ve Apple Books / New Yorker zarafetinde deneyim** isteniyorsa → **Yön 1 · Monografi** (özellikle `5 sekme + Ben sağ üstte` çubuğuyla).
- **Tablonun ekranı tamamen doldurduğu, `Bugün` ve `Dinleyerek bak` ile birebir akraba dramatik atmosfer** ve görsel etkileşim ağı isteniyorsa → **Yön 2 · Sinema Odası** (özellikle `5 + 1` ayrık cam çubuğuyla).
- **Okurken tek dokunuşla sese geçme, sanatçının kırılma yıllarını her an takip etme ve kronolojik etki çizgisi** öne çıksın isteniyorsa → **Yön 3 · Kırılma Ekseni**.
- *Melez seçenek:* **Yön 1’in sekme çubuğu (`5 + Ben üstte`) ve okuma tipografisi** + **Yön 2’nin tam ekran sinema dinleme sahnesi ve etkileşim ağı** + **Yön 3’ün okuma içi Fola eşlik çubuğu** tek bir nihai üründe de sorunsuz birleşebilir.

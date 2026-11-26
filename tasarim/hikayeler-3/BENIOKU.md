# Hikâyeler Sekmesi — Sade Blog / Dergi Tasarımı (3. Tur)

Emre’nin geri bildirimi doğrultusunda (*“Bu kısım blog gibi bir yer, bu kadar karışık olmamalı”*) takımyıldız, zaman nehri, portre duvarı, yıl sürgüsü, etki ağı, dönem çipleri ve filtrelerin tamamı kaldırıldı. Üç yönün tamamı **sade bir kültür dergisi / Substack okuma ve dinleme deneyimi** sunar; aralarındaki fark yalnızca **tipografi, kapak düzeni ve okuma ritmindedir**. **Uygulama koduna dokunulmamıştır.**

Her üç dosya da (`yon-1.html`, `yon-2.html`, `yon-3.html`) `390×844` iPhone ölçüsünde, uygulamanın yerel yazı tipleriyle (`Bodoni Moda`, `Newsreader`, `Archivo`), `sanat-atlasi` deposundaki gerçek `data/sanatci_hikayeleri.json` metinleriyle, **Türkçe eser adlarıyla** (`data/eser_adlari_tr.json`) ve Wikimedia Commons kamu malı görselleriyle (`gorseller/`, 57 yerel eser) tamamen **çevrimdışı** çalışır.

Tüm `390×844` (`deviceScaleFactor: 2`, `780×1688 px`) Gece ve Gündüz çıktıları [`goruntuler/`](goruntuler/) klasöründedir (36 PNG; tamamında `scrollWidth = 390`, 0 kırık görsel, ekran başına en çok 1 dolu düğme, tüm dokunma hedefleri `≥ 44 px`).

---

## Ortak Sade Yapı

- **Ana ekran:** Alt alta yazılar; her birinde büyük kapak görseli, başlık, bir cümlelik alt başlık ve `sanatçı adı · yıllar · "X dk okuma · Y dk dinleme"`. Yarım kalan ya da en son eklenen yazı en üstte; gerisi kesintisiz sade akış. Kategori, filtre, çip yok; arama yalnızca tek bir büyüteç düğmesi.
- **Okuma:** Tek sütun, rahat serif metin (`Newsreader 18,5–19 px`, geniş `1,72–1,74` satır aralığı); bölüm başlıkları sade ara başlık; eserler metnin arasında tam genişlikte, kırpılmamış, hemen altında Türkçe eser adı, yıl, müze ve **“Bu dönemle bağı”**. Yazının başında küçük bir `Dinle` düğmesi; sonunda **Bağlantılı yazılar** (2–4 tıklanabilir yazı kartı) ve sade **Kaynaklar** listesi.
- **Okuma içi dinleme:** Ayrı tam ekran sinema yok — dinleme doğrudan okuma ekranının içinde kalır. Altta ince bir çalar çubuğu (`1×`, `−15 sn`, oynat/duraklat, `+15 sn`, kapat ve ince ilerleme çizgisi) açılır; okunan paragraf sol kenarlı kutu olmadan hafifçe vurgulanır, diğer paragraflar geri çekilir ve ekran okunan paragrafı takip eder. Herhangi bir paragrafa dokunarak doğrudan o noktadan dinlenebilir.
- **Başka sekmede küçük çalar:** `Galeri`, `Bugün` veya `Yolculuk` sekmesine geçildiğinde alt sekme çubuğunun hemen üstünde ince cam çalar görünür; dokununca yazının kaldığı paragrafına döner.

---

## Sekme Çubuğu Önerisi

Mevcut 5 sekmeye (`Bugün · Çalış · Galeri · Yolculuk · Ben`) **Hikâyeler** eklendiğinde oluşan üç seçenek üç yöne bölünerek `390 px` ekranda yan yana kıyaslanır:

| Yön | Sekme Çubuğu Düzeni | Kısa Değerlendirme |
|---|---|---|
| **Yön 1 · Klasik Dergi** *(Önerilen)* | **5 sekme altta** (`Bugün · Hikâyeler · Çalış · Galeri · Yolculuk`) + **`Ben` sağ üst cam düğme** | Alt çubuk en ferah 5 sekme sınırında kalır (`~70 px`/sekme); `Ben` profil/ayar alanı olarak üst sağda sade durur. |
| **Yön 2 · Substack Minimal** | **`5 + 1` ayrık cam kapsül** (`Bugün · Hikâyeler · Çalış · Galeri · Yolculuk` + sağda ayrı yuvarlak `Ben`) | `Ben` başparmak erişiminden kopmaz, `8 px` aralıkla 5 içerik sekmesinden temiz ayrılır. |
| **Yön 3 · Foto-Deneme** | **6 sekme tek yüzen çubukta** (`Bugün · Hikâyeler · Çalış · Galeri · Yolculuk · Ben`) | Hiçbir sekmenin yeri değişmez; `390 px`’te 6’lı çubuğun gerçek yoğunluğunu kıyaslamak için gösterildi. |

---

## Yön 1 — Klasik Dergi (`yon-1.html`)

**Fikir:** *The New Yorker / K24 / Aeon* sakinliğinde klasik kültür dergisi.

- **Ana ekran** ([Gece](goruntuler/yon-1-ana-gece.png) · [Gündüz](goruntuler/yon-1-ana-gunduz.png)): En üstte yarım kalan Rembrandt yazısı (`4:3` kapak, `9 dk kaldı`, ince pirinç çizgi); altında ince yatay çizgilerle ayrılmış sade dergi yazıları (`Bodoni Moda` başlık, `Newsreader` alt başlık, `okuma · dinleme` süreleri). Üstte tek büyüteç ve sağ üst `Ben`.
- **Okuma (başı + eser)** ([Başı Gece](goruntuler/yon-1-okuma-basi-gece.png) · [Gündüz](goruntuler/yon-1-okuma-basi-gunduz.png) · [Eser Gece](goruntuler/yon-1-okuma-eser-gece.png) · [Gündüz](goruntuler/yon-1-okuma-eser-gunduz.png)): Ortalı dergi başlığı, yazının başında tek dolu `Dinle · 23 dk` hapı, ilk paragrafta zarif `Bodoni Moda` baş harf, metin içinde ince kenarlı kırpılmamış eserler ve Türkçe künye + `Bu dönemle bağı`.
- **Okuma sırasında dinleme** ([Gece](goruntuler/yon-1-dinleme-gece.png) · [Gündüz](goruntuler/yon-1-dinleme-gunduz.png)): Altta yüzen ince cam çalar çubuğu, okunan paragrafta hafif sıcak vurgu ve ince pirinç cümle altı çizgisi; pasif paragraflar geri çekilir.
- **Yazının sonu** ([Gece](goruntuler/yon-1-son-gece.png) · [Gündüz](goruntuler/yon-1-son-gunduz.png)): `Bağlantılı yazılar` (Goya, Van Gogh, Courbet — dokununca doğrudan açılır) ve sade `Kaynaklar` listesi.
- **Küçük çalar** ([Galeri üstünde Gece](goruntuler/yon-1-mini-gece.png) · [Gündüz](goruntuler/yon-1-mini-gunduz.png)).

---

## Yön 2 — Substack Minimal (`yon-2.html`)

**Fikir:** *Substack / Medium* bülten saflığı; desen ve hale en aza çekilmiş, kutu ve çerçeve yok, yalnız metin ve nefes.

- **Ana ekran** ([Gece](goruntuler/yon-2-ana-gece.png) · [Gündüz](goruntuler/yon-2-ana-gunduz.png)): Sola yaslı, kutusuz akış; en üstte yeni eklenen Vermeer yazısı, hemen altında yarım kalan Rembrandt; `16 px` yumuşak köşeli kapak, `Newsreader` başlık, `Archivo` özet ve süre. Altta **`5 + 1` ayrık cam sekme çubuğu**.
- **Okuma (başı + eser)** ([Başı Gece](goruntuler/yon-2-okuma-basi-gece.png) · [Gündüz](goruntuler/yon-2-okuma-basi-gunduz.png) · [Eser Gece](goruntuler/yon-2-okuma-eser-gece.png) · [Gündüz](goruntuler/yon-2-okuma-eser-gunduz.png)): Substack’in temiz üst bloğu (sola yaslı başlık → alt başlık → ince çizgiler arasında sanatçı + süre ve sağda kompakt `Dinle` hapı) → `Newsreader 19 px / 1,74` pürüzsüz okuma sütunu ve çerçevesiz tam genişlikte eserler.
- **Okuma sırasında dinleme** ([Gece](goruntuler/yon-2-dinleme-gece.png) · [Gündüz](goruntuler/yon-2-dinleme-gunduz.png)): Okunan paragraf öne çıkar, ekran akışı takip eder, altta ince yüzen çalar çubuğu.
- **Yazının sonu** ([Gece](goruntuler/yon-2-son-gece.png) · [Gündüz](goruntuler/yon-2-son-gunduz.png)): `Bağlantılı yazılar` + `Kaynaklar`.
- **Küçük çalar** ([Bugün üstünde Gece](goruntuler/yon-2-mini-gece.png) · [Gündüz](goruntuler/yon-2-mini-gunduz.png)).

---

## Yön 3 — Büyük Görselli Foto-Deneme (`yon-3.html`)

**Fikir:** *Aperture / NYT Magazine* uzun-biçimli foto-deneme; her yazı kenardan kenara büyük görselle açılır, ama akış yine tek sütun ve sade.

- **Ana ekran** ([Gece](goruntuler/yon-3-ana-gece.png) · [Gündüz](goruntuler/yon-3-ana-gunduz.png)): Kenardan kenara (`390 px` tam en) kapak görselleriyle akan yazılar (en üstte yarım kalan Goya), altında büyük `Bodoni Moda` başlık, alt başlık ve süreler. Altta **6 sekmeli tek cam çubuk**.
- **Okuma (başı + eser)** ([Başı Gece](goruntuler/yon-3-okuma-basi-gece.png) · [Gündüz](goruntuler/yon-3-okuma-basi-gunduz.png) · [Eser Gece](goruntuler/yon-3-okuma-eser-gece.png) · [Gündüz](goruntuler/yon-3-okuma-eser-gunduz.png)): Kenardan kenara açılan kapak ve metin içinde kenardan kenara (`390 px`, sıfır kırpma) eser levhaları; altında Türkçe ad, yıl, müze ve `Bu dönemle bağı`.
- **Okuma sırasında dinleme** ([Gece](goruntuler/yon-3-dinleme-gece.png) · [Gündüz](goruntuler/yon-3-dinleme-gunduz.png)): Alt kenara tam oturan sade cam çalar şeridi + vurgulanan paragraf.
- **Yazının sonu** ([Gece](goruntuler/yon-3-son-gece.png) · [Gündüz](goruntuler/yon-3-son-gunduz.png)): `Bağlantılı yazılar` (Velázquez, Rembrandt, Bosch) + `Kaynaklar`.
- **Küçük çalar** ([Yolculuk üstünde Gece](goruntuler/yon-3-mini-gece.png) · [Gündüz](goruntuler/yon-3-mini-gunduz.png)).

---

## Etkileşimler ve Titreşim (`Titresim.swift`)

- **Okuma & Dinleme:** Yazı başındaki `Dinle` düğmesi veya üst sağdaki kulaklık simgesi alt çaları yaylı geçişle açar (`spring(response: 0.36, dampingFraction: 0.88)`). Dinlerken herhangi bir paragrafa dokunmak sesi o paragrafa atlatır (`Titresim.secim()`).
- **±15 sn ve hız:** `Titresim.dokunus()`.
- **Yazı sonu bağlantılı yazılar:** Kart dokunuşunda sağdan yumuşak geçişle ilgili sanatçının yazısı açılır; okuma/dinleme tamamlanınca `Titresim.dogru()`.
- **Başka sekmeye geçince:** Çalar açıksa alt sekme çubuğunun üstünde küçük çalara katlanır; dokununca doğrudan yazının kaldığı paragrafa döner.

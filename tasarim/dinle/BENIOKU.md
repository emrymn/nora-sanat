# Dinleyerek bak (Sesli Rehberli Bakış) — Ekran ve Kamera Yeniden Tasarımı

Tam ekran **“Dinleyerek bak”** deneyimi (`NoraSanat/Ekranlar/Dinle/DinleEkrani.swift`, `DinleOynatici.swift`, `DinleSesi.swift` ve `Paketler/NoraCekirdek/Sources/NoraCekirdek/Dinle/DinlemePlani.swift`) için üç ayrı tasarım yönü ve Swift’e doğrudan aktarılacak sinematik kamera fiziği. **Uygulama koduna dokunulmamıştır.**

Her üç HTML dosyası da (`yon-1.html`, `yon-2.html`, `yon-3.html`) `390×844` telefon ölçüsünde, yerel yazı tipleriyle (`NoraSanat/YaziTipleri/`), dönem desen karolarıyla (`NoraSanat/Ekranlar/Galeri/Desenler/`) ve [`gorseller/`](gorseller/) altındaki **3 yüksek çözünürlüklü (`3840 px`) kamu malı tabloyla** tamamen **internetsiz** çalışır; dış bağlantı yoktur. Her dosyada tam bir tur (açılış → anlatı → 4 ayrıntı → sessiz bakış → kapanış) gerçek kamera fiziği, cümle zamanlamalı altyazı ve isteğe bağlı tarayıcı `speechSynthesis` (`tr-TR`) sesiyle canlı olarak oynar.

---

## Bugünkü ekrandaki sorunlar ve çözümler

1. **Doğrusal ve sert kamera kayması:** Bugünkü kod tek bir `withAnimation(.easeInOut(duration: yaklasma))` ile `olcek` ve `kayma` değerlerini doğrusal olarak A’dan B’ye taşıyordu. Bu hem ölçek–konum uyumsuzluğundan yalpalama yaratıyor, hem iki uzak ayrıntı arasında yüksek yakınlaştırmada sürüklenerek bağlamı kaybettiriyor, hem de anlatım bitene dek hedefe oturmayı geciktiriyordu.
   - **Çözüm:** Log-ölçek (`z = ln(s)`) uzayında **Nefesli Yay** (iki ayrıntı arasında önce hafifçe uzaklaşıp tablonun bağlamını gösteren, sonra kadife yavaşlamayla yeni ayrıntıya inen yol) + varış sonrası **canlı mikro-süzülme**.
2. **Aşırı yakınlaştırma ve dokununca tablonun sıçraması:** `enCok: 4` küçük ayrıntıları piksellenme sınırına yaklaştırıyordu; arayüzü gizlemek için dokunulduğunda kamera `0,6 sn` içinde tabloyu aşağı çekiyordu.
   - **Çözüm:** Üst sınır `2,68×` ve ekran DPR’ına bağlı piksel koruması; ayrıntının dikey odak çapası sabit `%43` (altyazının da, açılan denetimlerin de üstünde) olduğu için ekrana dokununca tablo yerinden oynamaz.
3. **Tablonun üçte birini kapatan ağır kart ve kaybolmayan denetimler:** Bugünkü altyazı bütün paragrafı tek kutuda veriyor ve denetimler dokunulana kadar ekranda kalıyordu.
   - **Çözüm:** Cümle cümle akan (en çok 2 satır) sade altyazı; oynatma denetimleri dokunulmadığında `3,5–4,0 sn` içinde kendiliğinden kaybolur, dokununca geri gelir.
4. **Gündüz teması ve tasarım dili uyumu:** Saf siyah zemin, büyük harfli `DİNLEYEREK BAK` etiketi ve iOS sistem `Picker`’ları yerine `TASARIM_DILI.md` kuralları (Bodoni Moda / Newsreader / Archivo, tek dolu hap düğme, cümle düzeni pirinç üst yazı, Gece karanlık sinema + Gündüz sıcak galeri duvarı, en az `44 px` dokunma hedefi, `390 px` yatay taşmasız).

---

## Swift’e aktarılacak kamera yolu ve eğri değerleri

Referans gerçekleme [`kamera.js`](kamera.js) içindedir. Swift tarafında saf Foundation mantığı olarak `Paketler/NoraCekirdek/Sources/NoraCekirdek/Dinle/DinlemeKamerasi.swift` dosyasına konup `DinleEkrani.swift` içinde `TimelineView(.animation)` ile her karede (`60/120 Hz`) değerlendirilmesi önerilir.

### 1. Durum uzayı ve dönüşüm

Kamera durumu 4 skalerden oluşur: `(u, v, z, anchorY)`

- `u, v ∈ [0, 1]`: tablo koordinatında odaklanılan nokta (`0,5, 0,5` tablonun merkezi).
- `z = ln(s)`: **logaritmik ölçek** (`s = exp(z)`). Log-ölçekte eşit adımlar, insan gözü için sabit algılanan yakınlaşma hızı üretir.
- `anchorY`: odak noktasının sahnedeki dikey yeri (px).
- `taban = (tabanW, tabanH)`: tablonun tam görünümde (`s = 1`) sahneye sığdırılmış boyutu.
- Ekrandaki piksel dönüşümü (merkezden `scaleEffect(s)` + `offset(tx, ty)`):

```text
s  = exp(z)
tx = -(u - 0.5) * tabanW * s
ty = -(v - 0.5) * tabanH * s + (anchorY - sahneH / 2)
```

### 2. Ölçek sınırları ve piksellenme koruması

| Parametre | Değer | Açıklama |
|---|---|---|
| `pay` | `0.56` | Ayrıntı kutusunun güvenli alan (`%90` en × `%60` boy) içindeki nefesli oranı |
| `enAzOlcek` | `1.48` | Ayrıntı adımında en düşük yakınlaşma |
| `enCokOlcek` | `2.68` | Abartısız üst sınır (ayrıntı net, çevre bağlamı canlı) |
| `anlatiOlcek` | `1.24` | Hikâye (`anlati`) adımında yavaş geniş gezinti ölçeği |
| `pikselSinir` | `(kaynakEn * 1.18) / (tabanW * dpr)` | Kaynak görselin gerçek çözünürlüğünü aşan piksellenmeyi önler |
| `odakYOrani` | `0.43` (`Yön 2–3: 0.42`) | Ayrıntının ekrandaki dikey odak noktası — dokununca tablo sıçramaz |
| `tamYOrani` | `0.34` (`Yön 3: 0.37`) | Başlangıç/bitişte tam tablonun dikey merkezi |

**Kenar sınırlaması (hedef hesaplanırken uygulanır, böylece yol boyunca duvara çarpma olmaz):**

- `olcekW = tabanW * s > sahneW` ise `yariU = (sahneW / 2) / olcekW`, `u = clamp(u, yariU, 1 - yariU)`.
- `olcekH = tabanH * s >= sahneH` ise `minV = anchorY / olcekH`, `maxV = 1 - (sahneH - anchorY) / olcekH`, `v = (minV <= maxV) ? clamp(v, minV, maxV) : 0.5`. Böylece yakınlaşılmış tablo hiçbir zaman alt kenarda boş şerit bırakmaz.

### 3. İki nokta arası yol: Nefesli Yay (`0 ≤ t ≤ 1`)

Başlangıç `(u0, v0, z0)` ve hedef `(u1, v1, z1)` arasındaki normalize uzaklık `d = hypot(u1 - u0, v1 - v0)`:

| Parametre | Değer / Formül | Açıklama |
|---|---|---|
| **Geçiş süresi (`T_gecis`)** | `clamp(2.8 + d * 2.6, 2.9, 4.4)` sn | İki ayrıntı arası; uzak ayrıntıya daha sakin varılır |
| Açılış → anlatı / ilk nokta | `3.1 – 3.2` sn | Uzaklaşma yayı kapalı (`A = 0`), doğrudan yumuşak yaklaşma |
| Sessiz bakış / Kapanış | `3.4 – 3.6` sn | Tam tabloya uzun, dingin geri çekilme |
| **Konum eğrisi (`egriKonum`)** | `cubic-bezier(0.42, 0.0, 0.18, 1.0)` | Yumuşak kalkış, uzun kadife yavaşlama kuyruğu |
| **Ölçek eğrisi (`egriOlcek`)** | `cubic-bezier(0.36, 0.0, 0.20, 1.0)` | Doğal sinema merceği hızlanması |
| **Uzaklaşma derinliği (`A`)** | `clamp(0.16 + d * 0.62, 0.16, 0.48)` | Yalnız iki yakın nokta arasında (`z0 > 0.18`, `z1 > 0.18`, `d > 0.05`); ortada `e^-A` (`0.85×` .. `0.62×`) kadar nefes alır |
| **Nefes zarfı (`nefes(t)`)** | `sin(π · t^0.88)^1.55` | `t = 0` ve `t = 1`’de değer ve türev `0` (`C¹` pürüzsüz); pik noktası hafif erken (`t ≈ 0.44`) olduğundan kamera önce yükselir, sonra yeni ayrıntıya süzülür |

```text
u(t) = lerp(u0, u1, egriKonum(t))
v(t) = lerp(v0, v1, egriKonum(t))
z(t) = max(0, lerp(z0, z1, egriOlcek(t)) - A * sin(π * pow(t, 0.88))^1.55)
```

> **Neden akıcı görünüyor?** `egriKonum`’un en hızlı olduğu an (`t ≈ 0.42`), tam olarak `nefes(t)`’nin kamerayı en çok uzaklaştırdığı ana denk gelir. Böylece ekran üzerindeki piksel akış hızı sabit ve sarsıntısız kalır; göz yeni ayrıntının tablodaki yerini kaybetmez.

### 4. Konuşma sürerken canlı süzülme (`τ = gecen - T_gecis ≥ 0`)

Kamera hedefe vardıktan sonra donup kalmaz; sıfır başlangıç hızıyla (`rampa(0) = 0`) belli belirsiz bir nefes alma başlar:

| Parametre | Değer / Formül | Açıklama |
|---|---|---|
| Devreye giriş rampası | `rampa(τ) = 1 - exp(-τ / 2.2)` | Varıştan süzülmeye kesintisiz `C¹` devir |
| Yavaş yaklaşma (`Δz`) | `min(0.072, 0.0052 * (τ - 2.2 * rampa(τ)))` | ~15 sn içinde en çok `+%7,5` dingin yaklaşma |
| Yatay mikro salınım (`Δu`) | `0.0052 * rampa(τ) * sin(0.24 * τ + φ)` | ~26 sn periyotlu belli belirsiz yatay nefes |
| Dikey mikro salınım (`Δv`) | `0.0038 * rampa(τ) * cos(0.19 * τ + φ)` | ~33 sn periyotlu belli belirsiz dikey nefes |
| Duraklatma freni | `zamanHizi` `6.5 s⁻¹` üstel sönümle `1 → 0` | Duraklatınca ani kilitlenme yerine 0,45 sn’de yumuşak duruş |
| Adım atlama | Başlangıç = o anki canlı `(u, v, z)` | `Önceki`/`Sonraki` yarı yolda basılsa bile sıçrama olmaz |

### 5. Ayrıntı ışığı zarfı ve Hareketi azalt

- **Ayrıntı ışığı opaklığı:** Kamera yolun `%68`’ini geçince doğar (`oran = clamp((gecen / T_gecis - 0.68) / 0.45, 0, 1)`, smoothstep `3p² - 2p³`). Denetimler açılınca `%55`’e çekilir; `acilis`, `anlati`, `sessiz`, `kapanis` adımlarında `0`’dır. Kutunun ekrandaki piksel koordinatı canlı kameradan hesaplandığı için ışık süzülmeyi gecikmesiz izler.
- **Hareket azaltılınca (`accessibilityReduceMotion`):** Kayma, yakınlaşma animasyonu ve süzülme tamamen kapalıdır (`0`). Yerine **çift `Image` katmanlı `0,90 sn` `cubic-bezier(0.4, 0, 0.2, 1)` çapraz geçiş** (cross-dissolve) uygulanır — bugünkü gibi siyaha düşüp geri gelmez.
- **Cümle ve kelime zamanlaması:** Uzun açıklamalar cümlelere bölünür (en çok 2 satır). Sesli kipte Swift’te `AVSpeechSynthesizerDelegate` `speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:)` kancasıyla (Yön 3’te) konuşulan kelime birebir parlatılır; sessiz kipte karakter sayısına göre `DinlemeKurallari.harfHizi` ile akar.

---

## Üç tasarım yönü

### Yön 1 — Sinema Odası ([`yon-1.html`](yon-1.html))

**Karakteri:** *En saf sinema deneyimi; tablo bütün ekranı kaplar, arayüz neredeyse yok olur.*

- **Altyazı:** Kutusuz sinema yazısı (`Newsreader 19 px`, yumuşak alt perde üstünde), üstünde cümle düzeninde pirinç ayrıntı adı.
- **Ayrıntı ışığı:** Geniş, tüylü eliptik **galeri spotu / çevresel vinyet** (`Gece %34`, `Gündüz %24`); hiçbir çizgi veya halka yok.
- **İlerleme izi:** En üstte `2,5 px` inceliğinde sürekli adım çizgisi (geçenler yeşil, süren pirinç).
- **Denetimler (`3,5 sn` sonra kaybolur):** Üstte `×`, evre + eser adı ve açılır `5 dk ⌄` cam menüsü; altta tıklanabilir evre şeridi (`Açılış · Anlatı · Ayrıntılar · Sessiz · Kapanış`) ve yüzen tek cam kapsül (`Ses`, `Önceki`, `Duraklat/Sürdür`, `Sonraki`, kalan süre).
- **Görüntüler:** [Başlangıç · Gece](goruntuler/yon-1-baslangic-gece.png) · [Anlatım (gizli) · Gece](goruntuler/yon-1-anlatim-gece.png) · [Denetimler açık · Gece](goruntuler/yon-1-denetimler-gece.png) · [Bitiş · Gece](goruntuler/yon-1-bitis-gece.png) · [Anlatım · Gündüz](goruntuler/yon-1-anlatim-gunduz.png)

---

### Yön 2 — Müze Defteri · Fenerli Bakış ([`yon-2.html`](yon-2.html))

**Karakteri:** *Sanat monografisi hassasiyeti: mimari pirinç köşe nişanları ve açılıp kapanan tek cam kurdele.*

- **Başlangıç / Bitiş:** Tablo üst yarım galeri duvarında ince gölgeli tam çerçeve olarak asılı durur; altta `TASARIM_DILI.md`’deki **2 px pirinç alt çizgili süre seçimi** (`3 dk · 5 dk · 10 dk`) ve `Başla` hapı bulunur.
- **Altyazı ve denetimler (`4,0 sn` sonra kapanır):** Altta dar, hafif buzlu **yüzen cam kurdele** (ayrıntı adı yanında pirinç nokta + 2 satır `Newsreader 17,5 px`). Ekrana dokununca ayrı bir kutu çıkmaz; aynı kurdele aşağı doğru yumuşakça genişleyip oynatma düğmelerini içine alır, üstte `3 · 5 · 10` cam hap belirir.
- **Ayrıntı ışığı:** Ayrıntıyı dört köşeden fısıldayan **`14 px` ince pirinç L-nişanları** (`1,5 px`, yumuşak parıltı) + hafif `%20` çevresel peçe.
- **İlerleme izi:** Kurdelenin hemen altında **iplik ve boncuk izi** (`◆` açılış/kapanış, `•` ayrıntılar, `—` sessiz bakış).
- **Görüntüler:** [Başlangıç · Gece](goruntuler/yon-2-baslangic-gece.png) · [Anlatım (gizli) · Gece](goruntuler/yon-2-anlatim-gece.png) · [Denetimler açık · Gece](goruntuler/yon-2-denetimler-gece.png) · [Bitiş · Gece](goruntuler/yon-2-bitis-gece.png) · [Anlatım · Gündüz](goruntuler/yon-2-anlatim-gunduz.png)

---

### Yön 3 — Canlı Ses · Kelime Akışı ([`yon-3.html`](yon-3.html))

**Karakteri:** *Sesli rehber odaklı, lirik kelime vurgusuyla okumayı çabasızlaştıran atmosferik yön.*

- **Altyazı:** Kutusuz, geniş `Newsreader 20 px` **kelime kelime aydınlanan altyazı** (henüz söylenmemiş kelimeler sakin `%36`, geçenler `%84`, o an söylenen kelime tam parlaklıkta ve ince pirinç alt çizgiyle). Üstünde konuşurken hafifçe nefes alan 3 çubuklu fısıltı ses izi.
- **Ayrıntı ışığı:** Yumuşak chiaroscuro iris (`%28` çevresel karartma) + çizgisiz, yavaşça nefes alan (`5,6 sn`) sıcak altın atmosfer halesi.
- **İlerleme izi:** Ekranın en dibinde `2,5 px` parçalı evre rayı.
- **Denetimler (`3,5 sn` sonra kaybolur):** Dokununca lirik metin yukarı kayar; altında çerçevesiz açık sinema düğmeleri (`3·5·10`, `‹`, `54 px` cam `Duraklat`, `›`, kalan süre) ve dokunulabilir 5 evre hapı belirir.
- **Görüntüler:** [Başlangıç · Gece](goruntuler/yon-3-baslangic-gece.png) · [Anlatım (gizli) · Gece](goruntuler/yon-3-anlatim-gece.png) · [Denetimler açık · Gece](goruntuler/yon-3-denetimler-gece.png) · [Bitiş · Gece](goruntuler/yon-3-bitis-gece.png) · [Anlatım · Gündüz](goruntuler/yon-3-anlatim-gunduz.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Sinema Odası | Yön 2 · Müze Defteri | Yön 3 · Kelime Akışı |
|---|---|---|---|
| **Altyazı biçimi** | Kutusuz sinema yazısı (cümle cümle) | İnce buzlu cam kurdele (tek kapta genişler) | Kutusuz lirik kelime vurgusu (karaoke) |
| **Ayrıntı vurgusu** | Yalnız yumuşak galeri spotu / vinyet | İnce pirinç L-köşe nişanları + hafif peçe | Chiaroscuro iris + çizgisiz altın hale |
| **İlerleme izi** | Üstte `2,5 px` sürekli çizgi | Altta iplik ve boncuk (`◆ — • • • • — ◆`) | Altta `2,5 px` parçalı ray |
| **Başlangıç düzeni** | Kenardan kenara tablo + alt davet | Üstte çerçeveli tablo + alt çizgili süre | Ortalı davet + kulaklık simgeli hap |
| **Eser görünürlüğü (gizli)** | En yüksek (`~%86` tuval) | Yüksek (altta tek ince cam şerit) | Çok yüksek (`~%84` tuval) |
| **SwiftUI karmaşıklığı** | En yalın | Orta (köşe nişan geometrisi) | Orta (`willSpeakRangeOfSpeechString` bağı) |

---

## Yerel yüksek çözünürlüklü görseller

Üçü de Wikimedia Commons kamu malı arşivinden `3840 px` genişlikte indirilmiştir; ayrıntı koordinatları Sanat Atlası’nın `eser_ayrintilari.json` ve `eser_hikayeleri.json` dosyalarından alınmıştır:

- `gorseller/nedimeler.jpg` (`3840×4420`) — Diego Velázquez, *Nedimeler (Las Meninas)*, 1656 (varsayılan)
- `gorseller/arnolfini.jpg` (`3840×5253`) — Jan van Eyck, *Arnolfini Portresi*, 1434 (dikey oran testi)
- `gorseller/karda-avcilar.jpg` (`3840×2733`) — Pieter Bruegel (Yaşlı), *Karda Avcılar*, 1565 (yatay oran testi)

Tarayıcıda herhangi bir `yon-*.html` dosyasını açtığınızda üstteki önizleme çubuğundan eseri, durumu, Gece/Gündüz temasını ve **Tam hareket / Hareketi azalt** kipini anında değiştirebilir; ekran içindeki **Altyazı / Sesli** düğmesiyle tarayıcının Türkçe ses sentezleyicisini (`speechSynthesis`) deneyebilirsiniz.

---

## Doğrulama özeti

- Bütün `15` ekran görüntüsü `390×844` @ `deviceScaleFactor: 2` (`780×1688 px`) olarak çekildi ve tek tek incelendi.
- Tüm durumlarda yatay taşma yok (`scrollWidth = 390`).
- Tüm görünür etkileşimli düğmelerde dokunma hedefi `≥ 44 px`.
- Her ekranda tek dolu hap düğme, büyük harfli etiket yok, dış bağlantı yok, uygulama koduna dokunulmadı.

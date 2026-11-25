# Galeri · Başyapıtlar — İkinci Tasarım Denemesi

Galeri sekmesinin **Başyapıtlar** ekranı (`NoraSanat/Ekranlar/Galeri/BasyapitListesi.swift`, `YakinOkuma.swift`, site karşılığı `js/ekranlar/gozat.js` `basyapitListesi`, `js/basyapit.js`, `js/ekranlar/basyapit.js`) için birbirinden ve bugünkü düzenden kökten farklı üç yeni tasarım yönü.

Önceki denemenin (`neon/galeri-basyapit-konu-tasarim`, PR #59) geri bildirimi doğrudan merkeze alındı:
- Bugünkü ekranın ufak rötuşlarla tekrarı (eski Yön 1) yapılmadı.
- **Çalış Yön 4**’ün (boncuklu takvim, sol omurgalı dönem yolu, tamamlanma tikleri) ve **Paylaşım Kartı Yön 4**’ün (statik odak çerçevesi + yanda sabit kırpım) kopyası (eski Yön 2) tamamen bırakıldı.
- Bunun yerine **Başyapıtlar ekranının kendi işine özgü** üç yeni keşif fikri kuruldu: **264 başyapıtı merakla keşfetmek, esere girmeden içinde ne beklediğini sezmek, tek dokunuşla yakın okumaya girmek ve 9 dönem arasında gezinmek.**

Üç dosya da `390×844` iPhone genişliğinde, yerel kamu malı görseller (`gorseller/`, `1280 px`), uygulamanın kendi dönem desen karoları (`NoraSanat/Ekranlar/Galeri/Desenler/desen-*@3x.png`) ve değişken yazı tipleriyle (`NoraSanat/YaziTipleri/`) tamamen **internetsiz** çalışır; hiçbir dış adres içermez. Üst çubuktan **Gece / Gündüz** değiştirilebilir; tüm etkileşimler ve hareketler HTML içinde canlıdır.

İki temada tam sayfa PNG çıktıları (`deviceScaleFactor: 2`, `780 px` en) [`goruntuler/`](goruntuler/) klasöründedir.

---

## Önemli veri notu: “okundu” kaydı ve yeni özellik ayrımı

Uygulama bugün bir başyapıtın okunduğunu **kaydetmiyor** (`localStorage['sanat-atlasi:ilerleme']` içinde başyapıt okuma geçmişi yok). Bu yüzden önceki denemede yapılan *“14 başyapıt okundu / sıradaki okuma”* varsayımı bilerek bırakıldı ve üç yön de **okundu kaydına dayanmadan**, merak ve keşif üzerine kuruldu:

| Yön | Okundu kaydı gerekir mi? | Bugünkü veriyle ne kadar çalışır? | Gerekirse yeni veri / özellik |
|---|---|---|---|
| **Yön 1 · Büyüteçten Tabloya** | **Hayır** | **%100 bugünkü veriyle çalışır** (`basyapitlar.json`, `eser_ayrintilari.json`, `eser_hikayeleri.json`, `basyapit-dersleri/`). | Yalnızca isteğe bağlı 1 cümlelik merak sorusu eklenebilir; yoksa ayrıntının `metin` ilk cümlesi doğrudan kullanılır. |
| **Yön 2 · Sorular ve İzler** | **Hayır** | Zaman spektrumu, 9 dönem kataloğu, süreler ve rozetler bugünkü veriden gelir. | **Yeni içerik verisi gerekir:** Karşılaştırmalı soru çiftleri ve 4 merak yolu için küçük bir kürasyon dosyası (ör. `data/basyapit_yollar.json`; isterse kısmen `DERS.json` içindeki `karsilastirma_onerileri`nden beslenebilir). |
| **Yön 3 · Haftanın Başyapıtı ve Sergi Destesi** | **Hayır** | **%100 bugünkü veriyle çalışır.** “Bu haftanın başyapıtı” tıpkı günün tablosu gibi deterministik hafta sırasıyla (`haftaNo`) seçilir; “İçinde ne var?” sekmeleri gerçek hikâye/ayrıntı/bölüm verisinden, deste ise 264 eserden üretilir. | İleride *“okuduklarımı destede sona at”* istenirse bu yeni bir `Ilerleme` alanı (`okunanBasyapitlar`) olarak sonradan eklenebilir — ekran onsuz tam çalışır. |

---

## Ortak temel, gerçek veri ve görseller

- **Korunan Galeri çerçevesi:** Üstte `Galeri`, cam arama hapı (`Sanatçı, eser ara`), kalp düğmesi ve cam kapta bölüm sekmeleri (`Akımlar · Başyapıtlar [seçili] · Konular · Zaman`); altta 5 sekmeli buzlu cam alt çubuk; eser rozetleri (`Hikâye`, `n ayrıntı`); tüm etkileşimli hedefler en az `44 px`; `390 px` genişlikte sıfır yatay taşma (`scrollWidth = 390`); Gece ve Gündüz temaları.
- **Üç katmanlı zemin (`TASARIM_DILI.md`):** Kömür (`#121110`) / sıcak kâğıt (`#ece8e1`) + `3×3 px` nokta dokusu, seçili tablonun iki renginden yumuşak hale, ve dönemin `96×96` desen karosu (Gece `%4`, Gündüz `%4,5`). Eser ya da dönem değiştiğinde hale ve desen yumuşakça yeni döneme geçer.
- **Gerçek 264 başyapıt ve 9 dönem (`js/harita.js` `BOLGELER`, `data/basyapitlar.json`):**
  - Orta Çağ `12` · Rönesans `98` · Barok `43` · Klasisizm ve Geç Barok `14` · Rokoko ve Neoklasisizm `20` · Romantizmden Realizme `34` · Empresyonizm `14` · Post-Empresyonizm ve Sembolizm `18` · Modern sanat `11` (**toplam 264**).
  - Gerçek **4 hikâyeli başyapıt** (*Elçiler*, *Nedimeler*, *Holofernes’in Kafasını Kesen Judith*, *Medusa’nın Salı*), **264 rehberli inceleme** (`4–6` ayrıntı noktası ve gerçek `[x, y, w, h]` koordinatları) ve **106 derin ders** (`~1–2 dk` yakın okuma + `7–9 dk` derin ders, `okumaDakikasi` 180 sözcük/dk hesabıyla).
- **22 farklı kamu malı başyapıt (`gorseller/`, Wikimedia Commons `1280 px`, sıfır dış adres, sıfır tekrar):**
  1. Giotto di Bondone — *Ağıt* (`by-agit.jpg`)
  2. Gentile da Fabriano — *Müneccimlerin Tapınması* (`by-muneccimler.jpg`)
  3. Jan van Eyck — *Arnolfini Portresi* (`by-arnolfini.jpg`)
  4. Sandro Botticelli — *Venüs’ün Doğuşu* (`by-venus.jpg`)
  5. Leonardo da Vinci — *Mona Lisa* (`by-monalisa.jpg`)
  6. Hans Holbein (Genç) — *Elçiler* (`by-elciler.jpg`)
  7. Parmigianino — *Uzun Boyunlu Meryem* (`by-uzunboyunlu.jpg`)
  8. Artemisia Gentileschi — *Holofernes’in Kafasını Kesen Judith* (`by-judith.jpg`)
  9. Rembrandt van Rijn — *Gece Devriyesi* (`by-gecedevriyesi.jpg`)
  10. Diego Velázquez — *Nedimeler* (`by-nedimeler.jpg`)
  11. Johannes Vermeer — *İnci Küpeli Kız* (`by-incikupeli.jpg`)
  12. Nicolas Poussin — *Arkadya’da Ben de Varım* (`by-arkadya.jpg`)
  13. Jean-Honoré Fragonard — *Salıncak* (`by-salincak.jpg`)
  14. Jacques-Louis David — *Marat’nın Ölümü* (`by-marat.jpg`)
  15. Caspar David Friedrich — *Sis Denizi Üzerinde Gezgin* (`by-gezgin.jpg`)
  16. Théodore Géricault — *Medusa’nın Salı* (`by-medusa.jpg`)
  17. Jean-François Millet — *Başak Toplayanlar* (`by-basak.jpg`)
  18. Claude Monet — *İzlenim, Gün Doğumu* (`by-izlenim.jpg`)
  19. Katsushika Hokusai — *Kanagawa Açıklarında Büyük Dalga* (`by-dalga.jpg`)
  20. Vincent van Gogh — *Yıldızlı Gece* (`by-yildizligece.jpg`)
  21. Edvard Munch — *Çığlık* (`by-ciglik.jpg`)
  22. Gustav Klimt — *Öpücük* (`by-opucuk.jpg`)

Her yönün varsayılan tam sayfa görünümünde tek bir tablo bile iki kez yinelenmez (`dupes = 0`).

---

## Yön 1 — Büyüteçten Tabloya (`yon-1.html`)

**Büyük fikir:** *Önce gözünü yakalayan tek bir ayrıntıya bak, sonra bir adım geri çekilip bütün tabloyu gör.*

- **Canlı mercek sahnesi (mikrodan makroya geçiş):** Ekran, bir başyapıtın küçültülmüş kapağıyla değil, `eser_ayrintilari.json` koordinatlarıyla (`kirpim()`) alınmış tek bir ayrıntının yakın planıyla açılır — burada *Elçiler*’deki **Anamorfik kurukafa** ve tek satırlık soru (*“Yerdeki bu uzun eğri gölge aslında ne?”*). Kullanıcı **`Tabloya uzaklaş`** cam düğmesine (ya da resmin üstüne) dokunduğunda, kamera akıcı bir geçişle (`0.85s cubic-bezier(0.22, 1, 0.36, 1)`) o ayrıntıdan bütün tabloya doğru geri çekilir; ayrıntının tablodaki yeri ince bir çerçeveyle, diğer 5 ayrıntıysa küçük noktalarla belirir. Alttaki 6 ayrıntı hapından herhangi birine dokununca kamera aynı tablo içinde o noktaya kayar. Ekrandaki tek dolu düğme (`Yakın okumayı aç`) tek dokunuşla içeri alır.
- **“Gözün hangisine takıldı?” — 3×2 Ayrıntı Pencereleri:** Alışılagelmiş poster ızgarası yerine 6 farklı başyapıttan yakın kırpılmış 6 merak penceresi (*Tek mum*, *Aynadaki çift*, *Uçan ayakkabı*, *İnci*, *Servinin alevleri*, *Kızıl gökyüzü*). Eser adları gizlidir; dokunulan ayrıntı anında yukarıdaki canlı merceğe taşınıp tablosuna açılır.
- **Ayrıntı imzalı 9 dönem fihristi:** Alt çizgili 9 dönem sekmesi ile `Tümü / Hikâyeli · 4 / Derin dersli · 106` süzgeçlerinin altında, her eserin yalnız adı değil **içindeki ilk 3 ayrıntının adları** (`Meryem ve İsa · Ağlayan melekler · Kuru ağaç`), okuma ve varsa derin ders süresi görünür. Satıra dokununca yerinde açılarak özeti gösterir; istenirse doğrudan `Mercekte gör` veya `Yakın okumaya gir` seçilir.
- **En güçlü olduğu yer:** Sıfır yeni veri ve sıfır okundu kaydıyla %100 bugünkü veriden en şaşırtıcı, uygulamaya özgü deneyimi üretmesi; *“içeride ne bekliyor?”* sorusunu kelimelerden önce doğrudan gözle yanıtlaması.
- **Ödün:** İlk bakışta üst sahne bir ayrıntıya odaklandığı için tablonun bütün kompozisyonu tek dokunuş uzağındadır (`Tabloya uzaklaş`).
- **`TASARIM_DILI.md`’den ayrılışlar:**
  - *Canlı kırpım ↔ tam tablo geçişi ve mercek köşe nişangâhı:* Tasarım dilinde kırpım yalnız okuma metni içinde durağan kutudur; burada keşif ekranının kahramanına taşınıp dokununca tam tabloya açılan bir merceğe dönüştürüldü. Gerekçe: 264 başyapıtın ayırt edici gücü olan rehberli ayrıntıları daha kapıdayken hissettirmek.
  - *3×2 kare ayrıntı pencereleri:* Standart 4:5 poster şeridi yerine 3 sütunlu küçük kare kırpım mozaiği kullanıldı; çünkü yatay kaydırma eklemeden aynı ekranda 6 merak kapısı açar.
- **Görüntüler:** [Gece (Yakın)](goruntuler/yon-1-gece.png) · [Gece (Tabloya uzaklaşılmış)](goruntuler/yon-1-uzak-gece.png) · [Gündüz](goruntuler/yon-1-gunduz.png)

---

## Yön 2 — Sorular ve İzler (`yon-2.html`)

**Büyük fikir:** *Sanat tarihini raf raf değil, yüzyılları birbirine bağlayan bir küratör sorusuyla keşfet.*

- **“Bu akşamın sorusu” — Çift Tablo Diyaloğu:** Tek bir öne çıkan kart yerine, birbirinden yüzyıllarca uzakta ama aynı fikri kuran **iki başyapıt yan yana** tek sahnede buluşur: örneğin **`Aynada kim var?`** — *Arnolfini Portresi* (`1434`) ve *Nedimeler* (`y. 1656`), aralarında `222 yıl` köprüsüyle. İki tablodan hangisine dokunulursa odak ve tek dolu düğme (`Nedimeler’i aç` / `Arnolfini Portresi’ni aç`) o esere döner. Hemen altındaki 2×2 soru seçicisiyle (`Aynada kim var?`, `Karanlıkta parlayan`, `Havada asılı bir an`, `Bize bakan yüzler`) 4 farklı diyalog arasında geçilir; zemin halesi ve dönemi yeni çifte uyar.
- **“Nereden başlamak istersin?” — Merak Yolları:** 4 tematik yol (`Gizli ayrıntılar`, `Hikâyeli 4 başyapıt`, `Sırtı dönükler`, `Işık ve gece`). Her satırda eserin rozetleri ve okuma süresinin üstünde, **o soruya verdiği tek satırlık gerçek ipucu** `Newsreader` eğik yazıyla yer alır (*“Kızıl göğün sol üstünde Munch’un kurşun kalemle yazdığı gizli not durur”*).
- **Oransal Zaman Spektrumu (9 dönem):** Alışılagelmiş düz sekme şeridine ek olarak, 264 başyapıtın 9 döneme **gerçek ağırlığıyla** bölünmüş yatay bir ışık çubuğu yer alır (Rönesans `98` en geniş dilim, Barok `43` ikinci, Modern `11` ince uç). Her dilim etkileşimli bir 44 px dönem süzgecidir; seçilince pirinçle ışıldar, zemin desenini değiştirir ve aşağıdaki 9 dönemlik editoryal kataloğu süzer.
- **En güçlü olduğu yer:** 264 eser karşısında “hangisinden başlasam?” kararsızlığını en doğal biçimde çözmesi; aynı ekranda hem tematik hem kronolojik gezinmeyi birbirini ezmeden sunması.
- **Ödün:** Karşılaştırmalı soru çiftleri ve merak yolları için kısa bir kürasyon verisi (`data/basyapit_yollar.json`) hazırlanması gerekir.
- **`TASARIM_DILI.md`’den ayrılışlar:**
  - *İki tablolu diyalog kahramanı ve `222 yıl` köprüsü:* Tek kapak kartı yerine yan yana iki dikey pencere kullanıldı; gerekçe, iki eserin arasındaki fikrî bağı tek bakışta kurmak.
  - *Oransal Zaman Spektrumu:* Yalnızca yazılı dönem sekmeleri yerine üstüne 9 dönemlik oransal genişlikte bir dağılım çubuğu eklendi; gerekçe, Rönesans’ın (98) ve Barok’un (43) katalogdaki gerçek ağırlığını metinsiz, mimari bir şeritte göstermek (boncuk takvimi kullanılmadan).
- **Görüntüler:** [Gece](goruntuler/yon-2-gece.png) · [Gündüz](goruntuler/yon-2-gunduz.png)

---

## Yön 3 — Haftanın Başyapıtı ve Sergi Destesi (`yon-3.html`)

**Büyük fikir:** *Üstte yavaş okuma için haftalık tek bir derin vitrin, ortada parmakla çevrilen dokunsal 264’lük sergi fişleri destesi, altta hızlı müze fihristi.*

- **“Bu haftanın başyapıtı” — Katmanlı okuma önizlemesi:** Dönen 4’lü carousel yerine her hafta tek bir başyapıt (*Nedimeler · 48. hafta*) kenardan kenara eriyen sakin bir kapakla açılır. Resmin hemen altında, esere **girmeden içinde ne beklediğini** 3 canlı sekmede gösteren **`İçinde ne var?`** kutusu bulunur: **`Hikâye · 10 kişi`**, **`5 ayrıntı`** ve **`Okuma akışı`** (`~2 dk`). Altında ekrandaki tek dolu düğme (`Yakın okumaya gir`) yer alır.
- **Dokunsal Sergi Destesi (“Sürükle ya da çevir”):** 264 eseri uzun listelerde kaydırmak yerine, 3 katmanlı fiziksel derinliğe sahip bir kart destesi sunulur. Üstte `Seçki · 264`, `Hikâyeli · 4`, `Derin dersli · 106` ve `Kısa okuma · ~1–2 dk` süzgeçleri desteyi anında daraltır. Öndeki kart sola/sağa sürüklenebilir ya da **`Sonraki`** cam düğmesiyle çevrilebilir; kart eğilip süzülerek arkaya geçer, altındaki başyapıt öne yükselir ve sayfanın renk halesi yeni tabloya döner.
- **9 dönemlik kompakt müze fihristi:** Destenin altında, hızlı tarama için `TASARIM_DILI.md` gruplu listesinde tek satırlık zarif müze fihristi bulunur: `54×54` kare tablo, başlık, sanatçı·yıl ve sağda tek bakışta `Hikâye` / `n ayrıntı` ile okuma ve derin ders süresi.
- **En güçlü olduğu yer:** Hem dingin bir haftalık okuma ritüeli kurması, hem de dokunsal kart destesiyle rastgele keşfi oyunsu ama ağırbaşlı hâle getirmesi; üstelik %100 bugünkü veriyle çalışması.
- **Ödün:** Üst üste kart destesi ve alttaki fihrist iki ayrı keşif ritmi sunar; destedeki kartı çevirmek için yatay hareket gerekir (dokunmatik sürüklemeye ek olarak tek dokunuşluk `Sonraki` düğmesi konuldu).
- **`TASARIM_DILI.md`’den ayrılışlar:**
  - *Kart içi 3 sekmeli “İçinde ne var?” önizleme kutusu:* Kapak kartında yalnızca başlık ve tek satır yerine etkileşimli 3 mini sekme eklendi; gerekçe, hikâye + ayrıntı + okuma akışı bilgisini ekrana yığmadan tek dokunuşla açmak.
  - *3 katmanlı sürüklenebilir Sergi Destesi:* Standart yatay şerit yerine üst üste derinlikli kart destesi kullanıldı; gerekçe, 264 eseri ekranda 20 küçük kutuya sıkıştırmadan tek seferde bir başyapıtla yüz yüze gelmek.
- **Görüntüler:** [Gece](goruntuler/yon-3-gece.png) · [Gündüz](goruntuler/yon-3-gunduz.png)

---

## Yön 4 — Büyüteçten Tabloya · Sade (`yon-4.html`) *(Seçilen yönün sadeleştirilmiş sürümü)*

Emre’nin **Yön 1**’i seçip *“ekran çok kalabalık oluyor, daha sade olsun”* geri bildiriminden sonra, Yön 1’in özünü koruyup `TASARIM_DILI.md`’nin **“Az şey, çok boşluk”** ilkesine damıtılmış sürüm.

- **Korunan öz:**
  - Ekran, `eser_ayrintilari.json` koordinatlarıyla (`kirpim()`) yakın kırpılmış tek bir ayrıntıyla (*Elçiler* · Anamorfik kurukafa) açılır; tek soru cümlesi merak uyandırır ve **`Tabloya uzaklaş`** cam düğmesiyle kamera akıcı biçimde bütün tabloya geri çekilir. Uzaklaşınca ayrıntının tablodaki yeri ince bir odak çerçevesiyle, diğer 5 ayrıntıysa doğrudan tablonun üstünde cam noktalarla belirir.
  - Ekranda tek dolu düğme (**`Yakın okumayı aç`**) ve altında **`Gözün hangisine takıldı?`** ayrıntı pencereleri yer alır.
  - Sıfır okundu kaydı, **%100 bugünkü veriyle** çalışır.
- **Neyi neden çıkardık?**
  - **Açılış kartının dış kutusu, üst yazısı ve tablo üstü rozet kalabalığı kaldırıldı:** Resim artık doğrudan 3 katmanlı zeminin üstünde tek başına duruyor (kutu içinde kutu ve ara çizgi yok). `Hikâye · 6 ayrıntı · ~2 dk · +7 dk ders` bilgisi tek sakin satır olarak **`Yakın okumayı aç`** düğmesinin alt yazısına taşındı; böylece tablonun köşeleri tamamen temiz kaldı ve ilk ekranda tablo + soru + eser adı + tek dolu düğme rahatça sığdı.
  - **6 ayrıntı hapı listesi kaldırıldı:** Ayrıntılar zaten `Tabloya uzaklaş` deyince tablonun kendi üzerinde noktalar hâlinde beliriyor; kart altında tekrarlanması gereksiz görsel gürültü ve dikey kalabalık yaratıyordu.
  - **“Gözün hangisine takıldı?” 6’dan 4 büyük pencereye indirildi (2×2):** Kart kutuları, büyüteç ikonları ve altındaki ayrıntı sayıları çıkarıldı; yalnızca büyük kırpım (*Aynadaki çift*, *Tek mum*, *Uçan ayakkabı*, *Servinin alevleri*) ve altında ayrıntının adı bırakıldı.
  - **Dönem dönem uzayan 15 satırlık liste ve içerik süzgeç hapları kaldırıldı:** Yerine 9 dönem sekmesi ve seçili dönemin eserlerini gösteren tek sakin yatay şerit konuldu; altta tek satırlık **`Bütün başyapıtlar · 264 ⌄`** açıcısı başlangıçta kapalı durur (dokununca yerinde açılır).
  - **Sayfa boyu yarıdan fazla kısaldı:** Yön 1’de `3960 px` (`4,69 ekran`) olan sayfa, Yön 4’te **`1862 px` (`2,21 ekran` — ilk ekrandan sonra ~1,2 ekran)** uzunluğa indi; bölümler arası boşluk `44 px`’e çıkarıldı ve her bölümde en çok bir başlık ile bir alt yazı bırakıldı.
- **Görüntüler:** [Gece (Yakın)](goruntuler/yon-4-gece.png) · [Gece (Tabloya uzaklaşılmış)](goruntuler/yon-4-uzak-gece.png) · [Gündüz](goruntuler/yon-4-gunduz.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Büyüteçten Tabloya | Yön 2 · Sorular ve İzler | Yön 3 · Haftanın Başyapıtı ve Deste | Yön 4 · Büyüteçten Tabloya (Sade) |
|---|---|---|---|---|
| **Keşif mekaniği** | Ayrıntıdan bütüne canlı mercek + 3×2 pencere | Çift tablo diyaloğu + merak yolları | Haftalık derin vitrin + sürüklenebilir deste | Kutusuz canlı mercek + 2×2 büyük pencere |
| **Girmeden sezme** | Gerçek kırpım + tablo içi noktalar + ayrıntı adları | Karşılaştırma cümlesi + 1 satırlık sır ipucu | 3 sekmeli “İçinde ne var?” + fişte 1 cümle sır | Yakın kırpım + tek soru + düğmede özet satırı |
| **Dönem gezinmesi** | 9 dönem sekmesi + uzun dönem fihristi | 9 dönemlik oransal Zaman Spektrumu | 9 dönem sekmesi + hızlı müze fihristi | 9 dönem sekmesi + tek yatay şerit + açılır dizin |
| **Sayfa uzunluğu (`390 px`)** | `3960 px` (`4,7 ekran`) | `4286 px` (`5,1 ekran`) | `3554 px` (`4,2 ekran`) | **`1862 px` (`2,2 ekran`)** |
| **Bugünkü veriyle uyum** | **%100 hazır** | Kürasyon dosyası gerekir | **%100 hazır** | **%100 hazır** |
| **Okundu kaydı bağımlılığı** | Yok | Yok | Yok | Yok |
| **Doğrulama (`390 px`, @2x)** | `scrollW=390`, 22 eşsiz eser, 0 tekrar, ≥44 px | `scrollW=390`, 22 eşsiz eser, 0 tekrar, ≥44 px | `scrollW=390`, 20 eşsiz eser, 0 tekrar, ≥44 px | `scrollW=390`, 22 eşsiz eser, 0 tekrar, ≥44 px |

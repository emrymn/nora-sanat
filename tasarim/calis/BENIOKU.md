# Çalış Ana Ekranı — Tasarım Yönleri

Çalış sekmesinin ana ekranı (`CalisAnaGorunumu.swift` / `#/pekistir`) için üç farklı yeniden tasarım önerisi. Bütün dosyalar `390×844` iPhone genişliğinde, yukarıdan aşağı kaydırılan tam sayfa olarak hazırlanmıştır; yerel [`tablo.jpg`](tablo.jpg) (`tasarim/paylas-karti/tablo.jpg` kopyası) ve `NoraSanat/YaziTipleri/` altındaki değişken yazı tipleriyle internetsiz açılabilir. Her HTML dosyasının üst çubuğundan **Gece / Gündüz** teması ve kapak yakınlaşmasının **Canlı / Başta / Ayrıntıda / Geri dönüşte** anları anında değiştirilebilir.

İki temada (`deviceScaleFactor: 2`, `780 px` en) tam sayfa çıktıları ve kapak yakınlaşmasının üç karesi [`goruntuler/`](goruntuler/) klasöründedir.

## Ortak temel ve tasarım dili uyumu

Üç yön de Sanat Atlası'nın tasarım diline (`TASARIM_DILI.md`) ve uygulamanın tema sistemine (`NoraSanat/Kabuk/Tema.swift`, `TemaRenkleri.swift`) sıkı bağlıdır:

- **Üç katmanlı zemin:** Kömür / sıcak kâğıt zemin (`--bg`) ile ince nokta dokusu (`--doku`, `3×3 px`), tablonun iki baskın renginden (kobalt mavi sol üst, sıcak altın sağ alt) yumuşak köşe halesi (`TabloRenkleri`), ve Post-Empresyonizm döneminin sarmal-göz karosu (`96×96`, Gece %3,8 / Gündüz %4,4).
- **Yazı üçlüsü:** Sayfa ve kart başlıklarında **Bodoni Moda** (500, `−0,01 em`), davet metninde **Newsreader** (`17,5–18 px`), üst yazılar ve arayüzde **Archivo** (`13–16 px`).
- **Kapaktaki 16 sn yakınlaşma döngüsü (`kapak-yuru`):** `CalisAnaGorunumu.swift`'teki `KapakYuruyusu` ve `css/app.css` İş 191 ile birebir aynı zamanlama (`16s`, `cubic-bezier(0.65, 0, 0.35, 1)`, `transform-origin: 50% 40%`): `0–8%` bütün tablo → `22–38%` ilk ayrıntı (`translate(-10%, 6%) scale(1.8)`) → `50–58%` bütüne dönüş → `72–90%` ikinci ayrıntı (`translate(14%, -4%) scale(1.9)`) → `100%` başlangıç. `prefers-reduced-motion: reduce` altında durur. Görüntülerdeki üç kare: **Başta** (`0 sn`, `1,0×`), **Ayrıntıda** (`4,8 sn`, `1,8×`), **Geri dönüşte** (`7,0 sn`, `1,4×`).
- **"Yapma" kurallarına sıkı uyum:**
  - Bölüm numarası, sıra numaralı adım halkası ve `"3 / 5"` türü sayaç yok (adımlar `3 px` ince çizgilerle: biten yeşil `--right`, süren pirinç `--pirinc`; devam alt yazısı `"2 özellik kaldı"`).
  - Büyük harfli, harf aralıklı etiket yok; bütün üst yazılar cümle düzeninde, `13 px`, yarı kalın, pirinç (`"Bugünün dersi"`, `"Günlük tekrar"`, `"Dersler"`, `"Başka turlar"`, `"Önümüzdeki 14 gün"`).
  - Ekranda **tek dolu düğme** var: Bugünün dersindeki birincil hap düğme (`"Öğren adımına devam"`). Günlük tekrar ve diğer bütün eylemler cam ok, ince çizgi ya da düz yüzeydir.
  - Sol kenarlı renkli kutu, emoji, renk geçişli büyük zemin ve belirgin desen yok; tüm dokunma hedefleri en az `44 px`, `390 px` genişlikte yatay taşma yok.
- **Gerçekçi Türkçe içerik:** Üç yönde de aynı örnek veri kullanılır: *Post-Empresyonizm* (Vincent van Gogh, *Yıldızlı Gece*, 1889; `6 sanatçı · Konu 11–13`, `Konu 13'tesin`), `Gör` tamam / `Öğren` sürüyor / `Ayırt et` bekliyor / `Harita` kilitli; Günlük tekrar `14 kart` (`Yaklaşık 5 dk · 6 tekrar · 5 pekiştirme · 3 yeni`); 4 açık ders (`Post-Empresyonizm`, `Empresyonizm`, `Gerçekçilik`, `Romantizm`) + kilitli sonraki ders (`Sembolizm · Konu 14'te açılır`); 5 ek tur (`Hatalarım · 4`, `Döneme göre`, `Bölüm turu · 12`, `Konu turu`, `Karşılaştır`); Yolculuk bağlantısı ve 14 günlük yük grafiği (`Bugün 14 · yarın 6 · 52 sanatçı`).

---

## Yön 1 — Müze defteri (`yon-1.html`)

**Yaklaşım:** Bugünkü Çalış ekranının görsel karmaşasını ayıklayıp `TASARIM_DILI.md`'deki **tek akış** ve **gruplu liste** ilkelerine oturtan en sakin, editoryal evrim.

- **Neden bu yön?** Mevcut ekrandaki ağır iki sütunlu 4:5 poster ızgarası, kapak üstündeki dolu rozetler ve 220 px'lik hantal tur kutuları yerine nefes alan bir okuma düzeni kurar. Bugünün dersi klasik yuvarlatılmış (`28 px`) kapak kartında açılır; resim üstten kenardan kenara akar, altta yumuşak karartma üstünde başlık oturur ve hemen altında ince `3 px` adım çizgileriyle tek dolu hap düğme gelir. **Günlük tekrar** iki ince ayırıcı arasında kart dışı ferah bir satırda kalır. **Dersler**, tasarım dilinin önerdiği gibi **tek kart içinde gruplu liste** olur (sağda `"Bugün"` pirinç, `"Bitti"` yeşil, `"Sırada"` soluk); böylece hem sayfa kısalır hem bütün dersler tek bakışta taranır.
- **En güçlü olduğu yer:** Günlük kullanımda hız, tarama kolaylığı ve bugünkü SwiftUI yapısından en az maliyetle yüksek nitelik kazanımı.
- **Ödün:** Dersler listesinde her dönemin kendi küçük tablosu yerine renkli akım noktası bulunur; görsel vitrin duygusu Yön 2 ve Yön 3 kadar baskın değildir.
- **Görüntüler:** [Gece](goruntuler/yon-1-gece.png) · [Gündüz](goruntuler/yon-1-gunduz.png) · Yakınlaşma: [Başta](goruntuler/yon-1-yakinlasma-1-bas.png) · [Ayrıntıda](goruntuler/yon-1-yakinlasma-2-ayrinti.png) · [Geri dönüşte](goruntuler/yon-1-yakinlasma-3-donus.png)

## Yön 2 — Bugün perdesi (`yon-2.html`)

**Yaklaşım:** Uygulamanın **Bugün** sekmesindeki tam en perde atmosferini Çalış'a taşır: *"Tablo önce gelir."*

- **Neden bu yön?** Ekran açıldığında ilk `368 px` doğrudan kenardan kenara *Yıldızlı Gece*'dir; 16 saniyelik yakınlaşma bir kutunun içine sıkışmak yerine ekranın üst sahnesinde nefes alır ve alt kenarı yumuşakça `--bg` zeminine erir (özellikle Gündüz temasında sıcak kâğıda erime çok doğaldır). Dersin başlığı, adımları ve tek dolu düğme doğrudan zemin üzerinde durur. **Günlük tekrar** buzlu cam yüzeyle ayrılır. **Çalışma masan** bölümünde ikonsuz cam sekme filtresi (`Tümü · Dersler · Başka turlar`) yer alır: **Dersler** yatay kaydırılan bir galeri rafında (sağ kenarda sonraki kartın ucu görünür — Başyapıtlar şeridiyle akraba), **Başka turlar** ise tek kart içinde sade bir gruplu listede toplanır. 14 günlük yük grafiği kutusuz olarak doğrudan zeminde yer alır.
- **En güçlü olduğu yer:** İlk bakışta "sanat müzesi uygulaması" hissini en güçlü veren, Bugün sekmesiyle görsel bütünlüğü en yüksek öneri.
- **Ödün:** Yatay ders rafı açık ders sayısı 6–8'e çıktığında yana kaydırma gerektirir; üstteki durum çubuğu ve başlık, çok açık tonlu kapak tablolarında üst gölgeye (`::before`) bağımlıdır.
- **Görüntüler:** [Gece](goruntuler/yon-2-gece.png) · [Gündüz](goruntuler/yon-2-gunduz.png) · Yakınlaşma: [Başta](goruntuler/yon-2-yakinlasma-1-bas.png) · [Ayrıntıda](goruntuler/yon-2-yakinlasma-2-ayrinti.png) · [Geri dönüşte](goruntuler/yon-2-yakinlasma-3-donus.png)

## Yön 3 — Çerçeveli atölye (`yon-3.html`)

**Yaklaşım:** Paylaşım kartı çalışmasındaki *Müze levhası* dinginliğini ve **birleşik günlük masa** fikrini birleştirir: tablonun üstünde tek bir yazı ya da karartma perdesi bile yoktur.

- **Neden bu yön?** Sanat tarihini çalışan kullanıcı için tablonun fırça darbeleri ve renkleri hiçbir örtünün altında kalmamalıdır. 16 saniyelik yakınlaşma ince iç çerçeveli (`18 px`) temiz bir pencere içinde bir büyüteç gibi çalışır; altında eserin *Newsreader* eğik künyesi ve *Bodoni* dönem başlığı yer alır. **Bugünün dersi** ile **Günlük tekrar**, tek bir günlük kartın iki kademesi (ince ayırıcıyla birleşik) olarak sunulur: kullanıcı sabah açtığında günün iki alışkanlığını tek bütün içinde görür. **Çalışma masan** bölümünde tasarım dilinin `2 px` pirinç alt çizgili metin sekmeleri (`Tümü · Dersler · Başka turlar`) vardır; ders kartlarında resmin üstünde hiçbir rozet veya ok bindirmesi bulunmaz, bütün bilgi resmin altındaki sakin tipografide yer alır. 14 günlük yük grafiği ince mimari çubuk-nokta ritmiyle çizilmiştir.
- **En güçlü olduğu yer:** Tabloya en saygılı (sıfır örtü/karartma), Gündüz temasında basılı sanat kitabı gibi duran, sabah rutinini (ders + tekrar) tek odakta toplayan yaklaşım.
- **Ödün:** İki sütunlu levha ızgarası ve birleşik kart nedeniyle toplam sayfa boyu Yön 1 ve Yön 2'ye göre biraz daha uzundur.
- **Görüntüler:** [Gece](goruntuler/yon-3-gece.png) · [Gündüz](goruntuler/yon-3-gunduz.png) · Yakınlaşma: [Başta](goruntuler/yon-3-yakinlasma-1-bas.png) · [Ayrıntıda](goruntuler/yon-3-yakinlasma-2-ayrinti.png) · [Geri dönüşte](goruntuler/yon-3-yakinlasma-3-donus.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Müze defteri | Yön 2 · Bugün perdesi | Yön 3 · Çerçeveli atölye |
|---|---|---|---|
| Kapak ve 16 sn yakınlaşma | Yuvarlatılmış kart, alt karartma | Kenardan kenara perde, zemine erime | Perdesiz, yazısız çerçeveli levha |
| Günlük tekrar yerleşimi | Kart dışı, iki çizgi arası satır | Ayrı buzlu cam yüzey kartı | Günlük ders kartının alt bandı |
| Dersler listesi | Tek kartta gruplu liste | Yatay galeri rafı (4:5) | Rozetsiz 2 sütunlu levha ızgarası |
| Başka turlar | Üstte Hatalarım + 2×2 kompakt ızgara | Tek kartta gruplu liste | Üstte Hatalarım + 2×2 kompakt ızgara |
| Çalışma masası sekmeleri | Tek akış (sekmesiz) | Cam sekme kabı (ikonsuz) | Pirinç alt çizgili yazı sekmeleri |
| 14 günlük yük grafiği | Yüzey kartında yuvarlak çubuk | Kutusuz, doğrudan zeminde | Yüzey kartında mimari çizgi-nokta |
| Uygulama akrabalığı | Başyapıt yakın okuma & gruplu liste | Bugün sekmesi & Başyapıt şeridi | Müze levhası (PR #54 Yön 1) |
| Toplam sayfa boyu (390 px en) | ~2146 px (en derli toplu) | ~2155 px | ~2329 px |
| SwiftUI geçiş karmaşıklığı | En düşük (doğrudan `CalisAnaGorunumu` sadeleştirmesi) | Orta (üst perde + yatay `ScrollView`) | Düşük–orta (birleşik kart + yeni satırlar) |

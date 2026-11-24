# Paylaşılabilir Eser Kartı — Tasarım Yönleri

Günün tablosunu Instagram hikâyesine (`1080×1920`) ya da mesaja / gönderiye (`1080×1350`) tek görsel olarak paylaşmak için dört farklı tasarım önerisi. Bütün dosyalar yerel [`tablo.jpg`](tablo.jpg) görselini kullanır ve internetsiz açılabilir. Her HTML dosyasının üst çubuğundan **Gece / Gündüz** teması ve hikâye için **Hikâye güvenli alanı** rehberi açılıp kapatılabilir.

Gerçek dışa aktarım boyutundaki (`1080×1920` ve `1080×1350`) bütün PNG çıktıları [`goruntuler/`](goruntuler/) klasöründedir.

## Ortak temel ve tasarım dili uyumu

Dört yön de Sanat Atlası'nın tasarım diline (`TASARIM_DILI.md`) ve uygulamanın tema sistemine (`NoraSanat/Kabuk/Tema.swift`, `TemaRenkleri.swift`) sıkı bağlıdır:

- **Üç katmanlı zemin:** Kömür / sıcak kâğıt zemin (`--bg`) ile ince nokta dokusu (`--doku`), tablonun iki baskın renginden (kobalt mavi ve sıcak altın) yumuşak köşe halesi (`TabloRenkleri`), ve Post-Empresyonizm döneminin sarmal-göz karosu (Gece %3,6, Gündüz %4,2).
- **Yazı üçlüsü:** Başlıkta **Bodoni Moda** (500, `−0,01 em`), ayrıntı notunda **Newsreader**, üst yazı ve künyede **Archivo**.
- **Renkler:** Yalnızca uygulamanın Gece ve Gündüz tema değişkenleri (`--bg`, `--surface`, `--border`, `--ink`, `--ink-2`, `--ink-3`, `--pirinc`).
- **"Yapma" kuralları:** Bölüm numarası veya sayaç yok; büyük harfli harf aralıklı etiket yok (tüm üst yazılar cümle düzeninde, pirinç); sol kenarlı renkli kutu yok; emoji yok; büyük renk geçişli zemin ya da belirgin desen yok.
- **İçerik:** Örnek eser *Yıldızlı Gece* (Vincent van Gogh · 1889, Post-Empresyonizm). Ayrıntı notu uygulamanın kendi rehberli inceleme verisinden (*Servinin alevleri*) alınmıştır.

---

## Yön 1 — Müze levhası (`yon-1.html`)

**Yaklaşım:** Tabloyu bir piksel bile kırpmadan özgün oranında sunan, müze duvarı dinginliğinde klasik bir levha.

- **Neden bu yön?** Yatay, dikey, kare ya da panoramik bütün tablolarda güvenle çalışır; resmin hiçbir köşesi yazının altında kalmaz. Tablonun altındaki tek ince yatay çizgi, künye ile okuma notunu kutuya hapsetmeden ayırır. Hikâye boyunda tablo ve tipografi Instagram güvenli alanını (`220 px` üst, `204 px` alt) dengeli doldurur.
- **En güçlü olduğu yer:** Mesaj paylaşımı, Gündüz teması ve eserin bütün kompozisyonunun bozulmaması gereken tablolar.
- **Ödün:** Hikâye boyunda kenardan kenara saran etki Yön 2 ve Yön 4 kadar dramatik değildir; sakin ve çerçeveli bir duruş tercih eder.
- **Görüntüler:** [Hikâye · Gece](goruntuler/yon-1-hikaye-gece.png) · [Hikâye · Gündüz](goruntuler/yon-1-hikaye-gunduz.png) · [Gönderi · Gece](goruntuler/yon-1-gonderi-gece.png) · [Gönderi · Gündüz](goruntuler/yon-1-gonderi-gunduz.png)

## Yön 2 — Bugün perdesi (`yon-2.html`)

**Yaklaşım:** Uygulamanın **Bugün** sekmesindeki tam ekran atmosferi doğrudan paylaşım görseline taşır. Tablo üstten kenardan kenara akar, alt kenarı yumuşakça zemine erir; ayrıntı notu yürüyüş kartlarıyla akraba buzlu cam yüzeyde durur.

- **Neden bu yön?** Kullanıcı uygulamada her sabah açtığı Bugün deneyiminin aynı görsel dilini paylaşır. Hikâye akışında tam boy görsel anında dikkat çeker; tablo ile metin arasında keskin bölünme yerine bütüncül bir geçiş vardır.
- **En güçlü olduğu yer:** Instagram hikâyesi (`1080×1920`) ve Gece teması.
- **Ödün:** Üst kapak `cover` yerleşimi kullandığı için çok geniş ya da çok dar tablolarda odak noktası (`gorsel_odak`) verilmezse kenarlardan kırpma oluşabilir.
- **Görüntüler:** [Hikâye · Gece](goruntuler/yon-2-hikaye-gece.png) · [Hikâye · Gündüz](goruntuler/yon-2-hikaye-gunduz.png) · [Gönderi · Gece](goruntuler/yon-2-gonderi-gece.png) · [Gönderi · Gündüz](goruntuler/yon-2-gonderi-gunduz.png)

## Yön 3 — Yakın bakış (`yon-3.html`)

**Yaklaşım:** Sanat Atlası'nı sıradan bir tablo paylaşımından ayıran **rehberli yakın okuma** deneyimini tek karede gösterir. Kırpılmamış tam tablonun üzerinde anlatılan ayrıntının yeri fısıltı gibi ince bir odak çerçevesiyle işaretlenir; alttaki yüzey kartında o bölgenin yakın kırpımı (`Kırpım`) ile notu yan yana yer alır.

- **Neden bu yön?** Paylaşımı gören kişi yalnızca "güzel bir tablo" değil, resmin içinde fark edilmesi gereken bir ayrıntı görür ve uygulamaya özgü okuma deneyimini tek bakışta hisseder. `eser_ayrintilari.json` koordinatlarıyla (burada *Servinin alevleri*) doğrudan otomatik üretilebilir.
- **En güçlü olduğu yer:** Ayrıntı kaydı bulunan günün başyapıtları; kırpılmamış eserle birlikte editoryal merak uyandıran kart.
- **Ödün:** Ayrıntı noktası koordinatı olmayan bir eserde kırpım kutusu üretilemez; o eserlerde Yön 1'e düşen bir yedek düzen gerekir.
- **Görüntüler:** [Hikâye · Gece](goruntuler/yon-3-hikaye-gece.png) · [Hikâye · Gündüz](goruntuler/yon-3-hikaye-gunduz.png) · [Gönderi · Gece](goruntuler/yon-3-gonderi-gece.png) · [Gönderi · Gündüz](goruntuler/yon-3-gonderi-gunduz.png)

## Yön 4 — Perde ve ayrıntı (`yon-4.html`)

**Yaklaşım:** Yön 2'nin kenardan kenara tablosu ve zemine yumuşakça eriyen perdesini, Yön 3'ün ince odak çerçevesi ve not kartı içindeki yakın kırpımıyla birleştirir.

- **Neden bu yön?** Bugün sekmesinin sürükleyici tam ekran hissini kaybetmeden Sanat Atlası'nın imza özelliği olan yakın okumayı da aynı kareye taşır. Kapak tablo özgün oranlı iç tuvalde konumlandığı için üstteki ince odak çerçevesi ile alttaki buzlu cam kartta duran küçük kırpım birebir aynı ayrıntıyı gösterir.
- **En güçlü olduğu yer:** Ayrıntı kaydı bulunan eserlerde hem Instagram hikâyesi hem gönderi için en bütüncül ve ayırt edici öneri.
- **Ödün:** Ayrıntı kaydı olmayan eserlerde odak çerçevesi ve kırpım gizlenerek kendiliğinden Yön 2 düzenine düşer.
- **Görüntüler:** [Hikâye · Gece](goruntuler/yon-4-hikaye-gece.png) · [Hikâye · Gündüz](goruntuler/yon-4-hikaye-gunduz.png) · [Gönderi · Gece](goruntuler/yon-4-gonderi-gece.png) · [Gönderi · Gündüz](goruntuler/yon-4-gonderi-gunduz.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Müze levhası | Yön 2 · Bugün perdesi | Yön 3 · Yakın bakış | Yön 4 · Perde ve ayrıntı |
|---|---|---|---|---|
| Tablo yerleşimi | Kırpılmamış çerçeveli | Kenardan kenara, eriyen | Kırpılmamış + odak | Kenardan kenara, eriyen + odak |
| Ayrıntı kırpımı | Yok | Yok | Yüzey kartında | Buzlu cam kartta |
| Uygulama akrabalığı | Galeri & Başyapıtlar | Bugün (Tuval) | Yakın okuma & Kırpım | Bugün + Yakın okuma |
| Her esere uyarlanabilirlik | Çok yüksek | Yüksek (odakla) | Ayrıntı kaydı olanlar (yedek: Yön 1) | Ayrıntı kaydı olanlar (yedek: Yön 2) |
| Hikâye etkisi (9:16) | Dingin, müze duvarı | Sürükleyici | Editoryal, çerçeveli | Sürükleyici + merak uyandıran |
| SwiftUI `ImageRenderer` karmaşıklığı | En sade | Orta | Orta | Orta–yüksek (erime + kırpım) |

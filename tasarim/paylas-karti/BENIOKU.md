# Paylaşılabilir Eser Kartı — Tasarım Yönleri

Günün tablosunu Instagram hikâyesine (`1080×1920`) ya da mesaja / gönderiye (`1080×1350`) tek görsel olarak paylaşmak için üç farklı tasarım önerisi. Her dosya tek başına tarayıcıda açılabilir; üst çubuktan **Gece / Gündüz** teması birlikte denetlenebilir ve `1080×1920` boyunda Instagram **Hikâye güvenli alanı** açılıp kapatılabilir.

## Ortak temel ve tasarım dili uyumu

Üç yön de Sanat Atlası'nın tasarım diline (`TASARIM_DILI.md`) ve uygulamanın tema sistemine (`NoraSanat/Kabuk/Tema.swift`, `TemaRenkleri.swift`) sıkı bağlıdır:

- **Üç katmanlı zemin:** Kömür / sıcak kâğıt zemin (`--bg`) ile ince nokta dokusu (`--doku`), tablonun iki baskın renginden (kobalt mavi ve sıcak altın) yumuşak köşe halesi (`TabloRenkleri`), ve Post-Empresyonizm döneminin sarmal-göz karosu (Gece %4, Gündüz %4,5).
- **Yazı üçlüsü:** Başlıkta **Bodoni Moda** (500, `−0,01 em`), ayrıntı notunda **Newsreader**, üst yazı ve künyede **Archivo**.
- **Renkler:** Yalnızca uygulamanın Gece ve Gündüz tema değişkenleri (`--bg`, `--surface`, `--border`, `--ink`, `--ink-2`, `--ink-3`, `--pirinc`).
- **"Yapma" kuralları:** Bölüm numarası veya sayaç yok; büyük harfli harf aralıklı etiket yok (tüm üst yazılar cümle düzeninde, pirinç); sol kenarlı renkli kutu yok; emoji yok; büyük renk geçişli zemin ya da belirgin desen yok.
- **İçerik:** Örnek eser *Yıldızlı Gece* (Vincent van Gogh · 1889, Post-Empresyonizm). Ayrıntı notu uygulamanın kendi rehberli inceleme verisinden (*Servinin alevleri*) alınmıştır.

---

## Yön 1 — Müze levhası (`yon-1.html`)

**Yaklaşım:** Tabloyu bir piksel bile kırpmadan özgün oranında sunan, müze duvarı dinginliğinde klasik bir levha.

- **Neden bu yön?** Farklı en-boy oranlarına sahip (yatay, dikey, kare, panoramik) bütün tablolarda güvenle çalışır; resmin hiçbir köşesi yazının altında kalmaz. Tablonun altındaki tek ince yatay çizgi, künye ile okuma notunu kutuya hapsetmeden ayırır.
- **En güçlü olduğu yer:** Mesaj paylaşımı, Gündüz teması ve eserin bütün kompozisyonunun bozulmaması gereken tablolar.
- **Ödün:** Hikâye (`1080×1920`) boyunda kenardan kenara saran etki Yön 2 kadar dramatik değildir; sakin ve çerçeveli bir duruş tercih eder.

## Yön 2 — Bugün perdesi (`yon-2.html`)

**Yaklaşım:** Uygulamanın **Bugün** sekmesindeki tam ekran atmosferi doğrudan paylaşım görseline taşır. Tablo üstten kenardan kenara akar, alt kenarı yumuşakça zemine erir; ayrıntı notu yürüyüş kartlarıyla akraba buzlu cam yüzeyde durur.

- **Neden bu yön?** Kullanıcı uygulamada her sabah açtığı Bugün deneyiminin aynı görsel dilini paylaşır. Hikâye akışında tam boy görsel anında dikkat çeker; tablo ile metin arasında keskin bölünme yerine bütüncül bir geçiş vardır.
- **En güçlü olduğu yer:** Instagram hikâyesi (`1080×1920`) ve Gece teması.
- **Ödün:** Üst kapak `cover` yerleşimi kullandığı için çok geniş ya da çok dar tablolarda odak noktası (`gorsel_odak`) verilmezse kenarlardan kırpma oluşabilir.

## Yön 3 — Yakın bakış (`yon-3.html`)

**Yaklaşım:** Sanat Atlası'nı sıradan bir tablo paylaşımından ayıran **rehberli yakın okuma** deneyimini tek karede gösterir. Tam tablonun üzerinde anlatılan ayrıntının yeri fısıltı gibi ince bir odak çerçevesiyle işaretlenir; alttaki yüzey kartında o bölgenin yakın kırpımı (`Kırpım`) ile notu yan yana yer alır.

- **Neden bu yön?** Paylaşımı gören kişi yalnızca "güzel bir tablo" değil, resmin içinde fark edilmesi gereken bir ayrıntı görür ve uygulamaya özgü okuma deneyimini tek bakışta hisseder. `eser_ayrintilari.json` koordinatlarıyla (burada *Servinin alevleri*) doğrudan otomatik üretilebilir.
- **En güçlü olduğu yer:** Ayrıntı kaydı bulunan günün başyapıtları; hem hikâyede hem gönderide merak uyandıran editoryal kart.
- **Ödün:** Ayrıntı noktası koordinatı olmayan bir eserde kırpım kutusu üretilemez; o eserlerde Yön 1'e düşen bir yedek düzen gerekir.

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Müze levhası | Yön 2 · Bugün perdesi | Yön 3 · Yakın bakış |
|---|---|---|---|
| Tablo kırpması | Yok (özgün oran) | Var (odak noktasına göre) | Tam tablo + ayrıntı kırpımı |
| Uygulama akrabalığı | Galeri & Başyapıtlar | Bugün (Tuval) sekmesi | Yakın okuma & Kırpım |
| Her esere uyarlanabilirlik | Çok yüksek | Yüksek (odak noktasıyla) | Ayrıntı kaydı olan eserlerde |
| Hikâye etkisi (9:16) | Dingin, müze duvarı | Tam ekran, sürükleyici | Editoryal, merak uyandıran |
| SwiftUI `ImageRenderer` karmaşıklığı | En sade | Orta | Orta (kırpım hesabı eklenir) |

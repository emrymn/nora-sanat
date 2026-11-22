# Kâhin: sitenin kendi cevapları

Swift'e taşınan her kural, canlı sitenin (sanat-atlasi.pages.dev) **kendi modülleriyle** üretilmiş cevaplarla sınanır.
Site Playwright'la açılır, `import('/js/...')` ile sitenin çalışan modülleri alınır (aynı adres → aynı modül örneği,
yani sitenin yüklediği veri `d` içinde hazırdır) ve sonuçlar JSON'a yazılır. Bu JSON `Paketler/NoraCekirdek/Tests/.../Ornekler/`'e girer.

```bash
# Playwright bulut oturumunda kurulu
node Testler/kahin/gunun_tablosu.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/site_cevaplari.json
```

Yeni bir kural taşırken aynı kalıpla `Testler/kahin/<konu>.mjs` yaz. Site o kuralı değiştirirse kâhini yeniden çalıştır; test kırılırsa Swift'i güncelle.

## Kabuk (T3)

```bash
# Sitenin sekme çubuğu (adres → seçili sekme) ve gece / gündüz / renkli gündüz renk değişkenleri
node Testler/kahin/kabuk.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/kabuk/cevaplar.json
# Swift dosyalarındaki köprü betikleri (Gecis.adresBetigi, TemaKoprusu.betik) canlı sitede; cevap dosyası yazmaz, geçer ya da kalır
node Testler/kahin/kabuk_koprusu.mjs
```

## Pekiştirme (C1a)

Uçtan uca örnek: `pekistir_turlari.mjs`. Sitenin ekran yapıştırıcısını (tur kurma, kart hazırlama, cevap yazma) aynen
kopyalar, tohumlu rastgeleyle 60 durum üretir. Swift testi aynı tohumla aynı sayıları çekmek zorunda; sayı ve sıra da
karşılaştırılır.

## Pekiştirme: tanışma ve eksik adımlar (C1c)

`pekistir_tanisma.mjs` aynı kalıpla, sitenin `kartCiz` akışını da kopyalar: konu turunda turdan önceki tanışmalar
(gösterilen eserler o turda sorulmaz), öbür turlarda yeni sanatçının kartından önceki tanışma, görseli açılmayan kartta
başka eser, eseri bulunamayan kartın sayaçta kalması, karıştırma sayısı, seviye sonucu ve seviye atlayan dönemler.
`PekistirTanismaTests` aynı akışı `TurKaydi` ile yürütür.

```bash
node Testler/kahin/pekistir_tanisma.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/pekistir/tanisma.json
```

## Temsil / küçük görsel (C4b)

```bash
# Her sanatçının sitedeki eser listesi ve sitenin `enBilinen` seçimi (küçük görseller, kitap kapakları, portreler),
# kötü işaretli görsellerle seçim, TEMSIL_DISI ve `bilinirlikSirasi` (tablo düğmesinin yelpazesi). ~1,5 MB.
node Testler/kahin/temsil.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/temsil/cevaplar.json
```

## Dersin adımları: Gör, Öğren, Ayırt et (C3)

`ders_adimlari.mjs` geçici profilde bütün konuları işlenmiş sayar ve sitenin kendi ders ekranlarını gezer: 28 dersin her
Gör karesi (üst satır, başlık, metin, noktalar, düğmeler ve kameranın kurduğu duruş: sahne genişliği, üst çubukla panel
arası, resmin CSS boyu, `transform`), her Öğren maddesi, her Ayırt et ikilisi (cevaptan sonraki sütunlar ve cümleler) ve
adım sonları. Ayrıca `js/kamera.js`'in yumuşak yolu (26 belirlenimli yol), eğriler ve `roma`. Webdriver'da site hareketi
kapatır; kamera duruşu anında kurulur. Ölçüler tarayıcının yazı çizimine bağlı olduğundan CI'da yeniden üretilip
karşılaştırılmaz; `DersAdimlariTests` sitenin girdileriyle (W, üst, alt, resim boyu) aynı duruşu hesaplar. ~3 dk.

```bash
node Testler/kahin/ders_adimlari.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/ders_adimlari/cevaplar.json
```

## Çevrimdışı görseller (C5)

```bash
# İndirme listesi (gösterilen görsellerin en büyük / 1280 / 400 kopyaları, sırayla; ~19 bin adres: sayılar, MD5, örnekler),
# parça planı ve Ayarlar'daki yazılar (bilgi ve her indirme durumunun iletisi, sayfanın kendisinden okunur).
# Site verisi Ornekler/site_verisi/'ndekilerden farklıysa durur: önce site_verisi.mjs ile örnekleri yenile.
node Testler/kahin/cevrimdisi.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/cevrimdisi/cevaplar.json
```

## Kayıt kuralları (Z2a)

`depo.mjs` tarayıcısız çalışır: sitenin deposunun bir kopyasındaki `js/depo.js`'i Node'da doğrudan yükler. Saat sabit
(2026-11-22T10:00:00Z), saat dilimi UTC olmalı. Tohumlu rastgele 400 ilerleme (eski temalar, bozuk alanlar, birleşen
akımlar, geliştirici yedeği…) `ilerlemeDogrula`'dan geçer; ayrıca yedek metni/çözümü, günlük, son çalışılanlar, yedek
hatırlatması, `enYeniKayit`, geliştirici modu aç/kapat. `IlerlemeKurallariTests` aynı girdilerle aynı yapıyı bekler.

```bash
TZ=UTC node Testler/kahin/depo.mjs /tmp/sa > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/depo/cevaplar.json
```

# Kâhin: sitenin kendi cevapları

Swift'e taşınan her kural, canlı sitenin (sanat-atlasi.pages.dev) **kendi modülleriyle** üretilmiş cevaplarla sınanır.
Site Playwright'la açılır, `import('/js/...')` ile sitenin çalışan modülleri alınır (aynı adres → aynı modül örneği,
yani sitenin yüklediği veri `d` içinde hazırdır) ve sonuçlar JSON'a yazılır. Bu JSON `Paketler/NoraCekirdek/Tests/.../Ornekler/`'e girer.

```bash
# Playwright bulut oturumunda kurulu
node Testler/kahin/gunun_tablosu.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/site_cevaplari.json
```

Yeni bir kural taşırken aynı kalıpla `Testler/kahin/<konu>.mjs` yaz. Site o kuralı değiştirirse kâhini yeniden çalıştır; test kırılırsa Swift'i güncelle.

Uçtan uca örnek: `pekistir_turlari.mjs`. Sitenin ekran yapıştırıcısını (tur kurma, kart hazırlama, cevap yazma) aynen
kopyalar, tohumlu rastgeleyle 60 durum üretir. Swift testi aynı tohumla aynı sayıları çekmek zorunda; sayı ve sıra da
karşılaştırılır.

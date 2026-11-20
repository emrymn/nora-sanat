# Kâhin: sitenin kendi cevapları

Swift'e taşınan her kural, canlı sitenin (sanat-atlasi.pages.dev) **kendi modülleriyle** üretilmiş cevaplarla sınanır.
Site Playwright'la açılır, `import('/js/...')` ile sitenin çalışan modülleri alınır (aynı adres → aynı modül örneği,
yani sitenin yüklediği veri `d` içinde hazırdır) ve sonuçlar JSON'a yazılır. Bu JSON `Paketler/NoraCekirdek/Tests/.../Ornekler/`'e girer.

```bash
# Playwright bulut oturumunda kurulu
node Testler/kahin/gunun_tablosu.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/site_cevaplari.json
```

Yeni bir kural taşırken aynı kalıpla `Testler/kahin/<konu>.mjs` yaz. Site o kuralı değiştirirse kâhini yeniden çalıştır; test kırılırsa Swift'i güncelle.

## Kâhinler

| Betik | Ne sınar | Çıktı |
|---|---|---|
| `gunun_tablosu.mjs` | Günün sanatçısı seçimi, günün tablosunun adı, yılı, görseli | `Ornekler/site_cevaplari.json` |
| `site_verisi.mjs` (T1) | Görünür sanatçılar ve akımlar, kurs konusu kapakları, ad parçaları, her görünür sanatçının eser listesi ve görsel adresleri (400, 1280, en büyük, üst kopya, yedek), yürüyüş görselleri, R2 kaynağı yokken adresler | `Ornekler/siteVerisi/` (sitenin aynı anda yüklediği `data_*.json` dosyaları + `cevaplar.json`) |

```bash
node Testler/kahin/site_verisi.mjs Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/siteVerisi
```
`site_verisi.mjs` veri dosyalarını da yeniden yazar: test örnekleri ile cevaplar hep aynı anlık görüntüden gelir.

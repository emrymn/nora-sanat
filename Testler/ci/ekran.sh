#!/bin/bash
# T8: CI ekran görüntüleri, grup grup. Her grup ayrı bir macOS işinde, aynı anda çalışır (.github/workflows/ios-derle.yml,
# `ekran` matrisi). Kullanım: Testler/ci/ekran.sh <grup> <NoraSanat.app>
# Gruplar: genel, bugun, ben, galeri-1, galeri-2, calis, yolculuk. Her grup temiz bir simülatörle başlar; Ben, Galeri, Çalış ve
# Yolculuk önce T2'nin deneme ilerlemesini yazar (7-8. konular), eskiden tek sırada önceki adımlardan kalan durum buydu.
# Görüntüler ekranlar/ klasörüne; adlar eskisiyle aynı.
set -e
GRUP="$1"
APP="$2"
test -n "$GRUP" && test -d "$APP"

# --- Simülatör ve yardımcılar (her grupta) ---
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys,re
d=json.load(sys.stdin)["devices"]
aday=[]
for rt,devs in d.items():
    m=re.search(r"iOS-(\d+)-(\d+)",rt)
    if not m: continue
    for x in devs:
        if "iPhone" in x["name"]:
            aday.append(((int(m.group(1)),int(m.group(2))),"Pro Max" in x["name"],x["name"],x["udid"]))
aday.sort()
print(aday[-1][3])')
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
PAKET=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
mkdir -p ekranlar
/usr/libexec/PlistBuddy -c "Print" "$APP/Info.plist" > ekranlar/Info.plist.txt
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true
cat > "$RUNNER_TEMP/ben-ekran.swift" <<'SWIFT'
import Foundation
import Vision
let istek = VNRecognizeTextRequest()
istek.recognitionLanguages = ["tr-TR", "en-US"]
try VNImageRequestHandler(url: URL(fileURLWithPath: CommandLine.arguments[1])).perform([istek])
let metin = (istek.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
print(metin)
let soz = CommandLine.arguments[2]
exit(metin.range(of: soz, options: [.caseInsensitive, .diacriticInsensitive]) == nil ? 1 : 0)
SWIFT
xcrun swiftc "$RUNNER_TEMP/ben-ekran.swift" -o "$RUNNER_TEMP/ben-ekran"
cat > "$RUNNER_TEMP/yan-yana.swift" <<'SWIFT'
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
func oku(_ y: String) -> CGImage {
  let k = CGImageSourceCreateWithURL(URL(fileURLWithPath: y) as CFURL, nil)!
  return CGImageSourceCreateImageAtIndex(k, 0, nil)!
}
let a = oku(CommandLine.arguments[1]), b = oku(CommandLine.arguments[2])
let ara = 48, w = a.width + ara + b.width, h = max(a.height, b.height)
let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
c.setFillColor(CGColor(red: 1, green: 0, blue: 0.5, alpha: 1))
c.fill(CGRect(x: 0, y: 0, width: w, height: h))
c.draw(a, in: CGRect(x: 0, y: h - a.height, width: a.width, height: a.height))
c.draw(b, in: CGRect(x: a.width + ara, y: h - b.height, width: b.width, height: b.height))
let hedef = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[3]) as CFURL,
                                            UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(hedef, c.makeImage()!, nil)
CGImageDestinationFinalize(hedef)
SWIFT
xcrun swiftc "$RUNNER_TEMP/yan-yana.swift" -o "$RUNNER_TEMP/yan-yana"
VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)

# Uygulamanın ilk açılışı: site ve service worker önbelleğe girer (görüntüsü yalnız genel grupta)
ilk_acilis() {
  xcrun simctl launch "$UDID" "$PAKET"
  sleep 25
}
# T2'nin deneme ilerlemesi (7-8. konular, bugüne 12 kart): Gotik dersi açık, Ben dolu
ilerleme_yaz() {
  xcrun simctl terminate "$UDID" "$PAKET" || true
  xcrun simctl launch "$UDID" "$PAKET" -ekran ilerleme -ilerlemeYaz
  sleep 30
}

genel() {
  xcrun simctl launch "$UDID" "$PAKET"
  sleep 25
  xcrun simctl io "$UDID" screenshot ekranlar/1-acilis.png
  # İkinci açılış: önbellekten (service worker) gelmeli
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET"
  sleep 12
  xcrun simctl io "$UDID" screenshot ekranlar/2-ikinci-acilis.png
  # Widget'ın üç boyutu, gerçek veriyle (yalnız Debug'da olan önizleme ekranı)
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -widgetOnizleme
  sleep 20
  xcrun simctl io "$UDID" screenshot ekranlar/3-widget.png
  # T2: ilerleme köprüsü. Önce Swift'ten okuyup bir deneme yazar (7-8. konular, bugüne 12 kart)...
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran ilerleme -ilerlemeYaz
  sleep 30
  xcrun simctl io "$UDID" screenshot ekranlar/5-ilerleme-ozeti.png
  # Z2b: ilerleme Swift'in dosyasında (ilk açılışta siteden taşındı); deneme yazısı (7-8. konular) orada olmalı
  IL="$VERI/Library/Application Support/Ilerleme/ilerleme.json"
  test -s "$IL"
  python3 -c 'import json,sys; v=json.load(open(sys.argv[1])); print("Swift ilerlemesi: kayitNo", v["kayitNo"], "islenen", len(v["islenen"])); assert 7 in v["islenen"] and 8 in v["islenen"]' "$IL"
  # ...sonra site kendi #/ilerleme sayfasında bunu göstermeli (kayıt kalıcı)
  sleep 3
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "#/ilerleme"
  sleep 20
  xcrun simctl io "$UDID" screenshot ekranlar/6-site-ilerleme.png
  # T3: temanın renk ve yazı örnekleri (Gece, Gündüz; altta sitenin canlı teması)
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran tema
  sleep 20
  xcrun simctl io "$UDID" screenshot ekranlar/7-tema.png
  # T3: yerli sekme denemesi: Galeri yerli sayılır; #/gozat'a gidilince site gizlenir, yerli çubuk görünür
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -yerliSekme galeri -adres "#/gozat"
  sleep 15
  xcrun simctl io "$UDID" screenshot ekranlar/8-yerli-sekme.png
  # T4: aynı adreste sitenin kendi çubuğu (8 ile yan yana: çubuk aynı yerde, aynı görünüşte olmalı).
  # G3'ten beri Galeri yerli: sitenin Galeri'si yalnız -yalnizSite ile görünür.
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "#/gozat"
  sleep 15
  xcrun simctl io "$UDID" screenshot ekranlar/8b-site-cubuk.png
  # T4: yerli çubuğun hızlı ayarlar yaprağı (sitedeki dişli dil)
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -yerliSekme galeri -adres "#/gozat" -hizliAcik
  sleep 15
  xcrun simctl io "$UDID" screenshot ekranlar/8c-hizli-ayar.png
  # Z3p (İş 180): İncele kipi: genel bakış (kartta eserin adı) ve 2. ayrıntı (kamera kartın dışındaki boşlukta)
  for INC in -1 1; do
    xcrun simctl terminate "$UDID" "$PAKET" || true
    xcrun simctl launch "$UDID" "$PAKET" -ekran goruntuleyici -incele "$INC"
    sleep 35
    if [ "$INC" = "-1" ]; then AD=9b-incele-genel; else AD=9c-incele-ayrinti; fi
    xcrun simctl io "$UDID" screenshot "ekranlar/$AD.png"
  done
  # G1: tam ekran görüntüleyici (ayrıntı noktası olan ilk eser; katalog ve görsel ağdan gelir)
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran goruntuleyici
  sleep 30
  xcrun simctl io "$UDID" screenshot ekranlar/9-goruntuleyici.png
  # Y1: "Dinleyerek bak": kurulum (süre ve ses seçimi), sonra sessiz seçenekte ilk ayrıntıya yaklaşmış hâli (altyazı)
  # Z4a (Yön 3): başlangıç ("Dinlemeye başla"), anlatım Gece ve Gündüz (altyazının arkasındaki geçiş), denetimler
  # (duraklatılmış, adım şeridi), bitiş ("Tur tamamlandı").
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle
  sleep 25
  xcrun simctl io "$UDID" screenshot ekranlar/9d-dinle-kurulum.png
  "$RUNNER_TEMP/ben-ekran" ekranlar/9d-dinle-kurulum.png "Dinlemeye ba"
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle -dinleAdim 1
  sleep 45
  xcrun simctl io "$UDID" screenshot ekranlar/9e-dinle-ayrinti.png
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle -dinleAdim 1 -dinleTema gunduz
  sleep 45
  xcrun simctl io "$UDID" screenshot ekranlar/9e-dinle-ayrinti-gunduz.png
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle -dinleAdim 1 -dinleDenetim
  sleep 45
  xcrun simctl io "$UDID" screenshot ekranlar/9f-dinle-denetim.png
  "$RUNNER_TEMP/ben-ekran" ekranlar/9f-dinle-denetim.png "Kapan"
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle -dinleAdim 0 -dinleBitis
  sleep 35
  xcrun simctl io "$UDID" screenshot ekranlar/9g-dinle-bitis.png
  "$RUNNER_TEMP/ben-ekran" ekranlar/9g-dinle-bitis.png "Tur tamam"
  # Z4a: doğal ses. Ses dizini yokmuş gibi (-dinleSesYok: R2'ye ya da ses_dizini.json'a ulaşılamaz) sesli başlayınca
  # açılışı telefonun sesi (AVSpeech) okumalı; uygulama kimin okuduğunu tmp/dinle-ses'e yazar.
  DVERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
  xcrun simctl terminate "$UDID" "$PAKET"
  rm -f "$DVERI/tmp/dinle-ses"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle -dinleAdim 0 -dinleSesli -dinleSesYok
  for _ in {1..60}; do
    test -f "$DVERI/tmp/dinle-ses" && break
    sleep 1
  done
  echo "dinle (R2 yok): $(cat "$DVERI/tmp/dinle-ses" 2>/dev/null)"
  grep -q "adim 0 acilis: AVSpeech" "$DVERI/tmp/dinle-ses"
  # Bilgi için: dizin ve kayıtlar varsa (site ses_dizini.json'u yayınladıysa) açılışı Fola okur; yoksa yine AVSpeech.
  xcrun simctl terminate "$UDID" "$PAKET"
  rm -f "$DVERI/tmp/dinle-ses"
  xcrun simctl launch "$UDID" "$PAKET" -ekran dinle -dinleAdim 0 -dinleSesli
  for _ in {1..60}; do
    test -f "$DVERI/tmp/dinle-ses" && break
    sleep 1
  done
  echo "dinle (R2): $(cat "$DVERI/tmp/dinle-ses" 2>/dev/null)"
  # C1b/C1c: pekiştirme. Açılışlar arası aynı tur sürer: 10a ilk ekran (yeni sanatçıysa tanışma), 10 soru kartı,
  # 10c yanlış bir şıktan sonra cevap yaprağı. Her adım hazır olunca işaret dosyası yazılır; yükleme ve hata başarı sayılmaz.
  VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
  for ADIM in ilk kart yaprak; do
    xcrun simctl terminate "$UDID" "$PAKET" || true
    rm -f "$VERI/tmp/pekistirme-hazir"
    xcrun simctl launch "$UDID" "$PAKET" -ekran pekistir -pekistirAdim "$ADIM"
    for _ in {1..90}; do
      test -f "$VERI/tmp/pekistirme-hazir" && break
      sleep 1
    done
    test -f "$VERI/tmp/pekistirme-hazir"
    echo "pekiştirme $ADIM: $(cat "$VERI/tmp/pekistirme-hazir")"
    sleep 4
    case "$ADIM" in
      ilk) AD=10a-pekistirme-ilk ;;
      kart) AD=10-pekistirme ;;
      yaprak) AD=10c-pekistirme-yaprak ;;
    esac
    xcrun simctl io "$UDID" screenshot "ekranlar/$AD.png"
  done
  # C1c: aynı turun sitedeki karşılığı (yan yana karşılaştırma için)
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "#/pekistir/karisik"
  sleep 20
  xcrun simctl io "$UDID" screenshot ekranlar/10s-site-pekistirme.png
  # T5: site hareket izni isteyince iOS penceresi çıkmamalı (uygulama izni kendisi verir)
  xcrun simctl terminate "$UDID" "$PAKET" || true
  VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
  rm -f "$VERI/tmp/hareket-izni"
  xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -hareketIzniDene
  for _ in {1..60}; do
    test -f "$VERI/tmp/hareket-izni" && break
    sleep 1
  done
  sleep 2
  xcrun simctl io "$UDID" screenshot ekranlar/t5-hareket-izni.png
  echo "hareket izni: $(cat "$VERI/tmp/hareket-izni" 2>/dev/null || echo yok)"
  test "$(cat "$VERI/tmp/hareket-izni")" = granted
  if "$RUNNER_TEMP/ben-ekran" ekranlar/t5-hareket-izni.png "Erişmek"; then echo "izin penceresi çıktı"; exit 1; fi
  # T7: beş sekme yerli. Açılışta Çalış istenince site arkada "#/" bildirse de Bugün'e atlamamalı.
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -adres "#/pekistir"
  sleep 25
  xcrun simctl io "$UDID" screenshot ekranlar/t7-acilis-calis.png
  "$RUNNER_TEMP/ben-ekran" ekranlar/t7-acilis-calis.png "Bugünün dersi"
  # Yolculuk yerli: haritanın ilerleme hapı
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET" -adres "#/harita"
  sleep 20
  xcrun simctl io "$UDID" screenshot ekranlar/t7-yolculuk.png
  "$RUNNER_TEMP/ben-ekran" ekranlar/t7-yolculuk.png "konu"
  # Widget'a dokunma: norasanat://… uygulamayı açmalı. HEP EN SONDA KALSIN: simülatörün "Open in…" onay
  # penceresi kapanmadan ekranda kalır ve sonraki ekran görüntülerinin üstüne biner.
  xcrun simctl terminate "$UDID" "$PAKET"
  xcrun simctl launch "$UDID" "$PAKET"
  sleep 10
  xcrun simctl openurl "$UDID" "norasanat://calis"
  sleep 6
  xcrun simctl io "$UDID" screenshot ekranlar/4-url-calis.png
}

bugun() {
  ilk_acilis
  # G4: aynı veri ve tarihte site ile yerli kapak; iki ekranda da eylem görünene kadar bekle.
  for KIP in site yerli; do
    xcrun simctl terminate "$UDID" "$PAKET"
    if [ "$KIP" = site ]; then
      EK=(-yalnizSite)
    else
      EK=(-yerliSekme bugun -bugunKarsilastir)
      rm -f "$VERI/tmp/bugun-hazir"
    fi
    xcrun simctl launch "$UDID" "$PAKET" "${EK[@]}" -adres "#/"
    for DENEME in {1..24}; do
      sleep 4
      if [ "$KIP" = yerli ] && [ ! -s "$VERI/tmp/bugun-hazir" ]; then
        if [ "$DENEME" = 24 ]; then exit 1; fi
        continue
      fi
      xcrun simctl io "$UDID" screenshot "ekranlar/bugun-$KIP.png"
      if "$RUNNER_TEMP/ben-ekran" "ekranlar/bugun-$KIP.png" "Hayat"; then break; fi
      if [ "$DENEME" = 24 ]; then exit 1; fi
    done
  done
  "$RUNNER_TEMP/yan-yana" ekranlar/bugun-site.png ekranlar/bugun-yerli.png ekranlar/yan-yana-bugun.png
  # Z3v: paylaş kartı. Uygulama kartın iki boyunu (hikâye 1080×1920, gönderi 1080×1350) ve iki temasını (Gece, Gündüz)
  # ImageRenderer ile tmp/paylas-<boy>-<tema>.png'ye yazar, sonra paylaş yaprağını açar. Tasarımla (neon/paylas-karti-tasarim,
  # yon-4-*.png) karşılaştırmak için PNG'ler artifact'a.
  xcrun simctl terminate "$UDID" "$PAKET"
  rm -f "$VERI/tmp/paylas-hazir" "$VERI"/tmp/paylas-*.png
  xcrun simctl launch "$UDID" "$PAKET" -yerliSekme bugun -adres "#/" -paylasKartiCiz
  for _ in {1..60}; do
    test -s "$VERI/tmp/paylas-hazir" && break
    sleep 2
  done
  echo "paylaş kartı: $(cat "$VERI/tmp/paylas-hazir")"
  xcrun simctl io "$UDID" screenshot ekranlar/bugun-paylas-yaprak.png
  for BOY in hikaye gonderi; do
    for TEMA in gece gunduz; do
      test -s "$VERI/tmp/paylas-$BOY-$TEMA.png"
      cp "$VERI/tmp/paylas-$BOY-$TEMA.png" "ekranlar/paylas-$BOY-$TEMA.png"
      sips -g pixelWidth -g pixelHeight "ekranlar/paylas-$BOY-$TEMA.png" | tail -2
    done
  done
  "$RUNNER_TEMP/ben-ekran" ekranlar/paylas-hikaye-gece.png "Sanat Atlas"
  # Denetim: aynı sanatçı, aynı gerçek ayrıntı, iki kart konumu ve yürüyüş sonu.
  for BOLUM in ayrinti-alt ayrinti-ust hayati eserler tur; do
    BETIK=$(node Testler/bugun-site-cekimi.mjs "$BOLUM")
    xcrun simctl terminate "$UDID" "$PAKET"
    rm -f "$VERI/tmp/site-betik"
    xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "#/" -siteBetik "$BETIK"
    for _ in {1..90}; do
      test -s "$VERI/tmp/site-betik" && break
      sleep 1
    done
    SONUC=$(cat "$VERI/tmp/site-betik")
    echo "$SONUC"
    IFS='|' read -r HEDEF SANATCI ADIM SOZ KONUM OLCU <<< "$SONUC"
    test "$HEDEF" = "$BOLUM" && test -n "$SOZ" || exit 1
    xcrun simctl io "$UDID" screenshot "ekranlar/bugun-site-$BOLUM.png"
    xcrun simctl terminate "$UDID" "$PAKET"
    rm -f "$VERI/tmp/bugun-hazir"
    KONUM_ARG=()
    if [ -n "$KONUM" ]; then KONUM_ARG=(-bugunKonum "$KONUM"); fi
    rm -f "$VERI/tmp/bugun-durum"
    xcrun simctl launch "$UDID" "$PAKET" -yerliSekme bugun -adres "#/" -bugunKaydir "$BOLUM" -bugunSanatci "$SANATCI" -bugunAdim "$ADIM" "${KONUM_ARG[@]}"
    for _ in {1..60}; do
      test -s "$VERI/tmp/bugun-hazir" && break
      sleep 1
    done
    test "$(cat "$VERI/tmp/bugun-hazir")" = "$BOLUM"
    echo "yerli $BOLUM: $(cat "$VERI/tmp/bugun-durum" 2>/dev/null)"
    xcrun simctl io "$UDID" screenshot "ekranlar/bugun-yerli-$BOLUM.png"
    # OCR bazı Türkçe harfleri düz Latin harflerine çevirir.
    "$RUNNER_TEMP/ben-ekran" "ekranlar/bugun-yerli-$BOLUM.png" "${SOZ%% *}"
    "$RUNNER_TEMP/yan-yana" "ekranlar/bugun-site-$BOLUM.png" "ekranlar/bugun-yerli-$BOLUM.png" "ekranlar/yan-yana-bugun-$BOLUM.png"
  done
}

ben() {
  ilk_acilis
  ilerleme_yaz
  # C4 + C4b: gerçek ilerleme ile yerli Ben ekranı ve ayarları; her biri sitenin aynı sayfasıyla yan yana
  # (solda site -yalnizSite, sağda yerli). -benKaydir aynı bölüme kaydırır (kurs, akim, yedek).
  # Z3x: Ayarlar'ın yeni grupları (hatirlatma, hakkinda; sitede karşılığı yok, yan yana alınmaz).
  for IS in ilerleme: ilerleme:kurs ilerleme:akim ayarlar: ayarlar:yedek ayarlar:cevrimdisi ayarlar:hatirlatma ayarlar:hakkinda; do
    SAYFA="${IS%%:*}"; BOLUM="${IS#*:}"
    AD="ben-$SAYFA${BOLUM:+-$BOLUM}"
    KAYDIR=()
    if [ -n "$BOLUM" ]; then KAYDIR=(-benKaydir "$BOLUM"); fi
    # Yerli (Ben artık Gecis.tasinanlar'da). Uygulama yüklenip (istendiyse) kayınca tmp/ben-hazir yazar.
    xcrun simctl terminate "$UDID" "$PAKET"
    VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
    rm -f "$VERI/tmp/ben-hazir"
    xcrun simctl launch "$UDID" "$PAKET" -adres "#/$SAYFA" -benSayfa "$SAYFA" "${KAYDIR[@]}"
    for _ in {1..90}; do
      test -f "$VERI/tmp/ben-hazir" && break
      sleep 1
    done
    test -f "$VERI/tmp/ben-hazir"
    sleep 3
    xcrun simctl io "$UDID" screenshot "ekranlar/$AD.png"
    SOZ="Ben"
    if [ "$SAYFA" = ayarlar ]; then SOZ="Gündüz rengi"; fi
    if [ -z "$BOLUM" ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/$AD.png" "$SOZ"; fi
    # C5: çevrimdışı bölüm Swift'in listesiyle (sitenin sayfası okunmadan)
    if [ "$BOLUM" = cevrimdisi ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/$AD.png" "Telefonda: 0 / "; fi
    # Z3x: hatırlatma uygulamanın içinde; Yenilikler siteden okunan sürüm notlarıyla. (OCR "ı"yı "i" okur ve arama
    # aksansız olsa da ı ≠ i: aranan sözlerde ı olmasın.)
    if [ "$BOLUM" = hatirlatma ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/$AD.png" "Simge rozeti"; continue; fi
    if [ "$BOLUM" = hakkinda ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/$AD.png" "Yenilikler"; continue; fi
    # Site: aynı adres, aynı bölüm
    xcrun simctl terminate "$UDID" "$PAKET"
    xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "#/$SAYFA" "${KAYDIR[@]}"
    sleep 22
    xcrun simctl io "$UDID" screenshot "ekranlar/site-$SAYFA${BOLUM:+-$BOLUM}.png"
    "$RUNNER_TEMP/yan-yana" "ekranlar/site-$SAYFA${BOLUM:+-$BOLUM}.png" "ekranlar/$AD.png" "ekranlar/yan-yana-$SAYFA${BOLUM:+-$BOLUM}.png"
  done
  # Z3x: Ayarlar Gündüz temasında da (renkler yalnız tema.renkler'den). Kayıttaki temayı Gündüz yapıp üstünü ve
  # Yedek'i (ekranın tek dolu düğmesi) çeker, sonra Gece'ye döner.
  IL="$VERI/Library/Application Support/Ilerleme/ilerleme.json"
  for BOLUM in "" yedek; do
    xcrun simctl terminate "$UDID" "$PAKET" || true
    python3 -c 'import json,sys; p=sys.argv[1]; v=json.load(open(p)); v.setdefault("ayarlar",{})["tema"]="gunduz"; json.dump(v,open(p,"w"),ensure_ascii=False)' "$IL"
    rm -f "$VERI/tmp/ben-hazir"
    KAYDIR=()
    if [ -n "$BOLUM" ]; then KAYDIR=(-benKaydir "$BOLUM"); fi
    xcrun simctl launch "$UDID" "$PAKET" -adres "#/ayarlar" -benSayfa ayarlar "${KAYDIR[@]}"
    for _ in {1..90}; do
      test -f "$VERI/tmp/ben-hazir" && break
      sleep 1
    done
    sleep 3
    xcrun simctl io "$UDID" screenshot "ekranlar/ben-ayarlar-gunduz${BOLUM:+-$BOLUM}.png"
  done
  "$RUNNER_TEMP/ben-ekran" ekranlar/ben-ayarlar-gunduz.png "Gündüz rengi"
  "$RUNNER_TEMP/ben-ekran" ekranlar/ben-ayarlar-gunduz-yedek.png "lerlemeni yedekle"
  xcrun simctl terminate "$UDID" "$PAKET" || true
  python3 -c 'import json,sys; p=sys.argv[1]; v=json.load(open(p)); v.setdefault("ayarlar",{})["tema"]="gece"; json.dump(v,open(p,"w"),ensure_ascii=False)' "$IL"
  # C5: Swift'te gerçek indirme (arka plan URLSession). Küçük bir parça (2 en büyük kopya kadar) iner,
  # dosyalar uygulamanın Application Support/CevrimdisiGorseller klasörüne yazılmalı.
  # (Z3x: Gündüz adımı uygulamayı zaten kapattı; kapalıysa terminate hata verir.)
  xcrun simctl terminate "$UDID" "$PAKET" || true
  VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
  rm -f "$VERI/tmp/ben-hazir"
  xcrun simctl launch "$UDID" "$PAKET" -adres "#/ayarlar" -benSayfa ayarlar -benKaydir cevrimdisi -cevrimdisiIndir -cevrimdisiParca 2
  INEN=0
  for _ in {1..120}; do
    INEN=$( (ls "$VERI/Library/Application Support/CevrimdisiGorseller" 2>/dev/null || true) | wc -l | tr -d ' ')
    if [ "$INEN" -ge 2 ]; then break; fi
    sleep 1
  done
  sleep 6
  xcrun simctl io "$UDID" screenshot ekranlar/c5-cevrimdisi-indi.png
  echo "çevrimdışı inen dosya: $INEN"
  cat "$VERI/tmp/cevrimdisi-durum.json" || true; echo
  ls -la "$VERI/Library/Application Support/CevrimdisiGorseller" || true
  test "$INEN" -ge 2
  "$RUNNER_TEMP/ben-ekran" ekranlar/c5-cevrimdisi-indi.png "bitti"
}

galeri() {
  ilk_acilis
  ilerleme_yaz
  # G2 + G2b + G3: her Galeri ekranı için solda site (-yalnizSite), sağda yerli ekran; yan yana galeri-yan-yana-*.png.
  # AD|adres|bölüm: -galeriKaydir aynı bölüme kaydırır (dizin: "Bütün akımlar" açık). Yerli Galeri hazır olunca
  # (veri ve görseller yüklendi, istendiyse kaydı) tmp/galeri-hazir yazar; ana ekranda OCR "Salona gir"i arar.
  ISLER=(
    "ana|#/gozat|" "ana-dizin|#/gozat|dizin" \
    "akim|#/akim/Gotik|" "akim-eserler|#/akim/Gotik|eserler" "akim-pekistir|#/akim/Gotik|pekistir" \
    "sanatci|#/sanatci/giotto-di-bondone|" "eserler|#/sanatci/giotto-di-bondone/eserler|" \
    "konular|#/konular|" "konu|#/konu/annunciation|" "ara|#/ara|" "koleksiyon|#/koleksiyon|" \
    "karsilastir|#/karsilastir/giotto-di-bondone/duccio-di-buoninsegna|" \
    "akim-karsilastir|#/akim-karsilastir/Gotik/Erken%20R%C3%B6nesans|" \
    "basyapitlar|#/basyapitlar|" "basyapitlar-serit|#/basyapitlar|serit" "basyapitlar-donem|#/basyapitlar|donem" \
    "okuma|#/basyapit/Q1212937|" "okuma-ayrinti|#/basyapit/Q1212937|okuma-ayrinti" \
    "okuma-derin|#/basyapit/Q1212937/ders|okuma-derin" "okuma-son|#/basyapit/Q1212937|okuma-son" \
    "yan-yana|#/basyapit/Q979440|yanyana"
  )
  # İki makineye bölünür (galeri-1, galeri-2): ilk yarı ya da ikinci yarı
  YARI=$(( (${#ISLER[@]} + 1) / 2 ))
  if [ "$1" = 1 ]; then ISLER=("${ISLER[@]:0:$YARI}"); else ISLER=("${ISLER[@]:$YARI}"); fi
  for IS in "${ISLER[@]}"; do
    AD="${IS%%|*}"; KALAN="${IS#*|}"; ADRES="${KALAN%%|*}"; BOLUM="${KALAN#*|}"
    KAYDIR=()
    if [ -n "$BOLUM" ]; then KAYDIR=(-galeriKaydir "$BOLUM"); fi
    xcrun simctl terminate "$UDID" "$PAKET" || true
    VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
    rm -f "$VERI/tmp/galeri-hazir"
    xcrun simctl launch "$UDID" "$PAKET" -yerliSekme galeri -adres "#/gozat" -galeriSayfa "$ADRES" "${KAYDIR[@]}"
    for _ in {1..90}; do
      test -f "$VERI/tmp/galeri-hazir" && break
      sleep 1
    done
    test -f "$VERI/tmp/galeri-hazir" || echo "::warning::$AD: yerli Galeri hazır olmadı"
    sleep 2
    xcrun simctl io "$UDID" screenshot "ekranlar/galeri-$AD.png"
    if [ "$AD" = ana ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/galeri-$AD.png" "Salona gir"; fi
    xcrun simctl terminate "$UDID" "$PAKET"
    xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "$ADRES" "${KAYDIR[@]}"
    sleep 22
    xcrun simctl io "$UDID" screenshot "ekranlar/site-galeri-$AD.png"
    "$RUNNER_TEMP/yan-yana" "ekranlar/site-galeri-$AD.png" "ekranlar/galeri-$AD.png" "ekranlar/galeri-yan-yana-$AD.png"
  done
}

calis() {
  ilk_acilis
  ilerleme_yaz
  # C2: Çalış ana ekranı (#/pekistir, #/calis) ve Turlar (#/pekistir/donem): yerli ekran ile sitenin yan yana görünümü
  for IS in calis: calis:turlar calis:yuk donem: donem:salon; do
    SAYFA="${IS%%:*}"; BOLUM="${IS#*:}"
    AD="calis-$SAYFA${BOLUM:+-$BOLUM}"
    ADRES="#/pekistir"
    ARGS=(-yerliSekme calis,ben -adres "#/pekistir")
    if [ "$SAYFA" = donem ]; then
      ADRES="#/pekistir/donem"
      ARGS=(-yerliSekme calis,ben -adres "#/pekistir/donem" -calisSayfa donem)
    fi
    if [ -n "$BOLUM" ]; then
      ARGS+=("-calisKaydir" "$BOLUM")
    fi
    xcrun simctl terminate "$UDID" "$PAKET"
    VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
    rm -f "$VERI/tmp/calis-hazir"
    xcrun simctl launch "$UDID" "$PAKET" "${ARGS[@]}"
    for _ in {1..90}; do
      test -f "$VERI/tmp/calis-hazir" && break
      sleep 1
    done
    test -f "$VERI/tmp/calis-hazir"
    sleep 3
    xcrun simctl io "$UDID" screenshot "ekranlar/$AD.png"
    if [ "$SAYFA" = calis ] && [ -z "$BOLUM" ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/$AD.png" "Bugünün dersi"; fi
    if [ "$SAYFA" = donem ] && [ -z "$BOLUM" ]; then "$RUNNER_TEMP/ben-ekran" "ekranlar/$AD.png" "Turu başlat"; fi
    # Site: -yalnizSite ile aynı adres
    xcrun simctl terminate "$UDID" "$PAKET"
    xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "$ADRES"
    sleep 22
    xcrun simctl io "$UDID" screenshot "ekranlar/site-calis-$SAYFA${BOLUM:+-$BOLUM}.png"
    "$RUNNER_TEMP/yan-yana" "ekranlar/site-calis-$SAYFA${BOLUM:+-$BOLUM}.png" "ekranlar/$AD.png" "ekranlar/yan-yana-calis-$SAYFA${BOLUM:+-$BOLUM}.png"
  done
  # C3: dersin sayfası ve adımları (Gör, Öğren, Ayırt et): solda site (-yalnizSite), sağda yerli; ders-yan-yana-*.png.
  # Gotik bu simülatörde açık (sitenin başlangıç konuları + T2'nin 7-8. konuları). Yerli ekran hazır olunca
  # tmp/ders-hazir yazar. Ayırt et'in cevaplı hâli (-dersCevapla) ilerleme yazdığı için en sonda ve yalnız yerli.
  for IS in ders: gor:gor ogren:ogren ayirt:ayirt ayirt-cevap:ayirt; do
    AD="${IS%%:*}"; ADIM="${IS#*:}"
    ADRES="#/pekistir/ders/Gotik${ADIM:+/$ADIM}"
    # Adım adresleri (…/gor|ogren|ayirt) sitede sekmesizdir (Sekme.swift): Kabuk onları siteye bırakır. Yerli
    # ekran ders sayfasının adresinden açılır, adımı -calisSayfa seçer (CalisSekmesi.ciAdimi).
    ARGS=(-yerliSekme calis,ben -adres "#/pekistir/ders/Gotik" -calisSayfa "ders:Gotik${ADIM:+:$ADIM}")
    if [ "$AD" = ayirt-cevap ]; then ARGS+=(-dersCevapla 1); fi
    xcrun simctl terminate "$UDID" "$PAKET"
    VERI=$(xcrun simctl get_app_container "$UDID" "$PAKET" data)
    rm -f "$VERI/tmp/ders-hazir" "$VERI/tmp/calis-hazir"
    xcrun simctl launch "$UDID" "$PAKET" "${ARGS[@]}"
    if [ -z "$ADIM" ]; then
      sleep 15
    else
      for _ in {1..90}; do
        test -f "$VERI/tmp/ders-hazir" && break
        sleep 1
      done
      sleep 3
    fi
    xcrun simctl io "$UDID" screenshot "ekranlar/ders-$AD.png"
    if [ "$AD" = ayirt-cevap ]; then continue; fi
    xcrun simctl terminate "$UDID" "$PAKET"
    xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "$ADRES"
    sleep 22
    xcrun simctl io "$UDID" screenshot "ekranlar/site-ders-$AD.png"
    "$RUNNER_TEMP/yan-yana" "ekranlar/site-ders-$AD.png" "ekranlar/ders-$AD.png" "ekranlar/ders-yan-yana-$AD.png"
  done
}

hazir_yolculuk() {
  for _ in {1..120}; do
    [ -f "$VERI/tmp/yolculuk-hata" ] && { cat "$VERI/tmp/yolculuk-hata"; return 1; }
    [ "$(cat "$VERI/tmp/yolculuk-hazir" 2>/dev/null)" = "$1" ] && return 0
    sleep 1
  done
  echo "::error::Yolculuk $1 hazır olmadı"
  return 1
}
yolculuk() {
  ilk_acilis
  ilerleme_yaz
  # G5 karşılaştırmaları, solda zorunlu site, sağda yerli ekran.
  for AD in harita gecis zaman kurs motif kilit durak tanisma soru cevap grup-sonu sergi seviye-tamam; do
    for TARAF in site yerli; do
      xcrun simctl terminate "$UDID" "$PAKET" || true
      rm -f "$VERI/tmp/yolculuk-hazir" "$VERI/tmp/yolculuk-hata"
      # Zaman Galeri'nin sekmesi (Galeri yerli); öbürleri yerli Yolculuk. -izinSorma: bildirim izni penceresi çıkmasın
      ADRES="#/harita"
      [ "$AD" = zaman ] && ADRES="#/zaman"
      ARGS=(-yerliSekme yolculuk -adres "$ADRES")
      [ "$TARAF" = site ] && ARGS=(-yalnizSite -adres "$ADRES")
      xcrun simctl launch "$UDID" "$PAKET" "${ARGS[@]}" -yolculukProva "$AD" -izinSorma
      hazir_yolculuk "$AD"
      sleep 3
      xcrun simctl io "$UDID" screenshot "ekranlar/$TARAF-yolculuk-$AD.png"
    done
    "$RUNNER_TEMP/yan-yana" "ekranlar/site-yolculuk-$AD.png" "ekranlar/yerli-yolculuk-$AD.png" "ekranlar/yan-yana-yolculuk-$AD.png"
  done
  xcrun simctl terminate "$UDID" "$PAKET"
  rm -f "$VERI/tmp/yolculuk-hazir"
  xcrun simctl launch "$UDID" "$PAKET" -yalnizSite -adres "#/harita" -yolculukProva geri-yukle -izinSorma
  hazir_yolculuk geri-yukle
}

case "$GRUP" in
  genel|bugun|ben|calis|yolculuk) "$GRUP" ;;
  galeri-1) galeri 1 ;;
  galeri-2) galeri 2 ;;
  *) echo "Bilinmeyen grup: $GRUP"; exit 1 ;;
esac

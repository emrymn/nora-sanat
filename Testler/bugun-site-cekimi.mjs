// CI'da -siteBetik ile sayfanın kendi JS ortamında çalışacak işlev gövdesini üretir.
async function bolumuAc(bolum) {
  const bekle = ms => new Promise(resolve => setTimeout(resolve, ms));
  async function hazir(oku) {
    for (let i = 0; i < 60; i++) {
      const sonuc = oku();
      if (sonuc) return sonuc;
      await bekle(250);
    }
    throw Error(bolum + ' yüklenmedi');
  }

  await hazir(() => document.querySelector('.yur-kapak'));
  const ortak = await import('/js/ekranlar/ortak.js');
  const bugun = await import('/js/ekranlar/bugun.js');
  // Yalnız o WebView oturumunda seçim yap. Kartların konumunu site belirlesin.
  for (const id of ['andrea-mantegna', 'ambrogio-lorenzetti', 'fra-angelico', 'sandro-botticelli']) {
    ortak.d.ilerleme.gununDegisim = {tarih:ortak.bugun(), id};
    bugun.anaSayfa();
    await document.fonts.ready;
    const sayi = ortak.d.yuruyus[id].noktalar.length;
    const adimlar = [...document.querySelectorAll('.yur-adim')];
    await hazir(() => adimlar[2]?.dataset.gorunen && document.querySelector('[data-yur-bio] h2'));
    const noktalar = adimlar.slice(2, 2 + sayi);
    const ust = noktalar.find(el => el.classList.contains('kart-ustte'));
    const alt = noktalar.find(el => !el.classList.contains('kart-ustte'));
    if (!ust || !alt) continue;
    const ayrinti = bolum === 'ayrinti-ust' ? ust : bolum === 'ayrinti-alt' ? alt : null;
    const secici = {hayati:'.yur-hayat', eserler:'[data-test="yur-eserler"]', tur:'[data-test="yur-tur"]'};
    const el = ayrinti || document.querySelector(secici[bolum]);
    if (!el) throw Error(bolum + ': ' + secici[bolum] + ' yok');
    const oran = {eserler:0.5, tur:0.85}[bolum] || 0;
    const yer = el.getBoundingClientRect();
    window.scrollTo({top:scrollY + yer.top - (innerHeight - yer.height) * oran, behavior:'instant'});
    await bekle(4500);
    const icerik = ayrinti ? el.querySelector('.yur-kart') : el.querySelector('[data-yur-bio] h2') || el;
    let gorunen = icerik.getBoundingClientRect();
    if (gorunen.top < -2 || gorunen.bottom > innerHeight + 2) {
      // WebKit'te sayfa sonu farklı olabilir: öğeyi ekranın altına hizalayıp bir kez daha dene.
      icerik.scrollIntoView({block: 'end', behavior: 'instant'});
      await bekle(1500);
      gorunen = icerik.getBoundingClientRect();
    }
    if (gorunen.top < -2 || gorunen.bottom > innerHeight + 2)
      throw Error(`${bolum} ekran dışında: üst ${Math.round(gorunen.top)}, alt ${Math.round(gorunen.bottom)}, ekran ${innerHeight}, kaydırma ${Math.round(scrollY)}/${document.documentElement.scrollHeight}`);
    const soz = ayrinti ? icerik.querySelector('h2').textContent : {hayati:'Hayat', eserler:'eserleri', tur:'Bugünkü'}[bolum];
    return [bolum, id, ayrinti ? adimlar.indexOf(el) : 0, soz].join('|');
  }
  throw Error('İki konumda ayrıntı bulunamadı');
}
const bolum = process.argv[2];
if (!['ayrinti-ust','ayrinti-alt','hayati','eserler','tur'].includes(bolum)) throw Error('Bilinmeyen bölüm');
console.log('return await (' + bolumuAc.toString() + ')(' + JSON.stringify(bolum) + ');');

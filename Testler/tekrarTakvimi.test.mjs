// Köprü betiğinin tekrar takvimi hesabı: `node --test Testler/`
// Betik NoraSanat/TekrarKoprusu.swift'ten okunur; tarayıcı nesneleri taklit edilir.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const kaynak = readFileSync(new URL('../NoraSanat/TekrarKoprusu.swift', import.meta.url), 'utf8');
const betik = kaynak.split('/* BETIK-BASI */')[1].split('/* BETIK-SONU */')[0];

function kur(depo = {}) {
  const gelen = [];
  const dinleyici = {};
  const ortam = {
    webkit: { messageHandlers: {
      tekrarTakvimi: { postMessage: (v) => gelen.push(['takvim', v]) },
      rozet: { postMessage: (v) => gelen.push(['rozet', v]) },
      bildirimIzni: { postMessage: () => Promise.resolve('granted') },
    } },
    addEventListener: (ad, f) => (dinleyici[ad] = f),
  };
  const belge = { visibilityState: 'visible', addEventListener: (ad, f) => (dinleyici[ad] = f) };
  const gezgin = {};
  const yerel = { getItem: (k) => (k in depo ? depo[k] : null) };
  new Function('window', 'document', 'navigator', 'localStorage', 'setTimeout', betik)(ortam, belge, gezgin, yerel, (f) => f());
  return { ortam, gelen, dinleyici, gezgin };
}

const skor = (son, sonraki) => ({ kutu: 1, dogru: 1, yanlis: 0, son, sonraki });

test('sitenin vadeSayisi ile aynı birikimli sayım', () => {
  const { ortam } = kur();
  const ilerleme = {
    ayarlar: { rozet: true },
    skorlar: {
      a: { sanatci: skor('2026-11-01', '2026-11-18') },                 // vadesi geçmiş → bugün
      b: { sanatci: skor('2026-11-10', '2026-11-22'), akim: skor('2026-11-10', '2026-11-21') }, // en yakın: yarın
      c: { akim: skor('2026-11-10', '2026-11-25') },                    // 5 gün sonra
      d: { sanatci: skor(null, '2026-11-20') },                         // hiç görülmemiş → sayılmaz
      e: { sanatci: skor('2026-11-10', '2027-01-01') },                 // 14 günden sonra
      f: {},
    },
  };
  const t = ortam.__noraKopru.takvim(JSON.stringify(ilerleme), '2026-11-20');
  assert.equal(t.bugun, '2026-11-20');
  assert.equal(t.rozet, true);
  assert.deepEqual(t.gunler, [1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3]);
});

test('ay sonu ve yedek biçimi ({ ilerleme })', () => {
  const { ortam } = kur();
  const t = ortam.__noraKopru.takvim(JSON.stringify({ ilerleme: { skorlar: { x: { sanatci: skor('2026-12-01', '2027-01-01') } } } }), '2026-12-30');
  assert.equal(t.rozet, false);
  assert.deepEqual(t.gunler.slice(0, 4), [0, 0, 1, 1]);
});

test('kapanışta takvim gönderilir, kayıt yoksa gönderilmez', () => {
  const bos = kur();
  bos.dinleyici.pagehide();
  assert.equal(bos.gelen.length, 0);
  const dolu = kur({ 'sanat-atlasi:ilerleme': JSON.stringify({ skorlar: {} }) });
  dolu.dinleyici.visibilitychange();
  assert.equal(dolu.gelen[0][0], 'takvim');
  assert.equal(dolu.gelen[0][1].gunler.length, 14);
});

test('rozet ve bildirim izni köprüsü', async () => {
  const { ortam, gelen, gezgin } = kur();
  await gezgin.setAppBadge(7.6);
  await gezgin.clearAppBadge();
  assert.deepEqual(gelen, [['rozet', 7], ['rozet', 0]]);
  assert.equal(ortam.Notification.permission, 'default');
  assert.equal(await ortam.Notification.requestPermission(), 'granted');
  assert.equal(ortam.Notification.permission, 'granted');
});

import Foundation

/// Sanat Atlası ile uygulama arasındaki köprü betikleri (sayfa açılmadan eklenir).
/// Sitenin kodu değişmez: betik sitenin kendi kaydını (localStorage) okur ve iOS'un bilmediği web işlevlerini tamamlar.
///
/// - Tekrar takvimi: sitenin ilerlemesindeki (`sanat-atlasi:ilerleme` → `skorlar`) vadelerden önümüzdeki 14 günün
///   "tekrar bekliyor" sayıları (sitenin `vadeSayisi`'yle aynı sayım). Açılışta ve her kapanışta `tekrarTakvimi`'ne gider.
/// - `navigator.setAppBadge` / `clearAppBadge`: sitedeki "Simge rozeti" ayarı uygulamanın simgesinde çalışsın (`rozet`).
/// - `Notification.requestPermission`: sitenin rozet izni iOS'un bildirim iznine bağlanır (`bildirimIzni`).
///
/// Betik `Testler/tekrarTakvimi.test.mjs` ile sınanır (BETIK-BASI / BETIK-SONU arası okunur).
enum TekrarKoprusu {
    static let betik = """
    /* BETIK-BASI */
    (function () {
      if (window.__noraKopru) return;
      var ANAHTAR = 'sanat-atlasi:ilerleme';
      var GUN = 14;
      function iki(n) { return (n < 10 ? '0' : '') + n; }
      function gunStr(d) { return d.getFullYear() + '-' + iki(d.getMonth() + 1) + '-' + iki(d.getDate()); }
      function gunEkle(t, n) { var p = t.split('-').map(Number); return gunStr(new Date(p[0], p[1] - 1, p[2] + n, 12)); }

      // ham: localStorage'daki ilerleme (JSON); bugun: "YYYY-MM-DD"
      function takvim(ham, bugun) {
        var v = JSON.parse(ham);
        if (!v || typeof v !== 'object') return null;
        if (v.ilerleme && typeof v.ilerleme === 'object') v = v.ilerleme;
        var sk = v.skorlar && typeof v.skorlar === 'object' ? v.skorlar : {};
        var sinir = [], gunler = [];
        for (var i = 0; i < GUN; i++) { sinir.push(gunEkle(bugun, i)); gunler.push(0); }
        Object.keys(sk).forEach(function (id) {
          var s = sk[id] || {};
          var t = [s.sanatci, s.akim]
            .filter(function (x) { return x && x.son && typeof x.sonraki === 'string' && x.sonraki; })
            .map(function (x) { return x.sonraki; })
            .sort();
          if (!t.length) return;
          for (var i = 0; i < GUN; i++) {
            if (t[0] <= sinir[i]) { for (var j = i; j < GUN; j++) gunler[j]++; break; }
          }
        });
        return { bugun: bugun, gunler: gunler, rozet: !!(v.ayarlar && v.ayarlar.rozet) };
      }

      function ileti(ad, veri) {
        var h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[ad];
        return h ? h.postMessage(veri) : undefined;
      }

      function gonder() {
        try {
          var ham = localStorage.getItem(ANAHTAR);
          if (!ham) return;
          var t = takvim(ham, gunStr(new Date()));
          if (t) ileti('tekrarTakvimi', t);
        } catch (e) {}
      }

      window.__noraKopru = { takvim: takvim, gonder: gonder };
      document.addEventListener('visibilitychange', function () {
        setTimeout(gonder, document.visibilityState === 'hidden' ? 0 : 1500);
      });
      window.addEventListener('pagehide', gonder);
      window.addEventListener('load', function () { setTimeout(gonder, 3000); });

      // Simge rozeti
      navigator.setAppBadge = function (n) {
        ileti('rozet', Math.max(0, Math.floor(Number(n) || 0)));
        return Promise.resolve();
      };
      navigator.clearAppBadge = function () { ileti('rozet', 0); return Promise.resolve(); };

      // Bildirim izni (yalnız sitenin rozet izni kullanır)
      var izin = 'default';
      var Bildirim = function () { throw new TypeError('Nora Sanat: bildirimler uygulamadan gelir'); };
      Object.defineProperty(Bildirim, 'permission', { get: function () { return izin; } });
      Bildirim.requestPermission = function () {
        var p = ileti('bildirimIzni', null);
        return Promise.resolve(p).then(function (s) { izin = s === 'granted' ? 'granted' : 'denied'; return izin; },
                                       function () { izin = 'denied'; return izin; });
      };
      try { Object.defineProperty(window, 'Notification', { value: Bildirim, configurable: true, writable: true }); } catch (e) {}
    })();
    /* BETIK-SONU */
    """
}

/* Nora Sanat · Dinleyerek bak — Ortak eser verileri, sinematik kamera motoru ve tur zamanlayıcısı.
 * Dış bağlantı yok; tamamen yerel yüksek çözünürlüklü Wikimedia Commons kamu malı görsellerle çalışır.
 * Matematik ve eğriler Swift'e (NoraCekirdek/Dinle/DinlemeKamerasi.swift) birebir aktarılacak şekilde yazılmıştır. */
(function (global) {
  'use strict';

  /* ===== 1. GERÇEK ESER VERİLERİ (Sanat Atlası eser_ayrintilari.json, eser_hikayeleri.json, eser_notlari.json) ===== */
  const ESERLER = {
    nedimeler: {
      id: 'nedimeler',
      ad: 'Nedimeler',
      sanatci: 'Diego Velázquez',
      tarih: '1656',
      akim: 'İspanyol Barok',
      donemDesen: '../../NoraSanat/Ekranlar/Galeri/Desenler/desen-barok@3x.png',
      gorsel: 'gorseller/nedimeler.jpg',
      en: 3840,
      boy: 4420,
      hale1: '154, 112, 68',
      hale2: '72, 58, 50',
      davet: 'Saray atölyesinin içinde hikâyesiyle sakin bir yürüyüş.',
      acilis: [
        'Nedimeler. Diego Velázquez, 1656.',
        'Velázquez atölyesinde prenses Margarita, nedimeler ve aynada kral ile kraliçe.',
        'Bakış, temsil ve iktidar üstüne Batı resminin en derin başyapıtlarından biri.'
      ],
      anlati: {
        baslik: 'Saray atölyesi',
        kutu: { x: 0.14, y: 0.36, w: 0.72, h: 0.54 },
        cumleler: [
          'Madrid’deki kraliyet sarayı, 1656. Saray ressamı Velázquez’in atölyesindeyiz.',
          'Ortada beş yaşındaki prenses Margarita Teresa; çevresinde nedimeleri ve saray cüceleri var.',
          'Peki odadaki herkes kime bakıyor? Arka duvardaki küçük ayna cevabı veriyor.'
        ]
      },
      noktalar: [
        {
          ad: 'Aynadaki çift',
          kutu: { x: 0.37, y: 0.51, w: 0.10, h: 0.11 },
          cumleler: [
            'Arka duvardaki aynada kral IV. Felipe ve kraliçe Mariana belli belirsiz görünüyor.',
            'Yansıma, ikisinin tam da izleyicinin durduğu yerde olduğunu düşündürür.',
            'Ressamın tuvalinde onların portresini yaptığı da öne sürülür.'
          ]
        },
        {
          ad: 'Ressamın otoportresi',
          kutu: { x: 0.16, y: 0.50, w: 0.14, h: 0.22 },
          cumleler: [
            'Velázquez elinde fırça ve paletle tuvalin arkasından doğrudan bize bakıyor.',
            'Göğsündeki kırmızı haç, Santiago şövalyelik nişanıdır.',
            'Ressam bu unvanı 1659’da aldığı için haç tabloya sonradan eklenmiştir.'
          ]
        },
        {
          ad: 'Prenses Margarita',
          kutu: { x: 0.41, y: 0.63, w: 0.16, h: 0.17 },
          cumleler: [
            'Ortada beş yaşlarındaki prenses Margarita duruyor; ışık en çok onun üstüne düşer.',
            'Solundaki nedime ona küçük kırmızı bir testi sunuyor.',
            'Tablonun adı bu nedimelerden — İspanyolca meninas sözcüğünden — gelir.'
          ]
        },
        {
          ad: 'Kapıdaki adam',
          kutu: { x: 0.51, y: 0.52, w: 0.11, h: 0.15 },
          cumleler: [
            'En uzaktaki açık kapıda bir adam merdivende durmuş, geriye bakıyor.',
            'Genellikle kraliçenin saray görevlisi José Nieto olarak tanınır.',
            'Arkasındaki parlak ışık, loş salonun derinliğini belirginleştirir.'
          ]
        }
      ],
      sessiz: ['Bir süre yalnız bak.'],
      kapanis: ['Şimdi tablonun tamamına bir kez daha bak.']
    },

    arnolfini: {
      id: 'arnolfini',
      ad: 'Arnolfini Portresi',
      sanatci: 'Jan van Eyck',
      tarih: '1434',
      akim: 'Kuzey Rönesansı',
      donemDesen: '../../NoraSanat/Ekranlar/Galeri/Desenler/desen-ronesans@3x.png',
      gorsel: 'gorseller/arnolfini.jpg',
      en: 3840,
      boy: 5253,
      hale1: '58, 108, 76',
      hale2: '158, 62, 52',
      davet: 'Dışbükey aynadan tek muma, yağlıboyanın sessiz simgeleri arasında gezinti.',
      acilis: [
        'Arnolfini Portresi. Jan van Eyck, 1434.',
        'Bir çiftin tam boy portresi; dışbükey ayna, sembolik nesneler ve ressamın imzasıyla ünlüdür.'
      ],
      anlati: {
        baslik: 'Brugge’de bir oda',
        kutu: { x: 0.16, y: 0.14, w: 0.68, h: 0.62 },
        cumleler: [
          'Kuzey ışığı pencereden süzülüp zümrüt yeşili kumaşlara ve pirinç avizeye dokunuyor.',
          'Odadaki her nesne, resmin sessiz tanığı gibi yerli yerine konmuş.'
        ]
      },
      noktalar: [
        {
          ad: 'Ayna ve imza',
          kutu: { x: 0.40, y: 0.19, w: 0.20, h: 0.18 },
          cumleler: [
            'Dışbükey aynada çiftin sırtı ve kapıda iki konuk görünür: biri van Eyck’in kendisi olabilir.',
            'Aynanın çerçevesindeki on madalyonda İsa’nın Çilesi’nden sahneler var.',
            'Üstteki yazı “Johannes de Eyck fuit hic 1434”: Jan van Eyck buradaydı.'
          ]
        },
        {
          ad: 'Tek mum',
          kutu: { x: 0.37, y: 0.04, w: 0.28, h: 0.15 },
          cumleler: [
            'Pirinç avizede gündüz vakti tek bir mum yanıyor.',
            'Tanrı’nın her şeyi gören gözü ya da evlilik mumu olarak yorumlanır.',
            'Metalin parlaklığı yağlıboyanın ince katmanlarıyla verilmiş.'
          ]
        },
        {
          ad: 'Birleşen eller',
          kutu: { x: 0.47, y: 0.37, w: 0.17, h: 0.09 },
          cumleler: [
            'Erkek kadının elini avucuna almış; sağ elini yemin eder gibi kaldırmış.',
            'Tablonun uzun süre bir nikâh belgesi gibi okunmasının nedeni bu jesttir.'
          ]
        },
        {
          ad: 'Köpek',
          kutu: { x: 0.36, y: 0.83, w: 0.24, h: 0.15 },
          cumleler: [
            'Küçük tüylü köpek sadakatin geleneksel simgesidir.',
            'Her tüyü ince fırçayla tek tek çizilmiş; çiftten farklı olarak doğrudan bize bakar.'
          ]
        }
      ],
      sessiz: ['Bir süre yalnız bak.'],
      kapanis: ['Şimdi tablonun tamamına bir kez daha bak.']
    },

    karda: {
      id: 'karda',
      ad: 'Karda Avcılar',
      sanatci: 'Pieter Bruegel (Yaşlı)',
      tarih: '1565',
      akim: 'Kuzey Rönesansı',
      donemDesen: '../../NoraSanat/Ekranlar/Galeri/Desenler/desen-ronesans@3x.png',
      gorsel: 'gorseller/karda-avcilar.jpg',
      en: 3840,
      boy: 2733,
      hale1: '86, 114, 122',
      hale2: '176, 126, 70',
      davet: 'Karlı tepeden donmuş vadiye ve hayali Alp zirvelerine uzanan kış yürüyüşü.',
      acilis: [
        'Karda Avcılar. Pieter Bruegel, 1565.',
        'Karlı bir kış gününde avcılar köpekleriyle köye döner; mevsim döngüsü dizisinin en ünlü parçasıdır.'
      ],
      anlati: {
        baslik: 'Kışın ortasında',
        kutu: { x: 0.08, y: 0.22, w: 0.82, h: 0.62 },
        cumleler: [
          '1565 kışı, Avrupa’nın Küçük Buz Çağı denen sert kışlarından biriydi.',
          'Bakışımız yüksek bir tepeden aşağıya, donmuş göletlere ve uzak dağlara doğru açılıyor.'
        ]
      },
      noktalar: [
        {
          ad: 'Yorgun avcılar',
          kutu: { x: 0.01, y: 0.52, w: 0.40, h: 0.42 },
          cumleler: [
            'Üç avcı ve köpekleri omuzları düşük, başları eğik döner.',
            'Sırttaki tek tilki, kış avının ne kadar kıt olduğunu söyler.',
            'Bakış onlarla birlikte tepeden aşağı, vadiye iner.'
          ]
        },
        {
          ad: 'Buzda kayanlar',
          kutu: { x: 0.65, y: 0.50, w: 0.30, h: 0.20 },
          cumleler: [
            'Buz oyunları Bruegel’in köylü hayatına ilgisini gösterir.',
            'Resmin yapıldığı kış, Avrupa’nın en soğuk dönemlerinden birinin tanığıdır.'
          ]
        },
        {
          ad: 'Uçan kuş',
          kutu: { x: 0.65, y: 0.19, w: 0.12, h: 0.13 },
          cumleler: [
            'Süzülen kuş bakışı tepeden vadiye, oradan uzak dağlara taşır.',
            'Bruegel derinliği çapraz bir çizgi ve küçülen figürlerle kurar.'
          ]
        },
        {
          ad: 'Alp zirveleri',
          kutu: { x: 0.75, y: 0.08, w: 0.24, h: 0.26 },
          cumleler: [
            'Düz Flandre’da böyle sivri dağlar yoktur.',
            'Bruegel İtalya yolculuğunda gördüğü Alpleri bu kış manzarasına katmıştır.'
          ]
        }
      ],
      sessiz: ['Bir süre yalnız bak.'],
      kapanis: ['Şimdi tablonun tamamına bir kez daha bak.']
    }
  };

  /* ===== 2. PLAN KURUCU (DinlemePlani.swift karşılığı: 3 / 5 / 10 dk) ===== */
  function planKur(eser, sureDk) {
    const dk = sureDk === 3 || sureDk === 10 ? sureDk : 5;
    // Demo oynatımında akıcı deneyim için gerçek oranları koruyan sakin tempo
    const sessizCarpan = dk === 3 ? 0.75 : dk === 10 ? 1.35 : 1.0;
    const adimlar = [];

    adimlar.push({
      tur: 'acilis',
      evrAd: 'Açılış',
      baslik: eser.ad,
      altBaslik: eser.sanatci + ' · ' + eser.tarih,
      kutu: null,
      cumleler: eser.acilis,
      gecisSuresi: 1.4,
      gecikme: 0.9,
      sessizlik: 1.8 * sessizCarpan
    });

    if (dk >= 5 && eser.anlati) {
      adimlar.push({
        tur: 'anlati',
        evrAd: 'Anlatı',
        baslik: eser.anlati.baslik,
        kutu: eser.anlati.kutu,
        cumleler: eser.anlati.cumleler,
        gecisSuresi: 3.1,
        gecikme: 1.3,
        sessizlik: 1.6 * sessizCarpan
      });
    }

    const noktaSayisi = dk === 3 ? Math.min(3, eser.noktalar.length) : eser.noktalar.length;
    for (let i = 0; i < noktaSayisi; i++) {
      const n = eser.noktalar[i];
      adimlar.push({
        tur: 'nokta',
        evrAd: 'Ayrıntı',
        noktaSira: i,
        baslik: n.ad,
        kutu: n.kutu,
        cumleler: n.cumleler,
        gecisSuresi: null, // mesafeye göre uyarlanır (2.9 – 4.4 sn)
        gecikme: 1.6,
        sessizlik: 2.2 * sessizCarpan
      });
    }

    if (dk >= 5) {
      adimlar.push({
        tur: 'sessiz',
        evrAd: 'Sessiz bakış',
        baslik: 'Sessiz bakış',
        kutu: null,
        cumleler: eser.sessiz,
        gecisSuresi: 3.4,
        gecikme: 1.2,
        sessizlik: (dk === 10 ? 7.5 : 5.0)
      });
    }

    adimlar.push({
      tur: 'kapanis',
      evrAd: 'Kapanış',
      baslik: eser.ad,
      kutu: null,
      cumleler: eser.kapanis,
      gecisSuresi: 3.6,
      gecikme: 1.5,
      sessizlik: 2.6 * sessizCarpan
    });

    return {
      sureDk: dk,
      noktaSayisi: noktaSayisi,
      adimlar: adimlar
    };
  }

  /* ===== 3. SİNEMATİK KAMERA FİZİĞİ (Swift'e aktarılacak sabitler ve eğriler) ===== */
  const KAMERA_AYAR = {
    pay: 0.56,          // Ayrıntının güvenli alandaki kaplama oranı (nefesli)
    enAzOlcek: 1.48,    // Yakınlaşma alt sınırı
    enCokOlcek: 2.68,   // Piksellenmeyi ve klostrofobiyi önleyen üst sınır
    anlatiOlcek: 1.24,  // Anlatı adımında yumuşak geniş gezinti
    odakYOrani: 0.43,   // Ayrıntının ekrandaki dikey odak noktası (altyazının üstünde altın oran)
    tamYOrani: 0.45,    // Tam tablo görünümünde dikey merkez
    gecisTaban: 2.8,    // İki ayrıntı arası taban süre (sn)
    gecisMesafe: 2.6,   // Mesafe başına ek süre (sn)
    gecisEnAz: 2.9,     // En kısa geçiş (sn)
    gecisEnCok: 4.4,    // En uzun geçiş (sn)
    nefesTaban: 0.16,   // Log-ölçek uzaklaşma yayı taban derinliği
    nefesMesafe: 0.62,  // Mesafe başına ek uzaklaşma derinliği
    nefesEnCok: 0.48,   // En fazla uzaklaşma (e^-0.48 ≈ 0.62×)
    suzmeHizi: 0.0052,  // Konuşma sürerken log-ölçek büyüme hızı (sn^-1)
    suzmeSiniri: 0.072, // Toplam süzülme sınırı (~%7.5)
    suzmeSalinimU: 0.0052,
    suzmeSalinimV: 0.0038,
    caprazSure: 0.90    // Hareket azaltılınca çapraz geçiş süresi (sn)
  };

  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
  function lerp(a, b, t) { return a + (b - a) * t; }

  // Tam kübik Bézier çözücü (Newton-Raphson; CSS ve Swift CAMediaTimingFunction ile birebir)
  function cubicBezier(p1x, p1y, p2x, p2y) {
    const cx = 3 * p1x, bx = 3 * (p2x - p1x) - cx, ax = 1 - cx - bx;
    const cy = 3 * p1y, by = 3 * (p2y - p1y) - cy, ay = 1 - cy - by;
    function sampleX(t) { return ((ax * t + bx) * t + cx) * t; }
    function sampleY(t) { return ((ay * t + by) * t + cy) * t; }
    function sampleDX(t) { return (3 * ax * t + 2 * bx) * t + cx; }
    return function (x) {
      if (x <= 0) return 0;
      if (x >= 1) return 1;
      let t = x;
      for (let i = 0; i < 6; i++) {
        const dx = sampleX(t) - x;
        if (Math.abs(dx) < 1e-5) break;
        const d = sampleDX(t);
        if (Math.abs(d) < 1e-6) break;
        t = clamp(t - dx / d, 0, 1);
      }
      return sampleY(t);
    };
  }

  const egriKonum = cubicBezier(0.42, 0.0, 0.18, 1.0); // Yumuşak çıkış, uzun kadife varış
  const egriOlcek = cubicBezier(0.36, 0.0, 0.20, 1.0); // Doğal mercek hızlanması

  function tabanOlcu(imgW, imgH, sahneW, sahneH, kenarPay) {
    const pad = kenarPay || 0;
    const maxW = Math.max(1, sahneW - pad * 2);
    const maxH = Math.max(1, sahneH - pad * 2);
    const oran = imgW / imgH;
    let w = maxW;
    let h = w / oran;
    if (h > maxH) {
      h = maxH;
      w = h * oran;
    }
    return { w: w, h: h };
  }

  // Bir adım için hedef kamera durumunu hesaplar: { u, v, z, anchorY }
  function hedefHesapla(adim, eser, sahneW, sahneH, secenek) {
    const opt = secenek || {};
    const taban = tabanOlcu(eser.en, eser.boy, sahneW, sahneH, opt.tamPay || 0);
    const tamY = opt.tamYOrani != null ? opt.tamYOrani : KAMERA_AYAR.tamYOrani;
    const odakY = opt.odakYOrani != null ? opt.odakYOrani : KAMERA_AYAR.odakYOrani;

    if (!adim || !adim.kutu) {
      const tamOlcek = opt.tamOlcek || 1.0;
      return {
        u: 0.5,
        v: 0.5,
        z: Math.log(tamOlcek),
        anchorY: tamY * sahneH,
        taban: taban
      };
    }

    const k = adim.kutu;
    const guvenliH = sahneH * 0.60;
    const guvenliW = sahneW * 0.90;
    const kw = Math.max(0.04, k.w) * taban.w;
    const kh = Math.max(0.04, k.h) * taban.h;

    const dpr = Math.max(2, global.devicePixelRatio || 2);
    const pikselSinir = (eser.en * 1.18) / (taban.w * dpr);

    let s;
    if (adim.tur === 'anlati') {
      s = Math.min(KAMERA_AYAR.anlatiOlcek, pikselSinir);
    } else {
      const ham = Math.min((guvenliW * KAMERA_AYAR.pay) / kw, (guvenliH * KAMERA_AYAR.pay) / kh);
      const ust = Math.min(KAMERA_AYAR.enCokOlcek, pikselSinir);
      s = clamp(ham, KAMERA_AYAR.enAzOlcek, ust);
    }

    let u = k.x + k.w / 2;
    let v = k.y + k.h / 2;
    const anchorY = odakY * sahneH;

    // Kenar taşma sınırlaması (tablo kenarı boşluğa kaymasın, ancak dip ayrıntılar altyazı üstünde kalsın)
    const olcekW = taban.w * s;
    const olcekH = taban.h * s;
    if (olcekW > sahneW) {
      const yariU = (sahneW / 2) / olcekW;
      u = clamp(u, yariU, 1 - yariU);
    } else {
      u = 0.5;
    }
    if (olcekH >= sahneH) {
      const minV = anchorY / olcekH;
      const maxV = 1 - (sahneH - anchorY) / olcekH;
      v = minV <= maxV ? clamp(v, minV, maxV) : 0.5;
    } else if (olcekH > sahneH * 0.80) {
      const ustPay = anchorY / olcekH;
      const altPay = (sahneH - anchorY - 24) / olcekH;
      const minV = clamp(ustPay, 0.08, 0.48);
      const maxV = clamp(1 - Math.max(0.06, altPay), 0.52, 0.94);
      v = clamp(v, minV, maxV);
    }

    return { u: u, v: v, z: Math.log(s), anchorY: anchorY, taban: taban };
  }

  // Kamera durumunu DOM transform ve kutu ekran koordinatlarına çevirir
  function kameraYerlesim(durum, eser, sahneW, sahneH, tamPay) {
    const taban = tabanOlcu(eser.en, eser.boy, sahneW, sahneH, tamPay || 0);
    const s = Math.exp(durum.z);
    const tx = -(durum.u - 0.5) * taban.w * s;
    const ty = -(durum.v - 0.5) * taban.h * s + (durum.anchorY - sahneH / 2);
    return { taban: taban, s: s, tx: tx, ty: ty };
  }

  // Bir kutunun ekrandaki gerçek piksel çerçevesi (ayrıntı ışığı/halkası canlı süzülmeyi izler)
  function kutuEkranda(kutu, yerlesim, sahneW, sahneH) {
    if (!kutu) return null;
    const w = yerlesim.taban.w * yerlesim.s;
    const h = yerlesim.taban.h * yerlesim.s;
    const sol = sahneW / 2 + yerlesim.tx - w / 2;
    const ust = sahneH / 2 + yerlesim.ty - h / 2;
    return {
      x: sol + kutu.x * w,
      y: ust + kutu.y * h,
      w: kutu.w * w,
      h: kutu.h * h,
      cx: sol + (kutu.x + kutu.w / 2) * w,
      cy: ust + (kutu.y + kutu.h / 2) * h
    };
  }

  /* ===== 4. ETKİLEŞİMLİ OYNATICI VE KAMERA DÖNGÜSÜ ===== */
  function DinleMotoru(ayar) {
    this.ayar = ayar;
    this.eser = ESERLER[ayar.eserId || 'nedimeler'];
    this.sureDk = ayar.sureDk || 5;
    this.plan = planKur(this.eser, this.sureDk);
    this.kip = 'baslangic'; // baslangic | oynuyor | duraklatildi | bitis
    this.adimSira = 0;
    this.hareketAz = !!ayar.hareketAz;
    this.sesli = !!ayar.sesli;
    this.denetimlerAcik = false;

    this.sahneW = ayar.sahneW || 390;
    this.sahneH = ayar.sahneH || 844;

    // Canlı kamera durumu
    const ilk = hedefHesapla(null, this.eser, this.sahneW, this.sahneH, ayar.kameraSecenek);
    this.bas = { u: ilk.u, v: ilk.v, z: ilk.z, anchorY: ilk.anchorY };
    this.hedef = { u: ilk.u, v: ilk.v, z: ilk.z, anchorY: ilk.anchorY };
    this.canli = { u: ilk.u, v: ilk.v, z: ilk.z, anchorY: ilk.anchorY };
    this.gecisSuresi = 2.8;
    this.nefesDerinlik = 0;
    this.kameraGecen = 0;
    this.fazTohum = 0.7;

    // Adım zamanlayıcı
    this.adimGecen = 0;
    this.cumleSira = -1;
    this.kelimeSira = -1;
    this.cumleZamanlari = [];
    this.adimToplamSure = 8;
    this.aktifKutu = null;
    this.isikOpaklik = 0;

    // Duraklatma yumuşatması ve otomatik denetim gizleme
    this.zamanHizi = 1;
    this.sonDokunus = 0;
    this.gizleSuresi = ayar.gizleSuresi || 3.6;
    this.otomatikGizle = true;

    this._raf = null;
    this._sonT = 0;
    this._sesAktif = false;
  }

  DinleMotoru.prototype.eserDegistir = function (eserId) {
    if (!ESERLER[eserId]) return;
    this.sesDurdur();
    this.eser = ESERLER[eserId];
    this.plan = planKur(this.eser, this.sureDk);
    this.baslangicaDon(true);
  };

  DinleMotoru.prototype.sureDegistir = function (dk) {
    this.sureDk = dk;
    const eskiKip = this.kip;
    this.plan = planKur(this.eser, dk);
    if (eskiKip === 'oynuyor' || eskiKip === 'duraklatildi') {
      this.adimSira = clamp(this.adimSira, 0, this.plan.adimlar.length - 1);
      this.adimaGit(this.adimSira, true);
    }
    this._bildir();
  };

  DinleMotoru.prototype.hareketDegistir = function (az) {
    this.hareketAz = !!az;
    if (this.hareketAz) {
      this.canli = { u: this.hedef.u, v: this.hedef.v, z: this.hedef.z, anchorY: this.hedef.anchorY };
      this.kameraGecen = this.gecisSuresi;
      this.ciz();
    }
    this._bildir();
  };

  DinleMotoru.prototype.sesDegistir = function (acik) {
    this.sesli = !!acik;
    if (!this.sesli) this.sesDurdur();
    else if (this.kip === 'oynuyor') {
      const a = this.plan.adimlar[this.adimSira];
      if (a && a.cumleler && a.cumleler[this.cumleSira]) {
        this._cumleOku(a.cumleler[this.cumleSira]);
      }
    }
    this._bildir();
  };

  DinleMotoru.prototype.baslangicaDon = function (aninda) {
    this.sesDurdur();
    this.kip = 'baslangic';
    this.adimSira = 0;
    this.aktifKutu = null;
    this.denetimlerAcik = false;
    const h = hedefHesapla(null, this.eser, this.sahneW, this.sahneH, this.ayar.kameraSecenek);
    this._kamerayaGit(h, aninda ? 0 : 1.6, false);
    this.ciz();
    this._bildir();
  };

  DinleMotoru.prototype.baslat = function (baslangicAdim) {
    this.kip = 'oynuyor';
    this.denetimlerAcik = false;
    this.zamanHizi = 1;
    this.adimaGit(baslangicAdim || 0, false);
    this._donguyuBaslat();
  };

  DinleMotoru.prototype.duraklatSurdur = function () {
    if (this.kip === 'oynuyor') {
      this.kip = 'duraklatildi';
      this.denetimlerAcik = true;
      this.sesDurdur();
    } else if (this.kip === 'duraklatildi') {
      this.kip = 'oynuyor';
      this.sonDokunus = performance.now() / 1000;
      this._donguyuBaslat();
    } else if (this.kip === 'bitis') {
      this.baslat(0);
    }
    this._bildir();
  };

  DinleMotoru.prototype.denetimDokun = function (acik) {
    if (this.kip !== 'oynuyor' && this.kip !== 'duraklatildi') return;
    this.denetimlerAcik = typeof acik === 'boolean' ? acik : !this.denetimlerAcik;
    this.sonDokunus = performance.now() / 1000;
    this._bildir();
  };

  DinleMotoru.prototype.etkilesimKaydet = function () {
    this.sonDokunus = performance.now() / 1000;
  };

  DinleMotoru.prototype.sonraki = function () {
    if (this.adimSira + 1 < this.plan.adimlar.length) {
      this.kip = 'oynuyor';
      this.adimaGit(this.adimSira + 1, false);
    } else {
      this.bitir();
    }
  };

  DinleMotoru.prototype.onceki = function () {
    if (this.adimGecen > 3.2 && this.adimSira > 0) {
      this.adimaGit(this.adimSira, false);
    } else {
      this.adimaGit(Math.max(0, this.adimSira - 1), false);
    }
  };

  DinleMotoru.prototype.bitisteBak = function (noktaIndex) {
    if (noktaIndex < 0 || noktaIndex >= this.eser.noktalar.length) {
      this.aktifKutu = null;
      const tam = hedefHesapla(null, this.eser, this.sahneW, this.sahneH, this.ayar.kameraSecenek);
      this._kamerayaGit(tam, 2.2, false);
      this._donguyuBaslat();
      this._bildir();
      return;
    }
    const n = this.eser.noktalar[noktaIndex];
    const sahteAdim = { tur: 'nokta', kutu: n.kutu };
    this.aktifKutu = n.kutu;
    const h = hedefHesapla(sahteAdim, this.eser, this.sahneW, this.sahneH, this.ayar.kameraSecenek);
    this._kamerayaGit(h, 2.6, true);
    this._donguyuBaslat();
    this._bildir();
  };

  DinleMotoru.prototype.bitir = function (aninda) {
    this.sesDurdur();
    this.kip = 'bitis';
    this.denetimlerAcik = false;
    this.aktifKutu = null;
    this.cumleSira = -1;
    const tam = hedefHesapla(null, this.eser, this.sahneW, this.sahneH, this.ayar.kameraSecenek);
    this._kamerayaGit(tam, aninda ? 0 : 2.8, false);
    this._donguyuBaslat();
    this._bildir();
  };

  DinleMotoru.prototype.adimaGit = function (sira, aninda) {
    this.sesDurdur();
    this.adimSira = clamp(sira, 0, this.plan.adimlar.length - 1);
    const a = this.plan.adimlar[this.adimSira];
    this.adimGecen = 0;
    this.cumleSira = -1;
    this.kelimeSira = -1;
    this.aktifKutu = a.tur === 'nokta' ? a.kutu : null;
    this.fazTohum = (this.adimSira + 1) * 1.37;

    // Cümle zaman çizelgesi (DinlemeKurallari harf hızına orantılı, rahat okunur)
    let t = a.gecikme;
    this.cumleZamanlari = (a.cumleler || []).map(function (metin) {
      const sure = clamp(metin.length / 18.5 + 1.15, 2.5, 5.4);
      const kayit = { bas: t, bit: t + sure, metin: metin, kelimeler: metin.split(/\s+/) };
      t += sure + 0.38;
      return kayit;
    });
    this.adimToplamSure = Math.max(t + a.sessizlik, a.tur === 'sessiz' ? 6.5 : 4.5);

    const h = hedefHesapla(a, this.eser, this.sahneW, this.sahneH, this.ayar.kameraSecenek);
    const oncekiZ = this.canli.z;
    const d = Math.hypot(h.u - this.canli.u, h.v - this.canli.v);
    const gecis = a.gecisSuresi != null
      ? a.gecisSuresi
      : clamp(KAMERA_AYAR.gecisTaban + d * KAMERA_AYAR.gecisMesafe, KAMERA_AYAR.gecisEnAz, KAMERA_AYAR.gecisEnCok);
    const nefes = oncekiZ > 0.18 && h.z > 0.18 && d > 0.05;

    this._kamerayaGit(h, aninda ? 0 : gecis, nefes);
    if (aninda) {
      // Anlık kare çekiminde kamera yerleşmiş ve ilk cümle görünür olsun
      this.kameraGecen = this.gecisSuresi + 1.4;
      this.adimGecen = this.cumleZamanlari.length ? this.cumleZamanlari[0].bas + 1.35 : 2.0;
      this._zamanGuncelle(0);
    }
    this.ciz();
    this._bildir();
  };

  DinleMotoru.prototype._kamerayaGit = function (hedef, sure, nefesKullan) {
    this.bas = { u: this.canli.u, v: this.canli.v, z: this.canli.z, anchorY: this.canli.anchorY };
    this.hedef = { u: hedef.u, v: hedef.v, z: hedef.z, anchorY: hedef.anchorY };
    this.kameraGecen = 0;

    if (this.hareketAz || sure <= 0.01) {
      this.gecisSuresi = 0.001;
      this.nefesDerinlik = 0;
      this.canli = { u: hedef.u, v: hedef.v, z: hedef.z, anchorY: hedef.anchorY };
      if (this.hareketAz && this.ayar.caprazGecis) {
        this.ayar.caprazGecis(this.canli, this.eser);
      }
      return;
    }

    this.gecisSuresi = sure;
    if (nefesKullan) {
      const d = Math.hypot(hedef.u - this.bas.u, hedef.v - this.bas.v);
      this.nefesDerinlik = clamp(
        KAMERA_AYAR.nefesTaban + d * KAMERA_AYAR.nefesMesafe,
        KAMERA_AYAR.nefesTaban,
        KAMERA_AYAR.nefesEnCok
      );
    } else {
      this.nefesDerinlik = 0;
    }
  };

  DinleMotoru.prototype._donguyuBaslat = function () {
    if (this._raf) return;
    this._sonT = performance.now();
    const self = this;
    function kare(simdi) {
      const dt = Math.min(0.05, Math.max(0, (simdi - self._sonT) / 1000));
      self._sonT = simdi;
      self._zamanGuncelle(dt);
      self.ciz();
      self._raf = requestAnimationFrame(kare);
    }
    this._raf = requestAnimationFrame(kare);
  };

  DinleMotoru.prototype.durdurDongu = function () {
    if (this._raf) {
      cancelAnimationFrame(this._raf);
      this._raf = null;
    }
  };

  DinleMotoru.prototype._zamanGuncelle = function (dt) {
    // Duraklatınca kamera yumuşakça yavaşlar
    const hedefHiz = this.kip === 'duraklatildi' ? 0 : 1;
    this.zamanHizi += (hedefHiz - this.zamanHizi) * Math.min(1, dt * 6.5);
    const kDt = dt * this.zamanHizi;

    // Otomatik denetim gizleme (yalnız oynarken ve dokunulmadığında)
    if (this.otomatikGizle && this.kip === 'oynuyor' && this.denetimlerAcik) {
      const simdiSn = performance.now() / 1000;
      if (simdiSn - this.sonDokunus >= this.gizleSuresi) {
        this.denetimlerAcik = false;
        this._bildir();
      }
    }

    // Kamera ilerlemesi
    if (!this.hareketAz) {
      this.kameraGecen += kDt;
      if (this.kameraGecen < this.gecisSuresi) {
        const t = clamp(this.kameraGecen / this.gecisSuresi, 0, 1);
        const ep = egriKonum(t);
        const ez = egriOlcek(t);
        const nefes = this.nefesDerinlik > 0
          ? Math.pow(Math.sin(Math.PI * Math.pow(t, 0.88)), 1.55)
          : 0;
        this.canli.u = lerp(this.bas.u, this.hedef.u, ep);
        this.canli.v = lerp(this.bas.v, this.hedef.v, ep);
        this.canli.anchorY = lerp(this.bas.anchorY, this.hedef.anchorY, ep);
        this.canli.z = Math.max(0, lerp(this.bas.z, this.hedef.z, ez) - this.nefesDerinlik * nefes);
      } else {
        // Varış sonrası canlı süzülme (mikro-nefes)
        const tau = this.kameraGecen - this.gecisSuresi;
        const rampa = 1 - Math.exp(-tau / 2.2);
        const dz = Math.min(
          KAMERA_AYAR.suzmeSiniri,
          KAMERA_AYAR.suzmeHizi * (tau - 2.2 * (1 - Math.exp(-tau / 2.2)))
        );
        const canliCarpan = (this.kip === 'oynuyor' || (this.kip === 'bitis' && this.aktifKutu)) ? 1 : 0.35;
        this.canli.z = this.hedef.z + dz * canliCarpan;
        this.canli.u = this.hedef.u + KAMERA_AYAR.suzmeSalinimU * rampa * Math.sin(tau * 0.24 + this.fazTohum) * canliCarpan;
        this.canli.v = this.hedef.v + KAMERA_AYAR.suzmeSalinimV * rampa * Math.cos(tau * 0.19 + this.fazTohum) * canliCarpan;
        this.canli.anchorY = this.hedef.anchorY;
      }
    }

    // Ayrıntı ışığı opaklığı (kamera yerleşince yumuşakça doğar)
    if (this.aktifKutu) {
      const oran = this.hareketAz ? 1 : clamp((this.kameraGecen / this.gecisSuresi - 0.68) / 0.45, 0, 1);
      const yumusak = oran * oran * (3 - 2 * oran);
      this.isikOpaklik = this.denetimlerAcik ? yumusak * 0.55 : yumusak;
    } else {
      this.isikOpaklik = Math.max(0, this.isikOpaklik - dt * 2.5);
    }

    // Adım akışı (altyazı cümleleri ve kelime vurgusu)
    if (this.kip === 'oynuyor') {
      this.adimGecen += dt;
      let yeniCumle = -1;
      let yeniKelime = -1;
      for (let i = 0; i < this.cumleZamanlari.length; i++) {
        const c = this.cumleZamanlari[i];
        if (this.adimGecen >= c.bas && this.adimGecen <= c.bit + 0.35) {
          yeniCumle = i;
          const p = clamp((this.adimGecen - c.bas) / Math.max(0.1, c.bit - c.bas), 0, 1);
          yeniKelime = Math.min(c.kelimeler.length - 1, Math.floor(p * c.kelimeler.length));
          break;
        }
      }
      if (yeniCumle !== this.cumleSira) {
        this.cumleSira = yeniCumle;
        this.kelimeSira = yeniKelime;
        if (this.sesli && yeniCumle >= 0) {
          this._cumleOku(this.cumleZamanlari[yeniCumle].metin);
        }
        this._bildir();
      } else if (yeniKelime !== this.kelimeSira) {
        this.kelimeSira = yeniKelime;
        if (this.ayar.kelimeGuncelle) this.ayar.kelimeGuncelle(this);
      }

      if (this.adimGecen >= this.adimToplamSure) {
        this.sonraki();
      }
    }
  };

  DinleMotoru.prototype._cumleOku = function (metin) {
    if (!global.speechSynthesis || !metin) return;
    try {
      global.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(metin);
      u.lang = 'tr-TR';
      u.rate = 0.92;
      const sesler = global.speechSynthesis.getVoices();
      const tr = sesler.find(function (s) { return /^tr/i.test(s.lang); });
      if (tr) u.voice = tr;
      global.speechSynthesis.speak(u);
    } catch (e) {}
  };

  DinleMotoru.prototype.sesDurdur = function () {
    if (!global.speechSynthesis) return;
    try { global.speechSynthesis.cancel(); } catch (e) {}
  };

  DinleMotoru.prototype.ciz = function () {
    const tamPay = (this.ayar.kameraSecenek && this.ayar.kameraSecenek.tamPay) || 0;
    const y = kameraYerlesim(this.canli, this.eser, this.sahneW, this.sahneH, tamPay);
    const kutu = this.aktifKutu ? kutuEkranda(this.aktifKutu, y, this.sahneW, this.sahneH) : null;
    if (this.ayar.kareCiz) {
      this.ayar.kareCiz({
        yerlesim: y,
        kutu: kutu,
        isikOpaklik: this.isikOpaklik,
        canli: this.canli,
        eser: this.eser,
        motor: this
      });
    }
  };

  DinleMotoru.prototype._bildir = function () {
    if (this.ayar.durumDegisti) this.ayar.durumDegisti(this);
  };

  DinleMotoru.prototype.aktifCumle = function () {
    if (this.cumleSira < 0 || this.cumleSira >= this.cumleZamanlari.length) return null;
    return this.cumleZamanlari[this.cumleSira];
  };

  DinleMotoru.prototype.adimIlerleme = function () {
    return clamp(this.adimGecen / Math.max(1, this.adimToplamSure), 0, 1);
  };

  DinleMotoru.prototype.kalanSaniye = function () {
    // Gerçek seçilen sürenin (3 / 5 / 10 dk) görsel zaman tahmini
    const toplam = this.sureDk * 60;
    const adimPay = (this.adimSira + this.adimIlerleme()) / Math.max(1, this.plan.adimlar.length);
    return Math.max(0, Math.round(toplam * (1 - adimPay)));
  };

  function sureBicim(sn) {
    const dk = Math.floor(sn / 60);
    const s = sn % 60;
    return dk + ':' + (s < 10 ? '0' : '') + s;
  }

  /* ===== 5. URL PARAMETRELERİ (Ekran görüntüsü çekimi ve doğrudan durum açma) ===== */
  function urlParametreleri() {
    const p = new URLSearchParams(global.location.search);
    return {
      cek: p.get('cek') === '1',
      tema: p.get('tema'),
      durum: p.get('durum'), // baslangic | anlatim | denetim | bitis
      adim: p.has('adim') ? parseInt(p.get('adim'), 10) : 2,
      eser: p.get('eser') || 'nedimeler',
      hareket: p.get('hareket') === 'az'
    };
  }

  global.DinleCekirdek = {
    ESERLER: ESERLER,
    KAMERA_AYAR: KAMERA_AYAR,
    planKur: planKur,
    hedefHesapla: hedefHesapla,
    kameraYerlesim: kameraYerlesim,
    kutuEkranda: kutuEkranda,
    DinleMotoru: DinleMotoru,
    sureBicim: sureBicim,
    urlParametreleri: urlParametreleri
  };
})(window);

/* ============================================================================
   Nora Sanat · Hikâyeler Sekmesi — Ortak Veri ve Fola Zamanlama Motoru
   Veri şeması:
   { baslik, alt_baslik, giris, bolumler:[{ baslik, yillar, paragraflar, eserler:[{ qid, bag }] }],
     kapanis, baglantilar:[{ sanatci, id, iliski }], kaynaklar:[{ baslik, adres }], kelime }
   Görseller: Wikimedia Commons Special:FilePath (yerel kopyalar: gorseller/)
   ============================================================================ */
(function (global) {
  'use strict';

  /* Nora Sanat SekmeCubugu.swift (24x24 viewBox, 1.5px yuvarlak çizgi) ile birebir uyumlu simgeler */
  const SEKME_IKONLARI = {
    bugun:
      '<rect x="4" y="3.5" width="16" height="17" rx="1.5"/><rect x="7.5" y="7" width="9" height="10"/>',
    hikayeler:
      '<path d="M4.5 5.5c2.2 0 4.8.6 7.5 2 2.7-1.4 5.3-2 7.5-2v12.8c-2.2 0-4.8.6-7.5 2-2.7-1.4-5.3-2-7.5-2z"/><path d="M12 7.5v12.8"/><path d="M15.6 6.2v4.6l1.3-1 1.3 1V5.7"/>',
    yolculuk:
      '<path d="M6 20c0-4 12-4 12-8s-12-4-12-8"/><circle cx="6" cy="20" r="1.4"/><circle cx="6" cy="4" r="1.4"/>',
    galeri:
      '<rect x="3.5" y="4" width="7.5" height="9"/><rect x="13.5" y="4" width="7" height="5.5"/><rect x="13.5" y="12" width="7" height="8"/><rect x="3.5" y="15.5" width="7.5" height="4.5"/>',
    calis:
      '<path d="M20 4l-9 9"/><path d="M11 13c-2.2-.6-4.6.8-5 3.2-.2 1.4-.9 2.4-2.5 3 3.4 1.2 8.3.3 9-3.4.2-1-.4-2.1-1.5-2.8z"/>',
    ben:
      '<circle cx="12" cy="8.2" r="3.4"/><path d="M5.2 19.2c1.4-3.2 4-4.7 6.8-4.7s5.4 1.5 6.8 4.7"/>'
  };

  function ikonSvg(ad, boyut, kalinlik) {
    const b = boyut || 22;
    const k = kalinlik || 1.5;
    return (
      '<svg width="' + b + '" height="' + b + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
      'stroke-width="' + k + '" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      (SEKME_IKONLARI[ad] || '') +
      '</svg>'
    );
  }

  /* İki tam hikâye: Caravaggio ve Artemisia Gentileschi + Katalogdaki diğer sanatçılar */
  const HIKAYELER = {
    caravaggio: {
      id: 'caravaggio',
      sanatci: 'Caravaggio',
      tamAd: 'Michelangelo Merisi da Caravaggio',
      donem: 'Barok',
      donemAnahtar: 'barok',
      akim: 'İtalyan Barok',
      yuzyil: 'XVI–XVII. yüzyıl',
      yillar: '1571–1610',
      sureDk: 15,
      kelime: 2280,
      baslik: 'Karanlığın içindeki bıçak',
      alt_baslik: 'Roma sokaklarından Malta zindanlarına, ışığı keskinleştiren bir ömür',
      kapak: 'gorseller/caravaggio-matta-cagri.jpg',
      kapakEser: 'Aziz Matta’nın Çağrılışı, 1599–1600',
      hale: ['168, 114, 58', '82, 46, 36'],
      ilerleme: { durum: 'suruyor', oran: 0.44, kalanDk: 9, bolumIndex: 1, saniye: 396 },
      kirilmaOzeti: ['Veba ve yetimlik', 'Roma tavan arası', 'Contarelli kırılması', '1606 düellosu ve sürgün'],
      giris: [
        '1592 yazında Milano’dan Roma’ya yürüyerek gelen yirmi bir yaşındaki Michelangelo Merisi’nin cebinde ne koruyucu bir tavsiye mektubu ne de büyük bir atölye sözü vardı. Onu bekleyen şehir, kiliseleri yenileyen ama sokakları kılıç kavgalarıyla çalkalanan gergin bir başkentti.',
        'On sekiz yıl sonra Porto Ercole kıyısında tek başına ateşler içinde öldüğünde, Avrupa resminin ışığa bakış biçimini geri dönülmez biçimde değiştirmişti. Onun karanlığı bir süs değildi; vebanın, davaların, bir cinayetin ve bitmeyen kaçışın tuvaldeki gölgesiydi.'
      ],
      bolumler: [
        {
          baslik: 'Sokaktan gelen çıplak gerçek',
          kisaAd: 'Roma',
          yillar: '1592–1596',
          sureDk: 3,
          kirilma: 'Hastalıklı ilk yıllar ve Kardinal Del Monte’nin keşfi',
          paragraflar: [
            'Roma’daki ilk yıllarında Caravaggio, Giuseppe Cesari’nin atölyesinde sabah akşam çiçek ve meyve boyadı. Bir at tekmesiyle bacağı parçalanıp Santa Maria della Consolazione hastanesinde altı ay yatınca, ölümün ve acının ten üzerindeki izi belleğine kazındı.',
            'İyileştikten sonra antik heykelleri kopyalamayı bıraktı. Aynanın karşısına geçip kendi yüzünü, pazardan çağırdığı çocukları ve meyvelerin üzerindeki çürük lekelerini olduğu gibi boyadı. İdeal güzelliğin yerine anlık bir irkilmeyi koyduğunda Kardinal Francesco Maria del Monte’nin dikkatini çekti.'
          ],
          eserler: [
            {
              qid: 'Q2482924',
              ad: 'Kertenkele Isıran Çocuk',
              yil: '1594',
              muze: 'National Gallery, Londra',
              gorsel: 'gorseller/caravaggio-kertenkele.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/Caravaggio_-_Boy_Bitten_by_a_Lizard.jpg?width=1200',
              oran: '1280 / 1721',
              bag: 'Del Monte’nin sarayına girmeden hemen önce yaptığı bu erken resimde, Caravaggio ilk kez donuk bir pozu değil, saniyenin onda birindeki acı ve şaşkınlık refleksini yakalar.'
            }
          ]
        },
        {
          baslik: 'Contarelli Şapeli ve ışığın hüküm anı',
          kisaAd: 'Contarelli',
          yillar: '1599–1600',
          sureDk: 4,
          kirilma: 'İlk büyük kamusal sipariş ve Roma’nın sarsılışı',
          paragraflar: [
            'Kardinal Del Monte’nin aracılığıyla aldığı San Luigi dei Francesi kilisesindeki Contarelli Şapeli siparişi, Caravaggio’nun hayatındaki en büyük eşikti. O güne dek küçük oda resimleri yapan genç ressam, birden üç metrelik iki dev tuvalin karşısında kaldı.',
            'Aziz Matta’nın çağrılışını bulutlar arasında değil, Roma’nın karanlık bir vergi masasında kurguladı. Sağ üstteki yüksek pencereden diyagonal bir bıçak gibi inen ışık, İsa’nın parmağını izleyip şaşkınlıkla göğsünü gösteren Matta’nın yüzüne düşüyordu. Yan duvardaki şehadet sahnesinde ise kalabalığın paniğinin ortasına, arka planda kendi kaygılı yüzünü de yerleştirdi.'
          ],
          eserler: [
            {
              qid: 'Q504556',
              ad: 'Aziz Matta’nın Çağrılışı',
              yil: '1599–1600',
              muze: 'San Luigi dei Francesi, Roma',
              gorsel: 'gorseller/caravaggio-matta-cagri.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/Caravaggio,_Michelangelo_Merisi_da_-_The_Calling_of_Saint_Matthew_-_1599-1600_(hi_res).jpg?width=1200',
              oran: '1280 / 1197',
              bag: 'Şapelin sol duvarında, kilisenin gerçek penceresiyle aynı açıdan gelen ışık, sıradan bir para masasını ilahi bir karar anına dönüştürür.'
            },
            {
              qid: 'Q1074285',
              ad: 'Aziz Matta’nın Şehadeti',
              yil: '1599–1600',
              muze: 'San Luigi dei Francesi, Roma',
              gorsel: 'gorseller/caravaggio-matta-sehadet.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/The_Martyrdom_of_Saint_Matthew-Caravaggio_(c._1599-1600).jpg?width=1200',
              oran: '1280 / 1125',
              bag: 'Röntgen taramaları Caravaggio’nun bu tuvali defalarca silip yeniden kurduğunu gösterir; arkadaki sakallı tanık, şiddetin hem faili hem seyircisi olan kendi otoportresidir.'
            }
          ]
        },
        {
          baslik: 'Aynı masada mucize, dışarıda mahkeme',
          kisaAd: 'Emmaus',
          yillar: '1601–1605',
          sureDk: 4,
          kirilma: 'Baglione hakaret davası ve şöhretle gelen öfke',
          paragraflar: [
            'Şapelin açılmasıyla Caravaggio bir gecede Roma’nın en çok konuşulan ressamı oldu; ama ünü kadar düşmanları da çoğaldı. 1603’te rakibi Giovanni Baglione, sokaklarda dağıtılan alaycı hiciv şiirleri yüzünden Caravaggio’yu ve dostu Orazio Gentileschi’yi mahkemeye verdi.',
            'Polis tutanakları enginar tabağı fırlatmaktan izinsiz kılıç taşımaya uzanan kavgalarla dolarken, tuvalindeki sessizlik derinleşiyordu. Emmaus’ta Akşam Yemeği’nde dirilen İsa’yı yaldızlı bir hale içinde değil, yırtık ceketli iki yolcunun tam karşısında, masanın ucundan neredeyse düşecek bir meyve sepetinin ardında resmetti.'
          ],
          eserler: [
            {
              qid: 'Q1152627',
              ad: 'Emmaus’ta Akşam Yemeği',
              yil: '1601',
              muze: 'National Gallery, Londra',
              gorsel: 'gorseller/caravaggio-emmaus.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/Supper_at_Emmaus-Caravaggio_(1601).jpg?width=1200',
              oran: '1280 / 910',
              bag: 'İki havarinin fırlayıp açılan kolları, seyirciyi doğrudan masanın dördüncü kenarına çeker; sokak gürültüsünün ortasında doğan en yalın tanıma anıdır.'
            }
          ]
        },
        {
          baslik: 'Düello, sürgün ve kararan gölge',
          kisaAd: 'Sürgün',
          yillar: '1606–1610',
          sureDk: 4,
          kirilma: '28 Mayıs 1606’da Ranuccio Tomassoni’nin ölümü ve başı için konulan ödül',
          paragraflar: [
            '28 Mayıs 1606 akşamı Campo Marzio’da bir tenis kortunda başlayan tartışma kılıç düellosuna döndü. Caravaggio, Ranuccio Tomassoni’yi ölümcül biçimde yaraladı; Papa’nın fermanıyla Roma’dan kaçmak zorunda kaldı. Artık şehrin herhangi bir sokağında onu öldüren kişi ödüllendirilecekti.',
            'Napoli, Malta ve Sicilya arasında geçen son dört yılda paleti neredeyse tamamen koyu toprak, kül ve kömüre çekildi. Malta’da şövalye ilan edildikten kısa süre sonra yeni bir kavgayla zindana atıldı, iplerle surlardan inip kaçtı. 1610 yazında affedildiği haberiyle Roma’ya dönerken Porto Ercole’de ateşler içinde kaldı.'
          ],
          eserler: []
        }
      ],
      kapanis: [
        'Caravaggio ardında hiçbir çizim defteri, tek bir atölye öğrencisi bırakmadı. Yine de ölümünden sonraki yirmi yıl içinde Roma’dan Utrecht’e, Sevilla’dan Napoli’ye bütün bir kuşak karanlığı onun gibi kesmeyi öğrendi.',
        'En beklenmedik mirasçısı ise, bir zamanlar Roma’da yanında duran Orazio Gentileschi’nin genç kızı Artemisia olacaktı.'
      ],
      baglantilar: [
        {
          sanatci: 'Artemisia Gentileschi',
          id: 'artemisia',
          iliski: 'etkiledi',
          iliskiEtiketi: 'Etkilediği',
          yon: 'ileri',
          yillar: '1593–1656',
          ozet: 'Caravaggio’nun keskin bodrum ışığını ve fiziksel gerilimini kadın öznelerin iradesine ve öfkesine taşıdı.',
          gorsel: 'gorseller/artemisia-judith.jpg',
          hikayesiVar: true
        },
        {
          sanatci: 'Simone Peterzano',
          id: 'peterzano',
          iliski: 'hoca',
          iliskiEtiketi: 'Hocası',
          yon: 'geri',
          yillar: '1535–1599',
          ozet: 'Milano’da dört yıl çırağı oldu; Tiziano’nun öğrencisi olan Peterzano’dan Venedik rengini ve dramatik gölgeyi devraldı.',
          gorsel: 'gorseller/caravaggio-kertenkele.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Orazio Gentileschi',
          id: 'orazio',
          iliski: 'dost',
          iliskiEtiketi: 'Dost ve takipçi',
          yon: 'yan',
          yillar: '1563–1639',
          ozet: '1603 Baglione davasında birlikte yargılandılar; Caravaggio’nun sert ışığını berrak, lirik bir dinginliğe çevirdi.',
          gorsel: 'gorseller/artemisia-susanna.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Giovanni Baglione',
          id: 'baglione',
          iliski: 'rakip',
          iliskiEtiketi: 'Rakibi',
          yon: 'yan',
          yillar: '1566–1643',
          ozet: 'Alaycı şiirler yüzünden Caravaggio’yu mahkemeye verdi; buna rağmen resminin karanlık dilini taklit etti ve ilk biyografisini yazdı.',
          gorsel: 'gorseller/caravaggio-matta-sehadet.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Diego Velázquez',
          id: 'velazquez',
          iliski: 'etkiledi',
          iliskiEtiketi: 'Etkilediği',
          yon: 'ileri',
          yillar: '1599–1660',
          ozet: 'Sevilla’daki erken mutfak ve meyhanecilik sahnelerini doğrudan Caravaggio’nun ışığıyla kurdu.',
          gorsel: 'gorseller/velazquez-nedimeler.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Rembrandt van Rijn',
          id: 'rembrandt',
          iliski: 'etkiledi',
          iliskiEtiketi: 'Etkilediği',
          yon: 'ileri',
          yillar: '1606–1669',
          ozet: 'Utrecht Caravaggiocuları aracılığıyla tanıdığı keskin ışık-gölgeyi içsel psikolojinin ve yaşlılığın derinliğine dönüştürdü.',
          gorsel: 'gorseller/rembrandt-gece-nobeti.jpg',
          hikayesiVar: false
        }
      ],
      kaynaklar: [
        {
          baslik: 'Helen Langdon — Caravaggio: A Life (Farrar, Straus and Giroux, 1998)',
          adres: 'https://www.worldcat.org/title/caravaggio-a-life/oclc/40126397',
          tur: 'Monografi'
        },
        {
          baslik: 'Andrew Graham-Dixon — Caravaggio: A Life Sacred and Profane (Allen Lane, 2010)',
          adres: 'https://www.penguin.co.uk/books/54705/caravaggio',
          tur: 'Monografi'
        },
        {
          baslik: 'National Gallery, Londra — Boy Bitten by a Lizard ve Supper at Emmaus katalog notları',
          adres: 'https://www.nationalgallery.org.uk/artists/michelangelo-merisi-da-caravaggio',
          tur: 'Müze kataloğu'
        },
        {
          baslik: 'San Luigi dei Francesi, Contarelli Şapeli röntgen ve arşiv kayıtları (1599–1600)',
          adres: 'https://www.wga.hu/html/c/caravagg/',
          tur: 'Arşiv'
        }
      ]
    },

    artemisia: {
      id: 'artemisia',
      sanatci: 'Artemisia Gentileschi',
      tamAd: 'Artemisia Lomi Gentileschi',
      donem: 'Barok',
      donemAnahtar: 'barok',
      akim: 'İtalyan Barok',
      yuzyil: 'XVII. yüzyıl',
      yillar: '1593–1656',
      sureDk: 14,
      kelime: 2060,
      baslik: 'Fırçayla geri alınan söz',
      alt_baslik: 'Bir davanın küllerinden Floransa akademisine ve kendi alegorisine yürüyen ressam',
      kapak: 'gorseller/artemisia-judith.jpg',
      kapakEser: 'Holofernes’in Başını Kesen Judith, 1613',
      hale: ['156, 78, 62', '128, 96, 54'],
      ilerleme: { durum: 'yeni', oran: 0, kalanDk: 14, bolumIndex: 0, saniye: 0 },
      kirilmaOzeti: ['Babasının atölyesi', '1611–1612 Tassi davası', 'Floransa akademisi', 'Londra ve La Pittura'],
      giris: [
        '1610 yılında Roma’daki küçük bir ev atölyesinde on yedi yaşındaki Artemisia Gentileschi, tuvalin alt kenarına kendi adını ve tarihini yazdı. O çağda kadın ressamlar ancak küçük portreler ve natürmortlar yaparken, o ilk imzasını büyük bir tarih sahnesinin altına atmıştı.',
        'İki yıl sonra bütün Roma’nın diline düşen ağır bir yargılamanın ardından şehri terk etmek zorunda kaldı. Ama sessizliğe çekilmek yerine, Caravaggio’dan devraldığı karanlık ışığı kendi deneyiminin keskin dili hâline getirdi.'
      ],
      bolumler: [
        {
          baslik: 'Babasının atölyesinde sıkışmış bir bakış',
          kisaAd: 'Susanna',
          yillar: '1608–1610',
          sureDk: 3,
          kirilma: 'On yedi yaşında imzalanan ilk büyük tuval',
          paragraflar: [
            'Annesini on iki yaşında kaybeden Artemisia, Roma’da ressam Orazio Gentileschi’nin tek kızı olarak boya öğüterek büyüdü. Erkek kardeşleri fırçayı bırakırken, Orazio kızının yeteneğini erkenden fark edip onu evde eğitti; o yıllarda kadınların sanat akademilerine girmesi yasaktı.',
            '1610’da tamamladığı Susanna ve İhtiyarlar, geleneksel erotik yorumların tam tersidir. İki yaşlı adam taş korkuluğun üzerinden Susanna’nın omuzlarına doğru karanlık bir duvar gibi eğilir; genç kadının bedeni zevkle değil, gerçek bir bunalım ve geri çekilmeyle bükülür.'
          ],
          eserler: [
            {
              qid: 'Q2388672',
              ad: 'Susanna ve İhtiyarlar',
              yil: '1610',
              muze: 'Schloss Weißenstein, Pommersfelden',
              gorsel: 'gorseller/artemisia-susanna.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/Susanna_and_the_Elders_(1610),_Artemisia_GentileschiFXD.jpg?width=1200',
              oran: '1280 / 1819',
              bag: 'Henüz on yedi yaşındayken yaptığı bu ilk imzalı eserde, gözetlenmenin ve baskının fiziksel ağırlığını çağının hiçbir erkek ressamının kurmadığı bir yakınlıkla çizer.'
            }
          ]
        },
        {
          baslik: '1612 davası ve sıvanmış kolların kararlılığı',
          kisaAd: '1612 davası',
          yillar: '1611–1613',
          sureDk: 4,
          kirilma: 'Agostino Tassi davası, parmak işkencesi ve Roma’dan ayrılış',
          paragraflar: [
            'Orazio, kızına perspektif öğretmesi için meslektaşı Agostino Tassi’yi eve davet etti. Mayıs 1611’de Tassi, Artemisia’ya saldırdı ve ardından evlilik vaadiyle aylarca oyaladı. 1612’de açılan davada mahkeme, Artemisia’nın sözünü sınamak için parmaklarına ip sıkılan sibille işkencesi uyguladı; o ise acı içinde bile ifadesini değiştirmedi.',
            'Dava Tassi’ye kısa bir sürgün cezasıyla kapandı, ancak asıl yankısı Artemisia’nın Floransa’ya giderken yaptığı Judith’te duyuldu. Önceki ressamlarda narin ve tereddütlü çizilen Judith, Artemisia’nın tuvalinde kollarını sıvamış, yardımcısı Abra ile omuz omuza fiziksel bir ağırlığı yöneten soğukkanlı bir figüre dönüştü.'
          ],
          eserler: [
            {
              qid: 'Q698483',
              ad: 'Holofernes’in Başını Kesen Judith',
              yil: '1613',
              muze: 'Museo di Capodimonte, Napoli',
              gorsel: 'gorseller/artemisia-judith.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/Artemisia_Gentileschi_-_Judith_Beheading_Holofernes_-_WGA8563.jpg?width=1200',
              oran: '1178 / 1500',
              bag: 'Davanın hemen ardından yapılan bu tabloda Caravaggio’nun sert ışığı, iki kadının ortak gücü ve merhametsiz anatomik gerçekçilikle birleşir.'
            }
          ]
        },
        {
          baslik: 'Floransa akademisi ve Galileo’nun mektupları',
          kisaAd: 'Floransa',
          yillar: '1614–1620',
          sureDk: 3,
          kirilma: 'Accademia delle Arti del Disegno’ya kabul edilen ilk kadın',
          paragraflar: [
            'Floransa’da Medici sarayının himayesine giren Artemisia, 1616’da Michelangelo’nun kurduğu Accademia delle Arti del Disegno’ya kabul edilen ilk kadın ressam oldu. Bu üyelik ona kendi adına sözleşme imzalama ve boya satın alma hakkı verdi.',
            'Aynı yıllarda Galileo Galilei ile mektuplaştı; fizikçinin eğik atış ve parabol yasaları, daha sonra Floransa’da yeniden boyadığı Judith’teki kan yaylarının geometrisinde bile iz bırakacaktı.'
          ],
          eserler: []
        },
        {
          baslik: 'La Pittura: Kendi sanatının bedeni',
          kisaAd: 'La Pittura',
          yillar: '1630–1639',
          sureDk: 4,
          kirilma: 'Napoli’de kendi atölyesi ve Londra sarayına yolculuk',
          paragraflar: [
            'Roma, Venedik ve Napoli’de kendi büyük atölyesini kurduktan sonra 1638’de yaşlı babasına yardım etmek üzere Londra’da Kral I. Charles’ın sarayına gitti. Artık siparişlerin fiyatını kendi belirleyen, koleksiyonculara “bir kadının neler yapabileceğini göstereceğim” diye mektup yazan bağımsız bir ustaydı.',
            'Resim Sanatının Alegorisi olarak Otoportre’sinde, Cesare Ripa’nın kitabında daima bir kadın olarak tanımlanan “Resim” alegorisini kendi bedeniyle birleştirdi. Hiçbir erkek ressamın yapamayacağı bu hamlede, hem özne hem ressam aynı kişiydi.'
          ],
          eserler: [
            {
              qid: 'Q1174885',
              ad: 'Resim Sanatının Alegorisi Olarak Otoportre (La Pittura)',
              yil: '1630',
              muze: 'Royal Collection, Londra',
              gorsel: 'gorseller/artemisia-otoportre.jpg',
              commons: 'https://commons.wikimedia.org/wiki/Special:FilePath/Self-portrait_as_the_Allegory_of_Painting_(La_Pittura)_-_Artemisia_Gentileschi.jpg?width=1200',
              oran: '1280 / 1729',
              bag: 'Boynundaki altın maske zinciri, dağınık saçları ve tuvale uzanan keskin kol açısıyla Artemisia, kendini yalnızca bir model değil, doğrudan sanatın kendisi ilan eder.'
            }
          ]
        }
      ],
      kapanis: [
        'Artemisia Gentileschi, yüzyıllar boyunca yalnızca babasının kızı ya da bir mahkeme tutanağının mağduru olarak anıldı. Oysa elli yılı aşan kariyerinde Avrupa’nın en güçlü saraylarına eser veren kararlı bir atölye ustasıydı.',
        'Caravaggio’nun başlattığı dramatik ışık dilini bir ömür boyu taşıdı; karanlığı bir kaçış değil, görünür olma aracına çevirdi.'
      ],
      baglantilar: [
        {
          sanatci: 'Caravaggio',
          id: 'caravaggio',
          iliski: 'etkilendi',
          iliskiEtiketi: 'Etkilendiği',
          yon: 'geri',
          yillar: '1571–1610',
          ozet: 'Babasının dostu olan Caravaggio’nun keskin ışık-gölge dilini ve sahici ten gözlemini kendi anlatısının temeli yaptı.',
          gorsel: 'gorseller/caravaggio-matta-cagri.jpg',
          hikayesiVar: true
        },
        {
          sanatci: 'Orazio Gentileschi',
          id: 'orazio',
          iliski: 'hoca',
          iliskiEtiketi: 'Hocası ve babası',
          yon: 'geri',
          yillar: '1563–1639',
          ozet: 'İlk eğitimini atölyesinde aldı; yıllar sonra Londra’da Greenwich Kraliçe Evi tavanında son kez yan yana çalıştılar.',
          gorsel: 'gorseller/artemisia-susanna.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Agostino Tassi',
          id: 'tassi',
          iliski: 'dava',
          iliskiEtiketi: '1612 davası',
          yon: 'yan',
          yillar: '1578–1644',
          ozet: 'Perspektif öğretmeni olarak girdiği evde 1611’de saldırdı; 1612 yargılaması Artemisia’nın Roma’yı bırakıp kendi yolunu çizmesine yol açtı.',
          gorsel: 'gorseller/artemisia-judith.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Cristofano Allori',
          id: 'allori',
          iliski: 'rakip',
          iliskiEtiketi: 'Floransa’da çağdaş',
          yon: 'yan',
          yillar: '1577–1621',
          ozet: 'Aynı yıllarda Floransa’da kendi Judith yorumunu yaptı; Artemisia’nın dramatik sahnesi onun soğuk zarafetine doğrudan yanıt verdi.',
          gorsel: 'gorseller/artemisia-otoportre.jpg',
          hikayesiVar: false
        },
        {
          sanatci: 'Elisabetta Sirani',
          id: 'sirani',
          iliski: 'etkiledi',
          iliskiEtiketi: 'Etkilediği',
          yon: 'ileri',
          yillar: '1638–1665',
          ozet: 'Bologna’da kadın ressamlar için ilk akademiyi kurarken Artemisia’nın açtığı bağımsız atölye geleneğini sürdürdü.',
          gorsel: 'gorseller/artemisia-otoportre.jpg',
          hikayesiVar: false
        }
      ],
      kaynaklar: [
        {
          baslik: 'Mary D. Garrard — Artemisia Gentileschi: The Image of the Female Hero in Italian Baroque Art (Princeton, 1989)',
          adres: 'https://press.princeton.edu/books/paperback/9780691002859/artemisia-gentileschi',
          tur: 'Monografi'
        },
        {
          baslik: 'Letizia Treves — Artemisia (National Gallery, Londra sergi kataloğu, 2020)',
          adres: 'https://www.nationalgallery.org.uk/exhibitions/past/artemisia',
          tur: 'Müze kataloğu'
        },
        {
          baslik: 'Elizabeth S. Cohen — The Trials of Artemisia Gentileschi: A Rape as History (Sixteenth Century Journal, 2000)',
          adres: 'https://www.jstor.org/stable/2671289',
          tur: 'Arşiv incelemesi'
        },
        {
          baslik: 'Royal Collection Trust — Self-Portrait as the Allegory of Painting (La Pittura) envanter kaydı',
          adres: 'https://www.rct.uk/collection/405551',
          tur: 'Müze kataloğu'
        }
      ]
    }
  };

  /* Ana ekranda döneme/akıma göre gezilen sanatçı kataloğu (Caravaggio ve Artemisia tam açılır) */
  const KATALOG = [
    {
      id: 'caravaggio',
      sanatci: 'Caravaggio',
      donem: 'Barok',
      akim: 'İtalyan Barok',
      yuzyil: 'XVII. yüzyıl',
      yillar: '1571–1610',
      baslik: 'Karanlığın içindeki bıçak',
      alt_baslik: 'Roma sokaklarından Malta zindanlarına, ışığı keskinleştiren bir ömür',
      sureDk: 15,
      kapak: 'gorseller/caravaggio-matta-cagri.jpg',
      hale: ['168, 114, 58', '82, 46, 36'],
      ilerleme: { durum: 'suruyor', oran: 0.44, kalanDk: 9, bolumAdi: 'Contarelli Şapeli ve ışığın hüküm anı', mod: 'dinle' },
      kirilmalar: ['Roma', 'Contarelli', '1606 düellosu', 'Malta'],
      tam: true
    },
    {
      id: 'artemisia',
      sanatci: 'Artemisia Gentileschi',
      donem: 'Barok',
      akim: 'İtalyan Barok',
      yuzyil: 'XVII. yüzyıl',
      yillar: '1593–1656',
      baslik: 'Fırçayla geri alınan söz',
      alt_baslik: 'Bir davanın küllerinden Floransa akademisine ve kendi alegorisine yürüyen ressam',
      sureDk: 14,
      kapak: 'gorseller/artemisia-judith.jpg',
      hale: ['156, 78, 62', '128, 96, 54'],
      ilerleme: { durum: 'yeni', oran: 0, kalanDk: 14, bolumAdi: '', mod: 'oku' },
      kirilmalar: ['Susanna', '1612 davası', 'Floransa', 'La Pittura'],
      tam: true
    },
    {
      id: 'velazquez',
      sanatci: 'Diego Velázquez',
      donem: 'Barok',
      akim: 'İspanyol Barok',
      yuzyil: 'XVII. yüzyıl',
      yillar: '1599–1660',
      baslik: 'Aynadaki kraliyet sessizliği',
      alt_baslik: 'Sevilla’nın karanlık mutfaklarından Madrid sarayının optik bilmecesine',
      sureDk: 13,
      kapak: 'gorseller/velazquez-nedimeler.jpg',
      hale: ['138, 108, 76', '68, 56, 48'],
      ilerleme: { durum: 'suruyor', oran: 0.22, kalanDk: 10, bolumAdi: 'Madrid’de saray ressamı', mod: 'oku' },
      kirilmalar: ['Sevilla', 'IV. Felipe', 'İtalya', 'Nedimeler'],
      tam: false
    },
    {
      id: 'rembrandt',
      sanatci: 'Rembrandt van Rijn',
      donem: 'Altın Çağ',
      akim: 'Hollanda Altın Çağı',
      yuzyil: 'XVII. yüzyıl',
      yillar: '1606–1669',
      baslik: 'İflasın içindeki altın ışık',
      alt_baslik: 'Amsterdam’ın en zengin atölyesinden Saskia’nın kaybına ve çıplak otoportrelere',
      sureDk: 16,
      kapak: 'gorseller/rembrandt-gece-nobeti.jpg',
      hale: ['164, 122, 66', '58, 48, 38'],
      ilerleme: { durum: 'bitti', oran: 1, kalanDk: 0, bolumAdi: 'Tamamlandı', mod: 'dinle' },
      kirilmalar: ['Gece Nöbeti', 'Saskia', 'İflas', 'Son otoportreler'],
      tam: false
    },
    {
      id: 'goya',
      sanatci: 'Francisco Goya',
      donem: 'Romantizm',
      akim: 'İspanyol Romantizmi',
      yuzyil: 'XVIII–XIX. yüzyıl',
      yillar: '1746–1828',
      baslik: 'Sağırlığın duvarındaki kâbuslar',
      alt_baslik: 'Saray portrecisinden savaş gravürlerine ve Sağır’ın Evi’ndeki Kara Resimlere',
      sureDk: 15,
      kapak: 'gorseller/goya-saturn.jpg',
      hale: ['142, 86, 62', '56, 44, 38'],
      ilerleme: { durum: 'yeni', oran: 0, kalanDk: 15, bolumAdi: '', mod: 'dinle' },
      kirilmalar: ['1792 sağırlığı', 'Savaş', 'Quinta del Sordo', 'Bordeaux'],
      tam: false
    }
  ];

  const DONEMLER = ['Tümü', 'Barok', 'Altın Çağ', 'Romantizm'];

  /* ============================================================================
     Fola Ses & Kelime Zamanlama Motoru
     - Her bölümün paragraflarını cümlelere ve kelimelere böler
     - 15 sn ileri/geri, bölüm atlama, hız (0.85x / 1x / 1.25x / 1.5x) destekler
     - O anki bölümün eserini ve kelime indeksini canlı bildirir
     ============================================================================ */
  function cumlelereBol(metin) {
    const ham = metin.match(/[^.!?…]+[.!?…]?/g) || [metin];
    return ham.map(function (c) { return c.trim(); }).filter(Boolean);
  }

  function bolumSesPlaniKur(hikaye) {
    const parcalar = [];
    let t = 0;
    const bolumBaslangiclari = [];

    hikaye.bolumler.forEach(function (bolum, bIndex) {
      bolumBaslangiclari.push(t);
      const eserler = bolum.eserler && bolum.eserler.length ? bolum.eserler : null;
      const varsayilanEser = eserler
        ? eserler[0]
        : {
            ad: hikaye.kapakEser,
            yil: bolum.yillar,
            muze: hikaye.akim,
            gorsel: hikaye.kapak,
            bag: bolum.kirilma
          };

      const cumleler = [];
      bolum.paragraflar.forEach(function (p) {
        cumlelereBol(p).forEach(function (c) { cumleler.push(c); });
      });

      cumleler.forEach(function (cumle, cIdx) {
        const kelimeler = cumle.split(/\s+/).filter(Boolean);
        // Doğal Fola konuşma temposu: ~2.6 kelime/sn + noktalama nefesi
        const sure = Math.max(2.4, kelimeler.length / 2.55 + 0.5);
        const eser = eserler && eserler.length > 1 && cIdx >= Math.floor(cumleler.length / 2)
          ? eserler[1]
          : varsayilanEser;
        parcalar.push({
          bolumIndex: bIndex,
          bolumBaslik: bolum.baslik,
          yillar: bolum.yillar,
          kirilma: bolum.kirilma,
          metin: cumle,
          kelimeler: kelimeler,
          eser: eser,
          bas: t,
          bit: t + sure
        });
        t += sure;
      });
    });

    // Gerçekçi 14-15 dakikalık hikâye ölçeği (zaman göstergesi için oran)
    const gercekToplam = hikaye.sureDk * 60;
    return {
      parcalar: parcalar,
      bolumBaslangiclari: bolumBaslangiclari,
      icToplam: Math.max(1, t),
      gercekToplam: gercekToplam
    };
  }

  function sureYaz(sn) {
    const s = Math.max(0, Math.round(sn));
    const dk = Math.floor(s / 60);
    const k = s % 60;
    return dk + ':' + (k < 10 ? '0' : '') + k;
  }

  function FolaMotoru(hikaye, secenek) {
    this.ayar = secenek || {};
    this.oynuyor = false;
    this.hizlar = [0.85, 1, 1.25, 1.5];
    this.hizIndex = 1;
    this.sesli = false;
    this.sonOkunanParca = -1;
    this._raf = null;
    this._sonTs = 0;
    this.hikayeYukle(hikaye, true);
  }

  FolaMotoru.prototype.hikayeYukle = function (hikaye, ilkKonum) {
    this.durdur(true);
    this.hikaye = hikaye;
    this.plan = bolumSesPlaniKur(hikaye);
    if (ilkKonum && hikaye.ilerleme && hikaye.ilerleme.bolumIndex > 0) {
      const b = Math.min(hikaye.ilerleme.bolumIndex, this.plan.bolumBaslangiclari.length - 1);
      // Bölümün ikinci cümlesinin ortasında başlamak ekran görüntülerinde zengin kelime vurgusu gösterir
      const hedefParca = this.plan.parcalar.find(function (p) { return p.bolumIndex === b; });
      this.zaman = hedefParca ? hedefParca.bas + (hedefParca.bit - hedefParca.bas) * 0.56 : 0;
    } else {
      const ilk = this.plan.parcalar[0];
      this.zaman = ilk ? ilk.bas + (ilk.bit - ilk.bas) * 0.48 : 0;
    }
    this.sonOkunanParca = -1;
    this._bildir();
  };

  FolaMotoru.prototype.hiz = function () {
    return this.hizlar[this.hizIndex];
  };

  FolaMotoru.prototype.hizDegistir = function () {
    this.hizIndex = (this.hizIndex + 1) % this.hizlar.length;
    this._bildir();
  };

  FolaMotoru.prototype.oynat = function () {
    if (this.oynuyor) return;
    this.oynuyor = true;
    this._sonTs = performance.now();
    const self = this;
    function adim(ts) {
      if (!self.oynuyor) return;
      const dt = Math.min(0.1, (ts - self._sonTs) / 1000);
      self._sonTs = ts;
      self.zaman += dt * self.hiz();
      if (self.zaman >= self.plan.icToplam) {
        self.zaman = self.plan.icToplam;
        self.oynuyor = false;
      }
      self._bildir();
      if (self.oynuyor) self._raf = requestAnimationFrame(adim);
    }
    this._raf = requestAnimationFrame(adim);
    this._bildir();
  };

  FolaMotoru.prototype.durdur = function (sessiz) {
    this.oynuyor = false;
    if (this._raf) {
      cancelAnimationFrame(this._raf);
      this._raf = null;
    }
    if (global.speechSynthesis) {
      try { global.speechSynthesis.cancel(); } catch (e) {}
    }
    if (!sessiz && this.plan) this._bildir();
  };

  FolaMotoru.prototype.degistir = function () {
    if (this.oynuyor) this.durdur();
    else this.oynat();
  };

  FolaMotoru.prototype.atlaSaniye = function (gercekSn) {
    const oran = this.plan.icToplam / this.plan.gercekToplam;
    const icDelta = gercekSn * oran;
    this.zaman = Math.max(0, Math.min(this.plan.icToplam - 0.05, this.zaman + icDelta));
    this.sonOkunanParca = -1;
    this._bildir();
  };

  FolaMotoru.prototype.bolumeGit = function (bIndex, ortaMi) {
    const i = Math.max(0, Math.min(this.plan.bolumBaslangiclari.length - 1, bIndex));
    if (ortaMi) {
      const hedef = this.plan.parcalar.find(function (p) { return p.bolumIndex === i; });
      this.zaman = hedef ? hedef.bas + (hedef.bit - hedef.bas) * 0.50 : this.plan.bolumBaslangiclari[i];
    } else {
      this.zaman = this.plan.bolumBaslangiclari[i] + 0.35;
    }
    this.sonOkunanParca = -1;
    this._bildir();
  };

  FolaMotoru.prototype.bolumAtla = function (yon) {
    const durum = this.durum();
    this.bolumeGit(durum.bolumIndex + yon);
  };

  FolaMotoru.prototype.oranaGit = function (oran) {
    const o = Math.max(0, Math.min(0.999, oran));
    this.zaman = o * this.plan.icToplam;
    this.sonOkunanParca = -1;
    this._bildir();
  };

  FolaMotoru.prototype.durum = function () {
    const parcalar = this.plan.parcalar;
    let pIndex = parcalar.length - 1;
    for (let i = 0; i < parcalar.length; i++) {
      if (this.zaman < parcalar[i].bit) {
        pIndex = i;
        break;
      }
    }
    const parca = parcalar[Math.max(0, pIndex)];
    const icOran = Math.max(0, Math.min(1, (this.zaman - parca.bas) / Math.max(0.1, parca.bit - parca.bas)));
    const kelimeIndex = Math.min(parca.kelimeler.length - 1, Math.floor(icOran * parca.kelimeler.length));
    const genelOran = Math.max(0, Math.min(1, this.zaman / this.plan.icToplam));
    const gecenGercek = genelOran * this.plan.gercekToplam;
    const kalanGercek = Math.max(0, this.plan.gercekToplam - gecenGercek);
    const bolumOranlari = this.plan.bolumBaslangiclari.map(function (b) { return b / this.plan.icToplam; }, this);

    if (this.oynuyor && this.sesli && pIndex !== this.sonOkunanParca) {
      this.sonOkunanParca = pIndex;
      this._oku(parca.metin);
    }

    return {
      hikaye: this.hikaye,
      parca: parca,
      parcaIndex: pIndex,
      kelimeIndex: kelimeIndex,
      bolumIndex: parca.bolumIndex,
      bolumSayisi: this.hikaye.bolumler.length,
      oran: genelOran,
      bolumOranlari: bolumOranlari,
      gecenYazi: sureYaz(gecenGercek),
      toplamYazi: sureYaz(this.plan.gercekToplam),
      kalanDk: Math.max(1, Math.ceil(kalanGercek / 60)),
      oynuyor: this.oynuyor,
      hiz: this.hiz(),
      sesli: this.sesli
    };
  };

  FolaMotoru.prototype._oku = function (metin) {
    if (!global.speechSynthesis || !metin) return;
    try {
      global.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(metin);
      u.lang = 'tr-TR';
      u.rate = this.hiz();
      const sesler = global.speechSynthesis.getVoices();
      const tr = sesler.find(function (s) { return /^tr/i.test(s.lang); });
      if (tr) u.voice = tr;
      global.speechSynthesis.speak(u);
    } catch (e) {}
  };

  FolaMotoru.prototype._bildir = function () {
    if (this.ayar.guncelle) this.ayar.guncelle(this.durum());
  };

  function urlParametreleri() {
    const p = new URLSearchParams(global.location.search);
    return {
      cek: p.get('cek') === '1',
      tema: p.get('tema') || 'gece',
      ekran: p.get('ekran') || 'ana', // ana | okuma | dinleme | baglantilar | mini
      sanatci: p.get('sanatci') || 'caravaggio',
      bolum: p.has('bolum') ? parseInt(p.get('bolum'), 10) : null,
      kaydir: p.has('kaydir') ? parseInt(p.get('kaydir'), 10) : 0
    };
  }

  function kelimeHtml(parca, kelimeIndex) {
    return parca.kelimeler
      .map(function (k, i) {
        const sinif = i < kelimeIndex ? 'k-gecti' : i === kelimeIndex ? 'k-aktif' : 'k-gelecek';
        return '<span class="' + sinif + '">' + k + '</span>';
      })
      .join(' ');
  }

  global.HikayeVerisi = {
    SEKME_IKONLARI: SEKME_IKONLARI,
    ikonSvg: ikonSvg,
    HIKAYELER: HIKAYELER,
    KATALOG: KATALOG,
    DONEMLER: DONEMLER,
    FolaMotoru: FolaMotoru,
    urlParametreleri: urlParametreleri,
    kelimeHtml: kelimeHtml,
    sureYaz: sureYaz
  };
})(window);

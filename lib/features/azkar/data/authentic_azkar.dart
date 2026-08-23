// lib/features/azkar/data/authentic_azkar.dart

class DuaItem {
  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String englishTranslation;
  final String urduTranslation;
  final String reference;
  final int count;
  final String benefit;

  const DuaItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.englishTranslation,
    required this.urduTranslation,
    required this.reference,
    this.count = 1,
    this.benefit = '',
  });
}

class AzkarCategory {
  final String id;
  final String title;
  final String arabicTitle;
  final String iconName;
  final List<DuaItem> items;

  const AzkarCategory({
    required this.id,
    required this.title,
    required this.arabicTitle,
    required this.iconName,
    required this.items,
  });
}

class AuthenticAzkar {
  static const List<AzkarCategory> categories = [
    // ── 1. Morning Azkar ──────────────────────────────────────────────────────
    AzkarCategory(
      id: 'morning',
      title: 'Morning Azkar',
      arabicTitle: 'أذكار الصباح',
      iconName: 'wb_sunny',
      items: [
        DuaItem(
          id: 'm_ayat_kursi',
          title: 'Ayat-ul-Kursi (The Throne Verse)',
          arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
          transliteration: 'Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta’khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard...',
          englishTranslation: 'Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth...',
          urduTranslation: 'اللہ وہ ہے جس کے سوا کوئی معبود نہیں، وہ ہمیشہ زندہ رہنے والا اور سب کا سنبھالنے والا ہے۔ اسے نہ اونگھ آتی ہے نہ نیند۔ جو کچھ آسمانوں میں ہے اور جو زمین میں ہے سب اسی کا ہے...',
          reference: 'Surah Al-Baqarah 2:255 (Hisn al-Muslim)',
          benefit: 'Whoever recites this when he wakes up will be protected from jinn until evening.',
          count: 1,
        ),
        DuaItem(
          id: 'm_sayyidul_istighfar',
          title: 'Sayyidul Istighfar (Master Forgiveness)',
          arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
          transliteration: 'Allahumma Anta Rabbi la ilaha illa Anta, khalaqtani wa ana ‘abduka, wa ana ‘ala ‘ahdika wa wa‘dika mastata‘tu, a‘udhu bika min sharri ma sana‘tu, abu’u laka bini‘matika ‘alayya, wa abu’u bidhanbi faghfir li fa’innahu la yaghfirudh-dhunuba illa Ant.',
          englishTranslation: 'O Allah, You are my Lord, there is no deity except You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me, for none can forgive sins except You.',
          urduTranslation: 'اے اللہ! تو میرا پروردگار ہے، تیرے سوا کوئی معبود نہیں۔ تو نے ہی مجھے پیدا کیا اور میں تیرا بندہ ہوں اور تیرے عہد اور وعدے پر قائم ہوں جتنی مجھ میں طاقت ہے۔ میں نے جو کچھ کیا اس کے شر سے تیری پناہ مانگتا ہوں۔ اپنے اوپر تیری نعمت کا اقرار کرتا ہوں اور اپنے گناہ کا اعتراف کرتا ہوں، لہٰذا مجھے بخش دے کیونکہ تیرے سوا کوئی گناہوں کو نہیں بخش سکتا۔',
          reference: 'Sahih Al-Bukhari 6306',
          benefit: 'Whoever recites this with firm faith in the morning and dies before evening will be of the people of Paradise.',
          count: 1,
        ),
        DuaItem(
          id: 'm_protection_harm',
          title: 'Protection from All Harm',
          arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
          transliteration: 'Bismillahil-ladhi la yadurru ma‘asmihi shay’un fil-ardi wa la fis-sama’i wa Huwas-Sami‘ul-‘Alim.',
          englishTranslation: 'In the Name of Allah, with Whose Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.',
          urduTranslation: 'اللہ کے نام کے ساتھ جس کے نام کی برکت سے زمین اور آسمان میں کوئی چیز نقصان نہیں پہنچا سکتی، اور وہ خوب سننے والا، سب کچھ جاننے والا ہے۔',
          reference: 'Abu Dawud 5088, At-Tirmidhi 3388',
          benefit: 'Recited 3 times morning & evening: nothing will harm the reciter.',
          count: 3,
        ),
        DuaItem(
          id: 'm_asbahna',
          title: 'Morning Declaration of Sovereignty',
          arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
          transliteration: 'Asbahna wa asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa ‘ala kulli shay’in Qadir.',
          englishTranslation: 'We have entered the morning and kingdom belongs to Allah, and all praise is for Allah. There is no deity except Allah alone with no partner. To Him belongs sovereignty and to Him belongs all praise, and He is over all things capable.',
          urduTranslation: 'ہم نے صبح کی اور صبح کے وقت سارا ملک اللہ ہی کا ہے، اور تمام تعریف اللہ کے لیے ہے۔ اللہ کے سوا کوئی معبود نہیں وہ اکیلا ہے، اس کا کوئی شریک نہیں، اسی کی بادشاہی ہے اور اسی کی حمد ہے اور وہ ہر چیز پر قادر ہے۔',
          reference: 'Sahih Muslim 2723',
          count: 1,
        ),
        DuaItem(
          id: 'm_raditu',
          title: 'Contentment with Allah, Islam & Prophet ﷺ',
          arabic: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
          transliteration: 'Raditu billahi Rabba, wa bil-Islami dina, wa bi Muhammadin sallallahu ‘alayhi wa sallama Nabiyya.',
          englishTranslation: 'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.',
          urduTranslation: 'میں راضی ہو گیا اللہ کو رب مان کر، اسلام کو دین مان کر اور محمد ﷺ کو نبی مان کر۔',
          reference: 'Abu Dawud 5072, At-Tirmidhi 3389',
          benefit: 'Allah has promised to please the person who recites this 3 times on the Day of Resurrection.',
          count: 3,
        ),
        DuaItem(
          id: 'm_ya_hayyu',
          title: 'Supplication for Divine Grace & Guidance',
          arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
          transliteration: 'Ya Hayyu Ya Qayyumu birahmatika astaghith, aslih li sha’ni kullahu wa la takilni ila nafsi tarfata ‘ayn.',
          englishTranslation: 'O Ever-Living, O Self-Sustaining! By Your mercy I seek assistance; rectify for me all of my affairs, and do not leave me to myself even for the blink of an eye.',
          urduTranslation: 'اے زندہ جاوید! اے سب کو تھامنے والے! تیری ہی رحمت کے وسیلے سے فریاد کرتا ہوں، تو میرے تمام معاملات سنوار دے اور مجھے پلک جھپکنے کے برابر بھی میرے نفس کے حوالے نہ کر۔',
          reference: 'An-Nasa’i, Al-Hakim (Sahih)',
          count: 1,
        ),
      ],
    ),

    // ── 2. Evening Azkar ──────────────────────────────────────────────────────
    AzkarCategory(
      id: 'evening',
      title: 'Evening Azkar',
      arabicTitle: 'أذكار المساء',
      iconName: 'nights_stay',
      items: [
        DuaItem(
          id: 'e_amsayna',
          title: 'Evening Declaration of Faith',
          arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
          transliteration: 'Amsayna wa amsal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa ‘ala kulli shay’in Qadir.',
          englishTranslation: 'We have reached the evening and the kingdom belongs to Allah, and all praise is for Allah. There is no deity except Allah alone with no partner. To Him belongs sovereignty and to Him belongs praise, and He has power over all things.',
          urduTranslation: 'ہم نے شام کی اور شام کے وقت سارا ملک اللہ کا ہے اور سب تعریف اللہ ہی کے لیے ہے۔ اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے اس کا کوئی شریک نہیں، اسی کی بادشاہی اور اسی کی حمد ہے اور وہ ہر چیز پر قادر ہے۔',
          reference: 'Sahih Muslim 2723',
          count: 1,
        ),
        DuaItem(
          id: 'e_words_allah',
          title: 'Refuge in the Perfect Words of Allah',
          arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
          transliteration: 'A‘udhu bikalimatil-lahit-tammati min sharri ma khalaq.',
          englishTranslation: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
          urduTranslation: 'میں اللہ کے مکمل کلمات کی پناہ مانگتا ہوں ہر اس چیز کے شر سے جو اس نے پیدا کی۔',
          reference: 'Sahih Muslim 2709',
          benefit: 'Whoever recites this 3 times in the evening will not be harmed by any poison/creature that night.',
          count: 3,
        ),
        DuaItem(
          id: 'e_hasbiya',
          title: 'Sufficiency in Allah',
          arabic: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
          transliteration: 'Hasbiyallahu la ilaha illa Huwa, ‘alayhi tawakkaltu wa Huwa Rabbul-‘Arshil-‘Azim.',
          englishTranslation: 'Allah is sufficient for me; there is no deity except Him. On Him I have relied, and He is the Lord of the Great Throne.',
          urduTranslation: 'مجھے اللہ ہی کافی ہے، اس کے سوا کوئی معبود نہیں، اسی پر میں نے بھروسہ کیا اور وہ عرش عظیم کا رب ہے۔',
          reference: 'Abu Dawud 5081 (Surah At-Tawbah 9:129)',
          benefit: 'Whoever recites this 7 times morning and evening, Allah will suffice him in what concerns him.',
          count: 7,
        ),
        DuaItem(
          id: 'e_afini',
          title: 'Supplication for Health & Hearing & Sight',
          arabic: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ',
          transliteration: 'Allahumma ‘afini fi badani, Allahumma ‘afini fi sam‘i, Allahumma ‘afini fi basari, la ilaha illa Ant.',
          englishTranslation: 'O Allah, grant me health in my body. O Allah, grant me health in my hearing. O Allah, grant me health in my sight. There is no deity except You.',
          urduTranslation: 'اے اللہ! میرے بدن میں مجھے عافیت عطا فرما۔ اے اللہ! میرے کانوں میں مجھے عافیت عطا فرما۔ اے اللہ! میری آنکھوں میں مجھے عافیت عطا فرما۔ تیرے سوا کوئی معبود نہیں۔',
          reference: 'Abu Dawud 5090, Ahmad',
          count: 3,
        ),
      ],
    ),

    // ── 3. After Prayer (Salah) ──────────────────────────────────────────────
    AzkarCategory(
      id: 'after_prayer',
      title: 'After Prayer Azkar',
      arabicTitle: 'أذكار بعد الصلاة',
      iconName: 'access_time',
      items: [
        DuaItem(
          id: 'p_astaghfirullah',
          title: 'Astaghfirullah & Peace Supplication',
          arabic: 'أَسْتَغْفِرُ اللَّهَ (٣×)، اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
          transliteration: 'Astaghfirullah (3x). Allahumma Antas-Salamu wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.',
          englishTranslation: 'I seek Allah’s forgiveness (3 times). O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of majesty and honor.',
          urduTranslation: 'میں اللہ سے بخشش مانگتا ہوں (۳ مرتبہ)۔ اے اللہ! تو ہی سلامتی والا ہے اور تجھی سے سلامتی ہے، تو بڑی برکت والا ہے، اے جلال اور بزرگی والے۔',
          reference: 'Sahih Muslim 591',
          count: 3,
        ),
        DuaItem(
          id: 'p_tahlil',
          title: 'Tahlil after Prayer',
          arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
          transliteration: 'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa ‘ala kulli shay’in Qadir. Allahumma la mani‘a lima a‘tayta, wa la mu‘tiya lima mana‘ta, wa la yanfa‘u dhal-jaddi minkal-jadd.',
          englishTranslation: 'There is no deity except Allah alone, without partner. To Him belongs sovereignty and all praise, and He is over all things omnipotent. O Allah, none can prevent what You give, nor can anyone give what You prevent, nor can the fortune of the prosperous avail him against You.',
          urduTranslation: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، اسی کی بادشاہی ہے اور اسی کی حمد ہے، اور وہ ہر چیز پر قادر ہے۔ اے اللہ! جو تو دے اسے کوئی روکنے والا نہیں، اور جو تو روک لے اسے کوئی دینے والا نہیں، اور کسی صاحبِ حیثیت کی حیثیت تیرے مقابلے میں فائدہ مند نہیں ہو سکتی۔',
          reference: 'Sahih Al-Bukhari 844, Sahih Muslim 593',
          count: 1,
        ),
        DuaItem(
          id: 'p_tasbeeh_33',
          title: 'Tasbeeh of 33s & Completion',
          arabic: 'سُبْحَانَ اللَّهِ (٣٣×) • الْحَمْدُ لِلَّهِ (٣٣×) • اللَّهُ أَكْبَرُ (٣٣×) • لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
          transliteration: 'SubhanAllah (33x), Alhamdulillah (33x), Allahu Akbar (33x), followed by: La ilaha illallahu wahdahu la sharika lah...',
          englishTranslation: 'Glory be to Allah (33x), Praise be to Allah (33x), Allah is the Greatest (33x). Then complete with: None has the right to be worshipped except Allah alone...',
          urduTranslation: 'اللہ پاک ہے (۳۳ بار)، سب تعریف اللہ کے لیے ہے (۳۳ بار)، اللہ سب سے بڑا ہے (۳۳ بار)۔ پھر ۱۰۰ پورا کرنے کے لیے کہیں: اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں۔',
          reference: 'Sahih Muslim 597',
          benefit: 'Whoever says this after every prayer will have his sins forgiven even if they were like the foam of the sea.',
          count: 33,
        ),
        DuaItem(
          id: 'p_ainni',
          title: 'Prayer for Gratitude & Good Worship',
          arabic: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ، وَشُكْرِكَ، وَحُسْنِ عِبَادَتِكَ',
          transliteration: 'Allahumma a‘inni ‘ala dhikrika, wa shukrika, wa husni ‘ibadatik.',
          englishTranslation: 'O Allah, assist me in remembering You, expressing gratitude to You, and worshipping You in the best manner.',
          urduTranslation: 'اے اللہ! اپنے ذکر، اپنے شکر اور اپنی بہترین عبادت پر میری مدد فرما۔',
          reference: 'Abu Dawud 1522, An-Nasa’i (Sahih)',
          count: 1,
        ),
      ],
    ),

    // ── 4. Before Sleep ──────────────────────────────────────────────────────
    AzkarCategory(
      id: 'sleep',
      title: 'Before Sleep',
      arabicTitle: 'أذكار النوم',
      iconName: 'bedtime',
      items: [
        DuaItem(
          id: 's_janbi',
          title: 'Placing Side in Bed Supplication',
          arabic: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
          transliteration: 'Bismika Rabbi wada‘tu janbi wa bika arfa‘uhu, fa’in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi ‘ibadakas-salihin.',
          englishTranslation: 'In Your Name my Lord, I lay down my side and in Your Name I raise it. If You hold back my soul, then have mercy on it, and if You release it, then protect it with that wherewith You protect Your righteous servants.',
          urduTranslation: 'اے میرے رب! تیرے نام کے ساتھ ہی میں نے اپنا پہلو بچھایا اور تیرے ہی نام سے اسے اٹھاؤں گا۔ پس اگر تو میری جان روک لے تو اس پر رحم فرما، اور اگر تو اسے چھوڑ دے تو اس کی حفاظت فرما جس طرح تو اپنے نیک بندوں کی حفاظت فرماتا ہے۔',
          reference: 'Sahih Al-Bukhari 6320, Sahih Muslim 2714',
          count: 1,
        ),
        DuaItem(
          id: 's_muawwidhat',
          title: 'The Three Quls (Mu’awwidhat)',
          arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ... • قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ... • قُلْ أَعُوذُ بِرَبِّ النَّاسِ...',
          transliteration: 'Surah Al-Ikhlas, Surah Al-Falaq, Surah An-Nas.',
          englishTranslation: 'Recite Surahs Al-Ikhlas (112), Al-Falaq (113), and An-Nas (114), blow into hands and wipe over body.',
          urduTranslation: 'سورۃ الاخلاص، سورۃ الفلق اور سورۃ الناس پڑھ کر ہاتھوں پر پھونکیں اور پورے جسم پر پھیر لیں۔',
          reference: 'Sahih Al-Bukhari 5017',
          count: 3,
        ),
        DuaItem(
          id: 's_amutu',
          title: 'Short Bedtime Supplication',
          arabic: 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
          transliteration: 'Allahumma bismika amutu wa ahya.',
          englishTranslation: 'O Allah, in Your Name I die and I live.',
          urduTranslation: 'اے اللہ! تیرے ہی نام کے ساتھ میں مرتا ہوں اور جیتا ہوں۔',
          reference: 'Sahih Al-Bukhari 6324',
          count: 1,
        ),
      ],
    ),

    // ── 5. Distress & Anxiety ────────────────────────────────────────────────
    AzkarCategory(
      id: 'distress',
      title: 'Distress & Anxiety',
      arabicTitle: 'الهم والحزن',
      iconName: 'healing',
      items: [
        DuaItem(
          id: 'd_yunus',
          title: 'Dua of Prophet Yunus (In the Belly of Whale)',
          arabic: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
          transliteration: 'La ilaha illa Anta subhanaka inni kuntu minaz-zalimin.',
          englishTranslation: 'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
          urduTranslation: 'تیرے سوا کوئی معبود نہیں، تو پاک ہے، بے شک میں ہی قصورواروں میں سے تھا۔',
          reference: 'Surah Al-Anbiya 21:87 (At-Tirmidhi 3505)',
          benefit: 'No Muslim supplicates with this for any distress except that Allah relieves him.',
          count: 1,
        ),
        DuaItem(
          id: 'd_hamm',
          title: 'Relief from Grief, Debt & Weakness',
          arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ',
          transliteration: 'Allahumma inni a‘udhu bika minal-hammi wal-hazan, wal-‘ajzi wal-kasal, wal-bukhli wal-jubn, wa dala‘id-dayni wa ghalabatir-rijal.',
          englishTranslation: 'O Allah, I seek refuge in You from anxiety and sorrow, from weakness and laziness, from miserliness and cowardice, from being overcome by debt and from the oppression of men.',
          urduTranslation: 'اے اللہ! میں تیری پناہ مانگتا ہوں فکر اور غم سے، عاجزی اور سستی سے، بخل اور بزدلی سے، قرض کے بوجھ اور لوگوں کے غلبے اور تسلط سے۔',
          reference: 'Sahih Al-Bukhari 2893',
          count: 1,
        ),
        DuaItem(
          id: 'd_hawla',
          title: 'Treasury of Paradise',
          arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
          transliteration: 'La hawla wa la quwwata illa billahil-‘Aliyyil-‘Azim.',
          englishTranslation: 'There is no power and no might except by Allah, the Most High, the Most Great.',
          urduTranslation: 'گناہوں سے بچنے کی کوئی طاقت اور نیکی کرنے کی کوئی قوت نہیں مگر اللہ عالی و عظیم کی توفیق سے۔',
          reference: 'Sahih Al-Bukhari 6384',
          benefit: 'A treasure from beneath the Throne of Allah.',
          count: 10,
        ),
      ],
    ),

    // ── 6. Daily Activities & Travel ─────────────────────────────────────────
    AzkarCategory(
      id: 'daily_travel',
      title: 'Daily Life & Travel',
      arabicTitle: 'اليومية والسفر',
      iconName: 'directions_car',
      items: [
        DuaItem(
          id: 't_waking',
          title: 'Upon Waking Up',
          arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
          transliteration: 'Alhamdu lillahil-ladhi ahyana ba‘da ma amatana wa ilayhin-nushur.',
          englishTranslation: 'All praise is due to Allah who gave us life after having given us death, and unto Him is the resurrection.',
          urduTranslation: 'تمام تعریفیں اللہ ہی کے لیے ہیں جس نے ہمیں مارنے (سلانے) کے بعد زندہ کیا اور اسی کی طرف سب کو لوٹ کر جانا ہے۔',
          reference: 'Sahih Al-Bukhari 6312',
          count: 1,
        ),
        DuaItem(
          id: 't_leaving_home',
          title: 'Leaving Home Supplication',
          arabic: 'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
          transliteration: 'Bismillahi tawakkaltu ‘alallahi, wa la hawla wa la quwwata illa billah.',
          englishTranslation: 'In the Name of Allah, I place my trust in Allah; there is no power and no might except by Allah.',
          urduTranslation: 'اللہ کے نام سے، میں نے اللہ پر بھروسہ کیا، اور گناہوں سے بچنے کی کوئی طاقت اور نیکی کی کوئی قوت نہیں مگر اللہ کے ساتھ۔',
          reference: 'Abu Dawud 5095, At-Tirmidhi 3426',
          benefit: 'It is said to him: You are guided, defended, and protected, and Satan retreats from him.',
          count: 1,
        ),
        DuaItem(
          id: 't_vehicle',
          title: 'Mounting / Riding Vehicle & Travel',
          arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
          transliteration: 'Subhanal-ladhi sakh-khara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun.',
          englishTranslation: 'Glory be to Him Who has subjected this to us, and we could never have achieved it by ourselves. And indeed, to our Lord we will return.',
          urduTranslation: 'پاک ہے وہ ذات جس نے اس (سواری) کو ہمارے قابو میں کر دیا حالانکہ ہم اسے قابو میں کرنے والے نہ تھے، اور بے شک ہم اپنے رب ہی کی طرف لوٹنے والے ہیں۔',
          reference: 'Surah Az-Zukhruf 43:13-14 (Sahih Muslim 1342)',
          count: 1,
        ),
      ],
    ),
  ];
}
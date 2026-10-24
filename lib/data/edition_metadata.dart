// lib/data/edition_metadata.dart
import 'package:flutter/foundation.dart';

@immutable
class EditionMetadata {
  final String bookTitle;
  final String scholarName;
  final String? imageAsset;
  final String authorityBadge;
  final String description;

  const EditionMetadata({
    required this.bookTitle,
    required this.scholarName,
    this.imageAsset,
    this.authorityBadge = '',
    this.description = '',
  });
}

class EditionMetadataRegistry {
  EditionMetadataRegistry._();

  static const Map<String, EditionMetadata> _registry = {
    // ═════════════════════════════════════════════════════════════════════════
    // URDU TRANSLATIONS (6 Approved Editions)
    // ═════════════════════════════════════════════════════════════════════════
    'ur.jalandhry': EditionMetadata(
      bookTitle: 'Fath-ul-Hameed',
      scholarName: 'Maulana Fateh Muhammad Jalandhry',
      imageAsset: 'assets/images/scholars/jalandhry.png',
      description: 'Historically beloved, authentic classical Urdu translation.',
    ),
    'ur.kanzuliman': EditionMetadata(
      bookTitle: 'Kanz-ul-Iman',
      scholarName: 'Ala Hazrat Imam Ahmed Raza Khan',
      imageAsset: 'assets/images/scholars/ahmed_raza_khan.jpg',
      description: 'Masterwork of reverential prose and theological precision.',
    ),
    'ur.maududi': EditionMetadata(
      bookTitle: 'Tafhim-ul-Quran',
      scholarName: "Sayyid Abul A'la Maududi",
      imageAsset: 'assets/images/scholars/maududi.jpg',
      description: 'Modern idiomatic Urdu translation elucidating Quranic worldview.',
    ),
    'ur.junagarhi': EditionMetadata(
      bookTitle: 'Tarjuma Quran Majeed',
      scholarName: 'Maulana Muhammad Junagarhi',
      imageAsset: 'assets/images/scholars/junagarhi.png',
      description: 'Official verified translation published by the King Fahd Complex Madinah.',
    ),
    'ur.qadri': EditionMetadata(
      bookTitle: 'Irfan-ul-Quran',
      scholarName: 'Dr. Muhammad Tahir-ul-Qadri',
      imageAsset: 'assets/images/scholars/tahir_ul_qadri.jpg',
      description: 'Scientifically aligned, contemporary, eloquent modern Urdu prose.',
    ),
    'ur.taqiusmani': EditionMetadata(
      bookTitle: 'Aasan Tarjuma Quran',
      scholarName: 'Mufti Muhammad Taqi Usmani',
      imageAsset: 'assets/images/scholars/taqi_usmani.jpg',
      description: 'Widely praised for utmost clarity, simplicity, and accessibility.',
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // ENGLISH TRANSLATIONS (3 Approved Editions)
    // ═════════════════════════════════════════════════════════════════════════
    'en.sahih': EditionMetadata(
      bookTitle: "The Qur'an: English Meanings",
      scholarName: 'Saheeh International',
      imageAsset: 'assets/images/scholars/sahih_international.png',
      description: 'The global standard for faithful, accurate modern English rendering.',
    ),
    'en.wahiduddin': EditionMetadata(
      bookTitle: 'The Quran (Wahiduddin Khan)',
      scholarName: 'Maulana Wahiduddin Khan',
      imageAsset: 'assets/images/scholars/wahiduddin_khan.jpg',
      description: 'Lucid, direct, and universally approachable modern English rendering.',
    ),
    'en.maududi': EditionMetadata(
      bookTitle: "Towards Understanding the Qur'an",
      scholarName: "Sayyid Abul A'la Maududi",
      imageAsset: 'assets/images/scholars/maududi.jpg',
      description: 'Engaging English exposition published by The Islamic Foundation UK.',
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // HINDI TRANSLATIONS (2 Approved Editions)
    // ═════════════════════════════════════════════════════════════════════════
    'hi.maududi': EditionMetadata(
      bookTitle: 'Tafhim-ul-Quran (Hindi)',
      scholarName: "Sayyid Abul A'la Maududi",
      imageAsset: 'assets/images/scholars/maududi.jpg',
      description: 'Accurate, highly respected Hindi translation.',
    ),
    'hi.taqiusmani': EditionMetadata(
      bookTitle: 'Aasan Tarjuma Quran (Hindi)',
      scholarName: 'Mufti Muhammad Taqi Usmani',
      imageAsset: 'assets/images/scholars/taqi_usmani.jpg',
      description: 'Simple, lucid and reader-friendly Hindi translation.',
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // TAFSEERS (Approved Commentaries with Dedicated Portraits & Emblems)
    // ═════════════════════════════════════════════════════════════════════════
    // Ibn Kathir (Arabic, Urdu, English)
    'ar-tafsir-ibn-kathir': EditionMetadata(
      bookTitle: 'Tafsir Ibn Kathir',
      scholarName: 'Al-Hafiz Ibn Kathir',
      imageAsset: 'assets/images/scholars/ibn_kathir.png',
      description: 'The foremost classical exegesis based on Quran and Sunnah.',
    ),
    'tafseer-ibn-e-kaseer-urdu': EditionMetadata(
      bookTitle: 'Tafseer Ibn Kathir (Urdu)',
      scholarName: 'Al-Hafiz Ibn Kathir / Maulana Muhammad Junagarhi',
      imageAsset: 'assets/images/scholars/ibn_kathir.png',
      description: 'Authoritative Urdu translation of Tafsir Ibn Kathir.',
    ),
    'en-tafisr-ibn-kathir': EditionMetadata(
      bookTitle: 'Tafseer Ibn Kathir (English)',
      scholarName: 'Al-Hafiz Ibn Kathir',
      imageAsset: 'assets/images/scholars/ibn_kathir.png',
      description: 'Classical commentary of Ibn Kathir in clear English.',
    ),

    // Thanvi - Bayan-ul-Quran
    'tafsir-bayan-ul-quran': EditionMetadata(
      bookTitle: 'Bayan-ul-Quran',
      scholarName: 'Maulana Ashraf Ali Thanvi',
      imageAsset: 'assets/images/scholars/thanvi.png',
      description: 'Masterwork commentary focusing on spiritual depths and subtle Quranic wisdom.',
    ),

    // Al-Tabari
    'ar-tafsir-al-tabari': EditionMetadata(
      bookTitle: 'Tafsir al-Tabari (Jami al-Bayan)',
      scholarName: 'Imam Muhammad ibn Jarir al-Tabari',
      imageAsset: 'assets/images/scholars/al_tabari.png',
      description: 'Jami al-Bayan: The mother of all classical Quranic exegesis treatises.',
    ),

    // Al-Qurtubi
    'ar-tafseer-al-qurtubi': EditionMetadata(
      bookTitle: 'Tafsir al-Qurtubi (Ahkam al-Quran)',
      scholarName: 'Imam Abu Abdillah Al-Qurtubi',
      imageAsset: 'assets/images/scholars/al_qurtubi.png',
      description: 'Comprehensive legal and ethical commentary of Quranic rulings.',
    ),

    // As-Sa'di (Arabic & Urdu)
    'ar-tafseer-al-saddi': EditionMetadata(
      bookTitle: "Tafsir As-Sa'di (Taysir al-Karim)",
      scholarName: "Shaykh Abdur-Rahman As-Sa'di",
      imageAsset: 'assets/images/scholars/as_saadi.png',
      description: 'Renowned commentary praised for pristine clarity and spiritual insight.',
    ),
    'tafsir-as-saadi': EditionMetadata(
      bookTitle: "Tafseer As-Sa'di (Urdu)",
      scholarName: "Shaykh Abdur-Rahman As-Sa'di",
      imageAsset: 'assets/images/scholars/as_saadi.png',
      description: 'Urdu rendering of the lucid exegesis of Shaykh As-Saadi.',
    ),

    // Jalalayn (Arabic, Urdu, English)
    'tafsir-jalalayn': EditionMetadata(
      bookTitle: 'Tafsir Al-Jalalayn (Arabic)',
      scholarName: 'Imams Al-Mahalli & Al-Suyuti',
      imageAsset: 'assets/images/scholars/jalalayn.png',
      description: 'Concise classical commentary studied throughout the Islamic world.',
    ),
    'tafsir-al-jalalayn': EditionMetadata(
      bookTitle: 'Tafsir Al-Jalalayn (English)',
      scholarName: 'Imams Al-Mahalli & Al-Suyuti',
      imageAsset: 'assets/images/scholars/jalalayn.png',
      description: 'English rendering of the concise classical Tafsir Al-Jalalayn.',
    ),
    'ur.jalalayn': EditionMetadata(
      bookTitle: 'Tafseer Jalalayn (Urdu)',
      scholarName: 'Imams Al-Mahalli & Al-Suyuti',
      imageAsset: 'assets/images/scholars/jalalayn.png',
      description: 'Urdu translation of the revered commentary Tafsir Al-Jalalayn.',
    ),

    // Sayyid Qutb - Fi Zilal al-Quran
    'tafsir-fe-zalul-quran-syed-qatab': EditionMetadata(
      bookTitle: 'Fi Zilal al-Quran',
      scholarName: 'Sayyid Qutb',
      imageAsset: 'assets/images/scholars/syed_qutb.jpg',
      description: 'In the Shade of the Quran: modern evocative exposition.',
    ),

    // Wahiduddin Khan - Tazkirul Quran (Urdu & English)
    'tazkiru-quran-ur': EditionMetadata(
      bookTitle: 'Tazkirul Quran (Urdu)',
      scholarName: 'Maulana Wahiduddin Khan',
      imageAsset: 'assets/images/scholars/wahiduddin_khan.jpg',
      description: 'Contemplative commentary focused on realization and spiritual reflection.',
    ),
    'tazkirul-quran-en': EditionMetadata(
      bookTitle: 'Tazkirul Quran (English)',
      scholarName: 'Maulana Wahiduddin Khan',
      imageAsset: 'assets/images/scholars/wahiduddin_khan.jpg',
      description: 'Contemplative English commentary focused on reflection and introspection.',
    ),

    // Al-Mukhtasar (English & Hindi)
    'Al-Mukhtasar': EditionMetadata(
      bookTitle: 'Al-Mukhtasar fi Tafsir (English)',
      scholarName: 'Markaz Tafsir Studies',
      imageAsset: 'assets/images/scholars/mukhtasar.png',
      description: 'Clear, concise, and modern commentary prepared by a committee of scholars.',
    ),
    'hindi-mokhtasar': EditionMetadata(
      bookTitle: 'Al-Mukhtasar fi Tafsir (Hindi)',
      scholarName: 'मरकज़ तफ़सीर अध्ययन',
      imageAsset: 'assets/images/scholars/mukhtasar.png',
      description: 'संक्षिप्त और प्रामाणिक क़ुरआनी तफ़सीर हिंदी भाषा में।',
    ),

    // Maarif-ul-Quran English
    'en-tafsir-maarif-ul-quran': EditionMetadata(
      bookTitle: "Ma'arif-ul-Quran (English)",
      scholarName: 'Mufti Muhammad Shafi Usmani',
      imageAsset: 'assets/images/scholars/maarif_ul_quran.png',
      description: 'Monumental 8-volume comprehensive exegesis in English.',
    ),

    // Ibn Uthaymeen
    'tafsir-ibn-uthaymeen': EditionMetadata(
      bookTitle: 'Tafsir Ibn Uthaymeen',
      scholarName: 'Shaykh Muhammad ibn Salih al-Uthaymeen',
      imageAsset: 'assets/images/scholars/ibn_uthaymeen.png',
      description: 'Profound analytical lessons and linguistic jurisprudence.',
    ),

    // Ibn Abi Hatim
    'tafsir-ibn-abi-hatim': EditionMetadata(
      bookTitle: 'Tafsir Ibn Abi Hatim',
      scholarName: 'Imam Abdur Rahman Ibn Abi Hatim',
      imageAsset: 'assets/images/scholars/ibn_abi_hatim.png',
      description: 'Early transmission-based exegesis recording authentic narrations of the Salaf.',
    ),

    // As-Seraj Fi Bayan Gharib Al-Quran
    'asseraj-fi-bayan-gharib-alquran': EditionMetadata(
      bookTitle: 'As-Seraj Fi Bayan Gharib Al-Quran',
      scholarName: 'Dr. Muhammad Al-Khudairi',
      imageAsset: 'assets/images/scholars/asseraj.png',
      description: 'Precise lexical commentary illuminating unique Quranic vocabulary.',
    ),
  };

  /// Returns metadata for the given edition apiKey.
  /// Falls back to sane defaults based on raw name if not found.
  static EditionMetadata getMetadata(String apiKey, {String? fallbackName}) {
    final meta = _registry[apiKey];
    if (meta != null) return meta;

    // Fallback formatting for any unindexed tafseer or custom edition
    final title = fallbackName != null && fallbackName.isNotEmpty
        ? fallbackName
        : apiKey;

    return EditionMetadata(
      bookTitle: title,
      scholarName: title,
      imageAsset: null,
      authorityBadge: '',
      description: '',
    );
  }

  /// List of strictly approved translation API keys
  static const Set<String> approvedTranslationKeys = {
    'ur.jalandhry',
    'ur.kanzuliman',
    'ur.maududi',
    'ur.junagarhi',
    'ur.qadri',
    'ur.taqiusmani',
    'en.sahih',
    'en.wahiduddin',
    'en.maududi',
    'hi.maududi',
    'hi.taqiusmani',
  };
}

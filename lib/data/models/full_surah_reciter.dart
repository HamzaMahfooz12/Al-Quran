// lib/data/models/full_surah_reciter.dart
// Model representing a reciter supporting full 114-surah playback

class FullSurahReciter {
  final int id;
  final String name;
  final String arabicName;
  final String folderSlug;
  final String mp3quranServer;
  final int surahTotal;

  const FullSurahReciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.folderSlug,
    required this.mp3quranServer,
    this.surahTotal = 114,
  });

  factory FullSurahReciter.fromJson(Map<String, dynamic> json) {
    return FullSurahReciter(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      arabicName: json['arabic_name'] as String? ?? json['name'] as String? ?? '',
      folderSlug: json['folder_slug'] as String? ?? '',
      mp3quranServer: json['mp3quran_server'] as String? ?? '',
      surahTotal: json['surah_total'] as int? ?? 114,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arabic_name': arabicName,
      'folder_slug': folderSlug,
      'mp3quran_server': mp3quranServer,
      'surah_total': surahTotal,
    };
  }

  /// Primary CDN: QuranicAudio.com (e.g. https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3)
  String getPrimaryUrl(int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    return 'https://download.quranicaudio.com/quran/$folderSlug/$padded.mp3';
  }

  /// Fallback CDN: MP3Quran.net (e.g. https://server8.mp3quran.net/afs/001.mp3)
  String getFallbackUrl(int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    final base = mp3quranServer.endsWith('/') ? mp3quranServer : '$mp3quranServer/';
    return '$base$padded.mp3';
  }

  /// Checks whether a given Surah number (1-114) is available for this reciter
  bool isSurahAvailable(int surahNumber) {
    return surahNumber >= 1 && surahNumber <= surahTotal;
  }
}

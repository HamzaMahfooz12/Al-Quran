// lib/data/models/edition.dart
import 'package:equatable/equatable.dart';

class Edition extends Equatable {
  final int id;
  final String type; // 'translation' | 'tafseer'
  final String language;
  final String name;
  final String apiKey;
  final bool isBundled;
  final bool isDownloaded;

  const Edition({
    required this.id,
    required this.type,
    required this.language,
    required this.name,
    required this.apiKey,
    required this.isBundled,
    required this.isDownloaded,
  });

  bool get isAvailable => isBundled || isDownloaded;

  factory Edition.fromMap(Map<String, dynamic> map) => Edition(
        id: map['id'] as int,
        type: map['type'] as String,
        language: map['language'] as String,
        name: map['name'] as String,
        apiKey: map['api_key'] as String,
        isBundled: (map['is_bundled'] as int) == 1,
        isDownloaded: (map['is_downloaded'] as int) == 1,
      );

  // From AlQuran Cloud API response
  factory Edition.fromApi(Map<String, dynamic> map) => Edition(
        id: 0,
        type: map['type'] as String? ?? 'translation',
        language: map['language'] as String? ?? 'en',
        name: map['name'] as String? ?? map['englishName'] as String? ?? '',
        apiKey: map['identifier'] as String? ?? '',
        isBundled: false,
        isDownloaded: false,
      );

  Map<String, dynamic> toMap() => {
        'type': type,
        'language': language,
        'name': name,
        'api_key': apiKey,
        'is_bundled': isBundled ? 1 : 0,
        'is_downloaded': isDownloaded ? 1 : 0,
      };

  Edition copyWith({bool? isDownloaded}) => Edition(
        id: id,
        type: type,
        language: language,
        name: name,
        apiKey: apiKey,
        isBundled: isBundled,
        isDownloaded: isDownloaded ?? this.isDownloaded,
      );

  @override
  List<Object?> get props => [id, apiKey];
}

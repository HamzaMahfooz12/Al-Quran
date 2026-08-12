// lib/data/models/reciter.dart
import 'package:equatable/equatable.dart';

class Reciter extends Equatable {
  final String id;
  final String name;
  final String? style;
  final String language;

  const Reciter({
    required this.id,
    required this.name,
    this.style,
    this.language = 'ar',
  });

  factory Reciter.fromMap(Map<String, dynamic> map) => Reciter(
        id: map['id'] as String,
        name: map['name'] as String,
        style: map['style'] as String?,
        language: map['language'] as String? ?? 'ar',
      );

  // From AlQuran Cloud API /v1/edition/format/audio
  factory Reciter.fromApi(Map<String, dynamic> map) => Reciter(
        id: map['identifier'] as String? ?? '',
        name: map['name'] as String? ?? map['englishName'] as String? ?? '',
        style: map['type'] as String?,
        language: map['language'] as String? ?? 'ar',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'style': style,
        'language': language,
      };

  @override
  List<Object?> get props => [id];
}

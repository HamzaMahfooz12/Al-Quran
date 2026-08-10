// lib/data/models/bookmark.dart
import 'package:equatable/equatable.dart';

class Bookmark extends Equatable {
  final int id;
  final int surah;
  final int ayah;
  final String? label;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.surah,
    required this.ayah,
    this.label,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as int,
        surah: map['surah'] as int,
        ayah: map['ayah'] as int,
        label: map['label'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'surah': surah,
        'ayah': ayah,
        'label': label,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id];
}

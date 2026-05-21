import 'package:uuid/uuid.dart';

class ImageData {
  final String id;
  final String imageUrl;
  final int position;
  final String? linkUrl;

  ImageData({
    String? id,
    required this.imageUrl,
    this.position = 0,
    this.linkUrl,
  }) : id = id ?? const Uuid().v4();

  ImageData copyWith({
    String? id,
    String? imageUrl,
    int? position,
    String? linkUrl,
  }) {
    return ImageData(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
      linkUrl: linkUrl ?? this.linkUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'position': position,
    'linkUrl': linkUrl,
  };

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String,
    position: json['position'] as int? ?? 0,
    linkUrl: json['linkUrl'] as String?,
  );
}

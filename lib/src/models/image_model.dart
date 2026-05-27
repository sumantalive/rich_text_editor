import 'package:uuid/uuid.dart';

class ImageData {
  final String id;
  final String imageUrl;
  final int position;
  final String? linkUrl;
  final double width;
  final double height;

  ImageData({
    String? id,
    required this.imageUrl,
    this.position = 0,
    this.linkUrl,
    this.width = 0,
    this.height = 0,
  }) : id = id ?? const Uuid().v4();

  /// Whether this image still needs its natural (intrinsic) size resolved.
  /// `0` is a sentinel meaning "auto-size from the image's real dimensions".
  bool get needsNaturalSize => width <= 0 || height <= 0;

  ImageData copyWith({
    String? id,
    String? imageUrl,
    int? position,
    String? linkUrl,
    double? width,
    double? height,
  }) {
    return ImageData(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
      linkUrl: linkUrl ?? this.linkUrl,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'position': position,
    'linkUrl': linkUrl,
    'width': width,
    'height': height,
  };

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String,
    position: json['position'] as int? ?? 0,
    linkUrl: json['linkUrl'] as String?,
    width: (json['width'] as num?)?.toDouble() ?? 0,
    height: (json['height'] as num?)?.toDouble() ?? 0,
  );
}

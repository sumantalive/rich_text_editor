class SpanData {
  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final int textColor;
  final int? highlightColor;
  final double fontSize;
  final String fontFamily;
  final String alignment; // 'left', 'center', 'right', 'justify'
  final String? linkUrl;

  SpanData({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.textColor = 0xFF000000,
    this.highlightColor,
    this.fontSize = 14.0,
    this.fontFamily = 'default',
    this.alignment = 'left',
    this.linkUrl,
  });

  SpanData copyWith({
    int? start,
    int? end,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    int? textColor,
    int? highlightColor,
    double? fontSize,
    String? fontFamily,
    String? alignment,
    String? linkUrl,
  }) {
    return SpanData(
      start: start ?? this.start,
      end: end ?? this.end,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      textColor: textColor ?? this.textColor,
      highlightColor: highlightColor ?? this.highlightColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      alignment: alignment ?? this.alignment,
      linkUrl: linkUrl ?? this.linkUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strikethrough': strikethrough,
    'textColor': textColor,
    'highlightColor': highlightColor,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'alignment': alignment,
    'linkUrl': linkUrl,
  };

  factory SpanData.fromJson(Map<String, dynamic> json) => SpanData(
    start: json['start'] as int,
    end: json['end'] as int,
    bold: json['bold'] as bool? ?? false,
    italic: json['italic'] as bool? ?? false,
    underline: json['underline'] as bool? ?? false,
    strikethrough: json['strikethrough'] as bool? ?? false,
    textColor: json['textColor'] as int? ?? 0xFF000000,
    highlightColor: json['highlightColor'] as int?,
    fontSize: json['fontSize'] as double? ?? 14.0,
    fontFamily: json['fontFamily'] as String? ?? 'default',
    alignment: json['alignment'] as String? ?? 'left',
    linkUrl: json['linkUrl'] as String?,
  );
}

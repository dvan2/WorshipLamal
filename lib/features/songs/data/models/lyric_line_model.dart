class LyricLine {
  final String id;
  final String content;
  final int lineNumber;
  final String? sectionType;

  LyricLine({
    required this.id,
    required this.content,
    required this.lineNumber,
    this.sectionType,
  });

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    return LyricLine(
      id: map['id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      lineNumber: (map['line_number'] as num?)?.toInt() ?? 0,
      sectionType: map['section_type']?.toString(), // Direct String mapping
    );
  }
}

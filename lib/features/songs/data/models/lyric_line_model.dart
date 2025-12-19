class LyricLine {
  final String content;
  final int lineNumber;

  LyricLine({required this.content, required this.lineNumber});

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    return LyricLine(
      content: map['content'] as String,
      lineNumber: map['line_number'] as int,
    );
  }
}

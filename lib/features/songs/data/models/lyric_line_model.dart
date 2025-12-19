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
      id: map['id'] as String,
      content: map['content'] as String,
      lineNumber: map['line_number'] as int,
      sectionType: map['section_type'] as String?,
    );
  }

  /// Parse section type from database value
  SongSection get section {
    if (sectionType == null || sectionType!.isEmpty) {
      return SongSection.unknown;
    }
    return SongSection.fromString(sectionType!);
  }

  /// Check if this line represents a section header (like [Chorus])
  bool get isSectionHeader =>
      content.trim().toLowerCase().startsWith('[') &&
      content.trim().toLowerCase().endsWith(']');

  /// Extract section name from header format [Verse]
  String get sectionName {
    if (!isSectionHeader) return '';
    return content.trim().replaceAll('[', '').replaceAll(']', '');
  }
}

enum SongSection {
  verse,
  chorus,
  preChorus,
  bridge,
  intro,
  outro,
  tag,
  unknown;

  static SongSection fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'verse':
      case 'v':
        return SongSection.verse;
      case 'chorus':
      case 'c':
        return SongSection.chorus;
      case 'pre-chorus':
      case 'prechorus':
      case 'pre_chorus':
      case 'pc':
        return SongSection.preChorus;
      case 'bridge':
      case 'b':
        return SongSection.bridge;
      case 'intro':
        return SongSection.intro;
      case 'outro':
        return SongSection.outro;
      case 'tag':
        return SongSection.tag;
      default:
        return SongSection.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case SongSection.verse:
        return 'Verse';
      case SongSection.chorus:
        return 'Chorus';
      case SongSection.preChorus:
        return 'Pre-Chorus';
      case SongSection.bridge:
        return 'Bridge';
      case SongSection.intro:
        return 'Intro';
      case SongSection.outro:
        return 'Outro';
      case SongSection.tag:
        return 'Tag';
      case SongSection.unknown:
        return '';
    }
  }

  /// Database value for this section
  String get databaseValue {
    switch (this) {
      case SongSection.verse:
        return 'verse';
      case SongSection.chorus:
        return 'chorus';
      case SongSection.preChorus:
        return 'pre_chorus';
      case SongSection.bridge:
        return 'bridge';
      case SongSection.intro:
        return 'intro';
      case SongSection.outro:
        return 'outro';
      case SongSection.tag:
        return 'tag';
      case SongSection.unknown:
        return '';
    }
  }
}

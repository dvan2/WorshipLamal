class RhythmChart {
  final String id;
  final String songId;
  final String sectionType;
  final int sortOrder;
  final String content;

  const RhythmChart({
    required this.id,
    required this.songId,
    required this.sectionType,
    required this.sortOrder,
    required this.content,
  });

  factory RhythmChart.fromJson(Map<String, dynamic> json) {
    return RhythmChart(
      id: json['id'] as String,
      songId: json['song_id'] as String,
      sectionType: json['section_type'] as String,
      sortOrder: json['sort_order'] as int,
      content: json['content'] as String,
    );
  }
}

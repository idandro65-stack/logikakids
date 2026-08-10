class ProgramModel {
  final String id;
  final String room;
  final String programName;
  final List<String> indicators;
  final int targetPoints;

  ProgramModel({
    required this.id,
    required this.room,
    required this.programName,
    required this.indicators,
    required this.targetPoints,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    List<String> parseIndicators(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return ProgramModel(
      id: json['id']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      programName: json['program_name']?.toString() ?? '',
      indicators: parseIndicators(json['indicators']),
      targetPoints: int.tryParse(json['target_points']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room': room,
      'program_name': programName,
      'indicators': indicators,
      'target_points': targetPoints,
    };
  }
}

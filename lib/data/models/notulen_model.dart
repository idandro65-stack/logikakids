class NotulenModel {
  final String id;
  final String date;
  final String childName;
  final String notulen;
  final String room;
  final List<String> programsSelected;
  final Map<String, List<int>> pointsAchieved;
  final Map<String, String> status;
  final String notes;

  NotulenModel({
    required this.id,
    required this.date,
    required this.childName,
    required this.notulen,
    required this.room,
    required this.programsSelected,
    required this.pointsAchieved,
    required this.status,
    required this.notes,
  });

  factory NotulenModel.fromJson(Map<String, dynamic> json) {
    List<String> parseSelected(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    Map<String, List<int>> parsePoints(dynamic raw) {
      if (raw is Map) {
        Map<String, List<int>> result = {};
        raw.forEach((key, val) {
          if (val is List) {
            result[key.toString()] = val.map((e) => int.tryParse(e.toString()) ?? 0).toList();
          }
        });
        return result;
      }
      return {};
    }

    Map<String, String> parseStatus(dynamic raw) {
      if (raw is Map) {
        Map<String, String> result = {};
        raw.forEach((key, val) {
          result[key.toString()] = val.toString();
        });
        return result;
      }
      return {};
    }

    return NotulenModel(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      childName: json['child_name']?.toString() ?? '',
      notulen: json['notulen']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      programsSelected: parseSelected(json['programs_selected']),
      pointsAchieved: parsePoints(json['points_achieved']),
      status: parseStatus(json['status']),
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'child_name': childName,
      'notulen': notulen,
      'room': room,
      'programs_selected': programsSelected,
      'points_achieved': pointsAchieved,
      'status': status,
      'notes': notes,
    };
  }
}

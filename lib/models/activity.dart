class Activity {
  final String description;
  final String half; // "AM" or "PM"
  final List<int> slots;

  Activity({
    required this.description,
    required this.half,
    required this.slots,
  });

  Map<String, dynamic> toJson() => {
    "description": description,
    "half": half,
    "slots": slots,
  };

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      description: json["description"],
      half: json["half"],
      slots: List<int>.from(json["slots"]),
    );
  }

  double get totalHours => (slots.length * 0.5);
}

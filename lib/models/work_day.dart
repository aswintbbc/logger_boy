import 'package:logger_boy/models/activity.dart';

class WorkDay {
  final String date; // YYYY-MM-DD
  final List<Activity> activities;

  WorkDay({required this.date, required this.activities});

  Map<String, dynamic> toJson() => {
    "date": date,
    "activities": activities.map((a) => a.toJson()).toList(),
  };

  factory WorkDay.fromJson(Map<String, dynamic> json) {
    return WorkDay(
      date: json["date"],
      activities: (json["activities"] as List)
          .map((a) => Activity.fromJson(a))
          .toList(),
    );
  }
}

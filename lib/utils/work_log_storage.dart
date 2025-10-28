import 'dart:convert';
import 'package:logger_boy/models/work_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkLogStorage {
  Future<List<WorkDay>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("worklog");
    if (jsonStr == null) return [];
    final data = jsonDecode(jsonStr) as List;
    return data.map((e) => WorkDay.fromJson(e)).toList();
  }

  Future<void> saveLogs(List<WorkDay> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(logs.map((e) => e.toJson()).toList());
    await prefs.setString("worklog", jsonStr);
  }

  /// ✅ Delete log by date (yyyy-MM-dd)
  Future<void> deleteLog(String date) async {
    final logs = await loadLogs();
    logs.removeWhere((log) => log.date == date);
    await saveLogs(logs);
  }
}

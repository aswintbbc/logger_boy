import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WorkLogApp());
}

class WorkLogApp extends StatelessWidget {
  const WorkLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Log',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LogListScreen(),
    );
  }
}

// ------------------ MODELS ------------------

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
}

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

// ------------------ STORAGE ------------------

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
}

// ------------------ UI ------------------

class LogListScreen extends StatefulWidget {
  const LogListScreen({super.key});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final WorkLogStorage storage = WorkLogStorage();
  List<WorkDay> logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await storage.loadLogs();
    setState(() => logs = l);
  }

  Future<void> _addLog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLogScreen(storage: storage)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Work Logs")),
      body: logs.isEmpty
          ? const Center(child: Text("No logs yet"))
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ExpansionTile(
                  title: Text(log.date),
                  children: log.activities.map((a) {
                    return ListTile(
                      title: Text(a.description),
                      subtitle: Text(
                        "${a.half} - Slots: ${a.slots.join(', ')}",
                      ),
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddLogScreen extends StatefulWidget {
  final WorkLogStorage storage;
  const AddLogScreen({super.key, required this.storage});

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final TextEditingController descCtrl = TextEditingController();
  List<int> selectedAM = [];
  List<int> selectedPM = [];
  List<int> lockedAM = [];
  List<int> lockedPM = [];
  late String today;

  @override
  void initState() {
    super.initState();
    today = DateTime.now().toIso8601String().split("T").first;
    _loadLocked();
  }

  Future<void> _loadLocked() async {
    final logs = await widget.storage.loadLogs();
    final todayLog = logs.where((l) => l.date == today).toList();
    if (todayLog.isNotEmpty) {
      for (var a in todayLog.first.activities) {
        if (a.half == "AM") lockedAM.addAll(a.slots);
        if (a.half == "PM") lockedPM.addAll(a.slots);
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (descCtrl.text.isEmpty || (selectedAM.isEmpty && selectedPM.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final logs = await widget.storage.loadLogs();
    WorkDay? todayLog = logs.firstWhere(
      (l) => l.date == today,
      orElse: () => WorkDay(date: today, activities: []),
    );

    if (!logs.contains(todayLog)) {
      logs.add(todayLog);
    }

    if (selectedAM.isNotEmpty) {
      todayLog.activities.add(
        Activity(description: descCtrl.text, half: "AM", slots: selectedAM),
      );
    }
    if (selectedPM.isNotEmpty) {
      todayLog.activities.add(
        Activity(description: descCtrl.text, half: "PM", slots: selectedPM),
      );
    }

    await widget.storage.saveLogs(logs);
    Navigator.pop(context);
  }

  Widget _buildSlots(String half, List<int> selected, List<int> locked) {
    final slots = List.generate(
      9,
      (i) => i,
    ); // 0–7 = 8 slots (30min each = 4 hrs half)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$half Slots",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isLocked = locked.contains(slot);
            final isSelected = selected.contains(slot);
            return GestureDetector(
              onTap: isLocked
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          selected.remove(slot);
                        } else {
                          selected.add(slot);
                        }
                      });
                    },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey
                      : isSelected
                      ? Colors.blue
                      : Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${(slot ~/ 2) + (half == "AM" ? 9 : 2)}:${slot % 2 == 0 ? "00" : "30"}",
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Log")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            _buildSlots("AM", selectedAM, lockedAM),
            const SizedBox(height: 20),
            _buildSlots("PM", selectedPM, lockedPM),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}

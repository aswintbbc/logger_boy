import 'package:flutter/material.dart';
import 'package:logger_boy/models/activity.dart';
import 'package:logger_boy/models/work_day.dart';
import 'package:logger_boy/utils/work_log_storage.dart';

class AddLogScreen extends StatefulWidget {
  final WorkLogStorage storage;
  final WorkDay? editingDay;

  const AddLogScreen({super.key, required this.storage, this.editingDay});

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final TextEditingController descCtrl = TextEditingController();
  List<int> selectedAM = [];
  List<int> selectedPM = [];
  List<int> lockedAM = [];
  List<int> lockedPM = [];
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();

    if (widget.editingDay != null) {
      selectedDate = DateTime.parse(widget.editingDay!.date);
    } else {
      selectedDate = DateTime.now();
    }
    _loadLocked();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        lockedAM.clear();
        lockedPM.clear();
        selectedAM.clear();
        selectedPM.clear();
      });
      _loadLocked();
    }
  }

  Future<void> _loadLocked() async {
    final logs = await widget.storage.loadLogs();
    final dateKey = selectedDate.toIso8601String().split("T").first;
    final todayLog = logs.where((l) => l.date == dateKey).toList();
    if (todayLog.isNotEmpty) {
      for (var a in todayLog.first.activities) {
        if (a.half == "AM") lockedAM.addAll(a.slots);
        if (a.half == "PM") lockedPM.addAll(a.slots);
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    final dateKey = selectedDate.toIso8601String().split("T").first;
    if (descCtrl.text.isEmpty || (selectedAM.isEmpty && selectedPM.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final logs = await widget.storage.loadLogs();
    WorkDay? dayLog = logs.firstWhere(
      (l) => l.date == dateKey,
      orElse: () => WorkDay(date: dateKey, activities: []),
    );

    if (!logs.contains(dayLog)) {
      logs.add(dayLog);
    }

    if (selectedAM.isNotEmpty) {
      dayLog.activities.add(
        Activity(description: descCtrl.text, half: "AM", slots: selectedAM),
      );
    }
    if (selectedPM.isNotEmpty) {
      dayLog.activities.add(
        Activity(description: descCtrl.text, half: "PM", slots: selectedPM),
      );
    }

    await widget.storage.saveLogs(logs);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
      appBar: AppBar(title: const Text("Add Log")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(child: Text("Date: $dateLabel")),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ],
            ),
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
}

import 'package:flutter/material.dart';
import 'package:logger_boy/models/work_day.dart';
import 'package:logger_boy/screens/add_log_screen.dart';
import 'package:logger_boy/utils/slot_to_time.dart';
import 'package:logger_boy/utils/work_log_storage.dart';

class LogListScreen extends StatefulWidget {
  const LogListScreen({super.key});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final WorkLogStorage storage = WorkLogStorage();
  List<WorkDay> logs = [];
  DateTime selectedMonth = DateTime.now();

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

  void _changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + delta,
        1,
      );
    });
  }

  List<WorkDay> get _filteredLogs {
    final filtered = logs.where((log) {
      final date = DateTime.parse(log.date);
      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    // Sort descending by date
    filtered.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("Work Logs")),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(child: Text("No logs for this month"))
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return ExpansionTile(
                        title: Text(log.date),
                        children: log.activities.map((a) {
                          return ListTile(
                            title: Text(a.description),
                            subtitle: Text(
                              "${a.half} - ${a.slots.map((s) => slotToTime(a.half, s)).join(', ')}",
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

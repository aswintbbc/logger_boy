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

  double _calculateMonthHours(List<WorkDay> logs, String selectedMonth) {
    return logs
        .where((day) => day.date.startsWith(selectedMonth)) // e.g. "2025-09"
        .fold(0.0, (sum, d) => sum + d.totalHours);
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

  Future<void> _deleteDay(String date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Log"),
        content: Text("Are you sure you want to delete logs for $date?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await storage.deleteLog(date);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Deleted logs for $date")));
      }
    }
  }

  void _editDay(WorkDay day) async {
    // Navigate to AddLogScreen with selected day
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLogScreen(editingDay: day, storage: storage),
      ),
    );

    // Refresh logs when returning
    _load();
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
                Spacer(),
                Text(
                  "Total: ${_calculateMonthHours(_filteredLogs, monthLabel).toStringAsFixed(1)} hrs",
                  style: const TextStyle(
                    fontSize: 12,
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
                        children: [
                          ...log.activities.map((a) {
                            return ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${a.description} - ${log.totalHours.toStringAsFixed(1)} hrs',
                                      maxLines: 10,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () => _editDay(log),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteDay(log.date),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                "${a.half} - ${a.slots.map((s) => slotToTime(a.half, s)).join(', ')}",
                              ),
                            );
                          }),
                        ],
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

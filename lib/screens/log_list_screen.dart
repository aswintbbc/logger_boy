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
                        "${a.half} - ${a.slots.map((s) => slotToTime(a.half, s)).join(', ')}",
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

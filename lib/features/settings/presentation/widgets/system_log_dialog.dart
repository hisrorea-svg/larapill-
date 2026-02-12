import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/system_logs_drift_dao.dart';

/// Dialog for viewing system logs
class SystemLogDialog extends ConsumerStatefulWidget {
  const SystemLogDialog({super.key});

  @override
  ConsumerState<SystemLogDialog> createState() => _SystemLogDialogState();

  /// Show the dialog
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => const SystemLogDialog(),
    );
  }
}

class _SystemLogDialogState extends ConsumerState<SystemLogDialog> {
  List<SystemLogEntry> _logs = [];
  bool _isLoading = true;
  String _selectedLevel = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final dao = ref.read(systemLogsDriftDaoProvider);
      final logs = await dao.getAllLogs(limit: 100);

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  Future<void> _loadLogsByLevel(String level) async {
    setState(() => _isLoading = true);
    try {
      final dao = ref.read(systemLogsDriftDaoProvider);
      final logs = level == 'all'
          ? await dao.getAllLogs(limit: 100)
          : await dao.getLogsByLevel(level, limit: 100);

      setState(() {
        _logs = logs;
        _isLoading = false;
        _selectedLevel = level;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment, color: Colors.indigo),
            const SizedBox(width: 8),
            const Text('System Logs'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLogs,
              tooltip: 'Refresh',
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', Colors.grey),
                    _buildFilterChip('Error', 'error', Colors.red),
                    _buildFilterChip('Warning', 'warning', Colors.orange),
                    _buildFilterChip('Info', 'info', Colors.blue),
                    _buildFilterChip('Debug', 'debug', Colors.grey),
                  ],
                ),
              ),
              const Divider(),
              // Logs list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _logs.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return _buildLogTile(log);
                            },
                          ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final dao = ref.read(systemLogsDriftDaoProvider);
              await dao.deleteAllLogs();
              _loadLogs();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String level, Color color) {
    final isSelected = _selectedLevel == level;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _loadLogsByLevel(level),
        selectedColor: color.withValues(alpha: 0.2),
        checkmarkColor: color,
      ),
    );
  }

  Widget _buildLogTile(SystemLogEntry log) {
    final Color levelColor = _getLevelColor(log.level);
    final IconData levelIcon = _getLevelIcon(log.level);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(levelIcon, color: levelColor),
        title: Text(
          log.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${log.category} - ${_formatDateTime(log.createdAt)}',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.userName != null)
                  _buildDetailRow('User', log.userName!),
                if (log.errorCode != null)
                  _buildDetailRow('Error Code', log.errorCode!),
                if (log.details != null)
                  _buildDetailRow('Details', log.details!),
                if (log.stackTrace != null) ...[
                  const Text('Stack Trace:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.stackTrace!,
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace'),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'fatal':
        return Colors.purple;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'fatal':
        return Icons.error;
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'debug':
      default:
        return Icons.bug_report;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}

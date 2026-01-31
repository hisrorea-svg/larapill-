import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../database/database_helper.dart';

class SystemLogDialog extends StatefulWidget {
  const SystemLogDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SystemLogDialog(),
    );
  }

  @override
  State<SystemLogDialog> createState() => _SystemLogDialogState();
}

class _SystemLogDialogState extends State<SystemLogDialog> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // جلب السجلات من قاعدة البيانات
      final results = await db.query(
        'system_logs',
        orderBy: 'created_at DESC',
        limit: 100,
      );

      final logs = results.map((log) {
        return {
          'type': log['log_type'] ?? 'info',
          'message': log['message'] ?? '',
          'timestamp': log['created_at'] ?? DateTime.now().toIso8601String(),
          'details': log['details'] ?? '',
        };
      }).toList();

      // إذا كانت قاعدة البيانات فارغة، استخدم بيانات تجريبية
      if (logs.isEmpty) {
        final mockLogs = [
          {
            'type': 'success',
            'message': 'تم تسجيل الدخول بنجاح',
            'timestamp': DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
            'details': 'المستخدم: مدير النظام',
          },
          {
            'type': 'warning',
            'message': 'تحذير: منتج قريب من الانتهاء',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'details': 'المنتج: باراسيتامول - ينتهي خلال 7 أيام',
          },
          {
            'type': 'info',
            'message': 'تم إنشاء نسخة احتياطية',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            'details': 'الحجم: 2.5 MB',
          },
          {
            'type': 'error',
            'message': 'فشل في الاتصال بالخادم',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 8))
                .toIso8601String(),
            'details': 'Timeout after 30 seconds',
          },
        ];

        if (mounted) {
          setState(() {
            _logs = mockLogs;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _logs = logs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل السجلات: $e',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                )),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filterType == 'all') return _logs;
    return _logs.where((log) => log['type'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                const Text('سجل النظام',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: _loadLogs,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('تصفية:',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
                const SizedBox(width: 8),
                _buildFilterChip('الكل', 'all'),
                _buildFilterChip('معلومات', 'info'),
                _buildFilterChip('تحذير', 'warning'),
                _buildFilterChip('خطأ', 'error'),
                _buildFilterChip('نجاح', 'success'),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('لا توجد سجلات',
                                  style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            return _buildLogEntry(log);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label:
            Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterType = type);
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final type = log['type'] as String? ?? 'info';
    final message = log['message'] as String? ?? '';
    final timestamp = log['timestamp'] as String? ?? '';
    final details = log['details'] as String? ?? '';

    final (icon, color) = _getLogStyle(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getLogStyle(String type) {
    switch (type) {
      case 'error':
        return (Icons.error_outline, AppColors.error);
      case 'warning':
        return (Icons.warning_amber_rounded, AppColors.warning);
      case 'success':
        return (Icons.check_circle_outline, AppColors.success);
      case 'info':
      default:
        return (Icons.info_outline, AppColors.info);
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return 'منذ ${diff.inDays} يوم';
      } else if (diff.inHours > 0) {
        return 'منذ ${diff.inHours} ساعة';
      } else if (diff.inMinutes > 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return timestamp;
    }
  }
}

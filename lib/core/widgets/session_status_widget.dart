import 'package:flutter/material.dart';
import '../services/session_timeout_service.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';

class SessionStatusWidget extends StatefulWidget {
  final bool showInAppBar;
  final VoidCallback? onSessionExtend;

  const SessionStatusWidget({
    super.key,
    this.showInAppBar = false,
    this.onSessionExtend,
  });

  @override
  State<SessionStatusWidget> createState() => _SessionStatusWidgetState();
}

class _SessionStatusWidgetState extends State<SessionStatusWidget>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  Map<String, dynamic> _sessionInfo = {};
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _updateSessionInfo();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateSessionInfo() {
    setState(() {
      _sessionInfo = SessionTimeoutService.getSessionInfo();
    });

    // تشغيل النبضة إذا كان الوقت المتبقي قليل
    final remainingMinutes = _sessionInfo['remainingTime'] as int?;
    if (remainingMinutes != null && remainingMinutes <= 5) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateSessionInfo();
      }
    });
  }

  Color _getStatusColor() {
    final remainingMinutes = _sessionInfo['remainingTime'] as int?;
    if (remainingMinutes == null || remainingMinutes <= 0) {
      return Colors.red;
    } else if (remainingMinutes <= 5) {
      return Colors.red;
    } else if (remainingMinutes <= 15) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    final remainingMinutes = _sessionInfo['remainingTime'] as int?;
    if (remainingMinutes == null || remainingMinutes <= 0) {
      return Icons.error;
    } else if (remainingMinutes <= 5) {
      return Icons.warning;
    } else {
      return Icons.schedule;
    }
  }

  String _getTimeText() {
    final remainingMinutes = _sessionInfo['remainingTime'] as int?;
    if (remainingMinutes == null || remainingMinutes <= 0) {
      return 'انتهت';
    } else if (remainingMinutes < 60) {
      return '$remainingMinutesد';
    } else {
      final hours = remainingMinutes ~/ 60;
      final minutes = remainingMinutes % 60;
      return '$hoursس $minutesد';
    }
  }

  void _showSessionDetails() {
    showDialog(
      context: context,
      builder: (context) => SessionDetailsDialog(
        sessionInfo: _sessionInfo,
        onExtendSession: widget.onSessionExtend,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!(_sessionInfo['isActive'] as bool? ?? false)) {
      return const SizedBox.shrink();
    }

    if (widget.showInAppBar) {
      return _buildAppBarVersion();
    } else {
      return _buildFullVersion();
    }
  }

  Widget _buildAppBarVersion() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: InkWell(
            onTap: _showSessionDetails,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeText(),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullVersion() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor().withValues(alpha: 0.1),
                  _getStatusColor().withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حالة الجلسة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'باقي ${_getTimeText()}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showSessionDetails,
                  child: Text(
                    'التفاصيل',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SessionDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> sessionInfo;
  final VoidCallback? onExtendSession;

  const SessionDetailsDialog({
    super.key,
    required this.sessionInfo,
    this.onExtendSession,
  });

  @override
  State<SessionDetailsDialog> createState() => _SessionDetailsDialogState();
}

class _SessionDetailsDialogState extends State<SessionDetailsDialog> {
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await SessionTimeoutService.getSessionStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _extendSession() async {
    await SessionTimeoutService.extendSession(
      additionalTime: const Duration(hours: 2),
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onExtendSession?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ تم تمديد الجلسة لساعتين إضافيتين',
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingMinutes = widget.sessionInfo['remainingTime'] as int?;
    final sessionDuration = widget.sessionInfo['sessionDuration'] as int?;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.schedule, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            'تفاصيل الجلسة',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الجلسة الحالية
            _buildInfoCard(
              title: 'الجلسة الحالية',
              children: [
                _buildInfoRow(
                    'المستخدم', widget.sessionInfo['userId'] ?? 'غير محدد'),
                _buildInfoRow(
                    'الوقت المتبقي',
                    remainingMinutes != null
                        ? '$remainingMinutes دقيقة'
                        : 'غير محدد'),
                _buildInfoRow(
                    'مدة الجلسة',
                    sessionDuration != null
                        ? '$sessionDuration دقيقة'
                        : 'غير محدد'),
                _buildInfoRow(
                    'آخر نشاط',
                    widget.sessionInfo['lastActivity'] != null
                        ? _formatDateTime(widget.sessionInfo['lastActivity'])
                        : 'غير محدد'),
              ],
            ),

            const SizedBox(height: 16),

            // الإحصائيات
            if (_isLoadingStats)
              const Center(child: CircularProgressIndicator())
            else if (_statistics != null)
              _buildInfoCard(
                title: 'الإحصائيات',
                children: [
                  _buildInfoRow(
                      'إجمالي الجلسات', '${_statistics!['totalSessions']}'),
                  _buildInfoRow('إجمالي الوقت النشط',
                      '${_statistics!['totalActiveTime']} ساعة'),
                  _buildInfoRow('متوسط مدة الجلسة',
                      '${_statistics!['averageSessionTime']} دقيقة'),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق',
              style: TextStyle(
                fontFamily: 'Tajawal',
              )),
        ),
        if (remainingMinutes != null && remainingMinutes > 0)
          ElevatedButton(
            onPressed: _extendSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تمديد الجلسة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'غير محدد';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return 'منذ ${difference.inDays} يوم';
      }
    } catch (e) {
      return 'غير صحيح';
    }
  }
}

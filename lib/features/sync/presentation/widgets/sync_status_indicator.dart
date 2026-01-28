import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

/// Widget indicator لعرض حالة المزامنة
class SyncStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  final double size;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionStatusProvider);
    final pendingAsync = ref.watch(pendingSalesCountProvider);

    return connectionAsync.when(
      data: (status) => _buildIndicator(context, ref, status, pendingAsync),
      loading: () => _buildLoadingIndicator(),
      error: (_, __) => _buildErrorIndicator(),
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    WidgetRef ref,
    ConnectionStatus status,
    AsyncValue<int> pendingAsync,
  ) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final label = _getStatusLabel(status);
    final pendingCount = pendingAsync.valueOrNull ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showSyncDetails(context, ref, status, pendingCount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نقطة الحالة المتحركة
            _StatusDot(color: color, size: size),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            // عداد المبيعات المعلّقة
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.error_outline, size: 16, color: Colors.red),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.wifi;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.disconnected:
        return Icons.wifi_off;
      case ConnectionStatus.error:
        return Icons.error_outline;
    }
  }

  String _getStatusLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'متصل';
      case ConnectionStatus.connecting:
        return 'جاري الاتصال...';
      case ConnectionStatus.disconnected:
        return 'غير متصل';
      case ConnectionStatus.error:
        return 'خطأ';
    }
  }

  void _showSyncDetails(
    BuildContext context,
    WidgetRef ref,
    ConnectionStatus status,
    int pendingCount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _SyncDetailsDialog(
        status: status,
        pendingCount: pendingCount,
      ),
    );
  }
}

/// نقطة الحالة المتحركة
class _StatusDot extends StatefulWidget {
  final Color color;
  final double size;

  const _StatusDot({required this.color, required this.size});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: widget.size,
                spreadRadius: widget.size / 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dialog لتفاصيل المزامنة
class _SyncDetailsDialog extends ConsumerWidget {
  final ConnectionStatus status;
  final int pendingCount;

  const _SyncDetailsDialog({
    required this.status,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final configAsync = ref.watch(terminalConfigProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi, color: Colors.blue),
          SizedBox(width: 8),
          Text('حالة المزامنة'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نوع الجهاز
          configAsync.when(
            data: (config) => config != null
                ? _buildInfoRow(
                    'نوع الجهاز',
                    config.isMaster
                        ? 'الجهاز الرئيسي (Master)'
                        : 'كاشير (Cashier)',
                    config.isMaster ? Colors.blue : Colors.green,
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),

          // حالة الاتصال
          _buildInfoRow(
            'حالة الاتصال',
            _getStatusLabel(status),
            _getStatusColor(status),
          ),

          // المبيعات المعلّقة
          if (pendingCount > 0)
            _buildInfoRow(
              'مبيعات معلّقة',
              '$pendingCount مبيعة',
              Colors.orange,
            ),

          // آخر مزامنة
          syncStatusAsync.whenOrNull(
                data: (syncStatus) {
                  final lastSync = syncStatus.lastSuccessfulSync;
                  if (lastSync == null) return null;
                  return _buildInfoRow(
                    'آخر مزامنة',
                    _formatTime(lastSync),
                    Colors.grey,
                  );
                },
              ) ??
              const SizedBox.shrink(),

          const SizedBox(height: 16),

          // رسالة الحالة
          syncStatusAsync.whenOrNull(
                data: (syncStatus) => Text(
                  syncStatus.statusMessage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      actions: [
        // زر المزامنة اليدوية
        if (status == ConnectionStatus.connected)
          TextButton.icon(
            onPressed: () {
              ref.read(syncNotifierProvider.notifier).syncNow();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('مزامنة الآن'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  String _getStatusLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'متصل';
      case ConnectionStatus.connecting:
        return 'جاري الاتصال...';
      case ConnectionStatus.disconnected:
        return 'غير متصل';
      case ConnectionStatus.error:
        return 'خطأ في الاتصال';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

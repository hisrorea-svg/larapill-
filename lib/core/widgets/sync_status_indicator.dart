/// Sync Status Indicator Widget
///
/// Shows the current synchronization status in the app bar or as a floating indicator.
/// Displays connection state, pending sync count, and allows manual sync trigger.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sync/domain/entities/sync_status_entity.dart';
import '../../features/sync/presentation/providers/sync_notifier.dart';

/// Compact sync indicator for use in AppBar
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final status = syncState.status;

    // Determine icon and color based on state
    IconData icon;
    Color color;
    String tooltip;

    switch (status.state) {
      case SyncState.syncing:
      case SyncState.pushing:
      case SyncState.pulling:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'جاري المزامنة...';
        break;
      case SyncState.completed:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'تمت المزامنة';
        break;
      case SyncState.failed:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = 'فشلت المزامنة';
        break;
      case SyncState.downloadingSnapshot:
        icon = Icons.download;
        color = Colors.orange;
        tooltip = 'جاري تحميل البيانات...';
        break;
      default:
        if (status.isConnected) {
          icon = Icons.cloud_queue;
          color = Colors.green.shade300;
          tooltip = 'متصل';
        } else {
          icon = Icons.cloud_off;
          color = Colors.grey;
          tooltip = 'غير متصل';
        }
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSyncDetails(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status.isSyncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(icon, color: color, size: 20),
                if (status.pendingSalesCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${status.pendingSalesCount}',
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
        ),
      ),
    );
  }

  void _showSyncDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SyncDetailsSheet(),
    );
  }
}

/// Detailed sync status sheet
class SyncDetailsSheet extends ConsumerWidget {
  const SyncDetailsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final status = syncState.status;
    final notifier = ref.read(syncNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getStatusIcon(status.state, status.isConnected),
                color: _getStatusColor(status.state, status.isConnected),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة المزامنة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      status.statusMessage.isNotEmpty
                          ? status.statusMessage
                          : _getDefaultMessage(status),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Stats
          _buildStatRow('الحالة', _getStatusText(status.state)),
          _buildStatRow('الاتصال', status.isConnected ? 'متصل' : 'غير متصل'),
          _buildStatRow('المبيعات في الانتظار', '${status.pendingSalesCount}'),
          if (status.lastSuccessfulSync != null)
            _buildStatRow(
              'آخر مزامنة',
              _formatDateTime(status.lastSuccessfulSync!),
            ),

          const SizedBox(height: 16),

          // Actions
          if (status.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: status.isSyncing
                      ? null
                      : () {
                          notifier.syncNow();
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.sync),
                  label: const Text('مزامنة الآن'),
                ),
              ),
            ],
          ),

          if (syncState.config != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sync-setup');
              },
              icon: const Icon(Icons.settings),
              label: const Text('إعدادات المزامنة'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getStatusText(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return 'غير مهيأ';
      case SyncState.downloadingSnapshot:
        return 'تحميل البيانات';
      case SyncState.pushing:
        return 'رفع المبيعات';
      case SyncState.pulling:
        return 'جلب التحديثات';
      case SyncState.syncing:
        return 'مزامنة';
      case SyncState.completed:
        return 'تم';
      case SyncState.failed:
        return 'فشل';
    }
  }

  String _getDefaultMessage(SyncStatusEntity status) {
    if (status.isConnected) {
      return 'متصل بالجهاز الرئيسي';
    }
    return 'غير متصل';
  }

  IconData _getStatusIcon(SyncState state, bool isConnected) {
    switch (state) {
      case SyncState.syncing:
      case SyncState.pushing:
      case SyncState.pulling:
        return Icons.sync;
      case SyncState.completed:
        return Icons.cloud_done;
      case SyncState.failed:
        return Icons.cloud_off;
      default:
        return isConnected ? Icons.cloud_queue : Icons.cloud_off;
    }
  }

  Color _getStatusColor(SyncState state, bool isConnected) {
    switch (state) {
      case SyncState.syncing:
      case SyncState.pushing:
      case SyncState.pulling:
        return Colors.blue;
      case SyncState.completed:
        return Colors.green;
      case SyncState.failed:
        return Colors.red;
      default:
        return isConnected ? Colors.green.shade300 : Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Floating sync indicator for use in screens
class FloatingSyncIndicator extends ConsumerWidget {
  const FloatingSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final status = syncState.status;

    // Only show when syncing or has pending items
    if (!status.isSyncing && status.pendingSalesCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        color: status.isSyncing ? Colors.blue : Colors.orange,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => const SyncDetailsSheet(),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.sync_problem, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  status.isSyncing
                      ? 'جاري المزامنة...'
                      : '${status.pendingSalesCount} مبيعة في الانتظار',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

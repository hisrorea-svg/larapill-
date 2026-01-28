// lib/features/network/presentation/screens/network_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lan_providers.dart';
import '../providers/network_settings_notifier.dart';
import '../../domain/entities/network_settings_entity.dart';
import '../../../../core/network/sync_aware_sales_service.dart';
import '../../../../core/network/offline_queue_service.dart';

/// شاشة حالة الشبكة وسجل العمليات
class NetworkStatusScreen extends ConsumerStatefulWidget {
  const NetworkStatusScreen({super.key});

  @override
  ConsumerState<NetworkStatusScreen> createState() =>
      _NetworkStatusScreenState();
}

class _NetworkStatusScreenState extends ConsumerState<NetworkStatusScreen> {
  final OfflineQueueService _offlineQueue = OfflineQueueService();
  List<QueuedOperation> _pendingOperations = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPendingOperations();
  }

  Future<void> _loadPendingOperations() async {
    await _offlineQueue.loadQueue();
    setState(() {
      _pendingOperations = _offlineQueue.getPendingOperations();
    });
  }

  Future<void> _processQueue() async {
    setState(() => _isProcessing = true);

    try {
      final syncService = ref.read(syncAwareSalesServiceProvider);
      final processed = await syncService.processOfflineQueue();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم معالجة $processed عملية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPendingOperations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(networkSettingsNotifierProvider);
    final isServerRunning = ref.watch(serverRunningProvider);
    final isClientConnected = ref.watch(clientConnectedProvider);
    final connectedClients = ref.watch(connectedClientsProvider);
    final localIp = ref.watch(localIpProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('حالة الشبكة', style: GoogleFonts.tajawal()),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPendingOperations,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حالة الاتصال
              _buildStatusCard(settings, isServerRunning, isClientConnected,
                  localIp, connectedClients),
              const SizedBox(height: 16),

              // العمليات المعلقة
              _buildPendingOperationsCard(),
              const SizedBox(height: 16),

              // سجل النشاط
              _buildActivityLog(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    NetworkSettingsEntity settings,
    bool isServerRunning,
    bool isClientConnected,
    AsyncValue<String> localIp,
    List<String> connectedClients,
  ) {
    final isOnline = settings.mode == NetworkMode.server
        ? isServerRunning
        : isClientConnected;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.withAlpha(30)
                        : Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    color: isOnline ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.mode == NetworkMode.server
                            ? 'وضع السيرفر'
                            : 'وضع الكلاينت',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOnline ? 'متصل ✓' : 'غير متصل',
                        style: GoogleFonts.tajawal(
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // معلومات إضافية
            if (settings.mode == NetworkMode.server) ...[
              _buildInfoRow(
                  'IP المحلي',
                  localIp.when(
                    data: (ip) => ip,
                    loading: () => '...',
                    error: (_, __) => 'غير معروف',
                  )),
              _buildInfoRow('المنفذ', settings.port.toString()),
              _buildInfoRow(
                  'الأجهزة المتصلة', connectedClients.length.toString()),
              if (connectedClients.isNotEmpty)
                ...connectedClients.map((ip) => Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: _buildInfoRow('', ip),
                    )),
            ] else ...[
              _buildInfoRow('IP السيرفر', settings.serverIp ?? 'غير محدد'),
              _buildInfoRow(
                  'حالة الاتصال', isClientConnected ? 'متصل' : 'غير متصل'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.tajawal(color: Colors.grey[600])),
          Text(value, style: GoogleFonts.tajawal(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPendingOperationsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.pending_actions, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العمليات المعلقة',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_pendingOperations.length} عملية في الانتظار',
                        style: GoogleFonts.tajawal(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (_pendingOperations.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processQueue,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_isProcessing ? 'جاري...' : 'مزامنة',
                        style: GoogleFonts.tajawal()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            if (_pendingOperations.isNotEmpty) ...[
              const Divider(height: 24),
              ..._pendingOperations.take(5).map((op) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getOperationIcon(op.type),
                      color: Colors.orange,
                      size: 20,
                    ),
                    title: Text(
                      _getOperationTitle(op.type),
                      style: GoogleFonts.tajawal(fontSize: 13),
                    ),
                    subtitle: Text(
                      _formatDateTime(op.createdAt),
                      style:
                          GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: op.retryCount > 0
                        ? Text('محاولة ${op.retryCount}',
                            style: GoogleFonts.tajawal(
                                fontSize: 11, color: Colors.red))
                        : null,
                  )),
              if (_pendingOperations.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${_pendingOperations.length - 5} عمليات أخرى',
                    style:
                        GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Text(
                  'سجل النشاط',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد أنشطة حديثة',
                    style: GoogleFonts.tajawal(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOperationIcon(QueueOperationType type) {
    switch (type) {
      case QueueOperationType.sale:
        return Icons.shopping_cart;
      case QueueOperationType.stockUpdate:
        return Icons.inventory;
      case QueueOperationType.productAdd:
        return Icons.add_box;
      case QueueOperationType.productUpdate:
        return Icons.edit;
    }
  }

  String _getOperationTitle(QueueOperationType type) {
    switch (type) {
      case QueueOperationType.sale:
        return 'عملية بيع';
      case QueueOperationType.stockUpdate:
        return 'تحديث مخزون';
      case QueueOperationType.productAdd:
        return 'إضافة منتج';
      case QueueOperationType.productUpdate:
        return 'تحديث منتج';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

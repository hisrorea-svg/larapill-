/// lib/features/sync/presentation/screens/sync_status_screen.dart
///
/// شاشة حالة المزامنة - تعرض حالة الاتصال بالجهاز الرئيسي
///
/// Sync System - الجديد (بدلاً من API Router القديم)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_notifier.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final status = syncState.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة المزامنة'),
        centerTitle: true,
      ),
      body: _buildStatus(context, status, ref),
    );
  }

  Widget _buildStatus(BuildContext context, dynamic status, WidgetRef ref) {
    final isConnected = status.isConnected ?? false;
    final pendingCount = status.pendingSalesCount ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // حالة الاتصال
          Card(
            color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isConnected ? Colors.green : Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'متصل بالجهاز الرئيسي' : 'غير متصل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green : Colors.orange,
                          ),
                        ),
                        if (status.statusMessage != null)
                          Text(
                            status.statusMessage!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // المبيعات المعلقة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 48, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مبيعات في الانتظار',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '$pendingCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // زر المزامنة اليدوية
          ElevatedButton.icon(
            onPressed: () => ref.read(syncNotifierProvider.notifier).syncNow(),
            icon: const Icon(Icons.sync),
            label: const Text('مزامنة الآن'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

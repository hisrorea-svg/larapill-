import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../sync/domain/entities/entities.dart';
import '../../sync/presentation/providers/providers.dart';

/// محدد نوع الجهاز (Master/Cashier)
class TerminalTypeSelector extends ConsumerWidget {
  const TerminalTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(terminalConfigProvider);
    final connectionAsync = ref.watch(connectionStatusProvider);

    return configAsync.when(
      data: (config) => _buildSelector(context, ref, config, connectionAsync),
      loading: () => _buildLoading(),
      error: (_, __) => _buildNotConfigured(context),
    );
  }

  Widget _buildSelector(
    BuildContext context,
    WidgetRef ref,
    TerminalConfigEntity? config,
    AsyncValue<ConnectionStatus> connectionAsync,
  ) {
    if (config == null) {
      return _buildNotConfigured(context);
    }

    final isMaster = config.isMaster;
    final color = isMaster ? Colors.blue : Colors.green;
    final icon = isMaster ? Icons.storage : Icons.point_of_sale;
    final label = isMaster ? 'Master' : 'Cashier';

    // حالة الاتصال
    final connectionColor = connectionAsync.when(
      data: (status) => _getConnectionColor(status),
      loading: () => Colors.grey,
      error: (_, __) => Colors.red,
    );

    return InkWell(
      onTap: () => _showTerminalInfo(context, config, connectionAsync),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نقطة حالة الاتصال
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connectionColor,
                boxShadow: [
                  BoxShadow(
                    color: connectionColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildNotConfigured(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/sync-setup'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              'إعداد الجهاز',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConnectionColor(ConnectionStatus status) {
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

  void _showTerminalInfo(
    BuildContext context,
    TerminalConfigEntity config,
    AsyncValue<ConnectionStatus> connectionAsync,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TerminalInfoSheet(
        config: config,
        connectionAsync: connectionAsync,
      ),
    );
  }
}

class _TerminalInfoSheet extends StatelessWidget {
  final TerminalConfigEntity config;
  final AsyncValue<ConnectionStatus> connectionAsync;

  const _TerminalInfoSheet({
    required this.config,
    required this.connectionAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isMaster = config.isMaster;
    final color = isMaster ? Colors.blue : Colors.green;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // أيقونة الجهاز
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isMaster ? Icons.storage : Icons.point_of_sale,
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 16),

          // اسم الجهاز
          Text(
            config.name,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMaster ? 'الجهاز الرئيسي (Master)' : 'نقطة بيع (Cashier)',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 24),

          // معلومات الاتصال
          if (!isMaster) ...[
            _buildInfoRow(
              'السيرفر',
              '${config.masterIp}:${config.masterPort}',
              Icons.computer,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'حالة الاتصال',
              connectionAsync.when(
                data: (s) => _getStatusLabel(s),
                loading: () => 'جاري...',
                error: (_, __) => 'خطأ',
              ),
              Icons.wifi,
            ),
          ],

          const SizedBox(height: 24),

          // زر إعادة الإعداد
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sync-setup');
            },
            icon: const Icon(Icons.settings),
            label: const Text('إعادة الإعداد'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
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
}

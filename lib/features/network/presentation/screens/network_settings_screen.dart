// lib/features/network/presentation/screens/network_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/network_settings_entity.dart';
import '../providers/network_settings_notifier.dart';
import '../providers/lan_providers.dart';
import '../../../../core/network/http_client_service.dart';
import '../../../../core/theme/app_colors.dart';

/// شاشة إعدادات الشبكة
class NetworkSettingsScreen extends ConsumerStatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  ConsumerState<NetworkSettingsScreen> createState() =>
      _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends ConsumerState<NetworkSettingsScreen> {
  final _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(networkSettingsNotifierProvider);
      _ipController.text = settings.serverIp ?? '';
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(networkSettingsNotifierProvider);
    final localIpAsync = ref.watch(localIpProvider);
    final isServerRunning = ref.watch(serverRunningProvider);
    final isClientConnected = ref.watch(clientConnectedProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إعدادات الشبكة', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // حالة الاتصال
            _buildStatusCard(
                settings, isServerRunning, isClientConnected, localIpAsync),
            const SizedBox(height: 16),

            // اختيار الوضع
            _buildModeCard(settings),
            const SizedBox(height: 16),

            // إعدادات الكلاينت
            if (settings.isClient) ...[
              _buildClientSettingsCard(settings),
              const SizedBox(height: 16),
            ],

            // إعدادات متقدمة
            _buildAdvancedSettingsCard(settings),
            const SizedBox(height: 16),

            // معلومات
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    NetworkSettingsEntity settings,
    bool isServerRunning,
    bool isClientConnected,
    AsyncValue<String> localIpAsync,
  ) {
    final isActive = settings.isServer ? isServerRunning : isClientConnected;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusText = settings.isServer
        ? (isServerRunning ? 'السيرفر يعمل' : 'السيرفر متوقف')
        : (isClientConnected ? 'متصل بالسيرفر' : 'غير متصل');

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              statusColor.withAlpha(30),
              statusColor.withAlpha(10),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (settings.isServer) ...[
              localIpAsync.when(
                data: (ip) => _buildInfoRow('IP المحلي:', ip),
                loading: () => _buildInfoRow('IP المحلي:', 'جارٍ التحميل...'),
                error: (_, __) => _buildInfoRow('IP المحلي:', 'خطأ'),
              ),
              _buildInfoRow('المنفذ:', '${settings.port}'),
            ] else ...[
              _buildInfoRow('IP السيرفر:', settings.serverIp ?? 'غير محدد'),
            ],
            const SizedBox(height: 12),
            _buildActionButton(settings, isServerRunning, isClientConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم النسخ: $value')),
              );
            },
            tooltip: 'نسخ',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    NetworkSettingsEntity settings,
    bool isServerRunning,
    bool isClientConnected,
  ) {
    if (settings.isServer) {
      return ElevatedButton.icon(
        onPressed: () => _toggleServer(!isServerRunning),
        icon: Icon(isServerRunning ? Icons.stop : Icons.play_arrow),
        label: Text(
          isServerRunning ? 'إيقاف السيرفر' : 'تشغيل السيرفر',
          style: GoogleFonts.tajawal(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isServerRunning ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
        ),
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: isClientConnected ? _disconnect : _connect,
            icon: Icon(isClientConnected ? Icons.link_off : Icons.link),
            label: Text(
              isClientConnected ? 'قطع الاتصال' : 'اتصال',
              style: GoogleFonts.tajawal(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isClientConnected ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _discoverServer,
            icon: const Icon(Icons.search),
            label: Text('بحث تلقائي', style: GoogleFonts.tajawal()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildModeCard(NetworkSettingsEntity settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وضع الجهاز',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<NetworkMode>(
              segments: [
                ButtonSegment(
                  value: NetworkMode.server,
                  label: Text('سيرفر', style: GoogleFonts.tajawal()),
                  icon: const Icon(Icons.computer),
                ),
                ButtonSegment(
                  value: NetworkMode.client,
                  label: Text('كلاينت', style: GoogleFonts.tajawal()),
                  icon: const Icon(Icons.phone_android),
                ),
              ],
              selected: {settings.mode},
              onSelectionChanged: (modes) async {
                await ref
                    .read(networkSettingsNotifierProvider.notifier)
                    .setMode(modes.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              settings.isServer
                  ? 'هذا الجهاز سيستقبل الاتصالات من الأجهزة الأخرى'
                  : 'هذا الجهاز سيتصل بجهاز السيرفر',
              style: GoogleFonts.tajawal(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSettingsCard(NetworkSettingsEntity settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعدادات الاتصال',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'IP السيرفر',
                hintText: '192.168.1.1',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lan),
                labelStyle: GoogleFonts.tajawal(),
                hintStyle: GoogleFonts.tajawal(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) async {
                await ref
                    .read(networkSettingsNotifierProvider.notifier)
                    .setServerIp(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsCard(NetworkSettingsEntity settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعدادات متقدمة',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text('صلاحية الكتابة', style: GoogleFonts.tajawal()),
              subtitle: Text(
                settings.isMaster ? 'يمكن تعديل البيانات' : 'قراءة فقط',
                style: GoogleFonts.tajawal(fontSize: 12),
              ),
              value: settings.isMaster,
              onChanged: (value) async {
                await ref
                    .read(networkSettingsNotifierProvider.notifier)
                    .setMaster(value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: Text('اتصال تلقائي', style: GoogleFonts.tajawal()),
              subtitle: Text(
                'الاتصال تلقائياً عند بدء التطبيق',
                style: GoogleFonts.tajawal(fontSize: 12),
              ),
              value: settings.autoConnect,
              onChanged: (value) async {
                await ref
                    .read(networkSettingsNotifierProvider.notifier)
                    .setAutoConnect(value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: Text('إعادة اتصال تلقائي', style: GoogleFonts.tajawal()),
              subtitle: Text(
                'إعادة الاتصال عند الانقطاع',
                style: GoogleFonts.tajawal(fontSize: 12),
              ),
              value: settings.autoReconnect,
              onChanged: (value) async {
                await ref
                    .read(networkSettingsNotifierProvider.notifier)
                    .setAutoReconnect(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'دليل الإعداد',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showFullSetupGuide(),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text('التفاصيل',
                      style: GoogleFonts.tajawal(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• الربط بكيبل LAN أو WiFi (نفس الشبكة)\n'
              '• شغّل السيرفر على الجهاز الأول\n'
              '• أدخل IP السيرفر في الجهاز الثاني\n'
              '• قد تحتاج لتعطيل Firewall مؤقتاً',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lan, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text('دليل ربط الأجهزة عبر LAN',
                  style: GoogleFonts.tajawal(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGuideSection(
                  '1️⃣ طريقة الربط',
                  '• كيبل LAN مباشر بين جهازين\n'
                      '• أو عبر راوتر/سويتش (كيبل أو WiFi)\n'
                      '• الشرط: نفس الشبكة المحلية',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  '2️⃣ إعداد IP (للربط المباشر بكيبل)',
                  '📌 الجهاز الأول (السيرفر):\n'
                      '   Settings → Network → Ethernet → Edit\n'
                      '   IP: 192.168.1.10\n'
                      '   Subnet: 255.255.255.0\n\n'
                      '📌 الجهاز الثاني (الكلاينت):\n'
                      '   IP: 192.168.1.11\n'
                      '   Subnet: 255.255.255.0',
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  '3️⃣ في التطبيق',
                  '• الجهاز الأول: اختر "سيرفر" ← تشغيل\n'
                      '• الجهاز الثاني: اختر "كلاينت"\n'
                      '• أدخل IP السيرفر (192.168.1.10)\n'
                      '• اضغط "اتصال"',
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  '⚠️ حل المشاكل',
                  '• تأكد من تعطيل Windows Firewall\n'
                      '• تأكد من أن الكيبل موصول بشكل صحيح\n'
                      '• جرب "بحث تلقائي" للعثور على السيرفر\n'
                      '• تأكد من تشغيل السيرفر أولاً',
                  Colors.red,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('فهمت', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServer(bool start) async {
    final server = ref.read(httpServerProvider);

    if (start) {
      try {
        await server.startServer();
        ref.read(serverRunningProvider.notifier).state = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم تشغيل السيرفر')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ خطأ: $e')),
          );
        }
      }
    } else {
      await server.stopServer();
      ref.read(serverRunningProvider.notifier).state = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🛑 تم إيقاف السيرفر')),
        );
      }
    }
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ أدخل IP السيرفر')),
      );
      return;
    }

    final client = ref.read(httpClientProvider);
    final success = await client.connect(ip);

    if (success) {
      ref.read(clientConnectedProvider.notifier).state = true;
      ref.read(connectedServerIpProvider.notifier).state = ip;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم الاتصال بنجاح')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ فشل الاتصال - تأكد من IP والـ Firewall')),
        );
      }
    }
  }

  void _disconnect() {
    final client = ref.read(httpClientProvider);
    client.disconnect();
    ref.read(clientConnectedProvider.notifier).state = false;
    ref.read(connectedServerIpProvider.notifier).state = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔌 تم قطع الاتصال')),
    );
  }

  Future<void> _discoverServer() async {
    ref.read(isDiscoveringProvider.notifier).state = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔍 جارٍ البحث عن السيرفر...')),
    );

    try {
      // محاولة اكتشاف السيرفر
      final localIp = await ref.read(localIpProvider.future);
      final parts = localIp.split('.');
      if (parts.length == 4) {
        final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
        final serverIp = await HttpClientService.discoverServer(subnet: subnet);

        if (serverIp != null) {
          _ipController.text = serverIp;
          await ref
              .read(networkSettingsNotifierProvider.notifier)
              .setServerIp(serverIp);
          ref.read(discoveredServerIpProvider.notifier).state = serverIp;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ تم العثور على السيرفر: $serverIp')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ لم يتم العثور على سيرفر')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e')),
        );
      }
    } finally {
      ref.read(isDiscoveringProvider.notifier).state = false;
    }
  }
}

// lib/features/network/presentation/screens/network_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/network_settings_notifier.dart';
import '../providers/lan_providers.dart';
import '../../../../core/network/http_client_service.dart';
import '../../../../core/theme/app_colors.dart';

/// شاشة الإعداد الأولي للشبكة
class NetworkSetupScreen extends ConsumerStatefulWidget {
  const NetworkSetupScreen({super.key});

  @override
  ConsumerState<NetworkSetupScreen> createState() => _NetworkSetupScreenState();
}

class _NetworkSetupScreenState extends ConsumerState<NetworkSetupScreen> {
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withBlue(200),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // الشعار
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lan,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // العنوان
                    Text(
                      'إعداد الشبكة',
                      style: GoogleFonts.tajawal(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر دور هذا الجهاز في الشبكة',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // خيارات الإعداد
                    if (_currentStep == 0) _buildRoleSelection(),
                    if (_currentStep == 1) _buildClientSetup(),

                    const SizedBox(height: 32),

                    // زر تخطي
                    TextButton(
                      onPressed: _skipSetup,
                      child: Text(
                        'تخطي الإعداد',
                        style: GoogleFonts.tajawal(
                          color: Colors.white.withAlpha(180),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        // زر السيرفر
        _buildRoleCard(
          icon: Icons.computer,
          title: 'جهاز رئيسي (سيرفر)',
          description: 'هذا الجهاز سيستقبل الاتصالات من الأجهزة الأخرى',
          color: Colors.green,
          onTap: _setupAsServer,
        ),
        const SizedBox(height: 16),

        // زر الكلاينت
        _buildRoleCard(
          icon: Icons.phone_android,
          title: 'جهاز ثانوي (كلاينت)',
          description: 'هذا الجهاز سيتصل بجهاز السيرفر',
          color: Colors.blue,
          onTap: () => setState(() => _currentStep = 1),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSetup() {
    final ipController = TextEditingController();
    final isDiscovering = ref.watch(isDiscoveringProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          IconButton(
            onPressed: () => setState(() => _currentStep = 0),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل IP السيرفر',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ipController,
            decoration: InputDecoration(
              labelText: 'IP السيرفر',
              hintText: '192.168.1.1',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lan),
              labelStyle: GoogleFonts.tajawal(),
              hintStyle: GoogleFonts.tajawal(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // زر البحث التلقائي
          OutlinedButton.icon(
            onPressed:
                isDiscovering ? null : () => _discoverServer(ipController),
            icon: isDiscovering
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(
              isDiscovering ? 'جارٍ البحث...' : 'بحث تلقائي',
              style: GoogleFonts.tajawal(),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 12),

          // زر الاتصال
          ElevatedButton.icon(
            onPressed:
                _isLoading ? null : () => _setupAsClient(ipController.text),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.link),
            label: Text('اتصال', style: GoogleFonts.tajawal()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupAsServer() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(networkSettingsNotifierProvider.notifier);
      await notifier.setupAsServer();

      // تشغيل السيرفر تلقائياً
      final server = ref.read(httpServerProvider);
      await server.startServer();
      ref.read(serverRunningProvider.notifier).state = true;

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupAsClient(String ip) async {
    if (ip.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ أدخل IP السيرفر')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // اختبار الاتصال أولاً
      final client = ref.read(httpClientProvider);
      final connected = await client.connect(ip);

      if (!connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ فشل الاتصال - تأكد من IP والـ Firewall'),
            ),
          );
        }
        return;
      }

      // حفظ الإعدادات
      final notifier = ref.read(networkSettingsNotifierProvider.notifier);
      await notifier.setupAsClient(ip);
      ref.read(clientConnectedProvider.notifier).state = true;

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _discoverServer(TextEditingController controller) async {
    ref.read(isDiscoveringProvider.notifier).state = true;

    try {
      final localIp = await ref.read(localIpProvider.future);
      final parts = localIp.split('.');
      if (parts.length == 4) {
        final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
        final serverIp = await HttpClientService.discoverServer(subnet: subnet);

        if (serverIp != null) {
          controller.text = serverIp;
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

  Future<void> _skipSetup() async {
    // إعداد كسيرفر افتراضي
    final notifier = ref.read(networkSettingsNotifierProvider.notifier);
    await notifier.setupAsServer();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

/// صفحة إعداد المزامنة (Master or Cashier)
class SyncSetupScreen extends ConsumerStatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  ConsumerState<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends ConsumerState<SyncSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();

  bool _isLoading = false;
  bool _isDiscovering = false;
  double _discoveryProgress = 0;
  String? _discoveredIp;
  TerminalType _selectedType = TerminalType.cashier;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد الجهاز'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Icon(
                      Icons.settings_input_antenna,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'إعداد المزامنة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر نوع هذا الجهاز في شبكة المبيعات',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // نوع الجهاز
                    _buildTerminalTypeSelector(),
                    const SizedBox(height: 24),

                    // اسم الجهاز
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الجهاز',
                        hintText: 'مثال: كاشير 1',
                        prefixIcon: Icon(Icons.devices),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم الجهاز';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // إعدادات الكاشير
                    if (_selectedType == TerminalType.cashier) ...[
                      _buildCashierSettings(),
                    ],

                    const SizedBox(height: 32),

                    // زر الحفظ
                    ElevatedButton.icon(
                      onPressed: _saveConfig,
                      icon: const Icon(Icons.check),
                      label: const Text('حفظ الإعدادات'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTerminalTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TerminalTypeCard(
            isSelected: _selectedType == TerminalType.master,
            type: TerminalType.master,
            title: 'جهاز رئيسي',
            subtitle: 'يدير المخزون والمبيعات',
            icon: Icons.storage,
            color: Colors.blue,
            onTap: () => setState(() => _selectedType = TerminalType.master),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TerminalTypeCard(
            isSelected: _selectedType == TerminalType.cashier,
            type: TerminalType.cashier,
            title: 'كاشير',
            subtitle: 'نقطة بيع تتصل بالرئيسي',
            icon: Icons.point_of_sale,
            color: Colors.green,
            onTap: () => setState(() => _selectedType = TerminalType.cashier),
          ),
        ),
      ],
    );
  }

  Widget _buildCashierSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اتصال بالجهاز الرئيسي',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // زر البحث التلقائي
            if (_discoveredIp == null) ...[
              OutlinedButton.icon(
                onPressed: _isDiscovering ? null : _discoverServer,
                icon: _isDiscovering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isDiscovering
                    ? 'جاري البحث... ${(_discoveryProgress * 100).toInt()}%'
                    : 'بحث تلقائي عن السيرفر'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // تم العثور على السيرفر
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تم العثور على السيرفر!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text('عنوان: $_discoveredIp'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() => _discoveredIp = null);
                        _ipController.clear();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // إدخال يدوي
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'عنوان IP للجهاز الرئيسي',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_selectedType == TerminalType.cashier) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان IP';
                  }
                  final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                  if (!ipRegex.hasMatch(value)) {
                    return 'صيغة IP غير صحيحة';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _discoverServer() async {
    setState(() {
      _isDiscovering = true;
      _discoveryProgress = 0;
    });

    try {
      final notifier = ref.read(syncNotifierProvider.notifier);
      final result = await notifier.discoverServer(
        onProgress: (current, total) {
          if (mounted) {
            setState(() => _discoveryProgress = current / total);
          }
        },
      );

      final ip = result?.ip;
      if (result != null && result.found && ip != null) {
        setState(() {
          _discoveredIp = ip;
          _ipController.text = ip;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على سيرفر في الشبكة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isDiscovering = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(syncNotifierProvider.notifier);
      bool success;

      if (_selectedType == TerminalType.master) {
        success = await notifier.setupAsMaster(
          name: _nameController.text.trim(),
        );
      } else {
        success = await notifier.setupAsCashier(
          name: _nameController.text.trim(),
          masterIp: _ipController.text.trim(),
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // Initialize sync
        await notifier.initialize();

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        final error = ref.read(syncNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'فشل حفظ الإعدادات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// بطاقة اختيار نوع الجهاز
class _TerminalTypeCard extends StatelessWidget {
  final bool isSelected;
  final TerminalType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TerminalTypeCard({
    required this.isSelected,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (Colors.grey[300] ?? Colors.grey),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20)
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

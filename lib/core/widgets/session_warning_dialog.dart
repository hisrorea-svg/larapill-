import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';

class SessionWarningDialog extends StatefulWidget {
  final Duration remainingTime;
  final VoidCallback onExtendSession;
  final VoidCallback onLogout;

  const SessionWarningDialog({
    super.key,
    required this.remainingTime,
    required this.onExtendSession,
    required this.onLogout,
  });

  @override
  State<SessionWarningDialog> createState() => _SessionWarningDialogState();
}

class _SessionWarningDialogState extends State<SessionWarningDialog>
    with TickerProviderStateMixin {
  late AnimationController _warningController;
  late AnimationController _countdownController;
  late Animation<double> _warningAnimation;
  late Animation<Color?> _colorAnimation;

  Timer? _countdownTimer;
  late Duration _currentRemaining;

  @override
  void initState() {
    super.initState();
    _currentRemaining = widget.remainingTime;

    // إعداد الرسوم المتحركة
    _warningController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _warningAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.orange,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.easeInOut,
    ));

    // بدء الرسوم المتحركة
    _warningController.repeat(reverse: true);
    _countdownController.repeat(reverse: true);

    // بدء العد التنازلي
    _startCountdown();
  }

  @override
  void dispose() {
    _warningController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentRemaining = _currentRemaining - const Duration(seconds: 1);
        });

        // إنهاء الحوار تلقائياً عند انتهاء الوقت
        if (_currentRemaining.inSeconds <= 0) {
          timer.cancel();
          Navigator.of(context).pop();
          widget.onLogout();
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(Duration duration) {
    if (duration.inSeconds <= 0) return '00:00';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getWarningColor() {
    if (_currentRemaining.inMinutes >= 5) return Colors.orange;
    if (_currentRemaining.inMinutes >= 2) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getWarningIcon() {
    if (_currentRemaining.inMinutes >= 5) return Icons.schedule;
    if (_currentRemaining.inMinutes >= 2) return Icons.warning;
    return Icons.error;
  }

  String _getWarningMessage() {
    if (_currentRemaining.inMinutes >= 5) {
      return 'ستنتهي جلستك قريباً';
    } else if (_currentRemaining.inMinutes >= 2) {
      return 'جلستك على وشك الانتهاء!';
    } else {
      return 'جلستك ستنتهي خلال ثوانٍ!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // منع إغلاق الحوار بزر الرجوع
      child: AnimatedBuilder(
        animation: Listenable.merge([_warningAnimation, _colorAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _warningAnimation.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _getWarningColor(),
                  width: 2,
                ),
              ),
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getWarningColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getWarningColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getWarningIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحذير انتهاء الجلسة',
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getWarningColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWarningMessage(),
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // العد التنازلي
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getWarningColor().withValues(alpha: 0.1),
                          _getWarningColor().withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getWarningColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'الوقت المتبقي',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(_currentRemaining),
                          style: GoogleFonts.robotoMono(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getWarningColor(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _currentRemaining.inSeconds /
                              widget.remainingTime.inSeconds,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_getWarningColor()),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // رسالة توضيحية
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'يمكنك تمديد الجلسة أو تسجيل الخروج الآن لحفظ عملك',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // زر تسجيل الخروج
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onLogout();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    'تسجيل الخروج',
                    style: GoogleFonts.tajawal(),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),

                // زر تمديد الجلسة
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onExtendSession();
                  },
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    'تمديد الجلسة',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getWarningColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// مساعد لعرض حوار التحذير
class SessionWarningHelper {
  static void showWarning(
    BuildContext context, {
    required Duration remainingTime,
    required VoidCallback onExtendSession,
    required VoidCallback onLogout,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionWarningDialog(
        remainingTime: remainingTime,
        onExtendSession: onExtendSession,
        onLogout: onLogout,
      ),
    );
  }

  /// عرض تحذير بسيط في SnackBar
  static void showSimpleWarning(
    BuildContext context, {
    required Duration remainingTime,
    required VoidCallback onExtendSession,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ستنتهي جلستك خلال ${remainingTime.inMinutes} دقيقة',
                style: GoogleFonts.tajawal(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'تمديد',
          textColor: Colors.white,
          onPressed: onExtendSession,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';

/// Dialog for double confirmation of critical operations
/// Requires user to type "DELETE" to confirm
class DeleteConfirmationDialog extends StatefulWidget {
  final String operationType;
  final String? warningMessage;

  const DeleteConfirmationDialog({
    super.key,
    required this.operationType,
    this.warningMessage,
  });

  /// Show the confirmation dialog
  /// Returns true if user typed DELETE correctly, false otherwise
  static Future<bool> confirm(
    BuildContext context, {
    required String operationType,
    String? warningMessage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeleteConfirmationDialog(
        operationType: operationType,
        warningMessage: warningMessage,
      ),
    );

    return result ?? false;
  }

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  final _textController = TextEditingController();
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_checkText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkText() {
    setState(() {
      _isCorrect = _textController.text.trim() == 'DELETE';
    });
  }

  void _confirm() {
    if (_isCorrect) {
      Navigator.of(context).pop(true);
    } else {
      AppToast.error(
        context,
        'الرجاء كتابة DELETE بالأحرف الكبيرة بشكل صحيح',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⚠️ تأكيد نهائي',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  widget.operationType,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning message
          if (widget.warningMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.warningMessage!,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Instructions
          const Text(
            'للمتابعة، اكتب كلمة DELETE بالأحرف الكبيرة:',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Text field
          TextField(
            controller: _textController,
            autofocus: true,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                _isCorrect ? Icons.check_circle : Icons.edit,
                color: _isCorrect ? AppColors.success : AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isCorrect ? AppColors.success : Colors.grey.shade300,
                  width: _isCorrect ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isCorrect ? AppColors.success : AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Hint
          if (!_isCorrect)
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  'يجب كتابة DELETE بالأحرف الكبيرة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'إلغاء',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isCorrect ? _confirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          icon: const Icon(Icons.delete_forever),
          label: const Text(
            'نعم، تنفيذ',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

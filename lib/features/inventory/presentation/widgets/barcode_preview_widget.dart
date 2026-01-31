import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../../../../core/models/barcode_type.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget لمعاينة الباركود مباشرة
class BarcodePreviewWidget extends StatelessWidget {
  final String barcode;
  final BarcodeType barcodeType;
  final String? productName;
  final double? price;
  final String? pharmacyName;
  final bool includePrice;
  final double width;
  final double height;

  const BarcodePreviewWidget({
    super.key,
    required this.barcode,
    required this.barcodeType,
    this.productName,
    this.price,
    this.pharmacyName,
    this.includePrice = false,
    this.width = 200,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (barcode.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Center(
          child: Text(
            'لا يوجد باركود',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: .3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اسم الصيدلية
              if (pharmacyName != null && pharmacyName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    pharmacyName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),

              // اسم المنتج
              if (productName != null && productName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    productName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // السعر
              if (includePrice && price != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${price!.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),

              // الباركود
              Flexible(
                child: Center(
                  child: _buildBarcodeWidget(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarcodeWidget() {
    try {
      return bw.BarcodeWidget(
        barcode: _getBarcodeForWidget(),
        data: barcode,
        width: width * 0.8,
        height: barcodeType == BarcodeType.qrCode ? 80 : 60,
        drawText: false,
        errorBuilder: (context, error) => _buildErrorWidget(error),
      );
    } catch (e) {
      return _buildErrorWidget(e.toString());
    }
  }

  bw.Barcode _getBarcodeForWidget() {
    switch (barcodeType) {
      case BarcodeType.ean13:
        return bw.Barcode.ean13();
      case BarcodeType.ean8:
        return bw.Barcode.ean8();
      case BarcodeType.upcA:
        return bw.Barcode.upcA();
      case BarcodeType.upcE:
        return bw.Barcode.upcE();
      case BarcodeType.code128:
        return bw.Barcode.code128();
      case BarcodeType.qrCode:
        return bw.Barcode.qrCode();
    }
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(height: 4),
          Text(
            'خطأ في الباركود',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            error,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 8,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

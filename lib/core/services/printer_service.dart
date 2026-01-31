import 'dart:typed_data';
import '../../features/pos/domain/entities/sale.dart';
import '../../features/purchases/data/models/daily_purchase_request.dart';
import '../models/barcode_type.dart';
import '../models/barcode_label_size.dart';
import 'printers/receipt_printer.dart';
import 'printers/barcode_printer.dart';
import 'printers/report_printer.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  // طباعة فاتورة البيع
  static Future<void> printReceipt({
    required Sale sale,
    required List<Map<String, dynamic>> items,
    String? customerName,
    required double totalAmount,
    required double amountPaid,
    required double change,
  }) async {
    await ReceiptPrinter.printReceipt(
      sale: sale,
      items: items,
      customerName: customerName,
      totalAmount: totalAmount,
      amountPaid: amountPaid,
      change: change,
    );
  }

  // طباعة طلبات الشراء اليومية
  Future<void> printDailyPurchaseRequests({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    await ReportPrinter.printDailyPurchaseRequests(
      requests: requests,
      supplierName: supplierName,
    );
  }

  /// طباعة باركود منتج
  static Future<void> printProductBarcode({
    required String barcode,
    required BarcodeType barcodeType,
    String? productName,
    double? price,
    BarcodeLabelSize labelSize = BarcodeLabelSize.standard,
    double? customWidth,
    double? customHeight,
    bool includePrice = false,
    int copies = 1,
  }) async {
    await BarcodePrinter.printProductBarcode(
      barcode: barcode,
      barcodeType: barcodeType,
      productName: productName,
      price: price,
      labelSize: labelSize,
      customWidth: customWidth,
      customHeight: customHeight,
      includePrice: includePrice,
      copies: copies,
    );
  }

  // معاينة طلبات الشراء اليومية قبل الطباعة - إرجاع البيانات للمعاينة
  Future<Uint8List> generateDailyPurchasePdfBytes({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    return await ReportPrinter.generateDailyPurchasePdfBytes(
      requests: requests,
      supplierName: supplierName,
    );
  }

  // معاينة طلبات الشراء اليومية قبل الطباعة (مع نافذة طباعة)
  Future<void> previewDailyPurchaseRequests({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    await ReportPrinter.previewDailyPurchaseRequests(
      requests: requests,
      supplierName: supplierName,
    );
  }

  // مشاركة طلبات الشراء اليومية
  Future<void> shareDailyPurchaseRequests({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    await ReportPrinter.shareDailyPurchaseRequests(
      requests: requests,
      supplierName: supplierName,
    );
  }
}

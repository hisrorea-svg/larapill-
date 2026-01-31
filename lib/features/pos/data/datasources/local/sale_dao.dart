import '../../../../../../core/models/shared/medicine_unit.dart';
import '../../../domain/entities/sale.dart';
import '../../../../../database/database_helper.dart';

class SaleDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // إضافة مبيعة جديدة مع تفاصيل العناصر
  Future<void> insertSale(Sale sale) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // إدراج المبيعة الرئيسية مع حقول الديون
      await txn.insert('sales', {
        'id': sale.id,
        'date': sale.date.toIso8601String(),
        'subtotal': sale.subtotal,
        'discount': sale.discount,
        'tax': sale.tax,
        'total': sale.total,
        'paid_amount': sale.paidAmount,
        'remaining_amount': sale.remainingAmount,
        'payment_status': sale.paymentStatus.name,
        'payment_method': sale.paymentMethod.name,
        'customer_name': sale.customerName,
        'customer_phone': sale.customerPhone,
        'cashier_id': sale.cashierId,
        'cashier_name': sale.cashierName,
        'status': sale.status.name,
        'created_at': sale.createdAt.toIso8601String(),
      });

      // إدراج عناصر البيع
      for (var item in sale.items) {
        await txn.insert('sale_items', {
          'id': item.id,
          'sale_id': sale.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit': item.unit.name,
          'unit_price': item.unitPrice,
          'quantity': item.quantity,
          'total': item.total,
        });
      }
    });
  }

  // جلب جميع المبيعات
  Future<List<Sale>> getAllSales() async {
    final db = await _dbHelper.database;
    final salesData = await db.query('sales', orderBy: 'date DESC');
    List<Sale> sales = [];

    for (var saleMap in salesData) {
      final saleId = saleMap['id'] as String;
      final itemsData = await db
          .query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      List<SaleItem> items = itemsData
          .map((i) => SaleItem(
                id: i['id'] as String,
                productId: i['product_id'] as String,
                productName: i['product_name'] as String,
                unit:
                    MedicineUnit.values.firstWhere((u) => u.name == i['unit']),
                unitPrice: (i['unit_price'] as num).toDouble(),
                quantity: (i['quantity'] as num).toDouble(),
                total: (i['total'] as num).toDouble(),
              ))
          .toList();

      sales.add(Sale(
        id: saleId,
        date: DateTime.parse(saleMap['date'] as String),
        items: items,
        subtotal: (saleMap['subtotal'] as num).toDouble(),
        discount: (saleMap['discount'] as num?)?.toDouble() ?? 0.0,
        tax: (saleMap['tax'] as num?)?.toDouble() ?? 0.0,
        total: (saleMap['total'] as num).toDouble(),
        paidAmount: (saleMap['paid_amount'] as num?)?.toDouble() ??
            (saleMap['total'] as num).toDouble(),
        remainingAmount:
            (saleMap['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == (saleMap['payment_status'] ?? 'paid'),
          orElse: () => PaymentStatus.paid,
        ),
        paymentMethod: PaymentMethod.values
            .firstWhere((e) => e.name == saleMap['payment_method']),
        customerName: saleMap['customer_name'] as String?,
        customerPhone: saleMap['customer_phone'] as String?,
        cashierId: saleMap['cashier_id'] as String,
        cashierName: saleMap['cashier_name'] as String? ?? "",
        status:
            SaleStatus.values.firstWhere((e) => e.name == saleMap['status']),
        createdAt: DateTime.parse(saleMap['created_at'] as String),
      ));
    }
    return sales;
  }

  // حذف مبيعة (حذف ناعم أو نهائي)
  Future<int> deleteSale(String saleId) async {
    final db = await _dbHelper.database;
    // حذف العناصر أولاً
    await db.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    // حذف السجل الأساسي
    return await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  // جلب المبيعات بتاريخ معين
  Future<List<Sale>> getSalesByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final salesData = await db.query(
      'sales',
      where: 'date LIKE ?',
      whereArgs: ['${date.toIso8601String().substring(0, 10)}%'],
      orderBy: 'date DESC',
    );
    // نفس طريقة استخراج العناصر كما في getAllSales()
    // مختصر لتكرار الكود
    List<Sale> sales = [];
    for (var saleMap in salesData) {
      final saleId = saleMap['id'] as String;
      final itemsData = await db
          .query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      List<SaleItem> items = itemsData
          .map((i) => SaleItem(
                id: i['id'] as String,
                productId: i['product_id'] as String,
                productName: i['product_name'] as String,
                unit:
                    MedicineUnit.values.firstWhere((u) => u.name == i['unit']),
                unitPrice: (i['unit_price'] as num).toDouble(),
                quantity: (i['quantity'] as num).toDouble(),
                total: (i['total'] as num).toDouble(),
              ))
          .toList();

      sales.add(Sale(
        id: saleId,
        date: DateTime.parse(saleMap['date'] as String),
        items: items,
        subtotal: (saleMap['subtotal'] as num).toDouble(),
        discount: (saleMap['discount'] as num?)?.toDouble() ?? 0.0,
        tax: (saleMap['tax'] as num?)?.toDouble() ?? 0.0,
        total: (saleMap['total'] as num).toDouble(),
        paidAmount: (saleMap['paid_amount'] as num?)?.toDouble() ??
            (saleMap['total'] as num).toDouble(),
        remainingAmount:
            (saleMap['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == (saleMap['payment_status'] ?? 'paid'),
          orElse: () => PaymentStatus.paid,
        ),
        paymentMethod: PaymentMethod.values
            .firstWhere((e) => e.name == saleMap['payment_method']),
        customerName: saleMap['customer_name'] as String?,
        customerPhone: saleMap['customer_phone'] as String?,
        cashierId: saleMap['cashier_id'] as String,
        cashierName: saleMap['cashier_name'] as String? ?? "",
        status:
            SaleStatus.values.firstWhere((e) => e.name == saleMap['status']),
        createdAt: DateTime.parse(saleMap['created_at'] as String),
      ));
    }
    return sales;
  }

  // 🆕 توليد رقم فاتورة احترافي ومبهم (FK-XXXXX)
  Future<String> generateSaleId() async {
    final db = await _dbHelper.database;

    // البحث عن آخر رقم فاتورة FK
    final result = await db.query(
      'sales',
      columns: ['id'],
      where: 'id LIKE ?',
      whereArgs: ['FK-%'],
      orderBy: 'id DESC',
      limit: 1,
    );

    int nextNumber = 10001; // نبدأ من 10001 لإخفاء العدد الحقيقي
    if (result.isNotEmpty) {
      final lastId = result.first['id'] as String;
      // استخراج الرقم من آخر فاتورة (مثال: FK-A3F2B → رقم مشفر)
      final parts = lastId.split('-');
      if (parts.length == 2) {
        // فك التشفير: تحويل من Base36 إلى رقم
        final decoded = int.tryParse(parts[1], radix: 36) ?? 10000;
        nextNumber = decoded + 1;
      }
    }

    // 🔐 تشفير الرقم: تحويل إلى Base36 (0-9 و A-Z)
    // مثال: 10001 → 7PS, 10050 → 7RU, 100000 → 255S
    final encodedNumber = nextNumber.toRadixString(36).toUpperCase();

    // إنشاء رقم الفاتورة: FK-XXXXX
    // مثال: FK-7PS, FK-A3F2B, FK-ZX9K2
    return 'FK-$encodedNumber';
  }
}

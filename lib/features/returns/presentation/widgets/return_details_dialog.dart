import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/return_entity.dart';

class ReturnDetailsDialog extends StatelessWidget {
  final Return return_;

  const ReturnDetailsDialog({
    super.key,
    required this.return_,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'تفاصيل المرتجع',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // معلومات المرتجع
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromARGB(
                  (0.1 * 255).round(),
                  (AppColors.info.r * 255).round(),
                  (AppColors.info.g * 255).round(),
                  (AppColors.info.b * 255).round(),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('رقم المرتجع:', return_.id),
                  _buildInfoRow('رقم المبيعة:', return_.saleId),
                  _buildInfoRow(
                      'تاريخ المرتجع:', _formatDate(return_.returnDate)),
                  _buildInfoRow('سبب الإرجاع:', return_.reason.arabicName),
                  _buildInfoRow('الحالة:', return_.status.arabicName),
                  _buildInfoRow(
                      'المبلغ المسترد:', '${return_.totalRefund} د.ع'),
                  _buildInfoRow(
                      'طريقة الاسترداد:', return_.refundMethod.arabicName),
                  if (return_.notes != null)
                    _buildInfoRow('ملاحظات:', return_.notes!),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // جدول المنتجات المرتجعة
            const Text(
              'المنتجات المرتجعة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(
                        label: Text('اسم المنتج',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                            ))),
                    DataColumn(
                        label: Text('الوحدة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                            ))),
                    DataColumn(
                        label: Text('الكمية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                            ))),
                    DataColumn(
                        label: Text('سعر الوحدة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                            ))),
                    DataColumn(
                        label: Text('المجموع',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                            ))),
                  ],
                  rows: return_.items
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item.productName,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                ))),
                            DataCell(Text(item.unit.arabicName,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                ))),
                            DataCell(Text(item.quantity.toString(),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                ))),
                            DataCell(Text('${item.unitPrice} د.ع',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                ))),
                            DataCell(Text('${item.total} د.ع',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                ))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // زر الإغلاق
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ),
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
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Tajawal',
              )),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

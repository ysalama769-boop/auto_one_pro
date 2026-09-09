import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

class AdminBookingsBody extends StatefulWidget {
  final bool isArabic;

  const AdminBookingsBody({super.key, required this.isArabic});

  @override
  State<AdminBookingsBody> createState() => _AdminBookingsBodyState();
}


class _AdminBookingsBodyState extends State<AdminBookingsBody> {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        bookings = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = isArabic
            ? 'تعذّر تحميل الحجوزات'
            : 'Failed to load bookings';
        isLoading = false;
      });
    }
  }

  // بتصدّر الحجوزات لملف CSV (بيتفتح عادي في Excel) وتنزّله في المتصفح
  void _exportBookingsToExcel() {
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'مفيش حجوزات تتصدّر دلوقتي' : 'No bookings to export',
          ),
        ),
      );
      return;
    }

    String cell(dynamic value) {
      final text = (value ?? '').toString().replaceAll('"', '""');
      return '"$text"';
    }

    final buffer = StringBuffer();
    buffer.writeln([
      isArabic ? 'اسم العميل' : 'Customer Name',
      isArabic ? 'رقم الجوال' : 'Phone',
      isArabic ? 'رقم الواتساب' : 'WhatsApp',
      isArabic ? 'الإيميل' : 'Email',
      isArabic ? 'المدينة' : 'City',
      isArabic ? 'السيارة' : 'Car',
      isArabic ? 'الماركة' : 'Brand',
      isArabic ? 'السعر' : 'Price',
      isArabic ? 'اللون' : 'Color',
      isArabic ? 'الحالة' : 'Status',
      isArabic ? 'ملاحظات' : 'Notes',
      isArabic ? 'تاريخ الحجز' : 'Date',
    ].map(cell).join(','));

    for (final b in bookings) {
      buffer.writeln([
        cell(b['customer_name']),
        cell(b['phone']),
        cell(b['whatsapp']),
        cell(b['email']),
        cell(b['city']),
        cell(b['car_name']),
        cell(b['car_brand']),
        cell(b['car_price']),
        cell(b['selected_color']),
        cell(b['status']),
        cell(b['notes']),
        cell(b['created_at']),
      ].join(','));
    }

    // بنضيف BOM في الأول عشان الحروف العربية تظهر صح في Excel
    final bytes = utf8.encode('\uFEFF${buffer.toString()}');
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'auto_one_bookings_${DateTime.now().millisecondsSinceEpoch}.csv',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _updateStatus(Map<String, dynamic> booking, String newStatus) async {
    final id = booking['id'] as int;

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus}).eq('id', id);
      _loadBookings();

      // نجهز رسالة للعميل ونفتح واتساب أو الإيميل عشان تدوسي إرسال
      final carLabel =
          '${booking['car_brand'] ?? ''} ${booking['car_name'] ?? ''}'.trim();
      final customerName = (booking['customer_name'] ?? '') as String;
      final whatsapp = (booking['whatsapp'] ?? '') as String;
      final email = (booking['email'] ?? '') as String;

      final message = newStatus == 'confirmed'
          ? (isArabic
              ? 'أهلًا $customerName، تم تأكيد حجزك لسيارة $carLabel في AUTO ONE. هيتم التواصل معاك قريبًا لاستكمال باقي الإجراءات. شكرًا لثقتك بينا! 🚗'
              : 'Hi $customerName, your booking for $carLabel at AUTO ONE has been confirmed. We will contact you soon to complete the process. Thank you!')
          : (isArabic
              ? 'أهلًا $customerName، نأسف لإبلاغك إنه تم إلغاء حجزك لسيارة $carLabel في AUTO ONE. لأي استفسار تقدري تتواصلي معانا في أي وقت.'
              : 'Hi $customerName, unfortunately your booking for $carLabel at AUTO ONE has been cancelled. Feel free to reach out to us anytime.');

      if (whatsapp.isNotEmpty) {
        final digitsOnly = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
        final url = Uri.parse(
          'https://wa.me/$digitsOnly?text=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (email.isNotEmpty) {
        final subject = newStatus == 'confirmed'
            ? (isArabic ? 'تأكيد حجزك في AUTO ONE' : 'Your AUTO ONE booking is confirmed')
            : (isArabic ? 'بخصوص حجزك في AUTO ONE' : 'About your AUTO ONE booking');
        final url = Uri.parse(
          'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة، حاولي تاني' : 'Something went wrong',
          ),
        ),
      );
    }
  }

  Future<void> _deleteBooking(int id, {String? customerName, String? carName}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm delete'),
        content: Text(
          isArabic
              ? 'متأكدة إنك عايزة تمسحي حجز ${customerName ?? ""}${(carName ?? "").isNotEmpty ? " (${carName!})" : ""} نهائيًا؟'
              : 'Delete the booking for "${customerName ?? ""}"${(carName ?? "").isNotEmpty ? " (${carName!})" : ""} permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('bookings').delete().eq('id', id);
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة، حاولي تاني' : 'Something went wrong',
          ),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return isArabic ? 'مؤكد' : 'Confirmed';
      case 'cancelled':
        return isArabic ? 'ملغي' : 'Cancelled';
      default:
        return isArabic ? 'قيد الانتظار' : 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: const Color(0xfff5f5f5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'كل الحجوزات' : 'All bookings',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _exportBookingsToExcel,
                        tooltip: isArabic
                            ? 'تصدير Excel (CSV)'
                            : 'Export to Excel (CSV)',
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                      IconButton(
                        onPressed: _loadBookings,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
            ? skeletonCardList()
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : bookings.isEmpty
                    ? Center(
                        child: Text(
                          isArabic ? 'مفيش حجوزات لسه' : 'No bookings yet',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final status =
                              (booking['status'] ?? 'pending') as String;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${booking['car_brand'] ?? ''} ${booking['car_name'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${isArabic ? "السعر" : "Price"}: ${booking['car_price'] ?? ''}',
                                  style:
                                      const TextStyle(color: Colors.black54),
                                ),
                                if ((booking['selected_color'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    '${isArabic ? "اللون" : "Color"}: ${booking['selected_color']}',
                                    style: const TextStyle(
                                        color: Colors.black54),
                                  ),
                                const Divider(height: 20),
                                Text(
                                  booking['customer_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  booking['phone'] ?? '',
                                  style:
                                      const TextStyle(color: Colors.black54),
                                ),
                                if ((booking['city'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    booking['city'],
                                    style: const TextStyle(
                                        color: Colors.black54),
                                  ),
                                if ((booking['notes'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    booking['notes'],
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (status != 'confirmed')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(
                                          booking,
                                          'confirmed',
                                        ),
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isArabic ? 'تأكيد' : 'Confirm',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    if (status != 'cancelled')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(
                                          booking,
                                          'cancelled',
                                        ),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isArabic ? 'إلغاء' : 'Cancel',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () => _deleteBooking(
                                        booking['id'] as int,
                                        customerName: booking['customer_name']
                                            as String?,
                                        carName:
                                            '${booking['car_brand'] ?? ''} ${booking['car_name'] ?? ''}'
                                                .trim(),
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      label: Text(
                                        isArabic ? 'حذف' : 'Delete',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}


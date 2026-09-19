import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../shared/auth.dart';

// ============================================================
// MY REQUESTS PAGE (طلباتي - حجوزات وتمويل سابقة للزبون المسجّل)
// ============================================================
class MyRequestsPage extends StatefulWidget {
  final bool isArabic;
  const MyRequestsPage({super.key, required this.isArabic});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
    markCustomerNotificationsSeen();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('customer_requests')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('bookings')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
      ]);

      final customerRequests = List<Map<String, dynamic>>.from(
        results[0] as List,
      );
      final bookings = List<Map<String, dynamic>>.from(results[1] as List)
          .map((b) => {...b, 'request_type': 'booking'})
          .toList();

      final merged = [...customerRequests, ...bookings];
      merged.sort((a, b) {
        final aDate = (a['created_at'] ?? '').toString();
        final bDate = (b['created_at'] ?? '').toString();
        return bDate.compareTo(aDate);
      });

      setState(() {
        requests = merged;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'booking':
        return isArabic ? 'حجز سيارة' : 'Car booking';
      case 'financing':
        return isArabic ? 'طلب تمويل' : 'Financing request';
      case 'contact':
        return isArabic ? 'استفسار' : 'Inquiry';
      default:
        return isArabic ? 'استفسار' : 'Inquiry';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      // حالات الحجوزات (bookings)
      case 'confirmed':
        return isArabic ? 'تم التأكيد' : 'Confirmed';
      case 'cancelled':
        return isArabic ? 'ملغي' : 'Cancelled';
      // حالات طلبات العملاء (customer_requests)
      case 'contacted':
        return isArabic ? 'تم التواصل معاك' : 'We contacted you';
      case 'follow_up':
        return isArabic ? 'قيد المتابعة' : 'Following up';
      case 'closed':
        return isArabic ? 'تم الإغلاق' : 'Closed';
      // حالات عامة قديمة (لو موجودة)
      case 'approved':
      case 'accepted':
        return isArabic ? 'مقبول' : 'Accepted';
      case 'rejected':
      case 'declined':
        return isArabic ? 'مرفوض' : 'Declined';
      case 'completed':
        return isArabic ? 'مكتمل' : 'Completed';
      default:
        return isArabic ? 'قيد المراجعة' : 'In review';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'approved':
      case 'accepted':
      case 'completed':
      case 'closed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'declined':
        return Colors.red;
      case 'contacted':
        return Colors.blue;
      case 'follow_up':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'financing':
        return Icons.account_balance_wallet_outlined;
      case 'contact':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = isArabic
          ? [
              'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
              'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
            ]
          : [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'طلباتي' : 'My Requests'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : requests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 60,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'مفيش طلبات سابقة لسه'
                                : 'No previous requests yet',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      final type = (r['request_type'] ?? '').toString();
                      final status = (r['status'] ?? 'new').toString();
                      final carName = (r['car_name'] ?? '').toString();
                      final createdAt = (r['created_at'] ?? '').toString();
                      final color = _statusColor(status);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // شريط ملوّن على الجنب بلون الحالة، عشان
                              // تعرف حالة الطلب من نظرة واحدة
                              Container(
                                width: 5,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _typeIcon(type),
                                          color: color,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _typeLabel(type),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                            if (carName.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                carName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                            if (createdAt.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatDate(createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

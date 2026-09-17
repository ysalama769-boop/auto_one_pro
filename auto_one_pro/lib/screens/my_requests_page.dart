import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

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
      case 'approved':
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      final type = (r['request_type'] ?? '').toString();
                      final status = (r['status'] ?? 'new').toString();
                      final carName = (r['car_name'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _typeLabel(type),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
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
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

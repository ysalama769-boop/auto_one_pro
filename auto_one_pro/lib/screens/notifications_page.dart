import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/auth.dart';
import 'my_requests_page.dart';

// ============================================================
// NOTIFICATIONS PAGE (إعلانات + تحديثات طلبات الزبون)
// ============================================================
class NotificationsPage extends StatefulWidget {
  final bool isArabic;
  const NotificationsPage({super.key, required this.isArabic});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
    markCustomerNotificationsSeen();
  }

  Future<void> _load() async {
    try {
      final response = await Supabase.instance.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      setState(() {
        announcements = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'offer':
        return isArabic ? 'عرض/خصم' : 'Offer';
      case 'service':
        return isArabic ? 'خدمة جديدة' : 'New service';
      case 'car':
        return isArabic ? 'سيارة جديدة' : 'New car';
      default:
        return isArabic ? 'إعلان' : 'Announcement';
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'offer':
        return Icons.local_offer_outlined;
      case 'service':
        return Icons.miscellaneous_services_outlined;
      case 'car':
        return Icons.directions_car_filled_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'offer':
        return Colors.red;
      case 'service':
        return Colors.teal;
      case 'car':
        return Colors.indigo;
      default:
        return Colors.orange;
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
          title: Text(isArabic ? 'الإشعارات' : 'Notifications'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // زرار سريع لصفحة "طلباتي" التفصيلية
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyRequestsPage(isArabic: isArabic),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'شوف حالة طلباتك وحجوزاتك'
                              : 'View your requests and bookings status',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(
                        isArabic
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                isArabic ? 'آخر الأخبار' : 'Latest updates',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (announcements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 50,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isArabic
                              ? 'مفيش أخبار جديدة لسه'
                              : 'No updates yet',
                          style: const TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...announcements.map((a) {
                  final type = (a['type'] ?? 'general').toString();
                  final color = _typeColor(type);
                  final createdAt = (a['created_at'] ?? '').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_typeIcon(type), color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _typeLabel(type),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (createdAt.isNotEmpty)
                                    Text(
                                      _formatDate(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (a['title'] ?? '').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (a['body'] ?? '').toString(),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

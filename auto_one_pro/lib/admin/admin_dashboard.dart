import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';
import '../admin/admin_bookings.dart';
import '../admin/admin_requests.dart';
import '../admin/admin_brands_categories.dart';
import '../admin/admin_users.dart';
import '../admin/admin_activity_log.dart';
import '../admin/admin_homepage.dart';
import '../admin/admin_cars.dart';
import '../admin/admin_financing_partners.dart';
import '../admin/admin_reviews.dart';
import '../admin/admin_services.dart';
import '../admin/admin_announcements.dart';

// ============================================================
// ADMIN DASHBOARD (TABS: BOOKINGS + INVENTORY)
// ============================================================
class _AdminTabDef {
  final String id;
  final String label;
  final IconData icon;
  final double width;
  final Widget Function() pageBuilder;
  final List<String> roles;
  final int badgeCount;

  _AdminTabDef({
    this.id = '',
    required this.label,
    required this.icon,
    required this.width,
    required this.pageBuilder,
    required this.roles,
    this.badgeCount = 0,
  });
}


class AdminDashboard extends StatefulWidget {
  final bool isArabic;

  const AdminDashboard({super.key, required this.isArabic});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}


class _AdminDashboardState extends State<AdminDashboard> {
  final Map<int, Widget> _builtTabPages = {};

  bool isLoadingStats = true;
  int totalBookings = 0;
  int pendingBookings = 0;
  int totalCars = 0;
  String? bestSellingCar;
  int totalRequests = 0;
  int newRequests = 0;
  int pendingReviews = 0;
  String? topRequestedCar;
  String? mostViewedCar;

  bool get isArabic => widget.isArabic;

  Timer? _statsRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // نحدّث العداد كل 60 ثانية تلقائيًا عشان الجرس يفضل محدّث من
    // غير ما تحتاج تعمل Refresh للصفحة بنفسك.
    _statsRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadStats(),
    );
  }

  @override
  void dispose() {
    _statsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      // بنبعت التلات طلبات مع بعض بالتوازي بدل ما ننتظر كل واحد
      // يخلص قبل ما نبدأ اللي بعده — بيقلل وقت الانتظار لتلت المدة تقريبًا.
      final results = await Future.wait([
        Supabase.instance.client
            .from('bookings')
            .select('status, car_name, car_brand'),
        Supabase.instance.client
            .from('cars')
            .select('id, name, brand, view_count'),
        Supabase.instance.client
            .from('customer_requests')
            .select('status, car_name, car_brand'),
        Supabase.instance.client
            .from('customer_reviews')
            .select('status'),
      ]);
      final bookingsResponse = results[0];
      final carsResponse = results[1];
      final requestsResponse = results[2];
      final reviewsResponse = results[3];

      final bookingsList =
          List<Map<String, dynamic>>.from(bookingsResponse as List);
      final requestsList =
          List<Map<String, dynamic>>.from(requestsResponse as List);

      final newReqs =
          requestsList.where((r) => (r['status'] ?? 'new') == 'new');

      final Map<String, int> requestedCarCounts = {};
      for (final r in requestsList) {
        final label =
            '${r['car_brand'] ?? ''} ${r['car_name'] ?? ''}'.trim();
        if (label.isEmpty) continue;
        requestedCarCounts[label] = (requestedCarCounts[label] ?? 0) + 1;
      }
      String? topRequested;
      int topRequestedCount = 0;
      requestedCarCounts.forEach((label, count) {
        if (count > topRequestedCount) {
          topRequestedCount = count;
          topRequested = label;
        }
      });

      final pending =
          bookingsList.where((b) => (b['status'] ?? 'pending') == 'pending');

      // نحسب السيارة الأكتر طلبًا
      final Map<String, int> carCounts = {};
      for (final b in bookingsList) {
        final label =
            '${b['car_brand'] ?? ''} ${b['car_name'] ?? ''}'.trim();
        if (label.isEmpty) continue;
        carCounts[label] = (carCounts[label] ?? 0) + 1;
      }
      String? topCar;
      int topCount = 0;
      carCounts.forEach((label, count) {
        if (count > topCount) {
          topCount = count;
          topCar = label;
        }
      });

      // نحسب السيارة الأكتر مشاهدة
      final carsList = List<Map<String, dynamic>>.from(carsResponse as List);
      String? mostViewed;
      int mostViews = 0;
      for (final c in carsList) {
        final views = (c['view_count'] ?? 0) as int;
        if (views > mostViews) {
          mostViews = views;
          mostViewed = '${c['brand'] ?? ''} ${c['name'] ?? ''}'.trim();
        }
      }

      final reviewsList =
          List<Map<String, dynamic>>.from(reviewsResponse as List);
      final pendingReviewsCount =
          reviewsList.where((r) => (r['status'] ?? 'pending') == 'pending').length;

      if (!mounted) return;
      setState(() {
        totalBookings = bookingsList.length;
        pendingBookings = pending.length;
        totalCars = carsList.length;
        bestSellingCar = topCar;
        totalRequests = requestsList.length;
        newRequests = newReqs.length;
        pendingReviews = pendingReviewsCount;
        topRequestedCar = topRequested;
        mostViewedCar = mostViewed;
        isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل إحصائيات الإدارة: $e');
      if (mounted) setState(() => isLoadingStats = false);
    }
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'لوحة التحكم' : 'Admin Dashboard'),
          actions: [
            _notificationsBell(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Image.asset(
                'assets/logo-autoone.png',
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // STATS ROW
            if (!isLoadingStats)
              Container(
                width: double.infinity,
                color: kHeaderColor,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statCard(
                        icon: Icons.event_note_rounded,
                        label: isArabic ? 'كل الحجوزات' : 'Total Bookings',
                        value: '$totalBookings',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.hourglass_top_rounded,
                        label: isArabic ? 'قيد الانتظار' : 'Pending',
                        value: '$pendingBookings',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.directions_car_filled_rounded,
                        label: isArabic ? 'السيارات بالمخزون' : 'Cars in Stock',
                        value: '$totalCars',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.star_rounded,
                        label: isArabic ? 'الأكتر طلبًا' : 'Best Seller',
                        value: bestSellingCar ??
                            (isArabic ? 'لا يوجد بعد' : 'None yet'),
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.support_agent_rounded,
                        label: isArabic ? 'طلبات العملاء' : 'Customer Requests',
                        value: '$totalRequests',
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.fiber_new_rounded,
                        label: isArabic ? 'طلبات جديدة' : 'New Requests',
                        value: '$newRequests',
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.trending_up_rounded,
                        label: isArabic
                            ? 'الأكتر طلب تمويل'
                            : 'Most Requested',
                        value: topRequestedCar ??
                            (isArabic ? 'لا يوجد بعد' : 'None yet'),
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.visibility_outlined,
                        label: isArabic ? 'الأكتر مشاهدة' : 'Most Viewed',
                        value: mostViewedCar ??
                            (isArabic ? 'لا يوجد بعد' : 'None yet'),
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: Builder(
                builder: (context) {
                  final tabs = _visibleTabs();
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: tabs.length,
                    itemBuilder: (context, i) {
                      final tab = tabs[i];
                      return _sectionCard(
                        label: tab.label,
                        icon: tab.icon,
                        badgeCount: tab.badgeCount,
                        onTap: () => _openSection(i),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String label,
    required IconData icon,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.red, size: 26),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 20),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بيفتح التاب بالـ id بتاعه لو موجود ضمن التابات المسموحة للدور
  // الحالي (يعني مش هيحاول يفتح تاب الأدمن مش شايفه أصلاً).
  void _openTabById(String id) {
    final tabs = _visibleTabs();
    final index = tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _openSection(index);
    }
  }

  // بيفتح قسم معيّن كصفحة منفصلة، فيها زرار "رجوع" (بيرجع خطوة)
  // وزرار "الداشبورد" (بيرجع على طول للصفحة الرئيسية للوحة التحكم).
  void _openSection(int index) {
    final tabs = _visibleTabs();
    if (index < 0 || index >= tabs.length) return;
    if (!_builtTabPages.containsKey(index)) {
      _builtTabPages[index] = tabs[index].pageBuilder();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminSectionScaffold(
          isArabic: isArabic,
          title: tabs[index].label,
          body: _builtTabPages[index]!,
        ),
      ),
    );
  }

  Widget _notificationsBell() {
    final total = pendingBookings + newRequests + pendingReviews;

    return PopupMenuButton<String>(
      tooltip: isArabic ? 'الإشعارات' : 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (total > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  total > 99 ? '99+' : '$total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      onSelected: (id) => _openTabById(id),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (total == 0) {
          items.add(
            PopupMenuItem(
              enabled: false,
              child: Text(
                isArabic ? 'مفيش إشعارات جديدة' : 'No new notifications',
                style: const TextStyle(color: Colors.black45),
              ),
            ),
          );
          return items;
        }

        if (pendingBookings > 0) {
          items.add(
            PopupMenuItem(
              value: 'bookings',
              child: Text(
                isArabic
                    ? '$pendingBookings حجز قيد الانتظار'
                    : '$pendingBookings pending bookings',
              ),
            ),
          );
        }
        if (newRequests > 0) {
          items.add(
            PopupMenuItem(
              value: 'requests',
              child: Text(
                isArabic
                    ? '$newRequests طلب عميل جديد'
                    : '$newRequests new customer requests',
              ),
            ),
          );
        }
        if (pendingReviews > 0) {
          items.add(
            PopupMenuItem(
              value: 'reviews',
              child: Text(
                isArabic
                    ? '$pendingReviews تقييم بانتظار المراجعة'
                    : '$pendingReviews reviews awaiting review',
              ),
            ),
          );
        }
        return items;
      },
    );
  }

  List<_AdminTabDef> _visibleTabs() {
    final role = (currentAdminUser.value?['role'] ?? 'admin') as String;

    final all = <_AdminTabDef>[
      _AdminTabDef(
        id: 'bookings',
        label: isArabic ? 'الحجوزات' : 'Bookings',
        icon: Icons.event_note_rounded,
        width: 130,
        pageBuilder: () => AdminBookingsBody(isArabic: isArabic),
        roles: const ['admin', 'sales'],
        badgeCount: pendingBookings,
      ),
      _AdminTabDef(
        label: isArabic ? 'المخزون' : 'Inventory',
        icon: Icons.directions_car_filled_rounded,
        width: 130,
        pageBuilder: () => AdminCarsPage(isArabic: isArabic),
        roles: const ['admin', 'inventory', 'editor'],
      ),
      _AdminTabDef(
        id: 'requests',
        label: isArabic ? 'طلبات العملاء' : 'Requests',
        icon: Icons.support_agent_rounded,
        width: 140,
        pageBuilder: () => AdminRequestsPage(isArabic: isArabic),
        roles: const ['admin', 'sales'],
        badgeCount: newRequests,
      ),
      _AdminTabDef(
        label: isArabic ? 'الماركات والفئات' : 'Brands & Categories',
        icon: Icons.category_rounded,
        width: 160,
        pageBuilder: () => AdminBrandsCategoriesPage(isArabic: isArabic),
        roles: const ['admin', 'editor'],
      ),
      _AdminTabDef(
        label: isArabic ? 'الصفحة الرئيسية' : 'Homepage',
        icon: Icons.home_outlined,
        width: 150,
        pageBuilder: () => AdminHomepagePage(isArabic: isArabic),
        roles: const ['admin', 'editor'],
      ),
      _AdminTabDef(
        label: isArabic ? 'جهات التمويل' : 'Financing Partners',
        icon: Icons.account_balance_rounded,
        width: 150,
        pageBuilder: () => AdminFinancingPartnersPage(isArabic: isArabic),
        roles: const ['admin', 'editor'],
      ),
      _AdminTabDef(
        id: 'reviews',
        label: isArabic ? 'تقييمات العملاء' : 'Reviews',
        icon: Icons.rate_review_outlined,
        width: 150,
        pageBuilder: () => AdminReviewsPage(isArabic: isArabic),
        roles: const ['admin', 'editor', 'sales'],
        badgeCount: pendingReviews,
      ),
      _AdminTabDef(
        id: 'service_packages',
        label: isArabic ? 'باقات الخدمات' : 'Service Packages',
        icon: Icons.miscellaneous_services_outlined,
        width: 150,
        pageBuilder: () => AdminServicesPage(isArabic: isArabic),
        roles: const ['admin', 'editor'],
      ),
      _AdminTabDef(
        id: 'announcements',
        label: isArabic ? 'الإعلانات' : 'Announcements',
        icon: Icons.campaign_outlined,
        width: 140,
        pageBuilder: () => AdminAnnouncementsPage(isArabic: isArabic),
        roles: const ['admin', 'editor'],
      ),
      _AdminTabDef(
        label: isArabic ? 'المستخدمين' : 'Users',
        icon: Icons.admin_panel_settings_outlined,
        width: 140,
        pageBuilder: () => AdminUsersPage(isArabic: isArabic),
        roles: const ['admin'],
      ),
      _AdminTabDef(
        label: isArabic ? 'سجل التعديلات' : 'Activity Log',
        icon: Icons.history_rounded,
        width: 150,
        pageBuilder: () => AdminActivityLogPage(isArabic: isArabic),
        roles: const ['admin'],
      ),
    ];

    return all.where((t) => t.roles.contains(role)).toList();
  }
}


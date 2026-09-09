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

// ============================================================
// ADMIN DASHBOARD (TABS: BOOKINGS + INVENTORY)
// ============================================================
class _AdminTabDef {
  final String label;
  final IconData icon;
  final double width;
  final Widget Function() pageBuilder;
  final List<String> roles;
  final int badgeCount;

  _AdminTabDef({
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
  int currentTab = 0;
  final Map<int, Widget> _builtTabPages = {};

  bool isLoadingStats = true;
  int totalBookings = 0;
  int pendingBookings = 0;
  int totalCars = 0;
  String? bestSellingCar;
  int totalRequests = 0;
  int newRequests = 0;
  String? topRequestedCar;
  String? mostViewedCar;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
      ]);
      final bookingsResponse = results[0];
      final carsResponse = results[1];
      final requestsResponse = results[2];

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

      if (!mounted) return;
      setState(() {
        totalBookings = bookingsList.length;
        pendingBookings = pending.length;
        totalCars = carsList.length;
        bestSellingCar = topCar;
        totalRequests = requestsList.length;
        newRequests = newReqs.length;
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
      width: 150,
      padding: const EdgeInsets.all(14),
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
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

            Container(
              color: kHeaderColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _visibleTabs().length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      SizedBox(
                        width: _visibleTabs()[i].width,
                        child: _adminTabButton(
                          label: _visibleTabs()[i].label,
                          icon: _visibleTabs()[i].icon,
                          selected: currentTab == i,
                          onTap: () => setState(() => currentTab = i),
                          badgeCount: _visibleTabs()[i].badgeCount,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final tabs = _visibleTabs();
                  // بنبني صفحة التاب بس أول مرة يتفتح، وبعدين بتفضل
                  // محفوظة في الكاش عشان التنقل بين التابات يبقى فوري
                  // من غير ما نعيد تحميل البيانات من Supabase تاني.
                  if (currentTab < tabs.length &&
                      !_builtTabPages.containsKey(currentTab)) {
                    _builtTabPages[currentTab] =
                        tabs[currentTab].pageBuilder();
                  }
                  return IndexedStack(
                    index: currentTab,
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        _builtTabPages[i] ?? const SizedBox.shrink(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AdminTabDef> _visibleTabs() {
    final role = (currentAdminUser.value?['role'] ?? 'admin') as String;

    final all = <_AdminTabDef>[
      _AdminTabDef(
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

  Widget _adminTabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return HoverLift(
      scale: 1.02,
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: selected ? Colors.red : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.black87,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: selected ? Colors.red : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


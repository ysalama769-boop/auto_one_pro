import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/favorites_compare.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../screens/static_pages.dart';
import '../screens/branches_page.dart';
import '../screens/services_page.dart';
import '../screens/car_details_page.dart';
import '../screens/favorites_page.dart';
import '../screens/comparison_page.dart';
import '../screens/cars_page.dart';
import '../screens/request_car_page.dart';
import '../screens/brands_page.dart';
import '../screens/auth_page.dart';
import '../screens/my_requests_page.dart';
import '../screens/notifications_page.dart';
import '../screens/settings_page.dart';
import 'auth.dart';

// ============================================================
// CONNECTIVITY BANNER (WEB ONLY)
// ============================================================
// بتظهر شريط أحمر لو النت مقطوع، وتختفي تلقائيًا لما يرجع
class ConnectivityBanner extends StatefulWidget {
  final bool isArabic;

  const ConnectivityBanner({super.key, required this.isArabic});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}


class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    isOffline = !(html.window.navigator.onLine ?? true);
    html.window.addEventListener('online', _handleOnline);
    html.window.addEventListener('offline', _handleOffline);
  }

  void _handleOnline(html.Event event) {
    if (mounted) setState(() => isOffline = false);
  }

  void _handleOffline(html.Event event) {
    if (mounted) setState(() => isOffline = true);
  }

  @override
  void dispose() {
    html.window.removeEventListener('online', _handleOnline);
    html.window.removeEventListener('offline', _handleOffline);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            widget.isArabic
                ? 'لا يوجد اتصال بالإنترنت'
                : 'No internet connection',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// HEADER
// ============================================================

class AutoOneHeader extends StatelessWidget {
  final bool isArabic;
  final bool showCars;
  final bool transparent;

  final VoidCallback onHome;
  final void Function([String? brand]) onCars;
  final VoidCallback onLanguage;
  final VoidCallback onAdminAccess;

  const AutoOneHeader({
    super.key,
    required this.isArabic,
    required this.showCars,
    this.transparent = false,
    required this.onHome,
    required this.onCars,
    required this.onLanguage,
    required this.onAdminAccess,
  });

  // ----------------------------------------------------------
  // WHATSAPP
  // ----------------------------------------------------------

  Future<void> openWhatsApp() async {
    const phone = '966541577894';

    final Uri url = Uri.parse(
      'https://wa.me/$phone',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
   Widget build(BuildContext context) { 
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      decoration: transparent
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            )
          : const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
          ),

          child: Row(
            children: [
// =================================================
// LOGO
// =================================================

InkWell(
  onTap: onHome,
  onLongPress: onAdminAccess,
  child: Image.asset(
    'assets/logo-autoone.png',
    width: isMobile ? 120 : 155,
    height: isMobile ? 45 : 55,
    fit: BoxFit.contain,
  ),
),

              if (!isMobile) ...[
                const SizedBox(width: 16),
  HeaderButton(
    title: isArabic ? 'الرئيسية' : 'HOME',
    active: !showCars,
    lightText: transparent,
    onTap: onHome,
  ),

  const SizedBox(width: 10),

  PopupMenuButton<String>(
    color: Colors.white,
    constraints: const BoxConstraints(minWidth: 300, maxWidth: 320),
    onSelected: (value) {
      switch (value) {
        case 'all_cars':
          onCars();
          break;
        case 'request_car':
          Navigator.of(context).push(
            smoothRoute(RequestCarPage(isArabic: isArabic)),
          );
          break;
        case 'compare':
          Navigator.of(context).push(
            smoothRoute(ComparisonPage(isArabic: isArabic)),
          );
          break;
        case 'brands':
          Navigator.of(context).push(
            smoothRoute(
              BrandsPage(
                isArabic: isArabic,
                onBrandTap: (brand) => onCars(brand),
              ),
            ),
          );
          break;
      }
    },
    itemBuilder: (context) => [
      _megaMenuItem(
        value: 'all_cars',
        icon: Icons.directions_car_filled_rounded,
        title: isArabic ? 'كل السيارات' : 'All Cars',
        subtitle: isArabic
            ? 'تصفح مجموعتنا من ماركات السيارات'
            : 'Browse our range of car brands',
      ),
      _megaMenuItem(
        value: 'request_car',
        icon: Icons.assignment_outlined,
        title: isArabic ? 'طلب سيارة' : 'Request a Car',
        subtitle: isArabic
            ? 'قدّم طلبك للحصول على سيارة وسنساعدك في الحصول على سيارتك المثالية'
            : "Submit your request and we'll help you find your ideal car",
      ),
      _megaMenuItem(
        value: 'compare',
        icon: Icons.compare_arrows_rounded,
        title: isArabic ? 'المقارنة' : 'Compare',
        subtitle: isArabic
            ? 'قارن بين موديلات السيارات المختلفة من حيث الأسعار والمواصفات والمميزات'
            : 'Compare different car models by price, specs and features',
      ),
      _megaMenuItem(
        value: 'brands',
        icon: Icons.verified_rounded,
        title: isArabic ? 'الماركات' : 'Brands',
        subtitle: isArabic
            ? 'استعرض الماركات المتوفرة وشاهد جميع الموديلات لكل ماركة'
            : 'Browse available brands and see all models for each',
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isArabic ? 'سياراتنا' : 'OUR CARS',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black87,
            size: 18,
          ),
        ],
      ),
    ),
  ),

  const SizedBox(width: 10),

  PopupMenuButton<String>(
    color: Colors.white,
    constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
    onSelected: (value) {
      switch (value) {
        case 'about':
          Navigator.of(context).push(
            smoothRoute(AboutAutoOnePage(isArabic: isArabic)),
          );
          break;
        case 'services':
          Navigator.of(context).push(
            smoothRoute(ServicesPage(isArabic: isArabic)),
          );
          break;
        case 'terms':
          Navigator.of(context).push(
            smoothRoute(TermsPage(isArabic: isArabic)),
          );
          break;
        case 'privacy':
          Navigator.of(context).push(
            smoothRoute(PrivacyPolicyPage(isArabic: isArabic)),
          );
          break;
      }
    },
    itemBuilder: (context) => [
      _megaMenuItem(
        value: 'about',
        icon: Icons.info_outline_rounded,
        title: isArabic ? 'من نحن' : 'Who We Are',
        subtitle: isArabic
            ? 'تعرّف على المجموعة وقيمنا'
            : 'Get to know our group and values',
      ),
      _megaMenuItem(
        value: 'services',
        icon: Icons.miscellaneous_services_outlined,
        title: isArabic ? 'خدماتنا' : 'Our Services',
        subtitle: isArabic
            ? 'استكشف مجموعة خدماتنا'
            : 'Explore our range of services',
      ),
      _megaMenuItem(
        value: 'terms',
        icon: Icons.description_outlined,
        title: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
      ),
      _megaMenuItem(
        value: 'privacy',
        icon: Icons.privacy_tip_outlined,
        title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isArabic ? 'عن أوتو ون' : 'ABOUT AUTO ONE',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black87,
            size: 18,
          ),
        ],
      ),
    ),
  ),
              ],

              const Spacer(),

              // =================================================
              // HOME
              // =================================================

              if (!isMobile) ...[
  HoverLift(
    scale: 1.1,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(context).push(
          smoothRoute(FavoritesPage(isArabic: isArabic)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.favorite_rounded,
          color: Colors.red,
          size: 20,
        ),
      ),
    ),
  ),

  const SizedBox(width: 12),

  ValueListenableBuilder<User?>(
    valueListenable: currentUser,
    builder: (context, user, _) {
      if (user == null) return const SizedBox.shrink();

      return ValueListenableBuilder<int>(
        valueListenable: customerNotificationsCount,
        builder: (context, count, _) {
          return HoverLift(
            scale: 1.1,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.of(context).push(
                  smoothRoute(NotificationsPage(isArabic: isArabic)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ),

  const SizedBox(width: 8),

  ValueListenableBuilder<User?>(
    valueListenable: currentUser,
    builder: (context, user, _) {
      if (user == null) {
        return HoverLift(
          scale: 1.1,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.of(context).push(
                smoothRoute(AuthPage(isArabic: isArabic)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),
        );
      }

      return PopupMenuButton<String>(
        icon: Icon(
          Icons.account_circle_rounded,
          color: Colors.black87,
          size: 24,
        ),
        onSelected: (value) {
          switch (value) {
            case 'settings':
              Navigator.of(context).push(
                smoothRoute(
                  SettingsPage(
                    isArabic: isArabic,
                    onLanguageChanged: onLanguage,
                  ),
                ),
              );
              break;
            case 'requests':
              Navigator.of(context).push(
                smoothRoute(MyRequestsPage(isArabic: isArabic)),
              );
              break;
            case 'logout':
              signOutUser();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Text(
              currentUserName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'requests',
            child: Text(isArabic ? 'طلباتي' : 'My Requests'),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Text(isArabic ? 'الإعدادات' : 'Settings'),
          ),
          PopupMenuItem(
            value: 'logout',
            child: Text(isArabic ? 'تسجيل الخروج' : 'Log out'),
          ),
        ],
      );
    },
  ),

  const SizedBox(width: 15),

  // زرار تبديل اللغة في الهيدر بيظهر بس للزوار اللي لسه ما
  // سجلوش دخول، لأن اللي عنده حساب بيقدر يغيّر اللغة من صفحة
  // الإعدادات بدل ما يتكرر الزرار في الهيدر.
  ValueListenableBuilder<User?>(
    valueListenable: currentUser,
    builder: (context, user, _) {
      if (user != null) return const SizedBox.shrink();
      return InkWell(
        onTap: onLanguage,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white54,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isArabic ? 'EN' : 'AR',
            style: TextStyle(
              color: transparent
                  ? Colors.white
                  : const Color.fromARGB(255, 12, 12, 12),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    },
  ),

  const SizedBox(width: 12),

  InkWell(
    onTap: openWhatsApp,
    borderRadius: BorderRadius.circular(50),
    child: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xff25D366),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 21,
        ),
      ),
    ),
  ),
],

if (isMobile)
  ValueListenableBuilder<int>(
    valueListenable: customerNotificationsCount,
    builder: (context, notifCount, _) {
      return PopupMenuButton<String>(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.menu,
              color: Colors.black87,
              size: 30,
            ),
            if (notifCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    notifCount > 9 ? '9+' : '$notifCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
    onSelected: (value) {
      switch (value) {
        case 'home':
          onHome();
          break;
        case 'cars':
          onCars();
          break;
        case 'language':
          onLanguage();
          break;
        case 'whatsapp':
          openWhatsApp();
          break;
        case 'favorites':
          Navigator.of(context).push(
            smoothRoute(FavoritesPage(isArabic: isArabic)),
          );
          break;
        case 'compare':
          Navigator.of(context).push(
            smoothRoute(ComparisonPage(isArabic: isArabic)),
          );
          break;
        case 'login':
          Navigator.of(context).push(
            smoothRoute(AuthPage(isArabic: isArabic)),
          );
          break;
        case 'requests':
          Navigator.of(context).push(
            smoothRoute(MyRequestsPage(isArabic: isArabic)),
          );
          break;
        case 'settings':
          Navigator.of(context).push(
            smoothRoute(
              SettingsPage(
                isArabic: isArabic,
                onLanguageChanged: onLanguage,
              ),
            ),
          );
          break;
        case 'notifications':
          Navigator.of(context).push(
            smoothRoute(NotificationsPage(isArabic: isArabic)),
          );
          break;
        case 'services':
          Navigator.of(context).push(
            smoothRoute(ServicesPage(isArabic: isArabic)),
          );
          break;
        case 'request_car':
          Navigator.of(context).push(
            smoothRoute(RequestCarPage(isArabic: isArabic)),
          );
          break;
        case 'about':
          Navigator.of(context).push(
            smoothRoute(AboutAutoOnePage(isArabic: isArabic)),
          );
          break;
        case 'branches':
          Navigator.of(context).push(
            smoothRoute(BranchesPage(isArabic: isArabic)),
          );
          break;
        case 'brands':
          Navigator.of(context).push(
            smoothRoute(
              BrandsPage(
                isArabic: isArabic,
                onBrandTap: (brand) => onCars(brand),
              ),
            ),
          );
          break;
        case 'terms':
          Navigator.of(context).push(
            smoothRoute(TermsPage(isArabic: isArabic)),
          );
          break;
        case 'privacy':
          Navigator.of(context).push(
            smoothRoute(PrivacyPolicyPage(isArabic: isArabic)),
          );
          break;
        case 'logout':
          signOutUser();
          break;
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'home',
        child: Text(
          isArabic ? 'الرئيسية' : 'HOME',
        ),
      ),
      PopupMenuItem(
        value: 'cars',
        child: Text(
          isArabic ? 'سياراتنا' : 'OUR CARS',
        ),
      ),
      PopupMenuItem(
        value: 'brands',
        child: Text(
          isArabic ? 'الماركات' : 'Brands',
        ),
      ),
      PopupMenuItem(
        value: 'services',
        child: Text(
          isArabic ? 'الخدمات' : 'Services',
        ),
      ),
      PopupMenuItem(
        value: 'request_car',
        child: Text(
          isArabic ? 'طلب سيارة' : 'Request a Car',
        ),
      ),
      PopupMenuItem(
        value: 'about',
        child: Text(
          isArabic ? 'من نحن' : 'Who We Are',
        ),
      ),
      PopupMenuItem(
        value: 'branches',
        child: Text(
          isArabic ? 'الفروع' : 'Branches',
        ),
      ),
      PopupMenuItem(
        value: 'terms',
        child: Text(
          isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
        ),
      ),
      PopupMenuItem(
        value: 'privacy',
        child: Text(
          isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
        ),
      ),
      PopupMenuItem(
        value: 'favorites',
        child: Text(
          isArabic ? 'المفضلة' : 'Favorites',
        ),
      ),
      PopupMenuItem(
        value: 'compare',
        child: Text(
          isArabic ? 'مقارنة السيارات' : 'Compare Cars',
        ),
      ),
      if (currentUser.value == null)
        PopupMenuItem(
          value: 'login',
          child: Text(
            isArabic ? 'تسجيل الدخول' : 'Sign in',
          ),
        )
      else ...[
        PopupMenuItem(
          value: 'notifications',
          child: Text(
            isArabic
                ? notifCount > 0
                    ? 'الإشعارات ($notifCount)'
                    : 'الإشعارات'
                : notifCount > 0
                    ? 'Notifications ($notifCount)'
                    : 'Notifications',
          ),
        ),
        PopupMenuItem(
          value: 'requests',
          child: Text(
            isArabic ? 'طلباتي' : 'My Requests',
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Text(
            isArabic ? 'الإعدادات' : 'Settings',
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Text(
            isArabic ? 'تسجيل الخروج' : 'Log out',
          ),
        ),
      ],
      if (currentUser.value == null)
        PopupMenuItem(
          value: 'language',
          child: Text(
            isArabic ? 'English' : 'العربية',
          ),
        ),
      PopupMenuItem(
        value: 'whatsapp',
        child: Text(
          isArabic ? 'واتساب' : 'WHATSAPP',
        ),
      ),
    ],
  );
    },
  ),

             
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// HEADER BUTTON
// ============================================================

// ============================================================
// MEGA MENU ITEM (عنصر قائمة منسدلة باسم + شعار تحته)
// ============================================================
PopupMenuItem<String> _megaMenuItem({
  required String value,
  required IconData icon,
  required String title,
  String? subtitle,
}) {
  return PopupMenuItem<String>(
    value: value,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class HeaderButton extends StatelessWidget {
  final String title;
  final bool active;
  final bool lightText;
  final VoidCallback onTap;

  const HeaderButton({
    super.key,
    required this.title,
    required this.active,
    this.lightText = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      scale: 1.05,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(8),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 11,
        ),

        decoration: BoxDecoration(
          color: active
              ? Colors.red
              : Colors.transparent,

          borderRadius:
              BorderRadius.circular(8),
        ),

        child: Text(
          title,

          style: TextStyle(
            color: (lightText && !active)
                ? Colors.white
                : const Color.fromARGB(255, 0, 0, 0),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ),
    );
  }
}

  
  
// ============================================================
// CAR CARD
// ============================================================
 
// ============================================================
// SMOOTH PAGE ROUTE (fade + slight slide-up)
// ============================================================
Route<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}


// ============================================================
// HOVER LIFT (subtle scale + shadow on mouse hover — desktop web)
// ============================================================
// ============================================================
// FAVORITE BUTTON (heart icon, toggles local favorite storage)
// ============================================================
class FavoriteButton extends StatefulWidget {
  final int? carId;
  final double size;

  const FavoriteButton({super.key, required this.carId, this.size = 15});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}


class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  Widget build(BuildContext context) {
    if (widget.carId == null) return const SizedBox.shrink();

    final isFav = favoriteCarIds.contains(widget.carId);

    return HoverLift(
      scale: 1.15,
      borderRadius: BorderRadius.circular(30),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() {
              toggleFavorite(widget.carId!);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.red : Colors.black45,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// CREATIVE BOOK BUTTON (gradient + pulsing glow + sliding arrow)
// ============================================================
class CreativeBookButton extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const CreativeBookButton({
    super.key,
    required this.isArabic,
    required this.onTap,
  });

  @override
  State<CreativeBookButton> createState() => _CreativeBookButtonState();
}


class _CreativeBookButtonState extends State<CreativeBookButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glow = 0.25 + (_controller.value * 0.25);
            return AnimatedScale(
              scale: _hovering ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE53935),
                      Color(0xFFB71C1C),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: glow),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isArabic ? 'احجز الآن' : 'BOOK NOW',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                        left: _hovering ? 10 : 6,
                      ),
                      child: Icon(
                        widget.isArabic
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
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


// ============================================================
// COMPARE BUTTON (checkbox icon, adds car to comparison list)
// ============================================================
class CompareButton extends StatelessWidget {
  final int? carId;

  const CompareButton({super.key, required this.carId});

  @override
  Widget build(BuildContext context) {
    if (carId == null) return const SizedBox.shrink();

    return ValueListenableBuilder<List<int>>(
      valueListenable: compareCarIds,
      builder: (context, list, _) {
        final isSelected = list.contains(carId);

        // شارة دهبية صغيرة بدل الدايرة العادية، عشان تبان مميزة
        // زي وسام على الكارت.
        return HoverLift(
          scale: 1.08,
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => toggleCompare(carId!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [
                            const Color(0xFFFFD700),
                            const Color(0xFFB8860B),
                          ]
                        : [
                            const Color(0xFFFFE9A8),
                            const Color(0xFFD4A017),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'قارن',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class HoverLift extends StatefulWidget {
  final Widget child;
  final double scale;
  final BorderRadius borderRadius;

  const HoverLift({
    super.key,
    required this.child,
    this.scale = 1.03,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}


class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}


// ============================================================
// MINI CONTACT STRIP (compact, softer — for non-home pages)
// ============================================================
// نسخة أصغر وأنعم من كارت التواصل بتاع الرئيسية، من غير ما نلمس
// كارت الرئيسية خالص. بتتحط في آخر باقي الصفحات.
class MiniContactStrip extends StatelessWidget {
  final bool isArabic;

  const MiniContactStrip({super.key, required this.isArabic});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _miniIcon({
    required Widget icon,
    required Color color,
    required String url,
  }) {
    return HoverLift(
      scale: 1.12,
      borderRadius: BorderRadius.circular(30),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openLink(url),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: icon,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            isArabic ? 'تواصلي معنا' : 'Get in touch',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniIcon(
                icon: const FaIcon(FontAwesomeIcons.whatsapp,
                    color: Colors.white, size: 16),
                color: const Color(0xFF25D366),
                url: 'https://wa.me/966541577894',
              ),
              _miniIcon(
                icon: const FaIcon(FontAwesomeIcons.instagram,
                    color: Colors.white, size: 16),
                color: const Color(0xFFE1306C),
                url: 'https://www.instagram.com/autoone_sa',
              ),
              _miniIcon(
                icon: const FaIcon(FontAwesomeIcons.tiktok,
                    color: Colors.white, size: 16),
                color: Colors.black,
                url: 'https://www.tiktok.com/@autoone_sa',
              ),
              _miniIcon(
                icon: const FaIcon(FontAwesomeIcons.facebookF,
                    color: Colors.white, size: 16),
                color: const Color(0xFF1877F2),
                url: 'https://www.facebook.com/share/1EiuLeeFP7/',
              ),
              _miniIcon(
                icon: const FaIcon(FontAwesomeIcons.xTwitter,
                    color: Colors.white, size: 16),
                color: Colors.black,
                url: 'https://x.com/autoone_sa',
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ============================================================
// FULL FOOTER (unified across all pages)
// ============================================================
// ============================================================
// REVIEW SUBMISSION SHEET (تقييم العملاء)
// ============================================================
void showReviewSubmissionSheet(
  BuildContext context,
  bool isArabic, {
  int? carId,
}) {
  final nameCtrl = TextEditingController();
  final reviewCtrl = TextEditingController();
  bool isSending = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'شاركنا رأيك' : 'Share your feedback',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'تقييمك هيظهر بعد مراجعته من فريقنا'
                      : 'Your review will appear after our team reviews it',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسمك' : 'Your name',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'رأيك' : 'Your review',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                reviewCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isArabic
                                        ? 'من فضلك اكتب اسمك ورأيك'
                                        : 'Please enter your name and review',
                                  ),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSending = true);
                            try {
                              await submitCustomerReview(
                                customerName: nameCtrl.text.trim(),
                                reviewText: reviewCtrl.text.trim(),
                                carId: carId,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? 'شكرًا لك! تقييمك هيظهر بعد المراجعة'
                                          : 'Thank you! Your review will appear after review',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isSending = false);
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? 'حصلت مشكلة، حاول تاني'
                                          : 'Something went wrong',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isArabic ? 'إرسال التقييم' : 'Submit review'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class AutoOneFooter extends StatelessWidget {
  final bool isArabic;

  const AutoOneFooter({super.key, required this.isArabic});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _socialIcon({
    required Widget icon,
    required Color color,
    required String url,
  }) {
    return HoverLift(
      scale: 1.12,
      borderRadius: BorderRadius.circular(30),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openLink(url),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: icon,
          ),
        ),
      ),
    );
  }

  Widget _columnTitle(String text) {
    return Column(
      crossAxisAlignment:
          isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 26, height: 2.5, color: Colors.white),
      ],
    );
  }

  Widget _quickLink(BuildContext context, String label) {
    return HoverLift(
      scale: 1.03,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Icon(
                isArabic
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyLink(BuildContext context, String label, Widget page) {
    return HoverLift(
      scale: 1.03,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          Navigator.of(context).push(smoothRoute(page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _branchLine(String text) {
    return HoverLift(
      scale: 1.02,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openLink(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('AUTO ONE $text')}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 17, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneLine(String displayNumber, String telUrl) {
    return HoverLift(
      scale: 1.02,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openLink(telUrl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              const Icon(Icons.phone_rounded,
                  size: 17, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                displayNumber,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailLine(String email) {
    return HoverLift(
      scale: 1.02,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openLink('mailto:$email'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              const Icon(Icons.email_rounded,
                  size: 17, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crossAxis =
        isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isArabic ? TextAlign.right : TextAlign.left;

    // ============================================================
    // COLUMN 1 — LOCATIONS (لوحدها)
    // ============================================================
    Widget locationColumn() {
      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          _columnTitle(isArabic ? 'مواقعنا' : 'Our Locations'),
          const SizedBox(height: 14),
          _branchLine(
            isArabic ? 'جدة — حي الجوهرة' : 'Jeddah — Al Jawharah',
          ),
          _branchLine(
            isArabic ? 'جدة — حي الحمدانية' : 'Jeddah — Al Hamdaniyah',
          ),
          _branchLine(
            isArabic ? 'الرياض — حي القادسية' : 'Riyadh — Al Qadisiyah',
          ),
        ],
      );
    }

    // ============================================================
    // COLUMN 2 — CONTACT (الهاتف + الإيميل + النشرة البريدية)
    // ============================================================
    Widget contactColumn() {
      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          _columnTitle(isArabic ? 'تواصل معنا' : 'Contact Us'),
          const SizedBox(height: 14),
          _phoneLine('+966 54 157 7894', 'tel:+966541577894'),
          _emailLine('info@autoone.com'),
          const SizedBox(height: 14),
          _NewsletterSubscribeBlock(isArabic: isArabic, compact: true),
        ],
      );
    }

    // ============================================================
    // COLUMN 2B — SERVICES (خدماتنا)
    // ============================================================
    Widget servicesColumn(BuildContext context) {
      Widget item(String label, VoidCallback onTap) {
        return HoverLift(
          scale: 1.03,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection:
                    isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Icon(
                    isArabic
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          _columnTitle(isArabic ? 'خدماتنا' : 'Our Services'),
          const SizedBox(height: 14),
          item(
            isArabic ? 'شراء سيارة' : 'Buy a car',
            () => Navigator.of(context).push(
              smoothRoute(CarsPage(isArabic: isArabic)),
            ),
          ),
          item(
            isArabic ? 'التمويل' : 'Financing',
            () => Navigator.of(context).push(
              smoothRoute(CarsPage(isArabic: isArabic)),
            ),
          ),
          item(
            isArabic ? 'المفضلة' : 'Favorites',
            () => Navigator.of(context).push(
              smoothRoute(FavoritesPage(isArabic: isArabic)),
            ),
          ),
          item(
            isArabic ? 'مقارنة السيارات' : 'Compare cars',
            () => Navigator.of(context).push(
              smoothRoute(ComparisonPage(isArabic: isArabic)),
            ),
          ),
        ],
      );
    }

    // ============================================================
    // COLUMN 3 — QUICK LINKS
    // ============================================================
    Widget linksColumn(BuildContext context) {
      Widget item(String label, VoidCallback onTap) {
        return HoverLift(
          scale: 1.03,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection:
                    isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Icon(
                    isArabic
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          _columnTitle(isArabic ? 'روابط سريعة' : 'Quick Links'),
          const SizedBox(height: 14),
          _quickLink(context, isArabic ? 'الرئيسية' : 'Home'),
          _quickLink(context, isArabic ? 'تصفح السيارات' : 'Browse Cars'),
          item(
            isArabic ? 'قيّم تجربتك معانا' : 'Rate your experience',
            () => showReviewSubmissionSheet(context, isArabic),
          ),
          item(
            isArabic ? 'فروعنا' : 'Our Branches',
            () => Navigator.of(context).push(
              smoothRoute(BranchesPage(isArabic: isArabic)),
            ),
          ),
          item(
            isArabic ? 'الخدمات' : 'Services',
            () => Navigator.of(context).push(
              smoothRoute(ServicesPage(isArabic: isArabic)),
            ),
          ),
        ],
      );
    }

    // ============================================================
    // COLUMN 4 — LOGO & TAGLINE
    // ============================================================
    Widget logoColumn() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo-autoone.png',
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 230,
            child: Text(
              isArabic
                  ? 'معرض سيارات موثوق، نوفّر لك أفضل السيارات بأسعار تنافسية وتجربة شراء سهلة.'
                  : 'A trusted car showroom offering the best cars at competitive prices.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _socialIcon(
                icon: const FaIcon(FontAwesomeIcons.whatsapp,
                    color: Colors.white, size: 15),
                color: const Color(0xFF25D366),
                url: 'https://wa.me/966541577894',
              ),
              _socialIcon(
                icon: const FaIcon(FontAwesomeIcons.instagram,
                    color: Colors.white, size: 15),
                color: const Color(0xFFE1306C),
                url: 'https://www.instagram.com/autoone_sa',
              ),
              _socialIcon(
                icon: const FaIcon(FontAwesomeIcons.tiktok,
                    color: Colors.white, size: 15),
                color: Colors.grey.shade800,
                url: 'https://www.tiktok.com/@autoone_sa',
              ),
              _socialIcon(
                icon: const FaIcon(FontAwesomeIcons.facebookF,
                    color: Colors.white, size: 15),
                color: const Color(0xFF1877F2),
                url: 'https://www.facebook.com/share/1EiuLeeFP7/',
              ),
              _socialIcon(
                icon: const FaIcon(FontAwesomeIcons.xTwitter,
                    color: Colors.white, size: 15),
                color: Colors.grey.shade800,
                url: 'https://x.com/autoone_sa',
              ),
            ],
          ),
        ],
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: kBrandGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.only(top: 36, left: 20, right: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      // شاشة واسعة: 5 أعمدة جنب بعض (النشرة البريدية
                      // بقت جوّه عمود "تواصل معنا" نفسه)
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: logoColumn()),
                          Expanded(child: linksColumn(context)),
                          Expanded(child: servicesColumn(context)),
                          Expanded(child: contactColumn()),
                          Expanded(child: locationColumn()),
                        ],
                      );
                    }
                    // شاشة ضيقة: عمودين جنب بعض بدل عمود واحد
                    final halfWidth = (constraints.maxWidth - 20) / 2;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 30,
                      children: [
                        SizedBox(width: halfWidth, child: logoColumn()),
                        SizedBox(width: halfWidth, child: linksColumn(context)),
                        SizedBox(
                          width: halfWidth,
                          child: servicesColumn(context),
                        ),
                        SizedBox(width: halfWidth, child: contactColumn()),
                        SizedBox(width: halfWidth, child: locationColumn()),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                Container(
                  height: 1,
                  color: Colors.white12,
                ),

                const SizedBox(height: 16),

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _policyLink(
                      context,
                      isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                      PrivacyPolicyPage(isArabic: isArabic),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                    _policyLink(
                      context,
                      isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                      TermsPage(isArabic: isArabic),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                    Text(
                      isArabic
                          ? '© ${DateTime.now().year} AUTO ONE — جميع الحقوق محفوظة'
                          : '© ${DateTime.now().year} AUTO ONE — All rights reserved',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NEWSLETTER SUBSCRIBE BLOCK (اشترك في نشرتنا البريدية)
// ============================================================
// بتاخد إيميل الزائر وتسجّله في جدول newsletter_subscribers في
// Supabase، مع تحقق بسيط من صحة شكل الإيميل ومنع التكرار.
// ============================================================
class _NewsletterSubscribeBlock extends StatefulWidget {
  final bool isArabic;
  final bool compact;
  const _NewsletterSubscribeBlock({
    required this.isArabic,
    this.compact = false,
  });

  @override
  State<_NewsletterSubscribeBlock> createState() =>
      _NewsletterSubscribeBlockState();
}

class _NewsletterSubscribeBlockState
    extends State<_NewsletterSubscribeBlock> {
  final TextEditingController emailCtrl = TextEditingController();
  bool isSubmitting = false;
  String? statusMessage;
  bool isError = false;

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = emailCtrl.text.trim();
    final isValidEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!isValidEmail) {
      setState(() {
        isError = true;
        statusMessage =
            isArabic ? 'اكتب بريد إلكتروني صحيح' : 'Enter a valid email';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      statusMessage = null;
    });

    try {
      await Supabase.instance.client.from('newsletter_subscribers').insert({
        'email': email,
      });
      setState(() {
        isSubmitting = false;
        isError = false;
        statusMessage =
            isArabic ? 'تم الاشتراك بنجاح، شكرًا لك!' : 'Subscribed, thank you!';
        emailCtrl.clear();
      });
    } on PostgrestException catch (e) {
      setState(() {
        isSubmitting = false;
        isError = true;
        // كود 23505 معناه الإيميل ده مسجّل قبل كده (unique constraint)
        statusMessage = e.code == '23505'
            ? (isArabic
                ? 'الإيميل ده مشترك بالفعل'
                : 'This email is already subscribed')
            : (isArabic ? 'حصل خطأ، جرّب تاني' : 'Something went wrong');
      });
    } catch (_) {
      setState(() {
        isSubmitting = false;
        isError = true;
        statusMessage = isArabic ? 'حصل خطأ، جرّب تاني' : 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'اشترك في نشرتنا البريدية' : 'Subscribe to our newsletter',
          style: TextStyle(
            color: widget.compact ? Colors.white70 : Colors.white,
            fontSize: widget.compact ? 13 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                SizedBox(
                  width: constraints.maxWidth >= 420
                      ? (widget.compact ? 100 : 160)
                      : double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _subscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kFooterColor,
                      padding: EdgeInsets.symmetric(
                        vertical: widget.compact ? 9 : 14,
                      ),
                      textStyle: TextStyle(
                        fontSize: widget.compact ? 12 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kFooterColor,
                            ),
                          )
                        : Text(isArabic ? 'اشتراك' : 'Subscribe'),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth >= 420
                      ? constraints.maxWidth - (widget.compact ? 112 : 172)
                      : double.infinity,
                  child: TextField(
                    controller: emailCtrl,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.compact ? 12.5 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          isArabic ? 'بريدك الإلكتروني' : 'Your email',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: widget.compact ? 9 : 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ];

              if (constraints.maxWidth >= 420) {
                return Row(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    fields[1],
                    const SizedBox(width: 10),
                    fields[0],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fields[1],
                  const SizedBox(height: 10),
                  fields[0],
                ],
              );
            },
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              statusMessage!,
              style: TextStyle(
                color: isError ? Colors.yellow.shade100 : Colors.greenAccent.shade100,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
    );

    if (widget.compact) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }
}

// ============================================================
// ADAPTIVE CAR IMAGE (LOCAL ASSET OR NETWORK LINK)
// ============================================================
// بتعرض الصورة صح سواء كانت رابط إنترنت (Supabase) أو صورة محلية جوه assets
// وبتحط لوجو "اوتو ون" فوقها تلقائيًا في الركن، مع صورة احتياطية لو الرابط بايظ
// ============================================================
// SHIMMER LOADING (skeleton placeholder)
// ============================================================
// مربع بينبض بهدوء لحد ما المحتوى يتحمّل، بدل دايرة تحميل عادية
// ============================================================
// PULSING DOTS (branded loading indicator)
// ============================================================
class PulsingDots extends StatefulWidget {
  final Color color;

  const PulsingDots({super.key, this.color = Colors.red});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}


class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final scale = t < 0.5 ? (0.6 + t) : (1.6 - t);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(0.6, 1.1),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}


class ShimmerBox extends StatefulWidget {
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}


class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + (_controller.value * 0.30);
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: opacity),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}


// شريط سحب أفقي بشكل مميز (رفيع، حواف مدوّرة، بلون العلامة الأحمر)
// بيتلف حوالين أي عنصر بيتسحب لجنب زي شريط الماركات وسيارات مميزة.
Widget styledHorizontalScrollbar({
  required ScrollController controller,
  required Widget child,
}) {
  return ScrollbarTheme(
    data: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        Colors.redAccent.withValues(alpha: 0.85),
      ),
      trackColor: WidgetStateProperty.all(Colors.black12),
      trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(20),
      crossAxisMargin: 0,
      mainAxisMargin: 2,
    ),
    child: Scrollbar(
      controller: controller,
      thumbVisibility: true,
      trackVisibility: true,
      child: child,
    ),
  );
}

Widget carImageAdaptive(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  AlignmentGeometry alignment = Alignment.center,
  bool showWatermark = true,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  Widget defaultErrorPlaceholder(BuildContext context, Object error, StackTrace? stack) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        size: 50,
        color: Colors.black26,
      ),
    );
  }

  final effectiveErrorBuilder = errorBuilder ?? defaultErrorPlaceholder;

  // بعض الصور القديمة ممكن تكون اتسجلت بروابط ناقصة أو متقطوعة (زي
  // "http" لوحدها من غير باقي الرابط) بسبب رفع فشل في نص الطريق —
  // بدل ما نحاول نحمّلها ونطلع إيرور في الكونسول، بنتأكد إنها رابط
  // كامل فعلاً الأول.
  final bool looksLikeFullUrl =
      path.startsWith('http://') || path.startsWith('https://');
  final bool looksLikeUsableAsset =
      path.trim().isNotEmpty && !path.startsWith('http');

  final Widget image;
  if (looksLikeFullUrl) {
    image = Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      // بنحدّ أقصى حجم يتفك بيه الصورة في الذاكرة، عشان صور
      // السيارات الكبيرة متبطئش التطبيق حتى لو بتتعرض صغيرة
      cacheWidth: width != null && width > 0
          ? (width * 2).clamp(50, 1200).round()
          : 1000,
      errorBuilder: effectiveErrorBuilder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ShimmerBox();
      },
    );
  } else if (looksLikeUsableAsset) {
    image = Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorBuilder: effectiveErrorBuilder,
    );
  } else {
    image = Builder(
      builder: (context) => effectiveErrorBuilder(context, 'invalid path', null),
    );
  }

  if (!showWatermark) return image;

  return Stack(
    fit: StackFit.expand,
    children: [
      image,
      Positioned(
        bottom: 8,
        right: 8,
        child: Opacity(
          opacity: 0.85,
          child: Image.asset(
            'assets/logo-autoone.png',
            width: 44,
            errorBuilder: (context, error, stack) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    ],
  );
}


class CarCard extends StatelessWidget {
  final Car car;
  final bool isArabic;

  const CarCard({
    super.key,
    required this.car,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      child: Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(18),

      elevation: 4,

      clipBehavior:
          Clip.antiAlias,

      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            smoothRoute(
              CarDetailsPage(
                car: car,
                isArabic: isArabic,
              ),
            ),
          );
        },

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            Expanded(
              child: carImageAdaptive(
                car.image,

                fit: BoxFit.contain,
                alignment: Alignment.center,
                
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                15,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    car.displayName(isArabic),

                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    '${car.brand} • ${car.year}',

                    style:
                        const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    car.price,

                    style:
                        const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                 

                  const SizedBox(height: 8),
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () async {
      const phone = '966541577894';

      final message = isArabic
          ? 'السلام عليكم، أريد الاستفسار عن ${car.name} من ${car.brand} موديل ${car.year} بسعر ${car.price}.'
          : 'Hello, I would like to ask about ${car.name} by ${car.brand}, year ${car.year}, priced at ${car.price}.';

      final Uri url = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    },

    icon: const FaIcon(
      FontAwesomeIcons.whatsapp,
      color: Colors.white,
      size: 22,
    ),

    label: Text(
      isArabic
          ? 'تواصل معنا عبر واتساب'
          : 'CONTACT US ON WHATSAPP',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),

    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff25D366),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 2,
    ),
  ),
),

                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}


// ============================================================
// CAR DETAILS
// ============================================================
class SimilarCarsSection extends StatelessWidget {
  final Car currentCar;
  final bool isArabic;

  const SimilarCarsSection({
    super.key,
    required this.currentCar,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final similarCars = cars
        .where(
          (car) =>
              car.brand == currentCar.brand &&
              car.name != currentCar.name,
        )
        .take(6)
        .toList();

    if (similarCars.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'سيارات مشابهة'
                : 'SIMILAR CARS',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            isArabic
                ? 'اقتراحات من نفس الماركة'
                : 'More cars from the same brand',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 2;

              if (constraints.maxWidth >= 1150) {
                columns = 4;
              } else if (constraints.maxWidth >= 800) {
                columns = 3;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: similarCars.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  return CarCard(
                    car: similarCars[index],
                    isArabic: isArabic,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}


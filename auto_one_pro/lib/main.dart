import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'shared/favorites_compare.dart';
import 'shared/auth.dart';
import 'shared/push_notifications.dart';
import 'shared/repository.dart';
import 'shared/widgets.dart';
import 'shared/ai_chat_widget.dart';
import 'screens/home_page.dart';
import 'screens/cars_page.dart';
import 'screens/car_details_page.dart';
import 'screens/comparison_page.dart';
import 'admin/admin_shared.dart';
import 'admin/admin_gate.dart' deferred as admin_gate;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  loadFavorites();
  initAuthListener();
  await initPushNotifications();
  if (isLoggedIn) {
    await loadFavoritesFromAccount();
    await registerForPushNotifications();
  }

  runApp(const AutoOneApp());
}


// وصول سريع للـ client في أي مكان بالتطبيق:
// final supabase = Supabase.instance.client;

// ============================================================
// APP
// ============================================================

class AutoOneApp extends StatefulWidget {
  const AutoOneApp({super.key});

  @override
  State<AutoOneApp> createState() => _AutoOneAppState();
}


class _AutoOneAppState extends State<AutoOneApp> {
  bool isArabic = true;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // لسه محتاجينه عشان زرار "ارجعي لفوق" يقدر يتحكم في سكرول
  // الصفحة الحالية (رصد ظهور الزرار بقى عن طريق NotificationListener
  // بدل الاعتماد على الكنترولر ده وحده).
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    // البيانات دي كانت بتتحمّل قبل كده وقت شاشة التحميل القديمة —
    // دلوقتي بنحمّلها هنا بدل كده، من غير ما نستنى أي شاشة تمهيدية.
    // وبعد ما تخلص، بنعمل setState عشان الصفحة تتحدّث بالبيانات
    // الجديدة (لأن قايمة cars مش مرتبطة بـ ValueNotifier).
    Future.wait([
      loadCarsFromSupabase(),
      loadHomepageSettings(),
      loadBrandLogos(),
    ]).then((_) {
      if (mounted) setState(() {});
    });
    _handleDeepLink();
  }

  // بتفتح صفحة السيارة تلقائيًا لو الرابط جاي بـ ?car=رقم (رابط مشاركة)
  void _handleDeepLink() {
    try {
      final search = html.window.location.search;
      final uri = Uri.parse('http://x$search');
      final carIdParam = uri.queryParameters['car'];
      if (carIdParam == null) return;

      final carId = int.tryParse(carIdParam);
      if (carId == null) return;

      final matches = cars.where((c) => c.id == carId);

      if (matches.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            smoothRoute(
              CarDetailsPage(car: matches.first, isArabic: isArabic),
            ),
          );
        });
        return;
      }

      // السيارة دي مش من ضمن الدفعة الأولى اللي اتحمّلت (أول
      // carsPageSize سيارة) — نجيبها مباشرة بالـ id بتاعها.
      fetchCarById(carId).then((car) {
        if (car == null || !mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            smoothRoute(CarDetailsPage(car: car, isArabic: isArabic)),
          );
        });
      });
    } catch (e) {
      debugPrint('AUTO_ONE_DEBUG: تعذّر فتح رابط المشاركة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'AUTO ONE',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
      ),

      // بيلف كل صفحة في الموقع بـ Stack فيه زرار الشات وزرار
      // الرجوع لأعلى الصفحة عائمين فوقها. بنستخدم NotificationListener
      // عشان نلتقط أي حركة سكرول في أي صفحة مباشرة (أضمن بكتير من
      // محاولة نوصل بـ ScrollController واحد لكل الصفحات، اللي كان
      // بيفشل بصمت وبيخلي الزرار ميظهرش خالص). وبنسيب
      // PrimaryScrollController زي ما هو عشان زرار "ارجعي لفوق"
      // نفسه يقدر يتحكم في سكرول الصفحة الحالية.
      builder: (context, child) {
        return PrimaryScrollController(
          controller: _scrollController,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final shouldShow = notification.metrics.pixels > 400;
              if (shouldShow != _showScrollTop) {
                // بنأجّل الـ setState لآخر الفريم الحالي، عشان منعملش
                // rebuild وسط عملية بناء شجرة الودجتس نفسها.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _showScrollTop = shouldShow);
                });
              }
              return false;
            },
            child: Stack(
              children: [
                if (child != null) child,
                AiChatBubble(isArabic: isArabic),
                ScrollToTopButton(
                  isArabic: isArabic,
                  visible: _showScrollTop,
                ),
              ],
            ),
          ),
        );
      },

      home: AutoOneShell(
        isArabic: isArabic,
        onLanguageChanged: () {
          setState(() {
            isArabic = !isArabic;
          });
        },
      ),
    );
  }
}




// ============================================================
// SHELL
// ============================================================

class AutoOneShell extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageChanged;

  const AutoOneShell({
    super.key,
    required this.isArabic,
    required this.onLanguageChanged,
  });

  @override
  State<AutoOneShell> createState() => _AutoOneShellState();
}


class _AutoOneShellState extends State<AutoOneShell> {
  bool showCars = false;
  String? selectedBrand;
  bool showOffers = false;
  String? selectedBodyType;
  void openHome() {
  setState(() {
    showCars = false;
    showOffers = false;
    selectedBrand = null;
    selectedBodyType = null;
  });
}
 void openCars([String? brand]) {
  setState(() {
    showCars = true;

    // فتح العروض فقط
    showOffers = brand == '__OFFERS__';

    // فتح نوع جسم معيّن بس (SUV / سيدان / جيب)
    if (brand != null && brand.startsWith('__BODYTYPE_')) {
      selectedBodyType = brand.replaceFirst('__BODYTYPE_', '');
      selectedBrand = null;
      return;
    }
    selectedBodyType = null;

    if (brand == null || brand == '__OFFERS__') {
      selectedBrand = null;
    } else if (brand.toLowerCase() == 'chery') {
      selectedBrand = 'CHERY PRO';
    } else if (brand.toLowerCase() == 'jetour') {
      selectedBrand = 'JETOUR';
    } else {
      selectedBrand = cars
          .map((car) => car.brand)
          .firstWhere(
            (value) =>
                value.toLowerCase() == brand.toLowerCase(),
            orElse: () => brand,
          );
    }
  });
}



  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,

      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),

        endDrawer: MobileMenuDrawer(
          isArabic: widget.isArabic,
          showCars: showCars,
          onHome: openHome,
          onCars: ([brand]) => openCars(brand),
          onLanguage: widget.onLanguageChanged,
        ),

        // ======================================================
        // TOP BAR
        // ======================================================

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),

          child: AutoOneHeader(
            isArabic: widget.isArabic,
            showCars: showCars,

            onHome: openHome,
           onCars: ([brand]) => openCars(brand),

            onLanguage: widget.onLanguageChanged,
            onAdminAccess: () async {
              // بيحمّل كود لوحة التحكم بس في اللحظة دي (مش مع الموقع
              // من الأول)، وده اللي بيقلل حجم التحميل لأي زائر عادي.
              await admin_gate.loadLibrary();
              if (!context.mounted) return;
              Navigator.of(context).push(
                smoothRoute(
                  admin_gate.AdminGate(isArabic: widget.isArabic),
                ),
              );
            },
          ),
        ),

        // ======================================================
        // CONTENT
        // ======================================================

        body: Column(
          children: [
            ConnectivityBanner(isArabic: widget.isArabic),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),

                child: showCars
                    ? CarsPage(
          key: const ValueKey('cars'),
          isArabic: widget.isArabic,
         initialBrand: selectedBrand,
          initialOffers: showOffers,
          initialBodyType: selectedBodyType,
        )
                    : HomePage(
                        key: const ValueKey('home'),
                        isArabic: widget.isArabic,
                        onOpenCars: (brand) => openCars(brand),
                      ),
              ),
            ),
          ],
        ),
      bottomNavigationBar: ValueListenableBuilder<List<int>>(
        valueListenable: compareCarIds,
        builder: (context, list, _) {
          if (list.length < 2) return const SizedBox.shrink();

          return Material(
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A1A1A),
                      Color(0xFF000000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.compare_arrows_rounded,
                            color: Color(0xFFD4AF37),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isArabic
                                ? '${list.length} سيارات محددة للمقارنة'
                                : '${list.length} cars selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            compareCarIds.value = [];
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    HoverLift(
                      scale: 1.02,
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              smoothRoute(
                                ComparisonPage(isArabic: widget.isArabic),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFD4AF37),
                                  Color(0xFFB8860B),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isArabic
                                      ? 'قارني الآن'
                                      : 'Compare Now',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  widget.isArabic
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ],
                            ),
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
      ),
    ),
    );
  }
}

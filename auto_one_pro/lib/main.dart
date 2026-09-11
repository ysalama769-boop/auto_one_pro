import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'shared/favorites_compare.dart';
import 'shared/repository.dart';
import 'shared/widgets.dart';
import 'screens/home_page.dart';
import 'screens/cars_page.dart';
import 'screens/car_details_page.dart';
import 'screens/comparison_page.dart';
import 'admin/admin_shared.dart';
import 'admin/admin_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  loadFavorites();

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
  bool showSplash = true;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      if (matches.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          smoothRoute(
            CarDetailsPage(car: matches.first, isArabic: isArabic),
          ),
        );
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

      home: showSplash
          ? SplashScreen(
              isArabic: isArabic,
              onLanguageChanged: () {
                setState(() {
                  isArabic = !isArabic;
                });
              },
              onFinished: () {
                setState(() {
                  showSplash = false;
                });
                _handleDeepLink();
              },
            )
          : AutoOneShell(
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
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageChanged;
  final VoidCallback onFinished;

  const SplashScreen({
    super.key,
    required this.isArabic,
    required this.onLanguageChanged,
    required this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // بيجيب بيانات السيارات من Supabase، مع ضمان إن الـ Splash Screen
    // تظهر ثانيتين على الأقل حتى لو النت سريع
    await Future.wait([
      loadCarsFromSupabase(),
      loadHomepageSettings(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo-autoone.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  const PulsingDots(),
                ],
              ),
            ),
          ),
        ),
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
  void openHome() {
  setState(() {
    showCars = false;
    showOffers = false;
    selectedBrand = null;
  });
}
 void openCars([String? brand]) {
  setState(() {
    showCars = true;

    // فتح العروض فقط
    showOffers = brand == '__OFFERS__';

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
    void openCars([String? brand]) {
  setState(() {
    showCars = true;

    if (brand == null) {
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
    return Directionality(
      textDirection: widget.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,

      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        extendBodyBehindAppBar: true,

        // ======================================================
        // TOP BAR
        // ======================================================

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),

          child: AutoOneHeader(
            isArabic: widget.isArabic,
            showCars: showCars,
            transparent: !showCars,

            onHome: openHome,
           onCars: () => openCars(),

            onLanguage: widget.onLanguageChanged,
            onAdminAccess: () {
              Navigator.of(context).push(
                smoothRoute(AdminGate(isArabic: widget.isArabic)),
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


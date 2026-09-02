import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

// ============================================================
// SHARED DESIGN CONSTANTS
// ============================================================
// نفس لون الهيدر الرئيسي، مستخدم في كل صفحات التطبيق للتناسق
const Color kHeaderColor = Color.fromARGB(255, 238, 221, 221);
const Color kHeaderTextColor = Color.fromARGB(255, 20, 20, 20);

// ============================================================
// FAVORITES (stored locally in the browser)
// ============================================================
Set<int> favoriteCarIds = {};

void loadFavorites() {
  try {
    final saved = html.window.localStorage['auto_one_favorites'];
    if (saved != null && saved.isNotEmpty) {
      favoriteCarIds =
          saved.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
    }
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل المفضلة: $e');
  }
}

void _saveFavorites() {
  try {
    html.window.localStorage['auto_one_favorites'] = favoriteCarIds.join(',');
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر حفظ المفضلة: $e');
  }
}

void toggleFavorite(int carId) {
  if (favoriteCarIds.contains(carId)) {
    favoriteCarIds.remove(carId);
  } else {
    favoriteCarIds.add(carId);
  }
  _saveFavorites();
}

// ============================================================
// COMPARISON (session only — up to 3 cars)
// ============================================================
final ValueNotifier<List<int>> compareCarIds = ValueNotifier<List<int>>([]);

void toggleCompare(int carId) {
  final list = List<int>.from(compareCarIds.value);
  if (list.contains(carId)) {
    list.remove(carId);
  } else {
    if (list.length >= 3) {
      list.removeAt(0);
    }
    list.add(carId);
  }
  compareCarIds.value = list;
}

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

        // ======================================================
        // TOP BAR
        // ======================================================

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),

          child: AutoOneHeader(
            isArabic: widget.isArabic,
            showCars: showCars,

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
            color: Colors.black,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isArabic
                            ? 'محددة ${list.length} سيارات للمقارنة'
                            : '${list.length} cars selected to compare',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        compareCarIds.value = [];
                      },
                      child: Text(
                        widget.isArabic ? 'مسح' : 'Clear',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          smoothRoute(
                            ComparisonPage(isArabic: widget.isArabic),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.isArabic ? 'قارني الآن' : 'Compare now',
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

  final VoidCallback onHome;
  final VoidCallback onCars;
  final VoidCallback onLanguage;
  final VoidCallback onAdminAccess;

  const AutoOneHeader({
    super.key,
    required this.isArabic,
    required this.showCars,
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
    final isMobile =
                 MediaQuery.of(context).size.width < 700;
    return Container(
      color: const Color.fromARGB(255, 238, 221, 221),

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

              const Spacer(),

              // =================================================
              // HOME
              // =================================================

              if (!isMobile) ...[
  HeaderButton(
    title: isArabic ? 'الرئيسية' : 'HOME',
    active: !showCars,
    onTap: onHome,
  ),

  const SizedBox(width: 10),

  HeaderButton(
    title: isArabic ? 'المعرض' : 'CARS',
    active: showCars,
    onTap: onCars,
  ),

  const SizedBox(width: 10),

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

  const SizedBox(width: 15),

  InkWell(
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
        style: const TextStyle(
          color: Color.fromARGB(255, 12, 12, 12),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
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
  PopupMenuButton<String>(
    icon: const Icon(
      Icons.menu,
      color: Colors.white,
      size: 30,
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
          isArabic ? 'المعرض' : 'CARS',
        ),
      ),
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

class HeaderButton extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const HeaderButton({
    super.key,
    required this.title,
    required this.active,
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

          style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
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
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  final bool isArabic;
  final ValueChanged<String?> onOpenCars;
  const HomePage({
    super.key,
    required this.isArabic,
    required this.onOpenCars,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 int currentImage = 0;

int get safeImageIndex {
  if (images.isEmpty) return 0;
  if (currentImage >= images.length) return images.length - 1;
  if (currentImage < 0) return 0;
  return currentImage;
}
late final PageController _pageController;        


@override
void initState() {
  super.initState();

  _pageController = PageController(
    viewportFraction: 0.86,
  );

}


@override
void dispose() {
  _pageController.dispose();
  super.dispose();
}

  // ==========================================================
  // صور الواجهة
  //
  // مؤقتًا حاطط نفس الصورة الموجودة عندك.
  //
  // بعدين هنغيرهم إلى:
  //
  // assets/jetour_g700.jpg
  // assets/patrol.jpg
  // assets/kia_sonet.jpg
  // ...
  // ==========================================================

  final List<String> images = [
    'assets/youssefcar1.jpg',
    'assets/youssefcar22.jpg',
    'assets/youssefcar3.jpg',
    'assets/youssefcar4.jpg',
    'assets/youssefcar5.jpg',
  ];
  
final List<Map<String, String>> slideTexts = [
  {
    'ar': 'أفضل السيارات الصينية بأفضل الأسعار',
    'en': 'Best Chinese Cars at the Best Prices',
  },
  {
    'ar': 'اختيارك المثالي يبدأ من AUTO ONE.',
    'en': 'Your Perfect Choice Starts at AUTO ONE.',
  },
  {
    'ar': 'سيارات فاخرة.. تجربة استثنائية.',
    'en': 'Luxury Cars.. An Exceptional Experience.',
  },
  {
    'ar': 'أقوى سيارات SUV جاهزة ليك.',
    'en': 'Powerful SUVs Ready for You.',
  },
  {
    'ar': 'أفضل العروض.. وأسعار تنافسية.',
    'en': 'The Best Offers at Competitive Prices.',
  },
];

final List<Map<String, String>> slideDescriptions = [
  
  {
    'ar': 'اختيارات مميزة، أسعار تنافسية، وتجربة شراء أسهل.',
    'en': 'Premium choices, competitive prices, and an easier buying experience.',
  },
  {
    'ar': 'اختيارك المثالي يبدأ من AUTO ONE.',
    'en': 'Your perfect choice starts at AUTO ONE.',
  },
  {
    'ar': 'فخامة وأناقة في كل تفصيلة.',
    'en': 'Luxury and elegance in every detail.',
  },
  {
    'ar': 'قوة وتجهيزات تناسب كل احتياجاتك.',
    'en': 'Power and features for every need.',
  },
  {
    'ar': 'أفضل العروض بسيارات مميزة وأسعار تنافسية.',
    'en': 'Great cars with competitive offers.',
  },
];

final List<Map<String, String>> slideButtons = [
  
  {
    'ar': 'استعرض السيارات',
    'en': 'Explore Cars',
  },
  {
    'ar': 'شاهد التفاصيل',
    'en': 'View Details',
  },
  {
    'ar': 'اكتشف الفخامة',
    'en': 'Discover Luxury',
  },
  {
    'ar': 'شاهد الـSUV',
    'en': 'View SUVs',
  },
  {
    'ar': 'شوف العروض',
    'en': 'See Offers',
  },
  
];

  // ==========================================================
  // NEXT
  // ==========================================================

 void nextImage() {
  if (images.isEmpty) return;

  setState(() {
    currentImage = (currentImage + 1) % images.length;
  });
}
  // ==========================================================
  // PREVIOUS
  // ==========================================================

  void previousImage() {
  if (images.isEmpty) return;

  setState(() {
    currentImage =
        (currentImage - 1 + images.length) % images.length;
  });
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 35),

          // ====================================================
          // CAROUSEL
          // ====================================================

        Padding(
  padding: const EdgeInsets.symmetric(horizontal: 25),

  child: LayoutBuilder(
    builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 850;

      return GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;

          if (velocity < -100) {
            nextImage();
          } else if (velocity > 100) {
            previousImage();
          }
        },

        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 550),

          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },

          child: Container(
            key: ValueKey(images[safeImageIndex]),
            width: double.infinity,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),

            clipBehavior: Clip.antiAlias,

            child: Flex(
              direction: isSmall
                  ? Axis.vertical
                  : Axis.horizontal,

              children: [

                // =================================================
                // الصورة
                // =================================================

                Expanded(
                  flex: isSmall ? 0 : 7,

                  child: SizedBox(
                    width: double.infinity,
                    height: isSmall ? 350 : 600,

                    child: Image.asset(
                      images[safeImageIndex],

                      width: double.infinity,
                      height: double.infinity,

                      fit: BoxFit.cover,

                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(
                              Icons.directions_car,
                              size: 90,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // =================================================
                // الجانب الأبيض + اللوجو
                // =================================================

                Expanded(
                  flex: isSmall ? 0 : 4,

                  child: Container(
                    width: double.infinity,
                    color: Colors.white,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 25,
                    ),

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        // اللوجو الحقيقي
                       Image.asset(
  'assets/logo-autoone.png',
  width: isSmall ? 130 : 165,
  height: isSmall ? 75: 90,
  fit: BoxFit.contain,
),

                        const SizedBox(height: 10),

                        Text(
                          widget.isArabic
                              ? 'معرض سيارات'
                              : 'CAR DEALERSHIP',

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 25),

                        Text(
                          widget.isArabic
                              ? slideTexts[currentImage]['ar']!
                              : slideTexts[currentImage]['en']!,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 26,
                            height: 1.3,
                            fontWeight: FontWeight.w900,
                            color: Color.fromARGB(255, 149, 138, 138),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          widget.isArabic
                              ? slideDescriptions[currentImage]['ar']!
                              : slideDescriptions[currentImage]['en']!,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 22),

                       

                        const SizedBox(height: 20),

                        Container(
                          height: 4,
                          width: 80,

                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                        ),
                      ],
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

          
          const SizedBox(height: 25),

          // ====================================================
          // ARROWS
          // ====================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
             Transform.scale(
  scale: 0.7,
  child: CarouselArrow(
    icon: Icons.arrow_back_ios_new,
    onTap: previousImage,
  ),
),

Transform.scale(
  scale: 0.7,
  child: CarouselArrow(
    icon: Icons.arrow_forward_ios,
    onTap: nextImage,
  ),
),

const SizedBox(width: 8),

Text(
  '${safeImageIndex + 1} / ${images.length}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.grey,
  ),
),

const SizedBox(width: 8),


            ],
          ),

          const SizedBox(height: 18),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(
    images.length,
    (index) {
      final isActive = index == currentImage;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.red
              : Colors.black26,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    },
  ),
),

BrandStrip(
  isArabic: widget.isArabic,
  onBrandTap: (brand) {
    widget.onOpenCars(brand);
  },
),

const SizedBox(height: 45),

          // ====================================================
          // FEATURES
          // ====================================================

          Container(
            width: double.infinity,
            color: Colors.white,

            padding:
                const EdgeInsets.symmetric(
              vertical: 35,
              horizontal: 20,
            ),

            child: Wrap(
              alignment:
                  WrapAlignment.center,

              spacing: 80,
              runSpacing: 30,

              children: [
             HomeFeature(
  icon: Icons.directions_car_filled,
  title: widget.isArabic
      ? 'سيارات مختارة بعناية'
      : 'CAREFULLY SELECTED CARS',
  description: widget.isArabic
      ? 'موديلات مميزة تناسب احتياجاتك'
      : 'Selected models for your needs',
),

HomeFeature(
  icon: Icons.price_check,
  title: widget.isArabic
      ? 'أسعار تنافسية'
      : 'COMPETITIVE PRICES',
  description: widget.isArabic
      ? 'عروض وقيمة أفضل مقابل السعر'
      : 'Better value for your money',
),

HomeFeature(
  icon: Icons.support_agent,
  title: widget.isArabic
      ? 'تجربة شراء أسهل'
      : 'EASY BUYING EXPERIENCE',
  description: widget.isArabic
      ? 'تواصل سريع ومساعدة في اختيار سيارتك'
      : 'Quick support to help you choose your car',
),
              ],
            ),
          ),

          const SizedBox(height: 50),
          // ====================================================
// FEATURED CARS
// ====================================================

Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    vertical: 55,
    horizontal: 30,
  ),
  color: const Color(0xFFF7F7F7),

  child: Column(
    children: [
      Text(
        widget.isArabic
            ? 'سيارات مميزة'
            : 'FEATURED CARS',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),

      const SizedBox(height: 10),

      Text(
        widget.isArabic
            ? 'اختيارات مميزة من سيارات AUTO ONE'
            : 'A selection of featured cars from AUTO ONE',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black54,
        ),
      ),

      const SizedBox(height: 35),

      LayoutBuilder(
  builder: (context, constraints) {

   final List<Car> featuredCars = [];

final featuredNames = [
  'باترول بلاتينيوم',
  'G700 Flagship',
  'سيلتوس 1.5 استاندر',
  'النترا 2.0 كمفورت',
  'K8 1.5 استاندر GL',
];

for (final keyword in featuredNames) {
  for (final car in cars) {
    if (car.name.contains(keyword)) {
      featuredCars.add(car);
      break;
    }
  }
}

    int columns = 1;

    if (constraints.maxWidth >= 1400) {
      columns = 5;
    } else if (constraints.maxWidth >= 1100) {
      columns = 4;
    } else if (constraints.maxWidth >= 800) {
      columns = 2;
    } else {
      columns = 1;
    }

return GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),

  itemCount: featuredCars.length,

  gridDelegate:
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: 16,
    mainAxisSpacing: 20,
    childAspectRatio: 0.70,
  ),

  itemBuilder: (context, index) {
    return FeaturedCarCard(
      car: featuredCars[index],
      isArabic: widget.isArabic,
    );
  },
);
        },
      ),
    ],
  ),
),
const SizedBox(height: 35),

// ====================================================
// WHY AUTO ONE
// ====================================================

Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    vertical: 70,
    horizontal: 30,
  ),
  color: const Color(0xFF0B0B0B),

  child: Column(
    children: [

      // TITLE
      Text(
        widget.isArabic
            ? 'لماذا AUTO ONE؟'
            : 'WHY AUTO ONE?',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),

      const SizedBox(height: 10),

      // SUBTITLE
      Text(
        widget.isArabic
            ? 'تجربة مختلفة في اختيار وشراء سيارتك'
            : 'A different experience in choosing and buying your car',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white60,
        ),
      ),

      const SizedBox(height: 45),

      LayoutBuilder(
        builder: (context, constraints) {

          final isSmall = constraints.maxWidth < 700;

          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,

            children: [

              _whyAutoOneCard(
                icon: Icons.directions_car_filled_rounded,
                title: widget.isArabic
                    ? 'اختيارات متنوعة'
                    : 'WIDE SELECTION',
                description: widget.isArabic
                    ? 'مجموعة متنوعة من السيارات والموديلات لتختار ما يناسبك.'
                    : 'A wide selection of cars and models to match your needs.',
                isSmall: isSmall,
              ),

              _whyAutoOneCard(
                icon: Icons.price_check_rounded,
                title: widget.isArabic
                    ? 'أسعار منافسة'
                    : 'COMPETITIVE PRICES',
                description: widget.isArabic
                    ? 'أسعار مدروسة وعروض مميزة على مجموعة من السيارات.'
                    : 'Competitive prices and special offers on selected cars.',
                isSmall: isSmall,
              ),

              _whyAutoOneCard(
                icon: Icons.handshake_rounded,
                title: widget.isArabic
                    ? 'خدمة موثوقة'
                    : 'RELIABLE SERVICE',
                description: widget.isArabic
                    ? 'نهتم بتقديم تجربة واضحة ومريحة من البداية للنهاية.'
                    : 'A clear and comfortable experience from start to finish.',
                isSmall: isSmall,
              ),

              _whyAutoOneCard(
                icon: Icons.support_agent_rounded,
                title: widget.isArabic
                    ? 'تواصل سريع'
                    : 'FAST SUPPORT',
                description: widget.isArabic
                    ? 'تواصل معنا بسهولة واحصل على المساعدة التي تحتاجها.'
                    : 'Easy communication and quick support when you need it.',
                isSmall: isSmall,
              ),
            ],
          );
        },
      ),
    ],
  ),
),

const SizedBox(height: 55),

// ====================================================
// OUR BRANCHES
// ====================================================

_buildBranchesSection(context),

const SizedBox(height: 55),

_buildAutoOneContactSection(context),

const SizedBox(height: 30),

        ],
      ),
    );
 
  }
 Widget _whyAutoOneCard({
  required IconData icon,
  required String title,
  required String description,
  required bool isSmall,
}) {
  return Container(
    width: isSmall ? 320 : 260,
    padding: const EdgeInsets.all(24),

    decoration: BoxDecoration(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white12,
      ),
    ),

    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // =================================================
        // ICON
        // =================================================

        Container(
          width: 58,
          height: 58,

          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),

          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),

        const SizedBox(height: 16),

        // =================================================
        // TITLE
        // =================================================

        Text(
          title,
          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 9),

        // =================================================
        // DESCRIPTION
        // =================================================

        Text(
          description,
          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 16),

        // =================================================
        // RED LINE
        // =================================================

        Container(
          width: 35,
          height: 3,

          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    ),
  );
}
Widget _buildAutoOneContactSection(BuildContext context) {
  Future<void> openLink(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.symmetric(
      horizontal: 25,
      vertical: 35,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF0B0B0B),
      borderRadius: BorderRadius.circular(25),
    ),

    child: Column(
      children: [

        const Icon(
          Icons.support_agent_rounded,
          color: Colors.red,
          size: 45,
        ),

        const SizedBox(height: 12),

        Text(
          widget.isArabic
              ? 'تواصل مع أوتو ون'
              : 'CONTACT AUTO ONE',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          widget.isArabic
              ? 'تواصل معنا عبر منصاتنا'
              : 'Connect with us on our platforms',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 28),

        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [

            // =================================================
            // WHATSAPP
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://wa.me/966541577894',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                size: 18,
              ),

              label: Text(
                widget.isArabic
                    ? 'واتساب'
                    : 'WHATSAPP',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),

            // =================================================
            // INSTAGRAM
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://www.instagram.com/autoone_sa',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.instagram,
                size: 18,
              ),

              label: const Text('Instagram'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),

            // =================================================
            // TIKTOK
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://www.tiktok.com/@autoone_sa',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.tiktok,
                size: 18,
              ),

              label: const Text('TikTok'),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(
                    color: Colors.white30,
                  ),
                ),
              ),
            ),

            // =================================================
            // FACEBOOK
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://www.facebook.com/share/1EiuLeeFP7/',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.facebookF,
                size: 18,
              ),

              label: const Text('Facebook'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),

            // =================================================
            // X
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://x.com/autoone_sa',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.xTwitter,
                size: 18,
              ),

              label: const Text('X'),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(
                    color: Colors.white30,
                  ),
                ),
              ),
            ),

            // =================================================
            // THREADS
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://www.threads.com/@autoone_sa',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.threads,
                size: 18,
              ),

              label: const Text('Threads'),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(
                    color: Colors.white30,
                  ),
                ),
              ),
            ),

            // =================================================
            // SNAPCHAT
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'https://www.snapchat.com/add/autoone_sa',
                );
              },

              icon: const FaIcon(
                FontAwesomeIcons.snapchat,
                size: 18,
              ),

              label: const Text('Snapchat'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFC00),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),

            // =================================================
            // CALL
            // =================================================

            ElevatedButton.icon(
              onPressed: () {
                openLink(
                  'tel:+966541577894',
                );
              },

              icon: const Icon(
                Icons.phone_rounded,
                size: 18,
              ),

              label: Text(
                widget.isArabic
                    ? 'اتصل بنا'
                    : 'CALL US',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        Container(
          width: 45,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    ),
  );
}
// ============================================================
// OUR BRANCHES
// ============================================================

Widget _buildBranchesSection(BuildContext context) {
  Future<void> openLink(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  final List<Map<String, dynamic>> branches = [
  {
    'number': '1',
    'nameAr': 'الفرع الرئيسي',
    'nameEn': 'MAIN BRANCH',
    'addressAr': 'الجوهرة - جدة',
    'addressEn': 'Al Johara - Jeddah',
    'map': 'https://www.google.com/maps/search/?api=1&query=Auto+One+Al+Johara+Jeddah',
    'showBadge': false,
  },
  {
    'number': '2',
    'nameAr': 'فرع القادسية',
    'nameEn': 'AL QADISIYAH BRANCH',
    'addressAr': 'القادسية - الرياض',
    'addressEn': 'Al Qadisiyah - Riyadh',
    'map': 'https://www.google.com/maps/search/?api=1&query=Auto+One+Al+Qadisiyah+Riyadh',
    'showBadge': false,
  },
  {
    'number': '3',
    'nameAr': 'فرع الحمدانية',
    'nameEn': 'AL HAMADANIYAH',
    'addressAr': 'الحمدانية - جدة',
    'addressEn': 'Al Hamadaniyah - Jeddah',
    'map': 'https://www.google.com/maps/search/?api=1&query=Auto+One+Al+Hamadaniyah+Jeddah',
    'showBadge': true,
  },
];
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      vertical: 65,
      horizontal: 25,
    ),
    color: const Color(0xFFF7F7F7),

    child: Column(
      children: [

        // ==================================================
        // TITLE
        // ==================================================

        Text(
          widget.isArabic
              ? 'فروع AUTO ONE'
              : 'AUTO ONE BRANCHES',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          widget.isArabic
              ? 'اختر الفرع الأقرب إليك'
              : 'Choose the branch closest to you',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: 45,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 42),

        // ==================================================
        // BRANCHES
        // ==================================================

        LayoutBuilder(
          builder: (context, constraints) {

            final isSmall =
                constraints.maxWidth < 800;

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 22,
              runSpacing: 22,

              children: branches.map((branch) {

                return Container(
                  width: isSmall
                      ? double.infinity
                      : 330,

                  padding: const EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),

                    border: Border.all(
                      color: Colors.black12,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Stack(
                    children: [

                      // ==================================================
                      // BIG NUMBER
                      // ==================================================

                      Positioned(
                        top: -8,
                        right: 0,

                        child: Text(
                          branch['number']!,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF1F1F1),
                          ),
                        ),
                      ),

                      Column(
                        children: [

                         // ==================================================
// PREMIUM LOCATION ICON
// ==================================================

Container(
  width: 72,
  height: 72,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.black12,
      width: 1.2,
    ),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 14,
        offset: Offset(0, 5),
      ),
    ],
  ),
  child: Stack(
    alignment: Alignment.center,
    children: [

      // Outer red accent
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(0.06),
        ),
      ),

      // Location pin
      ClipOval(
  child: Image.asset(
    'assets/google_maps_pin.png',
    width: 42,
    height: 42,
    fit: BoxFit.cover,
  ),
),
    ],
  ),
),
                            const SizedBox(height: 10),
                          

                          // ==================================================
                          // NAME
                          // ==================================================

                        Text(
  widget.isArabic
      ? branch['nameAr']!
      : branch['nameEn']!,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: Colors.black,
  ),
),

                          const SizedBox(height: 10),

                          // ==================================================
                          // ADDRESS
                          // ==================================================

                          Text(
                            widget.isArabic
                                ? branch['addressAr']!
                                : branch['addressEn']!,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black54,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // BUTTONS
                          // ==================================================

                          Row(
                            children: [

                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    openLink(
                                      branch['map']!,
                                    );
                                  },

                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 17,
                                  ),

                                  label: Text(
                                    widget.isArabic
                                        ? 'الموقع'
                                        : 'LOCATION',
                                  ),

                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(
                                            0xFF0B0B0B),

                                    foregroundColor:
                                        Colors.white,

                                    elevation: 0,

                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 13,
                                    ),

                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 9),

                              SizedBox(
                                width: 48,

                                child: ElevatedButton(
                                  onPressed: () {
                                    openLink(
                                      'tel:+966541577894',
                                    );
                                  },

                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red,

                                    foregroundColor:
                                        Colors.white,

                                    elevation: 0,

                                    padding:
                                        EdgeInsets.zero,

                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(12),
                                    ),
                                  ),

                                  child: const Icon(
                                    Icons.phone_rounded,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                         ], 
                      ),
                    ],
                  ),
                );

              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}
}
// ============================================================
// BRAND STRIP
// ============================================================

class BrandStrip extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<String> onBrandTap;

  const BrandStrip({
    super.key,
    required this.isArabic,
    required this.onBrandTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> brandLogos = {
      'Toyota': 'assets/brands/logo-toyota1.jpg',
      'Kia': 'assets/brands/logo-kia1.jpg',
      'Jetour': 'assets/brands/logo-jetour1.png',
      'Nissan': 'assets/brands/logo-nissan1.jpg',
      'Ford': 'assets/brands/logo-ford1.jpg',
      'BAIC': 'assets/brands/logo-baic1.jpg',
      'BYD': 'assets/brands/logo-byd1.png',
      'MG': 'assets/brands/logo-mg1.jpg',
      'Chery': 'assets/brands/logo-chery1.png',
      'Hyundai': 'assets/brands/logo-hyundai1.jpg',
      'Geely': 'assets/brands/logo-geely1.jpg',
      'RELY': 'assets/brands/logo-rely1.jpg',
      'JAC': 'assets/brands/logo-jac1.png',
    };

    final brands = brandLogos.keys.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            isArabic
                ? 'تصفح حسب الماركة'
                : 'BROWSE BY BRAND',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            isArabic
                ? 'اختار الماركة وشوف السيارات المتاحة'
                : 'Choose a brand and explore available cars',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: brands.map((brand) {
                final logo = brandLogos[brand]!;

                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 14,
                  ),
                  child: HoverLift(
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                    onTap: () => onBrandTap(brand),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 145,
                      height: 130,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xfffafafa),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.black12,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                logo,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return const Icon(
                                    Icons
                                        .directions_car_filled_rounded,
                                    size: 40,
                                    color: Colors.red,
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            brand,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// CAROUSEL ARROW
// ============================================================

class CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CarouselArrow({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
// ============================================================
// HOME FEATURE
// ============================================================

class HomeFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const HomeFeature({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.red,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

Text(
  title,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 8),

Text(
  description,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 13,
    height: 1.5,
    color: Colors.black54,
  ),
),
],
      ),
    );
  }
}
class FeaturedCarCard extends StatelessWidget {
  final Car car;
  final bool isArabic;
  final VoidCallback? onDetails;
  final bool compact;

  const FeaturedCarCard({
    super.key,
    required this.car,
    required this.isArabic,
    this.onDetails,
    this.compact = false,
  });
  String _brandLogo() {
    return getBrandLogo(car.brand);
  }

  Future<void> _openWhatsApp() async {
    const phone = '966541577894';

    final message = isArabic
        ? 'السلام عليكم، أريد الاستفسار عن ${car.name} من ${car.brand} موديل ${car.year}.'
        : 'Hello, I would like to ask about ${car.name} by ${car.brand}, year ${car.year}.';

    final Uri url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
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
  final logo = _brandLogo();

  return HoverLift(
    borderRadius: BorderRadius.circular(22),
    child: Material(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  elevation: 4,
  shadowColor: Colors.black26,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          smoothRoute(
            CarDetailsPage(car: car, isArabic: isArabic),
          ),
        );
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // =====================================================
        // IMAGE
        // =====================================================

        SizedBox(
          height: compact ? 120 : 195,
          child: Stack(
            fit: StackFit.expand,
            children: [

              carImageAdaptive(
                car.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: compact ? 44 : 75,
                        color: Colors.black26,
                      ),
                    ),
                  );
                },
              ),

              // NEW / OFFER
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: car.isOffer ? Colors.orange.shade800 : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    car.isOffer
                        ? (isArabic ? 'عرض خاص' : 'OFFER')
                        : (isArabic ? 'جديد' : 'NEW'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // BRAND LOGO
              if (logo.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: compact ? 38 : 54,
                    height: compact ? 38 : 54,
                    padding: const EdgeInsets.all(6),
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
                    child: Image.asset(
                      logo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              // YEAR
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    car.year,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // FAVORITE BUTTON
              Positioned(
                bottom: 10,
                left: 10,
                child: FavoriteButton(carId: car.id),
              ),

              // COMPARE BUTTON
              Positioned(
                bottom: 10,
                left: 54,
                child: CompareButton(carId: car.id),
              ),
            ],
          ),
        ),

        // =====================================================
        // LIGHT CONTENT
        // =====================================================

        Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(10, 9, 10, 9)
            : const EdgeInsets.fromLTRB(13, 11, 13, 12),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // MODEL + PRICE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                        
 
   Text(
    car.name,
    maxLines: compact ? 1 : 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.right,
    style: TextStyle(
      color: Colors.black,
      fontSize: compact ? 12.5 : 15,
      fontWeight: FontWeight.w900,
      height: 1.15,
    ),
  ),


                          SizedBox(height: compact ? 4 : 7),

                          Row(
                            children: [

Text(
  car.brand,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: Colors.red,
    fontSize: compact ? 10 : 11,
    fontWeight: FontWeight.w900,
  ),
),

                              const SizedBox(width: 8),

                              Container(
                                width: 1,
                                height: 12,
                                color: Colors.black12,
                              ),

                              const SizedBox(width: 8),

                              Text(
                                car.year,
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // PRICE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        Text(
                          'السعر',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (car.isOffer && car.oldPrice.isNotEmpty)
                          Text(
                            car.oldPrice,
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: compact ? 9 : 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),

                        Text(
                          car.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: compact ? 12.5 : 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (!compact) ...[
                const SizedBox(height: 10),

                // =================================================
                // SPECS
                // =================================================

               Container(
  height: 74,
  padding: const EdgeInsets.symmetric(
    horizontal: 3,
    vertical: 3,
  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff7f7f7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [

                      Expanded(
                        child: _lightspec(
                          icon: Icons.event_seat_outlined,
                          value: car.seats,
                          title: isArabic ? 'المقاعد' : 'SEATS',
                        ),
                      ),

                      _lightspecDivider(),

                      Expanded(
                        child: _lightspec(
                          icon: Icons.local_gas_station_outlined,
                          value: car.fuel,
                          title: isArabic ? 'الوقود' : 'FUEL',
                        ),
                      ),

                      _lightspecDivider(),

                      Expanded(
                        child: _lightspec(
                          icon: Icons.settings_outlined,
                          value: car.transmission,
                          title: isArabic ? 'ناقل الحركة' : 'GEAR',
                        ),
                      ),

                      _lightspecDivider(),

                      Expanded(
                        child: _lightspec(
                          icon: Icons.speed_outlined,
                          value: car.engine,
                          title: isArabic ? 'المحرك' : 'ENGINE',
                        ),
                      ),
                    ],
                  ),
                ),
                ],

                SizedBox(height: compact ? 8 : 5),

                // =================================================
                // BUTTONS
                // =================================================

                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: compact ? 12 : 15,
                        ),
                        label: Text(
                          compact
                              ? ''
                              : (isArabic
                                  ? 'واتساب'
                                  : 'WHATSAPP'),
                        ),
                        style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xff25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 8 : 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                          textStyle: TextStyle(
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: compact ? 6 : 9),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDetails ??
                            () {
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
                        icon: Icon(
                          Icons.description_outlined,
                          size: compact ? 12 : 15,
                        ),
                        label: Text(
                          compact
                              ? ''
                              : (isArabic
                                  ? 'التفاصيل'
                                  : 'DETAILS'),
                        ),
                      style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xff0B0B0B),
  foregroundColor: Colors.white,
  elevation: 0,
  padding: EdgeInsets.symmetric(
    vertical: compact ? 6 : 9,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(11),
  ),
  textStyle: TextStyle(
    fontSize: compact ? 10 : 12,
    fontWeight: FontWeight.w800,
  ),
),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    ),
  ),
  );
}



Widget _lightspecDivider() {
  return Container(
    width: 1,
    height: 82,
    color: Colors.black12,
  );
}

  Widget _lightspec({
  required IconData icon,
  required String value,
  required String title,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.red,
          size: 17,
        ),
      ),

      const SizedBox(height: 5),

      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),

      const SizedBox(height: 1),

      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

  Widget _specDivider() {
    return Container(
      width: 1,
      height: 55,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

// ============================================================
// CAR COLOR
// ============================================================

class CarColor {
  final String id;
  final String nameAr;
  final String nameEn;
  final int colorValue;
  // صورة السيارة باللون ده تحديدًا (لو موجودة)
  final String? image;

  const CarColor({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.colorValue,
    this.image,
  });

  // بيحول صف جاي من جدول colors في Supabase لكائن CarColor
  factory CarColor.fromMap(Map<String, dynamic> map) {
    final rawValue = (map['color_value'] as int?) ?? 0xFFFFFF;
    return CarColor(
      id: map['id'].toString(),
      nameAr: (map['name_ar'] ?? '') as String,
      nameEn: (map['name_en'] ?? '') as String,
      // بنضيف قناة الشفافية (alpha) لأن القيمة في القاعدة مخزنة من غيرها
      colorValue: 0xFF000000 | rawValue,
    );
  }
}

// ============================================================
// CAR COLORS CACHE (loaded from Supabase per car)
// ============================================================
// بتخزن الألوان المتاحة لكل سيارة حسب الـ id بتاعها
Map<int, List<CarColor>> carColorsCache = {};

// بتجيب الألوان المتاحة لسيارة واحدة من car_color_availability + colors
Future<List<CarColor>> fetchColorsForCar(int carId) async {
  try {
    final response = await Supabase.instance.client
        .from('car_color_availability')
        .select('color_id, is_available, colors(id, name_ar, name_en, color_value)')
        .eq('car_id', carId)
        .eq('is_available', true);

    return (response as List)
        .where((row) => row['colors'] != null)
        .map((row) => CarColor.fromMap(row['colors'] as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل ألوان السيارة $carId: $e');
    return [];
  }
}

// بتجيب ألوان كل السيارات دفعة واحدة (طلب واحد بس، مش طلب لكل سيارة)
Future<void> loadColorsForCars(List<Car> carsList) async {
  try {
    final response = await Supabase.instance.client
        .from('car_color_availability')
        .select('car_id, color_id, is_available, image, colors(id, name_ar, name_en, color_value)')
        .eq('is_available', true);

    final Map<int, List<CarColor>> grouped = {};

    for (final row in (response as List)) {
      final map = row as Map<String, dynamic>;
      final carId = map['car_id'] as int?;
      final colorData = map['colors'];
      if (carId == null || colorData == null) continue;

      final baseColor = CarColor.fromMap(colorData as Map<String, dynamic>);
      final colorImage = map['image'] as String?;
      final color = CarColor(
        id: baseColor.id,
        nameAr: baseColor.nameAr,
        nameEn: baseColor.nameEn,
        colorValue: baseColor.colorValue,
        image: (colorImage != null && colorImage.trim().isNotEmpty)
            ? colorImage.trim()
            : null,
      );
      grouped.putIfAbsent(carId, () => []).add(color);
    }

    carColorsCache = grouped;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل الألوان: $e');
  }
}

// ============================================================
// CAR IMAGES CACHE (loaded from Supabase, bulk query)
// ============================================================
// بتخزن كل صور معرض كل سيارة حسب الـ id بتاعها
Map<int, List<String>> carImagesCache = {};

// بتجيب صور كل السيارات دفعة واحدة (طلب واحد بس)
Future<void> loadImagesForCars(List<Car> carsList) async {
  try {
    final response = await Supabase.instance.client
        .from('car_images')
        .select('car_id, image');

    final Map<int, List<String>> grouped = {};

    for (final row in (response as List)) {
      final map = row as Map<String, dynamic>;
      final carId = map['car_id'] as int?;
      final image = map['image'] as String?;
      if (carId == null || image == null || image.isEmpty) continue;

      grouped.putIfAbsent(carId, () => []).add(image);
    }

    carImagesCache = grouped;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل صور المعرض: $e');
  }
}
const List<CarColor> carColorLibrary = [
  CarColor(
    id: 'white',
    nameAr: 'أبيض',
    nameEn: 'White',
    colorValue: 0xFFFFFFFF,
  ),

  CarColor(
    id: 'pearl_white',
    nameAr: 'أبيض لؤلؤي',
    nameEn: 'Pearl White',
    colorValue: 0xFFF5F5F0,
  ),

  CarColor(
    id: 'black',
    nameAr: 'أسود',
    nameEn: 'Black',
    colorValue: 0xFF000000,
  ),

  CarColor(
    id: 'silver',
    nameAr: 'فضي',
    nameEn: 'Silver',
    colorValue: 0xFFC0C0C0,
  ),

  CarColor(
    id: 'gray',
    nameAr: 'رمادي',
    nameEn: 'Gray',
    colorValue: 0xFF808080,
  ),

  CarColor(
    id: 'blue',
    nameAr: 'أزرق',
    nameEn: 'Blue',
    colorValue: 0xFF2196F3,
  ),

  CarColor(
    id: 'navy',
    nameAr: 'كحلي',
    nameEn: 'Navy Blue',
    colorValue: 0xFF0B1F3A,
  ),

  CarColor(
    id: 'red',
    nameAr: 'أحمر',
    nameEn: 'Red',
    colorValue: 0xFFF44336,
  ),

  CarColor(
    id: 'burgundy',
    nameAr: 'نبيتي',
    nameEn: 'Burgundy',
    colorValue: 0xFF800020,
  ),

  CarColor(
    id: 'brown',
    nameAr: 'بني',
    nameEn: 'Brown',
    colorValue: 0xFF795548,
  ),

  CarColor(
    id: 'beige',
    nameAr: 'بيج',
    nameEn: 'Beige',
    colorValue: 0xFFD8C3A5,
  ),

  CarColor(
    id: 'gold',
    nameAr: 'ذهبي',
    nameEn: 'Gold',
    colorValue: 0xFFD4AF37,
  ),

  CarColor(
    id: 'green',
    nameAr: 'أخضر',
    nameEn: 'Green',
    colorValue: 0xFF4CAF50,
  ),

  CarColor(
    id: 'orange',
    nameAr: 'برتقالي',
    nameEn: 'Orange',
    colorValue: 0xFFFF9800,
  ),

  CarColor(
    id: 'yellow',
    nameAr: 'أصفر',
    nameEn: 'Yellow',
    colorValue: 0xFFFFEB3B,
  ),

  CarColor(
    id: 'bronze',
    nameAr: 'برونزي',
    nameEn: 'Bronze',
    colorValue: 0xFFCD7F32,
  ),
];

// ============================================================
// CAR MODEL
// ============================================================

class Car {
  final int? id;
  final String name;
  final String brand;
  final String category;
  final String year;
  final String price;

  

  final String image;
  final List<String> images;
  final String description;

  // ==========================================================
  // BASIC SPECIFICATIONS
  // ==========================================================

  final String engine;
  final String transmission;
  final String fuel;
  final String seats;
  final String drive;

  // ==========================================================
  // DIMENSIONS
  // ==========================================================

  final String carLength;
  final String carWidth;
  final String carHeight;
  final String wheelbase;
  final String trunkCapacity;

  // ==========================================================
  // EXTRA DRIVING SPECS
  // ==========================================================

  final String horsepower;
  final String torque;
  final String fuelTank;
  final String fuelConsumption;

  // ==========================================================
  // FEATURES
  // ==========================================================

  final String infotainment;
  final String sunroof;
  final String cameraSensors;
  final String wirelessCharger;

  // ==========================================================
  // SAFETY
  // ==========================================================

  final String airbags;
  final String absSystem;

  // ==========================================================
  // MASTER SPECIFICATIONS
  // ==========================================================

  final List<String> specifications;

  // ==========================================================
  // OPTIONS
  // ==========================================================

  final List<String> options;

  // ==========================================================
  // AVAILABLE COLORS
  // ==========================================================

  final List<String> availableColorIds;
  final Map<String, String> colorImages;
  // ==========================================================
  // OFFER
  // ==========================================================

  final bool isOffer;
  final String oldPrice;

  const Car({
     this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.year,
    required this.price,
    
    
    required this.image,
    this.images = const [],
    required this.description,

    // Basic specifications
    this.engine = '1.5L',
    this.transmission = 'أوتوماتيك',
    this.fuel = 'بنزين',
    this.seats = '5',
    this.drive = 'دفع أمامي',

    // Dimensions
    this.carLength = '',
    this.carWidth = '',
    this.carHeight = '',
    this.wheelbase = '',
    this.trunkCapacity = '',

    // Extra driving specs
    this.horsepower = '',
    this.torque = '',
    this.fuelTank = '',
    this.fuelConsumption = '',

    // Features
    this.infotainment = '',
    this.sunroof = '',
    this.cameraSensors = '',
    this.wirelessCharger = '',

    // Safety
    this.airbags = '',
    this.absSystem = '',

    
    // Master specifications
    this.specifications = const [],

    // Options
    this.options = const [],

   // Colors
  this.availableColorIds = const [],
  this.colorImages = const {},

    // Offer
    this.isOffer = false,
    this.oldPrice = '',
  });

  // ==========================================================
  // FROM SUPABASE
  // ==========================================================
  // بيحول صف (row) جاي من جدول cars في Supabase لكائن Car
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      brand: (map['brand'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      year: (map['year'] ?? '') as String,
      price: (map['price'] ?? '') as String,
      image: (map['image'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      engine: (map['engine'] ?? '1.5L') as String,
      transmission: (map['transmission'] ?? 'أوتوماتيك') as String,
      fuel: (map['fuel'] ?? 'بنزين') as String,
      seats: (map['seats'] ?? '5') as String,
      drive: (map['drive'] ?? 'دفع أمامي') as String,
      carLength: (map['car_length'] ?? '') as String,
      carWidth: (map['car_width'] ?? '') as String,
      carHeight: (map['car_height'] ?? '') as String,
      wheelbase: (map['wheelbase'] ?? '') as String,
      trunkCapacity: (map['trunk_capacity'] ?? '') as String,
      horsepower: (map['horsepower'] ?? '') as String,
      torque: (map['torque'] ?? '') as String,
      fuelTank: (map['fuel_tank'] ?? '') as String,
      fuelConsumption: (map['fuel_consumption'] ?? '') as String,
      infotainment: (map['infotainment'] ?? '') as String,
      sunroof: (map['sunroof'] ?? '') as String,
      cameraSensors: (map['camera_sensors'] ?? '') as String,
      wirelessCharger: (map['wireless_charger'] ?? '') as String,
      airbags: (map['airbags'] ?? '') as String,
      absSystem: (map['abs_system'] ?? '') as String,
      isOffer: (map['is_offer'] ?? false) as bool,
      oldPrice: (map['old_price'] ?? '') as String,
    );
  }
}

// ============================================================
// LOAD CARS FROM SUPABASE
// ============================================================
// بتجيب السيارات المتاحة من الجدول وتحدّث القايمة العامة cars
// لو حصل أي خطأ (زي مفيش إنترنت)، القايمة الثابتة تحت بتفضل شغالة كـ احتياطي
Future<void> loadCarsFromSupabase() async {
  try {
    final response = await Supabase.instance.client
        .from('cars')
        .select()
        .eq('is_available', true);

    debugPrint('AUTO_ONE_DEBUG: raw response = $response');

    final fetched = (response as List)
        .map((row) => Car.fromMap(row as Map<String, dynamic>))
        .toList();

    debugPrint('AUTO_ONE_DEBUG: fetched ${fetched.length} cars from Supabase');

    if (fetched.isNotEmpty) {
      cars = fetched;
      debugPrint('AUTO_ONE_DEBUG: cars list replaced successfully');
      await Future.wait([
        loadColorsForCars(fetched),
        loadImagesForCars(fetched),
      ]);
      debugPrint('AUTO_ONE_DEBUG: colors loaded for ${carColorsCache.length} cars, images loaded for ${carImagesCache.length} cars');
    } else {
      debugPrint('AUTO_ONE_DEBUG: fetched list was empty, keeping fallback data');
    }
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: EXCEPTION while loading cars: $e');
  }
}

// ============================================================
// REAL INVENTORY (fallback / initial data)
// ============================================================

List<Car> cars = [
  // ============================================================
  // TOYOTA - 2
  // ============================================================

  Car(
  id: 1,
  name: 'يارس واي بلس',
  brand: 'Toyota',
  category: 'TOYOTA',
  year: '2026',
  price: '66,550 ﷼',
  image: 'assets/youssefcar4.jpg',
  colorImages: {
  'white': 'assets/yaris_white.jpeg',
  'black': 'assets/yaris_black.jpeg',
  'gray': 'assets/yaris_gray.jpeg',
},
  description: 'Toyota Yaris من مخزون AUTO ONE.',
  seats: '7',

  availableColorIds: [
  'white',
  'black',
  'gray',
  ],
),

  Car(
    id: 2,
    name: 'تويوتا كورولا 2.0 استاندر',
    brand: 'Toyota',
    category: 'TOYOTA',
    year: '2026',
    price: '80,000 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Toyota Corolla 2.0.',
  ),

  // ============================================================
  // HYUNDAI - 18
  // ============================================================

  Car(
    id: 3,
    name: 'اكسنت 1.5 فليت جنوط',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '65285 ريال ',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Accent 1.5.',
  ),

  Car(
    id: 4,
    name: 'اكسنت 1.5 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '69425 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Accent 1.5 Smart.',
  ),

  Car(
    id: 5,
    name: 'النترا 1.5 سمارت  ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '77,475 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 1.5 Smart.',
  ),

  Car(
    id: 6,
    name: 'النترا سمارت 2000 سي سي  ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '82,650 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 2.0 Smart.',
  ),

  Car(
    id: 7,
    name: 'النترا 2.0 سمارت بلس ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '82,650 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 2.0 Smart Plus.',
  ),

  Car(
    id: 8,
    name: 'النترا 2.0 كمفورت ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '90,700 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 2.0 Comfort.',
  ),

  Car(
    id: 9,
    name: 'كونا 2.0 كمفورت توتون',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '87,250 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Kona 2.0 Comfort.',
  ),

  Car(
    id: 10,
    name: 'كونا 2.0 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '84,375 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Kona 2.0 Smart.',
  ),

  Car(
    id: 11,
    name: 'كونا 2.0 كمفورت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '93,575 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Kona 2.0 Comfort.',
  ),

  Car(
    id: 12,
    name: 'كريتا 1.5 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '76,325 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta 1.5 Smart.',
  ),

  Car(
    id: 13,
    name: 'كريتا 1.5 كمفورت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '84,950',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta 1.5 Comfort.',
  ),

  Car(
    id: 14,
    name: 'كريتا 2.0 جراند سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '85,525 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta Grand Smart 2.0.',
  ),

  Car(
    id: 15,
    name: 'كريتا جراند سمارت 2000 سي سي',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta Grand Smart 2.0.',
  ),

  Car(
    id: 16,
    name: 'كريتا جراند كمفورت 2000 سي سي',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta Grand Comfort 2.0.',
  ),

  Car(
    id: 17,
    name: 'توسان 1.6 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Tucson 1.6 Smart.',
  ),

  Car(
    id: 18,
    name: 'توسان 1.6 سمارت لون تون',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Tucson 1.6 Smart.',
  ),

  Car(
    id: 19,
    name: 'سوناتا 2.5 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Sonata 2.5 Smart.',
  ),

  Car(
    id: 20,
    name: 'سوناتا 2.5 كمفورت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Sonata 2.5 Comfort.',
  ),

  // ============================================================
  // KIA - 24
  // ============================================================

  Car(
    id: 21,
    name: 'بيجاس 1.4 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Pegas 1.4.',
  ),

  Car(
    id: 22,
    name: 'K3 1.6 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K3 1.6.',
  ),

  Car(
    id: 23,
    name: 'K4 1.6 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K4 1.6 GL.',
  ),

  Car(
    id: 24,
    name: 'K4 1.6 استاندر GL بلس بصمة',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K4 1.6 GL Plus.',
  ),

  Car(
    id: 25,
    name: 'K4 2.0 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K4 2.0.',
  ),

  Car(
    id: 26,
    name: 'K5 2.0 2500 بصمة جي في فتحة سقف',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5.',
  ),

  Car(
    id: 27,
    name: 'K5 2.0 2500 بصمة GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5 GL.',
  ),

  Car(
    id: 28,
    name: 'K5 2.0 2500 بصمة نصف فل GLS لون احمر',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5 GLS.',
  ),

  Car(
    id: 29,
    name: 'K5 2.0 2500 بصمة نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5 GLS.',
  ),

  Car(
    id: 30,
    name: 'K8 1.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K8 1.5.',
  ),

  Car(
    id: 31,
    name: 'Sonet 1.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet 1.5.',
  ),

  Car(
    id: 32,
    name: 'Sonet 1.5 GL كامل بدون فتحة',
    brand: 'Kia',
    category: 'KIA',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet 1.5.',
  ),

  Car(
    id: 33,
    name: 'Sonet 1.5 GL كامل بدون فتحة',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet 1.5.',
      specifications: [
    'محرك 2.5 لتر',
    'قير أوتوماتيك',
    'بنزين',
    '5 مقاعد',
    'دفع أمامي',
  ],
  ),

  Car(
    id: 34,
    name: 'Sonet 1.5 GLS فل كامل فتحة سقف',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet GLS.',
  ),

  Car(
    id: 36,
    name: 'سيلتوس 1.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Seltos 1.5.',
  ),

  Car(
    id: 37,
    name: 'سيلتوس 1.5 نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Seltos GLS.',
  ),

  Car(
    id: 38,
    name: 'كارينز 1.5 استاندر شكل جديد GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carens 1.5.',
  ),

  Car(
    id: 39,
    name: 'كارينز 1.5 نصف فل شكل جديد GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carens GLS.',
  ),

  Car(
    id: 40,
    name: 'سورينتو 1.6 هايبرد استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Sorento Hybrid.',
  ),

  Car(
    id:41,
    name: 'سورينتو 1.6 هايبرد نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Sorento Hybrid GLS.',
  ),

  Car(
    id: 42,
    name: 'كرنفال 3.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carnival 3.5.',
  ),

  Car(
    id: 43,
    name: 'كرنفال 3.5 نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carnival GLS.',
  ),

  Car(
    id: 44,
    name: 'تيلورايد 3.8 توب كراسي منفصلة DCM داش كام',
    brand: 'Kia',
    category: 'KIA',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Telluride 3.8.',
  ),

  Car(
    id: 45,
    name: 'تيلورايد 3.8 4x4 GLS-MID',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Telluride 3.8 4x4.',
  ),

  // ============================================================
  // NISSAN - 11
  // ============================================================

  Car(
    id: 46,
    name: 'نيسان ماجنيت استاندر',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Magnite.',
  ),

  Car(
    id: 47,
    name: 'ماجنيت نصف فل SV',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Magnite SV.',
  ),

  Car(
    id: 48,
    name: 'اكستريل 7 مقاعد استاندر 2.5 دفع ثنائي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 7 Seats.',
  ),

  Car(
    id: 49,
    name: 'اكستريل 5 مقاعد استاندر 2.5 دفع رباعي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 5 Seats AWD.',
  ),

  Car(
    id: 50,
    name: 'اكستريل 7 مقاعد استاندر 2.5 دفع ثنائي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 7 Seats.',
  ),

  Car(
    id: 51,
    name: 'اكستريل 5 مقاعد استاندر 2.5 دفع رباعي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 5 Seats AWD.',
  ),

  Car(
    id: 52,
    name: 'التيما 2.5L S',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Altima 2.5L S.',
  ),

  Car(
    id: 53,
    name: 'التيما 2.5L SV',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Altima 2.5L SV.',
  ),

  Car(
    id: 54,
    name: 'نصف فل PATROL V6 SE T 2 3.8T 9AT',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Patrol V6.',
  ),

  Car(
    id: 55,
    name: 'نصف فل PATROL V6 SE T 2 3.8T 9AT',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Patrol V6..black ',
  ),

  Car(
    id: 56,
    name: 'باترول بلاتينيوم  تيربو 3.8',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Patrol Platinum.',
  ),

  // ============================================================
  // FORD - 8
  // ============================================================

  Car(
    id: 57,
    name: 'تيريتوري 1.8 ايمبيتي',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Territory 1.8.',
  ),

  Car(
    id: 58,
    name: 'تيريتوري 1.8 ترند',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Territory Trend.',
  ),

  Car(
    id: 59,
    name: 'تيريتوري 1.8 تيتانيوم',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Territory Titanium.',
  ),

  Car(
    id: 60,
    name: 'تورس 2.0 ترند الشكل الجديد',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Taurus Trend.',
  ),

  Car(
    id: 61,
    name: 'تورس 2.0 تيتانيوم الشكل الجديد',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Taurus Titanium.',
  ),

  Car(
    id: 62,
    name: 'فورد اكسبلور XLS بنزين 4x4',
    brand: 'Ford',
    category: 'FORD',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Explorer XLS.',
  ),

  Car(
    id: 63,
    name: 'فورد اكسبلور XLS بنزين 4x4',
    brand: 'Ford',
    category: 'FORD',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Explorer XLS.',
  ),

  Car(
    id: 64,
    name: 'فورد اكسبلور XLT بنزين 4x4',
    brand: 'Ford',
    category: 'FORD',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Explorer XLT.',
  ),

  // ============================================================
  // BAIC - 6
  // ============================================================

  Car(
    id: 65,
    name: 'بايك U5 لاكشري',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC U5 Luxury.',
  ),

  Car(
    id: 66,
    name: 'بايك U5 لاكشري فتحة سقف',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC U5 Luxury Sunroof.',
  ),

  Car(
    id: 67,
    name: 'بايك X35 ستاندر',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X35.',
  ),

  Car(
    id: 68,
    name: 'بايك X35 فل لاكشري',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X35 Luxury.',
  ),

  Car(
    id: 69,
    name: 'بايك X55 كمفورت',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X55 Comfort.',
  ),

  Car(
    id: 70,
    name: 'بايك X75 كمفورت',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2027',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X75 Comfort.',
  ),

  // ============================================================
  // BYD - 2
  // ============================================================

  Car(
    id: 71,
    name: 'Song Plus FWD',
    brand: 'BYD',
    category: 'BYD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'BYD Song Plus FWD.',
  ),

  Car(
    id: 72,
    name: 'Song Plus AWD',
    brand: 'BYD',
    category: 'BYD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'BYD Song Plus AWD.',
  ),

  // ============================================================
  // JETOUR - 12
  // ============================================================

  Car(
    id: 73,
    name: 'X50 بريميوم',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour X50 Premium.',
  ),

  Car(
    id: 74,
    name: 'JETOUR X70 Comfort 7 Seats',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour X70 Comfort.',
  ),

  Car(
    id: 75,
    name: 'JETOUR X70 Lux 7 Seats',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour X70 Lux.',
  ),

  Car(
    id: 76,
    name: 'Dashing 1600 LUX',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour Dashing 1600 LUX.',
  ),

  Car(
    id: 77,
    name: 'جيتور T1 كمفورت 2.0',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T1 Comfort.',
  ),

  Car(
    id: 78,
    name: 'جيتور T1 لاكشري 2.0',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T1 Luxury.',
  ),

  Car(
    id: 79,
    name: 'جيتور T2 لاكشري 2.0 بلس اللون الاسود',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T2 Luxury.',
  ),

  Car(
    id: 80,
    name: 'جيتور T2 لاكشري 2.0',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2027',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T2 Luxury.',
  ),

  Car(
    id: 81,
    name: 'جيتور T2 لاكشري 2.0 اسود مط',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2027',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T2 Luxury.',
  ),

  Car(
    id: 82,
    name: 'جيتور G700 Comfort 7 Seats COM',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour G700 Comfort.',
  ),

  Car(
    id: 83,
    name: 'جيتور G700  LUX 6 مقاعد',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/g700lux1.jpeg',
            
    description: 'Jetour G700 LUX.',
  ),

  Car(
    id: 84,
    name: 'جيتور G700 Flagship 6 مقاعد',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour G700 Flagship.',
  ),

 
  // ============================================================
  // CHERY PRO - 5
  // ============================================================

  Car(
    id: 85,
    name: 'اريزو 5 كمفورت 1.5 سي سي',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Arrizo 5 Comfort.',
  ),

  Car(
    id: 86,
    name: 'تيجو 2 كمفورت 1.5 الشكل الجديد',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 2.',
  ),

  Car(

    id: 87,
    name: 'تيجو 4 1.5 كمفورت',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 4.',
  ),

  Car(
    id: 88,
    name: 'تيجو 4 1.5 فل كامل LUX',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 4 LUX.',
  ),

  Car(
    id: 89,
    name: 'تيجو 7 كمفورت 1.5 ',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 7 Pro Max.',
  ),

  // ============================================================
  // MG - 5
  // ============================================================

  Car(
    id: 90,
    name: 'MG 5 Standard 1.5 الشكل القديم',
    brand: 'MG',
    category: 'MG',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG 5 1.5 الشكل القديم.',
  ),

  Car(
    id: 91,
    name: 'MG 5 Standard 1.5 الشكل الجديد',
    brand: 'MG',
    category: 'MG',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG 5 1.5 الشكل الجديد.',
  ),

  Car(
    id: 92,
    name: 'MG 5 Comfort 1.5 الشكل الجديد',
    brand: 'MG',
    category: 'MG',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG 5 Comfort.',
  ),

  Car(
    id: 93,
    name: 'MG ZS 1.5 فل كامل',
    brand: 'MG',
    category: 'MG',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG ZS 1.5.',
  ),

  Car(
    id: 94,
    name: 'MG ZS 1.3 فل كامل Turbo',
    brand: 'MG',
    category: 'MG',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG ZS 1.3 Turbo.',
  ),

  // ============================================================
  // JELLY - 2
  // ============================================================

  Car(
    id: 95,
    name: 'او كافانجو 2.0 فل كامل',
    brand: 'Jelly',
    category: 'JELLY',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'Jelly Okavango.',
  ),
  

  Car(
    id:96,
    name: 'ستاريا 2.0 نصف فل',
    brand: 'Jelly',
    category: 'JELLY',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'Jelly Staria.',
  ),

  // ============================================================
  // RELY - 1
  // ============================================================

  Car(
    id: 97,
    name: 'Rely Comfort 2.3 4x4 ديزل',
    brand: 'RELY',
    category: 'RELY',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'Rely 2.3 Diesel 4x4.',
  ),

  // ============================================================
  // JAC - 7
  // ============================================================

  Car(
    id: 98,
    name: 'جاك 2.0 ديزل 4x4 استاندر',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC 2.0 Diesel 4x4.',
  ),

  Car(
    id: 99,
    name: 'جاك 2.0 ديزل 4x4 فل كامل',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC 2.0 Diesel 4x4 Full.',
  ),

  Car(
    id: 100,
    name: 'ام زوم GB',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Emzoom GB.',
  ),

  Car(
    id: 101,
    name: 'ام زوم GL بلس',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Emzoom GL Plus.',
  ),

  Car(id: 102,
    name: 'ام زوم سبورت بلس',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Emzoom Sport Plus.',
  ),

  Car(
    id: 103,
    name: 'امباو GE',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Empow GE.',
  ),

  Car(
    id: 104,
    name: 'جيت امباو R 2.0',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Empow R 2.0.',
  ),
];

// ============================================================
// CARS PAGE
// ============================================================

class CarsPage extends StatefulWidget {
  final bool isArabic;
  final String? initialBrand;
  final bool initialOffers;

  const CarsPage({
    super.key,
    required this.isArabic,
    this.initialBrand,
    this.initialOffers = false,
  });

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  String search = '';
  bool showOffers = false;

 String selectedBrand = 'ALL';

@override
void initState() {
  super.initState();

  selectedBrand = widget.initialBrand ?? 'ALL';
  showOffers = widget.initialOffers;
}
  String selectedType = 'ALL';
  String selectedCategory = 'ALL';
  String selectedModel = 'ALL';

  // فلترة السعر والترتيب
  double? minPrice;
  double? maxPrice;
  String sortOption = 'newest'; // newest, price_asc, price_desc

  final TextEditingController controller =
      TextEditingController();

  // ============================================================
  // NORMALIZE SEARCH
  // ============================================================

  String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _searchAlias(Car car) {
  final text = _normalize(
    [
      car.name,
      car.brand,
      car.category,
      car.year,
      car.description,
      _carType(car),
      _carCategory(car),
    ].join(' '),
  );

  final aliases = <String>[
    'جيتور jetour',
    'g700 جي 700',
    'x70 اكس 70',
    'x50 اكس 50',
    't1 تي 1',
    't2 تي 2',
    'dashing داشينج',

    'كيا kia',
    'سونيت sonet',
    'سيلتوس seltos',
    'سورينتو sorento',
    'كرنفال carnival',
    'تيلورايد telluride',

    'هيونداي hyundai',
    'توسان tucson',
    'كريتا creta',
    'كونا kona',
    'النترا elantra',
    'اكسنت accent',
    'سوناتا sonata',

    'نيسان nissan',
    'باترول patrol',
    'اكستريل xtrail x-trail',
    'التيما altima',
    'ماجنيت magnite',

    'فورد ford',
    'اكسبلور explorer',
    'تيريتوري territory',
    'تورس taurus',

    'بايك baic',
    'byd بي واي دي',
    'mg ام جي',
    'شيري chery',
    'gac جى اي سي',
    'تويوتا toyota',

    'كمفورت comfort',
    'لاكشري luxury lux',
    'بريميوم premium',
    'فلاجشيب flagship',
    'سمارت smart',
    'ستاندر standard',
    'استاندر standard',
  ];

  return '$text ${aliases.join(' ')}';
}
  // ============================================================
  // TYPE / FAMILY
  // ============================================================

  String _carType(Car car) {
    final name = _normalize(car.name);

    // JETOUR
    if (name.contains('g700')) return 'G700';
    if (name.contains('t2')) return 'T2';
    if (name.contains('t1')) return 'T1';
    if (name.contains('x70')) return 'X70';
    if (name.contains('x50')) return 'X50';
    if (name.contains('dashing')) return 'DASHING';

    // KIA
    if (name.contains('telluride') ||
        name.contains('تيلورايد')) {
      return 'TELLURIDE';
    }

    if (name.contains('carnival') ||
        name.contains('كرنفال')) {
      return 'CARNIVAL';
    }

    if (name.contains('sorento') ||
        name.contains('سورينتو')) {
      return 'SORENTO';
    }

    if (name.contains('carens') ||
        name.contains('كارينز')) {
      return 'CARENS';
    }

    if (name.contains('seltos') ||
        name.contains('سيلتوس')) {
      return 'SELTOS';
    }

    if (name.contains('sonet')) {
      return 'SONET';
    }

    if (name.contains('k8')) return 'K8';
    if (name.contains('k5')) return 'K5';
    if (name.contains('k4')) return 'K4';
    if (name.contains('k3')) return 'K3';

    if (name.contains('pegas') ||
        name.contains('بيجاس')) {
      return 'PEGAS';
    }

    // HYUNDAI
    if (name.contains('sonata') ||
        name.contains('سوناتا')) {
      return 'SONATA';
    }

    if (name.contains('tucson') ||
        name.contains('توسان')) {
      return 'TUCSON';
    }

    if (name.contains('creta') ||
        name.contains('كريتا')) {
      return 'CRETA';
    }

    if (name.contains('kona') ||
        name.contains('كونا')) {
      return 'KONA';
    }

    if (name.contains('elantra') ||
        name.contains('النترا')) {
      return 'ELANTRA';
    }

    if (name.contains('accent') ||
        name.contains('اكسنت')) {
      return 'ACCENT';
    }

    // NISSAN
    if (name.contains('patrol') ||
        name.contains('باترول')) {
      return 'PATROL';
    }

    if (name.contains('x-trail') ||
        name.contains('xtrail') ||
        name.contains('اكستريل')) {
      return 'X-TRAIL';
    }

    if (name.contains('altima') ||
        name.contains('التيما')) {
      return 'ALTIMA';
    }

    if (name.contains('magnite') ||
        name.contains('ماجنيت')) {
      return 'MAGNITE';
    }

    // FORD
    if (name.contains('explorer') ||
        name.contains('اكسبلور')) {
      return 'EXPLORER';
    }

    if (name.contains('territory') ||
        name.contains('تيريتوري')) {
      return 'TERRITORY';
    }

    if (name.contains('taurus') ||
        name.contains('تورس')) {
      return 'TAURUS';
    }

    // BAIC
    if (name.contains('u5')) return 'U5';
    if (name.contains('x75')) return 'X75';
    if (name.contains('x55')) return 'X55';
    if (name.contains('x35')) return 'X35';

    // BYD
    if (name.contains('song plus') ||
        name.contains('song')) {
      return 'SONG PLUS';
    }

    // CHERY
    if (name.contains('tiggo 7') ||
        name.contains('تيجو 7')) {
      return 'TIGGO 7';
    }

    if (name.contains('tiggo 4') ||
        name.contains('تيجو 4')) {
      return 'TIGGO 4';
    }

    if (name.contains('tiggo 2') ||
        name.contains('تيجو 2')) {
      return 'TIGGO 2';
    }

    if (name.contains('arrizo') ||
        name.contains('اريزو')) {
      return 'ARRIZO 5';
    }

    // MG
    if (name.contains('mg zs') ||
        name.contains('mg zs')) {
      return 'MG ZS';
    }

    if (name.contains('mg 5')) {
      return 'MG 5';
    }

    // JAC / RELY / JAC / JELLY
    if (name.contains('rely')) return 'RELY';

    if (name.contains('empow') ||
        name.contains('امباو')) {
      return 'EMPOW';
    }

    if (name.contains('emzoom') ||
        name.contains('ام زوم')) {
      return 'EMZOOM';
    }

    if (name.contains('okavango') ||
        name.contains('كافانجو')) {
      return 'OKAVANGO';
    }

    if (name.contains('staria') ||
        name.contains('ستاريا')) {
      return 'STARIA';
    }

    // TOYOTA
    if (name.contains('corolla') ||
        name.contains('كورولا')) {
      return 'COROLLA';
    }

    if (name.contains('yaris') ||
        name.contains('يارس')) {
      return 'YARIS';
    }

    // fallback
    return car.brand;
  }

  // ============================================================
  // CATEGORY / TRIM
  // ============================================================

  String _carCategory(Car car) {
    final name = _normalize(car.name);

    if (name.contains('comfort') ||
        name.contains('كمفورت')) {
      return 'COMFORT';
    }

    if (name.contains('lux') ||
        name.contains('luxury') ||
        name.contains('لاكشري')) {
      return 'LUX';
    }

    if (name.contains('premium') ||
        name.contains('بريميوم')) {
      return 'PREMIUM';
    }

    if (name.contains('flagship') ||
        name.contains('فلاجشيب')) {
      return 'FLAGSHIP';
    }

    if (name.contains('smart') ||
        name.contains('سمارت')) {
      return 'SMART';
    }

    if (name.contains('titanium') ||
        name.contains('تيتانيوم')) {
      return 'TITANIUM';
    }

    if (name.contains('trend') ||
        name.contains('ترند')) {
      return 'TREND';
    }

    if (name.contains('gls')) {
      return 'GLS';
    }

    if (name.contains('gl')) {
      return 'GL';
    }

    if (name.contains('standard') ||
        name.contains('استاندر') ||
        name.contains('ستاندر')) {
      return 'STANDARD';
    }

    if (name.contains('comfort')) {
      return 'COMFORT';
    }

    if (name.contains('sv')) return 'SV';
    if (name.contains('se')) return 'SE';
    if (name.contains('xlt')) return 'XLT';
    if (name.contains('xls')) return 'XLS';

    return 'OTHER';
  }

  // ============================================================
  // BRAND LIST
  // ============================================================

  List<String> get inventoryBrands {
    final values = cars
        .map((car) => car.brand)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // TYPE LIST
  // ============================================================

  List<String> get inventoryTypes {
    final values = cars
        .where(
          (car) =>
              selectedBrand == 'ALL' ||
              car.brand == selectedBrand,
        )
        .map(_carType)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // CATEGORY LIST
  // ============================================================

  List<String> get inventoryCategories {
    final values = cars
        .where(
          (car) =>
              (selectedBrand == 'ALL' ||
                  car.brand == selectedBrand) &&
              (selectedType == 'ALL' ||
                  _carType(car) == selectedType),
        )
        .map(_carCategory)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // MODEL / YEAR LIST
  // ============================================================

  List<String> get inventoryModels {
    final values = cars
        .where(
          (car) =>
              (selectedBrand == 'ALL' ||
                  car.brand == selectedBrand) &&
              (selectedType == 'ALL' ||
                  _carType(car) == selectedType) &&
              (selectedCategory == 'ALL' ||
                  _carCategory(car) == selectedCategory),
        )
        .map((car) => car.year)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // SEARCH + FILTERED CARS
  // ============================================================

  // بتحول نص السعر (زي "65,285") لرقم قابل للمقارنة
  double _parsePrice(String price) {
    final digits = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  List<Car> get filteredCars {
    final query = _normalize(search);

    final result = cars.where((car) {
      final searchableText = _searchAlias(car);

      final matchesSearch =
          query.isEmpty ||
          searchableText.contains(query);

      final matchesBrand =
          selectedBrand == 'ALL' ||
          car.brand == selectedBrand;

      final matchesType =
          selectedType == 'ALL' ||
          _carType(car) == selectedType;

      final matchesCategory =
          selectedCategory == 'ALL' ||
          _carCategory(car) == selectedCategory;

      final matchesModel =
          selectedModel == 'ALL' ||
          car.year == selectedModel;
          final matchesOffer =
    !showOffers || car.isOffer;

      final price = _parsePrice(car.price);
      final matchesMinPrice = minPrice == null || price >= minPrice!;
      final matchesMaxPrice = maxPrice == null || price <= maxPrice!;

     return matchesSearch &&
    matchesBrand &&
    matchesType &&
    matchesCategory &&
    matchesModel &&
    matchesOffer &&
    matchesMinPrice &&
    matchesMaxPrice;
    }).toList();

    switch (sortOption) {
      case 'price_asc':
        result.sort(
          (a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)),
        );
        break;
      case 'price_desc':
        result.sort(
          (a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)),
        );
        break;
      default:
        // الأحدث: نرتب حسب الـ id تنازليًا (الأحدث إضافة أولًا)
        result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    }

    return result;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCHABLE SELECT
  // ============================================================

  Future<String?> _openSearchSelect({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String selectedValue,
  }) async {
    String query = '';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final filteredItems = items.where((item) {
              if (item == 'ALL') return true;

              return _normalize(item).contains(
                _normalize(query),
              );
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    20,
              ),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height * 900,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      autofocus: true,
                      onChanged: (value) {
                        modalSetState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.search_rounded),
                        hintText: widget.isArabic
                            ? 'اكتب للبحث...'
                            : 'Type to search...',
                        filled: true,
                        fillColor:
                            const Color(0xfff6f6f6),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                widget.isArabic
                                    ? 'لا توجد نتائج مطابقة'
                                    : 'NO MATCHING RESULTS',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount:
                                  filteredItems.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const Divider(
                                height: 1,
                              ),
                              itemBuilder:
                                  (context, index) {
                                final item =
                                    filteredItems[index];

                                final displayValue =
                                    item == 'ALL'
                                        ? (widget.isArabic
                                            ? 'الكل'
                                            : 'ALL')
                                        : item;

                                return ListTile(
                                  title: Text(
                                    displayValue,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  trailing:
                                      item == selectedValue
                                          ? const Icon(
                                              Icons
                                                  .check_circle,
                                              color: Colors.red,
                                            )
                                          : null,
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                      item,
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
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilters(BuildContext context) {
    String tempBrand = selectedBrand;
    String tempType = selectedType;
    String tempCategory = selectedCategory;
    String tempModel = selectedModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            List<String> tempTypes = cars
                .where(
                  (car) =>
                      tempBrand == 'ALL' ||
                      car.brand == tempBrand,
                )
                .map(_carType)
                .toSet()
                .toList()
              ..sort();

            List<String> tempCategories = cars
                .where(
                  (car) =>
                      (tempBrand == 'ALL' ||
                          car.brand == tempBrand) &&
                      (tempType == 'ALL' ||
                          _carType(car) == tempType),
                )
                .map(_carCategory)
                .toSet()
                .toList()
              ..sort();

            List<String> tempModels = cars
                .where(
                  (car) =>
                      (tempBrand == 'ALL' ||
                          car.brand == tempBrand) &&
                      (tempType == 'ALL' ||
                          _carType(car) == tempType) &&
                      (tempCategory == 'ALL' ||
                          _carCategory(car) == tempCategory),
                )
                .map((car) => car.year)
                .toSet()
                .toList()
              ..sort();

            tempTypes = ['ALL', ...tempTypes];
            tempCategories = ['ALL', ...tempCategories];
            tempModels = ['ALL', ...tempModels];

            final canApply =
                tempBrand != 'ALL' &&
                tempType != 'ALL' &&
                tempCategory != 'ALL' &&
                tempModel != 'ALL';

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 10,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.isArabic
                          ? 'فلترة السيارات'
                          : 'FILTER CARS',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BRAND
                    InkWell(
                      onTap: () async {
                        final result =
                            await _openSearchSelect(
                          context: context,
                          title: widget.isArabic
                              ? 'الماركة'
                              : 'BRAND',
                          items: inventoryBrands,
                          selectedValue: tempBrand,
                        );

                        if (result == null) return;

                        modalSetState(() {
                          tempBrand = result;
                          tempType = 'ALL';
                          tempCategory = 'ALL';
                          tempModel = 'ALL';
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'الماركة'
                            : 'BRAND',
                        value: tempBrand == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر الماركة'
                                : 'SELECT BRAND')
                            : tempBrand,
                        enabled: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // TYPE
                    InkWell(
                      onTap: tempBrand == 'ALL'
                          ? null
                          : () async {
                              final result =
                                  await _openSearchSelect(
                                context: context,
                                title: widget.isArabic
                                    ? 'النوع'
                                    : 'TYPE',
                                items: tempTypes,
                                selectedValue: tempType,
                              );

                              if (result == null) return;

                              modalSetState(() {
                                tempType = result;
                                tempCategory = 'ALL';
                                tempModel = 'ALL';
                              });
                            },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'النوع'
                            : 'TYPE',
                        value: tempType == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر النوع'
                                : 'SELECT TYPE')
                            : tempType,
                        enabled: tempBrand != 'ALL',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CATEGORY
                    InkWell(
                      onTap:
                          tempType == 'ALL'
                              ? null
                              : () async {
                                  final result =
                                      await _openSearchSelect(
                                    context: context,
                                    title: widget.isArabic
                                        ? 'الفئة'
                                        : 'CATEGORY',
                                    items:
                                        tempCategories,
                                    selectedValue:
                                        tempCategory,
                                  );

                                  if (result == null) return;

                                  modalSetState(() {
                                    tempCategory = result;
                                    tempModel = 'ALL';
                                  });
                                },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'الفئة'
                            : 'CATEGORY',
                        value: tempCategory == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر الفئة'
                                : 'SELECT CATEGORY')
                            : tempCategory,
                        enabled: tempType != 'ALL',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // MODEL / YEAR
                    InkWell(
                      onTap:
                          tempCategory == 'ALL'
                              ? null
                              : () async {
                                  final result =
                                      await _openSearchSelect(
                                    context: context,
                                    title: widget.isArabic
                                        ? 'الموديل'
                                        : 'MODEL',
                                    items: tempModels,
                                    selectedValue:
                                        tempModel,
                                  );

                                  if (result == null) return;

                                  modalSetState(() {
                                    tempModel = result;
                                  });
                                },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'الموديل'
                            : 'MODEL',
                        value: tempModel == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر الموديل'
                                : 'SELECT MODEL')
                            : tempModel,
                        enabled: tempCategory != 'ALL',
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedBrand = 'ALL';
                                selectedType = 'ALL';
                                selectedCategory = 'ALL';
                                selectedModel = 'ALL';
                              });

                              Navigator.pop(context);
                            },
                            child: Text(
                              widget.isArabic
                                  ? 'إعادة تعيين'
                                  : 'RESET',
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: canApply
                                ? () {
                                    setState(() {
                                      selectedBrand =
                                          tempBrand;
                                      selectedType =
                                          tempType;
                                      selectedCategory =
                                          tempCategory;
                                      selectedModel =
                                          tempModel;
                                    });

                                    Navigator.pop(
                                      context,
                                    );
                                  }
                                : null,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red,
                              foregroundColor:
                                  Colors.white,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              disabledForegroundColor:
                                  Colors.grey.shade600,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 16,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                            child: Text(
                              canApply
                                  ? (widget.isArabic
                                      ? 'تطبيق الفلتر'
                                      : 'APPLY FILTER')
                                  : (widget.isArabic
                                      ? 'اختر الماركة والنوع والفئة والموديل'
                                      : 'SELECT BRAND, TYPE, CATEGORY & MODEL'),
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER BOX
  // ============================================================

  Widget _filterBox({
    required String title,
    required String value,
    required bool enabled,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xfffafafa),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? Colors.grey.shade300
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? Colors.black87
                          : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled
                  ? Colors.black54
                  : Colors.black26,
            ),
          ],
        ),
      ),
      
    );
   }
     @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Text(
            widget.isArabic
                ? 'سيارات المعرض'
                : 'OUR CARS',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.isArabic
                ? 'ابحث عن سيارتك واختر السيارة المناسبة'
                : 'SEARCH AND FIND YOUR PERFECT CAR',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              SizedBox(
             width: 360,
              child: Container(
                 height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: (value) {
                      setState(() {
                        search = value;
                      });
                    },
                    textAlign: widget.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: widget.isArabic
                          ? 'ابحث عن سيارة...'
                          : 'Search for a car...',
                      prefixIcon:
                          const Icon(Icons.search_rounded),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: () => _showFilters(context),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  widget.isArabic ? 'فلتر' : 'FILTER',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // SORT + PRICE RANGE
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortOption,
                    icon: const Icon(Icons.sort_rounded, size: 18),
                    items: [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text(
                          widget.isArabic ? 'الأحدث' : 'Newest',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text(
                          widget.isArabic
                              ? 'السعر: الأرخص أولًا'
                              : 'Price: Low to High',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text(
                          widget.isArabic
                              ? 'السعر: الأغلى أولًا'
                              : 'Price: High to Low',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => sortOption = value);
                    },
                  ),
                ),
              ),

              SizedBox(
                width: 130,
                height: 44,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'أقل سعر' : 'Min price',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      minPrice = double.tryParse(value);
                    });
                  },
                ),
              ),

              SizedBox(
                width: 130,
                height: 44,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'أعلى سعر' : 'Max price',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      maxPrice = double.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          LayoutBuilder(
  builder: (context, constraints) {
    int columns = 1;

    if (constraints.maxWidth >= 1400) {
      columns = 5;
    } else if (constraints.maxWidth >= 1100) {
      columns = 4;
    } else if (constraints.maxWidth >= 800) {
      columns = 2;
    } else {
      columns = 1;
    }

              if (filteredCars.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 55,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 60,
                        color: Colors.black26,
                      ),

                      const SizedBox(height: 18),

                      Text(
                        widget.isArabic
                            ? 'لم نجد سيارة مطابقة لبحثك'
                            : 'NO MATCHING CARS FOUND',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        widget.isArabic
                            ? 'جرّب تغيير البحث أو خيارات الفلتر.'
                            : 'Try changing your search or filter options.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 18),

                      HoverLift(
                        borderRadius: BorderRadius.circular(10),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              search = '';
                              controller.clear();
                              showOffers = false;
                              selectedBrand = 'ALL';
                              selectedType = 'ALL';
                              selectedCategory = 'ALL';
                              selectedModel = 'ALL';
                            });
                          },
                          icon: const Icon(
                            Icons.filter_alt_off_rounded,
                            size: 18,
                          ),
                          label: Text(
                            widget.isArabic
                                ? 'مسح الفلاتر والرجوع للمعرض الكامل'
                                : 'Clear filters',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: filteredCars.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final car = filteredCars[index];

                 return FeaturedCarCard(
  key: ValueKey(
    '${car.name}-${car.year}',
  ),
  car: car,
  isArabic: widget.isArabic,
);
                },
              );
            },
          ),

          const SizedBox(height: 20),
          AutoOneFooter(isArabic: widget.isArabic),
        ],
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

        return HoverLift(
          scale: 1.15,
          borderRadius: BorderRadius.circular(30),
          child: Material(
            color: isSelected ? Colors.blue : Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => toggleCompare(carId!),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isSelected
                      ? Icons.check_box_rounded
                      : Icons.add_box_outlined,
                  color: isSelected ? Colors.white : Colors.black45,
                  size: 15,
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
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
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
              color: Colors.black54,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: Colors.black26,
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
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black26,
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
    // COLUMN 1 — CONTACT & BRANCHES
    // ============================================================
    Widget contactColumn() {
      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          _columnTitle(isArabic ? 'تواصل معنا' : 'Contact Us'),
          const SizedBox(height: 12),
          _branchLine(
            isArabic ? 'جدة — حي الجوهرة' : 'Jeddah — Al Jawharah',
          ),
          _branchLine(
            isArabic ? 'جدة — حي الحمدانية' : 'Jeddah — Al Hamdaniyah',
          ),
          _branchLine(
            isArabic ? 'الرياض — حي القادسية' : 'Riyadh — Al Qadisiyah',
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment:
                isArabic ? WrapAlignment.end : WrapAlignment.start,
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

    // ============================================================
    // COLUMN 2 — QUICK LINKS
    // ============================================================
    Widget linksColumn(BuildContext context) {
      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          _columnTitle(isArabic ? 'روابط سريعة' : 'Quick Links'),
          const SizedBox(height: 8),
          _quickLink(context, isArabic ? 'الرئيسية' : 'Home'),
          _quickLink(context, isArabic ? 'تصفح السيارات' : 'Browse Cars'),
        ],
      );
    }

    // ============================================================
    // COLUMN 3 — LOGO & TAGLINE
    // ============================================================
    Widget logoColumn() {
      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          Image.asset(
            'assets/logo-autoone.png',
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 220,
            child: Text(
              isArabic
                  ? 'معرض سيارات موثوق، نوفّر لك أفضل السيارات بأسعار تنافسية وتجربة شراء سهلة.'
                  : 'A trusted car showroom offering the best cars at competitive prices.',
              textAlign: textAlign,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        color: kHeaderColor,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 700) {
                      // شاشة واسعة: 3 أعمدة جنب بعض
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: contactColumn()),
                          Expanded(child: linksColumn(context)),
                          Expanded(child: logoColumn()),
                        ],
                      );
                    }
                    // شاشة ضيقة: الأعمدة فوق بعض
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        logoColumn(),
                        const SizedBox(height: 26),
                        contactColumn(),
                        const SizedBox(height: 26),
                        linksColumn(context),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  height: 1,
                  color: Colors.black12,
                ),

                const SizedBox(height: 14),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _policyLink(
                      context,
                      isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                      PrivacyPolicyPage(isArabic: isArabic),
                    ),
                    _policyLink(
                      context,
                      isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                      TermsPage(isArabic: isArabic),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  isArabic
                      ? '© ${DateTime.now().year} AUTO ONE — جميع الحقوق محفوظة'
                      : '© ${DateTime.now().year} AUTO ONE — All rights reserved',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRIVACY POLICY PAGE
// ============================================================
class PrivacyPolicyPage extends StatelessWidget {
  final bool isArabic;

  const PrivacyPolicyPage({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final content = isArabic
        ? '''نحن في AUTO ONE نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.

**البيانات اللي بنجمعها**
لما تعملي حجز، بنجمع اسمك، رقم جوالك، مدينتك، ووسيلة تواصل إضافية (واتساب أو إيميل) عشان نقدر نتواصل معاكِ بخصوص حجزك.

**استخدام البيانات**
البيانات دي بتُستخدم فقط لمتابعة طلب الحجز والتواصل معاكِ، ومش بيتم مشاركتها مع أي جهة خارجية.

**حماية البيانات**
بياناتك مخزنة بشكل آمن، وبنحرص على اتخاذ الإجراءات المناسبة لحمايتها من أي وصول غير مصرح به.

**التواصل**
لأي استفسار عن خصوصية بياناتك، تقدري تتواصلي معانا عبر وسائل التواصل الموجودة في التطبيق.

هذا النص عام ويُفضّل مراجعته وتخصيصه حسب طبيعة نشاطك التجاري.'''
        : '''At AUTO ONE, we respect your privacy and are committed to protecting your personal data.

**Data we collect**
When you make a booking, we collect your name, phone number, city, and an additional contact method (WhatsApp or email) so we can reach you about your booking.

**How we use your data**
This data is used only to process your booking request and contact you, and is never shared with third parties.

**Data protection**
Your data is stored securely, and we take reasonable measures to protect it from unauthorized access.

**Contact**
For any questions about your data privacy, you can reach us through the contact methods available in the app.

This is generic starter text — please review and customize it to match your actual business practices.''';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TERMS & CONDITIONS PAGE
// ============================================================
class TermsPage extends StatelessWidget {
  final bool isArabic;

  const TermsPage({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final content = isArabic
        ? '''باستخدامك تطبيق AUTO ONE، فإنك توافقين على الشروط والأحكام التالية.

**طلبات الحجز**
الحجز عبر التطبيق هو طلب أولي لحجز السيارة، ولا يعتبر تعاقدًا نهائيًا إلا بعد تأكيده من فريق AUTO ONE.

**دقة البيانات**
يجب إدخال بيانات صحيحة (الاسم، رقم الجوال، وسيلة التواصل) عند الحجز، لضمان قدرتنا على التواصل معاكِ.

**الأسعار والتوفر**
الأسعار وتوفر السيارات المعروضة في التطبيق قابلة للتغيير، وسيتم تأكيد التفاصيل النهائية عند التواصل معاكِ.

**التعديل والإلغاء**
نحتفظ بالحق في قبول أو رفض أي طلب حجز حسب توفر السيارة.

هذا النص عام ويُفضّل مراجعته مع مختص قانوني وتخصيصه حسب طبيعة نشاطك التجاري.'''
        : '''By using the AUTO ONE app, you agree to the following terms and conditions.

**Booking requests**
A booking made through the app is an initial request and is not considered final until confirmed by the AUTO ONE team.

**Accuracy of information**
You must provide accurate details (name, phone number, contact method) when booking, so we can reach you.

**Pricing and availability**
Prices and availability shown in the app are subject to change, and final details will be confirmed when we contact you.

**Modification and cancellation**
We reserve the right to accept or decline any booking request based on car availability.

This is generic starter text — please review it with a legal professional and customize it to your business.''';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'الشروط والأحكام' : 'Terms & Conditions'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
                    car.name,

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

  final Widget image = path.startsWith('http')
      ? Image.network(
          path,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          errorBuilder: effectiveErrorBuilder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const ShimmerBox();
          },
        )
      : Image.asset(
          path,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          errorBuilder: effectiveErrorBuilder,
        );

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

// ============================================================
// FULLSCREEN GALLERY (LIGHTBOX)
// ============================================================
// صفحة تعرض الصور بشاشة كاملة، وتقدري تقلبي بينها بالسحب،
// ومفيش أي عناصر تانية من الصفحة تلهيكي
class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (widget.images.length < 2) return;
    final newIndex = (currentIndex + 1) % widget.images.length;
    controller.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToPrevious() {
    if (widget.images.length < 2) return;
    final newIndex =
        currentIndex <= 0 ? widget.images.length - 1 : currentIndex - 1;
    controller.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: carImageAdaptive(
                    widget.images[index],
                    fit: BoxFit.contain,
                    showWatermark: false,
                  ),
                ),
              );
            },
          ),

          // NAVIGATION ARROWS
          if (widget.images.length > 1) ...[
            Positioned(
              top: 0,
              bottom: 0,
              left: 12,
              child: Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _goToNext,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 12,
              child: Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _goToPrevious,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // CLOSE BUTTON
          Positioned(
            top: 40,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // COUNTER (e.g. 2 / 5)
          if (widget.images.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class CarGallery extends StatefulWidget {
  final List<String> images;

  const CarGallery({
    super.key,
    required this.images,
  });

  @override
  State<CarGallery> createState() => _CarGalleryState();
}

class _CarGalleryState extends State<CarGallery> {
  late final PageController _controller;
  int currentIndex = 0;

 late final List<String> galleryImages = widget.images;

  @override
  void initState() {
    super.initState();

    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void nextImage() {
  if (galleryImages.length <= 1) return;

  setState(() {
    currentIndex =
        (currentIndex + 1) % galleryImages.length;
  });
}

  void previousImage() {
  if (galleryImages.length <= 1) return;

  setState(() {
    currentIndex =
        (currentIndex - 1 + galleryImages.length) %
            galleryImages.length;
  });
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
   Container(
  width: double.infinity,
  height: 520,

  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  ),

  clipBehavior: Clip.antiAlias,

  child: Stack(
    alignment: Alignment.center,

    children: [
      carImageAdaptive(
        galleryImages[currentIndex],
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),

      if (galleryImages.length > 1)
        Positioned(
          left: 15,
          child: _galleryArrow(
            icon: Icons.chevron_right,
            onTap: previousImage,
          ),
        ),

      if (galleryImages.length > 1)
        Positioned(
          right: 15,
          child: _galleryArrow(
            icon: Icons.chevron_left,
            onTap: nextImage,
          ),
        ),
    ],
  ),
),

        if (galleryImages.length > 1) ...[
          const SizedBox(height: 12),

          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: galleryImages.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected =
                    index == currentIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });

                    _controller.animateToPage(
                      index,
                      duration:
                          const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: carImageAdaptive(
                      galleryImages[index],
                      fit: BoxFit.cover,
                      showWatermark: false,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _galleryArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
class CarDetailsPage extends StatefulWidget {
  final Car car;
  final bool isArabic;

  const CarDetailsPage({
    super.key,
    required this.car,
    required this.isArabic,
  });

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}
  String getBrandLogo(String brand) {
  const logos = {
    'toyota': 'assets/brands/logo-toyota1.jpg',
    'kia': 'assets/brands/logo-kia1.jpg',
    'hyundai': 'assets/brands/logo-hyundai1.jpg',
    'nissan': 'assets/brands/logo-nissan1.jpg',
    'ford': 'assets/brands/logo-ford1.jpg',
    'baic': 'assets/brands/logo-baic1.jpg',
    'byd': 'assets/brands/logo-byd1.png',
    'mg': 'assets/brands/logo-mg1.jpg',
    'gac': 'assets/brands/logo-gac1.png',
    'chery': 'assets/brands/logo-chery1.png',
    'geely': 'assets/brands/logo-geely1.jpg',
    'rely': 'assets/brands/logo-rely1.jpg',
    'jac': 'assets/brands/logo-jac1.png',
    'jetour': 'assets/brands/logo-jetour1.png',
  };

  // مقارنة الاسم من غير حساسية لحالة الأحرف (كبيرة/صغيرة)
  return logos[brand.trim().toLowerCase()] ?? 'assets/logo-autoone.png';
}
  class _CarDetailsPageState extends State<CarDetailsPage> {
  String? selectedImage;

  Car get car => widget.car;
  bool get isArabic => widget.isArabic;

  // بندمج صورة السيارة الأساسية مع صور المعرض الإضافية من Supabase
  // (مع إزالة أي تكرار)، ولو مفيش صور من Supabase بنرجع للقايمة الثابتة
  List<String> get galleryImages {
    final extraImages = carImagesCache[car.id] ?? const <String>[];
    final seenImages = <String>{};
    return <String>[
      if (car.image.isNotEmpty) car.image,
      ...extraImages,
      ...car.images,
    ].where((img) => seenImages.add(img)).toList();
  }

  // بيروح للصورة اللي بعدها (اتجاه للأمام)
  void _goToNextImage() {
    final images = galleryImages;
    if (images.length < 2) return;
    setState(() {
      final currentIndex = images.indexOf(selectedImage ?? car.image);
      final newIndex = (currentIndex + 1) % images.length;
      selectedImage = images[newIndex];
    });
  }

  // بيرجع للصورة اللي قبلها
  void _goToPreviousImage() {
    final images = galleryImages;
    if (images.length < 2) return;
    setState(() {
      final currentIndex = images.indexOf(selectedImage ?? car.image);
      final newIndex =
          currentIndex <= 0 ? images.length - 1 : currentIndex - 1;
      selectedImage = images[newIndex];
    });
  }

  // بتستقبل ضغطات أسهم الكيبورد (يمين/شمال) للتنقل بين الصور
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPreviousImage();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToNextImage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _heroGalleryArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

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

  // بتعمل رابط مباشر للسيارة دي وتنسخه لحافظة الجهاز
  Future<void> _shareCarLink(BuildContext context) async {
    if (car.id == null) return;

    final baseUrl =
        '${html.window.location.origin}${html.window.location.pathname}';
    final link = '$baseUrl?car=${car.id}';

    await Clipboard.setData(ClipboardData(text: link));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '🔗 تم نسخ رابط السيارة!'
              : '🔗 Car link copied!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Widget _topInfoChip({
  required IconData icon,
  required String text,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xfff7f7f7),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.black54,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
   Widget _carSpec({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Container(
    width: 165,
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 17,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.black12,
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // ICON
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.red,
            size: 23,
          ),
        ),

        const SizedBox(height: 12),

        // TITLE
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 6),

        // VALUE
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

 Widget _detailSpec({
  required IconData icon,
  required String value,
  required String title,
}) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: Colors.red,
            size: 24,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _detailDivider() {
  return Container(
    width: 1,
    height: 62,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white12,
  );
}
@override
Widget build(BuildContext context) {
  return Focus(
    autofocus: true,
    onKeyEvent: _handleKeyEvent,
    child: Directionality(
    textDirection:
        isArabic ? TextDirection.rtl : TextDirection.ltr,

    child: Scaffold(
  backgroundColor: const Color(0xfff6f6f8),

 floatingActionButton: FloatingActionButton(
  onPressed: openWhatsApp,
  backgroundColor: Colors.green,
  shape: const CircleBorder(),
  child: const FaIcon(
    FontAwesomeIcons.whatsapp,
    color: Colors.white,
    size: 30,
  ),
),
floatingActionButtonLocation:
    FloatingActionButtonLocation.startFloat,

  appBar: AppBar(
        backgroundColor: kHeaderColor,
        foregroundColor: kHeaderTextColor,
        elevation: 0,

        title: Text(
          isArabic
              ? 'تفاصيل السيارة'
              : 'CAR DETAILS',

          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),

        actions: [
          IconButton(
            tooltip: isArabic ? 'مشاركة السيارة' : 'Share car',
            onPressed: () => _shareCarLink(context),
            icon: const Icon(Icons.share_outlined),
          ),
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1450,
            ),

          child: Column(
  children: [
const SizedBox(height: 24),

// ============================================================
// HERO CAR CARD - NEW
// ============================================================

Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    children: [
         ClipRRect(
  borderRadius: const BorderRadius.vertical(
    top: Radius.circular(24),
  ),
  child: SizedBox(
    width: double.infinity,
    height: 380,
    child: Stack(
      children: [
        // CAR IMAGE
Positioned.fill(
  child: Container(
    color: Colors.black,
    child: carImageAdaptive(
      selectedImage ?? car.image,
      fit: BoxFit.contain,
      showWatermark: false,
    ),
  ),
),

        // DARK GRADIENT
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),

       // NEW
Positioned(
  top: 20,
  left: 20,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Colors.black38,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      isArabic ? 'جديد' : 'NEW',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    ),
  ),
),

// BRAND LOGO
Positioned(
  top: 20,
  right: 20,
  child: Container(
    width: 58,
    height: 58,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Image.asset(
      getBrandLogo(car.brand),
      fit: BoxFit.contain,
    ),
  ),
),

// AUTO ONE WATERMARK - NEXT TO BRAND LOGO
Positioned(
  top: 20,
  right: 90,
  child: Opacity(
    opacity: 0.92,
    child: Container(
      width: 44,
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/logo-autoone.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) =>
            const SizedBox.shrink(),
      ),
    ),
  ),
),

// GALLERY NAVIGATION ARROWS
if (galleryImages.length > 1) ...[
  Positioned(
    top: 0,
    bottom: 0,
    left: 10,
    child: Center(
      child: _heroGalleryArrow(
        icon: Icons.chevron_right,
        onTap: () => _goToPreviousImage(),
      ),
    ),
  ),
  Positioned(
    top: 0,
    bottom: 0,
    right: 10,
    child: Center(
      child: _heroGalleryArrow(
        icon: Icons.chevron_left,
        onTap: () => _goToNextImage(),
      ),
    ),
  ),
],

// FULLSCREEN VIEW BUTTON (TRANSPARENT)
Positioned(
  bottom: 16,
  left: 0,
  right: 0,
  child: Center(
    child: Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          final startIndex = galleryImages.indexOf(
            selectedImage ?? car.image,
          );
          Navigator.of(context).push(
            smoothRoute(
              FullScreenGallery(
                images: galleryImages,
                initialIndex: startIndex < 0 ? 0 : startIndex,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isArabic ? 'شاهد الصور' : 'View photos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),

       
      ],
    ),
  ),
),
// ============================================================
// HERO INFO - WHITE AREA
// ============================================================

Container(
  width: double.infinity,
  padding: const EdgeInsets.fromLTRB(
    24,
    20,
    24,
    24,
  ),
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(24),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // MODEL + YEAR
      Row(
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  car.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${car.brand}  •  ${car.year}',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

         // PRICE + BOOKING
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      isArabic ? 'السعر' : 'PRICE',
      style: const TextStyle(
        color: Colors.black45,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),

    const SizedBox(height: 3),

    Text(
      car.price,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    ),

    const SizedBox(height: 10),

    CreativeBookButton(
      isArabic: isArabic,
      onTap: () {
        Navigator.push(
          context,
          smoothRoute(
            CarBookingPage(
              car: car,
              isArabic: isArabic,
            ),
          ),
        );
      },
    ),
  ],
),
        ],
      ),

     const SizedBox(height: 18),


const SizedBox(height: 18),


// COLORS TITLE
if ((carColorsCache[car.id] ?? const <CarColor>[]).isNotEmpty) ...[
  Text(
    isArabic
        ? 'الألوان المتاحة'
        : 'AVAILABLE COLORS',
    style: const TextStyle(
      color: Colors.black87,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
  ),

  const SizedBox(height: 10),

  Wrap(
    spacing: 10,
    runSpacing: 10,
    children: (carColorsCache[car.id] ?? const <CarColor>[]).map((color) {
      final image = color.image ?? car.colorImages[color.id];

      final isSelected =
          image != null && selectedImage == image;

      return InkWell(
        onTap: () {
          setState(() {
            selectedImage = image ?? car.image;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 36 : 32,
          height: isSelected ? 36 : 32,
          decoration: BoxDecoration(
            color: Color(color.colorValue),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Colors.red
                  : Colors.black12,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                )
              : null,
        ),
      );
    }).toList(),
  ),
],

// إغلاق Column الخاص بمعلومات السيارة
],
),
),
    ],
  ),
),

const SizedBox(height: 30),
// ============================================================
// CAR SPECIFICATIONS - AUTO ONE
// ============================================================

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: const Color(0xFF0B0B0B),
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // HEADER
      Row(
        children: [
          Container(
            width: 5,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'مواصفات السيارة'
                      : 'CAR SPECIFICATIONS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  isArabic
                      ? 'أهم المواصفات الفنية للسيارة'
                      : 'KEY TECHNICAL SPECIFICATIONS',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'AUTO ONE',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // SPECIFICATIONS
      LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth >= 1000;

          Widget specCard({
            required IconData icon,
            required String label,
            required String value,
          }) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.red, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          Widget specColumn(
            String title,
            List<Widget> cards, {
            bool twoPerRow = false,
          }) {
            if (cards.isEmpty) return const SizedBox.shrink();

            List<Widget> body;
            if (twoPerRow) {
              body = [];
              for (int i = 0; i < cards.length; i += 2) {
                if (i + 1 < cards.length) {
                  body.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[i]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[i + 1]),
                      ],
                    ),
                  );
                } else {
                  body.add(cards[i]);
                }
              }
            } else {
              body = cards;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...body,
              ],
            );
          }

          // ==================================================
          // القيادة
          // ==================================================
          final drivingCards = <Widget>[
            specCard(
              icon: Icons.compare_arrows_rounded,
              label: isArabic ? 'نظام الدفع' : 'DRIVE',
              value: car.drive,
            ),
            specCard(
              icon: Icons.speed_rounded,
              label: isArabic ? 'نوع المحرك' : 'ENGINE',
              value: car.engine,
            ),
            specCard(
              icon: Icons.settings_rounded,
              label: isArabic ? 'ناقل الحركة' : 'TRANSMISSION',
              value: car.transmission,
            ),
            specCard(
              icon: Icons.local_gas_station_rounded,
              label: isArabic ? 'الوقود' : 'FUEL',
              value: car.fuel,
            ),
            if (car.horsepower.isNotEmpty)
              specCard(
                icon: Icons.bolt_rounded,
                label: isArabic ? 'قوة المحرك (حصان)' : 'HORSEPOWER',
                value: car.horsepower,
              ),
            if (car.torque.isNotEmpty)
              specCard(
                icon: Icons.rotate_right_rounded,
                label: isArabic ? 'عزم الدوران' : 'TORQUE',
                value: car.torque,
              ),
            if (car.fuelTank.isNotEmpty)
              specCard(
                icon: Icons.oil_barrel_rounded,
                label: isArabic ? 'سعة خزان الوقود' : 'FUEL TANK',
                value: car.fuelTank,
              ),
            if (car.fuelConsumption.isNotEmpty)
              specCard(
                icon: Icons.local_gas_station_outlined,
                label: isArabic ? 'استهلاك الوقود' : 'FUEL CONSUMPTION',
                value: car.fuelConsumption,
              ),
          ];

          // ==================================================
          // التجهيزات والمزايا
          // ==================================================
          final featureCards = <Widget>[
            specCard(
              icon: Icons.event_seat_rounded,
              label: isArabic ? 'المقاعد' : 'SEATS',
              value: car.seats,
            ),
            if (car.infotainment.isNotEmpty)
              specCard(
                icon: Icons.tv_rounded,
                label: isArabic ? 'نظام الترفيه/الشاشة' : 'INFOTAINMENT',
                value: car.infotainment,
              ),
            if (car.sunroof.isNotEmpty)
              specCard(
                icon: Icons.wb_sunny_outlined,
                label: isArabic ? 'فتحة سقف' : 'SUNROOF',
                value: car.sunroof,
              ),
            if (car.cameraSensors.isNotEmpty)
              specCard(
                icon: Icons.camera_alt_rounded,
                label: isArabic
                    ? 'كاميرا خلفية + حساسات ركن'
                    : 'CAMERA & SENSORS',
                value: car.cameraSensors,
              ),
            if (car.wirelessCharger.isNotEmpty)
              specCard(
                icon: Icons.battery_charging_full_rounded,
                label: isArabic ? 'شاحن لاسلكي' : 'WIRELESS CHARGER',
                value: car.wirelessCharger,
              ),
          ];

          // ==================================================
          // الأبعاد
          // ==================================================
          final dimensionCards = <Widget>[
            if (car.carLength.isNotEmpty)
              specCard(
                icon: Icons.straighten_rounded,
                label: isArabic ? 'الطول' : 'LENGTH',
                value: car.carLength,
              ),
            if (car.carWidth.isNotEmpty)
              specCard(
                icon: Icons.straighten_rounded,
                label: isArabic ? 'العرض' : 'WIDTH',
                value: car.carWidth,
              ),
            if (car.carHeight.isNotEmpty)
              specCard(
                icon: Icons.straighten_rounded,
                label: isArabic ? 'الارتفاع' : 'HEIGHT',
                value: car.carHeight,
              ),
            if (car.wheelbase.isNotEmpty)
              specCard(
                icon: Icons.timeline_rounded,
                label: isArabic ? 'قاعدة العجلات' : 'WHEELBASE',
                value: car.wheelbase,
              ),
            if (car.trunkCapacity.isNotEmpty)
              specCard(
                icon: Icons.work_outline_rounded,
                label: isArabic ? 'سعة صندوق الأمتعة' : 'TRUNK CAPACITY',
                value: car.trunkCapacity,
              ),
          ];

          // ==================================================
          // الأمان
          // ==================================================
          final safetyCards = <Widget>[
            if (car.airbags.isNotEmpty)
              specCard(
                icon: Icons.airline_seat_recline_normal_rounded,
                label: isArabic ? 'عدد الوسائد الهوائية' : 'AIRBAGS',
                value: car.airbags,
              ),
            if (car.absSystem.isNotEmpty)
              specCard(
                icon: Icons.shield_outlined,
                label: isArabic ? 'نظام ABS' : 'ABS SYSTEM',
                value: car.absSystem,
              ),
          ];

          if (wide) {
            final columns = [
              specColumn(
                isArabic ? 'القيادة' : 'DRIVING',
                drivingCards,
              ),
              specColumn(
                isArabic ? 'التجهيزات والمزايا' : 'FEATURES',
                featureCards,
              ),
              specColumn(
                isArabic ? 'الأبعاد' : 'DIMENSIONS',
                dimensionCards,
              ),
              specColumn(
                isArabic ? 'الأمان' : 'SAFETY',
                safetyCards,
              ),
            ];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: columns[0]),
                const SizedBox(width: 20),
                Expanded(child: columns[1]),
                const SizedBox(width: 20),
                Expanded(child: columns[2]),
                const SizedBox(width: 20),
                Expanded(child: columns[3]),
              ],
            );
          }

          final mobileColumns = [
            specColumn(
              isArabic ? 'القيادة' : 'DRIVING',
              drivingCards,
              twoPerRow: true,
            ),
            specColumn(
              isArabic ? 'التجهيزات والمزايا' : 'FEATURES',
              featureCards,
              twoPerRow: true,
            ),
            specColumn(
              isArabic ? 'الأبعاد' : 'DIMENSIONS',
              dimensionCards,
              twoPerRow: true,
            ),
            specColumn(
              isArabic ? 'الأمان' : 'SAFETY',
              safetyCards,
              twoPerRow: true,
            ),
          ];

          return Column(
            children: [
              mobileColumns[0],
              const SizedBox(height: 20),
              mobileColumns[1],
              const SizedBox(height: 20),
              mobileColumns[2],
              const SizedBox(height: 20),
              mobileColumns[3],
            ],
          );
        },
      ),

      // DESCRIPTION (لو متسجل)
      if (car.description.trim().isNotEmpty) ...[
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'نبذة عن السيارة' : 'ABOUT THIS CAR',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                car.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  ),
),
// ============================================================
// SHOWROOM LOCATION - AUTO ONE
// ============================================================

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: const Color(0xFF0B0B0B),
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // HEADER
      Row(
        children: [
          Container(
            width: 5,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'موقع المعرض'
                      : 'SHOWROOM LOCATION',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  isArabic
                      ? 'تفضل بزيارة معرض AUTO ONE'
                      : 'VISIT AUTO ONE SHOWROOM',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // AUTO ONE BADGE
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'AUTO ONE',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 22),

      // LOCATION CARD
      GestureDetector(
        onTap: () async {
          final Uri url = Uri.parse(
            'https://maps.app.goo.gl/HL4SPud1pafGup8v8',
          );

          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          }
        },
        child: Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [

              // MAP ICON
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
  'assets/google_maps_pin.png',
  width: 65,
  height: 65,
  fit: BoxFit.contain,
),
              ),

              // OPEN MAP BUTTON
              Positioned(
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 18,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        isArabic
                            ? 'فتح موقع المعرض'
                            : 'OPEN SHOWROOM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 14),

      // LOCATION INFO
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'معرض AUTO ONE'
                        : 'AUTO ONE SHOWROOM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isArabic
                        ? 'اضغط لفتح الموقع على خرائط Google'
                        : 'Tap to open the location on Google Maps',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    ],
  ),
),

const SizedBox(height: 20),
AutoOneFooter(isArabic: isArabic),
       ],
       ),
          ),
        ),
      ),
    ),
  ),
  );
}

}

class CarBookingPage extends StatefulWidget {
    final Car car;
  final bool isArabic;

  const CarBookingPage({
    super.key,
    required this.car,
    required this.isArabic,
  });

  @override
  State<CarBookingPage> createState() => _CarBookingPageState();
}

class _CarBookingPageState extends State<CarBookingPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final notesController = TextEditingController();
  final whatsappController = TextEditingController();
  final emailController = TextEditingController();
  String? selectedColor;



  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    notesController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final car = widget.car;

    
    

    return Directionality(
      textDirection:
          isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),

        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          elevation: 0,
          title: Text(
            isArabic
                ? 'حجز السيارة'
                : 'CAR BOOKING',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [

                  // CAR
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(12),
                          child: carImageAdaptive(
                            car.image,
                            width: 100,
                            height: 75,
                            fit: BoxFit.cover,
                            showWatermark: false,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Text(
                                car.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                '${car.brand} • ${car.year}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                car.price,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // FORM
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [

                        Text(
                          isArabic
                              ? 'بيانات العميل'
                              : 'CUSTOMER INFORMATION',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 20),
                        // COLOR
Text(
  isArabic ? 'اللون المطلوب' : 'SELECTED COLOR',
  style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
  ),
),

const SizedBox(height: 10),

Wrap(
  spacing: 10,
  runSpacing: 10,
  children: (carColorsCache[car.id] ?? const <CarColor>[]).map((color) {
    final isSelected = selectedColor == color.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isSelected ? 38 : 32,
        height: isSelected ? 38 : 32,
        decoration: BoxDecoration(
          color: Color(color.colorValue),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.red
                : Colors.black12,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }).toList(),
),

const SizedBox(height: 20),

                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'الاسم'
                                : 'NAME',
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: phoneController,
                          keyboardType:
                              TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'رقم الجوال'
                                : 'PHONE NUMBER',
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'المدينة'
                                : 'CITY',
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          isArabic
                              ? 'وسيلة تواصل عشان نبلغك بحالة الحجز (املي واحدة على الأقل)'
                              : 'A way to reach you about your booking status (fill at least one)',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'رقم الواتساب'
                                : 'WHATSAPP NUMBER',
                            prefixIcon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'البريد الإلكتروني'
                                : 'EMAIL',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'ملاحظات'
                                : 'NOTES',
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
onPressed: () async {
  // تحققات إجبارية لكل الحقول، كل واحدة برسالة ولون مختلف
  final colorListForValidation = carColorsCache[car.id] ?? const <CarColor>[];

  if (nameController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '✍️ إحنا لسه ما اتعرفناش عليك! اكتب اسمك الأول'
              : "✍️ We don't know your name yet! Please write it",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  if (phoneController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '📱 السيارة محتاجة رقمك عشان نقدر نكلمك!'
              : '📱 We need your phone number to reach you!',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  if (cityController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '🏙️ حضرتك من وين؟ اكتب مدينتك الأول'
              : "🏙️ Where are you from? Tell us your city first",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  if (colorListForValidation.isNotEmpty && selectedColor == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '🎨 السيارة مستنياك تختارلها لونها! دوس على أي دايرة فوق'
              : '🎨 The car is waiting for you to pick a color!',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.pink.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  if (notesController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '📝 عندك أي طلب خاص؟ اكتبلنا كلمتين هنا الأول'
              : '📝 Got a special request? Tell us here first',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  if (whatsappController.text.trim().isEmpty &&
      emailController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? '📱💌 محتاجين وسيلة نوصلك بيها! اكتبي رقم الواتساب أو الإيميل'
              : '📱💌 We need a way to reach you! Add WhatsApp or email',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }

  // اسم اللون المختار (لو العميل اختار لون) عشان نسجله بشكل مقروء
  final colorList = carColorsCache[car.id] ?? const <CarColor>[];
  String? selectedColorName;
  if (selectedColor != null) {
    for (final c in colorList) {
      if (c.id == selectedColor) {
        selectedColorName = isArabic ? c.nameAr : c.nameEn;
        break;
      }
    }
  }

  // تسجيل الحجز في Supabase
  bool bookingSaved = false;
  int? bookingId;
  try {
    final inserted = await Supabase.instance.client
        .from('bookings')
        .insert({
      'customer_name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'city': cityController.text.trim(),
      'notes': notesController.text.trim(),
      'car_name': car.name,
      'car_brand': car.brand,
      'car_id': car.id,
      'car_price': car.price,
      'selected_color': selectedColorName,
      'whatsapp': whatsappController.text.trim(),
      'email': emailController.text.trim(),
      'status': 'pending',
    }).select().single();
    bookingId = inserted['id'] as int?;
    bookingSaved = true;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تسجيل الحجز في Supabase: $e');
  }

  if (!context.mounted) return;

  if (bookingSaved) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingSuccessDialog(
        isArabic: isArabic,
        carName: car.name,
        carBrand: car.brand,
        colorName: selectedColorName,
        phone: phoneController.text.trim(),
        bookingId: bookingId,
      ),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'حصلت مشكلة أثناء إرسال الحجز، من فضلك حاولي تاني'
              : 'Something went wrong, please try again',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isArabic
                                ? 'إرسال طلب الحجز'
                                : 'SUBMIT BOOKING',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  AutoOneFooter(isArabic: isArabic),
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
// ADMIN GATE (PASSWORD PROTECTION)
// ============================================================
// شاشة بسيطة بتطلب رقم سري قبل ما تفتح صفحة إدارة الحجوزات.
// ملحوظة: ده حماية على مستوى الواجهة بس، مش نظام تسجيل دخول أمني كامل.
const String kAdminPassword = 'autoone2026';

class AdminGate extends StatefulWidget {
  final bool isArabic;

  const AdminGate({super.key, required this.isArabic});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final passwordController = TextEditingController();
  String? errorText;
  bool obscure = true;

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (passwordController.text.trim() == kAdminPassword) {
      Navigator.of(context).pushReplacement(
        smoothRoute(AdminDashboard(isArabic: isArabic)),
      );
    } else {
      setState(() {
        errorText = isArabic
            ? 'الرقم السري غلط، حاولي تاني'
            : 'Wrong password, try again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'دخول الإدارة' : 'Admin Access',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'الرقم السري' : 'Password',
                      hintStyle: const TextStyle(color: Colors.white38),
                      errorText: errorText,
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isArabic ? 'دخول' : 'Enter',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isArabic ? 'رجوع' : 'Back',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
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
// ADMIN BOOKINGS PAGE
// ============================================================
// ============================================================
// SKELETON LIST (loading placeholder for lists)
// ============================================================
Widget skeletonCardList({int count = 4}) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: count,
    itemBuilder: (context, index) {
      return Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 66,
                height: 66,
                child: ShimmerBox(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const SizedBox(
                      height: 14,
                      width: 140,
                      child: ShimmerBox(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const SizedBox(
                      height: 12,
                      width: 90,
                      child: ShimmerBox(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

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

// ============================================================
// ADMIN DASHBOARD (TABS: BOOKINGS + INVENTORY)
// ============================================================
class AdminDashboard extends StatefulWidget {
  final bool isArabic;

  const AdminDashboard({super.key, required this.isArabic});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentTab = 0;

  bool isLoadingStats = true;
  int totalBookings = 0;
  int pendingBookings = 0;
  int totalCars = 0;
  String? bestSellingCar;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final bookingsResponse = await Supabase.instance.client
          .from('bookings')
          .select('status, car_name, car_brand');
      final carsResponse =
          await Supabase.instance.client.from('cars').select('id');

      final bookingsList =
          List<Map<String, dynamic>>.from(bookingsResponse as List);

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

      if (!mounted) return;
      setState(() {
        totalBookings = bookingsList.length;
        pendingBookings = pending.length;
        totalCars = (carsResponse as List).length;
        bestSellingCar = topCar;
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
              child: Row(
                children: [
                  Expanded(
                    child: _adminTabButton(
                      label: isArabic ? 'الحجوزات' : 'Bookings',
                      icon: Icons.event_note_rounded,
                      selected: currentTab == 0,
                      onTap: () => setState(() => currentTab = 0),
                      badgeCount: pendingBookings,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _adminTabButton(
                      label: isArabic ? 'المخزون' : 'Inventory',
                      icon: Icons.directions_car_filled_rounded,
                      selected: currentTab == 1,
                      onTap: () => setState(() => currentTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: currentTab,
                children: [
                  AdminBookingsBody(isArabic: isArabic),
                  AdminCarsPage(isArabic: isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

// ============================================================
// ADMIN INVENTORY (CARS CRUD)
// ============================================================
class AdminCarsPage extends StatefulWidget {
  final bool isArabic;

  const AdminCarsPage({super.key, required this.isArabic});

  @override
  State<AdminCarsPage> createState() => _AdminCarsPageState();
}

class _AdminCarsPageState extends State<AdminCarsPage> {
  List<Map<String, dynamic>> inventoryCars = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('cars')
          .select()
          .order('id', ascending: false);

      setState(() {
        inventoryCars = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            isArabic ? 'تعذّر تحميل السيارات' : 'Failed to load cars';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteCar(int id, {String? carName}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm delete'),
        content: Text(
          isArabic
              ? 'متأكدة إنك عايزة تمسحي "${carName ?? ""}" نهائيًا؟'
              : 'Permanently delete "${carName ?? ""}"?',
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
      await Supabase.instance.client.from('cars').delete().eq('id', id);
      _loadCars();
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

  Future<void> _openForm({Map<String, dynamic>? existingCar}) async {
    final saved = await Navigator.of(context).push<bool>(
      smoothRoute(
        CarFormPage(
          isArabic: isArabic,
          existingCar: existingCar,
        ),
      ),
    );

    if (saved == true) {
      _loadCars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'سيارة جديدة' : 'New car'),
      ),
      body: isLoading
          ? skeletonCardList()
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : inventoryCars.isEmpty
                  ? Center(
                      child: Text(
                        isArabic
                            ? 'مفيش سيارات في المخزون لسه'
                            : 'No cars in inventory yet',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: inventoryCars.length,
                      itemBuilder: (context, index) {
                        final carData = inventoryCars[index];
                        final isAvailable =
                            (carData['is_available'] ?? true) as bool;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: carImageAdaptive(
                                      (carData['image'] ?? '') as String,
                                      fit: BoxFit.cover,
                                      showWatermark: false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${carData['brand'] ?? ''} ${carData['name'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${carData['price'] ?? ''} • ${carData['year'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (isAvailable
                                                  ? Colors.green
                                                  : Colors.grey)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isAvailable
                                              ? (isArabic
                                                  ? 'متاحة'
                                                  : 'Available')
                                              : (isArabic
                                                  ? 'غير متاحة'
                                                  : 'Unavailable'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isAvailable
                                                ? Colors.green
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () => _openForm(
                                        existingCar: carData,
                                      ),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteCar(
                                        carData['id'] as int,
                                        carName:
                                            '${carData['brand'] ?? ''} ${carData['name'] ?? ''}'
                                                .trim(),
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// ============================================================
// CAR FORM (ADD / EDIT)
// ============================================================
class CarFormPage extends StatefulWidget {
  final bool isArabic;
  final Map<String, dynamic>? existingCar;

  const CarFormPage({
    super.key,
    required this.isArabic,
    this.existingCar,
  });

  @override
  State<CarFormPage> createState() => _CarFormPageState();
}

class _CarFormPageState extends State<CarFormPage> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameCtrl;
  late final TextEditingController brandCtrl;
  late final TextEditingController categoryCtrl;
  late final TextEditingController yearCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController imageCtrl;
  late final TextEditingController seatsCtrl;
  late final TextEditingController engineCtrl;
  late final TextEditingController transmissionCtrl;
  late final TextEditingController fuelCtrl;
  late final TextEditingController driveCtrl;
  late final TextEditingController lengthCtrl;
  late final TextEditingController widthCtrl;
  late final TextEditingController heightCtrl;
  late final TextEditingController wheelbaseCtrl;
  late final TextEditingController trunkCapacityCtrl;
  late final TextEditingController horsepowerCtrl;
  late final TextEditingController torqueCtrl;
  late final TextEditingController fuelTankCtrl;
  late final TextEditingController fuelConsumptionCtrl;
  late final TextEditingController infotainmentCtrl;
  late final TextEditingController sunroofCtrl;
  late final TextEditingController cameraSensorsCtrl;
  late final TextEditingController wirelessChargerCtrl;
  late final TextEditingController airbagsCtrl;
  late final TextEditingController absSystemCtrl;

  late bool isAvailable;
  late bool isOffer;
  late final TextEditingController oldPriceCtrl;
  bool isSaving = false;

  // الألوان المتاحة في المتجر كله، وإيه اللي متحدد للسيارة دي
  List<Map<String, dynamic>> allColors = [];
  Set<int> selectedColorIds = {};
  // رابط صورة خاص بكل لون متحدد (لو موجود)
  Map<int, TextEditingController> colorImageControllers = {};
  bool isLoadingExtras = true;

  // صور إضافية للمعرض (غير الصورة الأساسية)
  List<TextEditingController> extraImageControllers = [];

  bool get isArabic => widget.isArabic;
  bool get isEditing => widget.existingCar != null;

  @override
  void initState() {
    super.initState();
    final car = widget.existingCar;

    nameCtrl = TextEditingController(text: car?['name']?.toString() ?? '');
    brandCtrl = TextEditingController(text: car?['brand']?.toString() ?? '');
    categoryCtrl =
        TextEditingController(text: car?['category']?.toString() ?? '');
    yearCtrl = TextEditingController(text: car?['year']?.toString() ?? '');
    priceCtrl = TextEditingController(text: car?['price']?.toString() ?? '');
    descriptionCtrl =
        TextEditingController(text: car?['description']?.toString() ?? '');
    imageCtrl = TextEditingController(text: car?['image']?.toString() ?? '');
    seatsCtrl = TextEditingController(text: car?['seats']?.toString() ?? '5');
    engineCtrl =
        TextEditingController(text: car?['engine']?.toString() ?? '1.5L');
    transmissionCtrl = TextEditingController(
      text: car?['transmission']?.toString() ?? 'أوتوماتيك',
    );
    fuelCtrl =
        TextEditingController(text: car?['fuel']?.toString() ?? 'بنزين');
    driveCtrl = TextEditingController(
      text: car?['drive']?.toString() ?? 'دفع أمامي',
    );
    lengthCtrl =
        TextEditingController(text: car?['car_length']?.toString() ?? '');
    widthCtrl =
        TextEditingController(text: car?['car_width']?.toString() ?? '');
    heightCtrl =
        TextEditingController(text: car?['car_height']?.toString() ?? '');
    wheelbaseCtrl =
        TextEditingController(text: car?['wheelbase']?.toString() ?? '');
    trunkCapacityCtrl = TextEditingController(
        text: car?['trunk_capacity']?.toString() ?? '');
    horsepowerCtrl =
        TextEditingController(text: car?['horsepower']?.toString() ?? '');
    torqueCtrl =
        TextEditingController(text: car?['torque']?.toString() ?? '');
    fuelTankCtrl =
        TextEditingController(text: car?['fuel_tank']?.toString() ?? '');
    fuelConsumptionCtrl = TextEditingController(
        text: car?['fuel_consumption']?.toString() ?? '');
    infotainmentCtrl = TextEditingController(
        text: car?['infotainment']?.toString() ?? '');
    sunroofCtrl =
        TextEditingController(text: car?['sunroof']?.toString() ?? '');
    cameraSensorsCtrl = TextEditingController(
        text: car?['camera_sensors']?.toString() ?? '');
    wirelessChargerCtrl = TextEditingController(
        text: car?['wireless_charger']?.toString() ?? '');
    airbagsCtrl =
        TextEditingController(text: car?['airbags']?.toString() ?? '');
    absSystemCtrl =
        TextEditingController(text: car?['abs_system']?.toString() ?? '');

    isAvailable = (car?['is_available'] ?? true) as bool;
    isOffer = (car?['is_offer'] ?? false) as bool;
    oldPriceCtrl =
        TextEditingController(text: car?['old_price']?.toString() ?? '');

    _loadExtras();
  }

  // بيجيب كل الألوان المتاحة، وألوان/صور السيارة دي لو بنعدّل
  Future<void> _loadExtras() async {
    try {
      final colorsResponse =
          await Supabase.instance.client.from('colors').select();
      allColors = List<Map<String, dynamic>>.from(colorsResponse as List);

      if (isEditing) {
        final carId = widget.existingCar!['id'] as int;

        final carColorsResponse = await Supabase.instance.client
            .from('car_color_availability')
            .select('color_id, image')
            .eq('car_id', carId)
            .eq('is_available', true);

        selectedColorIds = (carColorsResponse as List)
            .map((row) => row['color_id'] as int)
            .toSet();

        for (final row in carColorsResponse) {
          final colorId = row['color_id'] as int;
          colorImageControllers[colorId] = TextEditingController(
            text: (row['image'] ?? '').toString(),
          );
        }

        final carImagesResponse = await Supabase.instance.client
            .from('car_images')
            .select('image')
            .eq('car_id', carId);

        extraImageControllers = (carImagesResponse as List)
            .map((row) => TextEditingController(
                  text: (row['image'] ?? '').toString(),
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل الألوان/الصور: $e');
    }

    if (mounted) {
      setState(() => isLoadingExtras = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    brandCtrl.dispose();
    categoryCtrl.dispose();
    yearCtrl.dispose();
    priceCtrl.dispose();
    descriptionCtrl.dispose();
    imageCtrl.dispose();
    seatsCtrl.dispose();
    engineCtrl.dispose();
    transmissionCtrl.dispose();
    fuelCtrl.dispose();
    driveCtrl.dispose();
    lengthCtrl.dispose();
    widthCtrl.dispose();
    heightCtrl.dispose();
    wheelbaseCtrl.dispose();
    trunkCapacityCtrl.dispose();
    horsepowerCtrl.dispose();
    torqueCtrl.dispose();
    fuelTankCtrl.dispose();
    fuelConsumptionCtrl.dispose();
    infotainmentCtrl.dispose();
    sunroofCtrl.dispose();
    cameraSensorsCtrl.dispose();
    wirelessChargerCtrl.dispose();
    airbagsCtrl.dispose();
    absSystemCtrl.dispose();
    oldPriceCtrl.dispose();
    for (final controller in extraImageControllers) {
      controller.dispose();
    }
    for (final controller in colorImageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final data = {
      'name': nameCtrl.text.trim(),
      'brand': brandCtrl.text.trim(),
      'category': categoryCtrl.text.trim(),
      'year': yearCtrl.text.trim(),
      'price': priceCtrl.text.trim(),
      'description': descriptionCtrl.text.trim(),
      'image': imageCtrl.text.trim(),
      'seats': seatsCtrl.text.trim(),
      'engine': engineCtrl.text.trim(),
      'transmission': transmissionCtrl.text.trim(),
      'fuel': fuelCtrl.text.trim(),
      'drive': driveCtrl.text.trim(),
      'car_length': lengthCtrl.text.trim(),
      'car_width': widthCtrl.text.trim(),
      'car_height': heightCtrl.text.trim(),
      'wheelbase': wheelbaseCtrl.text.trim(),
      'trunk_capacity': trunkCapacityCtrl.text.trim(),
      'horsepower': horsepowerCtrl.text.trim(),
      'torque': torqueCtrl.text.trim(),
      'fuel_tank': fuelTankCtrl.text.trim(),
      'fuel_consumption': fuelConsumptionCtrl.text.trim(),
      'infotainment': infotainmentCtrl.text.trim(),
      'sunroof': sunroofCtrl.text.trim(),
      'camera_sensors': cameraSensorsCtrl.text.trim(),
      'wireless_charger': wirelessChargerCtrl.text.trim(),
      'airbags': airbagsCtrl.text.trim(),
      'abs_system': absSystemCtrl.text.trim(),
      'is_offer': isOffer,
      'old_price': oldPriceCtrl.text.trim(),
      'is_available': isAvailable,
    };

    try {
      int carId;

      if (isEditing) {
        carId = widget.existingCar!['id'] as int;
        await Supabase.instance.client
            .from('cars')
            .update(data)
            .eq('id', carId);
      } else {
        final inserted = await Supabase.instance.client
            .from('cars')
            .insert(data)
            .select()
            .single();
        carId = inserted['id'] as int;
      }

      // نمسح الألوان والصور القديمة المرتبطة بالسيارة دي ونسجل الجديدة
      // (أسهل وأضمن من إننا نحاول نقارن الفرق واحد واحد)
      await Supabase.instance.client
          .from('car_color_availability')
          .delete()
          .eq('car_id', carId);

      if (selectedColorIds.isNotEmpty) {
        await Supabase.instance.client.from('car_color_availability').insert(
              selectedColorIds
                  .map((colorId) => {
                        'car_id': carId,
                        'color_id': colorId,
                        'is_available': true,
                        'image': colorImageControllers[colorId]
                                ?.text
                                .trim() ??
                            '',
                      })
                  .toList(),
            );
      }

      await Supabase.instance.client
          .from('car_images')
          .delete()
          .eq('car_id', carId);

      final extraImageUrls = extraImageControllers
          .map((c) => c.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      if (extraImageUrls.isNotEmpty) {
        await Supabase.instance.client.from('car_images').insert(
              extraImageUrls
                  .map((url) => {'car_id': carId, 'image': url})
                  .toList(),
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('AUTO_ONE_DEBUG: car save error: $e');
      setState(() => isSaving = false);
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return isArabic ? 'الحقل ده مطلوب' : 'This field is required';
                }
                return null;
              }
            : null,
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
          title: Text(
            isEditing
                ? (isArabic ? 'تعديل السيارة' : 'Edit Car')
                : (isArabic ? 'سيارة جديدة' : 'New Car'),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _field(
                controller: nameCtrl,
                label: isArabic ? 'اسم السيارة' : 'Car name',
                required: true,
              ),
              _field(
                controller: brandCtrl,
                label: isArabic ? 'الماركة' : 'Brand',
                required: true,
              ),
              _field(
                controller: categoryCtrl,
                label: isArabic ? 'الفئة' : 'Category',
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: yearCtrl,
                      label: isArabic ? 'السنة' : 'Year',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: priceCtrl,
                      label: isArabic ? 'السعر' : 'Price',
                      required: true,
                    ),
                  ),
                ],
              ),
              _field(
                controller: imageCtrl,
                label: isArabic
                    ? 'رابط الصورة الأساسية'
                    : 'Main image link',
                required: true,
              ),
              if (imageCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: carImageAdaptive(
                        imageCtrl.text.trim(),
                        fit: BoxFit.cover,
                        showWatermark: false,
                      ),
                    ),
                  ),
                ),
              _field(
                controller: descriptionCtrl,
                label: isArabic ? 'الوصف' : 'Description',
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: seatsCtrl,
                      label: isArabic ? 'المقاعد' : 'Seats',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: engineCtrl,
                      label: isArabic ? 'المحرك' : 'Engine',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: transmissionCtrl,
                      label: isArabic ? 'ناقل الحركة' : 'Transmission',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: fuelCtrl,
                      label: isArabic ? 'الوقود' : 'Fuel',
                    ),
                  ),
                ],
              ),
              _field(
                controller: driveCtrl,
                label: isArabic ? 'نظام الدفع' : 'Drive system',
              ),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: lengthCtrl,
                      label: isArabic ? 'الطول (سم)' : 'Length (cm)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: widthCtrl,
                      label: isArabic ? 'العرض (سم)' : 'Width (cm)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: heightCtrl,
                      label: isArabic ? 'الارتفاع (سم)' : 'Height (cm)',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: wheelbaseCtrl,
                      label: isArabic ? 'قاعدة العجلات' : 'Wheelbase',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: trunkCapacityCtrl,
                      label:
                          isArabic ? 'سعة صندوق الأمتعة' : 'Trunk capacity',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              Text(
                isArabic ? 'مواصفات إضافية للقيادة' : 'Extra driving specs',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: horsepowerCtrl,
                      label: isArabic ? 'قوة المحرك (حصان)' : 'Horsepower',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: torqueCtrl,
                      label: isArabic ? 'عزم الدوران' : 'Torque',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: fuelTankCtrl,
                      label:
                          isArabic ? 'سعة خزان الوقود' : 'Fuel tank capacity',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: fuelConsumptionCtrl,
                      label:
                          isArabic ? 'استهلاك الوقود' : 'Fuel consumption',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              Text(
                isArabic ? 'التجهيزات والمزايا' : 'Features',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: infotainmentCtrl,
                      label:
                          isArabic ? 'نظام الترفيه/الشاشة' : 'Infotainment',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: sunroofCtrl,
                      label: isArabic ? 'فتحة سقف' : 'Sunroof',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: cameraSensorsCtrl,
                      label: isArabic
                          ? 'كاميرا خلفية + حساسات ركن'
                          : 'Camera & sensors',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: wirelessChargerCtrl,
                      label:
                          isArabic ? 'شاحن لاسلكي' : 'Wireless charger',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              Text(
                isArabic ? 'الأمان' : 'Safety',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: airbagsCtrl,
                      label: isArabic
                          ? 'عدد الوسائد الهوائية'
                          : 'Number of airbags',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: absSystemCtrl,
                      label: isArabic ? 'نظام ABS' : 'ABS system',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              // ==========================================
              // COLORS SECTION
              // ==========================================
              Text(
                isArabic ? 'الألوان المتاحة' : 'Available colors',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'دوسي على أي لون عشان تحدديه كمتاح لهذه السيارة'
                    : 'Tap a color to mark it available for this car',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              if (isLoadingExtras)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      4,
                      (i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const SizedBox(
                          width: 90,
                          height: 36,
                          child: ShimmerBox(),
                        ),
                      ),
                    ),
                  ),
                )
              else if (allColors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    isArabic
                        ? 'مفيش ألوان مسجلة في جدول colors لسه'
                        : 'No colors registered in the colors table yet',
                    style: const TextStyle(color: Colors.black45),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allColors.map((color) {
                    final colorId = color['id'] as int;
                    final isSelected = selectedColorIds.contains(colorId);
                    final rawValue = (color['color_value'] as int?) ?? 0xFFFFFF;
                    final displayColor = Color(0xFF000000 | rawValue);
                    final name = isArabic
                        ? (color['name_ar'] ?? '') as String
                        : (color['name_en'] ?? '') as String;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedColorIds.remove(colorId);
                            colorImageControllers[colorId]?.dispose();
                            colorImageControllers.remove(colorId);
                          } else {
                            selectedColorIds.add(colorId);
                            colorImageControllers.putIfAbsent(
                              colorId,
                              () => TextEditingController(),
                            );
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.red.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSelected ? Colors.red : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: displayColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // روابط صور خاصة بكل لون متحدد
              if (selectedColorIds.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...selectedColorIds.map((colorId) {
                  final colorData = allColors.firstWhere(
                    (c) => c['id'] == colorId,
                    orElse: () => {},
                  );
                  final rawValue =
                      (colorData['color_value'] as int?) ?? 0xFFFFFF;
                  final displayColor = Color(0xFF000000 | rawValue);
                  final name = isArabic
                      ? (colorData['name_ar'] ?? '') as String
                      : (colorData['name_en'] ?? '') as String;

                  final controller = colorImageControllers.putIfAbsent(
                    colorId,
                    () => TextEditingController(),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          decoration: BoxDecoration(
                            color: displayColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'رابط صورة اللون $name (اختياري)'
                                  : 'Image link for $name (optional)',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              // ==========================================
              // EXTRA IMAGES SECTION
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'صور إضافية للمعرض' : 'Extra gallery photos',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        extraImageControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (extraImageControllers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isArabic
                        ? 'مفيش صور إضافية، دوسي + عشان تضيفي'
                        : 'No extra photos, tap + to add one',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              ...extraImageControllers.asMap().entries.map((entry) {
                final controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'رابط صورة إضافية'
                                : 'Extra image link',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            controller.dispose();
                            extraImageControllers.remove(controller);
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isArabic ? 'متاحة للعرض' : 'Available',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: isAvailable,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() => isAvailable = value);
                  },
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isArabic ? 'عرض خاص / خصم' : 'Special Offer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: isOffer,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() => isOffer = value);
                  },
                ),
              ),

              if (isOffer) ...[
                const SizedBox(height: 10),
                _field(
                  controller: oldPriceCtrl,
                  label: isArabic
                      ? 'السعر القديم (قبل الخصم)'
                      : 'Old price (before discount)',
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isArabic ? 'حفظ' : 'Save',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOOKING SUCCESS DIALOG
// ============================================================
class BookingSuccessDialog extends StatefulWidget {
  final bool isArabic;
  final String carName;
  final String carBrand;
  final String? colorName;
  final String phone;
  final int? bookingId;

  const BookingSuccessDialog({
    super.key,
    required this.isArabic,
    required this.carName,
    required this.carBrand,
    required this.colorName,
    required this.phone,
    this.bookingId,
  });

  @override
  State<BookingSuccessDialog> createState() => _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends State<BookingSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'تم إرسال طلب الحجز بنجاح' : 'Booking submitted!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'هيتم التواصل معاك قريبًا لتأكيد الحجز'
                    : 'We will contact you soon to confirm',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              if (widget.bookingId != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isArabic
                        ? 'رقم الحجز: #AO-${widget.bookingId}'
                        : 'Booking #: AO-${widget.bookingId}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow(
                      isArabic ? 'السيارة' : 'Car',
                      '${widget.carBrand} ${widget.carName}',
                    ),
                    if ((widget.colorName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _summaryRow(
                        isArabic ? 'اللون' : 'Color',
                        widget.colorName!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _summaryRow(
                      isArabic ? 'رقم الجوال' : 'Phone',
                      widget.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'تمام' : 'Done',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FAVORITES PAGE
// ============================================================
class FavoritesPage extends StatefulWidget {
  final bool isArabic;

  const FavoritesPage({super.key, required this.isArabic});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool get isArabic => widget.isArabic;

  @override
  Widget build(BuildContext context) {
    final favoriteCars =
        cars.where((c) => c.id != null && favoriteCarIds.contains(c.id)).toList();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'السيارات المفضلة' : 'Favorite Cars'),
        ),
        body: favoriteCars.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 60,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic
                          ? 'لسه مفيش سيارات في المفضلة'
                          : 'No favorite cars yet',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'دوسي على أيقونة ♡ في أي سيارة عشان تضيفيها هنا'
                          : 'Tap ♡ on any car to add it here',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: 360,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: favoriteCars.length,
                itemBuilder: (context, index) {
                  final car = favoriteCars[index];
                  return FeaturedCarCard(
                    key: ValueKey('${car.name}-${car.year}'),
                    car: car,
                    isArabic: isArabic,
                  );
                },
              ),
      ),
    );
  }
}

// ============================================================
// COMPARISON PAGE
// ============================================================
class ComparisonPage extends StatefulWidget {
  final bool isArabic;

  const ComparisonPage({super.key, required this.isArabic});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  bool get isArabic => widget.isArabic;

  Widget _row(String label, List<String> values) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ...values.map((v) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  child: Text(
                    v.isEmpty ? '—' : v,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCars = compareCarIds.value
        .map((id) => cars.where((c) => c.id == id))
        .where((iterable) => iterable.isNotEmpty)
        .map((iterable) => iterable.first)
        .toList();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'مقارنة السيارات' : 'Compare Cars'),
        ),
        body: selectedCars.length < 2
            ? Center(
                child: Text(
                  isArabic
                      ? 'اختاري سيارتين على الأقل للمقارنة'
                      : 'Select at least 2 cars to compare',
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // IMAGES + NAMES ROW
                    Row(
                      children: [
                        const SizedBox(width: 130),
                        ...selectedCars.map((car) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 90,
                                      child: carImageAdaptive(
                                        car.image,
                                        fit: BoxFit.cover,
                                        showWatermark: false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${car.brand} ${car.name}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _row(
                      isArabic ? 'السعر' : 'Price',
                      selectedCars.map((c) => c.price).toList(),
                    ),
                    _row(
                      isArabic ? 'السنة' : 'Year',
                      selectedCars.map((c) => c.year).toList(),
                    ),
                    _row(
                      isArabic ? 'المحرك' : 'Engine',
                      selectedCars.map((c) => c.engine).toList(),
                    ),
                    _row(
                      isArabic ? 'ناقل الحركة' : 'Transmission',
                      selectedCars.map((c) => c.transmission).toList(),
                    ),
                    _row(
                      isArabic ? 'الوقود' : 'Fuel',
                      selectedCars.map((c) => c.fuel).toList(),
                    ),
                    _row(
                      isArabic ? 'المقاعد' : 'Seats',
                      selectedCars.map((c) => c.seats).toList(),
                    ),
                    _row(
                      isArabic ? 'نظام الدفع' : 'Drive',
                      selectedCars.map((c) => c.drive).toList(),
                    ),
                    _row(
                      isArabic ? 'قوة المحرك' : 'Horsepower',
                      selectedCars.map((c) => c.horsepower).toList(),
                    ),
                    _row(
                      isArabic ? 'عدد الوسائد الهوائية' : 'Airbags',
                      selectedCars.map((c) => c.airbags).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 130),
                        ...selectedCars.map((car) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    smoothRoute(
                                      CarDetailsPage(
                                        car: car,
                                        isArabic: isArabic,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'التفاصيل' : 'Details',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../shared/widgets.dart';
import '../screens/car_details_page.dart';
import '../screens/static_pages.dart';
import '../admin/admin_shared.dart';

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
 final ScrollController _featuredCarsScrollController = ScrollController();

 // إحساس الـ parallax الخفيف على صورة الهيرو مع تحريك الماوس
 Offset _heroParallax = Offset.zero;

 void _onHeroHover(Offset localPosition, Size size) {
   if (size.width == 0 || size.height == 0) return;
   final dx = (localPosition.dx / size.width - 0.5) * 2; // -1..1
   final dy = (localPosition.dy / size.height - 0.5) * 2; // -1..1
   setState(() {
     _heroParallax = Offset(dx * 10, dy * 10);
   });
 }

 void _resetHeroParallax() {
   setState(() => _heroParallax = Offset.zero);
 }

int get safeImageIndex {
  final banners = heroBanners;
  if (banners.isEmpty) return 0;
  if (currentImage >= banners.length) return banners.length - 1;
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
  _featuredCarsScrollController.dispose();
  super.dispose();
}

// بيحرّك أي شريط بيتسحب لجنب (سيارات مميزة أو الماركات) خطوة لقدام
// أو لورا لما حد يدوس على السهم، بحركة سلسة بدل قفزة مفاجئة.
void _scrollBy(ScrollController controller, double delta) {
  if (!controller.hasClients) return;
  final target = (controller.offset + delta).clamp(
    0.0,
    controller.position.maxScrollExtent,
  );
  controller.animateTo(
    target,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOut,
  );
}

  // ==========================================================
  // صور/فيديوهات الهيرو
  //
  // بتتقرا من لوحة التحكم (إعدادات الرئيسية > صور البانر)، ولو
  // الأدمن لسه ما ضافش حاجة، بيرجع لنفس الصور الافتراضية.
  // ==========================================================

  static const List<String> _fallbackImages = [
    'assets/youssefcar22.jpg',
    'assets/youssefcar3.jpg',
    'assets/youssefcar4.jpg',
    'assets/youssefcar5.jpg',
  ];

  List<_HeroBannerItem> get heroBanners {
    final raw = homepageSettings.value?['banner_images'];
    if (raw is List && raw.isNotEmpty) {
      final parsed = raw.map((entry) {
        if (entry is Map) {
          final url = (entry['url'] ?? '').toString();
          final type = (entry['type'] ?? 'image').toString();
          return _HeroBannerItem(
            url: url,
            isVideo: type == 'video',
            isAsset: false,
          );
        }
        // توافق مع الشكل القديم: مجرد رابط نصي = صورة
        return _HeroBannerItem(
          url: entry.toString(),
          isVideo: false,
          isAsset: false,
        );
      }).where((item) => item.url.isNotEmpty).toList();

      if (parsed.isNotEmpty) return parsed;
    }

    return _fallbackImages
        .map((path) => _HeroBannerItem(
              url: path,
              isVideo: false,
              isAsset: true,
            ))
        .toList();
  }
  
final List<Map<String, String>> slideTexts = [
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
  final banners = heroBanners;
  if (banners.isEmpty) return;

  setState(() {
    currentImage = (currentImage + 1) % banners.length;
  });
}
  // ==========================================================
  // PREVIOUS
  // ==========================================================

  void previousImage() {
  final banners = heroBanners;
  if (banners.isEmpty) return;

  setState(() {
    currentImage =
        (currentImage - 1 + banners.length) % banners.length;
  });
}

  @override
  Widget build(BuildContext context) {
    final sections = <WidgetBuilder>[
      (context) => BrandStrip(
  isArabic: widget.isArabic,
  onBrandTap: (brand) {
    widget.onOpenCars(brand);
  },
),
      (context) => Container(
  color: Colors.white,
  width: double.infinity,
  height: 20,
),
      (context) => const SizedBox(height: 50),
      (context) => // ====================================================
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
        siteText(
          key: 'why_title',
          isArabic: widget.isArabic,
          defaultAr: 'لماذا AUTO ONE؟',
          defaultEn: 'WHY AUTO ONE?',
        ),
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
        siteText(
          key: 'why_subtitle',
          isArabic: widget.isArabic,
          defaultAr: 'تجربة مختلفة في اختيار وشراء سيارتك',
          defaultEn: 'A different experience in choosing and buying your car',
        ),
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
                title: siteText(
                  key: 'why_card1_title',
                  isArabic: widget.isArabic,
                  defaultAr: 'اختيارات متنوعة',
                  defaultEn: 'WIDE SELECTION',
                ),
                description: siteText(
                  key: 'why_card1_desc',
                  isArabic: widget.isArabic,
                  defaultAr: 'مجموعة متنوعة من السيارات والموديلات لتختار ما يناسبك.',
                  defaultEn: 'A wide selection of cars and models to match your needs.',
                ),
                isSmall: isSmall,
                onTap: () => _showBodyTypeSheet(context),
              ),

              _whyAutoOneCard(
                icon: Icons.price_check_rounded,
                title: siteText(
                  key: 'why_card2_title',
                  isArabic: widget.isArabic,
                  defaultAr: 'أسعار منافسة',
                  defaultEn: 'COMPETITIVE PRICES',
                ),
                description: siteText(
                  key: 'why_card2_desc',
                  isArabic: widget.isArabic,
                  defaultAr: 'أسعار مدروسة وعروض مميزة على مجموعة من السيارات.',
                  defaultEn: 'Competitive prices and special offers on selected cars.',
                ),
                isSmall: isSmall,
                onTap: () => widget.onOpenCars('__OFFERS__'),
              ),

              _whyAutoOneCard(
                icon: Icons.handshake_rounded,
                title: siteText(
                  key: 'why_card3_title',
                  isArabic: widget.isArabic,
                  defaultAr: 'خدمة موثوقة',
                  defaultEn: 'RELIABLE SERVICE',
                ),
                description: siteText(
                  key: 'why_card3_desc',
                  isArabic: widget.isArabic,
                  defaultAr: 'نهتم بتقديم تجربة واضحة ومريحة من البداية للنهاية.',
                  defaultEn: 'A clear and comfortable experience from start to finish.',
                ),
                isSmall: isSmall,
                onTap: () {
                  Navigator.of(context).push(
                    smoothRoute(
                      AboutAutoOnePage(isArabic: widget.isArabic),
                    ),
                  );
                },
              ),

              _whyAutoOneCard(
                icon: Icons.support_agent_rounded,
                title: siteText(
                  key: 'why_card4_title',
                  isArabic: widget.isArabic,
                  defaultAr: 'تواصل سريع',
                  defaultEn: 'FAST SUPPORT',
                ),
                description: siteText(
                  key: 'why_card4_desc',
                  isArabic: widget.isArabic,
                  defaultAr: 'تواصل معنا بسهولة واحصل على المساعدة التي تحتاجها.',
                  defaultEn: 'Reach out easily and get the help you need.',
                ),
                isSmall: isSmall,
                onTap: () => _showQuickContactSheet(context),
              ),
            ],
          );
        },
      ),
    ],
  ),
),
      (context) => const SizedBox(height: 35),
      (context) => // ====================================================
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

   final List<Car> featuredCars = cars.where((c) => c.isFeatured).toList();

// لو لسه محدش حدد أي سيارة كمميزة من لوحة التحكم، نعرض آخر السيارات
// كإجراء احتياطي عشان القسم ميفضلش فاضي
if (featuredCars.isEmpty && cars.isNotEmpty) {
  featuredCars.addAll(cars.take(5));
}

    // بقت بتتسحب لجنب زي شريط الماركات، بدل ما تتلف على أكتر من صف.
    // السهمين متحطين فوق الشريط نفسه (Stack) على الحافة اليمين
    // والشمال، مش قسم منفصل فوقه.
    return Stack(
      alignment: Alignment.center,
      children: [
        styledHorizontalScrollbar(
          controller: _featuredCarsScrollController,
          child: SingleChildScrollView(
            controller: _featuredCarsScrollController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: featuredCars.map((car) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: SizedBox(
                      width: 260,
                      child: FeaturedCarCard(
                        car: car,
                        isArabic: widget.isArabic,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        // السهمين بقوا صغيرين وف نفس مستوى شريط السحب (Scrollbar)
        // تحت، مش قاعدين فوق صورة الكارت.
        Positioned(
          right: 0,
          bottom: 0,
          child: Transform.scale(
            scale: 0.5,
            child: CarouselArrow(
              icon: Icons.arrow_back_ios_new,
              onTap: () => _scrollBy(_featuredCarsScrollController, 320),
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Transform.scale(
            scale: 0.5,
            child: CarouselArrow(
              icon: Icons.arrow_forward_ios,
              onTap: () => _scrollBy(_featuredCarsScrollController, -320),
            ),
          ),
        ),
      ],
    );
        },
      ),
    ],
  ),
),
      (context) => const SizedBox(height: 50),
      (context) => _FinancingPartnersCarousel(isArabic: widget.isArabic),
      (context) => const SizedBox(height: 50),
      (context) => _ReviewsCarousel(isArabic: widget.isArabic),
      (context) => const SizedBox(height: 40),
      (context) => AutoOneFooter(isArabic: widget.isArabic),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: // ====================================================
          // HERO (فيديو/صورة full-width بتملا الشاشة)
          // ====================================================

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isSmall = width < 850;
              final screenHeight = MediaQuery.of(context).size.height;
              final heroHeight =
                  (screenHeight - 75).clamp(420.0, 760.0);

              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -100) {
                    nextImage();
                  } else if (velocity > 100) {
                    previousImage();
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  height: heroHeight,
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, imgConstraints) {
                        final imgSize = imgConstraints.biggest;
                        return MouseRegion(
                          onHover: (event) => _onHeroHover(
                            event.localPosition,
                            imgSize,
                          ),
                          onExit: (_) => _resetHeroParallax(),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // =====================================
                              // الصورة/الفيديو (بتتغيّر بفيد ناعم + parallax)
                              // =====================================
                              AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 700),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: Transform.scale(
                                  key: ValueKey(
                                    heroBanners[safeImageIndex].url,
                                  ),
                                  scale: 1.06,
                                  child: Transform.translate(
                                    offset: _heroParallax,
                                    child: _HeroMedia(
                                      item: heroBanners[safeImageIndex],
                                    ),
                                  ),
                                ),
                              ),

                              // جسيمات ضوئية خفيفة
                              const Positioned.fill(
                                child: _FloatingParticles(),
                              ),

                              // تعتيم تدريجي عشان النص يبان بوضوح
                              const Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color.fromRGBO(0, 0, 0, 0.10),
                                        Color.fromRGBO(0, 0, 0, 0.30),
                                        Color.fromRGBO(0, 0, 0, 0.78),
                                      ],
                                      stops: [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // اللوجو أعلى الهيرو
                              Positioned(
                                top: 24,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Opacity(
                                    opacity: 0.92,
                                    child: Image.asset(
                                      'assets/logo-autoone.png',
                                      width: isSmall ? 110 : 150,
                                      height: isSmall ? 40 : 54,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // =====================================
                              // العنوان + الوصف + زرار الدعوة للإجراء
                              // =====================================
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: isSmall ? 92 : 122,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmall ? 24 : 70,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _TypewriterText(
                                        key: ValueKey(
                                          'hero_title_$currentImage',
                                        ),
                                        text: siteText(
                                          key: 'hero_title',
                                          isArabic: widget.isArabic,
                                          defaultAr: slideTexts[
                                              currentImage %
                                                  slideTexts.length]['ar']!,
                                          defaultEn: slideTexts[
                                              currentImage %
                                                  slideTexts.length]['en']!,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isSmall ? 28 : 46,
                                          height: 1.25,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 16,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      Text(
                                        siteText(
                                          key: 'hero_subtitle',
                                          isArabic: widget.isArabic,
                                          defaultAr: slideDescriptions[
                                              currentImage %
                                                  slideDescriptions
                                                      .length]['ar']!,
                                          defaultEn: slideDescriptions[
                                              currentImage %
                                                  slideDescriptions
                                                      .length]['en']!,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isSmall ? 14 : 17,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      const SizedBox(height: 26),

                                      ElevatedButton(
                                        onPressed: () =>
                                            widget.onOpenCars(null),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: 6,
                                        ),
                                        child: Text(
                                          widget.isArabic
                                              ? slideButtons[currentImage %
                                                  slideButtons.length]['ar']!
                                              : slideButtons[currentImage %
                                                  slideButtons.length]['en']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // أسهم التنقل يمين وشمال (ديسكتوب بس)
                              if (!isSmall) ...[
                                Positioned(
                                  left: 20,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: CarouselArrow(
                                          icon: Icons.chevron_left_rounded,
                                          onTap: previousImage,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 20,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: CarouselArrow(
                                          icon: Icons.chevron_right_rounded,
                                          onTap: nextImage,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // نقط التنقل أسفل الهيرو
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 28,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: List.generate(
                                    heroBanners.length,
                                    (index) {
                                      final isActive =
                                          index == currentImage;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => currentImage = index,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          margin:
                                              const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width: isActive ? 28 : 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.red
                                                : Colors.white
                                                    .withValues(
                                                        alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _LazySection(
              index: index,
              child: sections[index](context),
            ),
            childCount: sections.length,
          ),
        ),
      ],
    );

  }
 Widget _whyAutoOneCard({
  required IconData icon,
  required String title,
  required String description,
  required bool isSmall,
  VoidCallback? onTap,
}) {
  final content = Container(
    width: isSmall ? 320 : 260,
    padding: const EdgeInsets.all(26),

    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1C1C1C), Color(0xFF121212)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Colors.white12,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),

    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // =================================================
        // ICON
        // =================================================

        Container(
          width: 64,
          height: 64,

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE23636), Color(0xFFB01F1F)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),

        const SizedBox(height: 18),

        // =================================================
        // TITLE
        // =================================================

        Text(
          title,
          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 10),

        // =================================================
        // DESCRIPTION
        // =================================================

        Text(
          description,
          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 18),

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

  if (onTap == null) return content;

  return HoverLift(
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: content,
    ),
  );
}
void _showBodyTypeSheet(BuildContext context) {
  final options = [
    (
      'SUV',
      widget.isArabic ? 'إس يو في' : 'SUV',
      Icons.directions_car_filled_rounded,
    ),
    (
      'SEDAN',
      widget.isArabic ? 'سيدان' : 'Sedan',
      Icons.time_to_leave_rounded,
    ),
    (
      'JEEP',
      widget.isArabic ? 'جيب' : 'Jeep',
      Icons.terrain_rounded,
    ),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isArabic ? 'اختر نوع السيارة' : 'Choose a body type',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            for (final option in options)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onOpenCars('__BODYTYPE_${option.$1}__');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(option.$3, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        option.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

void _showQuickContactSheet(BuildContext context) {
  Future<void> openLink(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  final contactOptions = <_QuickContactOption>[
    _QuickContactOption(
      label: widget.isArabic ? 'واتساب' : 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      color: const Color(0xFF25D366),
      onTap: () => openLink('https://wa.me/966541577894'),
    ),
    _QuickContactOption(
      label: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE1306C),
      onTap: () => openLink('https://www.instagram.com/autoone_sa'),
    ),
    _QuickContactOption(
      label: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      onTap: () => openLink('https://www.tiktok.com/@autoone_sa'),
    ),
    _QuickContactOption(
      label: 'Facebook',
      icon: FontAwesomeIcons.facebookF,
      color: const Color(0xFF1877F2),
      onTap: () => openLink('https://www.facebook.com/share/1EiuLeeFP7/'),
    ),
    _QuickContactOption(
      label: 'X',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      onTap: () => openLink('https://x.com/autoone_sa'),
    ),
    _QuickContactOption(
      label: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      onTap: () => openLink('https://www.threads.com/@autoone_sa'),
    ),
    _QuickContactOption(
      label: 'Snapchat',
      icon: FontAwesomeIcons.snapchat,
      color: const Color(0xFFFFFC00),
      onTap: () => openLink('https://www.snapchat.com/add/autoone_sa'),
    ),
    _QuickContactOption(
      label: widget.isArabic ? 'اتصل بنا' : 'Call Us',
      materialIcon: Icons.phone_rounded,
      color: Colors.red,
      onTap: () => openLink('tel:+966541577894'),
    ),
  ];

  // بتفتح قائمة وسائل التواصل — دلوقتي بتتنادى من كارت "تواصل سريع"
  // نفسه في قسم "لماذا AUTO ONE" بدل ما تكون زرار منفصل في الصفحة.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isArabic ? 'تواصل مع أوتو ون' : 'Contact AUTO ONE',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 18,
                      children: contactOptions.map((option) {
                        return InkWell(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            option.onTap();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 76,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: option.color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: option.materialIcon != null
                                      ? Icon(
                                          option.materialIcon,
                                          color: option.color,
                                          size: 26,
                                        )
                                      : FaIcon(
                                          option.icon,
                                          color: option.color,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  option.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
}
}


// ============================================================
// BRAND STRIP
// ============================================================

class BrandStrip extends StatefulWidget {
  final bool isArabic;
  final ValueChanged<String> onBrandTap;

  const BrandStrip({
    super.key,
    required this.isArabic,
    required this.onBrandTap,
  });

  @override
  State<BrandStrip> createState() => _BrandStripState();
}


class _BrandStripState extends State<BrandStrip>
    with SingleTickerProviderStateMixin {
  // القايمة الثابتة القديمة، بتستخدم كـ fallback بس لو حصلت مشكلة
  // في تحميل الماركات من قاعدة البيانات (زي مشكلة في الشبكة)
  static const Map<String, String> _fallbackBrandLogos = {
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

  List<Map<String, String>> brandItems = [];
  bool isLoading = true;

  final ScrollController _scrollController = ScrollController();
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _offset = 0;
  bool _isPaused = false;

  static const double _itemWidth = 128;
  static const double _speed = 40; // بكسل في الثانية

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_scrollController.hasClients || brandItems.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (_isPaused || dt <= 0) return;

    final oneSetWidth = _itemWidth * brandItems.length;
    if (oneSetWidth <= 0) return;

    _offset += _speed * dt;
    if (_offset >= oneSetWidth) {
      _offset -= oneSetWidth;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_offset);
    }
  }

  // بيحرّك الشريط يدويًا لما حد يدوس على أي سهم، وبيوقف اللف
  // التلقائي مؤقتًا لحد ما الحركة تخلص عشان مايحصلش تعارض.
  void _scrollByArrow(double delta) {
    if (!_scrollController.hasClients || brandItems.isEmpty) return;
    _isPaused = true;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (_scrollController.offset + delta).clamp(0.0, maxExtent);
    _scrollController
        .animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    )
        .then((_) {
      if (!mounted) return;
      final oneSetWidth = _itemWidth * brandItems.length;
      _offset = oneSetWidth > 0 ? _scrollController.offset % oneSetWidth : 0;
      _isPaused = false;
    });
  }

  Future<void> _loadBrands() async {
    try {
      final response = await Supabase.instance.client
          .from('brands')
          .select()
          .eq('is_active', true)
          .order('name_ar');

      final rows = List<Map<String, dynamic>>.from(response as List);

      if (rows.isEmpty) {
        _useFallback();
        return;
      }

      setState(() {
        brandItems = rows.map((row) {
          final label = widget.isArabic
              ? ((row['name_ar'] ?? row['name_en'] ?? '').toString())
              : ((row['name_en'] ?? row['name_ar'] ?? '').toString());
          final matchKey =
              (row['name_en'] ?? row['name_ar'] ?? '').toString();
          return {
            'label': label,
            'matchKey': matchKey,
            'logo': (row['logo'] ?? '').toString(),
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      _useFallback();
    }
  }

  void _useFallback() {
    if (!mounted) return;
    setState(() {
      brandItems = _fallbackBrandLogos.entries
          .map((e) => {
                'label': e.key,
                'matchKey': e.key,
                'logo': e.value,
              })
          .toList();
      isLoading = false;
    });
  }

  Widget _buildBrandItem(Map<String, String> item) {
    final label = item['label']!;
    final matchKey = item['matchKey']!;
    final logo = item['logo']!;

    return SizedBox(
      width: _itemWidth,
      child: HoverLift(
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: () => widget.onBrandTap(matchKey),
          borderRadius: BorderRadius.circular(100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xfffafafa)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.28),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: logo.isEmpty
                    ? const Icon(
                        Icons.directions_car_filled_rounded,
                        size: 34,
                        color: Colors.red,
                      )
                    : carImageAdaptive(
                        logo,
                        fit: BoxFit.contain,
                        showWatermark: false,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 34,
                            color: Colors.red,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
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
    final isArabic = widget.isArabic;

    if (isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (brandItems.isEmpty) return const SizedBox.shrink();

    // بنكرر القايمة عشان اللفة تبقى متصلة من غير قفشة.
    final loopItems = [...brandItems, ...brandItems];

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

          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 164,
                child: MouseRegion(
                  onEnter: (_) => _isPaused = true,
                  onExit: (_) => _isPaused = false,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        _isPaused = true;
                      } else if (notification is ScrollEndNotification) {
                        final oneSetWidth = _itemWidth * brandItems.length;
                        if (oneSetWidth > 0 &&
                            _scrollController.hasClients) {
                          _offset = _scrollController.offset % oneSetWidth;
                        }
                        _isPaused = false;
                      }
                      return false;
                    },
                    child: styledHorizontalScrollbar(
                      controller: _scrollController,
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.06, 0.94, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: loopItems
                                    .map((p) => _buildBrandItem(p))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Transform.scale(
                  scale: 0.5,
                  child: CarouselArrow(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => _scrollByArrow(320),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Transform.scale(
                  scale: 0.5,
                  child: CarouselArrow(
                    icon: Icons.arrow_forward_ios,
                    onTap: () => _scrollByArrow(-320),
                  ),
                ),
              ),
            ],
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

  const FeaturedCarCard({
    super.key,
    required this.car,
    required this.isArabic,
    this.onDetails,
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
          height: 195,
          child: Stack(
            fit: StackFit.expand,
            children: [

              carImageAdaptive(
                car.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: 75,
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
                    color: car.isOfferActive ? Colors.orange.shade800 : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    car.isOfferActive
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
                    width: 54,
                    height: 54,
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
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
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
    car.displayName(isArabic),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.right,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 15,
      fontWeight: FontWeight.w900,
      height: 1.15,
    ),
  ),


                          const SizedBox(height: 7),

                          Row(
                            children: [

Text(
  car.brand,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    color: Colors.red,
    fontSize: 11,
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
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 11,
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

                        const Text(
                          'السعر',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (car.isOfferActive && car.oldPrice.isNotEmpty)
                          Text(
                            car.oldPrice,
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),

                        Text(
                          car.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

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

                const SizedBox(height: 3),
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


class _QuickContactOption {
  final String label;
  final FaIconData? icon;
  final IconData? materialIcon;
  final Color color;
  final VoidCallback onTap;

  _QuickContactOption({
    required this.label,
    this.icon,
    this.materialIcon,
    required this.color,
    required this.onTap,
  });
}

// ============================================================
// FINANCING PARTNERS CAROUSEL (معتمدون لدى جهات التمويل)
// ============================================================
class _FinancingPartnersCarousel extends StatefulWidget {
  final bool isArabic;
  const _FinancingPartnersCarousel({required this.isArabic});

  @override
  State<_FinancingPartnersCarousel> createState() =>
      _FinancingPartnersCarouselState();
}

class _FinancingPartnersCarouselState
    extends State<_FinancingPartnersCarousel>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _offset = 0;
  bool _isPaused = false;

  static const double _itemWidth = 132;
  static const double _speed = 45; // pixels per second

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final partners = financingPartnersCache;
    if (!_scrollController.hasClients || partners.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (_isPaused || dt <= 0) return;

    final oneSetWidth = _itemWidth * partners.length;
    if (oneSetWidth <= 0) return;

    _offset += _speed * dt;
    if (_offset >= oneSetWidth) {
      _offset -= oneSetWidth;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_offset);
    }
  }

  Widget _buildLogoItem(Map<String, dynamic> p) {
    final logo = (p['logo_url'] ?? '').toString();
    final name = widget.isArabic
        ? (p['name_ar'] ?? '').toString()
        : ((p['name_en'] ?? '').toString().isEmpty
            ? (p['name_ar'] ?? '').toString()
            : p['name_en'].toString());

    return SizedBox(
      width: _itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xfffafafa),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: logo.isEmpty
                ? const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.red,
                    size: 28,
                  )
                : carImageAdaptive(
                    logo,
                    fit: BoxFit.contain,
                    showWatermark: false,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partners = financingPartnersCache;
    if (partners.isEmpty) return const SizedBox.shrink();

    // Duplicate the list so the scroll can loop seamlessly.
    final loopItems = [...partners, ...partners];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            siteText(
              key: 'financing_title',
              isArabic: widget.isArabic,
              defaultAr: 'معتمدون لدى جهات التمويل',
              defaultEn: 'APPROVED BY FINANCING PARTNERS',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            siteText(
              key: 'financing_desc',
              isArabic: widget.isArabic,
              defaultAr:
                  'نالت AUTO ONE ثقة جهات التمويل الرائدة، ونسهّل عليك إجراءات التمويل عند شراء سيارتك.',
              defaultEn:
                  'AUTO ONE is trusted by leading financing partners, making your car financing journey easier.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 170,
            child: MouseRegion(
              onEnter: (_) => _isPaused = true,
              onExit: (_) => _isPaused = false,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.06, 0.94, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          loopItems.map((p) => _buildLogoItem(p)).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REVIEWS CAROUSEL (ماذا يقول عملاؤنا؟)
// ============================================================
class _ReviewsCarousel extends StatefulWidget {
  final bool isArabic;
  const _ReviewsCarousel({required this.isArabic});

  @override
  State<_ReviewsCarousel> createState() => _ReviewsCarouselState();
}

class _ReviewsCarouselState extends State<_ReviewsCarousel> {
  late final PageController controller;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    controller = PageController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Color _avatarColor(String name) {
    final colors = [
      Colors.red,
      Colors.green.shade700,
      Colors.orange,
      Colors.indigo,
      Colors.teal,
      Colors.brown,
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  void _showFullReview(String name, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _avatarColor(name),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final name = (r['customer_name'] ?? '').toString();
    final text = (r['review_text'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarRadius = 24.0;

    final card = Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: avatarRadius, left: 6, right: 6),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.grey.shade300.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: Colors.red.withValues(alpha: 0.35),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showFullReview(name, text),
            child: card,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: _avatarColor(name),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = approvedReviewsCache;
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            siteText(
              key: 'reviews_title',
              isArabic: widget.isArabic,
              defaultAr: 'ماذا يقول عملاؤنا؟',
              defaultEn: 'WHAT OUR CUSTOMERS SAY',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.isArabic
                ? 'رضا عملائنا هو محور اهتمامنا، وده اللي بيشجّعنا نكمل نقدّم أفضل تجربة ممكنة.'
                : 'Our customers\' satisfaction is what drives us to keep delivering the best experience.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              final perPage = constraints.maxWidth >= 700 ? 4 : 1;
              final pageCount = (reviews.length / perPage).ceil();
              final cardAreaHeight = perPage == 4 ? 190.0 : 210.0;

              return Column(
                children: [
                  SizedBox(
                    height: cardAreaHeight,
                    child: Row(
                      children: [
                        if (pageCount > 1)
                          IconButton(
                            onPressed: () {
                              if (currentPage > 0) {
                                controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.red,
                            ),
                          ),
                        Expanded(
                          child: PageView.builder(
                            controller: controller,
                            itemCount: pageCount,
                            onPageChanged: (i) =>
                                setState(() => currentPage = i),
                            itemBuilder: (context, pageIndex) {
                              final pageItems = reviews
                                  .skip(pageIndex * perPage)
                                  .take(perPage)
                                  .toList();
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: pageItems
                                    .map((r) => Expanded(child: _reviewCard(r)))
                                    .toList(),
                              );
                            },
                          ),
                        ),
                        if (pageCount > 1)
                          IconButton(
                            onPressed: () {
                              if (currentPage < pageCount - 1) {
                                controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (pageCount > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pageCount, (i) {
                        final isActive = i == currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.red : Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TYPEWRITER TEXT (تأثير كتابة تدريجية لعنوان الهيرو)
// ============================================================
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const _TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _visible = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    var i = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 28), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      i++;
      setState(() {
        _visible = widget.text.substring(0, i.clamp(0, widget.text.length));
      });
      if (i >= widget.text.length) {
        t.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // بنحجز مساحة النص كامل بشفافية صفر عشان الأسطر متقفزش وهي بتتكتب
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0,
          child: Text(
            widget.text,
            textAlign: widget.textAlign,
            style: widget.style,
          ),
        ),
        Text(
          _visible,
          textAlign: widget.textAlign,
          style: widget.style,
        ),
      ],
    );
  }
}

// ============================================================
// FLOATING PARTICLES (جسيمات ضوئية خفيفة فوق صورة الهيرو)
// ============================================================
class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_HeroParticle> _particles =
      List.generate(16, (i) => _HeroParticle.random(i));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _HeroParticlesPainter(_particles, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _HeroParticle {
  final double dx; // موقع أفقي نسبي 0..1
  final double speed; // سرعة نسبية
  final double size; // قطر الجسيم
  final double phase; // إزاحة زمنية عشان الجسيمات متبقاش متزامنة

  _HeroParticle({
    required this.dx,
    required this.speed,
    required this.size,
    required this.phase,
  });

  factory _HeroParticle.random(int seed) {
    final rnd = math.Random(seed * 97 + 13);
    return _HeroParticle(
      dx: rnd.nextDouble(),
      speed: 0.4 + rnd.nextDouble() * 0.9,
      size: 1.5 + rnd.nextDouble() * 2.5,
      phase: rnd.nextDouble(),
    );
  }
}

class _HeroParticlesPainter extends CustomPainter {
  final List<_HeroParticle> particles;
  final double t;

  _HeroParticlesPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y = size.height * (1 - progress);
      final x = size.width * p.dx +
          math.sin(progress * 2 * math.pi) * 10;
      final fade = math.sin(progress * math.pi).clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: 0.5 * fade);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroParticlesPainter oldDelegate) => true;
}

// ============================================================
// HERO BANNER ITEM (عنصر واحد في سلايدر الهيرو: صورة أو فيديو)
// ============================================================
class _HeroBannerItem {
  final String url;
  final bool isVideo;
  final bool isAsset; // true لو أصل محلي جوه assets، مش رابط شبكة

  const _HeroBannerItem({
    required this.url,
    required this.isVideo,
    required this.isAsset,
  });
}

// ============================================================
// HERO MEDIA (بتعرض صورة أو فيديو حسب نوع العنصر)
// ============================================================
class _HeroMedia extends StatefulWidget {
  final _HeroBannerItem item;

  const _HeroMedia({required this.item});

  @override
  State<_HeroMedia> createState() => _HeroMediaState();
}

class _HeroMediaState extends State<_HeroMedia> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      _initVideo();
    }
  }

  void _initVideo() {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.item.url));
    _controller = controller;
    controller
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        controller.play();
      }).catchError((_) {
        // لو الفيديو فشل، هيفضل الخلفية سادة (fallback بسيط)
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _errorFallback() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(
          Icons.directions_car,
          size: 100,
          color: Colors.white24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.isVideo) {
      final controller = _controller;
      if (controller == null || !_ready) {
        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ),
        );
      }
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    if (widget.item.isAsset) {
      return Image.asset(
        widget.item.url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _errorFallback(),
      );
    }

    return Image.network(
      widget.item.url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _errorFallback(),
    );
  }
}

// ============================================================
// LAZY SECTION (تأثير ظهور تدريجي لكل قسم في الصفحة الرئيسية،
// وبيتربط مع SliverList عشان القسم البعيد عن الشاشة أصلاً ميتبنيش
// (يتحمّل) غير لما الزائر يقرّب منه بالسكرول)
// ============================================================
class _LazySection extends StatefulWidget {
  final int index;
  final Widget child;

  const _LazySection({required this.index, required this.child});

  @override
  State<_LazySection> createState() => _LazySectionState();
}

class _LazySectionState extends State<_LazySection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // بنأخّر بداية كل قسم شوية عن اللي قبله، عشان الأقسام تبان
    // بترتيب واحد ورا التاني بدل ما تطلع كلها مرة واحدة — والتأخير
    // محدود بحد أقصى عشان قسم بعيد اتبنى بسبب سكرول سريع ميستناش
    // كتير.
    final delayMs = 70 * widget.index;
    final delay = Duration(milliseconds: delayMs > 300 ? 300 : delayMs);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

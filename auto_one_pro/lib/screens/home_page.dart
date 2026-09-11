import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../shared/widgets.dart';
import '../screens/car_details_page.dart';

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
    'assets/youssefcar22.jpg',
    'assets/youssefcar3.jpg',
    'assets/youssefcar4.jpg',
    'assets/youssefcar5.jpg',
  ];
  
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
          // ====================================================
          // CAROUSEL
          // ====================================================

        LayoutBuilder(
    builder: (context, constraints) {
      // بقت بتاخد ارتفاع الشاشة كامل عشان الهيدر يبان شفاف فوقها
      // بدل ما تكون مربوطة بارتفاع ثابت تحت الهيدر.
      final heroHeight = MediaQuery.of(context).size.height;

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // الصورة كاملة (Netflix-style) بدل ما تبقى نص الكارت بس
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 550),
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    images[safeImageIndex],
                    key: ValueKey(images[safeImageIndex]),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
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

                // تظليل تدريجي أسود من تحت عشان النص يبقى واضح فوق الصورة
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.75],
                    ),
                  ),
                ),

                // (اللوجو بقى ظاهر أوتوماتيك من الهيدر الشفاف اللي بيطفو
                // فوق الصورة، فمحتاجين لوجو تاني منفصل هنا)

                // النص فوق الصورة مباشرة
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.isArabic
                              ? slideTexts[safeImageIndex]['ar']!
                              : slideTexts[safeImageIndex]['en']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            height: 1.3,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.isArabic
                              ? slideDescriptions[safeImageIndex]['ar']!
                              : slideDescriptions[safeImageIndex]['en']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 4,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                width: isActive ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.redAccent
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // سهمين على حافتي الصورة (زي باقي السلايدرات في الصفحة)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Transform.scale(
                      scale: 0.85,
                      child: CarouselArrow(
                        icon: Icons.arrow_back_ios_new,
                        onTap: previousImage,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Transform.scale(
                      scale: 0.85,
                      child: CarouselArrow(
                        icon: Icons.arrow_forward_ios,
                        onTap: nextImage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      );
    },
  ),

BrandStrip(
  isArabic: widget.isArabic,
  onBrandTap: (brand) {
    widget.onOpenCars(brand);
  },
),

Container(
  color: Colors.white,
  width: double.infinity,
  height: 20,
),

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
        Positioned(
          right: 0,
          top: 0,
          bottom: 14,
          child: Container(
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Transform.scale(
              scale: 0.65,
              child: CarouselArrow(
                icon: Icons.arrow_back_ios_new,
                onTap: () => _scrollBy(_featuredCarsScrollController, 320),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 14,
          child: Container(
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: Transform.scale(
              scale: 0.65,
              child: CarouselArrow(
                icon: Icons.arrow_forward_ios,
                onTap: () => _scrollBy(_featuredCarsScrollController, -320),
              ),
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


class _BrandStripState extends State<BrandStrip> {
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
  final ScrollController _brandsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _brandsScrollController.dispose();
    super.dispose();
  }

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
              styledHorizontalScrollbar(
            controller: _brandsScrollController,
            child: SingleChildScrollView(
              controller: _brandsScrollController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
              children: brandItems.map((item) {
                final label = item['label']!;
                final matchKey = item['matchKey']!;
                final logo = item['logo']!;

                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 14,
                  ),
                  child: HoverLift(
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                    onTap: () => widget.onBrandTap(matchKey),
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
                              child: logo.isEmpty
                                  ? const Icon(
                                      Icons.directions_car_filled_rounded,
                                      size: 40,
                                      color: Colors.red,
                                    )
                                  : carImageAdaptive(
                                      logo,
                                      fit: BoxFit.contain,
                                      showWatermark: false,
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
                            label,
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
            ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 14,
                child: Container(
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Transform.scale(
                    scale: 0.65,
                    child: CarouselArrow(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => _scrollBy(_brandsScrollController, 320),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 14,
                child: Container(
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Transform.scale(
                    scale: 0.65,
                    child: CarouselArrow(
                      icon: Icons.arrow_forward_ios,
                      onTap: () => _scrollBy(_brandsScrollController, -320),
                    ),
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

                const SizedBox(height: 5),

                // =================================================
                // BUTTONS
                // =================================================

                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 15,
                        ),
                        label: Text(
                          isArabic
                              ? 'واتساب'
                              : 'WHATSAPP',
                        ),
                        style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xff25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 9),

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
                        icon: const Icon(
                          Icons.description_outlined,
                          size: 15,
                        ),
                        label: Text(
                          isArabic
                              ? 'التفاصيل'
                              : 'DETAILS',
                        ),
                      style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xff0B0B0B),
  foregroundColor: Colors.white,
  elevation: 0,
  padding: const EdgeInsets.symmetric(
    vertical: 9,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(11),
  ),
  textStyle: const TextStyle(
    fontSize: 12,
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


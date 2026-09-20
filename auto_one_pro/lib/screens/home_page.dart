import 'dart:async';
import 'package:flutter/material.dart';
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
          const SizedBox(height: 35),

          // ====================================================
          // CAROUSEL
          // ====================================================

        LayoutBuilder(
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

                        // اللوجو الحقيقي (بقى أكبر شوية)
                       Image.asset(
  'assets/logo-autoone.png',
  width: isSmall ? 160 : 200,
  height: isSmall ? 92 : 112,
  fit: BoxFit.contain,
),

                        const SizedBox(height: 22),

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

Container(
  color: Colors.white,
  width: double.infinity,
  height: 20,
),

          const SizedBox(height: 50),
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
const SizedBox(height: 35),

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

const SizedBox(height: 50),

_FinancingPartnersCarousel(isArabic: widget.isArabic),

const SizedBox(height: 50),

_ReviewsCarousel(isArabic: widget.isArabic),

const SizedBox(height: 40),

AutoOneFooter(isArabic: widget.isArabic),

        ],
      ),
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
                bottom: 0,
                child: Transform.scale(
                  scale: 0.5,
                  child: CarouselArrow(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => _scrollBy(_brandsScrollController, 320),
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
                    onTap: () => _scrollBy(_brandsScrollController, -320),
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
    extends State<_FinancingPartnersCarousel> {
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

  @override
  Widget build(BuildContext context) {
    final partners = financingPartnersCache;
    if (partners.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final perPage = outerConstraints.maxWidth >= 900
            ? 5
            : outerConstraints.maxWidth >= 600
                ? 3
                : 2;
        final pageCount = (partners.length / perPage).ceil();

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
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: pageCount,
                    onPageChanged: (i) => setState(() => currentPage = i),
                    itemBuilder: (context, pageIndex) {
                      final pageItems = partners
                          .skip(pageIndex * perPage)
                          .take(perPage)
                          .toList();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: pageItems.map((p) {
                          final logo = (p['logo_url'] ?? '').toString();
                          final name = widget.isArabic
                              ? (p['name_ar'] ?? '').toString()
                              : ((p['name_en'] ?? '').toString().isEmpty
                                  ? (p['name_ar'] ?? '').toString()
                                  : p['name_en'].toString());

                          return Container(
                            width: 130,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 56,
                                  width: 90,
                                  child: logo.isEmpty
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_rounded,
                                            color: Colors.red,
                                            size: 28,
                                          ),
                                        )
                                      : carImageAdaptive(
                                          logo,
                                          fit: BoxFit.contain,
                                          showWatermark: false,
                                        ),
                                ),
                                const SizedBox(height: 12),
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
                        }).toList(),
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
                    icon: const Icon(Icons.chevron_left_rounded),
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
      ),
    );
      },
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
  static const int perPage = 5;

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

  @override
  Widget build(BuildContext context) {
    final reviews = approvedReviewsCache;
    if (reviews.isEmpty) return const SizedBox.shrink();

    final pageCount = (reviews.length / perPage).ceil();

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
          SizedBox(
            height: 190,
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
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: pageCount,
                    onPageChanged: (i) => setState(() => currentPage = i),
                    itemBuilder: (context, pageIndex) {
                      final pageItems = reviews
                          .skip(pageIndex * perPage)
                          .take(perPage)
                          .toList();
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pageItems.map((r) {
                          final name = (r['customer_name'] ?? '').toString();
                          final text = (r['review_text'] ?? '').toString();
                          final initial =
                              name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                32,
                                12,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.06),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: -32,
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
                                          radius: 24,
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
                                  Column(
                                    children: [
                                      const SizedBox(height: 12),
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
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                    icon: const Icon(Icons.chevron_left_rounded),
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
      ),
    );
  }
}

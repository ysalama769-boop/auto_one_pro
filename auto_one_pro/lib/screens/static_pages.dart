import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../admin/admin_shared.dart';
import '../shared/widgets.dart';

// ============================================================
// ABOUT AUTO ONE PAGE (نبذة عن المعرض + طريقة الشراء)
// ============================================================
class AboutAutoOnePage extends StatelessWidget {
  final bool isArabic;

  const AboutAutoOnePage({super.key, required this.isArabic});

  // أيقونات ثابتة لكروت "خدماتنا" (النصوص بس قابلة للتعديل من
  // التحكم، الأيقونات مرتبطة بترتيب الكارت).
  static const List<IconData> _serviceIcons = [
    Icons.local_car_wash_rounded,
    Icons.auto_awesome_rounded,
    Icons.door_front_door_rounded,
    Icons.thermostat_rounded,
    Icons.videocam_rounded,
    Icons.event_seat_rounded,
    Icons.format_paint_rounded,
    Icons.shield_rounded,
  ];

  Widget _pageTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 3,
          width: 70,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = homepageSettings.value;

    String t(String key, String fallback) {
      final value = settings?[key]?.toString().trim();
      return (value == null || value.isEmpty) ? fallback : value;
    }

    final aboutImage = (settings?['about_image'] ?? '').toString().trim();
    final historyImage = (settings?['history_image'] ?? '').toString().trim();

    final rawPartners = settings?['brand_partners'];
    final brandPartners = (rawPartners is List)
        ? rawPartners
            .whereType<Map>()
            .map((e) => isArabic
                ? (e['text_ar'] ?? '').toString()
                : ((e['text_en'] ?? '').toString().isEmpty
                    ? (e['text_ar'] ?? '').toString()
                    : e['text_en'].toString()))
            .where((s) => s.trim().isNotEmpty)
            .toList()
        : <String>[];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'من نحن' : 'About Us'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ====================================================
              // نبذة عنا
              // ====================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _pageTitle(
                          isArabic ? 'من نحن' : 'About Us',
                          isArabic
                              ? 'تعرف على قصتنا ومبادئنا'
                              : 'Learn about our story and principles',
                        ),
                        const SizedBox(height: 36),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 800;
                            final imageWidget = ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 16 / 10,
                                child: aboutImage.isEmpty
                                    ? Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.directions_car_filled_rounded,
                                          size: 70,
                                          color: Colors.black26,
                                        ),
                                      )
                                    : carImageAdaptive(
                                        aboutImage,
                                        fit: BoxFit.cover,
                                        showWatermark: false,
                                      ),
                              ),
                            );

                            final textWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'نبذة عنا' : 'About Us',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 3,
                                  width: 50,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  isArabic
                                      ? t(
                                          'about_intro_ar',
                                          'AUTO ONE معرض سيارات يهتم بتقديم تجربة شراء موثوقة وسهلة، بأسعار تنافسية ومجموعة مختارة بعناية من السيارات.',
                                        )
                                      : t(
                                          'about_intro_en',
                                          'AUTO ONE is a car showroom focused on offering a trusted and easy buying experience, with competitive prices and a carefully selected range of cars.',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.9,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  isArabic
                                      ? t(
                                          'about_offer_ar',
                                          'نوفّر لك مجموعة متنوعة من السيارات بموديلات وفئات مختلفة، مع معلومات وصور واضحة لكل سيارة عشان تقدر تاخد قرارك بثقة.',
                                        )
                                      : t(
                                          'about_offer_en',
                                          'We provide a diverse range of cars across different models and categories, with clear information and photos for every car so you can decide with confidence.',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.9,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  isArabic
                                      ? t(
                                          'about_goal_ar',
                                          'هدفنا إننا نسهّل عليك رحلة اختيار وشراء سيارتك من البداية للنهاية، مع دعم وتواصل سريع في أي وقت تحتاجه.',
                                        )
                                      : t(
                                          'about_goal_en',
                                          'Our goal is to make your car-buying journey simple from start to finish, with fast support whenever you need it.',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.9,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            );

                            if (isSmall) {
                              return Column(
                                children: [
                                  imageWidget,
                                  const SizedBox(height: 26),
                                  textWidget,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: imageWidget),
                                const SizedBox(width: 48),
                                Expanded(child: textWidget),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ====================================================
              // تاريخنا (بانر غامق)
              // ====================================================
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0B),
                  image: historyImage.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(historyImage),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.55),
                            BlendMode.darken,
                          ),
                        ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic
                          ? t('about_history_title_ar', 'تاريخنا')
                          : t('about_history_title_en', 'Our History'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic
                          ? t(
                              'about_history_subtitle_ar',
                              'حلول للمركبات بمستوى عالٍ من الجودة والثقة.',
                            )
                          : t(
                              'about_history_subtitle_en',
                              'Quality and trusted vehicle solutions.',
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // ====================================================
              // الماركات الحصرية (لو موجودة) — شكل شجري متعرّج
              // ====================================================
              if (brandPartners.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          _pageTitle(
                            isArabic
                                ? 'الماركات الحصرية'
                                : 'Exclusive Brands',
                            isArabic
                                ? 'موزّعون حصريون لعدد من أشهر الماركات العالمية'
                                : 'Exclusive distributors for leading global brands',
                          ),
                          const SizedBox(height: 30),
                          _BrandPartnersTree(items: brandPartners),
                        ],
                      ),
                    ),
                  ),
                ),

              // ====================================================
              // خدماتنا
              // ====================================================
              Container(
                width: double.infinity,
                color: const Color(0xfff9f9fa),
                padding: const EdgeInsets.symmetric(
                  vertical: 44,
                  horizontal: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        _pageTitle(
                          isArabic
                              ? t('about_services_title_ar', 'خدماتنا')
                              : t('about_services_title_en', 'Our Services'),
                          isArabic
                              ? t(
                                  'about_services_subtitle_ar',
                                  'وجهتك الموثوقة لحلول العناية المتكاملة بالسيارات.',
                                )
                              : t(
                                  'about_services_subtitle_en',
                                  'Your trusted destination for complete car care solutions.',
                                ),
                        ),
                        const SizedBox(height: 30),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 900
                                ? 4
                                : constraints.maxWidth >= 600
                                    ? 2
                                    : 1;
                            final cardWidth =
                                (constraints.maxWidth - (columns - 1) * 16) /
                                    columns;

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: List.generate(8, (i) {
                                final title = isArabic
                                    ? t(
                                        'about_service${i + 1}_title_ar',
                                        _defaultServiceAr(i),
                                      )
                                    : t(
                                        'about_service${i + 1}_title_en',
                                        _defaultServiceEn(i),
                                      );
                                return SizedBox(
                                  width: cardWidth,
                                  child: HoverLift(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _serviceIcons[i],
                                              color: Colors.red,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ====================================================
              // ليه أوتو ون؟ (بنفس نصوص قسم "لماذا AUTO ONE" بالرئيسية)
              // ====================================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 44,
                  horizontal: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        _pageTitle(
                          siteText(
                            key: 'why_title',
                            isArabic: isArabic,
                            defaultAr: 'ليه أوتو ون؟',
                            defaultEn: 'WHY AUTO ONE?',
                          ),
                          siteText(
                            key: 'why_subtitle',
                            isArabic: isArabic,
                            defaultAr: 'تجربة مختلفة في اختيار وشراء سيارتك',
                            defaultEn:
                                'A different experience in choosing and buying your car',
                          ),
                        ),
                        const SizedBox(height: 30),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 700
                                ? 2
                                : 1;
                            final cardWidth =
                                (constraints.maxWidth - (columns - 1) * 16) /
                                    columns;

                            final items = [
                              (
                                Icons.local_offer_rounded,
                                siteText(
                                  key: 'why_card1_title',
                                  isArabic: isArabic,
                                  defaultAr: 'اختيارات متنوعة',
                                  defaultEn: 'WIDE SELECTION',
                                ),
                                siteText(
                                  key: 'why_card1_desc',
                                  isArabic: isArabic,
                                  defaultAr:
                                      'مجموعة متنوعة من السيارات والموديلات لتختار ما يناسبك.',
                                  defaultEn:
                                      'A wide selection of cars and models to match your needs.',
                                ),
                              ),
                              (
                                Icons.price_check_rounded,
                                siteText(
                                  key: 'why_card2_title',
                                  isArabic: isArabic,
                                  defaultAr: 'أسعار منافسة',
                                  defaultEn: 'COMPETITIVE PRICES',
                                ),
                                siteText(
                                  key: 'why_card2_desc',
                                  isArabic: isArabic,
                                  defaultAr:
                                      'أسعار مدروسة وعروض مميزة على مجموعة من السيارات.',
                                  defaultEn:
                                      'Competitive prices and special offers on selected cars.',
                                ),
                              ),
                              (
                                Icons.handshake_rounded,
                                siteText(
                                  key: 'why_card3_title',
                                  isArabic: isArabic,
                                  defaultAr: 'خدمة موثوقة',
                                  defaultEn: 'RELIABLE SERVICE',
                                ),
                                siteText(
                                  key: 'why_card3_desc',
                                  isArabic: isArabic,
                                  defaultAr:
                                      'نهتم بتقديم تجربة واضحة ومريحة من البداية للنهاية.',
                                  defaultEn:
                                      'A clear and comfortable experience from start to finish.',
                                ),
                              ),
                              (
                                Icons.support_agent_rounded,
                                siteText(
                                  key: 'why_card4_title',
                                  isArabic: isArabic,
                                  defaultAr: 'تواصل سريع',
                                  defaultEn: 'FAST SUPPORT',
                                ),
                                siteText(
                                  key: 'why_card4_desc',
                                  isArabic: isArabic,
                                  defaultAr:
                                      'تواصل معنا بسهولة واحصل على المساعدة التي تحتاجها.',
                                  defaultEn:
                                      'Reach out easily and get the help you need.',
                                ),
                              ),
                            ];

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: List.generate(items.length, (i) {
                                final isRed = i == 1 || i == 3;
                                final (icon, title, desc) = items[i];
                                return SizedBox(
                                  width: cardWidth,
                                  child: Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color:
                                          isRed ? Colors.red : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: isRed
                                          ? null
                                          : Border.all(color: Colors.black12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 10,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isRed
                                                ? Colors.white
                                                    .withValues(alpha: 0.18)
                                                : Colors.red
                                                    .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: isRed
                                                ? Colors.white
                                                : Colors.red,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: isRed
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          desc,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.6,
                                            color: isRed
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ====================================================
              // طريقة الشراء
              // ====================================================
              Container(
                width: double.infinity,
                color: const Color(0xfff6f6f8),
                padding: const EdgeInsets.symmetric(
                  vertical: 44,
                  horizontal: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        _pageTitle(
                          isArabic ? 'طريقة الشراء' : 'How to Buy',
                          isArabic
                              ? 'خطوات بسيطة توصلك لسيارتك'
                              : 'Simple steps to get your car',
                        ),
                        const SizedBox(height: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < 5; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Text(
                                          isArabic
                                              ? t('step${i + 1}_ar',
                                                  _defaultStepAr(i))
                                              : t('step${i + 1}_en',
                                                  _defaultStepEn(i)),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              AutoOneFooter(isArabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultServiceAr(int i) {
    const defaults = [
      'غسيل واكس احترافي للسيارات',
      'خدمات النانو سيراميك بمختلف أشكالها',
      'حماية أطراف ومقابض الأبواب',
      'تظليل العازل الحراري بضمان مفتوح',
      'داش كام بأنظمة وتقنيات عالية',
      'أرضيات جلد خام بتركيب ديناميكي',
      'طلاء السيارات وتلميع داخلي وخارجي',
      'حماية داخلية وخارجية',
    ];
    return defaults[i];
  }

  String _defaultServiceEn(int i) {
    const defaults = [
      'Professional car wash & wax',
      'Nano ceramic coating services',
      'Door edge & handle protection',
      'Thermal insulation tinting with open warranty',
      'High-tech dash cams',
      'Raw leather flooring with dynamic fitting',
      'Interior & exterior paint polishing',
      'Interior & exterior protection',
    ];
    return defaults[i];
  }

  String _defaultStepAr(int i) {
    const defaults = [
      'اختر سيارتك',
      'اضغط طلب حجز',
      'سجّل بياناتك',
      'فريق AUTO ONE يتواصل معك',
      'يتم استكمال إجراءات الشراء',
    ];
    return defaults[i];
  }

  String _defaultStepEn(int i) {
    const defaults = [
      'Choose your car',
      'Tap "Request Booking"',
      'Fill in your details',
      'The AUTO ONE team contacts you',
      'Purchase procedures are completed',
    ];
    return defaults[i];
  }
}

// ============================================================
// BRAND PARTNERS TREE (شكل شجري متعرّج للماركات الحصرية)
// ============================================================
class _BrandPartnersTree extends StatelessWidget {
  final List<String> items;

  const _BrandPartnersTree({required this.items});

  static const double _boxWidth = 340;
  static const double _rowHeight = 110;
  static const double _centerWidth = 70;

  Widget _card(String text) {
    return Container(
      width: _boxWidth,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 3, width: 60, color: Colors.red),
        ],
      ),
    );
  }

  Widget _spine(bool isRight, bool isFirst, bool isLast) {
    return SizedBox(
      width: _centerWidth,
      height: _rowHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الخط الرأسي المستمر عبر كل الصفوف
          Positioned(
            top: isFirst ? _rowHeight / 2 : 0,
            bottom: isLast ? _rowHeight / 2 : 0,
            child: Container(width: 2, color: Colors.red.shade200),
          ),
          // الخط الأفقي القصير اللي بيوصل للكارت
          Align(
            alignment:
                isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _centerWidth / 2,
              height: 2,
              color: Colors.red.shade300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final treeWidth = _boxWidth * 2 + _centerWidth;
        final isSmall = constraints.maxWidth < treeWidth + 20;

        if (isSmall) {
          // على الموبايل: قايمة بسيطة بدل الشكل الشجري
          return Column(
            children: items
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _card(text),
                  ),
                )
                .toList(),
          );
        }

        return Center(
          child: SizedBox(
            width: treeWidth,
            child: Column(
              children: List.generate(items.length, (i) {
                final isRight = i.isEven;
                final isFirst = i == 0;
                final isLast = i == items.length - 1;
                final card = _card(items[i]);

                return SizedBox(
                  height: _rowHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: _boxWidth,
                        child: isRight
                            ? null
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: card,
                              ),
                      ),
                      _spine(isRight, isFirst, isLast),
                      SizedBox(
                        width: _boxWidth,
                        child: isRight
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: card,
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
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

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget body,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  Widget _p(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, height: 1.9, color: Colors.black87),
      ),
    );
  }

  Widget _numbered(int n, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isArabic) {
      // النسخة الإنجليزية القديمة، محتاجة ترجمة للنص التفصيلي الجديد لاحقًا
      const content =
          '''By using the AUTO ONE app, you agree to the following terms and conditions.

Booking requests
A booking made through the app is an initial request and is not considered final until confirmed by the AUTO ONE team.

Accuracy of information
You must provide accurate details (name, phone number, contact method) when booking, so we can reach you.

Pricing and availability
Prices and availability shown in the app are subject to change, and final details will be confirmed when we contact you.

Modification and cancellation
We reserve the right to accept or decline any booking request based on car availability.

This is generic starter text — please review it with a legal professional and customize it to your business.''';

      return Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color(0xfff6f6f8),
          appBar: AppBar(
            backgroundColor: kHeaderColor,
            foregroundColor: kHeaderTextColor,
            title: const Text('Terms & Conditions'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const Text(
                  content,
                  style: TextStyle(fontSize: 14, height: 1.8),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: const Text('الشروط والأحكام'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'الشروط والأحكام',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'نحن في معرض اوتو ون نلتزم بالشفافية والوضوح في جميع تعاملاتنا. تحدد هذه الصفحة الشروط والأحكام التي تحكم استخدامك لخدماتنا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5, color: Colors.black54, height: 1.7),
                  ),
                  const SizedBox(height: 28),
                  _sectionCard(
                    icon: Icons.gpp_maybe_rounded,
                    title: 'إخلاء المسؤولية والتنازل عن المطالبات',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _p(
                            'إن الموقع الإلكتروني والخدمات الإلكترونية المقدمة من خلاله، والمعلومات والمواد والوظائف المتاحة عبره أو التي يمكن الوصول إليها من خلاله، يتم توفيرها لاستخدامكم الشخصي "كما هي" و"كما هي متاحة" دون أي إقرارات أو ضمانات من أي نوع، سواء كانت صريحة أو ضمنية.'),
                        _p(
                            'ولا يتحمل معرض اوتو ون للسيارات أي مسؤولية عن أي انقطاعات أو أخطاء أو أعطال قد تنشأ عن استخدام الموقع أو محتوياته أو أي مواقع مرتبطة به، سواء كان ذلك بعلم الشركة أو من دون علمها.'),
                        _p(
                            'كما أن أي مراسلات أو معلومات يرسلها المستخدم عبر الموقع لا تُعتبر مملوكة له، ولا تضمن الشركة سريتها بشكل كامل. ويُفهم أن أي استخدام تفاعلي أو عام ضمن الموقع لا يمنح المستخدم أي حقوق أو تراخيص أو امتيازات من أي نوع.'),
                      ],
                    ),
                  ),
                  _sectionCard(
                    icon: Icons.security_rounded,
                    title: 'الحماية من الفيروسات',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _p(
                            'تبذل إدارة تقنية المعلومات في معرض اوتو ون للسيارات أقصى جهد ممكن لفحص واختبار المحتوى الإلكتروني في جميع المراحل. ومع ذلك، فإننا نوصي المستخدمين دائماً باستخدام برامج الحماية من الفيروسات عند تحميل أي مواد من الإنترنت.'),
                        _p(
                            'ولا يتحمل المعرض أي مسؤولية عن أي فقد أو تلف أو ضرر قد يصيب بياناتكم أو أجهزتكم نتيجة الدخول إلى الموقع أو استخدام أي من محتوياته.'),
                      ],
                    ),
                  ),
                  _sectionCard(
                    icon: Icons.block_rounded,
                    title: 'إنهاء الاستخدام',
                    body: _p(
                        'تحتفظ الشركة بحقها الكامل، وحسب تقديرها المطلق، في إنهاء أو تقييد أو إيقاف حق المستخدم في الدخول إلى الموقع أو استخدام أي من خدماته دون إشعار مسبق، وذلك لأي سبب، بما في ذلك على سبيل المثال لا الحصر: مخالفة شروط الاستخدام أو القيام بأي سلوك تعتبره الشركة غير قانوني أو ضاراً بالآخرين.'),
                  ),
                  _sectionCard(
                    icon: Icons.rule_rounded,
                    title: 'شروط عامة',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _numbered(1, 'المواد والمعلومات',
                            'تقدم جميع المواد والمعلومات والخدمات المتاحة عبر الموقع "كما هي" دون أي التزام بضمان دقتها أو صلاحيتها كعروض أسعار، وهي غير ملزمة للشركة بأي شكل من الأشكال.'),
                        _numbered(2, 'اللغة الأساسية',
                            'اللغة العربية هي اللغة الأساسية للموقع، وأي ترجمة يتم توفيرها هي خدمة إضافية لا يُعتمد عليها في تفسير الخلافات.'),
                        _numbered(3, 'القبول',
                            'دخولك إلى الموقع واستخدامك له يعني قبولك الكامل وغير المشروط لهذه الشروط والأحكام.'),
                        _numbered(4, 'عدم الاعتماد على المعلومات',
                            'نحن لا نضمن أن المعلومات المقدمة على الموقع دقيقة أو كاملة أو محدثة. يجب عليك الحصول على مشورة مهنية قبل اتخاذ أي قرارات بناءً على المحتوى من أحد أعضاء فريق المبيعات لدى شركة الخضر للسيارات أو الاتصال على الرقم الموحد 920011895. يبذل المعرض الجهود الممكنة للتأكد من أن المعلومات الواردة في هذا الموقع صحيحة، لكن لا يمكن ضمان الدقة الكاملة وخلو الأخطاء.'),
                        _numbered(5, 'الأسعار والأقساط',
                            'المعلومات المعروضة أو المقدمة عبر هذا الموقع هي للاستفادة والمعلومة الأولية فقط وقد يتم تغييرها دون إشعار ولا تشكل عرضًا لبيع المنتجات. الأسعار هي أسعار بيع التجزئة فقط. الأقساط المحتسبة غير نهائية وتحدد لاحقًا وفقًا لشروط وأحكام شركة التمويل أو البنك الذي سيتم التمويل من خلاله، وتتفاوت بناءً على المبلغ والدفعة المقدمة.'),
                      ],
                    ),
                  ),
                  _sectionCard(
                    icon: Icons.assignment_ind_rounded,
                    title: 'التزامات المستخدم',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _p(
                            'عند دخولك إلى الموقع، فإنك توافق على استخدام الموقع لأغراض مشروعة فقط، والامتثال لجميع القوانين والأنظمة المعمول بها، والامتناع عن:'),
                        _bullet(
                            'ارتكاب أي فعل غير قانوني أو تشجيع الغير على ذلك'),
                        _bullet(
                            'إدخال أو نشر أي محتوى غير قانوني أو مسيء أو مخالف للآداب'),
                        _bullet('انتحال صفة أي شخص أو جهة دون تفويض'),
                        _bullet(
                            'تحميل أي ملفات أو برامج تحتوي على فيروسات أو شفرات ضارة'),
                        _bullet(
                            'التلاعب أو حذف أو تعديل أي محتوى على الموقع دون إذن'),
                        _bullet(
                            'تعطيل أو التدخل في البنية التحتية أو أنظمة الاتصال الخاصة بالموقع'),
                        _bullet('نشر أي محتوى دعائي أو تجاري غير مصرح به'),
                        _bullet(
                            'انتهاك حقوق الملكية الفكرية أو جمع بيانات شخصية عن الآخرين دون إذن'),
                      ],
                    ),
                  ),
                  _sectionCard(
                    icon: Icons.how_to_reg_rounded,
                    title: 'التسجيل',
                    body: _p(
                        'بتقديمك معلوماتك الشخصية عبر الموقع، فإنك تقر بأن جميع البيانات المقدمة صحيحة ودقيقة، وأنك لن تسجل أو تحاول الدخول باسم شخص آخر، أو باستخدام اسم مستخدم تعتبره الشركة غير مناسب.'),
                  ),
                  _sectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'المحتوى',
                    body: _p(
                        'يحتفظ معرض اوتو ون للسيارات بحقه في مراقبة أي محتوى يتم إدخاله من قبل المستخدمين، مع أنه غير ملزم بذلك. ويجوز للمعرض، وفق تقديره، حذف أو تعديل أي محتوى مخالف لهذه الشروط والأحكام دون أي التزام مسبق.'),
                  ),
                  _sectionCard(
                    icon: Icons.gavel_rounded,
                    title: 'القانون والاختصاص القضائي',
                    body: _p(
                        'تخضع هذه الشروط والأحكام للأنظمة والقوانين المعمول بها في المملكة العربية السعودية، وتختص المحاكم السعودية بالنظر في أي نزاع ينشأ عنها.'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

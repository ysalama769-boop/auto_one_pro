import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../shared/constants.dart';
import '../shared/favorites_compare.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../screens/static_pages.dart';
import '../screens/car_details_page.dart';
import '../screens/favorites_page.dart';

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
  final VoidCallback onCars;
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
    final isMobile =
                 MediaQuery.of(context).size.width < 700;
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
          : const BoxDecoration(
              color: Color.fromARGB(255, 238, 221, 221),
            ),

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
    lightText: transparent,
    onTap: onHome,
  ),

  const SizedBox(width: 10),

  HeaderButton(
    title: isArabic ? 'المعرض' : 'CARS',
    active: showCars,
    lightText: transparent,
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
        style: TextStyle(
          color: transparent
              ? Colors.white
              : const Color.fromARGB(255, 12, 12, 12),
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

  final Widget image = path.startsWith('http')
      ? Image.network(
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


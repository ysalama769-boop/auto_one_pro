import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../shared/widgets.dart';
import '../screens/car_booking_page.dart';

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


// ============================================================
// طلب تمويل — فورم مخصص بحقول تفصيلية + رسائل كريتيف للتحقق
// ============================================================
Future<void> _submitFinancingRequest(
  BuildContext context,
  Car car,
  bool isArabic,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: _FinancingRequestDialog(car: car, isArabic: isArabic),
    ),
  );
}


class _FinancingRequestDialog extends StatefulWidget {
  final Car car;
  final bool isArabic;
  const _FinancingRequestDialog({
    required this.car,
    required this.isArabic,
  });

  @override
  State<_FinancingRequestDialog> createState() =>
      _FinancingRequestDialogState();
}


class _FinancingRequestDialogState extends State<_FinancingRequestDialog> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final obligationsTypeCtrl = TextEditingController();
  final employerCtrl = TextEditingController();

  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final salaryFocus = FocusNode();
  final bankFocus = FocusNode();
  final obligationsTypeFocus = FocusNode();
  final employerFocus = FocusNode();

  final obligationsKey = GlobalKey();
  bool? hasObligations;
  bool obligationsError = false;
  bool isSending = false;
  String? selectedColorId;

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    salaryCtrl.dispose();
    bankCtrl.dispose();
    obligationsTypeCtrl.dispose();
    employerCtrl.dispose();
    nameFocus.dispose();
    phoneFocus.dispose();
    salaryFocus.dispose();
    bankFocus.dispose();
    obligationsTypeFocus.dispose();
    employerFocus.dispose();
    super.dispose();
  }

  void _showNudge(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            const Text('👋', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _focusAndScroll(FocusNode node) async {
    node.requestFocus();
  }

  bool _validateAndFocus() {
    if (nameCtrl.text.trim().isEmpty) {
      _focusAndScroll(nameFocus);
      _showNudge(
        isArabic
            ? 'يا هلا! اسمك إيه؟ محتاجينه الأول 😊'
            : "Hey! What's your name? We need it first 😊",
      );
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _focusAndScroll(phoneFocus);
      _showNudge(
        isArabic
            ? 'رقم جوالك ناقص! إزاي هنكلمك من غيره؟ 📱'
            : "Missing your phone number! How will we reach you? 📱",
      );
      return false;
    }
    if (salaryCtrl.text.trim().isEmpty) {
      _focusAndScroll(salaryFocus);
      _showNudge(
        isArabic
            ? 'الراتب فين؟ محتاجينه عشان نحسبلك أنسب تمويل 💰'
            : "What's your salary? We need it to work out your financing 💰",
      );
      return false;
    }
    if (bankCtrl.text.trim().isEmpty) {
      _focusAndScroll(bankFocus);
      _showNudge(
        isArabic
            ? 'راتبك بينزل على أي بنك؟ ماتنساش تقولنا 🏦'
            : "Which bank does your salary go to? Don't forget 🏦",
      );
      return false;
    }
    if (hasObligations == null) {
      setState(() => obligationsError = true);
      Scrollable.ensureVisible(
        obligationsKey.currentContext!,
        duration: const Duration(milliseconds: 300),
      );
      _showNudge(
        isArabic
            ? 'محتاجين نعرف، عندك التزامات شهرية ولا لأ؟ اختار من فوق ✅'
            : 'Do you have monthly obligations? Please choose above ✅',
      );
      return false;
    }
    if (hasObligations == true && obligationsTypeCtrl.text.trim().isEmpty) {
      _focusAndScroll(obligationsTypeFocus);
      _showNudge(
        isArabic
            ? 'قلت إن عندك التزامات، طيب نوعها إيه؟ ✍️'
            : "You said you have obligations, what type? ✍️",
      );
      return false;
    }
    if (employerCtrl.text.trim().isEmpty) {
      _focusAndScroll(employerFocus);
      _showNudge(
        isArabic
            ? 'شغال فين؟ اسم جهة العمل ناقص 🏢'
            : "Where do you work? Employer name is missing 🏢",
      );
      return false;
    }
    return true;
  }

  Future<void> _send() async {
    if (!_validateAndFocus()) return;

    setState(() => isSending = true);

    final colorList = carColorsCache[widget.car.id] ?? const <CarColor>[];
    String? selectedColorName;
    if (selectedColorId != null) {
      for (final c in colorList) {
        if (c.id == selectedColorId) {
          selectedColorName = isArabic ? c.nameAr : c.nameEn;
          break;
        }
      }
    }

    try {
      await Supabase.instance.client.from('customer_requests').insert({
        'customer_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'car_id': widget.car.id,
        'car_name': widget.car.name,
        'car_brand': widget.car.brand,
        'request_type': 'financing',
        'status': 'new',
        'salary': salaryCtrl.text.trim(),
        'bank_name': bankCtrl.text.trim(),
        'has_obligations': hasObligations,
        'obligations_type':
            hasObligations == true ? obligationsTypeCtrl.text.trim() : '',
        'employer': employerCtrl.text.trim(),
        'selected_color': selectedColorName ?? '',
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال طلب التمويل، هيتم التواصل معاك قريبًا'
                : 'Financing request sent, we will contact you soon',
          ),
        ),
      );
    } catch (e) {
      setState(() => isSending = false);
      if (!mounted) return;
      _showNudge(
        isArabic ? 'حصلت مشكلة، حاول تاني 🙏' : 'Something went wrong, try again 🙏',
      );
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isArabic ? 'طلب تمويل' : 'Financing request'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((carColorsCache[widget.car.id] ?? const <CarColor>[])
                  .isNotEmpty) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    isArabic ? 'اللون المطلوب (اختياري)' : 'Preferred color (optional)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      (carColorsCache[widget.car.id] ?? const <CarColor>[])
                          .map((color) {
                    final isSelected = selectedColorId == color.id;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColorId = color.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isSelected ? 36 : 30,
                        height: isSelected ? 36 : 30,
                        decoration: BoxDecoration(
                          color: Color(color.colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.black12,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: nameCtrl,
                focusNode: nameFocus,
                decoration: _decoration(isArabic ? 'الاسم' : 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                focusNode: phoneFocus,
                keyboardType: TextInputType.phone,
                decoration:
                    _decoration(isArabic ? 'رقم الجوال' : 'Phone number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: salaryCtrl,
                focusNode: salaryFocus,
                keyboardType: TextInputType.number,
                decoration: _decoration(isArabic ? 'الراتب' : 'Salary'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bankCtrl,
                focusNode: bankFocus,
                decoration: _decoration(
                  isArabic ? 'الراتب على أي بنك' : 'Salary bank',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                key: obligationsKey,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: obligationsError ? Colors.red : Colors.black26,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'هل عندك التزامات شهرية؟'
                          : 'Do you have monthly obligations?',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(isArabic ? 'أيوه' : 'Yes'),
                            selected: hasObligations == true,
                            onSelected: (_) => setState(() {
                              hasObligations = true;
                              obligationsError = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(isArabic ? 'لأ' : 'No'),
                            selected: hasObligations == false,
                            onSelected: (_) => setState(() {
                              hasObligations = false;
                              obligationsError = false;
                              obligationsTypeCtrl.clear();
                            }),
                          ),
                        ),
                      ],
                    ),
                    if (hasObligations == true) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: obligationsTypeCtrl,
                        focusNode: obligationsTypeFocus,
                        decoration: _decoration(
                          isArabic ? 'نوع الالتزامات' : 'Obligations type',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: employerCtrl,
                focusNode: employerFocus,
                decoration:
                    _decoration(isArabic ? 'جهة العمل' : 'Employer'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSending ? null : () => Navigator.of(context).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: isSending ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isArabic ? 'إرسال' : 'Send'),
        ),
      ],
    );
  }
}


// ============================================================
// FINANCING CALCULATOR — تقدير تقريبي للقسط الشهري
// ============================================================
class FinancingCalculatorCard extends StatefulWidget {
  final String price;
  final bool isArabic;

  const FinancingCalculatorCard({
    super.key,
    required this.price,
    required this.isArabic,
  });

  @override
  State<FinancingCalculatorCard> createState() =>
      _FinancingCalculatorCardState();
}


class _FinancingCalculatorCardState extends State<FinancingCalculatorCard> {
  double downPaymentPercent = 20;
  int months = 36;

  static const List<int> monthOptions = [12, 24, 36, 48, 60];

  double get _carPrice {
    final digitsOnly = widget.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digitsOnly) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final price = _carPrice;
    final downPayment = price * (downPaymentPercent / 100);
    final financedAmount = price - downPayment;

    // نسبة تمويل تقديرية بسيطة (مش عرض بنكي حقيقي)
    const yearlyRate = 0.0399;
    final years = months / 12;
    final totalWithProfit = financedAmount * (1 + (yearlyRate * years));
    final monthlyInstallment = months > 0 ? totalWithProfit / months : 0;

    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.calculate_outlined,
                color: Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'حاسبة التمويل' : 'FINANCING CALCULATOR',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // المقدم
          Row(
            children: [
              Text(
                isArabic ? 'المقدم' : 'Down payment',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${downPaymentPercent.round()}%  ·  '
                '${downPayment.toStringAsFixed(0)} '
                '${isArabic ? 'ريال' : 'SAR'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.red,
              thumbColor: Colors.red,
              inactiveTrackColor: Colors.white24,
              overlayColor: Colors.red.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: downPaymentPercent,
              min: 0,
              max: 80,
              divisions: 16,
              onChanged: (value) {
                setState(() => downPaymentPercent = value);
              },
            ),
          ),

          const SizedBox(height: 6),

          // مدة التمويل
          Text(
            isArabic ? 'مدة التمويل' : 'Financing duration',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: monthOptions.map((m) {
              final selected = m == months;
              return ChoiceChip(
                label: Text(
                  isArabic ? '$m شهر' : '$m mo',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                selected: selected,
                selectedColor: Colors.red,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                onSelected: (_) => setState(() => months = m),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isArabic
                        ? 'القسط الشهري التقريبي'
                        : 'Estimated monthly installment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${monthlyInstallment.toStringAsFixed(0)} '
                  '${isArabic ? 'ريال' : 'SAR'}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'ده تقدير تقريبي مش عرض تمويل رسمي، السعر النهائي بيحدده البنك أو جهة التمويل.'
                : 'This is a rough estimate, not an official offer — the final rate is set by the bank/financing provider.',
            style: const TextStyle(color: Colors.white38, fontSize: 10.5),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    _trackView();
  }

  // بيزوّد عداد المشاهدات مرة واحدة كل ما حد يفتح تفاصيل السيارة
  Future<void> _trackView() async {
    if (car.id == null) return;
    try {
      await Supabase.instance.client
          .rpc('increment_car_views', params: {'car_id_input': car.id});
    } catch (e) {
      // مش لازم يوقف عرض الصفحة لو فشل تسجيل المشاهدة
    }
  }

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
  heroTag: 'carDetailsWhatsAppFAB',
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
                  car.displayName(isArabic),
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

    const SizedBox(height: 10),

    SizedBox(
      width: 228,
      child: OutlinedButton.icon(
        onPressed: () => _submitFinancingRequest(context, car, isArabic),
        icon: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 16,
        ),
        label: Text(
          isArabic ? 'طلب تمويل' : 'Financing',
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.black26),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
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

          Widget specColumn(String title, List<Widget> cards) {
            if (cards.isEmpty) return const SizedBox.shrink();
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
                ...cards,
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

          // ==================================================
          // مواصفات إضافية (ديناميكية من لوحة التحكم)
          // ==================================================
          final extraCards = <Widget>[
            for (final entry in car.extraSpecs.entries)
              if (entry.value.trim().isNotEmpty)
                specCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: entry.key,
                  value: entry.value,
                ),
          ];

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
            specColumn(
              isArabic ? 'مواصفات إضافية' : 'MORE SPECS',
              extraCards,
            ),
          ].where((c) => c is! SizedBox).toList();

          if (wide) {
            final rowChildren = <Widget>[];
            for (var i = 0; i < columns.length; i++) {
              if (i > 0) rowChildren.add(const SizedBox(width: 20));
              rowChildren.add(Expanded(child: columns[i]));
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            );
          }

          final colChildren = <Widget>[];
          for (var i = 0; i < columns.length; i++) {
            if (i > 0) colChildren.add(const SizedBox(height: 20));
            colChildren.add(columns[i]);
          }
          return Column(
            children: colChildren,
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
                car.displayDescription(isArabic),
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

      // ============================================================
      // FINANCING CALCULATOR (تقدير تقريبي للقسط الشهري)
      // ============================================================
      const SizedBox(height: 24),
      FinancingCalculatorCard(
        price: car.price,
        isArabic: isArabic,
      ),
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


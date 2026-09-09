import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../shared/widgets.dart';

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
                                car.displayName(isArabic),
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


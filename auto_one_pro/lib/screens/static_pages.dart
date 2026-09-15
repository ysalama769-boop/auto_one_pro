import 'package:flutter/material.dart';
import '../shared/constants.dart';

// ============================================================
// ABOUT AUTO ONE PAGE (نبذة عن المعرض + طريقة الشراء)
// ============================================================
class AboutAutoOnePage extends StatelessWidget {
  final bool isArabic;

  const AboutAutoOnePage({super.key, required this.isArabic});

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _bulletBlock(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.8, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              '$number',
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
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
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
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'عن AUTO ONE' : 'About AUTO ONE'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(isArabic ? 'عن أوتو ون' : 'About Auto One'),
                  const SizedBox(height: 18),
                  _bulletBlock(
                    isArabic ? 'نبذة عن المعرض' : 'About the showroom',
                    isArabic
                        ? 'AUTO ONE معرض سيارات يهتم بتقديم تجربة شراء موثوقة وسهلة، بأسعار تنافسية ومجموعة مختارة بعناية من السيارات.'
                        : 'AUTO ONE is a car showroom focused on offering a trusted and easy buying experience, with competitive prices and a carefully selected range of cars.',
                  ),
                  _bulletBlock(
                    isArabic ? 'اللي بنقدمه' : 'What we offer',
                    isArabic
                        ? 'نوفّر لك مجموعة متنوعة من السيارات بموديلات وفئات مختلفة، مع معلومات وصور واضحة لكل سيارة عشان تقدر تاخد قرارك بثقة.'
                        : 'We provide a diverse range of cars across different models and categories, with clear information and photos for every car so you can decide with confidence.',
                  ),
                  _bulletBlock(
                    isArabic ? 'السيارات المتوفرة' : 'Available cars',
                    isArabic
                        ? 'مخزوننا بيتجدد باستمرار بسيارات جديدة ومستعملة من ماركات متعددة، وتقدر تتصفحها كلها من صفحة "المعرض".'
                        : 'Our inventory is regularly refreshed with new and used cars from multiple brands, and you can browse them all from the "Cars" page.',
                  ),
                  _bulletBlock(
                    isArabic ? 'هدفنا وخدمتنا' : 'Our goal and service',
                    isArabic
                        ? 'هدفنا إننا نسهّل عليك رحلة اختيار وشراء سيارتك من البداية للنهاية، مع دعم وتواصل سريع في أي وقت تحتاجه.'
                        : 'Our goal is to make your car-buying journey simple from start to finish, with fast support whenever you need it.',
                  ),

                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.black12),
                  const SizedBox(height: 30),

                  _sectionTitle(isArabic ? 'طريقة الشراء' : 'How to Buy'),
                  const SizedBox(height: 18),
                  _stepRow(
                    1,
                    isArabic ? 'اختر سيارتك' : 'Choose your car',
                  ),
                  _stepRow(
                    2,
                    isArabic ? 'اضغط طلب حجز' : 'Tap "Request Booking"',
                  ),
                  _stepRow(
                    3,
                    isArabic ? 'سجّل بياناتك' : 'Fill in your details',
                  ),
                  _stepRow(
                    4,
                    isArabic
                        ? 'فريق AUTO ONE يتواصل معك'
                        : 'The AUTO ONE team contacts you',
                  ),
                  _stepRow(
                    5,
                    isArabic
                        ? 'يتم استكمال إجراءات الشراء'
                        : 'Purchase procedures are completed',
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


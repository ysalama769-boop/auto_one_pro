import 'package:flutter/material.dart';
import '../shared/constants.dart';

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


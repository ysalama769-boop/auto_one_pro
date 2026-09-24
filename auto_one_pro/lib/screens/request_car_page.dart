import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

// ============================================================
// REQUEST CAR PAGE (اطلب سيارتك)
// ============================================================
class RequestCarPage extends StatefulWidget {
  final bool isArabic;
  const RequestCarPage({super.key, required this.isArabic});

  @override
  State<RequestCarPage> createState() => _RequestCarPageState();
}

class _RequestCarPageState extends State<RequestCarPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final carCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  bool isSubmitting = false;
  String customerType = 'individual'; // individual | company
  String paymentMethod = 'cash'; // cash | financing

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    cityCtrl.dispose();
    carCtrl.dispose();
    emailCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/966541577894');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callUs() async {
    final uri = Uri.parse('tel:+966541577894');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty ||
        phoneCtrl.text.trim().isEmpty ||
        cityCtrl.text.trim().isEmpty ||
        carCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'من فضلك املأ كل الحقول المطلوبة'
                : 'Please fill in all required fields',
          ),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      // بنجمع كل التفاصيل الإضافية (نوع العميل، طريقة الدفع،
      // المدينة، السيارة، الإيميل) في حقل notes بشكل مرتّب
      // وواضح، من غير ما نحتاج نضيف أعمدة جديدة في قاعدة البيانات.
      final buffer = StringBuffer();
      buffer.writeln(
        '${isArabic ? 'نوع العميل' : 'Customer type'}: '
        '${customerType == 'company' ? (isArabic ? 'شركات' : 'Company') : (isArabic ? 'أفراد' : 'Individual')}',
      );
      buffer.writeln(
        '${isArabic ? 'طريقة الدفع' : 'Payment method'}: '
        '${paymentMethod == 'financing' ? (isArabic ? 'تمويل' : 'Financing') : (isArabic ? 'كاش' : 'Cash')}',
      );
      buffer.writeln('${isArabic ? 'المدينة' : 'City'}: ${cityCtrl.text.trim()}');
      buffer.writeln(
          '${isArabic ? 'السيارة المطلوبة' : 'Requested car'}: ${carCtrl.text.trim()}');
      if (emailCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'البريد الإلكتروني' : 'Email'}: ${emailCtrl.text.trim()}');
      }
      if (messageCtrl.text.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln(messageCtrl.text.trim());
      }

      await Supabase.instance.client.from('customer_requests').insert({
        'customer_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'notes': buffer.toString().trim(),
        'request_type': 'car_request',
        'status': 'new',
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (!mounted) return;
      nameCtrl.clear();
      phoneCtrl.clear();
      cityCtrl.clear();
      carCtrl.clear();
      emailCtrl.clear();
      messageCtrl.clear();
      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'اتبعت طلبك بنجاح، هيتواصل معاك فريقنا قريبًا'
                : 'Your request was sent, our team will contact you soon',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة في الإرسال' : 'Something went wrong',
          ),
        ),
      );
    }
  }

  Widget _radioRow({
    required String label,
    required List<(String, String)> options,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = groupValue == opt.$2;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(opt.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: isSelected ? Colors.red : Colors.black38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.$1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
      ],
    );
  }

  Widget _fieldsGrid(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 420) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[0]),
              const SizedBox(width: 14),
              Expanded(child: fields[1]),
            ],
          );
        }
        return Column(children: fields);
      },
    );
  }

  Widget _requestField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
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
          title: Text(isArabic ? 'اطلب سيارتك' : 'Request a Car'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'اطلب سيارتك' : 'Request Your Car',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic
                          ? 'سيتواصل معك فريقنا بأفضل الخيارات المناسبة لاحتياجاتك'
                          : 'Our team will reach out with the best options for your needs',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'بيانات الطلب' : 'Request Details',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // نوع الطلب — بادج توضيحي بس
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Text(
                                isArabic ? 'نوع الطلب' : 'Request type',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF0DD),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE0C48C),
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'شراء الآن' : 'Buy Now',
                                  style: const TextStyle(
                                    color: Color(0xFF8A5A1E),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        _radioRow(
                          label: isArabic ? 'نوع العميل' : 'Customer type',
                          options: [
                            (
                              isArabic ? 'أفراد' : 'Individual',
                              'individual'
                            ),
                            (isArabic ? 'شركات' : 'Company', 'company'),
                          ],
                          groupValue: customerType,
                          onChanged: (v) =>
                              setState(() => customerType = v),
                        ),
                        const SizedBox(height: 14),
                        _radioRow(
                          label: isArabic ? 'طريقة الدفع' : 'Payment method',
                          options: [
                            (isArabic ? 'كاش' : 'Cash', 'cash'),
                            (isArabic ? 'تمويل' : 'Financing', 'financing'),
                          ],
                          groupValue: paymentMethod,
                          onChanged: (v) =>
                              setState(() => paymentMethod = v),
                        ),
                        const SizedBox(height: 18),

                        _fieldsGrid([
                          _requestField(
                            controller: nameCtrl,
                            label: customerType == 'company'
                                ? (isArabic
                                    ? 'اسم المسؤول'
                                    : "Manager's name")
                                : (isArabic ? 'الاسم الكامل' : 'Full name'),
                          ),
                          _requestField(
                            controller: phoneCtrl,
                            label: isArabic ? 'رقم الجوال' : 'Mobile number',
                            hint: '05xxxxxxxx',
                            keyboardType: TextInputType.phone,
                          ),
                        ]),
                        _fieldsGrid([
                          _requestField(
                            controller: cityCtrl,
                            label: isArabic ? 'المدينة' : 'City',
                          ),
                          _requestField(
                            controller: carCtrl,
                            label: isArabic
                                ? 'السيارة المطلوبة'
                                : 'Requested car',
                            hint: isArabic
                                ? 'مثال: تويوتا كامري 2026'
                                : 'e.g. Toyota Camry 2026',
                          ),
                        ]),
                        _fieldsGrid([
                          _requestField(
                            controller: emailCtrl,
                            label: isArabic
                                ? 'البريد الإلكتروني (اختياري)'
                                : 'Email (optional)',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _requestField(
                            controller: messageCtrl,
                            label: isArabic
                                ? 'ملاحظات إضافية (اختياري)'
                                : 'Additional notes (optional)',
                          ),
                        ]),

                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isArabic ? 'إرسال الطلب' : 'Send Request',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                isArabic
                                    ? 'أو تواصل معنا مباشرة'
                                    : 'Or contact us directly',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openWhatsApp,
                                icon: const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                label: Text(
                                  isArabic ? 'واتساب' : 'WhatsApp',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callUs,
                                icon: const Icon(
                                  Icons.call_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                label: Text(
                                  isArabic ? 'اتصل بنا' : 'Call Us',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                  ),
                ),
              ),

              const SizedBox(height: 50),
              AutoOneFooter(isArabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }
}

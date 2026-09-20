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
  final messageCtrl = TextEditingController();
  bool isSubmitting = false;

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
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
        messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'من فضلك املأ كل الحقول'
                : 'Please fill in all fields',
          ),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await Supabase.instance.client.from('customer_requests').insert({
        'customer_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'notes': messageCtrl.text.trim(),
        'request_type': 'car_request',
        'status': 'new',
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (!mounted) return;
      nameCtrl.clear();
      phoneCtrl.clear();
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
                constraints: const BoxConstraints(maxWidth: 480),
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
                          isArabic ? 'تواصل معنا' : 'Contact Us',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'الاسم الكامل' : 'Full name',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'رقم الهاتف' : 'Phone number',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: messageCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'الرسالة' : 'Message',
                            hintText: isArabic
                                ? 'اكتب مواصفات السيارة اللي بتدوّر عليها (الماركة، الموديل، الميزانية...)'
                                : 'Describe the car you are looking for',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';

// ============================================================
// FINANCING REQUEST PAGE (طلب تمويل)
// ============================================================
// بتوصل من رابط "التمويل" في الفوتر. بتاخد بيانات العميل + بيانات
// التمويل (الدخل، الدفعة المقدمة، جهة العمل...) وتخزّنها في نفس
// جدول customer_requests بنوع طلب مختلف.
// ============================================================
class FinancingRequestPage extends StatefulWidget {
  final bool isArabic;

  const FinancingRequestPage({super.key, required this.isArabic});

  @override
  State<FinancingRequestPage> createState() => _FinancingRequestPageState();
}

class _FinancingRequestPageState extends State<FinancingRequestPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(text: '+966');
  final cityCtrl = TextEditingController();
  final incomeCtrl = TextEditingController();
  final downPaymentCtrl = TextEditingController();
  final employerCtrl = TextEditingController();

  String? selectedBrand;
  String? selectedModel;
  String? employmentType;
  String? financingDuration;
  bool isSubmitting = false;

  List<Map<String, String>> _allCarsBrandName = [];

  bool get isArabic => widget.isArabic;

  final List<String> _employmentTypes = const [
    'حكومي',
    'قطاع خاص',
    'عمل حر',
  ];
  final List<String> _employmentTypesEn = const [
    'Government',
    'Private sector',
    'Self-employed',
  ];

  final List<String> _durations = const ['12', '24', '36', '48', '60'];

  @override
  void initState() {
    super.initState();
    _loadAllBrandsAndModels();
  }

  Future<void> _loadAllBrandsAndModels() async {
    try {
      final response = await Supabase.instance.client
          .from('cars')
          .select('brand, name')
          .eq('is_available', true);
      final rows = List<Map<String, dynamic>>.from(response as List);
      if (!mounted) return;
      setState(() {
        _allCarsBrandName = rows
            .map((r) => {
                  'brand': (r['brand'] ?? '').toString().trim(),
                  'name': (r['name'] ?? '').toString().trim(),
                })
            .where((r) => r['brand']!.isNotEmpty)
            .toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    cityCtrl.dispose();
    incomeCtrl.dispose();
    downPaymentCtrl.dispose();
    employerCtrl.dispose();
    super.dispose();
  }

  List<String> get _brands {
    final values =
        _allCarsBrandName.map((c) => c['brand']!).toSet().toList();
    values.sort();
    return values;
  }

  List<String> get _modelsForSelectedBrand {
    if (selectedBrand == null) return const [];
    final values = _allCarsBrandName
        .where((c) => c['brand'] == selectedBrand)
        .map((c) => c['name']!)
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'من فضلك اكتبي الاسم ورقم الهاتف على الأقل'
                : 'Please enter at least your name and phone number',
          ),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final buffer = StringBuffer();
      if (emailCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'البريد الإلكتروني' : 'Email'}: ${emailCtrl.text.trim()}');
      }
      if (cityCtrl.text.trim().isNotEmpty) {
        buffer.writeln('${isArabic ? 'المدينة' : 'City'}: ${cityCtrl.text.trim()}');
      }
      if (selectedBrand != null) {
        buffer.writeln(
            '${isArabic ? 'العلامة التجارية' : 'Brand'}: $selectedBrand');
      }
      if (selectedModel != null) {
        buffer.writeln(
            '${isArabic ? 'الموديل المطلوب' : 'Requested model'}: $selectedModel');
      }
      if (incomeCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'الدخل الشهري' : 'Monthly income'}: ${incomeCtrl.text.trim()}');
      }
      if (downPaymentCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'الدفعة المقدمة' : 'Down payment'}: ${downPaymentCtrl.text.trim()}');
      }
      if (employerCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'جهة العمل' : 'Employer'}: ${employerCtrl.text.trim()}');
      }
      if (employmentType != null) {
        buffer.writeln(
            '${isArabic ? 'طبيعة العمل' : 'Employment type'}: $employmentType');
      }
      if (financingDuration != null) {
        buffer.writeln(
            '${isArabic ? 'مدة التمويل المطلوبة' : 'Requested financing duration'}: $financingDuration ${isArabic ? 'شهر' : 'months'}');
      }

      await Supabase.instance.client.from('customer_requests').insert({
        'customer_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'notes': buffer.toString().trim(),
        'request_type': 'financing_request',
        'status': 'new',
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'اتبعت طلب التمويل بنجاح، هيتواصل معاكِ فريقنا قريبًا'
                : 'Your financing request was sent, our team will contact you soon',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة في الإرسال' : 'Something went wrong',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget _fieldsGrid(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 500) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[0]),
              const SizedBox(width: 20),
              Expanded(child: fields[1]),
            ],
          );
        }
        return Column(children: fields);
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: _decoration(hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration:
                _decoration(hint: isArabic ? 'اختر...' : 'Select...'),
            items: items
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl =
        (homepageSettings.value?['financing_request_banner'] ?? '')
            .toString()
            .trim();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'طلب تمويل' : 'Financing Request'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (bannerUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 5,
                  child: carImageAdaptive(
                    bannerUrl,
                    fit: BoxFit.contain,
                    showWatermark: false,
                  ),
                ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Text(
                  isArabic
                      ? 'املئي بياناتك وتفاصيل التمويل، وهيتواصل معاكِ فريقنا بأنسب خيارات التمويل'
                      : 'Fill in your details and financing info — our team will reach out with the best financing options',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xfff9f9fa),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _fieldsGrid([
                            _textField(
                              controller: nameCtrl,
                              label: isArabic ? 'الاسم' : 'Name',
                            ),
                            _textField(
                              controller: emailCtrl,
                              label: isArabic ? 'البريد الإلكتروني' : 'Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ]),
                          _fieldsGrid([
                            _textField(
                              controller: phoneCtrl,
                              label: isArabic ? 'رقم الهاتف' : 'Phone number',
                              keyboardType: TextInputType.phone,
                            ),
                            _textField(
                              controller: cityCtrl,
                              label: isArabic ? 'المدينة' : 'City',
                            ),
                          ]),
                          _fieldsGrid([
                            _dropdownField(
                              label: isArabic
                                  ? 'العلامة التجارية المطلوبة'
                                  : 'Desired brand',
                              value: selectedBrand,
                              items: _brands,
                              onChanged: (v) => setState(() {
                                selectedBrand = v;
                                selectedModel = null;
                              }),
                            ),
                            _dropdownField(
                              label: isArabic
                                  ? 'الموديل المطلوب'
                                  : 'Desired model',
                              value: selectedModel,
                              items: _modelsForSelectedBrand,
                              onChanged: (v) =>
                                  setState(() => selectedModel = v),
                            ),
                          ]),
                          _fieldsGrid([
                            _textField(
                              controller: incomeCtrl,
                              label: isArabic
                                  ? 'الدخل الشهري (ر.س)'
                                  : 'Monthly income (SAR)',
                              keyboardType: TextInputType.number,
                            ),
                            _textField(
                              controller: downPaymentCtrl,
                              label: isArabic
                                  ? 'الدفعة المقدمة (ر.س)'
                                  : 'Down payment (SAR)',
                              keyboardType: TextInputType.number,
                            ),
                          ]),
                          _fieldsGrid([
                            _textField(
                              controller: employerCtrl,
                              label: isArabic ? 'جهة العمل' : 'Employer',
                            ),
                            _dropdownField(
                              label: isArabic
                                  ? 'طبيعة العمل'
                                  : 'Employment type',
                              value: employmentType,
                              items: isArabic
                                  ? _employmentTypes
                                  : _employmentTypesEn,
                              onChanged: (v) =>
                                  setState(() => employmentType = v),
                            ),
                          ]),
                          _dropdownField(
                            label: isArabic
                                ? 'مدة التمويل المطلوبة (بالشهور)'
                                : 'Requested financing duration (months)',
                            value: financingDuration,
                            items: _durations,
                            onChanged: (v) =>
                                setState(() => financingDuration = v),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                      isArabic
                                          ? 'تقديم طلب التمويل'
                                          : 'Submit Financing Request',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              AutoOneFooter(isArabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }
}

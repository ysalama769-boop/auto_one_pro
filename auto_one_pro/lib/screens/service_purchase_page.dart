import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';

// ============================================================
// SERVICE PURCHASE REQUEST PAGE (طلب شراء خدمة/باقة)
// ============================================================
// بتوصل من زرار "طلب شراء" تحت كل باقة في صفحة الخدمات، مع اسم
// وسعر الباقة متملّيين تلقائيًا. البيانات بتتخزّن في نفس جدول
// customer_requests (زي طلب السيارة) بنوع طلب مختلف، عشان منحتاجش
// جدول جديد.
// ============================================================
class ServicePurchasePage extends StatefulWidget {
  final bool isArabic;
  final String serviceName;
  final String servicePrice;

  const ServicePurchasePage({
    super.key,
    required this.isArabic,
    required this.serviceName,
    required this.servicePrice,
  });

  @override
  State<ServicePurchasePage> createState() => _ServicePurchasePageState();
}

class _ServicePurchasePageState extends State<ServicePurchasePage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(text: '+966');
  final odometerCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final areaCtrl = TextEditingController();

  String? selectedBrand;
  String? selectedModel;
  bool isSubmitting = false;
  bool isLoadingBrands = true;
  // بنجيب كل الماركات والموديلات مباشرة من قاعدة البيانات، بدل
  // ما نعتمد على قايمة السيارات المحمّلة في الذاكرة (اللي بتكون
  // ناقصة أحيانًا لأنها بتتحمّل على دفعات، مش كلها مرة واحدة).
  List<Map<String, String>> _allCarsBrandName = [];

  bool get isArabic => widget.isArabic;

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
        isLoadingBrands = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingBrands = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    odometerCtrl.dispose();
    cityCtrl.dispose();
    areaCtrl.dispose();
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
      buffer.writeln(
        '${isArabic ? 'الخدمة/الباقة' : 'Service/Package'}: ${widget.serviceName}',
      );
      buffer.writeln(
        '${isArabic ? 'سعر الخدمة' : 'Service price'}: ${widget.servicePrice}',
      );
      if (emailCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'البريد الإلكتروني' : 'Email'}: ${emailCtrl.text.trim()}');
      }
      if (selectedBrand != null) {
        buffer.writeln(
            '${isArabic ? 'العلامة التجارية' : 'Brand'}: $selectedBrand');
      }
      if (selectedModel != null) {
        buffer.writeln(
            '${isArabic ? 'موديل السيارة' : 'Car model'}: $selectedModel');
      }
      if (odometerCtrl.text.trim().isNotEmpty) {
        buffer.writeln(
            '${isArabic ? 'قراءة العداد' : 'Odometer reading'}: ${odometerCtrl.text.trim()}');
      }
      if (cityCtrl.text.trim().isNotEmpty) {
        buffer.writeln('${isArabic ? 'المدينة' : 'City'}: ${cityCtrl.text.trim()}');
      }
      if (areaCtrl.text.trim().isNotEmpty) {
        buffer.writeln('${isArabic ? 'المنطقة' : 'Area'}: ${areaCtrl.text.trim()}');
      }

      await Supabase.instance.client.from('customer_requests').insert({
        'customer_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'notes': buffer.toString().trim(),
        'request_type': 'service_purchase',
        'status': 'new',
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'اتبعت طلبك بنجاح، هيتواصل معاكِ فريق المبيعات قريبًا'
                : 'Your request was sent, our sales team will contact you soon',
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
    bool readOnly = false,
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
            readOnly: readOnly,
            style: TextStyle(color: readOnly ? Colors.black54 : Colors.black),
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
    String? hint,
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
            decoration: _decoration(hint: hint ?? (isArabic ? 'اختر...' : 'Select...')),
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
    final bannerUrl = (homepageSettings.value?['service_purchase_banner'] ??
            '')
        .toString()
        .trim();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'طلب شراء خدمة' : 'Service Purchase Request'),
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
                child: Column(
                  children: [
                    Text(
                      isArabic
                          ? 'املئي البيانات للحصول على باقتك وتواصل فريق المبيعات معك'
                          : 'Fill in your details to get your package — our sales team will contact you',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
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
                              controller: emailCtrl,
                              label: isArabic ? 'البريد الإلكتروني' : 'Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _textField(
                              controller: nameCtrl,
                              label: isArabic ? 'الاسم' : 'Name',
                            ),
                          ]),
                          _fieldsGrid([
                            _textField(
                              controller: TextEditingController(
                                text: widget.serviceName,
                              ),
                              label: isArabic ? 'الخدمة' : 'Service',
                              readOnly: true,
                            ),
                            _textField(
                              controller: phoneCtrl,
                              label: isArabic ? 'رقم الهاتف' : 'Phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ]),
                          _fieldsGrid([
                            _dropdownField(
                              label:
                                  isArabic ? 'العلامة التجارية' : 'Brand',
                              value: selectedBrand,
                              items: _brands,
                              onChanged: (v) => setState(() {
                                selectedBrand = v;
                                selectedModel = null;
                              }),
                            ),
                            _textField(
                              controller: TextEditingController(
                                text: widget.servicePrice,
                              ),
                              label: isArabic ? 'سعر الخدمة' : 'Service price',
                              readOnly: true,
                            ),
                          ]),
                          _fieldsGrid([
                            _textField(
                              controller: odometerCtrl,
                              label: isArabic ? 'قراءة العداد' : 'Odometer reading',
                              keyboardType: TextInputType.number,
                            ),
                            _dropdownField(
                              label: isArabic ? 'موديل السيارة' : 'Car model',
                              value: selectedModel,
                              items: _modelsForSelectedBrand,
                              onChanged: (v) =>
                                  setState(() => selectedModel = v),
                            ),
                          ]),
                          _fieldsGrid([
                            _textField(
                              controller: cityCtrl,
                              label: isArabic ? 'المدينة' : 'City',
                            ),
                            _textField(
                              controller: areaCtrl,
                              label: isArabic ? 'المنطقة' : 'Area',
                            ),
                          ]),
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
                                      isArabic ? 'تقديم الطلب' : 'Submit Request',
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

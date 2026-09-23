import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';
import '../shared/widgets.dart';

// ============================================================
// ADMIN SERVICE PACKAGES (باقات الخدمات - AUTOCARE plus وغيرها)
// ============================================================
class AdminServicesPage extends StatefulWidget {
  final bool isArabic;
  const AdminServicesPage({super.key, required this.isArabic});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  List<Map<String, dynamic>> packages = [];
  bool isLoading = true;
  bool isUploadingFile = false;

  final nameArCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final descArCtrl = TextEditingController();
  final priceBeforeCtrl = TextEditingController();
  final priceAfterCtrl = TextEditingController();
  final pdfCtrl = TextEditingController();

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    nameArCtrl.dispose();
    nameEnCtrl.dispose();
    descArCtrl.dispose();
    priceBeforeCtrl.dispose();
    priceAfterCtrl.dispose();
    pdfCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('service_packages')
          .select()
          .order('price_after');
      setState(() {
        packages = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadPdf(TextEditingController target) async {
    final uploadInput = html.FileUploadInputElement()..accept = '.pdf';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      setState(() => isUploadingFile = true);
      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final bytes = reader.result as Uint8List;

        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            'services/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await Supabase.instance.client.storage.from('car_images').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'application/pdf',
              ),
            );

        final publicUrl =
            Supabase.instance.client.storage.from('car_images').getPublicUrl(path);

        if (mounted) setState(() => target.text = publicUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'فشل رفع الملف: $e' : 'Failed to upload: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isUploadingFile = false);
      }
    });
  }

  Future<void> _addPackage() async {
    if (nameArCtrl.text.trim().isEmpty || priceAfterCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'من فضلك اكتب الاسم والسعر الحالي على الأقل'
                : 'Please enter at least the name and current price',
          ),
        ),
      );
      return;
    }
    try {
      final packageName = nameArCtrl.text.trim();
      await Supabase.instance.client.from('service_packages').insert({
        'name_ar': packageName,
        'name_en': nameEnCtrl.text.trim(),
        'description_ar': descArCtrl.text.trim(),
        'price_before': double.tryParse(priceBeforeCtrl.text.trim()),
        'price_after': double.tryParse(priceAfterCtrl.text.trim()) ?? 0,
        'pdf_url': pdfCtrl.text.trim().isEmpty ? null : pdfCtrl.text.trim(),
      });

      // إشعار تلقائي للزبائن بالباقة الجديدة
      try {
        await Supabase.instance.client.from('announcements').insert({
          'title': isArabic ? 'خدمة جديدة!' : 'New service!',
          'body': isArabic
              ? 'ضفنا باقة "$packageName" لخدماتنا، شوف تفاصيلها دلوقتي.'
              : 'We added the "$packageName" package to our services, check it out now.',
          'type': 'service',
        });
      } catch (e) {
        debugPrint('AUTO_ONE_DEBUG: تعذّر إرسال إشعار الخدمة: $e');
      }

      nameArCtrl.clear();
      nameEnCtrl.clear();
      descArCtrl.clear();
      priceBeforeCtrl.clear();
      priceAfterCtrl.clear();
      pdfCtrl.clear();
      await logActivity(
        isArabic ? 'أضاف باقة خدمة جديدة' : 'Added a service package',
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشلت الإضافة: $e' : 'Failed to add: $e',
          ),
        ),
      );
    }
  }

  Future<void> _editPackage(Map<String, dynamic> package) async {
    final editNameAr = TextEditingController(text: (package['name_ar'] ?? '').toString());
    final editNameEn = TextEditingController(text: (package['name_en'] ?? '').toString());
    final editDesc = TextEditingController(text: (package['description_ar'] ?? '').toString());
    final editPriceBefore = TextEditingController(
      text: package['price_before'] == null ? '' : '${package['price_before']}',
    );
    final editPriceAfter = TextEditingController(
      text: '${package['price_after'] ?? ''}',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isArabic ? 'تعديل الباقة' : 'Edit package'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editNameAr,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الاسم (عربي)' : 'Name (Arabic)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: editNameEn,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الاسم (إنجليزي)' : 'Name (English)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: editDesc,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الوصف' : 'Description',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: editPriceBefore,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'قبل الخصم' : 'Before',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: editPriceAfter,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'السعر الحالي' : 'Current',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      try {
        await Supabase.instance.client.from('service_packages').update({
          'name_ar': editNameAr.text.trim(),
          'name_en': editNameEn.text.trim(),
          'description_ar': editDesc.text.trim(),
          'price_before': double.tryParse(editPriceBefore.text.trim()),
          'price_after': double.tryParse(editPriceAfter.text.trim()) ?? 0,
        }).eq('id', package['id'] as int);
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'فشل الحفظ: $e' : 'Failed to save: $e'),
          ),
        );
      }
    }

    editNameAr.dispose();
    editNameEn.dispose();
    editDesc.dispose();
    editPriceBefore.dispose();
    editPriceAfter.dispose();
  }

  Future<void> _deletePackage(int id) async {
    try {
      await Supabase.instance.client
          .from('service_packages')
          .delete()
          .eq('id', id);
      _load();
    } catch (e) {
      // silent
    }
  }

  Future<void> _updatePdfFor(Map<String, dynamic> package) async {
    final ctrl = TextEditingController();
    await _pickAndUploadPdf(ctrl);
    if (ctrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client
          .from('service_packages')
          .update({'pdf_url': ctrl.text.trim()}).eq('id', package['id'] as int);
      _load();
    } catch (e) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'باقات الخدمات' : 'Service Packages',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'القائمة دي بتظهر في صفحة "الخدمات" للزبائن مرتبة من الأرخص للأغلى.'
                : 'This list shows on the customer "Services" page, sorted from cheapest to most expensive.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ADD NEW PACKAGE (قابل للطي)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: Colors.grey.shade50,
              collapsedBackgroundColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.black12),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.black12),
              ),
              title: Text(
                isArabic ? 'إضافة باقة جديدة' : 'Add a new package',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameArCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اسم الباقة (عربي)' : 'Package name (Arabic)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: nameEnCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اسم الباقة (إنجليزي، اختياري)' : 'Package name (English)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descArCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'وصف مختصر (اختياري)' : 'Short description',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceBeforeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'السعر قبل الخصم (اختياري)' : 'Price before discount',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceAfterCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'السعر الحالي' : 'Current price',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pdfCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'رابط ملف PDF (اختياري)' : 'PDF file link',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isUploadingFile
                          ? null
                          : () => _pickAndUploadPdf(pdfCtrl),
                      icon: const Icon(Icons.upload_file),
                      tooltip: isArabic ? 'رفع ملف PDF' : 'Upload PDF',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addPackage,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isArabic ? 'إضافة' : 'Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: packages.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'مفيش باقات لسه' : 'No packages yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;
                      return GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 108,
                        ),
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                      final p = packages[index];
                      final pdf = (p['pdf_url'] ?? '').toString();
                      final priceBefore = p['price_before'];
                      final priceAfter = p['price_after'];

                      return HoverLift(
                        scale: 1.02,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isArabic
                                        ? (p['name_ar'] ?? '').toString()
                                        : ((p['name_en'] ?? '').toString().isEmpty
                                            ? (p['name_ar'] ?? '').toString()
                                            : p['name_en'].toString()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (priceBefore != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            '$priceBefore',
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.black38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        '$priceAfter ﷼',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (pdf.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        '📄 PDF',
                                        style: TextStyle(fontSize: 11, color: Colors.green),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _editPackage(p),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: isArabic ? 'تعديل' : 'Edit',
                            ),
                            IconButton(
                              onPressed:
                                  isUploadingFile ? null : () => _updatePdfFor(p),
                              icon: const Icon(Icons.upload_file),
                              tooltip: isArabic ? 'تغيير PDF' : 'Change PDF',
                            ),
                            IconButton(
                              onPressed: () => _deletePackage(p['id'] as int),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

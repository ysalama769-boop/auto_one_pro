import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';
import '../shared/widgets.dart';
import 'admin_cars.dart';

// ============================================================
// ADMIN BRANDS
// ============================================================
class AdminBrandsCategoriesPage extends StatefulWidget {
  final bool isArabic;
  const AdminBrandsCategoriesPage({super.key, required this.isArabic});

  @override
  State<AdminBrandsCategoriesPage> createState() =>
      _AdminBrandsCategoriesPageState();
}


class _AdminBrandsCategoriesPageState
    extends State<AdminBrandsCategoriesPage> {
  List<Map<String, dynamic>> brands = [];
  bool isLoading = true;
  bool isUploadingLogo = false;
  // عدد السيارات لكل ماركة، حسب اسمها (name_en لو موجود، وإلا name_ar)
  Map<String, int> carCountByBrand = {};

  Future<void> _pickAndUploadLogo(
    TextEditingController target,
    StateSetter setDialogState,
  ) async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      setDialogState(() => isUploadingLogo = true);

      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final rawBytes = reader.result as Uint8List;
        final bytes = await compressImageBytes(rawBytes);

        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            'brands/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await Supabase.instance.client.storage.from('car_images').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = Supabase.instance.client.storage
            .from('car_images')
            .getPublicUrl(path);

        setDialogState(() => target.text = publicUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'فشل رفع الصورة: $e'
                    : 'Failed to upload image: $e',
              ),
            ),
          );
        }
      } finally {
        setDialogState(() => isUploadingLogo = false);
      }
    });
  }

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    try {
      final b = await Supabase.instance.client
          .from('brands')
          .select()
          .order('name_ar');
      // بنجيب أسامي ماركات كل السيارات (عمود واحد بس)، عشان نحسب
      // عدد السيارات لكل ماركة من غير ما نجيب كل بيانات السيارات
      final carsBrandsResponse =
          await Supabase.instance.client.from('cars').select('brand');

      final counts = <String, int>{};
      for (final row in (carsBrandsResponse as List)) {
        final brandName =
            (row['brand'] ?? '').toString().trim().toLowerCase();
        if (brandName.isEmpty) continue;
        counts[brandName] = (counts[brandName] ?? 0) + 1;
      }

      setState(() {
        brands = List<Map<String, dynamic>>.from(b as List);
        carCountByBrand = counts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> item, bool value) async {
    setState(() {
      item['is_active'] = value;
    });
    try {
      await Supabase.instance.client
          .from('brands')
          .update({'is_active': value}).eq('id', item['id'] as int);
    } catch (e) {
      setState(() {
        item['is_active'] = !value;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong'),
        ),
      );
    }
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameArCtrl =
        TextEditingController(text: existing?['name_ar']?.toString() ?? '');
    final nameEnCtrl =
        TextEditingController(text: existing?['name_en']?.toString() ?? '');
    final logoCtrl =
        TextEditingController(text: existing?['logo']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? (isArabic ? 'ماركة جديدة' : 'New brand')
                : (isArabic ? 'تعديل الماركة' : 'Edit brand'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الاسم بالعربي' : 'Name (Arabic)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnCtrl,
                  decoration: InputDecoration(
                    labelText:
                        isArabic ? 'الاسم بالإنجليزي' : 'Name (English)',
                    helperText: isArabic
                        ? 'لازم يطابق بالظبط اسم الماركة المكتوب في بيانات السيارات (مثال: Toyota)'
                        : 'Must match the brand name exactly as used on car records',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: logoCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'رابط اللوجو' : 'Logo URL',
                          hintText: isArabic
                              ? 'الصق رابط صورة اللوجو (يبدأ بـ https://)'
                              : 'Paste the logo image URL (starts with https://)',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isUploadingLogo
                          ? null
                          : () => _pickAndUploadLogo(logoCtrl, setDialogState),
                      icon: isUploadingLogo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      tooltip: isArabic ? 'اختيار من الجهاز' : 'Browse',
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final payload = {
      'name_ar': nameArCtrl.text.trim(),
      'name_en': nameEnCtrl.text.trim(),
      'logo': logoCtrl.text.trim(),
    };

    try {
      if (existing == null) {
        await Supabase.instance.client.from('brands').insert(payload);
      } else {
        await Supabase.instance.client
            .from('brands')
            .update(payload)
            .eq('id', existing['id'] as int);
      }
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong')),
      );
    }
  }

  Future<void> _delete(int id) async {
    try {
      await Supabase.instance.client.from('brands').delete().eq('id', id);
      _loadAll();
    } catch (e) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminBrandsCategoriesFAB',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'ماركة جديدة' : 'New brand'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : brands.isEmpty
              ? Center(
                  child: Text(
                    isArabic ? 'لا يوجد ماركات بعد' : 'No brands yet',
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 600
                            ? 2
                            : 1;
                    final cardWidth =
                        (constraints.maxWidth - 14 * 2 - (columns - 1) * 12) /
                            columns;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: brands.map((item) {
                          final brandKey =
                              (item['name_en'] ?? '').toString().isNotEmpty
                                  ? (item['name_en'] ?? '').toString()
                                  : (item['name_ar'] ?? '').toString();
                          final carCount = brandKey.isEmpty
                              ? 0
                              : (carCountByBrand[
                                      brandKey.trim().toLowerCase()] ??
                                  0);

                          void openBrandCars() {
                            if (brandKey.isEmpty) return;
                            Navigator.of(context).push(
                              smoothRoute(
                                AdminCarsPage(
                                  isArabic: isArabic,
                                  filterBrand: brandKey,
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            width: cardWidth,
                            child: HoverLift(
                              scale: 1.02,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: brandKey.isEmpty ? null : openBrandCars,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child:
                                                (item['logo'] ?? '')
                                                        .toString()
                                                        .isEmpty
                                                    ? const Icon(
                                                        Icons
                                                            .directions_car_filled_rounded,
                                                        color: Colors.black26,
                                                      )
                                                    : ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        child: Image.network(
                                                          item['logo']
                                                              .toString(),
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (_,
                                                                  __, ___) =>
                                                              const Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            color: Colors
                                                                .black26,
                                                          ),
                                                        ),
                                                      ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (item['name_ar'] ?? '')
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  (item['name_en'] ?? '')
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: carCount > 0
                                                  ? Colors.green
                                                      .withValues(alpha: .1)
                                                  : Colors.black
                                                      .withValues(alpha: .06),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isArabic
                                                  ? '$carCount سيارة'
                                                  : '$carCount cars',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: carCount > 0
                                                    ? Colors.green.shade700
                                                    : Colors.black45,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Switch(
                                            value: (item['is_active'] ??
                                                true) as bool,
                                            activeColor: Colors.red,
                                            onChanged: (value) =>
                                                _toggleActive(item, value),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _openForm(existing: item),
                                            icon: const Icon(
                                                Icons.edit_outlined),
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            onPressed: () =>
                                                _delete(item['id'] as int),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red,
                                            ),
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}

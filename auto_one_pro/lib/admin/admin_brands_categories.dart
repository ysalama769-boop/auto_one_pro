import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN BRANDS & CATEGORIES
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
  bool showBrands = true;
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  bool isUploadingLogo = false;

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

        await Supabase.instance.client.storage
            .from('car_images')
            .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

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
      final c = await Supabase.instance.client
          .from('categories')
          .select()
          .order('name_ar');
      setState(() {
        brands = List<Map<String, dynamic>>.from(b as List);
        categories = List<Map<String, dynamic>>.from(c as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> item, bool value) async {
    final table = showBrands ? 'brands' : 'categories';
    setState(() {
      item['is_active'] = value;
    });
    try {
      await Supabase.instance.client
          .from(table)
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
    final logoCtrl = TextEditingController(
      text: showBrands ? (existing?['logo']?.toString() ?? '') : '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: Text(
          existing == null
              ? (isArabic ? 'إضافة' : 'Add')
              : (isArabic ? 'تعديل' : 'Edit'),
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
                  labelText: isArabic ? 'الاسم بالإنجليزي' : 'Name (English)',
                  helperText: showBrands
                      ? (isArabic
                          ? 'لازم يطابق بالظبط اسم الماركة المكتوب في بيانات السيارات (مثال: Toyota)'
                          : 'Must match the brand name exactly as used on car records')
                      : null,
                  helperMaxLines: 2,
                ),
              ),
              if (showBrands) ...[
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

    final table = showBrands ? 'brands' : 'categories';
    final payload = {
      'name_ar': nameArCtrl.text.trim(),
      'name_en': nameEnCtrl.text.trim(),
      if (showBrands) 'logo': logoCtrl.text.trim(),
    };

    try {
      if (existing == null) {
        await Supabase.instance.client.from(table).insert(payload);
      } else {
        await Supabase.instance.client
            .from(table)
            .update(payload)
            .eq('id', existing['id'] as int);
      }
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong')),
      );
    }
  }

  Future<void> _delete(int id) async {
    final table = showBrands ? 'brands' : 'categories';
    try {
      await Supabase.instance.client.from(table).delete().eq('id', id);
      _loadAll();
    } catch (e) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = showBrands ? brands : categories;

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminBrandsCategoriesFAB',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          showBrands
              ? (isArabic ? 'ماركة جديدة' : 'New brand')
              : (isArabic ? 'فئة جديدة' : 'New category'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => showBrands = true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: showBrands ? Colors.red : null,
                      foregroundColor: showBrands ? Colors.white : Colors.black,
                    ),
                    child: Text(isArabic ? 'الماركات' : 'Brands'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => showBrands = false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !showBrands ? Colors.red : null,
                      foregroundColor: !showBrands ? Colors.white : Colors.black,
                    ),
                    child: Text(isArabic ? 'الفئات' : 'Categories'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red))
                : list.isEmpty
                    ? Center(
                        child: Text(
                          isArabic ? 'لا يوجد عناصر بعد' : 'No items yet',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (item['name_ar'] ?? '').toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        (item['name_en'] ?? '').toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: (item['is_active'] ?? true) as bool,
                                  activeColor: Colors.red,
                                  onChanged: (value) =>
                                      _toggleActive(item, value),
                                ),
                                IconButton(
                                  onPressed: () => _openForm(existing: item),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _delete(item['id'] as int),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN FINANCING PARTNERS (جهات التمويل المعتمدة)
// ============================================================
class AdminFinancingPartnersPage extends StatefulWidget {
  final bool isArabic;
  const AdminFinancingPartnersPage({super.key, required this.isArabic});

  @override
  State<AdminFinancingPartnersPage> createState() =>
      _AdminFinancingPartnersPageState();
}

class _AdminFinancingPartnersPageState
    extends State<AdminFinancingPartnersPage> {
  List<Map<String, dynamic>> partners = [];
  bool isLoading = true;
  bool isUploadingImage = false;

  final nameArCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final logoCtrl = TextEditingController();

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
    logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('financing_partners')
          .select()
          .order('id');
      setState(() {
        partners = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      setState(() => isUploadingImage = true);
      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final rawBytes = reader.result as Uint8List;
        final bytes = await compressImageBytes(rawBytes);

        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            'financing/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await Supabase.instance.client.storage
            .from('car_images')
            .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl =
            Supabase.instance.client.storage.from('car_images').getPublicUrl(path);

        if (mounted) {
          setState(() => logoCtrl.text = publicUrl);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'فشل رفع الصورة: $e' : 'Failed to upload: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isUploadingImage = false);
      }
    });
  }

  Future<void> _addPartner() async {
    if (nameArCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('financing_partners').insert({
        'name_ar': nameArCtrl.text.trim(),
        'name_en': nameEnCtrl.text.trim(),
        'logo_url': logoCtrl.text.trim().isEmpty ? null : logoCtrl.text.trim(),
      });
      nameArCtrl.clear();
      nameEnCtrl.clear();
      logoCtrl.clear();
      await logActivity(
        isArabic ? 'أضاف جهة تمويل جديدة' : 'Added a financing partner',
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong')),
      );
    }
  }

  Future<void> _updateLogo(int id, String url) async {
    try {
      await Supabase.instance.client
          .from('financing_partners')
          .update({'logo_url': url}).eq('id', id);
      _load();
    } catch (e) {
      // silent
    }
  }

  Future<void> _deletePartner(int id) async {
    try {
      await Supabase.instance.client
          .from('financing_partners')
          .delete()
          .eq('id', id);
      _load();
    } catch (e) {
      // silent
    }
  }

  Future<void> _uploadLogoFor(Map<String, dynamic> partner) async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      setState(() => isUploadingImage = true);
      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final rawBytes = reader.result as Uint8List;
        final bytes = await compressImageBytes(rawBytes);

        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            'financing/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await Supabase.instance.client.storage
            .from('car_images')
            .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl =
            Supabase.instance.client.storage.from('car_images').getPublicUrl(path);

        await _updateLogo(partner['id'] as int, publicUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'فشل رفع الصورة: $e' : 'Failed to upload: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isUploadingImage = false);
      }
    });
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
            isArabic ? 'جهات التمويل المعتمدة' : 'Approved Financing Partners',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'القائمة دي بتظهر في قسم "معتمدون لدى جهات التمويل" في الصفحة الرئيسية.'
                : 'This list shows in the "Approved Financing Partners" section on the homepage.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ADD NEW PARTNER (قابل للطي)
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
                isArabic ? 'إضافة جهة جديدة' : 'Add a new partner',
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
                          labelText: isArabic ? 'الاسم (عربي)' : 'Name (Arabic)',
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
                          labelText:
                              isArabic ? 'الاسم (إنجليزي، اختياري)' : 'Name (English, optional)',
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
                        controller: logoCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'رابط اللوجو (اختياري)' : 'Logo URL (optional)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isUploadingImage ? null : _pickAndUploadLogo,
                      icon: const Icon(Icons.upload_file),
                      tooltip: isArabic ? 'اختيار من الجهاز' : 'Browse',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addPartner,
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

          // LIST
          Expanded(
            child: partners.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'مفيش جهات تمويل لسه' : 'No partners yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    itemCount: partners.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = partners[index];
                      final logo = (p['logo_url'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: logo.isEmpty
                                  ? const Icon(
                                      Icons.image_outlined,
                                      color: Colors.black26,
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        logo,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.black26,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? (p['name_ar'] ?? '').toString()
                                    : ((p['name_en'] ?? '').toString().isEmpty
                                        ? (p['name_ar'] ?? '').toString()
                                        : p['name_en'].toString()),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isUploadingImage
                                  ? null
                                  : () => _uploadLogoFor(p),
                              icon: const Icon(Icons.upload_file),
                              tooltip: isArabic
                                  ? 'تغيير اللوجو'
                                  : 'Change logo',
                            ),
                            IconButton(
                              onPressed: () => _deletePartner(p['id'] as int),
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

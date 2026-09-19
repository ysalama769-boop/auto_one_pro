import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN ANNOUNCEMENTS (إعلانات وإشعارات عامة للزبائن)
// ============================================================
class AdminAnnouncementsPage extends StatefulWidget {
  final bool isArabic;
  const AdminAnnouncementsPage({super.key, required this.isArabic});

  @override
  State<AdminAnnouncementsPage> createState() =>
      _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;
  bool isSending = false;

  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  String type = 'general';

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        announcements = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'offer':
        return isArabic ? 'عرض/خصم' : 'Offer';
      case 'service':
        return isArabic ? 'خدمة جديدة' : 'New service';
      case 'car':
        return isArabic ? 'سيارة جديدة' : 'New car';
      default:
        return isArabic ? 'عام' : 'General';
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'offer':
        return Icons.local_offer_outlined;
      case 'service':
        return Icons.miscellaneous_services_outlined;
      case 'car':
        return Icons.directions_car_filled_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  Future<void> _send() async {
    if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'اكتب العنوان والنص الأول'
                : 'Write a title and message first',
          ),
        ),
      );
      return;
    }

    setState(() => isSending = true);
    try {
      await Supabase.instance.client.from('announcements').insert({
        'title': titleCtrl.text.trim(),
        'body': bodyCtrl.text.trim(),
        'type': type,
      });
      await logActivity(
        isArabic
            ? 'أرسل إعلان: ${titleCtrl.text.trim()}'
            : 'Sent announcement: ${titleCtrl.text.trim()}',
      );
      titleCtrl.clear();
      bodyCtrl.clear();
      setState(() {
        type = 'general';
        isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'اتبعت للزبائن كلهم'
                  : 'Sent to all customers',
            ),
          ),
        );
      }
      _load();
    } catch (e) {
      setState(() => isSending = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'فشل الإرسال: $e' : 'Failed to send: $e'),
        ),
      );
    }
  }

  Future<void> _delete(int id) async {
    try {
      await Supabase.instance.client
          .from('announcements')
          .delete()
          .eq('id', id);
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
            isArabic ? 'إعلانات للزبائن' : 'Customer Announcements',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'أي إعلان تبعته هنا هيظهر كإشعار لكل الزبائن المسجّلين دخول في الموقع.'
                : 'Any announcement you send here will show as a notification to all signed-in customers.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // FORM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['general', 'offer', 'service', 'car'].map((t) {
                    final isSelected = type == t;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.black12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _typeIcon(t),
                              size: 16,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _typeLabel(t),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'العنوان' : 'Title',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'النص' : 'Message',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isSending ? null : _send,
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.campaign_rounded),
                  label: Text(isArabic ? 'إرسال للزبائن' : 'Send to customers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            isArabic ? 'الإعلانات السابقة' : 'Previous announcements',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: announcements.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'مفيش إعلانات لسه' : 'No announcements yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    itemCount: announcements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = announcements[index];
                      final t = (a['type'] ?? 'general').toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Icon(_typeIcon(t), color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (a['title'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (a['body'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _delete(a['id'] as int),
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

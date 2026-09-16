import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN CUSTOMER REVIEWS (تقييمات العملاء)
// ============================================================
class AdminReviewsPage extends StatefulWidget {
  final bool isArabic;
  const AdminReviewsPage({super.key, required this.isArabic});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String filter = 'pending'; // pending | approved | rejected | all

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('customer_reviews')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        reviews = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _setStatus(int id, String status) async {
    try {
      await Supabase.instance.client
          .from('customer_reviews')
          .update({'status': status}).eq('id', id);
      await logActivity(
        isArabic
            ? 'غيّر حالة تقييم رقم $id إلى ${_statusLabel(status)}'
            : 'Changed review #$id status to ${_statusLabel(status)}',
      );
      _load();
    } catch (e) {
      // silent
    }
  }

  Future<void> _delete(int id) async {
    try {
      await Supabase.instance.client
          .from('customer_reviews')
          .delete()
          .eq('id', id);
      _load();
    } catch (e) {
      // silent
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return isArabic ? 'موافَق عليه' : 'Approved';
      case 'rejected':
        return isArabic ? 'مرفوض' : 'Rejected';
      default:
        return isArabic ? 'معلّق' : 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = filter == 'all'
        ? reviews
        : reviews.where((r) => (r['status'] ?? 'pending') == filter).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تقييمات العملاء' : 'Customer Reviews',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'التقييمات "الموافَق عليها" بس هي اللي تظهر في قسم "ماذا يقول عملاؤنا" بالصفحة الرئيسية.'
                : 'Only "Approved" reviews appear in the "What our customers say" section on the homepage.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _filterChip('pending', isArabic ? 'معلّقة' : 'Pending'),
              _filterChip('approved', isArabic ? 'موافَق عليها' : 'Approved'),
              _filterChip('rejected', isArabic ? 'مرفوضة' : 'Rejected'),
              _filterChip('all', isArabic ? 'الكل' : 'All'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'مفيش تقييمات هنا' : 'No reviews here',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      final status = (r['status'] ?? 'pending').toString();

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (r['customer_name'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (r['review_text'] ?? '').toString(),
                              style: const TextStyle(fontSize: 13, height: 1.6),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (status != 'approved')
                                  TextButton.icon(
                                    onPressed: () =>
                                        _setStatus(r['id'] as int, 'approved'),
                                    icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isArabic ? 'موافقة' : 'Approve',
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ),
                                if (status != 'rejected')
                                  TextButton.icon(
                                    onPressed: () =>
                                        _setStatus(r['id'] as int, 'rejected'),
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isArabic ? 'رفض' : 'Reject',
                                      style: const TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _delete(r['id'] as int),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
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

  Widget _filterChip(String value, String label) {
    final isSelected = filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => filter = value),
      selectedColor: Colors.red.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? Colors.red : Colors.black87,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN CUSTOMER REQUESTS (تمويل / تجربة قيادة / استفسار)
// ============================================================
class AdminRequestsPage extends StatefulWidget {
  final bool isArabic;
  const AdminRequestsPage({super.key, required this.isArabic});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}


class _AdminRequestsPageState extends State<AdminRequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('customer_requests')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        requests = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = isArabic
            ? 'تعذّر تحميل الطلبات'
            : 'Failed to load requests';
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('customer_requests')
          .update({'status': newStatus}).eq('id', id);
      await logActivity(
        isArabic
            ? 'غيّر حالة طلب رقم $id إلى ${_statusLabel(newStatus)}'
            : 'Changed request #$id status to ${_statusLabel(newStatus)}',
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong'),
        ),
      );
    }
  }

  Future<void> _deleteRequest(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm delete'),
        content: Text(
          isArabic ? 'متأكد إنك عايز تمسح الطلب ده؟' : 'Delete this request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('customer_requests')
          .delete()
          .eq('id', id);
      _loadRequests();
    } catch (e) {
      // silent
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'financing':
        return isArabic ? 'تمويل' : 'Financing';
      case 'test_drive':
        return isArabic ? 'تجربة قيادة' : 'Test drive';
      default:
        return isArabic ? 'استفسار' : 'Inquiry';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'contacted':
        return Colors.blue;
      case 'follow_up':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'contacted':
        return isArabic ? 'تم التواصل' : 'Contacted';
      case 'follow_up':
        return isArabic ? 'متابعة' : 'Follow up';
      case 'closed':
        return isArabic ? 'مغلق' : 'Closed';
      default:
        return isArabic ? 'جديد' : 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }
    if (requests.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا يوجد طلبات بعد' : 'No requests yet',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
          final status = (r['status'] ?? 'new') as String;
          final type = (r['request_type'] ?? 'inquiry') as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
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
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(r['phone'] ?? '').toString()} · ${_typeLabel(type)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (((r['car_name'] ?? '') as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${r['car_brand'] ?? ''} ${r['car_name'] ?? ''}'.trim(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                if (type == 'financing') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (((r['salary'] ?? '') as String).isNotEmpty)
                          Text(
                            '${isArabic ? 'الراتب' : 'Salary'}: ${r['salary']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (((r['bank_name'] ?? '') as String).isNotEmpty)
                          Text(
                            '${isArabic ? 'البنك' : 'Bank'}: ${r['bank_name']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (r['has_obligations'] != null)
                          Text(
                            '${isArabic ? 'التزامات' : 'Obligations'}: '
                            '${r['has_obligations'] == true ? (isArabic ? 'أيوه (${r['obligations_type'] ?? ''})' : 'Yes (${r['obligations_type'] ?? ''})') : (isArabic ? 'لأ' : 'No')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (((r['employer'] ?? '') as String).isNotEmpty)
                          Text(
                            '${isArabic ? 'جهة العمل' : 'Employer'}: ${r['employer']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (((r['selected_color'] ?? '') as String).isNotEmpty)
                          Text(
                            '${isArabic ? 'اللون المطلوب' : 'Preferred color'}: ${r['selected_color']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
                if (((r['notes'] ?? '') as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r['notes'].toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: status,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'new',
                                child: Text(_statusLabel('new')),
                              ),
                              DropdownMenuItem(
                                value: 'contacted',
                                child: Text(_statusLabel('contacted')),
                              ),
                              DropdownMenuItem(
                                value: 'follow_up',
                                child: Text(_statusLabel('follow_up')),
                              ),
                              DropdownMenuItem(
                                value: 'closed',
                                child: Text(_statusLabel('closed')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updateStatus(r['id'] as int, value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteRequest(r['id'] as int),
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
    );
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// ADMIN ACTIVITY LOG
// ============================================================
class AdminActivityLogPage extends StatefulWidget {
  final bool isArabic;
  const AdminActivityLogPage({super.key, required this.isArabic});

  @override
  State<AdminActivityLogPage> createState() => _AdminActivityLogPageState();
}


class _AdminActivityLogPageState extends State<AdminActivityLogPage> {
  List<Map<String, dynamic>> logs = [];
  bool isLoading = true;

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
          .from('activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      setState(() {
        logs = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: RefreshIndicator(
        onRefresh: _load,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.red))
            : logs.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'لا يوجد تعديلات مسجّلة بعد' : 'No activity yet',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (log['action'] ?? '').toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${log['user_name'] ?? ''} · '
                                    '${_formatDate(log['created_at']?.toString())}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}


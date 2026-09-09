import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN USERS & ROLES
// ============================================================
class AdminUsersPage extends StatefulWidget {
  final bool isArabic;
  const AdminUsersPage({super.key, required this.isArabic});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}


class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  bool get isArabic => widget.isArabic;

  static const roles = ['admin', 'sales', 'inventory', 'editor'];

  String _roleLabel(String role) {
    switch (role) {
      case 'sales':
        return isArabic ? 'مبيعات' : 'Sales';
      case 'inventory':
        return isArabic ? 'مخزون' : 'Inventory';
      case 'editor':
        return isArabic ? 'محرر' : 'Editor';
      default:
        return isArabic ? 'مدير' : 'Admin';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('admin_users')
          .select()
          .order('created_at');
      setState(() {
        users = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameCtrl =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final usernameCtrl =
        TextEditingController(text: existing?['username']?.toString() ?? '');
    final passwordCtrl =
        TextEditingController(text: existing?['password']?.toString() ?? '');
    String role = (existing?['role'] ?? 'sales') as String;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? (isArabic ? 'مستخدم جديد' : 'New user')
                : (isArabic ? 'تعديل مستخدم' : 'Edit user'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الاسم' : 'Name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم المستخدم' : 'Username',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'كلمة السر' : 'Password',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الدور' : 'Role',
                  ),
                  items: roles
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabel(r)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => role = value);
                    }
                  },
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    if (nameCtrl.text.trim().isEmpty ||
        usernameCtrl.text.trim().isEmpty ||
        passwordCtrl.text.trim().isEmpty) {
      return;
    }

    final payload = {
      'name': nameCtrl.text.trim(),
      'username': usernameCtrl.text.trim(),
      'password': passwordCtrl.text.trim(),
      'role': role,
    };

    try {
      if (existing == null) {
        await Supabase.instance.client.from('admin_users').insert(payload);
        await logActivity(
          isArabic
              ? 'أضاف مستخدم جديد: ${nameCtrl.text.trim()} (${_roleLabel(role)})'
              : 'Added new user: ${nameCtrl.text.trim()} (${_roleLabel(role)})',
        );
      } else {
        await Supabase.instance.client
            .from('admin_users')
            .update(payload)
            .eq('id', existing['id'] as int);
        await logActivity(
          isArabic
              ? 'عدّل بيانات المستخدم: ${nameCtrl.text.trim()}'
              : 'Updated user: ${nameCtrl.text.trim()}',
        );
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'حصلت مشكلة (يمكن اسم المستخدم مستخدم قبل كده)'
                : 'Something went wrong (username might be taken)',
          ),
        ),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm delete'),
        content: Text(
          isArabic
              ? 'متأكد إنك عايز تمسح المستخدم ده؟'
              : 'Delete this user?',
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
          .from('admin_users')
          .delete()
          .eq('id', user['id'] as int);
      await logActivity(
        isArabic
            ? 'حذف المستخدم: ${user['name']}'
            : 'Deleted user: ${user['name']}',
      );
      _load();
    } catch (e) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminUsersFAB',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(isArabic ? 'مستخدم جديد' : 'New user'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : users.isEmpty
              ? Center(
                  child: Text(
                    isArabic ? 'لا يوجد مستخدمين بعد' : 'No users yet',
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final role = (user['role'] ?? 'sales') as String;
                    final isCurrentUser =
                        currentAdminUser.value?['id'] == user['id'];

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
                          CircleAvatar(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            child: Text(
                              ((user['name'] ?? '?') as String).isNotEmpty
                                  ? (user['name'] as String)[0]
                                  : '?',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      (user['name'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        isArabic ? '(إنت)' : '(you)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  '@${user['username'] ?? ''} · ${_roleLabel(role)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openForm(existing: user),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed:
                                isCurrentUser ? null : () => _delete(user),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: isCurrentUser
                                  ? Colors.black26
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}


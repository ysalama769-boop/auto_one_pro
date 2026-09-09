import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';
import '../admin/admin_dashboard.dart';

class AdminGate extends StatefulWidget {
  final bool isArabic;

  const AdminGate({super.key, required this.isArabic});

  @override
  State<AdminGate> createState() => _AdminGateState();
}


class _AdminGateState extends State<AdminGate> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorText;
  bool obscure = true;
  bool isSubmitting = false;

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorText = isArabic
            ? 'اكتب اسم المستخدم وكلمة السر'
            : 'Enter username and password';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('admin_users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        setState(() {
          isSubmitting = false;
          errorText = isArabic
              ? 'اسم المستخدم أو كلمة السر غلط'
              : 'Wrong username or password';
        });
        return;
      }

      currentAdminUser.value = response;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        smoothRoute(AdminDashboard(isArabic: isArabic)),
      );
    } catch (e) {
      // فallback: لو قاعدة بيانات المستخدمين لسه متعملتلهاش SQL،
      // نسمح بالدخول بالرقم السري القديم كـ Admin مؤقتًا
      if (password == kAdminPassword) {
        currentAdminUser.value = {
          'name': isArabic ? 'المدير' : 'Admin',
          'role': 'admin',
        };
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          smoothRoute(AdminDashboard(isArabic: isArabic)),
        );
        return;
      }
      setState(() {
        isSubmitting = false;
        errorText =
            isArabic ? 'حصلت مشكلة في الاتصال' : 'Connection problem';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'دخول الإدارة' : 'Admin Access',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'اسم المستخدم' : 'Username',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'الرقم السري' : 'Password',
                      hintStyle: const TextStyle(color: Colors.white38),
                      errorText: errorText,
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isArabic ? 'دخول' : 'Enter',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isArabic ? 'رجوع' : 'Back',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


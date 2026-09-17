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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String? errorText;
  bool obscure = true;
  bool isSubmitting = false;
  bool isFirstTimeSetup = false;

  bool get isArabic => widget.isArabic;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isFirstTimeSetup) {
      await _firstTimeSetup();
    } else {
      await _signIn();
    }
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorText = isArabic
            ? 'اكتب الإيميل وكلمة السر'
            : 'Enter email and password';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      // ١) تسجيل الدخول عن طريق Supabase Auth الحقيقي (تشفير كامل،
      // مفيش كلمة سر بتتبعت أو تتخزن كنص عادي في أي مكان).
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final user = authResponse.user;
      if (user == null) {
        setState(() {
          isSubmitting = false;
          errorText = isArabic
              ? 'الإيميل أو كلمة السر غلط'
              : 'Wrong email or password';
        });
        return;
      }

      // ٢) نتأكّد إن الحساب ده فعلاً "أدمن" — عن طريق جدول admin_users
      // المربوط بمعرّف المستخدم (مش بكلمة سر تانية). سياسة القاعدة
      // (RLS) بتسمح بس إنه يقرا صفّه هو بس، مش كل الأدمنز.
      final adminRow = await Supabase.instance.client
          .from('admin_users')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (adminRow == null) {
        // الحساب سليم بس مش أدمن — نسجّل خروج فورًا عشان محدش
        // يفضل جلسة داخلة من غير صلاحية.
        await Supabase.instance.client.auth.signOut();
        setState(() {
          isSubmitting = false;
          errorText = isArabic
              ? 'الحساب ده مش عنده صلاحية دخول لوحة التحكم'
              : 'This account has no admin access';
        });
        return;
      }

      currentAdminUser.value = adminRow;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        smoothRoute(AdminDashboard(isArabic: isArabic)),
      );
    } on AuthException catch (e) {
      setState(() {
        isSubmitting = false;
        errorText = e.message;
      });
    } catch (e) {
      setState(() {
        isSubmitting = false;
        errorText =
            isArabic ? 'حصلت مشكلة في الاتصال' : 'Connection problem';
      });
    }
  }

  // أول تسجيل دخول لأدمن جديد — المدير الأساسي بيكون سبق وضاف
  // إيميله في جدول admin_users (بدون user_id بعد)، وهنا بس بيعمل
  // حساب Supabase Auth حقيقي ونربطه بنفس الصف.
  Future<void> _firstTimeSetup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        errorText = isArabic
            ? 'اكتب الاسم والإيميل وكلمة السر'
            : 'Enter name, email and password';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      // نتأكّد الأول إن الإيميل ده معتمد فعلاً من المدير الأساسي
      // (يعني موجود في admin_users بدون user_id لسه)
      final pendingRow = await Supabase.instance.client
          .from('admin_users')
          .select()
          .eq('email', email)
          .filter('user_id', 'is', null)
          .maybeSingle();

      if (pendingRow == null) {
        setState(() {
          isSubmitting = false;
          errorText = isArabic
              ? 'الإيميل ده مش معتمد من المدير — اطلب منه يضيفك الأول'
              : 'This email is not approved by the admin yet';
        });
        return;
      }

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        setState(() {
          isSubmitting = false;
          errorText = isArabic ? 'فشل إنشاء الحساب' : 'Failed to create account';
        });
        return;
      }

      final updatedRow = await Supabase.instance.client
          .from('admin_users')
          .update({'user_id': user.id, 'name': name})
          .eq('id', pendingRow['id'] as int)
          .select()
          .single();

      currentAdminUser.value = updatedRow;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        smoothRoute(AdminDashboard(isArabic: isArabic)),
      );
    } on AuthException catch (e) {
      setState(() {
        isSubmitting = false;
        errorText = e.message;
      });
    } catch (e) {
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
                  if (isFirstTimeSetup) ...[
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isArabic ? 'اسمك' : 'Your name',
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
                  ],
                  TextField(
                    controller: emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'الإيميل' : 'Email',
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
                      hintText: isArabic ? 'كلمة السر' : 'Password',
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
                              isFirstTimeSetup
                                  ? (isArabic ? 'تفعيل الحساب' : 'Activate account')
                                  : (isArabic ? 'دخول' : 'Enter'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            setState(() {
                              isFirstTimeSetup = !isFirstTimeSetup;
                              errorText = null;
                            });
                          },
                    child: Text(
                      isFirstTimeSetup
                          ? (isArabic
                              ? 'عندك حساب بالفعل؟ سجّل دخولك'
                              : 'Already have an account? Sign in')
                          : (isArabic
                              ? 'أول مرة تدخل؟ فعّل حسابك'
                              : 'First time? Activate your account'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/auth.dart';
import '../shared/push_notifications.dart';

// ============================================================
// SETTINGS PAGE (إعدادات حساب العميل)
// ============================================================
class SettingsPage extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageChanged;

  const SettingsPage({
    super.key,
    required this.isArabic,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // نسخة محلية من اللغة عشان الصفحة نفسها تستجيب فورًا لما
  // المستخدم يغيّر اللغة من جواها، من غير ما ننتظر إعادة بناء
  // من فوق (الصفحات اللي بتتفتح بالـ Navigator.push مبتتجددش
  // تلقائيًا لو اتغيّرت حاجة في الصفحة اللي فتحتها).
  late bool _isArabic;
  bool get isArabic => _isArabic;

  final _nameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _savingName = false;
  bool _savingPassword = false;
  bool _notificationsEnabled = true;
  bool _updatingNotifications = false;

  @override
  void initState() {
    super.initState();
    _isArabic = widget.isArabic;
    final user = Supabase.instance.client.auth.currentUser;
    _nameCtrl.text = (user?.userMetadata?['full_name'] ?? '').toString();
    _notificationsEnabled =
        (user?.userMetadata?['notifications_enabled'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    // بيغيّر اللغة على مستوى التطبيق كله (الهيدر والصفحة الرئيسية)...
    widget.onLanguageChanged();
    // ...وبيغيّرها كمان جوه صفحة الإعدادات نفسها فورًا.
    setState(() => _isArabic = !_isArabic);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showMessage(isArabic ? 'اكتب الاسم الأول' : 'Please enter your name');
      return;
    }
    setState(() => _savingName = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
      _showMessage(isArabic ? 'تم حفظ الاسم' : 'Name saved');
    } catch (e) {
      _showMessage(
        isArabic ? 'تعذّر حفظ الاسم: $e' : 'Failed to save name: $e',
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _updatePassword() async {
    final currentPass = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;
    final email = Supabase.instance.client.auth.currentUser?.email;

    if (currentPass.isEmpty) {
      _showMessage(
        isArabic ? 'اكتب كلمة السر الحالية' : 'Enter your current password',
      );
      return;
    }
    if (newPass.length < 6) {
      _showMessage(
        isArabic
            ? 'كلمة السر الجديدة لازم تكون 6 حروف/أرقام على الأقل'
            : 'New password must be at least 6 characters',
      );
      return;
    }
    if (newPass != confirmPass) {
      _showMessage(
        isArabic
            ? 'كلمة السر الجديدة والتأكيد مش متطابقين'
            : 'New password and confirmation do not match',
      );
      return;
    }
    if (email == null) {
      _showMessage(
        isArabic ? 'تعذّر التحقق من الحساب' : 'Could not verify account',
      );
      return;
    }

    setState(() => _savingPassword = true);
    try {
      // الخطوة 1: نتأكد إن كلمة السر الحالية صح عن طريق تسجيل
      // دخول تجريبي بيها (Supabase مبيطلبش كلمة السر القديمة
      // تلقائيًا قبل التحديث، فبنعمل التحقق ده يدويًا).
      final verify = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPass,
      );
      if (verify.user == null) {
        _showMessage(
          isArabic ? 'كلمة السر الحالية غلط' : 'Current password is wrong',
        );
        return;
      }

      // الخطوة 2: كلمة السر الحالية صح، دلوقتي نحدّث للجديدة.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showMessage(isArabic ? 'تم تغيير كلمة السر' : 'Password updated');
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final isWrongPassword = msg.contains('invalid') ||
          msg.contains('credentials') ||
          msg.contains('password');
      _showMessage(
        isWrongPassword
            ? (isArabic
                ? 'كلمة السر الحالية غلط'
                : 'Current password is wrong')
            : (isArabic
                ? 'تعذّر تغيير كلمة السر: ${e.message}'
                : 'Failed to update password: ${e.message}'),
      );
    } catch (e) {
      _showMessage(
        isArabic
            ? 'تعذّر تغيير كلمة السر: $e'
            : 'Failed to update password: $e',
      );
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      _updatingNotifications = true;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'notifications_enabled': value}),
      );
      if (value) {
        await registerForPushNotifications();
      } else {
        await unregisterPushNotifications();
      }
    } catch (e) {
      // لو حصل خطأ، نرجّع الحالة زي ما كانت
      if (mounted) {
        setState(() => _notificationsEnabled = !value);
      }
      _showMessage(
        isArabic
            ? 'تعذّر تحديث الإشعارات: $e'
            : 'Failed to update notifications: $e',
      );
    } finally {
      if (mounted) setState(() => _updatingNotifications = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Log out'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد إنك عايز تسجّل خروج؟'
              : 'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isArabic ? 'تسجيل الخروج' : 'Log out',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await signOutUser();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'الإعدادات' : 'Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ====================================================
            // البيانات الشخصية
            // ====================================================
            _HoverCard(
              title: isArabic ? 'البيانات الشخصية' : 'Personal Info',
              icon: Icons.person_rounded,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: _fieldDecoration(
                    isArabic ? 'الاسم' : 'Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: user?.email ?? ''),
                  decoration: _fieldDecoration(
                    isArabic ? 'البريد الإلكتروني' : 'Email',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: _PrimaryButton(
                    onPressed: _savingName ? null : _saveName,
                    loading: _savingName,
                    label: isArabic ? 'حفظ' : 'Save',
                  ),
                ),
              ],
            ),

            // ====================================================
            // تغيير كلمة السر
            // ====================================================
            _HoverCard(
              title: isArabic ? 'تغيير كلمة السر' : 'Change Password',
              icon: Icons.lock_rounded,
              children: [
                TextField(
                  controller: _currentPasswordCtrl,
                  obscureText: true,
                  decoration: _fieldDecoration(
                    isArabic ? 'كلمة السر الحالية' : 'Current password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordCtrl,
                  obscureText: true,
                  decoration: _fieldDecoration(
                    isArabic ? 'كلمة السر الجديدة' : 'New password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  decoration: _fieldDecoration(
                    isArabic ? 'تأكيد كلمة السر الجديدة' : 'Confirm new password',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: _PrimaryButton(
                    onPressed: _savingPassword ? null : _updatePassword,
                    loading: _savingPassword,
                    label: isArabic ? 'تحديث كلمة السر' : 'Update password',
                  ),
                ),
              ],
            ),

            // ====================================================
            // الإشعارات
            // ====================================================
            _HoverCard(
              title: isArabic ? 'الإشعارات' : 'Notifications',
              icon: Icons.notifications_rounded,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _notificationsEnabled,
                  onChanged:
                      _updatingNotifications ? null : _toggleNotifications,
                  activeColor: Colors.red,
                  title: Text(
                    isArabic
                        ? 'تفعيل إشعارات العروض والتحديثات'
                        : 'Enable offers & update notifications',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),

            // ====================================================
            // اللغة
            // ====================================================
            _HoverCard(
              title: isArabic ? 'اللغة' : 'Language',
              icon: Icons.language_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'اللغة الحالية: العربية'
                            : 'Current language: English',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _toggleLanguage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: Text(isArabic ? 'English' : 'العربية'),
                    ),
                  ],
                ),
              ],
            ),

            // ====================================================
            // الحساب
            // ====================================================
            _HoverCard(
              title: isArabic ? 'الحساب' : 'Account',
              icon: Icons.manage_accounts_rounded,
              children: [
                Align(
                  alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      isArabic ? 'تسجيل الخروج' : 'Log out',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xfffafafa),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }
}

// ============================================================
// PRIMARY BUTTON (زرار موحّد لكل الحفظ/التحديث في الصفحة)
// ============================================================
class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  const _PrimaryButton({
    required this.onPressed,
    required this.loading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

// ============================================================
// HOVER CARD (كارت بتصميم احترافي، بيتفاعل مع الماوس عند المرور)
// ============================================================
class _HoverCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _HoverCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering ? Colors.red.withValues(alpha: 0.35) : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? Colors.black.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: _hovering ? 22 : 10,
              spreadRadius: _hovering ? 1 : 0,
              offset: Offset(0, _hovering ? 8 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(widget.icon, color: Colors.red, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.children,
          ],
        ),
      ),
    );
  }
}

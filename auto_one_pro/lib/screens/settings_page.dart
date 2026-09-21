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
  bool get isArabic => widget.isArabic;

  final _nameCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _savingName = false;
  bool _savingPassword = false;
  bool _notificationsEnabled = true;
  bool _updatingNotifications = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _nameCtrl.text = (user?.userMetadata?['full_name'] ?? '').toString();
    _notificationsEnabled =
        (user?.userMetadata?['notifications_enabled'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
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
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (newPass.length < 6) {
      _showMessage(
        isArabic
            ? 'كلمة السر لازم تكون 6 حروف/أرقام على الأقل'
            : 'Password must be at least 6 characters',
      );
      return;
    }
    if (newPass != confirmPass) {
      _showMessage(
        isArabic ? 'كلمتا السر مش متطابقتين' : 'Passwords do not match',
      );
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showMessage(isArabic ? 'تم تغيير كلمة السر' : 'Password updated');
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

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
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
            _sectionCard(
              title: isArabic ? 'البيانات الشخصية' : 'Personal Info',
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الاسم' : 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: user?.email ?? ''),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'البريد الإلكتروني' : 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _savingName ? null : _saveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _savingName
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isArabic ? 'حفظ' : 'Save'),
                  ),
                ),
              ],
            ),

            // ====================================================
            // تغيير كلمة السر
            // ====================================================
            _sectionCard(
              title: isArabic ? 'تغيير كلمة السر' : 'Change Password',
              children: [
                TextField(
                  controller: _newPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'كلمة السر الجديدة' : 'New password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        isArabic ? 'تأكيد كلمة السر' : 'Confirm password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _savingPassword ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _savingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isArabic ? 'تحديث كلمة السر' : 'Update password'),
                  ),
                ),
              ],
            ),

            // ====================================================
            // الإشعارات
            // ====================================================
            _sectionCard(
              title: isArabic ? 'الإشعارات' : 'Notifications',
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
            _sectionCard(
              title: isArabic ? 'اللغة' : 'Language',
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
                      onPressed: widget.onLanguageChanged,
                      child: Text(isArabic ? 'English' : 'العربية'),
                    ),
                  ],
                ),
              ],
            ),

            // ====================================================
            // الحساب
            // ====================================================
            _sectionCard(
              title: isArabic ? 'الحساب' : 'Account',
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
}

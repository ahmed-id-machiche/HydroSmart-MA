import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';
import '../widgets/analyse_info_row.dart';
import '../state/selected_location.dart';
import '../language/app_language.dart';
import '../language/app_translations.dart';
import '../services/pref_service.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  bool isEditing = false;
  Map<String, dynamic>? profileData;
  bool _notificationsEnabled = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  String tr(String key) => AppTranslations.t(key);

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadNotificationsPreference();
  }

  Future<void> loadNotificationsPreference() async {
    final enabled = await PrefService.getNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  String get _currentLanguageName {
    switch (appLanguageController.language) {
      case AppLanguage.english:
        return "English";
      case AppLanguage.french:
        return "Français";
      case AppLanguage.arabic:
        return "العربية";
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr("select_language")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("English"),
                leading: Radio<AppLanguage>(
                  value: AppLanguage.english,
                  groupValue: appLanguageController.language,
                  onChanged: (AppLanguage? val) {
                    if (val != null) {
                      appLanguageController.changeLanguage(val);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  appLanguageController.changeLanguage(AppLanguage.english);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Français"),
                leading: Radio<AppLanguage>(
                  value: AppLanguage.french,
                  groupValue: appLanguageController.language,
                  onChanged: (AppLanguage? val) {
                    if (val != null) {
                      appLanguageController.changeLanguage(val);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  appLanguageController.changeLanguage(AppLanguage.french);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("العربية"),
                leading: Radio<AppLanguage>(
                  value: AppLanguage.arabic,
                  groupValue: appLanguageController.language,
                  onChanged: (AppLanguage? val) {
                    if (val != null) {
                      appLanguageController.changeLanguage(val);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  appLanguageController.changeLanguage(AppLanguage.arabic);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecurityDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool localLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr("change_password")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: tr("new_password"),
                      prefixIcon: const Icon(Icons.lock_outline, color: primaryGreen),
                      filled: true,
                      fillColor: lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: tr("confirm_password"),
                      prefixIcon: const Icon(Icons.lock_outline, color: primaryGreen),
                      filled: true,
                      fillColor: lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: localLoading ? null : () => Navigator.pop(context),
                  child: Text(tr("cancel")),
                ),
                ElevatedButton(
                  onPressed: localLoading
                      ? null
                      : () async {
                          final pass = passwordController.text.trim();
                          final confirm = confirmController.text.trim();

                          if (pass.isEmpty || confirm.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr("fill_all_fields"))),
                            );
                            return;
                          }

                          if (pass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr("password_min"))),
                            );
                            return;
                          }

                          if (pass != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr("passwords_dont_match"))),
                            );
                            return;
                          }

                          setDialogState(() {
                            localLoading = true;
                          });

                          try {
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(password: pass),
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr("password_updated_success"))),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setDialogState(() {
                              localLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${tr("password_update_error")}$e")),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: localLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(tr("update")),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      passwordController.dispose();
      confirmController.dispose();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    regionController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final data = await ApiService.getFarmerProfile();
      if (!mounted) return;
      setState(() {
        profileData = data;
        nameController.text = _pickField(data, ["full_name", "fullName", "name"]) ?? "";
        phoneController.text = _pickField(data, ["phone", "phone_number", "telephone", "mobile"]) ?? "";
        regionController.text = _pickField(data, ["region", "state", "province"]) ?? "";
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${tr("profile_load_error")}$e")),
      );
    }
  }

  String? _pickField(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;
    for (final k in keys) {
      if (data.containsKey(k) && data[k] != null && data[k].toString().trim().isNotEmpty) {
        return data[k].toString();
      }
    }
    return null;
  }

  Future<void> saveProfile() async {
    setState(() {
      loading = true;
    });
    try {
      final updated = await ApiService.updateFarmerProfile(
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        region: regionController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        profileData = updated;
        isEditing = false;
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("profile_updated"))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${tr("profile_update_error")}$e")),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await SelectedLocation.clear();
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const SignInScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? "User";
    final userId = user?.id ?? "-";

    final displayFarmer = tr("farmer");
    final displayName = _pickField(profileData, ["full_name", "fullName", "name"]) ?? displayFarmer;
    final displayPhone = _pickField(profileData, ["phone", "phone_number", "telephone", "mobile"]) ?? tr("not_specified");
    final displayRegion = _pickField(profileData, ["region", "state", "province"]) ?? tr("not_specified");
    final displayRole = _pickField(profileData, ["role"]) ?? "farmer";
    final displayRoleLabel = displayRole == "admin" ? tr("administrator") : tr("farmer");

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
              decoration: const BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.white),
                      const Spacer(),
                      Text(
                        tr("profile_title"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.close : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isEditing) {
                              nameController.text = profileData?["full_name"] ?? "";
                              phoneController.text = profileData?["phone"] ?? "";
                              regionController.text = profileData?["region"] ?? "";
                            }
                            isEditing = !isEditing;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayRegion,
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        if (isEditing) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr("edit_profile_info"),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: tr("full_name"),
                                    prefixIcon: const Icon(Icons.person_outline, color: primaryGreen),
                                    filled: true,
                                    fillColor: lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: tr("phone"),
                                    prefixIcon: const Icon(Icons.phone_outlined, color: primaryGreen),
                                    filled: true,
                                    fillColor: lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: regionController,
                                  decoration: InputDecoration(
                                    labelText: tr("region"),
                                    prefixIcon: const Icon(Icons.map_outlined, color: primaryGreen),
                                    filled: true,
                                    fillColor: lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    onPressed: saveProfile,
                                    child: Text(
                                      tr("save_changes"),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardGreen,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                AnalyseInfoRow(
                                  icon: Icons.badge_outlined,
                                  label: tr("role"),
                                  value: displayRoleLabel,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.email_outlined,
                                  label: tr("email"),
                                  value: email,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.phone_outlined,
                                  label: tr("phone"),
                                  value: displayPhone,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.map_outlined,
                                  label: tr("region"),
                                  value: displayRegion,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.fingerprint,
                                  label: tr("user_id"),
                                  value: userId.length > 8
                                      ? "${userId.substring(0, 8)}..."
                                      : userId,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              ProfileOption(
                                icon: Icons.notifications_outlined,
                                title: tr("notifications"),
                                subtitle: tr("notifications_subtitle"),
                                trailing: Switch(
                                  value: _notificationsEnabled,
                                  onChanged: (value) async {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                    await PrefService.setNotificationsEnabled(value);
                                  },
                                  activeColor: primaryGreen,
                                ),
                              ),
                              const Divider(height: 24),
                              ProfileOption(
                                icon: Icons.language_outlined,
                                title: tr("language"),
                                subtitle: _currentLanguageName,
                                onTap: _showLanguageDialog,
                              ),
                              const Divider(height: 24),
                              ProfileOption(
                                icon: Icons.security_outlined,
                                title: tr("security"),
                                subtitle: tr("security_subtitle"),
                                onTap: _showSecurityDialog,
                              ),
                              const Divider(height: 24),
                              ProfileOption(
                                icon: Icons.help_outline,
                                title: tr("help"),
                                subtitle: tr("help_subtitle"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () => logout(context),
                            icon: const Icon(Icons.logout),
                            label: Text(
                              tr("log_out"),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
        ],
      ),
    );
  }
}
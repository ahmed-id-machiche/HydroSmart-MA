import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';
import '../widgets/analyse_info_row.dart';
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
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
        nameController.text = data["full_name"] ?? "";
        phoneController.text = data["phone"] ?? "";
        regionController.text = data["region"] ?? "";
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur profil: $e")),
      );
    }
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
        const SnackBar(content: Text("Profil mis à jour avec succès !")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur mise à jour: $e")),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
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
    final email = user?.email ?? "Utilisateur";
    final userId = user?.id ?? "-";

    final displayName = profileData?["full_name"] ?? "Agriculteur";
    final displayPhone = profileData?["phone"] ?? "Non spécifié";
    final displayRegion = profileData?["region"] ?? "Non spécifiée";
    final displayRole = profileData?["role"] ?? "farmer";
    final displayRoleFr = displayRole == "admin" ? "Administrateur" : "Agriculteur";

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
                      const Text(
                        "Profil Agriculteur",
                        style: TextStyle(
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
                                const Text(
                                  "Modifier vos informations",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: "Nom complet",
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
                                    labelText: "Numéro de téléphone",
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
                                    labelText: "Région",
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
                                    child: const Text(
                                      "Sauvegarder",
                                      style: TextStyle(fontWeight: FontWeight.bold),
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
                                  label: "Rôle",
                                  value: displayRoleFr,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.email_outlined,
                                  label: "Email",
                                  value: email,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.phone_outlined,
                                  label: "Téléphone",
                                  value: displayPhone,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.map_outlined,
                                  label: "Région",
                                  value: displayRegion,
                                ),
                                const Divider(height: 24),
                                AnalyseInfoRow(
                                  icon: Icons.fingerprint,
                                  label: "User ID",
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
                                title: "Notifications",
                                subtitle: "Alertes d’irrigation et météo",
                                trailing: Switch(
                                  value: true,
                                  onChanged: (_) {},
                                  activeColor: primaryGreen,
                                ),
                              ),
                              const Divider(height: 24),
                              const ProfileOption(
                                icon: Icons.language_outlined,
                                title: "Langue",
                                subtitle: "Français",
                              ),
                              const Divider(height: 24),
                              const ProfileOption(
                                icon: Icons.security_outlined,
                                title: "Sécurité",
                                subtitle: "Compte et confidentialité",
                              ),
                              const Divider(height: 24),
                              const ProfileOption(
                                icon: Icons.help_outline,
                                title: "Aide",
                                subtitle: "Support et documentation",
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
                            label: const Text(
                              "Se déconnecter",
                              style: TextStyle(fontWeight: FontWeight.bold),
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

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
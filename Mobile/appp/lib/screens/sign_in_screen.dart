import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../language/app_language.dart';
import '../language/app_translations.dart';
import '../services/api_services.dart';
import '../services/pref_service.dart';
import 'main_navigation.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();

  bool loading = false;
  bool isSignUpMode = false;
  bool obscurePassword = true;
  bool keepSignedIn = true;

  String tr(String key) => AppTranslations.t(key);

  @override
  void initState() {
    super.initState();
    loadKeepSignedIn();
  }

  Future<void> loadKeepSignedIn() async {
    final value = await PrefService.getKeepSignedIn();
    setState(() {
      keepSignedIn = value;
    });
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(tr("fill_email_password"));
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await PrefService.setKeepSignedIn(keepSignedIn);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
      );
    } on AuthException catch (error) {
      showMessage(error.message);
    } catch (error) {
      showMessage("${tr("login_error")}: $error");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(tr("fill_email_password"));
      return;
    }

    if (fullName.isEmpty) {
      showMessage(tr("fill_full_name"));
      return;
    }

    if (password.length < 6) {
      showMessage(tr("password_min"));
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        showMessage(tr("check_email"));

        setState(() {
          isSignUpMode = false;
        });

        return;
      }

      await ApiService.createFarmerProfile(
        id: user.id,
        email: email,
        fullName: fullName,
        phone: phone.isEmpty ? null : phone,
        region: null,
      );

      await PrefService.setKeepSignedIn(keepSignedIn);

      if (!mounted) return;

      if (response.session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigation(),
          ),
        );
      } else {
        showMessage(tr("account_created"));

        setState(() {
          isSignUpMode = false;
        });
      }
    } on AuthException catch (error) {
      showMessage(error.message);
    } catch (error) {
      showMessage("${tr("signup_error")}: $error");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    try {
      setState(() {
        loading = true;
      });

      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.hydrosmart://login-callback',
      );

      await PrefService.setKeepSignedIn(keepSignedIn);
    } on AuthException catch (error) {
      showMessage(error.message);
    } catch (error) {
      showMessage("Erreur connexion sociale: $error");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return AnimatedBuilder(
          animation: appLanguageController,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr("language"),
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LanguageOption(
                    title: "English",
                    code: "EN",
                    selected:
                        appLanguageController.language == AppLanguage.english,
                    onTap: () {
                      appLanguageController.changeLanguage(
                        AppLanguage.english,
                      );
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  LanguageOption(
                    title: "Français",
                    code: "FR",
                    selected:
                        appLanguageController.language == AppLanguage.french,
                    onTap: () {
                      appLanguageController.changeLanguage(
                        AppLanguage.french,
                      );
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  LanguageOption(
                    title: "العربية",
                    code: "AR",
                    selected:
                        appLanguageController.language == AppLanguage.arabic,
                    onTap: () {
                      appLanguageController.changeLanguage(
                        AppLanguage.arabic,
                      );
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8FF),
      prefixIcon: Icon(
        icon,
        color: Colors.redAccent,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget inputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguageController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: primaryGreen,
          body: SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(22),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: loginCardGreen,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: openLanguageSheet,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language,
                                  size: 16,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  appLanguageController.languageCode,
                                  style: const TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isSignUpMode
                            ? tr("create_account")
                            : tr("welcome_back"),
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        isSignUpMode
                            ? tr("signup_subtitle")
                            : tr("login_subtitle"),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),

                      const SizedBox(height: 22),

                      Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          "assets/images/logo.png",
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.water_drop,
                              color: Colors.lightBlueAccent,
                              size: 55,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 26),

                      if (isSignUpMode) ...[
                        inputLabel(tr("full_name")),
                        const SizedBox(height: 8),
                        TextField(
                          controller: fullNameController,
                          decoration: inputDecoration(
                            hint: tr("enter_full_name"),
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 18),

                        inputLabel(tr("phone")),
                        const SizedBox(height: 8),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: inputDecoration(
                            hint: tr("enter_phone"),
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      inputLabel(tr("email")),

                      const SizedBox(height: 8),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDecoration(
                          hint: tr("enter_email"),
                          icon: Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(height: 18),

                      inputLabel(tr("password")),

                      const SizedBox(height: 8),

                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: inputDecoration(
                          hint: tr("enter_password"),
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (!isSignUpMode)
                        Row(
                          children: [
                            Checkbox(
                              value: keepSignedIn,
                              onChanged: (val) {
                                setState(() {
                                  keepSignedIn = val ?? true;
                                });
                                PrefService.setKeepSignedIn(keepSignedIn);
                              },
                              side: const BorderSide(color: Colors.green),
                            ),
                            Text(
                              tr("keep_signed_in"),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              tr("forgot_password"),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      if (isSignUpMode)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            tr("password_rule"),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF48AD63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: loading
                              ? null
                              : isSignUpMode
                                  ? signUp
                                  : signIn,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isSignUpMode
                                      ? tr("sign_up")
                                      : tr("sign_in"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white70)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              tr("connect_with"),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white70)),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => signInWithOAuth(OAuthProvider.facebook),
                            borderRadius: BorderRadius.circular(21),
                            child: const Icon(Icons.facebook, color: Colors.blue, size: 42),
                          ),
                          const SizedBox(width: 22),
                          InkWell(
                            onTap: () => signInWithOAuth(OAuthProvider.google),
                            borderRadius: BorderRadius.circular(23),
                            child: const Icon(
                              Icons.g_mobiledata,
                              color: Colors.orange,
                              size: 46,
                            ),
                          ),
                          const SizedBox(width: 22),
                          InkWell(
                            onTap: () => signInWithOAuth(OAuthProvider.apple),
                            borderRadius: BorderRadius.circular(21),
                            child: const Icon(Icons.apple, color: Colors.black, size: 42),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      InkWell(
                        onTap: () {
                          setState(() {
                            isSignUpMode = !isSignUpMode;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: isSignUpMode
                                    ? tr("already_have_account")
                                    : tr("dont_have_account"),
                              ),
                              TextSpan(
                                text: isSignUpMode
                                    ? tr("sign_in_here")
                                    : tr("sign_up_here"),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LanguageOption extends StatelessWidget {
  final String title;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const LanguageOption({
    super.key,
    required this.title,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected ? loginCardGreen : lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primaryGreen : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: selected ? primaryGreen : Colors.white,
              child: Text(
                code,
                style: TextStyle(
                  color: selected ? Colors.white : primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: primaryGreen,
              ),
          ],
        ),
      ),
    );
  }
}
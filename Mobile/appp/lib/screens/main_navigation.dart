import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';
import '../state/selected_location.dart';
import 'analyse_screen.dart';
import 'fields_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'sign_in_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  bool _isLoading = true;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkBlockedStatus();
  }

  Future<void> _checkBlockedStatus() async {
    try {
      final profile = await ApiService.getFarmerProfile();
      if (profile['role'] == 'blocked') {
        setState(() {
          _isBlocked = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void goToFields() {
    setState(() {
      currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
          ),
        ),
      );
    }

    if (_isBlocked) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.block_outlined,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                "Account Blocked",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your account has been suspended by the administrator. Please contact support if you believe this is a mistake.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () async {
                  await SelectedLocation.clear();
                  await Supabase.instance.client.auth.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignInScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screens = [
      HomeScreen(
        onViewAllFields: goToFields,
      ),
      const AnalyseScreen(),
      const FieldsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryGreen),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: primaryGreen),
            label: "Analyze",
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass, color: primaryGreen),
            label: "Fields",
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: primaryGreen),
            label: "History",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: primaryGreen),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
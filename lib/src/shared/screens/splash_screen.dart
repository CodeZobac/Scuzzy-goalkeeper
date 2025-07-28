import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/controllers/user_profile_controller.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Wait for the first frame to be rendered to ensure context is available
    await Future.delayed(Duration.zero);

    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session == null) {
      // Initialize guest context for users without session
      final authProvider = context.read<AuthStateProvider>();
      authProvider.initializeGuestContext();
      
      // Redirect to home as guest instead of signin
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    final userProfileController = context.read<UserProfileController>();
    await userProfileController.getUserProfile();

    if (!mounted) return;

    final profile = userProfileController.userProfile;
    if (profile != null && !profile.profileCompleted) {
      Navigator.of(context).pushReplacementNamed('/complete-profile');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

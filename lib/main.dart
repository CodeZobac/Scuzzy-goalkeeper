import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:goalkeeper/src/features/user_profile/data/repositories/user_profile_repository.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/controllers/user_profile_controller.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/profile_screen.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/data/repositories/goalkeeper_search_repository.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/presentation/controllers/goalkeeper_search_controller.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:goalkeeper/src/features/map/presentation/providers/field_selection_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';
import 'package:goalkeeper/src/features/map/presentation/screens/map_screen.dart';
import 'package:goalkeeper/src/features/main/presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      // Firebase configuration will be read from google-services.json/GoogleService-Info.plist
      // For now, we'll initialize without options and handle the configuration later
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase for now - FCM notifications won't work
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Create and initialize the service before running the app
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationService>.value(
          value: notificationService,
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileController(UserProfileRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalkeeperSearchController(GoalkeeperSearchRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => FieldSelectionProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Handle user authentication state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = context.read<NotificationService>();
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        
        if (event == AuthChangeEvent.signedIn) {
          notificationService.onUserSignIn().catchError((error) {
            debugPrint('Failed to handle user sign-in for notifications: $error');
          });
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          notificationService.disableToken().catchError((error) {
            debugPrint('Failed to disable notification token: $error');
          });
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/signin');
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goalkeeper-Finder',
      theme: AppTheme.darkTheme,
      initialRoute: Supabase.instance.client.auth.currentSession == null ? '/signin' : '/home',
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}

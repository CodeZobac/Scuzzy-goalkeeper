import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:goalkeeper/src/core/config/app_config.dart';
import 'package:goalkeeper/src/features/user_profile/data/repositories/user_profile_repository.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/controllers/user_profile_controller.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/profile_screen.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/complete_profile_screen.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/data/repositories/goalkeeper_search_repository.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/presentation/controllers/goalkeeper_search_controller.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:goalkeeper/src/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/create_announcement_screen.dart';
import 'package:goalkeeper/src/features/map/presentation/providers/field_selection_provider.dart';
import 'package:goalkeeper/src/core/navigation/navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';
import 'package:goalkeeper/src/features/map/presentation/screens/map_screen.dart';
import 'package:goalkeeper/src/features/main/presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
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
          create: (_) => AnnouncementController(
            AnnouncementRepositoryImpl(Supabase.instance.client),
          ),
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
    
    _handleAuthStateChanges();
  }

  void _handleAuthStateChanges() {
    final userProfileController = context.read<UserProfileController>();
    final notificationService = context.read<NotificationService>();
    final announcementController = context.read<AnnouncementController>();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        await userProfileController.getUserProfile();
        final profile = userProfileController.userProfile;
        if (profile != null && !profile.profileCompleted) {
          Navigator.of(context).pushReplacementNamed('/complete-profile');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        notificationService.disableToken().catchError((error) {
          debugPrint('Failed to disable notification token: $error');
        });
        // Clear announcement cache when user signs out
        announcementController.clearParticipationCache();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signin');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goalkeeper-Finder',
      theme: AppTheme.darkTheme,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: Supabase.instance.client.auth.currentSession == null ? '/signin' : '/home',
      onGenerateRoute: _generateRoute,
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/map': (context) => const MapScreen(),
        '/announcements': (context) => const AnnouncementsScreen(),
        '/create-announcement': (context) => const CreateAnnouncementScreen(),
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/announcement-detail':
        final announcement = settings.arguments;
        if (announcement != null) {
          return _createSlideRoute(
            AnnouncementDetailScreen(announcement: announcement as dynamic),
          );
        }
        return null;
      default:
        return null;
    }
  }

  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:goalkeeper/src/core/config/firebase_config.dart';
import 'package:goalkeeper/src/core/config/app_config.dart';
import 'package:goalkeeper/src/features/user_profile/data/repositories/user_profile_repository.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/controllers/user_profile_controller.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/profile_screen.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/complete_profile_screen.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/data/repositories/goalkeeper_search_repository.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/presentation/controllers/goalkeeper_search_controller.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service_manager.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:goalkeeper/src/features/notifications/presentation/controllers/notification_preferences_controller.dart';
import 'package:goalkeeper/src/features/notifications/presentation/controllers/notification_badge_controller.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
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
import 'package:goalkeeper/src/shared/screens/splash_screen.dart';
import 'package:goalkeeper/src/core/error_handling/error_monitoring_service.dart';
import 'package:goalkeeper/src/core/logging/error_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Initialize error monitoring service first
  await ErrorMonitoringService.instance.initialize();

  late final NotificationService notificationService;


  // Initialize Firebase

  try {
    await dotenv.load(fileName: ".env");

    // Initialize Firebase (optional - only if configuration files exist)
    final firebaseInitialized = await FirebaseConfig.initialize();

    // Initialize Supabase with environment variables or fallback to AppConfig
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? AppConfig.supabaseUrl;
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? AppConfig.supabaseAnonKey;
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    // Initialize the enhanced notification service manager
    final notificationServiceManager = NotificationServiceManager.instance;
    await notificationServiceManager.initialize();
    
    // Get the core notification service for provider
    notificationService = notificationServiceManager.notificationService;


    ErrorLogger.logInfo(
      'Application initialized successfully',
      context: 'APP_STARTUP',
      additionalData: {
        'firebase_initialized': firebaseInitialized,
        'supabase_url': dotenv.env['SUPABASE_URL'] != null ? 'configured' : 'missing',
      },
    );
  } catch (error, stackTrace) {
    ErrorLogger.logError(
      error,
      stackTrace,
      context: 'APP_STARTUP_ERROR',
      severity: ErrorSeverity.error,
    );
    
    ErrorMonitoringService.instance.reportError(
      'startup_failure',
      context: 'APP_STARTUP',
      severity: ErrorSeverity.error,
    );
    
    // Re-throw to prevent app from starting in broken state
    rethrow;
  }

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
        ChangeNotifierProvider(
          create: (_) => NotificationPreferencesController(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationBadgeController(NotificationRepository()),
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
    // Handle user authentication state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileController = context.read<UserProfileController>();
      final notificationService = context.read<NotificationService>();
      final announcementController = context.read<AnnouncementController>();
      final notificationServiceManager = NotificationServiceManager.instance;

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final user = data.session?.user;

        // The splash screen handles the initial navigation. This listener handles auth changes while the app is running.
        if (event == AuthChangeEvent.initialSession) {
          return;
        }

        if (event == AuthChangeEvent.signedIn && user != null) {
          // Initialize enhanced notification services for user
          notificationServiceManager.onUserSignIn(user.id).catchError((error) {
            debugPrint('Failed to initialize enhanced notification services: $error');
          });

          // Legacy notification service initialization
          notificationService.onUserSignIn().catchError((error) {
            debugPrint('Failed to handle user sign-in for notifications: $error');
          });

          // Initialize notification badge controller
          final badgeController = context.read<NotificationBadgeController>();
          badgeController.initialize(user.id).catchError((error) {
            debugPrint('Failed to initialize notification badge controller: $error');
          });

          // Check user profile completion on sign-in
          await userProfileController.getUserProfile();
          final profile = userProfileController.userProfile;
          // Use the global navigator key to avoid context issues
          final navigator = NavigationService.navigator;
          if (navigator != null && navigator.mounted) {
            if (profile != null && !profile.profileCompleted) {
              navigator.pushReplacementNamed('/complete-profile');
            } else {
              navigator.pushReplacementNamed('/home');
            }
          }
        } else if (event == AuthChangeEvent.signedOut) {
          // Cleanup enhanced notification services
          notificationServiceManager.onUserSignOut().catchError((error) {
            debugPrint('Failed to cleanup enhanced notification services: $error');
          });

          // Legacy notification service cleanup
          notificationService.disableToken().catchError((error) {
            debugPrint('Failed to disable notification token: $error');
          });

          // Clear announcement cache when user signs out
          announcementController.clearParticipationCache();

          // Use the global navigator key to avoid context issues
          final navigator = NavigationService.navigator;
          if (navigator != null && navigator.mounted) {
            navigator.pushReplacementNamed('/signin');
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
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
      routes: {
        '/': (context) => const SplashScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/notification-preferences': (context) => const NotificationPreferencesScreen(),
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
      case '/contract-details':
        final contractData = settings.arguments as Map<String, dynamic>?;
        if (contractData != null) {
          return _createSlideRoute(
            _buildContractDetailsScreen(contractData),
          );
        }
        return null;
      case '/notification-deep-link':
        final notificationData = settings.arguments as Map<String, dynamic>?;
        if (notificationData != null) {
          return _handleNotificationDeepLink(notificationData);
        }
        return null;
      default:
        return null;
    }
  }

  /// Build contract details screen (placeholder until dedicated screen is created)
  Widget _buildContractDetailsScreen(Map<String, dynamic> contractData) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Contrato'),
        backgroundColor: AppTheme.primaryBackground,
      ),
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.handshake,
                  size: 80,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Detalhes do Contrato',
                  style: AppTheme.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tela de detalhes do contrato será implementada em breve.',
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Voltar',
                    style: AppTheme.buttonText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle notification deep linking
  Route<dynamic>? _handleNotificationDeepLink(Map<String, dynamic> notificationData) {
    final type = notificationData['type'] as String?;
    
    switch (type) {
      case 'contract_request':
        return _createSlideRoute(_buildContractDetailsScreen(notificationData));
      case 'full_lobby':
        return _handleFullLobbyDeepLink(notificationData);
      default:
        // Navigate to notifications screen for unknown types
        return _createSlideRoute(const NotificationsScreen());
    }
  }

  /// Handle full lobby notification deep link
  Route<dynamic>? _handleFullLobbyDeepLink(Map<String, dynamic> notificationData) {
    final announcementIdStr = notificationData['announcement_id'] as String?;
    
    if (announcementIdStr != null) {
      final announcementId = int.tryParse(announcementIdStr);
      if (announcementId != null) {
        // Navigate to main screen with notifications tab selected and then to announcement
        return _createSlideRoute(
          _DeepLinkHandler(
            targetScreen: 'announcement_detail',
            data: {'announcement_id': announcementId},
          ),
        );
      }
    }
    
    // Fallback to notifications screen
    return _createSlideRoute(const NotificationsScreen());
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

/// Deep link handler widget that manages navigation to specific screens
class _DeepLinkHandler extends StatefulWidget {
  final String targetScreen;
  final Map<String, dynamic> data;

  const _DeepLinkHandler({
    required this.targetScreen,
    required this.data,
  });

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    
    // Handle navigation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLinkNavigation();
    });
  }

  Future<void> _handleDeepLinkNavigation() async {
    try {
      switch (widget.targetScreen) {
        case 'announcement_detail':
          await _navigateToAnnouncementDetail();
          break;
        default:
          _navigateToNotifications();
      }
    } catch (e) {
      debugPrint('Error handling deep link navigation: $e');
      _navigateToNotifications();
    }
  }

  Future<void> _navigateToAnnouncementDetail() async {
    final announcementId = widget.data['announcement_id'] as int?;
    if (announcementId == null) {
      _navigateToNotifications();
      return;
    }

    try {
      // Get announcement repository from context
      final announcementController = context.read<AnnouncementController>();
      
      // Try to find the announcement in the current list first
      final existingAnnouncement = announcementController.announcements
          .where((a) => a.id == announcementId)
          .firstOrNull;

      if (existingAnnouncement != null) {
        // Navigate directly if announcement is already loaded
        Navigator.of(context).pushReplacementNamed(
          '/announcement-detail',
          arguments: existingAnnouncement,
        );
      } else {
        // Fetch the announcement and then navigate
        final repository = AnnouncementRepositoryImpl(Supabase.instance.client);
        final announcement = await repository.getAnnouncementById(announcementId);
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/announcement-detail',
            arguments: announcement,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching announcement for deep link: $e');
      _navigateToNotifications();
    }
  }

  void _navigateToNotifications() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while handling navigation
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
              SizedBox(height: 24),
              Text(
                'Carregando...',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

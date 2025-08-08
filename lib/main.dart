import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:goalkeeper/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/config/app_config.dart';
import 'src/core/config/config_validator.dart';
import 'src/core/config/firebase_config.dart';
import 'src/core/error_handling/error_monitoring_service.dart';
import 'src/core/logging/error_logger.dart';
import 'src/core/navigation/navigation_service.dart';
import 'src/core/services/deep_link_service.dart';
import 'src/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'src/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'src/features/announcements/presentation/screens/create_announcement_screen.dart';
import 'src/features/auth/presentation/providers/auth_state_provider.dart';
import 'src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'src/features/auth/presentation/screens/reset_password_screen.dart';
import 'src/features/auth/presentation/screens/sign_in_screen.dart';
import 'src/features/auth/presentation/screens/sign_up_screen.dart';
import 'src/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'src/features/auth/presentation/screens/email_confirmation_waiting_screen.dart';
import 'src/features/auth/presentation/theme/app_theme.dart';
import 'src/features/auth/services/email_confirmation_service.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/goalkeeper_search/data/repositories/goalkeeper_search_repository.dart';
import 'src/features/goalkeeper_search/presentation/controllers/goalkeeper_search_controller.dart';
import 'src/features/main/presentation/screens/main_screen.dart';
import 'src/features/map/presentation/providers/field_selection_provider.dart';
import 'src/features/notifications/data/repositories/notification_repository.dart';
import 'src/features/notifications/presentation/controllers/notification_badge_controller.dart';
import 'src/features/notifications/presentation/controllers/notification_preferences_controller.dart';
import 'src/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'src/features/notifications/presentation/screens/notifications_screen.dart';
import 'src/features/notifications/services/notification_service.dart';
import 'src/features/notifications/services/notification_service_manager.dart';
import 'src/features/user_profile/data/repositories/user_profile_repository.dart';
import 'src/features/user_profile/presentation/controllers/user_profile_controller.dart';
import 'src/features/user_profile/presentation/screens/complete_profile_screen.dart';
import 'src/features/user_profile/presentation/screens/profile_screen.dart';
import 'src/shared/screens/splash_screen.dart';
import 'src/shared/screens/deep_link_test_screen.dart';
import 'src/core/state/password_reset_state.dart';
import 'src/core/services/http_email_service_initializer.dart';
import 'src/core/services/http_email_service_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error monitoring service first
  await ErrorMonitoringService.instance.initialize();

  late final NotificationService notificationService;
  bool firebaseInitialized = false;
  bool emailServicesInitialized = false;

  try {
    // Initialize Firebase (optional - only if configuration files exist)
    firebaseInitialized = await FirebaseConfig.initialize();

    // Validate and log configuration status
    ConfigValidator.logConfigurationStatus();
    ConfigValidator.validateConfiguration();

    // Initialize Supabase using unified AppConfig
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    // Initialize the enhanced notification service manager
    final notificationServiceManager = NotificationServiceManager.instance;
    await notificationServiceManager.initialize();

    // Get the core notification service for provider
    notificationService = notificationServiceManager.notificationService;

    // Initialize deep link service for password reset handling
    await DeepLinkService.instance.initialize();

    // Initialize HTTP-based email services (communicating with Python backend)
    emailServicesInitialized = await HttpEmailServiceInitializer.initialize();
    
    ErrorLogger.logInfo(
      'Application initialized successfully',
      context: 'APP_STARTUP',
      additionalData: {
        'firebase_initialized': firebaseInitialized,
        'supabase_url': AppConfig.supabaseUrl.isNotEmpty ? 'configured' : 'missing',
        'deep_links_enabled': true,
        'email_services_initialized': emailServicesInitialized,
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
        ChangeNotifierProvider(
          create: (_) => AuthStateProvider(),
        ),
        // HTTP Email Service Providers - only create if email services were initialized
        if (emailServicesInitialized) ...HttpEmailServiceProviders.createProviders(),
      ],
      child: MyApp(emailServicesInitialized: emailServicesInitialized),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool emailServicesInitialized;
  
  const MyApp({super.key, required this.emailServicesInitialized});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  String _getInitialRoute() {
    // Check if app was opened via password reset URL fragment
    // This handles web-based password reset links
    final currentUrl = Uri.base;
    
    // Debug: Print URL information
    print('=== PASSWORD RESET DEBUG ===');
    print('Full URL: ${currentUrl.toString()}');
    print('Fragment: ${currentUrl.fragment}');
    print('Query Parameters: ${currentUrl.queryParameters}');
    print('Path: ${currentUrl.path}');
    
    // Check for password reset in URL fragment (common pattern: #/reset-password)
    final hasResetPasswordFragment = currentUrl.fragment.contains('reset-password') || 
                                   currentUrl.path.contains('reset-password');
    
    // Check for email confirmation in URL fragment (pattern: #/email-confirmed)
    final hasEmailConfirmationFragment = currentUrl.fragment.contains('email-confirmed') || 
                                        currentUrl.path.contains('email-confirmed');
    
    // Check for Supabase auth tokens (code parameter or access_token in fragment)
    final hasSupabaseAuthCode = currentUrl.queryParameters.containsKey('code') ||
                              currentUrl.fragment.contains('access_token=') ||
                              currentUrl.fragment.contains('refresh_token=') ||
                              currentUrl.fragment.contains('token_type=');
    
    print('Has reset-password fragment: $hasResetPasswordFragment');
    print('Has email-confirmation fragment: $hasEmailConfirmationFragment');
    print('Has Supabase auth code: $hasSupabaseAuthCode');
    print('=== END DEBUG ===');
    
    // If we have email confirmation fragment, treat as email confirmation (not password reset)
    if (hasEmailConfirmationFragment && hasSupabaseAuthCode) {
      ErrorLogger.logInfo(
        'Email confirmation URL detected - allowing normal auth flow',
        context: 'EMAIL_CONFIRMATION_URL_DETECTED',
        additionalData: {
          'fragment': currentUrl.fragment,
          'query_params': currentUrl.queryParameters.toString(),
          'full_url': currentUrl.toString(),
        },
      );
      // Don't set password recovery mode for email confirmations
    }
    // If we have reset-password fragment, always treat as password reset initially
    else if (hasResetPasswordFragment) {
      // Set GLOBAL flag to prevent any redirects
      PasswordResetState.setInProgress();
      
      // Set password recovery mode IMMEDIATELY when app is opened via reset link
      // Don't wait for post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final authProvider = context.read<AuthStateProvider>();
          authProvider.handlePasswordRecoveryMode();
        }
      });
      
      ErrorLogger.logInfo(
        'Password reset URL detected - recovery mode set IMMEDIATELY',
        context: 'PASSWORD_RESET_URL_DETECTED',
        additionalData: {
          'fragment': currentUrl.fragment,
          'query_params': currentUrl.queryParameters.toString(),
          'full_url': currentUrl.toString(),
          'has_auth_tokens': hasSupabaseAuthCode,
        },
      );
      
      return '/reset-password';
    }

    // Check if app was opened via password reset deep link (mobile)
    if (DeepLinkService.instance.isInitialPasswordResetLink) {
      DeepLinkService.instance.clearInitialUri();
      // Set password recovery mode for mobile deep links
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final authProvider = context.read<AuthStateProvider>();
          authProvider.handlePasswordRecoveryMode();
        }
      });
      return '/reset-password';
    }

    // Determine initial route based on authentication state
    final isAuthenticated = Supabase.instance.client.auth.currentSession != null;

    if (!isAuthenticated) {
      // For guest users, initialize guest context immediately
      // This ensures guest tracking starts from app launch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final authProvider = context.read<AuthStateProvider>();
          authProvider.initializeGuestContext();
        }
      });
    }

    // Both authenticated and guest users start at home
    // MainScreen will handle guest-specific behavior and content
    // This ensures consistent initialization for all users
    return '/home';
  }

  Widget _buildHomeRoute(BuildContext context) {
    final authProvider = context.read<AuthStateProvider>();

    // Initialize guest context for guest users using post frame callback
    if (authProvider.isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.initializeGuestContext();
      });
    }

    return const MainScreen();
  }

  Widget _buildRouteForGuests(BuildContext context, String routeName, int tabIndex) {
    final authProvider = context.read<AuthStateProvider>();

    if (authProvider.isGuest) {
      // For guest users, redirect to MainScreen with appropriate tab
      // MainScreen will handle guest-specific content and registration prompts
      // Initialize guest context if not already done using post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.initializeGuestContext();
        // Track guest route access
        authProvider.trackGuestContentView('route_$routeName');
      });

      return MainScreen(initialTabIndex: tabIndex);
    }

    // For authenticated users, return the appropriate screen
    switch (routeName) {
      case '/profile':
        return const ProfileScreen();
      case '/notifications':
        return const NotificationsScreen();
      case '/announcements':
        return MainScreen(initialTabIndex: tabIndex);
      case '/map':
        return MainScreen(initialTabIndex: tabIndex);
      default:
        return const MainScreen();
    }
  }

  Widget _requiresAuthentication(BuildContext context, Widget screen) {
    final authProvider = context.read<AuthStateProvider>();

    if (authProvider.isGuest) {
      // For guest users trying to access auth-required screens, show redirect screen
      // This provides better UX than immediate redirect
      return _buildGuestRedirectScreen('/signup');
    }

    return screen;
  }



  @override
  void initState() {
    super.initState();
    _handleAuthStateChanges();
    _setupDeepLinkHandling();
  }

  void _setupDeepLinkHandling() {
    // Set up deep link callback for password reset
    DeepLinkService.instance.setDeepLinkCallback((Uri uri) {
      if (uri.scheme == 'io.supabase.goalkeeper' && uri.host == 'reset-password') {
        // Navigate to reset password screen when deep link is received
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final authProvider = context.read<AuthStateProvider>();
            authProvider.handlePasswordRecoveryMode();
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/reset-password',
              (route) => false,
            );
          }
        });
      }
    });
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

        // Log all auth state changes for debugging
        ErrorLogger.logInfo(
          'Auth state change detected',
          context: 'AUTH_STATE_CHANGE',
          additionalData: {
            'event': event.toString(),
            'has_user': user != null,
            'has_session': data.session != null,
          },
        );

        // The splash screen handles the initial navigation. This listener handles auth changes while the app is running.
        if (event == AuthChangeEvent.initialSession) {
          return;
        }

        if (event == AuthChangeEvent.signedIn && user != null) {
          final authProvider = context.read<AuthStateProvider>();
          
          // FIRST: Check GLOBAL password reset flag (ULTIMATE BLOCKER)
          if (PasswordResetState.isInProgress) {
            print('🚫 GLOBAL BLOCK: Password reset in progress - BLOCKING ALL NAVIGATION');
            ErrorLogger.logInfo(
              '🚫 GLOBAL BLOCKED: Sign-in event during password reset - staying on reset screen',
              context: 'AUTH_GLOBAL_PASSWORD_RESET_BLOCKED',
            );
            return;
          }
          
          // SECOND: Check if we're already in password recovery mode
          if (authProvider.isInPasswordRecoveryMode) {
            ErrorLogger.logInfo(
              '🚫 BLOCKED: Sign-in event during password recovery mode - staying on reset screen',
              context: 'AUTH_PASSWORD_RECOVERY_MODE_SIGNIN_BLOCKED',
            );
            return;
          }
          
          // THIRD: Check if the current URL indicates a password reset flow vs email confirmation
          final currentUrl = Uri.base;
          final hasResetPasswordFragment = currentUrl.fragment.contains('reset-password');
          final hasEmailConfirmationFragment = currentUrl.fragment.contains('email-confirmed');
          final hasSupabaseAuthCode = currentUrl.queryParameters.containsKey('code') ||
                                    currentUrl.fragment.contains('access_token=') ||
                                    currentUrl.fragment.contains('refresh_token=');
          
          print('🔍 SIGNIN EVENT DEBUG:');
          print('  Recovery mode: ${authProvider.isInPasswordRecoveryMode}');
          print('  Has reset fragment: $hasResetPasswordFragment');
          print('  Has email confirmation fragment: $hasEmailConfirmationFragment');
          print('  Has auth code: $hasSupabaseAuthCode');
          print('  URL: ${currentUrl.toString()}');
          
          // If URL has email confirmation fragment, allow normal sign-in flow
          if (hasEmailConfirmationFragment && hasSupabaseAuthCode) {
            ErrorLogger.logInfo(
              '✅ ALLOWED: Sign-in from email confirmation URL - proceeding with normal flow',
              context: 'AUTH_EMAIL_CONFIRMATION_SIGNIN_ALLOWED',
              additionalData: {
                'url': currentUrl.toString(),
                'fragment': currentUrl.fragment,
                'query_params': currentUrl.queryParameters.toString(),
              },
            );
            // Continue with normal sign-in flow - don't return here
          }
          // If URL has both reset-password and auth tokens, this is definitely a password reset
          else if (hasResetPasswordFragment && hasSupabaseAuthCode) {
            authProvider.handlePasswordRecoveryMode();
            ErrorLogger.logInfo(
              '🚫 BLOCKED: Sign-in from password reset URL detected - blocking redirect',
              context: 'AUTH_PASSWORD_RESET_SIGNIN_BLOCKED',
              additionalData: {
                'url': currentUrl.toString(),
                'fragment': currentUrl.fragment,
                'query_params': currentUrl.queryParameters.toString(),
              },
            );
            
            // DON'T navigate anywhere - let the reset password screen handle the success
            return;
          }
          
          // FOURTH: Check if we're currently on the reset password screen
          final navigator = NavigationService.navigator;
          if (navigator != null && navigator.mounted) {
            final currentContext = navigator.context;
            final currentRoute = ModalRoute.of(currentContext)?.settings.name;
            if (currentRoute == '/reset-password') {
              // If we're on reset screen, assume it's password reset
              authProvider.handlePasswordRecoveryMode();
              ErrorLogger.logInfo(
                'Sign-in on reset password screen - setting recovery mode',
                context: 'AUTH_RESET_SCREEN_SIGNIN',
              );
              // DON'T navigate anywhere - let the reset password screen handle the success
              return;
            }
          }
          
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

          // Check email confirmation BEFORE profile check
          // For new signups, always check email confirmation first
          try {
            final authRepository = AuthRepository();
            final hasValidConfirmation = await authRepository.isEmailConfirmed(user.id);
            
            if (!hasValidConfirmation) {
              // Email is not confirmed - redirect to email confirmation waiting screen
              final navigator = NavigationService.navigator;
              if (navigator != null && navigator.mounted) {
                navigator.pushReplacementNamed(
                  '/email-confirmation-waiting', 
                  arguments: {
                    'email': user.email ?? '',
                    'userId': user.id,
                  }
                );
              }
              return; // Stop execution here
            } else {
              // Update Supabase user's email confirmation status if needed
              if (user.emailConfirmedAt == null) {
                try {
                  await authRepository.updateSupabaseEmailConfirmation(user.id);
                } catch (e) {
                  print('Failed to update Supabase email confirmation status: $e');
                  // Continue anyway if this fails
                }
              }
            }
          } catch (e) {
            print('Failed to check email confirmation status: $e');
            // In case of error, redirect to waiting screen to be safe
            final navigator = NavigationService.navigator;
            if (navigator != null && navigator.mounted) {
              navigator.pushReplacementNamed(
                '/email-confirmation-waiting',
                arguments: {
                  'email': user.email ?? '',
                  'userId': user.id,
                }
              );
            }
            return;
          }

          await userProfileController.getUserProfile();
          final profile = userProfileController.userProfile;
          // Use the global navigator key to avoid context issues
          final profileNavigator = NavigationService.navigator;
          if (profileNavigator != null && profileNavigator.mounted) {
            if (profile != null && !profile.profileCompleted) {
              profileNavigator.pushReplacementNamed('/complete-profile');
            } else {
              profileNavigator.pushReplacementNamed('/home');
            }
          }
        } else if (event == AuthChangeEvent.passwordRecovery) {
          // Handle password recovery event - ensure proper state management
          final authProvider = context.read<AuthStateProvider>();
          authProvider.handlePasswordRecoveryMode();
          
          ErrorLogger.logInfo(
            'Password recovery event detected',
            context: 'AUTH_PASSWORD_RECOVERY',
          );
          
          // Navigate to reset password screen when password recovery is detected
          final navigator = NavigationService.navigator;
          if (navigator != null && navigator.mounted) {
            navigator.pushNamedAndRemoveUntil(
              '/reset-password',
              (route) => false,
            );
          }
          
          // IMPORTANT: Return early to prevent automatic sign-in during password recovery
          return;
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
          
          // Initialize guest context for the auth provider
          final authProvider = context.read<AuthStateProvider>();
          authProvider.clearGuestContext();
          authProvider.initializeGuestContext();
          
          if (mounted) {
            // Clear any pending intended destinations on sign out
            authProvider.getAndClearIntendedDestination();
            
            // Instead of redirecting to signin, redirect to home as guest
            // This provides a better UX for users who sign out
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            });
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', ''),
      ],
      locale: const Locale('pt', ''),
      initialRoute: _getInitialRoute(),
      onGenerateRoute: _generateRoute,
      routes: {
        '/': (context) => const SplashScreen(),
        '/test-svg': (context) => const TestSvgScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/email-confirmation-waiting': (context) => const EmailConfirmationWaitingScreen(email: 'placeholder@email.com'),

        '/deep-link-test': (context) => const DeepLinkTestScreen(),
        '/home': (context) => _buildHomeRoute(context),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/profile': (context) => _buildRouteForGuests(context, '/profile', 3),
        '/notifications': (context) => _buildRouteForGuests(context, '/notifications', 2),
        '/notification-preferences': (context) => _requiresAuthentication(context, const NotificationPreferencesScreen()),
        '/map': (context) => _buildRouteForGuests(context, '/map', 1),
        '/announcements': (context) => _buildRouteForGuests(context, '/announcements', 0),
        '/create-announcement': (context) => _requiresAuthentication(context, const CreateAnnouncementScreen()),
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Check if guest user is trying to access restricted routes
    final authProvider = context.read<AuthStateProvider>();
    
    // Handle email confirmation route with query parameters
    if (settings.name?.startsWith('/auth/confirm') == true) {
      final uri = Uri.parse(settings.name!);
      final code = uri.queryParameters['code'];
      return _createSlideRoute(EmailConfirmationScreen(code: code));
    }
    
    // Handle password reset route with query parameters
    if (settings.name?.startsWith('/auth/reset') == true) {
      final uri = Uri.parse(settings.name!);
      final code = uri.queryParameters['code'];
      // Store the code in URL for the reset password screen to access
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Update the URL to include the code parameter for the reset screen
        final currentUri = Uri.base;
        final newUri = currentUri.replace(
          path: '/reset-password',
          queryParameters: {
            'code': code,
            'type': 'password_reset',
          },
        );
        // Navigate to reset password screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
      });
      // Return a temporary loading screen while navigating
      return _createSlideRoute(
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    switch (settings.name) {
      case '/email-confirmation-waiting':
        // Handle email confirmation waiting screen with arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return _createSlideRoute(EmailConfirmationWaitingScreen(
            email: args['email'] ?? '',
            userId: args['userId'],
          ));
        }
        return _createSlideRoute(const EmailConfirmationWaitingScreen(email: 'unknown@email.com'));
      case '/email-confirmed':
        // Handle email confirmation - redirect to main screen after successful confirmation
        return _createSlideRoute(_buildEmailConfirmationScreen());
      case '/announcement-detail':
        final announcement = settings.arguments;
        if (announcement != null) {
          // Both guest and authenticated users can view announcement details
          // Track guest content viewing
          if (authProvider.isGuest) {
            authProvider.trackGuestContentView('announcement_detail');
          }
          return _createSlideRoute(
            AnnouncementDetailScreen(announcement: announcement as dynamic),
          );
        }
        return null;
      case '/contract-details':
        final contractData = settings.arguments as Map<String, dynamic>?;
        if (contractData != null) {
          // Contract details require authentication
          if (authProvider.isGuest) {
            // Store intended destination for post-registration redirect
            authProvider.setIntendedDestination('/contract-details', contractData);
            return _createSlideRoute(_buildGuestRedirectScreen('/signup', 
              intendedDestination: '/contract-details',
              destinationArguments: contractData));
          }
          return _createSlideRoute(
            _buildContractDetailsScreen(contractData),
          );
        }
        return null;
      case '/notification-deep-link':
        final notificationData = settings.arguments as Map<String, dynamic>?;
        if (notificationData != null) {
          // Notification deep links require authentication
          if (authProvider.isGuest) {
            // Store intended destination for post-registration redirect
            authProvider.setIntendedDestination('/notification-deep-link', notificationData);
            return _createSlideRoute(_buildGuestRedirectScreen('/signup',
              intendedDestination: '/notification-deep-link',
              destinationArguments: notificationData));
          }
          return _handleNotificationDeepLink(notificationData);
        }
        return null;
      default:
        // Handle unknown routes for guest users
        if (authProvider.isGuest) {
          // Check if the route is guest-accessible
          if (authProvider.isRouteAccessibleToGuests(settings.name ?? '')) {
            // Track guest navigation to allowed routes
            authProvider.trackGuestContentView('route_${settings.name}');
            return null; // Let the default route handling take over
          } else {
            // Store intended destination and redirect to signup for restricted routes
            if (settings.name != null) {
              authProvider.setIntendedDestination(settings.name!, settings.arguments);
            }
            return _createSlideRoute(_buildGuestRedirectScreen('/signup',
              intendedDestination: settings.name,
              destinationArguments: settings.arguments));
          }
        }
        return null;
    }
  }

  Widget _buildGuestRedirectScreen(String targetRoute, {
    String? intendedDestination,
    dynamic destinationArguments,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 80,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Acesso Restrito',
                  style: AppTheme.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getContextualMessage(intendedDestination),
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Store intended destination for post-registration redirect
                      if (intendedDestination != null) {
                        final authProvider = context.read<AuthStateProvider>();
                        authProvider.setIntendedDestination(
                          intendedDestination, 
                          destinationArguments
                        );
                      }
                      
                      // Navigate to signup with proper route handling
                      if (targetRoute == '/signup') {
                        Navigator.of(context).pushReplacementNamed('/signup');
                      } else {
                        Navigator.of(context).pushReplacementNamed(targetRoute);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Criar Conta',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      // Clear any stored intended destination
                      final authProvider = context.read<AuthStateProvider>();
                      authProvider.getAndClearIntendedDestination();
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      'Voltar ao Início',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getContextualMessage(String? intendedDestination) {
    switch (intendedDestination) {
      case '/contract-details':
        return 'Para visualizar detalhes de contratos e gerir as suas reservas, precisa de criar uma conta.';
      case '/notification-deep-link':
        return 'Para aceder a notificações e manter-se actualizado, precisa de criar uma conta.';
      case '/create-announcement':
        return 'Para criar anúncios e organizar partidas, precisa de criar uma conta.';
      case '/notification-preferences':
        return 'Para gerir as suas preferências de notificação, precisa de criar uma conta.';
      default:
        return 'Esta funcionalidade requer uma conta.\nCrie a sua conta para continuar e aproveitar todos os recursos.';
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
                  'Ecrã de detalhes do contrato será implementado em breve.',
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

  /// Build email confirmation screen with auto-redirect
  Widget _buildEmailConfirmationScreen() {
    return _EmailConfirmationScreen();
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

class TestSvgScreen extends StatefulWidget {
  const TestSvgScreen({super.key});

  @override
  State<TestSvgScreen> createState() => _TestSvgScreenState();
}

class _TestSvgScreenState extends State<TestSvgScreen> {
  String? _svgContent;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    try {
      final svgString = await DefaultAssetBundle.of(context).loadString('assets/auth-header.svg');
      setState(() {
        _svgContent = svgString;
        _loading = false;
      });
      print('SVG loaded successfully, length: ${svgString.length}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      print('Error loading SVG: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SVG Loading Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loading Status:', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (_loading) 
              const CircularProgressIndicator()
            else if (_error != null) 
              Text('Error: $_error', style: const TextStyle(color: Colors.red))
            else if (_svgContent != null) ...[
              const Text('✅ SVG loaded successfully!', style: TextStyle(color: Colors.green)),
              const SizedBox(height: 16),
              const Text('Testing different loading methods:'),
              const SizedBox(height: 16),
              
              // Method 1: SvgPicture.asset
              const Text('Method 1: SvgPicture.asset'),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all()),
                child: SvgPicture.asset(
                  'assets/auth-header.svg',
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Method 2: SvgPicture.string
              const Text('Method 2: SvgPicture.string'),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all()),
                child: SvgPicture.string(
                  _svgContent!,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
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
                'A carregar...',
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

class _EmailConfirmationScreen extends StatefulWidget {
  @override
  _EmailConfirmationScreenState createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<_EmailConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect to main screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  'Email Confirmado!',
                  style: AppTheme.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'A sua conta foi ativada com sucesso.\nA redirecionar para a aplicação...',
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/main',
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Continuar agora',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.accentColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

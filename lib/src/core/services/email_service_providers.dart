import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'azure_email_service.dart';
import 'auth_code_service.dart';
import 'service_locator.dart';
import '../models/email_response.dart';
import '../../features/auth/data/models/auth_code.dart';
import '../exceptions/email_service_exception.dart';
import 'email_logger.dart';

/// Provider wrapper for Azure Email Service
/// 
/// This class wraps the AzureEmailService to integrate with Flutter's
/// Provider pattern for dependency injection and state management.
class AzureEmailServiceProvider extends ChangeNotifier {
  AzureEmailService? _emailService;
  
  // State tracking
  bool _isInitialized = false;
  bool _isSending = false;
  String? _lastError;
  
  AzureEmailServiceProvider({AzureEmailService? emailService})
      : _emailService = emailService;

  /// Whether the service is currently initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether an email is currently being sent
  bool get isSending => _isSending;
  
  /// The last error that occurred, if any
  String? get lastError => _lastError;

  /// Initializes the email service provider
  Future<void> initialize() async {
    try {
      _clearError();
      
      // Initialize the email service if not provided
      if (_emailService == null) {
        if (!ServiceLocator.instance.isInitialized) {
          throw EmailServiceException(
            'ServiceLocator not initialized. Call ServiceLocator.instance.initialize() first.',
            EmailServiceErrorType.configurationError,
          );
        }
        _emailService = ServiceLocator.instance.azureEmailService;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      EmailLogger.info('AzureEmailServiceProvider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize email service: $e');
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sends a confirmation email
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
    String authCode,
  ) async {
    return await _executeEmailOperation(
      'sendConfirmationEmail',
      () => _emailService!.sendConfirmationEmail(email, userId, authCode),
    );
  }

  /// Sends a password reset email
  Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
    String authCode,
  ) async {
    return await _executeEmailOperation(
      'sendPasswordResetEmail',
      () => _emailService!.sendPasswordResetEmail(email, userId, authCode),
    );
  }

  /// Executes an email operation with proper state management
  Future<EmailResponse> _executeEmailOperation(
    String operationName,
    Future<EmailResponse> Function() operation,
  ) async {
    if (!_isInitialized) {
      throw EmailServiceException(
        'Email service not initialized',
        EmailServiceErrorType.configurationError,
      );
    }

    _setSending(true);
    _clearError();

    try {
      if (_emailService == null) {
        throw EmailServiceException(
          'Email service not available',
          EmailServiceErrorType.configurationError,
        );
      }
      
      final result = await operation();
      
      EmailLogger.info(
        '$operationName completed successfully',
        context: {'messageId': result.messageId},
      );
      
      return result;
    } catch (e) {
      final errorMessage = e is EmailServiceException 
          ? e.message 
          : 'Unexpected error: $e';
      
      _setError(errorMessage);
      
      EmailLogger.error(
        '$operationName failed',
        error: e,
      );
      
      rethrow;
    } finally {
      _setSending(false);
    }
  }

  /// Sets the sending state and notifies listeners
  void _setSending(bool sending) {
    if (_isSending != sending) {
      _isSending = sending;
      notifyListeners();
    }
  }

  /// Sets an error message and notifies listeners
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  /// Clears the last error
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _emailService?.dispose();
    super.dispose();
  }
}

/// Provider wrapper for Authentication Code Service
/// 
/// This class wraps the AuthCodeService to integrate with Flutter's
/// Provider pattern for dependency injection and state management.
class AuthCodeServiceProvider extends ChangeNotifier {
  AuthCodeService? _authCodeService;
  
  // State tracking
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _lastError;
  
  AuthCodeServiceProvider({AuthCodeService? authCodeService})
      : _authCodeService = authCodeService;

  /// Whether the service is currently initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether a code operation is currently being processed
  bool get isProcessing => _isProcessing;
  
  /// The last error that occurred, if any
  String? get lastError => _lastError;

  /// Initializes the auth code service provider
  Future<void> initialize() async {
    try {
      _clearError();
      
      // Initialize the auth code service if not provided
      if (_authCodeService == null) {
        if (!ServiceLocator.instance.isInitialized) {
          throw EmailServiceException(
            'ServiceLocator not initialized. Call ServiceLocator.instance.initialize() first.',
            EmailServiceErrorType.configurationError,
          );
        }
        _authCodeService = ServiceLocator.instance.authCodeService;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      EmailLogger.info('AuthCodeServiceProvider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize auth code service: $e');
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Generates a new authentication code
  Future<String> generateAuthCode(
    String userId,
    AuthCodeType type, {
    Duration? expirationDuration,
  }) async {
    return await _executeCodeOperation(
      'generateAuthCode',
      () => _authCodeService!.generateAuthCode(
        userId,
        type,
        expirationDuration: expirationDuration,
      ),
    );
  }

  /// Validates an authentication code
  Future<AuthCode?> validateAuthCode(String plainCode, AuthCodeType type) async {
    return await _executeCodeOperation(
      'validateAuthCode',
      () => _authCodeService!.validateAuthCode(plainCode, type),
    );
  }

  /// Validates and consumes an authentication code
  Future<AuthCode?> validateAndConsumeAuthCode(String plainCode, AuthCodeType type) async {
    return await _executeCodeOperation(
      'validateAndConsumeAuthCode',
      () => _authCodeService!.validateAndConsumeAuthCode(plainCode, type),
    );
  }

  /// Invalidates all codes for a user and type
  Future<void> invalidateUserCodes(String userId, AuthCodeType type) async {
    await _executeCodeOperation(
      'invalidateUserCodes',
      () => _authCodeService!.invalidateUserCodes(userId, type),
    );
  }

  /// Cleans up expired codes
  Future<int> cleanupExpiredCodes() async {
    return await _executeCodeOperation(
      'cleanupExpiredCodes',
      () => _authCodeService!.cleanupExpiredCodes(),
    );
  }

  /// Executes a code operation with proper state management
  Future<T> _executeCodeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!_isInitialized) {
      throw EmailServiceException(
        'Auth code service not initialized',
        EmailServiceErrorType.configurationError,
      );
    }

    _setProcessing(true);
    _clearError();

    try {
      if (_authCodeService == null) {
        throw EmailServiceException(
          'Auth code service not available',
          EmailServiceErrorType.configurationError,
        );
      }
      
      final result = await operation();
      
      EmailLogger.info(
        '$operationName completed successfully',
      );
      
      return result;
    } catch (e) {
      final errorMessage = e.toString();
      _setError(errorMessage);
      
      EmailLogger.error(
        '$operationName failed',
        error: e,
      );
      
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  /// Sets the processing state and notifies listeners
  void _setProcessing(bool processing) {
    if (_isProcessing != processing) {
      _isProcessing = processing;
      notifyListeners();
    }
  }

  /// Sets an error message and notifies listeners
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  /// Clears the last error
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }
}

/// Combined email service provider that manages both email sending and auth codes
/// 
/// This provider combines both Azure email service and auth code service
/// functionality into a single provider for easier integration.
class EmailServiceManager extends ChangeNotifier {
  final AzureEmailServiceProvider _emailProvider;
  final AuthCodeServiceProvider _authCodeProvider;
  
  EmailServiceManager({
    AzureEmailServiceProvider? emailProvider,
    AuthCodeServiceProvider? authCodeProvider,
  }) : _emailProvider = emailProvider ?? AzureEmailServiceProvider(),
       _authCodeProvider = authCodeProvider ?? AuthCodeServiceProvider();

  /// Gets the email service provider
  AzureEmailServiceProvider get emailService => _emailProvider;
  
  /// Gets the auth code service provider
  AuthCodeServiceProvider get authCodeService => _authCodeProvider;

  /// Whether both services are initialized
  bool get isInitialized => _emailProvider.isInitialized && _authCodeProvider.isInitialized;
  
  /// Whether any operation is currently in progress
  bool get isBusy => _emailProvider.isSending || _authCodeProvider.isProcessing;
  
  /// Gets the last error from either service
  String? get lastError => _emailProvider.lastError ?? _authCodeProvider.lastError;

  /// Initializes both services
  Future<void> initialize() async {
    await Future.wait([
      _emailProvider.initialize(),
      _authCodeProvider.initialize(),
    ]);
    
    // Listen to changes from both providers
    _emailProvider.addListener(_onProviderChanged);
    _authCodeProvider.addListener(_onProviderChanged);
    
    notifyListeners();
  }

  /// Sends a confirmation email with code generation
  Future<EmailResponse> sendConfirmationEmailWithCode(
    String email,
    String userId,
  ) async {
    // Generate auth code
    final authCode = await _authCodeProvider.generateAuthCode(
      userId,
      AuthCodeType.emailConfirmation,
    );
    
    // Send email with the generated code
    return await _emailProvider.sendConfirmationEmail(email, userId, authCode);
  }

  /// Sends a password reset email with code generation
  Future<EmailResponse> sendPasswordResetEmailWithCode(
    String email,
    String userId,
  ) async {
    // Generate auth code
    final authCode = await _authCodeProvider.generateAuthCode(
      userId,
      AuthCodeType.passwordReset,
    );
    
    // Send email with the generated code
    return await _emailProvider.sendPasswordResetEmail(email, userId, authCode);
  }

  /// Handles changes from child providers
  void _onProviderChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _emailProvider.removeListener(_onProviderChanged);
    _authCodeProvider.removeListener(_onProviderChanged);
    _emailProvider.dispose();
    _authCodeProvider.dispose();
    super.dispose();
  }
}

/// Helper class for creating email service providers
class EmailServiceProviders {
  /// Creates a list of providers for the email services
  static List<ChangeNotifierProvider> createProviders() {
    return [
      ChangeNotifierProvider<AzureEmailServiceProvider>(
        create: (_) => AzureEmailServiceProvider(),
      ),
      ChangeNotifierProvider<AuthCodeServiceProvider>(
        create: (_) => AuthCodeServiceProvider(),
      ),
      ChangeNotifierProvider<EmailServiceManager>(
        create: (_) => EmailServiceManager(),
      ),
    ];
  }

  /// Creates providers with custom instances (useful for testing)
  static List<ChangeNotifierProvider> createProvidersWithInstances({
    AzureEmailServiceProvider? emailProvider,
    AuthCodeServiceProvider? authCodeProvider,
    EmailServiceManager? emailManager,
  }) {
    return [
      ChangeNotifierProvider<AzureEmailServiceProvider>.value(
        value: emailProvider ?? AzureEmailServiceProvider(),
      ),
      ChangeNotifierProvider<AuthCodeServiceProvider>.value(
        value: authCodeProvider ?? AuthCodeServiceProvider(),
      ),
      ChangeNotifierProvider<EmailServiceManager>.value(
        value: emailManager ?? EmailServiceManager(),
      ),
    ];
  }
}
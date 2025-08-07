import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'http_email_service.dart';
import 'http_auth_code_service.dart';
import 'http_service_locator.dart';
import '../models/email_response.dart';
import '../../features/auth/data/models/auth_code.dart';
import '../exceptions/email_service_exception.dart';
import 'email_logger.dart';

/// Provider wrapper for HTTP Email Service
/// 
/// This class wraps the HttpEmailService to integrate with Flutter's
/// Provider pattern for dependency injection and state management.
/// It communicates with the Python backend instead of directly with Azure.
class HttpEmailServiceProvider extends ChangeNotifier {
  HttpEmailService? _httpEmailService;
  
  // State tracking
  bool _isInitialized = false;
  bool _isSending = false;
  String? _lastError;
  
  HttpEmailServiceProvider({HttpEmailService? httpEmailService})
      : _httpEmailService = httpEmailService;

  /// Whether the service is currently initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether an email is currently being sent
  bool get isSending => _isSending;
  
  /// The last error that occurred, if any
  String? get lastError => _lastError;

  /// Initializes the HTTP email service provider
  Future<void> initialize() async {
    try {
      _clearError();
      
      // Initialize the HTTP email service if not provided
      if (_httpEmailService == null) {
        if (!HttpServiceLocator.instance.isInitialized) {
          throw EmailServiceException(
            'HttpServiceLocator not initialized. Call HttpServiceLocator.instance.initialize() first.',
            EmailServiceErrorType.configurationError,
          );
        }
        _httpEmailService = HttpServiceLocator.instance.httpEmailService;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      EmailLogger.info('HttpEmailServiceProvider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize HTTP email service: $e');
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sends a confirmation email via the Python backend
  /// 
  /// This method delegates to the Python backend which handles:
  /// - Authentication code generation
  /// - Email template processing  
  /// - Azure Communication Services integration
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
  ) async {
    return await _executeEmailOperation(
      'sendConfirmationEmail',
      () => _httpEmailService!.sendConfirmationEmail(email, userId),
    );
  }

  /// Sends a password reset email via the Python backend
  /// 
  /// This method delegates to the Python backend which handles:
  /// - Authentication code generation
  /// - Email template processing  
  /// - Azure Communication Services integration
  Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
  ) async {
    return await _executeEmailOperation(
      'sendPasswordResetEmail',
      () => _httpEmailService!.sendPasswordResetEmail(email, userId),
    );
  }

  /// Executes an email operation with proper state management
  Future<EmailResponse> _executeEmailOperation(
    String operationName,
    Future<EmailResponse> Function() operation,
  ) async {
    if (!_isInitialized) {
      throw EmailServiceException(
        'HTTP email service not initialized',
        EmailServiceErrorType.configurationError,
      );
    }

    _setSending(true);
    _clearError();

    try {
      if (_httpEmailService == null) {
        throw EmailServiceException(
          'HTTP email service not available',
          EmailServiceErrorType.configurationError,
        );
      }
      
      final result = await operation();
      
      EmailLogger.info(
        '$operationName completed successfully via Python backend',
        context: {'messageId': result.messageId},
      );
      
      return result;
    } catch (e) {
      final errorMessage = e is EmailServiceException 
          ? e.message 
          : 'Unexpected error: $e';
      
      _setError(errorMessage);
      
      EmailLogger.error(
        '$operationName failed via Python backend',
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
    _httpEmailService?.dispose();
    super.dispose();
  }
}

/// Provider wrapper for HTTP Authentication Code Service
/// 
/// This class wraps the HttpAuthCodeService to integrate with Flutter's
/// Provider pattern for dependency injection and state management.
/// It communicates with the Python backend for code validation.
class HttpAuthCodeServiceProvider extends ChangeNotifier {
  HttpAuthCodeService? _httpAuthCodeService;
  
  // State tracking
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _lastError;
  
  HttpAuthCodeServiceProvider({HttpAuthCodeService? httpAuthCodeService})
      : _httpAuthCodeService = httpAuthCodeService;

  /// Whether the service is currently initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether a code operation is currently being processed
  bool get isProcessing => _isProcessing;
  
  /// The last error that occurred, if any
  String? get lastError => _lastError;

  /// Initializes the HTTP auth code service provider
  Future<void> initialize() async {
    try {
      _clearError();
      
      // Initialize the HTTP auth code service if not provided
      if (_httpAuthCodeService == null) {
        if (!HttpServiceLocator.instance.isInitialized) {
          throw EmailServiceException(
            'HttpServiceLocator not initialized. Call HttpServiceLocator.instance.initialize() first.',
            EmailServiceErrorType.configurationError,
          );
        }
        _httpAuthCodeService = HttpServiceLocator.instance.httpAuthCodeService;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      EmailLogger.info('HttpAuthCodeServiceProvider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize HTTP auth code service: $e');
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Validates an authentication code via the Python backend
  Future<AuthCode?> validateAuthCode(String plainCode, AuthCodeType type) async {
    return await _executeCodeOperation(
      'validateAuthCode',
      () => _httpAuthCodeService!.validateAuthCode(plainCode, type),
    );
  }

  /// Validates and consumes an authentication code via the Python backend
  Future<AuthCode?> validateAndConsumeAuthCode(String plainCode, AuthCodeType type) async {
    return await _executeCodeOperation(
      'validateAndConsumeAuthCode',
      () => _httpAuthCodeService!.validateAndConsumeAuthCode(plainCode, type),
    );
  }

  /// Checks if a plain text code is valid (via Python backend)
  Future<bool> isCodeValid(String plainCode, AuthCodeType type) async {
    return await _executeCodeOperation(
      'isCodeValid',
      () => _httpAuthCodeService!.isCodeValid(plainCode, type),
    );
  }

  /// Executes a code operation with proper state management
  Future<T> _executeCodeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!_isInitialized) {
      throw EmailServiceException(
        'HTTP auth code service not initialized',
        EmailServiceErrorType.configurationError,
      );
    }

    _setProcessing(true);
    _clearError();

    try {
      if (_httpAuthCodeService == null) {
        throw EmailServiceException(
          'HTTP auth code service not available',
          EmailServiceErrorType.configurationError,
        );
      }
      
      final result = await operation();
      
      EmailLogger.info(
        '$operationName completed successfully via Python backend',
      );
      
      return result;
    } catch (e) {
      final errorMessage = e.toString();
      _setError(errorMessage);
      
      EmailLogger.error(
        '$operationName failed via Python backend',
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

  @override
  void dispose() {
    _httpAuthCodeService?.dispose();
    super.dispose();
  }
}

/// Combined HTTP email service provider that manages both email sending and auth codes
/// 
/// This provider combines both HTTP email service and HTTP auth code service
/// functionality into a single provider for easier integration.
/// All operations are performed via the Python backend.
class HttpEmailServiceManager extends ChangeNotifier {
  final HttpEmailServiceProvider _emailProvider;
  final HttpAuthCodeServiceProvider _authCodeProvider;
  
  HttpEmailServiceManager({
    HttpEmailServiceProvider? emailProvider,
    HttpAuthCodeServiceProvider? authCodeProvider,
  }) : _emailProvider = emailProvider ?? HttpEmailServiceProvider(),
       _authCodeProvider = authCodeProvider ?? HttpAuthCodeServiceProvider();

  /// Gets the HTTP email service provider
  HttpEmailServiceProvider get emailService => _emailProvider;
  
  /// Gets the HTTP auth code service provider
  HttpAuthCodeServiceProvider get authCodeService => _authCodeProvider;

  /// Whether both services are initialized
  bool get isInitialized => _emailProvider.isInitialized && _authCodeProvider.isInitialized;
  
  /// Whether any operation is currently in progress
  bool get isBusy => _emailProvider.isSending || _authCodeProvider.isProcessing;
  
  /// Gets the last error from either service
  String? get lastError => _emailProvider.lastError ?? _authCodeProvider.lastError;

  /// Initializes both HTTP services
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

  /// Sends a confirmation email (code generation handled by Python backend)
  /// 
  /// This is a simplified interface - the Python backend handles all the
  /// complex orchestration of code generation and email composition.
  Future<EmailResponse> sendConfirmationEmailWithCode(
    String email,
    String userId,
  ) async {
    EmailLogger.info(
      'Sending confirmation email via Python backend',
      context: {
        'email': email,
        'userId': userId,
        'backendHandles': ['codeGeneration', 'templateProcessing', 'azureIntegration'],
      },
    );
    
    return await _emailProvider.sendConfirmationEmail(email, userId);
  }

  /// Sends a password reset email (code generation handled by Python backend)
  /// 
  /// This is a simplified interface - the Python backend handles all the
  /// complex orchestration of code generation and email composition.
  Future<EmailResponse> sendPasswordResetEmailWithCode(
    String email,
    String userId,
  ) async {
    EmailLogger.info(
      'Sending password reset email via Python backend',
      context: {
        'email': email,
        'userId': userId,
        'backendHandles': ['codeGeneration', 'templateProcessing', 'azureIntegration'],
      },
    );
    
    return await _emailProvider.sendPasswordResetEmail(email, userId);
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

/// Helper class for creating HTTP email service providers
class HttpEmailServiceProviders {
  /// Creates a list of providers for the HTTP email services
  static List<ChangeNotifierProvider> createProviders() {
    return [
      ChangeNotifierProvider<HttpEmailServiceProvider>(
        create: (_) => HttpEmailServiceProvider(),
      ),
      ChangeNotifierProvider<HttpAuthCodeServiceProvider>(
        create: (_) => HttpAuthCodeServiceProvider(),
      ),
      ChangeNotifierProvider<HttpEmailServiceManager>(
        create: (_) => HttpEmailServiceManager(),
      ),
    ];
  }

  /// Creates providers with custom instances (useful for testing)
  static List<ChangeNotifierProvider> createProvidersWithInstances({
    HttpEmailServiceProvider? emailProvider,
    HttpAuthCodeServiceProvider? authCodeProvider,
    HttpEmailServiceManager? emailManager,
  }) {
    return [
      ChangeNotifierProvider<HttpEmailServiceProvider>.value(
        value: emailProvider ?? HttpEmailServiceProvider(),
      ),
      ChangeNotifierProvider<HttpAuthCodeServiceProvider>.value(
        value: authCodeProvider ?? HttpAuthCodeServiceProvider(),
      ),
      ChangeNotifierProvider<HttpEmailServiceManager>.value(
        value: emailManager ?? HttpEmailServiceManager(),
      ),
    ];
  }
}

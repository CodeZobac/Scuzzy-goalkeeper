import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'azure_email_service.dart';
import 'auth_code_service.dart';
import 'email_template_manager.dart';
import 'secure_code_generator.dart';
import '../../features/auth/data/repositories/auth_code_repository.dart';
import '../config/azure_config.dart';

/// Service locator for managing Azure email service dependencies
/// 
/// This class provides a centralized way to register and retrieve
/// service instances with proper lifecycle management and singleton patterns.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  ServiceLocator._internal();

  // Service instances
  AzureEmailService? _azureEmailService;
  AuthCodeService? _authCodeService;
  AuthCodeRepository? _authCodeRepository;
  SecureCodeGenerator? _secureCodeGenerator;
  http.Client? _httpClient;

  /// Initializes all services with proper configuration
  /// 
  /// This method should be called during app startup to ensure
  /// all services are properly configured and ready for use.
  Future<void> initialize() async {
    try {
      // Validate Azure configuration first
      AzureConfig.validateConfiguration();
      
      // Initialize core dependencies
      _httpClient = http.Client();
      _secureCodeGenerator = SecureCodeGenerator();
      
      // Initialize repository with Supabase client
      _authCodeRepository = AuthCodeRepository(
        supabase: Supabase.instance.client,
        codeGenerator: _secureCodeGenerator!,
      );
      
      // Initialize auth code service
      _authCodeService = AuthCodeService(
        repository: _authCodeRepository!,
        codeGenerator: _secureCodeGenerator!,
      );
      
      // Initialize Azure email service
      _azureEmailService = AzureEmailService(
        httpClient: _httpClient!,
      );
      
    } catch (e) {
      throw ServiceLocatorException(
        'Failed to initialize services: $e',
        ServiceLocatorErrorType.initializationError,
        e,
      );
    }
  }

  /// Gets the Azure email service instance
  /// 
  /// Throws [ServiceLocatorException] if services haven't been initialized
  AzureEmailService get azureEmailService {
    if (_azureEmailService == null) {
      throw ServiceLocatorException(
        'AzureEmailService not initialized. Call ServiceLocator.instance.initialize() first.',
        ServiceLocatorErrorType.notInitialized,
      );
    }
    return _azureEmailService!;
  }

  /// Gets the authentication code service instance
  /// 
  /// Throws [ServiceLocatorException] if services haven't been initialized
  AuthCodeService get authCodeService {
    if (_authCodeService == null) {
      throw ServiceLocatorException(
        'AuthCodeService not initialized. Call ServiceLocator.instance.initialize() first.',
        ServiceLocatorErrorType.notInitialized,
      );
    }
    return _authCodeService!;
  }

  /// Gets the authentication code repository instance
  /// 
  /// Throws [ServiceLocatorException] if services haven't been initialized
  AuthCodeRepository get authCodeRepository {
    if (_authCodeRepository == null) {
      throw ServiceLocatorException(
        'AuthCodeRepository not initialized. Call ServiceLocator.instance.initialize() first.',
        ServiceLocatorErrorType.notInitialized,
      );
    }
    return _authCodeRepository!;
  }

  /// Gets the secure code generator instance
  /// 
  /// Throws [ServiceLocatorException] if services haven't been initialized
  SecureCodeGenerator get secureCodeGenerator {
    if (_secureCodeGenerator == null) {
      throw ServiceLocatorException(
        'SecureCodeGenerator not initialized. Call ServiceLocator.instance.initialize() first.',
        ServiceLocatorErrorType.notInitialized,
      );
    }
    return _secureCodeGenerator!;
  }

  /// Gets the HTTP client instance
  /// 
  /// Throws [ServiceLocatorException] if services haven't been initialized
  http.Client get httpClient {
    if (_httpClient == null) {
      throw ServiceLocatorException(
        'HTTP Client not initialized. Call ServiceLocator.instance.initialize() first.',
        ServiceLocatorErrorType.notInitialized,
      );
    }
    return _httpClient!;
  }

  /// Factory method for creating a new Azure email service instance
  /// 
  /// This is useful for testing or when you need a fresh instance
  /// with custom configuration.
  static AzureEmailService createAzureEmailService({
    http.Client? httpClient,
  }) {
    return AzureEmailService(
      httpClient: httpClient ?? http.Client(),
    );
  }

  /// Factory method for creating a new authentication code service instance
  /// 
  /// This is useful for testing or when you need a fresh instance
  /// with custom dependencies.
  static AuthCodeService createAuthCodeService({
    AuthCodeRepository? repository,
    SecureCodeGenerator? codeGenerator,
  }) {
    return AuthCodeService(
      repository: repository ?? AuthCodeRepository(),
      codeGenerator: codeGenerator ?? SecureCodeGenerator(),
    );
  }

  /// Factory method for creating a new authentication code repository instance
  /// 
  /// This is useful for testing or when you need a fresh instance
  /// with custom dependencies.
  static AuthCodeRepository createAuthCodeRepository({
    SupabaseClient? supabase,
    SecureCodeGenerator? codeGenerator,
  }) {
    return AuthCodeRepository(
      supabase: supabase ?? Supabase.instance.client,
      codeGenerator: codeGenerator ?? SecureCodeGenerator(),
    );
  }

  /// Checks if all services have been initialized
  bool get isInitialized {
    return _azureEmailService != null &&
           _authCodeService != null &&
           _authCodeRepository != null &&
           _secureCodeGenerator != null &&
           _httpClient != null;
  }

  /// Disposes of all services and cleans up resources
  /// 
  /// This should be called when the app is shutting down to ensure
  /// proper cleanup of resources like HTTP clients.
  void dispose() {
    _azureEmailService?.dispose();
    _httpClient?.close();
    
    // Clear all instances
    _azureEmailService = null;
    _authCodeService = null;
    _authCodeRepository = null;
    _secureCodeGenerator = null;
    _httpClient = null;
  }

  /// Resets the service locator (useful for testing)
  /// 
  /// This method disposes of current services and resets the locator
  /// to an uninitialized state.
  void reset() {
    dispose();
  }
}

/// Exception thrown by ServiceLocator operations
class ServiceLocatorException implements Exception {
  final String message;
  final ServiceLocatorErrorType type;
  final dynamic originalError;

  const ServiceLocatorException(
    this.message,
    this.type, [
    this.originalError,
  ]);

  @override
  String toString() => 'ServiceLocatorException: $message';
}

/// Types of errors that can occur in ServiceLocator
enum ServiceLocatorErrorType {
  initializationError,
  notInitialized,
  configurationError,
  dependencyError,
}
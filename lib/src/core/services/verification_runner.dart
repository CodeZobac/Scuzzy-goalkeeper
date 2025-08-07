import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'email_service_verification.dart';
import 'email_logger.dart';
import 'email_template_manager.dart';
import 'auth_code_service.dart';
import '../config/azure_config.dart';
import '../../features/auth/data/models/auth_code.dart';

/// Main runner for email service verification
/// 
/// This class orchestrates the complete verification process and provides
/// a simple interface for running all verification tests.
class VerificationRunner {
  static VerificationRunner? _instance;
  static VerificationRunner get instance => _instance ??= VerificationRunner._();
  
  VerificationRunner._();

  /// Runs the complete email service verification
  /// 
  /// This method initializes all necessary services and runs the comprehensive
  /// verification suite. It handles setup, execution, and cleanup.
  /// 
  /// Returns a [VerificationReport] with detailed results
  Future<VerificationReport> runCompleteVerification() async {
    EmailLogger.info('Starting complete email service verification');
    
    try {
      // Initialize environment if not already done
      await _initializeEnvironment();
      
      // Verify prerequisites
      await _verifyPrerequisites();
      
      // Create verification service
      final verification = EmailServiceVerification();
      
      // Run verification
      final report = await verification.runFullVerification();
      
      // Log summary
      EmailLogger.info(
        'Verification completed',
        context: {
          'totalTests': report.totalTests,
          'passedTests': report.passedTests,
          'failedTests': report.failedTests,
          'successRate': '${report.successPercentage.toStringAsFixed(1)}%',
          'overallResult': report.isSuccess ? 'SUCCESS' : 'FAILURE',
        },
      );
      
      // Print detailed report if in debug mode
      if (kDebugMode) {
        print(report.generateDetailedReport());
      }
      
      return report;
    } catch (e) {
      EmailLogger.error('Verification runner failed', error: e);
      
      // Return a failure report
      return VerificationReport(
        results: [
          VerificationResult.error(
            'Verification Runner',
            'Critical error during verification: $e',
            e,
          ),
        ],
        totalTests: 1,
        passedTests: 0,
        failedTests: 1,
        isSuccess: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Runs a quick verification of core functionality
  /// 
  /// This method runs a subset of tests to quickly verify that the email
  /// service is working correctly. Useful for health checks.
  /// 
  /// Returns a [VerificationReport] with results from core tests
  Future<VerificationReport> runQuickVerification() async {
    EmailLogger.info('Starting quick email service verification');
    
    try {
      await _initializeEnvironment();
      
      final results = <VerificationResult>[];
      
      // Quick configuration check
      results.add(await _quickConfigurationCheck());
      
      // Quick template check
      results.add(await _quickTemplateCheck());
      
      // Quick auth code check
      results.add(await _quickAuthCodeCheck());
      
      final passedTests = results.where((r) => r.isSuccess).length;
      final failedTests = results.where((r) => !r.isSuccess).length;
      
      final report = VerificationReport(
        results: results,
        totalTests: results.length,
        passedTests: passedTests,
        failedTests: failedTests,
        isSuccess: failedTests == 0,
        timestamp: DateTime.now(),
      );
      
      EmailLogger.info(
        'Quick verification completed',
        context: {
          'totalTests': report.totalTests,
          'passedTests': report.passedTests,
          'failedTests': report.failedTests,
          'overallResult': report.isSuccess ? 'SUCCESS' : 'FAILURE',
        },
      );
      
      return report;
    } catch (e) {
      EmailLogger.error('Quick verification failed', error: e);
      
      return VerificationReport(
        results: [
          VerificationResult.error(
            'Quick Verification',
            'Critical error during quick verification: $e',
            e,
          ),
        ],
        totalTests: 1,
        passedTests: 0,
        failedTests: 1,
        isSuccess: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Verifies that a specific email flow works correctly
  /// 
  /// [flowType] The type of flow to verify ('confirmation' or 'reset')
  /// [testEmail] The email address to use for testing
  /// [testUserId] The user ID to use for testing
  /// 
  /// Returns a [VerificationReport] with results from the flow test
  Future<VerificationReport> verifyEmailFlow(
    String flowType,
    String testEmail,
    String testUserId,
  ) async {
    EmailLogger.info(
      'Verifying specific email flow',
      context: {
        'flowType': flowType,
        'testEmail': testEmail,
        'testUserId': testUserId,
      },
    );
    
    try {
      await _initializeEnvironment();
      
      final verification = EmailServiceVerification();
      final results = <VerificationResult>[];
      
      switch (flowType.toLowerCase()) {
        case 'confirmation':
          results.add(await verification._testEmailConfirmationFlow());
          break;
        case 'reset':
          results.add(await verification._testPasswordResetFlow());
          break;
        default:
          results.add(VerificationResult.failure(
            'Flow Verification',
            'Unknown flow type: $flowType',
          ));
      }
      
      final passedTests = results.where((r) => r.isSuccess).length;
      final failedTests = results.where((r) => !r.isSuccess).length;
      
      final report = VerificationReport(
        results: results,
        totalTests: results.length,
        passedTests: passedTests,
        failedTests: failedTests,
        isSuccess: failedTests == 0,
        timestamp: DateTime.now(),
      );
      
      EmailLogger.info(
        'Flow verification completed',
        context: {
          'flowType': flowType,
          'overallResult': report.isSuccess ? 'SUCCESS' : 'FAILURE',
        },
      );
      
      return report;
    } catch (e) {
      EmailLogger.error('Flow verification failed', error: e);
      
      return VerificationReport(
        results: [
          VerificationResult.error(
            'Flow Verification',
            'Critical error during flow verification: $e',
            e,
          ),
        ],
        totalTests: 1,
        passedTests: 0,
        failedTests: 1,
        isSuccess: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Initializes the environment for verification
  Future<void> _initializeEnvironment() async {
    try {
      // Load environment variables if not already loaded
      if (!dotenv.isInitialized) {
        await dotenv.load();
      }
      
      // Initialize Supabase if not already initialized
      if (!Supabase.instance.isInitialized) {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
      }
      
      EmailLogger.debug('Environment initialized for verification');
    } catch (e) {
      EmailLogger.error('Failed to initialize environment', error: e);
      rethrow;
    }
  }

  /// Verifies that all prerequisites are met for verification
  Future<void> _verifyPrerequisites() async {
    final missingVars = <String>[];
    
    // Check required environment variables
    final requiredVars = [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'EMAIL_SERVICE',
      'AZURE_KEY',
    ];
    
    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value == null || value.isEmpty) {
        missingVars.add(varName);
      }
    }
    
    if (missingVars.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVars.join(', ')}',
      );
    }
    
    EmailLogger.debug('All prerequisites verified');
  }

  /// Quick configuration check
  Future<VerificationResult> _quickConfigurationCheck() async {
    try {
      AzureConfig.validateConfiguration();
      return VerificationResult.success(
        'Quick Configuration Check',
        'Azure configuration is valid',
      );
    } catch (e) {
      return VerificationResult.error(
        'Quick Configuration Check',
        'Configuration validation failed: $e',
        e,
      );
    }
  }

  /// Quick template check
  Future<VerificationResult> _quickTemplateCheck() async {
    try {
      final template = await EmailTemplateManager.loadTemplate('confirmation');
      if (template.isEmpty) {
        return VerificationResult.failure(
          'Quick Template Check',
          'Template is empty',
        );
      }
      
      return VerificationResult.success(
        'Quick Template Check',
        'Template loading works correctly',
      );
    } catch (e) {
      return VerificationResult.error(
        'Quick Template Check',
        'Template loading failed: $e',
        e,
      );
    }
  }

  /// Quick auth code check
  Future<VerificationResult> _quickAuthCodeCheck() async {
    try {
      final authCodeService = AuthCodeService();
      final code = await authCodeService.generateAuthCode(
        'test-user-quick',
        AuthCodeType.emailConfirmation,
      );
      
      if (code.length != 32) {
        return VerificationResult.failure(
          'Quick Auth Code Check',
          'Generated code has wrong length: ${code.length}',
        );
      }
      
      return VerificationResult.success(
        'Quick Auth Code Check',
        'Auth code generation works correctly',
      );
    } catch (e) {
      return VerificationResult.error(
        'Quick Auth Code Check',
        'Auth code generation failed: $e',
        e,
      );
    }
  }

  /// Prints a summary of verification results to console
  void printVerificationSummary(VerificationReport report) {
    print('\n=== EMAIL SERVICE VERIFICATION SUMMARY ===');
    print('Timestamp: ${report.timestamp.toIso8601String()}');
    print('Total Tests: ${report.totalTests}');
    print('Passed: ${report.passedTests}');
    print('Failed: ${report.failedTests}');
    print('Success Rate: ${report.successPercentage.toStringAsFixed(1)}%');
    print('Overall Result: ${report.isSuccess ? "✅ SUCCESS" : "❌ FAILURE"}');
    
    if (report.failedResults.isNotEmpty) {
      print('\n=== FAILED TESTS ===');
      for (final result in report.failedResults) {
        print('❌ ${result.testName}: ${result.message}');
      }
    }
    
    print('\n=== END SUMMARY ===\n');
  }

  /// Generates a verification report for CI/CD systems
  Map<String, dynamic> generateCIReport(VerificationReport report) {
    return {
      'timestamp': report.timestamp.toIso8601String(),
      'totalTests': report.totalTests,
      'passedTests': report.passedTests,
      'failedTests': report.failedTests,
      'successRate': report.successPercentage,
      'isSuccess': report.isSuccess,
      'summary': report.summary,
      'failedTests': report.failedResults.map((r) => {
        'testName': r.testName,
        'message': r.message,
        'isError': r.isError,
      }).toList(),
      'successfulTests': report.successfulResults.map((r) => {
        'testName': r.testName,
        'message': r.message,
      }).toList(),
    };
  }
}
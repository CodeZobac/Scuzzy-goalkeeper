import '../exceptions/email_service_exception.dart';
import '../../features/auth/data/repositories/auth_code_repository.dart';

/// Service for handling email service errors and providing user-friendly messages
class EmailErrorHandler {
  /// Converts an EmailServiceException to a user-friendly error message
  static String getUserFriendlyMessage(EmailServiceException exception) {
    switch (exception.type) {
      case EmailServiceErrorType.azureServiceError:
        return _handleAzureServiceError(exception);
      
      case EmailServiceErrorType.backendError:
        return _handleBackendError(exception);
      
      case EmailServiceErrorType.templateError:
        return 'Ocorreu um erro ao preparar o e-mail. Tente novamente em alguns minutos.';
      
      case EmailServiceErrorType.databaseError:
        return 'Erro temporário no sistema. Tente novamente em alguns minutos.';
      
      case EmailServiceErrorType.authCodeError:
        return _handleAuthCodeError(exception);
      
      case EmailServiceErrorType.configurationError:
        return 'Serviço temporariamente indisponível. Tente novamente mais tarde.';
      
      case EmailServiceErrorType.networkError:
        return 'Problema de conexão. Verifique sua internet e tente novamente.';
      
      case EmailServiceErrorType.authenticationError:
        return 'Erro de autenticação do serviço. Tente novamente mais tarde.';
      
      case EmailServiceErrorType.rateLimitError:
        return 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.';
      
      case EmailServiceErrorType.validationError:
        return 'Dados inválidos fornecidos. Verifique as informações e tente novamente.';
      
      case EmailServiceErrorType.unknownError:
        return 'Erro inesperado. Tente novamente em alguns minutos.';
    }
  }
  
  /// Converts an AuthCodeRepositoryException to a user-friendly error message
  static String getAuthCodeErrorMessage(AuthCodeRepositoryException exception) {
    switch (exception.type) {
      case AuthCodeRepositoryErrorType.databaseError:
        return 'Erro temporário no sistema. Tente novamente em alguns minutos.';
      
      case AuthCodeRepositoryErrorType.validationError:
        return 'Código de verificação inválido. Solicite um novo código.';
      
      case AuthCodeRepositoryErrorType.notFound:
        return 'Código de verificação não encontrado. Solicite um novo código.';
      
      case AuthCodeRepositoryErrorType.expired:
        return 'Código de verificação expirado. Solicite um novo código.';
      
      case AuthCodeRepositoryErrorType.alreadyUsed:
        return 'Este código já foi utilizado. Solicite um novo código.';
    }
  }
  
  /// Handles Azure service specific errors
  static String _handleAzureServiceError(EmailServiceException exception) {
    if (exception.statusCode != null) {
      switch (exception.statusCode!) {
        case 400:
          return 'Erro na solicitação de e-mail. Tente novamente.';
        case 401:
        case 403:
          return 'Erro de autorização do serviço. Tente novamente mais tarde.';
        case 429:
          return 'Muitas tentativas de envio. Aguarde alguns minutos.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Serviço de e-mail temporariamente indisponível. Tente novamente em alguns minutos.';
        default:
          return 'Erro no serviço de e-mail. Tente novamente mais tarde.';
      }
    }
    
    return 'Erro no serviço de e-mail. Tente novamente mais tarde.';
  }
  
  /// Handles Python backend specific errors
  static String _handleBackendError(EmailServiceException exception) {
    if (exception.statusCode != null) {
      switch (exception.statusCode!) {
        case 400:
          return 'Dados inválidos fornecidos. Verifique as informações e tente novamente.';
        case 401:
        case 403:
          return 'Erro de autorização do backend. Tente novamente mais tarde.';
        case 404:
          return 'Recurso não encontrado. Verifique os dados e tente novamente.';
        case 429:
          return 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Backend temporariamente indisponível. Tente novamente em alguns minutos.';
        default:
          return 'Erro no backend. Tente novamente mais tarde.';
      }
    }
    
    return 'Erro no backend. Tente novamente mais tarde.';
  }
  
  /// Handles authentication code specific errors
  static String _handleAuthCodeError(EmailServiceException exception) {
    final message = exception.message.toLowerCase();
    
    if (message.contains('expired')) {
      return 'Código de verificação expirado. Solicite um novo código.';
    } else if (message.contains('invalid') || message.contains('format')) {
      return 'Código de verificação inválido. Verifique o código e tente novamente.';
    } else if (message.contains('used')) {
      return 'Este código já foi utilizado. Solicite um novo código.';
    } else {
      return 'Erro com o código de verificação. Solicite um novo código.';
    }
  }
  
  /// Gets a user-friendly message for email sending operations
  static String getEmailSendingMessage(String emailType) {
    switch (emailType.toLowerCase()) {
      case 'confirmation':
      case 'email_confirmation':
        return 'E-mail de confirmação enviado! Verifique sua caixa de entrada.';
      
      case 'password_reset':
      case 'reset':
        return 'E-mail de recuperação enviado! Verifique sua caixa de entrada.';
      
      default:
        return 'E-mail enviado com sucesso!';
    }
  }
  
  /// Gets a user-friendly message for retry operations
  static String getRetryMessage(int attemptNumber, int maxAttempts) {
    if (attemptNumber == maxAttempts) {
      return 'Não foi possível enviar o e-mail após várias tentativas. Tente novamente mais tarde.';
    } else {
      return 'Tentando enviar novamente... (tentativa $attemptNumber de $maxAttempts)';
    }
  }
  
  /// Determines if an error is recoverable (user should retry)
  static bool isRecoverableError(EmailServiceException exception) {
    switch (exception.type) {
      case EmailServiceErrorType.networkError:
      case EmailServiceErrorType.azureServiceError:
      case EmailServiceErrorType.backendError:
      case EmailServiceErrorType.rateLimitError:
        return true;
      
      case EmailServiceErrorType.authenticationError:
      case EmailServiceErrorType.configurationError:
      case EmailServiceErrorType.templateError:
      case EmailServiceErrorType.validationError:
        return false;
      
      case EmailServiceErrorType.databaseError:
      case EmailServiceErrorType.authCodeError:
      case EmailServiceErrorType.unknownError:
        return true;
    }
  }
  
  /// Determines if an error should trigger automatic retry
  static bool shouldAutoRetry(EmailServiceException exception) {
    switch (exception.type) {
      case EmailServiceErrorType.networkError:
      case EmailServiceErrorType.azureServiceError:
      case EmailServiceErrorType.backendError:
        // Check status code for backend/Azure errors
        if (exception.statusCode != null) {
          switch (exception.statusCode!) {
            case 500:
            case 502:
            case 503:
            case 504:
              return true; // Server errors should be retried
            case 429:
              return true; // Rate limit should be retried with backoff
            case 400:
            case 401:
            case 403:
            case 404:
              return false; // Client errors should not be retried
            default:
              return false;
          }
        }
        return true;
      
      case EmailServiceErrorType.rateLimitError:
        return true;
      
      case EmailServiceErrorType.authenticationError:
      case EmailServiceErrorType.configurationError:
      case EmailServiceErrorType.templateError:
      case EmailServiceErrorType.validationError:
      case EmailServiceErrorType.authCodeError:
        return false;
      
      case EmailServiceErrorType.databaseError:
      case EmailServiceErrorType.unknownError:
        return true;
    }
  }
  
  /// Gets the appropriate retry delay based on error type and attempt number
  static Duration getRetryDelay(EmailServiceException exception, int attemptNumber) {
    const baseDelay = Duration(seconds: 1);
    
    switch (exception.type) {
      case EmailServiceErrorType.rateLimitError:
        // Longer delay for rate limiting
        return Duration(seconds: 30 * attemptNumber);
      
      case EmailServiceErrorType.azureServiceError:
      case EmailServiceErrorType.backendError:
        if (exception.statusCode == 429) {
          // Rate limit specific delay
          return Duration(seconds: 30 * attemptNumber);
        }
        // Exponential backoff for other Azure/backend errors
        return Duration(seconds: baseDelay.inSeconds * (1 << attemptNumber));
      
      case EmailServiceErrorType.networkError:
      case EmailServiceErrorType.databaseError:
      case EmailServiceErrorType.unknownError:
        // Standard exponential backoff
        return Duration(seconds: baseDelay.inSeconds * (1 << attemptNumber));
      
      default:
        return baseDelay;
    }
  }
}
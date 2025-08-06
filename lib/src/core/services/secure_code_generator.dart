import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for generating cryptographically secure authentication codes
class SecureCodeGenerator {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const int _codeLength = 32;
  
  final Random _secureRandom = Random.secure();

  /// Generates a cryptographically secure 32-character alphanumeric code
  /// 
  /// Uses dart:math.Random.secure() for cryptographically secure random generation.
  /// The code contains 32 characters from a 62-character alphabet (A-Z, a-z, 0-9),
  /// providing approximately 190 bits of entropy (log2(62^32) ≈ 190.3 bits).
  /// 
  /// Returns the plain text code that should be sent to the user.
  String generateSecureCode() {
    return List.generate(
      _codeLength, 
      (index) => _chars[_secureRandom.nextInt(_chars.length)]
    ).join();
  }

  /// Hashes a code using SHA-256 for secure database storage
  /// 
  /// The plain text code should never be stored in the database.
  /// Instead, store the hashed version returned by this method.
  /// 
  /// [code] The plain text authentication code to hash
  /// Returns the SHA-256 hash of the code as a hexadecimal string
  String hashAuthCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a plain text code against a stored hash
  /// 
  /// [plainCode] The plain text code to verify
  /// [storedHash] The SHA-256 hash stored in the database
  /// Returns true if the code matches the hash, false otherwise
  bool verifyCode(String plainCode, String storedHash) {
    final computedHash = hashAuthCode(plainCode);
    return computedHash == storedHash;
  }

  /// Generates a secure code and returns both the plain text and hashed versions
  /// 
  /// Returns a [SecureCodePair] containing:
  /// - plainCode: The code to send to the user
  /// - hashedCode: The code to store in the database
  SecureCodePair generateCodePair() {
    final plainCode = generateSecureCode();
    final hashedCode = hashAuthCode(plainCode);
    
    return SecureCodePair(
      plainCode: plainCode,
      hashedCode: hashedCode,
    );
  }
}

/// Container for a plain text code and its corresponding hash
class SecureCodePair {
  final String plainCode;
  final String hashedCode;

  const SecureCodePair({
    required this.plainCode,
    required this.hashedCode,
  });

  @override
  String toString() => 'SecureCodePair(plainCode: [REDACTED], hashedCode: $hashedCode)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SecureCodePair &&
      other.plainCode == plainCode &&
      other.hashedCode == hashedCode;
  }

  @override
  int get hashCode => plainCode.hashCode ^ hashedCode.hashCode;
}
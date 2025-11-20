import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// 🔐 خدمة تشفير كلمات المرور بأمان عالٍ
/// يستخدم PBKDF2 مع SHA256 و 100,000 iteration و salt فريد لكل مستخدم
class PasswordHasher {
  // تكوين التشفير
  static const int _saltLength = 32; // 256 bits
  static const int _iterations = 100000; // عدد كبير من التكرارات
  static const int _keyLength = 32; // 256 bits

  /// تشفير كلمة المرور (إنشاء hash جديد)
  /// يتم إنشاء salt فريد لكل مستخدم
  static String hash(String password) {
    try {
      // إنشاء salt عشوائي
      final salt = _generateSalt();

      // توليد الـ hash باستخدام PBKDF2
      final hash = _pbkdf2(password, salt);

      // تخزين: salt + hash معاً (مفصولان بـ :)
      return '${base64.encode(salt)}:${base64.encode(hash)}';
    } catch (e) {
      throw Exception('فشل في تشفير كلمة المرور: $e');
    }
  }

  /// التحقق من كلمة المرور
  /// يقارن الـ hash المخزن مع hash كلمة المرور المدخلة
  static bool verify(String password, String storedHash) {
    try {
      // فصل salt و hash
      final parts = storedHash.split(':');
      if (parts.length != 2) {
        return false; // تنسيق خاطئ
      }

      final salt = base64.decode(parts[0]);
      final originalHash = base64.decode(parts[1]);

      // إنشاء hash لكلمة المرور المدخلة بنفس الـ salt
      final testHash = _pbkdf2(password, salt);

      // مقارنة الـ hashes
      return _secureCompare(originalHash, testHash);
    } catch (e) {
      return false;
    }
  }

  /// توليد salt عشوائي
  static Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLength);
    for (var i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// PBKDF2 مع SHA-256
  static Uint8List _pbkdf2(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    derivator.init(
      Pbkdf2Parameters(salt, _iterations, _keyLength),
    );

    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// مقارنة آمنة (Constant-time comparison لمنع timing attacks)
  static bool _secureCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// فحص إذا كان الـ hash يستخدم النظام القديم (للترقية)
  static bool isLegacyHash(String hash) {
    // النظام القديم: SHA256 فقط (64 حرف hex)
    // النظام الجديد: base64:base64 (يحتوي على :)
    return !hash.contains(':');
  }

  /// ترقية hash قديم إلى جديد
  static String? upgradeLegacyHash(String oldHash, String plainPassword) {
    try {
      // التحقق من كلمة المرور بالنظام القديم
      if (_verifyLegacyPassword(plainPassword, oldHash)) {
        // إنشاء hash جديد
        return hash(plainPassword);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// التحقق بالنظام القديم (للترحيل فقط)
  static bool _verifyLegacyPassword(String password, String hash) {
    const salt = 'larapill_salt_2025';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString() == hash;
  }
}

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_secrets.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../auth/data/auth_repository.dart';

/// Deletes all cloud account data via Cloud Function (Google Play requirement).
class DataDeletionService {
  DataDeletionService({
    FirebaseAuth? auth,
    AuthRepository? authRepository,
    SecureStorageService? secureStorage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _authRepository = authRepository ?? AuthRepository(),
        _secureStorage = secureStorage ?? SecureStorageService();

  static final _baseUrl = AppSecrets.cloudFunctionsUrl;

  final FirebaseAuth _auth;
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');

    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/deleteUserAccount'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw const AccountDeletionReauthRequired();
    }
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw StateError(body?['error'] as String? ?? 'Deletion failed');
    }

    await _secureStorage.deleteAll();
    await _authRepository.signOut();
  }
}

class AccountDeletionReauthRequired implements Exception {
  const AccountDeletionReauthRequired();
}

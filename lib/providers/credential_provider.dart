import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credential.dart';

/// Credential Provider - Manages credentials storage and operations
class CredentialProvider extends ChangeNotifier {
  List<Credential> _credentials = [];
  bool _isLoaded = false;

  List<Credential> get credentials => List.unmodifiable(_credentials);
  bool get isLoaded => _isLoaded;

  static const String _storageKey = 'credentials';

  /// Load credentials from SharedPreferences
  Future<void> loadCredentials() async {
    try {
      print('[CREDENTIAL PROVIDER] Loading credentials...');
      final prefs = await SharedPreferences.getInstance();
      final String? credentialsJson = prefs.getString(_storageKey);

      if (credentialsJson != null) {
        final List<dynamic> jsonList = json.decode(credentialsJson);
        _credentials = jsonList
            .map((json) => Credential.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('[CREDENTIAL PROVIDER] SUCCESS: Loaded ${_credentials.length} credentials');
      } else {
        _credentials = [];
        print('[CREDENTIAL PROVIDER] No saved credentials found');
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e, stackTrace) {
      print('[CREDENTIAL PROVIDER] ERROR loading credentials: $e');
      print('[CREDENTIAL PROVIDER] Stack trace: $stackTrace');
      _credentials = [];
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      print('[CREDENTIAL PROVIDER] Saving ${_credentials.length} credentials...');
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          _credentials.map((credential) => credential.toJson()).toList();
      final String credentialsJson = json.encode(jsonList);
      
      await prefs.setString(_storageKey, credentialsJson);
      print('[CREDENTIAL PROVIDER] SUCCESS: Credentials saved successfully');
    } catch (e, stackTrace) {
      print('[CREDENTIAL PROVIDER] ERROR saving credentials: $e');
      print('[CREDENTIAL PROVIDER] Stack trace: $stackTrace');
      throw Exception('Failed to save credentials: $e');
    }
  }

  /// Add new credential
  Future<void> addCredential(Credential credential) async {
    try {
      print('[CREDENTIAL PROVIDER] Adding credential: ${credential.name}');
      print('[CREDENTIAL PROVIDER] ID: ${credential.id}');
      print('[CREDENTIAL PROVIDER] Type: ${credential.type.displayName}');
      
      _credentials.insert(0, credential); // Add at beginning
      await _saveCredentials();
      notifyListeners();
      
      print('[CREDENTIAL PROVIDER] SUCCESS: Credential added successfully');
    } catch (e, stackTrace) {
      print('[CREDENTIAL PROVIDER] ERROR adding credential: $e');
      print('[CREDENTIAL PROVIDER] Stack trace: $stackTrace');
      throw Exception('Failed to add credential: $e');
    }
  }

  /// Update existing credential
  Future<void> updateCredential(Credential credential) async {
    try {
      print('[CREDENTIAL PROVIDER] Updating credential: ${credential.name}');
      print('[CREDENTIAL PROVIDER] ID: ${credential.id}');
      
      final index = _credentials.indexWhere((c) => c.id == credential.id);
      
      if (index == -1) {
        print('[CREDENTIAL PROVIDER] ERROR: Credential not found with ID: ${credential.id}');
        throw Exception('Credential not found');
      }

      _credentials[index] = credential;
      await _saveCredentials();
      notifyListeners();
      
      print('[CREDENTIAL PROVIDER] SUCCESS: Credential updated successfully');
    } catch (e, stackTrace) {
      print('[CREDENTIAL PROVIDER] ERROR updating credential: $e');
      print('[CREDENTIAL PROVIDER] Stack trace: $stackTrace');
      throw Exception('Failed to update credential: $e');
    }
  }

  /// Delete credential
  Future<void> deleteCredential(String id) async {
    try {
      print('[CREDENTIAL PROVIDER] Deleting credential with ID: $id');
      
      final credential = _credentials.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Credential not found'),
      );
      
      print('[CREDENTIAL PROVIDER] Found credential: ${credential.name}');
      
      _credentials.removeWhere((c) => c.id == id);
      await _saveCredentials();
      notifyListeners();
      
      print('[CREDENTIAL PROVIDER] SUCCESS: Credential deleted successfully');
    } catch (e, stackTrace) {
      print('[CREDENTIAL PROVIDER] ERROR deleting credential: $e');
      print('[CREDENTIAL PROVIDER] Stack trace: $stackTrace');
      throw Exception('Failed to delete credential: $e');
    }
  }

  /// Get credential by ID
  Credential? getCredentialById(String id) {
    try {
      return _credentials.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get credentials by type
  List<Credential> getCredentialsByType(CredentialType type) {
    return _credentials.where((c) => c.type == type).toList();
  }

  /// Get expired credentials
  List<Credential> get expiredCredentials {
    return _credentials.where((c) => c.isExpired()).toList();
  }

  /// Search credentials
  List<Credential> searchCredentials(String query) {
    if (query.isEmpty) return credentials;

    final lowerQuery = query.toLowerCase();
    return _credentials.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) ||
          c.issuer.toLowerCase().contains(lowerQuery) ||
          (c.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (c.credentialId?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Clear all credentials (for testing or reset)
  Future<void> clearAll() async {
    try {
      print('[CREDENTIAL PROVIDER] Clearing all credentials');
      _credentials.clear();
      await _saveCredentials();
      notifyListeners();
      print('[CREDENTIAL PROVIDER] SUCCESS: All credentials cleared');
    } catch (e) {
      print('[CREDENTIAL PROVIDER] ERROR clearing credentials: $e');
      throw Exception('Failed to clear credentials: $e');
    }
  }
}
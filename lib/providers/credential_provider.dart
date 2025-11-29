import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Credential Types
enum CredentialType {
  certificate,
  degree,
  license,
  training,
  award,
  other,
}

/// Credential Model - Stored Locally Only
class Credential {
  final String id;
  final String title;
  final String issuer;
  final DateTime issueDate;
  final DateTime? expirationDate;
  final CredentialType type;
  final String? description;
  final String? filePath; // Path to PDF/image on device
  final String? credentialNumber;
  final List<String> tags;
  final DateTime createdAt;

  Credential({
    String? id,
    required this.title,
    required this.issuer,
    required this.issueDate,
    this.expirationDate,
    required this.type,
    this.description,
    this.filePath,
    this.credentialNumber,
    List<String>? tags,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  bool get expiringWithin30Days {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration > 0 && daysUntilExpiration <= 30;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'issuer': issuer,
      'issueDate': issueDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'type': type.toString(),
      'description': description,
      'filePath': filePath,
      'credentialNumber': credentialNumber,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'],
      title: json['title'],
      issuer: json['issuer'],
      issueDate: DateTime.parse(json['issueDate']),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
      type: CredentialType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => CredentialType.other,
      ),
      description: json['description'],
      filePath: json['filePath'],
      credentialNumber: json['credentialNumber'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Credential copyWith({
    String? title,
    String? issuer,
    DateTime? issueDate,
    DateTime? expirationDate,
    CredentialType? type,
    String? description,
    String? filePath,
    String? credentialNumber,
    List<String>? tags,
  }) {
    return Credential(
      id: id,
      title: title ?? this.title,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      expirationDate: expirationDate ?? this.expirationDate,
      type: type ?? this.type,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      credentialNumber: credentialNumber ?? this.credentialNumber,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}

/// LOCAL-ONLY Credential Storage Provider
/// NO CLOUD SYNC - Everything stored on device
class CredentialProvider extends ChangeNotifier {
  List<Credential> _credentials = [];
  bool _isLoading = false;
  String? _error;

  List<Credential> get credentials => List.unmodifiable(_credentials);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get app's document directory for local storage
  Future<Directory> get _credentialsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final credDir = Directory(path.join(appDir.path, 'credentials'));
    if (!await credDir.exists()) {
      await credDir.create(recursive: true);
    }
    return credDir;
  }

  // Get metadata file path
  Future<File> get _metadataFile async {
    final dir = await _credentialsDir;
    return File(path.join(dir.path, 'credentials.json'));
  }

  /// Initialize - Load from local storage
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadCredentials();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load credentials from local JSON file
  Future<void> _loadCredentials() async {
    try {
      final file = await _metadataFile;
      
      if (!await file.exists()) {
        _credentials = [];
        return;
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      
      _credentials = jsonList
          .map((json) => Credential.fromJson(json))
          .toList();
      
      // Sort by creation date (newest first)
      _credentials.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    } catch (e) {
      print('Error loading credentials: $e');
      _credentials = [];
    }
  }

  /// Save credentials to local JSON file
  Future<void> _saveCredentials() async {
    try {
      final file = await _metadataFile;
      final jsonList = _credentials.map((c) => c.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving credentials: $e');
      throw Exception('Failed to save credentials: $e');
    }
  }

  /// Add new credential with optional file
  Future<void> addCredential(
    Credential credential, {
    File? file,
  }) async {
    try {
      String? savedFilePath;

      // If file is provided, save it locally
      if (file != null) {
        savedFilePath = await _saveCredentialFile(credential.id, file);
      }

      // Create credential with file path
      final newCredential = credential.copyWith(
        filePath: savedFilePath ?? credential.filePath,
      );

      _credentials.insert(0, newCredential);
      await _saveCredentials();
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to add credential: $e');
    }
  }

  /// Save credential file (PDF/image) to local storage
  Future<String> _saveCredentialFile(String credentialId, File file) async {
    try {
      final dir = await _credentialsDir;
      final extension = path.extension(file.path);
      final newPath = path.join(dir.path, '$credentialId$extension');
      
      await file.copy(newPath);
      return newPath;
      
    } catch (e) {
      throw Exception('Failed to save credential file: $e');
    }
  }

  /// Update existing credential
  Future<void> updateCredential(Credential credential) async {
    try {
      final index = _credentials.indexWhere((c) => c.id == credential.id);
      
      if (index == -1) {
        throw Exception('Credential not found');
      }

      _credentials[index] = credential;
      await _saveCredentials();
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to update credential: $e');
    }
  }

  /// Delete credential and its file
  Future<void> deleteCredential(String id) async {
    try {
      final credential = _credentials.firstWhere((c) => c.id == id);
      
      // Delete file if exists
      if (credential.filePath != null) {
        final file = File(credential.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _credentials.removeWhere((c) => c.id == id);
      await _saveCredentials();
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to delete credential: $e');
    }
  }

  /// Search credentials
  List<Credential> searchCredentials(String query) {
    if (query.isEmpty) return credentials;

    final lowerQuery = query.toLowerCase();
    return _credentials.where((c) {
      return c.title.toLowerCase().contains(lowerQuery) ||
          c.issuer.toLowerCase().contains(lowerQuery) ||
          (c.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          c.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get credentials by type
  List<Credential> getCredentialsByType(CredentialType type) {
    return _credentials.where((c) => c.type == type).toList();
  }

  /// Get expired credentials
  List<Credential> get expiredCredentials {
    return _credentials.where((c) => c.isExpired).toList();
  }

  /// Get credentials expiring soon
  List<Credential> get expiringSoonCredentials {
    return _credentials.where((c) => c.expiringWithin30Days).toList();
  }

  /// Get credentials by tag
  List<Credential> getCredentialsByTag(String tag) {
    return _credentials.where((c) => c.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  List<String> get allTags {
    final tags = <String>{};
    for (var credential in _credentials) {
      tags.addAll(credential.tags);
    }
    return tags.toList()..sort();
  }

  /// Get storage stats
  Future<Map<String, dynamic>> getStorageStats() async {
    final dir = await _credentialsDir;
    int totalSize = 0;
    int fileCount = 0;

    if (await dir.exists()) {
      final files = dir.listSync();
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
          fileCount++;
        }
      }
    }

    return {
      'total_credentials': _credentials.length,
      'total_files': fileCount,
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'expired_count': expiredCredentials.length,
      'expiring_soon_count': expiringSoonCredentials.length,
    };
  }

  /// Export all credentials (for backup)
  Future<File> exportCredentials() async {
    final tempDir = await getTemporaryDirectory();
    final exportFile = File(path.join(
      tempDir.path,
      'prostack_credentials_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    ));

    final exportData = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'credentials': _credentials.map((c) => c.toJson()).toList(),
    };

    await exportFile.writeAsString(json.encode(exportData));
    return exportFile;
  }

  /// Import credentials from backup
  Future<void> importCredentials(File backupFile) async {
    try {
      final contents = await backupFile.readAsString();
      final data = json.decode(contents);
      
      if (data['version'] != '1.0') {
        throw Exception('Unsupported backup version');
      }

      final List<dynamic> credentialsList = data['credentials'];
      final imported = credentialsList
          .map((json) => Credential.fromJson(json))
          .toList();

      // Add imported credentials (avoiding duplicates)
      for (var credential in imported) {
        if (!_credentials.any((c) => c.id == credential.id)) {
          _credentials.add(credential);
        }
      }

      await _saveCredentials();
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to import credentials: $e');
    }
  }
}

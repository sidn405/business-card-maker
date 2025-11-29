import 'package:flutter/foundation.dart';
import '../models/business_card.dart';
import '../services/database_service.dart';

class BusinessCardProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<BusinessCard> _cards = [];
  bool _isLoading = false;

  List<BusinessCard> get cards => _cards;
  bool get isLoading => _isLoading;

  /// Initialize provider and load cards from database
  Future<void> initialize() async {
    await _databaseService.initialize();
    await loadCards();
  }

  /// Load all cards from database
  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      _cards = await _databaseService.getAllCards();
    } catch (e) {
      print('Error loading cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new card
  Future<void> addCard(BusinessCard card) async {
    try {
      await _databaseService.insertCard(card);
      _cards.insert(0, card); // Add to beginning of list
      notifyListeners();
    } catch (e) {
      print('Error adding card: $e');
      rethrow;
    }
  }

  /// Update existing card
  Future<void> updateCard(BusinessCard card) async {
    try {
      await _databaseService.updateCard(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _cards[index] = card;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating card: $e');
      rethrow;
    }
  }

  /// Delete card
  Future<void> deleteCard(String id) async {
    try {
      await _databaseService.deleteCard(id);
      _cards.removeWhere((card) => card.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting card: $e');
      rethrow;
    }
  }

  /// Get card by ID
  BusinessCard? getCardById(String id) {
    try {
      return _cards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search cards
  List<BusinessCard> searchCards(String query) {
    if (query.isEmpty) return _cards;

    final lowercaseQuery = query.toLowerCase();
    return _cards.where((card) {
      return card.name.toLowerCase().contains(lowercaseQuery) ||
          card.company.toLowerCase().contains(lowercaseQuery) ||
          card.email.toLowerCase().contains(lowercaseQuery) ||
          card.phone.contains(query);
    }).toList();
  }

  /// Dispose resources
  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}

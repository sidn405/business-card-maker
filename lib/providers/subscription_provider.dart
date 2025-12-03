import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/subscription.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:device_info_plus/device_info_plus.dart';
//import '../config.dart';

class SubscriptionProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  Subscription _currentSubscription = Subscription.free();
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isLoading = false;
  String _lastError = '';

  // Backend configuration
  static const String _backendUrl = 'https://business-card-maker-production.up.railway.app';
  // ProStack API Key for authenticating with your backend
  // MUST be provided via --dart-define=PROSTACK_API_KEY=xxx at build time
  static const String _prostackApiKey = String.fromEnvironment('PROSTACK_API_KEY', defaultValue: '');
  
  // Device ID for license management
  String? _deviceId;

  Subscription get currentSubscription => _currentSubscription;
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  // Product IDs
  static const Set<String> _productIds = {
    'prostack_premium',
    'prostack_premium_yearly',
    'prostack_business',
    'prostack_business_yearly',
  };

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor; // iOS Vendor ID
      }
      debugPrint('🔵 [Device] Device ID: $_deviceId');
      return _deviceId ?? 'unknown';
    } catch (e) {
      debugPrint('🔴 [Device] Error getting device ID: $e');
      _deviceId = 'unknown';
      return _deviceId!;
    }
  }

  Future<void> initialize() async {
    debugPrint('🔵 [IAP] Initializing subscription provider...');
    debugPrint('🔵 [Config] ProStack API Key present: ${_prostackApiKey.isNotEmpty}');
    
    if (_prostackApiKey.isEmpty) {
      debugPrint('🔴 [Config] CRITICAL: PROSTACK_API_KEY not configured!');
      debugPrint('🔴 [Config] Build with: flutter build apk --dart-define=PROSTACK_API_KEY=xxx');
      _lastError = 'App not configured properly. Please contact support.';
      notifyListeners();
      return;
    }
    
    // Get device ID
    await _getDeviceId();
    
    // Check if IAP is available
    _isAvailable = await _iap.isAvailable();
    debugPrint('🔵 [IAP] In-app purchases available: $_isAvailable');
    
    if (_isAvailable) {
      // Load products
      await _loadProducts();
      
      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) {
          debugPrint('🔴 [IAP] Purchase stream error: $error');
          _lastError = error.toString();
          notifyListeners();
        },
      );
      
      // Restore previous purchases
      await _restorePurchases();
    } else {
      debugPrint('🔴 [IAP] In-app purchases NOT available on this device');
      _lastError = 'In-app purchases not available';
    }
    
    // Load saved subscription
    await _loadSavedSubscription();
    notifyListeners();
    
    debugPrint('🔵 [IAP] Initialization complete');
  }

  Future<void> _loadProducts() async {
    debugPrint('🔵 [IAP] Loading products...');
    debugPrint('🔵 [IAP] Product IDs: $_productIds');
    
    try {
      final response = await _iap.queryProductDetails(_productIds);
      
      if (response.error != null) {
        debugPrint('🔴 [IAP] Error loading products: ${response.error}');
        _lastError = 'Failed to load products: ${response.error!.message}';
        notifyListeners();
        return;
      }

      _products = response.productDetails;
      debugPrint('🟢 [IAP] Loaded ${_products.length} products:');
      for (var product in _products) {
        debugPrint('  - ${product.id}: ${product.title} (${product.price})');
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('🟡 [IAP] Products not found: ${response.notFoundIDs}');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('🔴 [IAP] Exception querying products: $e');
      _lastError = 'Exception loading products: $e';
      notifyListeners();
    }
  }

  Future<void> _loadSavedSubscription() async {
    debugPrint('🔵 [Storage] Loading saved subscription...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final tierString = prefs.getString('subscription_tier');
      final expiryString = prefs.getString('subscription_expiry');
      
      debugPrint('🔵 [Storage] Saved tier: $tierString');
      debugPrint('🔵 [Storage] Saved expiry: $expiryString');
      
      if (tierString != null) {
        SubscriptionTier tier = SubscriptionTier.values.firstWhere(
          (e) => e.toString() == tierString,
          orElse: () => SubscriptionTier.free,
        );
        
        DateTime? expiryDate;
        if (expiryString != null) {
          expiryDate = DateTime.parse(expiryString);
        }
        
        // Check if subscription is still active
        bool isActive = true;
        if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
          isActive = false;
          tier = SubscriptionTier.free;
          debugPrint('🟡 [Storage] Subscription expired');
        }
        
        _currentSubscription = Subscription(
          tier: tier,
          expiryDate: expiryDate,
          isActive: isActive,
        );
        
        debugPrint('🟢 [Storage] Loaded subscription: ${tier.toString()}');
      } else {
        debugPrint('🔵 [Storage] No saved subscription found, using free tier');
      }
    } catch (e) {
      debugPrint('🔴 [Storage] Error loading subscription: $e');
    }
  }

  Future<void> _saveSubscription() async {
    debugPrint('🔵 [Storage] Saving subscription...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_tier', _currentSubscription.tier.toString());
      if (_currentSubscription.expiryDate != null) {
        await prefs.setString('subscription_expiry', _currentSubscription.expiryDate!.toIso8601String());
      }
      
      debugPrint('🟢 [Storage] Subscription saved: ${_currentSubscription.tier}');
    } catch (e) {
      debugPrint('🔴 [Storage] Error saving subscription: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    debugPrint('🔵 [IAP] Purchase update received: ${purchases.length} purchases');
    
    for (var purchase in purchases) {
      debugPrint('🔵 [IAP] Purchase status: ${purchase.status}');
      debugPrint('🔵 [IAP] Product ID: ${purchase.productID}');
      
      if (purchase.status == PurchaseStatus.purchased) {
        debugPrint('🟢 [IAP] Purchase completed!');
        _verifyAndDeliverProduct(purchase);
      } else if (purchase.status == PurchaseStatus.restored) {
        debugPrint('🟢 [IAP] Purchase restored!');
        _verifyAndDeliverProduct(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('🔴 [IAP] Purchase error: ${purchase.error}');
        _lastError = 'Purchase failed: ${purchase.error?.message ?? "Unknown error"}';
        _isLoading = false;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.pending) {
        debugPrint('🟡 [IAP] Purchase pending...');
        _lastError = 'Purchase pending...';
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint('🟡 [IAP] Purchase canceled by user');
        _lastError = 'Purchase canceled';
        _isLoading = false;
        notifyListeners();
      }

      if (purchase.pendingCompletePurchase) {
        debugPrint('🔵 [IAP] Completing purchase...');
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchase) async {
    debugPrint('🔵 [Verify] Starting purchase verification...');

    try {
      // Get purchase token
      String? purchaseToken;

      if (Platform.isAndroid) {
        purchaseToken = purchase.verificationData.serverVerificationData;
      } else if (Platform.isIOS) {
        purchaseToken = purchase.verificationData.serverVerificationData;
      }

      // Safe preview for logs (null + short string safe)
      final previewToken = (purchaseToken ?? '');
      final preview = previewToken.length > 20
          ? previewToken.substring(0, 20)
          : previewToken;

      if (Platform.isAndroid) {
        debugPrint('🔵 [Verify] Android purchase token: $preview...');
      } else if (Platform.isIOS) {
        debugPrint('🔵 [Verify] iOS purchase token: $preview...');
      }

      if (purchaseToken == null || purchaseToken.isEmpty) {
        debugPrint('🔴 [Verify] No purchase token available!');
        _lastError = 'No purchase token';
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('🔵 [Verify] Verifying with backend: $_backendUrl');

      // Send purchase data to backend for verification
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/subscriptions/verify'),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': _prostackApiKey, // ProStack API key for backend auth
            },
            body: jsonEncode({
              'product_id': purchase.productID,
              'purchase_token': purchaseToken,
              'platform': Platform.isAndroid ? 'android' : 'ios',
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('🔵 [Verify] Backend response status: ${response.statusCode}');
      debugPrint('🔵 [Verify] Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['is_valid'] == true) {
          debugPrint('🟢 [Verify] Purchase verified successfully!');

          // Parse subscription tier
          SubscriptionTier tier = SubscriptionTier.free;
          if (data['subscription_tier'] == 'premium') {
            tier = SubscriptionTier.premium;
          } else if (data['subscription_tier'] == 'business') {
            tier = SubscriptionTier.business;
          }

          debugPrint('🔵 [Verify] Subscription tier: $tier');

          // Parse expiry date
          DateTime? expiryDate;
          if (data['expiry_date'] != null) {
            expiryDate = DateTime.parse(data['expiry_date']);
            debugPrint('🔵 [Verify] Expiry date: $expiryDate');
          }

          // Update subscription
          _currentSubscription = Subscription(
            tier: tier,
            expiryDate: expiryDate,
            isActive: true,
          );

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('purchase_token', purchaseToken);
          await prefs.setString('last_product_id', purchase.productID);
          await _saveSubscription();

          _isLoading = false;
          _lastError = '';
          notifyListeners();

          debugPrint('🟢 [Verify] Subscription activated: ${tier.toString()}');
        } else {
          debugPrint('🔴 [Verify] Purchase verification failed: ${data['message']}');
          _lastError = 'Verification failed: ${data['message']}';
          _isLoading = false;
          notifyListeners();
        }
      } else {
        debugPrint('🔴 [Verify] Backend verification error: ${response.statusCode}');
        _lastError = 'Backend error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🔴 [Verify] Exception verifying purchase: $e');
      _lastError = 'Verification error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> purchaseSubscription(String productId) async {
    debugPrint('══════════════════════════════════════════════');
    debugPrint('🔵 [Purchase] Starting purchase flow...');
    debugPrint('🔵 [Purchase] Product ID: $productId');
    debugPrint('══════════════════════════════════════════════');
    
    if (!_isAvailable) {
      debugPrint('🔴 [Purchase] IAP not available');
      _lastError = 'In-app purchases not available';
      notifyListeners();
      return;
    }

    debugPrint('🔵 [Purchase] Looking for product in ${_products.length} loaded products...');
    
    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == productId);
      debugPrint('🟢 [Purchase] Found product: ${product.title}');
    } catch (e) {
      debugPrint('🔴 [Purchase] Product not found: $productId');
      debugPrint('🔴 [Purchase] Available products: ${_products.map((p) => p.id).toList()}');
      _lastError = 'Product not found: $productId';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    debugPrint('🔵 [Purchase] Creating purchase param...');

    try {
      // For Android subscriptions with base plans, use GooglePlayPurchaseParam
      final purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
      );
      
      debugPrint('🔵 [Purchase] Initiating purchase...');
      debugPrint('🔵 [Purchase] Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
      
      bool result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      debugPrint('🔵 [Purchase] Purchase initiated: $result');
      
      if (!result) {
        debugPrint('🔴 [Purchase] Failed to initiate purchase');
        _lastError = 'Failed to start purchase';
        _isLoading = false;
        notifyListeners();
      } else {
        debugPrint('🟢 [Purchase] Waiting for purchase stream update...');
      }
    } catch (e) {
      debugPrint('🔴 [Purchase] Exception during purchase: $e');
      _lastError = 'Purchase error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restorePurchases() async {
    debugPrint('🔵 [Restore] Restoring purchases...');
    try {
      await _iap.restorePurchases();
      debugPrint('🟢 [Restore] Restore purchases completed');
    } catch (e) {
      debugPrint('🔴 [Restore] Error restoring purchases: $e');
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('🔵 [Restore] User requested restore purchases');
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    await _restorePurchases();
    
    _isLoading = false;
    notifyListeners();
  }

  // Synchronous check for UI
  bool canAccessFeature(String feature) {
    final sub = _currentSubscription;

    // A subscription must be active at minimum
    if (!sub.isActive) return false;

    switch (feature) {
      // --- BUSINESS-ONLY FEATURES ---
      case 'ai_resume':
      case 'credentials':
      case 'portfolio':
        return sub.tier == SubscriptionTier.business;

      // --- PREMIUM or BUSINESS (example) ---
      case 'custom_templates':
      case 'color_themes':
      case 'company_logos':
      case 'qr_codes':
        return sub.tier == SubscriptionTier.premium ||
              sub.tier == SubscriptionTier.business;

      // --- BUSINESS-ONLY big features ---
      case 'bulk_export':
        return sub.tier == SubscriptionTier.business;


      default:
        return false;
    }
  }

  // Check if user has reached card limit
  bool canAddCard(int currentCardCount) {
    final maxCards = _currentSubscription.maxCards;
    if (maxCards == -1) return true;
    return currentCardCount < maxCards;
  }

  @override
  void dispose() {
    debugPrint('🔵 [IAP] Disposing subscription provider');
    _subscription.cancel();
    super.dispose();
  }
}
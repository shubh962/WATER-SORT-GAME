import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:water_sort/models/products.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/telemetry.dart';

/// Hook for server-side receipt validation. The default trusts the store.
/// Before you sell a lot of coin packs, replace it with a call to your own
/// backend (or a service such as iaptic) that checks the purchase token
/// with the Google Play Developer API.
abstract class PurchaseVerifier {
  Future<bool> verify(PurchaseDetails purchase);
}

class LocalVerifier implements PurchaseVerifier {
  const LocalVerifier();
  @override
  Future<bool> verify(PurchaseDetails purchase) async => true;
}

/// Google Play Billing through the official in_app_purchase plugin.
/// - Subscribes to the purchase stream at app start (required by Google).
/// - Grants first, then consumes/acknowledges, and de-duplicates by purchase token,
///   so a crash in between can never lose or double a purchase.
class IapService extends ChangeNotifier {
  IapService(this._state, {InAppPurchase? iap, PurchaseVerifier? verifier})
      : _iap = iap ?? InAppPurchase.instance,
        _verifier = verifier ?? const LocalVerifier();

  final AppState _state;
  final InAppPurchase _iap;
  final PurchaseVerifier _verifier;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _details = <String, ProductDetails>{};
  final Set<String> _pending = <String>{};
  final StreamController<String> _messages = StreamController<String>.broadcast();

  bool storeAvailable = false;
  bool loading = true;

  /// Short user-facing messages ("PRO unlocked", errors) for SnackBars.
  Stream<String> get messages => _messages.stream;

  bool isPending(String id) => _pending.contains(id);
  bool isBuyable(String id) => storeAvailable && _details.containsKey(id);

  String priceOf(StoreProduct p) => _details[p.id]?.price ?? p.fallbackPrice;

  Future<void> init() async {
    if (kIsWeb) {
      loading = false; // no store in a browser
      notifyListeners();
      return;
    }
    _sub ??= _iap.purchaseStream.listen(
      (List<PurchaseDetails> list) => unawaited(_onPurchases(list)),
      onError: (Object e, StackTrace s) => Telemetry.error(e, s, reason: 'purchaseStream'),
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    loading = true;
    notifyListeners();
    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final response = await _iap.queryProductDetails(Products.ids);
        _details
          ..clear()
          ..addEntries(response.productDetails.map((d) => MapEntry<String, ProductDetails>(d.id, d)));
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('IAP: products not found in Play Console: ${response.notFoundIDs}');
        }
        if (response.error != null) Telemetry.error(response.error!.message, null, reason: 'iap.query');
      }
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'iap.load');
      storeAvailable = false;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(StoreProduct product) async {
    final details = _details[product.id];
    if (details == null || !storeAvailable) {
      _messages.add('The store is not available right now. Try again later.');
      return;
    }
    if (_pending.contains(product.id)) return;
    _pending.add(product.id);
    notifyListeners();
    Telemetry.event('purchase_start', <String, Object?>{'id': product.id});
    try {
      final param = PurchaseParam(productDetails: details);
      final started = product.kind == ProductKind.consumable
          ? await _iap.buyConsumable(purchaseParam: param, autoConsume: false)
          : await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _pending.remove(product.id);
        notifyListeners();
      }
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'iap.buy');
      _pending.remove(product.id);
      _messages.add('Purchase could not be started.');
      notifyListeners();
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
      _messages.add('Checking your purchases...');
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'iap.restore');
      _messages.add('Could not restore purchases.');
    }
  }

  // ---------- purchase stream ----------
  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      try {
        await _process(p);
      } catch (e, s) {
        Telemetry.error(e, s, reason: 'iap.process ${p.productID}');
      }
    }
    notifyListeners();
  }

  Future<void> _process(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        _pending.add(p.productID);
        return;
      case PurchaseStatus.error:
        _pending.remove(p.productID);
        _messages.add(p.error?.message ?? 'Purchase failed.');
        Telemetry.event('purchase_error', <String, Object?>{'id': p.productID, 'code': p.error?.code});
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        return;
      case PurchaseStatus.canceled:
        _pending.remove(p.productID);
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _deliver(p);
        return;
    }
  }

  String _keyOf(PurchaseDetails p) {
    final token = p.verificationData.serverVerificationData;
    return token.isNotEmpty ? token : (p.purchaseID ?? '${p.productID}:${p.transactionDate}');
  }

  Future<void> _deliver(PurchaseDetails p) async {
    _pending.remove(p.productID);
    final product = Products.byId(p.productID);
    if (product == null) {
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      return;
    }
    if (!await _verifier.verify(p)) {
      Telemetry.event('purchase_rejected', <String, Object?>{'id': p.productID});
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      return;
    }

    final firstTime = _state.markProcessed(_keyOf(p));
    if (firstTime || product.kind == ProductKind.nonConsumable) {
      // Non-consumables are idempotent (flags), so re-granting after a restore is safe.
      final alreadyHad = (product.grantsPro && _state.pro) || (product.removesAds && _state.noAds);
      if (firstTime || !alreadyHad) {
        _state.grantProduct(product);
        _messages.add(_messageFor(product));
      }
    }

    // Grant is saved. Now tell Google the purchase is handled.
    if (Platform.isAndroid && product.kind == ProductKind.consumable && p is GooglePlayPurchaseDetails) {
      final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await android.consumePurchase(p);
    }
    if (p.pendingCompletePurchase) await _iap.completePurchase(p);
  }

  String _messageFor(StoreProduct p) {
    if (p.grantsPro) return 'PRO unlocked. Thank you!';
    if (p.removesAds) return 'Ads removed. Thank you!';
    return '+${p.coins} coins added';
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_messages.close());
    super.dispose();
  }
}

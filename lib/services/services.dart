import 'package:water_sort/services/ads_service.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/iap_service.dart';
import 'package:water_sort/services/review_service.dart';

/// Tiny service locator. Filled once in main() before runApp().
class Services {
  static late final AppState state;
  static late final AdsService ads;
  static late final IapService iap;
  static late final ReviewService review;

  static void register({
    required AppState state,
    required AdsService ads,
    required IapService iap,
    required ReviewService review,
  }) {
    Services.state = state;
    Services.ads = ads;
    Services.iap = iap;
    Services.review = review;
  }
}

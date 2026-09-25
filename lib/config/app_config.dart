/// Central application configuration.
///
/// This file contains the main release-editable configuration for Water Sort.
///
/// ADS:
/// - Build with --dart-define=USE_TEST_ADS=true for Google test ads.
/// - Build with --dart-define=USE_TEST_ADS=false for real production ads.
///
/// Example test build:
/// flutter build apk --release --dart-define=USE_TEST_ADS=true
///
/// Example production build:
/// flutter build appbundle --release --dart-define=USE_TEST_ADS=false
class AppConfig {
  AppConfig._();

  // ===========================================================================
  // APP
  // ===========================================================================

  static const String appName = 'Water Sort';

  // ===========================================================================
  // ADS
  // ===========================================================================

  /// Controls whether Google test ad units or real production ad units are used.
  ///
  /// TEST:
  ///   flutter build apk --release --dart-define=USE_TEST_ADS=true
  ///
  /// PRODUCTION:
  ///   flutter build appbundle --release --dart-define=USE_TEST_ADS=false
  ///
  /// Default is false so a normal production build uses real AdMob IDs.
  static const bool useTestAds =
      bool.fromEnvironment('USE_TEST_ADS', defaultValue: false);

  /// Shows a banner on the Home screen.
  ///
  /// The Game screen uses its banner according to the game's ad configuration.
  static const bool bannerOnHome = true;

  // ===========================================================================
  // DEBUG
  // ===========================================================================

  /// Shows the in-game debug helper.
  ///
  /// Keep this disabled for production.
  static const bool debugTools =
      bool.fromEnvironment('DEBUG_TOOLS', defaultValue: false);

  // ===========================================================================
  // LEGAL / STORE LISTING
  // ===========================================================================

  static const String privacyPolicyUrl =
      'https://shubh962.github.io/Water-sort-Legal/privacy-policy.html';

  static const String termsUrl =
      'https://shubh962.github.io/Water-sort-Legal/terms-and-conditions.html';

  static const String supportEmail = 'Gautamshubham962@gmail.com';

  // ===========================================================================
  // ADMOB TEST DEVICES
  // ===========================================================================

  /// Optional test device IDs.
  ///
  /// Google test ad units are used when USE_TEST_ADS=true, so a test device
  /// ID is not required for the current test build.
  ///
  /// If you later want to test your REAL production ad units on your phone,
  /// add your Android test device ID here.
  static const List<String> testDeviceIds = <String>[];
}

// =============================================================================
// ADMOB AD UNIT IDs
// =============================================================================

/// AdMob production and test ad-unit configuration.
///
/// Production App ID:
/// ca-app-pub-2427221337462218~1343049941
///
/// IMPORTANT:
/// The AdMob App ID itself is configured separately in the Android
/// Gradle/Manifest configuration.
///
/// When USE_TEST_ADS=true:
///   Google official test ad units are selected.
///
/// When USE_TEST_ADS=false:
///   Your real production ad units are selected.
class AdIds {
  AdIds._();

  // ===========================================================================
  // REAL PRODUCTION AD UNITS
  // ===========================================================================

  static const AdUnits _real = AdUnits(
    // Real Banner
    banner: 'ca-app-pub-2427221337462218/4381110971',

    // Real Interstitial
    interstitial: 'ca-app-pub-2427221337462218/6139633948',

    // Real Rewarded
    rewarded: 'ca-app-pub-2427221337462218/5948062259',
  );

  // ===========================================================================
  // GOOGLE OFFICIAL TEST AD UNITS
  // ===========================================================================

  static const AdUnits _test = AdUnits(
    // Google Banner Test ID
    banner: 'ca-app-pub-3940256099942544/6300978111',

    // Google Interstitial Test ID
    interstitial: 'ca-app-pub-3940256099942544/1033173712',

    // Google Rewarded Test ID
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  // ===========================================================================
  // ACTIVE AD UNITS
  // ===========================================================================

  /// Returns test IDs when USE_TEST_ADS=true.
  ///
  /// Returns your real production IDs when USE_TEST_ADS=false.
  static AdUnits get units {
    return AppConfig.useTestAds ? _test : _real;
  }

  // ===========================================================================
  // PRODUCTION ID VALIDATION
  // ===========================================================================

  /// Checks whether any REAL production ad-unit ID is missing or contains
  /// an obvious placeholder.
  ///
  /// This intentionally checks the production IDs, not the test IDs.
  static bool get realIdsMissing {
    return _real.banner.isEmpty ||
        _real.interstitial.isEmpty ||
        _real.rewarded.isEmpty ||
        _real.banner.contains('XXXX') ||
        _real.interstitial.contains('XXXX') ||
        _real.rewarded.contains('XXXX');
  }
}

// =============================================================================
// ADMOB AD UNIT COLLECTION
// =============================================================================

/// Collection of AdMob ad-unit IDs.
class AdUnits {
  const AdUnits({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  final String banner;
  final String interstitial;
  final String rewarded;
}

// =============================================================================
// AD FREQUENCY / PLACEMENT RULES
// =============================================================================

/// Ad frequency and placement rules.
///
/// These values control when interstitial ads are allowed to appear.
class AdRules {
  AdRules._();

  /// Never show an interstitial before level 4.
  static const int firstInterstitialLevel = 4;

  /// Show an interstitial at every second eligible level break.
  static const int everyNLevels = 2;

  /// Minimum time between interstitial advertisements.
  static const Duration cooldown = Duration(seconds: 60);
}
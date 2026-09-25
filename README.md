# Water Sort (Flutter shell + HTML5 game)

> **Publishing to Google Play?** Read `PLAY_STORE_GUIDE.md` (target SDK 36, legal pages, real AdMob, real IAP, APK/AAB, Play Console forms). Legal page templates are in `docs/`.

The game itself is the same HTML5 code (`assets/web/index.html`). Flutter is the "front end" that wraps it:
home screen, shop, PRO, styles (coin sink), daily reward, settings, AdMob and Google Play Billing.

```
Home / Shop / PRO / Styles / Settings / Daily reward      <- Flutter (lib/ui)
        |
GameScreen = WebView (assets/web/index.html) + banner ad  <- the HTML5 game
        |  JS channel "FlutterHost"  (lib/services/game_bridge.dart)
Flutter services: AppState (coins, level, purchases), AdsService (AdMob + consent), IapService (Play Billing)
```

Flutter owns coins, level progress, purchases and settings. The game can only ask Flutter to add or spend coins,
show an ad, or open a screen. That keeps money logic in one trusted place.

> **Honest status:** I could not install Flutter in my environment, so the Dart code has **not been compiled**.
> What I did check: every Dart file parses (syntax), all imports resolve, and the HTML game was tested against a fake
> Flutter host that implements the same message protocol (coins, ads, back button, PRO, timers, boosts).
> Run `flutter analyze` first. Package APIs (especially `google_mobile_ads` 9.x and `in_app_purchase`) can change between
> versions, so expect to fix a few small compile errors on first run. Send me the output and I will fix them.

---

## 1. Requirements

- **Flutter 3.44 or newer (Dart 3.12+)**. This is required: `in_app_purchase_android` 0.5+ (the release that uses Google Play Billing Library 8, which Google Play has demanded since 31 Aug 2026) needs Flutter 3.44. `pubspec.yaml` enforces it.
- Android SDK (Platform 36) and JDK 17
- A phone with USB debugging (a low-RAM laptop is fine: use `flutter run` on the phone, or build in the cloud, see step 8)

## 2. Create the Android project around these files

```bash
flutter create --platforms=android --org com.yourname --project-name water_sort .
```

Run this inside this folder. It adds the `android/` folder and keeps our `lib/` and `pubspec.yaml`.
It may also create `test/widget_test.dart` (it references a `MyApp` class that does not exist here): **delete that file**. Then:

```bash
python3 tool/patch_android.py      # manifest permissions, AdMob app id placeholder, network config, proguard file
flutter pub get
```

## 3. What the patch script does

- adds `INTERNET` and `com.google.android.gms.permission.AD_ID` (needed by AdMob on Android 13+)
- adds the AdMob `APPLICATION_ID` meta-data as `${admobAppId}` (filled by Gradle, step 4)
- turns off clear-text traffic, adds `network_security_config.xml`, copies `proguard-rules.pro`

## 4. Gradle edits in `android/app/build.gradle.kts` (4 small blocks)

Add at the very top of the file:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android { ... }`:

```kotlin
    defaultConfig {
        // keep the lines Flutter generated (applicationId, targetSdk, versionCode...) and set/add:
        minSdk = 24
        targetSdk = 36   // Google Play requires API 36 for new apps and updates since 31 Aug 2026
        // AdMob APP ID: Google's sample id by default (safe for testing). Real id comes from -PadmobAppId.
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("admobAppId") as String?) ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
```

At the very end of the file (blocks a release build that still has the sample AdMob app id):

```kotlin
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release", ignoreCase = true) } && project.findProperty("admobAppId") == null) {
        throw GradleException("Set your real AdMob App ID: -PadmobAppId=ca-app-pub-XXXX~YYYY (or env ORG_GRADLE_PROJECT_admobAppId)")
    }
}
```

To try a release build on your phone with test ads, put this in `~/.gradle/gradle.properties`:
`admobAppId=ca-app-pub-3940256099942544~3347511713`

If your project uses `build.gradle` (Groovy) instead of `.kts`, the same four blocks apply with Groovy syntax.

## 5. Run with TEST ads (default)

```bash
flutter analyze
flutter test
flutter run
```

You get Google's demo banner, interstitial and rewarded ads. The Settings screen shows a red "TEST ADS ENABLED" line.
Everything is already wired with the test IDs, so you can test the whole flow today.

## 6. Switch to your REAL ads (the only 3 places)

1. `lib/config/app_config.dart` -> `AdIds._real`: paste your banner, interstitial and rewarded **ad unit IDs**.
2. AdMob **App ID** (`ca-app-pub-...~...`): pass it as a Gradle property, never in code:
   `ORG_GRADLE_PROJECT_admobAppId=ca-app-pub-XXXX~YYYY` (CI secret `ADMOB_APP_ID`).
3. Build with `--dart-define=USE_TEST_ADS=false`:
   `flutter build appbundle --release --dart-define=USE_TEST_ADS=false --obfuscate --split-debug-info=build/symbols`

Safety nets: if `USE_TEST_ADS=false` but the ad unit IDs still contain `XXXX`, ads are disabled and an error is logged
(the app never crashes). If a release build still uses test ads, a warning is logged. Never click your own live ads.

## 7. In-app products (Play Console > Monetize > In-app products)

Create these **exact** IDs (or edit `lib/models/products.dart`). All are "one-time products". The app decides which are
consumed.

| Product ID    | Behaviour                 | Suggested price | Gives                                   |
|---------------|---------------------------|-----------------|-----------------------------------------|
| `remove_ads`  | permanent (non-consumable)| Rs 149          | no banners / no forced videos           |
| `pro_pass`    | permanent (non-consumable)| Rs 349          | no ads + all PRO perks (see below)      |
| `coins_500`   | consumable                | Rs 29           | 500 coins                               |
| `coins_1500`  | consumable                | Rs 79           | 1,500 coins                             |
| `coins_5000`  | consumable                | Rs 199          | 5,000 coins                             |

Prices in the app come from Google Play automatically (the numbers in code are only shown before the store answers).

Testing purchases: upload a build to **Internal testing**, add your Gmail under Setup > License testers, install from the
testing link. License testers are not charged.

**PRO perks** (all implemented): no ads, unlimited undos, 3 extra bottles per level, 1 free hint per level,
double coins on wins and daily rewards, PRO-only bottle style (Obsidian) and background (Royal).

## 8. Build without a strong laptop (GitHub Actions)

`.github/workflows/android.yml` builds a signed, obfuscated AAB in the cloud. Add these repository secrets:
`KEYSTORE_BASE64` (`base64 -w0 upload-keystore.jks`), `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `ADMOB_APP_ID`.
Create the keystore once: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
and **back it up**. Commit the `android/` folder so the workflow can use it (`key.properties` and `*.jks` are git-ignored).

## 9. What coins are for (all wired)

| Sink                        | Price          | Where                              |
|-----------------------------|----------------|------------------------------------|
| Hint                        | 30             | game (free for PRO, once a level)  |
| +3 undos                    | 40             | game (unlimited for PRO)           |
| Extra bottle                | 60             | game                               |
| +30 seconds (timed levels)  | 50             | game                               |
| Skip a level                | 150            | pause menu / time-up screen        |
| Bottle styles, backgrounds  | 400 to 1,500   | Home > Styles                      |

Sources: level wins (40 to 120+ coins), daily reward streak (50 to 500), free rewarded video (200), coin packs.
Every boost can also be paid with a rewarded video instead (the player chooses). All prices live in `lib/config/economy.dart`
and are sent to the game at boot, so you never edit the HTML to rebalance.

## 10. Game <-> Flutter protocol (for when you extend the game)

Game to Flutter (`window.FlutterHost.postMessage(JSON)`, `{id, type, payload}`; `id != 0` expects a reply):

| type              | payload                     | reply                       |
|-------------------|-----------------------------|-----------------------------|
| `boot`            | none                        | full state (coins, level, PRO, skin, bg, prices...) |
| `ready`           | none                        | none                        |
| `coins.add`       | amount, reason              | `{coins}`                   |
| `coins.spend`     | amount, reason              | `{ok, coins}`               |
| `progress.level`  | level                       | none                        |
| `ads.interstitial`| level                       | `{shown}` (policy decides)  |
| `ads.rewarded`    | placement                   | `{rewarded, reason?}`       |
| `nav`             | to: home / shop / pro       | none                        |
| `settings.muted`, `kv.set`, `haptic`, `analytics`, `review.maybe`, `log` | ... | none |

Flutter to game: `window.__hostEvent(name, data)` with `state`, `pause`, `resume`, `back`.
The game also runs in a normal browser (it uses a built-in mock host), so you can develop the gameplay with just Chrome.

## 11. Production checklist

Done in code:
- Google UMP consent (GDPR/US) before any ad, plus an "Ad privacy settings" entry when required
- Ad preloading with retry and exponential backoff, interstitial frequency policy (level 4+, every 2nd break, 60 s cooldown, never for Remove Ads/PRO), unit tested
- Rewarded ads are always opt-in; banner is outside the game area (no accidental taps)
- Purchases: subscribe to the purchase stream at start, grant first then consume/acknowledge, de-duplicate by purchase token, restore purchases, pending state, verifier hook for server-side validation
- Persistence: versioned JSON save with automatic backup copy, corruption fallback
- Global error handlers, telemetry hook (`lib/services/telemetry.dart`), WebView locked to the local page (all navigation blocked), pause on background / ads, back-button handling, portrait lock, edge-to-edge
- R8 minify + shrink, obfuscation, no clear-text traffic, debug tools off in release
- Rating prompt at happy moments only (max once per 60 days)

You still have to do:
- Fill in and host the legal pages in `docs/` (privacy policy, terms), then set `privacyPolicyUrl`, `termsUrl`, `supportEmail` in `app_config.dart`
- Play Console: App content > **Ads = yes**, **Data safety** (advertising ID is collected by AdMob), **Advertising ID** declaration, target audience 13+ (do not target children). Exact answers are in `PLAY_STORE_GUIDE.md`
- Add `app-ads.txt` to your developer website and link the app in AdMob after publishing
- App icon: add `flutter_launcher_icons`, and a splash with `flutter_native_splash` (optional)
- Crash reporting: implement `TelemetrySink` with Firebase Crashlytics + Analytics and set `Telemetry.sink` in `main()`
- Server-side receipt validation before you rely on coin-pack revenue (implement `PurchaseVerifier`)
- Personal developer accounts created after 13 Nov 2023 must run a closed test with at least 12 testers for 14 days before production
- Real-device test on a low-end phone, and with "Android System WebView" outdated (the game shows a retry screen)

## 12. Known limits

- Android only (iOS would need Info.plist ad IDs, StoreKit products and a Mac to build).
- The game requires Android System WebView (Chrome 90+ equivalent). Old phones may show the retry screen.
- Daily reward uses the phone clock, so a player can cheat it by changing the date. Add a server time check if it matters.
- Levels are procedural and unlimited, the same level number always gives the same puzzle.

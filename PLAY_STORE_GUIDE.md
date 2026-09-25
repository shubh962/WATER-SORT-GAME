# From test build to Play Store: full guide

This guide covers: target SDK 36, privacy policy and legal pages, real AdMob, real in-app purchases, building the APK/AAB, and the Play Console forms.
Facts about Google's rules were checked against Google's own pages on 21 September 2026. Rules change every year, so re-check anything marked (verify).

> The Dart code in this project has not been compiled yet (see README). Do the README steps 1 to 5 first, so the app runs with test ads on your phone. Then follow this guide.

---

## 0. What Google requires right now (September 2026)

| Requirement | What it means for you |
|---|---|
| **Target Android 16 (API 36)** | Since **31 Aug 2026** every new app and every update must target API 36. Set `targetSdk = 36` (step 1) |
| **Play Billing Library 8+** | Since 31 Aug 2026 new apps and updates must use Billing Library 8 or newer. This project needs **Flutter 3.44+** so that `in_app_purchase_android` 0.5+ (Billing Library 8) is used. The `pubspec.yaml` already enforces this |
| **AAB, not APK** | Play Store only accepts an Android App Bundle (`.aab`). APKs are for testing on your own phone |
| **Privacy policy URL** | Mandatory for apps with ads or purchases. Must be a public web page (step 2) |
| **Data safety form + Ads declaration + Advertising ID declaration** | Mandatory Play Console forms (step 7) |
| **Closed test, 12 testers, 14 days** | Only for **personal** developer accounts created after 13 Nov 2023. Organization accounts and older personal accounts are exempt |
| **16 KB page size support** | Apps that ship native code and target Android 15+ must support 16 KB memory pages (verify): current Flutter and the plugins used here should comply. Check the Play Console pre-launch/policy warnings after your first upload |

---

## 1. Target SDK 36 (and Android 16 behavior)

### 1.1 Gradle
In `android/app/build.gradle.kts`, inside `android { defaultConfig { ... } }` set:

```kotlin
compileSdk = flutter.compileSdkVersion     // keep what Flutter generated
targetSdk = 36
minSdk = 24
```

Set `targetSdk = 36` explicitly (do not rely on `flutter.targetSdkVersion`), so a Flutter upgrade or downgrade can never silently change it. If Gradle asks for the "Android SDK Platform 36", accept the licenses: `flutter doctor --android-licenses`, and install "Android SDK Platform 36" from the SDK manager (or let Gradle download it).

### 1.2 What Android 16 changes for this app
| Change | Status in this project |
|---|---|
| Edge-to-edge is always on (cannot be turned off) | Already handled: the app uses `SystemUiMode.edgeToEdge` and `SafeArea` on every screen |
| Predictive back: the old `onBackPressed()` is no longer called | `tool/patch_android.py` adds `android:enableOnBackInvokedCallback="true"`, and the game screen uses Flutter's `PopScope`. **Test the back button** in the game, pause menu, shop and home |
| On screens 600 dp or wider (tablets, foldables) orientation and resizability locks are ignored | The app locks portrait, but on tablets it may appear in landscape. Test on a tablet/foldable emulator. The layout is fluid but not tuned for wide screens |

### 1.3 Check that the build really targets 36
After building the AAB (step 6):

```bash
# bundletool: https://github.com/google/bundletool/releases
java -jar bundletool.jar dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab | grep -E "targetSdkVersion|billingclient"
```
You should see `android:targetSdkVersion="36"` and a `com.google.android.play.billingclient.version` value starting with `8`. Play Console shows the same values after upload (App bundle explorer). If the billing version is below 8, your Flutter is too old: `flutter upgrade`.

---

## 2. Privacy policy and legal pages

Google requires a **public URL**; a PDF or a page that needs login is not accepted.

### 2.1 Use the templates in `docs/`
- `docs/privacy-policy.html`: written for this app (AdMob ads, Google UMP consent, Google Play Billing, data stored on the device, no accounts).
- `docs/terms-of-service.html`: licence, virtual coins (no cash value), purchases and refunds through Google Play, ads.
- `docs/index.html`: a small landing page linking both.

Open each file and replace every yellow `[PLACEHOLDER]`: developer or company name, support email, effective date, country and jurisdiction, app name. **Have a lawyer review them.** These are templates, not legal advice.

If you later add Firebase Analytics or Crashlytics, or any account system, update the privacy policy **and** the Play Console Data safety form. A mismatch between the policy, the form and what the app really does is a common reason for rejection.

### 2.2 Host them for free (GitHub Pages)
1. Push this project to a GitHub repository.
2. Repository **Settings > Pages > Build and deployment > Deploy from a branch**, branch `main`, folder `/docs`.
3. After a minute your pages are live at `https://YOUR-USERNAME.github.io/YOUR-REPO/privacy-policy.html` and `.../terms-of-service.html`.

(You can also host them on your own domain, Google Sites, or Notion public pages, as long as the URL is public and stable.)

### 2.3 Put the URLs into the app
In `lib/config/app_config.dart`:

```dart
static const String privacyPolicyUrl = 'https://YOUR-USERNAME.github.io/YOUR-REPO/privacy-policy.html';
static const String termsUrl        = 'https://YOUR-USERNAME.github.io/YOUR-REPO/terms-of-service.html';
static const String supportEmail    = 'you@yourdomain.com';
```
Settings > Privacy policy / Terms / Contact support already use these. Use the same privacy URL in Play Console (step 7).

---

## 3. Real AdMob

1. Create an account at admob.google.com and finish the profile. (Payments: add your address, tax and payment details; Google mails a PIN when you reach the payment threshold. You can show ads before that.)
2. **Apps > Add app > Android.** If the app is not on Google Play yet, answer "No". You link it to the store listing after it is published.
3. Copy the **App ID** (contains `~`, like `ca-app-pub-1234567890123456~1234567890`).
4. Create **3 ad units** in that app: **Banner**, **Interstitial**, **Rewarded**. Copy each **Ad unit ID** (contains `/`).
5. Paste them:
   - `lib/config/app_config.dart` > `AdIds._real` gets the 3 ad unit IDs.
   - The App ID goes in Gradle, not in code: `ORG_GRADLE_PROJECT_admobAppId` (CI) or `admobAppId=ca-app-pub-...~...` in `~/.gradle/gradle.properties` (local release builds). The Gradle guard from README step 4 stops a release build that does not have it.
6. Build the release with `--dart-define=USE_TEST_ADS=false` (step 6).
7. **Consent message (needed for EEA/UK and recommended everywhere):** AdMob > **Privacy & messaging** > create a **GDPR** message (and a **US states** message), select your app, and **publish**. The app already calls Google's consent form; without a published message no form appears.
8. **app-ads.txt:** put the line AdMob gives you at `https://your-website/app-ads.txt` (see `docs/app-ads.txt.example`), and add the website to your Play Store listing. It protects your ad revenue.
9. After the app is live: AdMob > Apps > your app > **Link to Google Play** (so ad revenue reports match the store listing).

Rules that protect your account:
- **Never click your own live ads.** Use test IDs (the default) or register your phone as a test device.
- New ad units can return "no fill" or no ads for the first hours or days. That is normal.
- Do not ask users to click ads, and do not place buttons next to the banner (this app already keeps them apart).

---

## 4. Real in-app purchases (IAP)

1. Play Console > **Setup > Payments profile** (merchant account). You need it before you can sell anything.
2. Upload a build that contains billing (any track, even Internal testing) once. Products need an app that has billing in its manifest.
3. **Monetize with Play > Products > In-app products > Create product.** Use the **exact IDs** from `lib/models/products.dart`:

| Product ID | Name shown to the player | Suggested price |
|---|---|---|
| `remove_ads` | Remove Ads | Rs 149 |
| `pro_pass` | PRO Pass | Rs 349 |
| `coins_500` | 500 coins | Rs 29 |
| `coins_1500` | 1,500 coins | Rs 79 |
| `coins_5000` | 5,000 coins | Rs 199 |

   For each: add a title and description, set the price (you can set other countries automatically from the base price), and press **Activate**. Product IDs cannot be changed or reused after you delete them.
4. The app decides which products are consumed: coin packs are consumed after the coins are granted; `remove_ads` and `pro_pass` are permanent.
5. **Test with no real charge:** Play Console > **Settings > License testing**, add your Gmail. Install the app **from the Play testing link** (internal or closed track), not from `flutter run` (IAP does not work on sideloaded debug builds). Purchases by license testers are free and can be refunded instantly.
6. If the shop shows "Unavailable": the product is not active, the app was not installed from Play, the Gmail is not a tester, or the product ID does not match. `flutter run` shows "IAP: products not found" in the log with the missing IDs.
7. Before you sell many coin packs, add **server-side receipt validation** (`PurchaseVerifier` in `lib/services/iap_service.dart`).

---

## 5. App icon and app identity (do before the first upload)

- **applicationId** (like `com.yourname.watersort`) is set when you run `flutter create --org com.yourname`. It can **never be changed** after you publish. Check `android/app/build.gradle.kts`.
- **App name:** `android:label` in `AndroidManifest.xml` and `AppConfig.appName`. "Water Sort" is a very common name; pick something unique and check trademarks.
- **Icon:** add `flutter_launcher_icons` (a 1024x1024 PNG), run `dart run flutter_launcher_icons`.
- **Version:** `version: 1.0.0+1` in `pubspec.yaml`. The number after `+` (versionCode) must increase with every upload.

---

## 6. Build the AAB (for Play) and the APK (for testing)

### 6.1 Create the signing key once (and back it up)
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Move `upload-keystore.jks` to `android/app/`, copy `android_patch/key.properties.example` to `android/key.properties`, and fill it in. Both are git-ignored. **Back up the .jks and its passwords** in a safe place (a password manager plus an offline copy). With Play App Signing (enabled by default) Google holds the real app key and this is only your *upload* key, but losing it is still painful.

### 6.2 Release AAB (upload this to Play)
```bash
flutter build appbundle --release \
  --dart-define=USE_TEST_ADS=false \
  --obfuscate --split-debug-info=build/symbols
# output: build/app/outputs/bundle/release/app-release.aab
```
Keep the `build/symbols` folder for this version. You can upload it in Play Console (App bundle explorer > Downloads > Assets) so crash reports are readable.

### 6.3 APK (for installing on your phone or sending to friends)
```bash
# one file per CPU type (small; arm64 works for almost every modern phone)
flutter build apk --release --split-per-abi --dart-define=USE_TEST_ADS=true
# output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# or a single universal APK (bigger)
flutter build apk --release --dart-define=USE_TEST_ADS=true
```
Use `USE_TEST_ADS=true` for APKs you hand out, so nobody clicks your live ads. A release APK still needs `admobAppId` set (see the Gradle guard); for test-only APKs set `admobAppId=ca-app-pub-3940256099942544~3347511713` in `~/.gradle/gradle.properties`.
To install: `adb install app-arm64-v8a-release.apk`, or copy it to the phone and open it.

### 6.3b No powerful laptop?
`.github/workflows/android.yml` builds the signed AAB in GitHub Actions. Secrets needed: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `ADMOB_APP_ID`. Download the AAB from the workflow's artifacts.

### 6.4 Pre-upload checklist
- [ ] `flutter analyze` and `flutter test` pass
- [ ] `USE_TEST_ADS=false`, real ad unit IDs in `AdIds._real`, real `admobAppId`
- [ ] `targetSdk = 36` and Billing 8 verified (step 1.3)
- [ ] Privacy policy and terms URLs live and set in `app_config.dart`
- [ ] Version code higher than the previous upload
- [ ] Tested on a real phone: fresh install, no internet, back button, an ad closed early, a purchase cancelled

---

## 7. Play Console setup (App content)

Create the app: **Create app** > name, language, type **Game**, **Free**, accept the declarations. Then complete **Dashboard > Set up your app**:

| Section | What to answer for this app |
|---|---|
| **Privacy policy** | Your public URL from step 2 |
| **App access** | "All functionality is available without special access" (no login) |
| **Ads** | **Yes, my app contains ads** |
| **Content rating** | Start the IARC questionnaire, category **Game**. Answer honestly: no violence, no user-generated content, no chat. Say the app has in-app purchases and ads. Expect a low rating (for example Everyone / PEGI 3) |
| **Target audience and content** | Choose age groups **13+** (13-15, 16-17, 18 and over). See the note below |
| **Data safety** | See table below |
| **Advertising ID** | **Yes**. Purposes: **Advertising or marketing**, and optionally **Analytics** and **Fraud prevention**. The manifest already has the `AD_ID` permission |
| **Government apps / Financial features / Health / News** | No |
| **Category and tags** | Game > **Puzzle** |
| **Store settings** | Contact email (required), website (recommended, needed for app-ads.txt) |

**Note on children:** a colorful puzzle game can appeal to children. If Google decides your app is directed to children (under 13), the stricter *Families Policy* applies: certified ad networks only, child-directed ad settings, and no personalized ads. This project is built for 13+. Keep your store screenshots, icon and marketing aimed at teens and adults, and choose the target audience honestly. If you want children as an audience, ask me and I will adapt the app (child-directed ad configuration, no Advertising ID).

**Data safety form (how to answer):**
- *Does your app collect or share user data?* **Yes** (because of the ads SDK).
- Google states that the Google Mobile Ads SDK automatically collects and shares **IP address (approximate location), app interactions, diagnostics and device/other identifiers** for advertising, analytics and fraud prevention. Declare those data types as **collected and shared (with Google)**, purposes **Advertising or marketing / Analytics / Fraud prevention**, and mark them **not optional**, unless you decide otherwise.
- *Is all data encrypted in transit?* **Yes** (Google states its SDK traffic is encrypted).
- *Can users request data deletion?* The app has no accounts and stores nothing on a server; your policy explains how.
- Purchases: Google Play handles payments, so you do not declare payment information.
- Always compare with Google's page: developers.google.com/admob/android/play-data-disclosure (it lists the data for the latest SDK version) and update the form whenever you add an SDK.

**Store listing (Grow > Store presence > Main store listing):**
- App name (max 30 characters), short description (max 80), full description (max 4,000). Honest text: no fake ratings, no unrelated keywords.
- **App icon 512x512 PNG**, **feature graphic 1024x500**, **2 to 8 phone screenshots** (16:9 or 9:16). Add a 30 to 60 second gameplay video if you can. Own art only, never screenshots or names from other games.

---

## 8. Testing tracks and going live

1. **Internal testing** (up to 100 testers, no review wait): upload the AAB, add testers, install from the Play link, test IAP with license testers.
2. **Closed testing:** if your personal account was created after 13 Nov 2023 you must run a closed test with **at least 12 testers opted in continuously for 14 days**, then apply for production access in Play Console. The 12 must be real people on real devices (emulators and duplicate accounts do not count). Organization accounts and older personal accounts skip this.
3. **Production:** create a release, upload the AAB, write release notes, use a **staged rollout** (start with 10 to 20 percent), and watch **Android vitals** (crashes, ANRs) for a few days before going to 100 percent.
4. Review takes from a few hours to several days for a new app. Later updates are usually faster.
5. Play Console gives a **pre-launch report** (automatic test on real devices). Fix crashes it finds.

---

## 9. After launch

- Link the app in AdMob and confirm `app-ads.txt` is detected.
- Watch retention (day 1 and day 7), crash-free rate, ad revenue per user, IAP conversion. Targets are in the PRD document.
- If day-1 retention drops after adding interstitials, lower the frequency in `AdRules` (`app_config.dart`).
- Every update: bump the version, keep the same keystore, rebuild with `USE_TEST_ADS=false`, roll out in stages.
- Re-check the Play target-API and Billing deadlines every August.

---

## 10. Every placeholder you must replace

| Where | What |
|---|---|
| `docs/*.html` | Developer name, support email, effective date, country, app name |
| `lib/config/app_config.dart` | `privacyPolicyUrl`, `termsUrl`, `supportEmail`, `AdIds._real` (3 IDs) |
| Gradle property `admobAppId` | Your real AdMob **App ID** (with `~`) |
| Build flag | `--dart-define=USE_TEST_ADS=false` for the store build |
| `android/app/build.gradle.kts` | `applicationId`, `targetSdk = 36`, signing config |
| `AndroidManifest.xml` / `AppConfig.appName` | App name |
| `pubspec.yaml` | `version` (bump before every upload) |
| Play Console | Products with the exact IDs, privacy URL, forms, listing, license testers |
| AdMob | Ad units, consent message, `app-ads.txt` |

## 11. Common rejection and error reasons

| Problem | Fix |
|---|---|
| "Your app targets API 35" | Set `targetSdk = 36` and rebuild |
| "Billing Library version too old" | Use Flutter 3.44+ so `in_app_purchase_android` 0.5+ is used; verify with step 1.3 |
| Missing or broken privacy policy link | Public URL, no login, matches what the app does |
| Data safety form does not match the app | Compare with Google's ads SDK disclosure page and your privacy policy |
| Test ads in production | Build with `USE_TEST_ADS=false`; the Settings screen shows "TEST ADS ENABLED" when they are on |
| Ads do not show | New ad unit (wait), consent message not published, wrong IDs, or no fill |
| Shop shows "Unavailable" | Product not active, wrong ID, not installed from Play, not a license tester |
| Upload rejected: version code already used | Increase the number after `+` in `pubspec.yaml` |
| Wrong signing key | Use the same upload keystore every time |
| "Deceptive" or "impersonation" | Original name, icon and art. Nothing copied from other games |

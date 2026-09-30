# Water Sort --- Color Puzzle

> Production-oriented Android water-sort puzzle game built with
> Flutter + an HTML5 Canvas game runtime.

**Project:** `water_sort_flutter`\
**Package:** `com.shubham.watersort`\
**Primary platform:** Android\
**Target SDK:** 36\
**Minimum SDK:** 24\
**Game content:** Procedurally generated levels\
**Game engine:** HTML5 Canvas 2D + vanilla JavaScript\
**Native shell:** Flutter / Dart

------------------------------------------------------------------------

## 1. Project Purpose

Water Sort is a color-sorting puzzle game.

The player pours colored liquid between bottles until every non-empty
bottle contains only one color.

The project deliberately separates:

-   **Flutter** → app shell, persistence, economy, ads, IAP, navigation,
    settings, themes.
-   **HTML5 Canvas / JavaScript** → puzzle board, bottle state, level
    generation, pouring rules, hints, animation, effects and game loop.
-   **GameBridge** → controlled communication between JavaScript and
    Flutter.

### Golden architecture rule

Flutter is the source of truth for:

-   Coins
-   Level progress
-   Purchases / entitlements
-   Settings
-   Themes / equipped cosmetics
-   Ads and rewarded-ad decisions
-   Persistence

The HTML game can request actions through the bridge, but it should not
become the authoritative store for permanent player economy.

------------------------------------------------------------------------

# 2. High-Level Architecture

``` text
                         ANDROID APP
                              |
                 +------------+------------+
                 |                         |
           Flutter Shell                HTML5 Game
                 |                         |
     +-----------+-----------+       Canvas 2D
     |           |           |       Vanilla JS
   AppState     Ads        IAP            |
     |           |           |            |
   Storage     AdMob     Play Billing     |
     |           |           |            |
     +-----------+-----------+------------+
                 |
            GameBridge
                 |
        FlutterHost JS Channel
                 |
        assets/web/index.html
```

### Flutter owns

-   Home
-   Shop
-   PRO
-   Styles / themes
-   Settings
-   Daily rewards
-   Coin balance
-   Level progression
-   Ad state
-   IAP
-   Persistent save data
-   Native haptics
-   Native banner ad
-   App navigation

### HTML owns

-   Bottle arrays
-   Pouring animation
-   Valid move calculation
-   Level generation
-   Solver
-   Hint selection
-   Mystery-color rendering
-   Timer presentation
-   Canvas drawing
-   Particles / effects
-   Web Audio sound
-   Game input
-   Win / lose presentation

------------------------------------------------------------------------

# 3. Technology Stack

  Layer             Technology
  ----------------- -----------------------------------------------
  App               Flutter
  Language          Dart
  Game              HTML5 Canvas 2D
  Game language     Vanilla JavaScript
  Web container     `webview_flutter`
  Android WebView   `webview_flutter_android`
  Ads               Google Mobile Ads / AdMob
  Consent           Google UMP
  IAP               `in_app_purchase` + `in_app_purchase_android`
  Billing           Google Play Billing
  Storage           `shared_preferences`
  URLs              `url_launcher`
  App information   `package_info_plus`
  Reviews           `in_app_review`
  UI state          `ChangeNotifier` + `ListenableBuilder`
  Service wiring    Static `Services` service locator
  Game sound        Web Audio API
  Game rendering    Canvas 2D
  Haptics           Flutter `HapticFeedback`
  Font              Fredoka Medium/Bold
  Build             Flutter Android App Bundle
  Obfuscation       Flutter `--obfuscate` + split debug info

The project specification chose HTML5 for the game because the mechanics
are simple 2D shapes/tweens and the approach is quick to iterate and
lightweight. Flutter handles native Android concerns such as ads and
billing.

------------------------------------------------------------------------

# 4. Repository Structure

``` text
water_sort_flutter/
│
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
│
├── assets/
│   ├── web/
│   │   ├── index.html
│   │   └── backgrounds/
│   │       ├── candy_dreams.webp
│   │       ├── cosmic_galaxy.webp
│   │       ├── crystal_falls.webp
│   │       ├── golden_sunset.webp
│   │       └── moonlit_haven.webp
│   │
│   └── fonts/
│       ├── Fredoka-Medium.ttf
│       └── Fredoka-Bold.ttf
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── config/
│   │   ├── app_config.dart
│   │   └── economy.dart
│   │
│   ├── models/
│   │   ├── products.dart
│   │   ├── themes.dart
│   │   └── save_data.dart
│   │
│   ├── services/
│   │   ├── app_state.dart
│   │   ├── ads_service.dart
│   │   ├── interstitial_policy.dart
│   │   ├── iap_service.dart
│   │   ├── game_bridge.dart
│   │   ├── storage.dart
│   │   ├── review_service.dart
│   │   ├── telemetry.dart
│   │   └── services.dart
│   │
│   └── ui/
│       ├── home_screen.dart
│       ├── game_screen.dart
│       ├── shop_screen.dart
│       ├── pro_screen.dart
│       ├── themes_screen.dart
│       ├── settings_screen.dart
│       ├── daily_reward_dialog.dart
│       ├── routes.dart
│       ├── theme.dart
│       └── widgets/
│           ├── game_button.dart
│           ├── coin_pill.dart
│           ├── bottle_painter.dart
│           ├── bubble_background.dart
│           ├── banner_ad_view.dart
│           └── screen_scaffold.dart
│
├── test/
├── tool/
│   └── verify_levels.js
│
└── android/
```

### Important economy file

The authoritative economy file is:

``` text
lib/config/economy.dart
```

Do **not** create/use a second `lib/models/economy.dart`.

The project currently imports:

``` dart
import 'package:water_sort/config/economy.dart';
```

from the relevant Flutter services/UI.

------------------------------------------------------------------------

# 5. HTML5 Game Architecture

`assets/web/index.html` is intentionally self-contained.

Main sections:

1.  Host bridge
2.  Difficulty ladder
3.  Level generation
4.  Game state
5.  Puzzle rules
6.  Hint system
7.  Economy / boosts
8.  UI wiring
9.  Sound
10. Input / layout
11. Canvas rendering
12. Animation loop

The game uses:

``` javascript
requestAnimationFrame(...)
```

for continuous rendering and animation.

------------------------------------------------------------------------

# 6. Core Game Data Model

The board is represented as an array of bottles:

``` javascript
bottles = [
  [colorA, colorB, colorB],
  [colorC, colorA],
  [],
  []
];
```

A bottle is an array of color indices.

Important:

-   Bottom of bottle = index `0`
-   Top of bottle = last array element
-   `CAP` = maximum units per bottle
-   Empty bottle = `[]`

Example:

``` text
Bottle:
bottom → RED
         BLUE
         BLUE ← top
```

JavaScript:

``` javascript
['RED', 'BLUE', 'BLUE']
```

------------------------------------------------------------------------

# 7. Pouring Algorithm

The fundamental rule is `canPour(a, b)`.

A move is valid when:

1.  Source and destination are different.
2.  Source is not empty.
3.  Destination is not full.
4.  Destination is either empty or has the same top color.
5.  Only the contiguous top run of the source color is moved.

Conceptually:

``` javascript
if source empty:
    invalid

if destination full:
    invalid

if destination has different top color:
    invalid

count contiguous matching top units
move min(run, destination free capacity)
```

This is standard Water Sort behavior.

------------------------------------------------------------------------

# 8. Solved-State Algorithm

A bottle is complete when:

``` javascript
a.length === CAP
```

and every unit has the same color.

Conceptually:

``` javascript
isDone(a) =
    a.length === CAP
    AND
    every color equals a[0]
```

The level is won when all bottles satisfy the solved condition or the
game-specific completion condition.

------------------------------------------------------------------------

# 9. Level Generation --- Most Important Algorithm

The project does **not** ship hundreds of manually authored level files.

Levels are generated procedurally.

There are two main generation strategies.

## 9.1 Reverse-Walk Generator

Used for:

-   Early levels
-   Levels with only one empty bottle
-   Fallback generation

### Principle

Start from a completely solved board.

Then perform legal **reverse pours**.

Because every generated state is reachable from a solved state by
reversing legal operations, the resulting puzzle has a known solution
path.

Conceptually:

``` text
Solved board
     ↓
Reverse move
     ↓
Mixed board
     ↓
Reverse move
     ↓
More mixed board
     ↓
Playable puzzle
```

### Why this guarantees solvability

If:

``` text
Solved → A → B → C
```

was created by valid reverse operations, then:

``` text
C → B → A → Solved
```

is a valid solution path.

Therefore the generator cannot accidentally create an impossible state
when using this construction.

### Mixing

Moves that place a unit on a different color are weighted more heavily
to create more mixed puzzles.

Multiple candidates can be generated and the more mixed candidate
selected.

------------------------------------------------------------------------

# 10. Random Deal + Solver

For later levels with two empty bottles, the game can generate a random
distribution and then verify it.

Process:

``` text
Generate random color distribution
          ↓
Reject obviously bad layout
          ↓
Run solver
          ↓
Solvable?
   ┌──────┴──────┐
  YES            NO
   |              |
Accept        Try another
```

The solver uses depth-first search with move ordering and a node limit.

The documented design uses:

-   Up to 30,000 solver nodes
-   Multiple random attempts
-   Fallback to reverse-walk generation

This gives harder, more random levels without sacrificing solvability.

------------------------------------------------------------------------

# 11. Deterministic Level Seeds

Level generation uses a seeded PRNG.

The documented generator uses `mulberry32` with the level number as the
seed.

This gives:

``` text
Level 1 → same generated layout
Level 2 → same generated layout
Level 100 → same generated layout
```

assuming the generator code and parameters remain unchanged.

### Why this matters

-   Bugs can be reproduced.
-   Players can receive deterministic levels.
-   QA can report a specific level.
-   Level generation does not require hundreds of stored files.

Changing generator logic can change the resulting boards, so generator
changes should be treated as gameplay-content changes.

------------------------------------------------------------------------

# 12. Mystery Levels

Mystery levels hide some colors.

A per-bottle value:

``` javascript
hid[i]
```

tracks the number of hidden units.

The hidden count changes only when the affected bottle is touched by a
pour or reaches a reveal condition.

Important invariant:

> A bottle that was not touched by a move must not randomly
> reveal/change its hidden count.

This has been specifically regression-tested in the project's level
verification work.

------------------------------------------------------------------------

# 13. Difficulty Ladder

The difficulty system is centralized in:

``` javascript
params(level)
```

It controls parameters such as:

-   Number of colors
-   Number of empty bottles
-   Mystery mode
-   Timed mode
-   Bottle capacity
-   Undo count
-   Difficulty tier

Documented progression includes:

``` text
Colors:
4 at level 1
increase progressively
up to 12+

Empty bottles:
normally 2
reduced at later difficulty stages

Mystery:
starts early
becomes more frequent later

Timed:
starts from later levels

Capacity:
4 initially
5+
6+
and later larger capacities
```

The exact current tuning should always be read from `params()` in the
active `index.html`, because this is intentionally a balancing point.

------------------------------------------------------------------------

# 14. Timed-Level Algorithm

The documented timer formula is approximately:

``` text
round(
    (40 + colors × 12 + capacity × 6)
    × max(0.7, 1 - (level - 40) × 0.003)
)
```

The formula is tunable.

Timed levels are activated by the difficulty ladder.

When time reaches zero:

``` text
Level lost
    ↓
Retry
OR
+30 seconds
OR
Skip
```

------------------------------------------------------------------------

# 15. Hint Algorithm

The hint system does not randomly select a move.

It evaluates legal moves.

`findHint()` scores candidate moves.

Factors include:

-   Amount poured
-   Pouring into a non-empty matching bottle
-   Completing a bottle
-   Emptying the source
-   Mystery-related value

The highest-scoring legal move is returned.

Conceptually:

``` text
for every source:
    for every destination:
        if move is legal:
            calculate score
            keep highest score
```

### Important current economy

Per level:

``` text
Hint #1 → 100 coins
Hint #2 → 100 coins
Hint #3+ → rewarded ad
```

The first two uses reset when a new level starts.

The third and later hints do not use coins; they require a rewarded ad.

------------------------------------------------------------------------

# 16. Extra Bottle Algorithm

Extra bottles are added dynamically:

``` javascript
bottles.push([]);
```

Supporting visual arrays are also extended:

``` text
hid
lift
wob
shake
corkT
done
appear
```

so rendering and animation remain synchronized.

### Current economy

Per level:

``` text
Bottle #1 → 100 coins
Bottle #2 → 100 coins
Bottle #3+ → rewarded ad
```

The first two paid uses reset on a new level.

------------------------------------------------------------------------

# 17. Important Economy Rule

The Flutter economy source is:

``` text
lib/config/economy.dart
```

Current requested prices:

``` text
Hint             100 coins
Extra bottle     100 coins
Undo pack         40 coins
+30 seconds       50 coins
Skip level       150 coins
```

Current daily rewards:

``` text
50
75
100
150
200
300
500
```

Current rewarded free-coin source is documented as:

``` text
200 coins
```

Do not change economy values in the HTML alone.

The Flutter economy should remain the source of truth.

------------------------------------------------------------------------

# 18. Coin Flow

Typical coin sources:

-   Level completion
-   Daily reward
-   Rewarded free coins
-   Certain bonuses
-   IAP coin packs

Typical coin sinks:

-   Hint
-   Extra bottle
-   Undo pack
-   Extra time
-   Skip level
-   Cosmetic items

The game requests coin operations from Flutter:

``` text
Game
  ↓
coins.spend
  ↓
Flutter AppState
  ↓
validate balance
  ↓
persist
  ↓
reply with result
```

This prevents the HTML page from being the permanent authority over the
balance.

------------------------------------------------------------------------

# 19. Undo System

Game state snapshots are serialized:

``` javascript
JSON.stringify({
    b: bottles,
    h: hid
})
```

Before a reversible action, a snapshot is pushed into history.

Undo:

``` text
history.pop()
    ↓
restore(snapshot)
    ↓
rebuild visual state
    ↓
layout()
```

PRO can have unlimited undo behavior according to the PRO configuration.

------------------------------------------------------------------------

# 20. GameBridge

Communication uses a JavaScript channel:

``` text
FlutterHost
```

Game → Flutter:

``` javascript
window.FlutterHost.postMessage(
    JSON.stringify({
        id,
        type,
        payload
    })
)
```

Flutter can reply through:

``` javascript
window.__hostReply(id, result)
```

Flutter → Game events use:

``` javascript
window.__hostEvent(name, data)
```

------------------------------------------------------------------------

# 21. Main Bridge Commands

Documented commands include:

  Command              Purpose
  -------------------- -----------------------------------
  `boot`               Send complete initial state
  `ready`              Game finished initialization
  `coins.add`          Add coins
  `coins.spend`        Spend coins
  `progress.level`     Update level progress
  `ads.interstitial`   Request interstitial
  `ads.rewarded`       Request rewarded ad
  `nav`                Navigate to Home / Shop / PRO
  `settings.muted`     Change sound setting
  `kv.set`             Persist small game key/value data
  `haptic`             Trigger native haptic
  `analytics`          Telemetry event
  `review.maybe`       Rating prompt
  `log`                Debug logging

Rewarded responses can indicate:

``` text
rewarded
unavailable
dismissed
failed
```

------------------------------------------------------------------------

# 22. Flutter AppState

`AppState` is the main native source of truth.

It manages:

-   Coins
-   Current/highest level
-   No Ads
-   PRO
-   Haptics
-   Themes
-   Daily reward
-   Purchase tokens
-   Small game KV state

Important principles:

-   Coin spending is atomic.
-   Level progress moves forward.
-   Changes are persisted.
-   Purchase tokens prevent duplicate purchase grants.

------------------------------------------------------------------------

# 23. Persistence

Storage uses:

``` text
shared_preferences
```

The documented save keys are:

``` text
save_v1
save_v1_bak
```

The save structure contains:

``` text
v
coins
level
muted
haptics
noAds
pro
owned
skin
bg
streak
lastDaily
processed
kv
sessions
```

### Backup behavior

Load sequence:

``` text
Primary save
    ↓
if invalid:
Backup save
    ↓
if invalid:
Defaults
```

When changing save structure:

1.  Increment schema version.
2.  Update `fromJson`.
3.  Preserve backward compatibility where possible.

------------------------------------------------------------------------

# 24. Ads Architecture

AdMob is native Flutter functionality.

Ads are not implemented directly inside the HTML game.

## Ad types

### Banner

Native Flutter `BannerAdView`.

Current architecture:

``` text
Flutter screen
     |
     +--- WebView game
     |
     +--- native BannerAdView
```

The banner implementation uses controlled loading and retry/backoff
rather than aggressive request loops.

Banner telemetry tracks:

-   loaded
-   failed
-   impression
-   mediation adapter / response information

### Interstitial

Used between levels according to `InterstitialPolicy`.

Important protection rules:

-   Not immediately at app launch.
-   First-level protection.
-   Frequency control.
-   Cooldown.
-   Not shown when Remove Ads / PRO applies.
-   Game waits for native ad decision.

### Rewarded

Rewarded placements include:

``` text
hint
bottle
undo
time
skip
double_coins
daily_double
free coins
```

The current hint/bottle economy specifically uses rewarded ads after the
first two coin-paid uses.

------------------------------------------------------------------------

# 25. AdMob IDs

Configured production identifiers:

``` text
App ID:
ca-app-pub-2427221337462218~1343049941

Banner:
ca-app-pub-2427221337462218/4381110971

Interstitial:
ca-app-pub-2427221337462218/6139633948

Rewarded:
ca-app-pub-2427221337462218/5948062259
```

`app-ads.txt`:

``` text
google.com, pub-2427221337462218, DIRECT, f08c47fec0942fa0
```

Hosted at:

``` text
https://taskguru.site/app-ads.txt
```

### Testing rule

Never click live production ads while testing.

Use test ads or a registered test device during development.

Production release uses:

``` powershell
--dart-define=USE_TEST_ADS=false
```

------------------------------------------------------------------------

# 26. Consent / UMP

Ads use Google User Messaging Platform consent handling.

General sequence:

``` text
App start
    ↓
Gather consent
    ↓
Check whether ads may request
    ↓
Initialize Mobile Ads SDK
    ↓
Preload interstitial/rewarded
    ↓
Banner loads when needed
```

Privacy options can be opened from the relevant settings flow.

------------------------------------------------------------------------

# 27. In-App Purchases

Product catalog:

  Product ID     Type               Price
  -------------- ---------------- -------
  `remove_ads`   Non-consumable      ₹149
  `pro_pass`     Non-consumable      ₹349
  `coins_500`    Consumable           ₹29
  `coins_1500`   Consumable           ₹79
  `coins_5000`   Consumable          ₹199

### PRO concept

PRO provides premium gameplay benefits such as:

-   No ads
-   Unlimited undos
-   Double coin rewards
-   Other premium perks defined in the product catalog

The exact PRO behavior should always be checked against:

``` text
lib/models/products.dart
lib/services/app_state.dart
assets/web/index.html
```

------------------------------------------------------------------------

# 28. Purchase Safety

Purchase processing uses purchase tokens to avoid double granting.

Persistent purchase records are stored in the save model.

The architecture includes a `PurchaseVerifier` hook.

Default behavior trusts the Google Play store result; a future backend
can replace the verifier for server-side validation.

### Important future improvement

For consumables, grant + consume + processed-token persistence should
remain carefully ordered so a crash cannot permanently lose a purchased
pack.

------------------------------------------------------------------------

# 29. Themes and Backgrounds

Themes are defined in:

``` text
lib/models/themes.dart
```

Flutter sends theme information to the HTML game.

Background assets currently include:

``` text
assets/web/backgrounds/candy_dreams.webp
assets/web/backgrounds/cosmic_galaxy.webp
assets/web/backgrounds/crystal_falls.webp
assets/web/backgrounds/golden_sunset.webp
assets/web/backgrounds/moonlit_haven.webp
```

The HTML game supports:

``` javascript
bg.assetPath
```

with a gradient fallback.

### Important

Do not hard-code the theme catalog separately inside the HTML game.

Flutter should remain the source of truth for equipped themes.

------------------------------------------------------------------------

# 30. Canvas Rendering

The game uses Canvas 2D.

The rendering system draws:

-   Bottle glass
-   Liquid
-   Liquid surface
-   Highlights
-   Cork / neck
-   Glow
-   Particles
-   Confetti
-   Floating reward text
-   Hint indicators
-   Background effects

Liquid is rendered in world space so it remains visually level while a
bottle rotates.

This is important for polished pouring animation.

------------------------------------------------------------------------

# 31. Animation System

Visual state arrays include concepts such as:

``` text
lift
wob
shake
corkT
appear
done
```

A pour generally follows:

``` text
Select source
    ↓
Select destination
    ↓
Validate canPour
    ↓
Save history
    ↓
Animate bottle
    ↓
Transfer liquid
    ↓
Update hidden state
    ↓
Recalculate solved state
    ↓
Check win / no-move condition
```

`busy` prevents conflicting input during animations.

------------------------------------------------------------------------

# 32. Sound

Sound is generated using the Web Audio API.

No large audio-file dependency is required for the core game.

Sound effects include concepts such as:

``` text
tone
sfx
sfxPour
sfxWin
```

Audio is unlocked after a user interaction because browser/WebView audio
policies require user activation.

------------------------------------------------------------------------

# 33. Haptics

Haptics are controlled from Flutter.

The HTML game requests:

``` text
haptic
```

through the GameBridge.

Flutter uses native:

``` text
HapticFeedback
```

This is preferred over relying on:

``` javascript
navigator.vibrate
```

inside WebView.

------------------------------------------------------------------------

# 34. Browser / Chrome Behavior

The real game is an Android WebView game.

Flutter Web / Chrome does not provide the same WebView platform
implementation.

Therefore the GameScreen has a web-platform guard so Chrome does not
call unsupported methods such as:

``` dart
setJavaScriptMode(...)
```

### Expected behavior

``` text
Chrome
  ↓
Android Version Required / development fallback

Android
  ↓
Actual WebView game
```

Do not remove the Android WebView configuration merely to make Chrome
run.

------------------------------------------------------------------------

# 35. GameScreen

`GameScreen`:

-   Creates WebView controller.
-   Configures JavaScript.
-   Adds `FlutterHost`.
-   Blocks remote navigation.
-   Loads bundled `assets/web/index.html`.
-   Attaches `GameBridge`.
-   Shows loading state.
-   Shows WebView errors.
-   Shows native banner beneath game.
-   Handles Android back button.
-   Handles app lifecycle pause/resume.

Remote content should not be loaded by the game.

------------------------------------------------------------------------

# 36. Security / Trust Boundaries

The game page is local.

Navigation should remain blocked except for allowed local/data content.

Flutter validates bridge inputs.

Especially validate:

``` text
coin amounts
level numbers
product IDs
reward placements
navigation targets
```

Never allow JavaScript to directly modify the permanent Flutter coin
balance.

------------------------------------------------------------------------

# 37. Release Build

Production AAB command:

``` powershell
flutter build appbundle --release --dart-define=USE_TEST_ADS=false --obfuscate --split-debug-info=build/symbols
```

AAB output:

``` text
build/app/outputs/bundle/release/app-release.aab
```

------------------------------------------------------------------------

# 38. Development Commands

### Install dependencies

``` powershell
flutter pub get
```

### Clean build

``` powershell
flutter clean
flutter pub get
```

### Analyze

``` powershell
flutter analyze
```

### Run on Android device

``` powershell
flutter run
```

### Release AAB

``` powershell
flutter build appbundle --release --dart-define=USE_TEST_ADS=false --obfuscate --split-debug-info=build/symbols
```

### Dependency audit

``` powershell
flutter pub outdated
```

Do not blindly upgrade all packages. Upgrade deliberately and retest.

------------------------------------------------------------------------

# 39. Current Analyzer Status

At the latest development check, the analyzer reported only two
informational lint items:

``` text
unnecessary_const
use_null_aware_elements
```

These are not runtime failures.

There was also a message that some packages have newer versions
incompatible with the current dependency constraints.

That is not itself a build failure.

Before a production release, run:

``` powershell
flutter analyze
flutter test
flutter build appbundle --release ...
```

and resolve any actual errors.

------------------------------------------------------------------------

# 40. Testing Strategy

## Level generator

The project has:

``` text
tool/verify_levels.js
```

The documented verification includes:

-   Valid unit counts
-   Determinism
-   Solvability
-   Performance
-   Mystery-level constraints
-   No pre-solved bottles where prohibited

The project documentation records successful generator verification.

## Mystery regression

Randomized playthrough tests verify that an untouched bottle does not
unexpectedly change its hidden count.

## Game bridge

The documented jsdom/fake-host test suite covers:

-   Win flow
-   Coins
-   Rewarded ads
-   Interstitials
-   Boosts
-   PRO live upgrade
-   Skip
-   Timed loss
-   Extra time
-   Back
-   Pause
-   Resume

## Flutter tests

The project contains tests for:

-   Interstitial policy
-   AppState
-   Daily reward
-   Save round-trip
-   Themes

Run:

``` powershell
flutter test
```

------------------------------------------------------------------------

# 41. Manual Release QA Checklist

Before uploading a production AAB:

### Fresh install

-   [ ] App starts
-   [ ] Home loads
-   [ ] Play opens game
-   [ ] Level 1 loads
-   [ ] No red Flutter error screen
-   [ ] Coins display correctly
-   [ ] Hint starts at 2
-   [ ] Extra bottle starts at 2

### Gameplay

-   [ ] Pour valid move
-   [ ] Invalid move rejected
-   [ ] Undo works
-   [ ] Restart works
-   [ ] Hint works
-   [ ] First hint deducts 100 coins
-   [ ] Second hint deducts 100 coins
-   [ ] Third hint requests rewarded ad
-   [ ] First bottle costs 100 coins
-   [ ] Second bottle costs 100 coins
-   [ ] Third bottle requests rewarded ad
-   [ ] Win screen works
-   [ ] Next level works
-   [ ] Level progression persists

### Ads

-   [ ] Banner loads
-   [ ] Banner does not spam requests
-   [ ] Interstitial policy respected
-   [ ] Rewarded loads
-   [ ] Rewarded dismissal does not grant reward
-   [ ] Rewarded success grants reward
-   [ ] Remove Ads hides applicable ads
-   [ ] PRO hides applicable ads

### IAP

-   [ ] Products load
-   [ ] Purchase succeeds
-   [ ] Cancel works
-   [ ] Pending works
-   [ ] Restore works
-   [ ] Consumables are not double-granted
-   [ ] PRO entitlement persists

### Persistence

-   [ ] Kill/reopen app
-   [ ] Coins remain
-   [ ] Level remains
-   [ ] Themes remain
-   [ ] PRO remains
-   [ ] Remove Ads remains
-   [ ] Daily reward state remains

### Device/lifecycle

-   [ ] Back button
-   [ ] App background/foreground
-   [ ] Screen rotation behavior
-   [ ] Low-memory device
-   [ ] Poor/no internet
-   [ ] Ad unavailable
-   [ ] WebView failure
-   [ ] Timed level while app is backgrounded

------------------------------------------------------------------------

# 42. Android Release Signing

Release signing uses the upload keystore.

Important files/settings:

``` text
android/key.properties
android/app/
```

`key.properties` and keystore files must remain outside Git.

### Never commit

``` text
*.jks
key.properties
passwords
API secrets
private credentials
```

Back up the upload keystore securely.

If the upload keystore is lost, future Play uploads can become a serious
problem.

------------------------------------------------------------------------

# 43. AdMob / Play Console Release Requirements

Before production:

-   [ ] Real AdMob App ID
-   [ ] Real banner ID
-   [ ] Real interstitial ID
-   [ ] Real rewarded ID
-   [ ] app-ads.txt reachable
-   [ ] UMP consent flow
-   [ ] Privacy policy
-   [ ] Data Safety form
-   [ ] Ads declaration
-   [ ] IAP products active
-   [ ] Billing tested with license testers
-   [ ] Store listing completed
-   [ ] Screenshots
-   [ ] Feature graphic
-   [ ] App icon
-   [ ] Content rating
-   [ ] Target SDK 36
-   [ ] Closed testing requirements completed

------------------------------------------------------------------------

# 44. Current Monetization Model

## Free player

``` text
Gameplay
  ↓
Level reward
  ↓
Coins
  ↓
Spend on boosts/cosmetics
```

Boosts:

``` text
Hint #1       100 coins
Hint #2       100 coins
Hint #3+      Rewarded ad

Bottle #1     100 coins
Bottle #2     100 coins
Bottle #3+    Rewarded ad
```

## PRO player

PRO is designed to reduce advertising friction and increase convenience.

Documented benefits include:

``` text
No ads
Unlimited undos
Double coin rewards
Other premium benefits defined in products.dart
```

------------------------------------------------------------------------

# 45. Economy Design Principles

The economy should remain understandable.

Rules:

1.  Never silently deduct coins.
2.  Always show the cost before spending.
3.  Rewarded ads should clearly state the reward.
4.  Failed ads must not grant rewards.
5.  Purchases must not double-grant.
6.  New levels reset the per-level hint/bottle counters.
7.  Do not create unlimited coin-generation exploits.
8.  Flutter remains authoritative for persistent coins.
9.  Balance changes should be made centrally in
    `lib/config/economy.dart`.

------------------------------------------------------------------------

# 46. Common Bugs and Their Causes

## `setJavaScriptMode is not implemented`

Cause:

Flutter Web / Chrome does not implement the native WebView operation.

Fix:

Keep WebView operations behind:

``` dart
if (!kIsWeb) {
   ...
}
```

------------------------------------------------------------------------

## Hint showing 0 at Level 1

Cause:

Per-level hint counter was initialized incorrectly.

Correct:

``` text
2 hints at level start
```

Then:

``` text
2 → 1 → 0 → AD
```

------------------------------------------------------------------------

## Extra bottle counter

Correct:

``` text
2 → 1 → 0 → AD
```

------------------------------------------------------------------------

## `getCurrentOrientationAnchoredAdaptiveBannerAdSize` deprecated

Use the current large anchored adaptive API in the banner
implementation.

The banner implementation should also dispose failed ads and use
controlled retry/backoff.

------------------------------------------------------------------------

## Analyzer `info` messages

Examples:

``` text
unnecessary_const
use_null_aware_elements
```

These are code-quality lint messages, not runtime crashes.

------------------------------------------------------------------------

# 47. Future Feature Development Rules

When adding a new feature:

### If it affects permanent state

Implement it in Flutter first.

Example:

``` text
New currency
New purchase
New entitlement
New progression
New setting
```

### If it affects puzzle mechanics

Implement it in HTML.

Example:

``` text
New bottle rule
New puzzle modifier
New visual effect
New hint scoring
```

### If both sides need it

Add a GameBridge command.

Pattern:

``` text
HTML
  ↓
Host.call/post
  ↓
GameBridge.handle
  ↓
Flutter service
  ↓
reply/event
  ↓
HTML
```

Also update `MockHost` so Chrome development continues to work.

------------------------------------------------------------------------

# 48. How to Add a New Game Feature

Recommended workflow:

``` text
1. Define state
2. Decide authoritative owner
3. Add bridge message if needed
4. Add MockHost support
5. Implement feature
6. Add telemetry
7. Add tests
8. Test Android
9. Test lifecycle
10. Test release AAB
```

Never make a large change to the level generator without rerunning the
level verifier.

------------------------------------------------------------------------

# 49. How to Modify Difficulty

Primary location:

``` text
assets/web/index.html
```

Find:

``` javascript
params(level)
```

Modify:

-   colors
-   bottle capacity
-   empty bottles
-   mystery frequency
-   timed frequency
-   undo counts

After modification:

``` text
Run level verification
        ↓
Check solvability
        ↓
Check mystery constraints
        ↓
Play sample levels
        ↓
Build Android
```

------------------------------------------------------------------------

# 50. How to Modify Win Rewards

Primary location:

``` text
assets/web/index.html
```

Find the win handler, documented as:

``` javascript
onWin()
```

Do not duplicate reward calculations in Flutter unless the architecture
is intentionally changed.

If rewards affect permanent coins, the final coin mutation must still go
through Flutter.

------------------------------------------------------------------------

# 51. How to Modify Prices

Primary location:

``` text
lib/config/economy.dart
```

Current key values:

``` dart
hint = 100;
extraBottle = 100;
undoPack = 40;
extraTime = 50;
skipLevel = 150;
```

Do not create a second economy file.

After changing:

``` powershell
flutter analyze
flutter test
flutter run
```

Then verify the actual in-game displayed price.

------------------------------------------------------------------------

# 52. Performance Principles

The target is a low/mid-range Android phone.

Important rules:

-   Avoid unnecessary WebView reloads.
-   Avoid allocating large objects every animation frame.
-   Reuse visual arrays.
-   Keep canvas drawing efficient.
-   Keep effects bounded.
-   Do not spam bridge messages.
-   Do not aggressively retry ads.
-   Dispose native ads correctly.
-   Avoid large image assets where possible.
-   Use compressed WebP backgrounds.
-   Avoid unnecessary Flutter rebuilds.

------------------------------------------------------------------------

# 53. Background Asset Rules

Backgrounds are bundled locally.

Current files:

``` text
candy_dreams.webp
cosmic_galaxy.webp
crystal_falls.webp
golden_sunset.webp
moonlit_haven.webp
```

Recommended:

-   WebP
-   Portrait-friendly
-   Optimized file size
-   No text baked into the image
-   Keep important visual detail away from HUD areas
-   Test on 9:16 devices

------------------------------------------------------------------------

# 54. Git Rules

Commit source code, not secrets.

Recommended:

``` text
git add lib/
git add assets/
git add android/
git add pubspec.yaml
```

Do not commit:

``` text
android/key.properties
*.jks
private API keys
local credentials
build/
```

Before a major release:

``` powershell
git status
git diff
```

Review all modified files.

------------------------------------------------------------------------

# 55. Versioning

Flutter version format:

``` text
version: MAJOR.MINOR.PATCH+BUILD
```

Example:

``` text
1.0.3+4
```

For every Play upload:

-   Increase build number.
-   Keep version semantics meaningful.
-   Never reuse an already uploaded Play version code.

------------------------------------------------------------------------

# 56. Release Workflow

Recommended final workflow:

``` text
                 CODE CHANGE
                      |
                      v
              flutter analyze
                      |
                      v
                flutter test
                      |
                      v
             Manual Android QA
                      |
                      v
              Build release AAB
                      |
                      v
              Internal testing
                      |
                      v
               Closed testing
                      |
                      v
              Production release
```

Production command:

``` powershell
flutter build appbundle --release --dart-define=USE_TEST_ADS=false --obfuscate --split-debug-info=build/symbols
```

------------------------------------------------------------------------

# 57. Debugging Checklist

When something breaks:

### Game does not open

Check:

``` text
GameScreen
WebView
GameBridge
assets/web/index.html
```

### Game opens but Flutter state is wrong

Check:

``` text
GameBridge
AppState
Storage
```

### Coins wrong

Check:

``` text
lib/config/economy.dart
AppState
GameBridge coins.spend
GameBridge coins.add
```

### Hint wrong

Check:

``` text
useHint()
findHint()
resetBoosts()
Economy.hint
```

### Bottle wrong

Check:

``` text
addBottle()
resetBoosts()
Economy.extraBottle
```

### Rewarded ad does not show

Check:

``` text
AdsService
rewarded preload
consent
AdMob ID
test device
placement
```

### Banner does not show

Check:

``` text
BannerAdView
AdMob banner ID
consent readiness
load error
responseInfo
```

### Purchase does not work

Check:

``` text
IapService
product IDs
Play Console product status
license tester
purchase stream
processed tokens
```

------------------------------------------------------------------------

# 58. Important Current Project Decisions

These decisions should not be accidentally reversed:

### Game engine

``` text
HTML5 Canvas + vanilla JavaScript
```

Not Unity, Godot or Three.js.

### Native shell

``` text
Flutter
```

### Android only

Production game target is Android.

### Level generation

``` text
Seeded procedural generation
+
solvability verification
```

### Persistent economy

``` text
Flutter AppState
```

### Hint economy

``` text
2 coin-paid hints / level
100 coins each
3rd+ requires rewarded ad
```

### Bottle economy

``` text
2 coin-paid extra bottles / level
100 coins each
3rd+ requires rewarded ad
```

### Themes

Flutter-owned catalog + local WebP backgrounds.

------------------------------------------------------------------------

# 59. Known Development Notes

The project has intentionally accumulated several compatibility fixes.

### Web platform

Chrome cannot run native WebView operations. The GameScreen must guard
native WebView configuration using `kIsWeb`.

### Analyzer

Minor informational lints may remain if they do not affect runtime/build
behavior.

### Dependencies

Do not upgrade packages simply because `flutter pub outdated` reports
newer incompatible versions.

First determine whether the upgrade is needed, then upgrade and test.

### Ads

Do not attempt to inflate ad requests through aggressive retry loops.
Low match rate and low show rate are different problems.

------------------------------------------------------------------------

# 60. Long-Term Roadmap

Possible future improvements:

1.  More sophisticated level difficulty scoring.
2.  Independent shortest-solution / optimality analysis.
3.  Better hint ranking using solver look-ahead.
4.  Server-side purchase verification.
5.  Crash reporting backend.
6.  Remote economy configuration.
7.  A/B testing of rewards.
8.  Cloud save.
9.  Achievements.
10. Leaderboards.
11. More bottle skins.
12. More background packs.
13. Seasonal events.
14. Daily challenge.
15. Weekly challenge.
16. Level editor for internal QA.
17. Automated Android device testing.
18. Performance profiling on low-end devices.
19. More robust WebView asset loading.
20. Automated release pipeline.

------------------------------------------------------------------------

# 61. One-Page Maintenance Reference

## Change prices

``` text
lib/config/economy.dart
```

## Change level difficulty

``` text
assets/web/index.html
params()
```

## Change level generator

``` text
assets/web/index.html
genLevel()
genWalk()
dealRandom()
solvable()
```

## Change hint behavior

``` text
assets/web/index.html
findHint()
useHint()
```

## Change extra bottle

``` text
assets/web/index.html
addBottle()
```

## Change ads

``` text
lib/config/app_config.dart
lib/services/ads_service.dart
lib/ui/widgets/banner_ad_view.dart
```

## Change purchases

``` text
lib/models/products.dart
lib/services/iap_service.dart
lib/services/app_state.dart
```

## Change persistence

``` text
lib/models/save_data.dart
lib/services/storage.dart
lib/services/app_state.dart
```

## Change bridge

``` text
lib/services/game_bridge.dart
assets/web/index.html
```

## Change themes

``` text
lib/models/themes.dart
lib/ui/themes_screen.dart
assets/web/backgrounds/
```

## Change native game screen

``` text
lib/ui/game_screen.dart
```

------------------------------------------------------------------------

# 62. Final Architecture Principle

The most important rule for future development is:

``` text
                 FLUTTER
                    |
        +-----------+-----------+
        |           |           |
      STATE        ADS         IAP
        |           |           |
     STORAGE      ADMOB     PLAY BILLING
        |
        |
   GAME BRIDGE
        |
        v
       HTML
        |
   +----+----+
   |         |
 PUZZLE    RENDER
 LOGIC     EFFECTS
```

**Permanent truth belongs to Flutter.**

**Puzzle simulation and visuals belong to HTML.**

**Communication belongs to GameBridge.**

**Every new feature should respect that boundary.**

------------------------------------------------------------------------

## Source / Design Reference

The project architecture and technical design are based on the project's
existing `Water_Sort_PRD_and_Tech_Stack.md`, current Flutter structure,
and subsequent implementation changes.

When this README conflicts with actual source code, **the current source
code is authoritative**. Update this README whenever architecture,
economy, product IDs, difficulty rules, or release configuration
changes.

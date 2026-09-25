import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:water_sort/app.dart';
import 'package:water_sort/services/ads_service.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/iap_service.dart';
import 'package:water_sort/services/review_service.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/services/storage.dart';
import 'package:water_sort/services/telemetry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never let an uncaught error kill the app silently: report it.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Telemetry.error(details.exception, details.stack, reason: 'flutter');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    Telemetry.error(error, stack, reason: 'platform');
    return true;
  };

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storage = await Storage.open();
  final state = AppState(storage, storage.load())..noteSession();
  final ads = AdsService(state);
  final iap = IapService(state);
  Services.register(state: state, ads: ads, iap: iap, review: ReviewService(state));

  runApp(const WaterSortApp());

  // Heavy work after the first frame so the app opens instantly.
  unawaited(ads.init());
  unawaited(iap.init());
}

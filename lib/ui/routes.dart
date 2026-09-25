import 'package:flutter/material.dart';
import 'package:water_sort/ui/game_screen.dart';
import 'package:water_sort/ui/pro_screen.dart';
import 'package:water_sort/ui/settings_screen.dart';
import 'package:water_sort/ui/shop_screen.dart';
import 'package:water_sort/ui/themes_screen.dart';

Future<T?> _push<T>(BuildContext c, Widget page) =>
    Navigator.of(c).push<T>(MaterialPageRoute<T>(builder: (_) => page));

Future<void> pushGame(BuildContext c) => _push<void>(c, const GameScreen());
Future<void> pushShop(BuildContext c) => _push<void>(c, const ShopScreen());
Future<void> pushPro(BuildContext c) => _push<void>(c, const ProScreen());
Future<void> pushThemes(BuildContext c) => _push<void>(c, const ThemesScreen());
Future<void> pushSettings(BuildContext c) => _push<void>(c, const SettingsScreen());

import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

const String _waterSortViewType = 'water-sort-html-game';

bool _registered = false;

void registerWebGameView() {
  if (_registered) return;

  ui_web.platformViewRegistry.registerViewFactory(
    _waterSortViewType,
    (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = 'assets/assets/web/index.html'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..setAttribute('allow', 'autoplay; fullscreen')
        ..setAttribute('title', 'Water Sort Game');

      return iframe;
    },
  );

  _registered = true;
}

Widget buildWebGameView() {
  return const HtmlElementView(
    viewType: _waterSortViewType,
  );
}

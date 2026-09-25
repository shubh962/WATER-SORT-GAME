import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/screen_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    unawaited(PackageInfo.fromPlatform().then((PackageInfo i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    }));
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Settings',
      showCoins: false,
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[Services.state, Services.ads]),
        builder: (BuildContext context, Widget? _) {
          final s = Services.state;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              _Group(children: <Widget>[
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Sound', style: kBody),
                  value: !s.muted,
                  onChanged: (bool v) => s.setMuted(!v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Haptics', style: kBody),
                  value: s.haptics,
                  onChanged: s.setHaptics,
                ),
              ]),
              const SizedBox(height: 14),
              _Group(children: <Widget>[
                if (Services.ads.privacyOptionsRequired)
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_rounded),
                    title: const Text('Ad privacy settings', style: kBody),
                    onTap: () => unawaited(Services.ads.showPrivacyOptions()),
                  ),
                ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: const Text('Restore purchases', style: kBody),
                  onTap: () => unawaited(Services.iap.restore()),
                ),
                ListTile(
                  leading: const Icon(Icons.star_rounded),
                  title: const Text('Rate the game', style: kBody),
                  onTap: () => unawaited(Services.review.openStore()),
                ),
              ]),
              const SizedBox(height: 14),
              _Group(children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: const Text('Privacy policy', style: kBody),
                  onTap: () => unawaited(_open(AppConfig.privacyPolicyUrl)),
                ),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded),
                  title: const Text('Terms of service', style: kBody),
                  onTap: () => unawaited(_open(AppConfig.termsUrl)),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_rounded),
                  title: const Text('Contact support', style: kBody),
                  onTap: () => unawaited(_open('mailto:${AppConfig.supportEmail}?subject=${Uri.encodeComponent('${AppConfig.appName} support')}')),
                ),
              ]),
              const SizedBox(height: 18),
              Center(child: Text('${AppConfig.appName}  $_version', style: kDim)),
              if (AppConfig.useTestAds)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Center(child: Text('TEST ADS ENABLED', style: TextStyle(fontFamily: 'Fredoka', color: AppColors.red, fontSize: 12))),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: panelDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

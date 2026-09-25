import 'package:flutter/material.dart';
import 'package:water_sort/config/economy.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/coin_pill.dart';
import 'package:water_sort/ui/widgets/game_button.dart';

Future<void> showDailyRewardDialog(BuildContext context) async {
  final claimed = await showDialog<int>(context: context, builder: (_) => const _DailyDialog());
  if (claimed != null && claimed > 0 && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+$claimed coins. See you tomorrow!')));
  }
}

class _DailyDialog extends StatefulWidget {
  const _DailyDialog();

  @override
  State<_DailyDialog> createState() => _DailyDialogState();
}

class _DailyDialogState extends State<_DailyDialog> {
  bool _busy = false;

  Future<void> _claim({required bool withVideo}) async {
    if (_busy) return;
    setState(() => _busy = true);
    var doubled = false;
    if (withVideo) {
      final r = await Services.ads.showRewarded(placement: 'daily_double');
      doubled = r.rewarded;
      if (!doubled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video not completed. Claiming the normal reward.')));
      }
    }
    final amount = Services.state.claimDaily(doubled: doubled);
    if (mounted) Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final DailyStatus s = Services.state.daily;
    final today = (s.streak - 1) % Economy.dailyRewards.length; // index of today's day
    final mult = Services.state.pro ? 2 : 1;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Daily reward', style: kTitle),
            const SizedBox(height: 4),
            Text(s.canClaim ? 'Come back every day for bigger rewards' : 'Already claimed today. Come back tomorrow!', style: kDim, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (var i = 0; i < Economy.dailyRewards.length; i++)
                  _DayChip(
                    day: i + 1,
                    coins: Economy.dailyRewards[i] * mult,
                    state: i < today ? _DayState.done : (i == today ? (s.canClaim ? _DayState.today : _DayState.done) : _DayState.future),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (s.canClaim) ...<Widget>[
              GameButton(label: 'Claim +${s.reward * mult}', onPressed: _busy ? null : () => _claim(withVideo: false)),
              const SizedBox(height: 4),
              GameButton(
                label: 'Claim x2 with video',
                icon: Icons.ondemand_video_rounded,
                style: GameButtonStyle.purple,
                fontSize: 19,
                onPressed: _busy ? null : () => _claim(withVideo: true),
              ),
            ] else
              GameButton(label: 'OK', onPressed: () => Navigator.of(context).pop(0)),
          ],
        ),
      ),
    );
  }
}

enum _DayState { done, today, future }

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.coins, required this.state});
  final int day;
  final int coins;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final isToday = state == _DayState.today;
    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppColors.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isToday ? AppColors.gold : Colors.transparent, width: 2),
      ),
      child: Column(
        children: <Widget>[
          Text('Day $day', style: kDim.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          state == _DayState.done ? const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 24) : const CoinIcon(size: 24),
          const SizedBox(height: 4),
          Text('$coins', style: kBody.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

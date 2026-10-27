import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.state});

  final AppState state;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.state.completeOnboarding();
  }

  Future<void> _allowCamera() async {
    await Permission.camera.request();
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (l10n.onboard1Title, l10n.onboard1Body, Icons.receipt_long_outlined),
      (l10n.onboard2Title, l10n.onboard2Body, Icons.insights_outlined),
      (l10n.onboard3Title, l10n.onboard3Body, Icons.photo_camera_outlined),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final page = pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: context.palette.primarySoft,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(page.$3, size: 48, color: context.palette.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(page.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text(page.$2, textAlign: TextAlign.center, style: TextStyle(color: context.palette.muted, height: 1.4)),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: active ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active ? context.palette.primary : context.palette.border,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (!last)
                FilledButton(
                  onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                  child: Text(l10n.next),
                )
              else ...[
                FilledButton(onPressed: _allowCamera, child: Text(l10n.allowCamera)),
                TextButton(onPressed: _finish, child: Text(l10n.notNow)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

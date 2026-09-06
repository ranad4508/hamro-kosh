import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_sizes.dart';
import '../constants/asset_paths.dart';
import '../widgets/app_button.dart';
import 'app_lock_controller.dart';

/// Wraps the authenticated app: while app-lock is enabled and the session
/// hasn't been unlocked yet, this shows a lock screen instead of [child].
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(appLockSessionProvider.notifier).lock();
    }
  }

  Future<void> _attemptUnlock() async {
    if (!ref.read(appLockSettingProvider)) return;
    if (ref.read(appLockSessionProvider)) return;
    final auth = ref.read(localAuthProvider);
    final success = await tryBiometricUnlock(auth);
    if (success && mounted) {
      ref.read(appLockSessionProvider.notifier).markUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = ref.watch(appLockSessionProvider);
    if (isUnlocked) return widget.child;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AssetPaths.logoMark, height: 96),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'App locked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Unlock Hamro Kosh to continue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Unlock',
                icon: Icons.fingerprint,
                onPressed: _attemptUnlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

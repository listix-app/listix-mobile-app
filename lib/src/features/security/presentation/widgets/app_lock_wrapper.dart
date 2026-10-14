import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_lock_controller.dart';
import '../screens/app_lock_screen.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    return Stack(
      children: [
        widget.child,
        if (lockState.isEnabled && lockState.isLocked)
          const Positioned.fill(child: AppLockScreen()),
      ],
    );
  }
}

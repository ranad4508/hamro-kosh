import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';

/// Bridges Riverpod's auth/profile providers into a [Listenable] so
/// `go_router`'s `redirect` re-evaluates whenever either changes.
///
/// This listens to the *Riverpod* providers (via `ref.listen`) rather than
/// the raw Firebase stream directly — important because [authStateProvider]
/// applies a timeout fallback on top of the raw `authStateChanges()` stream
/// (see its doc comment there). Listening to the raw stream instead would
/// miss that fallback's emission entirely, since it only happens inside the
/// provider's own stream transformation, and the router would never learn
/// that auth state had "resolved" to signed-out.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(userProfileProvider, (_, _) => notifyListeners());
  }
}

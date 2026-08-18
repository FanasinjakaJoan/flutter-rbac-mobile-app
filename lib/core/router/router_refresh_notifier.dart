import 'dart:async';

import 'package:flutter/foundation.dart';

/// Relaie un ou plusieurs flux vers `go_router` afin de forcer la réévaluation
/// des gardes (`redirect`) à chaque changement d'authentification ou de matrice
/// de permissions.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Stream<Object?> stream) : this.merge([stream]);

  RouterRefreshNotifier.merge(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final stream in streams) stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

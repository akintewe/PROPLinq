import 'package:flutter/foundation.dart';

/// Singleton notifier. Call [notify] after any wishlist add/remove so that
/// SavedView reloads immediately without the user having to pull-to-refresh.
class WishlistNotifier extends ChangeNotifier {
  static final WishlistNotifier _instance = WishlistNotifier._();
  factory WishlistNotifier() => _instance;
  WishlistNotifier._();

  void notify() => notifyListeners();
}

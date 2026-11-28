import 'dart:js_interop';

import 'web_url_cleaner.dart';

@JS('window')
external _JSWindow get _window;

extension type _JSWindow(JSObject _) implements JSObject {
  external _JSHistory? get history;
}

extension type _JSHistory(JSObject _) implements JSObject {
  external void replaceState(JSAny? data, String unused, [String? url]);
}

/// Strips OAuth callback and error parameters from `window.location` via
/// `history.replaceState`.
void scrubOAuthParamsFromBrowserUrlImpl() {
  try {
    final relative = cleanedOAuthRelativeLocation(Uri.base);
    if (relative == null) return;

    _window.history?.replaceState(null, '', relative);
  } catch (_) {
    // Never let browser history manipulation break auth flows.
  }
}

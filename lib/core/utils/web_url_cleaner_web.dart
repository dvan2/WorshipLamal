import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'web_url_cleaner.dart';

@JS('window')
external JSObject get _window;

/// Strips OAuth error parameters from `window.location` via `history.replaceState`.
void scrubOAuthErrorFromBrowserUrlImpl() {
  final current = Uri.base;
  final cleaned = stripOAuthErrorParams(current);
  if (cleaned.toString() == current.toString()) return;

  final history = _window.getProperty<JSObject?>('history'.toJS);
  if (history == null) return;

  final relative = StringBuffer(cleaned.path.isEmpty ? '/' : cleaned.path);
  if (cleaned.hasQuery) {
    relative.write('?${cleaned.query}');
  }
  if (cleaned.hasFragment) {
    relative.write('#${cleaned.fragment}');
  }

  history.callMethod<JSAny?>(
    'replaceState'.toJS,
    null,
    ''.toJS,
    relative.toString().toJS,
  );
}

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'push_notification_platform.dart';

const String _pushSwScope = '/push-scope/';

@JS('window')
external JSObject get _window;

@JS('navigator')
external JSObject get _navigator;

extension type _JSMediaQueryList(JSObject _) implements JSObject {
  external bool get matches;
}

@JS('Notification')
extension type _JSNotification(JSObject _) implements JSObject {
  external static String get permission;
}

extension type _JSServiceWorkerContainer(JSObject _) implements JSObject {
  external JSPromise<JSObject?> getRegistration([String? clientURL]);
}

extension type _JSServiceWorkerRegistration(JSObject _) implements JSObject {
  external _JSPushManager? get pushManager;
}

extension type _JSPushManager(JSObject _) implements JSObject {
  external JSPromise<_JSPushSubscription> subscribe(JSObject options);
}

extension type _JSPushSubscription(JSObject _) implements JSObject {
  external String get endpoint;
  external JSArrayBuffer? getKey(String name);
}

/// Web (`dart:js_interop`) implementation of [PushNotificationPlatform].
class WebPushNotificationPlatform implements PushNotificationPlatform {
  _JSServiceWorkerRegistration? _cachedRegistration;

  @override
  bool get isSupported {
    final isSecure =
        _window.getProperty<JSBoolean?>('isSecureContext'.toJS)?.toDart ??
            false;
    final hasSw = _navigator.has('serviceWorker');
    final hasPush = _window.has('PushManager');
    final hasNotif = _window.has('Notification');
    return isSecure && hasSw && hasPush && hasNotif;
  }

  @override
  bool get isStandalone {
    final mediaMatch = _window
        .callMethod<_JSMediaQueryList>(
          'matchMedia'.toJS,
          '(display-mode: standalone)'.toJS,
        )
        .matches;
    final iosStandalone = _navigator.has('standalone') &&
        (_navigator.getProperty<JSBoolean?>('standalone'.toJS)?.toDart ??
            false);
    return mediaMatch || iosStandalone;
  }

  @override
  bool get isIosSafari {
    final ua =
        (_navigator.getProperty<JSString?>('userAgent'.toJS)?.toDart ?? '')
            .toLowerCase();
    final isIos =
        ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
    final isSafari = ua.contains('safari') &&
        !ua.contains('crios') &&
        !ua.contains('fxios');
    return isIos && isSafari;
  }

  @override
  String get permissionState {
    if (!_window.has('Notification')) return 'denied';
    return _JSNotification.permission;
  }

  @override
  Future<void> prepare() async {
    if (!isSupported || _cachedRegistration != null) return;
    try {
      final container = _navigator.getProperty<_JSServiceWorkerContainer>(
        'serviceWorker'.toJS,
      );
      final reg = await container.getRegistration(_pushSwScope).toDart;
      if (reg != null) {
        _cachedRegistration = _JSServiceWorkerRegistration(reg);
      }
    } catch (_) {
      // Ignore pre-warm failures; subscribe() will handle missing registration.
    }
  }

  @override
  Future<PushSubscriptionData?> subscribe(String vapidPublicKey) async {
    if (!isSupported || vapidPublicKey.isEmpty) return null;

    final registration = _cachedRegistration;
    if (registration == null) {
      await prepare();
    }
    final activeReg = _cachedRegistration;
    if (activeReg == null) return null;

    final pushManager = activeReg.pushManager;
    if (pushManager == null) return null;

    final keyBytes = _decodeBase64Url(vapidPublicKey);
    final options = JSObject()
      ..setProperty('userVisibleOnly'.toJS, true.toJS)
      ..setProperty('applicationServerKey'.toJS, keyBytes.toJS);

    try {
      // Very first await inside the user-gesture handler when prepare() ran
      // beforehand, preserving iOS Safari transient user activation.
      final sub = await pushManager.subscribe(options).toDart;
      final p256dhBuf = sub.getKey('p256dh');
      final authBuf = sub.getKey('auth');
      if (p256dhBuf == null || authBuf == null) return null;

      return PushSubscriptionData(
        endpoint: sub.endpoint,
        p256dh: _encodeBase64Url(p256dhBuf.toDart.asUint8List()),
        auth: _encodeBase64Url(authBuf.toDart.asUint8List()),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _decodeBase64Url(String input) {
    final normalized = base64Url.normalize(input);
    return base64Url.decode(normalized);
  }

  String _encodeBase64Url(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

PushNotificationPlatform createPushNotificationPlatform() =>
    WebPushNotificationPlatform();

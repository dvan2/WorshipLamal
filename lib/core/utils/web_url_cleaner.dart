import 'web_url_cleaner_stub.dart'
    if (dart.library.js_interop) 'web_url_cleaner_web.dart';

const _oauthErrorKeys = {'error', 'error_code', 'error_description'};

/// Returns a copy of [uri] with OAuth error parameters (`error`, `error_code`,
/// `error_description`) removed from both query parameters and fragment.
Uri stripOAuthErrorParams(Uri uri) {
  final filteredQuery = Map<String, String>.from(uri.queryParameters)
    ..removeWhere((key, _) => _oauthErrorKeys.contains(key));

  var cleanedFragment = uri.fragment;
  if (cleanedFragment.isNotEmpty) {
    try {
      final fragmentParams = Uri.splitQueryString(cleanedFragment);
      if (fragmentParams.keys.any(_oauthErrorKeys.contains)) {
        fragmentParams.removeWhere((key, _) => _oauthErrorKeys.contains(key));
        cleanedFragment = fragmentParams.isEmpty
            ? ''
            : Uri(queryParameters: fragmentParams).query;
      }
    } catch (_) {
      if (_oauthErrorKeys.any(cleanedFragment.contains)) {
        cleanedFragment = '';
      }
    }
  }

  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    fragment: cleanedFragment.isEmpty ? null : cleanedFragment,
  );
}

/// Scrubs OAuth error parameters from the browser address bar without reloading.
///
/// No-op on non-web platforms.
void scrubOAuthErrorFromBrowserUrl() => scrubOAuthErrorFromBrowserUrlImpl();

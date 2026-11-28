import 'web_url_cleaner_stub.dart'
    if (dart.library.js_interop) 'web_url_cleaner_web.dart';

const _oauthCallbackKeys = {
  'code',
  'state',
  'error',
  'error_code',
  'error_description',
};

/// Returns a copy of [uri] with OAuth callback and error parameters (`code`,
/// `state`, `error`, `error_code`, `error_description`) removed from both
/// query parameters and fragment, preserving app query parameters.
Uri stripOAuthParams(Uri uri) {
  final filteredQuery = Map<String, String>.from(uri.queryParameters)
    ..removeWhere((key, _) => _oauthCallbackKeys.contains(key));

  var cleanedFragment = uri.fragment;
  if (cleanedFragment.isNotEmpty) {
    try {
      final fragmentParams = Uri.splitQueryString(cleanedFragment);
      if (fragmentParams.keys.any(_oauthCallbackKeys.contains)) {
        fragmentParams.removeWhere((key, _) => _oauthCallbackKeys.contains(key));
        cleanedFragment = fragmentParams.isEmpty
            ? ''
            : Uri(queryParameters: fragmentParams).query;
      }
    } catch (_) {
      if (_oauthCallbackKeys.any(cleanedFragment.contains)) {
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

/// Returns the cleaned relative URL (path + query + fragment) if [uri]
/// contained any OAuth callback/error parameters, or `null` otherwise.
String? cleanedOAuthRelativeLocation(Uri uri) {
  final cleaned = stripOAuthParams(uri);
  if (cleaned.toString() == uri.toString()) return null;

  final relative = StringBuffer(cleaned.path.isEmpty ? '/' : cleaned.path);
  if (cleaned.hasQuery) {
    relative.write('?${cleaned.query}');
  }
  if (cleaned.hasFragment) {
    relative.write('#${cleaned.fragment}');
  }
  return relative.toString();
}

/// Scrubs OAuth callback/error parameters from the browser address bar without
/// reloading. No-op on non-web platforms.
void scrubOAuthParamsFromBrowserUrl() => scrubOAuthParamsFromBrowserUrlImpl();

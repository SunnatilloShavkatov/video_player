final class UrlValidator {
  const new _();

  static const UrlValidator instance = UrlValidator._();

  bool isNotValidHttpsUrl(String url) {
    if (url.trim().isEmpty) {
      return true;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return true;
    }

    if (!uri.isAbsolute) {
      return true;
    }
    if (uri.scheme != 'https') {
      return true;
    }
    if (uri.host.isEmpty) {
      return true;
    }

    return false;
  }
}

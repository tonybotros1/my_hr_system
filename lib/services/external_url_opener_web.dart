import 'package:web/web.dart' as web;

/// Opens an attachment in a new browser tab.
void openExternalUrl(String url) {
  web.window.open(url, '_blank');
}

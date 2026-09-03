/// Native/test fallback for opening a URL outside the application.
///
/// The HR system currently exposes attachments in its web interface. Keeping
/// this fallback makes widgets that use the opener portable and testable.
void openExternalUrl(String url) {}

/// Non-web fallback for the dialog-history bridge.
///
/// Native Flutter navigators already own the platform Back action, so there is
/// no browser entry to create or remove.
class BrowserDialogHistory {
  BrowserDialogHistory._();

  static bool get hasOpenDialogs => false;
  static Future<void> get whenSettled => Future<void>.value();

  static BrowserDialogHistoryHandle open(void Function() onBrowserBack) {
    return BrowserDialogHistoryHandle._();
  }
}

class BrowserDialogHistoryHandle {
  BrowserDialogHistoryHandle._();

  void complete() {}
}

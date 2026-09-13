/// Tracks the imperative dialogs that are currently shown on Flutter web.
///
/// GetMaterialApp uses Flutter's Navigator-based web history. Flutter already
/// turns browser Back into a pop of the top Navigator route, including routes
/// created by `showDialog`. Adding a second, synthetic browser entry here made
/// Flutter restore the employee editor after a child dialog closed, which left
/// two identical editor routes and required two Close clicks.
///
/// This tracker intentionally leaves browser history ownership to Flutter. It
/// only retains the stack information used to decide whether a nested employee
/// editor should be a named route or another imperative dialog.
class BrowserDialogHistory {
  BrowserDialogHistory._();

  static final List<_DialogHistoryEntry> _entries = [];

  static bool get hasOpenDialogs => _entries.isNotEmpty;
  static Future<void> get whenSettled => Future<void>.value();

  static BrowserDialogHistoryHandle open(void Function() _) {
    final entry = _DialogHistoryEntry();
    _entries.add(entry);
    return BrowserDialogHistoryHandle._(entry);
  }

  static void _complete(_DialogHistoryEntry entry) {
    _entries.remove(entry);
  }
}

class BrowserDialogHistoryHandle {
  BrowserDialogHistoryHandle._(this._entry);

  final _DialogHistoryEntry _entry;
  bool _completed = false;

  void complete() {
    if (_completed) return;
    _completed = true;
    BrowserDialogHistory._complete(_entry);
  }
}

class _DialogHistoryEntry {
  const _DialogHistoryEntry();
}

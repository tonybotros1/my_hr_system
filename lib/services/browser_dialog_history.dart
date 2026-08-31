import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Adds a browser-history entry for an imperative Flutter dialog.
///
/// Flutter's Navigator closes dialogs correctly inside the app, but an
/// imperative dialog does not create a browser history entry on its own. This
/// small bridge makes the browser Back button close the top registered dialog
/// while keeping normal in-app Close buttons in sync with browser history.
class BrowserDialogHistory {
  BrowserDialogHistory._();

  static final List<_DialogHistoryEntry> _entries = [];
  static JSFunction? _popStateListener;
  static bool _ignoreNextPopState = false;
  static int _nextId = 0;

  static BrowserDialogHistoryHandle open(void Function() onBrowserBack) {
    _ensureListening();
    final entry = _DialogHistoryEntry(++_nextId, onBrowserBack);
    _entries.add(entry);
    web.window.history.pushState(
      <String, Object?>{'appDialog': entry.id}.jsify(),
      '',
      web.window.location.href,
    );
    return BrowserDialogHistoryHandle._(entry);
  }

  static void _ensureListening() {
    if (_popStateListener != null) return;
    _popStateListener = ((web.Event _) {
      if (_ignoreNextPopState) {
        _ignoreNextPopState = false;
        return;
      }
      if (_entries.isEmpty) return;
      final entry = _entries.removeLast();
      entry.wasClosedByBrowser = true;
      entry.onBrowserBack();
    }).toJS;
    web.window.addEventListener('popstate', _popStateListener);
  }

  static void _complete(_DialogHistoryEntry entry) {
    if (entry.wasClosedByBrowser) return;
    final index = _entries.indexOf(entry);
    if (index < 0) return;
    final wasTopEntry = index == _entries.length - 1;
    _entries.removeAt(index);
    if (wasTopEntry) {
      _ignoreNextPopState = true;
      web.window.history.back();
    }
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
  _DialogHistoryEntry(this.id, this.onBrowserBack);

  final int id;
  final void Function() onBrowserBack;
  bool wasClosedByBrowser = false;
}

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

  // The whole dialog stack shares one synthetic browser-history entry. Child
  // dialogs therefore close without issuing history.back(), which prevents a
  // delayed popstate from also dismissing their parent dialog.
  static bool _hasHistoryEntry = false;
  static int _ignoredPopStates = 0;
  static int _nextId = 0;

  static BrowserDialogHistoryHandle open(void Function() onBrowserBack) {
    _ensureListening();
    final entry = _DialogHistoryEntry(++_nextId, onBrowserBack);
    _entries.add(entry);
    if (_currentEntryIsSynthetic()) {
      _hasHistoryEntry = true;
    } else {
      _pushHistoryEntry(entry.id);
    }
    return BrowserDialogHistoryHandle._(entry);
  }

  static void _pushHistoryEntry(int id) {
    web.window.history.pushState(
      <String, Object?>{'appDialog': id}.jsify(),
      '',
      web.window.location.href,
    );
    _hasHistoryEntry = true;
  }

  static bool _currentEntryIsSynthetic() {
    final state = web.window.history.state;
    if (state == null) return false;
    final dartState = state.dartify();
    return dartState is Map && dartState['appDialog'] != null;
  }

  static void _ensureListening() {
    if (_popStateListener != null) return;
    _popStateListener = ((web.Event _) {
      _hasHistoryEntry = _currentEntryIsSynthetic();
      if (_ignoredPopStates > 0) {
        _ignoredPopStates--;
        if (_entries.isNotEmpty && !_hasHistoryEntry) {
          _pushHistoryEntry(_entries.last.id);
        }
        return;
      }
      if (_entries.isEmpty) return;
      final entry = _entries.removeLast();
      entry.wasClosedByBrowser = true;
      entry.onBrowserBack();
      if (_entries.isNotEmpty && !_hasHistoryEntry) {
        _pushHistoryEntry(_entries.last.id);
      }
    }).toJS;
    web.window.addEventListener('popstate', _popStateListener);
  }

  static void _complete(_DialogHistoryEntry entry) {
    if (entry.wasClosedByBrowser) return;
    final index = _entries.indexOf(entry);
    if (index < 0) return;
    _entries.removeAt(index);
    _hasHistoryEntry = _currentEntryIsSynthetic();
    if (_entries.isEmpty) {
      if (_hasHistoryEntry) {
        _ignoredPopStates++;
        web.window.history.back();
      }
    } else if (!_hasHistoryEntry) {
      _pushHistoryEntry(_entries.last.id);
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

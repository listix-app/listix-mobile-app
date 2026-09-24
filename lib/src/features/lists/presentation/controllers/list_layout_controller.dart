import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';

enum ListLayoutMode { list, grid }

class ListLayoutController extends Notifier<ListLayoutMode> {
  final AppDatabase _db;
  bool _isDisposed = false;

  ListLayoutController([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  @override
  ListLayoutMode build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _loadSavedMode();
    return ListLayoutMode.list;
  }

  Future<void> _loadSavedMode() async {
    try {
      final saved = await _db.getSetting('list_layout_mode');
      if (_isDisposed) return;
      if (saved == 'grid') {
        state = ListLayoutMode.grid;
      } else if (saved == 'list') {
        state = ListLayoutMode.list;
      }
    } catch (_) {}
  }

  Future<void> setLayoutMode(ListLayoutMode mode) async {
    state = mode;
    try {
      await _db.setSetting('list_layout_mode', mode.name);
    } catch (_) {}
  }

  Future<void> toggleLayout() async {
    final next = state == ListLayoutMode.list
        ? ListLayoutMode.grid
        : ListLayoutMode.list;
    await setLayoutMode(next);
  }
}

final listLayoutControllerProvider =
    NotifierProvider<ListLayoutController, ListLayoutMode>(
      ListLayoutController.new,
    );

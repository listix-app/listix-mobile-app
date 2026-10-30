import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/services/url_launcher_service.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:listix/src/features/backup/domain/entities/backup_data.dart';
import 'package:listix/src/features/lists/data/repositories/sqlite_lists_repository.dart';
import 'package:listix/src/features/lists/domain/entities/list_type.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:listix/src/features/lists/presentation/widgets/item_card_base.dart';
import 'package:listix/src/features/lists/presentation/widgets/item_editor_sheet.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_card.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_grid_card.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_type_presentation.dart';
import 'package:listix/src/features/lists/presentation/widgets/quick_add_input.dart';
import 'package:listix/src/features/lists/presentation/widgets/todo_item_tile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';

final _now = DateTime(2026, 10, 28);

TodoItem _item(
  String id, {
  String? title,
  String listId = 'l1',
  bool isCompleted = false,
  double? quantity,
  String? unit,
  String? category,
  double? price,
  String? store,
  String? url,
  ItemPriority? priority,
  String? notes,
  String? description,
  bool isFavorite = false,
  bool isChosen = false,
  DateTime? dueDate,
  bool isInProgress = false,
  String? imageUrl,
  Map<String, String> attributes = const {},
  ItemEvaluation? evaluation,
}) => TodoItem(
  id: id,
  listId: listId,
  title: title ?? 'Item $id',
  isCompleted: isCompleted,
  createdAt: _now,
  quantity: quantity,
  unit: unit,
  category: category,
  price: price,
  store: store,
  url: url,
  priority: priority,
  notes: notes,
  description: description,
  isFavorite: isFavorite,
  isChosen: isChosen,
  dueDate: dueDate,
  isInProgress: isInProgress,
  imageUrl: imageUrl,
  attributes: attributes,
  evaluation: evaluation,
);

final _spanish = AppStrings(AppLanguage.es);

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: theme,
  home: Scaffold(body: child),
);

class _FailingDetailsRepository extends SqliteListsRepository {
  @override
  Future<TodoItem> updateItemDetails(TodoItem item) =>
      throw Exception('details failure');

  @override
  Future<void> toggleChosenItem(String listId, String itemId) =>
      throw Exception('chosen failure');

  @override
  Future<void> updateListAttributes(
    String listId,
    List<String> attributeNames,
  ) => throw Exception('attributes failure');

  @override
  Future<TodoItem> addItem(
    String listId,
    String title, {
    String? id,
    TodoItem? details,
  }) => throw Exception('add failure');
}

class _RecordingController extends ListsController {
  final List<ShoppingList> initial;
  final List<TodoItem> updated = [];
  final List<String> chosen = [];
  final List<String> toggled = [];
  final List<(String, TodoItem?)> added = [];

  _RecordingController(this.initial);

  @override
  Future<List<ShoppingList>> build() async => initial;

  @override
  Future<void> updateItemDetails(TodoItem item) async => updated.add(item);

  @override
  Future<void> toggleChosenItem(String listId, String itemId) async {
    chosen.add(itemId);
    state = AsyncData([
      for (final list in state.value!)
        list.id == listId
            ? list.copyWith(
                items: [
                  for (final item in list.items)
                    item.copyWith(
                      isChosen: item.id == itemId && !item.isChosen,
                    ),
                ],
              )
            : list,
    ]);
  }

  final List<List<String>> attributeCalls = [];

  @override
  Future<void> updateListAttributes(
    String listId,
    List<String> attributeNames,
  ) async {
    attributeCalls.add(attributeNames);
    state = AsyncData([
      for (final list in state.value!)
        list.id == listId
            ? list.copyWith(attributeNames: attributeNames)
            : list,
    ]);
  }

  @override
  Future<void> toggleItem(String listId, String itemId) async =>
      toggled.add(itemId);

  @override
  Future<void> addItem(
    String listId,
    String title, {
    TodoItem? details,
  }) async => added.add((title, details));
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  group('List type domain model', () {
    test('ListType.fromName falls back to custom', () {
      expect(ListType.fromName('market'), ListType.market);
      expect(ListType.fromName('options'), ListType.options);
      expect(ListType.fromName('unknown'), ListType.custom);
      expect(ListType.fromName(null), ListType.custom);
    });

    test('ListType capabilities', () {
      expect(ListType.market.isGroupedByCategory, isTrue);
      expect(ListType.tasks.isGroupedByCategory, isFalse);
      expect(ListType.options.tracksCompletion, isFalse);
      expect(ListType.shopping.tracksCompletion, isTrue);
    });

    test('ItemPriority.fromName resolves known names only', () {
      expect(ItemPriority.fromName('high'), ItemPriority.high);
      expect(ItemPriority.fromName('nope'), isNull);
      expect(ItemPriority.fromName(null), isNull);
    });

    test('TodoItem json round trip keeps every detail field', () {
      final item = _item(
        'a',
        quantity: 2.5,
        unit: 'kg',
        category: 'produce',
        price: 9.9,
        store: 'Exito',
        url: 'https://example.com',
        priority: ItemPriority.medium,
        notes: 'n',
        description: 'c',
        isFavorite: true,
        isChosen: true,
        dueDate: DateTime(2026, 11, 2),
        isInProgress: true,
        imageUrl: 'https://img.test/a.png',
        attributes: {'Área': '40'},
        evaluation: ItemEvaluation.evaluated,
      );

      final copy = TodoItem.fromJson(item.toJson());

      expect(copy, item);
      expect(copy.hashCode, item.hashCode);
      expect(copy.dueDate, DateTime(2026, 11, 2));
      expect(copy.hasDetails, isTrue);
      expect(copy.attributes, {'Área': '40'});
      expect(copy.evaluation, ItemEvaluation.evaluated);
      expect(copy.imageUrl, 'https://img.test/a.png');
    });

    test('TodoItem equality and copyWith cover the option fields', () {
      final base = _item('a');
      final other = base.copyWith(
        description: 'd',
        imageUrl: 'u',
        attributes: {'k': 'v'},
        evaluation: ItemEvaluation.discarded,
      );
      expect(other == base, isFalse);
      expect(other.hasDetails, isTrue);
      expect(
        other,
        base.copyWith(
          description: 'd',
          imageUrl: 'u',
          attributes: {'k': 'v'},
          evaluation: ItemEvaluation.discarded,
        ),
      );
      expect(ItemEvaluation.fromName('evaluated'), ItemEvaluation.evaluated);
      expect(ItemEvaluation.fromName('x'), isNull);
    });

    test('TodoItem without details serializes compactly', () {
      final item = _item('plain');
      expect(item.hasDetails, isFalse);
      expect(item.toJson().containsKey('quantity'), isFalse);
      expect(TodoItem.fromJson(item.toJson()), item);
    });

    test('TodoItem copyWith overrides each detail field', () {
      final copy = _item('a').copyWith(
        quantity: 1,
        unit: 'g',
        category: 'dairy',
        price: 2,
        store: 's',
        url: 'u',
        priority: ItemPriority.low,
        notes: 'n',
        description: 'c',
        isFavorite: true,
        isChosen: true,
        dueDate: _now,
        isInProgress: true,
      );
      expect(copy.quantity, 1);
      expect(copy.unit, 'g');
      expect(copy.category, 'dairy');
      expect(copy.price, 2);
      expect(copy.store, 's');
      expect(copy.url, 'u');
      expect(copy.priority, ItemPriority.low);
      expect(copy.notes, 'n');
      expect(copy.description, 'c');
      expect(copy.isFavorite && copy.isChosen && copy.isInProgress, isTrue);
      expect(copy.dueDate, _now);
    });

    test('ShoppingList keeps type through json, copyWith and equality', () {
      final list = ShoppingList(
        id: 'l',
        name: 'Compras',
        type: ListType.shopping,
        items: [_item('a', price: 10), _item('b', price: 5.5), _item('c')],
        createdAt: _now,
      );

      expect(list.totalPrice, 15.5);
      expect(ShoppingList.fromJson(list.toJson()).type, ListType.shopping);
      final withAttributes = list.copyWith(attributeNames: ['Área', 'Piso']);
      expect(ShoppingList.fromJson(withAttributes.toJson()).attributeNames, [
        'Área',
        'Piso',
      ]);
      expect(withAttributes == list, isFalse);
      expect(ShoppingList.fromJson(list.toJson()), list);
      expect(list.copyWith(type: ListType.tasks).type, ListType.tasks);
      expect(list.copyWith(type: ListType.tasks) == list, isFalse);
      expect(list.copyWith().hashCode, list.hashCode);
    });

    test('ShoppingList.fromJson defaults legacy payloads to custom', () {
      final json = ShoppingList(
        id: 'l',
        name: 'Vieja',
        createdAt: _now,
      ).toJson()..remove('type');
      expect(ShoppingList.fromJson(json).type, ListType.custom);
    });

    test('backup json preserves type and item details', () {
      final data = BackupData(
        version: 1,
        exportedAt: _now,
        appVersion: '1.0.0',
        lists: [
          ShoppingList(
            id: 'l',
            name: 'Mercado',
            type: ListType.market,
            items: [_item('a', quantity: 3, unit: 'kg', category: 'meat')],
            createdAt: _now,
          ),
        ],
      );

      final restored = BackupData.fromJson(
        BackupData.fromJson(data.toJson()).toJson(),
      );

      expect(restored.lists.single.type, ListType.market);
      expect(restored.lists.single.items.single.category, 'meat');
    });
  });

  group('Typed lists persistence (SQLite)', () {
    late SqliteListsRepository repository;

    setUp(() async {
      AppDatabase.overrideDbPath = inMemoryDatabasePath;
      final db = await AppDatabase.instance.database;
      await db.delete('items');
      await db.delete('collaborators');
      await db.delete('lists');
      await db.delete('pending_operations');
      repository = SqliteListsRepository();
    });

    test('createList persists the list type and defaults to custom', () async {
      final market = await repository.createList(
        'Mercado',
        type: ListType.market,
      );
      final plain = await repository.createList('Libre');

      expect(market.type, ListType.market);
      expect(plain.type, ListType.custom);
      final stored = await repository.getLists();
      expect(
        {for (final l in stored) l.name: l.type},
        {'Mercado': ListType.market, 'Libre': ListType.custom},
      );
    });

    test('updateListName can change the list type', () async {
      final list = await repository.createList('Lista', type: ListType.market);
      await repository.setListShared(list.id, true, hasInvite: true);
      await repository.clearPendingOperationsForList(list.id);

      final updated = await repository.updateListName(
        list.id,
        'Lista',
        type: ListType.tasks,
      );
      final kept = await repository.updateListName(list.id, 'Lista');

      expect(updated.type, ListType.tasks);
      expect(kept.type, ListType.tasks);
      final ops = await repository.getPendingOperations(listId: list.id);
      expect(ops.first.payload!['list_type'], 'tasks');
    });

    test('addItem stores item details and returns them', () async {
      final list = await repository.createList(
        'Mercado',
        type: ListType.market,
      );

      final created = await repository.addItem(
        list.id,
        '  Leche ',
        details: _item('x', quantity: 2, unit: 'l', category: 'dairy'),
      );

      expect(created.title, 'Leche');
      expect(created.quantity, 2);
      final stored = (await repository.getListById(list.id))!.items.single;
      expect(stored.unit, 'l');
      expect(stored.category, 'dairy');
      expect(stored.id, created.id);
    });

    test('addItem without details keeps plain items', () async {
      final list = await repository.createList('Libre');
      final created = await repository.addItem(list.id, 'Pan');
      expect(created.hasDetails, isFalse);
    });

    test(
      'updateItemDetails persists every field and clears removed ones',
      () async {
        final list = await repository.createList(
          'Compras',
          type: ListType.shopping,
        );
        final created = await repository.addItem(list.id, 'Teclado');

        final updated = await repository.updateItemDetails(
          created.copyWith(
            title: ' Teclado mecánico ',
            price: 120,
            store: 'Tienda',
            url: 'https://shop.test/k',
            priority: ItemPriority.high,
            dueDate: DateTime(2026, 12, 1),
          ),
        );

        expect(updated.title, 'Teclado mecánico');
        expect(updated.price, 120);
        expect(updated.priority, ItemPriority.high);
        expect(updated.dueDate, DateTime(2026, 12, 1));

        final cleared = await repository.updateItemDetails(
          TodoItem(
            id: created.id,
            listId: list.id,
            title: 'Teclado mecánico',
            createdAt: created.createdAt,
          ),
        );
        expect(cleared.hasDetails, isFalse);
      },
    );

    test('updateItemDetails on a shared list queues the details', () async {
      final list = await repository.createList(
        'Compartida',
        type: ListType.tasks,
      );
      final created = await repository.addItem(list.id, 'Tarea');
      await repository.setListShared(list.id, true, hasInvite: true);
      await repository.clearPendingOperationsForList(list.id);

      await repository.updateItemDetails(
        created.copyWith(priority: ItemPriority.low, isInProgress: true),
      );

      final ops = await repository.getPendingOperations(listId: list.id);
      expect(ops, hasLength(1));
      expect(ops.single.payload!['priority'], 'low');
      expect(ops.single.payload!['in_progress'], 1);
    });

    test('toggleChosenItem keeps a single chosen option', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      final a = await repository.addItem(list.id, 'UNAL');
      final b = await repository.addItem(list.id, 'Javeriana');

      await repository.toggleChosenItem(list.id, a.id);
      var items = (await repository.getListById(list.id))!.items;
      expect(items.firstWhere((i) => i.id == a.id).isChosen, isTrue);
      expect(items.firstWhere((i) => i.id == b.id).isChosen, isFalse);

      await repository.toggleChosenItem(list.id, b.id);
      items = (await repository.getListById(list.id))!.items;
      expect(items.firstWhere((i) => i.id == a.id).isChosen, isFalse);
      expect(items.firstWhere((i) => i.id == b.id).isChosen, isTrue);

      await repository.toggleChosenItem(list.id, b.id);
      items = (await repository.getListById(list.id))!.items;
      expect(items.any((i) => i.isChosen), isFalse);
    });

    test('toggleChosenItem on a shared list queues changed items', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      final a = await repository.addItem(list.id, 'A');
      await repository.setListShared(list.id, true, hasInvite: true);
      await repository.clearPendingOperationsForList(list.id);

      await repository.toggleChosenItem(list.id, a.id);

      final ops = await repository.getPendingOperations(listId: list.id);
      expect(ops, hasLength(1));
      expect(ops.single.payload!['is_chosen'], 1);
    });

    test('completing a task clears the in progress flag', () async {
      final list = await repository.createList('Tareas', type: ListType.tasks);
      final created = await repository.addItem(
        list.id,
        'Pagar',
        details: _item('x', isInProgress: true),
      );

      await repository.toggleItemCompletion(list.id, created.id);

      final stored = (await repository.getListById(list.id))!.items.single;
      expect(stored.isCompleted, isTrue);
      expect(stored.isInProgress, isFalse);
    });

    test('undo helpers keep the item details', () async {
      final list = await repository.createList(
        'Compras',
        type: ListType.shopping,
      );
      final created = await repository.addItem(
        list.id,
        'Monitor',
        details: _item('x', price: 300, store: 'Tienda'),
      );
      await repository.toggleItemCompletion(list.id, created.id);

      final deleted = await repository.deleteCompletedItems(list.id);
      expect(deleted.single.price, 300);

      await repository.restoreItem(deleted.single);
      expect(
        (await repository.getListById(list.id))!.items.single.store,
        'Tienda',
      );

      await repository.deleteItem(list.id, created.id);
      await repository.restoreItems(deleted);
      expect((await repository.getListById(list.id))!.items.single.price, 300);
    });

    test('restoreList keeps type and item details', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      await repository.addItem(
        list.id,
        'Casa',
        details: _item('x', description: 'cerca', isFavorite: true),
      );
      final snapshot = (await repository.getListById(list.id))!;
      await repository.deleteList(list.id);

      await repository.restoreList(snapshot);

      final restored = (await repository.getListById(list.id))!;
      expect(restored.type, ListType.options);
      expect(restored.items.single.description, 'cerca');
      expect(restored.items.single.isFavorite, isTrue);
    });

    test(
      'saveRemoteList keeps local type and details the remote lacks',
      () async {
        final list = await repository.createList(
          'Compras',
          type: ListType.shopping,
        );
        final created = await repository.addItem(
          list.id,
          'Monitor',
          details: _item('x', price: 300),
        );

        await repository.saveRemoteList(
          ShoppingList(
            id: list.id,
            name: 'Compras',
            items: [
              TodoItem(
                id: created.id,
                listId: list.id,
                title: 'Monitor',
                createdAt: _now,
              ),
              TodoItem(
                id: 'remote-new',
                listId: list.id,
                title: 'Nuevo remoto',
                createdAt: _now,
              ),
            ],
            createdAt: _now,
          ),
        );

        final stored = (await repository.getListById(list.id))!;
        expect(stored.type, ListType.shopping);
        expect(stored.items.firstWhere((i) => i.id == created.id).price, 300);
        expect(stored.items.any((i) => i.id == 'remote-new'), isTrue);
      },
    );

    test('saveRemoteList adopts a type sent by the remote', () async {
      await repository.saveRemoteList(
        ShoppingList(
          id: 'remote-list',
          name: 'Remota',
          type: ListType.tasks,
          items: [
            _item('r1', listId: 'remote-list', priority: ItemPriority.high),
          ],
          createdAt: _now,
        ),
      );

      final stored = (await repository.getListById('remote-list'))!;
      expect(stored.type, ListType.tasks);
      expect(stored.items.single.priority, ItemPriority.high);
    });

    test('applyRemoteItem preserves local details for plain echoes', () async {
      final list = await repository.createList(
        'Compras',
        type: ListType.shopping,
      );
      final created = await repository.addItem(
        list.id,
        'Monitor',
        details: _item('x', price: 300),
      );

      await repository.applyRemoteItem(
        TodoItem(
          id: created.id,
          listId: list.id,
          title: 'Monitor',
          createdAt: _now,
        ),
      );
      await repository.applyRemoteItem(
        _item('fresh', listId: list.id, store: 'Remota'),
      );

      final items = (await repository.getListById(list.id))!.items;
      expect(items.firstWhere((i) => i.id == created.id).price, 300);
      expect(items.firstWhere((i) => i.id == 'fresh').store, 'Remota');
    });

    test('syncing a list enqueues its type and item details', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      await repository.addItem(
        list.id,
        'A',
        details: _item('x', description: 'precio'),
      );

      await repository.setListShared(list.id, true, hasInvite: true);

      final ops = await repository.getPendingOperations(listId: list.id);
      final payloads = ops.map((o) => o.payload!).toList();
      expect(payloads.any((p) => p['list_type'] == 'options'), isTrue);
      expect(payloads.any((p) => p['description'] == 'precio'), isTrue);
    });

    test('backup data source round trips type and item details', () async {
      final list = await repository.createList(
        'Mercado',
        type: ListType.market,
      );
      await repository.addItem(
        list.id,
        'Arroz',
        details: _item('x', quantity: 2, unit: 'kg', category: 'pantry'),
      );
      final source = BackupLocalDataSourceImpl();

      final exported = await source.fetchAllLists();
      expect(exported.single.type, ListType.market);
      expect(exported.single.items.single.unit, 'kg');

      await source.restoreLists(exported, replaceExisting: true);

      final restored = (await repository.getListById(list.id))!;
      expect(restored.type, ListType.market);
      expect(restored.items.single.category, 'pantry');
    });
  });

  group('ListsController typed lists', () {
    late ProviderContainer container;

    setUp(() async {
      AppDatabase.overrideDbPath = inMemoryDatabasePath;
      final db = await AppDatabase.instance.database;
      await db.delete('items');
      await db.delete('collaborators');
      await db.delete('lists');
      await db.delete('pending_operations');
      container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(listsControllerProvider.future);
    });

    ListsController notifier() =>
        container.read(listsControllerProvider.notifier);
    List<ShoppingList> lists() =>
        container.read(listsControllerProvider).value!;

    test('createList stores the chosen type', () async {
      final created = await notifier().createList(
        'Tareas',
        type: ListType.tasks,
      );
      expect(created.type, ListType.tasks);
      expect(lists().single.type, ListType.tasks);
    });

    test('updateListName changes the type in state and storage', () async {
      final created = await notifier().createList('Lista');

      await notifier().updateListName(
        created.id,
        'Lista',
        type: ListType.options,
      );

      expect(lists().single.type, ListType.options);
      final stored = await container.read(listsRepositoryProvider).getLists();
      expect(stored.single.type, ListType.options);
    });

    test(
      'addItem with details, updateItemDetails and toggleChosenItem',
      () async {
        final list = await notifier().createList(
          'Opciones',
          type: ListType.options,
        );
        await notifier().addItem(
          list.id,
          'UNAL',
          details: _item('x', description: 'costo'),
        );
        await notifier().addItem(list.id, 'Javeriana');

        var items = lists().single.items;
        final first = items.firstWhere((i) => i.title == 'UNAL');
        final second = items.firstWhere((i) => i.title == 'Javeriana');
        expect(first.description, 'costo');

        await notifier().updateItemDetails(first.copyWith(isFavorite: true));
        await notifier().toggleChosenItem(list.id, second.id);

        items = lists().single.items;
        expect(items.firstWhere((i) => i.id == first.id).isFavorite, isTrue);
        expect(items.firstWhere((i) => i.id == second.id).isChosen, isTrue);

        await notifier().toggleChosenItem(list.id, first.id);
        items = lists().single.items;
        expect(items.firstWhere((i) => i.id == first.id).isChosen, isTrue);
        expect(items.firstWhere((i) => i.id == second.id).isChosen, isFalse);

        final stored = await container.read(listsRepositoryProvider).getLists();
        expect(stored.single.items.where((i) => i.isChosen), hasLength(1));
      },
    );

    test('completing a task item clears in progress optimistically', () async {
      final list = await notifier().createList('Tareas', type: ListType.tasks);
      await notifier().addItem(
        list.id,
        'Pagar',
        details: _item('x', isInProgress: true),
      );
      final id = lists().single.items.single.id;

      await notifier().toggleItem(list.id, id);

      final item = lists().single.items.single;
      expect(item.isCompleted, isTrue);
      expect(item.isInProgress, isFalse);
    });

    test('repository failures roll the state back', () async {
      final failing = ProviderContainer(
        overrides: [
          listsRepositoryProvider.overrideWithValue(
            _FailingDetailsRepository(),
          ),
        ],
      );
      addTearDown(failing.dispose);
      await failing.read(listsControllerProvider.future);
      final controller = failing.read(listsControllerProvider.notifier);
      final list = await controller.createList(
        'Opciones',
        type: ListType.options,
      );
      await expectLater(
        controller.updateItemDetails(_item('missing', listId: list.id)),
        throwsException,
      );
      await expectLater(
        controller.toggleChosenItem(list.id, 'missing'),
        throwsException,
      );
      await expectLater(
        controller.updateListAttributes(list.id, ['Área']),
        throwsException,
      );
      await expectLater(
        controller.addItem(list.id, 'Nuevo', details: _item('x')),
        throwsException,
      );
      expect(
        failing.read(listsControllerProvider).value!.single.items,
        isEmpty,
      );
    });
  });

  group('Type presentation helpers', () {
    test('every type has an icon, a name and a description', () {
      final english = AppStrings(AppLanguage.en);
      for (final type in ListType.values) {
        expect(type.icon, isA<IconData>());
        for (final tr in [_spanish, english]) {
          expect(tr.listTypeName(type), isNotEmpty);
          expect(tr.listTypeDescription(type), isNotEmpty);
        }
      }
      expect(english.listTypeName(ListType.market), 'Groceries');
      expect(_spanish.listTypeName(ListType.market), 'Mercado');
    });

    test('category and priority names are localized', () {
      final english = AppStrings(AppLanguage.en);
      for (final key in [...MarketCatalog.categories, 'unknown']) {
        expect(_spanish.categoryName(key), isNotEmpty);
        expect(english.categoryName(key), isNotEmpty);
      }
      for (final priority in ItemPriority.values) {
        expect(english.priorityName(priority), isNotEmpty);
      }
      expect(_spanish.categoryName(null), 'Otros');
      expect(_spanish.categoryName('dairy'), 'Lácteos y huevos');
      for (final priority in ItemPriority.values) {
        expect(_spanish.priorityName(priority), isNotEmpty);
      }
    });

    test('new strings resolve in both languages', () {
      for (final tr in [_spanish, AppStrings(AppLanguage.en)]) {
        final values = [
          tr.listTypePickerHeading,
          tr.listTypePickerSubheading,
          tr.changeListType,
          tr.newItemTitle,
          tr.itemDetailsTitle,
          tr.addWithDetails,
          tr.quantityLabel,
          tr.unitLabel,
          tr.categoryLabel,
          tr.priorityLabel,
          tr.priceLabel,
          tr.storeLabel,
          tr.linkLabel,
          tr.linkInvalid,
          tr.numberInvalid,
          tr.notesLabel,
          tr.descriptionLabel,
          tr.imageUrlLabel,
          tr.imageUrlInvalid,
          tr.estimatedPriceLabel,
          tr.evaluationLabel,
          tr.evaluationPending,
          tr.evaluationEvaluated,
          tr.evaluationDiscarded,
          tr.manageAttributes,
          tr.attributeNameLabel,
          tr.attributeNameHint,
          tr.addAttribute,
          tr.removeAttribute,
          tr.attributesEmpty,
          tr.compareOptions,
          tr.compareNeedsTwo,
          tr.optionColumn,
          tr.favoriteLabel,
          tr.chosenBadge,
          tr.markChosen,
          tr.unmarkChosen,
          tr.addFavorite,
          tr.removeFavorite,
          tr.dueDateLabel,
          tr.noDueDate,
          tr.clearDate,
          tr.inProgressLabel,
          tr.openLink,
          tr.optionsCount(1),
          tr.optionsCount(3),
          tr.shoppingTotal('9.00'),
        ];
        expect(values.every((v) => v.isNotEmpty), isTrue);
      }
    });
  });

  group('ItemEditorSheet', () {
    testWidgets('market: captures quantity, unit and category', (tester) async {
      TodoItem? saved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showItemEditorSheet(
                context,
                type: ListType.market,
                strings: _spanish,
                draft: _item('m1', title: 'Leche'),
                isNew: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo item'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('item_editor_quantity')),
        '2,5',
      );
      await tester.tap(find.byKey(const Key('unit_kg')));
      await tester.tap(find.byKey(const Key('category_dairy')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('category_dairy')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('category_dairy')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(saved!.title, 'Leche');
      expect(saved!.quantity, 2.5);
      expect(saved!.unit, 'kg');
      expect(saved!.category, 'dairy');
    });

    testWidgets('market: shows existing values and rejects bad numbers', (
      tester,
    ) async {
      TodoItem? saved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showItemEditorSheet(
                context,
                type: ListType.market,
                strings: _spanish,
                draft: _item('m1', quantity: 3, unit: 'g'),
              ),
              child: const Text('open'),
            ),
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Detalles del elemento'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('item_editor_quantity')),
            )
            .controller!
            .text,
        '3',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_quantity')),
        '1.2.3',
      );
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pump();
      expect(find.text('Ingresa un número válido'), findsOneWidget);
      expect(saved, isNull);

      await tester.enterText(find.byKey(const Key('item_editor_quantity')), '');
      await tester.enterText(find.byKey(const Key('item_editor_title')), '  ');
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pump();
      expect(find.text('Por favor ingresa un nombre'), findsOneWidget);
    });

    testWidgets('shopping: captures price, store, link and priority', (
      tester,
    ) async {
      TodoItem? saved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showItemEditorSheet(
                context,
                type: ListType.shopping,
                strings: _spanish,
                draft: _item('s1', title: 'Teclado', price: 12.5),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('item_editor_price')),
        '120.50',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_store')),
        'Alkosto',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_url')),
        'ftp://x',
      );
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pump();
      expect(find.text('Ingresa un enlace http(s) válido'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('item_editor_url')),
        'https://alkosto.com/k',
      );
      await tester.ensureVisible(find.byKey(const Key('priority_high')));
      await tester.tap(find.byKey(const Key('priority_high')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(saved!.price, 120.5);
      expect(saved!.store, 'Alkosto');
      expect(saved!.url, 'https://alkosto.com/k');
      expect(saved!.priority, ItemPriority.high);
    });

    testWidgets('options: captures description, notes and favorite', (
      tester,
    ) async {
      TodoItem? saved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showItemEditorSheet(
                context,
                type: ListType.options,
                strings: _spanish,
                draft: _item('o1', title: 'Apto Centro', isChosen: true),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('item_editor_description')),
        'cerca',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_notes')),
        'visitar',
      );
      await tester.ensureVisible(find.byKey(const Key('item_editor_favorite')));
      await tester.tap(find.byKey(const Key('item_editor_favorite')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(saved!.description, 'cerca');
      expect(saved!.notes, 'visitar');
      expect(saved!.isFavorite, isTrue);
      expect(saved!.isChosen, isTrue);
    });

    testWidgets('tasks: priority, due date and in progress', (tester) async {
      TodoItem? saved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showItemEditorSheet(
                context,
                type: ListType.tasks,
                strings: _spanish,
                draft: _item('t1', title: 'Declarar renta'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Sin fecha'), findsOneWidget);
      await tester.tap(find.byKey(const Key('priority_medium')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('item_editor_due_date')));
      await tester.tap(find.byKey(const Key('item_editor_due_date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Sin fecha'), findsNothing);
      expect(find.byKey(const Key('item_editor_clear_date')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('item_editor_clear_date')),
      );
      await tester.tap(find.byKey(const Key('item_editor_clear_date')));
      await tester.pump();
      expect(find.text('Sin fecha'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('item_editor_due_date')));
      await tester.tap(find.byKey(const Key('item_editor_due_date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('item_editor_in_progress')),
      );
      await tester.tap(find.byKey(const Key('item_editor_in_progress')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(saved!.priority, ItemPriority.medium);
      expect(saved!.dueDate, isNotNull);
      expect(saved!.isInProgress, isTrue);
    });

    testWidgets('tasks: cancelling the date picker keeps the date empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showItemEditorSheet(
                context,
                type: ListType.tasks,
                strings: _spanish,
                draft: _item('t1', isCompleted: true),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_editor_in_progress')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('item_editor_due_date')));
      await tester.tap(find.byKey(const Key('item_editor_due_date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Sin fecha'), findsOneWidget);
    });

    testWidgets('custom lists only edit the title', (tester) async {
      TodoItem? saved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showItemEditorSheet(
                context,
                type: ListType.custom,
                strings: _spanish,
                draft: _item('c1', title: 'Libre'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();
      expect(saved!.title, 'Libre');
      expect(saved!.hasDetails, isFalse);
    });
  });

  group('TodoItemTile typed content', () {
    Future<void> pumpTile(
      WidgetTester tester,
      TodoItem item,
      ListType type, {
      VoidCallback? onToggle,
      VoidCallback? onEdit,
      VoidCallback? onFavorite,
      VoidCallback? onLink,
      ThemeData? theme,
      List<String> attributeNames = const [],
    }) => tester.pumpWidget(
      _host(
        TodoItemTile(
          item: item,
          listType: type,
          strings: _spanish,
          attributeNames: attributeNames,
          onToggle: onToggle ?? () {},
          onDelete: () {},
          onEdit: onEdit,
          onToggleFavorite: onFavorite,
          onOpenLink: onLink,
        ),
        theme: theme,
      ),
    );

    testWidgets('market shows quantity with unit', (tester) async {
      await pumpTile(
        tester,
        _item('a', quantity: 2, unit: 'kg'),
        ListType.market,
      );
      expect(find.text('2 kg'), findsOneWidget);
      await pumpTile(tester, _item('b', quantity: 1.5), ListType.market);
      expect(find.text('1.5'), findsOneWidget);
    });

    testWidgets('shopping shows price, store, priority and link', (
      tester,
    ) async {
      var opened = false;
      await pumpTile(
        tester,
        _item(
          'a',
          price: 12.5,
          store: 'Alkosto',
          url: 'https://x.test',
          priority: ItemPriority.high,
        ),
        ListType.shopping,
        onLink: () => opened = true,
      );
      expect(find.text('12.50'), findsOneWidget);
      expect(find.text('Alkosto'), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('link_a')));
      expect(opened, isTrue);

      await pumpTile(
        tester,
        _item('b', priority: ItemPriority.medium),
        ListType.shopping,
      );
      expect(find.text('Media'), findsOneWidget);
      await pumpTile(
        tester,
        _item('c', priority: ItemPriority.low),
        ListType.shopping,
      );
      expect(find.text('Baja'), findsOneWidget);
      expect(find.byKey(const ValueKey('link_c')), findsNothing);
    });

    testWidgets('options show chosen badge, description and attributes', (
      tester,
    ) async {
      var toggled = 0;
      var edited = 0;
      var favorite = 0;
      await pumpTile(
        tester,
        _item(
          'a',
          isChosen: true,
          description: 'cerca',
          evaluation: ItemEvaluation.evaluated,
          attributes: {'Área': '40 m²', 'Piso': '3', 'Oculto': ''},
        ),
        ListType.options,
        onToggle: () => toggled++,
        onEdit: () => edited++,
        onFavorite: () => favorite++,
        theme: ThemeData.dark(),
        attributeNames: const ['Área', 'Oculto'],
      );
      expect(find.text('Elegida'), findsOneWidget);
      expect(find.text('cerca'), findsOneWidget);
      expect(find.text('Evaluada'), findsOneWidget);
      expect(find.text('Área: 40 m²'), findsOneWidget);
      expect(find.textContaining('Piso'), findsNothing);
      expect(find.textContaining('Oculto'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('chosen_indicator')));
      expect(toggled, 1);
      await tester.tap(find.byKey(const ValueKey('favorite_a')));
      expect(favorite, 1);
      await tester.tap(find.text('cerca'));
      expect(edited, 1);
      expect(toggled, 1);

      await pumpTile(
        tester,
        _item('b', isFavorite: true),
        ListType.options,
        onToggle: () => toggled++,
        onFavorite: () {},
      );
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
      await tester.tap(find.text('Item b'));
      expect(toggled, 2);
    });

    testWidgets('tasks show status, priority and overdue dates', (
      tester,
    ) async {
      await pumpTile(
        tester,
        _item(
          'a',
          isInProgress: true,
          priority: ItemPriority.medium,
          dueDate: DateTime(2020, 1, 1),
        ),
        ListType.tasks,
      );
      expect(find.text('En progreso'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      final overdue = tester.widget<Text>(find.textContaining('Jan 1'));
      expect(overdue.style!.color, const Color(0xFFDC2626));

      await pumpTile(
        tester,
        _item('b', isCompleted: true, dueDate: DateTime(2020, 1, 1)),
        ListType.tasks,
      );
      final done = tester.widget<Text>(find.textContaining('Jan 1'));
      expect(done.style!.color, isNot(const Color(0xFFDC2626)));

      await pumpTile(
        tester,
        _item('c', dueDate: DateTime.now().add(const Duration(days: 30))),
        ListType.tasks,
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('custom lists render no extra metadata', (tester) async {
      await pumpTile(tester, _item('a', price: 5), ListType.custom);
      expect(find.text('5.00'), findsNothing);
    });

    testWidgets('tile falls back to Spanish when no strings are given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          TodoItemTile(
            item: _item('a', isChosen: true),
            listType: ListType.options,
            onToggle: () {},
            onDelete: () {},
          ),
        ),
      );
      expect(find.text('Elegida'), findsOneWidget);
    });
  });

  group('QuickAddInput details shortcut', () {
    testWidgets('details button passes the typed title and clears the field', (
      tester,
    ) async {
      String? received;
      await tester.pumpWidget(
        _host(
          QuickAddInput(
            autoFocus: false,
            onAdd: (_) {},
            onAddWithDetails: (title) => received = title,
            detailsTooltip: 'Agregar con detalles',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Arroz');
      await tester.tap(find.byKey(const Key('quick_add_details_button')));
      await tester.pump();

      expect(received, 'Arroz');
      expect(find.text('Arroz'), findsNothing);
    });

    testWidgets('no details button without a callback', (tester) async {
      await tester.pumpWidget(
        _host(QuickAddInput(autoFocus: false, onAdd: (_) {})),
      );
      expect(find.byKey(const Key('quick_add_details_button')), findsNothing);
    });
  });

  group('Home cards for typed lists', () {
    testWidgets('list card shows the type icon and option count', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'o',
        name: 'Universidades',
        type: ListType.options,
        items: [_item('a'), _item('b')],
        createdAt: _now,
      );
      await tester.pumpWidget(
        _host(ListCard(list: list, onTap: () {}, strings: _spanish)),
      );

      expect(find.byKey(const Key('list_type_icon')), findsOneWidget);
      expect(find.text('2 opciones'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('list card for custom lists is unchanged', (tester) async {
      final list = ShoppingList(
        id: 'c',
        name: 'Libre',
        items: [_item('a')],
        createdAt: _now,
      );
      await tester.pumpWidget(
        _host(ListCard(list: list, onTap: () {}, strings: _spanish)),
      );

      expect(find.byKey(const Key('list_type_icon')), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('grid card shows the option count', (tester) async {
      final list = ShoppingList(
        id: 'o',
        name: 'Celulares',
        type: ListType.options,
        items: [_item('a')],
        createdAt: _now,
      );
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 200,
            height: 200,
            child: ListGridCard(list: list, onTap: () {}, strings: _spanish),
          ),
        ),
      );
      expect(find.text('1 opción'), findsOneWidget);
    });
  });

  group('ListDetailScreen for typed lists', () {
    Future<_RecordingController> pumpDetail(
      WidgetTester tester,
      ShoppingList list, {
      List<String>? openedUrls,
    }) async {
      final controller = _RecordingController([list]);
      final router = GoRouter(
        initialLocation: '/list/${list.id}',
        routes: [
          GoRoute(
            path: '/list/:id',
            builder: (context, state) =>
                ListDetailScreen(listId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => controller),
            urlLauncherServiceProvider.overrideWithValue(
              UrlLauncherService(
                customLauncher:
                    (uri, {mode = LaunchMode.platformDefault}) async {
                      openedUrls?.add(uri.toString());
                      return true;
                    },
              ),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('market groups pending items by category', (tester) async {
      final list = ShoppingList(
        id: 'm',
        name: 'Mercado semanal',
        type: ListType.market,
        items: [
          _item('a', title: 'Pan', category: 'bakery', listId: 'm'),
          _item('b', title: 'Leche', category: 'dairy', listId: 'm'),
          _item('c', title: 'Sal', listId: 'm', quantity: 1, unit: 'kg'),
          _item('d', title: 'Cola', category: 'ghost', listId: 'm'),
          _item('e', title: 'Hecho', listId: 'm', isCompleted: true),
        ],
        createdAt: _now,
      );
      await pumpDetail(tester, list);

      expect(find.byKey(const Key('category_header_dairy')), findsOneWidget);
      expect(find.byKey(const Key('category_header_bakery')), findsOneWidget);
      expect(find.byKey(const Key('category_header_other')), findsOneWidget);
      expect(find.text('LÁCTEOS Y HUEVOS'), findsOneWidget);
      final dairy = tester.getTopLeft(
        find.byKey(const Key('category_header_dairy')),
      );
      final bakery = tester.getTopLeft(
        find.byKey(const Key('category_header_bakery')),
      );
      final other = tester.getTopLeft(
        find.byKey(const Key('category_header_other')),
      );
      expect(dairy.dy, lessThan(bakery.dy));
      expect(bakery.dy, lessThan(other.dy));
      expect(find.text('1 kg'), findsOneWidget);
      expect(find.text('Completados (1)'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('options header counts options and toggles the chosen one', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'o',
        name: 'Universidades',
        type: ListType.options,
        items: [
          _item('a', title: 'UNAL', listId: 'o', description: 'costo'),
          _item('b', title: 'Javeriana', listId: 'o', isChosen: true),
        ],
        createdAt: _now,
      );
      final controller = await pumpDetail(tester, list);

      expect(find.text('2 opciones'), findsOneWidget);
      expect(find.textContaining('completado'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.tap(find.byKey(const Key('chosen_indicator')).first);
      await tester.pump();
      expect(controller.chosen, ['a']);

      await tester.tap(find.byKey(const ValueKey('favorite_a')));
      await tester.pump();
      expect(controller.updated.single.isFavorite, isTrue);
    });

    testWidgets('editing an item opens the typed editor and saves details', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 's',
        name: 'Compras',
        type: ListType.shopping,
        items: [_item('a', title: 'Teclado', listId: 's', price: 100)],
        createdAt: _now,
      );
      final controller = await pumpDetail(tester, list);

      expect(find.text('Total: 100.00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit_a')));
      await tester.pumpAndSettle();
      expect(find.text('Detalles del elemento'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('item_editor_store')),
        'Alkosto',
      );
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(controller.updated.single.store, 'Alkosto');
      expect(controller.updated.single.price, 100);

      await tester.tap(find.byKey(const ValueKey('edit_a')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(controller.updated, hasLength(1));
    });

    testWidgets('add with details sends the draft to the controller', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 't',
        name: 'Pendientes',
        type: ListType.tasks,
        items: const [],
        createdAt: _now,
      );
      final controller = await pumpDetail(tester, list);

      await tester.enterText(find.byType(TextField).last, 'Llamar');
      await tester.tap(find.byKey(const Key('quick_add_details_button')));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo item'), findsOneWidget);
      await tester.tap(find.byKey(const Key('priority_high')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(controller.added.single.$1, 'Llamar');
      expect(controller.added.single.$2!.priority, ItemPriority.high);
      expect(controller.added.single.$2!.listId, 't');

      await tester.tap(find.byKey(const Key('quick_add_details_button')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(controller.added, hasLength(1));
    });

    testWidgets('shopping links open through the url launcher', (tester) async {
      final opened = <String>[];
      final list = ShoppingList(
        id: 's',
        name: 'Compras',
        type: ListType.shopping,
        items: [_item('a', listId: 's', url: 'https://shop.test/p')],
        createdAt: _now,
      );
      await pumpDetail(tester, list, openedUrls: opened);

      await tester.tap(find.byKey(const ValueKey('link_a')));
      await tester.pump();

      expect(opened, ['https://shop.test/p']);
    });

    testWidgets('custom lists edit name, description and notes', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'c',
        name: 'Libre',
        items: [_item('a', title: 'Algo', listId: 'c')],
        createdAt: _now,
      );
      await pumpDetail(tester, list);

      expect(find.byKey(const Key('quick_add_details_button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('item_editor_description')), findsOneWidget);
      expect(find.byKey(const Key('item_editor_notes')), findsOneWidget);
    });
  });

  group('Option attributes and extended details (SQLite)', () {
    late SqliteListsRepository repository;

    setUp(() async {
      AppDatabase.overrideDbPath = inMemoryDatabasePath;
      final db = await AppDatabase.instance.database;
      await db.delete('items');
      await db.delete('collaborators');
      await db.delete('lists');
      await db.delete('pending_operations');
      repository = SqliteListsRepository();
    });

    test('updateListAttributes persists names and clears them', () async {
      final list = await repository.createList(
        'Universidades',
        type: ListType.options,
      );

      await repository.updateListAttributes(list.id, ['Matrícula', 'Área']);
      expect((await repository.getListById(list.id))!.attributeNames, [
        'Matrícula',
        'Área',
      ]);

      await repository.updateListAttributes(list.id, []);
      expect((await repository.getListById(list.id))!.attributeNames, isEmpty);
    });

    test('updateListAttributes queues a change for shared lists', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      await repository.setListShared(list.id, true, hasInvite: true);
      await repository.clearPendingOperationsForList(list.id);

      await repository.updateListAttributes(list.id, ['Precio']);

      final ops = await repository.getPendingOperations(listId: list.id);
      expect(ops.single.payload!['option_attributes'], ['Precio']);
    });

    test('item attributes, image and evaluation persist', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      final created = await repository.addItem(
        list.id,
        'UNAL',
        details: _item(
          'x',
          description: 'Pública',
          imageUrl: 'https://img.test/u.png',
          attributes: {'Matrícula': 'Baja'},
          evaluation: ItemEvaluation.evaluated,
        ),
      );

      final stored = (await repository.getListById(list.id))!.items.single;
      expect(stored.id, created.id);
      expect(stored.attributes, {'Matrícula': 'Baja'});
      expect(stored.evaluation, ItemEvaluation.evaluated);
      expect(stored.imageUrl, 'https://img.test/u.png');
      expect(stored.description, 'Pública');
    });

    test('row mapper tolerates missing or corrupt json', () async {
      final db = await AppDatabase.instance.database;
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      final created = await repository.addItem(list.id, 'A');
      await db.update(
        'items',
        {'attributes': '{not json'},
        where: 'id = ?',
        whereArgs: [created.id],
      );
      await db.update(
        'lists',
        {'option_attributes': '[broken'},
        where: 'id = ?',
        whereArgs: [list.id],
      );

      final stored = (await repository.getListById(list.id))!;
      expect(stored.items.single.attributes, isEmpty);
      expect(stored.attributeNames, isEmpty);
    });

    test('restoreList and backup keep attribute names', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      await repository.updateListAttributes(list.id, ['Área']);
      await repository.addItem(
        list.id,
        'A',
        details: _item('x', attributes: {'Área': '40'}),
      );
      final snapshot = (await repository.getListById(list.id))!;
      final source = BackupLocalDataSourceImpl();

      final exported = await source.fetchAllLists();
      expect(exported.single.attributeNames, ['Área']);

      await repository.deleteList(list.id);
      await repository.restoreList(snapshot);
      var restored = (await repository.getListById(list.id))!;
      expect(restored.attributeNames, ['Área']);

      await source.restoreLists(exported, replaceExisting: true);
      restored = (await repository.getListById(list.id))!;
      expect(restored.items.single.attributes, {'Área': '40'});
    });

    test(
      'saveRemoteList keeps local attribute names when remote lacks them',
      () async {
        final list = await repository.createList(
          'Opciones',
          type: ListType.options,
        );
        await repository.updateListAttributes(list.id, ['Área']);

        await repository.saveRemoteList(
          ShoppingList(id: list.id, name: 'Opciones', createdAt: _now),
        );
        expect((await repository.getListById(list.id))!.attributeNames, [
          'Área',
        ]);

        await repository.saveRemoteList(
          ShoppingList(
            id: list.id,
            name: 'Opciones',
            attributeNames: const ['Precio'],
            createdAt: _now,
          ),
        );
        expect((await repository.getListById(list.id))!.attributeNames, [
          'Precio',
        ]);
      },
    );

    test('sharing a list enqueues its attribute names', () async {
      final list = await repository.createList(
        'Opciones',
        type: ListType.options,
      );
      await repository.updateListAttributes(list.id, ['Área']);

      await repository.setListShared(list.id, true, hasInvite: true);

      final payloads = (await repository.getPendingOperations(
        listId: list.id,
      )).map((o) => o.payload!);
      expect(payloads.any((p) => p['option_attributes'] != null), isTrue);
    });
  });

  group('Controller list attributes', () {
    test('updateListAttributes updates state and storage', () async {
      AppDatabase.overrideDbPath = inMemoryDatabasePath;
      final db = await AppDatabase.instance.database;
      await db.delete('items');
      await db.delete('lists');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(listsControllerProvider.future);
      final controller = container.read(listsControllerProvider.notifier);
      final list = await controller.createList(
        'Opciones',
        type: ListType.options,
      );

      await controller.updateListAttributes(list.id, ['Área', 'Piso']);

      expect(
        container.read(listsControllerProvider).value!.single.attributeNames,
        ['Área', 'Piso'],
      );
      final stored = await container.read(listsRepositoryProvider).getLists();
      expect(stored.single.attributeNames, ['Área', 'Piso']);
    });
  });

  group('Item editor for extended fields', () {
    Future<void> openSheet(
      WidgetTester tester, {
      required ListType type,
      required TodoItem draft,
      List<String> attributeNames = const [],
      required void Function(TodoItem?) onResult,
    }) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await showItemEditorSheet(
                  context,
                  type: type,
                  strings: _spanish,
                  draft: draft,
                  attributeNames: attributeNames,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();
    }

    testWidgets('options: image, description, attributes and evaluation', (
      tester,
    ) async {
      TodoItem? saved;
      await openSheet(
        tester,
        type: ListType.options,
        draft: _item(
          'o1',
          title: 'Apto',
          attributes: {'Área': '40', 'Viejo': 'x'},
        ),
        attributeNames: const ['Área', 'Piso'],
        onResult: (item) => saved = item,
      );

      expect(find.byKey(const Key('item_editor_attr_Área')), findsOneWidget);
      expect(find.byKey(const Key('item_editor_attr_Piso')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('item_editor_image')),
        'https://img.test/apto.png',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_description')),
        'Cerca al metro',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_attr_Área')),
        '',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_attr_Piso')),
        '5',
      );
      await tester.ensureVisible(find.byKey(const Key('evaluation_evaluated')));
      await tester.tap(find.byKey(const Key('evaluation_evaluated')));
      await tester.pump();
      await save(tester);

      expect(saved!.imageUrl, 'https://img.test/apto.png');
      expect(saved!.description, 'Cerca al metro');
      expect(saved!.attributes, {'Viejo': 'x', 'Piso': '5'});
      expect(saved!.evaluation, ItemEvaluation.evaluated);
    });

    testWidgets('image links must be http(s)', (tester) async {
      TodoItem? saved;
      await openSheet(
        tester,
        type: ListType.shopping,
        draft: _item('s1'),
        onResult: (item) => saved = item,
      );

      await tester.enterText(
        find.byKey(const Key('item_editor_image')),
        'nope',
      );
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pump();
      expect(
        find.text('Ingresa un enlace de imagen http(s) válido'),
        findsOneWidget,
      );
      expect(saved, isNull);

      await tester.enterText(find.byKey(const Key('item_editor_image')), '');
      await save(tester);
      expect(saved!.imageUrl, isNull);
    });

    testWidgets('market captures the estimated price', (tester) async {
      TodoItem? saved;
      await openSheet(
        tester,
        type: ListType.market,
        draft: _item('m1'),
        onResult: (item) => saved = item,
      );
      await tester.ensureVisible(find.byKey(const Key('item_editor_price')));
      await tester.enterText(find.byKey(const Key('item_editor_price')), '3,5');
      await save(tester);
      expect(saved!.price, 3.5);
    });

    testWidgets('tasks capture description and notes', (tester) async {
      TodoItem? saved;
      await openSheet(
        tester,
        type: ListType.tasks,
        draft: _item('t1'),
        onResult: (item) => saved = item,
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_description')),
        'Llevar documentos',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_notes')),
        'Piso 2',
      );
      await save(tester);
      expect(saved!.description, 'Llevar documentos');
      expect(saved!.notes, 'Piso 2');
    });

    testWidgets('custom items capture description and notes', (tester) async {
      TodoItem? saved;
      await openSheet(
        tester,
        type: ListType.custom,
        draft: _item('c1'),
        onResult: (item) => saved = item,
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_description')),
        'Algo',
      );
      await tester.enterText(
        find.byKey(const Key('item_editor_notes')),
        'Nota',
      );
      await save(tester);
      expect(saved!.description, 'Algo');
      expect(saved!.notes, 'Nota');
    });
  });

  group('Item card variants', () {
    Future<void> pump(
      WidgetTester tester,
      TodoItem item,
      ListType type, {
      VoidCallback? onEdit,
    }) => tester.pumpWidget(
      _host(
        TodoItemTile(
          item: item,
          listType: type,
          strings: _spanish,
          onToggle: () {},
          onDelete: () {},
          onEdit: onEdit,
        ),
      ),
    );

    testWidgets('thumbnails fall back to an icon when the image fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ItemThumbnail(
            imageUrl: 'https://img.invalid/missing.png',
            fallbackIcon: Icons.image_outlined,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('thumbnails without a link show the placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ItemThumbnail(
            imageUrl: null,
            fallbackIcon: Icons.image_outlined,
          ),
        ),
      );
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('market shows quantity and estimated price', (tester) async {
      await pump(
        tester,
        _item('a', quantity: 2, unit: 'kg', price: 3.5),
        ListType.market,
      );
      expect(find.text('2 kg'), findsOneWidget);
      expect(find.text('3.50'), findsOneWidget);
      expect(find.byType(ItemCheckbox), findsOneWidget);
    });

    testWidgets('shopping shows a thumbnail and highlighted price', (
      tester,
    ) async {
      await pump(
        tester,
        _item('a', price: 99, imageUrl: 'https://img.test/x.png'),
        ListType.shopping,
      );
      expect(find.byKey(const ValueKey('thumb_a')), findsOneWidget);
      expect(find.byKey(const ValueKey('price_a')), findsOneWidget);

      await pump(tester, _item('b'), ListType.shopping);
      expect(find.byKey(const ValueKey('thumb_b')), findsNothing);
      expect(find.byKey(const ValueKey('price_b')), findsNothing);
    });

    testWidgets('options are not checkbox rows and dim when discarded', (
      tester,
    ) async {
      await pump(
        tester,
        _item(
          'a',
          imageUrl: 'https://img.test/o.png',
          evaluation: ItemEvaluation.discarded,
          isChosen: true,
        ),
        ListType.options,
      );
      expect(find.byType(ItemCheckbox), findsNothing);
      expect(find.byKey(const ValueKey('thumb_a')), findsOneWidget);
      expect(find.text('Descartada'), findsOneWidget);
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.45);
    });

    testWidgets('options fall back to notes and hide pending evaluation', (
      tester,
    ) async {
      await pump(
        tester,
        _item('a', notes: 'Llamar', evaluation: ItemEvaluation.pending),
        ListType.options,
      );
      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('Por evaluar'), findsNothing);
    });

    testWidgets('tasks show description before notes', (tester) async {
      await pump(
        tester,
        _item('a', description: 'Detalle', notes: 'Nota'),
        ListType.tasks,
      );
      expect(find.text('Detalle'), findsOneWidget);
      expect(find.text('Nota'), findsNothing);
      expect(find.byType(ItemCheckbox), findsOneWidget);
    });

    testWidgets('custom shows notes when there is no description', (
      tester,
    ) async {
      await pump(tester, _item('a', notes: 'Solo nota'), ListType.custom);
      expect(find.text('Solo nota'), findsOneWidget);
    });
  });

  group('Options tools in the detail screen', () {
    ShoppingList optionsList({List<String> names = const ['Área']}) =>
        ShoppingList(
          id: 'o',
          name: 'Apartamentos',
          type: ListType.options,
          attributeNames: names,
          items: [
            _item(
              'a',
              title: 'Centro',
              listId: 'o',
              isFavorite: true,
              attributes: {'Área': '40'},
              evaluation: ItemEvaluation.evaluated,
            ),
            _item('b', title: 'Norte', listId: 'o'),
          ],
          createdAt: _now,
        );

    Future<_RecordingController> pumpOptions(
      WidgetTester tester,
      ShoppingList list,
    ) async {
      final controller = _RecordingController([list]);
      final router = GoRouter(
        initialLocation: '/list/o',
        routes: [
          GoRoute(
            path: '/list/:id',
            builder: (context, state) =>
                ListDetailScreen(listId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [listsControllerProvider.overrideWith(() => controller)],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('only options lists show the compare and attribute actions', (
      tester,
    ) async {
      await pumpOptions(tester, optionsList());
      expect(find.byKey(const Key('compare_options_button')), findsOneWidget);
      expect(find.byKey(const Key('manage_attributes_button')), findsOneWidget);
      expect(find.text('Área: 40'), findsOneWidget);
    });

    testWidgets('attribute dialog adds, rejects duplicates and removes', (
      tester,
    ) async {
      final controller = await pumpOptions(tester, optionsList());

      await tester.tap(find.byKey(const Key('manage_attributes_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attribute_chip_Área')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('attribute_name_input')),
        'Piso',
      );
      await tester.tap(find.byKey(const Key('attribute_add_button')));
      await tester.pumpAndSettle();
      expect(controller.attributeCalls.last, ['Área', 'Piso']);
      expect(find.byKey(const Key('attribute_chip_Piso')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('attribute_name_input')),
        'piso',
      );
      await tester.tap(find.byKey(const Key('attribute_add_button')));
      await tester.enterText(
        find.byKey(const Key('attribute_name_input')),
        '  ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.attributeCalls, hasLength(1));

      await tester.enterText(
        find.byKey(const Key('attribute_name_input')),
        'Precio',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(controller.attributeCalls.last, ['Área', 'Piso', 'Precio']);

      await tester.tap(find.byTooltip('Quitar atributo').first);
      await tester.pumpAndSettle();
      expect(controller.attributeCalls.last, ['Piso', 'Precio']);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attribute_add_button')), findsNothing);
    });

    testWidgets('attribute dialog explains the empty state', (tester) async {
      await pumpOptions(tester, optionsList(names: const []));
      await tester.tap(find.byKey(const Key('manage_attributes_button')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Aún no hay atributos. Agrega las características que quieras comparar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('compare sheet shows the table and chooses an option', (
      tester,
    ) async {
      final controller = await pumpOptions(tester, optionsList());

      await tester.tap(find.byKey(const Key('compare_options_button')));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('Evaluada'),
        ),
        findsOneWidget,
      );
      expect(find.text('—'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('compare_choose_b')));
      await tester.pumpAndSettle();
      expect(controller.chosen, ['b']);
      final rows = tester.widget<DataTable>(find.byType(DataTable)).rows;
      expect(
        rows
            .firstWhere((r) => r.key == const ValueKey('compare_row_b'))
            .selected,
        isTrue,
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('compare sheet needs at least two options', (tester) async {
      final single = optionsList().copyWith(
        items: [_item('a', title: 'Solo', listId: 'o')],
      );
      await pumpOptions(tester, single);

      await tester.tap(find.byKey(const Key('compare_options_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Agrega al menos dos opciones para compararlas.'),
        findsOneWidget,
      );
    });
  });
}

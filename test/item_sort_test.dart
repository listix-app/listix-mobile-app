import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/features/lists/domain/entities/list_type.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_type_presentation.dart';

TodoItem _item(
  String id, {
  double? price,
  ItemPriority? priority,
  DateTime? dueDate,
  int? rating,
  bool isChosen = false,
  bool isInProgress = false,
  bool isCompleted = false,
  ItemEvaluation? evaluation,
}) => TodoItem(
  id: id,
  listId: 'l',
  title: id,
  createdAt: DateTime(2026),
  price: price,
  priority: priority,
  dueDate: dueDate,
  rating: rating,
  isChosen: isChosen,
  isInProgress: isInProgress,
  isCompleted: isCompleted,
  evaluation: evaluation,
);

List<String> _ids(List<TodoItem> items) => items.map((i) => i.id).toList();

void main() {
  group('ItemSort', () {
    final items = [
      _item('none'),
      _item(
        'b',
        price: 5,
        priority: ItemPriority.low,
        dueDate: DateTime(2026, 3),
        rating: 3,
      ),
      _item(
        'a',
        price: 2,
        priority: ItemPriority.high,
        dueDate: DateTime(2026, 1),
        rating: 5,
      ),
      _item('c', price: 9, rating: 4),
      _item('none2'),
    ];

    test('manual keeps the original order', () {
      expect(ItemSort.manual.apply(items), same(items));
    });

    test('price sorts ascending with missing prices last', () {
      expect(_ids(ItemSort.price.apply(items)), [
        'a',
        'b',
        'c',
        'none',
        'none2',
      ]);
    });

    test('missing values stay last whichever side they are compared on', () {
      final priced = _item('priced', price: 1);
      final missing = _item('missing');
      expect(_ids(ItemSort.price.apply([priced, missing])), [
        'priced',
        'missing',
      ]);
      expect(_ids(ItemSort.price.apply([missing, priced])), [
        'priced',
        'missing',
      ]);
    });

    test('priority sorts high first with missing priorities last', () {
      expect(_ids(ItemSort.priority.apply(items)), [
        'a',
        'b',
        'none',
        'c',
        'none2',
      ]);
    });

    test('dueDate sorts soonest first with missing dates last', () {
      expect(_ids(ItemSort.dueDate.apply(items)), [
        'a',
        'b',
        'none',
        'c',
        'none2',
      ]);
    });

    test('rating sorts highest rating first with missing ratings last', () {
      expect(_ids(ItemSort.rating.apply(items)), [
        'a',
        'c',
        'b',
        'none',
        'none2',
      ]);
    });
  });

  group('ListType sorting, templates and summaries', () {
    test('sort options per type and primaryTypes', () {
      expect(ListType.shopping.sortOptions, contains(ItemSort.price));
      expect(ListType.tasks.sortOptions, contains(ItemSort.dueDate));
      expect(ListType.market.sortOptions, [ItemSort.manual]);
      expect(ListType.options.sortOptions, contains(ItemSort.rating));
      expect(ListType.options.sortOptions, contains(ItemSort.price));
      expect(ListType.options.supportsFavoritesFilter, isTrue);
      expect(ListType.tasks.supportsFavoritesFilter, isFalse);
      expect(ListType.primaryTypes, [
        ListType.market,
        ListType.shopping,
        ListType.options,
        ListType.tasks,
      ]);
    });

    test('templates resolve for every primary type in es and en', () {
      for (final type in ListType.primaryTypes) {
        final templates = ListTemplate.templatesFor(type);
        expect(templates, isNotEmpty);
        for (final t in templates) {
          expect(t.name(true), isNotEmpty);
          expect(t.name(false), isNotEmpty);
          expect(t.attributeNames(true), isA<List<String>>());
          expect(t.attributeNames(false), isA<List<String>>());
          for (final seed in t.starterItems) {
            expect(seed.title(true), isNotEmpty);
            expect(seed.title(false), isNotEmpty);
          }
          expect(t.type, type);
        }
      }
      expect(ListTemplate.templatesFor(ListType.custom), isEmpty);
    });

    test('strings resolve for every sort, list type and secondary summary', () {
      for (final language in AppLanguage.values) {
        final tr = AppStrings(language);
        for (final sort in ItemSort.values) {
          expect(tr.sortName(sort), isNotEmpty);
        }
        for (final type in ListType.values) {
          expect(type.accentColor, isNotNull);
        }
        final messages = {
          for (final type in ListType.values) tr.emptyItemsMessageFor(type),
        };
        expect(messages.length, ListType.values.length);
        expect(tr.sortItems, isNotEmpty);
        expect(tr.favoritesOnly, isNotEmpty);
        expect(tr.prosLabel, isNotEmpty);
        expect(tr.consLabel, isNotEmpty);
        expect(tr.ratingLabel, isNotEmpty);
        expect(tr.subtasksLabel, isNotEmpty);
        expect(tr.subtaskHint, isNotEmpty);
        expect(tr.addSubtask, isNotEmpty);
        expect(tr.removeSubtask, isNotEmpty);
        expect(tr.duplicateListAction, isNotEmpty);
        expect(tr.listDuplicated, isNotEmpty);
        expect(tr.templatesHeading, isNotEmpty);
        expect(tr.filterAllTypes, isNotEmpty);
        expect(tr.filterCompletedLists, isNotEmpty);
        expect(tr.decreaseQuantity, isNotEmpty);
        expect(tr.increaseQuantity, isNotEmpty);
        expect(tr.statusPending, isNotEmpty);
        expect(tr.statusPurchased, isNotEmpty);
        expect(tr.statusDiscarded, isNotEmpty);

        final marketList = ShoppingList(
          id: 'm',
          name: 'M',
          type: ListType.market,
          items: [_item('1', price: 25)],
          createdAt: DateTime(2026),
        );
        expect(tr.listCardSecondarySummary(marketList), isNotNull);

        final emptyMarketList = marketList.copyWith(items: const []);
        expect(tr.listCardSecondarySummary(emptyMarketList), isNull);

        final optionsList = ShoppingList(
          id: 'o',
          name: 'O',
          type: ListType.options,
          items: [_item('1', isChosen: true)],
          createdAt: DateTime(2026),
        );
        expect(tr.listCardSecondarySummary(optionsList), contains('1'));
        expect(
          tr.listCardSecondarySummary(optionsList.copyWith(items: const [])),
          isNull,
        );

        final tasksList = ShoppingList(
          id: 't',
          name: 'T',
          type: ListType.tasks,
          items: [_item('1', isInProgress: true)],
          createdAt: DateTime(2026),
        );
        expect(tr.listCardSecondarySummary(tasksList), tr.inProgressLabel);
        expect(
          tr.listCardSecondarySummary(tasksList.copyWith(items: const [])),
          isNull,
        );

        final customList = ShoppingList(
          id: 'c',
          name: 'C',
          type: ListType.custom,
          createdAt: DateTime(2026),
        );
        expect(tr.listCardSecondarySummary(customList), isNull);
      }
    });
  });
}

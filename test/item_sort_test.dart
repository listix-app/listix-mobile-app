import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/features/lists/domain/entities/list_type.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_type_presentation.dart';

TodoItem _item(
  String id, {
  double? price,
  ItemPriority? priority,
  DateTime? dueDate,
}) => TodoItem(
  id: id,
  listId: 'l',
  title: id,
  createdAt: DateTime(2026),
  price: price,
  priority: priority,
  dueDate: dueDate,
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
      ),
      _item(
        'a',
        price: 2,
        priority: ItemPriority.high,
        dueDate: DateTime(2026, 1),
      ),
      _item('c', price: 9),
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
  });

  group('ListType sorting and copy', () {
    test('sort options per type', () {
      expect(ListType.shopping.sortOptions, contains(ItemSort.price));
      expect(ListType.tasks.sortOptions, contains(ItemSort.dueDate));
      expect(ListType.market.sortOptions, [ItemSort.manual]);
      expect(ListType.options.supportsFavoritesFilter, isTrue);
      expect(ListType.tasks.supportsFavoritesFilter, isFalse);
    });

    test('strings resolve for every sort and list type', () {
      for (final language in AppLanguage.values) {
        final tr = AppStrings(language);
        for (final sort in ItemSort.values) {
          expect(tr.sortName(sort), isNotEmpty);
        }
        final messages = {
          for (final type in ListType.values) tr.emptyItemsMessageFor(type),
        };
        expect(messages.length, ListType.values.length);
        expect(tr.sortItems, isNotEmpty);
        expect(tr.favoritesOnly, isNotEmpty);
      }
    });
  });
}

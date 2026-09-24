import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/features/ads/presentation/controllers/banner_ad_controller.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';

void main() {
  group('Collaborator Entity', () {
    test('initials handles full name, single name, and empty name', () {
      const c1 = Collaborator(
        id: '1',
        name: 'Maria Perez',
        email: 'maria@test.com',
      );
      expect(c1.initials, 'MP');

      const c2 = Collaborator(id: '2', name: 'Carlos', email: 'c@test.com');
      expect(c2.initials, 'C');

      const c3 = Collaborator(id: '3', name: '', email: 'empty@test.com');
      expect(c3.initials, '?');
    });

    test('equality and hashCode contract', () {
      const c1 = Collaborator(
        id: '1',
        name: 'Ana',
        email: 'a@test.com',
        isOwner: true,
      );
      const c2 = Collaborator(
        id: '1',
        name: 'Ana',
        email: 'a@test.com',
        isOwner: true,
      );
      const c3 = Collaborator(
        id: '2',
        name: 'Ana',
        email: 'a@test.com',
        isOwner: false,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1 == c1, isTrue);
      expect(c1 == c3, isFalse);
      expect(c1 == Object(), isFalse);
    });
  });

  group('TodoItem Entity', () {
    final now = DateTime(2026, 9, 22);

    test('copyWith works correctly', () {
      final item = TodoItem(
        id: 't1',
        listId: 'l1',
        title: 'Leche',
        isCompleted: false,
        isSynced: false,
        createdAt: now,
      );

      final updated = item.copyWith(
        title: 'Leche deslactosada',
        isCompleted: true,
        isSynced: true,
      );

      expect(updated.title, 'Leche deslactosada');
      expect(updated.isCompleted, isTrue);
      expect(updated.isSynced, isTrue);
      expect(updated.id, 't1');
      expect(updated.listId, 'l1');
      expect(updated.createdAt, now);

      final defaultCopy = item.copyWith();
      expect(defaultCopy, equals(item));
    });

    test('equality and hashCode', () {
      final i1 = TodoItem(
        id: 't1',
        listId: 'l1',
        title: 'Manzanas',
        createdAt: now,
      );
      final i2 = TodoItem(
        id: 't1',
        listId: 'l1',
        title: 'Manzanas',
        createdAt: now,
      );
      final i3 = TodoItem(
        id: 't2',
        listId: 'l1',
        title: 'Peras',
        createdAt: now,
      );

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1 == i3, isFalse);
      expect(i1 == Object(), isFalse);
    });
  });

  group('ShoppingList Entity', () {
    final now = DateTime(2026, 9, 22);

    test('computed properties and progressText', () {
      final item1 = TodoItem(
        id: '1',
        listId: 'l1',
        title: 'A',
        isCompleted: true,
        createdAt: now,
      );
      final item2 = TodoItem(
        id: '2',
        listId: 'l1',
        title: 'B',
        isCompleted: false,
        createdAt: now,
      );
      const collab = Collaborator(id: 'c1', name: 'User', email: 'u@test.com');

      final list = ShoppingList(
        id: 'l1',
        name: 'Supermercado',
        items: [item1, item2],
        collaborators: const [collab],
        createdAt: now,
      );

      expect(list.totalCount, 2);
      expect(list.completedCount, 1);
      expect(list.pendingCount, 1);
      expect(list.progressText, '1 de 2');
      expect(list.isShared, isFalse);
      expect(list.copyWith(isShared: true).isShared, isTrue);
    });

    test('copyWith updates and falls back to original values', () {
      final list = ShoppingList(id: 'l1', name: 'Hogar', createdAt: now);

      expect(list.isShared, isFalse);

      final modified = list.copyWith(name: 'Ferretería', isSynced: true);
      expect(modified.name, 'Ferretería');
      expect(modified.isSynced, isTrue);
      expect(modified.id, 'l1');

      final defaultCopy = list.copyWith();
      expect(defaultCopy, equals(list));
    });

    test('equality and hashCode', () {
      final l1 = ShoppingList(id: 'l1', name: 'Compras', createdAt: now);
      final l2 = ShoppingList(id: 'l1', name: 'Compras', createdAt: now);
      final l3 = ShoppingList(id: 'l2', name: 'Otras', createdAt: now);

      expect(l1, equals(l2));
      expect(l1.hashCode, equals(l2.hashCode));
      expect(l1 == l3, isFalse);
      expect(l1 == Object(), isFalse);
    });

    test('isShared boolean serialization and explicit toggle', () {
      final localList = ShoppingList(
        id: 'l1',
        name: 'Solo local',
        isShared: false,
        createdAt: now,
      );
      expect(localList.isShared, isFalse);

      final sharedList = ShoppingList(
        id: 'l2',
        name: 'Compartida nube',
        isShared: true,
        createdAt: now,
      );
      expect(sharedList.isShared, isTrue);

      final jsonShared = sharedList.toJson();
      expect(jsonShared['isShared'], isTrue);

      final fromJsonList = ShoppingList.fromJson(jsonShared);
      expect(fromJsonList.isShared, isTrue);
      expect(fromJsonList.id, 'l2');

      final toggledOff = sharedList.copyWith(isShared: false);
      expect(toggledOff.isShared, isFalse);
    });
  });

  group('BannerAdStatus & SyncStatus', () {
    test('banner ad status enum values', () {
      expect(BannerAdStatus.values.length, 3);
      expect(BannerAdStatus.loading, isNotNull);
      expect(BannerAdStatus.loaded, isNotNull);
      expect(BannerAdStatus.failed, isNotNull);
    });

    test('sync status enum values', () {
      expect(SyncStatus.values.length, 4);
      expect(SyncStatus.synced, isNotNull);
      expect(SyncStatus.syncing, isNotNull);
      expect(SyncStatus.offline, isNotNull);
      expect(SyncStatus.pendingChanges, isNotNull);
    });
  });
}

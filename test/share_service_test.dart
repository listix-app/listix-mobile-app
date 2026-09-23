import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/services/share_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 22);
  final tr = AppStrings(AppLanguage.es);

  group('ShareService Tests', () {
    test('formatListForSharing with empty items', () {
      final list = ShoppingList(
        id: '1',
        name: 'Lista Vacía',
        items: const [],
        createdAt: now,
      );

      final text = ShareService.formatListForSharing(
        list: list,
        createdWithText: tr.sharedWithListix,
      );
      expect(text, contains('📋 *Lista Vacía*'));
      expect(text, contains('• (Empty)'));
      expect(text, contains('Creado con Listix'));
    });

    test('formatListForSharing with pending and completed items', () {
      final list = ShoppingList(
        id: '2',
        name: 'Supermercado',
        items: [
          TodoItem(
            id: 'i1',
            listId: '2',
            title: 'Leche',
            isCompleted: false,
            createdAt: now,
          ),
          TodoItem(
            id: 'i2',
            listId: '2',
            title: 'Huevos',
            isCompleted: true,
            createdAt: now,
          ),
        ],
        createdAt: now,
      );

      final text = ShareService.formatListForSharing(
        list: list,
        createdWithText: tr.sharedWithListix,
      );
      expect(text, contains('📋 *Supermercado*'));
      expect(text, contains('• Leche'));
      expect(text, contains('✓ Huevos'));
    });

    test(
      'shareToWhatsApp tries native scheme first, then web fallback',
      () async {
        final launchedUris = <String>[];
        final service = ShareService(
          urlLauncher:
              (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
                launchedUris.add(uri.toString());
                // Native fails, so fallback is triggered
                if (uri.scheme == 'whatsapp') return false;
                return true;
              },
        );

        final result = await service.shareToWhatsApp('Hola mundo');
        expect(result, isTrue);
        expect(launchedUris.length, 2);
        expect(launchedUris.first, startsWith('whatsapp://send?text='));
        expect(
          launchedUris.last,
          startsWith('https://api.whatsapp.com/send?text='),
        );
      },
    );

    test('shareToWhatsApp succeeds immediately on native scheme', () async {
      final launchedUris = <String>[];
      final service = ShareService(
        urlLauncher:
            (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
              launchedUris.add(uri.toString());
              return true;
            },
      );

      final result = await service.shareToWhatsApp('Hola mundo');
      expect(result, isTrue);
      expect(launchedUris.length, 1);
      expect(launchedUris.first, startsWith('whatsapp://send?text='));
    });

    test('shareToWhatsApp returns false when both fail or throw', () async {
      final service = ShareService(
        urlLauncher:
            (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
              throw Exception('Intent failed');
            },
      );

      final result = await service.shareToWhatsApp('Hola mundo');
      expect(result, isFalse);
    });

    test('shareToGmail launches mailto scheme successfully', () async {
      final launchedUris = <String>[];
      final service = ShareService(
        urlLauncher:
            (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
              launchedUris.add(uri.toString());
              return true;
            },
      );

      final result = await service.shareToGmail(
        subject: 'Mi Lista',
        body: 'Contenido de la lista',
      );
      expect(result, isTrue);
      expect(launchedUris.first, startsWith('mailto:?'));
      expect(launchedUris.first, contains('subject=Mi%20Lista'));
      expect(launchedUris.first, contains('body=Contenido%20de%20la%20lista'));
    });

    test('shareToGmail returns false when launch fails or throws', () async {
      final service = ShareService(
        urlLauncher:
            (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
              throw Exception('Mailto failed');
            },
      );

      final result = await service.shareToGmail(
        subject: 'Mi Lista',
        body: 'Contenido',
      );
      expect(result, isFalse);
    });

    test('copyToClipboard copies formatted text without errors', () async {
      final service = ShareService();
      await service.copyToClipboard('Texto de prueba');
    });

    test('shareServiceProvider provides ShareService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(shareServiceProvider);
      expect(service, isA<ShareService>());
    });
  });
}

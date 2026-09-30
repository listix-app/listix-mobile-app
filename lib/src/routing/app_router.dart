import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/screens/about_screen.dart';
import '../features/collaboration/domain/services/invite_token_service.dart';
import '../features/collaboration/presentation/screens/join_invite_screen.dart';
import '../features/lists/presentation/screens/create_edit_list_screen.dart';
import '../features/lists/presentation/screens/home_screen.dart';
import '../features/lists/presentation/screens/list_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final uri = state.uri;
      final host = uri.host.toLowerCase();
      final scheme = uri.scheme.toLowerCase();
      final isJoinLink =
          (host == 'join' && (scheme.isEmpty || scheme == 'listix')) ||
          (scheme == 'listix' && uri.pathSegments.contains('join')) ||
          ((scheme == 'http' || scheme == 'https') &&
              uri.pathSegments.contains('join'));

      if (isJoinLink) {
        final token = uri.pathSegments.firstWhere(
          (segment) => segment.isNotEmpty && segment.toLowerCase() != 'join',
          // coverage:ignore-start
          orElse: () => uri.path.replaceAll(RegExp(r'^/+'), '').trim(),
          // coverage:ignore-end
        );
        if (token.isNotEmpty) {
          final cleanCode = InviteTokenService.extractToken(token) ?? token;
          return AppRoutes.joinListPath(cleanCode);
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.newList,
        builder: (context, state) => const CreateEditListScreen(),
      ),
      GoRoute(
        path: AppRoutes.listDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ListDetailScreen(listId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editList,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CreateEditListScreen(listId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.joinList,
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return JoinInviteScreen(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

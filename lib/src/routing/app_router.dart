import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/screens/about_screen.dart';
import '../features/lists/presentation/screens/create_edit_list_screen.dart';
import '../features/lists/presentation/screens/home_screen.dart';
import '../features/lists/presentation/screens/list_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
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
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});

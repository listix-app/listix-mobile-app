abstract final class AppRoutes {
  static const String home = '/';
  static const String newList = '/lists/new';
  static const String listDetail = '/list/:id';
  static const String editList = '/list/:id/edit';
  static const String settings = '/settings';
  static const String about = '/about';

  static String listDetailPath(String id) => '/list/$id';
  static String editListPath(String id) => '/list/$id/edit';
}

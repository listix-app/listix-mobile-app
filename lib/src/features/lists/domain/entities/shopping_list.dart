import 'package:flutter/foundation.dart';

import 'collaborator.dart';
import 'todo_item.dart';

class ShoppingList {
  final String id;
  final String name;
  final bool isSynced;
  final bool isStarred;
  final int position;
  final List<TodoItem> items;
  final List<Collaborator> collaborators;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    this.isSynced = false,
    this.isStarred = false,
    this.position = 0,
    this.items = const [],
    this.collaborators = const [],
    required this.createdAt,
  });

  int get totalCount => items.length;
  int get completedCount => items.where((item) => item.isCompleted).length;
  int get pendingCount => totalCount - completedCount;

  String get progressText => '$pendingCount de $totalCount';
  double get completionProgress =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  bool get isShared => collaborators.isNotEmpty;

  ShoppingList copyWith({
    String? id,
    String? name,
    bool? isSynced,
    bool? isStarred,
    int? position,
    List<TodoItem>? items,
    List<Collaborator>? collaborators,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      isSynced: isSynced ?? this.isSynced,
      isStarred: isStarred ?? this.isStarred,
      position: position ?? this.position,
      items: items ?? this.items,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isSynced == other.isSynced &&
          isStarred == other.isStarred &&
          position == other.position &&
          listEquals(items, other.items) &&
          listEquals(collaborators, other.collaborators);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isSynced,
    isStarred,
    position,
    Object.hashAll(items),
    Object.hashAll(collaborators),
  );
}

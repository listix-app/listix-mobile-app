import 'package:flutter/foundation.dart';

import 'collaborator.dart';
import 'todo_item.dart';

class ShoppingList {
  final String id;
  final String name;
  final bool isSynced;
  final bool isStarred;
  final bool isShared;
  final bool hasInvite;
  final int position;
  final List<TodoItem> items;
  final List<Collaborator> collaborators;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    this.isSynced = false,
    this.isStarred = false,
    this.isShared = false,
    this.hasInvite = false,
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

  bool get canSyncAndShare =>
      isShared && (hasInvite || collaborators.isNotEmpty);

  ShoppingList copyWith({
    String? id,
    String? name,
    bool? isSynced,
    bool? isStarred,
    bool? isShared,
    bool? hasInvite,
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
      isShared: isShared ?? this.isShared,
      hasInvite: hasInvite ?? this.hasInvite,
      position: position ?? this.position,
      items: items ?? this.items,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isSynced': isSynced,
    'isStarred': isStarred,
    'isShared': isShared,
    'hasInvite': hasInvite,
    'position': position,
    'items': items.map((i) => i.toJson()).toList(),
    'collaborators': collaborators.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      isSynced: json['isSynced'] as bool? ?? false,
      isStarred: json['isStarred'] as bool? ?? false,
      isShared: json['isShared'] as bool? ?? false,
      hasInvite: json['hasInvite'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((i) => TodoItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      collaborators:
          (json['collaborators'] as List<dynamic>?)
              ?.map((c) => Collaborator.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
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
          isShared == other.isShared &&
          hasInvite == other.hasInvite &&
          position == other.position &&
          listEquals(items, other.items) &&
          listEquals(collaborators, other.collaborators) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isSynced,
    isStarred,
    isShared,
    hasInvite,
    position,
    Object.hashAll(items),
    Object.hashAll(collaborators),
    createdAt,
  );
}

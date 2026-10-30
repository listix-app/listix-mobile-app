import 'package:flutter/foundation.dart';

import 'collaborator.dart';
import 'list_type.dart';
import 'todo_item.dart';

class ShoppingList {
  final String id;
  final String name;
  final ListType? _type;
  final List<String> attributeNames;
  final bool isSynced;
  final bool isStarred;
  final bool isShared;
  final bool hasInvite;
  final bool isArchived;
  final int? color;
  final bool isOwner;
  final int position;
  final List<TodoItem> items;
  final List<Collaborator> collaborators;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    ListType type = ListType.custom,
    this.attributeNames = const [],
    this.isSynced = false,
    this.isStarred = false,
    this.isShared = false,
    this.hasInvite = false,
    this.isArchived = false,
    this.color,
    this.isOwner = true,
    this.position = 0,
    this.items = const [],
    this.collaborators = const [],
    required this.createdAt,
  }) : _type = type;

  ListType get type => _type ?? ListType.custom;

  int get totalCount => items.length;
  int get completedCount => items.where((item) => item.isCompleted).length;
  int get pendingCount => totalCount - completedCount;

  String get progressText => '$pendingCount de $totalCount';
  double get completionProgress =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + (item.price ?? 0.0));

  bool get canSyncAndShare =>
      isShared && (hasInvite || collaborators.isNotEmpty);

  ShoppingList copyWith({
    String? id,
    String? name,
    ListType? type,
    List<String>? attributeNames,
    bool? isSynced,
    bool? isStarred,
    bool? isShared,
    bool? hasInvite,
    bool? isArchived,
    int? color,
    bool? isOwner,
    int? position,
    List<TodoItem>? items,
    List<Collaborator>? collaborators,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      attributeNames: attributeNames ?? this.attributeNames,
      isSynced: isSynced ?? this.isSynced,
      isStarred: isStarred ?? this.isStarred,
      isShared: isShared ?? this.isShared,
      hasInvite: hasInvite ?? this.hasInvite,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
      isOwner: isOwner ?? this.isOwner,
      position: position ?? this.position,
      items: items ?? this.items,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    if (attributeNames.isNotEmpty) 'attributeNames': attributeNames,
    'isSynced': isSynced,
    'isStarred': isStarred,
    'isShared': isShared,
    'hasInvite': hasInvite,
    'isArchived': isArchived,
    'color': color,
    'isOwner': isOwner,
    'position': position,
    'items': items.map((i) => i.toJson()).toList(),
    'collaborators': collaborators.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ListType.fromName(json['type'] as String?),
      attributeNames: List<String>.from(
        (json['attributeNames'] as List?) ?? const <String>[],
      ),
      isSynced: json['isSynced'] as bool? ?? false,
      isStarred: json['isStarred'] as bool? ?? false,
      isShared: json['isShared'] as bool? ?? false,
      hasInvite: json['hasInvite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      color: json['color'] as int?,
      isOwner: json['isOwner'] as bool? ?? true,
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
          type == other.type &&
          listEquals(attributeNames, other.attributeNames) &&
          isSynced == other.isSynced &&
          isStarred == other.isStarred &&
          isShared == other.isShared &&
          hasInvite == other.hasInvite &&
          isArchived == other.isArchived &&
          color == other.color &&
          isOwner == other.isOwner &&
          position == other.position &&
          listEquals(items, other.items) &&
          listEquals(collaborators, other.collaborators) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    Object.hashAll(attributeNames),
    isSynced,
    isStarred,
    isShared,
    hasInvite,
    isArchived,
    color,
    isOwner,
    position,
    Object.hashAll(items),
    Object.hashAll(collaborators),
    createdAt,
  );
}

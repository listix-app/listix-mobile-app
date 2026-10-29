import 'dart:convert';

import '../../domain/entities/list_type.dart';
import '../../domain/entities/todo_item.dart';

abstract final class TodoItemRowMapper {
  static TodoItem fromRow(Map<String, Object?> row) {
    final dueDate = row['due_date'] as int?;
    return TodoItem(
      id: row['id'] as String,
      listId: row['list_id'] as String,
      title: row['title'] as String,
      isCompleted: (row['is_completed'] as int) == 1,
      isSynced: (row['is_synced'] as int) == 1,
      position: (row['position'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      quantity: (row['quantity'] as num?)?.toDouble(),
      unit: row['unit'] as String?,
      category: row['category'] as String?,
      price: (row['price'] as num?)?.toDouble(),
      store: row['store'] as String?,
      url: row['url'] as String?,
      priority: ItemPriority.fromName(row['priority'] as String?),
      notes: row['notes'] as String?,
      isFavorite: (row['is_favorite'] as int? ?? 0) == 1,
      isChosen: (row['is_chosen'] as int? ?? 0) == 1,
      dueDate: dueDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dueDate),
      isInProgress: (row['in_progress'] as int? ?? 0) == 1,
      description: row['description'] as String?,
      imageUrl: row['image_url'] as String?,
      attributes: decodeAttributes(row['attributes'] as String?),
      evaluation: ItemEvaluation.fromName(row['evaluation'] as String?),
    );
  }

  static Map<String, String> decodeAttributes(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  static List<String> decodeNames(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  static String? encodeNames(List<String> names) =>
      names.isEmpty ? null : jsonEncode(names);

  static Map<String, Object?> detailColumns(TodoItem item) => {
    'quantity': item.quantity,
    'unit': item.unit,
    'category': item.category,
    'price': item.price,
    'store': item.store,
    'url': item.url,
    'priority': item.priority?.name,
    'notes': item.notes,
    'is_favorite': item.isFavorite ? 1 : 0,
    'is_chosen': item.isChosen ? 1 : 0,
    'due_date': item.dueDate?.millisecondsSinceEpoch,
    'in_progress': item.isInProgress ? 1 : 0,
    'description': item.description,
    'image_url': item.imageUrl,
    'attributes': item.attributes.isEmpty ? null : jsonEncode(item.attributes),
    'evaluation': item.evaluation?.name,
  };
}

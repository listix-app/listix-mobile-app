import 'package:flutter/foundation.dart';

import 'list_type.dart';

class TodoItem {
  final String id;
  final String listId;
  final String title;
  final bool isCompleted;
  final bool isSynced;
  final int position;
  final DateTime createdAt;
  final double? quantity;
  final String? unit;
  final String? category;
  final double? price;
  final String? store;
  final String? url;
  final ItemPriority? priority;
  final String? notes;
  final bool isFavorite;
  final bool isChosen;
  final DateTime? dueDate;
  final bool isInProgress;
  final String? description;
  final String? imageUrl;
  final Map<String, String> attributes;
  final ItemEvaluation? evaluation;

  const TodoItem({
    required this.id,
    required this.listId,
    required this.title,
    this.isCompleted = false,
    this.isSynced = false,
    this.position = 0,
    required this.createdAt,
    this.quantity,
    this.unit,
    this.category,
    this.price,
    this.store,
    this.url,
    this.priority,
    this.notes,
    this.isFavorite = false,
    this.isChosen = false,
    this.dueDate,
    this.isInProgress = false,
    this.description,
    this.imageUrl,
    this.attributes = const {},
    this.evaluation,
  });

  bool get hasDetails =>
      quantity != null ||
      unit != null ||
      category != null ||
      price != null ||
      store != null ||
      url != null ||
      priority != null ||
      notes != null ||
      isFavorite ||
      isChosen ||
      dueDate != null ||
      isInProgress ||
      description != null ||
      imageUrl != null ||
      attributes.isNotEmpty ||
      evaluation != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'listId': listId,
    'title': title,
    'isCompleted': isCompleted,
    'isSynced': isSynced,
    'position': position,
    'createdAt': createdAt.millisecondsSinceEpoch,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (category != null) 'category': category,
    if (price != null) 'price': price,
    if (store != null) 'store': store,
    if (url != null) 'url': url,
    if (priority != null) 'priority': priority!.name,
    if (notes != null) 'notes': notes,
    if (isFavorite) 'isFavorite': true,
    if (isChosen) 'isChosen': true,
    if (dueDate != null) 'dueDate': dueDate!.millisecondsSinceEpoch,
    if (isInProgress) 'isInProgress': true,
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (attributes.isNotEmpty) 'attributes': attributes,
    if (evaluation != null) 'evaluation': evaluation!.name,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String,
    listId: json['listId'] as String,
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
    isSynced: json['isSynced'] as bool? ?? false,
    position: (json['position'] as int?) ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    ),
    quantity: (json['quantity'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
    category: json['category'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    store: json['store'] as String?,
    url: json['url'] as String?,
    priority: ItemPriority.fromName(json['priority'] as String?),
    notes: json['notes'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    isChosen: json['isChosen'] as bool? ?? false,
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int),
    isInProgress: json['isInProgress'] as bool? ?? false,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    attributes: Map<String, String>.from(
      (json['attributes'] as Map?) ?? const <String, String>{},
    ),
    evaluation: ItemEvaluation.fromName(json['evaluation'] as String?),
  );

  TodoItem copyWith({
    String? id,
    String? listId,
    String? title,
    bool? isCompleted,
    bool? isSynced,
    int? position,
    DateTime? createdAt,
    double? quantity,
    String? unit,
    String? category,
    double? price,
    String? store,
    String? url,
    ItemPriority? priority,
    String? notes,
    bool? isFavorite,
    bool? isChosen,
    DateTime? dueDate,
    bool? isInProgress,
    String? description,
    String? imageUrl,
    bool clearImageUrl = false,
    Map<String, String>? attributes,
    ItemEvaluation? evaluation,
  }) {
    return TodoItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      price: price ?? this.price,
      store: store ?? this.store,
      url: url ?? this.url,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isChosen: isChosen ?? this.isChosen,
      dueDate: dueDate ?? this.dueDate,
      isInProgress: isInProgress ?? this.isInProgress,
      description: description ?? this.description,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      attributes: attributes ?? this.attributes,
      evaluation: evaluation ?? this.evaluation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listId == other.listId &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          isSynced == other.isSynced &&
          position == other.position &&
          quantity == other.quantity &&
          unit == other.unit &&
          category == other.category &&
          price == other.price &&
          store == other.store &&
          url == other.url &&
          priority == other.priority &&
          notes == other.notes &&
          isFavorite == other.isFavorite &&
          isChosen == other.isChosen &&
          dueDate == other.dueDate &&
          isInProgress == other.isInProgress &&
          description == other.description &&
          imageUrl == other.imageUrl &&
          mapEquals(attributes, other.attributes) &&
          evaluation == other.evaluation;

  @override
  int get hashCode => Object.hashAll([
    id,
    listId,
    title,
    isCompleted,
    isSynced,
    position,
    quantity,
    unit,
    category,
    price,
    store,
    url,
    priority,
    notes,
    isFavorite,
    isChosen,
    dueDate,
    isInProgress,
    description,
    imageUrl,
    Object.hashAllUnordered(
      attributes.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    evaluation,
  ]);
}

class TodoItem {
  final String id;
  final String listId;
  final String title;
  final bool isCompleted;
  final bool isSynced;
  final int position;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.listId,
    required this.title,
    this.isCompleted = false,
    this.isSynced = false,
    this.position = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'listId': listId,
    'title': title,
    'isCompleted': isCompleted,
    'isSynced': isSynced,
    'position': position,
    'createdAt': createdAt.millisecondsSinceEpoch,
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
  );

  TodoItem copyWith({
    String? id,
    String? listId,
    String? title,
    bool? isCompleted,
    bool? isSynced,
    int? position,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
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
          position == other.position;

  @override
  int get hashCode =>
      Object.hash(id, listId, title, isCompleted, isSynced, position);
}

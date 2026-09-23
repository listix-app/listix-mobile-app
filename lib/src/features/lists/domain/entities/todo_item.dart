class TodoItem {
  final String id;
  final String listId;
  final String title;
  final bool isCompleted;
  final bool isSynced;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.listId,
    required this.title,
    this.isCompleted = false,
    this.isSynced = false,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? listId,
    String? title,
    bool? isCompleted,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
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
          isSynced == other.isSynced;

  @override
  int get hashCode => Object.hash(id, listId, title, isCompleted, isSynced);
}

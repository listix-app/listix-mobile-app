class Collaborator {
  final String id;
  final String name;
  final String email;
  final bool isOwner;

  const Collaborator({
    required this.id,
    required this.name,
    required this.email,
    this.isOwner = false,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  }

  Collaborator copyWith({
    String? id,
    String? name,
    String? email,
    bool? isOwner,
  }) {
    return Collaborator(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collaborator &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

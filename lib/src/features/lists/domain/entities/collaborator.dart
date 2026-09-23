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
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collaborator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          isOwner == other.isOwner;

  @override
  int get hashCode => Object.hash(id, name, email, isOwner);
}

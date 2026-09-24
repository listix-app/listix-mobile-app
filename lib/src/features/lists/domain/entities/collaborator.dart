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
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'isOwner': isOwner,
  };

  factory Collaborator.fromJson(Map<String, dynamic> json) => Collaborator(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    isOwner: json['isOwner'] as bool? ?? false,
  );

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

enum CollaboratorRole {
  owner,
  admin,
  member;

  bool get isOwner => this == CollaboratorRole.owner;
  bool get isAdmin =>
      this == CollaboratorRole.admin || this == CollaboratorRole.owner;
  bool get isMember => this == CollaboratorRole.member;
}

class Collaborator {
  final String id;
  final String name;
  final String email;
  final CollaboratorRole role;

  const Collaborator({
    required this.id,
    required this.name,
    required this.email,
    CollaboratorRole? role,
    bool isOwner = false,
  }) : role =
           role ?? (isOwner ? CollaboratorRole.owner : CollaboratorRole.member);

  bool get isOwner => role == CollaboratorRole.owner;
  bool get isAdmin =>
      role == CollaboratorRole.admin || role == CollaboratorRole.owner;
  bool get isMember => role == CollaboratorRole.member;

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
    'role': role.name,
    'isOwner': isOwner,
  };

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String?;
    CollaboratorRole role;
    if (roleStr != null) {
      role = CollaboratorRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => CollaboratorRole.member,
      );
    } else if (json['isOwner'] as bool? ?? false) {
      role = CollaboratorRole.owner;
    } else {
      role = CollaboratorRole.member;
    }

    return Collaborator(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role,
    );
  }

  Collaborator copyWith({
    String? id,
    String? name,
    String? email,
    CollaboratorRole? role,
    bool? isOwner,
  }) => Collaborator(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role:
        role ??
        (isOwner != null
            ? (isOwner ? CollaboratorRole.owner : CollaboratorRole.member)
            : this.role),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collaborator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, name, email, role);
}

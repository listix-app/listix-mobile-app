/// Base exception for collaboration errors.
sealed class CollaborationException implements Exception {
  final String message;
  const CollaborationException(this.message);

  @override
  String toString() => message;
}

class ListMemberLimitReachedException extends CollaborationException {
  const ListMemberLimitReachedException([
    super.message = 'Esta lista alcanzó el límite máximo de miembros (máx. 5).',
  ]);
}

class InviteExpiredException extends CollaborationException {
  const InviteExpiredException([
    super.message = 'El link de invitación ha expirado.',
  ]);
}

class InvalidInviteException extends CollaborationException {
  const InvalidInviteException([
    super.message = 'El link de invitación no es válido o ha sido desactivado.',
  ]);
}

class UnauthenticatedJoinException extends CollaborationException {
  const UnauthenticatedJoinException([
    super.message = 'Se requiere autenticación anónima para unirse a la lista.',
  ]);
}

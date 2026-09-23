// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Listix';

  @override
  String get appTagline =>
      'Listas de compras y pendientes rápidas, colaborativas y offline-first.';

  @override
  String get myLists => 'Mis Listas';

  @override
  String get emptyListsTitle => 'Aún no tienes listas';

  @override
  String get emptyListsMessage =>
      'Crea una lista para organizar tus compras del supermercado, ropa o pendientes del hogar.';

  @override
  String get createFirstList => 'Crea tu primera lista';

  @override
  String get newList => 'Nueva lista';

  @override
  String get deleteListTitle => '¿Eliminar lista?';

  @override
  String deleteListMessage(String name) {
    return 'Se eliminará \"$name\" y todos sus items de forma permanente.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get listCountSuffix => 'listas';

  @override
  String get noItemsBadge => 'Sin items';

  @override
  String get allDoneBadge => 'Todo listo ✓';

  @override
  String pendingBadge(String progress) {
    return '$progress pendientes';
  }

  @override
  String get rename => 'Renombrar';

  @override
  String get shareList => 'Compartir lista';

  @override
  String get noItemsYet => 'Sin items aún';

  @override
  String pendingCountText(int pending, int total) {
    return '$pending de $total pendientes';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% completado';
  }

  @override
  String completedGroup(int count) {
    return 'Completados ($count)';
  }

  @override
  String get emptyItemsTitle => 'Lista vacía';

  @override
  String get emptyItemsMessage =>
      'Escribe tu primer item en la barra inferior y presiona enter.';

  @override
  String get quickAddHint => 'Agregar item rápido...';

  @override
  String get quickAddTooltip => 'Agregar item';

  @override
  String get back => 'Volver';

  @override
  String get listNotFound => 'Lista no encontrada';

  @override
  String get renameListTitle => 'Renombrar lista';

  @override
  String get newListTitle => 'Nueva lista';

  @override
  String get editListHeading => 'Edita el nombre de tu lista';

  @override
  String get createListHeading => '¿Qué vas a comprar o preparar hoy?';

  @override
  String get editListSubheading =>
      'El nuevo nombre se guardará en SQLite local y se sincronizará automáticamente.';

  @override
  String get createListSubheading =>
      'Escribe un nombre claro (ej. Supermercado semanal, Ferretería, Farmacia).';

  @override
  String get listNameLabel => 'Nombre de la lista';

  @override
  String get listNameHint => 'Ej. Despensa mensual';

  @override
  String get listNameValidation => 'Por favor ingresa un nombre';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get createListAction => 'Crear lista';

  @override
  String get shareHeading => 'Compartir';

  @override
  String get shareListSubheading =>
      'Invita a otras personas a ver y tachar items en tiempo real.';

  @override
  String get copyInviteLink => 'Copiar enlace de invitación';

  @override
  String get linkCopied => 'Enlace de invitación copiado al portapapeles';

  @override
  String get inviteByEmail => 'O invitar por correo';

  @override
  String get emailHint => 'ejemplo@correo.com';

  @override
  String get inviteAction => 'Invitar';

  @override
  String get enterEmailError => 'Ingresa un correo';

  @override
  String get invalidEmailError => 'Correo no válido';

  @override
  String get collaboratorsHeading => 'Colaboradores';

  @override
  String get noCollaboratorsYet => 'Aún no hay colaboradores en esta lista.';

  @override
  String get removeCollaborator => 'Quitar colaborador';

  @override
  String get ownerBadge => 'Dueño';

  @override
  String inviteSent(String email) {
    return 'Invitación enviada a $email';
  }

  @override
  String get syncStatusTitle => 'Estado de Sincronización';

  @override
  String get syncStatusDescription =>
      'Listix opera bajo arquitectura Offline-First con persistencia local en SQLite.';

  @override
  String get simulateOffline => 'Simular Modo Offline';

  @override
  String get simulateOfflineSubtitle =>
      'Comprueba cómo la app guarda localmente sin conexión';

  @override
  String get close => 'Cerrar';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get statusSyncing => 'Sincronizando...';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusSynced => 'Sincronizado';

  @override
  String get aboutApp => 'Acerca de Listix';

  @override
  String get version => 'Versión';

  @override
  String versionLabel(String version, String build) {
    return 'Versión $version (Build $build)';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get offlineFirstTitle => 'Offline-First';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get termsOfService => 'Términos del Servicio';

  @override
  String get privacyStatement =>
      'En Listix tu privacidad es absoluta. Todos tus datos residen de forma predeterminada en el almacenamiento SQLite local de tu dispositivo. No recopilamos rastreadores de publicidad, no vendemos datos a terceros ni almacenamos analíticas invasivas.';

  @override
  String get offlineFirstStatement =>
      'Arquitectura Offline-First: Cada creación, tachado y edición se realiza a velocidad nativa con latencia cero en disco local, sincronizándose de manera segura en segundo plano.';

  @override
  String get termsStatement =>
      'Listix es una herramienta creada para la productividad personal y colaborativa. El usuario es el único propietario de sus listas y contenido.';

  @override
  String copyrightFooter(int year) {
    return '© $year Listix • Licencia MIT';
  }

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }
}

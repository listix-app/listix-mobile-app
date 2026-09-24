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
      'Listas de compras y tareas rápidas, privadas y 100% offline.';

  @override
  String get myLists => 'Mis Listas';

  @override
  String get emptyListsTitle => 'Tus listas, siempre contigo';

  @override
  String get emptyListsMessage =>
      'Crea tu lista de supermercado o pendientes en segundos. Funciona completamente offline.';

  @override
  String get createFirstList => 'Crear mi primera lista';

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
  String get emptyItemsTitle => 'Lista sin items aún';

  @override
  String get emptyItemsMessage =>
      'Escribe tu primer item abajo para agregarlo al instante.';

  @override
  String get quickAddHint => 'Agregar item';

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
      'El nuevo nombre se guardará al instante y de forma segura en tu dispositivo.';

  @override
  String get createListSubheading =>
      'Escribe un nombre claro (ej. Supermercado semanal, Ferretería, Farmacia).';

  @override
  String get listNameLabel => 'Nombre de la lista';

  @override
  String get listNameHint => 'Ej. Despensa semanal';

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
      'Envía esta lista al instante por WhatsApp o Gmail.';

  @override
  String get shareWhatsApp => 'Compartir por WhatsApp';

  @override
  String get shareWhatsAppDesc => 'Enviar lista formateada por chat';

  @override
  String get shareGmail => 'Compartir por Gmail';

  @override
  String get shareGmailDesc => 'Enviar lista completa por correo';

  @override
  String get copyListText => 'Copiar texto de la lista';

  @override
  String get copyListTextDesc => 'Copiar contenido al portapapeles';

  @override
  String get listCopied => '¡Lista copiada al portapapeles!';

  @override
  String shareSubject(String name) {
    return 'Listix: $name';
  }

  @override
  String get sharedWithListix =>
      'Creado con Listix — Listas rápidas y 100% offline';

  @override
  String get offlineNotice => 'Almacenamiento Local Offline';

  @override
  String get offlineNoticeDesc =>
      'Tus datos se guardan de forma local en tu dispositivo con SQLite. La lista se sincroniza únicamente al compartir.';

  @override
  String get copyInviteLink => 'Copiar enlace de invitación';

  @override
  String get linkCopied => 'Enlace copiado al portapapeles';

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
  String get settings => 'Configuración';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get version => 'Versión';

  @override
  String versionLabel(String version, String build) {
    return 'Versión $version (compilación $build)';
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
      'Todas tus listas de compras y productos se guardan localmente en tu dispositivo. Listix muestra anuncios mediante Google AdMob para apoyar el desarrollo continuo. Google AdMob puede recopilar y procesar identificadores del dispositivo, ID de publicidad y datos de uso para mostrar anuncios personalizados y no personalizados de acuerdo con la Política de Privacidad de Google. Nunca vendemos tus datos personales ni el contenido de tus listas.';

  @override
  String get offlineFirstStatement =>
      'Arquitectura Offline-First: Cada creación, tachado y edición se realiza a velocidad nativa con latencia cero en disco local, sincronizándose únicamente al compartir.';

  @override
  String get termsStatement =>
      'Listix es una herramienta creada para la productividad personal y colaborativa. El usuario es el único propietario de sus listas y contenido.';

  @override
  String copyrightFooter(int year) {
    return '© $year Nicolas Mena. Todos los derechos reservados.';
  }

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get weeklyReminderTitle => 'Recordatorio semanal';

  @override
  String get weeklyReminderSubtitle =>
      'Recibe un recordatorio semanal para planificar tus compras';

  @override
  String get notificationTimeTitle => 'Hora del recordatorio';

  @override
  String notificationTimeSubtitle(String time) {
    return 'Programada para las $time';
  }

  @override
  String get weeklyReminderNotificationTitle =>
      '¡Momento de organizar tus compras!';

  @override
  String get weeklyReminderNotificationBody =>
      'Revisa tus listas o crea una nueva para esta semana.';

  @override
  String get undo => 'Deshacer';

  @override
  String listDeleted(String name) {
    return '\"$name\" eliminada';
  }

  @override
  String itemDeleted(String title) {
    return '\"$title\" eliminado';
  }

  @override
  String get starred => 'Favoritas';

  @override
  String get starList => 'Destacar lista';

  @override
  String get unstarList => 'Quitar de destacadas';

  @override
  String get reorder => 'Reordenar';

  @override
  String get developer => 'Desarrollador';

  @override
  String get developerName => 'Nicolas Mena';

  @override
  String get developerEmail => 'nmena.garzon@gmail.com';

  @override
  String get contactDeveloper => 'Contactar al desarrollador';

  @override
  String get buyMeACoffee => 'Invítame un café';

  @override
  String get buyMeACoffeeSubtitle => 'Apoya el desarrollo de Listix';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get sendFeedbackSubtitle => 'Sugerencias, errores o consultas';

  @override
  String get rateApp => 'Calificar app';

  @override
  String get rateAppSubtitle => 'Deja una reseña en Google Play';

  @override
  String get layoutTitle => 'Diseño de listas';

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutGrid => 'Bloques';

  @override
  String get switchLayout => 'Cambiar diseño';

  @override
  String get adPolicyTitle => 'Política de Anuncios y Privacidad';

  @override
  String get adPolicyStatement =>
      'Listix utiliza Google AdMob. Los anuncios intersticiales se muestran como máximo una vez al día en transiciones naturales para respetar tu experiencia.';

  @override
  String get shareSystem => 'Compartir en el sistema';

  @override
  String get shareSystemDesc =>
      'Enviar lista y enlace a WhatsApp, Telegram, Correo y más';

  @override
  String shareInviteLinkPrompt(String url) {
    return '🔗 Únete a esta lista para colaborar en tiempo real:\n$url';
  }

  @override
  String get sharePendingSection => '📝 Por comprar';

  @override
  String get shareCompletedSection => '✅ Comprados';

  @override
  String get shareEmptyListNotice => '• (Sin productos en la lista todavía)';

  @override
  String get realtimeLive => 'En vivo';

  @override
  String get realtimeConnecting => 'Conectando...';

  @override
  String get realtimeDisconnected => 'Desconectado';

  @override
  String get realtimeCollaborating => 'Colaboración en tiempo real activa';

  @override
  String realtimeOnlineUsers(int count) {
    return '$count en línea';
  }

  @override
  String get joinList => 'Unirse a lista';

  @override
  String get joinListTitle => 'Unirse a una lista compartida';

  @override
  String get joinListPrompt =>
      'Ingresa el código o enlace de invitación para colaborar en tiempo real.';

  @override
  String get joinListHint => 'Código o enlace de la lista';

  @override
  String get joinAction => 'Unirse';

  @override
  String listJoined(String name) {
    return 'Te has unido a \"$name\"';
  }

  @override
  String get invalidInviteCode => 'Código o enlace de invitación inválido';

  @override
  String get alreadyJoined => 'Ya tienes acceso a esta lista';

  @override
  String get collaborators => 'Colaboradores';

  @override
  String get inviteColleague => 'Invitar amigos o colegas';

  @override
  String get inviteColleagueSubtitle =>
      'Colabora en tiempo real agregando y tachando productos';

  @override
  String get simulateColleagueAction => 'Simular acción de colega';

  @override
  String get simulateColleagueTooltip =>
      'Simula que un colega agrega o tacha un producto en tiempo real';

  @override
  String get simulatedItemAdded =>
      'Un colega agregó un producto en tiempo real';

  @override
  String get listIsShared => 'Lista compartida';

  @override
  String get listIsLocalOnly => 'Lista privada (solo local)';

  @override
  String get listSharedSyncEnabled =>
      'Sincronización en tiempo real habilitada con la nube';

  @override
  String get listLocalOnlyDescription =>
      'Los datos se guardan únicamente en tu dispositivo';

  @override
  String get enableSharingAction => 'Habilitar sincronización';

  @override
  String get supportAndFeedback => 'Soporte y Comentarios';
}

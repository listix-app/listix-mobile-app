enum AppLanguage { es, en }

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isSpanish => language == AppLanguage.es;

  // General & Brand
  String get appName => 'Listix';
  String get appTagline => isSpanish
      ? 'Listas de compras y pendientes rápidas, colaborativas y offline-first.'
      : 'Fast, collaborative, offline-first shopping and todo lists.';

  // Home / Index Screen
  String get myLists => isSpanish ? 'Mis Listas' : 'My Lists';
  String get emptyListsTitle =>
      isSpanish ? 'Aún no tienes listas' : 'No lists yet';
  String get emptyListsMessage => isSpanish
      ? 'Crea una lista para organizar tus compras del supermercado, ropa o pendientes del hogar.'
      : 'Create a list to organize your groceries, clothing, or household tasks.';
  String get createFirstList =>
      isSpanish ? 'Crea tu primera lista' : 'Create your first list';
  String get newList => isSpanish ? 'Nueva lista' : 'New list';
  String get deleteListTitle => isSpanish ? '¿Eliminar lista?' : 'Delete list?';
  String deleteListMessage(String name) => isSpanish
      ? 'Se eliminará "$name" y todos sus items de forma permanente.'
      : 'This will permanently delete "$name" and all of its items.';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';
  String get listCountSuffix => isSpanish ? 'listas' : 'lists';
  String get noItemsBadge => isSpanish ? 'Sin items' : 'No items';
  String get allDoneBadge => isSpanish ? 'Todo listo ✓' : 'All done ✓';
  String pendingBadge(String progress) =>
      isSpanish ? '$progress pendientes' : '$progress pending';

  // List Detail Screen
  String get rename => isSpanish ? 'Renombrar' : 'Rename';
  String get shareList => isSpanish ? 'Compartir lista' : 'Share list';
  String get noItemsYet => isSpanish ? 'Sin items aún' : 'No items yet';
  String pendingCountText(int pending, int total) => isSpanish
      ? '$pending de $total pendientes'
      : '$pending of $total pending';
  String percentCompleted(int percent) =>
      isSpanish ? '$percent% completado' : '$percent% completed';
  String completedGroup(int count) =>
      isSpanish ? 'Completados ($count)' : 'Completed ($count)';
  String get emptyItemsTitle => isSpanish ? 'Lista vacía' : 'Empty list';
  String get emptyItemsMessage => isSpanish
      ? 'Escribe tu primer item en la barra inferior y presiona enter.'
      : 'Type your first item in the bottom bar and press enter.';
  String get quickAddHint =>
      isSpanish ? 'Agregar item rápido...' : 'Quick add item...';
  String get quickAddTooltip => isSpanish ? 'Agregar item' : 'Add item';
  String get back => isSpanish ? 'Volver' : 'Back';
  String get listNotFound =>
      isSpanish ? 'Lista no encontrada' : 'List not found';

  // Create / Edit List Screen
  String get renameListTitle => isSpanish ? 'Renombrar lista' : 'Rename list';
  String get newListTitle => isSpanish ? 'Nueva lista' : 'New list';
  String get editListHeading =>
      isSpanish ? 'Edita el nombre de tu lista' : 'Edit your list name';
  String get createListHeading => isSpanish
      ? '¿Qué vas a comprar o preparar hoy?'
      : 'What are you shopping or planning today?';
  String get editListSubheading => isSpanish
      ? 'El nuevo nombre se guardará en SQLite local y se sincronizará automáticamente.'
      : 'The updated name is saved locally in SQLite and synced automatically.';
  String get createListSubheading => isSpanish
      ? 'Escribe un nombre claro (ej. Supermercado semanal, Ferretería, Farmacia).'
      : 'Type a clear name (e.g. Weekly Groceries, Hardware, Pharmacy).';
  String get listNameLabel => isSpanish ? 'Nombre de la lista' : 'List name';
  String get listNameHint =>
      isSpanish ? 'Ej. Despensa mensual' : 'e.g. Monthly Pantry';
  String get listNameValidation =>
      isSpanish ? 'Por favor ingresa un nombre' : 'Please enter a name';
  String get saveChanges => isSpanish ? 'Guardar cambios' : 'Save changes';
  String get createListAction => isSpanish ? 'Crear lista' : 'Create list';

  // Share List Sheet
  String get shareHeading => isSpanish ? 'Compartir' : 'Share';
  String get shareListSubheading => isSpanish
      ? 'Invita a otras personas a ver y tachar items en tiempo real.'
      : 'Invite others to view and check off items in real time.';
  String get copyInviteLink =>
      isSpanish ? 'Copiar enlace de invitación' : 'Copy invitation link';
  String get linkCopied => isSpanish
      ? 'Enlace de invitación copiado al portapapeles'
      : 'Invitation link copied to clipboard';
  String get inviteByEmail =>
      isSpanish ? 'O invitar por correo' : 'Or invite by email';
  String get emailHint =>
      isSpanish ? 'ejemplo@correo.com' : 'example@email.com';
  String get inviteAction => isSpanish ? 'Invitar' : 'Invite';
  String get enterEmailError =>
      isSpanish ? 'Ingresa un correo' : 'Please enter an email';
  String get invalidEmailError =>
      isSpanish ? 'Correo no válido' : 'Invalid email';
  String get collaboratorsHeading =>
      isSpanish ? 'Colaboradores' : 'Collaborators';
  String get noCollaboratorsYet => isSpanish
      ? 'Aún no hay colaboradores en esta lista.'
      : 'No collaborators on this list yet.';
  String get removeCollaborator =>
      isSpanish ? 'Eliminar colaborador' : 'Remove collaborator';
  String inviteSent(String email) =>
      isSpanish ? 'Invitación enviada a $email' : 'Invitation sent to $email';

  // Sync Status
  String get syncStatusTitle =>
      isSpanish ? 'Estado de Sincronización' : 'Synchronization Status';
  String get syncStatusDescription => isSpanish
      ? 'Listix opera bajo arquitectura Offline-First con persistencia local en SQLite.'
      : 'Listix operates under an Offline-First architecture with local SQLite storage.';
  String get simulateOffline =>
      isSpanish ? 'Simular Modo Offline' : 'Simulate Offline Mode';
  String get simulateOfflineSubtitle => isSpanish
      ? 'Comprueba cómo la app guarda localmente sin conexión'
      : 'Test how the app saves data locally with zero connection';
  String get close => isSpanish ? 'Cerrar' : 'Close';
  String get syncNow => isSpanish ? 'Sincronizar ahora' : 'Sync now';
  String get statusSyncing => isSpanish ? 'Sincronizando...' : 'Syncing...';
  String get statusOffline => isSpanish ? 'Offline' : 'Offline';
  String get statusPending => isSpanish ? 'Pendiente' : 'Pending';
  String get statusSynced => isSpanish ? 'Sincronizado' : 'Synced';

  // About, Policy & Privacy
  String get aboutApp => isSpanish ? 'Acerca de Listix' : 'About Listix';
  String get version => isSpanish ? 'Versión' : 'Version';
  String get languageTitle => isSpanish ? 'Idioma' : 'Language';
  String get privacyPolicy =>
      isSpanish ? 'Política de Privacidad' : 'Privacy Policy';
  String get termsOfService =>
      isSpanish ? 'Términos del Servicio' : 'Terms of Service';

  String get privacyStatement => isSpanish
      ? 'En Listix tu privacidad es absoluta. Todos tus datos residen de forma predeterminada en el almacenamiento SQLite local de tu dispositivo. No recopilamos rastreadores de publicidad, no vendemos datos a terceros ni almacenamos analíticas invasivas.'
      : 'At Listix, your privacy is absolute. All your data lives by default on your device’s local SQLite storage. We do not use advertising trackers, sell personal data to third parties, or run invasive analytics.';

  String get offlineFirstStatement => isSpanish
      ? 'Arquitectura Offline-First: Cada creación, tachado y edición se realiza a velocidad nativa con latencia cero en disco local, sincronizándose de manera segura en segundo plano.'
      : 'Offline-First Architecture: Every creation, check-off, and edit occurs at native speed with zero latency on local storage, syncing securely in the background.';

  String get termsStatement => isSpanish
      ? 'Listix es una herramienta creada para la productividad personal y colaborativa. El usuario es el único propietario de sus listas y contenido.'
      : 'Listix is a tool built for personal and collaborative productivity. You retain full ownership of your lists and content.';
}

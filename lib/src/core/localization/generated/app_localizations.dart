import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Listix'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Listas de compras y tareas rápidas, privadas y 100% offline.'**
  String get appTagline;

  /// No description provided for @myLists.
  ///
  /// In es, this message translates to:
  /// **'Mis Listas'**
  String get myLists;

  /// No description provided for @emptyListsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus listas, siempre contigo'**
  String get emptyListsTitle;

  /// No description provided for @emptyListsMessage.
  ///
  /// In es, this message translates to:
  /// **'Crea tu lista de supermercado o pendientes en segundos. Funciona completamente offline.'**
  String get emptyListsMessage;

  /// No description provided for @createFirstList.
  ///
  /// In es, this message translates to:
  /// **'Crear mi primera lista'**
  String get createFirstList;

  /// No description provided for @newList.
  ///
  /// In es, this message translates to:
  /// **'Nueva lista'**
  String get newList;

  /// No description provided for @deleteListTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar lista?'**
  String get deleteListTitle;

  /// No description provided for @deleteListMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{name}\" y todos sus items de forma permanente.'**
  String deleteListMessage(String name);

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @listCountSuffix.
  ///
  /// In es, this message translates to:
  /// **'listas'**
  String get listCountSuffix;

  /// No description provided for @noItemsBadge.
  ///
  /// In es, this message translates to:
  /// **'Sin items'**
  String get noItemsBadge;

  /// No description provided for @allDoneBadge.
  ///
  /// In es, this message translates to:
  /// **'Todo listo ✓'**
  String get allDoneBadge;

  /// No description provided for @pendingBadge.
  ///
  /// In es, this message translates to:
  /// **'{progress} pendientes'**
  String pendingBadge(String progress);

  /// No description provided for @rename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get rename;

  /// No description provided for @shareList.
  ///
  /// In es, this message translates to:
  /// **'Compartir lista'**
  String get shareList;

  /// No description provided for @noItemsYet.
  ///
  /// In es, this message translates to:
  /// **'Sin items aún'**
  String get noItemsYet;

  /// No description provided for @pendingCountText.
  ///
  /// In es, this message translates to:
  /// **'{pending} de {total} pendientes'**
  String pendingCountText(int pending, int total);

  /// No description provided for @percentCompleted.
  ///
  /// In es, this message translates to:
  /// **'{percent}% completado'**
  String percentCompleted(int percent);

  /// No description provided for @completedGroup.
  ///
  /// In es, this message translates to:
  /// **'Completados ({count})'**
  String completedGroup(int count);

  /// No description provided for @emptyItemsTitle.
  ///
  /// In es, this message translates to:
  /// **'Lista sin items aún'**
  String get emptyItemsTitle;

  /// No description provided for @emptyItemsMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu primer item abajo para agregarlo al instante.'**
  String get emptyItemsMessage;

  /// No description provided for @quickAddHint.
  ///
  /// In es, this message translates to:
  /// **'Agregar item'**
  String get quickAddHint;

  /// No description provided for @quickAddTooltip.
  ///
  /// In es, this message translates to:
  /// **'Agregar item'**
  String get quickAddTooltip;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @listNotFound.
  ///
  /// In es, this message translates to:
  /// **'Lista no encontrada'**
  String get listNotFound;

  /// No description provided for @renameListTitle.
  ///
  /// In es, this message translates to:
  /// **'Renombrar lista'**
  String get renameListTitle;

  /// No description provided for @newListTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva lista'**
  String get newListTitle;

  /// No description provided for @editListHeading.
  ///
  /// In es, this message translates to:
  /// **'Edita el nombre de tu lista'**
  String get editListHeading;

  /// No description provided for @createListHeading.
  ///
  /// In es, this message translates to:
  /// **'¿Qué vas a comprar o preparar hoy?'**
  String get createListHeading;

  /// No description provided for @editListSubheading.
  ///
  /// In es, this message translates to:
  /// **'El nuevo nombre se guardará al instante y de forma segura en tu dispositivo.'**
  String get editListSubheading;

  /// No description provided for @createListSubheading.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre claro (ej. Supermercado semanal, Ferretería, Farmacia).'**
  String get createListSubheading;

  /// No description provided for @listNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la lista'**
  String get listNameLabel;

  /// No description provided for @listNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Despensa semanal'**
  String get listNameHint;

  /// No description provided for @listNameValidation.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un nombre'**
  String get listNameValidation;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @createListAction.
  ///
  /// In es, this message translates to:
  /// **'Crear lista'**
  String get createListAction;

  /// No description provided for @shareHeading.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get shareHeading;

  /// No description provided for @shareListSubheading.
  ///
  /// In es, this message translates to:
  /// **'Envía esta lista al instante por WhatsApp o Gmail.'**
  String get shareListSubheading;

  /// No description provided for @shareWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'Compartir por WhatsApp'**
  String get shareWhatsApp;

  /// No description provided for @shareWhatsAppDesc.
  ///
  /// In es, this message translates to:
  /// **'Enviar lista formateada por chat'**
  String get shareWhatsAppDesc;

  /// No description provided for @shareGmail.
  ///
  /// In es, this message translates to:
  /// **'Compartir por Gmail'**
  String get shareGmail;

  /// No description provided for @shareGmailDesc.
  ///
  /// In es, this message translates to:
  /// **'Enviar lista completa por correo'**
  String get shareGmailDesc;

  /// No description provided for @copyListText.
  ///
  /// In es, this message translates to:
  /// **'Copiar texto de la lista'**
  String get copyListText;

  /// No description provided for @copyListTextDesc.
  ///
  /// In es, this message translates to:
  /// **'Copiar contenido al portapapeles'**
  String get copyListTextDesc;

  /// No description provided for @listCopied.
  ///
  /// In es, this message translates to:
  /// **'¡Lista copiada al portapapeles!'**
  String get listCopied;

  /// No description provided for @shareSubject.
  ///
  /// In es, this message translates to:
  /// **'Listix: {name}'**
  String shareSubject(String name);

  /// No description provided for @sharedWithListix.
  ///
  /// In es, this message translates to:
  /// **'Creado con Listix — Listas rápidas y 100% offline'**
  String get sharedWithListix;

  /// No description provided for @offlineNotice.
  ///
  /// In es, this message translates to:
  /// **'Almacenamiento Local Offline'**
  String get offlineNotice;

  /// No description provided for @offlineNoticeDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus datos se guardan de forma local en tu dispositivo con SQLite. La lista se sincroniza únicamente al compartir.'**
  String get offlineNoticeDesc;

  /// No description provided for @copyInviteLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace de invitación'**
  String get copyInviteLink;

  /// No description provided for @linkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado al portapapeles'**
  String get linkCopied;

  /// No description provided for @inviteByEmail.
  ///
  /// In es, this message translates to:
  /// **'O invitar por correo'**
  String get inviteByEmail;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'ejemplo@correo.com'**
  String get emailHint;

  /// No description provided for @inviteAction.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get inviteAction;

  /// No description provided for @enterEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo'**
  String get enterEmailError;

  /// No description provided for @invalidEmailError.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido'**
  String get invalidEmailError;

  /// No description provided for @collaboratorsHeading.
  ///
  /// In es, this message translates to:
  /// **'Colaboradores'**
  String get collaboratorsHeading;

  /// No description provided for @noCollaboratorsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay colaboradores en esta lista.'**
  String get noCollaboratorsYet;

  /// No description provided for @removeCollaborator.
  ///
  /// In es, this message translates to:
  /// **'Quitar colaborador'**
  String get removeCollaborator;

  /// No description provided for @ownerBadge.
  ///
  /// In es, this message translates to:
  /// **'Dueño'**
  String get ownerBadge;

  /// No description provided for @inviteSent.
  ///
  /// In es, this message translates to:
  /// **'Invitación enviada a {email}'**
  String inviteSent(String email);

  /// No description provided for @syncStatusTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado de Sincronización'**
  String get syncStatusTitle;

  /// No description provided for @syncStatusDescription.
  ///
  /// In es, this message translates to:
  /// **'Listix opera bajo arquitectura Offline-First con persistencia local en SQLite.'**
  String get syncStatusDescription;

  /// No description provided for @simulateOffline.
  ///
  /// In es, this message translates to:
  /// **'Simular Modo Offline'**
  String get simulateOffline;

  /// No description provided for @simulateOfflineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Comprueba cómo la app guarda localmente sin conexión'**
  String get simulateOfflineSubtitle;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @syncNow.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get syncNow;

  /// No description provided for @statusSyncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando...'**
  String get statusSyncing;

  /// No description provided for @statusOffline.
  ///
  /// In es, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @statusSynced.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado'**
  String get statusSynced;

  /// No description provided for @aboutApp.
  ///
  /// In es, this message translates to:
  /// **'Acerca de Listix'**
  String get aboutApp;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @themeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @versionLabel.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} (compilación {build})'**
  String versionLabel(String version, String build);

  /// No description provided for @languageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @offlineFirstTitle.
  ///
  /// In es, this message translates to:
  /// **'Offline-First'**
  String get offlineFirstTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos del Servicio'**
  String get termsOfService;

  /// No description provided for @privacyStatement.
  ///
  /// In es, this message translates to:
  /// **'En Listix tu privacidad es absoluta. Todos tus datos residen de forma predeterminada en el almacenamiento SQLite local de tu dispositivo. No recopilamos rastreadores de publicidad, no vendemos datos a terceros ni almacenamos analíticas invasivas.'**
  String get privacyStatement;

  /// No description provided for @offlineFirstStatement.
  ///
  /// In es, this message translates to:
  /// **'Arquitectura Offline-First: Cada creación, tachado y edición se realiza a velocidad nativa con latencia cero en disco local, sincronizándose únicamente al compartir.'**
  String get offlineFirstStatement;

  /// No description provided for @termsStatement.
  ///
  /// In es, this message translates to:
  /// **'Listix es una herramienta creada para la productividad personal y colaborativa. El usuario es el único propietario de sus listas y contenido.'**
  String get termsStatement;

  /// No description provided for @copyrightFooter.
  ///
  /// In es, this message translates to:
  /// **'© {year} Nicolas Mena. Todos los derechos reservados.'**
  String copyrightFooter(int year);

  /// No description provided for @errorPrefix.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @weeklyReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio semanal'**
  String get weeklyReminderTitle;

  /// No description provided for @weeklyReminderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibe un recordatorio cada domingo a las 10:00 AM para planificar tus compras'**
  String get weeklyReminderSubtitle;

  /// No description provided for @weeklyReminderNotificationTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Momento de organizar tus compras!'**
  String get weeklyReminderNotificationTitle;

  /// No description provided for @weeklyReminderNotificationBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus listas o crea una nueva para esta semana.'**
  String get weeklyReminderNotificationBody;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @listDeleted.
  ///
  /// In es, this message translates to:
  /// **'\"{name}\" eliminada'**
  String listDeleted(String name);

  /// No description provided for @itemDeleted.
  ///
  /// In es, this message translates to:
  /// **'\"{title}\" eliminado'**
  String itemDeleted(String title);

  /// No description provided for @starred.
  ///
  /// In es, this message translates to:
  /// **'Favoritas'**
  String get starred;

  /// No description provided for @starList.
  ///
  /// In es, this message translates to:
  /// **'Destacar lista'**
  String get starList;

  /// No description provided for @unstarList.
  ///
  /// In es, this message translates to:
  /// **'Quitar de destacadas'**
  String get unstarList;

  /// No description provided for @reorder.
  ///
  /// In es, this message translates to:
  /// **'Reordenar'**
  String get reorder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

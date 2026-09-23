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
  /// **'Listas de compras y pendientes rápidas, colaborativas y offline-first.'**
  String get appTagline;

  /// No description provided for @myLists.
  ///
  /// In es, this message translates to:
  /// **'Mis Listas'**
  String get myLists;

  /// No description provided for @emptyListsTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes listas'**
  String get emptyListsTitle;

  /// No description provided for @emptyListsMessage.
  ///
  /// In es, this message translates to:
  /// **'Crea una lista para organizar tus compras del supermercado, ropa o pendientes del hogar.'**
  String get emptyListsMessage;

  /// No description provided for @createFirstList.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera lista'**
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
  /// **'Lista vacía'**
  String get emptyItemsTitle;

  /// No description provided for @emptyItemsMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu primer item en la barra inferior y presiona enter.'**
  String get emptyItemsMessage;

  /// No description provided for @quickAddHint.
  ///
  /// In es, this message translates to:
  /// **'Agregar item rápido...'**
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
  /// **'El nuevo nombre se guardará en SQLite local y se sincronizará automáticamente.'**
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
  /// **'Ej. Despensa mensual'**
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
  /// **'Invita a otras personas a ver y tachar items en tiempo real.'**
  String get shareListSubheading;

  /// No description provided for @copyInviteLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace de invitación'**
  String get copyInviteLink;

  /// No description provided for @linkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace de invitación copiado al portapapeles'**
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

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @versionLabel.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} (Build {build})'**
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
  /// **'Arquitectura Offline-First: Cada creación, tachado y edición se realiza a velocidad nativa con latencia cero en disco local, sincronizándose de manera segura en segundo plano.'**
  String get offlineFirstStatement;

  /// No description provided for @termsStatement.
  ///
  /// In es, this message translates to:
  /// **'Listix es una herramienta creada para la productividad personal y colaborativa. El usuario es el único propietario de sus listas y contenido.'**
  String get termsStatement;

  /// No description provided for @copyrightFooter.
  ///
  /// In es, this message translates to:
  /// **'© {year} Listix • Licencia MIT'**
  String copyrightFooter(int year);

  /// No description provided for @errorPrefix.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);
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

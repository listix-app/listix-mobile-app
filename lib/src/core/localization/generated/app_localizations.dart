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
  /// In en, this message translates to:
  /// **'Listix'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Fast, private, offline-first shopping and todo lists.'**
  String get appTagline;

  /// No description provided for @myLists.
  ///
  /// In en, this message translates to:
  /// **'My Lists'**
  String get myLists;

  /// No description provided for @emptyListsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your lists, always with you'**
  String get emptyListsTitle;

  /// No description provided for @emptyListsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your grocery or task list in seconds. It works completely offline.'**
  String get emptyListsMessage;

  /// No description provided for @createFirstList.
  ///
  /// In en, this message translates to:
  /// **'Create your first list'**
  String get createFirstList;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @deleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get deleteListTitle;

  /// No description provided for @deleteListMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\" and all of its items.'**
  String deleteListMessage(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @listCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'lists'**
  String get listCountSuffix;

  /// No description provided for @noItemsBadge.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItemsBadge;

  /// No description provided for @allDoneBadge.
  ///
  /// In en, this message translates to:
  /// **'All done ✓'**
  String get allDoneBadge;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'{progress} pending'**
  String pendingBadge(String progress);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @shareList.
  ///
  /// In en, this message translates to:
  /// **'Share list'**
  String get shareList;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noItemsYet;

  /// No description provided for @pendingCountText.
  ///
  /// In en, this message translates to:
  /// **'{pending} of {total} pending'**
  String pendingCountText(int pending, int total);

  /// No description provided for @percentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String percentCompleted(int percent);

  /// No description provided for @completedGroup.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String completedGroup(int count);

  /// No description provided for @emptyItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty list'**
  String get emptyItemsTitle;

  /// No description provided for @emptyItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your first item below to add it instantly.'**
  String get emptyItemsMessage;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get quickAddHint;

  /// No description provided for @quickAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get quickAddTooltip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @listNotFound.
  ///
  /// In en, this message translates to:
  /// **'List not found'**
  String get listNotFound;

  /// No description provided for @renameListTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get renameListTitle;

  /// No description provided for @newListTitle.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newListTitle;

  /// No description provided for @editListHeading.
  ///
  /// In en, this message translates to:
  /// **'Edit your list name'**
  String get editListHeading;

  /// No description provided for @createListHeading.
  ///
  /// In en, this message translates to:
  /// **'What are you shopping or planning today?'**
  String get createListHeading;

  /// No description provided for @editListSubheading.
  ///
  /// In en, this message translates to:
  /// **'The updated name is saved instantly and securely on your device.'**
  String get editListSubheading;

  /// No description provided for @createListSubheading.
  ///
  /// In en, this message translates to:
  /// **'Type a clear name (e.g. Weekly Groceries, Hardware, Pharmacy).'**
  String get createListSubheading;

  /// No description provided for @listNameLabel.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listNameLabel;

  /// No description provided for @listNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly Groceries'**
  String get listNameHint;

  /// No description provided for @listNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get listNameValidation;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @createListAction.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get createListAction;

  /// No description provided for @shareHeading.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareHeading;

  /// No description provided for @shareListSubheading.
  ///
  /// In en, this message translates to:
  /// **'Send this list instantly via WhatsApp or Gmail.'**
  String get shareListSubheading;

  /// No description provided for @shareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get shareWhatsApp;

  /// No description provided for @shareWhatsAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Send formatted list directly in chat'**
  String get shareWhatsAppDesc;

  /// No description provided for @shareGmail.
  ///
  /// In en, this message translates to:
  /// **'Share via Gmail'**
  String get shareGmail;

  /// No description provided for @shareGmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Send complete list via email'**
  String get shareGmailDesc;

  /// No description provided for @copyListText.
  ///
  /// In en, this message translates to:
  /// **'Copy list text'**
  String get copyListText;

  /// No description provided for @copyListTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy list content to clipboard'**
  String get copyListTextDesc;

  /// No description provided for @listCopied.
  ///
  /// In en, this message translates to:
  /// **'List copied to clipboard!'**
  String get listCopied;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'Listix: {name}'**
  String shareSubject(String name);

  /// No description provided for @sharedWithListix.
  ///
  /// In en, this message translates to:
  /// **'Created with Listix — Fast & 100% Offline Lists'**
  String get sharedWithListix;

  /// No description provided for @offlineNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline Local Storage'**
  String get offlineNotice;

  /// No description provided for @offlineNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored locally on your device with SQLite. The list is synchronized only when sharing.'**
  String get offlineNoticeDesc;

  /// No description provided for @copyInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share invitation link'**
  String get copyInviteLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @inviteByEmail.
  ///
  /// In en, this message translates to:
  /// **'Or invite by email'**
  String get inviteByEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @inviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteAction;

  /// No description provided for @enterEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get enterEmailError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmailError;

  /// No description provided for @collaboratorsHeading.
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get collaboratorsHeading;

  /// No description provided for @noCollaboratorsYet.
  ///
  /// In en, this message translates to:
  /// **'No collaborators on this list yet.'**
  String get noCollaboratorsYet;

  /// No description provided for @removeCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Remove collaborator'**
  String get removeCollaborator;

  /// No description provided for @ownerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerBadge;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminBadge;

  /// No description provided for @memberBadge.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberBadge;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdmin;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Make Member'**
  String get makeMember;

  /// No description provided for @inviteAsRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get inviteAsRole;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}'**
  String inviteSent(String email);

  /// No description provided for @syncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronization Status'**
  String get syncStatusTitle;

  /// No description provided for @syncStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'Listix operates under an Offline-First architecture with local SQLite storage.'**
  String get syncStatusDescription;

  /// No description provided for @simulateOffline.
  ///
  /// In en, this message translates to:
  /// **'Simulate Offline Mode'**
  String get simulateOffline;

  /// No description provided for @simulateOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test how the app saves data locally with zero connection'**
  String get simulateOfflineSubtitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @statusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get statusSyncing;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get statusSynced;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Listix'**
  String get aboutApp;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String versionLabel(String version, String build);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @offlineFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline-First'**
  String get offlineFirstTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyStatement.
  ///
  /// In en, this message translates to:
  /// **'All shopping lists and items are stored locally on your device. Listix displays advertisements via Google AdMob to support continuous development. Google AdMob may collect and process device identifiers, advertising IDs, and usage analytics to serve non-personalized and personalized ads in accordance with Google\'s Privacy Policy. We never sell your personal data or list contents.'**
  String get privacyStatement;

  /// No description provided for @offlineFirstStatement.
  ///
  /// In en, this message translates to:
  /// **'Offline-First Architecture: Every creation, check-off, and edit occurs at native speed with zero latency on local storage, syncing only when sharing.'**
  String get offlineFirstStatement;

  /// No description provided for @termsStatement.
  ///
  /// In en, this message translates to:
  /// **'Listix is a tool built for personal and collaborative productivity. You retain full ownership of your lists and content.'**
  String get termsStatement;

  /// No description provided for @copyrightFooter.
  ///
  /// In en, this message translates to:
  /// **'© {year} Nicolas Mena. All rights reserved.'**
  String copyrightFooter(int year);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @weeklyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly reminder'**
  String get weeklyReminderTitle;

  /// No description provided for @weeklyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive a weekly reminder to plan your shopping'**
  String get weeklyReminderSubtitle;

  /// No description provided for @notificationTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notificationTimeTitle;

  /// No description provided for @notificationTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String notificationTimeSubtitle(String time);

  /// No description provided for @weeklyReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to plan your shopping!'**
  String get weeklyReminderNotificationTitle;

  /// No description provided for @weeklyReminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Review your lists or create a new one for the week.'**
  String get weeklyReminderNotificationBody;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @listDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted'**
  String listDeleted(String name);

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" deleted'**
  String itemDeleted(String title);

  /// No description provided for @starred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get starred;

  /// No description provided for @starList.
  ///
  /// In en, this message translates to:
  /// **'Star list'**
  String get starList;

  /// No description provided for @unstarList.
  ///
  /// In en, this message translates to:
  /// **'Unstar list'**
  String get unstarList;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'Nicolas Mena'**
  String get developerName;

  /// No description provided for @developerEmail.
  ///
  /// In en, this message translates to:
  /// **'nmena.garzon@gmail.com'**
  String get developerEmail;

  /// No description provided for @contactDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Contact developer'**
  String get contactDeveloper;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyMeACoffee;

  /// No description provided for @buyMeACoffeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support the development of Listix'**
  String get buyMeACoffeeSubtitle;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions, bugs or questions'**
  String get sendFeedbackSubtitle;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate app'**
  String get rateApp;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a review on Google Play'**
  String get rateAppSubtitle;

  /// No description provided for @layoutTitle.
  ///
  /// In en, this message translates to:
  /// **'List Layout'**
  String get layoutTitle;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get layoutGrid;

  /// No description provided for @switchLayout.
  ///
  /// In en, this message translates to:
  /// **'Switch layout'**
  String get switchLayout;

  /// No description provided for @shareSystem.
  ///
  /// In en, this message translates to:
  /// **'Share via system'**
  String get shareSystem;

  /// No description provided for @shareSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Send list and link to WhatsApp, Telegram, Email, and more'**
  String get shareSystemDesc;

  /// No description provided for @shareInviteLinkPrompt.
  ///
  /// In en, this message translates to:
  /// **'🔗 Join this list to collaborate in real-time:\n{url}'**
  String shareInviteLinkPrompt(String url);

  /// No description provided for @sharePendingSection.
  ///
  /// In en, this message translates to:
  /// **'📝 To buy'**
  String get sharePendingSection;

  /// No description provided for @shareCompletedSection.
  ///
  /// In en, this message translates to:
  /// **'✅ Completed'**
  String get shareCompletedSection;

  /// No description provided for @shareEmptyListNotice.
  ///
  /// In en, this message translates to:
  /// **'• (No items in the list yet)'**
  String get shareEmptyListNotice;

  /// No description provided for @realtimeLive.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get realtimeLive;

  /// No description provided for @realtimeConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get realtimeConnecting;

  /// No description provided for @realtimeDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get realtimeDisconnected;

  /// No description provided for @realtimeCollaborating.
  ///
  /// In en, this message translates to:
  /// **'Real-time collaboration active'**
  String get realtimeCollaborating;

  /// No description provided for @realtimeOnlineUsers.
  ///
  /// In en, this message translates to:
  /// **'{count} online'**
  String realtimeOnlineUsers(int count);

  /// No description provided for @joinList.
  ///
  /// In en, this message translates to:
  /// **'Join list'**
  String get joinList;

  /// No description provided for @joinListTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a shared list'**
  String get joinListTitle;

  /// No description provided for @joinListPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code or link to collaborate in real time.'**
  String get joinListPrompt;

  /// No description provided for @joinListHint.
  ///
  /// In en, this message translates to:
  /// **'List code or invite link'**
  String get joinListHint;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinAction;

  /// No description provided for @listJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined \"{name}\"'**
  String listJoined(String name);

  /// No description provided for @invalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invitation code or link'**
  String get invalidInviteCode;

  /// No description provided for @alreadyJoined.
  ///
  /// In en, this message translates to:
  /// **'You already have access to this list'**
  String get alreadyJoined;

  /// No description provided for @collaborators.
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get collaborators;

  /// No description provided for @inviteColleague.
  ///
  /// In en, this message translates to:
  /// **'Invite friends or colleagues'**
  String get inviteColleague;

  /// No description provided for @inviteColleagueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collaborate in real time adding and completing items'**
  String get inviteColleagueSubtitle;

  /// No description provided for @simulateColleagueAction.
  ///
  /// In en, this message translates to:
  /// **'Simulate colleague action'**
  String get simulateColleagueAction;

  /// No description provided for @simulateColleagueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Simulates a colleague adding or completing an item in real time'**
  String get simulateColleagueTooltip;

  /// No description provided for @simulatedItemAdded.
  ///
  /// In en, this message translates to:
  /// **'A colleague added an item in real time'**
  String get simulatedItemAdded;

  /// No description provided for @listIsShared.
  ///
  /// In en, this message translates to:
  /// **'Shared list'**
  String get listIsShared;

  /// No description provided for @listIsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Private list (local only)'**
  String get listIsLocalOnly;

  /// No description provided for @listSharedSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Real-time sync enabled with cloud'**
  String get listSharedSyncEnabled;

  /// No description provided for @listSharedWaitingInvite.
  ///
  /// In en, this message translates to:
  /// **'Share an invitation link to activate sync'**
  String get listSharedWaitingInvite;

  /// No description provided for @listLocalOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Data is stored strictly on this device'**
  String get listLocalOnlyDescription;

  /// No description provided for @enableSharingAction.
  ///
  /// In en, this message translates to:
  /// **'Enable sync'**
  String get enableSharingAction;

  /// No description provided for @supportAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get supportAndFeedback;

  /// No description provided for @inactiveShareInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite others to collaborate'**
  String get inactiveShareInviteTitle;

  /// No description provided for @inactiveShareInviteDescription.
  ///
  /// In en, this message translates to:
  /// **'This list is private and saved only on your device. Turn on sharing to invite friends or colleagues and edit together in real time.'**
  String get inactiveShareInviteDescription;

  /// No description provided for @activateAndShare.
  ///
  /// In en, this message translates to:
  /// **'Activate & Share List'**
  String get activateAndShare;

  /// No description provided for @enableCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Enable Collaboration'**
  String get enableCollaboration;

  /// No description provided for @realtimeSyncFeature.
  ///
  /// In en, this message translates to:
  /// **'Real-time sync when adding or checking off items'**
  String get realtimeSyncFeature;

  /// No description provided for @collaboratorsFeature.
  ///
  /// In en, this message translates to:
  /// **'Easily invite via link or email'**
  String get collaboratorsFeature;

  /// No description provided for @backupAndExport.
  ///
  /// In en, this message translates to:
  /// **'Backup & Export Data'**
  String get backupAndExport;

  /// No description provided for @backupAndExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export or restore your lists using the file system'**
  String get backupAndExportSubtitle;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportJsonBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Full Backup (JSON)'**
  String get exportJsonBackup;

  /// No description provided for @exportJsonBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save all lists and items into a JSON file'**
  String get exportJsonBackupDesc;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup (JSON)'**
  String get importBackup;

  /// No description provided for @importBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Load a backup file from the system file picker'**
  String get importBackupDesc;

  /// No description provided for @exportTextSummary.
  ///
  /// In en, this message translates to:
  /// **'Export Text Summary'**
  String get exportTextSummary;

  /// No description provided for @exportTextSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy or share a readable checklist summary of all lists'**
  String get exportTextSummaryDesc;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save File'**
  String get saveToDevice;

  /// No description provided for @shareBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get shareBackupFile;

  /// No description provided for @openFromFileSystem.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFromFileSystem;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backupSuccess;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored {lists} lists and {items} items'**
  String restoreSuccess(int lists, int items);

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The file contains {lists} lists and {items} items. How would you like to restore?'**
  String restoreConfirmMessage(int lists, int items);

  /// No description provided for @restoreMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge with Existing'**
  String get restoreMerge;

  /// No description provided for @restoreReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace Everything'**
  String get restoreReplace;

  /// No description provided for @backupInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'The file is not a valid Listix backup'**
  String get backupInvalidFile;

  /// No description provided for @backupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lists available to export'**
  String get backupEmpty;

  /// No description provided for @listsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Summary'**
  String get listsSummaryTitle;

  /// No description provided for @totalListsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lists'**
  String totalListsCount(int count);

  /// No description provided for @totalItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String totalItemsCount(int count);

  /// No description provided for @nativeFileSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Native Android File System'**
  String get nativeFileSystemTitle;

  /// No description provided for @nativeFileSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Listix uses Android\'s native Document Picker to save and open backups privately.'**
  String get nativeFileSystemDesc;

  /// No description provided for @exportDataCsv.
  ///
  /// In en, this message translates to:
  /// **'Export data CSV'**
  String get exportDataCsv;

  /// No description provided for @exportDataCsvDesc.
  ///
  /// In en, this message translates to:
  /// **'Save lists and items as a CSV spreadsheet file'**
  String get exportDataCsvDesc;

  /// No description provided for @backupDataJson.
  ///
  /// In en, this message translates to:
  /// **'Backup data JSON'**
  String get backupDataJson;

  /// No description provided for @backupDataJsonDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a complete JSON backup to restore later'**
  String get backupDataJsonDesc;

  /// No description provided for @restoreJson.
  ///
  /// In en, this message translates to:
  /// **'Restore JSON'**
  String get restoreJson;

  /// No description provided for @restoreJsonDesc.
  ///
  /// In en, this message translates to:
  /// **'Open native file picker to restore from a JSON backup'**
  String get restoreJsonDesc;

  /// No description provided for @csvExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV file exported successfully'**
  String get csvExportSuccess;

  /// No description provided for @editItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItemTitle;

  /// No description provided for @itemTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Item title'**
  String get itemTitleLabel;

  /// No description provided for @itemTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Milk'**
  String get itemTitleHint;

  /// No description provided for @itemTitleValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get itemTitleValidation;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get searchItems;

  /// No description provided for @searchItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchItemsHint;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @searchLists.
  ///
  /// In en, this message translates to:
  /// **'Search lists'**
  String get searchLists;

  /// No description provided for @searchListsHint.
  ///
  /// In en, this message translates to:
  /// **'Search lists...'**
  String get searchListsHint;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noSearchResults;

  /// No description provided for @activeLists.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLists;

  /// No description provided for @archivedLists.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedLists;

  /// No description provided for @archiveListAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveListAction;

  /// No description provided for @unarchiveListAction.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchiveListAction;

  /// No description provided for @emptyArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived lists'**
  String get emptyArchivedTitle;

  /// No description provided for @emptyArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Lists you archive will appear here.'**
  String get emptyArchivedMessage;

  /// No description provided for @listArchived.
  ///
  /// In en, this message translates to:
  /// **'List archived'**
  String get listArchived;

  /// No description provided for @listUnarchived.
  ///
  /// In en, this message translates to:
  /// **'List unarchived'**
  String get listUnarchived;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your lists with biometrics or PIN'**
  String get appLockSubtitle;

  /// No description provided for @appLockReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Listix'**
  String get appLockReason;

  /// No description provided for @unlockApp.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockApp;

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'Listix is locked'**
  String get appLocked;

  /// No description provided for @ownerOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can modify this list'**
  String get ownerOnlyAction;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'List color'**
  String get pickColor;

  /// No description provided for @leaveListTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave list?'**
  String get leaveListTitle;

  /// No description provided for @leaveListMessage.
  ///
  /// In en, this message translates to:
  /// **'You will leave \"{name}\" and lose access.'**
  String leaveListMessage(String name);

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;
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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Listix';

  @override
  String get appTagline =>
      'Fast, private, offline-first shopping and todo lists.';

  @override
  String get myLists => 'My Lists';

  @override
  String get emptyListsTitle => 'Your lists, always with you';

  @override
  String get emptyListsMessage =>
      'Create your grocery or task list in seconds. It works completely offline.';

  @override
  String get createFirstList => 'Create your first list';

  @override
  String get newList => 'New list';

  @override
  String get deleteListTitle => 'Delete list?';

  @override
  String deleteListMessage(String name) {
    return 'This will permanently delete \"$name\" and all of its items.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get listCountSuffix => 'lists';

  @override
  String get noItemsBadge => 'No items';

  @override
  String get allDoneBadge => 'All done ✓';

  @override
  String pendingBadge(String progress) {
    return '$progress pending';
  }

  @override
  String get rename => 'Rename';

  @override
  String get shareList => 'Share list';

  @override
  String get noItemsYet => 'No items yet';

  @override
  String pendingCountText(int pending, int total) {
    return '$pending of $total pending';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% completed';
  }

  @override
  String completedGroup(int count) {
    return 'Completed ($count)';
  }

  @override
  String get emptyItemsTitle => 'Empty list';

  @override
  String get emptyItemsMessage =>
      'Type your first item below to add it instantly.';

  @override
  String get quickAddHint => 'Add item';

  @override
  String get quickAddTooltip => 'Add item';

  @override
  String get back => 'Back';

  @override
  String get listNotFound => 'List not found';

  @override
  String get renameListTitle => 'Rename list';

  @override
  String get newListTitle => 'New list';

  @override
  String get editListHeading => 'Edit your list name';

  @override
  String get createListHeading => 'What are you shopping or planning today?';

  @override
  String get editListSubheading =>
      'The updated name is saved instantly and securely on your device.';

  @override
  String get createListSubheading =>
      'Type a clear name (e.g. Weekly Groceries, Hardware, Pharmacy).';

  @override
  String get listNameLabel => 'List name';

  @override
  String get listNameHint => 'e.g. Weekly Groceries';

  @override
  String get listNameValidation => 'Please enter a name';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get createListAction => 'Create list';

  @override
  String get shareHeading => 'Share';

  @override
  String get shareListSubheading =>
      'Send this list instantly via WhatsApp or Gmail.';

  @override
  String get shareWhatsApp => 'Share via WhatsApp';

  @override
  String get shareWhatsAppDesc => 'Send formatted list directly in chat';

  @override
  String get shareGmail => 'Share via Gmail';

  @override
  String get shareGmailDesc => 'Send complete list via email';

  @override
  String get copyListText => 'Copy list text';

  @override
  String get copyListTextDesc => 'Copy list content to clipboard';

  @override
  String get listCopied => 'List copied to clipboard!';

  @override
  String shareSubject(String name) {
    return 'Listix: $name';
  }

  @override
  String get sharedWithListix =>
      'Created with Listix — Fast & 100% Offline Lists';

  @override
  String get offlineNotice => 'Offline Local Storage';

  @override
  String get offlineNoticeDesc =>
      'Your data is stored locally on your device with SQLite. The list is synchronized only when sharing.';

  @override
  String get copyInviteLink => 'Copy invitation link';

  @override
  String get linkCopied => 'Invitation link copied to clipboard';

  @override
  String get inviteByEmail => 'Or invite by email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get inviteAction => 'Invite';

  @override
  String get enterEmailError => 'Please enter an email';

  @override
  String get invalidEmailError => 'Invalid email';

  @override
  String get collaboratorsHeading => 'Collaborators';

  @override
  String get noCollaboratorsYet => 'No collaborators on this list yet.';

  @override
  String get removeCollaborator => 'Remove collaborator';

  @override
  String get ownerBadge => 'Owner';

  @override
  String inviteSent(String email) {
    return 'Invitation sent to $email';
  }

  @override
  String get syncStatusTitle => 'Synchronization Status';

  @override
  String get syncStatusDescription =>
      'Listix operates under an Offline-First architecture with local SQLite storage.';

  @override
  String get simulateOffline => 'Simulate Offline Mode';

  @override
  String get simulateOfflineSubtitle =>
      'Test how the app saves data locally with zero connection';

  @override
  String get close => 'Close';

  @override
  String get syncNow => 'Sync now';

  @override
  String get statusSyncing => 'Syncing...';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusSynced => 'Synced';

  @override
  String get aboutApp => 'About Listix';

  @override
  String get settings => 'Settings';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get version => 'Version';

  @override
  String versionLabel(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get offlineFirstTitle => 'Offline-First';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyStatement =>
      'All shopping lists and items are stored locally on your device. Listix displays advertisements via Google AdMob to support continuous development. Google AdMob may collect and process device identifiers, advertising IDs, and usage analytics to serve non-personalized and personalized ads in accordance with Google\'s Privacy Policy. We never sell your personal data or list contents.';

  @override
  String get offlineFirstStatement =>
      'Offline-First Architecture: Every creation, check-off, and edit occurs at native speed with zero latency on local storage, syncing only when sharing.';

  @override
  String get termsStatement =>
      'Listix is a tool built for personal and collaborative productivity. You retain full ownership of your lists and content.';

  @override
  String copyrightFooter(int year) {
    return '© $year Nicolas Mena. All rights reserved.';
  }

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get weeklyReminderTitle => 'Weekly reminder';

  @override
  String get weeklyReminderSubtitle =>
      'Receive a reminder every Sunday at 10:00 AM to plan your shopping';

  @override
  String get weeklyReminderNotificationTitle => 'Time to plan your shopping!';

  @override
  String get weeklyReminderNotificationBody =>
      'Review your lists or create a new one for the week.';

  @override
  String get undo => 'Undo';

  @override
  String listDeleted(String name) {
    return '\"$name\" deleted';
  }

  @override
  String itemDeleted(String title) {
    return '\"$title\" deleted';
  }

  @override
  String get starred => 'Starred';

  @override
  String get starList => 'Star list';

  @override
  String get unstarList => 'Unstar list';

  @override
  String get reorder => 'Reorder';

  @override
  String get developer => 'Developer';

  @override
  String get developerName => 'Nicolas Mena';

  @override
  String get developerEmail => 'nmena.garzon@gmail.com';

  @override
  String get contactDeveloper => 'Contact developer';

  @override
  String get buyMeACoffee => 'Buy me a coffee';

  @override
  String get buyMeACoffeeSubtitle => 'Support the development of Listix';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get sendFeedbackSubtitle => 'Suggestions, bugs or questions';

  @override
  String get rateApp => 'Rate app';

  @override
  String get rateAppSubtitle => 'Leave a review on Google Play';

  @override
  String get layoutTitle => 'List layout';

  @override
  String get layoutList => 'List';

  @override
  String get layoutGrid => 'Blocks';

  @override
  String get switchLayout => 'Switch layout';

  @override
  String get adPolicyTitle => 'Ad Policy & Privacy';

  @override
  String get adPolicyStatement =>
      'Listix uses Google AdMob. Interstitial ads appear at most once per day during natural transitions to respect your user experience.';
}

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
  String get editAction => 'Edit';

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
  String get createItemAction => 'Create item';

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
  String get copyInviteLink => 'Share invitation link';

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
  String get adminBadge => 'Admin';

  @override
  String get memberBadge => 'Member';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String get makeMember => 'Make Member';

  @override
  String get inviteAsRole => 'Role';

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
  String get notificationsSubtitle =>
      'Receive notifications when items are added to shared lists';

  @override
  String get weeklyReminderTitle => 'Weekly reminder';

  @override
  String get weeklyReminderSubtitle =>
      'Receive a weekly reminder to plan your shopping';

  @override
  String get notificationTimeTitle => 'Reminder time';

  @override
  String notificationTimeSubtitle(String time) {
    return 'Scheduled for $time';
  }

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
  String get layoutTitle => 'List Layout';

  @override
  String get layoutList => 'List';

  @override
  String get layoutGrid => 'Blocks';

  @override
  String get switchLayout => 'Switch layout';

  @override
  String get shareSystem => 'Share via system';

  @override
  String get shareSystemDesc =>
      'Send list and link to WhatsApp, Telegram, Email, and more';

  @override
  String shareInviteLinkPrompt(String url) {
    return '🔗 Join this list to collaborate in real-time:\n$url';
  }

  @override
  String get sharePendingSection => '📝 To buy';

  @override
  String get shareCompletedSection => '✅ Completed';

  @override
  String get shareEmptyListNotice => '• (No items in the list yet)';

  @override
  String get realtimeLive => 'Sharing';

  @override
  String get realtimeConnecting => 'Connecting...';

  @override
  String get realtimeDisconnected => 'Disconnected';

  @override
  String get realtimeCollaborating => 'Real-time collaboration active';

  @override
  String realtimeOnlineUsers(int count) {
    return '$count online';
  }

  @override
  String get joinList => 'Join list';

  @override
  String get joinListTitle => 'Join a shared list';

  @override
  String get joinListPrompt =>
      'Enter the invite code or link to collaborate in real time.';

  @override
  String get joinListHint => 'List code or invite link';

  @override
  String get joinAction => 'Join';

  @override
  String get yourNicknameLabel => 'Your nickname or name';

  @override
  String get yourNicknameHint => 'E.g., Alex or @alex';

  @override
  String get yourNicknamePrompt =>
      'Enter your nickname or name to collaborate in real time.';

  @override
  String get yourNicknameValidation => 'Please enter a name or nickname';

  @override
  String listJoined(String name) {
    return 'You joined \"$name\"';
  }

  @override
  String get invalidInviteCode => 'Invalid invitation code or link';

  @override
  String get alreadyJoined => 'You already have access to this list';

  @override
  String get collaborators => 'Collaborators';

  @override
  String get inviteColleague => 'Invite friends or colleagues';

  @override
  String get inviteColleagueSubtitle =>
      'Collaborate in real time adding and completing items';

  @override
  String get simulateColleagueAction => 'Simulate colleague action';

  @override
  String get simulateColleagueTooltip =>
      'Simulates a colleague adding or completing an item in real time';

  @override
  String get simulatedItemAdded => 'A colleague added an item in real time';

  @override
  String get listIsShared => 'Shared list';

  @override
  String get listIsLocalOnly => 'Private list (local only)';

  @override
  String get listSharedSyncEnabled => 'Real-time sync enabled with cloud';

  @override
  String get listSharedWaitingInvite =>
      'Share an invitation link to activate sync';

  @override
  String get listLocalOnlyDescription =>
      'Data is stored strictly on this device';

  @override
  String get enableSharingAction => 'Enable sync';

  @override
  String get supportAndFeedback => 'Support & Feedback';

  @override
  String get inactiveShareInviteTitle => 'Invite others to collaborate';

  @override
  String get inactiveShareInviteDescription =>
      'This list is private and saved only on your device. Turn on sharing to invite friends or colleagues and edit together in real time.';

  @override
  String get activateAndShare => 'Activate & Share List';

  @override
  String get enableCollaboration => 'Enable Collaboration';

  @override
  String get realtimeSyncFeature =>
      'Real-time sync when adding or checking off items';

  @override
  String get collaboratorsFeature => 'Easily invite via link or email';

  @override
  String get backupAndExport => 'Backup & Export Data';

  @override
  String get backupAndExportSubtitle =>
      'Export or restore your lists using the file system';

  @override
  String get backupTitle => 'Backup';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportJsonBackup => 'Export Full Backup (JSON)';

  @override
  String get exportJsonBackupDesc =>
      'Save all lists and items into a JSON file';

  @override
  String get importBackup => 'Restore Backup (JSON)';

  @override
  String get importBackupDesc =>
      'Load a backup file from the system file picker';

  @override
  String get exportTextSummary => 'Export Text Summary';

  @override
  String get exportTextSummaryDesc =>
      'Copy or share a readable checklist summary of all lists';

  @override
  String get saveToDevice => 'Save File';

  @override
  String get shareBackupFile => 'Share File';

  @override
  String get openFromFileSystem => 'Open File';

  @override
  String get backupSuccess => 'Backup exported successfully';

  @override
  String restoreSuccess(int lists, int items) {
    return 'Restored $lists lists and $items items';
  }

  @override
  String get restoreConfirmTitle => 'Restore Backup?';

  @override
  String restoreConfirmMessage(int lists, int items) {
    return 'The file contains $lists lists and $items items. How would you like to restore?';
  }

  @override
  String get restoreMerge => 'Merge with Existing';

  @override
  String get restoreReplace => 'Replace Everything';

  @override
  String get backupInvalidFile => 'The file is not a valid Listix backup';

  @override
  String get backupEmpty => 'No lists available to export';

  @override
  String get listsSummaryTitle => 'Data Summary';

  @override
  String totalListsCount(int count) {
    return '$count lists';
  }

  @override
  String totalItemsCount(int count) {
    return '$count items';
  }

  @override
  String get nativeFileSystemTitle => 'Native Android File System';

  @override
  String get nativeFileSystemDesc =>
      'Listix uses Android\'s native Document Picker to save and open backups privately.';

  @override
  String get exportDataCsv => 'Export data CSV';

  @override
  String get exportDataCsvDesc =>
      'Save lists and items as a CSV spreadsheet file';

  @override
  String get backupDataJson => 'Backup data JSON';

  @override
  String get backupDataJsonDesc =>
      'Create a complete JSON backup to restore later';

  @override
  String get restoreJson => 'Restore JSON';

  @override
  String get restoreJsonDesc =>
      'Open native file picker to restore from a JSON backup';

  @override
  String get csvExportSuccess => 'CSV file exported successfully';

  @override
  String get editItemTitle => 'Edit item';

  @override
  String get itemTitleLabel => 'Item title';

  @override
  String get itemTitleHint => 'e.g. Milk';

  @override
  String get itemTitleValidation => 'Please enter a title';

  @override
  String get searchItems => 'Search items';

  @override
  String get searchItemsHint => 'Search items...';

  @override
  String get closeSearch => 'Close search';

  @override
  String get searchLists => 'Search lists';

  @override
  String get searchListsHint => 'Search lists...';

  @override
  String get noSearchResults => 'No results found';

  @override
  String get activeLists => 'Active';

  @override
  String get archivedLists => 'Archived';

  @override
  String get archiveListAction => 'Archive';

  @override
  String get unarchiveListAction => 'Unarchive';

  @override
  String get emptyArchivedTitle => 'No archived lists';

  @override
  String get emptyArchivedMessage => 'Lists you archive will appear here.';

  @override
  String get listArchived => 'List archived';

  @override
  String get listUnarchived => 'List unarchived';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockSubtitle => 'Protect your lists with biometrics or PIN';

  @override
  String get appLockReason => 'Authenticate to unlock Listix';

  @override
  String get unlockApp => 'Unlock';

  @override
  String get appLocked => 'Listix is locked';

  @override
  String get ownerOnlyAction => 'Only the owner can modify this list';

  @override
  String get pickColor => 'List color';

  @override
  String get leaveListTitle => 'Leave list?';

  @override
  String leaveListMessage(String name) {
    return 'You will leave \"$name\" and lose access.';
  }

  @override
  String get leave => 'Leave';

  @override
  String get confirmArchiveTitle => 'Archive list?';

  @override
  String confirmArchiveMessage(String name) {
    return 'Are you sure you want to archive \"$name\"?';
  }

  @override
  String get deleteAllArchivedLists => 'Delete all archived';

  @override
  String get deleteArchivedListsTitle => 'Delete all archived lists?';

  @override
  String deleteArchivedListsMessage(int count) {
    return 'All $count archived lists and their items will be permanently deleted.';
  }

  @override
  String archivedListsDeleted(int count) {
    return '$count archived lists deleted';
  }

  @override
  String get deleteCompletedItems => 'Delete completed';

  @override
  String get deleteCompletedItemsTitle => 'Delete completed items?';

  @override
  String deleteCompletedItemsMessage(int count) {
    return 'All $count completed items will be permanently deleted.';
  }

  @override
  String completedItemsDeleted(int count) {
    return '$count completed items deleted';
  }

  @override
  String inviteProcessError(String error) {
    return 'Could not process invite: $error';
  }

  @override
  String get shareAsText => 'Share as text';

  @override
  String get copyListAsText => 'Copy list text';

  @override
  String get shareTextSubtitle =>
      'Share or copy list items as text without real-time sync';

  @override
  String get listTextCopied => 'List text copied to clipboard';

  @override
  String get realtimeCollaboration => 'Real-time collaboration';

  @override
  String get itemActions => 'Item actions';

  @override
  String get listTypePickerHeading => 'What kind of list do you need?';

  @override
  String get listTypePickerSubheading =>
      'Pick a structure, then give your list a name.';

  @override
  String get changeListType => 'Change type';

  @override
  String get listTypeMarket => 'Groceries';

  @override
  String get listTypeMarketDesc =>
      'Products by category, with quantities and units.';

  @override
  String get listTypeShopping => 'Shopping';

  @override
  String get listTypeShoppingDesc =>
      'Items with price, store, link and priority.';

  @override
  String get listTypeOptions => 'Options';

  @override
  String get listTypeOptionsDesc =>
      'Compare alternatives and pick one: universities, phones, apartments.';

  @override
  String get listTypeTasks => 'Tasks';

  @override
  String get listTypeTasksDesc =>
      'Activities with status, priority and due date.';

  @override
  String get listTypeCustom => 'Custom';

  @override
  String get listTypeCustomDesc => 'A flexible list with basic items.';

  @override
  String get newItemTitle => 'New item';

  @override
  String get itemDetailsTitle => 'Item details';

  @override
  String get addWithDetails => 'Add with details';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get categoryLabel => 'Category';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priceLabel => 'Price';

  @override
  String get storeLabel => 'Store';

  @override
  String get linkLabel => 'Link';

  @override
  String get linkInvalid => 'Enter a valid http(s) link';

  @override
  String get numberInvalid => 'Enter a valid number';

  @override
  String get notesLabel => 'Notes';

  @override
  String get favoriteLabel => 'Favorite';

  @override
  String get chosenBadge => 'Chosen';

  @override
  String get markChosen => 'Mark as chosen';

  @override
  String get unmarkChosen => 'Remove choice';

  @override
  String get addFavorite => 'Mark as favorite';

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get noDueDate => 'No date';

  @override
  String get clearDate => 'Clear date';

  @override
  String get inProgressLabel => 'In progress';

  @override
  String get openLink => 'Open link';

  @override
  String get categoryProduce => 'Produce';

  @override
  String get categoryDairy => 'Dairy & eggs';

  @override
  String get categoryMeat => 'Meat & fish';

  @override
  String get categoryBakery => 'Bakery';

  @override
  String get categoryPantry => 'Pantry';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryCleaning => 'Cleaning';

  @override
  String get categoryOther => 'Other';

  @override
  String optionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count options',
      one: '1 option',
    );
    return '$_temp0';
  }

  @override
  String shoppingTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get descriptionLabel => 'Description';

  @override
  String get imageUrlLabel => 'Image link';

  @override
  String get imageUrlInvalid => 'Enter a valid http(s) image link';

  @override
  String get estimatedPriceLabel => 'Estimated price';

  @override
  String get evaluationLabel => 'Evaluation';

  @override
  String get evaluationPending => 'To evaluate';

  @override
  String get evaluationEvaluated => 'Evaluated';

  @override
  String get evaluationDiscarded => 'Discarded';

  @override
  String get manageAttributes => 'Comparison attributes';

  @override
  String get attributeNameLabel => 'New attribute';

  @override
  String get attributeNameHint => 'e.g. Tuition, Area, Battery';

  @override
  String get addAttribute => 'Add';

  @override
  String get removeAttribute => 'Remove attribute';

  @override
  String get attributesEmpty =>
      'No attributes yet. Add the traits you want to compare.';

  @override
  String get compareOptions => 'Compare options';

  @override
  String get compareNeedsTwo => 'Add at least two options to compare them.';

  @override
  String get optionColumn => 'Option';

  @override
  String get sortItems => 'Sort';

  @override
  String get sortManual => 'Manual order';

  @override
  String get sortPrice => 'Price';

  @override
  String get sortPriority => 'Priority';

  @override
  String get sortDueDate => 'Due date';

  @override
  String get favoritesOnly => 'Favorites only';

  @override
  String get emptyMarketMessage =>
      'Add your first product below. Set quantity, unit and category with the details button.';

  @override
  String get emptyShoppingMessage =>
      'Add your first item below. Track its price, store and link with the details button.';

  @override
  String get emptyOptionsMessage =>
      'Add your first option below, then add notes and attributes to compare alternatives.';

  @override
  String get emptyTasksMessage =>
      'Add your first task below. Set a due date and priority with the details button.';

  @override
  String get retry => 'Retry';

  @override
  String get goHome => 'Go home';

  @override
  String get openList => 'Open list';

  @override
  String get changeRole => 'Change role';

  @override
  String get authenticationFailed => 'Authentication failed';

  @override
  String get generatingInviteLink => 'Generating invite link...';

  @override
  String get shareLinkAction => 'Share link';

  @override
  String get copyLinkAction => 'Copy link';

  @override
  String inviteLinkError(String error) {
    return 'Could not generate the link: $error';
  }

  @override
  String inviteLinkCreateError(String error) {
    return 'Could not create the invite link: $error';
  }
}

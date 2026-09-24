import 'package:flutter/material.dart';

import 'generated/app_localizations.dart';

enum AppLanguage { es, en }

class AppStrings {
  final AppLocalizations _l10n;

  AppStrings(AppLanguage language)
    : _l10n = lookupAppLocalizations(Locale(language.name));

  const AppStrings.fromLocalizations(this._l10n);

  AppLanguage get language =>
      _l10n.localeName == 'en' ? AppLanguage.en : AppLanguage.es;

  bool get isSpanish => language == AppLanguage.es;

  String get appName => _l10n.appName;
  String get appTagline => _l10n.appTagline;

  String get myLists => _l10n.myLists;
  String get emptyListsTitle => _l10n.emptyListsTitle;
  String get emptyListsMessage => _l10n.emptyListsMessage;
  String get createFirstList => _l10n.createFirstList;
  String get newList => _l10n.newList;
  String get deleteListTitle => _l10n.deleteListTitle;
  String deleteListMessage(String name) => _l10n.deleteListMessage(name);
  String get cancel => _l10n.cancel;
  String get delete => _l10n.delete;
  String get listCountSuffix => _l10n.listCountSuffix;
  String get noItemsBadge => _l10n.noItemsBadge;
  String get allDoneBadge => _l10n.allDoneBadge;
  String pendingBadge(String progress) => _l10n.pendingBadge(progress);

  String get rename => _l10n.rename;
  String get shareList => _l10n.shareList;
  String get noItemsYet => _l10n.noItemsYet;
  String pendingCountText(int pending, int total) =>
      _l10n.pendingCountText(pending, total);
  String percentCompleted(int percent) => _l10n.percentCompleted(percent);
  String completedGroup(int count) => _l10n.completedGroup(count);
  String get emptyItemsTitle => _l10n.emptyItemsTitle;
  String get emptyItemsMessage => _l10n.emptyItemsMessage;
  String get quickAddHint => _l10n.quickAddHint;
  String get quickAddTooltip => _l10n.quickAddTooltip;
  String get back => _l10n.back;
  String get listNotFound => _l10n.listNotFound;

  String get renameListTitle => _l10n.renameListTitle;
  String get newListTitle => _l10n.newListTitle;
  String get editListHeading => _l10n.editListHeading;
  String get createListHeading => _l10n.createListHeading;
  String get editListSubheading => _l10n.editListSubheading;
  String get createListSubheading => _l10n.createListSubheading;
  String get listNameLabel => _l10n.listNameLabel;
  String get listNameHint => _l10n.listNameHint;
  String get listNameValidation => _l10n.listNameValidation;
  String get saveChanges => _l10n.saveChanges;
  String get createListAction => _l10n.createListAction;

  String get shareHeading => _l10n.shareHeading;
  String get shareListSubheading => _l10n.shareListSubheading;
  String get shareWhatsApp => _l10n.shareWhatsApp;
  String get shareWhatsAppDesc => _l10n.shareWhatsAppDesc;
  String get shareGmail => _l10n.shareGmail;
  String get shareGmailDesc => _l10n.shareGmailDesc;
  String get copyListText => _l10n.copyListText;
  String get copyListTextDesc => _l10n.copyListTextDesc;
  String get listCopied => _l10n.listCopied;
  String shareSubject(String name) => _l10n.shareSubject(name);
  String get sharedWithListix => _l10n.sharedWithListix;
  String get offlineNotice => _l10n.offlineNotice;
  String get offlineNoticeDesc => _l10n.offlineNoticeDesc;
  String get copyInviteLink => _l10n.copyInviteLink;
  String get linkCopied => _l10n.linkCopied;
  String get inviteByEmail => _l10n.inviteByEmail;
  String get emailHint => _l10n.emailHint;
  String get inviteAction => _l10n.inviteAction;
  String get enterEmailError => _l10n.enterEmailError;
  String get invalidEmailError => _l10n.invalidEmailError;
  String get collaboratorsHeading => _l10n.collaboratorsHeading;
  String get noCollaboratorsYet => _l10n.noCollaboratorsYet;
  String get removeCollaborator => _l10n.removeCollaborator;
  String get ownerBadge => _l10n.ownerBadge;
  String inviteSent(String email) => _l10n.inviteSent(email);

  String get syncStatusTitle => _l10n.syncStatusTitle;
  String get syncStatusDescription => _l10n.syncStatusDescription;
  String get simulateOffline => _l10n.simulateOffline;
  String get simulateOfflineSubtitle => _l10n.simulateOfflineSubtitle;
  String get close => _l10n.close;
  String get syncNow => _l10n.syncNow;
  String get statusSyncing => _l10n.statusSyncing;
  String get statusOffline => _l10n.statusOffline;
  String get statusPending => _l10n.statusPending;
  String get statusSynced => _l10n.statusSynced;

  String get settings => _l10n.settings;
  String get themeTitle => _l10n.themeTitle;
  String get themeSystem => _l10n.themeSystem;
  String get themeLight => _l10n.themeLight;
  String get themeDark => _l10n.themeDark;

  String get notificationsTitle => _l10n.notificationsTitle;
  String get weeklyReminderTitle => _l10n.weeklyReminderTitle;
  String get weeklyReminderSubtitle => _l10n.weeklyReminderSubtitle;
  String get weeklyReminderNotificationTitle =>
      _l10n.weeklyReminderNotificationTitle;
  String get weeklyReminderNotificationBody =>
      _l10n.weeklyReminderNotificationBody;

  String get undo => _l10n.undo;
  String listDeleted(String name) => _l10n.listDeleted(name);
  String itemDeleted(String title) => _l10n.itemDeleted(title);
  String get starred => _l10n.starred;
  String get starList => _l10n.starList;
  String get unstarList => _l10n.unstarList;
  String get reorder => _l10n.reorder;

  String get aboutApp => _l10n.aboutApp;
  String get version => _l10n.version;
  String versionLabel(String version, String build) =>
      _l10n.versionLabel(version, build);
  String get languageTitle => _l10n.languageTitle;
  String get spanish => _l10n.spanish;
  String get english => _l10n.english;
  String get offlineFirstTitle => _l10n.offlineFirstTitle;
  String get privacyPolicy => _l10n.privacyPolicy;
  String get termsOfService => _l10n.termsOfService;
  String get privacyStatement => _l10n.privacyStatement;
  String get offlineFirstStatement => _l10n.offlineFirstStatement;
  String get termsStatement => _l10n.termsStatement;
  String copyrightFooter(int year) => _l10n.copyrightFooter(year);
  String errorPrefix(String error) => _l10n.errorPrefix(error);

  String get developer => _l10n.developer;
  String get developerName => _l10n.developerName;
  String get developerEmail => _l10n.developerEmail;
  String get contactDeveloper => _l10n.contactDeveloper;
  String get buyMeACoffee => _l10n.buyMeACoffee;
  String get buyMeACoffeeSubtitle => _l10n.buyMeACoffeeSubtitle;
  String get sendFeedback => _l10n.sendFeedback;
  String get sendFeedbackSubtitle => _l10n.sendFeedbackSubtitle;
  String get rateApp => _l10n.rateApp;
  String get rateAppSubtitle => _l10n.rateAppSubtitle;
  String get layoutTitle => _l10n.layoutTitle;
  String get layoutList => _l10n.layoutList;
  String get layoutGrid => _l10n.layoutGrid;
  String get switchLayout => _l10n.switchLayout;
  String get adPolicyTitle => _l10n.adPolicyTitle;
  String get adPolicyStatement => _l10n.adPolicyStatement;
  String get notificationTimeTitle => _l10n.notificationTimeTitle;
  String notificationTimeSubtitle(String time) =>
      _l10n.notificationTimeSubtitle(time);
  String get shareSystem => _l10n.shareSystem;
  String get shareSystemDesc => _l10n.shareSystemDesc;

  String get realtimeLive => _l10n.realtimeLive;
  String get realtimeConnecting => _l10n.realtimeConnecting;
  String get realtimeDisconnected => _l10n.realtimeDisconnected;
  String get realtimeCollaborating => _l10n.realtimeCollaborating;
  String realtimeOnlineUsers(int count) => _l10n.realtimeOnlineUsers(count);
  String get joinList => _l10n.joinList;
  String get joinListTitle => _l10n.joinListTitle;
  String get joinListPrompt => _l10n.joinListPrompt;
  String get joinListHint => _l10n.joinListHint;
  String get joinAction => _l10n.joinAction;
  String listJoined(String name) => _l10n.listJoined(name);
  String get invalidInviteCode => _l10n.invalidInviteCode;
  String get alreadyJoined => _l10n.alreadyJoined;
  String get collaborators => _l10n.collaborators;
  String get inviteColleague => _l10n.inviteColleague;
  String get inviteColleagueSubtitle => _l10n.inviteColleagueSubtitle;
  String get simulateColleagueAction => _l10n.simulateColleagueAction;
  String get simulateColleagueTooltip => _l10n.simulateColleagueTooltip;
  String get simulatedItemAdded => _l10n.simulatedItemAdded;
  String get listIsShared => _l10n.listIsShared;
  String get listIsLocalOnly => _l10n.listIsLocalOnly;
  String get listSharedSyncEnabled => _l10n.listSharedSyncEnabled;
  String get listLocalOnlyDescription => _l10n.listLocalOnlyDescription;
  String get enableSharingAction => _l10n.enableSharingAction;
  String shareInviteLinkPrompt(String url) => _l10n.shareInviteLinkPrompt(url);
  String get sharePendingSection => _l10n.sharePendingSection;
  String get shareCompletedSection => _l10n.shareCompletedSection;
  String get shareEmptyListNotice => _l10n.shareEmptyListNotice;
  String get supportAndFeedback => _l10n.supportAndFeedback;
}

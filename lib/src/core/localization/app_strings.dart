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

  // General & Brand
  String get appName => _l10n.appName;
  String get appTagline => _l10n.appTagline;

  // Home / Index Screen
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

  // List Detail Screen
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

  // Create / Edit List Screen
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

  // Share List Sheet
  String get shareHeading => _l10n.shareHeading;
  String get shareListSubheading => _l10n.shareListSubheading;
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

  // Sync Status
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

  // About, Policy & Privacy
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
}

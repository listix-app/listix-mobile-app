import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../collaboration/presentation/controllers/collaboration_controller.dart';
import '../../../collaboration/presentation/widgets/realtime_presence_badge.dart';
import '../../domain/entities/shopping_list.dart';
import '../controllers/lists_controller.dart';
import '../services/share_service.dart';
import '../widgets/collaborator_tile.dart';

class ShareListSheet extends ConsumerStatefulWidget {
  final String listId;

  const ShareListSheet({super.key, required this.listId});

  static Future<void> show(BuildContext context, String listId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareListSheet(listId: listId),
    );
  }

  @override
  ConsumerState<ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends ConsumerState<ShareListSheet> {
  Future<void> _shareSystem(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final tr = ref.read(stringsProvider);
    await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
    final inviteLink = ShareService.createInviteLink(list.id, list.name);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
      inviteLinkText: tr.shareInviteLinkPrompt(inviteLink),
      pendingSectionTitle: tr.sharePendingSection,
      completedSectionTitle: tr.shareCompletedSection,
      emptyListText: tr.shareEmptyListNotice,
    );
    final subject = tr.shareSubject(list.name);
    final shareService = ref.read(shareServiceProvider);
    await shareService.shareWithSystem(
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _copyInviteLink(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final tr = ref.read(stringsProvider);
    final inviteLink = ShareService.createInviteLink(list.id, list.name);
    final shareService = ref.read(shareServiceProvider);
    await shareService.copyToClipboard(inviteLink);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.linkCopied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _simulateColleagueAction(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    AppStrings tr,
  ) async {
    await ref
        .read(collaborationControllerProvider.notifier)
        .simulatePeerAction(list.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.simulatedItemAdded),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.syncDone,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(shoppingListProvider(widget.listId));
    final tr = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark ? AppColors.cardDark : Colors.white;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textMutedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final handleColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (list == null) {
      return Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Text(tr.listNotFound, style: TextStyle(color: textTitleColor)),
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with Realtime status
            Row(
              children: [
                const Icon(
                  Icons.share_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tr.shareHeading} "${list.name}"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textTitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (list.isShared) ...[
                  const SizedBox(width: 8),
                  const RealtimePresenceBadge(),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tr.inviteColleagueSubtitle,
              style: TextStyle(fontSize: 13, color: textMutedColor),
            ),
            const SizedBox(height: 14),

            // Collaboration & Cloud Sync status switch
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: list.isShared
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: list.isShared
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : handleColor,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile.adaptive(
                  key: const Key('toggle_shared_switch'),
                  value: list.isShared,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                  inactiveThumbColor: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF94A3B8),
                  inactiveTrackColor: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFE2E8F0),
                  thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      );
                    }
                    return null;
                  }),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (list.isShared
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight))
                              .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      list.isShared
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: list.isShared
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    list.isShared ? tr.listIsShared : tr.listIsLocalOnly,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textTitleColor,
                    ),
                  ),
                  subtitle: Text(
                    list.isShared
                        ? tr.listSharedSyncEnabled
                        : tr.listLocalOnlyDescription,
                    style: TextStyle(fontSize: 12, color: textMutedColor),
                  ),
                  onChanged: (bool value) async {
                    await ref
                        .read(listsControllerProvider.notifier)
                        .setListShared(list.id, value);
                  },
                ),
              ),
            ),

            if (!list.isShared) ...[
              // When inactive: show dedicated List Invite Component
              _InactiveShareInviteComponent(
                list: list,
                tr: tr,
                isDark: isDark,
                cardBg: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderColor: handleColor,
                textTitleColor: textTitleColor,
                textMutedColor: textMutedColor,
                onActivateAndShare: () async {
                  await ref
                      .read(listsControllerProvider.notifier)
                      .setListShared(list.id, true);
                  if (context.mounted) {
                    await _shareSystem(context, ref, list);
                  }
                },
                onEnableCollaboration: () async {
                  await ref
                      .read(listsControllerProvider.notifier)
                      .setListShared(list.id, true);
                },
              ),
              const SizedBox(height: 8),
              // Section: System Share
              _ShareOptionTile(
                key: const Key('share_system_tile'),
                icon: Icons.share_rounded,
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primary.withValues(alpha: 0.14),
                title: tr.shareSystem,
                subtitle: tr.shareSystemDesc,
                onTap: () => _shareSystem(context, ref, list),
              ),
            ] else ...[
              // When active: show full Collaborators and Sharing Screen
              _ShareOptionTile(
                key: const Key('share_system_tile'),
                icon: Icons.share_rounded,
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primary.withValues(alpha: 0.14),
                title: tr.shareSystem,
                subtitle: tr.shareSystemDesc,
                onTap: () => _shareSystem(context, ref, list),
              ),
              const SizedBox(height: 10),

              // Copy invite link button
              OutlinedButton.icon(
                key: const Key('copy_invite_link_button'),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: Text(tr.copyInviteLink),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _copyInviteLink(context, ref, list),
              ),
              const SizedBox(height: 16),

              // Section: Current Collaborators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tr.collaboratorsHeading} (${list.collaborators.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textTitleColor,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('simulate_peer_button'),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(
                      tr.simulateColleagueAction,
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.syncDone,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        _simulateColleagueAction(context, ref, list, tr),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (list.collaborators.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    tr.noCollaboratorsYet,
                    style: TextStyle(fontSize: 13, color: textMutedColor),
                  ),
                )
              else
                ...list.collaborators.map(
                  (collab) => CollaboratorTile(
                    key: ValueKey('collab_${collab.id}'),
                    collaborator: collab,
                    ownerLabel: tr.ownerBadge,
                    adminLabel: tr.adminBadge,
                    memberLabel: tr.memberBadge,
                    removeTooltip: tr.removeCollaborator,
                    onRoleChanged: collab.isOwner
                        ? null
                        : (newRole) {
                            ref
                                .read(listsControllerProvider.notifier)
                                .updateCollaboratorRole(
                                  list.id,
                                  collab.id,
                                  newRole,
                                );
                          },
                    onRemove: collab.isOwner
                        ? null
                        : () {
                            ref
                                .read(listsControllerProvider.notifier)
                                .removeCollaborator(list.id, collab.id);
                          },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InactiveShareInviteComponent extends StatelessWidget {
  final ShoppingList list;
  final AppStrings tr;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textTitleColor;
  final Color textMutedColor;
  final VoidCallback onActivateAndShare;
  final VoidCallback onEnableCollaboration;

  const _InactiveShareInviteComponent({
    required this.list,
    required this.tr,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textTitleColor,
    required this.textMutedColor,
    required this.onActivateAndShare,
    required this.onEnableCollaboration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inactive_share_invite_component'),
      margin: const EdgeInsets.only(top: 4, bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.inactiveShareInviteTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textTitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr.inviteColleagueSubtitle,
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr.inactiveShareInviteDescription,
            style: TextStyle(fontSize: 13, height: 1.45, color: textMutedColor),
          ),
          const SizedBox(height: 16),
          _BenefitRow(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFF59E0B),
            text: tr.realtimeSyncFeature,
            textColor: textTitleColor,
          ),
          const SizedBox(height: 10),
          _BenefitRow(
            icon: Icons.link_rounded,
            iconColor: const Color(0xFF6366F1),
            text: tr.collaboratorsFeature,
            textColor: textTitleColor,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('activate_and_share_button'),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(
              tr.activateAndShare,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onActivateAndShare,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('enable_sharing_button'),
            icon: const Icon(Icons.cloud_sync_rounded, size: 18),
            label: Text(tr.enableCollaboration),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onEnableCollaboration,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  const _BenefitRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

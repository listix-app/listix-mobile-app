import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../collaboration/data/repositories/supabase_collaboration_repository.dart';
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
  Future<String> _getOrGenerateInviteLink(
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    // coverage:ignore-start
    if (supabaseService.isReady) {
      final supabaseCollab = ref.read(supabaseCollaborationRepositoryProvider);
      return await supabaseCollab.createInviteLink(listId: list.id);
    }
    // coverage:ignore-end
    throw StateError(
      'Supabase no está disponible. Verifica Anonymous Sign-Ins en el proyecto.',
    );
  }

  Future<void> _shareInviteLink(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final tr = ref.read(stringsProvider);
    // coverage:ignore-start
    try {
      await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
      final inviteLink = await _getOrGenerateInviteLink(ref, list);
      await ref
          .read(shareServiceProvider)
          .shareWithSystem(
            text: tr.shareInviteLinkPrompt(inviteLink),
            subject: tr.shareSubject(list.name),
            sharePositionOrigin: sharePositionOrigin,
          );
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      // coverage:ignore-end
      if (context.mounted) _showShareError(context, error);
    }
  }

  void _showShareError(BuildContext context, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('No se pudo crear el enlace de invitación: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                if (list.canSyncAndShare) ...[
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

            if (!list.isOwner)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr.ownerOnlyAction,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                        ? (list.canSyncAndShare
                              ? tr.listSharedSyncEnabled
                              : tr.listSharedWaitingInvite)
                        : tr.listLocalOnlyDescription,
                    style: TextStyle(fontSize: 12, color: textMutedColor),
                  ),
                  onChanged: list.isOwner
                      ? (bool value) async {
                          await ref
                              .read(listsControllerProvider.notifier)
                              .setListShared(list.id, value);
                        }
                      : null,
                ),
              ),
            ),

            if (!list.isShared) ...[
              if (list.isOwner)
                _InactiveShareInviteComponent(
                  list: list,
                  tr: tr,
                  isDark: isDark,
                  cardBg: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderColor: handleColor,
                  textTitleColor: textTitleColor,
                  textMutedColor: textMutedColor,
                  onActivateAndShare: () async {
                    await ref
                        .read(listsControllerProvider.notifier)
                        .setListShared(list.id, true);
                    if (context.mounted) {
                      await _shareInviteLink(context, ref, list);
                    }
                  },
                  onEnableCollaboration: () async {
                    await ref
                        .read(listsControllerProvider.notifier)
                        .setListShared(list.id, true);
                  },
                ),
            ] else ...[
              if (list.isOwner) ...[
                OutlinedButton.icon(
                  key: const Key('share_invite_link_button'),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(tr.copyInviteLink),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // coverage:ignore-start
                  onPressed: () => _shareInviteLink(context, ref, list),
                  // coverage:ignore-end
                ),
                const SizedBox(height: 14),
              ],

              // Section: Current Collaborators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tr.collaboratorsHeading} (${list.collaborators.length}/5 máx.)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textTitleColor,
                    ),
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
                    onRoleChanged: (list.isOwner && !collab.isOwner)
                        ? (newRole) {
                            ref
                                .read(listsControllerProvider.notifier)
                                .updateCollaboratorRole(
                                  list.id,
                                  collab.id,
                                  newRole,
                                );
                          }
                        : null,
                    onRemove: (list.isOwner && !collab.isOwner)
                        ? () {
                            ref
                                .read(listsControllerProvider.notifier)
                                .removeCollaborator(list.id, collab.id);
                          }
                        : null,
                  ),
                ),
            ],
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr.inactiveShareInviteTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textTitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr.inactiveShareInviteDescription,
            style: TextStyle(fontSize: 12, color: textMutedColor, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('activate_shared_button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: onEnableCollaboration,
                  child: Text(
                    tr.enableCollaboration,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('activate_and_share_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    tr.activateAndShare,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onActivateAndShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

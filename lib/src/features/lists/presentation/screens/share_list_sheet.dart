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
  final _emailController = TextEditingController();
  final _inviteFormKey = GlobalKey<FormState>();
  bool _isInviting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
    if (!list.isShared) {
      await ref
          .read(listsControllerProvider.notifier)
          .setListShared(list.id, true);
    }
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

  Future<void> _handleInvite(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    AppStrings tr,
  ) async {
    if (!_inviteFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isInviting = true);

    try {
      await ref
          .read(listsControllerProvider.notifier)
          .addCollaborator(list.id, email);
      _emailController.clear();
      setState(() => _isInviting = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.inviteSent(email)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isInviting = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.errorPrefix(e.toString())),
            backgroundColor: AppColors.delete,
          ),
        );
      }
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
                  activeTrackColor: AppColors.primary,
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

            const SizedBox(height: 16),
            Divider(color: handleColor),
            const SizedBox(height: 12),

            // Section: Invite Colleague by Email
            Text(
              tr.inviteColleague,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textTitleColor,
              ),
            ),
            const SizedBox(height: 8),
            Form(
              key: _inviteFormKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('collaborator_email_input'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: tr.emailHint,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return tr.enterEmailError;
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return tr.invalidEmailError;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          _handleInvite(context, ref, list, tr),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('invite_collaborator_button'),
                    onPressed: _isInviting
                        ? null
                        : () => _handleInvite(context, ref, list, tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isInviting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(tr.inviteAction),
                  ),
                ],
              ),
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
                  removeTooltip: tr.removeCollaborator,
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

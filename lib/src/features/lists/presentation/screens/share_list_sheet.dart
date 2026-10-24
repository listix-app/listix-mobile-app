import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../collaboration/data/repositories/api_collaboration_repository.dart';
import '../../../collaboration/presentation/widgets/realtime_presence_badge.dart';
import '../../domain/entities/shopping_list.dart';
import '../controllers/lists_controller.dart';
import '../services/share_service.dart';
import '../widgets/collaborator_tile.dart';

class ShareListSheet extends ConsumerStatefulWidget {
  final String listId;
  final ScrollController? scrollController;

  const ShareListSheet({
    super.key,
    required this.listId,
    this.scrollController,
  });

  static Future<void> show(BuildContext context, String listId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: false,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.45, 0.82, 0.95],
        expand: false,
        builder: (sheetContext, scrollController) =>
            ShareListSheet(listId: listId, scrollController: scrollController),
      ),
    );
  }

  @override
  ConsumerState<ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends ConsumerState<ShareListSheet> {
  String? _inviteUrl;
  bool _isLoadingLink = false;
  bool _isSharing = false;
  String? _linkError;

  Future<String> _getOrGenerateInviteLink(
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final authSession = ref.read(authSessionServiceProvider);
    await authSession.ensureInitialized();
    if (authSession.isReady) {
      // coverage:ignore-start
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.put(
          '/lists/${list.id}',
          body: {
            'name': list.name,
            'isStarred': list.isStarred,
            'position': list.position < 0 ? 0 : list.position,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
      } catch (_) {}
      // coverage:ignore-end
      final apiCollab = ref.read(apiCollaborationRepositoryProvider);
      return await apiCollab.createInviteLink(listId: list.id);
    }
    throw StateError('El servicio de API no está disponible.');
  }

  Future<String?> _obtainInviteLink(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    // coverage:ignore-start
    if (_inviteUrl != null && _inviteUrl!.isNotEmpty) {
      return _inviteUrl;
    }
    // coverage:ignore-end
    setState(() {
      _isLoadingLink = true;
      _linkError = null;
    });
    try {
      await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
      final inviteLink = await _getOrGenerateInviteLink(ref, list);
      if (mounted) {
        setState(() {
          _inviteUrl = inviteLink;
          _isLoadingLink = false;
        });
      }
      return inviteLink;
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingLink = false;
          _linkError = error.toString();
        });
      }
      rethrow;
    }
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
    setState(() => _isSharing = true);
    // coverage:ignore-start
    try {
      final inviteLink = await _obtainInviteLink(context, ref, list);
      final text = ShareService.formatListForSharing(
        list: list,
        createdWithText: tr.sharedWithListix,
        inviteLinkText: tr.shareInviteLinkPrompt(inviteLink ?? ''),
        pendingSectionTitle: tr.sharePendingSection,
        completedSectionTitle: tr.shareCompletedSection,
        emptyListText: tr.shareEmptyListNotice,
      );
      await ref
          .read(shareServiceProvider)
          .shareWithSystem(
            text: text,
            subject: tr.shareSubject(list.name),
            sharePositionOrigin: sharePositionOrigin,
          );
    } catch (error) {
      // coverage:ignore-end
      if (context.mounted) _showShareError(context, error);
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  // coverage:ignore-start
  Future<void> _copyInviteLink(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final tr = ref.read(stringsProvider);
    try {
      final link = await _obtainInviteLink(context, ref, list);
      if (link != null && link.isNotEmpty) {
        await ref.read(shareServiceProvider).copyToClipboard(link);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(tr.linkCopied),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
        }
      }
    } catch (error) {
      if (context.mounted) _showShareError(context, error);
    }
  }
  // coverage:ignore-end

  Future<void> _copyListAsText(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final tr = ref.read(stringsProvider);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
      pendingSectionTitle: tr.sharePendingSection,
      completedSectionTitle: tr.shareCompletedSection,
      emptyListText: tr.shareEmptyListNotice,
    );
    await ref.read(shareServiceProvider).copyToClipboard(text);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(tr.listTextCopied),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _shareListAsText(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final tr = ref.read(stringsProvider);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
      pendingSectionTitle: tr.sharePendingSection,
      completedSectionTitle: tr.shareCompletedSection,
      emptyListText: tr.shareEmptyListNotice,
    );
    try {
      await ref
          .read(shareServiceProvider)
          .shareWithSystem(
            text: text,
            subject: tr.shareSubject(list.name),
            sharePositionOrigin: sharePositionOrigin,
          );
    } catch (_) {}
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

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: widget.scrollController == null
          ? BoxConstraints(maxHeight: mediaQuery.size.height * 0.90)
          : null,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 16 + bottomInset,
          ),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (list.canSyncAndShare) ...[
                      const SizedBox(width: 8),
                      const RealtimePresenceBadge(),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('close_share_sheet_button'),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: tr.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr.inviteColleagueSubtitle,
                  style: TextStyle(fontSize: 13, color: textMutedColor),
                ),
                const SizedBox(height: 14),

                _PlainTextShareCard(
                  onCopyText: () => _copyListAsText(context, ref, list),
                  onShareText: () => _shareListAsText(context, ref, list),
                  title: tr.shareAsText,
                  subtitle: tr.shareTextSubtitle,
                  copyButtonLabel: tr.copyListAsText,
                  shareButtonLabel: tr.shareAsText,
                  cardBg: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderColor: handleColor,
                  textTitleColor: textTitleColor,
                  textMutedColor: textMutedColor,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: Divider(color: handleColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        tr.realtimeCollaboration,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textMutedColor,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: handleColor)),
                  ],
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
                        : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight),
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
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.35,
                      ),
                      inactiveThumbColor: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF94A3B8),
                      inactiveTrackColor: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFE2E8F0),
                      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
                        states,
                      ) {
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
                    _ShareInviteUrlCard(
                      inviteUrl: _inviteUrl,
                      isLoading: _isLoadingLink,
                      errorMessage: _linkError,
                      isSharing: _isSharing,
                      // coverage:ignore-start
                      onRetry: () => _obtainInviteLink(context, ref, list),
                      onCopy: () => _copyInviteLink(context, ref, list),
                      // coverage:ignore-end
                      onShare: () => _shareInviteLink(context, ref, list),
                      shareButtonLabel: tr.copyInviteLink.contains('Compartir')
                          ? 'Compartir enlace'
                          : 'Share link',
                      copyButtonLabel: tr.linkCopied.contains('copiado')
                          ? 'Copiar enlace'
                          : 'Copy link',
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
        ),
      ),
    );
  }
}

class _ShareInviteUrlCard extends StatelessWidget {
  final String? inviteUrl;
  final bool isLoading;
  final String? errorMessage;
  final bool isSharing;
  final VoidCallback onRetry;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final String shareButtonLabel;
  final String copyButtonLabel;

  const _ShareInviteUrlCard({
    required this.inviteUrl,
    required this.isLoading,
    required this.errorMessage,
    required this.isSharing,
    required this.onRetry,
    required this.onCopy,
    required this.onShare,
    required this.shareButtonLabel,
    required this.copyButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textMutedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enlace para compartir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textTitleColor,
                  ),
                ),
              ),
              // coverage:ignore-start
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              // coverage:ignore-end
            ],
          ),
          const SizedBox(height: 10),
          // coverage:ignore-start
          if (isLoading && inviteUrl == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                'Generando enlace de invitación...',
                style: TextStyle(fontSize: 12, color: textMutedColor),
              ),
            )
          else if (errorMessage != null && inviteUrl == null) ...[
            Text(
              'No se pudo generar el enlace: $errorMessage',
              style: const TextStyle(fontSize: 12, color: AppColors.delete),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
          ] else if (inviteUrl != null) ...[
            // coverage:ignore-end
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: SelectableText(
                inviteUrl!,
                key: const Key('share_invite_url_text'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('copy_invite_link_button'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        copyButtonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    onPressed: onCopy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('share_invite_link_button'),
                    icon: isSharing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shareButtonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    onPressed: isSharing ? null : onShare,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Comparte este enlace para que otros puedan ver y editar la lista en tiempo real.',
              style: TextStyle(fontSize: 12, color: textMutedColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('copy_invite_link_button'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        copyButtonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    onPressed: onCopy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('share_invite_link_button'),
                    icon: isSharing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shareButtonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    onPressed: isSharing ? null : onShare,
                  ),
                ),
              ],
            ),
          ],
        ],
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                  ),
                  onPressed: onEnableCollaboration,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr.enableCollaboration,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr.activateAndShare,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

class _PlainTextShareCard extends StatelessWidget {
  final VoidCallback onCopyText;
  final VoidCallback onShareText;
  final String title;
  final String subtitle;
  final String copyButtonLabel;
  final String shareButtonLabel;
  final Color cardBg;
  final Color borderColor;
  final Color textTitleColor;
  final Color textMutedColor;

  const _PlainTextShareCard({
    required this.onCopyText,
    required this.onShareText,
    required this.title,
    required this.subtitle,
    required this.copyButtonLabel,
    required this.shareButtonLabel,
    required this.cardBg,
    required this.borderColor,
    required this.textTitleColor,
    required this.textMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.text_snippet_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textTitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: textMutedColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('copy_list_text_button'),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      copyButtonLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                  ),
                  onPressed: onCopyText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('share_list_text_button'),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      shareButtonLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                  ),
                  onPressed: onShareText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

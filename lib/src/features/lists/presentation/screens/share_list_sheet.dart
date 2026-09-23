import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/shopping_list.dart';
import '../controllers/lists_controller.dart';
import '../widgets/collaborator_tile.dart';

class ShareListSheet extends ConsumerStatefulWidget {
  final String listId;

  const ShareListSheet({super.key, required this.listId});

  static Future<void> show(BuildContext context, String listId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ShareListSheet(listId: listId),
    );
  }

  @override
  ConsumerState<ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends ConsumerState<ShareListSheet> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _invite() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final tr = ref.read(stringsProvider);
    ref
        .read(listsControllerProvider.notifier)
        .addCollaborator(widget.listId, email);

    _emailController.clear();
    FocusScope.of(context).unfocus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.inviteSent(email)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyLink(ShoppingList list, String copiedMessage) {
    Clipboard.setData(
      ClipboardData(text: 'https://listix.app/join/${list.id}'),
    );
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(copiedMessage),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(shoppingListProvider(widget.listId));
    final tr = ref.watch(stringsProvider);

    if (list == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(tr.listNotFound),
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tr.shareHeading} "${list.name}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tr.shareListSubheading,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Quick Copy Link button
            InkWell(
              onTap: () => _copyLink(list, tr.linkCopied),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr.copyInviteLink,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.copy,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            Text(
              tr.inviteByEmail,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (_) => _invite(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: tr.emailHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr.enterEmailError;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return tr.invalidEmailError;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _invite,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(tr.inviteAction),
                  ),
                ],
              ),
            ),

            // Collaborators section
            if (list.collaborators.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '${tr.collaboratorsHeading} (${list.collaborators.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...list.collaborators.map(
                (collab) => CollaboratorTile(
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
            ] else ...[
              const SizedBox(height: 20),
              Text(
                tr.noCollaboratorsYet,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

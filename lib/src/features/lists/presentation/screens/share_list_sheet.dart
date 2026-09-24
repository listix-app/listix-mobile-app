import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/shopping_list.dart';
import '../controllers/lists_controller.dart';
import '../services/share_service.dart';

class ShareListSheet extends ConsumerWidget {
  final String listId;

  const ShareListSheet({super.key, required this.listId});

  static Future<void> show(BuildContext context, String listId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareListSheet(listId: listId),
    );
  }

  Future<void> _shareSystem(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final tr = ref.read(stringsProvider);
    await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
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

  Future<void> _shareWhatsApp(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final tr = ref.read(stringsProvider);
    await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
    );
    final shareService = ref.read(shareServiceProvider);
    await shareService.shareToWhatsApp(text);
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _shareGmail(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final tr = ref.read(stringsProvider);
    await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
    final subject = tr.shareSubject(list.name);
    final body = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
    );
    final shareService = ref.read(shareServiceProvider);
    await shareService.shareToGmail(subject: subject, body: body);
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _copyList(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final tr = ref.read(stringsProvider);
    await ref.read(listsControllerProvider.notifier).syncListOnShare(list.id);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
    );
    final shareService = ref.read(shareServiceProvider);
    await shareService.copyToClipboard(text);
    if (context.mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.listCopied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingListProvider(listId));
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tr.shareListSubheading,
              style: TextStyle(fontSize: 13, color: textMutedColor),
            ),
            const SizedBox(height: 20),

            _ShareOptionTile(
              key: const Key('share_system_tile'),
              icon: Icons.share_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBackgroundColor: const Color(
                0xFF0284C7,
              ).withValues(alpha: 0.14),
              title: tr.shareSystem,
              subtitle: tr.shareSystemDesc,
              onTap: () => _shareSystem(context, ref, list),
            ),

            const SizedBox(height: 12),

            _ShareOptionTile(
              key: const Key('share_whatsapp_tile'),
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF25D366),
              iconBackgroundColor: const Color(
                0xFF25D366,
              ).withValues(alpha: 0.14),
              title: tr.shareWhatsApp,
              subtitle: tr.shareWhatsAppDesc,
              onTap: () => _shareWhatsApp(context, ref, list),
            ),

            const SizedBox(height: 12),

            _ShareOptionTile(
              key: const Key('share_gmail_tile'),
              icon: Icons.email_rounded,
              iconColor: const Color(0xFFEA4335),
              iconBackgroundColor: const Color(
                0xFFEA4335,
              ).withValues(alpha: 0.14),
              title: tr.shareGmail,
              subtitle: tr.shareGmailDesc,
              onTap: () => _shareGmail(context, ref, list),
            ),

            const SizedBox(height: 12),

            _ShareOptionTile(
              key: const Key('share_copy_tile'),
              icon: Icons.copy_rounded,
              iconColor: AppColors.primary,
              iconBackgroundColor: AppColors.primaryLight,
              title: tr.copyListText,
              subtitle: tr.copyListTextDesc,
              onTap: () => _copyList(context, ref, list),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_bolt_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr.offlineNoticeDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMutedColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
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
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textMutedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final tileBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
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
                        color: textTitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

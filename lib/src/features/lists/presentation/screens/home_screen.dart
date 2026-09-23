import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/listix_logo.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../controllers/lists_controller.dart';
import '../widgets/list_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsControllerProvider);
    final tr = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const ListixLogo(size: 28, showWordmark: true, fontSize: 22),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: tr.settings,
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.checklist_rounded,
              title: tr.emptyListsTitle,
              message: tr.emptyListsMessage,
              actionLabel: tr.createFirstList,
              onAction: () => context.push('/lists/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(listsControllerProvider.notifier).manualSync();
            },
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
                  child: Row(
                    children: [
                      Text(
                        tr.myLists,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lists.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ...lists.map((list) {
                  return Dismissible(
                    key: Key(list.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(tr.deleteListTitle),
                              content: Text(tr.deleteListMessage(list.name)),
                              actions: [
                                TextButton(
                                  onPressed: () => ctx.pop(false),
                                  child: Text(tr.cancel),
                                ),
                                FilledButton(
                                  onPressed: () => ctx.pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.delete,
                                  ),
                                  child: Text(tr.delete),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) {
                      ref
                          .read(listsControllerProvider.notifier)
                          .deleteList(list.id);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.deleteBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.delete,
                        size: 24,
                      ),
                    ),
                    child: ListCard(
                      list: list,
                      strings: tr,
                      onTap: () => context.push('/list/${list.id}'),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(tr.errorPrefix(err.toString())),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/lists/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          tr.newList,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

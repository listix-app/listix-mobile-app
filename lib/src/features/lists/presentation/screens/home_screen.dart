import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/listix_logo.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../sync/presentation/widgets/sync_status_badge.dart';
import '../controllers/lists_controller.dart';
import '../widgets/list_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsControllerProvider);
    final tr = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const ListixLogo(size: 28, showWordmark: true, fontSize: 22),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            tooltip: tr.aboutApp,
            onPressed: () => context.push('/about'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SyncStatusBadge(),
          ),
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
                // Section header
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
                  child: Row(
                    children: [
                      Text(
                        tr.myLists,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lists.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List items
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
            child: Text('Error: $err'),
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

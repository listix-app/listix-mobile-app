// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../ads/data/interstitial_ad_service.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../collaboration/presentation/controllers/collaboration_controller.dart';
import '../../../collaboration/presentation/widgets/realtime_presence_badge.dart';
import '../../domain/entities/shopping_list.dart';
import '../services/share_service.dart';
import '../controllers/lists_controller.dart';
import '../widgets/quick_add_input.dart';
import '../widgets/todo_item_tile.dart';
import 'share_list_sheet.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  bool _isCompletedExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final current = ref.read(shoppingListProvider(widget.listId));
        if (current != null && current.canSyncAndShare) {
          ref
              .read(collaborationControllerProvider.notifier)
              .joinListRoom(widget.listId);
        }
      }
    });
  }

  @override
  void deactivate() {
    try {
      ref
          .read(collaborationControllerProvider.notifier)
          .leaveListRoom(widget.listId);
    } catch (_) {}
    super.deactivate();
  }

  Future<void> _handleDeleteItem(String listId, String itemId) async {
    final tr = ref.read(stringsProvider);
    final deleted = await ref
        .read(listsControllerProvider.notifier)
        .deleteItemWithUndo(listId, itemId);
    if (deleted != null && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.itemDeleted(deleted.title)),
          action: SnackBarAction(
            label: tr.undo,
            textColor: AppColors.primaryLight,
            onPressed: () {
              ref.read(listsControllerProvider.notifier).restoreItem(deleted);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _copyListText(ShoppingList list) async {
    if (list.items.isEmpty) return;

    final tr = ref.read(stringsProvider);
    final text = ShareService.formatListForSharing(
      list: list,
      createdWithText: tr.sharedWithListix,
      pendingSectionTitle: tr.sharePendingSection,
      completedSectionTitle: tr.shareCompletedSection,
      emptyListText: tr.shareEmptyListNotice,
    );
    await ref.read(shareServiceProvider).copyToClipboard(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(tr.listCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ShoppingList?>(shoppingListProvider(widget.listId), (
      prev,
      next,
    ) {
      final prevCan = prev?.canSyncAndShare ?? false;
      final nextCan = next?.canSyncAndShare ?? false;
      if (!prevCan && nextCan) {
        ref
            .read(collaborationControllerProvider.notifier)
            .joinListRoom(widget.listId);
      } else if (prevCan && !nextCan) {
        ref
            .read(collaborationControllerProvider.notifier)
            .leaveListRoom(widget.listId);
      }
    });

    final list = ref.watch(shoppingListProvider(widget.listId));
    final tr = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (list == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr.listNotFound,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(tr.back),
              ),
            ],
          ),
        ),
      );
    }

    final pendingItems = list.items.where((i) => !i.isCompleted).toList();
    final completedItems = list.items.where((i) => i.isCompleted).toList();
    final progress = list.totalCount == 0
        ? 0.0
        : list.completedCount / list.totalCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: tr.back,
          onPressed: () {
            ref.read(interstitialAdServiceProvider).showInterstitialIfAllowed();
            context.pop();
          },
        ),
        title: Text(
          list.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy_rounded, size: 20),
            tooltip: tr.copyListText,
            onPressed: list.items.isEmpty ? null : () => _copyListText(list),
          ),
          if (list.canSyncAndShare)
            Center(
              child: RealtimePresenceBadge(
                onTap: () => ShareListSheet.show(context, list.id),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: tr.rename,
            onPressed: () => context.push('/list/${list.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined, size: 21),
            tooltip: tr.shareList,
            onPressed: () => ShareListSheet.show(context, list.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      list.items.isEmpty
                          ? tr.noItemsYet
                          : tr.pendingCountText(
                              list.pendingCount,
                              list.totalCount,
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    if (list.totalCount > 0)
                      Text(
                        tr.percentCompleted((progress * 100).toInt()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (list.totalCount > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
                if (list.collaborators.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${tr.collaborators}:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 22,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: list.collaborators.map((c) {
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.primaryDark,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: list.items.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.add_task_rounded,
                    title: tr.emptyItemsTitle,
                    message: tr.emptyItemsMessage,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(listsControllerProvider.notifier)
                          .manualSync();
                    },
                    color: AppColors.primary,
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: pendingItems.length,
                      onReorderItem: (oldIndex, newIndex) {
                        ref
                            .read(listsControllerProvider.notifier)
                            .reorderItems(list.id, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = pendingItems[index];
                        return TodoItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          onToggle: () {
                            ref
                                .read(listsControllerProvider.notifier)
                                .toggleItem(list.id, item.id);
                          },
                          onDelete: () => _handleDeleteItem(list.id, item.id),
                        );
                      },
                      footer: completedItems.isEmpty
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isCompletedExpanded =
                                          !_isCompletedExpanded;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isCompletedExpanded
                                              ? Icons.expand_more
                                              : Icons.chevron_right,
                                          size: 18,
                                          color: isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tr.completedGroup(
                                            completedItems.length,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textMutedDark
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isCompletedExpanded)
                                  ...completedItems.map(
                                    (item) => TodoItemTile(
                                      key: ValueKey(item.id),
                                      item: item,
                                      onToggle: () {
                                        ref
                                            .read(
                                              listsControllerProvider.notifier,
                                            )
                                            .toggleItem(list.id, item.id);
                                      },
                                      onDelete: () =>
                                          _handleDeleteItem(list.id, item.id),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
          ),

          QuickAddInput(
            autoFocus: false,
            hintText: tr.quickAddHint,
            tooltip: tr.quickAddTooltip,
            onAdd: (title) {
              ref
                  .read(listsControllerProvider.notifier)
                  .addItem(list.id, title);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(isDetail: true),
    );
  }
}

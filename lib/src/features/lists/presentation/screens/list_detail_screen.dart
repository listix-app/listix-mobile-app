// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../ads/data/interstitial_ad_service.dart';
import '../../../ads/presentation/controllers/banner_ad_controller.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../collaboration/presentation/controllers/collaboration_controller.dart';
import '../../../collaboration/presentation/widgets/realtime_presence_badge.dart';
import '../../../sync/data/api_sync_service.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/todo_item.dart';
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
  bool _isSearching = false;
  String _itemSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          ref.read(apiSyncServiceProvider).subscribeToList(widget.listId);
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
      ref.read(apiSyncServiceProvider).unsubscribeFromList(widget.listId);
    } catch (_) {}
    super.deactivate();
  }

  Future<void> _handleDeleteItem(String listId, String itemId) async {
    final tr = ref.read(stringsProvider);
    final deleted = await ref
        .read(listsControllerProvider.notifier)
        .deleteItemWithUndo(listId, itemId);
    if (deleted != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr.itemDeleted(deleted.title)),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: tr.undo,
            textColor: AppColors.primaryLight,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              ref.read(listsControllerProvider.notifier).restoreItem(deleted);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleDeleteCompletedItems(String listId, int count) async {
    final tr = ref.read(stringsProvider);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr.deleteCompletedItemsTitle),
            content: Text(tr.deleteCompletedItemsMessage(count)),
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

    if (!confirmed || !mounted) return;

    final deleted = await ref
        .read(listsControllerProvider.notifier)
        .deleteCompletedItemsWithUndo(listId);
    if (deleted.isNotEmpty && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr.completedItemsDeleted(deleted.length)),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: tr.undo,
            textColor: AppColors.primaryLight,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              ref
                  .read(listsControllerProvider.notifier)
                  .restoreItems(listId, deleted);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showEditItemDialog(BuildContext context, TodoItem item) async {
    final tr = ref.read(stringsProvider);
    final controller = TextEditingController(text: item.title);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.editItemTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const Key('edit_item_title_input'),
            controller: controller,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: tr.itemTitleLabel,
              hintText: tr.itemTitleHint,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr.itemTitleValidation;
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                ref
                    .read(listsControllerProvider.notifier)
                    .updateItem(widget.listId, item.id, controller.text);
                ctx.pop();
              }
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(tr.cancel)),
          FilledButton(
            key: const Key('save_edit_item_button'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(listsControllerProvider.notifier)
                    .updateItem(widget.listId, item.id, controller.text);
                ctx.pop();
              }
            },
            child: Text(tr.saveChanges),
          ),
        ],
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
        ref.read(apiSyncServiceProvider).subscribeToList(widget.listId);
      } else if (prevCan && !nextCan) {
        ref
            .read(collaborationControllerProvider.notifier)
            .leaveListRoom(widget.listId);
        ref.read(apiSyncServiceProvider).unsubscribeFromList(widget.listId);
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

    final query = _itemSearchQuery.trim().toLowerCase();
    final pendingItems = list.items.where((i) => !i.isCompleted).toList();
    final completedItems = list.items.where((i) => i.isCompleted).toList();
    final filteredPending = query.isEmpty
        ? pendingItems
        : pendingItems
              .where((i) => i.title.toLowerCase().contains(query))
              .toList();
    final filteredCompleted = query.isEmpty
        ? completedItems
        : completedItems
              .where((i) => i.title.toLowerCase().contains(query))
              .toList();

    final progress = list.totalCount == 0
        ? 0.0
        : list.completedCount / list.totalCount;
    final listColor = list.color != null
        ? Color(list.color!)
        : AppColors.primary;

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
        title: _isSearching
            ? TextField(
                key: const Key('item_search_input'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: tr.searchItemsHint,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                onChanged: (val) {
                  setState(() {
                    _itemSearchQuery = val;
                  });
                },
              )
            : Text(
                list.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          IconButton(
            key: const Key('item_search_toggle_button'),
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
            ),
            tooltip: _isSearching ? tr.closeSearch : tr.searchItems,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _itemSearchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          if (!_isSearching) ...[
            if (completedItems.isNotEmpty)
              IconButton(
                key: const Key('delete_completed_items_app_bar_button'),
                icon: const Icon(Icons.delete_sweep_outlined, size: 21),
                tooltip: tr.deleteCompletedItems,
                onPressed: () =>
                    _handleDeleteCompletedItems(list.id, completedItems.length),
              ),
            if (list.canSyncAndShare)
              Center(
                child: RealtimePresenceBadge(
                  onTap: () => ShareListSheet.show(context, list.id),
                ),
              ),
            if (list.isOwner)
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
          ],
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
                      valueColor: AlwaysStoppedAnimation<Color>(listColor),
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
                : (query.isNotEmpty &&
                      filteredPending.isEmpty &&
                      filteredCompleted.isEmpty)
                ? EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: tr.noSearchResults,
                    message: tr.searchItemsHint,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(listsControllerProvider.notifier)
                          .manualSync();
                    },
                    color: listColor,
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: filteredPending.length,
                      buildDefaultDragHandles: false,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      onReorderItem: (oldIndex, newIndex) {
                        if (query.isNotEmpty) return;
                        HapticFeedback.selectionClick();
                        ref
                            .read(listsControllerProvider.notifier)
                            .reorderItems(list.id, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = filteredPending[index];
                        return TodoItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          reorderIndex: query.isEmpty ? index : null,
                          activeColor: listColor,
                          onToggle: () {
                            ref
                                .read(listsControllerProvider.notifier)
                                .toggleItem(list.id, item.id);
                          },
                          onDelete: () => _handleDeleteItem(list.id, item.id),
                          onEdit: () => _showEditItemDialog(context, item),
                        );
                      },
                      footer: filteredCompleted.isEmpty
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
                                            filteredCompleted.length,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textMutedDark
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          key: const Key(
                                            'delete_completed_items_button',
                                          ),
                                          onPressed: () =>
                                              _handleDeleteCompletedItems(
                                                list.id,
                                                filteredCompleted.length,
                                              ),
                                          icon: const Icon(
                                            Icons.delete_sweep_outlined,
                                            size: 16,
                                            color: AppColors.delete,
                                          ),
                                          label: Text(
                                            tr.deleteCompletedItems,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.delete,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isCompletedExpanded)
                                  ...filteredCompleted.map(
                                    (item) => TodoItemTile(
                                      key: ValueKey(item.id),
                                      item: item,
                                      activeColor: listColor,
                                      onToggle: () {
                                        ref
                                            .read(
                                              listsControllerProvider.notifier,
                                            )
                                            .toggleItem(list.id, item.id);
                                      },
                                      onDelete: () =>
                                          _handleDeleteItem(list.id, item.id),
                                      onEdit: () =>
                                          _showEditItemDialog(context, item),
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
      bottomNavigationBar: switch (ref.watch(detailBannerAdProvider)) {
        BannerAdStatus.loaded ||
        BannerAdStatus.loading => const BannerAdWidget(isDetail: true),
        BannerAdStatus.disabled || BannerAdStatus.failed => null,
      },
    );
  }
}

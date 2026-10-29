// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../ads/data/interstitial_ad_service.dart';
import '../../../ads/presentation/controllers/banner_ad_controller.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../collaboration/presentation/controllers/collaboration_controller.dart';
import '../../../collaboration/presentation/widgets/realtime_presence_badge.dart';
import '../../../sync/data/api_sync_service.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/todo_item.dart';
import '../controllers/lists_controller.dart';
import '../widgets/item_editor_sheet.dart';
import '../widgets/list_type_presentation.dart';
import '../widgets/options_tools.dart';
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

  void _handleBackNavigation(BuildContext context) {
    try {
      ref.read(interstitialAdServiceProvider).showInterstitialIfAllowed();
    } catch (_) {}
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _showItemActionsSheet(
    BuildContext context,
    TodoItem item,
  ) async {
    final tr = ref.read(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOptions = _listType == ListType.options;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  (isOptions ? item.isChosen : item.isCompleted)
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  isOptions
                      ? (item.isChosen ? tr.unmarkChosen : tr.markChosen)
                      : item.isCompleted
                      ? 'Marcar como pendiente'
                      : 'Marcar como completado',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  ctx.pop();
                  final notifier = ref.read(listsControllerProvider.notifier);
                  if (isOptions) {
                    notifier.toggleChosenItem(widget.listId, item.id);
                  } else {
                    notifier.toggleItem(widget.listId, item.id);
                  }
                },
              ),
              if (!item.isCompleted)
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(
                    tr.rename,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    ctx.pop();
                    _editItem(item);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.delete,
                ),
                title: Text(
                  tr.delete,
                  style: const TextStyle(
                    color: AppColors.delete,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  ctx.pop();
                  _handleDeleteItem(widget.listId, item.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListType get _listType =>
      ref.read(shoppingListProvider(widget.listId))?.type ?? ListType.custom;

  List<String> get _attributeNames =>
      ref.read(shoppingListProvider(widget.listId))?.attributeNames ?? const [];

  Future<void> _editItem(TodoItem item) async {
    final updated = await showItemEditorSheet(
      context,
      type: _listType,
      strings: ref.read(stringsProvider),
      draft: item,
      attributeNames: _attributeNames,
    );
    if (updated == null || !mounted) return;
    await ref.read(listsControllerProvider.notifier).updateItemDetails(updated);
  }

  Future<void> _addItemWithDetails(String title) async {
    final created = await showItemEditorSheet(
      context,
      type: _listType,
      strings: ref.read(stringsProvider),
      draft: TodoItem(
        id: '',
        listId: widget.listId,
        title: title,
        createdAt: DateTime.now(),
      ),
      attributeNames: _attributeNames,
      isNew: true,
    );
    if (created == null || !mounted) return;
    await ref
        .read(listsControllerProvider.notifier)
        .addItem(widget.listId, created.title, details: created);
  }

  Widget _buildItemTile(
    ShoppingList list,
    TodoItem item,
    Color listColor, {
    int? reorderIndex,
  }) {
    final notifier = ref.read(listsControllerProvider.notifier);
    return TodoItemTile(
      key: ValueKey(item.id),
      item: item,
      reorderIndex: reorderIndex,
      listType: list.type,
      attributeNames: list.attributeNames,
      strings: ref.read(stringsProvider),
      activeColor: listColor,
      onToggle: () => list.type == ListType.options
          ? notifier.toggleChosenItem(list.id, item.id)
          : notifier.toggleItem(list.id, item.id),
      onDelete: () => _handleDeleteItem(list.id, item.id),
      onEdit: () => _editItem(item),
      onLongPress: () => _showItemActionsSheet(context, item),
      onToggleFavorite: () => notifier.updateItemDetails(
        item.copyWith(isFavorite: !item.isFavorite),
      ),
      onOpenLink: () =>
          ref.read(urlLauncherServiceProvider).openUrl(item.url ?? ''),
    );
  }

  List<Widget> _buildCategoryGroups(
    ShoppingList list,
    List<TodoItem> pending,
    Color listColor,
    AppStrings tr,
    bool isDark,
  ) {
    final order = MarketCatalog.categories;
    String keyOf(TodoItem item) => order.contains(item.category)
        ? item.category!
        : MarketCatalog.uncategorized;
    final groups = <String, List<TodoItem>>{};
    for (final item in pending) {
      groups.putIfAbsent(keyOf(item), () => []).add(item);
    }
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return [
      for (final key in sortedKeys) ...[
        Padding(
          key: Key('category_header_$key'),
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(
            tr.categoryName(key).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ),
        for (final item in groups[key]!) _buildItemTile(list, item, listColor),
      ],
    ];
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

    final Widget? completedFooter = filteredCompleted.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    _isCompletedExpanded = !_isCompletedExpanded;
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
                        tr.completedGroup(filteredCompleted.length),
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
                        key: const Key('delete_completed_items_button'),
                        onPressed: () => _handleDeleteCompletedItems(
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
                  (item) => _buildItemTile(list, item, listColor),
                ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: tr.back,
          onPressed: () => _handleBackNavigation(context),
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
                          : list.type == ListType.options
                          ? tr.optionsCount(list.totalCount)
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
                    if (list.totalCount > 0 && list.type.tracksCompletion)
                      Text(
                        list.type == ListType.shopping && list.totalPrice > 0
                            ? tr.shoppingTotal(
                                list.totalPrice.toStringAsFixed(2),
                              )
                            : tr.percentCompleted((progress * 100).toInt()),
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
                if (list.totalCount > 0 && list.type.tracksCompletion) ...[
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
                if (list.type == ListType.options) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    children: [
                      TextButton.icon(
                        key: const Key('compare_options_button'),
                        onPressed: () => showCompareSheet(context, list.id),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: Text(tr.compareOptions),
                      ),
                      TextButton.icon(
                        key: const Key('manage_attributes_button'),
                        onPressed: () => showAttributesDialog(context, list.id),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(tr.manageAttributes),
                      ),
                    ],
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
                    child: list.type.isGroupedByCategory
                        ? ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            children: [
                              ..._buildCategoryGroups(
                                list,
                                filteredPending,
                                listColor,
                                tr,
                                isDark,
                              ),
                              ?completedFooter,
                            ],
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: filteredPending.length,
                            buildDefaultDragHandles: false,
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                elevation: 4,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.25,
                                ),
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
                              return _buildItemTile(
                                list,
                                filteredPending[index],
                                listColor,
                                reorderIndex: query.isEmpty ? index : null,
                              );
                            },
                            footer: completedFooter,
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
            onAddWithDetails: _addItemWithDetails,
            detailsTooltip: tr.addWithDetails,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/listix_logo.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../collaboration/presentation/widgets/join_list_dialog.dart';
import '../../domain/entities/shopping_list.dart';
import '../controllers/list_layout_controller.dart';
import '../controllers/lists_controller.dart';
import '../widgets/list_card.dart';
import '../widgets/list_grid_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteList(
    BuildContext context,
    ShoppingList list,
    AppStrings tr,
  ) async {
    final title = list.isOwner ? tr.deleteListTitle : tr.leaveListTitle;
    final message = list.isOwner
        ? tr.deleteListMessage(list.name)
        : tr.leaveListMessage(list.name);
    final actionLabel = list.isOwner ? tr.delete : tr.leave;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
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
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      final deleted = await ref
          .read(listsControllerProvider.notifier)
          .deleteListWithUndo(list.id);
      if (deleted != null && context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(tr.listDeleted(deleted.name)),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
            dismissDirection: DismissDirection.horizontal,
            action: SnackBarAction(
              label: tr.undo,
              textColor: AppColors.primaryLight,
              onPressed: () {
                messenger.hideCurrentSnackBar();
                ref.read(listsControllerProvider.notifier).restoreList(deleted);
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleArchiveList(
    BuildContext context,
    ShoppingList list,
    AppStrings tr,
  ) async {
    await ref.read(listsControllerProvider.notifier).archiveList(list.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(tr.listArchived),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: tr.undo,
          textColor: AppColors.primaryLight,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            ref.read(listsControllerProvider.notifier).unarchiveList(list.id);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleUnarchiveList(
    BuildContext context,
    ShoppingList list,
    AppStrings tr,
  ) async {
    await ref.read(listsControllerProvider.notifier).unarchiveList(list.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(tr.listUnarchived),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: tr.undo,
          textColor: AppColors.primaryLight,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            ref.read(listsControllerProvider.notifier).archiveList(list.id);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(listsControllerProvider);
    final tr = ref.watch(stringsProvider);
    final layoutMode = ref.watch(listLayoutControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _isSearching
            ? TextField(
                key: const Key('list_search_input'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: tr.searchListsHint,
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
                    _searchQuery = val;
                  });
                },
              )
            : const ListixLogo(size: 28, showWordmark: true, fontSize: 22),
        actions: [
          IconButton(
            key: const Key('list_search_toggle_button'),
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
            tooltip: _isSearching ? tr.closeSearch : tr.searchLists,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              key: const Key('join_list_button'),
              icon: const Icon(Icons.group_add_outlined, size: 22),
              tooltip: tr.joinList,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const JoinListDialog(),
                );
              },
            ),
            IconButton(
              key: const Key('layout_toggle_button'),
              icon: Icon(
                layoutMode == ListLayoutMode.list
                    ? Icons.grid_view_rounded
                    : Icons.view_agenda_outlined,
                size: 22,
              ),
              tooltip: tr.switchLayout,
              onPressed: () {
                ref.read(listLayoutControllerProvider.notifier).toggleLayout();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              tooltip: tr.settings,
              onPressed: () => context.push('/settings'),
            ),
          ],
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

          final activeLists = lists.where((l) => !l.isArchived).toList();
          final archivedLists = lists.where((l) => l.isArchived).toList();
          final currentTabLists = _selectedTab == 0
              ? activeLists
              : archivedLists;

          final query = _searchQuery.trim().toLowerCase();
          final displayedLists = query.isEmpty
              ? currentTabLists
              : currentTabLists
                    .where((l) => l.name.toLowerCase().contains(query))
                    .toList();

          final segmentedTabs = Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                key: const Key('lists_tab_segmented_button'),
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('${tr.activeLists} (${activeLists.length})'),
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(
                      '${tr.archivedLists} (${archivedLists.length})',
                    ),
                    icon: const Icon(Icons.archive_outlined, size: 16),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedTab = newSelection.first;
                  });
                },
              ),
            ),
          );

          final header = Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
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
                    color: isDark ? AppColors.cardDark : AppColors.borderLight,
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
          );

          final topSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [header, segmentedTabs],
          );

          if (query.isNotEmpty && displayedLists.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                topSection,
                const SizedBox(height: 24),
                EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: tr.noSearchResults,
                  message: tr.searchListsHint,
                ),
              ],
            );
          }

          if (_selectedTab == 1 && archivedLists.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                topSection,
                const SizedBox(height: 24),
                EmptyStateWidget(
                  icon: Icons.archive_outlined,
                  title: tr.emptyArchivedTitle,
                  message: tr.emptyArchivedMessage,
                ),
              ],
            );
          }

          if (_selectedTab == 0 && activeLists.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                topSection,
                const SizedBox(height: 24),
                EmptyStateWidget(
                  icon: Icons.checklist_rounded,
                  title: tr.emptyListsTitle,
                  message: tr.emptyListsMessage,
                  actionLabel: tr.createFirstList,
                  onAction: () => context.push('/lists/new'),
                ),
              ],
            );
          }

          if (layoutMode == ListLayoutMode.grid) {
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(listsControllerProvider.notifier).manualSync();
              },
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  topSection,
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: displayedLists.length,
                    itemBuilder: (context, index) {
                      final list = displayedLists[index];
                      return ListGridCard(
                        key: ValueKey('grid_card_${list.id}'),
                        list: list,
                        strings: tr,
                        onTap: () => context.push('/list/${list.id}'),
                        onToggleStar: _selectedTab == 0
                            ? () {
                                ref
                                    .read(listsControllerProvider.notifier)
                                    .toggleStar(list.id);
                              }
                            : null,
                        onArchive: (_selectedTab == 0 && list.isOwner)
                            ? () => _handleArchiveList(context, list, tr)
                            : null,
                        onUnarchive: _selectedTab == 1
                            ? () => _handleUnarchiveList(context, list, tr)
                            : null,
                        onDelete: () => _handleDeleteList(context, list, tr),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(listsControllerProvider.notifier).manualSync();
            },
            color: AppColors.primary,
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: displayedLists.length,
              buildDefaultDragHandles: _selectedTab == 0 && query.isEmpty,
              onReorderItem: (oldIndex, newIndex) {
                if (_selectedTab != 0 || query.isNotEmpty) return;
                ref
                    .read(listsControllerProvider.notifier)
                    .reorderLists(oldIndex, newIndex);
              },
              header: topSection,
              itemBuilder: (context, index) {
                final list = displayedLists[index];
                return Dismissible(
                  key: ValueKey(list.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final title = list.isOwner
                        ? tr.deleteListTitle
                        : tr.leaveListTitle;
                    final message = list.isOwner
                        ? tr.deleteListMessage(list.name)
                        : tr.leaveListMessage(list.name);
                    final actionLabel = list.isOwner ? tr.delete : tr.leave;

                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(title),
                            content: Text(message),
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
                                child: Text(actionLabel),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    final deleted = await ref
                        .read(listsControllerProvider.notifier)
                        .deleteListWithUndo(list.id);
                    if (deleted != null && context.mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(tr.listDeleted(deleted.name)),
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
                                  .restoreList(deleted);
                            },
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
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
                    key: ValueKey('card_${list.id}'),
                    list: list,
                    strings: tr,
                    onTap: () => context.push('/list/${list.id}'),
                    onToggleStar: _selectedTab == 0
                        ? () {
                            ref
                                .read(listsControllerProvider.notifier)
                                .toggleStar(list.id);
                          }
                        : null,
                    onArchive: (_selectedTab == 0 && list.isOwner)
                        ? () => _handleArchiveList(context, list, tr)
                        : null,
                    onUnarchive: _selectedTab == 1
                        ? () => _handleUnarchiveList(context, list, tr)
                        : null,
                  ),
                );
              },
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

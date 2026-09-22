import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/sync_indicator.dart';
import '../../../sync/presentation/widgets/sync_status_badge.dart';
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
  Widget build(BuildContext context) {
    final list = ref.watch(shoppingListProvider(widget.listId));

    if (list == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Lista no encontrada.')),
      );
    }

    final pendingItems = list.items.where((i) => !i.isCompleted).toList();
    final completedItems = list.items.where((i) => i.isCompleted).toList();
    final progress = list.totalCount > 0
        ? (list.completedCount / list.totalCount)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                list.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            SyncIndicator(isSynced: list.isSynced),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Renombrar',
            onPressed: () => context.push('/list/${list.id}/edit'),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.person_add_outlined, size: 21),
                if (list.isShared)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          '${list.collaborators.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Compartir lista',
            onPressed: () => ShareListSheet.show(context, list.id),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0, left: 4.0),
            child: SyncStatusBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-header with pending count & progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      list.items.isEmpty
                          ? 'Sin items aún'
                          : '${list.progressText} pendientes',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    if (list.totalCount > 0)
                      Text(
                        '${(progress * 100).toInt()}% completado',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
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
                      backgroundColor: AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main list content
          Expanded(
            child: list.items.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.add_task_rounded,
                    title: 'Lista vacía',
                    message: 'Escribe tu primer item en la barra inferior y presiona enter.',
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(listsControllerProvider.notifier)
                          .manualSync();
                    },
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      children: [
                        // Pending items
                        ...pendingItems.map(
                          (item) => TodoItemTile(
                            item: item,
                            onToggle: () {
                              ref
                                  .read(listsControllerProvider.notifier)
                                  .toggleItem(list.id, item.id);
                            },
                            onDelete: () {
                              ref
                                  .read(listsControllerProvider.notifier)
                                  .deleteItem(list.id, item.id);
                            },
                          ),
                        ),

                        // Completed items section grouped at the bottom
                        if (completedItems.isNotEmpty) ...[
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
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Completados (${completedItems.length})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isCompletedExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isCompletedExpanded)
                            ...completedItems.map(
                              (item) => TodoItemTile(
                                item: item,
                                onToggle: () {
                                  ref
                                      .read(listsControllerProvider.notifier)
                                      .toggleItem(list.id, item.id);
                                },
                                onDelete: () {
                                  ref
                                      .read(listsControllerProvider.notifier)
                                      .deleteItem(list.id, item.id);
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),

          // Bottom Quick Add Input
          QuickAddInput(
            autoFocus: false,
            onAdd: (title) {
              ref
                  .read(listsControllerProvider.notifier)
                  .addItem(list.id, title);
            },
          ),
        ],
      ),
    );
  }
}

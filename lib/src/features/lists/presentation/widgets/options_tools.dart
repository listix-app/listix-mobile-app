import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_context.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/shopping_list.dart';
import '../controllers/lists_controller.dart';
import 'list_type_presentation.dart';

Future<void> showAttributesDialog(BuildContext context, String listId) {
  return showDialog<void>(
    context: context,
    builder: (_) => AttributesDialog(listId: listId),
  );
}

Future<void> showCompareSheet(BuildContext context, String listId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CompareOptionsSheet(listId: listId),
  );
}

class AttributesDialog extends ConsumerStatefulWidget {
  final String listId;

  const AttributesDialog({super.key, required this.listId});

  @override
  ConsumerState<AttributesDialog> createState() => _AttributesDialogState();
}

class _AttributesDialogState extends ConsumerState<AttributesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(List<String> names) => ref
      .read(listsControllerProvider.notifier)
      .updateListAttributes(widget.listId, names);

  void _add(List<String> current) {
    final name = _controller.text.trim();
    final exists = current.any((n) => n.toLowerCase() == name.toLowerCase());
    if (name.isEmpty || exists) return;
    _controller.clear();
    _update([...current, name]);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final names =
        ref.watch(shoppingListProvider(widget.listId))?.attributeNames ??
        const <String>[];

    return AlertDialog(
      title: Text(tr.manageAttributes),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (names.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(tr.attributesEmpty),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in names)
                      InputChip(
                        key: Key('attribute_chip_$name'),
                        label: Text(name),
                        deleteButtonTooltipMessage: tr.removeAttribute,
                        onDeleted: () => _update([...names]..remove(name)),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('attribute_name_input'),
                    controller: _controller,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(names),
                    decoration: InputDecoration(
                      labelText: tr.attributeNameLabel,
                      hintText: tr.attributeNameHint,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('attribute_add_button'),
                  onPressed: () => _add(names),
                  child: Text(tr.addAttribute),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

class CompareOptionsSheet extends ConsumerWidget {
  final String listId;

  const CompareOptionsSheet({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final list = ref.watch(shoppingListProvider(listId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ListType.options.icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.compareOptions,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: headingColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list == null || list.items.length < 2)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(tr.compareNeedsTwo)),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _CompareTable(list: list, strings: tr),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompareTable extends ConsumerWidget {
  final ShoppingList list;
  final AppStrings strings;

  const _CompareTable({required this.list, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = strings;
    final names = list.attributeNames;
    return DataTable(
      columnSpacing: 20,
      columns: [
        DataColumn(label: Text(tr.optionColumn)),
        for (final name in names) DataColumn(label: Text(name)),
        DataColumn(label: Text(tr.evaluationLabel)),
        const DataColumn(label: SizedBox.shrink()),
      ],
      rows: [
        for (final item in list.items)
          DataRow(
            key: ValueKey('compare_row_${item.id}'),
            selected: item.isChosen,
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.isFavorite)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.star,
                        ),
                      ),
                    Text(item.title),
                  ],
                ),
              ),
              for (final name in names)
                DataCell(Text(item.attributes[name] ?? '—')),
              DataCell(
                Text(
                  item.evaluation == null
                      ? '—'
                      : tr.evaluationName(item.evaluation!),
                ),
              ),
              DataCell(
                IconButton(
                  key: ValueKey('compare_choose_${item.id}'),
                  tooltip: item.isChosen ? tr.unmarkChosen : tr.markChosen,
                  icon: Icon(
                    item.isChosen
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.isChosen ? AppColors.primary : null,
                  ),
                  onPressed: () => ref
                      .read(listsControllerProvider.notifier)
                      .toggleChosenItem(list.id, item.id),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

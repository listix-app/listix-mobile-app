import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_context.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/todo_item.dart';
import 'list_type_presentation.dart';

Future<TodoItem?> showItemEditorSheet(
  BuildContext context, {
  required ListType type,
  required AppStrings strings,
  required TodoItem draft,
  List<String> attributeNames = const [],
  bool isNew = false,
}) {
  return showModalBottomSheet<TodoItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: context.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ItemEditorSheet(
      type: type,
      strings: strings,
      draft: draft,
      attributeNames: attributeNames,
      isNew: isNew,
    ),
  );
}

class ItemEditorSheet extends StatefulWidget {
  final ListType type;
  final AppStrings strings;
  final TodoItem draft;
  final List<String> attributeNames;
  final bool isNew;

  const ItemEditorSheet({
    super.key,
    required this.type,
    required this.strings,
    required this.draft,
    this.attributeNames = const [],
    this.isNew = false,
  });

  @override
  State<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<ItemEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _store;
  late final TextEditingController _url;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final Map<String, TextEditingController> _attributes;
  late final TextEditingController _notes;
  String? _unit;
  String? _category;
  ItemPriority? _priority;
  DateTime? _dueDate;
  bool _isFavorite = false;
  bool _isInProgress = false;
  ItemEvaluation? _evaluation;

  AppStrings get _tr => widget.strings;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _title = TextEditingController(text: d.title);
    _quantity = TextEditingController(text: _formatNumber(d.quantity));
    _price = TextEditingController(text: _formatNumber(d.price));
    _store = TextEditingController(text: d.store ?? '');
    _url = TextEditingController(text: d.url ?? '');
    _description = TextEditingController(text: d.description ?? '');
    _imageUrl = TextEditingController(text: d.imageUrl ?? '');
    _attributes = {
      for (final name in widget.attributeNames)
        name: TextEditingController(text: d.attributes[name] ?? ''),
    };
    _evaluation = d.evaluation;
    _notes = TextEditingController(text: d.notes ?? '');
    _unit = d.unit;
    _category = d.category;
    _priority = d.priority;
    _dueDate = d.dueDate;
    _isFavorite = d.isFavorite;
    _isInProgress = d.isInProgress;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _quantity,
      _price,
      _store,
      _url,
      _description,
      _imageUrl,
      _notes,
      ..._attributes.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _formatNumber(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static double? _parseNumber(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = _parseNumber(value);
    return parsed == null || parsed < 0 ? _tr.numberInvalid : null;
  }

  static bool _isWebLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _isWebLink(value) ? null : _tr.linkInvalid;
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _isWebLink(value) ? null : _tr.imageUrlInvalid;
  }

  Map<String, String> _collectAttributes() {
    final collected = Map<String, String>.from(widget.draft.attributes);
    _attributes.forEach((name, controller) {
      final value = controller.text.trim();
      if (value.isEmpty) {
        collected.remove(name);
      } else {
        collected[name] = value;
      }
    });
    return collected;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final d = widget.draft;
    Navigator.of(context).pop(
      TodoItem(
        id: d.id,
        listId: d.listId,
        title: _title.text.trim(),
        isCompleted: d.isCompleted,
        isSynced: false,
        position: d.position,
        createdAt: d.createdAt,
        quantity: _parseNumber(_quantity.text),
        unit: _unit,
        category: _category,
        price: _parseNumber(_price.text),
        store: _textOrNull(_store),
        url: _textOrNull(_url),
        priority: _priority,
        notes: _textOrNull(_notes),
        description: _textOrNull(_description),
        imageUrl: _textOrNull(_imageUrl),
        attributes: _collectAttributes(),
        evaluation: _evaluation,
        isFavorite: _isFavorite,
        isChosen: d.isChosen,
        dueDate: _dueDate,
        isInProgress: _isInProgress && !d.isCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;

    return AnimatedPadding(
      duration: mediaQuery.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(widget.type.icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isNew ? _tr.newItemTitle : _tr.itemDetailsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: headingColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('item_editor_title'),
                        controller: _title,
                        autofocus: widget.isNew,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: _tr.itemTitleLabel,
                          hintText: _tr.itemTitleHint,
                          counterText: '',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? _tr.itemTitleValidation
                            : null,
                      ),
                      ..._typeFields(labelColor),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  16 + mediaQuery.viewPadding.bottom,
                ),
                child: FilledButton(
                  key: const Key('item_editor_save'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(
                    widget.isNew ? _tr.createItemAction : _tr.saveChanges,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typeFields(Color labelColor) => switch (widget.type) {
    ListType.market => _marketFields(labelColor),
    ListType.shopping => _shoppingFields(labelColor),
    ListType.options => _optionsFields(labelColor),
    ListType.tasks => _taskFields(labelColor),
    ListType.custom => _customFields(),
  };

  Widget _priceField() => TextFormField(
    key: const Key('item_editor_price'),
    controller: _price,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(labelText: _tr.estimatedPriceLabel),
    validator: _validateNumber,
  );

  Widget _imageField() => TextFormField(
    key: const Key('item_editor_image'),
    controller: _imageUrl,
    keyboardType: TextInputType.url,
    decoration: InputDecoration(labelText: _tr.imageUrlLabel),
    validator: _validateImageUrl,
  );

  Widget _descriptionField({int maxLines = 2}) => TextFormField(
    key: const Key('item_editor_description'),
    controller: _description,
    maxLines: maxLines,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(labelText: _tr.descriptionLabel),
  );

  Widget _notesField() => TextFormField(
    key: const Key('item_editor_notes'),
    controller: _notes,
    maxLines: 3,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(labelText: _tr.notesLabel),
  );

  List<Widget> _marketFields(Color labelColor) => [
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('item_editor_quantity'),
      controller: _quantity,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: _tr.quantityLabel),
      validator: _validateNumber,
    ),
    _SectionLabel(_tr.unitLabel, labelColor),
    _ChoiceWrap<String>(
      keyPrefix: 'unit',
      values: MarketCatalog.units,
      selected: _unit,
      labelOf: (unit) => unit,
      onChanged: (value) => setState(() => _unit = value),
    ),
    _SectionLabel(_tr.categoryLabel, labelColor),
    _ChoiceWrap<String>(
      keyPrefix: 'category',
      values: MarketCatalog.categories,
      selected: _category,
      labelOf: _tr.categoryName,
      onChanged: (value) => setState(() => _category = value),
    ),
    const SizedBox(height: 12),
    _priceField(),
  ];

  List<Widget> _shoppingFields(Color labelColor) => [
    const SizedBox(height: 12),
    _imageField(),
    const SizedBox(height: 12),
    _priceField(),
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('item_editor_store'),
      controller: _store,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: _tr.storeLabel),
    ),
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('item_editor_url'),
      controller: _url,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(labelText: _tr.linkLabel),
      validator: _validateUrl,
    ),
    ..._priorityFields(labelColor),
  ];

  List<Widget> _optionsFields(Color labelColor) => [
    const SizedBox(height: 12),
    _imageField(),
    const SizedBox(height: 12),
    _descriptionField(),
    for (final entry in _attributes.entries) ...[
      const SizedBox(height: 12),
      TextFormField(
        key: Key('item_editor_attr_${entry.key}'),
        controller: entry.value,
        decoration: InputDecoration(labelText: entry.key),
      ),
    ],
    _SectionLabel(_tr.evaluationLabel, labelColor),
    _ChoiceWrap<ItemEvaluation>(
      keyPrefix: 'evaluation',
      values: ItemEvaluation.values,
      selected: _evaluation,
      labelOf: _tr.evaluationName,
      onChanged: (value) => setState(() => _evaluation = value),
    ),
    const SizedBox(height: 12),
    _notesField(),
    SwitchListTile(
      key: const Key('item_editor_favorite'),
      contentPadding: EdgeInsets.zero,
      title: Text(_tr.favoriteLabel),
      value: _isFavorite,
      onChanged: (value) => setState(() => _isFavorite = value),
    ),
  ];

  List<Widget> _taskFields(Color labelColor) => [
    const SizedBox(height: 12),
    _descriptionField(),
    const SizedBox(height: 12),
    _notesField(),
    ..._priorityFields(labelColor),
    _SectionLabel(_tr.dueDateLabel, labelColor),
    Row(
      children: [
        OutlinedButton.icon(
          key: const Key('item_editor_due_date'),
          onPressed: _pickDate,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(
            _dueDate == null
                ? _tr.noDueDate
                : MaterialLocalizations.of(context).formatMediumDate(_dueDate!),
          ),
        ),
        if (_dueDate != null)
          IconButton(
            key: const Key('item_editor_clear_date'),
            tooltip: _tr.clearDate,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => setState(() => _dueDate = null),
          ),
      ],
    ),
    if (!widget.draft.isCompleted)
      SwitchListTile(
        key: const Key('item_editor_in_progress'),
        contentPadding: EdgeInsets.zero,
        title: Text(_tr.inProgressLabel),
        value: _isInProgress,
        onChanged: (value) => setState(() => _isInProgress = value),
      ),
  ];

  List<Widget> _customFields() => [
    const SizedBox(height: 12),
    _descriptionField(),
    const SizedBox(height: 12),
    _notesField(),
  ];

  List<Widget> _priorityFields(Color labelColor) => [
    _SectionLabel(_tr.priorityLabel, labelColor),
    _ChoiceWrap<ItemPriority>(
      keyPrefix: 'priority',
      values: ItemPriority.values,
      selected: _priority,
      labelOf: _tr.priorityName,
      onChanged: (value) => setState(() => _priority = value),
    ),
  ];
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ChoiceWrap<T extends Object> extends StatelessWidget {
  final String keyPrefix;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _ChoiceWrap({
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            key: Key('${keyPrefix}_${value is Enum ? value.name : value}'),
            label: Text(labelOf(value)),
            selected: value == selected,
            onSelected: (isSelected) => onChanged(isSelected ? value : null),
          ),
      ],
    );
  }
}

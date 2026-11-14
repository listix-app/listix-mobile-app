import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/todo_item.dart';
import '../controllers/lists_controller.dart';
import '../widgets/list_type_picker.dart';
import '../widgets/list_type_presentation.dart';
import '../../../ads/data/interstitial_ad_service.dart';

class CreateEditListScreen extends ConsumerStatefulWidget {
  final String? listId;

  const CreateEditListScreen({super.key, this.listId});

  bool get isEditing => listId != null;

  @override
  ConsumerState<CreateEditListScreen> createState() =>
      _CreateEditListScreenState();
}

class _CreateEditListScreenState extends ConsumerState<CreateEditListScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _selectedColor;
  ListType? _selectedType;
  ListTemplate? _selectedTemplate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final list = ref.read(shoppingListProvider(widget.listId!));
        if (list != null) {
          if (!list.isOwner) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ref.read(stringsProvider).ownerOnlyAction),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
            return;
          }
          _nameController.text = list.name;
          setState(() {
            _selectedColor = list.color;
            _selectedType = list.type;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectTemplate(ListTemplate template, bool isSpanish) {
    setState(() {
      if (_selectedTemplate?.id == template.id) {
        _selectedTemplate = null;
      } else {
        _selectedTemplate = template;
        _nameController.text = template.name(isSpanish);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final notifier = ref.read(listsControllerProvider.notifier);
      final isSpanish = ref.read(stringsProvider).isSpanish;

      if (widget.isEditing) {
        await notifier.updateListName(
          widget.listId!,
          name,
          color: _selectedColor,
          type: _selectedType,
        );
        if (mounted) context.pop();
      } else {
        final created = await notifier.createList(
          name,
          color: _selectedColor,
          type: _selectedType ?? ListType.custom,
        );
        final template = _selectedTemplate;
        if (template != null && template.type == _selectedType) {
          final attrs = template.attributeNames(isSpanish);
          if (attrs.isNotEmpty) {
            await notifier.updateListAttributes(created.id, attrs);
          }
          for (final seed in template.starterItems) {
            final itemTitle = seed.title(isSpanish);
            await notifier.addItem(
              created.id,
              itemTitle,
              details: TodoItem(
                id: '',
                listId: created.id,
                title: itemTitle,
                createdAt: DateTime.now(),
                quantity: seed.quantity,
                unit: seed.unit,
                category: seed.category,
                priority: seed.priority,
              ),
            );
          }
        }
        ref.read(interstitialAdServiceProvider).showInterstitialIfAllowed();
        if (mounted) {
          context.pushReplacement('/list/${created.id}');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isPickingType => !widget.isEditing && _selectedType == null;

  void _handleBack() {
    if (!widget.isEditing && _selectedType != null) {
      setState(() {
        _selectedType = null;
        _selectedTemplate = null;
      });
      return;
    }
    context.pop();
  }

  Widget _buildTypePickerStep(
    AppStrings tr,
    Color headingColor,
    Color subheadingColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr.listTypePickerHeading,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: headingColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr.listTypePickerSubheading,
            style: TextStyle(fontSize: 14, color: subheadingColor, height: 1.4),
          ),
          const SizedBox(height: 24),
          ListTypePicker(
            strings: tr,
            onSelected: (type) => setState(() {
              _selectedType = type;
              _selectedTemplate = null;
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final subheadingColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final title = widget.isEditing ? tr.renameListTitle : tr.newListTitle;
    final actionButtonText = widget.isEditing
        ? tr.saveChanges
        : tr.createListAction;
    final templates = (!widget.isEditing && _selectedType != null)
        ? ListTemplate.templatesFor(_selectedType!)
        : const <ListTemplate>[];

    return PopScope(
      canPop: widget.isEditing || _selectedType == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: _isPickingType
              ? _buildTypePickerStep(tr, headingColor, subheadingColor)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 14.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 28.0).clamp(
                            0.0,
                            double.infinity,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    widget.isEditing
                                        ? tr.editListHeading
                                        : tr.createListHeading,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: headingColor,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.isEditing
                                        ? tr.editListSubheading
                                        : tr.createListSubheading,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subheadingColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  if (widget.isEditing &&
                                      _selectedType != null) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final type in ListType.values)
                                          ChoiceChip(
                                            key: Key(
                                              'edit_list_type_${type.name}',
                                            ),
                                            avatar: Icon(type.icon, size: 18),
                                            label: Text(tr.listTypeName(type)),
                                            selected: _selectedType == type,
                                            onSelected: (_) => setState(
                                              () => _selectedType = type,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                  ] else if (_selectedType != null) ...[
                                    _SelectedTypeChip(
                                      type: _selectedType!,
                                      label: tr.listTypeName(_selectedType!),
                                      changeLabel: tr.changeListType,
                                      onChange: _handleBack,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  TextFormField(
                                    controller: _nameController,
                                    autofocus: true,
                                    maxLength: 50,
                                    textInputAction: TextInputAction.done,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: tr.listNameLabel,
                                      hintText: tr.listNameHint,
                                      prefixIcon: const Icon(
                                        Icons.edit_note_rounded,
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return tr.listNameValidation;
                                      }
                                      return null;
                                    },
                                  ),
                                  if (templates.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      tr.templatesHeading,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        for (final template in templates)
                                          ChoiceChip(
                                            key: Key('template_${template.id}'),
                                            label: Text(
                                              template.name(tr.isSpanish),
                                            ),
                                            selected:
                                                _selectedTemplate?.id ==
                                                template.id,
                                            onSelected: (_) => _selectTemplate(
                                              template,
                                              tr.isSpanish,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Text(
                                    tr.pickColor,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: AppColors.listColors.map((color) {
                                      final colorValue = color.toARGB32();
                                      final isSelected =
                                          _selectedColor == colorValue;
                                      return Semantics(
                                        label:
                                            '${tr.pickColor} #${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                                        selected: isSelected,
                                        button: true,
                                        child: InkWell(
                                          key: Key(
                                            'color_picker_${colorValue.toRadixString(16)}',
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedColor = isSelected
                                                  ? null
                                                  : colorValue;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: isSelected
                                                  ? Border.all(
                                                      color: isDark
                                                          ? AppColors.onPrimary
                                                          : Colors.black87,
                                                      width: 3,
                                                    )
                                                  : null,
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    color: AppColors.onPrimary,
                                                    size: 24,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        actionButtonText,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SelectedTypeChip extends StatelessWidget {
  final ListType type;
  final String label;
  final String changeLabel;
  final VoidCallback onChange;

  const _SelectedTypeChip({
    required this.type,
    required this.label,
    required this.changeLabel,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.primaryLight,
        ),
      ),
      child: Row(
        children: [
          Icon(type.icon, size: 20, color: type.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              key: const Key('selected_list_type_label'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            key: const Key('change_list_type_button'),
            onPressed: onChange,
            child: Text(changeLabel),
          ),
        ],
      ),
    );
  }
}

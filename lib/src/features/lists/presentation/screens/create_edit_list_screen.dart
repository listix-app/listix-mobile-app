import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/lists_controller.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final notifier = ref.read(listsControllerProvider.notifier);

      if (widget.isEditing) {
        await notifier.updateListName(
          widget.listId!,
          name,
          color: _selectedColor,
        );
        if (mounted) context.pop();
      } else {
        final created = await notifier.createList(name, color: _selectedColor);
        ref.read(interstitialAdServiceProvider).showInterstitialIfAllowed();
        if (mounted) {
          context.pushReplacement('/list/${created.id}');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final title = widget.isEditing ? tr.renameListTitle : tr.newListTitle;
    final actionButtonText = widget.isEditing
        ? tr.saveChanges
        : tr.createListAction;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 40.0).clamp(
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isEditing
                                ? tr.editListSubheading
                                : tr.createListSubheading,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            maxLength: 50,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.sentences,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: tr.listNameLabel,
                              hintText: tr.listNameHint,
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return tr.listNameValidation;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            tr.pickColor,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: AppColors.listColors.map((color) {
                              final colorValue = color.toARGB32();
                              final isSelected = _selectedColor == colorValue;
                              return InkWell(
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
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
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
    );
  }
}

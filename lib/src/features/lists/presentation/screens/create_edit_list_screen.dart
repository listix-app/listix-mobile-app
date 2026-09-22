import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../ads/presentation/controllers/admob_controller.dart';
import '../controllers/lists_controller.dart';

class CreateEditListScreen extends ConsumerStatefulWidget {
  final String? listId;

  const CreateEditListScreen({super.key, this.listId});

  bool get isEditing => listId != null;

  @override
  ConsumerState<CreateEditListScreen> createState() =>
      _CreateEditListScreenState();
}

class _CreateEditListScreenState extends ConsumerState<CreateEditListScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final list = ref.read(shoppingListProvider(widget.listId!));
        if (list != null) {
          _nameController.text = list.name;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final notifier = ref.read(listsControllerProvider.notifier);

      if (widget.isEditing) {
        await notifier.updateListName(widget.listId!, name);
        if (mounted) context.pop();
      } else {
        final created = await notifier.createList(name);
        if (mounted) {
          // Trigger AdMob Interstitial ad before opening created list
          await ref.read(admobControllerProvider).showInterstitial(context);
          if (mounted) {
            context.pushReplacement('/list/${created.id}');
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Renombrar lista' : 'Nueva lista';
    final actionButtonText = widget.isEditing
        ? 'Guardar cambios'
        : 'Crear lista';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isEditing
                      ? 'Edita el nombre de tu lista'
                      : '¿Qué vas a comprar o preparar hoy?',
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
                      ? 'El nuevo nombre se guardará en SQLite local y se sincronizará automáticamente.'
                      : 'Escribe un nombre claro (ej. Supermercado semanal, Ferretería, Farmacia).',
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
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onFieldSubmitted: (_) => _save(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la lista',
                    hintText: 'Ej. Despensa mensual',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../lists/presentation/controllers/lists_controller.dart';
import '../controllers/collaboration_controller.dart';

class JoinListDialog extends ConsumerStatefulWidget {
  const JoinListDialog({super.key});

  @override
  ConsumerState<JoinListDialog> createState() => _JoinListDialogState();
}

class _JoinListDialogState extends ConsumerState<JoinListDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseInviteCode(
    String input, {
    required Function(String id, String name) onSuccess,
    required VoidCallback onError,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      onError();
      return;
    }

    try {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final uri = Uri.parse(trimmed);
        final listId =
            uri.queryParameters['listId'] ?? uri.pathSegments.lastOrNull;
        final listName = uri.queryParameters['name'] ?? 'Lista Compartida';
        if (listId != null && listId.isNotEmpty) {
          onSuccess(listId, listName);
          return;
        }
      }
    } catch (_) {}

    // Fallback: direct ID or code
    final parts = trimmed.split('/');
    final cleanId = parts.last.trim();
    if (cleanId.isNotEmpty) {
      onSuccess(cleanId, 'Lista Compartida');
    } else {
      onError();
    }
  }

  Future<void> _handleJoin(AppStrings tr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? targetId;
    String targetName = 'Lista Compartida';
    var parseError = false;

    _parseInviteCode(
      _controller.text,
      onSuccess: (id, name) {
        targetId = id;
        targetName = name;
      },
      onError: () {
        parseError = true;
      },
    );

    if (parseError || targetId == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.invalidInviteCode),
            backgroundColor: AppColors.delete,
          ),
        );
      }
      return;
    }

    try {
      final joinedList = await ref
          .read(listsControllerProvider.notifier)
          .joinList(targetId!, targetName);

      // Join room in websocket
      await ref
          .read(collaborationControllerProvider.notifier)
          .joinListRoom(targetId!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.listJoined(joinedList.name)),
            backgroundColor: AppColors.primary,
          ),
        );
        context.push('/list/${joinedList.id}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.errorPrefix(e.toString())),
            backgroundColor: AppColors.delete,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.group_add_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr.joinListTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.joinListPrompt,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('invite_code_input'),
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: tr.joinListHint,
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return tr.invalidInviteCode;
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleJoin(tr),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(tr.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () => _handleJoin(tr),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(tr.joinAction),
        ),
      ],
    );
  }
}

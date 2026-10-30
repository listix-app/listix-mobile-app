// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../lists/presentation/controllers/lists_controller.dart';
import '../../domain/entities/collaboration_exceptions.dart';
import '../controllers/collaboration_controller.dart';

class JoinListDialog extends ConsumerStatefulWidget {
  const JoinListDialog({super.key});

  @override
  ConsumerState<JoinListDialog> createState() => _JoinListDialogState();
}

class _JoinListDialogState extends ConsumerState<JoinListDialog> {
  final _controller = TextEditingController();
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedNickname();
  }

  Future<void> _loadSavedNickname() async {
    try {
      final saved = await AppDatabase.instance.getSetting('user_nickname');
      if (saved != null && saved.isNotEmpty && mounted) {
        _nicknameController.text = saved;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _parseInviteCode(
    String input, {
    required Function(String id, String name) onSuccess,
    required VoidCallback onError,
  }) {
    final trimmed = input.trim();

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

    final nickname = _nicknameController.text.trim();
    if (nickname.isNotEmpty) {
      try {
        await AppDatabase.instance.setSetting('user_nickname', nickname);
      } catch (_) {}
    }

    try {
      final joinedList = await ref
          .read(listsControllerProvider.notifier)
          .joinListByInviteToken(
            _controller.text,
            displayName: nickname.isNotEmpty ? nickname : null,
          );

      // Join room in websocket if active
      await ref
          .read(collaborationControllerProvider.notifier)
          .joinListRoom(joinedList.id);

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
    } on ListMemberLimitReachedException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.delete),
        );
      }
    } on InviteExpiredException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.delete),
        );
      }
    } on InvalidInviteException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.delete),
        );
      }
    } catch (_) {
      // Fallback to legacy URL / code parser
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
              key: const Key('join_list_nickname_input'),
              controller: _nicknameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: tr.yourNicknameLabel,
                hintText: tr.yourNicknameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('join_list_input'),
              controller: _controller,
              autofocus: _nicknameController.text.isNotEmpty,
              decoration: InputDecoration(
                labelText: tr.joinListHint,
                hintText: tr.joinListHint,
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr.invalidInviteCode;
                }
                return null;
              },
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
          key: const Key('join_list_confirm_button'),
          onPressed: _isLoading ? null : () => _handleJoin(tr),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(tr.joinAction),
        ),
      ],
    );
  }
}

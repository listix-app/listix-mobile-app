import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class QuickAddInput extends StatefulWidget {
  final ValueChanged<String> onAdd;
  final bool autoFocus;
  final String? hintText;
  final String? tooltip;

  const QuickAddInput({
    super.key,
    required this.onAdd,
    this.autoFocus = true,
    this.hintText,
    this.tooltip,
  });

  @override
  State<QuickAddInput> createState() => _QuickAddInputState();
}

class _QuickAddInputState extends State<QuickAddInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _canSubmit) {
      setState(() => _canSubmit = hasText);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() => _canSubmit = false);
    widget.onAdd(text);
    // Keep focus so the user can quickly type multiple items
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autoFocus,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Agregar item',
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _canSubmit ? AppColors.primary : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _canSubmit ? _submit : null,
                icon: Icon(
                  Icons.check,
                  size: 22,
                  color: _canSubmit ? Colors.white : AppColors.textMuted,
                ),
                splashRadius: 24,
                tooltip: widget.tooltip ?? 'Agregar item',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

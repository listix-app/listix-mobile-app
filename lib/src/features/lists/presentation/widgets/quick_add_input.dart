import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class QuickAddInput extends StatefulWidget {
  final ValueChanged<String> onAdd;
  final bool autoFocus;
  final String? hintText;
  final String? tooltip;
  final ValueChanged<String>? onAddWithDetails;
  final String? detailsTooltip;

  const QuickAddInput({
    super.key,
    required this.onAdd,
    this.autoFocus = true,
    this.hintText,
    this.tooltip,
    this.onAddWithDetails,
    this.detailsTooltip,
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
    _focusNode.requestFocus();
  }

  void _openDetails() {
    final text = _controller.text.trim();
    _controller.clear();
    setState(() => _canSubmit = false);
    widget.onAddWithDetails!(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.cardDark : Colors.white;
    final inputBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final unselectedButtonBg = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final unselectedIconColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMuted;

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final systemBottomPadding = bottomInset > 0
        ? 0.0
        : (mediaQuery.padding.bottom > 0
              ? mediaQuery.padding.bottom
              : mediaQuery.viewPadding.bottom);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + systemBottomPadding),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
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
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autoFocus,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                style: TextStyle(fontSize: 15, color: textTitleColor),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Agregar item',
                  counterText: '',
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                  filled: true,
                  fillColor: inputBg,
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
            if (widget.onAddWithDetails != null) ...[
              const SizedBox(width: 4),
              IconButton(
                key: const Key('quick_add_details_button'),
                onPressed: _openDetails,
                icon: Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: unselectedIconColor,
                ),
                tooltip: widget.detailsTooltip,
              ),
            ],
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _canSubmit ? AppColors.primary : unselectedButtonBg,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _canSubmit ? _submit : null,
                icon: Icon(
                  Icons.check,
                  size: 22,
                  color: _canSubmit ? Colors.white : unselectedIconColor,
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

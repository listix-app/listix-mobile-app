import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PriceInput {
  static const maxDecimals = 2;

  final String decimalSeparator;
  final String groupSeparator;
  final NumberFormat _display;

  PriceInput(String locale)
    : decimalSeparator = NumberFormat.decimalPattern(
        locale,
      ).symbols.DECIMAL_SEP,
      groupSeparator = NumberFormat.decimalPattern(locale).symbols.GROUP_SEP,
      _display = NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = 0
        ..maximumFractionDigits = maxDecimals;

  TextInputFormatter get formatter => _PriceInputFormatter(this);

  String format(double? value) => value == null ? '' : _display.format(value);

  double? parse(String text) => double.tryParse(
    text
        .trim()
        .replaceAll(groupSeparator, '')
        .replaceAll(decimalSeparator, '.'),
  );

  String group(String integerDigits) {
    final buffer = StringBuffer();
    for (var i = 0; i < integerDigits.length; i++) {
      if (i > 0 && (integerDigits.length - i) % 3 == 0) {
        buffer.write(groupSeparator);
      }
      buffer.write(integerDigits[i]);
    }
    return buffer.toString();
  }
}

class _PriceInputFormatter extends TextInputFormatter {
  final PriceInput _price;

  _PriceInputFormatter(this._price);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final rawCursor = newValue.selection.baseOffset;
    final cursor = rawCursor < 0 || rawCursor > raw.length
        ? raw.length
        : rawCursor;

    var integerDigits = '';
    var fraction = '';
    var hasDecimal = false;
    var significantBeforeCursor = 0;
    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];
      final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      final isDecimal = char == _price.decimalSeparator && !hasDecimal;
      if (!isDigit && !isDecimal) continue;
      if (isDecimal) {
        hasDecimal = true;
      } else if (hasDecimal) {
        if (fraction.length == PriceInput.maxDecimals) continue;
        fraction += char;
      } else {
        integerDigits += char;
      }
      if (i < cursor) significantBeforeCursor++;
    }

    var strippedZeros = 0;
    while (integerDigits.length > 1 && integerDigits.startsWith('0')) {
      integerDigits = integerDigits.substring(1);
      strippedZeros++;
    }
    significantBeforeCursor -= strippedZeros.clamp(0, significantBeforeCursor);

    if (integerDigits.isEmpty && hasDecimal) {
      integerDigits = '0';
      if (significantBeforeCursor > 0) significantBeforeCursor++;
    }

    final text =
        _price.group(integerDigits) +
        (hasDecimal ? _price.decimalSeparator + fraction : '');

    var offset = text.length;
    if (cursor < raw.length) {
      offset = significantBeforeCursor == 0 ? 0 : text.length;
      var seen = 0;
      for (var j = 0; j < text.length && significantBeforeCursor > 0; j++) {
        if (text[j] == _price.groupSeparator) continue;
        seen++;
        if (seen == significantBeforeCursor) {
          offset = j + 1;
          break;
        }
      }
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/utils/price_input.dart';

TextEditingValue _type(
  PriceInput input,
  String text, {
  int? cursor,
  String previous = '',
}) => input.formatter.formatEditUpdate(
  TextEditingValue(text: previous),
  TextEditingValue(
    text: text,
    selection: cursor == null
        ? const TextSelection.collapsed(offset: -1)
        : TextSelection.collapsed(offset: cursor),
  ),
);

void main() {
  final es = PriceInput('es');
  final en = PriceInput('en');

  group('PriceInput display and parsing', () {
    test('formats per locale and omits empty decimals', () {
      expect(es.format(1234567.5), '1.234.567,5');
      expect(en.format(1234567.5), '1,234,567.5');
      expect(es.format(100), '100');
      expect(es.format(null), '');
    });

    test('parses what it formats', () {
      expect(es.parse('1.234,50'), 1234.5);
      expect(en.parse('1,234.50'), 1234.5);
      expect(es.parse(' 12 '), 12);
      expect(es.parse(''), isNull);
      expect(es.parse(','), isNull);
    });
  });

  group('PriceInput formatter', () {
    test('groups thousands while typing', () {
      expect(_type(es, '1234567').text, '1.234.567');
      expect(_type(en, '1234567').text, '1,234,567');
    });

    test('keeps the cursor at the end when typing at the end', () {
      expect(_type(es, '1234').selection.baseOffset, 5);
    });

    test('keeps only digits and a single decimal separator', () {
      expect(_type(es, 'a1b2,3,4').text, '12,34');
      expect(_type(es, '12,345').text, '12,34');
    });

    test('limits decimals to two', () {
      expect(_type(es, '1,999').text, '1,99');
    });

    test('keeps a trailing decimal separator', () {
      expect(_type(es, '12,').text, '12,');
    });

    test('adds a leading zero before a lone decimal separator', () {
      expect(_type(es, ',5', cursor: 1).text, '0,5');
      expect(_type(es, ',5', cursor: 1).selection.baseOffset, 2);
      expect(_type(es, ',5', cursor: 0).selection.baseOffset, 0);
    });

    test('strips leading zeros', () {
      expect(_type(es, '007').text, '7');
      expect(_type(es, '0').text, '0');
      expect(_type(es, '007', cursor: 2).selection.baseOffset, 0);
    });

    test('empty and non numeric input become empty', () {
      expect(_type(es, '').text, '');
      expect(_type(es, 'abc').text, '');
    });

    test('maps the cursor around grouping separators', () {
      final value = _type(es, '12345', cursor: 2);
      expect(value.text, '12.345');
      expect(value.selection.baseOffset, 2);
      expect(_type(es, '1234', cursor: 3).selection.baseOffset, 4);
      expect(_type(es, '1234', cursor: 0).selection.baseOffset, 0);
    });

    test('cursor falls back to the end when characters were dropped', () {
      expect(_type(es, '1,999x', cursor: 5).selection.baseOffset, 4);
    });
  });
}

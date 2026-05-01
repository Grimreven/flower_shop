import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }

    if (!digits.startsWith('7')) {
      digits = '7$digits';
    }

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    String result = '+7';

    if (digits.length > 1) {
      result += ' (${digits.substring(1, digits.length.clamp(1, 4))}';
    }

    if (digits.length >= 4) {
      result += ') ${digits.substring(4, digits.length.clamp(4, 7))}';
    }

    if (digits.length >= 7) {
      result += '-${digits.substring(7, digits.length.clamp(7, 9))}';
    }

    if (digits.length >= 9) {
      result += '-${digits.substring(9, digits.length.clamp(9, 11))}';
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
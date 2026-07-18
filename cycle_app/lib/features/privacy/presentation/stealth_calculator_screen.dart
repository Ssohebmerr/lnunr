import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/user_prefs.dart';

/// A fully functional calculator that secretly unlocks Lune
/// when the user enters their stealth PIN and presses '='.
class StealthCalculatorScreen extends StatefulWidget {
  const StealthCalculatorScreen({super.key});

  @override
  State<StealthCalculatorScreen> createState() => _StealthCalculatorScreenState();
}

class _StealthCalculatorScreenState extends State<StealthCalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  String _secretBuffer = '';

  void _onDigit(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _secretBuffer += digit;
      if (_shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display = _display == '0' ? digit : _display + digit;
      }
    });
  }

  void _onDecimal() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      _secretBuffer += op;
      final current = double.tryParse(_display) ?? 0;
      if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
        _firstOperand = _calculate(_firstOperand!, current, _operator!);
        _display = _formatResult(_firstOperand!);
      } else {
        _firstOperand = current;
      }
      _operator = op;
      _expression = '${_formatResult(_firstOperand!)} $op';
      _shouldResetDisplay = true;
    });
  }

  void _onEquals() {
    HapticFeedback.mediumImpact();

    // Capture the buffer NOW — the setState below wipes it synchronously,
    // and the async check used to read the field only after that wipe, so
    // the unlock could never fire no matter how correct the PIN was.
    _checkSecretUnlock(_secretBuffer);

    setState(() {
      if (_firstOperand != null && _operator != null) {
        final current = double.tryParse(_display) ?? 0;
        final result = _calculate(_firstOperand!, current, _operator!);
        _expression = '${_formatResult(_firstOperand!)} $_operator ${_formatResult(current)} =';
        _display = _formatResult(result);
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = true;
      }
      _secretBuffer = ''; // Reset secret buffer after equals
    });
  }

  Future<void> _checkSecretUnlock(String buffer) async {
    if (buffer.isEmpty) return;
    if (!await UserPrefs.hasStealthPin()) return;

    if (await UserPrefs.stealthPinMatchesBuffer(buffer)) {
      _unlockApp();
    }
  }

  void _unlockApp() {
    UserPrefs.setSessionUnlocked(true);
    if (!mounted) return;
    context.go('/home');
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
      _secretBuffer = '';
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onPercent() {
    HapticFeedback.lightImpact();
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      _display = _formatResult(current / 100);
    });
  }

  void _onToggleSign() {
    HapticFeedback.lightImpact();
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      _display = _formatResult(-current);
    });
  }

  double _calculate(double a, double b, String op) {
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '×' => a * b,
      '÷' => b != 0 ? a / b : double.nan,
      _ => b,
    };
  }

  String _formatResult(double value) {
    if (value.isNaN) return 'Error';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.round().toString();
    }
    // Limit decimal places to avoid overflow
    final str = value.toStringAsFixed(10);
    return str.contains('.') ? str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : str;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Calculator name
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Calculator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),

            // Display
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_expression.isNotEmpty)
                      Text(
                        _expression,
                        style: TextStyle(
                          fontSize: 20,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: _display.length > 9 ? 48 : 64,
                          fontWeight: FontWeight.w300,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Expanded(
              flex: 4,
              child: _buildButtonGrid(isDark, screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGrid(bool isDark, double screenWidth) {
    final buttons = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: buttons.map((row) {
          return Expanded(
            child: Row(
              children: row.map((btn) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildButton(btn, isDark),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String text, bool isDark) {
    final isOperator = ['÷', '×', '-', '+', '='].contains(text);
    final isFunction = ['C', '⌫', '%', '±'].contains(text);
    final isEquals = text == '=';

    Color bgColor;
    Color textColor;

    if (isEquals) {
      bgColor = const Color(0xFFFF9500); // Orange
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = isDark ? const Color(0xFFFF9500) : const Color(0xFFFF9500);
      textColor = Colors.white;
    } else if (isFunction) {
      bgColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
      textColor = isDark ? Colors.white : Colors.black87;
    } else {
      bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleButtonPress(text),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: text == '⌫'
                ? Icon(Icons.backspace_outlined, color: textColor, size: 24)
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: isOperator ? 28 : 24,
                      fontWeight: isOperator ? FontWeight.w500 : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleButtonPress(String text) {
    switch (text) {
      case 'C':
        _onClear();
      case '⌫':
        _onBackspace();
      case '%':
        _onPercent();
      case '±':
        _onToggleSign();
      case '.':
        _onDecimal();
      case '=':
        _onEquals();
      case '+':
      case '-':
      case '×':
      case '÷':
        _onOperator(text);
      default:
        _onDigit(text);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ai/direct_gemini_service.dart';

/// Diagnostic + manual key setup screen for the Gemini API.
///
/// Lets the user:
/// - See whether a key is currently stored.
/// - Run a live connection test against Google AI Studio.
/// - Paste / replace the key on-device (stored in SecureStorage, never sent
///   anywhere except the official Google endpoint).
class AiDiagnosticScreen extends StatefulWidget {
  const AiDiagnosticScreen({super.key});

  @override
  State<AiDiagnosticScreen> createState() => _AiDiagnosticScreenState();
}

class _AiDiagnosticScreenState extends State<AiDiagnosticScreen> {
  final _service = DirectGeminiService();
  final _controller = TextEditingController();
  bool _busy = false;
  String? _status;
  bool? _hasKey;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final hasKey = await _service.hasKey();
    if (!mounted) return;
    setState(() => _hasKey = hasKey);
  }

  Future<void> _runTest() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.testConnection();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = result;
    });
  }

  Future<void> _saveKey() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() => _busy = true);
    await _service.setKey(raw);
    _controller.clear();
    await _refresh();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = 'تم حفظ المفتاح. اضغطي "اختبار الاتصال" للتأكد.';
    });
  }

  Color _statusColor(String? text) {
    if (text == null) return Colors.transparent;
    if (text.startsWith('SUCCESS')) return Colors.green.shade100;
    if (text.startsWith('ERROR')) return Colors.red.shade100;
    if (text.startsWith('EXCEPTION')) return Colors.red.shade100;
    return Colors.amber.shade100;
  }

  IconData _statusIcon(String? text) {
    if (text == null) return Icons.help_outline;
    if (text.startsWith('SUCCESS')) return Icons.check_circle;
    if (text.startsWith('ERROR') || text.startsWith('EXCEPTION')) {
      return Icons.error_outline;
    }
    return Icons.info_outline;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تشخيص الذكاء الاصطناعي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasKey == true
                            ? Icons.vpn_key
                            : Icons.key_off_outlined,
                        color: _hasKey == true ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasKey == null
                            ? 'جاري الفحص...'
                            : _hasKey!
                                ? 'يوجد مفتاح مخزّن على الجهاز'
                                : 'لا يوجد مفتاح مخزّن',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _runTest,
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('اختبار الاتصال بـ Gemini الآن'),
                  ),
                ],
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor(_status),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon(_status)),
                  const SizedBox(width: 8),
                  Expanded(child: SelectableText(_status!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'تحديث المفتاح يدوياً',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'احصلي على مفتاح صالح من Google AI Studio (aistudio.google.com/apikey) '
            'ثم الصقيه هنا. يُخزَّن محلياً على الجهاز فقط في SecureStorage.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'الصقي المفتاح الجديد',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _obscure ? 'إظهار' : 'إخفاء',
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  IconButton(
                    tooltip: 'لصق',
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _controller.text = data!.text!.trim();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _saveKey,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ المفتاح'),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كيف أحصل على المفتاح؟',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. افتحي https://aistudio.google.com/apikey\n'
                    '2. سجّلي بحساب Google\n'
                    '3. اضغطي "Create API key"\n'
                    '4. انسخي المفتاح والصقيه هنا\n\n'
                    'المفاتيح الجديدة تبدأ بـ "AQ.Ab..." أو "AIzaSy..."',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/support_service.dart';

/// Sheet with two actions: send feedback, redeem promo code.
class SupportSheet extends StatelessWidget {
  const SupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'الدعم والملاحظات',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'شاركينا رأيك أو فعّلي كوداً ترويجياً',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _SupportTile(
              icon: Icons.bug_report_outlined,
              color: const Color(0xFFD14758),
              title: 'الإبلاغ عن خطأ',
              subtitle: 'شيء لا يعمل أو يتعطل؟',
              onTap: () {
                Navigator.pop(context);
                _openFeedback(context, 'bug');
              },
            ),
            _SupportTile(
              icon: Icons.lightbulb_outline_rounded,
              color: const Color(0xFFD89C32),
              title: 'اقتراح ميزة',
              subtitle: 'فكرة تساعد التطبيق ينمو',
              onTap: () {
                Navigator.pop(context);
                _openFeedback(context, 'idea');
              },
            ),
            _SupportTile(
              icon: Icons.help_outline_rounded,
              color: const Color(0xFFA48AD4),
              title: 'مساعدة أو سؤال',
              subtitle: 'لديك سؤال؟ سنرد عليك',
              onTap: () {
                Navigator.pop(context);
                _openFeedback(context, 'help');
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _SupportTile(
              icon: Icons.card_giftcard_rounded,
              color: const Color(0xFFE8A0BF),
              title: 'استخدام كود ترويجي',
              subtitle: 'احصلي على Premium مجاناً',
              onTap: () {
                Navigator.pop(context);
                _openPromoSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFeedback(BuildContext context, String type) {
    showDialog<void>(
      context: context,
      builder: (_) => _FeedbackDialog(type: type),
    );
  }

  void _openPromoSheet(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _PromoDialog(),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final String type;
  const _FeedbackDialog({required this.type});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _err;

  String get _title => switch (widget.type) {
        'bug' => 'الإبلاغ عن خطأ',
        'idea' => 'اقتراح ميزة',
        'help' => 'مساعدة أو سؤال',
        _ => 'ملاحظة',
      };

  String get _hint => switch (widget.type) {
        'bug' => 'صفي ما حدث، وماذا كنت تحاولين فعله...',
        'idea' => 'اقترحي ميزة تحبّين رؤيتها في التطبيق...',
        'help' => 'ما الذي تحتاجين المساعدة فيه؟',
        _ => 'اكتبي رسالتك هنا...',
      };

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.length < 5) {
      setState(() => _err = 'الرسالة قصيرة جداً (5 أحرف على الأقل)');
      return;
    }
    setState(() { _sending = true; _err = null; });
    try {
      await SupportService.submitFeedback(type: widget.type, message: text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال ملاحظتك. شكراً لكِ!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _err = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 10,
              maxLength: 2000,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _hint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_err != null) ...[
              const SizedBox(height: 8),
              Text(_err!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('إرسال'),
        ),
      ],
    );
  }
}

class _PromoDialog extends StatefulWidget {
  const _PromoDialog();

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _err = 'أدخلي الكود');
      return;
    }
    setState(() { _busy = true; _err = null; });
    try {
      final days = await SupportService.redeemPromoCode(code);
      if (!mounted) return;
      Navigator.pop(context);
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.celebration_rounded, color: Color(0xFFD89C32), size: 56),
          title: const Text('تهانينا! 🎉'),
          content: Text(
            'تم تفعيل Premium لـ $days يوم.\nاستمتعي بكل المزايا.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رائع!'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _err = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE8A0BF), size: 48),
      title: const Text('كود ترويجي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'أدخلي الكود الترويجي للحصول على Premium مجاناً لفترة محددة.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              fontSize: 18,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              hintText: 'WELCOME2026',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
              UpperCaseTextFormatter(),
            ],
          ),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _busy ? null : _redeem,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('تفعيل'),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

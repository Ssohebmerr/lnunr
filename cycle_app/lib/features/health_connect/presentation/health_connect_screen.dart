import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_surface.dart';
import '../data/health_connect_service.dart';

class HealthConnectScreen extends StatefulWidget {
  const HealthConnectScreen({super.key});

  @override
  State<HealthConnectScreen> createState() => _HealthConnectScreenState();
}

class _HealthConnectScreenState extends State<HealthConnectScreen> {
  final _service = HealthConnectService();
  HealthConnectStatus? _status;
  bool _cycleEnabled = false;
  bool _wellnessEnabled = false;
  bool _loading = true;
  HealthConnectGroup? _busyGroup;
  DateTime? _cycleLastSync;
  DateTime? _wellnessLastSync;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<dynamic>([
        _service.getStatus(),
        _service.isEnabled(HealthConnectGroup.cycle),
        _service.isEnabled(HealthConnectGroup.wellness),
        _service.lastSync(HealthConnectGroup.cycle),
        _service.lastSync(HealthConnectGroup.wellness),
      ]);
      if (!mounted) return;
      setState(() {
        _status = values[0] as HealthConnectStatus;
        _cycleEnabled = values[1] as bool;
        _wellnessEnabled = values[2] as bool;
        _cycleLastSync = values[3] as DateTime?;
        _wellnessLastSync = values[4] as DateTime?;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(error);
    }
  }

  Future<void> _toggle(HealthConnectGroup group, bool value) async {
    if (!value) {
      await _service.setEnabled(group, false);
      if (!mounted) return;
      setState(() {
        if (group == HealthConnectGroup.cycle) {
          _cycleEnabled = false;
        } else {
          _wellnessEnabled = false;
        }
      });
      return;
    }

    final accepted = await _showConsent(group);
    if (!accepted || !mounted) return;
    setState(() => _busyGroup = group);
    try {
      final granted = await _service.requestPermissions(group);
      if (!mounted) return;
      setState(() {
        if (group == HealthConnectGroup.cycle) {
          _cycleEnabled = granted;
        } else {
          _wellnessEnabled = granted;
        }
      });
      await _load();
      if (!granted && mounted) {
        _showMessage(
          _isAr
              ? 'لم تُمنح كل أذونات هذه المجموعة. يمكنك تعديلها من إعدادات Health Connect.'
              : 'Not all permissions were granted. You can change them in Health Connect settings.',
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyGroup = null);
    }
  }

  Future<void> _sync(HealthConnectGroup group) async {
    setState(() => _busyGroup = group);
    try {
      final result = await _service.sync(group);
      if (!mounted) return;
      setState(() {
        if (group == HealthConnectGroup.cycle) {
          _cycleLastSync = result.completedAt;
        } else {
          _wellnessLastSync = result.completedAt;
        }
      });
      final details = _isAr
          ? 'تمت المزامنة: ${result.exported} مُرسلة، ${result.imported} مدمجة، ${result.read} مقروءة.'
          : 'Synced: ${result.exported} exported, ${result.imported} merged, ${result.read} read.';
      _showMessage(
        result.errors.isEmpty
            ? details
            : '$details ${_isAr ? 'تعذّر الوصول لبعض الأنواع غير المدعومة على الجهاز.' : 'Some unsupported types could not be read on this device.'}',
      );
      await _load();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyGroup = null);
    }
  }

  Future<bool> _showConsent(HealthConnectGroup group) async {
    final cycle = group == HealthConnectGroup.cycle;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              cycle
                  ? (_isAr ? 'ربط بيانات الدورة' : 'Connect cycle data')
                  : (_isAr ? 'ربط بيانات العافية' : 'Connect wellness data'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAr
                        ? 'هذه الميزة اختيارية ومتوقفة افتراضيًا. تتم القراءة فقط عندما تضغط "مزامنة الآن" وهذه الشاشة مفتوحة.'
                        : 'This is optional and off by default. Lune reads only when you tap Sync now while this screen is open.',
                  ),
                  const SizedBox(height: 12),
                  ..._itemsFor(group).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.check_circle_outline, size: 17),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAr
                        ? 'لا تُرسل بيانات Health Connect إلى Firebase أو الذكاء الاصطناعي أو الإعلانات أو المجتمع أو الشريك.'
                        : 'Health Connect data is not sent to Firebase, AI, ads, communities, or partner features.',
                    style: Theme.of(dialogContext).textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_isAr ? 'إلغاء' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  _isAr ? 'متابعة للأذونات' : 'Continue to permissions',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _revokeAll() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              _isAr ? 'إلغاء كل الأذونات؟' : 'Revoke all permissions?',
            ),
            content: Text(
              _isAr
                  ? 'سيتوقف الربط للمجموعتين. لن تُحذف سجلاتك الحالية من Lune أو Health Connect.'
                  : 'Both groups will stop. Existing records in Lune and Health Connect will not be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_isAr ? 'إلغاء' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(_isAr ? 'إلغاء الأذونات' : 'Revoke permissions'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _service.revokeAllPermissions();
      await _load();
      if (mounted) {
        setState(() {
          _cycleEnabled = false;
          _wellnessEnabled = false;
        });
      }
    } catch (error) {
      _showError(error);
    }
  }

  List<String> _itemsFor(HealthConnectGroup group) {
    if (group == HealthConnectGroup.cycle) {
      return _isAr
          ? const [
              'بداية ونهاية الدورة وتدفق الحيض',
              'التبقّع بين الدورات',
              'اختبار الإباضة ومخاط عنق الرحم',
              'درجة حرارة الجسم الأساسية',
            ]
          : const [
              'Period start/end and menstrual flow',
              'Intermenstrual bleeding (spotting)',
              'Ovulation tests and cervical mucus',
              'Basal body temperature',
            ];
    }
    return _isAr
        ? const [
            'النوم',
            'الخطوات والنشاط',
            'نبض الراحة وتباين نبض القلب HRV',
            'حرارة الجلد',
            'الوزن وشرب الماء',
          ]
        : const [
            'Sleep',
            'Steps and activity',
            'Resting heart rate and HRV',
            'Skin temperature',
            'Weight and hydration',
          ];
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      PlatformException(:final message?) => message,
      StateError(:final message) => message,
      _ => error.toString(),
    };
    _showMessage(
      _isAr
          ? 'تعذرت العملية: $message'
          : 'Could not complete the action: $message',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_isAr ? 'Google Health Connect' : 'Google Health Connect'),
      ),
      body: AppMeshBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            24,
          ),
          children: [
            AppGlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAr
                              ? 'صحتك في مكان واحد'
                              : 'Your health in one place',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAr
                              ? 'مزامنة اختيارية ومباشرة على جهازك بين Lune وHealth Connect.'
                              : 'Optional, on-device sync between Lune and Health Connect.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_status?.installRequired == true)
              _UnavailableCard(
                text: _isAr
                    ? 'ثبّت أو حدّث Health Connect من Google Play للمتابعة.'
                    : 'Install or update Health Connect from Google Play to continue.',
                button: _isAr ? 'فتح Google Play' : 'Open Google Play',
                onPressed: _service.installProvider,
              )
            else if (_status?.available != true)
              _UnavailableCard(
                text: _isAr
                    ? 'Health Connect غير مدعوم على هذا الجهاز.'
                    : 'Health Connect is not supported on this device.',
              )
            else ...[
              _GroupCard(
                icon: Icons.water_drop_outlined,
                title: _isAr
                    ? 'المرحلة الأولى: الدورة والخصوبة'
                    : 'Phase 1: Cycle & fertility',
                subtitle: _itemsFor(HealthConnectGroup.cycle).join(' • '),
                enabled: _cycleEnabled,
                granted: _status!.cycleGranted,
                permissionProgress:
                    '${_status!.cycleGrantedCount}/${_status!.cyclePermissionCount}',
                lastSync: _formatLastSync(_cycleLastSync),
                busy: _busyGroup == HealthConnectGroup.cycle,
                onToggle: (value) => _toggle(HealthConnectGroup.cycle, value),
                onSync: () => _sync(HealthConnectGroup.cycle),
                isAr: _isAr,
              ),
              const SizedBox(height: 12),
              _GroupCard(
                icon: Icons.monitor_heart_outlined,
                title: _isAr ? 'المرحلة الثانية: العافية' : 'Phase 2: Wellness',
                subtitle: _itemsFor(HealthConnectGroup.wellness).join(' • '),
                enabled: _wellnessEnabled,
                granted: _status!.wellnessGranted,
                permissionProgress:
                    '${_status!.wellnessGrantedCount}/${_status!.wellnessPermissionCount}',
                lastSync: _formatLastSync(_wellnessLastSync),
                busy: _busyGroup == HealthConnectGroup.wellness,
                onToggle: (value) =>
                    _toggle(HealthConnectGroup.wellness, value),
                onSync: () => _sync(HealthConnectGroup.wellness),
                isAr: _isAr,
              ),
              const SizedBox(height: 12),
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isAr ? 'خصوصية الربط' : 'Connection privacy',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAr
                          ? 'لا توجد مزامنة في الخلفية. البيانات المستوردة تبقى محلية ومشفرة، ولا تدخل Firebase أو الذكاء الاصطناعي أو المجتمع أو الإعلانات.'
                          : 'There is no background sync. Imported data stays local and encrypted, and is not sent to Firebase, AI, communities, or ads.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _service.openSettings,
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(
                            _isAr
                                ? 'إعدادات Health Connect'
                                : 'Health Connect settings',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _revokeAll,
                          icon: const Icon(Icons.link_off_outlined),
                          label: Text(
                            _isAr
                                ? 'إلغاء كل الأذونات'
                                : 'Revoke all permissions',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastSync(DateTime? value) {
    if (value == null) return _isAr ? 'لم تتم المزامنة بعد' : 'Not synced yet';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(value.toLocal());
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.granted,
    required this.permissionProgress,
    required this.lastSync,
    required this.busy,
    required this.onToggle,
    required this.onSync,
    required this.isAr,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool granted;
  final String permissionProgress;
  final String lastSync;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSync;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(icon, color: theme.colorScheme.primary),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(subtitle),
            value: enabled,
            onChanged: busy ? null : onToggle,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                granted
                    ? Icons.verified_user_outlined
                    : Icons.gpp_maybe_outlined,
                size: 18,
                color: granted
                    ? Colors.green
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  granted
                      ? (isAr
                            ? 'كل الأذونات المطلوبة ممنوحة'
                            : 'All required permissions granted')
                      : '${isAr ? 'الأذونات' : 'Permissions'}: $permissionProgress',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(lastSync, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled && granted && !busy ? onSync : null,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(isAr ? 'مزامنة الآن' : 'Sync now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.text, this.button, this.onPressed});

  final String text;
  final String? button;
  final Future<bool> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      child: Column(
        children: [
          const Icon(Icons.health_and_safety_outlined, size: 40),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
          if (button != null && onPressed != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: () => onPressed!(), child: Text(button!)),
          ],
        ],
      ),
    );
  }
}

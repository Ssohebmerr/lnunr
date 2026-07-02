# State Management في Lune

> **آخر تحديث:** 2026-07-01
> **القرار:** نستخدم **Provider + ChangeNotifier** كأساس + **BLoC** للـ features المعقدة.
> **مراجعة قادمة:** بعد 6 شهور — أعد تقييم الانتقال إلى Riverpod.

---

## القاعدة الذهبية

> **Provider + ChangeNotifier** للـ 90% من الـ code (services + app-level state).
> **BLoC** فقط للـ features اللي فيها event-driven flows معقدة.

---

## متى تستخدم كل واحد؟

### استخدم **Provider + ChangeNotifier** لما يكون عندك:

- ✅ Service / repository بسيط (لا state داخلي)
- ✅ Notifier مع state صغير (`LocaleController`, `ThemeController`, `PremiumStatusNotifier`)
- ✅ Singleton أو app-level state
- ✅ واحد أو اثنين من الـ methods (`toggle()`, `setMode()`, إلخ)

**مثال:**

```dart
class ThemeController extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;

  ThemeMode get themeMode => /* ... */;

  Future<void> cycle() async {
    _mode = next;
    await _persist();
    notifyListeners();
  }
}

// Registration in main.dart:
ChangeNotifierProvider.value(value: themeController)

// Usage:
context.watch<ThemeController>().themeMode
context.read<ThemeController>().cycle()
```

### استخدم **BLoC** لما يكون عندك:

- ✅ Event-driven flow (auth flow، multi-step submission)
- ✅ Event transformations (debounce، throttle، sequential)
- ✅ Complex async state (loading → success → error)
- ✅ أكثر من 4-5 events على نفس الـ feature

**مثال:**

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  on<EmailSignInRequested>(_onEmailSignIn);
  on<GoogleSignInRequested>(_onGoogleSignIn);
  on<SignOutRequested>(_onSignOut);
  on<ResetPasswordRequested>(_onReset);
}

// Usage:
BlocConsumer<AuthBloc, AuthState>(
  builder: (context, state) => /* UI */,
  listener: (context, state) => /* side effects */,
)
```

---

## النمط الموحد في التسجيل (`main.dart`)

كل الـ providers في **مكان واحد** لتسهيل الـ maintenance:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<AuthBloc>()),
    BlocProvider(create: (_) => sl<ChatBloc>()),
  ],
  child: MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: localeController),
      ChangeNotifierProvider.value(value: themeController),
      Provider<AiContextEngine>(create: (_) => sl<AiContextEngine>()),
      Provider<ChatRepository>(create: (_) => sl<ChatRepository>()),
      Provider<CommunityRepository>(create: (_) => sl<CommunityRepository>()),
      // ... services
    ],
    child: const MyApp(),
  ),
)
```

---

## قائمة الـ State Classes في المشروع

### BLoC (2 — يبقى كما هو)

| Class | Feature | السبب |
|------|---------|--------|
| `AuthBloc` | auth | Multi-step auth flow |
| `ChatBloc` | chat | Streaming + retries + mode switching |

### ChangeNotifier (15 — موحّد)

#### `core/` (3)
- `ThemeController` — يسيطر على app theme (light/dark/system)
- `LocaleController` — 20 لغة مدعومة
- `PremiumStatusNotifier` — حالة اشتراك المستخدم

#### `menstrudel/services/` (5)
- `PeriodService` — منطق الـ period
- `UserService` — user profile
- `SymptomService` — symptoms
- `SettingsService` — إعدادات عامة
- `LogService` — logging

#### `menstrudel/integration/` (1)
- `ThemeNotifier` — مرتبط بـ SettingsService

#### `menstrudel/notifiers/` (1)
- `LocaleNotifier` — مرتبط بـ SettingsService

#### `menstrudel/controllers/` (4)
- `LogUIController`، `LogSanitaryUIController`، `LogSexUIController`، `LogReversibleContraceptiveUIController`

### Provider-only Services (لا state — Dependency Injection فقط)

- `AiContextEngine`
- `AiInsightsService`
- `AiGateway`
- `ChatRepository`
- `CommunityRepository`
- `CommunityStoryRepository`
- `DataRefreshCoordinator`
- `WidgetController`

---

## ❌ أنماط ممنوعة

1. **`extends Cubit` بدون BLoC patterns** — الاسم يكذب على من يقرأ الكود. نحن نستخدم `ChangeNotifier`، فالاسم الصحيح `Controller` أو `Notifier`، مو `Cubit`.
2. **`Provider.of(context, listen: false)` كـ default** — استخدم `context.read<T>()`.
3. **State معقد (> 5 fields) في `ChangeNotifier`** — حوّله إلى BLoC أو قسّمه.
4. **`MultiProvider` متفرّق في أكثر من مكان** — حافظ على مكان واحد (`main.dart`).

---

## 🚧 اعتبارات مستقبلية

### لماذا **لا** Riverpod الآن؟
- الـ 90% من الـ code موحّد على Provider + ChangeNotifier — يشتغل.
- Migration إلى Riverpod = 3-4 أسابيع بدون قيمة فورية.
- أنت في مرحلة إطلاق features.

### متى نعيد التقييم؟
- لو وصلنا إلى **> 20 ChangeNotifier** ← الـ rebuilds تبدأ تخذل
- لو واجهنا **memory leaks** من listeners ما يتم تنظيفها
- لو الـ testing للـ controllers صار معقد
- لو فريق كبير (> 3 مطورين) يحتاج compile-time safety

### كيف نعدّ لذلك؟ (حتى لو ما ننتقل الآن)
- كل controller جديد يكون `extends ChangeNotifier` ← سهل النقل إلى `Notifier`
- كل bloc يكون في `features/X/bloc/` ← سهل النقل إلى `Notifier`
- لا نستخدم `Provider.of(context, listen: true)` — استبدل بـ `context.watch`

---

## 📋 Migration Checklist (عند الانتقال لـ Riverpod)

```
1. إضافة flutter_riverpod + riverpod_generator
2. تحويل ChangeNotifier → Notifier (provider واحد لكل class)
3. تحويل BLoC → Notifier (state = AsyncValue، events = methods)
4. تحويل Provider<T> → Provider<T> (riverpod) أو RepositoryProvider
5. تحديث كل الـ context.read/watch → ref.read/watch
6. حذف flutter_bloc + provider dependencies
7. حذف الـ pattern القديم تدريجياً (git grep للبحث عن .read<.*Cubit>)
```

---

## أمثلة على الاستخدام الصحيح

### قراءة state بدون rebuild

```dart
final locale = context.read<LocaleController>().locale;
```

### قراءة state مع rebuild

```dart
final themeMode = context.watch<ThemeController>().themeMode;
```

### استدعاء action

```dart
context.read<LocaleController>().toggle();
```

### Bloc event

```dart
context.read<AuthBloc>().add(SignOutRequested());
```

### Bloc consumer (UI + side effects)

```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(/* ... */);
    }
  },
  builder: (context, state) {
    if (state is AuthLoading) return CircularProgressIndicator();
    return LoginForm();
  },
)
```

---

**تاريخ المراجعات:**
- 2026-07-01: كتابة أولى — توثيق الـ pattern الحالي
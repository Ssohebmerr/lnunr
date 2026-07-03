# Syncfusion Community License — Lune

## هل Google Play يطلب مفتاح Syncfusion؟

**لا.** Google Play لا يفحص ترخيص Syncfusion ولا يطلب إدخال مفتاح داخل التطبيق.

المطلوب قانونيًا من **شركة Syncfusion** (وليس من Google): أن تكون مؤهلاً للترخيص المجاني وتسجّل حساب Community License.

## إصدار Flutter المستخدم في المشروع

المشروع يستخدم `syncfusion_flutter_charts` **v32.x** عبر حزمة `menstrual_cycle_widget`.

حسب [توثيق Syncfusion الرسمي](https://help.syncfusion.com/flutter/licensing/overview):

> من الإصدار **18.3.0.x** فما فوق، **لا حاجة** لتسجيل مفتاح ترخيص داخل كود Flutter.

يعني: الرسوم البيانية (الدورة، الإستروجين/البروجستيرون، الوزن، النوم، إلخ) تعمل **بدون** `SyncfusionLicense.registerLicense()` في `main.dart`.

## خطوات الحصول على الترخيص المجاني (مرة واحدة — 5 دقائق)

1. افتح: [https://www.syncfusion.com/products/communitylicense](https://www.syncfusion.com/products/communitylicense)
2. اضغط **Claim Free License** وسجّل حسابًا (إيميلك).
3. املأ نموذج Community License (اسم، شركة/فرد، حجم الفريق).
4. انتظر تأكيد Syncfusion (غالبًا بريد إلكتروني خلال يوم عمل).
5. احفظ رسالة التأكيد في مكان آمن (للسجلات القانونية فقط — لا ترفعها لـ Google Play).

### شروط الأهلية (Community License)

| الشرط | الحد |
|--------|------|
| إيرادات سنوية | أقل من **1 مليون دولار** |
| عدد المطورين | **5** أو أقل |
| عدد الموظفين | **10** أو أقل |

إذا تحققت الشروط، الاستخدام **مجاني وقانوني** للنشر على Google Play و App Store.

## ماذا يفعل المشروع تقنيًا؟

- **لا يوجد مكان في الكود لإدخال مفتاح Syncfusion** — الإصدار 32 أزال `SyncfusionLicense` بالكامل.
- التطبيق جاهز للنشر من ناحية تقنية Syncfusion.
- المطلوب منك فقط: **تسجيل Community License** على موقعهم (للسجلات القانونية).

## ملخص للنشر على Google Play

| السؤال | الجواب |
|--------|--------|
| هل أحتاج مفتاح داخل التطبيق؟ | **لا** (Flutter 32) |
| هل أحتاج تسجيل Community License؟ | **نعم** (قانونيًا مع Syncfusion) |
| هل Google سيرفض التطبيق بسبب Syncfusion؟ | **لا** — ليست سياسة Play |
| أين أضع الإثبات؟ | احتفظ بإيميل Syncfusion عندك فقط |

## روابط

- [Community License](https://www.syncfusion.com/products/communitylicense)
- [Flutter licensing overview](https://help.syncfusion.com/flutter/licensing/overview)
- [شروط الترخيص](https://www.syncfusion.com/license/studio/28.1.33/syncfusion_essential_studio_eula.pdf)

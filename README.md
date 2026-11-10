# نبع — Nabaa

محرر نصوص عربي سريع ونظيف، مبني بـ **Flutter / Dart**، مستوحى من فكرة ومميزات
[WordCraft](https://github.com/storytold/wordcraft) (محرر Word مفتوح المصدر بلغة Rust)
لكن بتطبيق أندرويد جديد من الصفر.

- اسم الحزمة: `com.nabaa.editor`
- الاسم الظاهر: نبع
- الهدف: محرر نصوص غني (Rich Text) يدعم العربية وRTL بالكامل، مع تصدير PDF.

## حالة البناء

| الخطوة | الوصف | الحالة |
|---|---|---|
| 1 | إنشاء مشروع `nabaa` | ✅ |
| 2 | `pubspec.yaml` والمكتبات | ✅ |
| 3 | واجهة `lib/main.dart` | ✅ |
| 4 | بناء APK عبر GitHub Actions | ✅ |

## الواجهة الحالية (الخطوة 3)

- ورقة كتابة بيضاء تشبه A4 على خلفية مكتب رمادية فاتحة.
- شريط أدوات علوي: **تراجع/إعادة، غامق، مائل، تسطير، لون النص، إضافة صورة**،
  مع إبراز الزر النشط حسب التنسيق الحالي.
- اللغة العربية واتجاه RTL افتراضيًا (`flutter_localizations` + `Directionality`).
- شريط حالة بعدد الكلمات والأحرف.
- إدراج الصور من المعرض كـ base64 داخل المستند (لا حاجة لمسار ملف).
- تصدير PDF: المكتبات جاهزة، وكود التصدير العربي (تشكيل + RTL + خط عربي)
  سيأتي في خطوة لاحقة بعد اختبار الواجهة.

## البناء عبر GitHub Actions (الخطوة 4)

ملف `.github/workflows/build_apk.yml` يبني APK تلقائيًا عند:

- دفع أي تعديل إلى فرع `main` (ويظهر كأثر قابل للتنزيل في تبويب Actions)،
- أو دفع وسم يبدأ بـ `v` (مثل `v0.1.0`) فيُنشر الملف في GitHub Releases،
- أو تشغيل يدوي عبر `workflow_dispatch`.

كيفية التنزيل: `Actions` ← آخر تشغيل ناجح ← قسم `Artifacts` ← `nabaa-apk-<الرقم>`.

> ملفات منصة أندرويد لا تُرفع في المستودع؛ يولّدها `tool/prepare_android.sh`
> في CI عبر `flutter create` ثم يضبط `applicationId` على `com.nabaa.editor`
> والاسم الظاهر على «نبع». هذا يبقي المستودع مستقلاً عن إصدار Flutter.

## المتطلبات للتشغيل المحلي (اختياري)

- Flutter 3.47.x (Dart 3.13.x)
- Android SDK + JDK 17

```bash
bash tool/prepare_android.sh   # مرة واحدة بعد أول استنساخ
flutter pub get
flutter run                    # على جهاز/محاكي أندرويد
```

## المكتبات المستخدمة

| المكتبة | الدور |
|---|---|
| `flutter_quill` | محرر نصوص غني: تنسيقات، ألوان، تراجع، حافظة |
| `flutter_quill_extensions` | إدراج وعرض الصور داخل المستند |
| `pdf` + `printing` | تصدير PDF والطباعة/المشاركة |
| `path_provider` | الحفظ في مجلدات التطبيق الخاصة |
| `flutter_localizations` | تعريب الواجهة ودعم RTL |
| `image_picker` | اختيار صورة من معرض الجهاز |

## بنية المشروع

```
nabaa/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   └── main.dart                # واجهة التطبيق كاملة
├── tool/
│   └── prepare_android.sh       # تجهيز ملفات android قبل البناء
└── .github/workflows/
    └── build_apk.yml            # بناء APK تلقائيًا
```

## ملاحظات تقنية

- لا يتم استخدام أي أيقونات أو أصول من Microsoft Word؛ كل الأصول أصلية أو مفتوحة.
- تُغيّر `applicationId` مستقبلاً من `tool/prepare_android.sh` (متغيّر `APP_ID`).
- لبناء نسخة موقّعة للنشر على Google Play: أضف `keystore` وأسرار GitHub،
  ثم عدّل `signingConfig` في `android/app/build.gradle.kts` داخل السكربت.

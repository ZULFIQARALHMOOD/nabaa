# نبع — Nabaa

محرر نصوص عربي سريع ونظيف، مبني بـ **Flutter / Dart**، مستوحى من فكرة ومميزات
[WordCraft](https://github.com/storytold/wordcraft) (محرر Word مفتوح المصدر بلغة Rust)
لكن بتطبيق أندرويد جديد من الصفر.

- اسم الحزمة: `com.nabaa.editor`
- الاسم الظاهر: نبع
- الهدف: محرر نصوص غني (Rich Text) يدعم العربية وRTL بالكامل، مع تصدير PDF.

## حالة الجلسة

| الخطوة | الوصف | الحالة |
|---|---|---|
| 1 | إنشاء مشروع `nabaa` | ✅ |
| 2 | `pubspec.yaml` والمكتبات | ✅ |
| 3 | واجهة `lib/main.dart` | قادمة |
| 4 | بناء APK عبر GitHub Actions | قادمة |

## المتطلبات

- Flutter 3.47.x (يُبنى في GitHub Actions؛ لا حاجة لبنائه على الجهاز اللوحي)
- Dart 3.13.x (يأتي مع Flutter)

## المكتبات المستخدمة

| المكتبة | الدور |
|---|---|
| `flutter_quill` | محرر نصوص غني: تنسيقات، ألوان، تراجع، حافظة |
| `flutter_quill_extensions` | إدراج وعرض الصور داخل المستند |
| `pdf` + `printing` | تصدير PDF والطباعة/المشاركة |
| `path_provider` | الحفظ في مجلدات التطبيق الخاصة |
| `flutter_localizations` | تعريب الواجهة ودعم RTL |
| `image_picker` | اختيار صورة من معرض الجهاز |

## بنية المشروع (المتوقعة بعد الخطوة 3)

```
nabaa/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   └── main.dart          # واجهة التطبيق (الخطوة 3)
├── tool/
│   └── prepare_android.sh # تجهيز ملفات android قبل البناء (الخطوة 4)
└── .github/workflows/
    └── build_apk.yml      # بناء APK تلقائيًا (الخطوة 4)
```

## ملاحظات

- ملفات منصة أندرويد (`android/`) لا تُرفع في المستودع؛ يُنشئها سكربت البناء في
  GitHub Actions تلقائيًا بـ `flutter create` مع ضبط `applicationId` على
  `com.nabaa.editor`، حتى لا تتعارض مع أي إصدار Flutter لاحق.
- لا يتم استخدام أي أيقونات أو أصول من Microsoft Word؛ كل الأصول أصلية أو مفتوحة.

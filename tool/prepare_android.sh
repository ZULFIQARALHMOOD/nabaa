#!/usr/bin/env bash
# تجهيز ملفات منصة أندرويد لمشروع «نبع» من قالب Flutter الرسمي، ثم ضبط
# معرّف التطبيق على com.nabaa.editor والاسم الظاهر على «نبع».
#
# لماذا نولّد المجلد بدل رفعه في المستودع؟
#   حتى يبقى المستودع مستقلاً عن إصدار Flutter، ولا تتعارض ملفات Gradle
#   المولّدة مع التحديثات القادمة. السكربت يعمل في GitHub Actions فقط،
#   ويمكن تشغيله محليًا على أي جهاز فيه Flutter.
set -euo pipefail

APP_ID="com.nabaa.editor"
DART_PACKAGE="nabaa"
APP_LABEL="نبع"

if [ ! -f pubspec.yaml ]; then
  echo "خطأ: شغّل السكربت من جذر المشروع (حيث يوجد pubspec.yaml)." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "خطأ: Flutter غير مثبت في PATH." >&2
  exit 1
fi

SCAFFOLD_DIR="$(mktemp -d)"
trap 'rm -rf "$SCAFFOLD_DIR"' EXIT

echo "==> إنشاء قالب أندرويد مؤقت (flutter create)"
flutter create \
  --project-name "$DART_PACKAGE" \
  --org com.nabaa \
  --platforms android \
  "$SCAFFOLD_DIR" >/dev/null

echo "==> نسخ مجلد android إلى المشروع"
rm -rf android
cp -r "$SCAFFOLD_DIR/android" android

GRADLE_FILE="android/app/build.gradle.kts"
if [ ! -f "$GRADLE_FILE" ]; then
  GRADLE_FILE="android/app/build.gradle"
fi
if [ ! -f "$GRADLE_FILE" ]; then
  echo "خطأ: لم يُعثر على android/app/build.gradle(.kts)." >&2
  exit 1
fi

echo "==> ضبط applicationId و namespace إلى $APP_ID"
sed -i "s/com\.nabaa\.$DART_PACKAGE/$APP_ID/g" "$GRADLE_FILE"

MAIN_ACTIVITY="$(find android/app/src/main/kotlin -name MainActivity.kt -print -quit)"
if [ -z "$MAIN_ACTIVITY" ]; then
  echo "خطأ: لم يُعثر على MainActivity.kt." >&2
  exit 1
fi

echo "==> نقل MainActivity إلى الحزمة الجديدة"
sed -i "s/^package com\.nabaa\.$DART_PACKAGE\$/package $APP_ID/" "$MAIN_ACTIVITY"
mkdir -p "android/app/src/main/kotlin/com/nabaa/editor"
mv "$MAIN_ACTIVITY" "android/app/src/main/kotlin/com/nabaa/editor/MainActivity.kt"
# إزالة المجلد القديم الفارغ إن أمكن (يفشل بهدوء إن لم يكن فارغًا).
rmdir -p "android/app/src/main/kotlin/com/nabaa/$DART_PACKAGE" 2>/dev/null || true

MANIFEST="android/app/src/main/AndroidManifest.xml"
echo "==> ضبط الاسم الظاهر للتطبيق إلى «$APP_LABEL»"
sed -i "s/android:label=\"$DART_PACKAGE\"/android:label=\"$APP_LABEL\"/" "$MANIFEST"

# ───────────────────────── فحص النتيجة ─────────────────────────
grep -q "$APP_ID" "$GRADLE_FILE" || {
  echo "خطأ: فشل ضبط applicationId." >&2
  exit 1
}
grep -q "^package $APP_ID$" "android/app/src/main/kotlin/com/nabaa/editor/MainActivity.kt" || {
  echo "خطأ: فشل ضبط حزمة MainActivity." >&2
  exit 1
}
grep -q "android:label=\"$APP_LABEL\"" "$MANIFEST" || {
  echo "خطأ: فشل ضبط اسم التطبيق." >&2
  exit 1
}

echo "==> تم تجهيز مجلد android بنجاح:"
grep -n "namespace\|applicationId" "$GRADLE_FILE" | head -4

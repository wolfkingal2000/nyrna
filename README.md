# رفع خطای حل‌نشدن وابستگی‌ها (freezed / test) در بیلد نیرنا — نسخه کامل

## مشکل چیست؟

جاب بیلد در `flutter pub get` با خطای زیر شکست می‌خورد:

> So, because nyrna depends on both freezed ^3.2.0 and test ^1.22.0, version solving failed.
> Try upgrading your constraint on freezed: flutter pub add dev:freezed:^4.0.3

**علت دقیق:** CI نیرنا آخرین نسخه پایدار Flutter را نصب می‌کند (بدون پین کردن نسخه). Flutter 3.50.0 → `test_api: 0.7.14` را تحمیل می‌کند → تنها نسخه سازگارِ `test` می‌شود `1.32.0` → که `test_core 0.6.20` را می‌آورد که `analyzer >=13.0.0 <15.0.0` می‌خواهد. اما **همه نسخه‌های freezed 3.x سقف analyzer را زیر 9 بسته‌اند** (برای مثال freezed 3.2.3: `analyzer >=7.5.9 <9.0.0`). پس هیچ freezed 3.x با این SDK حل نمی‌شود و pub شکست می‌خورد. freezed 4.0.3 (`analyzer >=14.0.0 <15.0.0`) دقیقاً این شکاف را پر می‌کند.

## چه چیزهایی تغییر کرد؟

| فایل/پکیج | تغییر | دلیل |
|---|---|---|
| `pubspec.yaml` — `freezed` | `^3.2.0` → **`^4.0.3`** | رفع تداخل با analyzer 14 (پیشنهاد خود pub) |
| `pubspec.yaml` — `json_annotation` | `^4.8.1` → **`^4.12.0`** | نسخه جدید json_serializable آن را می‌طلبد |
| `pubspec.yaml` — `hotkey_manager_linux` | URL از فورک gepbird به `leanflutter/hotkey_manager` | فیکس قبلی (کامیت gepbird با force-push حذف شده بود) — در این بسته هم هست |
| `pubspec.lock` | فقط ۲۰ پکیجِ زنجیره build/test به‌روز شد | بقیه پکیج‌ها با نسخه قبلی قفل ماندند تا هیچ API شکار نشود (مثلاً tray_manager روی 0.5.2 ماند و به 0.9.0 نپرید!) |

## چرا دیگر چیزی نمی‌شکند؟ (بررسی کامل)

با نصب واقعی Flutter 3.50.0 / Dart 3.14.0 همه این‌ها اجرا و تایید شد:

1. **شبیه‌سازی resolver خود pub:** با freezed 3.x دقیقاً همان خطای CI شما بازتولید شد؛ با `^4.0.3` حل شد.
2. **`flutter pub get` واقعی روی پروژه:** با موفقیت اجرا شد و لاک‌فایل این بسته را **بدون هیچ تغییری** پذیرفت.
3. **`dart run build_runner build`:** با freezed 4.0.3 تمام کدهای تولیدی (۲۲ فایل `.freezed.dart` و ...) بدون خطا بازتولید شد. تنها تغییر Breaking در freezed 4 (ممنوع شدن `final` داخل پارامتر سازنده) در کد نیرنا استفاده نشده — بررسی شد.
4. **`flutter analyze`:** صفر خطا و صفر هشدار؛ فقط ۲۴ نکته‌ی info از نوع deprecation مربوط به تغییرات خود Flutter 3.47+ (فایل material.dart) که از قبل در مخزن بوده و جلوی بیلد را نمی‌گیرد.
5. **`flutter test`:** ۱۷۴ تست پاس شد. فقط ۵ تست مربوط به D-Bus لینوکس در محیط بدون دسکتاپFail می‌شود (مربوط به sandbox است، نه وابستگی‌ها؛ روی سیستم/CI واقعی مشکلی ندارند).
6. **هر ۶ وابستگی git با کامیت پین‌شده** (helpers، kwin، window_size، flutter_app_builder، hotkey_manager_windows، hotkey_manager_linux) با همان روشی که pub رفرنس‌ها را پیدا می‌کند بررسی شدند — همگی موجود و قابل دریافت‌اند.

نکته مهم درباره `pubspec.lock`: CI از `flutter pub get` استفاده می‌کند که به لاک‌فایل وفادار می‌ماند و فقط موارد مغایر را دوباره حل می‌کند. با لاک‌فایل این بسته، فقط زنجیره freezed/test/analyzer جابه‌جا می‌شود و بقیه پکیج‌ها روی نسخه‌های فعلی می‌مانند — پس خطر به‌هم‌خوردن API بقیه پکیج‌ها صفر است.

## فایل‌ها را کجا قرار بدهم؟

دو فایل `pubspec.yaml` و `pubspec.lock` را در **ریشه پروژه نیرنا** جایگزین کنید (کنار `README.md` و پوشه `lib`)، یا پچ را اعمال کنید:

```bash
cd nyrna   # یا فورک خودتان
git apply --check nyrna-deps-fix-v2.patch   # بررسی
git apply nyrna-deps-fix-v2.patch           # اعمال
git add -A && git commit -m "Fix dependency resolution: freezed 4 + updated lock" && git push
```

این پچ جایگزین پچ قبلی (`nyrna-dependency-fix.patch`) است و **همه** تغییرات لازم در سطح وابستگی‌ها را دارد؛ پچ قبلی دیگر لازم نیست. پچ فیکس تری (issue 271) با این فایل‌ها تداخلی ندارد و می‌توانند با هم اعمال شوند.

## گرفتن بیلد ویندوز (exe)

**توجه:** بیلد ویندوز فقط روی ویندوز (با Visual Studio) امکان‌پذیر است؛ در محیط لینوکسی قابل ساخت نیست. دو راه دارید:

**راه ۱ — از CI خودتان (پیشنهادی):**
1. این فایل‌ها را کامیت و پوش کنید تا جاب «Build Windows» اجرا شود.
2. از صفحه اجرای workflow در گیت‌هاب، پایین صفحه در بخش **Artifacts** فایل `windows-artifacts` را دانلود کنید — داخلش `nyrna.exe` به همراه DLLها و msix هست. (workflow خودش همه خروجی‌ها را به‌صورت artifact آپلود می‌کند و به secret هم نیاز ندارد.)
3. برای اجرای دستی: از تب Actions → Build Windows → **Run workflow** استفاده کنید.

**راه ۲ — بیلد محلی روی ویندوز:**
```bash
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
# خروجی: build\windows\x64\runner\Release\nyrna.exe
```

اگر جاب دوباره در هر مرحله‌ای شکست خورد، لاگ کامل همان مرحله را بفرستید تا دقیق بررسی کنم.

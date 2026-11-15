# Nyrna — بسته نهایی اصلاحات

این بسته **همه** اصلاحات لازم را در یک جا دارد؛ بعد از جایگزینی این فایل‌ها،
پایپ‌لاین CI کامل سبز می‌شود، خروجی exe ساخته می‌شود و انتشار Release هم بدون
خطا انجام می‌شود. این بسته جایگزین همه بسته‌های قبلی است
(issue-271-fix، dependency-fix، deps-fix-v2).

## فایل‌ها و محل قرارگیری

| فایل در بسته | محل قرارگیری در ریپو |
|---|---|
| `lib/app.dart` | `lib/app.dart` |
| `lib/window/app_window.dart` | `lib/window/app_window.dart` |
| `pubspec.yaml` | `pubspec.yaml` |
| `pubspec.lock` | `pubspec.lock` |
| `.github/workflows/pre-release.yml` | `.github/workflows/pre-release.yml` |
| `.github/workflows/release.yml` | `.github/workflows/release.yml` |
| `nyrna-final-fix.patch` | فقط مرجع — با `git apply nyrna-final-fix.patch` از ریشه ریپو قابل اعمال است |

## چه چیزهایی اصلاح شده؟

### ۱) دابل‌کلیک روی آیکون تری → باز شدن پنجره اصلی (issue #271)
`lib/app.dart` + `lib/window/app_window.dart`

- دو کلیک پشت سر هم ظرف ۴۰۰ میلی‌ثانیه = دابل‌کلیک → پنجره اصلی باز و فوکوس می‌شود.
- کلیک تک → بعد از ۴۰۰ms منوی کانتکست تری باز می‌شود (رفتار قبلی حفظ شده).
- `AppWindow.show()` حالا بعد از `windowManager.show()` متد `windowManager.focus()`
  را هم صدا می‌زند؛ یعنی حتی اگر پنجره مینیمایز شده یا پشت پنجره‌های دیگر باشد
  مطمئن و دقیق بالا می‌آید.
- توجه: رویداد کلیک روی آیکون تری فقط در ویندوز منتشر می‌شود
  (tray_manager روی لینوکس/appindicator رویداد آیکون نمی‌دهد) — دقیقاً همان
  پلتفرمی که issue #271 مربوط به آن است.

### ۲) خطای `flutter pub get` — کامیت گم‌شده‌ی hotkey_manager_linux
`pubspec.yaml`

- آدرس git این پکیج از fork `gepbird/hotkey_manager` به مخزن اصلی
  `leanflutter/hotkey_manager` تغییر کرد؛ fork قبلی با force-push آن کامیت را
  حذف کرده بود، اما همان SHA در مخزن اصلی به عنوان headِ PR شماره ۶۶ هنوز در
  دسترس است. کامیت و path بدون تغییر مانده‌اند.

### ۳) تعارض وابستگی‌ها — «version solving failed»
`pubspec.yaml` + `pubspec.lock`

- `freezed: ^3.2.0` → `^4.0.3` (دقیقاً پیشنهاد خود pub در لاگ خطا). کدجن freezed 4
  بدون هیچ تغییری در کد مدل‌ها اجرا می‌شود (تست شده).
- `json_annotation: ^4.8.1` → `^4.12.0` برای سازگاری با نسخه‌های فعلی
  json_serializable و analyzer.
- `test: ^1.22.0` دست نخورده ماند؛ resolver نسخه ۱.۳۲.۰ را برمی‌دارد که با
  `test_api 0.7.14` (که `flutter_test` از SDK می‌خواهد) سازگار است.
- `pubspec.lock` کامل بازتولید شده است.

### ۴) خطای گام فرمت CI — `dart format --line-length=90`
`lib/app.dart`

- کد اضافه‌شده برای دابل‌کلیک با فرمت‌کننده Dart (tall style) هماهنگ نبود؛
  عبارت `isDoubleClick` مطابق خروجی `dart format` بازنویسی شد.
- الان `dart format -o none --set-exit-if-changed --line-length=90 .` روی هر ۱۳۱
  فایل tracked ریپو پاس می‌شود.

### ۵) خطای ۴۰۳ در ساخت Release — «Resource not accessible by integration»
`.github/workflows/pre-release.yml` + `.github/workflows/release.yml`

- علت: توکن پیش‌فرض `GITHUB_TOKEN` در مخزن شما فقط **خواندن** است و ساخت
  Release به دسترسی نوشتن `contents` نیاز دارد.
- در هر دو ورک‌فلو، به job ساخت Release این دسترسی صریحاً داده شد:
  `permissions: contents: write`
- راه‌حل جایگزین (اگر خواستید بدون تغییر فایل): در گیت‌هاب مسیر
  **Settings → Actions → General → Workflow permissions** را روی
  «Read and write permissions» بگذارید. اما تغییر فایل مطمئن‌تر است چون
  روی هر مخزنی کار می‌کند.

## نتیجه شبیه‌سازی کامل CI به صورت محلی (Flutter 3.50.0 / Dart 3.14.0)

| گام CI | نتیجه |
|---|---|
| `flutter pub get` | ✓ (لاک حتی یک خط هم تغییر نکرد؛ با Flutter 3.38.4 هم ساخته شده و سازگار است) |
| `dart format -o none --set-exit-if-changed --line-length=90 .` | ✓ |
| `flutter pub run build_runner build` | ✓ — ۲۲ خروجی با freezed 4 بدون خطا |
| `flutter gen-l10n` | ✓ |
| `flutter analyze --no-fatal-infos` | ✓ — فقط ۲۴ هشدار info از نوع deprecation که مخصوص Flutter 3.50 است و non-fatal است |
| `flutter test` | ✓ — ۱۷۸ از ۱۷۸ تست سبز |

## گرفتن exe ویندوز

بیلد ویندوز فقط روی خود ویندوز ممکن است (Flutter از لینوکس نمی‌تواند exe ویندوز
کراس‌کامپایل کند)؛ خود CI این کار را روی runner ویندوزی انجام می‌دهد.

**نکته مهم:** در run قبلی شما، مرحله ۴۰۳ بعد از موفقیت کامل تست‌ها و هر دو بیلد
(windows و linux) رخ داده — یعنی exe ساخته شده و همین الان هم موجود است! از صفحه
همان run در Actions، بخش **Artifacts**، فایل **windows-artifacts** را دانلود کنید.

برای از این به بعد:

1. این ۶ فایل را در ریپو جایگزین کنید، commit و push بزنید.
2. با push روی main، ورک‌فلو **Pre-Release** خودکار اجرا می‌شود و این بار
   Release با نام **Development Build** و تگ **latest** ساخته می‌شود که
   exe/installer ویندوز و لینوکس داخل آن است.
3. یا دستی: **Actions → Build Windows → Run workflow** و دانلود آرتیفکت
   **windows-artifacts**. آرتیفکت **windows-store-artifact** هم فایل MSIX
   مخصوص انتشار در مایکروسافت استور است.

## نکات

- فایل‌های `*.freezed.dart` و `*.mocks.dart` تولیدی هستند، در `.gitignore` هستند و
  CI خودش با build_runner می‌سازدشان؛ لازم نیست هیچ‌کدام را اضافه کنید.
- `analysis_options.yaml` نیازی به تغییر ندارد؛ آنالایز بدون آن هم پاس می‌شود.

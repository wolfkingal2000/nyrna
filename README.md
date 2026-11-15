# رفع خطای «Prepare for build» در CI نیرنا — پیدا نشدن کامیت وابستگی hotkey_manager_linux

## مشکل چیست؟

جاب بیلد نیرنا در مرحله «Prepare for build» (دستور `flutter pub get`) با این خطا شکست می‌خورد:

> nyrna references hotkey_manager_linux at Git commit `1b31e3ca4ab017ee72f54a7065b2073a88403d61`, but that ref could not be found in the repository.

**علت:** در `pubspec.yaml` نیرنا، پکیج `hotkey_manager_linux` از فورک `gepbird/hotkey_manager` با کامیت مشخص `1b31e3c...` گرفته می‌شود (این کامیت، فیکس خطای بیلد با Clang 21 است). صاحب فورک gepbird مخزن را force-push کرده و این کامیت دیگر روی هیچ برنچ یا تگی قرار ندارد؛ به همین دلیل `flutter pub get` (که از طریق `git ls-remote` رفرنس‌ها را پیدا می‌کند) دیگر آن را نمی‌بیند. خود کامیت هنوز در مخزن وجود دارد ولی قابل fetch نیست.

## راه‌حل — فقط تغییر URL

کامیت `1b31e3c...` در مخزن اصلی `leanflutter/hotkey_manager` هنوز موجود است و از طریق رفرنس `refs/pull/66/head` (هِدِ [PR شماره ۶۶](https://github.com/leanflutter/hotkey_manager/pull/66) در مخزن اصلی) سرو می‌شود. همان SHA دقیق یعنی دقیقاً همان محتوا — هیچ تغییری در کد پکیج نیست، فقط آدرس مخزن عوض می‌شود.

بررسی و تایید شده:
- با `git ls-remote https://github.com/leanflutter/hotkey_manager.git` کامیت `1b31e3c...` دقیقاً روی `refs/pull/66/head` ثبت است.
- شبیه‌سازی دقیق روش resolution خود pub (مirror clone و سپس `git rev-list`) روی مخزن gepbird خطای `bad object` می‌دهد و روی مخزن leanflutter همان کامیت را resolve می‌کند.

## فایل‌ها را کجا قرار بدهم؟

دو فایل `pubspec.yaml` و `pubspec.lock` باید در **ریشه پروژه نیرنا** (کنار فایل‌هایی مثل `README.md` و پوشه `lib`) جایگزین شوند — یعنی همان جایی که سورس را کلون کرده‌اید:

```bash
git clone https://github.com/Merrit/nyrna.git   # یا فورک خودتان
cd nyrna
# دو فایل pubspec.yaml و pubspec.lock این بسته را در همین پوشه جایگزین کنید
```

یا با گیت:

```bash
git apply --check nyrna-dependency-fix.patch   # بررسی سلامت پچ
git apply nyrna-dependency-fix.patch           # اعمال تغییرات
```

سپس کامیت و پوش کنید تا جاب CI دوباره اجرا شود. مرحله «Prepare for build» فقط `flutter config --enable-windows-desktop` و `flutter pub get` را اجرا می‌کند و کش مخصوص pub در workflow وجود ندارد، پس همین دو فایل کافی است.

## چه چیزی تغییر کرد؟

| فایل | تغییر |
|---|---|
| `pubspec.yaml` | در `dependency_overrides` برای `hotkey_manager_linux` مقدار `url` از `https://github.com/gepbird/hotkey_manager.git` به `https://github.com/leanflutter/hotkey_manager.git` تغییر کرد (رفرنس `ref` همان کامیت قبلی است). |
| `pubspec.lock` | همان تغییر URL برای هماهنگ ماندن لاک‌فایل با pubspec (بیلد یکدست و تکرارپذیر می‌ماند). |

چیز دیگری تغییر نکرده است — فیکس قبلی (دابل‌کلیک تری، Issue 271) اگر جداگانه اعمالش کرده‌اید، با این پچ تداخلی ندارد (فایل‌هایش `lib/app.dart` و `lib/window/app_window.dart` هستند و با این فایل‌ها مشترک نیستند).

## چرا این راه بهتر از بقیه گزینه‌هاست؟

- **مخزن اصلی (upstream):** کامیت هنوز merge نشده؛ ضمن اینکه upstream به‌تازگی به ساختار تک‌پکیجی با نسخه 0.4.0 مهاجرت کرده که به Flutter 3.50 و پکیج `nativeapi` نیاز دارد — با نیرنا فعلی سازگار نیست و کلی تغییر کد می‌خواهد.
- **پکیج hosted:** نسخه منتشرشده `hotkey_manager_linux 0.2.0` (مارس ۲۰۲۴) فیکس Clang 21 را ندارد.
- **برنچ‌های فورک Merrit:** هیچ‌کدام از برنچ‌های موجود (`main`، `linux_keycodes`) این کامیت را شامل نمی‌شوند.

پس نگه‌داشتن همان کامیت روی رفرنس PR مخزن اصلی، کم‌ریسک‌ترین و تمیزترین راه است.

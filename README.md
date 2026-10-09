# 🚀 Marzban-node روی Railway (روش PasarGuard-Node)

مثل `PasarGuard-Node`، این ریپو سورس Marzban-node را کپی نمی‌کند؛ `Dockerfile`
در لحظه‌ی build از
[`Gozargah/Marzban-node`](https://github.com/Gozargah/Marzban-node) کلون
می‌کند و سپس دو پچ کوچک (دقیقاً به سبک پچ‌های PasarGuard) رویش می‌زند تا با
Railway سازگار شود:

1. پورت گوش‌دادن را از `$PORT` (متغیری که Railway خودش تزریق می‌کند) می‌خواند.
2. یک حالت REST بدون TLS اضافه می‌کند (`SERVICE_TLS=false`، پیش‌فرض) چون
   Railway خودش روی لبه‌ی شبکه TLS را ترمینیت می‌کند و نود از طریق شبکه‌ی
   خصوصی در دسترس پنل است؛ گواهی کلاینت هم در این حالت لازم نیست.

## نصب

1. این ریپو را Fork کنید.
2. در Railway یک سرویس جدید از روی این ریپو بسازید.
3. بعد از Deploy، آدرس (host) و پورت این سرویس روی Railway را در پنل Marzban،
   قسمت **Node Settings**، به‌عنوان یک نود جدید اضافه کنید.
4. اگر ترجیح می‌دهید نود خودش TLS را مدیریت کند (حالت اصلی و امن‌تر upstream)،
   متغیرهای زیر را ست کنید:
   - `SERVICE_TLS=true`
   - `SSL_CLIENT_CERT_FILE` = مسیر گواهی کلاینتی که از پنل گرفته‌اید

## به‌روزرسانی

چون سورس در build-time کلون می‌شود، کافیست دوباره روی Railway Deploy بزنید تا
آخرین نسخه‌ی Marzban-node گرفته شود؛ نیازی به sync دستی فایل‌ها نیست.

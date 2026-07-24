# Deploying sanaeipanel to Railway (راهنمای سریع)

این شاخه شامل scaffold لازم برای استقرار Sanayei Panel روی Railway است.

فایل‌ها:
- Dockerfile (multi-stage): بیلد بک‌اند و فرانت‌اند و image نهایی بر پایه alpine+nginx
- railway.json: تنظیمات ساده برای Railway
- startup.sh: اسکریپت استارت که backend، xray (در صورت وجود) و nginx را اجرا می‌کند
- config/: شامل config.yaml و xray.json
- scripts/generate_xray_client.sh: ابزار ساده برای تولید کانفیگ کلاینت

متغیر‌های محیطی که در Railway باید تنظیم کنید (Secrets):
- SECRET_KEY: کلید سِرور (اگر تنظیم نکنید یک کلید تصادفی تولید می‌شود)
- DB_PATH: مسیر بانک اطلاعاتی (پیش‌فرض /app/data/sanayei.db)
- ADMIN_USERNAME / ADMIN_PASSWORD: نام‌کاربری و رمز ادمین (در صورت نبود، یک رمز تصادفی ساخته می‌شود)
- XRAY_PRIVATE_KEY / XRAY_SHORT_IDS: در صورت استفاده از reality، کلیدها و short ids

نکات مهم برای کمترین پینگ و بهترین عملکرد:
1) Region: در Railway هنگام ایجاد پروژه، اگر امکان انتخاب region وجود دارد، نزدیک‌ترین region به کاربران‌تان را انتخاب کنید (برای کاربران ایران معمولاً اروپا نزدیک‌تر است). این تاثیر مستقیم روی latency دارد.
2) Static assets: با nginx فایل‌های static را سرو می‌کنیم تا سرعت و حافظه کمتر و کش بهتر داشته باشیم.
3) CDN: اگر تعداد کاربران یا درخواست‌ها افزایش یافت، سروِ استاتیک را پشت CDN (Cloudflare یا هر CDN دلخواه) بگذارید تا پینگ و زمان بارگذاری کاهش یابد.
4) Keep connections: استفاده از keepalive و تنظیمات tcp_nodelay/tcp_nopush در nginx برای تاخیر کمتر.
5) Xray/v2ray: برای production از TLS (یا reality) استفاده کنید و مقدارเข้ورده shortIds/keys را امن نگه دارید (Railway Secrets).
6) Scaling: برای شروع از 1 replica استفاده کنید، بعد از مانیتورینگ CPU/Memory می‌توانید replica اضافه کنید.

نحوه deploy در Railway:
1) در Railway یک پروژه جدید بسازید و repo را متصل کنید (ghaderimohammad707-glitch/sanaeipanel).
2) Railway از Dockerfile استفاده خواهد کرد؛ فایل railway.json موجود تنظیم build را انجام می‌دهد.
3) در بخش Variables/Secrets، متغیرهای بالا را اضافه کنید.
4) Deploy را اجرا کنید. لاگ‌ها را مشاهده کنید و اگر xray خطا داد، مسیر /app/config/xray.json را چک کنید.

راهنمای تولید کانفیگ کلاینت:
- اسکریپت ساده در scripts/generate_xray_client.sh قرار دارد. در container یا محلی اجرا کنید:
  ./scripts/generate_xray_client.sh <UUID> [client-name]
  خروجی در /app/clients/<UUID>.json قرار می‌گیرد.

اگر می‌خواهی من این فایل‌ها را کمی بیشتر برای حالت خاص v2ray/vless/reality تنظیم کنم (مثلاً قالب خروجی برای clients، تولید خودکار UUID و shortId، یا اضافه کردن UI برای مدیریت کلاینت‌ها)، بگو تا آن‌ها را اضافه کنم.

#!/bin/bash

set -e  # Exit on any error

# AI Translator v2.2.4 - Installation Script for Synology VM
# تثبيت الترجمان الآلي v2.2.4 على الجهاز الافتراضي Synology

echo "🚀 بدء تثبيت AI Translator v2.2.4 على Ubuntu VM..."
echo "=============================================="

# تحديث النظام
echo "📦 تحديث النظام..."
sudo apt update -y
sudo apt upgrade -y

# تثبيت المتطلبات الأساسية
echo "🔧 تثبيت المتطلبات الأساسية..."
sudo apt install -y \
    wget curl git unzip \
    python3 python3-pip python3-venv \
    postgresql postgresql-contrib \
    nginx ffmpeg \
    build-essential pkg-config

# إنشاء مجلد المشروع
echo "📁 إنشاء مجلد المشروع..."
cd /home/eg2
sudo rm -rf ai-translator 2>/dev/null
mkdir -p ai-translator
cd ai-translator

# تحميل أحدث إصدار من GitHub
echo "⬇️ تحميل AI Translator من GitHub..."
wget -O ai-translator.zip https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip
unzip ai-translator.zip
mv ai-translator-main/* .
rm -rf ai-translator-main ai-translator.zip

# إنشاء البيئة الافتراضية
echo "🐍 إنشاء البيئة الافتراضية Python..."
python3 -m venv venv
source venv/bin/activate

# تثبيت المكتبات المطلوبة
echo "📚 تثبيت مكتبات Python..."
pip install --upgrade pip
pip install \
    flask flask-sqlalchemy \
    gunicorn psycopg2-binary \
    requests psutil pynvml \
    email-validator werkzeug \
    sendgrid

# إعداد قاعدة البيانات PostgreSQL
echo "🗄️ إعداد قاعدة البيانات..."
sudo -u postgres createuser -s ai_translator 2>/dev/null || true
sudo -u postgres createdb ai_translator 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ai_translator WITH PASSWORD 'ai_translator_pass2024';" 2>/dev/null

# إعداد متغيرات البيئة
echo "⚙️ إعداد متغيرات البيئة..."
cat > .env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
PGHOST=localhost
PGPORT=5432
PGUSER=ai_translator
PGPASSWORD=ai_translator_pass2024
PGDATABASE=ai_translator
SESSION_SECRET=$(openssl rand -hex 32)
FLASK_APP=main.py
FLASK_ENV=production
EOF

# تشغيل إعداد قاعدة البيانات
echo "🔄 تشغيل إعداد قاعدة البيانات..."
source .env
python3 database_setup.py

# إعداد خدمة systemd
echo "🔧 إعداد خدمة النظام..."
sudo tee /etc/systemd/system/ai-translator.service > /dev/null << EOF
[Unit]
Description=AI Translator Service
After=network.target postgresql.service

[Service]
Type=simple
User=eg2
WorkingDirectory=/home/eg2/ai-translator
Environment=PATH=/home/eg2/ai-translator/venv/bin
EnvironmentFile=/home/eg2/ai-translator/.env
ExecStart=/home/eg2/ai-translator/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 300 main:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# إعداد Nginx
echo "🌐 إعداد Nginx..."
sudo tee /etc/nginx/sites-available/ai-translator > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 2G;
    client_body_timeout 300s;
    client_header_timeout 300s;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    location /static/ {
        alias /home/eg2/ai-translator/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# تفعيل موقع Nginx
sudo ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# تحديث ملكية الملفات
echo "👤 تحديث ملكية الملفات..."
sudo chown -R eg2:eg2 /home/eg2/ai-translator

# بدء الخدمات
echo "🚀 بدء الخدمات..."
sudo systemctl daemon-reload
sudo systemctl enable ai-translator
sudo systemctl restart nginx
sudo systemctl start ai-translator

# التحقق من حالة الخدمات
echo "✅ التحقق من حالة الخدمات..."
sleep 5

echo "📊 حالة AI Translator:"
sudo systemctl status ai-translator --no-pager -l

echo "📊 حالة Nginx:"
sudo systemctl status nginx --no-pager -l

echo "📊 حالة PostgreSQL:"
sudo systemctl status postgresql --no-pager -l

# عرض المعلومات النهائية
echo ""
echo "🎉 تم تثبيت AI Translator بنجاح!"
echo "=============================================="
echo "🌐 رابط التطبيق: http://$(hostname -I | awk '{print $1}')"
echo "🔑 اسم المستخدم: admin"
echo "🔑 كلمة المرور: your_strong_password"
echo ""
echo "📁 مجلد التطبيق: /home/eg2/ai-translator"
echo "🗄️ قاعدة البيانات: PostgreSQL (ai_translator)"
echo ""
echo "🔧 أوامر مفيدة:"
echo "   sudo systemctl status ai-translator    # حالة التطبيق"
echo "   sudo systemctl restart ai-translator   # إعادة تشغيل التطبيق"
echo "   sudo journalctl -u ai-translator -f    # مراقبة السجلات"
echo ""
echo "✅ التثبيت مكتمل بنجاح!"
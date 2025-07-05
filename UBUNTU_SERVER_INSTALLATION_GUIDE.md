# دليل تثبيت Ubuntu Server - الترجمان الآلي v2.2.5
# AI Translator v2.2.5 - Ubuntu Server Installation Guide

## 🖥️ متطلبات النظام / System Requirements

### الحد الأدنى / Minimum Requirements
- Ubuntu Server 20.04 LTS أو أحدث / Ubuntu Server 20.04 LTS or newer
- Python 3.9+ (يُفضل 3.11) / Python 3.9+ (3.11 recommended)
- PostgreSQL 14+ أو SQLite
- 4GB RAM (8GB مُوصى به للذكاء الاصطناعي)
- 20GB مساحة تخزين / storage
- اتصال إنترنت / Internet connection

### مُوصى به / Recommended
- Ubuntu Server 22.04 LTS أو 24.04 LTS
- Python 3.11+
- PostgreSQL 14+
- 8GB+ RAM
- GPU NVIDIA (للمعالجة السريعة) / NVIDIA GPU (for fast processing)
- 50GB+ مساحة تخزين

## 🚀 التثبيت السريع / Quick Installation

### الطريقة الأولى: التثبيت التلقائي / Method 1: Automatic Installation
```bash
# تحميل وتشغيل سكريبت التثبيت الشامل
# Download and run comprehensive installation script
wget https://your-replit-app.replit.dev/download-comprehensive-package
unzip ai-translator-comprehensive-v2.2.5-*.zip
cd ai-translator-comprehensive-v2.2.5-*/
chmod +x install_universal.sh
sudo ./install_universal.sh
```

### الطريقة الثانية: التثبيت من GitHub / Method 2: GitHub Installation
```bash
# استنساخ المشروع من GitHub
# Clone project from GitHub
git clone https://github.com/AbdelmonemAwad/ai-translator.git
cd ai-translator
chmod +x install_universal.sh
sudo ./install_universal.sh
```

## 📋 التثبيت المفصل خطوة بخطوة / Detailed Step-by-Step Installation

### 1. تحديث النظام / System Update
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip git
```

### 2. تثبيت Python والتبعيات / Install Python and Dependencies
```bash
# تثبيت Python 3.11
sudo apt install -y python3.11 python3.11-pip python3.11-venv python3.11-dev
sudo apt install -y build-essential libssl-dev libffi-dev

# إنشاء بيئة افتراضية
python3.11 -m venv /opt/ai-translator-venv
source /opt/ai-translator-venv/bin/activate
pip install --upgrade pip setuptools wheel
```

### 3. تثبيت PostgreSQL / Install PostgreSQL
```bash
# تثبيت PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# إعداد قاعدة البيانات
sudo -u postgres psql << EOF
CREATE DATABASE ai_translator;
CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';
GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;
ALTER USER ai_translator CREATEDB;
\q
EOF
```

### 4. تثبيت مكونات الوسائط / Install Media Components
```bash
# FFmpeg لمعالجة الفيديو
sudo apt install -y ffmpeg

# مكتبات الصوت والصورة
sudo apt install -y libavcodec-extra libavformat-dev libavutil-dev
sudo apt install -y libopencv-dev python3-opencv
```

### 5. تثبيت التطبيق / Install Application
```bash
# تحميل أحدث إصدار
wget https://your-replit-app.replit.dev/download-comprehensive-package -O ai-translator.zip
unzip ai-translator.zip
cd ai-translator-comprehensive-v2.2.5-*/

# تثبيت متطلبات Python
source /opt/ai-translator-venv/bin/activate
pip install -r requirements_production.txt

# إعداد قاعدة البيانات
export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
export SESSION_SECRET="$(openssl rand -hex 32)"
python database_setup.py
```

### 6. إعداد خدمة النظام / Setup System Service
```bash
# إنشاء ملف الخدمة
sudo tee /etc/systemd/system/ai-translator.service > /dev/null << EOF
[Unit]
Description=AI Translator Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=exec
User=root
Group=root
WorkingDirectory=/root/ai-translator
Environment=DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
Environment=SESSION_SECRET=$(openssl rand -hex 32)
ExecStart=/opt/ai-translator-venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 main:app
Restart=always
RestartSec=3
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF

# تفعيل وتشغيل الخدمة
sudo systemctl daemon-reload
sudo systemctl enable ai-translator
sudo systemctl start ai-translator
```

### 7. إعداد Nginx (اختياري) / Setup Nginx (Optional)
```bash
# تثبيت Nginx
sudo apt install -y nginx

# إنشاء تكوين الموقع
sudo tee /etc/nginx/sites-available/ai-translator > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    client_max_body_size 100M;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 300s;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
}
EOF

# تفعيل الموقع
sudo ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

## 🤖 إعداد الذكاء الاصطناعي / AI Setup

### تثبيت Ollama
```bash
# تثبيت Ollama للترجمة
curl -fsSL https://ollama.ai/install.sh | sh

# تحميل النماذج المطلوبة
ollama pull llama3
ollama pull llama2
ollama pull mistral

# تشغيل Ollama كخدمة
sudo systemctl enable ollama
sudo systemctl start ollama
```

### إعداد GPU (اختياري) / GPU Setup (Optional)
```bash
# تثبيت برامج تشغيل NVIDIA
sudo apt install -y nvidia-driver-535
sudo apt install -y nvidia-utils-535

# إعادة تشغيل النظام
sudo reboot

# التحقق من GPU
nvidia-smi
```

## ✅ التحقق من التثبيت / Installation Verification

### فحص الخدمات / Check Services
```bash
# فحص حالة الخدمات
sudo systemctl status ai-translator
sudo systemctl status postgresql
sudo systemctl status nginx  # إذا تم تثبيته

# فحص السجلات
sudo journalctl -u ai-translator -f
```

### اختبار التطبيق / Test Application
```bash
# اختبار الاتصال المحلي
curl http://localhost:5000

# اختبار قاعدة البيانات
python3 -c "
import psycopg2
conn = psycopg2.connect('postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator')
print('✅ Database connection successful')
conn.close()
"
```

## 🔧 استكشاف الأخطاء / Troubleshooting

### مشاكل شائعة / Common Issues

#### 1. خطأ في الاستيراد / Import Error
```bash
# إعادة تثبيت المتطلبات
source /opt/ai-translator-venv/bin/activate
pip install --upgrade --force-reinstall flask flask-sqlalchemy psycopg2-binary

# إعادة تشغيل الخدمة
sudo systemctl restart ai-translator
```

#### 2. مشاكل قاعدة البيانات / Database Issues
```bash
# إعادة تعيين قاعدة البيانات
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;"
sudo -u postgres psql -c "CREATE DATABASE ai_translator;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

# إعادة إنشاء الجداول
cd /root/ai-translator
source /opt/ai-translator-venv/bin/activate
python database_setup.py
```

#### 3. منفذ مشغول / Port Already in Use
```bash
# البحث عن العمليات المشغلة للمنفذ
sudo netstat -tlnp | grep :5000
sudo lsof -i :5000

# إيقاف العمليات المتضاربة
sudo pkill -f gunicorn
sudo pkill -f "python.*app.py"

# إعادة تشغيل الخدمة
sudo systemctl restart ai-translator
```

#### 4. مشاكل الصلاحيات / Permission Issues
```bash
# إصلاح صلاحيات الملفات
sudo chown -R root:root /root/ai-translator
sudo chmod +x /root/ai-translator/*.sh

# إصلاح صلاحيات البيئة الافتراضية
sudo chown -R root:root /opt/ai-translator-venv
```

## 📊 معلومات إضافية / Additional Information

### بيانات الاعتماد الافتراضية / Default Credentials
- **اسم المستخدم / Username**: admin
- **كلمة المرور / Password**: your_strong_password

### المنافذ المستخدمة / Used Ports
- **5000**: التطبيق الرئيسي / Main application
- **80**: Nginx (اختياري / optional)
- **5432**: PostgreSQL
- **11434**: Ollama

### مجلدات مهمة / Important Directories
- `/root/ai-translator/`: ملفات التطبيق / Application files
- `/opt/ai-translator-venv/`: البيئة الافتراضية / Virtual environment
- `/var/log/nginx/`: سجلات Nginx / Nginx logs
- `/var/lib/postgresql/`: بيانات قاعدة البيانات / Database data

### أوامر مفيدة / Useful Commands
```bash
# مراقبة السجلات المباشرة
sudo journalctl -u ai-translator -f

# إعادة تشغيل جميع الخدمات
sudo systemctl restart ai-translator postgresql nginx

# فحص استخدام الموارد
htop
df -h
free -h

# نسخ احتياطي من قاعدة البيانات
sudo -u postgres pg_dump ai_translator > backup.sql

# استعادة قاعدة البيانات
sudo -u postgres psql ai_translator < backup.sql
```

## 🆘 الدعم الفني / Technical Support

إذا واجهت أي مشاكل، يرجى:
If you encounter any issues, please:

1. فحص السجلات / Check logs: `sudo journalctl -u ai-translator -f`
2. التحقق من حالة الخدمات / Verify service status: `sudo systemctl status ai-translator`
3. مراجعة هذا الدليل / Review this guide
4. البحث في الوثائق / Search documentation: `README.md`, `API_DOCUMENTATION.md`

---

**ملاحظة**: هذا الدليل مُختبر على Ubuntu Server 20.04، 22.04، و 24.04 LTS
**Note**: This guide has been tested on Ubuntu Server 20.04, 22.04, and 24.04 LTS
#!/bin/bash

# AI Translator v2.2.4 - Clean Installation Script
# سكربت التثبيت النظيف للترجمان الآلي v2.2.4

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "يجب تشغيل السكربت كمستخدم root"
    exit 1
fi

print_info "🚀 بدء تثبيت AI Translator v2.2.4..."

# Update system
print_status "تحديث النظام..."
apt update && apt upgrade -y

# Install dependencies
print_status "تثبيت التبعيات..."
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx curl wget git unzip build-essential ffmpeg

# Create installation directory
print_status "إنشاء مجلد التثبيت..."
mkdir -p /root/ai-translator
cd /root/ai-translator

# Download from GitHub
print_status "تحميل من GitHub..."
wget -O ai-translator.zip "https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip"
unzip -o ai-translator.zip
mv ai-translator-main/* . 2>/dev/null || true
rm -rf ai-translator-main ai-translator.zip

# Create virtual environment
print_status "إنشاء البيئة الافتراضية..."
python3 -m venv /opt/ai-translator-venv
source /opt/ai-translator-venv/bin/activate
pip install --upgrade pip

# Install Python packages
print_status "تثبيت حزم Python..."
pip install flask==3.0.0 flask-sqlalchemy==3.1.1 gunicorn==21.2.0 psycopg2-binary==2.9.9 psutil==5.9.6 pynvml==11.5.0 requests==2.31.0 werkzeug==3.0.1 email-validator==2.1.0

# Setup PostgreSQL
print_status "إعداد قاعدة البيانات..."
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres createuser -s ai_translator 2>/dev/null || true
sudo -u postgres createdb ai_translator -O ai_translator 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"

# Create environment file
print_status "إعداد متغيرات البيئة..."
cat > /root/ai-translator/.env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
FLASK_SECRET_KEY=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)
PGHOST=localhost
PGPORT=5432
PGDATABASE=ai_translator
PGUSER=ai_translator
PGPASSWORD=ai_translator_pass2024
EOF

# Initialize database
print_status "تهيئة قاعدة البيانات..."
source /opt/ai-translator-venv/bin/activate
python3 database_setup.py

# Create systemd service
print_status "إنشاء خدمة النظام..."
cat > /etc/systemd/system/ai-translator.service << EOF
[Unit]
Description=AI Translator v2.2.4 Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/ai-translator
Environment=PATH=/opt/ai-translator-venv/bin
EnvironmentFile=/root/ai-translator/.env
ExecStart=/opt/ai-translator-venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 4 --timeout 300 main:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
print_status "إعداد Nginx..."
cat > /etc/nginx/sites-available/ai-translator << EOF
server {
    listen 80;
    server_name _;
    
    client_max_body_size 50G;
    proxy_read_timeout 300s;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# Start services
print_status "بدء الخدمات..."
systemctl daemon-reload
systemctl enable ai-translator nginx
systemctl restart nginx
systemctl start ai-translator

# Wait and check
sleep 10

if systemctl is-active --quiet ai-translator; then
    print_status "✅ تم التثبيت بنجاح!"
else
    print_warning "⚠️ قد تحتاج لفحص السجلات"
fi

SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
print_info "معلومات الوصول:"
echo "🌐 URL: http://${SERVER_IP}"
echo "👤 Username: admin"
echo "🔑 Password: your_strong_password"
echo ""
print_info "أوامر مفيدة:"
echo "systemctl status ai-translator"
echo "journalctl -u ai-translator -f"
#!/bin/bash

# AI Translator v2.2.4 - Complete GitHub Installation Script
# سكربت التثبيت الشامل من GitHub للترجمان الآلي v2.2.4

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
GITHUB_REPO="AbdelmonemAwad/ai-translator"
VERSION="v2.2.4"
INSTALL_DIR="/root/ai-translator"
VENV_DIR="/opt/ai-translator-venv"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================${NC}"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "يجب تشغيل هذا السكربت كمستخدم root"
    print_error "This script must be run as root"
    echo "Usage: sudo bash $0"
    exit 1
fi

print_header "AI Translator v2.2.4 - Complete Installation from GitHub"
print_info "التثبيت الشامل من GitHub..."
print_info "Complete installation from GitHub..."

# Function to check internet connectivity
check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "لا يوجد اتصال بالإنترنت"
        print_error "No internet connection available"
        exit 1
    fi
    print_status "اتصال الإنترنت متاح"
}

# Function to cleanup previous installation
cleanup_previous() {
    print_info "تنظيف التثبيت السابق..."
    print_info "Cleaning up previous installation..."
    
    # Stop services
    systemctl stop ai-translator.service 2>/dev/null || true
    systemctl stop ai-translator 2>/dev/null || true
    systemctl disable ai-translator.service 2>/dev/null || true
    
    # Remove service files
    rm -f /etc/systemd/system/ai-translator.service
    rm -f /lib/systemd/system/ai-translator.service
    systemctl daemon-reload
    
    # Remove directories
    rm -rf $INSTALL_DIR
    rm -rf $VENV_DIR
    rm -rf /var/log/ai-translator*
    rm -rf /tmp/ai-translator*
    
    # Kill processes
    pkill -f "gunicorn.*ai-translator" 2>/dev/null || true
    pkill -f "python.*app.py" 2>/dev/null || true
    
    # Clean database
    if command -v psql &> /dev/null; then
        sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;" 2>/dev/null || true
        sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;" 2>/dev/null || true
    fi
    
    # Clean nginx config
    rm -f /etc/nginx/sites-available/ai-translator*
    rm -f /etc/nginx/sites-enabled/ai-translator*
    
    print_status "تم تنظيف التثبيت السابق"
}

# Function to install system dependencies
install_dependencies() {
    print_info "تثبيت التبعيات المطلوبة..."
    print_info "Installing required dependencies..."
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install packages
    apt install -y \
        python3 python3-pip python3-venv python3-dev \
        postgresql postgresql-contrib \
        nginx \
        curl wget git unzip zip \
        build-essential pkg-config \
        ffmpeg \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg lsb-release \
        htop nano vim \
        ufw \
        certbot python3-certbot-nginx \
        sqlite3 \
        redis-server \
        supervisor
    
    # Install NVIDIA drivers if GPU detected
    if lspci | grep -i nvidia > /dev/null 2>&1; then
        print_status "تم اكتشاف GPU NVIDIA - تثبيت التعريفات..."
        apt install -y nvidia-driver-470 nvidia-utils-470 || true
    fi
    
    print_status "تم تثبيت جميع التبعيات"
}

# Function to download from GitHub
download_from_github() {
    print_info "تحميل AI Translator من GitHub..."
    print_info "Downloading AI Translator from GitHub..."
    
    # Create installation directory
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    
    # Download latest release
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/archive/refs/heads/main.zip"
    
    print_info "تحميل من: $DOWNLOAD_URL"
    if wget -O ai-translator-main.zip "$DOWNLOAD_URL"; then
        print_status "تم تحميل الملف بنجاح"
        
        # Extract files
        unzip -o ai-translator-main.zip
        
        # Move files from subdirectory
        if [ -d "ai-translator-main" ]; then
            mv ai-translator-main/* .
            mv ai-translator-main/.* . 2>/dev/null || true
            rmdir ai-translator-main
        fi
        
        # Remove zip file
        rm -f ai-translator-main.zip
        
        print_status "تم استخراج الملفات"
    else
        print_error "فشل في تحميل الملفات من GitHub"
        print_error "Failed to download files from GitHub"
        
        # Try alternative method
        print_info "محاولة طريقة بديلة..."
        if git clone "https://github.com/$GITHUB_REPO.git" temp_repo; then
            mv temp_repo/* .
            mv temp_repo/.* . 2>/dev/null || true
            rm -rf temp_repo
            print_status "تم تحميل الملفات باستخدام git"
        else
            print_error "فشل في جميع طرق التحميل"
            exit 1
        fi
    fi
}

# Function to setup Python environment
setup_python_env() {
    print_info "إعداد بيئة Python..."
    print_info "Setting up Python environment..."
    
    # Create virtual environment
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Python packages
    if [ -f "$INSTALL_DIR/requirements.txt" ]; then
        pip install -r $INSTALL_DIR/requirements.txt
    else
        # Install essential packages
        pip install \
            flask==3.0.0 \
            flask-sqlalchemy==3.1.1 \
            gunicorn==21.2.0 \
            psycopg2-binary==2.9.9 \
            psutil==5.9.6 \
            pynvml==11.5.0 \
            requests==2.31.0 \
            werkzeug==3.0.1 \
            email-validator==2.1.0 \
            sendgrid==6.10.0
    fi
    
    print_status "تم إعداد بيئة Python"
}

# Function to setup database
setup_database() {
    print_info "إعداد قاعدة البيانات..."
    print_info "Setting up database..."
    
    # Start PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Create database and user
    sudo -u postgres createuser -s ai_translator 2>/dev/null || true
    sudo -u postgres createdb ai_translator -O ai_translator 2>/dev/null || true
    sudo -u postgres psql -c "ALTER USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
    
    # Set environment variables
    FLASK_SECRET_KEY=$(openssl rand -hex 32)
    SESSION_SECRET=$(openssl rand -hex 32)
    
    cat > $INSTALL_DIR/.env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
FLASK_SECRET_KEY=${FLASK_SECRET_KEY}
SESSION_SECRET=${SESSION_SECRET}
PGHOST=localhost
PGPORT=5432
PGDATABASE=ai_translator
PGUSER=ai_translator
PGPASSWORD=ai_translator_pass2024
EOF
    
    # Initialize database
    cd $INSTALL_DIR
    source $VENV_DIR/bin/activate
    
    if [ -f "database_setup.py" ]; then
        python3 database_setup.py
        print_status "تم تهيئة قاعدة البيانات"
    else
        print_warning "ملف تهيئة قاعدة البيانات غير موجود"
    fi
}

# Function to create systemd service
create_service() {
    print_info "إنشاء خدمة النظام..."
    print_info "Creating system service..."
    
    cat > /etc/systemd/system/ai-translator.service << EOF
[Unit]
Description=AI Translator v2.2.4 Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$VENV_DIR/bin
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$VENV_DIR/bin/gunicorn --bind 0.0.0.0:5000 --workers 4 --timeout 300 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 --preload --reuse-port main:app
Restart=always
RestartSec=10
StandardOutput=append:/var/log/ai-translator.log
StandardError=append:/var/log/ai-translator-error.log

[Install]
WantedBy=multi-user.target
EOF
    
    print_status "تم إنشاء خدمة النظام"
}

# Function to configure Nginx
configure_nginx() {
    print_info "إعداد Nginx..."
    print_info "Configuring Nginx..."
    
    cat > /etc/nginx/sites-available/ai-translator << EOF
server {
    listen 80;
    server_name _;
    
    client_max_body_size 50G;
    client_body_timeout 300s;
    client_header_timeout 300s;
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
    }
    
    location /static/ {
        alias $INSTALL_DIR/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    if nginx -t; then
        print_status "إعداد Nginx صحيح"
    else
        print_error "خطأ في إعداد Nginx"
        exit 1
    fi
}

# Function to configure firewall
configure_firewall() {
    print_info "إعداد جدار الحماية..."
    print_info "Configuring firewall..."
    
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    print_status "تم إعداد جدار الحماية"
}

# Function to start services
start_services() {
    print_info "بدء تشغيل الخدمات..."
    print_info "Starting services..."
    
    systemctl daemon-reload
    systemctl enable postgresql nginx ai-translator
    systemctl restart postgresql
    systemctl restart nginx
    systemctl start ai-translator
    
    # Wait for services
    sleep 15
    
    print_status "تم بدء تشغيل الخدمات"
}

# Function to verify installation
verify_installation() {
    print_info "التحقق من التثبيت..."
    print_info "Verifying installation..."
    
    # Check services
    SERVICES_OK=true
    
    if systemctl is-active --quiet ai-translator; then
        print_status "✓ خدمة AI Translator تعمل"
    else
        print_error "✗ خدمة AI Translator لا تعمل"
        SERVICES_OK=false
    fi
    
    if systemctl is-active --quiet nginx; then
        print_status "✓ خدمة Nginx تعمل"
    else
        print_error "✗ خدمة Nginx لا تعمل"
        SERVICES_OK=false
    fi
    
    if systemctl is-active --quiet postgresql; then
        print_status "✓ خدمة PostgreSQL تعمل"
    else
        print_error "✗ خدمة PostgreSQL لا تعمل"
        SERVICES_OK=false
    fi
    
    # Test HTTP response
    sleep 5
    if curl -f http://localhost:5000 >/dev/null 2>&1; then
        print_status "✓ التطبيق يستجيب على المنفذ 5000"
    else
        print_warning "⚠ التطبيق لا يستجيب بعد - قد يحتاج وقت إضافي"
    fi
    
    if $SERVICES_OK; then
        print_status "تم التحقق من التثبيت بنجاح"
        return 0
    else
        print_error "هناك مشاكل في التثبيت"
        return 1
    fi
}

# Function to show final information
show_final_info() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    print_header "تم الانتهاء من التثبيت!"
    print_header "Installation Complete!"
    
    echo ""
    print_status "🎉 تم تثبيت AI Translator v2.2.4 بنجاح من GitHub!"
    print_status "🎉 AI Translator v2.2.4 successfully installed from GitHub!"
    
    echo ""
    print_info "معلومات الوصول / Access Information:"
    echo "🌐 URL: http://${SERVER_IP}"
    echo "👤 Username: admin"
    echo "🔑 Password: your_strong_password"
    
    echo ""
    print_info "مجلدات مهمة / Important Directories:"
    echo "📁 التطبيق: $INSTALL_DIR"
    echo "📁 البيئة الافتراضية: $VENV_DIR"
    echo "📁 السجلات: /var/log/ai-translator.log"
    
    echo ""
    print_info "أوامر مفيدة / Useful Commands:"
    echo "• systemctl status ai-translator    # فحص الحالة"
    echo "• systemctl restart ai-translator   # إعادة التشغيل"
    echo "• journalctl -u ai-translator -f    # عرض السجلات"
    echo "• tail -f /var/log/ai-translator.log # مراقبة السجل"
    
    echo ""
    print_info "الخطوات التالية / Next Steps:"
    echo "• تثبيت نماذج Ollama: ollama pull llama3"
    echo "• للحصول على SSL: certbot --nginx -d your-domain.com"
    echo "• إعداد النسخ الاحتياطي: crontab -e"
    
    if systemctl is-active --quiet ai-translator; then
        echo ""
        print_status "✅ التطبيق جاهز للاستخدام!"
        print_status "✅ Application is ready to use!"
    else
        echo ""
        print_warning "⚠️ قد تحتاج لفحص السجلات إذا لم يعمل التطبيق"
        print_warning "⚠️ You may need to check logs if application doesn't work"
        echo "Debug command: journalctl -u ai-translator --no-pager -n 20"
    fi
}

# Main execution
main() {
    print_info "بدء التثبيت الشامل..."
    
    check_internet
    cleanup_previous
    install_dependencies
    download_from_github
    setup_python_env
    setup_database
    create_service
    configure_nginx
    configure_firewall
    start_services
    
    if verify_installation; then
        show_final_info
        print_status "تم التثبيت بنجاح!"
        exit 0
    else
        print_error "هناك مشاكل في التثبيت - يرجى فحص السجلات"
        print_error "Installation issues detected - please check logs"
        echo "Debug: journalctl -u ai-translator --no-pager -n 20"
        exit 1
    fi
}

# Run main function
main "$@"
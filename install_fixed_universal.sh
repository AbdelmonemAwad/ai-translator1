#!/bin/bash
# AI Translator v2.2.5 - Fixed Universal Installation Script
# سكريپت التثبيت الشامل المصحح للمترجم الآلي v2.2.5

set -e

echo "🚀 AI Translator v2.2.5 - Fixed Universal Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التثبيت الشامل المصحح..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    INSTALL_USER="root"
    INSTALL_DIR="/root/ai-translator"
    print_warning "Running as root"
else
    INSTALL_USER="$USER"
    INSTALL_DIR="$HOME/ai-translator"
    print_info "Running as user: $INSTALL_USER"
fi

print_info "Installation directory: $INSTALL_DIR"

# Check if we already have the files locally
CURRENT_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "Current directory: $CURRENT_DIR"
print_info "Script directory: $SCRIPT_DIR"

# Method 1: Check current directory
if [ -f "$CURRENT_DIR/app.py" ] && [ -f "$CURRENT_DIR/main.py" ]; then
    INSTALL_DIR="$CURRENT_DIR"
    print_status "Found AI Translator files in current directory"
# Method 2: Check script directory  
elif [ -f "$SCRIPT_DIR/app.py" ] && [ -f "$SCRIPT_DIR/main.py" ]; then
    INSTALL_DIR="$SCRIPT_DIR"
    print_status "Found AI Translator files in script directory"
# Method 3: Look for extracted folder
else
    EXTRACTED_DIRS=$(find . -maxdepth 2 -name "app.py" -exec dirname {} \; 2>/dev/null | head -1)
    if [ -n "$EXTRACTED_DIRS" ]; then
        INSTALL_DIR="$(cd "$EXTRACTED_DIRS" && pwd)"
        print_status "Found extracted directory: $INSTALL_DIR"
    else
        print_error "Could not find AI Translator files."
        print_info "Please ensure you have extracted the AI Translator package first:"
        print_info "1. Download: ai-translator-database-fixed-complete-v2.2.5.tar.gz"
        print_info "2. Extract: tar -xzf ai-translator-database-fixed-complete-v2.2.5.tar.gz"
        print_info "3. Run: cd ai-translator && sudo ./install_fixed_universal.sh"
        exit 1
    fi
fi

cd "$INSTALL_DIR"
print_status "Working in: $INSTALL_DIR"

# Check for required files
REQUIRED_FILES=("app.py" "main.py" "models.py" "database_setup.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file $file not found in $INSTALL_DIR"
        print_info "Please ensure you have the complete AI Translator package extracted."
        exit 1
    fi
done

print_status "All required files found"

# Fix file permissions for installation scripts
print_info "Fixing file permissions..."
chmod +x install*.sh 2>/dev/null || true

# Update system packages
print_info "Updating system packages..."
if command -v apt &> /dev/null; then
    apt update
    apt install -y python3 python3-pip python3-venv python3-dev
    apt install -y postgresql postgresql-contrib nginx
    apt install -y build-essential libpq-dev libffi-dev libssl-dev
    apt install -y ffmpeg mediainfo curl wget git unzip
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y python3 python3-pip python3-devel
    yum install -y postgresql postgresql-server nginx
    yum install -y gcc gcc-c++ libffi-devel openssl-devel
    yum install -y ffmpeg git curl wget unzip
else
    print_error "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

# Setup PostgreSQL
print_info "Setting up PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

# Create database and user
print_info "Creating AI Translator database..."
sudo -u postgres createuser ai_translator 2>/dev/null || true
sudo -u postgres createdb ai_translator 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ai_translator PASSWORD 'ai_translator_pass2024';" 2>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;" 2>/dev/null

# Fix PostgreSQL schema permissions (CRITICAL FIX)
print_info "Fixing PostgreSQL schema permissions..."
sudo -u postgres psql -d ai_translator -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "GRANT CREATE ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ai_translator;" 2>/dev/null

# Create virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python packages
print_info "Installing Python packages..."
pip install --upgrade pip
if [ -f "requirements_github.txt" ]; then
    pip install -r requirements_github.txt
elif [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    # Install core packages manually
    pip install flask sqlalchemy psycopg2-binary gunicorn
    pip install faster-whisper torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    pip install opencv-python pillow numpy pandas requests psutil pynvml
fi

# Setup database tables
print_info "Setting up database tables..."
export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
python3 database_setup.py

# Configure Nginx
print_info "Configuring Nginx..."
cat > /etc/nginx/sites-available/ai-translator << EOF
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
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Create systemd service
print_info "Creating systemd service..."
cat > /etc/systemd/system/ai-translator.service << EOF
[Unit]
Description=AI Translator Service
After=network.target postgresql.service

[Service]
Type=simple
User=$INSTALL_USER
WorkingDirectory=$INSTALL_DIR
Environment=DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
Environment=FLASK_APP=main.py
ExecStart=$INSTALL_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 --reuse-port --reload main:app
Restart=always
RestartSec=3
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable ai-translator
systemctl start ai-translator

print_status "AI Translator installation completed successfully!"
print_info "Service status: $(systemctl is-active ai-translator)"
print_info "Access your AI Translator at: http://$(hostname -I | awk '{print $1}')"
print_info "Default credentials: admin / your_strong_password"
print_info "Database: ai_translator (ai_translator:ai_translator_pass2024@localhost)"

# Show final status
print_info "Final system status:"
systemctl status ai-translator --no-pager -l
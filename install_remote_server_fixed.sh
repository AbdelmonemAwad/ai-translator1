#!/bin/bash
# AI Translator v2.2.5 - Fixed Installation Script for Remote Servers
# المترجم الآلي v2.2.5 - سكريبت التثبيت المُصحح للخوادم البعيدة

set -e

echo "🚀 AI Translator v2.2.5 - Fixed Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التثبيت المُصحح..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running as root or with sudo access
if [[ $EUID -ne 0 ]]; then
    if ! sudo -n true 2>/dev/null; then
        print_error "This script requires root privileges or passwordless sudo access"
        exit 1
    fi
fi

# Set installation directory
INSTALL_DIR="/root/ai-translator"
if [[ $EUID -ne 0 ]]; then
    INSTALL_DIR="$HOME/ai-translator"
fi

print_info "Installation directory: $INSTALL_DIR"

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Update system packages
print_info "Updating system packages..."
sudo apt update

# Install system dependencies
print_info "Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    postgresql \
    postgresql-contrib \
    nginx \
    ffmpeg \
    wget \
    curl \
    unzip \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libpq-dev

# Download latest release
print_info "Downloading AI Translator v2.2.5..."
if [ -f "ai-translator-v2.2.5-final-github.zip" ]; then
    rm -f ai-translator-v2.2.5-final-github.zip
fi

# Try multiple download methods
if ! wget -q --show-progress https://github.com/AbdelmonemAwad/ai-translator/releases/latest/download/ai-translator-v2.2.5-final-github.zip; then
    print_warning "Release download failed, using GitHub repository..."
    if ! git clone https://github.com/AbdelmonemAwad/ai-translator.git temp_repo; then
        print_error "Failed to download from GitHub"
        exit 1
    fi
    cp -r temp_repo/* .
    rm -rf temp_repo
else
    print_info "Extracting archive..."
    unzip -q ai-translator-v2.2.5-final-github.zip
    rm ai-translator-v2.2.5-final-github.zip
fi

# Create Python virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
print_info "Installing Python dependencies..."
pip install --upgrade pip setuptools wheel
pip install -r requirements_github.txt

# Setup PostgreSQL database
print_info "Setting up PostgreSQL database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;"
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;"
sudo -u postgres psql -c "CREATE USER ai_translator WITH ENCRYPTED PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "CREATE DATABASE ai_translator OWNER ai_translator;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

# Fix PostgreSQL schema permissions
print_info "Fixing PostgreSQL schema permissions..."
sudo -u postgres psql -d ai_translator -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "GRANT CREATE ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ai_translator;" 2>/dev/null

# Create environment file
print_info "Creating environment configuration..."
cat > .env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
SESSION_SECRET=$(openssl rand -hex 32)
FLASK_ENV=production
FLASK_DEBUG=False
EOF

# Initialize database with fixed settings
print_info "Initializing database with corrected settings..."
export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
python3 -c "
import sys
sys.path.insert(0, '.')
from app import app, db
from database_setup import create_default_settings

with app.app_context():
    db.create_all()
    create_default_settings()
    
    # Fix admin password issue - ensure it's stored as plain text not hash
    from models import Settings
    admin_password_setting = Settings.query.filter_by(key='admin_password').first()
    if admin_password_setting:
        admin_password_setting.value = 'your_strong_password'
        db.session.commit()
        print('✓ Admin password fixed')
    else:
        new_password = Settings(
            key='admin_password',
            value='your_strong_password',
            section='DEFAULT',
            type='password',
            description='Admin password'
        )
        db.session.add(new_password)
        db.session.commit()
        print('✓ Admin password created')
        
    print('✓ Database initialization completed')
"

# Configure Nginx
print_info "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/ai-translator > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    client_max_body_size 500M;
    client_body_timeout 300s;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location /static {
        alias $INSTALL_DIR/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Create systemd service
print_info "Creating systemd service..."
sudo tee /etc/systemd/system/ai-translator.service > /dev/null << EOF
[Unit]
Description=AI Translator v2.2.5 Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=exec
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 1 --timeout 300 --preload main:app
Restart=always
RestartSec=10
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
print_info "Enabling and starting AI Translator service..."
sudo systemctl daemon-reload
sudo systemctl enable ai-translator
sudo systemctl start ai-translator

# Wait and check service status
print_info "Checking service status..."
sleep 10

if sudo systemctl is-active --quiet ai-translator; then
    print_status "AI Translator service is running!"
else
    print_error "Service failed to start. Checking logs..."
    sudo journalctl -u ai-translator --no-pager -l
    exit 1
fi

# Install Ollama (optional)
print_info "Installing Ollama for AI translation..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.ai/install.sh | sh
    print_status "Ollama installed successfully"
    
    # Start Ollama service
    sudo systemctl enable ollama
    sudo systemctl start ollama
    
    # Download recommended model
    print_info "Downloading Llama 3 model (this may take several minutes)..."
    ollama pull llama3 &
    OLLAMA_PID=$!
    print_info "Ollama model download started in background (PID: $OLLAMA_PID)"
else
    print_status "Ollama already installed"
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Final instructions
echo ""
echo "🎉 Installation completed successfully!"
echo "   التثبيت اكتمل بنجاح!"
echo ""
echo -e "${GREEN}📋 Access Information:${NC}"
echo "• Web Interface: http://$SERVER_IP"
echo "• Local Access:  http://localhost"
echo "• Default Login: admin / your_strong_password"
echo ""
echo -e "${BLUE}🔧 Service Management:${NC}"
echo "• Start service:   sudo systemctl start ai-translator"
echo "• Stop service:    sudo systemctl stop ai-translator"
echo "• View logs:       sudo journalctl -u ai-translator -f"
echo "• Service status:  sudo systemctl status ai-translator"
echo ""
echo -e "${YELLOW}⚙️ Configuration:${NC}"
echo "• Installation path: $INSTALL_DIR"
echo "• Database: PostgreSQL (ai_translator)"
echo "• Web server: Nginx (port 80)"
echo "• Application: Gunicorn (port 5000)"
echo ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo "1. Access the web interface and log in"
echo "2. Configure your media servers (Plex, Jellyfin, Radarr, Sonarr)"
echo "3. Set up file paths for your media libraries"
echo "4. Wait for Ollama model download to complete"
echo "5. Start translating your media files!"
echo ""
print_status "AI Translator v2.2.5 is now ready to use!"
print_info "Access your installation at: http://$SERVER_IP"
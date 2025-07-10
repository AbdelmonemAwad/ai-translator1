#!/bin/bash

# AI Translator v2.2.4 - Complete Installation Script for Ubuntu Server
# Automatic installation with PostgreSQL, Nginx, and all dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_header "AI Translator v2.2.4 Installation"
print_status "Starting installation process..."

# Update system packages
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install system dependencies
print_status "Installing system dependencies..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    postgresql \
    postgresql-contrib \
    nginx \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    pkg-config \
    libpq-dev \
    ffmpeg \
    software-properties-common

# Start and enable PostgreSQL
print_status "Configuring PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

# Create database and user
print_status "Setting up database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;"
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;"
sudo -u postgres psql -c "CREATE DATABASE ai_translator;"
sudo -u postgres psql -c "CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

# Fix PostgreSQL schema permissions
print_info "Fixing PostgreSQL schema permissions..."
sudo -u postgres psql -d ai_translator -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "GRANT CREATE ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ai_translator;" 2>/dev/null
sudo -u postgres psql -c "ALTER USER ai_translator CREATEDB;"

# Navigate to project directory
cd /root/ai-translator

# Create virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Set environment variables
print_status "Setting up environment variables..."
export DATABASE_URL='postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator'
export SESSION_SECRET='ai-translator-secret-key-2024'
export FLASK_APP=main.py

# Create environment file
cat > .env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
SESSION_SECRET=ai-translator-secret-key-2024
FLASK_APP=main.py
FLASK_ENV=production
EOF

# Initialize database
print_status "Initializing database..."
python3 database_setup.py || python3 -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('Database tables created successfully')
"

# Configure Nginx
print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/ai-translator << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
    
    location /static {
        alias /root/ai-translator/static;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/ai-translator.service << EOF
[Unit]
Description=AI Translator v2.2.4
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/ai-translator
Environment=DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
Environment=SESSION_SECRET=ai-translator-secret-key-2024
Environment=FLASK_APP=main.py
Environment=FLASK_ENV=production
ExecStart=/root/ai-translator/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 300 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 --preload main:app
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
print_status "Setting file permissions..."
chmod +x *.sh 2>/dev/null || true
chmod 755 /root/ai-translator
chown -R root:root /root/ai-translator

# Enable and start services
print_status "Starting services..."
systemctl daemon-reload
systemctl enable ai-translator
systemctl start ai-translator
systemctl enable nginx
systemctl start nginx

# Wait for service to start
sleep 5

# Check service status
print_status "Checking service status..."
if systemctl is-active --quiet ai-translator; then
    print_status "✅ AI Translator service is running"
else
    print_error "❌ AI Translator service failed to start"
    systemctl status ai-translator --no-pager
fi

if systemctl is-active --quiet nginx; then
    print_status "✅ Nginx is running"
else
    print_error "❌ Nginx failed to start"
    systemctl status nginx --no-pager
fi

if systemctl is-active --quiet postgresql; then
    print_status "✅ PostgreSQL is running"
else
    print_error "❌ PostgreSQL failed to start"
    systemctl status postgresql --no-pager
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

print_header "Installation Complete!"
print_status "🎉 AI Translator v2.2.4 installed successfully!"
echo
print_status "📋 Access Information:"
echo -e "   🌐 Web Interface: ${GREEN}http://$SERVER_IP${NC}"
echo -e "   👤 Username: ${GREEN}admin${NC}"
echo -e "   🔑 Password: ${GREEN}your_strong_password${NC}"
echo
print_status "🔧 Service Commands:"
echo -e "   📊 Check status: ${YELLOW}systemctl status ai-translator${NC}"
echo -e "   🔄 Restart: ${YELLOW}systemctl restart ai-translator${NC}"
echo -e "   📝 View logs: ${YELLOW}journalctl -u ai-translator -f${NC}"
echo
print_status "🗂️ Important Paths:"
echo -e "   📁 Project: ${YELLOW}/root/ai-translator${NC}"
echo -e "   📊 Logs: ${YELLOW}journalctl -u ai-translator${NC}"
echo -e "   ⚙️ Config: ${YELLOW}/etc/nginx/sites-available/ai-translator${NC}"
echo
print_warning "🔒 Security Note: Change default password after first login!"
print_header "Installation Finished - Ready to Use!"
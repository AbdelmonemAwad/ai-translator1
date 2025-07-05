#!/bin/bash
# AI Translator v2.2.5 - Universal Installation Script
# سكريپت التثبيت الشامل للمترجم الآلي v2.2.5

set -e

echo "🚀 AI Translator v2.2.5 - Universal Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التثبيت الشامل..."

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

# Detect installation directory
CURRENT_DIR=$(pwd)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

print_info "Current directory: $CURRENT_DIR"
print_info "Script directory: $SCRIPT_DIR"

# Check if we're already in the extracted directory
if [ -f "$CURRENT_DIR/app.py" ] && [ -f "$CURRENT_DIR/main.py" ]; then
    INSTALL_DIR="$CURRENT_DIR"
    print_info "Using current directory as installation directory"
elif [ -f "$SCRIPT_DIR/app.py" ] && [ -f "$SCRIPT_DIR/main.py" ]; then
    INSTALL_DIR="$SCRIPT_DIR"
    print_info "Using script directory as installation directory"
else
    # We're probably in a parent directory, look for extracted folder
    EXTRACTED_DIRS=$(find . -maxdepth 2 -name "app.py" -exec dirname {} \; 2>/dev/null | head -1)
    if [ -n "$EXTRACTED_DIRS" ]; then
        INSTALL_DIR="$(cd "$EXTRACTED_DIRS" && pwd)"
        print_info "Found extracted directory: $INSTALL_DIR"
    else
        print_error "Could not find AI Translator files. Please run this script from the extracted directory."
        exit 1
    fi
fi

cd "$INSTALL_DIR"
print_status "Working in: $INSTALL_DIR"

# Check for required files
REQUIRED_FILES=("app.py" "main.py" "models.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file $file not found in $INSTALL_DIR"
        exit 1
    fi
done

print_status "All required files found"

# Detect if running as root or user
if [[ $EUID -eq 0 ]]; then
    INSTALL_USER="root"
    print_warning "Running as root"
else
    INSTALL_USER="$USER"
    print_info "Running as user: $INSTALL_USER"
fi

# Download GitHub repository
print_info "Downloading AI Translator from GitHub..."
if git clone https://github.com/AbdelmonemAwad/ai-translator.git temp_repo 2>/dev/null; then
    print_status "Successfully cloned GitHub repository"
    
    # Move files to installation directory
    if [ -d "temp_repo" ]; then
        mv temp_repo/* .
        mv temp_repo/.* . 2>/dev/null || true
        rm -rf temp_repo
        print_status "Files extracted to installation directory"
    fi
else
    print_error "Failed to clone GitHub repository"
    print_info "Trying alternative download method..."
    
    # Alternative: Download as ZIP
    if curl -L -o ai-translator.zip "https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip"; then
        print_status "Downloaded ZIP archive"
        
        # Extract using Python
        python3 << 'EOF'
import zipfile
import os
import shutil

try:
    with zipfile.ZipFile('ai-translator.zip', 'r') as zip_ref:
        zip_ref.extractall('.')
    
    # Move files from subdirectory
    for item in os.listdir('.'):
        if item.startswith('ai-translator-') and os.path.isdir(item):
            for subitem in os.listdir(item):
                src = os.path.join(item, subitem)
                dst = subitem
                if os.path.exists(dst):
                    if os.path.isdir(dst):
                        shutil.rmtree(dst)
                    else:
                        os.remove(dst)
                shutil.move(src, dst)
            shutil.rmtree(item)
            break
    
    os.remove('ai-translator.zip')
    print("✅ Files extracted successfully")
except Exception as e:
    print(f"❌ Extraction failed: {e}")
    exit(1)
EOF
    else
        print_error "All download methods failed"
        exit 1
    fi
fi

# Verify required files exist
REQUIRED_FILES=("app.py" "main.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file $file not found"
        exit 1
    fi
done

print_status "All required files verified"

# System update and dependencies
print_info "Updating system and installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx ffmpeg git curl build-essential python3-dev libpq-dev

# Create virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip

# Install Python packages
print_info "Installing Python packages..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
elif [ -f "requirements_github.txt" ]; then
    pip install -r requirements_github.txt
else
    # Install essential packages
    pip install flask flask-sqlalchemy psycopg2-binary gunicorn python-dotenv requests psutil pynvml
fi

# Setup PostgreSQL
print_info "Setting up PostgreSQL database..."
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ai_translator;"
sudo -u postgres psql -c "CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"
sudo -u postgres psql -c "ALTER USER ai_translator CREATEDB;"

print_status "PostgreSQL database configured"

# Create environment file
print_info "Creating environment configuration..."
cat > .env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
SESSION_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
FLASK_ENV=production
FLASK_DEBUG=False
EOF

# Initialize database
print_info "Initializing database..."
export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
if [ -f "database_setup.py" ]; then
    python database_setup.py || print_warning "Database setup completed with warnings"
fi

# Create systemd service
print_info "Creating systemd service..."
cat > /etc/systemd/system/ai-translator.service << EOF
[Unit]
Description=AI Translator Web Application
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=exec
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 --reload main:app
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Setup Nginx
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
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable Nginx configuration
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Start services
print_info "Starting services..."
systemctl daemon-reload
systemctl enable ai-translator
systemctl start ai-translator
systemctl enable nginx

# Wait for service to start
sleep 5

# Check service status
if systemctl is-active --quiet ai-translator; then
    print_status "AI Translator service is running"
else
    print_error "Service failed to start, checking logs..."
    journalctl -u ai-translator --no-pager -l
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

print_status "Installation completed successfully!"
echo ""
echo "🎉 AI Translator v2.2.5 is now installed and running!"
echo "📱 Access your application at: http://$SERVER_IP"
echo "🔑 Default login credentials:"
echo "   Username: admin"
echo "   Password: your_strong_password"
echo ""
echo "🔧 Service management commands:"
echo "   systemctl status ai-translator    # Check status"
echo "   systemctl restart ai-translator   # Restart service"
echo "   systemctl stop ai-translator      # Stop service"
echo "   journalctl -u ai-translator -f    # View logs"
echo ""
echo "✅ Installation complete - Your AI Translator is ready to use!"
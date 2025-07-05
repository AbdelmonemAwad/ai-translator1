#!/bin/bash
# AI Translator v2.2.5 - Fixed Installation Script
# المترجم الآلي v2.2.5 - سكريبت التثبيت المطور

set -e

echo "🚀 AI Translator v2.2.5 - Fixed Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التثبيت المطور..."

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. Will install in /opt/ai-translator"
    INSTALL_DIR="/opt/ai-translator"
    INSTALL_USER="root"
else
    print_info "Running as user. Will install in current directory"
    INSTALL_DIR="$(pwd)/ai-translator"
    INSTALL_USER="$USER"
fi

# Update system packages
print_info "Updating system packages..."
if command -v apt &> /dev/null; then
    sudo apt update
elif command -v yum &> /dev/null; then
    sudo yum update -y
fi

# Install system dependencies
print_info "Installing system dependencies..."
if command -v apt &> /dev/null; then
    sudo apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        postgresql \
        postgresql-contrib \
        nginx \
        ffmpeg \
        git \
        curl \
        wget \
        unzip \
        build-essential \
        pkg-config \
        libpq-dev
elif command -v yum &> /dev/null; then
    sudo yum install -y \
        python3 \
        python3-pip \
        python3-devel \
        postgresql \
        postgresql-server \
        postgresql-contrib \
        nginx \
        ffmpeg \
        git \
        curl \
        wget \
        unzip \
        gcc \
        gcc-c++ \
        postgresql-devel
fi

# Create installation directory
print_info "Creating installation directory..."
sudo mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download and extract AI Translator package
print_info "Downloading AI Translator package..."
if [ -f "ai-translator-clean-v2.2.5.zip" ]; then
    print_info "Package already exists, using local file"
else
    # Try multiple download sources
    DOWNLOAD_SUCCESS=false
    
    # Source 1: Direct GitHub release
    if ! $DOWNLOAD_SUCCESS; then
        print_info "Trying GitHub release download..."
        if curl -L -o ai-translator-clean-v2.2.5.zip "https://github.com/AbdelmonemAwad/ai-translator/releases/download/v2.2.5/ai-translator-clean-v2.2.5.zip" 2>/dev/null; then
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded from GitHub releases"
        fi
    fi
    
    # Source 2: Raw GitHub files
    if ! $DOWNLOAD_SUCCESS; then
        print_info "Trying raw GitHub download..."
        if curl -L -o ai-translator-clean-v2.2.5.zip "https://raw.githubusercontent.com/AbdelmonemAwad/ai-translator/main/ai-translator-clean-v2.2.5.zip" 2>/dev/null; then
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded from GitHub raw"
        fi
    fi
    
    # Source 3: Clone and package
    if ! $DOWNLOAD_SUCCESS; then
        print_info "Downloading via git clone..."
        if git clone https://github.com/AbdelmonemAwad/ai-translator.git temp_clone; then
            if [ -f "temp_clone/ai-translator-clean-v2.2.5.zip" ]; then
                cp temp_clone/ai-translator-clean-v2.2.5.zip .
                DOWNLOAD_SUCCESS=true
                print_status "Found package in repository"
            else
                # Create package from repository
                cd temp_clone
                zip -r ../ai-translator-clean-v2.2.5.zip . -x "*.git*" "*__pycache__*" "*.pyc" "*node_modules*" "*attached_assets*"
                cd ..
                DOWNLOAD_SUCCESS=true
                print_status "Created package from repository"
            fi
            rm -rf temp_clone
        fi
    fi
    
    if ! $DOWNLOAD_SUCCESS; then
        print_error "Failed to download AI Translator package"
        exit 1
    fi
fi

# Extract package
print_info "Extracting AI Translator package..."
if command -v unzip &> /dev/null; then
    unzip -q ai-translator-clean-v2.2.5.zip
else
    python3 -c "import zipfile; zipfile.ZipFile('ai-translator-clean-v2.2.5.zip').extractall()"
fi

# Find the extracted directory
EXTRACTED_DIR=$(find . -name "ai-translator-clean-v*" -type d | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    print_error "Could not find extracted directory"
    exit 1
fi

print_info "Found extracted directory: $EXTRACTED_DIR"

# Move files to installation directory
print_info "Setting up installation files..."
cp -r "$EXTRACTED_DIR"/* .
rm -rf "$EXTRACTED_DIR"
sudo chown -R "$INSTALL_USER:$INSTALL_USER" .

# Create virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies with fallback
print_info "Installing Python dependencies..."
REQUIREMENTS_INSTALLED=false

# Try requirements_github.txt first
if [ -f "requirements_github.txt" ] && ! $REQUIREMENTS_INSTALLED; then
    print_info "Installing from requirements_github.txt..."
    if pip install -r requirements_github.txt; then
        REQUIREMENTS_INSTALLED=true
        print_status "Installed from requirements_github.txt"
    else
        print_warning "Failed to install from requirements_github.txt"
    fi
fi

# Try requirements.txt as fallback
if [ -f "requirements.txt" ] && ! $REQUIREMENTS_INSTALLED; then
    print_info "Installing from requirements.txt..."
    if pip install -r requirements.txt; then
        REQUIREMENTS_INSTALLED=true
        print_status "Installed from requirements.txt"
    else
        print_warning "Failed to install from requirements.txt"
    fi
fi

# Install essential packages manually if both failed
if ! $REQUIREMENTS_INSTALLED; then
    print_warning "Installing essential packages manually..."
    pip install flask flask-sqlalchemy psycopg2-binary gunicorn python-dotenv sqlalchemy requests psutil
    REQUIREMENTS_INSTALLED=true
    print_status "Installed essential packages manually"
fi

# Setup PostgreSQL database
print_info "Setting up PostgreSQL database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user with error handling
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ai_translator;"
sudo -u postgres psql -c "CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "ALTER ROLE ai_translator SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE ai_translator SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE ai_translator SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

print_status "PostgreSQL database setup completed"

# Set environment variables
print_info "Setting up environment variables..."
cat > .env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
SESSION_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
FLASK_ENV=production
FLASK_APP=main.py
EOF

# Initialize database schema
print_info "Initializing database schema..."
export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
export SESSION_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')

if [ -f "database_setup.py" ]; then
    print_info "Running database_setup.py..."
    python database_setup.py || print_warning "database_setup.py had issues, but continuing"
else
    print_warning "database_setup.py not found, database will be initialized on first run"
fi

# Create systemd service
print_info "Creating systemd service..."
sudo tee /etc/systemd/system/ai-translator.service > /dev/null << EOF
[Unit]
Description=AI Translator v2.2.5 Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=exec
User=$INSTALL_USER
Group=$INSTALL_USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 main:app
Restart=always
RestartSec=3
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx (optional)
print_info "Configuring Nginx reverse proxy..."
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
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl enable nginx

# Enable and start AI Translator service
print_info "Starting AI Translator service..."
sudo systemctl daemon-reload
sudo systemctl enable ai-translator
sudo systemctl start ai-translator

# Wait and check service status
sleep 5
if sudo systemctl is-active --quiet ai-translator; then
    print_status "AI Translator service is running!"
else
    print_warning "Service may have issues. Checking logs..."
    sudo journalctl -u ai-translator --no-pager -n 10
fi

# Install Ollama (optional)
print_info "Installing Ollama for AI translation..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.ai/install.sh | sh
    print_status "Ollama installed successfully"
else
    print_status "Ollama already installed"
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Final instructions
echo ""
echo "🎉 AI Translator v2.2.5 installation completed successfully!"
echo "   التثبيت اكتمل بنجاح!"
echo ""
echo -e "${GREEN}📋 Access Information:${NC}"
echo "• Web Interface: http://$SERVER_IP (via Nginx)"
echo "• Direct Access: http://$SERVER_IP:5000"
echo "• Default Login: admin / your_strong_password"
echo ""
echo -e "${BLUE}🔧 Service Management:${NC}"
echo "• Start service:   sudo systemctl start ai-translator"
echo "• Stop service:    sudo systemctl stop ai-translator"
echo "• Restart service: sudo systemctl restart ai-translator"
echo "• View logs:       sudo journalctl -u ai-translator -f"
echo "• Service status:  sudo systemctl status ai-translator"
echo ""
echo -e "${YELLOW}📖 Next Steps:${NC}"
echo "1. Configure your media servers in Settings"
echo "2. Install Ollama models: ollama pull llama3"
echo "3. Upload video files for translation"
echo ""
echo -e "${GREEN}📁 Installation Directory:${NC} $INSTALL_DIR"
echo -e "${GREEN}🗃️ Database:${NC} PostgreSQL - ai_translator"
echo -e "${GREEN}🔐 Database User:${NC} ai_translator"
echo ""
print_status "AI Translator v2.2.5 is now ready to use!"
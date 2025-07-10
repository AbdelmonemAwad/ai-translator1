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
        print_warning "AI Translator files not found locally. Attempting to download from GitHub..."
        
        # Check if we're running the script from a remote URL (curl | bash)
        if [ ! -f "${BASH_SOURCE[0]}" ]; then
            print_info "Running from remote URL, downloading project..."
            
            # Create installation directory
            INSTALL_DIR="/root/ai-translator"
            mkdir -p "$INSTALL_DIR"
            cd "$INSTALL_DIR"
            
            # Try multiple download methods
            print_info "Attempting to clone from GitHub..."
            if command -v git &> /dev/null; then
                if git clone https://github.com/AbdelmonemAwad/ai-translator.git .; then
                    print_status "Successfully cloned from GitHub"
                else
                    print_warning "Git clone failed, trying direct download..."
                    # Try downloading comprehensive package
                    if command -v wget &> /dev/null; then
                        wget https://github.com/AbdelmonemAwad/ai-translator/archive/main.zip -O ai-translator.zip
                        if [ -f ai-translator.zip ]; then
                            unzip -q ai-translator.zip
                            mv ai-translator-main/* .
                            rm -rf ai-translator-main ai-translator.zip
                            print_status "Successfully downloaded and extracted"
                        else
                            print_error "Failed to download from GitHub"
                            exit 1
                        fi
                    else
                        print_error "Neither git nor wget available. Please install git or wget."
                        exit 1
                    fi
                fi
            else
                print_error "Git not available. Please install git or download manually."
                exit 1
            fi
        else
            print_error "Could not find AI Translator files. Please run this script from the extracted directory."
            exit 1
        fi
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

print_status "System dependencies installed"

# Create virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies with smart fallback
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
sudo -u postgres psql -c "ALTER USER ai_translator WITH SUPERUSER;"
sudo -u postgres psql -c "ALTER USER ai_translator WITH CREATEDB;"
sudo -u postgres psql -c "ALTER USER ai_translator WITH CREATEROLE;"
sudo -u postgres psql -c "ALTER USER ai_translator WITH LOGIN;"
sudo -u postgres psql -c "ALTER ROLE ai_translator SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE ai_translator SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE ai_translator SET timezone TO 'UTC';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

# Fix PostgreSQL schema permissions
print_info "Fixing PostgreSQL schema permissions..."
sudo -u postgres psql -d ai_translator -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "GRANT CREATE ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ai_translator;" 2>/dev/null

# Fix PostgreSQL schema permissions
print_info "Fixing PostgreSQL schema permissions..."
sudo -u postgres psql -d ai_translator -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "GRANT CREATE ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ai_translator;" 2>/dev/null
sudo -u postgres psql -c "ALTER DATABASE ai_translator OWNER TO ai_translator;"

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

# Configure Nginx
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

# Set proper permissions
print_info "Setting file permissions..."
sudo chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_DIR"

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

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Final instructions
echo ""
echo "🎉 AI Translator v2.2.5 installation completed successfully!"
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
echo -e "${GREEN}📁 Installation Directory:${NC} $INSTALL_DIR"
echo -e "${GREEN}🗃️ Database:${NC} PostgreSQL - ai_translator"
echo ""
print_status "AI Translator v2.2.5 is now ready to use!"
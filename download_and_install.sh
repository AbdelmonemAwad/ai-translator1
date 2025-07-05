#!/bin/bash
# AI Translator v2.2.5 - GitHub Download and Install Script
# سكريپت التحميل والتثبيت من GitHub

set -e

echo "🚀 AI Translator v2.2.5 - GitHub Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التثبيت من GitHub..."

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
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    echo "Please run: sudo bash"
    exit 1
fi

# Create installation directory
INSTALL_DIR="/root/ai-translator"
print_info "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clean any existing installation
if [ "$(ls -A $INSTALL_DIR)" ]; then
    print_warning "Directory not empty, cleaning..."
    rm -rf ./*
fi

# Download the project
print_info "Downloading AI Translator from GitHub..."

# Method 1: Try git clone
if command -v git &> /dev/null; then
    print_info "Using git to clone repository..."
    if git clone https://github.com/AbdelmonemAwad/ai-translator.git . 2>/dev/null; then
        print_status "Successfully cloned repository"
    else
        print_warning "Git clone failed, trying wget download..."
        METHOD2=true
    fi
else
    print_warning "Git not available, using wget..."
    METHOD2=true
fi

# Method 2: Direct download with wget
if [ "$METHOD2" = true ]; then
    if command -v wget &> /dev/null; then
        print_info "Downloading ZIP archive..."
        wget -q https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip -O ai-translator.zip
        
        if [ -f ai-translator.zip ]; then
            print_info "Extracting archive..."
            unzip -q ai-translator.zip
            mv ai-translator-main/* .
            mv ai-translator-main/.[^.]* . 2>/dev/null || true
            rm -rf ai-translator-main ai-translator.zip
            print_status "Successfully downloaded and extracted"
        else
            print_error "Failed to download archive"
            exit 1
        fi
    else
        print_error "Neither git nor wget available. Please install one of them."
        exit 1
    fi
fi

# Verify download
print_info "Verifying downloaded files..."
REQUIRED_FILES=("app.py" "main.py" "models.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file $file not found after download"
        exit 1
    fi
done
print_status "All required files found"

# Make install script executable if it exists
if [ -f "install_universal.sh" ]; then
    chmod +x install_universal.sh
    print_status "Made install script executable"
    
    # Run the universal installer
    print_info "Running universal installation script..."
    ./install_universal.sh
else
    print_warning "install_universal.sh not found, running manual installation..."
    
    # Manual installation steps
    print_info "Starting manual installation..."
    
    # Update system
    print_info "Updating system packages..."
    apt update -y && apt upgrade -y
    
    # Install dependencies
    print_info "Installing system dependencies..."
    apt install -y python3 python3-pip python3-venv python3-dev
    apt install -y postgresql postgresql-contrib
    apt install -y nginx
    apt install -y ffmpeg
    apt install -y build-essential libssl-dev libffi-dev
    apt install -y git wget curl unzip
    
    # Create virtual environment
    print_info "Creating Python virtual environment..."
    python3 -m venv /opt/ai-translator-venv
    source /opt/ai-translator-venv/bin/activate
    
    # Install Python packages
    print_info "Installing Python packages..."
    pip install --upgrade pip setuptools wheel
    
    # Try different requirements files
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    elif [ -f "requirements_production.txt" ]; then
        pip install -r requirements_production.txt
    else
        # Install core packages manually
        pip install flask flask-sqlalchemy psycopg2-binary gunicorn
        pip install requests psutil pynvml
    fi
    
    # Setup database
    print_info "Setting up PostgreSQL database..."
    systemctl start postgresql
    systemctl enable postgresql
    
    sudo -u postgres psql << EOF
CREATE DATABASE ai_translator;
CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';
ALTER USER ai_translator WITH SUPERUSER;
ALTER USER ai_translator WITH CREATEDB;
ALTER USER ai_translator WITH CREATEROLE;
ALTER USER ai_translator WITH LOGIN;
GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;
ALTER DATABASE ai_translator OWNER TO ai_translator;
\q
EOF
    
    # Setup environment
    export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
    export SESSION_SECRET="$(openssl rand -hex 32)"
    
    # Initialize database
    if [ -f "database_setup.py" ]; then
        print_info "Initializing database..."
        source /opt/ai-translator-venv/bin/activate
        python database_setup.py
    fi
    
    # Create systemd service
    print_info "Creating systemd service..."
    cat > /etc/systemd/system/ai-translator.service << EOF
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
    
    # Start services
    systemctl daemon-reload
    systemctl enable ai-translator
    systemctl start ai-translator
    
    print_status "Manual installation completed"
fi

# Final verification
print_info "Verifying installation..."
sleep 5

if systemctl is-active --quiet ai-translator; then
    print_status "AI Translator service is running"
else
    print_warning "Service not running, checking status..."
    systemctl status ai-translator --no-pager
fi

if curl -s http://localhost:5000 > /dev/null; then
    print_status "Application is responding on port 5000"
else
    print_warning "Application not responding on port 5000"
fi

# Display final information
echo ""
echo "============================================================"
print_status "AI Translator v2.2.5 Installation Complete!"
echo "============================================================"
echo ""
print_info "Installation Directory: $INSTALL_DIR"
print_info "Service Status: $(systemctl is-active ai-translator)"
print_info "Database: PostgreSQL (ai_translator)"
print_info "Default Credentials: admin / your_strong_password"
echo ""
print_info "Access your application at:"
print_info "- Local: http://localhost:5000"
print_info "- Network: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
print_info "Useful commands:"
echo "  sudo systemctl status ai-translator    # Check service status"
echo "  sudo systemctl restart ai-translator   # Restart service"
echo "  sudo journalctl -u ai-translator -f    # View live logs"
echo ""
print_status "Installation completed successfully!"
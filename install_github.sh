#!/bin/bash
# AI Translator v2.2.5 - GitHub Installation Script
# سكريپت التثبيت من GitHub للمترجم الآلي

set -e

echo "🚀 AI Translator v2.2.5 - GitHub Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التثبيت من GitHub..."

# Colors
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

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Installation directory
INSTALL_DIR="/root/ai-translator"
print_info "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download the AI Translator package from multiple sources
print_info "Downloading AI Translator package..."

DOWNLOAD_SUCCESS=false

# Method 1: Try Replit download
REPLIT_URL="https://7051c462-c198-47dc-88bb-33339edb37ed-00-166z3xoyzbrt3.picard.replit.dev"
if ! $DOWNLOAD_SUCCESS; then
    print_info "Attempting download from Replit..."
    if curl -L -o package.zip "${REPLIT_URL}/download-working-package" --connect-timeout 30 --max-time 60; then
        if [ -f "package.zip" ] && [ $(stat -c%s "package.zip") -gt 100000 ]; then
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded from Replit ($(stat -c%s "package.zip") bytes)"
        else
            rm -f package.zip
            print_error "Downloaded file too small or corrupted"
        fi
    else
        print_error "Failed to download from Replit"
    fi
fi

# Method 2: Try GitHub repository clone
if ! $DOWNLOAD_SUCCESS; then
    print_info "Attempting GitHub repository clone..."
    if git clone https://github.com/AbdelmonemAwad/ai-translator.git temp_repo 2>/dev/null; then
        if [ -f "temp_repo/app.py" ] && [ -f "temp_repo/main.py" ]; then
            mv temp_repo/* .
            rm -rf temp_repo
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded from GitHub repository"
        else
            rm -rf temp_repo
            print_error "GitHub repository incomplete"
        fi
    else
        print_error "Failed to clone GitHub repository"
    fi
fi

# Method 3: Manual download instructions
if ! $DOWNLOAD_SUCCESS; then
    print_error "All download methods failed"
    echo ""
    echo "Please manually download the package:"
    echo "1. Go to: ${REPLIT_URL}/download-working-package"
    echo "2. Save the file as package.zip in $INSTALL_DIR"
    echo "3. Run this script again"
    echo ""
    echo "Or download from GitHub:"
    echo "1. Go to: https://github.com/AbdelmonemAwad/ai-translator"
    echo "2. Click 'Code' -> 'Download ZIP'"
    echo "3. Extract to $INSTALL_DIR"
    echo "4. Run the install.sh script"
    exit 1
fi

# If we downloaded a zip file, extract it
if [ -f "package.zip" ]; then
    print_info "Extracting package..."
    
    # Extract using Python
    python3 << 'EOF'
import zipfile
import os
import shutil

try:
    with zipfile.ZipFile('package.zip', 'r') as zip_ref:
        zip_ref.extractall('temp')
    
    # Find and move extracted files
    for item in os.listdir('temp'):
        item_path = os.path.join('temp', item)
        if os.path.isdir(item_path):
            for subitem in os.listdir(item_path):
                src = os.path.join(item_path, subitem)
                dst = subitem
                if os.path.exists(dst):
                    if os.path.isdir(dst):
                        shutil.rmtree(dst)
                    else:
                        os.remove(dst)
                shutil.move(src, dst)
            break
    
    # Cleanup
    shutil.rmtree('temp')
    os.remove('package.zip')
    print("✅ Extraction completed")
except Exception as e:
    print(f"❌ Extraction failed: {e}")
    exit(1)
EOF
fi

# Verify required files exist
REQUIRED_FILES=("app.py" "main.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file $file not found after download"
        print_info "Current directory contents:"
        ls -la
        exit 1
    fi
done

print_status "All required files found"

# Check if install.sh exists, if not create a basic one
if [ ! -f "install.sh" ]; then
    print_info "Creating installation script..."
    cat > install.sh << 'INSTALL_SCRIPT'
#!/bin/bash
# Basic AI Translator Installation Script

set -e

echo "🔧 AI Translator - Basic Installation"

# Update system
apt update

# Install dependencies
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx ffmpeg git curl

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install --upgrade pip
pip install flask flask-sqlalchemy psycopg2-binary gunicorn python-dotenv requests psutil

# Setup PostgreSQL
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ai_translator;"
sudo -u postgres psql -c "CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

# Create environment file
cat > .env << EOF
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
SESSION_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
FLASK_ENV=production
EOF

# Initialize database if setup script exists
if [ -f "database_setup.py" ]; then
    export DATABASE_URL="postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator"
    python database_setup.py || echo "Database setup had issues, continuing..."
fi

echo "✅ Basic installation completed"
echo "You can now start the application with:"
echo "source venv/bin/activate && python main.py"
INSTALL_SCRIPT

    chmod +x install.sh
    print_status "Created basic installation script"
fi

# Run the installation
print_info "Running installation script..."
chmod +x install.sh
./install.sh

print_status "AI Translator installation completed!"

# Get server IP for final message
SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "🎉 Installation completed successfully!"
echo "📱 Access your AI Translator at: http://$SERVER_IP:5000"
echo "🔑 Default login: admin / your_strong_password"
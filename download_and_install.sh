#!/bin/bash
# AI Translator v2.2.5 - Direct Download and Install Script
# سكريپت التحميل والتثبيت المباشر للمترجم الآلي

set -e

echo "🚀 AI Translator v2.2.5 - Direct Download Installation Starting..."
echo "   المترجم الآلي v2.2.5 - بدء التحميل والتثبيت المباشر..."

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

# Create installation directory
INSTALL_DIR="/root/ai-translator"
print_info "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download the working package - try multiple sources
print_info "Downloading AI Translator package..."

# Try different download methods
DOWNLOAD_SUCCESS=false

# Method 1: GitHub repository clone
if ! $DOWNLOAD_SUCCESS; then
    print_info "Attempting GitHub repository clone..."
    if git clone https://github.com/AbdelmonemAwad/ai-translator.git temp_repo 2>/dev/null; then
        if [ -f "temp_repo/app.py" ] && [ -f "temp_repo/main.py" ]; then
            mv temp_repo/* .
            mv temp_repo/.* . 2>/dev/null || true
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

# Method 2: GitHub ZIP download
if ! $DOWNLOAD_SUCCESS; then
    print_info "Trying GitHub ZIP download..."
    if curl -L -o ai-translator.zip "https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip" --connect-timeout 30; then
        if [ -f "ai-translator.zip" ] && [ $(stat -c%s "ai-translator.zip") -gt 100000 ]; then
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
            DOWNLOAD_SUCCESS=true
            print_status "Downloaded and extracted ZIP package"
        else
            rm -f ai-translator.zip
            print_error "Downloaded ZIP file too small or corrupted"
        fi
    else
        print_error "Failed to download ZIP from GitHub"
    fi
fi

# Check if download was successful
if ! $DOWNLOAD_SUCCESS; then
    print_error "All download methods failed"
    print_info "Manual installation instructions:"
    print_info "1. Download: https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip"
    print_info "2. Extract to $INSTALL_DIR"
    print_info "3. Run: cd $INSTALL_DIR && chmod +x install_universal.sh && ./install_universal.sh"
    exit 1
fi

# Verify required files exist
REQUIRED_FILES=("app.py" "main.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file $file not found after download"
        exit 1
    fi
done

print_status "All required files verified"

# Check if install script exists, prioritize universal installer
INSTALL_SCRIPT=""
if [ -f "install_universal.sh" ]; then
    INSTALL_SCRIPT="install_universal.sh"
elif [ -f "install.sh" ]; then
    INSTALL_SCRIPT="install.sh"
else
    print_error "No installation script found"
    exit 1
fi

# Make install script executable and run it
print_info "Running installation script: $INSTALL_SCRIPT"
chmod +x "$INSTALL_SCRIPT"
./"$INSTALL_SCRIPT"

print_status "AI Translator installation completed!"
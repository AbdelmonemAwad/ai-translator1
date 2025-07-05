#!/bin/bash

# AI Translator - Automatic Driver and Tools Installation Script
# نص تثبيت التعريفات والأدوات التلقائي - الترجمان الآلي

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root. This is recommended for system-wide installation."
    else
        info "Running as regular user. Some operations may require sudo."
    fi
}

# Detect system information
detect_system() {
    log "Detecting system information..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        DISTRO=$ID
    else
        error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
    
    ARCH=$(uname -m)
    KERNEL=$(uname -r)
    
    info "System: $OS $VER"
    info "Architecture: $ARCH"
    info "Kernel: $KERNEL"
    info "Distribution: $DISTRO"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf update -y
            else
                sudo yum update -y
            fi
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
        *)
            warn "Unsupported distribution: $DISTRO"
            ;;
    esac
}

# Install basic development tools
install_basic_tools() {
    log "Installing basic development tools..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y \
                build-essential \
                curl \
                wget \
                git \
                vim \
                nano \
                htop \
                tree \
                unzip \
                software-properties-common \
                apt-transport-https \
                ca-certificates \
                gnupg \
                lsb-release \
                pkg-config \
                cmake \
                make \
                gcc \
                g++
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf groupinstall -y "Development Tools"
                sudo dnf install -y curl wget git vim nano htop tree unzip cmake make gcc gcc-c++
            else
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y curl wget git vim nano htop tree unzip cmake make gcc gcc-c++
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm base-devel curl wget git vim nano htop tree unzip cmake make gcc
            ;;
    esac
}

# Install Python and dependencies
install_python() {
    log "Installing Python and dependencies..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                python3-setuptools \
                python3-wheel
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y python3 python3-pip python3-venv python3-devel
            else
                sudo yum install -y python3 python3-pip python3-venv python3-devel
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm python python-pip python-virtualenv
            ;;
    esac
    
    # Upgrade pip
    python3 -m pip install --upgrade pip
}

# Install FFmpeg
install_ffmpeg() {
    log "Installing FFmpeg..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y ffmpeg
            ;;
        centos|rhel|fedora)
            # Enable RPM Fusion for FFmpeg
            if command -v dnf &> /dev/null; then
                sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
                sudo dnf install -y ffmpeg
            else
                sudo yum install -y epel-release
                sudo yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
                sudo yum install -y ffmpeg
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm ffmpeg
            ;;
    esac
}

# Install NVIDIA drivers and CUDA
install_nvidia_drivers() {
    log "Installing NVIDIA drivers and CUDA..."
    
    # Check if NVIDIA GPU is present
    if ! lspci | grep -i nvidia &> /dev/null; then
        warn "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
        return
    fi
    
    case $DISTRO in
        ubuntu|debian)
            # Add NVIDIA repository
            wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -rs | tr -d .)/x86_64/cuda-keyring_1.0-1_all.deb
            sudo dpkg -i cuda-keyring_1.0-1_all.deb
            sudo apt update
            
            # Install NVIDIA drivers
            sudo apt install -y nvidia-driver-535
            
            # Install CUDA toolkit
            sudo apt install -y cuda-toolkit-12-2
            
            # Install additional NVIDIA tools
            sudo apt install -y nvidia-utils-535 nvidia-settings
            ;;
        centos|rhel|fedora)
            # Install NVIDIA repository
            if command -v dnf &> /dev/null; then
                sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora37/x86_64/cuda-fedora37.repo
                sudo dnf install -y nvidia-driver cuda-toolkit
            else
                sudo yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
                sudo yum install -y nvidia-driver cuda-toolkit
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm nvidia nvidia-utils cuda
            ;;
    esac
    
    # Add CUDA to PATH
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    case $DISTRO in
        ubuntu|debian)
            # Remove old versions
            sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Add Docker repository
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            else
                sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm docker docker-compose
            ;;
    esac
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
}

# Install PostgreSQL
install_postgresql() {
    log "Installing PostgreSQL..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y postgresql postgresql-contrib postgresql-client
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y postgresql postgresql-server postgresql-contrib
                sudo postgresql-setup --initdb
            else
                sudo yum install -y postgresql postgresql-server postgresql-contrib
                sudo postgresql-setup initdb
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm postgresql
            sudo -u postgres initdb -D /var/lib/postgres/data
            ;;
    esac
    
    # Start and enable PostgreSQL
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
}

# Install Nginx
install_nginx() {
    log "Installing Nginx..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y nginx
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y nginx
            else
                sudo yum install -y nginx
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm nginx
            ;;
    esac
    
    # Start and enable Nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
}

# Install Ollama
install_ollama() {
    log "Installing Ollama..."
    
    # Download and install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh
    
    # Start Ollama service
    sudo systemctl start ollama
    sudo systemctl enable ollama
    
    # Download default model
    info "Downloading Llama 3 model (this may take a while)..."
    ollama pull llama3
}

# Install AI Translator Python dependencies
install_ai_translator_deps() {
    log "Installing AI Translator Python dependencies..."
    
    # Create requirements.txt if not exists
    cat > /tmp/ai_translator_requirements.txt << EOF
flask==3.0.0
flask-sqlalchemy==3.1.1
gunicorn==21.2.0
psycopg2-binary==2.9.9
requests==2.31.0
psutil==5.9.6
pynvml==11.5.0
openai-whisper==20231117
torch==2.1.1
torchaudio==2.1.1
transformers==4.36.0
accelerate==0.25.0
datasets==2.15.0
soundfile==0.12.1
librosa==0.10.1
numpy==1.24.4
scipy==1.11.4
matplotlib==3.8.2
Pillow==10.1.0
python-dateutil==2.8.2
pytz==2023.3
werkzeug==3.0.1
email-validator==2.1.0
sendgrid==6.10.0
EOF
    
    # Install dependencies
    python3 -m pip install -r /tmp/ai_translator_requirements.txt
    
    # Clean up
    rm /tmp/ai_translator_requirements.txt
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian UFW
        sudo ufw allow 22/tcp    # SSH
        sudo ufw allow 80/tcp    # HTTP
        sudo ufw allow 443/tcp   # HTTPS
        sudo ufw allow 5000/tcp  # Flask app
        sudo ufw --force enable
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL/Fedora firewalld
        sudo firewall-cmd --permanent --add-port=22/tcp
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        sudo firewall-cmd --permanent --add-port=5000/tcp
        sudo firewall-cmd --reload
    else
        warn "No firewall management tool found. Please configure firewall manually."
    fi
}

# Create system user for AI Translator
create_ai_translator_user() {
    log "Creating AI Translator system user..."
    
    if ! id "aitranslator" &>/dev/null; then
        sudo useradd -r -s /bin/bash -d /opt/ai-translator -m aitranslator
        sudo usermod -aG docker aitranslator
    else
        info "User 'aitranslator' already exists."
    fi
}

# Post-installation tasks
post_installation() {
    log "Performing post-installation tasks..."
    
    # Update shared libraries
    sudo ldconfig
    
    # Refresh font cache if X11 is available
    if command -v fc-cache &> /dev/null; then
        fc-cache -f -v
    fi
    
    # Display system information
    info "=== Installation Summary ==="
    info "OS: $OS $VER ($DISTRO)"
    info "Architecture: $ARCH"
    info "Kernel: $KERNEL"
    info "Python: $(python3 --version 2>/dev/null || echo 'Not found')"
    info "FFmpeg: $(ffmpeg -version 2>/dev/null | head -1 || echo 'Not found')"
    info "Docker: $(docker --version 2>/dev/null || echo 'Not found')"
    info "PostgreSQL: $(postgres --version 2>/dev/null || echo 'Not found')"
    info "Nginx: $(nginx -v 2>&1 || echo 'Not found')"
    info "Ollama: $(ollama --version 2>/dev/null || echo 'Not found')"
    
    if command -v nvidia-smi &> /dev/null; then
        info "NVIDIA Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)"
        info "CUDA: $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' | tr -d ',' || echo 'Not found')"
    else
        warn "NVIDIA drivers not detected or not installed"
    fi
}

# Main installation function
main() {
    log "Starting AI Translator automatic installation..."
    log "الترجمان الآلي - بدء التثبيت التلقائي"
    
    check_root
    detect_system
    
    info "This script will install:"
    info "- System updates and basic tools"
    info "- Python 3 and development tools"
    info "- FFmpeg for video processing"
    info "- NVIDIA drivers and CUDA (if NVIDIA GPU detected)"
    info "- Docker for containerization"
    info "- PostgreSQL database"
    info "- Nginx web server"
    info "- Ollama AI platform"
    info "- AI Translator Python dependencies"
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Installation cancelled."
        exit 0
    fi
    
    # Run installation steps
    update_system
    install_basic_tools
    install_python
    install_ffmpeg
    install_nvidia_drivers
    install_docker
    install_postgresql
    install_nginx
    install_ollama
    install_ai_translator_deps
    configure_firewall
    create_ai_translator_user
    post_installation
    
    log "Installation completed successfully!"
    log "اكتمل التثبيت بنجاح!"
    
    warn "Please reboot your system to ensure all drivers are loaded properly."
    warn "يرجى إعادة تشغيل النظام لضمان تحميل جميع التعريفات بشكل صحيح."
}

# Run main function
main "$@"
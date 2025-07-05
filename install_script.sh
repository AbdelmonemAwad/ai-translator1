#!/bin/bash

# AI Translator v2.2.4 Installation Script
# Auto-installer for Ubuntu 24.04+ with comprehensive tabs fix

set -e

echo "🚀 AI Translator v2.2.4 Installation Starting..."

# Install required packages
echo "📦 Installing system packages..."
sudo DEBIAN_FRONTEND=noninteractive apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    wget curl git unzip \
    python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib \
    nginx \
    ffmpeg \
    build-essential pkg-config

echo "✅ System packages installed"

# Clean any existing installation
cd /home/eg2
sudo systemctl stop ai-translator 2>/dev/null || true
sudo rm -rf ai-translator 2>/dev/null || true

# Download project
echo "📥 Downloading AI Translator..."
wget -O ai-translator.zip https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip
unzip -q ai-translator.zip
mv ai-translator-main ai-translator
rm ai-translator.zip
cd ai-translator

echo "✅ Project downloaded"

# Setup Python environment
echo "🐍 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

pip install \
    flask==3.0.0 \
    flask-sqlalchemy==3.1.1 \
    gunicorn==21.2.0 \
    psycopg2-binary==2.9.9 \
    requests==2.31.0 \
    psutil==5.9.6 \
    pynvml==11.5.0 \
    email-validator==2.1.0 \
    werkzeug==3.0.1 \
    sendgrid==6.11.0

echo "✅ Python environment ready"

# Setup PostgreSQL
echo "🗄️ Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "CREATE DATABASE ai_translator OWNER ai_translator;"

echo "✅ PostgreSQL configured"

# Create environment file
echo "⚙️ Creating environment configuration..."
cat > .env << 'EOF'
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
PGHOST=localhost
PGPORT=5432
PGUSER=ai_translator
PGPASSWORD=ai_translator_pass2024
PGDATABASE=ai_translator
FLASK_APP=main.py
FLASK_ENV=production
EOF

echo "SESSION_SECRET=$(openssl rand -hex 32)" >> .env

echo "✅ Environment configured"

# Initialize database
echo "🏗️ Initializing database..."
source .env
python3 database_setup.py

echo "✅ Database initialized"

# Create advanced tabs fix
echo "🔧 Creating advanced tabs fix..."
mkdir -p static/js

cat > static/js/ultimate-tabs-fix.js << 'TABSFIX'
console.log('🚀 Ultimate Tabs Fix Loading...');

document.addEventListener('DOMContentLoaded', function() {
    let isInitialized = false;
    
    function initializeTabs() {
        if (isInitialized) return;
        
        const categorySelect = document.getElementById('category-select');
        const subcategorySelect = document.getElementById('subcategory-select');
        
        if (!categorySelect || !subcategorySelect) {
            setTimeout(initializeTabs, 1000);
            return;
        }
        
        const mapping = {
            'general': {
                sections: [
                    { id: 'DEFAULT', name: 'الإعدادات الأساسية' },
                    { id: 'LANGUAGE', name: 'إعدادات اللغة' },
                    { id: 'FOOTER', name: 'إعدادات التذييل' },
                    { id: 'UI', name: 'إعدادات الواجهة' }
                ]
            },
            'ai': {
                sections: [
                    { id: 'WHISPER', name: 'إعدادات Whisper' },
                    { id: 'OLLAMA', name: 'إعدادات Ollama' },
                    { id: 'GPU', name: 'إدارة GPU' },
                    { id: 'API', name: 'إعدادات API' },
                    { id: 'MODELS', name: 'إعدادات النماذج' }
                ]
            },
            'media': {
                sections: [
                    { id: 'PLEX', name: 'Plex Media Server' },
                    { id: 'JELLYFIN', name: 'Jellyfin Media Server' },
                    { id: 'EMBY', name: 'Emby Media Server' },
                    { id: 'KODI', name: 'Kodi Media Center' },
                    { id: 'RADARR', name: 'Radarr (أفلام)' },
                    { id: 'SONARR', name: 'Sonarr (مسلسلات)' }
                ]
            },
            'system': {
                sections: [
                    { id: 'PATHS', name: 'مسارات الملفات' },
                    { id: 'REMOTE_STORAGE', name: 'التخزين البعيد' },
                    { id: 'DATABASE', name: 'قاعدة البيانات' },
                    { id: 'SERVER', name: 'إعدادات الخادم' },
                    { id: 'CORRECTIONS', name: 'إعدادات التصحيحات' }
                ]
            },
            'development': {
                sections: [
                    { id: 'DEBUG', name: 'أدوات التطوير' },
                    { id: 'TESTING', name: 'الاختبار' },
                    { id: 'DEVELOPMENT', name: 'أدوات التطوير' }
                ]
            }
        };
        
        function findAvailableSections() {
            const available = [];
            Object.values(mapping).flatMap(cat => cat.sections).forEach(section => {
                if (document.querySelector('#tab-' + section.id)) {
                    available.push(section.id);
                }
            });
            return available;
        }
        
        const availableSections = findAvailableSections();
        console.log('Available sections:', availableSections);
        
        function hideAllTabs() {
            document.querySelectorAll('[id^="tab-"]').forEach(tab => {
                tab.style.display = 'none';
                tab.style.visibility = 'hidden';
                tab.classList.add('hidden');
                tab.setAttribute('hidden', '');
            });
        }
        
        function showTab(sectionId) {
            console.log('Showing tab:', sectionId);
            hideAllTabs();
            
            const tab = document.querySelector('#tab-' + sectionId);
            if (tab) {
                tab.style.display = 'block';
                tab.style.visibility = 'visible';
                tab.classList.remove('hidden');
                tab.removeAttribute('hidden');
                
                setTimeout(() => {
                    tab.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }, 100);
                
                return true;
            } else {
                console.warn('Tab not found:', sectionId);
                return false;
            }
        }
        
        function updateSubcategories(categoryKey) {
            console.log('Updating subcategories for:', categoryKey);
            
            subcategorySelect.innerHTML = '<option value="">اختر القسم الفرعي</option>';
            
            const category = mapping[categoryKey];
            if (!category) {
                console.warn('Unknown category:', categoryKey);
                return;
            }
            
            const available = category.sections.filter(s => availableSections.includes(s.id));
            
            available.forEach(section => {
                const option = document.createElement('option');
                option.value = section.id;
                option.textContent = section.name;
                subcategorySelect.appendChild(option);
            });
            
            subcategorySelect.disabled = available.length === 0;
            
            if (available.length > 0) {
                subcategorySelect.value = available[0].id;
                showTab(available[0].id);
            }
        }
        
        // Event listeners
        categorySelect.addEventListener('change', function() {
            updateSubcategories(this.value);
        });
        
        subcategorySelect.addEventListener('change', function() {
            if (this.value) {
                showTab(this.value);
            } else {
                hideAllTabs();
            }
        });
        
        // Initialize
        const initialCategory = categorySelect.value || 'general';
        updateSubcategories(initialCategory);
        
        // Global debug functions
        window.ultimateDebugTabs = function() {
            return {
                availableSections: availableSections,
                category: categorySelect.value,
                subcategory: subcategorySelect.value,
                mapping: mapping
            };
        };
        
        window.ultimateShowSection = function(sectionId) {
            return showTab(sectionId);
        };
        
        window.ultimateRefreshTabs = function() {
            isInitialized = false;
            setTimeout(initializeTabs, 500);
        };
        
        isInitialized = true;
        console.log('✅ Ultimate Tabs System Initialized Successfully!');
        
        // Show success notification
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed; top: 20px; right: 20px; z-index: 10000;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; padding: 12px 20px; border-radius: 8px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            font-family: Arial, sans-serif; font-size: 14px;
        `;
        notification.innerHTML = '✅ نظام التبويبات المتطور جاهز!';
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
    
    setTimeout(initializeTabs, 1000);
    
    // DOM observer for changes
    const observer = new MutationObserver(function(mutations) {
        let shouldReinitialize = false;
        mutations.forEach(function(mutation) {
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1 && (
                        (node.id && node.id.startsWith('tab-')) ||
                        (node.className && node.className.includes('tab'))
                    )) {
                        shouldReinitialize = true;
                    }
                });
            }
        });
        
        if (shouldReinitialize && !isInitialized) {
            setTimeout(initializeTabs, 500);
        }
    });
    
    observer.observe(document.body, { childList: true, subtree: true });
});

console.log('✅ Ultimate Tabs Fix Loaded Successfully!');
TABSFIX

echo "✅ Advanced tabs fix created"

# Update layout.html
echo "📝 Updating layout.html..."
if [[ -f "templates/layout.html" ]]; then
    # Remove any existing tabs fixes
    sed -i '/tabs-fix\.js/d' templates/layout.html
    sed -i '/ultimate-tabs-fix\.js/d' templates/layout.html
    
    # Add the new fix
    sed -i 's|</body>|    <script src="{{ url_for('\''static'\'', filename='\''js/ultimate-tabs-fix.js'\'') }}"></script>\n</body>|' templates/layout.html
    echo "✅ layout.html updated"
else
    echo "⚠️ layout.html not found"
fi

# Create systemd service
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/ai-translator.service > /dev/null << 'SERVICE'
[Unit]
Description=AI Translator v2.2.4 Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=eg2
Group=eg2
WorkingDirectory=/home/eg2/ai-translator
Environment=PATH=/home/eg2/ai-translator/venv/bin
EnvironmentFile=/home/eg2/ai-translator/.env
ExecStart=/home/eg2/ai-translator/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 300 main:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

echo "✅ Systemd service created"

# Setup Nginx
echo "🌐 Setting up Nginx..."
sudo tee /etc/nginx/sites-available/ai-translator > /dev/null << 'NGINX'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 5G;
    client_body_timeout 600s;
    proxy_read_timeout 600s;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /static/ {
        alias /home/eg2/ai-translator/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    access_log /var/log/nginx/ai-translator.access.log;
    error_log /var/log/nginx/ai-translator.error.log;
}
NGINX

sudo ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

if sudo nginx -t; then
    echo "✅ Nginx configured successfully"
else
    echo "❌ Nginx configuration error"
    exit 1
fi

# Set permissions
echo "🔒 Setting permissions..."
sudo chown -R eg2:eg2 /home/eg2/ai-translator
chmod 600 .env

# Start services
echo "🚀 Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable ai-translator
sudo systemctl restart postgresql
sudo systemctl restart nginx
sudo systemctl start ai-translator

echo "⏳ Waiting for services to start..."
sleep 15

# Check services
echo "📊 Service Status Check:"
echo "========================"
for service in postgresql nginx ai-translator; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
        echo "Last 3 log lines:"
        sudo journalctl -u $service --no-pager -n 3 | sed 's/^/  /'
    fi
done

echo ""
echo "🔌 Port Check:"
echo "=============="
for port in 80 5000 5432; do
    if ss -tlnp | grep -q ":$port "; then
        echo "✅ Port $port: Open"
    else
        echo "❌ Port $port: Closed"
    fi
done

echo ""
echo "🌐 Connection Test:"
echo "=================="
if curl -s --connect-timeout 5 http://localhost/ | grep -q "title\|html\|AI"; then
    echo "✅ Application responding on port 80"
else
    echo "❌ Application not responding on port 80"
fi

if curl -s --connect-timeout 5 http://localhost:5000/ | grep -q "title\|html\|AI"; then
    echo "✅ Application responding on port 5000"
else
    echo "❌ Application not responding on port 5000"
fi

echo ""
echo "🎉 AI Translator v2.2.4 Installation Complete!"
echo "=============================================="
echo ""
echo "🌐 Access URLs:"
echo "   External: http://5.31.55.179"
echo "   Local: http://localhost"
echo ""
echo "🔑 Login Credentials:"
echo "   Username: admin"
echo "   Password: your_strong_password"
echo ""
echo "🛠️ Management Commands:"
echo "   sudo systemctl status ai-translator"
echo "   sudo systemctl restart ai-translator"
echo "   sudo journalctl -u ai-translator -f"
echo ""
echo "🎯 Advanced Tabs Fix Features:"
echo "   ✅ Ultimate tabs system with comprehensive mapping"
echo "   ✅ Automatic section detection and management"
echo "   ✅ Smart tab hiding/showing with DOM protection"
echo "   ✅ Advanced debug functions: ultimateDebugTabs()"
echo "   ✅ Force section display: ultimateShowSection('SECTION')"
echo "   ✅ System refresh: ultimateRefreshTabs()"
echo ""
echo "✅ Installation completed successfully!"
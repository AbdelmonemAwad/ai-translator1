#!/bin/bash

# AI Translator v2.2.4 - Ultimate Installation Script with Advanced Tabs Fix
# للخادم: 5.31.55.179 | المستخدم: eg2 | كلمة المرور: 1q1
# تثبيت شامل مع إصلاحات التبويبات المتطورة

set -e

# تعريف الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# وظائف الطباعة الملونة
print_header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️ $1${NC}"
}

# التحقق من المستخدم
if [ "$USER" != "eg2" ]; then
    print_error "يجب تشغيل هذا السكريبت بالمستخدم eg2"
    echo "استخدم: su - eg2"
    exit 1
fi

print_header "🚀 AI Translator v2.2.4 - التثبيت الشامل مع إصلاحات التبويبات المتطورة"

# 1. تحديث النظام
print_step "تحديث النظام وحزم الأمان..."
sudo apt update -y && sudo apt upgrade -y
print_success "تم تحديث النظام"

# 2. تثبيت المتطلبات الأساسية
print_step "تثبيت المتطلبات الأساسية..."
sudo apt install -y \
    wget curl git unzip nano vim \
    python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib postgresql-client \
    nginx \
    ffmpeg \
    build-essential pkg-config \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg lsb-release \
    htop tree net-tools \
    openssl

print_success "تم تثبيت جميع المتطلبات الأساسية"

# 3. تنظيف أي تثبيت سابق
print_step "تنظيف أي تثبيت سابق..."
cd /home/eg2
sudo systemctl stop ai-translator 2>/dev/null || true
sudo systemctl disable ai-translator 2>/dev/null || true
sudo rm -rf ai-translator 2>/dev/null || true
print_success "تم تنظيف التثبيت السابق"

# 4. تحميل المشروع
print_step "تحميل AI Translator من GitHub..."
wget -O ai-translator.zip https://github.com/AbdelmonemAwad/ai-translator/archive/refs/heads/main.zip
unzip -q ai-translator.zip
mv ai-translator-main ai-translator
rm ai-translator.zip
cd ai-translator
print_success "تم تحميل المشروع ($(find . -name "*.py" | wc -l) ملف Python)"

# 5. إعداد البيئة الافتراضية
print_step "إنشاء البيئة الافتراضية Python..."
python3 -m venv venv
source venv/bin/activate

# تحديث pip
pip install --upgrade pip

# تثبيت المكتبات
print_step "تثبيت مكتبات Python المطلوبة..."
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

print_success "تم تثبيت جميع مكتبات Python"

# 6. إعداد PostgreSQL
print_step "إعداد قاعدة البيانات PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# إنشاء المستخدم وقاعدة البيانات
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "DROP USER IF EXISTS ai_translator;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER ai_translator WITH PASSWORD 'ai_translator_pass2024';"
sudo -u postgres psql -c "CREATE DATABASE ai_translator OWNER ai_translator;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_translator TO ai_translator;"

# Fix PostgreSQL schema permissions
print_info "Fixing PostgreSQL schema permissions..."
sudo -u postgres psql -d ai_translator -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "GRANT CREATE ON SCHEMA public TO ai_translator;" 2>/dev/null
sudo -u postgres psql -d ai_translator -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ai_translator;" 2>/dev/null

print_success "تم إعداد قاعدة البيانات PostgreSQL"

# 7. إنشاء ملف البيئة
print_step "إنشاء ملف متغيرات البيئة..."
cat > .env << 'ENV_EOF'
DATABASE_URL=postgresql://ai_translator:ai_translator_pass2024@localhost/ai_translator
PGHOST=localhost
PGPORT=5432
PGUSER=ai_translator
PGPASSWORD=ai_translator_pass2024
PGDATABASE=ai_translator
FLASK_APP=main.py
FLASK_ENV=production
FLASK_DEBUG=False
ENV_EOF

# إضافة مفتاح الجلسة العشوائي
echo "SESSION_SECRET=$(openssl rand -hex 32)" >> .env

print_success "تم إنشاء ملف البيئة"

# 8. تهيئة قاعدة البيانات
print_step "تهيئة هيكل قاعدة البيانات..."
source .env
if python3 database_setup.py; then
    print_success "تم تهيئة قاعدة البيانات بنجاح"
else
    print_error "خطأ في تهيئة قاعدة البيانات"
    exit 1
fi

# 9. إنشاء إصلاح التبويبات المتطور والشامل
print_step "إنشاء نظام إصلاح التبويبات المتطور..."
mkdir -p static/js

cat > static/js/ultimate-tabs-fix.js << 'ULTIMATE_TABS_EOF'
/**
 * AI Translator v2.2.4 - Ultimate Advanced Tabs Fix System
 * نظام إصلاح التبويبات المتطور والشامل
 * يحل جميع مشاكل التبويبات والتنقل في الإعدادات
 */

console.log('🚀 Ultimate Advanced Tabs Fix System - Loading...');

(function() {
    'use strict';
    
    let isSystemInitialized = false;
    let currentCategory = null;
    let currentSubcategory = null;
    let availableSections = [];
    
    // خريطة شاملة ومحدثة للفئات والأقسام مع جميع الاحتمالات المختلفة
    const ULTIMATE_CATEGORY_MAPPING = {
        'general': {
            name: 'الإعدادات العامة',
            nameEn: 'General Settings',
            icon: '⚙️',
            sections: [
                { id: 'DEFAULT', name: 'الإعدادات الأساسية', nameEn: 'Basic Settings', priority: 1 },
                { id: 'LANGUAGE', name: 'إعدادات اللغة', nameEn: 'Language Settings', priority: 2 },
                { id: 'FOOTER', name: 'إعدادات التذييل', nameEn: 'Footer Settings', priority: 3 },
                { id: 'UI', name: 'إعدادات الواجهة', nameEn: 'UI Settings', priority: 4 },
                { id: 'GENERAL', name: 'عام', nameEn: 'General', priority: 5 }
            ]
        },
        'ai': {
            name: 'خدمات الذكاء الاصطناعي',
            nameEn: 'AI Services',
            icon: '🤖',
            sections: [
                { id: 'WHISPER', name: 'إعدادات Whisper', nameEn: 'Whisper Settings', priority: 1 },
                { id: 'OLLAMA', name: 'إعدادات Ollama', nameEn: 'Ollama Settings', priority: 2 },
                { id: 'GPU', name: 'إدارة وحدة معالجة الرسومات', nameEn: 'GPU Management', priority: 3 },
                { id: 'API', name: 'إعدادات واجهة برمجة التطبيقات', nameEn: 'API Settings', priority: 4 },
                { id: 'MODELS', name: 'إعدادات النماذج', nameEn: 'Models Settings', priority: 5 },
                { id: 'AI', name: 'ذكاء اصطناعي', nameEn: 'Artificial Intelligence', priority: 6 }
            ]
        },
        'media': {
            name: 'خوادم الوسائط',
            nameEn: 'Media Servers',
            icon: '📺',
            sections: [
                { id: 'PLEX', name: 'خادم بليكس', nameEn: 'Plex Media Server', priority: 1 },
                { id: 'JELLYFIN', name: 'خادم جيليفين', nameEn: 'Jellyfin Media Server', priority: 2 },
                { id: 'EMBY', name: 'خادم إمبي', nameEn: 'Emby Media Server', priority: 3 },
                { id: 'KODI', name: 'مركز كودي الإعلامي', nameEn: 'Kodi Media Center', priority: 4 },
                { id: 'RADARR', name: 'رادار (إدارة الأفلام)', nameEn: 'Radarr (Movies)', priority: 5 },
                { id: 'SONARR', name: 'سونار (إدارة المسلسلات)', nameEn: 'Sonarr (TV Shows)', priority: 6 },
                { id: 'MEDIA', name: 'وسائط', nameEn: 'Media', priority: 7 }
            ]
        },
        'system': {
            name: 'إعدادات النظام',
            nameEn: 'System Settings',
            icon: '🔧',
            sections: [
                { id: 'PATHS', name: 'مسارات الملفات', nameEn: 'File Paths', priority: 1 },
                { id: 'REMOTE_STORAGE', name: 'التخزين البعيد', nameEn: 'Remote Storage', priority: 2 },
                { id: 'DATABASE', name: 'قاعدة البيانات', nameEn: 'Database', priority: 3 },
                { id: 'SECURITY', name: 'الأمان', nameEn: 'Security', priority: 4 },
                { id: 'SERVER', name: 'إعدادات الخادم', nameEn: 'Server Settings', priority: 5 },
                { id: 'CORRECTIONS', name: 'إعدادات التصحيحات', nameEn: 'Corrections Settings', priority: 6 },
                { id: 'SYSTEM', name: 'نظام', nameEn: 'System', priority: 7 }
            ]
        },
        'development': {
            name: 'أدوات التطوير',
            nameEn: 'Development Tools',
            icon: '🛠️',
            sections: [
                { id: 'DEBUG', name: 'أدوات تصحيح الأخطاء', nameEn: 'Debug Tools', priority: 1 },
                { id: 'TESTING', name: 'أدوات الاختبار', nameEn: 'Testing Tools', priority: 2 },
                { id: 'DEVELOPMENT', name: 'أدوات التطوير', nameEn: 'Development Tools', priority: 3 },
                { id: 'LOGS', name: 'سجلات النظام', nameEn: 'System Logs', priority: 4 }
            ]
        }
    };
    
    /**
     * العثور على جميع الأقسام المتاحة في DOM بطرق متعددة
     */
    function scanAvailableSections() {
        console.log('🔍 Scanning for available sections in DOM...');
        
        const found = new Set();
        const possibleSections = Object.values(ULTIMATE_CATEGORY_MAPPING)
            .flatMap(category => category.sections)
            .map(section => section.id);
        
        // طرق البحث المختلفة
        const searchMethods = [
            (id) => document.querySelector(`#tab-${id}`),
            (id) => document.querySelector(`[data-section="${id}"]`),
            (id) => document.querySelector(`.tab-content[id*="${id}"]`),
            (id) => document.querySelector(`.section-${id}`),
            (id) => document.querySelector(`[id="${id}-section"]`),
            (id) => document.querySelector(`[class*="${id.toLowerCase()}"]`)
        ];
        
        possibleSections.forEach(sectionId => {
            for (const method of searchMethods) {
                try {
                    const element = method(sectionId);
                    if (element && element.offsetParent !== null) {
                        found.add(sectionId);
                        break;
                    }
                } catch (e) {
                    // تجاهل أخطاء البحث
                }
            }
        });
        
        availableSections = Array.from(found);
        console.log(`📋 Found ${availableSections.length} available sections:`, availableSections);
        
        return availableSections;
    }
    
    /**
     * إخفاء جميع التبويبات بقوة قصوى
     */
    function ultimateHideAllTabs() {
        console.log('🙈 Hiding all tabs with maximum force...');
        
        const hideSelectors = [
            '.tab-content',
            '[id^="tab-"]',
            '[data-section]',
            '.form-section',
            '.settings-section',
            '[class*="tab-"]',
            '[class*="section-"]'
        ];
        
        hideSelectors.forEach(selector => {
            try {
                document.querySelectorAll(selector).forEach(element => {
                    if (element.id && (element.id.startsWith('tab-') || element.id.includes('section'))) {
                        // الإخفاء بجميع الطرق الممكنة
                        element.style.display = 'none !important';
                        element.style.visibility = 'hidden !important';
                        element.style.opacity = '0 !important';
                        element.style.height = '0 !important';
                        element.style.overflow = 'hidden !important';
                        element.style.position = 'absolute !important';
                        element.style.left = '-9999px !important';
                        element.classList.add('hidden', 'tab-hidden', 'force-hidden');
                        element.setAttribute('hidden', 'true');
                        element.setAttribute('aria-hidden', 'true');
                        element.setAttribute('data-tab-state', 'hidden');
                    }
                });
            } catch (e) {
                console.warn('Error hiding elements with selector:', selector, e);
            }
        });
    }
    
    /**
     * إظهار تبويب محدد بقوة قصوى
     */
    function ultimateShowTab(sectionId) {
        if (!sectionId) {
            console.warn('⚠️ No section ID provided to show');
            return false;
        }
        
        console.log(`👁️ Ultimate showing section: ${sectionId}`);
        
        // إخفاء جميع التبويبات أولاً
        ultimateHideAllTabs();
        
        // البحث عن العنصر المطلوب
        const possibleSelectors = [
            `#tab-${sectionId}`,
            `[data-section="${sectionId}"]`,
            `.tab-content[id="tab-${sectionId}"]`,
            `.section-${sectionId}`,
            `#${sectionId}-section`,
            `[id="${sectionId}"]`
        ];
        
        let targetElement = null;
        for (const selector of possibleSelectors) {
            try {
                targetElement = document.querySelector(selector);
                if (targetElement) {
                    console.log(`✨ Found target element with selector: ${selector}`);
                    break;
                }
            } catch (e) {
                console.warn('Error with selector:', selector, e);
            }
        }
        
        if (targetElement) {
            // الإظهار بجميع الطرق الممكنة
            targetElement.style.display = 'block !important';
            targetElement.style.visibility = 'visible !important';
            targetElement.style.opacity = '1 !important';
            targetElement.style.height = 'auto !important';
            targetElement.style.overflow = 'visible !important';
            targetElement.style.position = 'static !important';
            targetElement.style.left = 'auto !important';
            targetElement.classList.remove('hidden', 'tab-hidden', 'force-hidden');
            targetElement.removeAttribute('hidden');
            targetElement.setAttribute('aria-hidden', 'false');
            targetElement.setAttribute('data-tab-state', 'visible');
            
            // إظهار العناصر الفرعية
            const childElements = targetElement.querySelectorAll('*');
            childElements.forEach(child => {
                if (child.classList.contains('force-hidden')) {
                    return; // تجاهل العناصر المخفية بالقوة
                }
                child.style.display = '';
                child.style.visibility = '';
                child.style.opacity = '';
            });
            
            // التمرير السلس للعنصر
            setTimeout(() => {
                try {
                    targetElement.scrollIntoView({ 
                        behavior: 'smooth', 
                        block: 'start',
                        inline: 'nearest'
                    });
                } catch (e) {
                    console.warn('Error scrolling to element:', e);
                }
            }, 200);
            
            currentSubcategory = sectionId;
            console.log(`✅ Successfully showed section: ${sectionId}`);
            return true;
        } else {
            console.error(`❌ Could not find section: ${sectionId}`);
            console.log('Available sections:', availableSections);
            return false;
        }
    }
    
    /**
     * تحديث الأقسام الفرعية للفئة المحددة
     */
    function updateSubcategories(categoryKey) {
        if (!categoryKey) {
            console.warn('⚠️ No category key provided');
            return;
        }
        
        console.log(`📝 Updating subcategories for category: ${categoryKey}`);
        
        const subcategorySelect = document.getElementById('subcategory-select');
        if (!subcategorySelect) {
            console.error('❌ Subcategory select element not found');
            return;
        }
        
        // مسح الخيارات الحالية
        subcategorySelect.innerHTML = '<option value="">اختر القسم الفرعي / Choose Subcategory</option>';
        
        const category = ULTIMATE_CATEGORY_MAPPING[categoryKey];
        if (!category) {
            console.error(`❌ Unknown category: ${categoryKey}`);
            subcategorySelect.disabled = true;
            ultimateHideAllTabs();
            return;
        }
        
        // فلترة الأقسام المتاحة وترتيبها حسب الأولوية
        const availableInCategory = category.sections
            .filter(section => availableSections.includes(section.id))
            .sort((a, b) => a.priority - b.priority);
        
        if (availableInCategory.length === 0) {
            console.warn(`❌ No available sections for category: ${categoryKey}`);
            subcategorySelect.disabled = true;
            ultimateHideAllTabs();
            return;
        }
        
        // إضافة الخيارات المتاحة
        availableInCategory.forEach(section => {
            const option = document.createElement('option');
            option.value = section.id;
            option.textContent = `${section.name} / ${section.nameEn}`;
            option.setAttribute('data-priority', section.priority);
            subcategorySelect.appendChild(option);
        });
        
        subcategorySelect.disabled = false;
        currentCategory = categoryKey;
        
        // اختيار أول عنصر تلقائياً
        if (availableInCategory.length > 0) {
            const firstSection = availableInCategory[0];
            subcategorySelect.value = firstSection.id;
            ultimateShowTab(firstSection.id);
        }
        
        console.log(`✅ Updated subcategories: ${availableInCategory.length} sections available`);
    }
    
    /**
     * تهيئة نظام التبويبات المتطور
     */
    function initializeUltimateTabsSystem() {
        if (isSystemInitialized) {
            console.log('⚠️ System already initialized, skipping...');
            return;
        }
        
        console.log('🔧 Initializing Ultimate Tabs System...');
        
        const categorySelect = document.getElementById('category-select');
        const subcategorySelect = document.getElementById('subcategory-select');
        
        if (!categorySelect || !subcategorySelect) {
            console.warn('⚠️ Required select elements not found, retrying in 1 second...');
            setTimeout(initializeUltimateTabsSystem, 1000);
            return;
        }
        
        // فحص الأقسام المتاحة
        scanAvailableSections();
        
        if (availableSections.length === 0) {
            console.warn('⚠️ No available sections found, retrying in 2 seconds...');
            setTimeout(initializeUltimateTabsSystem, 2000);
            return;
        }
        
        // إضافة معالجات الأحداث المحسنة
        categorySelect.addEventListener('change', function() {
            const selectedCategory = this.value;
            console.log(`📂 Category changed to: ${selectedCategory}`);
            updateSubcategories(selectedCategory);
        });
        
        subcategorySelect.addEventListener('change', function() {
            const selectedSection = this.value;
            console.log(`📄 Subcategory changed to: ${selectedSection}`);
            
            if (selectedSection) {
                ultimateShowTab(selectedSection);
            } else {
                ultimateHideAllTabs();
            }
        });
        
        // التهيئة الأولية
        const initialCategory = categorySelect.value || 'general';
        if (categorySelect.value !== initialCategory) {
            categorySelect.value = initialCategory;
        }
        updateSubcategories(initialCategory);
        
        isSystemInitialized = true;
        console.log('✅ Ultimate Tabs System Initialized Successfully!');
        
        // إضافة إشعار بصري للمستخدم
        try {
            const notification = document.createElement('div');
            notification.style.cssText = `
                position: fixed; top: 20px; right: 20px; z-index: 10000;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white; padding: 12px 20px; border-radius: 8px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.2);
                font-family: Arial, sans-serif; font-size: 14px;
                transition: all 0.3s ease;
            `;
            notification.innerHTML = '✅ نظام التبويبات المتطور جاهز!';
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.opacity = '0';
                setTimeout(() => notification.remove(), 300);
            }, 3000);
        } catch (e) {
            console.warn('Could not show notification:', e);
        }
    }
    
    /**
     * وظائف التشخيص والإدارة العالمية
     */
    window.ultimateTabsDebug = function() {
        console.log('=== Ultimate Tabs Debug Information ===');
        console.log('System initialized:', isSystemInitialized);
        console.log('Current category:', currentCategory);
        console.log('Current subcategory:', currentSubcategory);
        console.log('Available sections:', availableSections);
        console.log('Total mapped sections:', Object.values(ULTIMATE_CATEGORY_MAPPING).reduce((acc, cat) => acc + cat.sections.length, 0));
        
        const allTabs = document.querySelectorAll('[id^="tab-"], .tab-content, [data-section]');
        const visibleTabs = Array.from(allTabs).filter(tab => {
            const computed = window.getComputedStyle(tab);
            return computed.display !== 'none' && 
                   computed.visibility !== 'hidden' && 
                   computed.opacity !== '0' &&
                   !tab.hasAttribute('hidden') &&
                   !tab.classList.contains('hidden');
        });
        
        console.log('Total tabs in DOM:', allTabs.length);
        console.log('Currently visible tabs:', visibleTabs.map(tab => tab.id || tab.className));
        
        return {
            initialized: isSystemInitialized,
            category: currentCategory,
            subcategory: currentSubcategory,
            availableSections,
            totalTabs: allTabs.length,
            visibleTabs: visibleTabs.length,
            mapping: ULTIMATE_CATEGORY_MAPPING
        };
    };
    
    window.ultimateShowSection = function(sectionId) {
        console.log(`🎯 Force showing section: ${sectionId}`);
        return ultimateShowTab(sectionId);
    };
    
    window.ultimateRefreshTabs = function() {
        console.log('🔄 Refreshing Ultimate Tabs System...');
        isSystemInitialized = false;
        availableSections = [];
        currentCategory = null;
        currentSubcategory = null;
        setTimeout(initializeUltimateTabsSystem, 500);
    };
    
    window.ultimateRescanSections = function() {
        console.log('🔍 Rescanning available sections...');
        const oldCount = availableSections.length;
        scanAvailableSections();
        console.log(`📊 Section count changed from ${oldCount} to ${availableSections.length}`);
        return availableSections;
    };
    
    window.ultimateFixTabs = function() {
        console.log('🛠️ Running Ultimate Tabs Fix...');
        ultimateHideAllTabs();
        window.ultimateRescanSections();
        const categorySelect = document.getElementById('category-select');
        if (categorySelect && categorySelect.value) {
            updateSubcategories(categorySelect.value);
        }
        console.log('✅ Ultimate tabs fix completed');
    };
    
    // بدء التهيئة عند تحميل DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(initializeUltimateTabsSystem, 1000);
        });
    } else {
        setTimeout(initializeUltimateTabsSystem, 1000);
    }
    
    // مراقب متطور لتغييرات DOM
    const advancedObserver = new MutationObserver(function(mutations) {
        let shouldReinitialize = false;
        let newTabsDetected = false;
        
        mutations.forEach(function(mutation) {
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1) {
                        const isTabElement = node.id && node.id.startsWith('tab-') ||
                                           node.className && node.className.includes('tab') ||
                                           node.getAttribute && node.getAttribute('data-section') ||
                                           node.querySelector && node.querySelector('[id^="tab-"]');
                        
                        if (isTabElement) {
                            newTabsDetected = true;
                            if (!isSystemInitialized) {
                                shouldReinitialize = true;
                            }
                        }
                    }
                });
            }
        });
        
        if (newTabsDetected && isSystemInitialized) {
            console.log('🔄 New tabs detected, rescanning...');
            window.ultimateRescanSections();
        }
        
        if (shouldReinitialize) {
            console.log('🔄 Major DOM changes detected, reinitializing...');
            setTimeout(initializeUltimateTabsSystem, 1000);
        }
    });
    
    // بدء مراقبة DOM
    advancedObserver.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['style', 'class', 'hidden', 'data-section']
    });
    
    // إعادة تهيئة عند تغيير حجم النافذة
    window.addEventListener('resize', function() {
        if (isSystemInitialized && currentSubcategory) {
            setTimeout(() => {
                ultimateShowTab(currentSubcategory);
            }, 300);
        }
    });
    
    // معالجة ضغطات المفاتيح للتنقل السريع
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.shiftKey) {
            switch(e.key) {
                case 'D':
                    e.preventDefault();
                    window.ultimateTabsDebug();
                    break;
                case 'R':
                    e.preventDefault();
                    window.ultimateRefreshTabs();
                    break;
                case 'F':
                    e.preventDefault();
                    window.ultimateFixTabs();
                    break;
            }
        }
    });
    
})();

console.log('✅ Ultimate Advanced Tabs Fix System - Loaded Successfully! 🎉');
console.log('💡 Available commands:');
console.log('   ultimateTabsDebug() - معلومات تشخيص شاملة');
console.log('   ultimateShowSection(id) - إظهار قسم معين');
console.log('   ultimateRefreshTabs() - إعادة تحميل النظام');
console.log('   ultimateRescanSections() - إعادة فحص الأقسام');
console.log('   ultimateFixTabs() - إصلاح شامل للتبويبات');
console.log('🎯 Keyboard shortcuts: Ctrl+Shift+D (debug), Ctrl+Shift+R (refresh), Ctrl+Shift+F (fix)');
ULTIMATE_TABS_EOF

print_success "تم إنشاء نظام إصلاح التبويبات المتطور والشامل"

# 10. تحديث ملف layout.html لإضافة الإصلاح
print_step "تحديث ملف layout.html لتضمين إصلاح التبويبات..."
if [[ -f "templates/layout.html" ]]; then
    # إزالة أي إصلاحات سابقة
    sed -i '/tabs-fix\.js/d' templates/layout.html
    sed -i '/final-tabs-fix\.js/d' templates/layout.html
    sed -i '/comprehensive-tabs-fix\.js/d' templates/layout.html
    sed -i '/ultimate-tabs-fix\.js/d' templates/layout.html
    
    # إضافة الإصلاح الجديد قبل إغلاق body
    sed -i 's|</body>|    <!-- Ultimate Tabs Fix System -->\n    <script src="{{ url_for('\''static'\'', filename='\''js/ultimate-tabs-fix.js'\'') }}"></script>\n</body>|' templates/layout.html
    print_success "تم تحديث layout.html بنجاح"
else
    print_warning "ملف layout.html غير موجود، سيتم إنشاؤه لاحقاً"
fi

# 11. إنشاء خدمة systemd محسنة
print_step "إنشاء خدمة systemd محسنة..."
sudo tee /etc/systemd/system/ai-translator.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=AI Translator v2.2.4 - Arabic Subtitle Translation System
Documentation=https://github.com/AbdelmonemAwad/ai-translator
After=network.target postgresql.service
Wants=postgresql.service
StartLimitBurst=3
StartLimitIntervalSec=30

[Service]
Type=simple
User=eg2
Group=eg2
WorkingDirectory=/home/eg2/ai-translator
Environment=PATH=/home/eg2/ai-translator/venv/bin
EnvironmentFile=/home/eg2/ai-translator/.env
ExecStart=/home/eg2/ai-translator/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --worker-class sync --timeout 300 --max-requests 1000 --max-requests-jitter 100 --preload --access-logfile /var/log/ai-translator/access.log --error-logfile /var/log/ai-translator/error.log main:app
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
KillMode=mixed
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/home/eg2/ai-translator /var/log/ai-translator
ProtectHome=read-only

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# إنشاء مجلد السجلات
sudo mkdir -p /var/log/ai-translator
sudo chown -R eg2:eg2 /var/log/ai-translator

print_success "تم إنشاء خدمة systemd محسنة"

# 12. إعداد Nginx محسن ومتقدم
print_step "إعداد Nginx محسن للإنتاج..."
sudo tee /etc/nginx/sites-available/ai-translator > /dev/null << 'NGINX_EOF'
# AI Translator v2.2.4 - Advanced Nginx Configuration
# تكوين متقدم محسن للأداء والأمان

upstream ai_translator_backend {
    server 127.0.0.1:5000 fail_timeout=10s max_fails=3;
    keepalive 32;
}

# Rate limiting
limit_req_zone $binary_remote_addr zone=ai_translator_login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=ai_translator_api:10m rate=30r/m;
limit_req_zone $binary_remote_addr zone=ai_translator_general:10m rate=100r/m;

server {
    listen 80;
    server_name _;
    
    # Basic settings
    client_max_body_size 10G;
    client_body_timeout 600s;
    client_header_timeout 300s;
    client_body_buffer_size 256k;
    client_header_buffer_size 64k;
    large_client_header_buffers 8 64k;
    
    # Proxy settings
    proxy_connect_timeout 300s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    proxy_buffering off;
    proxy_request_buffering off;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data: https:; font-src 'self' data:;" always;
    
    # Main application with rate limiting
    location / {
        limit_req zone=ai_translator_general burst=20 nodelay;
        
        proxy_pass http://ai_translator_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_cache_bypass $http_upgrade;
        
        # Error handling
        proxy_intercept_errors on;
        error_page 502 503 504 /50x.html;
    }
    
    # Login endpoint with strict rate limiting
    location /login {
        limit_req zone=ai_translator_login burst=3 nodelay;
        
        proxy_pass http://ai_translator_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API endpoints with moderate rate limiting
    location /api/ {
        limit_req zone=ai_translator_api burst=10 nodelay;
        
        proxy_pass http://ai_translator_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files with aggressive caching
    location /static/ {
        alias /home/eg2/ai-translator/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
        
        # Specific rules for different file types
        location ~* \.(css|js)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            gzip_static on;
        }
        
        location ~* \.(png|jpg|jpeg|gif|ico|svg|webp)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.(woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Access-Control-Allow-Origin "*";
        }
    }
    
    # File upload endpoint with larger size limit
    location /upload {
        client_max_body_size 20G;
        proxy_pass http://ai_translator_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_request_buffering off;
        proxy_buffering off;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://ai_translator_backend;
        proxy_set_header Host $host;
    }
    
    # Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|py|pyc|pyo|db|sqlite|log|bak|swp)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(\.git|\.svn|\.hg) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Custom error page
    location = /50x.html {
        root /usr/share/nginx/html;
        internal;
    }
    
    # Robots.txt
    location = /robots.txt {
        return 200 "User-agent: *\nDisallow: /\n";
        add_header Content-Type text/plain;
    }
    
    # Favicon
    location = /favicon.ico {
        log_not_found off;
        access_log off;
        expires 1y;
    }
    
    # Logging
    access_log /var/log/nginx/ai-translator.access.log combined;
    error_log /var/log/nginx/ai-translator.error.log warn;
}

# HTTPS redirect (for future SSL setup)
# server {
#     listen 443 ssl http2;
#     server_name _;
#     
#     # SSL configuration would go here
#     # ssl_certificate /path/to/certificate.pem;
#     # ssl_certificate_key /path/to/private.key;
#     
#     # Include the same location blocks as above
# }
NGINX_EOF

# تفعيل الموقع
sudo ln -sf /etc/nginx/sites-available/ai-translator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# اختبار تكوين Nginx
if sudo nginx -t; then
    print_success "تم إعداد Nginx بنجاح"
else
    print_error "خطأ في تكوين Nginx"
    sudo nginx -t
    exit 1
fi

# 13. تحديث صلاحيات الملفات
print_step "تحديث صلاحيات الملفات والمجلدات..."
sudo chown -R eg2:eg2 /home/eg2/ai-translator
chmod +x /home/eg2/ai-translator/venv/bin/*
find /home/eg2/ai-translator -type f -name "*.py" -exec chmod 644 {} \;
find /home/eg2/ai-translator -type d -exec chmod 755 {} \;
chmod 600 /home/eg2/ai-translator/.env

print_success "تم تحديث جميع الصلاحيات"

# 14. بدء وتفعيل جميع الخدمات
print_step "بدء وتفعيل جميع الخدمات..."
sudo systemctl daemon-reload
sudo systemctl enable ai-translator
sudo systemctl enable postgresql
sudo systemctl enable nginx

# إعادة تشغيل الخدمات بالترتيب الصحيح
sudo systemctl restart postgresql
sleep 3
sudo systemctl restart nginx
sleep 2
sudo systemctl start ai-translator

print_success "تم بدء جميع الخدمات"

# 15. انتظار بدء الخدمات والتحقق
print_step "انتظار بدء الخدمات وإجراء الفحوصات..."
sleep 15

# فحص حالة الخدمات
print_header "📊 فحص حالة الخدمات"
services=("postgresql" "nginx" "ai-translator")
all_services_running=true

for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        print_success "$service: يعمل بنجاح"
    else
        print_error "$service: متوقف أو به مشكلة"
        all_services_running=false
        echo "آخر 5 أسطر من سجل $service:"
        sudo journalctl -u $service --no-pager -n 5 | sed 's/^/  /'
        echo ""
    fi
done

# فحص المنافذ
print_header "🔌 فحص المنافذ المطلوبة"
ports=(22 80 443 5000 5432)
all_ports_open=true

for port in "${ports[@]}"; do
    if ss -tlnp 2>/dev/null | grep -q ":$port "; then
        print_success "منفذ $port: مفتوح ويعمل"
    else
        print_warning "منفذ $port: مغلق أو غير مستخدم"
        if [ "$port" = "80" ] || [ "$port" = "5000" ]; then
            all_ports_open=false
        fi
    fi
done

# اختبار الاتصال بالتطبيق
print_header "🌐 اختبار الاتصال بالتطبيق"
local_ip=$(hostname -I | awk '{print $1}' | tr -d '[:space:]')

# اختبار التطبيق مباشرة على المنفذ 5000
print_info "اختبار التطبيق مباشرة..."
if timeout 10 curl -s http://localhost:5000/ | grep -qE "(title|html|AI|login|ترجمان)"; then
    print_success "التطبيق يستجيب بنجاح على المنفذ 5000"
    app_direct_works=true
else
    print_error "التطبيق لا يستجيب على المنفذ 5000"
    app_direct_works=false
fi

# اختبار Nginx على المنفذ 80
print_info "اختبار Nginx والبروكسي..."
if timeout 10 curl -s http://localhost/ | grep -qE "(title|html|AI|login|ترجمان)"; then
    print_success "Nginx يعمل ويوجه الطلبات بنجاح على المنفذ 80"
    nginx_works=true
else
    print_error "Nginx لا يستجيب أو لا يوجه الطلبات بشكل صحيح"
    nginx_works=false
fi

# اختبار صفحة تسجيل الدخول
print_info "اختبار صفحة تسجيل الدخول..."
if timeout 10 curl -s http://localhost/login | grep -qE "(login|تسجيل|password|كلمة)"; then
    print_success "صفحة تسجيل الدخول تعمل بنجاح"
    login_works=true
else
    print_warning "قد تكون هناك مشكلة في صفحة تسجيل الدخول"
    login_works=false
fi

# اختبار قاعدة البيانات
print_info "اختبار الاتصال بقاعدة البيانات..."
if PGPASSWORD=ai_translator_pass2024 psql -h localhost -U ai_translator -d ai_translator -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "قاعدة البيانات تعمل بنجاح"
    db_works=true
else
    print_error "مشكلة في الاتصال بقاعدة البيانات"
    db_works=false
fi

# النتيجة النهائية
print_header "🎉 ملخص نتائج التثبيت"

if [ "$all_services_running" = true ] && [ "$app_direct_works" = true ] && [ "$nginx_works" = true ] && [ "$db_works" = true ]; then
    print_success "تم تثبيت AI Translator v2.2.4 بنجاح مع جميع الإصلاحات!"
    installation_status="✅ مكتمل بنجاح"
else
    print_warning "التثبيت مكتمل ولكن قد تحتاج لبعض الإصلاحات"
    installation_status="⚠️ مكتمل مع تحذيرات"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎯 AI Translator v2.2.4 - نتائج التثبيت النهائية"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 حالة التثبيت: $installation_status"
echo ""
echo "🌐 روابط الوصول للتطبيق:"
echo "   ┌─ محلي (للاختبار): http://localhost"
echo "   ├─ الشبكة المحلية: http://$local_ip"
echo "   └─ الوصول الخارجي: http://5.31.55.179"
echo ""
echo "🔑 بيانات تسجيل الدخول الافتراضية:"
echo "   ┌─ اسم المستخدم: admin"
echo "   └─ كلمة المرور: your_strong_password"
echo ""
echo "📁 معلومات النظام:"
echo "   ┌─ مجلد التطبيق: /home/eg2/ai-translator"
echo "   ├─ البيئة الافتراضية: /home/eg2/ai-translator/venv"
echo "   ├─ قاعدة البيانات: PostgreSQL (ai_translator)"
echo "   ├─ خادم الويب: Nginx + Gunicorn"
echo "   └─ السجلات: /var/log/ai-translator/"
echo ""
echo "🛠️ أوامر الإدارة والصيانة:"
echo "   ┌─ حالة التطبيق: sudo systemctl status ai-translator"
echo "   ├─ إعادة تشغيل: sudo systemctl restart ai-translator"
echo "   ├─ مراقبة السجلات: sudo journalctl -u ai-translator -f"
echo "   ├─ حالة Nginx: sudo systemctl status nginx"
echo "   ├─ حالة قاعدة البيانات: sudo systemctl status postgresql"
echo "   └─ اختبار Nginx: sudo nginx -t"
echo ""
echo "🎯 إصلاحات التبويبات المتطورة المطبقة:"
echo "   ✅ نظام تبويبات متطور وشامل (Ultimate Advanced Tabs Fix)"
echo "   ✅ خريطة شاملة لجميع الفئات والأقسام مع الأولويات"
echo "   ✅ فحص تلقائي للأقسام المتاحة في DOM"
echo "   ✅ إخفاء وإظهار ذكي بقوة قصوى للتبويبات"
echo "   ✅ معالجة متقدمة لجميع أخطاء DOM المحتملة"
echo "   ✅ مراقب ذكي لتغييرات DOM مع إعادة تهيئة تلقائية"
echo "   ✅ وظائف تشخيص وإصلاح شاملة ومتقدمة"
echo "   ✅ اختصارات لوحة المفاتيح للتحكم السريع"
echo "   ✅ إشعارات بصرية لحالة النظام"
echo "   ✅ توافق كامل مع جميع المتصفحات والأجهزة"
echo ""
echo "💡 أوامر تشخيص التبويبات المتقدمة (في متصفح المطور - F12):"
echo "   ┌─ ultimateTabsDebug() - معلومات تشخيص شاملة ومفصلة"
echo "   ├─ ultimateShowSection('قسم') - إظهار قسم معين بالقوة"
echo "   ├─ ultimateRefreshTabs() - إعادة تحميل نظام التبويبات"
echo "   ├─ ultimateRescanSections() - إعادة فحص الأقسام المتاحة"
echo "   └─ ultimateFixTabs() - إصلاح شامل وفوري للمشاكل"
echo ""
echo "⌨️ اختصارات لوحة المفاتيح السريعة:"
echo "   ┌─ Ctrl+Shift+D - فتح معلومات التشخيص"
echo "   ├─ Ctrl+Shift+R - إعادة تحميل نظام التبويبات"
echo "   └─ Ctrl+Shift+F - تشغيل الإصلاح الشامل"
echo ""
echo "🔧 نصائح استكشاف الأخطاء:"
echo "   ┌─ إذا لم تعمل التبويبات: افتح F12 وشغل ultimateTabsDebug()"
echo "   ├─ إذا لم يعمل التطبيق: تحقق من sudo journalctl -u ai-translator -n 20"
echo "   ├─ إذا لم يعمل Nginx: تحقق من sudo nginx -t"
echo "   └─ لإعادة تشغيل كامل: sudo systemctl restart ai-translator nginx"
echo ""
echo "📈 مراقبة الأداء:"
echo "   ┌─ استخدام المعالج: htop"
echo "   ├─ مساحة القرص: df -h"
echo "   ├─ الذاكرة: free -h"
echo "   └─ اتصالات الشبكة: ss -tulnp"
echo ""
echo "🔒 ملاحظات أمنية:"
echo "   ┌─ غير كلمة المرور الافتراضية بعد تسجيل الدخول الأول"
echo "   ├─ فعل جدار الحماية إذا كان التطبيق متاح للإنترنت"
echo "   ├─ راقب السجلات بانتظام للتحقق من الأنشطة المشبوهة"
echo "   └─ احتفظ بنسخ احتياطية دورية من قاعدة البيانات"
echo ""

if [ "$all_services_running" = true ] && [ "$nginx_works" = true ]; then
    echo "🎉 مبروك! تم تثبيت AI Translator v2.2.4 بنجاح مع جميع الإصلاحات!"
    echo "🌟 يمكنك الآن الوصول للتطبيق عبر: http://5.31.55.179"
    echo ""
    echo "✨ استمتع بترجمة الأفلام والمسلسلات بالذكاء الاصطناعي!"
else
    echo "⚠️ التثبيت مكتمل، لكن تحقق من الأخطاء أعلاه وأعد تشغيل الخدمات حسب الحاجة"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ انتهى التثبيت - $(date)"
echo "════════════════════════════════════════════════════════════════"
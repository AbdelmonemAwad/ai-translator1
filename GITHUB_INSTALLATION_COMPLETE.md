# AI Translator v2.2.5 - Complete GitHub Installation Guide

## الطرق المتوفرة للتثبيت

### 1. التثبيت المباشر من GitHub (الطريقة المفضلة)

```bash
# تحميل وتثبيت مباشر من المستودع
curl -fsSL https://raw.githubusercontent.com/AbdelmonemAwad/ai-translator1/main/install_fixed.sh | bash

# أو تحميل سكريبت التثبيت الموثوق
curl -fsSL https://raw.githubusercontent.com/AbdelmonemAwad/ai-translator1/main/install_fixed_reliable.sh | bash
```

### 2. استنساخ المستودع والتثبيت اليدوي

```bash
# استنساخ المستودع
git clone https://github.com/AbdelmonemAwad/ai-translator1.git
cd ai-translator1

# تشغيل سكريبت التثبيت
chmod +x install_fixed.sh
sudo ./install_fixed.sh

# أو استخدام السكريبت الموثوق
chmod +x install_fixed_reliable.sh
sudo ./install_fixed_reliable.sh
```

### 3. التثبيت باستخدام الحزمة المضغوطة

```bash
# تحميل الحزمة الكاملة
wget https://github.com/AbdelmonemAwad/ai-translator1/archive/refs/heads/main.zip
unzip main.zip
cd ai-translator1-main

# تشغيل التثبيت
chmod +x install_universal.sh
sudo ./install_universal.sh
```

## روابط مهمة

- **المستودع الرئيسي:** https://github.com/AbdelmonemAwad/ai-translator1
- **دليل التثبيت:** https://github.com/AbdelmonemAwad/ai-translator1#installation
- **الوثائق:** https://github.com/AbdelmonemAwad/ai-translator1/blob/main/README.md
- **دليل Ubuntu Server:** https://github.com/AbdelmonemAwad/ai-translator1/blob/main/UBUNTU_SERVER_INSTALLATION_GUIDE.md

## الأوامر السريعة للتثبيت

### Ubuntu Server (الطريقة الموصى بها)

```bash
# تحديث النظام أولاً
sudo apt update && sudo apt upgrade -y

# تثبيت Git إذا لم يكن مثبتاً
sudo apt install -y git curl wget

# تثبيت AI Translator
curl -fsSL https://raw.githubusercontent.com/AbdelmonemAwad/ai-translator1/main/install_fixed_reliable.sh | sudo bash
```

### للمستخدمين العاديين (بدون صلاحيات root)

```bash
# استنساخ في مجلد المستخدم
git clone https://github.com/AbdelmonemAwad/ai-translator1.git ~/ai-translator
cd ~/ai-translator

# تثبيت في بيئة افتراضية
./install_fixed.sh --user
```

## متطلبات النظام

- **نظام التشغيل:** Ubuntu 20.04+ / 22.04+ / 24.04+
- **Python:** 3.9+ (يفضل 3.11+)
- **قاعدة البيانات:** PostgreSQL 14+
- **الذاكرة:** 2GB RAM كحد أدنى (يفضل 4GB+)
- **التخزين:** 10GB مساحة حرة كحد أدنى

## بعد التثبيت

```bash
# فحص حالة الخدمة
sudo systemctl status ai-translator

# الوصول للتطبيق
# http://YOUR_SERVER_IP
# أو http://localhost إذا كان محلياً

# بيانات الدخول الافتراضية:
# المستخدم: admin
# كلمة المرور: your_strong_password
```

## استكشاف الأخطاء

### مشكلة تلف ملفات ZIP
```bash
# استخدم سكريبت التثبيت الموثوق
curl -fsSL https://raw.githubusercontent.com/AbdelmonemAwad/ai-translator1/main/install_fixed_reliable.sh | sudo bash
```

### مشاكل الصلاحيات
```bash
# تأكد من تشغيل الأوامر مع sudo
sudo -i
curl -fsSL https://raw.githubusercontent.com/AbdelmonemAwad/ai-translator1/main/install_fixed.sh | bash
```

### مشاكل قاعدة البيانات
```bash
# إعادة تهيئة قاعدة البيانات
sudo -u postgres createdb ai_translator
sudo systemctl restart ai-translator
```
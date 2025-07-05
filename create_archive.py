#!/usr/bin/env python3
import os
import tarfile
import shutil

# إنشاء مجلد مؤقت
temp_dir = 'ai_translator_github'
if os.path.exists(temp_dir):
    shutil.rmtree(temp_dir)
os.makedirs(temp_dir)

# قائمة الملفات والمجلدات المطلوبة
files_to_copy = [
    'README_GITHUB.md',
    'RELEASES.md',
    'CONTRIBUTING.md', 
    'DEPENDENCIES.md',
    '.gitignore',
    'app.py',
    'main.py',
    'models.py',
    'database_setup.py',
    'translations.py',
    'install.sh'
]

folders_to_copy = ['templates', 'static', 'services']

# نسخ الملفات
for file in files_to_copy:
    if os.path.exists(file):
        shutil.copy2(file, temp_dir)
        print(f"تم نسخ: {file}")

# نسخ المجلدات
for folder in folders_to_copy:
    if os.path.exists(folder):
        shutil.copytree(folder, os.path.join(temp_dir, folder))
        print(f"تم نسخ مجلد: {folder}")

# إنشاء الأرشيف
archive_name = 'ai-translator-github-final.tar.gz'
with tarfile.open(archive_name, 'w:gz') as tar:
    tar.add(temp_dir, arcname='ai-translator')

# تنظيف المجلد المؤقت
shutil.rmtree(temp_dir)

print(f"\n✅ تم إنشاء الأرشيف: {archive_name}")
print(f"الحجم: {os.path.getsize(archive_name)} bytes")
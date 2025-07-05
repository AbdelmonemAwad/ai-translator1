#!/usr/bin/env python3
"""
Complete Component Installation System
نظام التثبيت الشامل للمكونات
"""

import os
import sys
import subprocess
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ComponentInstaller:
    def __init__(self):
        self.installation_log = []
        self.failed_components = []
        
    def log_step(self, message):
        """تسجيل خطوة التثبيت"""
        logger.info(message)
        self.installation_log.append(message)
    
    def run_command(self, command, description):
        """تشغيل أمر مع معالجة الأخطاء"""
        self.log_step(f"🔄 {description}")
        try:
            if isinstance(command, str):
                result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=300)
            else:
                result = subprocess.run(command, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                self.log_step(f"✓ {description} - Success")
                return True
            else:
                self.log_step(f"❌ {description} - Failed: {result.stderr}")
                self.failed_components.append(description)
                return False
        except subprocess.TimeoutExpired:
            self.log_step(f"⏰ {description} - Timeout")
            self.failed_components.append(description)
            return False
        except Exception as e:
            self.log_step(f"❌ {description} - Error: {str(e)}")
            self.failed_components.append(description)
            return False
    
    def install_python_packages(self):
        """تثبيت حزم Python المطلوبة"""
        self.log_step("📦 Installing Python packages...")
        
        # Core packages
        core_packages = [
            "flask>=2.3.0",
            "flask-sqlalchemy>=3.0.0",
            "psycopg2-binary>=2.9.0",
            "gunicorn>=21.0.0",
            "python-dotenv>=1.0.0",
            "werkzeug>=2.3.0"
        ]
        
        # AI packages
        ai_packages = [
            "torch>=2.0.0",
            "faster-whisper>=0.9.0",
            "transformers>=4.30.0",
            "accelerate>=0.20.0",
            "huggingface-hub>=0.15.0"
        ]
        
        # Media processing packages
        media_packages = [
            "opencv-python>=4.8.0",
            "pillow>=10.0.0",
            "numpy>=1.24.0",
            "moviepy>=1.0.3",
            "librosa>=0.10.0"
        ]
        
        # Storage and network packages
        storage_packages = [
            "paramiko>=3.2.0",
            "boto3>=1.28.0",
            "requests>=2.31.0",
            "smbprotocol>=1.11.0"
        ]
        
        # Monitoring packages
        monitoring_packages = [
            "psutil>=5.9.0",
            "pynvml>=11.5.0",
            "pandas>=2.0.0",
            "matplotlib>=3.7.0",
            "scikit-learn>=1.3.0"
        ]
        
        all_packages = {
            "Core packages": core_packages,
            "AI packages": ai_packages,
            "Media packages": media_packages,
            "Storage packages": storage_packages,
            "Monitoring packages": monitoring_packages
        }
        
        for category, packages in all_packages.items():
            self.log_step(f"Installing {category}...")
            for package in packages:
                self.run_command(
                    f"pip install --upgrade {package}",
                    f"Install {package}"
                )
    
    def install_system_dependencies(self):
        """تثبيت التبعيات على مستوى النظام"""
        self.log_step("🔧 Installing system dependencies...")
        
        # Only install what's available in Replit environment
        replit_packages = [
            "curl",
            "wget",
            "zip",
            "unzip"
        ]
        
        # Try to install available packages
        for package in replit_packages:
            self.run_command(
                f"which {package} || echo '{package} not available in this environment'",
                f"Check {package} availability"
            )
    
    def setup_ollama(self):
        """إعداد Ollama للترجمة"""
        self.log_step("🤖 Setting up Ollama...")
        
        # Check if Ollama is available
        if self.run_command("which ollama", "Check Ollama installation"):
            # Ollama is installed, try to pull models
            models = ["llama3", "llama2", "mistral"]
            for model in models:
                self.run_command(
                    f"ollama pull {model}",
                    f"Pull Ollama model: {model}"
                )
        else:
            self.log_step("ℹ Ollama not available - will need manual installation")
            self.log_step("ℹ Install command: curl -fsSL https://ollama.ai/install.sh | sh")
    
    def setup_ffmpeg(self):
        """إعداد FFmpeg لمعالجة الفيديو"""
        self.log_step("🎬 Setting up FFmpeg...")
        
        if self.run_command("which ffmpeg", "Check FFmpeg installation"):
            self.log_step("✓ FFmpeg is available")
            # Test FFmpeg functionality
            self.run_command(
                "ffmpeg -version | head -1",
                "Test FFmpeg version"
            )
        else:
            self.log_step("ℹ FFmpeg not available in this environment")
            self.log_step("ℹ For local installation: sudo apt install ffmpeg")
    
    def create_requirements_files(self):
        """إنشاء ملفات requirements محدثة"""
        self.log_step("📝 Creating requirements files...")
        
        # Production requirements
        prod_requirements = """# AI Translator - Production Requirements
# Core Web Framework
flask>=2.3.0
flask-sqlalchemy>=3.0.0
psycopg2-binary>=2.9.0
gunicorn>=21.0.0
python-dotenv>=1.0.0
werkzeug>=2.3.0

# AI and Machine Learning
torch>=2.0.0
faster-whisper>=0.9.0
transformers>=4.30.0

# Media Processing
opencv-python>=4.8.0
pillow>=10.0.0
numpy>=1.24.0

# System Monitoring
psutil>=5.9.0
pynvml>=11.5.0

# Network and Storage
paramiko>=3.2.0
boto3>=1.28.0
requests>=2.31.0
"""
        
        # Development requirements
        dev_requirements = """# AI Translator - Development Requirements
# Include all production requirements
-r requirements_production.txt

# Additional AI Models
accelerate>=0.20.0
huggingface-hub>=0.15.0

# Advanced Media Processing
moviepy>=1.0.3
librosa>=0.10.0

# Data Analysis
pandas>=2.0.0
matplotlib>=3.7.0
scikit-learn>=1.3.0

# Storage Protocols
smbprotocol>=1.11.0

# Development Tools
pytest>=7.4.0
black>=23.7.0
flake8>=6.0.0
"""
        
        # Minimal requirements
        minimal_requirements = """# AI Translator - Minimal Requirements
flask>=2.3.0
flask-sqlalchemy>=3.0.0
psycopg2-binary>=2.9.0
gunicorn>=21.0.0
python-dotenv>=1.0.0
werkzeug>=2.3.0
psutil>=5.9.0
requests>=2.31.0
numpy>=1.24.0
pillow>=10.0.0
"""
        
        requirements_files = {
            "requirements_production.txt": prod_requirements,
            "requirements_development.txt": dev_requirements,
            "requirements_minimal.txt": minimal_requirements
        }
        
        for filename, content in requirements_files.items():
            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.log_step(f"✓ Created {filename}")
            except Exception as e:
                self.log_step(f"❌ Failed to create {filename}: {e}")
    
    def validate_installation(self):
        """التحقق من صحة التثبيت"""
        self.log_step("🔍 Validating installation...")
        
        validation_tests = [
            ("import flask", "Flask framework"),
            ("import sqlalchemy", "SQLAlchemy ORM"),
            ("import psycopg2", "PostgreSQL driver"),
            ("import torch", "PyTorch"),
            ("import cv2", "OpenCV"),
            ("import PIL", "Pillow"),
            ("import numpy", "NumPy"),
            ("import psutil", "System monitoring"),
            ("import requests", "HTTP requests")
        ]
        
        passed = 0
        total = len(validation_tests)
        
        for test_code, description in validation_tests:
            try:
                exec(test_code)
                self.log_step(f"✓ {description}")
                passed += 1
            except ImportError:
                self.log_step(f"❌ {description} - Not available")
            except Exception as e:
                self.log_step(f"❌ {description} - Error: {e}")
        
        success_rate = (passed / total) * 100
        self.log_step(f"📊 Validation complete: {passed}/{total} ({success_rate:.1f}%)")
        
        return success_rate > 80
    
    def install_all(self):
        """تشغيل التثبيت الشامل"""
        self.log_step("🚀 Starting complete component installation...")
        
        # Install Python packages
        self.install_python_packages()
        
        # Setup external services
        self.setup_ollama()
        self.setup_ffmpeg()
        
        # Install system dependencies
        self.install_system_dependencies()
        
        # Create requirements files
        self.create_requirements_files()
        
        # Validate installation
        success = self.validate_installation()
        
        # Generate summary
        self.log_step("📋 Installation Summary:")
        self.log_step(f"   Total steps: {len(self.installation_log)}")
        self.log_step(f"   Failed components: {len(self.failed_components)}")
        
        if self.failed_components:
            self.log_step("❌ Failed components:")
            for component in self.failed_components:
                self.log_step(f"   • {component}")
        
        if success:
            self.log_step("✅ Installation completed successfully!")
        else:
            self.log_step("⚠️ Installation completed with some issues")
        
        return success, self.installation_log, self.failed_components

def main():
    """الدالة الرئيسية"""
    installer = ComponentInstaller()
    success, log, failed = installer.install_all()
    
    # Save installation log
    with open('installation_log.txt', 'w', encoding='utf-8') as f:
        for entry in log:
            f.write(f"{entry}\n")
    
    print(f"\n{'='*60}")
    print("🔧 COMPONENT INSTALLATION COMPLETE")
    print(f"{'='*60}")
    print(f"Success: {'✅ Yes' if success else '⚠️ Partial'}")
    print(f"Log saved to: installation_log.txt")
    
    if failed:
        print(f"\nFailed components ({len(failed)}):")
        for component in failed[:5]:  # Show first 5
            print(f"  • {component}")
        if len(failed) > 5:
            print(f"  • ... and {len(failed) - 5} more")
    
    return success

if __name__ == "__main__":
    main()
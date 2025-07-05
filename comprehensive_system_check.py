#!/usr/bin/env python3
"""
Comprehensive System Check for AI Translator
فحص شامل للنظام للترجمان الآلي
"""

import os
import sys
import json
import logging
import subprocess
from datetime import datetime
from pathlib import Path

# إعداد السجلات
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SystemChecker:
    def __init__(self):
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'system_info': {},
            'dependencies': {},
            'database': {},
            'files': {},
            'services': {},
            'performance': {},
            'issues': [],
            'recommendations': []
        }
    
    def check_system_info(self):
        """فحص معلومات النظام الأساسية"""
        logger.info("🔍 Checking system information...")
        
        try:
            import platform
            import psutil
            
            self.results['system_info'] = {
                'platform': platform.platform(),
                'python_version': platform.python_version(),
                'architecture': platform.architecture()[0],
                'processor': platform.processor(),
                'memory_total': f"{psutil.virtual_memory().total / (1024**3):.2f} GB",
                'memory_available': f"{psutil.virtual_memory().available / (1024**3):.2f} GB",
                'disk_usage': f"{psutil.disk_usage('/').percent}%",
                'cpu_count': psutil.cpu_count(),
                'cpu_percent': psutil.cpu_percent(interval=1)
            }
            logger.info("✓ System information collected")
            
        except Exception as e:
            logger.error(f"❌ Error collecting system info: {e}")
            self.results['issues'].append(f"System info collection failed: {e}")
    
    def check_dependencies(self):
        """فحص التبعيات والمكتبات المطلوبة"""
        logger.info("🔍 Checking dependencies...")
        
        required_packages = {
            'core': ['flask', 'sqlalchemy', 'psycopg2-binary', 'gunicorn'],
            'ai_models': ['torch', 'faster-whisper', 'transformers'],
            'media': ['opencv-python', 'pillow', 'numpy', 'moviepy'],
            'storage': ['paramiko', 'boto3', 'requests'],
            'monitoring': ['psutil', 'pynvml'],
            'utils': ['python-dotenv', 'werkzeug']
        }
        
        for category, packages in required_packages.items():
            self.results['dependencies'][category] = {}
            
            for package in packages:
                try:
                    if package == 'opencv-python':
                        import cv2
                        version = cv2.__version__
                    elif package == 'pillow':
                        from PIL import Image
                        version = Image.__version__
                    elif package == 'psycopg2-binary':
                        import psycopg2
                        version = psycopg2.__version__
                    elif package == 'python-dotenv':
                        import dotenv
                        version = "installed"
                    else:
                        module = __import__(package.replace('-', '_'))
                        version = getattr(module, '__version__', 'unknown')
                    
                    self.results['dependencies'][category][package] = {
                        'status': 'installed',
                        'version': version
                    }
                    logger.info(f"✓ {package}: {version}")
                    
                except ImportError:
                    self.results['dependencies'][category][package] = {
                        'status': 'missing',
                        'version': None
                    }
                    logger.warning(f"⚠ {package}: Missing")
                    self.results['issues'].append(f"Missing dependency: {package}")
                    
                except Exception as e:
                    self.results['dependencies'][category][package] = {
                        'status': 'error',
                        'version': None,
                        'error': str(e)
                    }
                    logger.error(f"❌ {package}: Error - {e}")
    
    def check_database(self):
        """فحص قاعدة البيانات والجداول"""
        logger.info("🔍 Checking database...")
        
        try:
            from app import app
            from models import db
            
            with app.app_context():
                # فحص الاتصال
                db.session.execute('SELECT 1')
                self.results['database']['connection'] = 'success'
                logger.info("✓ Database connection successful")
                
                # فحص الجداول
                result = db.session.execute("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'
                """)
                tables = [row[0] for row in result]
                
                self.results['database']['tables'] = {}
                for table in tables:
                    try:
                        count_result = db.session.execute(f"SELECT COUNT(*) FROM {table}")
                        count = count_result.scalar()
                        self.results['database']['tables'][table] = {
                            'exists': True,
                            'record_count': count
                        }
                        logger.info(f"✓ Table {table}: {count} records")
                    except Exception as e:
                        self.results['database']['tables'][table] = {
                            'exists': True,
                            'error': str(e)
                        }
                        logger.error(f"❌ Table {table}: Error - {e}")
                
        except Exception as e:
            self.results['database']['connection'] = 'failed'
            self.results['database']['error'] = str(e)
            logger.error(f"❌ Database check failed: {e}")
            self.results['issues'].append(f"Database connection failed: {e}")
    
    def check_files(self):
        """فحص الملفات الأساسية"""
        logger.info("🔍 Checking essential files...")
        
        essential_files = [
            'app.py', 'main.py', 'models.py', 'database_setup.py',
            'auth_manager.py', 'translations.py', 'gpu_manager.py',
            'background_tasks.py', 'process_video.py', 'system_monitor.py'
        ]
        
        template_dirs = ['templates', 'static']
        
        for file in essential_files:
            if os.path.exists(file):
                size = os.path.getsize(file)
                self.results['files'][file] = {
                    'exists': True,
                    'size': size,
                    'readable': os.access(file, os.R_OK)
                }
                logger.info(f"✓ {file}: {size} bytes")
            else:
                self.results['files'][file] = {'exists': False}
                logger.warning(f"⚠ {file}: Missing")
                self.results['issues'].append(f"Missing file: {file}")
        
        for directory in template_dirs:
            if os.path.exists(directory):
                file_count = len(list(Path(directory).rglob('*')))
                self.results['files'][directory] = {
                    'exists': True,
                    'type': 'directory',
                    'file_count': file_count
                }
                logger.info(f"✓ {directory}/: {file_count} files")
            else:
                self.results['files'][directory] = {'exists': False, 'type': 'directory'}
                logger.warning(f"⚠ {directory}/: Missing")
                self.results['issues'].append(f"Missing directory: {directory}")
    
    def check_external_services(self):
        """فحص الخدمات الخارجية"""
        logger.info("🔍 Checking external services...")
        
        services = {
            'ollama': 'http://localhost:11434/api/tags',
            'ffmpeg': 'ffmpeg -version'
        }
        
        # فحص Ollama
        try:
            import requests
            response = requests.get(services['ollama'], timeout=5)
            if response.status_code == 200:
                models = response.json().get('models', [])
                self.results['services']['ollama'] = {
                    'status': 'running',
                    'models': len(models),
                    'model_list': [m.get('name', 'unknown') for m in models[:5]]
                }
                logger.info(f"✓ Ollama: {len(models)} models available")
            else:
                self.results['services']['ollama'] = {'status': 'not_responding'}
                logger.warning("⚠ Ollama: Not responding")
        except Exception as e:
            self.results['services']['ollama'] = {'status': 'not_available', 'error': str(e)}
            logger.warning(f"⚠ Ollama: {e}")
        
        # فحص FFmpeg
        try:
            result = subprocess.run(['ffmpeg', '-version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                version_line = result.stdout.split('\n')[0]
                self.results['services']['ffmpeg'] = {
                    'status': 'available',
                    'version': version_line
                }
                logger.info(f"✓ FFmpeg: {version_line}")
            else:
                self.results['services']['ffmpeg'] = {'status': 'error'}
                logger.warning("⚠ FFmpeg: Command failed")
        except Exception as e:
            self.results['services']['ffmpeg'] = {'status': 'not_available', 'error': str(e)}
            logger.warning(f"⚠ FFmpeg: {e}")
    
    def check_gpu_support(self):
        """فحص دعم GPU"""
        logger.info("🔍 Checking GPU support...")
        
        try:
            import pynvml
            pynvml.nvmlInit()
            gpu_count = pynvml.nvmlDeviceGetCount()
            
            if gpu_count > 0:
                gpu_info = []
                for i in range(gpu_count):
                    handle = pynvml.nvmlDeviceGetHandleByIndex(i)
                    name = pynvml.nvmlDeviceGetName(handle)
                    memory = pynvml.nvmlDeviceGetMemoryInfo(handle)
                    gpu_info.append({
                        'id': i,
                        'name': name.decode('utf-8') if isinstance(name, bytes) else str(name),
                        'memory_total': f"{memory.total / (1024**3):.1f} GB",
                        'memory_used': f"{memory.used / (1024**3):.1f} GB"
                    })
                
                self.results['services']['gpu'] = {
                    'status': 'available',
                    'count': gpu_count,
                    'devices': gpu_info
                }
                logger.info(f"✓ GPU: {gpu_count} devices available")
            else:
                self.results['services']['gpu'] = {'status': 'no_devices'}
                logger.info("ℹ GPU: No devices detected")
                
        except Exception as e:
            self.results['services']['gpu'] = {'status': 'not_available', 'error': str(e)}
            logger.info(f"ℹ GPU: {e}")
    
    def generate_recommendations(self):
        """إنشاء التوصيات بناءً على النتائج"""
        logger.info("🔍 Generating recommendations...")
        
        # توصيات للتبعيات المفقودة
        missing_deps = []
        for category, packages in self.results['dependencies'].items():
            for package, info in packages.items():
                if info['status'] == 'missing':
                    missing_deps.append(package)
        
        if missing_deps:
            self.results['recommendations'].append({
                'type': 'install_dependencies',
                'title': 'Install Missing Dependencies',
                'description': f"Install missing packages: {', '.join(missing_deps)}",
                'command': f"pip install {' '.join(missing_deps)}"
            })
        
        # توصيات للخدمات
        if self.results['services']['ollama']['status'] != 'running':
            self.results['recommendations'].append({
                'type': 'install_ollama',
                'title': 'Install Ollama',
                'description': 'Ollama is required for AI translation',
                'command': 'curl -fsSL https://ollama.ai/install.sh | sh'
            })
        
        if self.results['services']['ffmpeg']['status'] != 'available':
            self.results['recommendations'].append({
                'type': 'install_ffmpeg',
                'title': 'Install FFmpeg',
                'description': 'FFmpeg is required for video processing',
                'command': 'sudo apt update && sudo apt install -y ffmpeg'
            })
        
        # توصيات للأداء
        memory_gb = float(self.results['system_info']['memory_total'].split()[0])
        if memory_gb < 8:
            self.results['recommendations'].append({
                'type': 'memory_warning',
                'title': 'Low Memory Warning',
                'description': f'System has {memory_gb:.1f} GB RAM. 8GB+ recommended for AI processing',
                'priority': 'medium'
            })
        
        cpu_usage = self.results['system_info']['cpu_percent']
        if cpu_usage > 80:
            self.results['recommendations'].append({
                'type': 'cpu_warning',
                'title': 'High CPU Usage',
                'description': f'CPU usage is {cpu_usage}%. Consider reducing load',
                'priority': 'high'
            })
    
    def run_full_check(self):
        """تشغيل الفحص الشامل"""
        logger.info("🚀 Starting comprehensive system check...")
        
        self.check_system_info()
        self.check_dependencies()
        self.check_database()
        self.check_files()
        self.check_external_services()
        self.check_gpu_support()
        self.generate_recommendations()
        
        # حساب النتيجة الإجمالية
        total_checks = 0
        passed_checks = 0
        
        # فحص التبعيات
        for category, packages in self.results['dependencies'].items():
            for package, info in packages.items():
                total_checks += 1
                if info['status'] == 'installed':
                    passed_checks += 1
        
        # فحص الملفات
        for file, info in self.results['files'].items():
            total_checks += 1
            if info['exists']:
                passed_checks += 1
        
        # فحص قاعدة البيانات
        if self.results['database'].get('connection') == 'success':
            passed_checks += 1
        total_checks += 1
        
        self.results['summary'] = {
            'total_checks': total_checks,
            'passed_checks': passed_checks,
            'success_rate': f"{(passed_checks/total_checks*100):.1f}%",
            'issues_count': len(self.results['issues']),
            'recommendations_count': len(self.results['recommendations'])
        }
        
        logger.info(f"✓ System check completed: {passed_checks}/{total_checks} checks passed")
        return self.results
    
    def save_report(self, filename=None):
        """حفظ التقرير إلى ملف"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"system_check_report_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        logger.info(f"✓ Report saved to {filename}")
        return filename

def main():
    """الدالة الرئيسية"""
    checker = SystemChecker()
    results = checker.run_full_check()
    
    # طباعة ملخص النتائج
    print("\n" + "="*60)
    print("🔍 COMPREHENSIVE SYSTEM CHECK REPORT")
    print("="*60)
    
    print(f"\n📊 Summary:")
    print(f"   Success Rate: {results['summary']['success_rate']}")
    print(f"   Checks Passed: {results['summary']['passed_checks']}/{results['summary']['total_checks']}")
    print(f"   Issues Found: {results['summary']['issues_count']}")
    print(f"   Recommendations: {results['summary']['recommendations_count']}")
    
    if results['issues']:
        print(f"\n⚠️  Issues Found:")
        for issue in results['issues'][:5]:  # Show first 5 issues
            print(f"   • {issue}")
        if len(results['issues']) > 5:
            print(f"   • ... and {len(results['issues']) - 5} more")
    
    if results['recommendations']:
        print(f"\n💡 Recommendations:")
        for rec in results['recommendations'][:3]:  # Show first 3 recommendations
            print(f"   • {rec['title']}: {rec['description']}")
        if len(results['recommendations']) > 3:
            print(f"   • ... and {len(results['recommendations']) - 3} more")
    
    # حفظ التقرير
    report_file = checker.save_report()
    print(f"\n📄 Full report saved to: {report_file}")
    
    return results

if __name__ == "__main__":
    main()
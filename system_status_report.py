#!/usr/bin/env python3
"""
System Status Report Generator
مولد تقرير حالة النظام
"""

import os
import json
from datetime import datetime

def generate_system_report():
    """إنشاء تقرير شامل لحالة النظام"""
    
    report = {
        'timestamp': datetime.now().isoformat(),
        'version': '2.2.5',
        'status': 'operational',
        'components': {},
        'database': {},
        'dependencies': {},
        'recommendations': []
    }
    
    # فحص المكونات الأساسية
    core_files = [
        'app.py', 'main.py', 'models.py', 'database_setup.py',
        'auth_manager.py', 'translations.py', 'gpu_manager.py',
        'background_tasks.py', 'process_video.py', 'system_monitor.py',
        'ai_integration_workaround.py'
    ]
    
    for file in core_files:
        if os.path.exists(file):
            size = os.path.getsize(file)
            report['components'][file] = {
                'status': 'available',
                'size': size,
                'readable': os.access(file, os.R_OK)
            }
        else:
            report['components'][file] = {'status': 'missing'}
    
    # فحص المجلدات المهمة
    directories = ['templates', 'static', 'services']
    for directory in directories:
        if os.path.exists(directory):
            file_count = len([f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))])
            report['components'][f'{directory}/'] = {
                'status': 'available',
                'type': 'directory',
                'file_count': file_count
            }
        else:
            report['components'][f'{directory}/'] = {'status': 'missing', 'type': 'directory'}
    
    # فحص التبعيات المتوفرة
    dependencies = [
        'flask', 'sqlalchemy', 'psycopg2', 'gunicorn', 'torch',
        'faster_whisper', 'cv2', 'PIL', 'numpy', 'psutil',
        'paramiko', 'boto3', 'requests'
    ]
    
    for dep in dependencies:
        try:
            if dep == 'cv2':
                import cv2 as module
            elif dep == 'PIL':
                import PIL as module
            elif dep == 'psycopg2':
                import psycopg2 as module
            else:
                module = __import__(dep)
            
            version = getattr(module, '__version__', 'unknown')
            report['dependencies'][dep] = {
                'status': 'installed',
                'version': str(version)
            }
        except ImportError:
            report['dependencies'][dep] = {'status': 'missing'}
        except Exception as e:
            report['dependencies'][dep] = {'status': 'error', 'error': str(e)}
    
    # فحص قاعدة البيانات
    try:
        from app import app
        from models import db
        with app.app_context():
            # Test connection
            db.session.execute('SELECT 1')
            report['database']['connection'] = 'success'
            
            # Check tables
            result = db.session.execute("""
                SELECT table_name, 
                       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
                FROM information_schema.tables t 
                WHERE table_schema = 'public'
            """)
            
            tables = {}
            for row in result:
                table_name = row[0]
                column_count = row[1]
                
                # Get record count
                try:
                    count_result = db.session.execute(f'SELECT COUNT(*) FROM "{table_name}"')
                    record_count = count_result.scalar()
                    tables[table_name] = {
                        'columns': column_count,
                        'records': record_count,
                        'status': 'operational'
                    }
                except Exception as e:
                    tables[table_name] = {
                        'columns': column_count,
                        'status': 'error',
                        'error': str(e)
                    }
            
            report['database']['tables'] = tables
            
    except Exception as e:
        report['database']['connection'] = 'failed'
        report['database']['error'] = str(e)
    
    # إضافة التوصيات
    missing_deps = [dep for dep, info in report['dependencies'].items() if info['status'] == 'missing']
    if missing_deps:
        report['recommendations'].append({
            'type': 'dependencies',
            'title': 'Missing Dependencies',
            'description': f"Install missing packages: {', '.join(missing_deps)}",
            'priority': 'medium'
        })
    
    missing_files = [file for file, info in report['components'].items() if info['status'] == 'missing']
    if missing_files:
        report['recommendations'].append({
            'type': 'files',
            'title': 'Missing Files',
            'description': f"Missing essential files: {', '.join(missing_files)}",
            'priority': 'high'
        })
    
    if report['database']['connection'] != 'success':
        report['recommendations'].append({
            'type': 'database',
            'title': 'Database Connection Issue',
            'description': 'Database connection failed - check configuration',
            'priority': 'high'
        })
    
    return report

def main():
    """الدالة الرئيسية"""
    print("🔍 Generating comprehensive system status report...")
    
    report = generate_system_report()
    
    # Save report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"system_status_report_{timestamp}.json"
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    # Print summary
    print(f"\n{'='*60}")
    print("📊 SYSTEM STATUS REPORT")
    print(f"{'='*60}")
    print(f"Version: {report['version']}")
    print(f"Status: {report['status']}")
    print(f"Database: {report['database'].get('connection', 'unknown')}")
    
    # Component summary
    available_components = sum(1 for info in report['components'].values() if info['status'] == 'available')
    total_components = len(report['components'])
    print(f"Components: {available_components}/{total_components} available")
    
    # Dependencies summary
    installed_deps = sum(1 for info in report['dependencies'].values() if info['status'] == 'installed')
    total_deps = len(report['dependencies'])
    print(f"Dependencies: {installed_deps}/{total_deps} installed")
    
    # Database tables
    if 'tables' in report['database']:
        table_count = len(report['database']['tables'])
        print(f"Database Tables: {table_count} tables found")
    
    # Recommendations
    if report['recommendations']:
        print(f"\n💡 Recommendations ({len(report['recommendations'])}):")
        for rec in report['recommendations']:
            priority_icon = "🔴" if rec['priority'] == 'high' else "🟡"
            print(f"   {priority_icon} {rec['title']}")
    else:
        print("\n✅ No critical issues found")
    
    print(f"\n📄 Full report saved to: {filename}")
    return filename

if __name__ == "__main__":
    main()
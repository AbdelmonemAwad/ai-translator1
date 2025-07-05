
#!/usr/bin/env python3
import paramiko
import time
import sys

def connect_and_diagnose():
    """الاتصال بالخادم وفحص التطبيق"""
    
    # بيانات الاتصال
    hostname = "94.203.60.118"
    username = "eg2"
    password = "1q1"
    port = 22
    
    print("🔍 إعادة فحص التطبيق على الخادم 94.203.60.118...")
    print("=" * 60)
    
    try:
        # إنشاء اتصال SSH
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        print(f"📡 محاولة الاتصال بـ {hostname}...")
        ssh.connect(hostname, port=port, username=username, password=password, timeout=15)
        print("✅ تم الاتصال بنجاح!")
        
        # قائمة الأوامر للفحص الشامل
        commands = [
            # فحص النظام الأساسي
            ("حالة النظام", "sudo -i -c 'uptime && free -h'"),
            
            # فحص الخدمات الأساسية
            ("خدمة AI Translator", "sudo -i -c 'systemctl status ai-translator --no-pager -l'"),
            ("خدمة Nginx", "sudo -i -c 'systemctl status nginx --no-pager -l'"),
            ("خدمة PostgreSQL", "sudo -i -c 'systemctl status postgresql --no-pager'"),
            
            # فحص العمليات النشطة
            ("العمليات النشطة", "sudo -i -c 'ps aux | grep -E \"(python|gunicorn|nginx|postgres)\" | grep -v grep'"),
            
            # فحص المنافذ
            ("المنافذ المفتوحة", "sudo -i -c 'ss -tlnp | grep -E \":80|:5000|:5432\"'"),
            
            # اختبار الاتصال المحلي
            ("Flask مباشرة", "sudo -i -c 'curl -I http://127.0.0.1:5000 2>/dev/null || echo \"فشل الاتصال\"'"),
            ("Nginx", "sudo -i -c 'curl -I http://127.0.0.1:80 2>/dev/null || echo \"فشل الاتصال\"'"),
            
            # فحص ملفات التكوين
            ("تكوين nginx", "sudo -i -c 'cat /etc/nginx/sites-enabled/ai-translator 2>/dev/null | head -20 || echo \"ملف التكوين غير موجود\"'"),
            ("ملفات nginx المفعلة", "sudo -i -c 'ls -la /etc/nginx/sites-enabled/'"),
            
            # فحص مجلد التطبيق
            ("مجلد التطبيق", "sudo -i -c 'ls -la /root/ai-translator/ | head -10 2>/dev/null || echo \"مجلد التطبيق غير موجود\"'"),
            ("ملفات Python", "sudo -i -c 'ls -la /root/ai-translator/*.py 2>/dev/null | head -5 || echo \"ملفات Python غير موجودة\"'"),
            
            # فحص قاعدة البيانات
            ("اتصال قاعدة البيانات", "sudo -i -c 'sudo -u postgres psql -c \"SELECT version();\" 2>/dev/null || echo \"فشل اتصال قاعدة البيانات\"'"),
            
            # اختبار المحتوى
            ("محتوى الصفحة الرئيسية", "sudo -i -c 'curl -s http://127.0.0.1:5000 2>/dev/null | head -5 || echo \"لا يوجد محتوى\"'"),
            ("فحص nginx للمحتوى", "sudo -i -c 'curl -s http://127.0.0.1:80 2>/dev/null | head -5 || echo \"لا يوجد محتوى من nginx\"'"),
            
            # السجلات الأخيرة
            ("سجلات AI Translator", "sudo -i -c 'journalctl -u ai-translator --no-pager -n 5 --since \"5 minutes ago\"'"),
            ("أخطاء nginx", "sudo -i -c 'tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo \"لا توجد أخطاء nginx\"'"),
            
            # الجدار الناري
            ("حالة الجدار الناري", "sudo -i -c 'ufw status numbered'"),
            
            # اختبار خارجي سريع
            ("اختبار خارجي", "curl -I http://94.203.60.118 --connect-timeout 10 2>/dev/null || echo 'فشل الاتصال الخارجي'"),
        ]
        
        results = {}
        issues = []
        recommendations = []
        
        for description, command in commands:
            print(f"\n🔧 {description}...")
            print("-" * 40)
            
            try:
                if command.startswith('curl -I http://94.203.60.118'):
                    # تنفيذ محلي للاختبار الخارجي
                    import subprocess
                    result = subprocess.run(command.split(), capture_output=True, text=True, timeout=10)
                    output = result.stdout + result.stderr
                else:
                    stdin, stdout, stderr = ssh.exec_command(command, timeout=30)
                    output = stdout.read().decode('utf-8', errors='ignore')
                    error = stderr.read().decode('utf-8', errors='ignore')
                    if error and 'warning' not in error.lower():
                        output += f"\nError: {error}"
                
                if output.strip():
                    print(output)
                    results[description] = output
                else:
                    print("لا توجد نتائج")
                    results[description] = "No output"
                    
            except Exception as e:
                error_msg = f"فشل تنفيذ الأمر: {str(e)}"
                print(f"❌ {error_msg}")
                results[description] = error_msg
                issues.append(f"{description}: {error_msg}")
        
        # تحليل النتائج
        print("\n" + "=" * 60)
        print("📊 تحليل شامل للنتائج")
        print("=" * 60)
        
        # فحص حالة الخدمات
        ai_status = results.get('خدمة AI Translator', '')
        nginx_status = results.get('خدمة Nginx', '')
        postgres_status = results.get('خدمة PostgreSQL', '')
        
        if 'active (running)' in ai_status:
            print("✅ خدمة AI Translator تعمل")
        else:
            print("❌ خدمة AI Translator متوقفة")
            issues.append("AI Translator service down")
            recommendations.append("sudo systemctl start ai-translator")
        
        if 'active (running)' in nginx_status:
            print("✅ Nginx يعمل")
        else:
            print("❌ Nginx متوقف")
            issues.append("Nginx service down")
            recommendations.append("sudo systemctl start nginx")
        
        if 'active (running)' in postgres_status:
            print("✅ PostgreSQL يعمل")
        else:
            print("❌ PostgreSQL متوقف")
            issues.append("PostgreSQL service down")
            recommendations.append("sudo systemctl start postgresql")
        
        # فحص المنافذ
        ports_output = results.get('المنافذ المفتوحة', '')
        if ':5000' in ports_output:
            print("✅ المنفذ 5000 مفتوح")
        else:
            print("❌ المنفذ 5000 مغلق")
            issues.append("Port 5000 not open")
        
        if ':80' in ports_output:
            print("✅ المنفذ 80 مفتوح")
        else:
            print("❌ المنفذ 80 مغلق")
            issues.append("Port 80 not open")
        
        # فحص الاستجابة
        flask_response = results.get('Flask مباشرة', '')
        nginx_response = results.get('Nginx', '')
        
        if 'HTTP/1.1 200' in flask_response or '200 OK' in flask_response:
            print("✅ Flask يستجيب")
        else:
            print("❌ Flask لا يستجيب")
            issues.append("Flask not responding")
        
        if 'HTTP/1.1 200' in nginx_response or '200 OK' in nginx_response:
            print("✅ Nginx يستجيب")
        else:
            print("❌ Nginx لا يستجيب")
            issues.append("Nginx not responding")
        
        # فحص المحتوى
        content_flask = results.get('محتوى الصفحة الرئيسية', '')
        content_nginx = results.get('فحص nginx للمحتوى', '')
        
        if 'AI Translator' in content_flask or 'الترجمان' in content_flask:
            print("✅ محتوى AI Translator موجود في Flask")
        else:
            print("❌ محتوى AI Translator غير موجود في Flask")
            issues.append("AI Translator content not found in Flask")
        
        if 'AI Translator' in content_nginx or 'الترجمان' in content_nginx:
            print("✅ محتوى AI Translator موجود في Nginx")
        else:
            print("❌ محتوى AI Translator غير موجود في Nginx")
            issues.append("AI Translator content not found in Nginx")
        
        # فحص التكوين
        nginx_config = results.get('تكوين nginx', '')
        if 'proxy_pass http://127.0.0.1:5000' in nginx_config:
            print("✅ تكوين nginx صحيح")
        else:
            print("❌ تكوين nginx غير صحيح")
            issues.append("Nginx configuration incorrect")
            recommendations.append("Fix nginx configuration")
        
        # الاختبار الخارجي
        external_test = results.get('اختبار خارجي', '')
        if 'HTTP/1.1 200' in external_test or '200 OK' in external_test:
            print("✅ الخادم يستجيب خارجياً")
        else:
            print("❌ الخادم لا يستجيب خارجياً")
            issues.append("External access failed")
        
        # ملخص المشاكل والحلول
        print("\n" + "=" * 60)
        print("🚨 المشاكل المكتشفة:")
        if issues:
            for i, issue in enumerate(issues, 1):
                print(f"  {i}. {issue}")
        else:
            print("  لا توجد مشاكل!")
        
        print("\n🔧 الحلول المقترحة:")
        if recommendations:
            for i, rec in enumerate(recommendations, 1):
                print(f"  {i}. {rec}")
        else:
            print("  لا توجد حلول مطلوبة!")
        
        print("\n🔗 أوامر الإصلاح السريع:")
        print("  sudo systemctl restart ai-translator nginx postgresql")
        print("  sudo nginx -t && sudo systemctl reload nginx")
        print("  curl -I http://94.203.60.118")
        
        ssh.close()
        print("\n✅ انتهى الفحص الشامل!")
        
    except paramiko.AuthenticationException:
        print("❌ فشل المصادقة - تحقق من بيانات الاعتماد")
    except paramiko.SSHException as e:
        print(f"❌ خطأ SSH: {str(e)}")
    except Exception as e:
        print(f"❌ خطأ عام: {str(e)}")

if __name__ == "__main__":
    connect_and_diagnose()

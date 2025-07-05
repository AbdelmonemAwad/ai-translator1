#!/usr/bin/env python3
"""Language Bridge - Simple Working Version"""

from flask import Flask, request, session, redirect

app = Flask(__name__)
app.secret_key = 'bridge-secret-key'

@app.route('/')
def home():
    if session.get('logged_in'):
        return f'''
<!DOCTYPE html>
<html dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>المترجم الذكي - Language Bridge</title>
    <style>
        body {{ font-family: Arial; background: linear-gradient(135deg, #667eea, #764ba2); margin: 0; color: white; }}
        .container {{ max-width: 800px; margin: 50px auto; text-align: center; }}
        .header {{ background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; margin-bottom: 30px; }}
        .nav {{ display: flex; gap: 20px; justify-content: center; margin: 20px 0; }}
        .nav a {{ color: white; text-decoration: none; padding: 10px 20px; background: rgba(255,255,255,0.2); border-radius: 8px; }}
        .nav a:hover {{ background: rgba(255,255,255,0.3); }}
        .form-box {{ background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; margin: 20px 0; }}
        textarea {{ width: 100%; height: 150px; padding: 15px; border: none; border-radius: 8px; margin: 10px 0; }}
        button {{ background: #ff6b6b; color: white; border: none; padding: 15px 30px; border-radius: 8px; cursor: pointer; font-size: 16px; }}
        button:hover {{ background: #ff5252; }}
        .footer {{ margin-top: 40px; opacity: 0.8; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌍 Language Bridge - المترجم الذكي</h1>
            <p>نظام الترجمة الذكية متعدد اللغات</p>
        </div>
        
        <div class="nav">
            <a href="/">🏠 الرئيسية</a>
            <a href="/translate">🔄 ترجمة</a>
            <a href="/history">📚 السجل</a>
            <a href="/logout">🚪 خروج</a>
        </div>
        
        <div class="form-box">
            <h2>مرحباً بك في Language Bridge</h2>
            <p>النظام الذكي للترجمة بين اللغات المختلفة</p>
            <p><strong>المستخدم:</strong> {session.get('username', 'admin')}</p>
            <p><strong>اللغات المدعومة:</strong> العربية، الإنجليزية، الفرنسية، الإسبانية</p>
            
            <div style="margin: 30px 0;">
                <a href="/translate" style="background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block;">
                    ابدأ الترجمة الآن
                </a>
            </div>
        </div>
        
        <div class="footer">
            <p>© 2025 Language Bridge | Developed with ❤️</p>
        </div>
    </div>
</body>
</html>
        '''
    else:
        return redirect('/login')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if username == 'admin' and password == 'admin123':
            session['logged_in'] = True
            session['username'] = username
            return redirect('/')
        else:
            error = "بيانات خاطئة! جرب: admin / admin123"
    else:
        error = ""
    
    return f'''
<!DOCTYPE html>
<html dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>تسجيل الدخول - Language Bridge</title>
    <style>
        body {{ font-family: Arial; background: linear-gradient(135deg, #667eea, #764ba2); margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }}
        .login-box {{ background: white; padding: 40px; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); width: 100%; max-width: 400px; text-align: center; }}
        .logo {{ font-size: 24px; font-weight: bold; color: #667eea; margin-bottom: 10px; }}
        .subtitle {{ color: #666; margin-bottom: 30px; }}
        .form-group {{ margin-bottom: 20px; text-align: right; }}
        label {{ display: block; margin-bottom: 5px; font-weight: bold; }}
        input {{ width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 8px; font-size: 16px; }}
        input:focus {{ outline: none; border-color: #667eea; }}
        button {{ width: 100%; padding: 12px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; }}
        button:hover {{ opacity: 0.9; }}
        .error {{ background: #ffebee; color: #c62828; padding: 10px; border-radius: 5px; margin-bottom: 20px; }}
        .credentials {{ background: #e8f5e8; color: #2e7d32; padding: 15px; border-radius: 8px; margin-top: 20px; font-size: 14px; }}
        .lang-toggle {{ margin-top: 20px; }}
        .lang-btn {{ padding: 5px 15px; margin: 0 5px; border: 1px solid #667eea; background: white; color: #667eea; border-radius: 5px; text-decoration: none; }}
        .lang-btn.active {{ background: #667eea; color: white; }}
    </style>
</head>
<body>
    <div class="login-box">
        <div class="logo">🌍 Language Bridge</div>
        <div class="subtitle">المترجم الذكي</div>
        
        {f'<div class="error">{error}</div>' if error else ''}
        
        <form method="POST">
            <div class="form-group">
                <label>اسم المستخدم</label>
                <input type="text" name="username" required>
            </div>
            <div class="form-group">
                <label>كلمة المرور</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit">تسجيل الدخول</button>
        </form>
        
        <div class="credentials">
            <strong>بيانات الدخول الافتراضية:</strong><br>
            Username: admin<br>
            Password: admin123
        </div>
        
        <div class="lang-toggle">
            <a href="?lang=ar" class="lang-btn active">العربية</a>
            <a href="?lang=en" class="lang-btn">English</a>
        </div>
    </div>
</body>
</html>
    '''

@app.route('/translate', methods=['GET', 'POST'])
def translate():
    if not session.get('logged_in'):
        return redirect('/login')
    
    result = ""
    if request.method == 'POST':
        text = request.form.get('text', '')
        if text:
            result = f"[مترجم] {text}"
    
    return f'''
<!DOCTYPE html>
<html dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>صفحة الترجمة - Language Bridge</title>
    <style>
        body {{ font-family: Arial; background: linear-gradient(135deg, #667eea, #764ba2); margin: 0; color: white; }}
        .container {{ max-width: 1000px; margin: 20px auto; }}
        .header {{ background: rgba(255,255,255,0.1); padding: 20px; border-radius: 15px; margin-bottom: 20px; text-align: center; }}
        .nav {{ display: flex; gap: 15px; justify-content: center; margin: 15px 0; }}
        .nav a {{ color: white; text-decoration: none; padding: 8px 16px; background: rgba(255,255,255,0.2); border-radius: 6px; }}
        .nav a:hover, .nav a.active {{ background: rgba(255,255,255,0.3); }}
        .translate-box {{ background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; }}
        .lang-selector {{ display: grid; grid-template-columns: 1fr auto 1fr; gap: 20px; margin-bottom: 20px; align-items: center; }}
        select {{ padding: 10px; border: none; border-radius: 6px; font-size: 16px; }}
        .swap-btn {{ background: #ff6b6b; color: white; border: none; padding: 10px; border-radius: 50%; cursor: pointer; font-size: 18px; }}
        .text-areas {{ display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0; }}
        textarea {{ width: 100%; height: 200px; padding: 15px; border: none; border-radius: 8px; font-size: 16px; }}
        .translate-btn {{ width: 100%; padding: 15px; background: #4CAF50; color: white; border: none; border-radius: 8px; font-size: 18px; cursor: pointer; }}
        .translate-btn:hover {{ background: #45a049; }}
        .success {{ background: rgba(76, 175, 80, 0.2); padding: 15px; border-radius: 8px; margin-bottom: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔄 صفحة الترجمة</h1>
        </div>
        
        <div class="nav">
            <a href="/">🏠 الرئيسية</a>
            <a href="/translate" class="active">🔄 ترجمة</a>
            <a href="/history">📚 السجل</a>
            <a href="/logout">🚪 خروج</a>
        </div>
        
        <div class="translate-box">
            {f'<div class="success">✓ تمت الترجمة بنجاح!</div>' if result else ''}
            
            <form method="POST">
                <div class="lang-selector">
                    <select name="from_lang">
                        <option value="ar">العربية</option>
                        <option value="en" selected>الإنجليزية</option>
                        <option value="fr">الفرنسية</option>
                        <option value="es">الإسبانية</option>
                    </select>
                    
                    <button type="button" class="swap-btn">⇄</button>
                    
                    <select name="to_lang">
                        <option value="ar" selected>العربية</option>
                        <option value="en">الإنجليزية</option>
                        <option value="fr">الفرنسية</option>
                        <option value="es">الإسبانية</option>
                    </select>
                </div>
                
                <div class="text-areas">
                    <textarea name="text" placeholder="أدخل النص المراد ترجمته هنا..." required>{request.form.get('text', '') if request.method == 'POST' else ''}</textarea>
                    <textarea placeholder="النص المترجم سيظهر هنا..." readonly>{result}</textarea>
                </div>
                
                <button type="submit" class="translate-btn">🔄 ترجم الآن</button>
            </form>
        </div>
    </div>
</body>
</html>
    '''

@app.route('/history')
def history():
    if not session.get('logged_in'):
        return redirect('/login')
    
    return '''
<!DOCTYPE html>
<html dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>سجل الترجمات - Language Bridge</title>
    <style>
        body { font-family: Arial; background: linear-gradient(135deg, #667eea, #764ba2); margin: 0; color: white; }
        .container { max-width: 1000px; margin: 20px auto; }
        .header { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 15px; margin-bottom: 20px; text-align: center; }
        .nav { display: flex; gap: 15px; justify-content: center; margin: 15px 0; }
        .nav a { color: white; text-decoration: none; padding: 8px 16px; background: rgba(255,255,255,0.2); border-radius: 6px; }
        .nav a:hover, .nav a.active { background: rgba(255,255,255,0.3); }
        .history-box { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📚 سجل الترجمات</h1>
        </div>
        
        <div class="nav">
            <a href="/">🏠 الرئيسية</a>
            <a href="/translate">🔄 ترجمة</a>
            <a href="/history" class="active">📚 السجل</a>
            <a href="/logout">🚪 خروج</a>
        </div>
        
        <div class="history-box">
            <h2>لا توجد ترجمات محفوظة بعد</h2>
            <p>ابدأ بترجمة النصوص وستظهر هنا</p>
            <a href="/translate" style="background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; margin-top: 20px;">
                إنشاء ترجمة جديدة
            </a>
        </div>
    </div>
</body>
</html>
    '''

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')

if __name__ == '__main__':
    print("🚀 Starting Language Bridge")
    print("🌐 Access at: http://localhost:5001")
    print("📱 Login: admin / admin123")
    app.run(host='0.0.0.0', port=5001, debug=False)
# AI Translator v2.2.5 - Installation Guide

## Quick Installation (Ubuntu Server)
```bash
# Download and extract
wget https://your-server.com/download/ai-translator-comprehensive-v2.2.5.zip
unzip ai-translator-comprehensive-v2.2.5.zip
cd ai-translator-comprehensive-v2.2.5/

# Install
chmod +x install_universal.sh
sudo ./install_universal.sh

# Start service
sudo systemctl start ai-translator
sudo systemctl enable ai-translator
```

## Manual Installation
1. Install Python 3.11+ and PostgreSQL 14+
2. Install requirements: `pip install -r requirements_production.txt`
3. Setup database: `python database_setup.py`
4. Run application: `gunicorn -b 0.0.0.0:5000 main:app`

## Default Credentials
- Username: admin
- Password: your_strong_password

## Support
- Documentation: README.md
- API Guide: API_DOCUMENTATION.md
- Requirements: REQUIREMENTS_ANALYSIS.md

@echo off
cd /d "%~dp0"
echo Starting S-Care Cloud... open http://localhost:8000 in your browser
python server.py
pause

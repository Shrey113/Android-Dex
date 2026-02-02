@echo off
echo ========================================
echo Building mDNS Service
echo ========================================

pyinstaller main.py --clean --noconfirm --onedir --noconsole --name mdns_service --contents-directory _internal --collect-submodules zeroconf --hidden-import socket --hidden-import json --hidden-import signal --hidden-import time --add-data "mdns_service.py;."

echo.
echo ========================================
echo Build Complete!
echo Executable location: dist\mdns_service\mdns_service.exe
echo ========================================
pause

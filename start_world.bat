@echo off
set BUNDLE_MODE=dev
cd gems\tef-manager
start bin\start_manager.bat
cd ..\tef-queuebert
start bin\start_queuebert.bat
cd ..\tef-worker-cuke_worker
start bin\start_cuke_worker.bat
cd ..\tef-cuke_keeper
start bin\start_cuke_keeper.bat
pause

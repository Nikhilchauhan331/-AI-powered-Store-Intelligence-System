@echo off
echo Starting Store Intelligence System - All 5 Cameras
echo ====================================================

powershell -NoProfile -Command "Start-Sleep -Seconds 3"
start "CAM_001 - Camera 1" powershell -NoProfile -Command "& { Set-Location -LiteralPath '%~dp0'; $env:VIDEO_SOURCE = 'data/CAM 1.mp4'; $env:CAMERA_ID = 'CAM_001'; & 'venv\Scripts\python.exe' -m src.pipeline.pipeline }"

powershell -NoProfile -Command "Start-Sleep -Seconds 3"
start "CAM_002 - Camera 2" powershell -NoProfile -Command "& { Set-Location -LiteralPath '%~dp0'; $env:VIDEO_SOURCE = 'data/CAM 2.mp4'; $env:CAMERA_ID = 'CAM_002'; & 'venv\Scripts\python.exe' -m src.pipeline.pipeline }"

powershell -NoProfile -Command "Start-Sleep -Seconds 3"
start "CAM_003 - Camera 3" powershell -NoProfile -Command "& { Set-Location -LiteralPath '%~dp0'; $env:VIDEO_SOURCE = 'data/CAM 3.mp4'; $env:CAMERA_ID = 'CAM_003'; & 'venv\Scripts\python.exe' -m src.pipeline.pipeline }"

powershell -NoProfile -Command "Start-Sleep -Seconds 3"
start "CAM_004 - Camera 4" powershell -NoProfile -Command "& { Set-Location -LiteralPath '%~dp0'; $env:VIDEO_SOURCE = 'data/CAM 4.mp4'; $env:CAMERA_ID = 'CAM_004'; & 'venv\Scripts\python.exe' -m src.pipeline.pipeline }"

start "CAM_005 - Camera 5" powershell -NoProfile -Command "& { Set-Location -LiteralPath '%~dp0'; $env:VIDEO_SOURCE = 'data/CAM 5.mp4'; $env:CAMERA_ID = 'CAM_005'; & 'venv\Scripts\python.exe' -m src.pipeline.pipeline }"

echo.
echo All 5 camera pipelines launched!
echo Check each terminal window for status.

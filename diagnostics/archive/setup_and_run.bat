@echo off
echo ========================================
echo MyCircle - Setup and Run Script
echo ========================================
echo.

:: Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Flutter is not installed or not in PATH!
    echo.
    echo Please follow these steps:
    echo 1. Download Flutter from: https://flutter.dev/docs/get-started/install/windows
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to your PATH environment variable
    echo 4. Restart this script
    echo.
    echo Opening download page...
    start https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo Flutter found! Checking version...
flutter --version
echo.

:: Install dependencies
echo Installing Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Failed to install dependencies
    pause
    exit /b 1
)

echo Dependencies installed successfully!
echo.

:: Check for connected devices
echo Checking for available devices...
flutter devices
echo.

:: Run the app
echo Starting the app...
echo.
echo Choose your target:
echo 1. Chrome (Web)
echo 2. Windows Desktop
echo 3. Android Emulator/Device
echo 4. List all devices
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    echo Running on Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo Running on Windows Desktop...
    flutter run -d windows
) else if "%choice%"=="3" (
    echo Running on Android...
    flutter run
) else if "%choice%"=="4" (
    flutter devices
    echo.
    set /p device="Enter device ID from above list: "
    flutter run -d %device%
) else (
    echo Invalid choice. Running on default device...
    flutter run
)

pause

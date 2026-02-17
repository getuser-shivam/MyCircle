# Flutter Windows Build Instructions

## Prerequisites

### 1. Install Flutter SDK
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract to a location (e.g., `C:\flutter`)
3. Add Flutter to your PATH:
   ```cmd
   set PATH=%PATH%;C:\flutter\bin
   ```
4. Or add permanently via System Environment Variables

### 2. Install Visual Studio 2022
1. Download Visual Studio 2022 Community Edition
2. Install with "Desktop development with C++" workload
3. Ensure Windows 10/11 SDK is installed

### 3. Enable Windows Desktop Support
```cmd
flutter config --enable-windows-desktop
```

### 4. Verify Installation
```cmd
flutter doctor -v
```

## Build Commands

### Development Build
```cmd
flutter run -d windows
```

### Release Build
```cmd
flutter build windows --release
```

### Profile Build (Performance Testing)
```cmd
flutter run -d windows --profile
```

### Build with Analysis
```cmd
flutter analyze
flutter build windows --release
```

## Build Output Location
Release builds are located at:
```
build\windows\x64\runner\Release\
```

## Troubleshooting

### Flutter Not Found in PATH
1. Close and reopen Command Prompt/PowerShell
2. Verify Flutter installation path
3. Manually add to PATH if needed

### Visual Studio Issues
1. Ensure "Desktop development with C++" is installed
2. Run Visual Studio Installer and modify installation
3. Restart after installation

### Build Errors
```cmd
flutter clean
flutter pub get
flutter build windows --release
```

### Windows SDK Issues
1. Install latest Windows 10/11 SDK
2. Verify through Visual Studio Installer
3. Restart Command Prompt

## CI/CD Build Script

### PowerShell Build Script (build.ps1)
```powershell
Write-Host "Starting Flutter Windows Build..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Build release
flutter build windows --release

# Check if build succeeded
if (Test-Path "build\windows\x64\runner\Release\my_circle.exe") {
    Write-Host "Build successful!"
    exit 0
} else {
    Write-Host "Build failed!"
    exit 1
}
```

### Batch Build Script (build.bat)
```batch
@echo off
echo Starting Flutter Windows Build...

REM Clean previous builds
flutter clean

REM Get dependencies
flutter pub get

REM Run tests
flutter test

REM Analyze code
flutter analyze

REM Build release
flutter build windows --release

REM Check if build succeeded
if exist "build\windows\x64\runner\Release\my_circle.exe" (
    echo Build successful!
    exit /b 0
) else (
    echo Build failed!
    exit /b 1
)
```

## Automated Testing

### Run All Tests
```cmd
flutter test --coverage
```

### Run Specific Test Categories
```cmd
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

### Performance Testing
```cmd
flutter run -d windows --profile
```

## Deployment

### Create Installer Package
```cmd
flutter build windows --release --msix
```

### Manual Distribution
1. Navigate to `build\windows\x64\runner\Release\`
2. Copy `my_circle.exe` and required DLLs
3. Create installer using NSIS or WiX Toolset

### Microsoft Store
1. Package as MSIX
2. Submit to Microsoft Partner Center
3. Follow store certification process

## Build Verification

### Pre-Build Checklist
- [ ] Flutter SDK installed and in PATH
- [ ] Visual Studio 2022 with C++ workload
- [ ] Windows Desktop support enabled
- [ ] All dependencies resolved
- [ ] Tests passing
- [ ] Code analysis clean

### Post-Build Verification
- [ ] Executable runs without errors
- [ ] All features functional
- [ ] Performance acceptable
- [ ] Memory usage within limits
- [ ] No security warnings

## Performance Optimization

### Build Flags
```cmd
flutter build windows --release --tree-shake-icons --split-debug-info
```

### Size Optimization
- Use `--tree-shake-icons` to remove unused assets
- Use `--split-debug-info` to separate debug symbols
- Compress final executable

### Memory Optimization
- Profile with Observatory
- Monitor memory usage during testing
- Optimize image assets and caching

## Security Considerations

### Code Signing
```cmd
signtool sign /f certificate.pfx /p password my_circle.exe
```

### Windows Defender
- Add application to exclusions if needed
- Submit for Microsoft SmartScreen screening
- Ensure code signing certificate is valid

## Build Automation

### GitHub Actions Workflow
```yaml
name: Build Windows Release
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v3
        with:
          name: windows-build
          path: build/windows/x64/runner/Release/
```

### Azure DevOps Pipeline
```yaml
trigger:
- main

pool:
  vmImage: 'windows-latest'

steps:
- task: FlutterInstall@1
  inputs:
    channel: 'stable'
    version: '3.10.0'
- script: flutter pub get
  displayName: 'Get Dependencies'
- script: flutter test
  displayName: 'Run Tests'
- script: flutter analyze
  displayName: 'Analyze Code'
- script: flutter build windows --release
  displayName: 'Build Release'
```

## Troubleshooting Common Issues

### "flutter: command not found"
- Install Flutter SDK
- Add to PATH environment variable
- Restart Command Prompt

### "No connected devices"
- Run `flutter devices` to verify
- Ensure Windows desktop support is enabled
- Check Visual Studio installation

### "Build failed with exit code 1"
- Check build logs for specific errors
- Ensure all dependencies are available
- Verify Windows SDK installation

### "Application crashes on startup"
- Check Event Viewer for crash details
- Run with `flutter run -d windows --verbose`
- Enable debug logging

### "High memory usage"
- Profile with Observatory
- Check for memory leaks
- Optimize image loading and caching

# Flutter Windows Build Script
Write-Host "Starting Flutter Windows Build for MyCircle..." -ForegroundColor Green

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter version: $flutterVersion" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Flutter not found in PATH!" -ForegroundColor Red
    Write-Host "Please install Flutter SDK and add to PATH" -ForegroundColor Yellow
    exit 1
}

# Check if Visual Studio is installed
try {
    $vsWhere = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vsPath = $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsPath) {
        Write-Host "Visual Studio found at: $vsPath" -ForegroundColor Cyan
    } else {
        Write-Host "WARNING: Visual Studio with C++ workload not found!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not verify Visual Studio installation" -ForegroundColor Yellow
}

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Run tests
Write-Host "Running tests..." -ForegroundColor Yellow
$testResult = flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Tests failed!" -ForegroundColor Red
    exit 1
}

# Analyze code
Write-Host "Analyzing code..." -ForegroundColor Yellow
$analyzeResult = flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Code analysis found issues!" -ForegroundColor Yellow
}

# Build release
Write-Host "Building release version..." -ForegroundColor Yellow
$buildResult = flutter build windows --release

# Check if build succeeded
$exePath = "build\windows\x64\runner\Release\my_circle.exe"
if (Test-Path $exePath) {
    Write-Host "SUCCESS: Build completed successfully!" -ForegroundColor Green
    Write-Host "Executable location: $exePath" -ForegroundColor Cyan
    
    # Get file size
    $fileInfo = Get-Item $exePath
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "File size: $sizeInMB MB" -ForegroundColor Cyan
    
    # List output files
    Write-Host "Output files:" -ForegroundColor Yellow
    Get-ChildItem "build\windows\x64\runner\Release\" | ForEach-Object {
        $size = if ($_.PSIsContainer) { "Directory" } else { 
            "$([math]::Round($_.Length / 1KB, 2)) KB"
        }
        Write-Host "  $($_.Name) - $size" -ForegroundColor Gray
    }
    
    exit 0
} else {
    Write-Host "ERROR: Build failed! Executable not found." -ForegroundColor Red
    Write-Host "Expected location: $exePath" -ForegroundColor Yellow
    exit 1
}

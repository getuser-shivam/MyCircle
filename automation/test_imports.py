#!/usr/bin/env python3
"""
Test script to verify all imports work correctly
"""

import sys
import os

print("Testing imports...")
print(f"Python version: {sys.version}")
print(f"Current directory: {os.getcwd()}")

# Test basic imports
try:
    import tkinter as tk
    print("✅ tkinter imported successfully")
except ImportError as e:
    print(f"❌ tkinter import failed: {e}")

# Test automation imports
try:
    from mycircle_automation import MyCircleAutomation
    print("✅ MyCircleAutomation imported successfully")
except ImportError as e:
    print(f"❌ MyCircleAutomation import failed: {e}")

try:
    from github_automation import GitHubAutomation
    print("✅ GitHubAutomation imported successfully")
except ImportError as e:
    print(f"❌ GitHubAutomation import failed: {e}")

try:
    from windsurf_integration import WindsurfIntegration
    print("✅ WindsurfIntegration imported successfully")
except ImportError as e:
    print(f"❌ WindsurfIntegration import failed: {e}")

# Test external dependencies
dependencies = [
    'PyGithub', 'openai', 'GitPython', 'PyYAML', 'requests'
]

for dep in dependencies:
    try:
        __import__(dep)
        print(f"✅ {dep} available")
    except ImportError:
        print(f"❌ {dep} missing")

print("\nTest complete!")

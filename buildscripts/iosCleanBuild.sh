#!/bin/bash

# Navigate to project root
cd "$(dirname "$0")/.."

# Basic Flutter clean
flutter clean

# Complete iOS cache clean
rm -rf ios/Pods ios/.symlinks ios/Flutter/Flutter.framework
rm -rf ~/Library/Developer/Xcode/DerivedData
pod cache clean --all

# Reinstall dependencies  
flutter pub get
cd ios && pod install --repo-update
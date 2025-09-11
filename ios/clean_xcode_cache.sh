#!/bin/bash

echo "🧹 Cleaning Xcode Cache and Derived Data"
echo "========================================"

echo ""
echo "📁 Removing Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/TrainViewer-*

echo ""
echo "🗂️  Removing Xcode Cache..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode

echo ""
echo "📦 Removing Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache

echo ""
echo "🧽 Removing iOS Device Support Cache..."
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport

echo ""
echo "✅ Cache cleanup complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Close Xcode completely"
echo "2. Reopen your project"
echo "3. Clean Build Folder: Product → Clean Build Folder"
echo "4. Build: Product → Build"
echo "5. Archive: Product → Archive"
echo ""
echo "This should resolve any cached validation errors."

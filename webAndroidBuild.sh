#!/bin/bash

# Build script for Flutter web application

echo "🚀 Starting build process..."

# Step 1: Build Flutter web application
echo "📦 Building Flutter web application..."
flutter build web --base-href "/sheet-routine-flutter/"

if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed!"
    exit 1
fi

echo "✅ Flutter build completed successfully!"

# Step 2: Delete ./docs folder contents
echo "🗑️  Cleaning ./docs directory..."
if [ -d "./docs" ]; then
    rm -rf ./docs/*
    echo "✅ ./docs directory cleaned"
else
    echo "📁 Creating ./docs directory..."
    mkdir -p ./docs
fi

# Step 3: Copy build/web contents to ./docs
echo "🗃️ Copying build files to ./docs..."
cp -r ./build/web/* ./docs/

echo "✅ Files copied successfully!"
echo "🎉 Build process completed!"
echo ""
echo "📂 Build output is now in: ./docs/"

echo "📦 Building Flutter Android app bundle for playstore..."
flutter build appbundle --release

if [ $? -ne 0 ]; then
    echo "❌ Flutter app bundle build failed!"
    exit 1
fi

echo "✅ Flutter app bundle build completed successfully!"
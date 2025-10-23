#!/bin/bash

# Proplinq Code Push Distribution Script
# Usage: ./distribute.sh [release-notes]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Proplinq Code Push Distribution${NC}"
echo "=================================="

# Check if release notes provided
RELEASE_NOTES=${1:-"Bug fixes and UI improvements"}

echo -e "${YELLOW}📝 Release Notes: $RELEASE_NOTES${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${RED}❌ Not logged into Firebase. Please run 'firebase login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Firebase CLI ready${NC}"

# Build the app
echo -e "${YELLOW}🔨 Building Flutter app...${NC}"
flutter build apk --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed. Please check your Flutter setup.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Get the APK path
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ APK not found at $APK_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 APK found: $APK_PATH${NCr}"

# You'll need to replace YOUR_ANDROID_APP_ID with your actual app ID from Firebase Console
echo -e "${YELLOW}⚠️  Please update YOUR_ANDROID_APP_ID in this script with your actual App ID from Firebase Console${NC}"
echo -e "${BLUE}💡 To find your App ID:${NC}"
echo "   1. In Firebase Console, click the gear icon ⚙️ next to 'Project Overview'"
echo "   2. Go to 'Project settings'"
echo "   3. Scroll to 'Your apps' section"
echo "   4. Click on your Android app"
echo "   5. Copy the App ID (looks like: 1:123456789:android:abcdef1234567890)"
echo ""
echo -e "${GREEN}🎯 Your project ID is: proplinq-1263e${NC}"

# Your actual App ID from Firebase Console
ANDROID_APP_ID="1:256669257357:android:6e79df14c7fa8105a8dcc4"

# Distribute to testers
echo -e "${YELLOW}🚀 Distributing to testers...${NC}"
firebase appdistribution:distribute "$APK_PATH" \
  --app "$ANDROID_APP_ID" \
  --groups "testers" \
  --release-notes "$RELEASE_NOTES"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Distribution successful!${NC}"
    echo -e "${BLUE}📱 Testers will receive notification to download the update${NC}"
else
    echo -e "${RED}❌ Distribution failed${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Add testers to your Firebase App Distribution group"
echo "2. Make UI changes in your Flutter app"
echo "3. Run this script to distribute updates"
echo ""
echo -e "${GREEN}🎉 Your app is ready for Code Push distribution!${NC}"

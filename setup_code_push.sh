#!/bin/bash

# Proplinq Code Push Setup Script
# This script helps you set up Firebase App Distribution for Code Push

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Proplinq Code Push Setup${NC}"
echo "=============================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Installing...${NC}"
    curl -sL https://firebase.tools | bash
    echo -e "${GREEN}✅ Firebase CLI installed${NC}"
else
    echo -e "${GREEN}✅ Firebase CLI already installed${NC}"
fi

# Check if user is logged in
echo -e "${YELLOW}🔐 Checking Firebase authentication...${NC}"
if firebase projects:list &> /dev/null; then
    echo -e "${GREEN}✅ Already logged into Firebase${NC}"
else
    echo -e "${YELLOW}⚠️  Please log into Firebase:${NC}"
    echo "   Run: firebase login"
    echo "   This will open a browser window for authentication"
fi

# Check if Firebase App Distribution package is installed
echo -e "${YELLOW}📦 Checking Flutter dependencies...${NC}"
if grep -q "firebase_app_distribution" pubspec.yaml; then
    echo -e "${GREEN}✅ Firebase App Distribution package already added${NC}"
else
    echo -e "${YELLOW}📦 Adding Firebase App Distribution package...${NC}"
    flutter pub add firebase_app_distribution
    echo -e "${GREEN}✅ Package added${NC}"
fi

# Get app package name for Android
echo -e "${YELLOW}📱 Getting Android package name...${NC}"
if [ -f "android/app/build.gradle" ]; then
    PACKAGE_NAME=$(grep -o 'applicationId "[^"]*"' android/app/build.gradle | cut -d'"' -f2)
    echo -e "${GREEN}✅ Android package name: $PACKAGE_NAME${NC}"
else
    echo -e "${RED}❌ Android build.gradle not found${NC}"
fi

# Get iOS bundle ID
echo -e "${YELLOW}🍎 Getting iOS bundle ID...${NC}"
if [ -f "ios/Runner/Info.plist" ]; then
    BUNDLE_ID=$(grep -A1 'CFBundleIdentifier' ios/Runner/Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo -e "${GREEN}✅ iOS bundle ID: $BUNDLE_ID${NC}"
else
    echo -e "${RED}❌ iOS Info.plist not found${NC}"
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Go to https://console.firebase.google.com"
echo "2. Select your project (or create a new one)"
echo "3. Navigate to 'App Distribution' in the left sidebar"
echo "4. Add your Android app with package name: $PACKAGE_NAME"
if [ ! -z "$BUNDLE_ID" ]; then
    echo "5. Add your iOS app with bundle ID: $BUNDLE_ID"
fi
echo "6. Copy the App IDs and update distribute.sh script"
echo "7. Run './distribute.sh \"Your update message\"' to distribute updates"
echo ""
echo -e "${GREEN}🎉 Setup complete! You're ready for Code Push distribution!${NC}"

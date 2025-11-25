#!/bin/bash
# Quick deep link testing script for Android

echo "🔗 Testing Proplinq Deep Links on Android..."
echo ""

echo "1. Testing listing deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "proplinq://listing/1" com.proplinq.app
sleep 3

echo ""
echo "2. Testing shortlet deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "proplinq://shortlet/2" com.proplinq.app
sleep 3

echo ""
echo "3. Testing hotel deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "proplinq://hotel/3" com.proplinq.app

echo ""
echo "✅ Deep link tests completed!"
echo "Check your app to see if properties opened correctly."

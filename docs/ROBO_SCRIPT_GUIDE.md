# Firebase Test Lab Robo Script Guide for Sakshat Savita Flutter App

## Overview
This guide explains how to use the Robo script (`robo_script.json`) to perform automated testing of your Sakshat Savita Flutter app on Firebase Test Lab.

## What the Robo Script Tests

### Core App Flows
1. **App Initialization**: Tests Firebase setup and splash screen
2. **Welcome/Onboarding**: Tests welcome screen navigation and feature introduction
3. **Main Navigation**: Tests drawer menu and primary navigation paths
4. **Book Reading**: Tests accessing parts, reading kiranas, and reading functionality
5. **Search**: Tests search functionality with Gujarati text
6. **Settings**: Tests settings page navigation and options
7. **Aashirvachan**: Tests blessing/guidance section
8. **Multilingual Support**: Tests both Gujarati and English text elements

### Key Features Tested
- ✅ Navigation drawer functionality
- ✅ Book part selection and reading
- ✅ Search with spiritual content
- ✅ Settings page interactions
- ✅ Bookmark functionality
- ✅ Back navigation handling
- ✅ Bilingual UI (Gujarati/English)
- ✅ Firebase integration stability

## How to Use the Robo Script

### 1. Upload to Firebase Test Lab

**Via Firebase Console:**
```bash
# Build your Android APK
flutter build apk --debug

# Upload to Firebase Console
# 1. Go to Firebase Console > Test Lab
# 2. Select "Run a test"
# 3. Choose "Robo test"
# 4. Upload your APK
# 5. Upload robo_script.json as "Robo script"
# 6. Configure test devices and run
```

**Via Firebase CLI:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Run test with Robo script
gcloud firebase test android run \
  --type=robo \
  --app=build/app/outputs/flutter-apk/app-debug.apk \
  --robo-script=robo_script.json \
  --device=model=Pixel2,version=28,locale=en,orientation=portrait \
  --timeout=15m
```

### 2. Advanced Configuration

**Multiple Device Testing:**
```bash
gcloud firebase test android run \
  --type=robo \
  --app=build/app/outputs/flutter-apk/app-debug.apk \
  --robo-script=robo_script.json \
  --device=model=Pixel2,version=28,locale=en \
  --device=model=Pixel4,version=29,locale=en \
  --device=model=walleye,version=26,locale=en \
  --timeout=15m
```

**With Environment Variables:**
```bash
gcloud firebase test android run \
  --type=robo \
  --app=build/app/outputs/flutter-apk/app-debug.apk \
  --robo-script=robo_script.json \
  --environment-variables=coverage=true,clearPackageData=true \
  --device=model=Pixel2,version=28 \
  --timeout=15m
```

## Script Configuration Explained

### Test Flow Structure (Current Firebase Format)
```json
[
  {
    "id": 1000,
    "crawlStage": "pre_crawl",
    "actions": [
      {
        "eventType": "ADB_SHELL_COMMAND",
        "command": "pm clear __%APP_PACKAGE_NAME%__"
      }
    ]
  },
  {
    "id": 1001,
    "contextDescriptor": {
      "condition": "app_under_test_shown"
    },
    "actions": [
      {
        "eventType": "WAIT",
        "delayTime": 7000
      },
      {
        "eventType": "VIEW_CLICKED",
        "optional": true,
        "elementDescriptors": [
          {
            "textRegex": "(Settings|સેટિંગ્સ)"
          }
        ]
      }
    ]
  }
]
```

### Action Types Used
- `WAIT`: pauses execution for a fixed duration (`delayTime` in ms)
- `VIEW_CLICKED`: taps an identified UI element
- `VIEW_TEXT_CHANGED`: inputs text in a target field
- `PRESSED_EDITOR_ACTION`: submits input using IME action
- `PRESSED_BACK`: sends Android back key event
- `TAKE_SCREENSHOT`: captures a named screenshot in test artifacts
- `ADB_SHELL_COMMAND`: executes adb shell commands (for example, `pm clear`)

### Element Matching Strategies
- `elementDescriptors.text`: exact visible text
- `elementDescriptors.textRegex`: regex matching for multilingual labels
- `elementDescriptors.resourceId` / `resourceIdRegex`: Android resource IDs
- `elementDescriptors.contentDescription` / `contentDescriptionRegex`: accessibility labels
- `visionText`: OCR text matching when hierarchy matching is not sufficient

## Customization Options

### 1. Modify Test Flow
Edit the `actions` list inside your script object to add/remove/modify test steps:

```json
{
  "eventType": "VIEW_CLICKED",
  "elementDescriptors": [
    {
      "text": "Your Button Text"
    }
  ],
  "description": "Description of what this does",
  "optional": true
}
```

### 2. Add New Test Scenarios
```json
{
  "eventType": "VIEW_TEXT_CHANGED",
  "replacementText": "navi test",
  "elementDescriptors": [
    {
      "className": "android.widget.EditText"
    }
  ],
  "description": "Test new search term",
  "optional": true
}
```

### 3. Skip Sensitive Actions
Use ignore actions to avoid problematic UI elements:

```json
{
  "eventType": "ELEMENT_IGNORED",
  "elementDescriptors": [
    {
      "textRegex": "(Delete|Remove|Dangerous Action)"
    }
  ],
  "description": "Skip this during testing"
}
```

## Monitoring Test Results

### 1. Firebase Console
- View test execution videos
- Check screenshots at each step
- Review crash logs and performance metrics
- Analyze coverage reports

### 2. Common Issues to Watch For
- **Navigation failures**: App doesn't respond to back button
- **Loading timeouts**: Content takes too long to load
- **Firebase connection**: Network-related failures
- **Memory issues**: App crashes due to memory pressure
- **UI rendering**: Elements not found due to layout issues

### 3. Performance Metrics
- App startup time
- Screen transition speeds
- Memory usage patterns
- Network request performance
- Firebase operation latency

## Maintenance and Updates

### When to Update the Script
- After adding new features to the app
- When UI text or navigation changes
- After localization updates
- When adding new languages
- After major refactoring

### Best Practices
1. **Keep scripts focused**: Test core user journeys
2. **Use optional actions**: Allow tests to continue if optional steps fail
3. **Add appropriate waits**: Give async operations time to complete
4. **Test both languages**: Include Gujarati and English paths
5. **Regular updates**: Keep script synchronized with app changes

## Troubleshooting

### Common Problems

**Element Not Found:**
```json
{
  "eventType": "VIEW_CLICKED",
  "optional": true,
  "elementDescriptors": [
    {
      "text": "Primary Text"
    },
    {
      "contentDescription": "Fallback Description"
    }
  ]
}
```

**Timing Issues:**
```json
{
  "eventType": "WAIT",
  "delayTime": 5000,
  "description": "Wait for Firebase initialization"
}
```

**Navigation Problems:**
```json
{
  "eventType": "PRESSED_BACK",
  "description": "Navigate back"
}
```

### Debug Tips
1. Review test execution videos frame by frame
2. Check element inspector for correct matchers
3. Verify app state at failure points
4. Test script locally using Android emulator
5. Use gradual rollout for script changes

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Firebase Test Lab
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v1
    - run: flutter build apk --debug
    - uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GCLOUD_KEY }}
    - run: |
        gcloud firebase test android run \
          --type=robo \
          --app=build/app/outputs/flutter-apk/app-debug.apk \
          --robo-script=robo_script.json \
          --device=model=Pixel2,version=28
```

This Robo script provides comprehensive testing coverage for your spiritual reading app, ensuring all major user flows work correctly across different devices and Android versions.
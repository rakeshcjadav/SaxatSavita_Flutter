# 🍎 **iOS TestFlight Upload Guide**
## For Saxat Savita App (Sakshat Savita)

### **📋 Current App Configuration**
- **Bundle ID**: `com.farenidham.books.saxatsavitaFlutter`
- **App Name**: સાક્ષાત્ સવિતા (Saxat Savita)
- **Current Version**: 2.0.0 (Build 106)
- **Target**: iOS 12.0+
- **Platforms**: iPhone & iPad

---

## **🚀 Step-by-Step Upload Process**

### **Step 1: Prerequisites ✅**
- [x] Apple Developer Account (Active)
- [x] Xcode installed
- [x] App ID registered in Apple Developer Portal
- [x] Distribution Certificate and Provisioning Profile
- [x] Flutter project configured

### **Step 2: Build Archive**
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Update iOS pods
cd ios && pod install --repo-update && cd ..

# Build iOS archive
flutter build ipa --release
```

### **Step 3: App Store Connect Setup**

#### **A. Access App Store Connect**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Navigate to "My Apps"

#### **B. Locate Your Existing App**
Since your app is already live, you should see:
- **App Name**: Saxat Savita or સાક્ષાત્ સવિતા
- **Bundle ID**: com.farenidham.books.saxatsavitaFlutter
- **Current Live Version**: (whatever is currently on App Store)

#### **C. Create New Version**
1. Click on your app
2. Click "+" next to "iOS App" 
3. Enter new version number: **2.0.0**
4. Click "Create"

### **Step 4: Version Information**

#### **What's New in This Version**
```
મુખ્ય નવા ફીચર્સ:
• નવું ડિઝાઇન અને સુધારેલ યુઝર ઇન્ટરફેસ
• વાંચન યોજના ફીચર - દૈનિક વાંચન ટ્રેક કરો
• ઇમેજ જનરેટર - ક્વોટ્સ સાથે સુંદર ઇમેજ બનાવો
• બુકમાર્ક સિસ્ટમ સુધારો
• પ્રદર્શન અને સ્થિરતામાં સુધારો

Key New Features:
• New design and improved user interface
• Reading plan feature - track daily reading
• Image generator - create beautiful images with quotes
• Improved bookmark system
• Performance and stability improvements
```

#### **App Information**
- **Category**: Books or Education
- **Age Rating**: 4+ (suitable for all ages)
- **Copyright**: © 2025 Faren Idham

### **Step 5: Upload IPA File**

#### **Option A: Using Xcode**
1. Open Xcode
2. Go to Window → Organizer
3. Select "Archives" tab
4. Find your Saxat Savita archive
5. Click "Distribute App"
6. Select "App Store Connect"
7. Follow the upload wizard

#### **Option B: Using Transporter App**
1. Download "Transporter" from Mac App Store
2. Open Transporter
3. Sign in with Apple ID
4. Drag your `.ipa` file from `build/ios/ipa/`
5. Click "Deliver"

#### **Option C: Using Command Line**
```bash
# Install Apple's altool (if not already installed)
xcrun altool --upload-app -f build/ios/ipa/saxatsavita_flutter.ipa -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD
```

### **Step 6: TestFlight Configuration**

#### **A. Processing Time**
- Upload processing: 2-10 minutes
- Binary review: 1-3 hours (automated)

#### **B. TestFlight Information**
1. **Test Information**: 
   ```
   આ અપડેટ નવા ફીચર્સ અને સુધારાઓ સાથે આવે છે। કૃપા કરીને ટેસ્ટ કરો અને ફીડબેક આપો।
   
   This update comes with new features and improvements. Please test and provide feedback.
   ```

2. **What to Test**:
   ```
   • બધા મુખ્ય ફીચર્સ ટેસ્ટ કરો
   • વાંચન યોજના ટ્રાય કરો
   • ઇમેજ જનરેટર ઉપયોગ કરો
   • બુકમાર્ક ફંક્શન ચેક કરો
   
   • Test all main features
   • Try reading plan functionality
   • Use image generator
   • Check bookmark function
   ```

#### **C. Add Beta Testers**
1. Go to TestFlight tab
2. Click "External Testing" → "Add Group"
3. Name: "Pre-Release Testers"
4. Add email addresses of testers
5. Submit for review

### **Step 7: Store Review Preparation**

#### **A. App Review Information**
- **Demo Account**: Not required (spiritual content app)
- **Review Notes**: 
  ```
  This app provides spiritual content and reading materials in Gujarati language.
  All content is appropriate for all ages.
  No special review requirements.
  ```

#### **B. App Store Screenshots**
Use the screenshots from your `store_listing/enhanced_with_frame/` directory:
- iPhone 6.7" (1290 x 2796): framed_01_main_home_screen.jpg, etc.
- iPhone 6.5" (1242 x 2688): Same images work
- iPhone 5.5" (1242 x 2208): Resize if needed
- iPad Pro (2048 x 2732): Create iPad-specific if needed

### **Step 8: Submission Timeline**

#### **TestFlight Timeline**
- ✅ Upload: Immediate
- ⏳ Processing: 2-10 minutes  
- ⏳ Automated Review: 1-3 hours
- ✅ Available to Testers: After review

#### **App Store Timeline (if submitting)**
- ⏳ App Review: 24-48 hours
- ✅ Live on Store: After approval

---

## **🔧 Troubleshooting Common Issues**

### **Build Issues**
```bash
# If pod install fails
cd ios && rm Podfile.lock && pod install

# If archive fails
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter build ipa
```

### **Upload Issues**
- **Invalid Bundle**: Check bundle ID matches App Store Connect
- **Missing Provisioning Profile**: Regenerate in Apple Developer Portal
- **Version Conflict**: Ensure version number is higher than current live version

### **Code Signing Issues**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to Signing & Capabilities
3. Ensure correct Team and Bundle ID
4. Check "Automatically manage signing"

---

## **📱 Post-Upload Checklist**

### **TestFlight Testing**
- [ ] Internal testing (your team)
- [ ] External testing (beta users)
- [ ] All major features working
- [ ] No crashes or major bugs
- [ ] Performance acceptable

### **Store Submission**
- [ ] All metadata filled
- [ ] Screenshots uploaded
- [ ] App description updated
- [ ] Keywords optimized
- [ ] Privacy policy updated (if required)

---

## **🎯 Quick Commands Summary**

```bash
# Full rebuild and upload preparation
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release

# Check build output
ls -la build/ios/ipa/

# Upload using altool (alternative)
xcrun altool --upload-app -f build/ios/ipa/saxatsavita_flutter.ipa -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD
```

---

## **📞 Need Help?**

If you encounter issues:
1. Check build logs for specific errors
2. Verify Apple Developer account status
3. Ensure all certificates are valid
4. Contact Apple Developer Support if needed

**Good luck with your TestFlight upload! 🚀**
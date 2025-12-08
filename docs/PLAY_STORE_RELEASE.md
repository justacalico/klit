# Google Play Store Release Guide

## Prerequisites

1. **Google Play Console Account** - You need a Google Play Developer account ($25 one-time fee)
2. **App Icon** - Make sure you have proper icons in `android/app/src/main/res/mipmap-*` folders
3. **Screenshots** - Prepare screenshots for different device sizes

## Step 1: Generate Upload Keystore

Run this command to create your upload keystore:

```bash
keytool -genkey -v -keystore android/keystore/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**IMPORTANT:** 
- Store this keystore file securely! If you lose it, you cannot update your app.
- Remember the passwords you set.
- Back up the keystore file in multiple secure locations.

## Step 2: Configure Signing

1. Copy the example key.properties file:
   ```bash
   cp android/key.properties.example android/key.properties
   ```

2. Edit `android/key.properties` with your actual values:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../keystore/upload-keystore.jks
   ```

## Step 3: Build Release App Bundle

For Google Play Store, build an App Bundle (AAB):

```bash
flutter build appbundle --release
```

The output file will be at:
`build/app/outputs/bundle/release/app-release.aab`

## Step 4: Test the Release Build

Before uploading, test the release build locally:

```bash
# Build APK for testing
flutter build apk --release

# Install on a device
flutter install --release
```

## Step 5: Prepare Store Listing

You'll need:
- **App Name:** Klit
- **Short Description:** (max 80 characters) Browse and discover content from e621/e926 with a beautiful iOS-style interface
- **Full Description:** (max 4000 characters) Write a detailed description of the app features
- **App Icon:** 512x512 PNG
- **Feature Graphic:** 1024x500 PNG
- **Screenshots:** At least 2 screenshots for phone (recommended: 4-8)
- **Privacy Policy URL:** Required for apps that collect user data
- **Category:** Entertainment or Social

## Step 6: Content Rating

Complete the content rating questionnaire in Google Play Console. 
For an app that accesses e621/e926:
- Mature content may require appropriate ratings
- Consider adding content warnings

## Step 7: Upload to Google Play Console

1. Go to https://play.google.com/console
2. Create a new app
3. Fill in store listing details
4. Upload the AAB file to "Production" or "Internal testing" track
5. Complete content rating questionnaire
6. Set up pricing and distribution
7. Submit for review

## Version Updates

For each new release:
1. Update version in `pubspec.yaml`:
   ```yaml
   version: 2.0.1+2  # format: major.minor.patch+buildNumber
   ```
   - `buildNumber` (after +) must be incremented for each release
   - `versionName` (before +) is what users see

2. Build new AAB:
   ```bash
   flutter build appbundle --release
   ```

3. Upload to Google Play Console

## Troubleshooting

### Signing Issues
- Make sure `key.properties` exists and has correct paths
- Verify keystore file exists at the specified location
- Check passwords are correct

### Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build appbundle --release
```

### ProGuard Issues
If the release build crashes but debug works, check `android/app/proguard-rules.pro` and add keep rules for any classes that are being stripped.

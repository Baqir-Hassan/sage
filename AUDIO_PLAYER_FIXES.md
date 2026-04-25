# Audio Player APK Fixes and Troubleshooting Guide

## Issues Fixed

### 1. **Missing Storage Permissions** ✅
**Problem:** Android requires explicit permission requests for accessing storage, especially for local audio files.

**Fix:** Added storage permissions to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### 2. **No Network Security Configuration** ✅
**Problem:** Modern Android versions require explicit network security policies. Missing configuration can prevent HTTPS/HTTP audio streams from loading.

**Fix:** Created `android/app/src/main/res/xml/network_security_config.xml` that:
- Allows cleartext traffic for localhost (development)
- Enforces HTTPS for your API domain (`api.sageai.live`)
- Uses system certificate store for SSL verification

Then linked it in `AndroidManifest.xml`:
```xml
android:networkSecurityConfig="@xml/network_security_config"
```

### 3. **Unpinned Audio Plugin Versions** ✅
**Problem:** Audio plugins without version constraints can cause incompatibilities between web and Android platforms.

**Fix:** Updated `pubspec.yaml` with stable versions:
```yaml
just_audio: ^0.9.34
just_audio_background: ^0.0.1
```

### 4. **Missing Runtime Permission Requests** ✅
**Problem:** Android 6.0+ requires runtime permission requests, not just manifest declarations.

**Fix:** 
- Added `permission_handler: ^11.4.4` to dependencies
- Updated `main.dart` to request permissions before initializing audio:
```dart
Future<void> _requestAudioPermissions() async {
  if (!kIsWeb) {
    await [
      Permission.storage,
      Permission.microphone,
    ].request();
  }
}
```

### 5. **Insufficient Error Logging** ✅
**Problem:** Couldn't diagnose why audio wasn't loading on Android.

**Fix:** Enhanced `lecture_player_cubit.dart` with detailed debug logging:
- Logs attempts to load local vs remote audio
- Logs specific error messages when loading fails
- Logs successful loads with source information

## How to Debug Further

### 1. **Check logcat output** (when running on device)
```bash
flutter logs
# OR
adb logcat | grep -i audio
```

Look for error messages containing:
- "Failed to load remote audio"
- "Failed to load local audio"
- "Audio playback error"

### 2. **Verify Permissions Granted**
On your device:
- Settings → Apps → Sage → Permissions
- Ensure "Storage" and "Microphone" are granted

### 3. **Test with Different Audio Sources**
- Try a public HTTPS URL (e.g., `https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3`)
- This helps isolate if it's a server/auth issue vs general audio playback issue

### 4. **Check Network Connectivity**
```bash
# From device terminal
curl -v https://api.sageai.live/path-to-audio
```

### 5. **Verify Audio File Format**
Ensure audio files are in a format `just_audio` supports:
- MP3 ✅
- M4A ✅
- WAV ✅
- Vorbis ✅
- OPUS ✅

### 6. **Check Authorization Headers**
If using protected URLs, verify:
- Auth token is being retrieved from SharedPreferences
- Token is valid and not expired
- The `_headersFor()` method is correctly identifying protected paths

## Next Steps

1. **Rebuild the APK:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Install on device:**
   ```bash
   adb install -r build/app/outputs/apk/release/app-release.apk
   ```

3. **Enable logcat:**
   ```bash
   flutter logs
   ```

4. **Test audio playback** and monitor logs for error messages

## If Audio Still Doesn't Work

### Common Causes:

1. **Codec Not Supported**
   - Check audio file format in server response headers
   - Use VLC or ffprobe to verify codec: `ffprobe your_audio.mp3`

2. **Server Issue**
   - Verify audio file exists and is accessible
   - Test URL directly in browser on your phone
   - Check server logs for access errors

3. **Authorization Failed**
   - Token might be expired
   - Logout/login to refresh token
   - Add temporary logging to verify token is being sent

4. **File Path Issues (Local Audio)**
   - Verify path exists with correct permissions
   - Use `debugPrint()` to log the exact path being used

5. **Device-Specific Issues**
   - Try different audio file/URL
   - Test on different device if possible
   - Check device audio settings (volume not muted, etc.)

## References

- [Just Audio Documentation](https://pub.dev/packages/just_audio)
- [Android Network Security Config](https://developer.android.com/training/articles/security-config)
- [Permission Handler Package](https://pub.dev/packages/permission_handler)
- [Android Audio Codec Support](https://developer.android.com/guide/topics/media/media-formats)

## Quick Checklist

- [ ] Rebuilt APK after changes
- [ ] Installed on test device
- [ ] Permissions granted in settings
- [ ] Test with public HTTPS audio URL
- [ ] Checked flutter logs for errors
- [ ] Verified network connectivity
- [ ] Confirmed audio file format is supported

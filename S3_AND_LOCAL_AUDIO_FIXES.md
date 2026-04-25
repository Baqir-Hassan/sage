# S3 Audio Streaming & Local Playback Fixes

## Problems Identified & Fixed

### 1. **S3 Download Missing Authorization Headers** ✅
**Problem:** When downloading audio files from S3, authorization headers weren't being passed. This would cause 403 Forbidden errors if S3 buckets are private or access-controlled.

**Fix:** Modified `OfflineAudioService` to extract auth token from SharedPreferences and pass it to downloads:
```dart
Map<String, String>? _getDownloadHeaders(String url) {
  final token = _preferences.getString('auth_token');
  if (token != null && token.isNotEmpty && 
      (url.contains('api.sageai.live') || url.startsWith('/'))) {
    return {'Authorization': 'Bearer $token'};
  }
  return null;
}
```

### 2. **Download Method Didn't Accept Headers** ✅
**Problem:** The `download()` method signature didn't support passing headers, preventing auth tokens from being sent.

**Fix:** Updated signature in `OfflineAudioStore` abstract class:
```dart
Future<String?> download(String lectureId, String url, {Map<String, String>? headers});
```

Updated implementations:
- `offline_audio_store_io.dart` - Main Android implementation
- `offline_audio_store_stub.dart` - Web stub

### 3. **Local File Playback on Android** ✅
**Problem:** Downloaded files couldn't be played because:
- File paths weren't using the `file://` URI scheme required by `just_audio`
- `just_audio` on Android needs proper URI formatting

**Fix:** Enhanced `_tryLoadLocal()` in `lecture_player_cubit.dart`:
```dart
// Ensure path uses file:// scheme for proper Android handling
final filePath = path.startsWith('file://') ? path : 'file://$path';
await audioPlayer.setFilePath(filePath);

// Fallback: Try without file:// scheme if above fails
await audioPlayer.setFilePath(path);
```

### 4. **Insufficient Download Error Logging** ✅
**Problem:** Downloads failed silently without clear error messages, making it impossible to diagnose S3 connection issues.

**Fix:** Added comprehensive debug logging to `offline_audio_store_io.dart`:
```dart
// Logs file size after download
debugPrint('Downloaded ${response.bodyBytes.length} bytes for lecture $lectureId');

// Logs HTTP status code if download fails
debugPrint('Download failed - ID: $lectureId, Status: ${response.statusCode}');

// Verifies file was actually written
final fileSize = await file.length();
debugPrint('Saved file: ${file.path} (size: $fileSize bytes)');
```

## Troubleshooting Guide

### For S3 Remote Streaming (Direct URLs)

#### 1. **Check if S3 URLs are pre-signed**
Pre-signed URLs include auth directly in the URL and should work. If streams fail:

```bash
# Test the URL from your phone's browser
# It should download/play the file directly
https://your-bucket.s3.amazonaws.com/path/to/audio.mp3?X-Amz-Credential=...
```

#### 2. **Check S3 CORS Configuration**
If using direct S3 URLs (not pre-signed), you need CORS:

```json
[
  {
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3000
  }
]
```

Apply in S3 console: S3 → Your Bucket → Permissions → CORS

#### 3. **Verify S3 Bucket Access**
- Check bucket policy allows public read (if needed)
- Or verify IAM role has S3 access
- Test with `curl`: `curl -v https://bucket.s3.amazonaws.com/file.mp3`

### For Local Playback (Downloaded Files)

#### 1. **Check Downloaded Files Exist**
Enable detailed logging and look for:
```
flutter logs | grep -i "Found local lecture file"
flutter logs | grep -i "Saved file"
```

#### 2. **Verify File Integrity**
```bash
# Check if download completed successfully
flutter logs | grep "Downloaded.*bytes"

# Verify it's not empty
flutter logs | grep "size: [0-9]* bytes"
```

#### 3. **Test File Path Format**
The app now tries both:
1. With `file://` prefix: `file:///data/user/0/com.chunhthanhde.spotify_flutter/app_flutter/offline_audio/lecture123.mp3`
2. Raw path (fallback)

If still failing, the file format might be wrong.

#### 4. **Check File Format**
Ensure downloaded files are valid audio:
```bash
# From device (using adb)
adb shell
# Navigate to app's files directory
cd /data/data/com.chunhthanhde.spotify_flutter/app_flutter/offline_audio/
# Check if file is valid MP3
file lecture123.mp3
```

### API-Side S3 Issues

#### 1. **S3 URLs Not Absolute**
If backend returns relative URLs like `/media/audio/123.mp3`, they get converted to full URLs by `_resolveMediaUrl()`. Verify this works:

```dart
// In lecture_api_service.dart
String? _resolveMediaUrl(String? mediaUrl) {
  if (mediaUrl == null || mediaUrl.isEmpty) return null;
  if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) return mediaUrl;
  return '${ApiUrls.baseUrl}$mediaUrl';
}
```

#### 2. **S3 Pre-Signed URL Expiration**
If using pre-signed URLs, they expire after a time period (often 1 hour). Solutions:
- Backend should generate fresh URLs each time
- Or use longer expiration times (24+ hours)

#### 3. **Content-Type Mismatch**
If file is downloaded but not playable:
- Check S3 object's Content-Type metadata
- Should be `audio/mpeg` for MP3 files
- If wrong, `just_audio` might reject it

## Rebuild & Test Steps

```bash
# Clean build
flutter clean
flutter pub get

# Rebuild APK with logging
flutter build apk --release

# Install
adb install -r build/app/outputs/apk/release/app-release.apk

# Monitor logs
flutter logs > app_logs.txt  # Save for analysis

# Test:
# 1. Try streaming audio directly (without download)
# 2. Try downloading then playing
# 3. Monitor logs for specific errors
```

## Debug Checklist

**For Remote Streaming:**
- [ ] S3 URL is absolute (starts with https://)
- [ ] S3 bucket has proper CORS if public
- [ ] If private bucket, pre-signed URL is valid
- [ ] URL isn't expired (check S3 signature time)
- [ ] Network connection is active
- [ ] Auth token is valid (if needed)

**For Local Playback:**
- [ ] File downloaded successfully (log shows X bytes)
- [ ] File path is stored in SharedPreferences
- [ ] File exists on device (not deleted)
- [ ] File size is > 0 bytes
- [ ] File format is supported (MP3 best)
- [ ] Audio player can open file:// URIs

**Network:**
- [ ] Device can reach S3 bucket domain
- [ ] Device can reach api.sageai.live
- [ ] No firewall/proxy blocking audio streams
- [ ] Storage permissions granted on device

## If Issues Persist

1. **Check Server Logs:**
   - Verify S3 bucket access logs for 403/404 errors
   - Check API logs for download request failures

2. **Test with Public URL:**
   - Replace S3 URL with public test audio
   - Example: `https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3`
   - If this works, issue is S3-specific

3. **Check `just_audio` Version:**
   ```yaml
   just_audio: ^0.9.34
   ```
   - Older versions may not support file:// URIs properly
   - Update to latest stable

4. **Device-Specific Issues:**
   - Try different device/emulator
   - Check Android version (API 24+)
   - Verify storage is not full

## References

- [AWS S3 CORS Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html)
- [Just Audio File URI Support](https://pub.dev/packages/just_audio#readme)
- [Android File Access](https://developer.android.com/training/data-storage)
- [AWS Pre-Signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)

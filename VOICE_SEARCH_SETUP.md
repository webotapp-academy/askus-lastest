# Voice Search Feature - Setup & Usage Guide

## Overview
The search screen now includes a production-ready voice-to-text feature that allows users to search for products and services using their voice.

## Features Implemented

### 1. **Runtime Permission Handling**
- Automatic microphone permission requests on first use
- User-friendly permission denial dialogs with settings redirect
- Works on both Android (API 23+) and iOS (iOS 10+)

### 2. **Visual Feedback**
- Animated microphone icon (mic_none → mic with red color)
- Visual listening indicator banner with "Listening... Speak now"
- Loading animation during speech recognition
- Smooth transitions and tooltips

### 3. **Error Handling**
- Permission denied scenarios
- Speech recognition unavailability
- Network/API errors
- User-friendly error messages via SnackBars

### 4. **UX Enhancements**
- Real-time text updates as user speaks (partial results)
- Automatic search trigger on final speech result
- Easy toggle on/off with mic button
- Maintains keyboard search functionality

## Dependencies Added

```yaml
speech_to_text: 7.3.0        # On-device speech recognition
permission_handler: ^11.3.0   # Runtime permission management
```

## Platform Setup

### Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

Already configured with:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET" />
```

**Minimum Requirements:**
- Android SDK 21+ (Android 5.0+)
- Google Play Services (for speech recognition)

### iOS Configuration

**File:** `ios/Runner/Info.plist`

Added permissions:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to convert speech to text for searching products and services.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need access to speech recognition to convert your voice to text for searching.</string>
```

**Minimum Requirements:**
- iOS 10.0+
- Device with microphone

## How to Use

### For Users
1. Open the search screen
2. Tap the microphone icon in the app bar
3. Grant microphone permission if prompted
4. Speak your search query
5. Watch as your words appear in the search field
6. Search automatically triggers when you finish speaking
7. Tap mic again to stop listening manually

### For Developers

#### Testing on Real Devices
```bash
# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <ios-device-id>

# List available devices
flutter devices
```

**Important:** Emulators/Simulators may not provide accurate microphone input. Always test on physical devices.

#### Code Structure

**Main Components:**
- `_speech`: SpeechToText instance for speech recognition
- `_isListening`: Boolean flag for listening state
- `_speechAvailable`: Boolean flag for speech capability
- `_startListening()`: Handles permission checks and starts listening
- `_stopListening()`: Stops listening and cleanup
- `_showPermissionDialog()`: User-friendly permission dialog

**Key Methods:**
```dart
// Initialize speech recognition
Future<void> _initSpeech() async { ... }

// Start listening with permission checks
Future<void> _startListening() async { ... }

// Stop listening
Future<void> _stopListening() async { ... }

// Show permission dialog
void _showPermissionDialog() { ... }
```

## Testing Checklist

### Functional Testing
- [ ] Tap mic icon and grant permission on first use
- [ ] Speak and verify text appears in search field
- [ ] Verify automatic search triggers after speaking
- [ ] Test manual stop by tapping mic again
- [ ] Test permission denial and settings redirect
- [ ] Test with airplane mode (should show error)
- [ ] Test with no internet after recognition (search should fail gracefully)

### UI/UX Testing
- [ ] Verify mic icon animates correctly
- [ ] Verify listening banner appears/disappears
- [ ] Verify red color indication when listening
- [ ] Verify tooltips show on hover/long-press
- [ ] Test with different screen sizes
- [ ] Test rotation (if supported)

### Platform-Specific Testing
- [ ] Android: Test on API 23, 28, 30+
- [ ] iOS: Test on iOS 12, 14, 15+
- [ ] Test with different languages (if supported)

## Troubleshooting

### Issue: "Speech recognition unavailable"
**Solutions:**
- Ensure device has internet connection (most speech engines require it)
- On Android: Ensure Google app is updated
- On iOS: Ensure Siri is enabled in Settings
- Check device has working microphone

### Issue: Permission denied
**Solutions:**
- App will show dialog to open settings
- User needs to manually enable microphone permission
- On Android: Settings → Apps → AskUs → Permissions → Microphone
- On iOS: Settings → AskUs → Microphone

### Issue: No text appearing while speaking
**Solutions:**
- Check microphone is not muted
- Speak clearly and in a quiet environment
- Ensure proper language/locale is set on device
- Check internet connection

### Issue: Build errors after adding dependencies
**Solutions:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

## Production Considerations

### Performance
- Speech recognition uses device resources efficiently
- Internet required for most speech engines
- Consider adding offline fallback message

### Privacy
- Speech data is processed by platform services (Google/Apple)
- No data stored locally by our app
- User consent obtained via permission dialogs
- Review platform-specific privacy policies

### Accessibility
- Keyboard search remains fully functional
- Screen reader compatible
- Voice feedback can be added if needed

### Localization
- Speech recognition uses device locale automatically
- Consider adding language selector for multi-language support
- Test with regional accents

## Future Enhancements

Consider adding:
- [ ] Waveform visualization during listening
- [ ] Offline speech recognition (if available)
- [ ] Language/accent selection
- [ ] Voice command shortcuts ("search for...", "find...")
- [ ] Haptic feedback on start/stop
- [ ] Tutorial/onboarding for first-time users
- [ ] Analytics to track usage and error rates

## Support

For issues or questions:
- Check Flutter documentation: https://flutter.dev/docs
- speech_to_text package: https://pub.dev/packages/speech_to_text
- permission_handler package: https://pub.dev/packages/permission_handler

## Version History

**v1.0.0** (January 2026)
- Initial production-ready implementation
- Runtime permission handling
- Visual feedback and error handling
- iOS and Android support

# Music Player Caching System

## Overview
The music player now includes a sophisticated caching system that improves performance and user experience by storing downloaded music files locally.

## Features

### 🎵 Single-Track Caching
- Only one music track is cached at a time
- Previous cache is automatically cleared when a new track is downloaded
- Reduces storage usage while maintaining performance

### 📁 Cache Directory Structure
```
appdir/
└── user/
    └── cache/
        └── {music_id}_{title}.{extension}
```

### 🔄 Cache Management
- **Automatic Cache Clearing**: Previous track cache is cleared before downloading new track
- **Cache Validation**: Checks if cached files exist and have content
- **Cache Information**: Shows cache size, file count, and path
- **Manual Cache Clearing**: Users can manually clear cache through UI

## Implementation

### CacheManager Class
Located at: `lib/utils/CacheManager.dart`

**Key Methods:**
- `downloadAndCacheMusic()`: Downloads and caches a music track
- `isMusicCached()`: Checks if a track is cached
- `clearCache()`: Clears all cached files for a user
- `getCacheInfo()`: Returns cache statistics

### Integration with Application
The caching system is integrated into the main application flow:

1. **Music Playback**: When user clicks on a track
2. **Cache Check**: System checks if track is already cached
3. **Download & Cache**: If not cached, downloads and caches the track
4. **Play**: Plays the cached file

### UI Integration
- **Cache Management Dialog**: Accessible via long-press menu or storage icon in AppBar
- **Cache Statistics**: Shows cache size, file count, and path
- **Clear Cache Button**: Allows manual cache clearing

## Permissions Required

### Android Permissions
The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Usage

### For Users
1. **Play Music**: Simply tap on any track to play (caching happens automatically)
2. **Cache Management**: Long-press any track and select "Cache Management" or tap the storage icon in the AppBar
3. **Clear Cache**: Use the "Clear Cache" button in the cache management dialog

### For Developers
```dart
// Get cache manager instance
final CacheManager cacheManager = CacheManager.instance;

// Check if music is cached
bool isCached = await cacheManager.isMusicCached(user, music);

// Download and cache music
bool success = await cacheManager.downloadAndCacheMusic(user: user, music: music);

// Clear cache
await cacheManager.clearCache(user);

// Get cache info
Map<String, dynamic> cacheInfo = await cacheManager.getCacheInfo(user);
```

## Benefits

1. **Improved Performance**: Cached tracks play instantly
2. **Reduced Bandwidth**: No need to re-download previously played tracks
3. **Better User Experience**: Faster playback and offline capability
4. **Storage Efficiency**: Only one track cached at a time
5. **Transparent Operation**: Users don't need to manage cache manually

## Technical Details

### Cache File Naming
Files are named using the pattern: `{music_id}_{title}.{extension}`
- Special characters in titles are replaced with underscores
- Ensures unique file names across different tracks

### Cache Validation
- Checks file existence
- Verifies file has content (not empty)
- Validates file size after writing

### Error Handling
- Graceful handling of download failures
- Automatic retry logic in TcpClient
- User-friendly error messages

## Future Enhancements

1. **Multi-Track Caching**: Cache multiple tracks simultaneously
2. **Cache Size Limits**: Implement maximum cache size
3. **Background Downloads**: Download tracks in background
4. **Cache Persistence**: Maintain cache across app restarts
5. **Smart Caching**: Predict and pre-cache likely-to-play tracks 
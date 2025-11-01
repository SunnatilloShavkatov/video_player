import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/second_page.dart';
import 'package:video_player_example/video_view_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Plugin example',
    themeMode: ThemeMode.light,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarContrastEnforced: false,
          // iOS
          statusBarBrightness: Brightness.light,
          // android
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
    ),

    home: const MainPage(),
  );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _videoPlayerPlugin = VideoPlayer.instance;
  static const String downloadUrl = 'https://cdn.ooo.io/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8';

  /// Helper method to show snack bar messages
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> download1() async {
    try {
      final success = await _videoPlayerPlugin.downloadVideo(
        downloadConfig: const DownloadConfiguration(title: 'She-Hulk 2', url: downloadUrl),
      );
      if (kDebugMode) {
        print('Download 1 ${success ? 'started successfully' : 'failed to start'}');
      }
      _showSnackBar(success ? 'Download started' : 'Download failed to start');
    } on PlatformException catch (e) {
      debugPrint('Failed to start download: ${e.message}');
      _showSnackBar('Error: ${e.message}');
    }
  }

  Future<void> download2() async {
    try {
      final success = await _videoPlayerPlugin.downloadVideo(
        downloadConfig: const DownloadConfiguration(
          title: 'She-Hulk 2',
          url: 'https://cdn.ooo.io/videos/a04c9257216b2f2085c88be31a13e5d7/240p/index.m3u8',
        ),
      );
      if (kDebugMode) {
        print('Download 2 ${success ? 'started successfully' : 'failed to start'}');
      }
      _showSnackBar(success ? 'Download started' : 'Download failed to start');
    } on PlatformException catch (e) {
      debugPrint('Failed to start download: ${e.message}');
      _showSnackBar('Error: ${e.message}');
    }
  }

  Future<void> pauseDownload() async {
    try {
      final success = await _videoPlayerPlugin.pauseDownload(
        downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
      );
      if (kDebugMode) {
        print('Pause download ${success ? 'successful' : 'failed'}');
      }
      _showSnackBar(success ? 'Download paused' : 'Failed to pause download');
    } on PlatformException catch (e) {
      debugPrint('Failed to pause download: ${e.message}');
      _showSnackBar('Error: ${e.message}');
    }
  }

  Future<void> resumeDownload() async {
    try {
      final success = await _videoPlayerPlugin.resumeDownload(
        downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
      );
      if (kDebugMode) {
        print('Resume download ${success ? 'successful' : 'failed'}');
      }
      _showSnackBar(success ? 'Download resumed' : 'Failed to resume download');
    } on PlatformException catch (e) {
      debugPrint('Failed to resume download: ${e.message}');
      _showSnackBar('Error: ${e.message}');
    }
  }

  Future<void> removeDownload() async {
    try {
      final success = await _videoPlayerPlugin.removeDownload(
        downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
      );
      if (kDebugMode) {
        print('Remove download ${success ? 'successful' : 'failed'}');
      }
      _showSnackBar(success ? 'Download removed' : 'Failed to remove download');
    } on PlatformException catch (e) {
      debugPrint('Failed to remove download: ${e.message}');
      _showSnackBar('Error: ${e.message}');
    }
  }

  Future<int> getStateDownload() async {
    try {
      final state =
          await _videoPlayerPlugin.getStateDownload(
            downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
          ) ??
          -1;

      if (kDebugMode) {
        print('Download state: $state');
      }

      // Show user-friendly state message
      String stateMessage;
      switch (state) {
        case 0:
          stateMessage = 'Queued';
        case 1:
          stateMessage = 'Stopped';
        case 2:
          stateMessage = 'Downloading';
        case 3:
          stateMessage = 'Completed';
        case 4:
          stateMessage = 'Failed';
        case 5:
          stateMessage = 'Removing';
        case 7:
          stateMessage = 'Restarting';
        default:
          stateMessage = 'Unknown ($state)';
      }
      _showSnackBar('Download state: $stateMessage');
      return state;
    } on PlatformException catch (e) {
      debugPrint('Failed to get download state: ${e.message}');
      _showSnackBar('Error getting state: ${e.message}');
      return -1;
    }
  }

  Future<bool> checkIsDownloaded() async {
    try {
      final isDownloaded = await _videoPlayerPlugin.isDownloadVideo(
        downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
      );
      if (kDebugMode) {
        print('Is downloaded: $isDownloaded');
      }
      return isDownloaded;
    } on PlatformException catch (e) {
      debugPrint('Failed to check download status: ${e.message}');
      _showSnackBar('Error checking download: ${e.message}');
      return false;
    }
  }

  Stream<MediaItemDownload> currentProgressDownloadAsStream() => _videoPlayerPlugin.currentProgressDownloadAsStream;

  Future<void> playVideo() async {
    try {
      final playbackTimes = await _videoPlayerPlugin.playVideo(
        playerConfig: const PlayerConfiguration(
          videoUrl:
              'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8',
          movieShareLink: 'https://uzd.iiii.io/movie/7963?type=premier',
          qualityText: 'Quality',
          speedText: 'Speed',
          lastPosition: 0,
          title: "Harry Potter and the Philosopher's Stone Part 1",
          playVideoFromAsset: false,
          assetPath: '',
          autoText: 'Auto',
        ),
      );
      if (kDebugMode) {
        print('Playback completed. Times: $playbackTimes');
      }
      if (playbackTimes != null && playbackTimes.isNotEmpty) {
        _showSnackBar('Video played successfully');
      } else {
        _showSnackBar('Video playback completed with no time data');
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to play video: ${e.message}');
      _showSnackBar('Failed to play video: ${e.message}');
    } on Exception catch (e) {
      debugPrint('Unexpected error playing video: $e');
      _showSnackBar('Unexpected error occurred');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video Player')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton(onPressed: playVideo, child: const Text('Play Video')),
        ElevatedButton(onPressed: download1, child: const Text('Download1')),
        ElevatedButton(onPressed: download2, child: const Text('Download2')),
        ElevatedButton(onPressed: pauseDownload, child: const Text('Pause Download')),
        ElevatedButton(onPressed: resumeDownload, child: const Text('Resume Download')),
        ElevatedButton(onPressed: removeDownload, child: const Text('Remove Download')),
        ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => const SecondPage()));
          },
          child: const Text('Got to next page'),
        ),
        ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => const VideoPlayerPage()));
          },
          child: const Text('Got to video view page'),
        ),
        ElevatedButton(
          onPressed: () async {
            final state = await getStateDownload();
            if (kDebugMode) {
              print('download state: $state');
            }
          },
          child: const Text('Get state'),
        ),
        StreamBuilder(
          stream: currentProgressDownloadAsStream(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(
              children: [
                Text(
                  data == null
                      ? 'Not downloading'
                      : data.url != downloadUrl
                      ? 'Not downloading'
                      : data.percent.toString(),
                ),
                Text(
                  data == null
                      ? 'Not downloading'
                      : data.url !=
                            'https://cdn.uzd.io/uzdigital/videos/a04c9257216b2f2085c88be31a13e5d7/240p/index.m3u8'
                      ? 'Not downloading'
                      : data.percent.toString(),
                ),
              ],
            );
          },
        ),
        FutureBuilder(
          future: checkIsDownloaded(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Text((data ?? false) ? 'Downloaded' : 'Not downloaded', textAlign: TextAlign.center);
          },
        ),
      ],
    ),
  );

  @override
  void dispose() {
    unawaited(_videoPlayerPlugin.dispose());
    super.dispose();
  }
}

/// flutter pub run flutter_launcher_icons:main
/// flutter run -d windows
/// flutter build apk --release
/// flutter build apk --split-per-abi
/// flutter build appbundle --release
/// flutter pub run build_runner watch --delete-conflicting-outputs
/// flutter pub ipa
/// dart fix --apply

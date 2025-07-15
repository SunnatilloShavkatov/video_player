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

  Future<void> download1() async {
    try {
      final s =
          await _videoPlayerPlugin.downloadVideo(
            downloadConfig: const DownloadConfiguration(title: 'She-Hulk 2', url: downloadUrl),
          ) ??
          'nothing';
      if (kDebugMode) {
        print('result: $s');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
  }

  Future<void> download2() async {
    try {
      final s =
          await _videoPlayerPlugin.downloadVideo(
            downloadConfig: const DownloadConfiguration(
              title: 'She-Hulk 2',
              url: 'https://cdn.ooo.io/videos/a04c9257216b2f2085c88be31a13e5d7/240p/index.m3u8',
            ),
          ) ??
          'nothing';
      if (kDebugMode) {
        print('result: $s');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
  }

  Future<void> pauseDownload() async {
    try {
      final s =
          await _videoPlayerPlugin.pauseDownload(
            downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
          ) ??
          'nothing';
      if (kDebugMode) {
        print('result: $s');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
  }

  Future<void> resumeDownload() async {
    try {
      final s =
          await _videoPlayerPlugin.resumeDownload(
            downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
          ) ??
          'nothing';
      if (kDebugMode) {
        print('result: $s');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
  }

  Future<void> removeDownload() async {
    try {
      final s =
          await _videoPlayerPlugin.removeDownload(
            downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
          ) ??
          'nothing';
      if (kDebugMode) {
        print('result: $s');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
  }

  Future<int> getStateDownload() async {
    int state = -1;
    try {
      state =
          await _videoPlayerPlugin.getStateDownload(
            downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
          ) ??
          -1;
      if (kDebugMode) {
        print('result: $state');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
    return state;
  }

  Future<bool> checkIsDownloaded() async {
    bool isDownloaded = false;
    try {
      isDownloaded = await _videoPlayerPlugin.isDownloadVideo(
        downloadConfig: const DownloadConfiguration(title: 'She-Hulk', url: downloadUrl),
      );
      if (kDebugMode) {
        print('result: $isDownloaded');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
    return isDownloaded;
  }

  Stream<MediaItemDownload> currentProgressDownloadAsStream() => _videoPlayerPlugin.currentProgressDownloadAsStream;

  Future<void> playVideo() async {
    try {
      final s = await _videoPlayerPlugin.playVideo(
        playerConfig: const PlayerConfiguration(
          movieShareLink: 'https://uzd.iiii.io/movie/7963?type=premier',
          initialResolution: {
            'Auto':
                'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8',
          },
          resolutions: {
            'Auto':
                'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8',
            '480p': '1014624',
            '720p': '1321824',
            '360p': '1937246',
          },
          qualityText: 'Quality',
          speedText: 'Speed',
          lastPosition: 0,
          title: 'S1 E1   ',
          playVideoFromAsset: false,
          assetPath: '',
          autoText: 'Auto',
        ),
      );
      if (kDebugMode) {
        print('Result Time: $s');
      }
    } on Exception catch (e, s) {
      debugPrint('$e, $s');
      debugPrint('Failed to get platform version.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video Player')),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
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

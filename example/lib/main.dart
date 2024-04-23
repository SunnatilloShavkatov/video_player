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
        theme: ThemeData(primarySwatch: Colors.blue),
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

  Future<void> download1() async {
    try {
      final s = await _videoPlayerPlugin.downloadVideo(
            downloadConfig: const DownloadConfiguration(
              title: 'She-Hulk 2',
              url:
                  'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8',
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

  Future<void> download2() async {
    try {
      final s = await _videoPlayerPlugin.downloadVideo(
              downloadConfig: const DownloadConfiguration(
            title: 'She-Hulk 2',
            url:
                'https://cdn.uzd.udevs.io/uzdigital/videos/a04c9257216b2f2085c88be31a13e5d7/240p/index.m3u8',
          )) ??
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
      final s = await _videoPlayerPlugin.pauseDownload(
              downloadConfig: const DownloadConfiguration(
            title: 'She-Hulk',
            url:
                'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8',
          )) ??
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
      final s = await _videoPlayerPlugin.resumeDownload(
              downloadConfig: const DownloadConfiguration(
            title: 'She-Hulk',
            url:
                'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8',
          )) ??
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
      final s = await _videoPlayerPlugin.removeDownload(
              downloadConfig: const DownloadConfiguration(
            title: 'She-Hulk',
            url:
                'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8',
          )) ??
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
      state = await _videoPlayerPlugin.getStateDownload(
              downloadConfig: const DownloadConfiguration(
            title: 'She-Hulk',
            url:
                'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8',
          )) ??
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
        downloadConfig: const DownloadConfiguration(
          title: 'She-Hulk',
          url:
              'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8',
        ),
      );
      if (kDebugMode) {
        print('result: $isDownloaded');
      }
    } on PlatformException {
      debugPrint('Failed to get platform version.');
    }
    return isDownloaded;
  }

  Stream<MediaItemDownload> currentProgressDownloadAsStream() =>
      _videoPlayerPlugin.currentProgressDownloadAsStream;

  Future<void> playVideo() async {
    try {
      final s = await _videoPlayerPlugin.playVideo(
        playerConfig: const PlayerConfiguration(
          movieShareLink: 'https://uzd.udevs.io/movie/7963?type=premier',
          baseUrl: 'https://api.spec.uzd.udevs.io/v1/',
          initialResolution: {
            'Auto':
                'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8'
          },
          resolutions: {
            'Auto':
                'https://df5ralxb7y7wh.cloudfront.net/elementary_unit_1_the_karate_kid/TRKyawvyNXdOIoLVloLmytyIRSOmgbuUUTqXGMX1.m3u8',
            '480p': '1014624',
            '720p': '1321824',
            '360p': '1937246',
          },
          qualityText: 'Качество',
          speedText: 'Скорость',
          lastPosition: 0,
          title: 'S1 E1  "Женщина-Халк: Адвокат" ',
          isSerial: false,
          episodeButtonText: 'Эпизоды',
          nextButtonText: 'След.эпизод',
          seasons: [],
          isLive: false,
          tvProgramsText: 'Телеканалы',
          programsInfoList: [],
          showController: true,
          playVideoFromAsset: false,
          assetPath: '',
          seasonIndex: 0,
          episodeIndex: 0,
          isMegogo: false,
          isPremier: false,
          videoId: "",
          sessionId: '',
          megogoAccessToken: '',
          authorization: '',
          autoText: 'Автонастройка',
          fromCache: true,
          selectChannelIndex: 0,
          tvCategories: [],
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

  Future<void> playVideoTV() async {
    try {
      final s = await _videoPlayerPlugin.playVideo(
            playerConfig: const PlayerConfiguration(
              movieShareLink: 'https://uzd.udevs.io/movie/7963?type=premier',
              baseUrl: 'https://api.spec.uzd.udevs.io/v1/',
              initialResolution: {
                'Автонастройка':
                    'https://st1.uzdigital.tv/Setanta1HD/video.m3u8?token=316ee910a8ba3e654e262f580299fc93f0367a3b-41666c6b50654d5a7a62747149497458-1695113748-1695102948&remote=94.232.24.122',
                '1080p':
                    'http://st1.uzdigital.tv/Setanta1HD/tracks-v1a1a2/mono.m3u8?remote=94.232.24.122&token=316ee910a8ba3e654e262f580299fc93f0367a3b-41666c6b50654d5a7a62747149497458-1695113748-1695102948&remote=94.232.24.122',
                '576p':
                    'http://st1.uzdigital.tv/Setanta1HD/tracks-v2a1a2/mono.m3u8?remote=94.232.24.122&token=316ee910a8ba3e654e262f580299fc93f0367a3b-41666c6b50654d5a7a62747149497458-1695113748-1695102948&remote=94.232.24.122'
              },
              resolutions: {
                'Автонастройка':
                    'https://st1.uzdigital.tv/Setanta1HD/video.m3u8?token=316ee910a8ba3e654e262f580299fc93f0367a3b-41666c6b50654d5a7a62747149497458-1695113748-1695102948&remote=94.232.24.122'
              },
              qualityText: 'Качество',
              speedText: 'Скорость',
              lastPosition: 0,
              title: 'S1 E1  "Женщина-Халк: Адвокат" ',
              isSerial: false,
              episodeButtonText: 'Эпизоды',
              nextButtonText: 'След.эпизод',
              seasons: [],
              isLive: true,
              tvProgramsText: 'Телеканалы',
              programsInfoList: [],
              showController: true,
              playVideoFromAsset: false,
              assetPath: '',
              seasonIndex: 0,
              episodeIndex: 0,
              isMegogo: false,
              isPremier: false,
              videoId: '',
              sessionId: '',
              megogoAccessToken: '',
              authorization: '',
              autoText: 'Автонастройка',
              fromCache: true,
              selectChannelIndex: 0,
              tvCategories: [],
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: playVideo,
              child: const Text('Play Video'),
            ),
            ElevatedButton(
              onPressed: playVideoTV,
              child: const Text('Play Video Tv'),
            ),
            ElevatedButton(
              onPressed: download1,
              child: const Text('Download1'),
            ),
            ElevatedButton(
              onPressed: download2,
              child: const Text('Download2'),
            ),
            ElevatedButton(
              onPressed: pauseDownload,
              child: const Text('Pause Download'),
            ),
            ElevatedButton(
              onPressed: resumeDownload,
              child: const Text('Resume Download'),
            ),
            ElevatedButton(
              onPressed: removeDownload,
              child: const Text('Remove Download'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SecondPage(),
                  ),
                );
              },
              child: const Text('Got to next page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const VideoPlayerPage(),
                  ),
                );
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
                          : data.url !=
                                  'https://cdn.uzd.udevs.io/uzdigital/videos/772a7a12977cd08a10b6f6843ae80563/240p/index.m3u8'
                              ? 'Not downloading'
                              : data.percent.toString(),
                    ),
                    Text(
                      data == null
                          ? 'Not downloading'
                          : data.url !=
                                  'https://cdn.uzd.udevs.io/uzdigital/videos/a04c9257216b2f2085c88be31a13e5d7/240p/index.m3u8'
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
                return Text((data ?? false) ? 'Downloaded' : 'Not downloaded');
              },
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _videoPlayerPlugin.dispose();
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

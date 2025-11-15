import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/video_view_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Video Player',
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
  /// Helper method to show snack bar messages
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> playVideo() async {
    try {
      final playbackTimes = await VideoPlayer.instance.playVideo(
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
        ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => const VideoPlayerPage()));
          },
          child: const Text('Got to video view page'),
        ),
      ],
    ),
  );
}

/// flutter pub run flutter_launcher_icons:main
/// flutter run -d windows
/// flutter build apk --release
/// flutter build apk --split-per-abi
/// flutter build appbundle --release
/// flutter pub run build_runner watch --delete-conflicting-outputs
/// flutter pub ipa
/// dart fix --apply

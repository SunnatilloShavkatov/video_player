import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/video_view_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Video Player Example',
    themeMode: ThemeMode.light,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarContrastEnforced: false,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
    ),
    home: const MainPage(),
  );
}

class MainPage extends StatefulWidget {
  const new({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const String _sampleVideoUrl =
      'https://englifypublicvideos.hel1.your-objectstorage.com/public/englify-intro-video2/master.m3u8';

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
  }

  Future<void> _playFullscreenVideo() async {
    try {
      final result = await VideoPlayer.instance.playVideo(
        playerConfig: PlayerConfiguration.remote(
          videoUrl: _sampleVideoUrl,
          title: "Harry Potter and the Philosopher's Stone",
          movieShareLink: 'https://uzd.iiii.io/movie/7963?type=premier',
        ),
      );

      switch (result) {
        case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
          if (kDebugMode) {
            print('Playback completed: $lastPositionSeconds / $durationSeconds sec');
          }
          _showSnackBar('Playback finished at ${lastPositionSeconds}s of ${durationSeconds}s');
        case PlaybackCancelled():
          if (kDebugMode) {
            print('Playback cancelled by user');
          }
          _showSnackBar('Playback cancelled');
        case PlaybackFailed(:final error):
          debugPrint('Playback failed: $error');
          _showSnackBar('Playback failed: $error');
      }
    } on ArgumentError catch (e) {
      debugPrint('Invalid video configuration: $e');
      _showSnackBar('Invalid video configuration: ${e.message}');
    } on Exception catch (e) {
      debugPrint('Unexpected error playing video: $e');
      _showSnackBar('Unexpected error occurred');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video Player Plugin')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Full-Screen Player', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Launches the native full-screen video player (ExoPlayer on Android, AVPlayer on iOS/macOS) with HLS quality selection, playback speed controls, and PiP support.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _playFullscreenVideo,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play Fullscreen Video'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Embedded Platform View', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Embeds the native video player directly inside the Flutter widget hierarchy with custom overlay controls, duration streams, and seeking.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await Navigator.of(
                          context,
                        ).push(MaterialPageRoute<void>(builder: (context) => const VideoPlayerPage()));
                      },
                      icon: const Icon(Icons.video_library_rounded),
                      label: const Text('Open Embedded View Demo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
